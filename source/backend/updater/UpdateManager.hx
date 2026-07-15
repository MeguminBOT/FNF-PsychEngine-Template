package backend.updater;

import backend.updater.SemVer.Version;

using StringTools;

enum abstract UpdateChannel(String) from String to String {
	var Stable = 'stable';
	var BleedingEdge = 'bleeding';
}

typedef ReleaseAsset = {name:String, url:String, digest:String};
typedef ReleaseEntry = {tag:String, prerelease:Bool, body:String, assets:Array<ReleaseAsset>};

typedef UpdateInfo = {
	channel:UpdateChannel,
	tag:String,
	version:Version,
	zipUrl:String,
	zipName:String,
	zipSha256:String, // expected hash from GitHub's asset digest (null if unavailable)
	sumsUrl:String, // fallback: a SHA256SUMS.txt asset (null if none)
	body:String
};

/**
 * Manages application update checking and resolution from GitHub releases.
 * Provides background update checks with thread-safe state management and version resolution.
 */
class UpdateManager {
	public static inline var REPO:String = 'MeguminBOT/FNF-PsychEngine-Template';
	static inline var RELEASES_URL:String = 'https://api.github.com/repos/MeguminBOT/FNF-PsychEngine-Template/releases';
	public static inline var RELEASES_PAGE:String = 'https://github.com/MeguminBOT/FNF-PsychEngine-Template/releases';

	public static function currentChannel():UpdateChannel {
		return (ClientPrefs.data.updateChannel == BleedingEdge) ? BleedingEdge : Stable;
	}

	public static var dismissedThisSession:Bool = false;

	public static var checkState(default, null):String = 'idle'; // idle | checking | done | failed
	public static var result(default, null):UpdateInfo = null;
	public static var checkError(default, null):String = null;

	#if sys
	static var _mutex:sys.thread.Mutex = new sys.thread.Mutex();
	#end

	/**
	 * Starts an update check on a background thread.
	 * @param channel The update channel to check.
	 */
	public static function beginBackgroundCheck(channel:UpdateChannel):Void {
		#if sys
		_mutex.acquire();
		if (checkState == 'checking') {
			_mutex.release();
			return;
		}
		checkState = 'checking';
		result = null;
		checkError = null;
		_mutex.release();

		sys.thread.Thread.create(function() {
			var info:UpdateInfo = null;
			var err:String = null;
			try {
				var releases:Array<ReleaseEntry> = fetchReleases();
				info = resolve(channel, releases);
			} catch (e:Dynamic) {
				err = Std.string(e);
			}
			_mutex.acquire();
			if (err != null) {
				checkError = err;
				checkState = 'failed';
			} else {
				result = info;
				checkState = 'done';
			}
			_mutex.release();
		});
		#else
		checkState = 'failed';
		checkError = 'Updater is desktop-only.';
		#end
	}

	/**
	 * Fetches all releases from the GitHub API.
	 * @return An array of release entries with tag, prerelease status, and assets
	 */
	public static function fetchReleases():Array<ReleaseEntry> {
		var raw:String = httpGet(RELEASES_URL);
		if (raw == null || raw.length == 0)
			throw 'Empty response from GitHub.';

		var parsed:Dynamic = haxe.Json.parse(raw);
		var out:Array<ReleaseEntry> = [];
		var arr:Array<Dynamic> = cast parsed;
		if (arr == null)
			return out;

		for (rel in arr) {
			if (rel == null)
				continue;
			var assets:Array<ReleaseAsset> = [];
			var rawAssets:Array<Dynamic> = cast Reflect.field(rel, 'assets');
			if (rawAssets != null) {
				for (a in rawAssets) {
					if (a == null)
						continue;
					var name:String = Reflect.field(a, 'name');
					var url:String = Reflect.field(a, 'browser_download_url');
					var digest:String = Reflect.field(a, 'digest'); // "sha256:..." or null
					if (name != null && url != null)
						assets.push({name: name, url: url, digest: digest});
				}
			}
			var tag:String = Reflect.field(rel, 'tag_name');
			if (tag == null)
				continue;
			out.push({
				tag: tag,
				prerelease: Reflect.field(rel, 'prerelease') == true,
				body: (Reflect.field(rel, 'body') : String),
				assets: assets
			});
		}
		return out;
	}

	/**
	 * Resolves the best available update for a given channel from a list of releases.
	 * Filters by channel eligibility and selects the newest compatible version.
	 * @param channel The update channel to resolve for
	 * @param releases The array of available releases
	 * @return An UpdateInfo object for the best available update, or null if none found
	 */
	public static function resolve(channel:UpdateChannel, releases:Array<ReleaseEntry>):UpdateInfo {
		if (releases == null || releases.length == 0)
			return null;

		var best:ReleaseEntry = null;
		var bestVer:Version = null;

		for (rel in releases) {
			var tagLow:String = rel.tag.toLowerCase();
			var isReleaseTag:Bool = tagLow.startsWith('release-') || (!rel.prerelease && !tagLow.startsWith('dev-'));
			var isDevTag:Bool = rel.prerelease || tagLow.startsWith('dev-');

			var eligible:Bool = switch (channel) {
				case Stable: isReleaseTag && !rel.prerelease;
				case BleedingEdge: true; // dev sees everything
				default: false;
			}
			if (!eligible)
				continue;

			var ver:Version = SemVer.parse(rel.tag);
			if (best == null) {
				best = rel;
				bestVer = ver;
				continue;
			}

			var cmp:Int = SemVer.compare(ver, bestVer);
			if (cmp > 0) {
				best = rel;
				bestVer = ver;
			} else if (cmp == 0 && channel == BleedingEdge) {
				// Tie: prefer the stable release over the dev prerelease.
				var bestIsDev:Bool = best.prerelease || best.tag.toLowerCase().startsWith('dev-');
				if (bestIsDev && !isDevTag) {
					best = rel;
					bestVer = ver;
				}
			}
		}

		if (best == null)
			return null;

		var zip:ReleaseAsset = findAsset(best.assets, a -> {
			var n:String = a.name.toLowerCase();
			return n.indexOf('windows') >= 0 && n.endsWith('.zip');
		});
		var sums:ReleaseAsset = findAsset(best.assets, a -> a.name.toLowerCase().indexOf('sha256sums') >= 0);

		if (zip == null)
			return null;

		var zipSha:String = null;
		if (zip.digest != null && zip.digest.toLowerCase().startsWith('sha256:'))
			zipSha = zip.digest.substr('sha256:'.length).trim();

		return {
			channel: channel,
			tag: best.tag,
			version: bestVer,
			zipUrl: zip.url,
			zipName: zip.name,
			zipSha256: zipSha,
			sumsUrl: sums != null ? sums.url : null,
			body: best.body != null ? best.body : ''
		};
	}

	/**
	 * Checks if an update is newer than the current engine version.
	 * @param info The update information to check
	 * @return True if the update version is newer than the running version
	 */
	public static function isNewer(info:UpdateInfo):Bool {
		if (info == null)
			return false;
		return SemVer.compare(info.version, SemVer.parse(states.MainMenuState.psychEngineVersion)) > 0;
	}

	static function findAsset(assets:Array<ReleaseAsset>, pred:ReleaseAsset->Bool):ReleaseAsset {
		if (assets == null)
			return null;
		for (a in assets)
			if (pred(a))
				return a;
		return null;
	}

	/**
	 * Performs an HTTP GET request with GitHub API headers.
	 * @param url The URL to request
	 * @return The response body as a string
	 */
	static function httpGet(url:String):String {
		var http = new haxe.Http(url);
		http.setHeader('User-Agent', 'FNF-PsychEngine-Updater');
		http.setHeader('Accept', 'application/vnd.github+json');
		var data:String = null;
		var error:String = null;
		http.onData = d -> data = d;
		http.onError = e -> error = e;
		http.request(false);
		if (error != null)
			throw error;
		return data;
	}
}
