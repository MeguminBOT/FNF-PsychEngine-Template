package backend.updater;

import backend.updater.UpdateManager.UpdateInfo;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import haxe.io.Bytes;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.net.URLLoaderDataFormat;
import openfl.utils.ByteArray;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
#end

using StringTools;

#if (windows && cpp)
@:cppFileCode('extern "C" __declspec(dllimport) int __stdcall MoveFileExW(const wchar_t*, const wchar_t*, unsigned long);
extern "C" __declspec(dllimport) unsigned long __stdcall GetLastError(void);
extern "C" __declspec(dllimport) unsigned long __stdcall GetCurrentProcessId(void);
extern "C" __declspec(dllimport) void* __stdcall OpenProcess(unsigned long, int, unsigned long);
extern "C" __declspec(dllimport) unsigned long __stdcall WaitForSingleObject(void*, unsigned long);
extern "C" __declspec(dllimport) int __stdcall CloseHandle(void*);')
#end
class UpdateInstaller {
	public static var DIR_TMP:String = 'update_tmp';
	public static var DIR_STAGING:String = 'update_staging';
	public static var BAK_SUFFIX:String = '.old.bak';
	static var MARKER_READY:String = '.ready'; // written into staging once extraction succeeds
	static var MARKER_PID:String = '.parent_pid'; // PID of the session that staged the update

	static var SKIP_PREFIXES:Array<String> = ['mods/', 'update_tmp/', 'update_staging/'];

	#if sys
	final info:UpdateInfo;

	final mutex:sys.thread.Mutex = new sys.thread.Mutex();
	var _phase:String = 'idle';
	var _percent:Float = 0;
	var _error:String = null;
	var _ready:Bool = false;
	var _needElevation:Bool = false;
	var _logs:Array<String> = [];

	var root:String;
	var tmpDir:String;
	var stageDir:String;
	var sumsText:String;
	var zipBytes:Bytes;

	public function new(info:UpdateInfo) {
		this.info = info;
	}

	public function start():Void {
		root = Path.directory(Sys.programPath());
		tmpDir = Path.join([root, DIR_TMP]);
		stageDir = Path.join([root, DIR_STAGING]);

		log('Update ${info.tag} selected.');
		if (info.zipUrl == null) {
			fail('Release has no Windows build to download.');
			return;
		}
		if (info.zipSha256 == null && info.sumsUrl == null) {
			fail('Release has no checksum (GitHub digest or SHA256SUMS.txt) -- refusing to install an unverified build.');
			return;
		}

		try {
			recreateDir(tmpDir);
			recreateDir(stageDir);
		} catch (e:Dynamic) {
			fail('Could not prepare staging folders: ${Std.string(e)}');
			return;
		}

		if (info.zipSha256 != null) {
			log('Using GitHub-provided SHA-256.');
			downloadZip();
		} else {
			downloadSums();
		}
	}

	public function phase():String return guarded(() -> _phase);
	public function percent():Float return guarded(() -> _percent);
	public function error():String return guarded(() -> _error);
	public function isReady():Bool return guarded(() -> _ready);
	public function needsElevation():Bool return guarded(() -> _needElevation);

	public function popLogs():Array<String> {
		mutex.acquire();
		var out = _logs;
		_logs = [];
		mutex.release();
		return out;
	}

	public function relaunch():Void {
		try {
			new sys.io.Process(Sys.programPath(), []);
		} catch (e:Dynamic) {}
		Sys.exit(0);
	}

	function downloadSums():Void {
		setPhase('download-sums');
		log('Downloading checksums...');
		httpBinary(info.sumsUrl, false, function(bytes:Bytes) {
			sumsText = bytes.toString();
			downloadZip();
		});
	}

	function downloadZip():Void {
		setPhase('downloading');
		setPercent(0);
		log('Downloading ${info.zipName}...');
		httpBinary(info.zipUrl, true, function(bytes:Bytes) {
			zipBytes = bytes;
			log('Download complete (${fmtMB(bytes.length)}).');
			startWorker();
		});
	}

	function httpBinary(url:String, trackProgress:Bool, onDone:Bytes->Void):Void {
		var loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		if (trackProgress) {
			loader.addEventListener(ProgressEvent.PROGRESS, function(e:ProgressEvent) {
				if (e.bytesTotal > 0)
					setPercent(e.bytesLoaded / e.bytesTotal);
			});
		}
		loader.addEventListener(Event.COMPLETE, function(_) {
			var ba:ByteArray = loader.data;
			var bytes:Bytes = ba;
			onDone(bytes);
		});
		loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) fail('Download failed: ${e.text}'));
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent) fail('Download blocked: ${e.text}'));
		try
			loader.load(new URLRequest(url))
		catch (e:Dynamic)
			fail('Could not start download: ${Std.string(e)}');
	}

	function startWorker():Void {
		sys.thread.Thread.create(function() {
			try {
				setPhase('verifying');
				log('Verifying SHA-256...');
				var actual:String = haxe.crypto.Sha256.make(zipBytes).toHex().toLowerCase();
				var expected:String = (info.zipSha256 != null) ? info.zipSha256 : expectedHashFor(info.zipName, sumsText);
				if (expected == null)
					throw 'No checksum listed for ${info.zipName}.';
				if (actual != expected.toLowerCase())
					throw 'Checksum mismatch -- the download is corrupt or tampered with.';
				log('Checksum OK.');

				setPhase('extracting');
				log('Extracting...');
				extractZip(zipBytes, stageDir);
				zipBytes = null; // free the in-memory archive

				if (!isWritable(root)) {
					log('Install folder is not writable (admin/Program Files?).');
					mutex.acquire();
					_needElevation = true;
					mutex.release();
					setPhase('need-elevation');
					return;
				}

				File.saveContent(Path.join([stageDir, MARKER_READY]), 'ready');
				File.saveContent(Path.join([stageDir, MARKER_PID]), Std.string(currentPid()));
				log('Update staged. Restarting to finish install...');

				mutex.acquire();
				_ready = true;
				mutex.release();
				setPhase('ready');
			} catch (e:Dynamic) {
				fail(Std.string(e));
			}
		});
	}

	function extractZip(bytes:Bytes, dest:String):Void {
		var entries = haxe.zip.Reader.readZip(new haxe.io.BytesInput(bytes));
		for (entry in entries) {
			if (entry.fileName == null || entry.fileName.endsWith('/'))
				continue;
			var rel:String = entry.fileName.split('\\').join('/');
			var outPath:String = Path.join([dest, rel]);
			ensureDir(Path.directory(outPath));
			File.saveBytes(outPath, haxe.zip.Reader.unzip(entry));
		}
	}

	static function effectiveBuildRoot(dir:String):String {
		var items:Array<String> = FileSystem.readDirectory(dir);
		if (items.length == 1) {
			var only:String = Path.join([dir, items[0]]);
			if (FileSystem.isDirectory(only))
				return only;
		}
		return dir;
	}

	static function applyStaged(srcRoot:String, dstRoot:String):Int {
		var count:Int = 0;
		function walk(dir:String) {
			for (name in FileSystem.readDirectory(dir)) {
				if (name == MARKER_READY || name == MARKER_PID)
					continue;
				var full:String = Path.join([dir, name]);
				var rel:String = relativeTo(srcRoot, full).split('\\').join('/');
				var relLow:String = rel.toLowerCase();
				if (relLow.endsWith(BAK_SUFFIX) || isSkipped(relLow))
					continue;
				if (FileSystem.isDirectory(full)) {
					walk(full);
				} else {
					replaceFile(full, Path.join([dstRoot, rel]));
					count++;
				}
			}
		}
		walk(srcRoot);
		return count;
	}

	static function replaceFile(src:String, target:String):Void {
		ensureDir(Path.directory(target));
		var bak:String = target + BAK_SUFFIX;
		if (FileSystem.exists(target)) {
			if (!moveWithRetry(target, bak)) {
				clearReadOnly(target);
				if (!moveWithRetry(target, bak))
					throw 'Could not move "$target" aside (Windows error $lastWinErr). It may be locked by another program or antivirus.';
			}
		}
		if (!moveWithRetry(src, target)) {
			clearReadOnly(src);
			if (!moveWithRetry(src, target))
				throw 'Could not install "$target" (Windows error $lastWinErr).';
		}
	}

	public static var lastWinErr:Int = 0;

	static function moveReplace(src:String, dst:String):Bool {
		#if windows
		var r:Int = 0;
		var err:Int = 0;
		untyped __cpp__('hx::strbuf _s; hx::strbuf _d; {0} = MoveFileExW({1}.wchar_str(&_s), {2}.wchar_str(&_d), 0x3) ? 1 : 0; {3} = {0} ? 0 : (int)GetLastError();',
			r, src, dst, err);
		lastWinErr = err;
		return r != 0;
		#else
		try {
			sys.FileSystem.rename(src, dst);
			return true;
		} catch (e:Dynamic)
			return false;
		#end
	}

	static function moveWithRetry(src:String, dst:String):Bool {
		var tries:Int = 0;
		while (true) {
			if (moveReplace(src, dst))
				return true;
			if (lastWinErr != 32 || tries >= 25) // 32 = ERROR_SHARING_VIOLATION
				return false;
			tries++;
			#if sys Sys.sleep(0.2); #end
		}
	}

	static function currentPid():Int {
		#if windows
		var pid:Int = 0;
		untyped __cpp__('{0} = (int)GetCurrentProcessId()', pid);
		return pid;
		#else
		return 0;
		#end
	}

	static function waitForPidExit(pid:Int, timeoutMs:Int):Void {
		#if windows
		if (pid <= 0)
			return;
		untyped __cpp__('void* _h = OpenProcess(0x00100000, 0, (unsigned long){0}); _h ? (WaitForSingleObject(_h, (unsigned long){1}), CloseHandle(_h)) : 0',
			pid, timeoutMs);
		#end
	}

	static function forceDelete(p:String):Void {
		try
			FileSystem.deleteFile(p)
		catch (e:Dynamic) {
			clearReadOnly(p);
			try
				FileSystem.deleteFile(p)
			catch (e2:Dynamic) {}
		}
	}

	static function clearReadOnly(p:String):Void {
		#if windows
		try
			Sys.command('attrib', ['-R', p])
		catch (e:Dynamic) {}
		#end
	}

	function isWritable(dir:String):Bool {
		var probe:String = Path.join([dir, '.psych_update_probe']);
		try {
			File.saveContent(probe, 'ok');
			FileSystem.deleteFile(probe);
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}

	static function isSkipped(relLow:String):Bool {
		for (p in SKIP_PREFIXES)
			if (relLow == p.substr(0, p.length - 1) || relLow.startsWith(p))
				return true;
		return false;
	}

	static function relativeTo(root:String, full:String):String {
		var r:String = root.split('\\').join('/');
		var f:String = full.split('\\').join('/');
		if (!r.endsWith('/'))
			r += '/';
		return f.startsWith(r) ? f.substr(r.length) : f;
	}

	function expectedHashFor(fileName:String, sums:String):String {
		if (sums == null)
			return null;
		var base:String = Path.withoutDirectory(fileName).toLowerCase();
		for (line in sums.split('\n')) {
			var t:String = line.trim();
			if (t.length == 0)
				continue;
			var sp:Int = t.indexOf(' ');
			if (sp <= 0)
				continue;
			var hash:String = t.substr(0, sp).trim();
			var name:String = t.substr(sp).trim();
			if (name.startsWith('*'))
				name = name.substr(1);
			if (Path.withoutDirectory(name).toLowerCase() == base)
				return hash;
		}
		return null;
	}

	static function ensureDir(dir:String):Void {
		if (dir != null && dir.length > 0 && !FileSystem.exists(dir))
			FileSystem.createDirectory(dir);
	}

	function recreateDir(dir:String):Void {
		if (FileSystem.exists(dir))
			deleteTree(dir);
		FileSystem.createDirectory(dir);
	}

	static function deleteTree(dir:String):Void {
		if (!FileSystem.exists(dir))
			return;
		if (FileSystem.isDirectory(dir)) {
			for (name in FileSystem.readDirectory(dir))
				deleteTree(Path.join([dir, name]));
			try
				FileSystem.deleteDirectory(dir)
			catch (e:Dynamic) {}
		} else {
			try
				FileSystem.deleteFile(dir)
			catch (e:Dynamic) {}
		}
	}

	inline function fmtMB(bytes:Int):String
		return '${Math.round(bytes / 1048576 * 10) / 10} MB';

	function log(msg:String):Void {
		mutex.acquire();
		_logs.push(msg);
		mutex.release();
	}

	function setPhase(p:String):Void {
		mutex.acquire();
		_phase = p;
		mutex.release();
	}

	function setPercent(p:Float):Void {
		mutex.acquire();
		_percent = p;
		mutex.release();
	}

	function fail(msg:String):Void {
		mutex.acquire();
		_error = msg;
		_phase = 'error';
		_logs.push('ERROR: $msg');
		mutex.release();
	}

	function guarded<T>(f:Void->T):T {
		mutex.acquire();
		var v = f();
		mutex.release();
		return v;
	}

	public static function applyPendingOnBoot():Void {
		var root:String = Path.directory(Sys.programPath());
		var staging:String = Path.join([root, DIR_STAGING]);
		if (!FileSystem.exists(Path.join([staging, MARKER_READY])))
			return;

		try {
			var pidFile:String = Path.join([staging, MARKER_PID]);
			if (FileSystem.exists(pidFile)) {
				var pid:Null<Int> = Std.parseInt(File.getContent(pidFile).trim());
				if (pid != null)
					waitForPidExit(pid, 20000);
			}

			var buildRoot:String = effectiveBuildRoot(staging);
			applyStaged(buildRoot, root);
			deleteTree(staging);
		} catch (e:Dynamic) {
			try
				deleteTree(staging)
			catch (e2:Dynamic) {}
			return;
		}

		try {
			new sys.io.Process(Sys.programPath(), []);
		} catch (e:Dynamic) {}
		Sys.exit(0);
	}

	public static function cleanupOnBoot():Void {
		var root:String = Path.directory(Sys.programPath());
		deleteTree(Path.join([root, DIR_TMP]));
		var staging:String = Path.join([root, DIR_STAGING]);
		if (FileSystem.exists(staging) && !FileSystem.exists(Path.join([staging, MARKER_READY])))
			deleteTree(staging);
		deleteBaks(root);
	}

	static function deleteBaks(dir:String):Void {
		if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))
			return;
		for (name in FileSystem.readDirectory(dir)) {
			if (name == 'mods')
				continue;
			var full:String = Path.join([dir, name]);
			try {
				if (FileSystem.isDirectory(full))
					deleteBaks(full);
				else if (name.toLowerCase().endsWith(BAK_SUFFIX))
					forceDelete(full);
			} catch (e:Dynamic) {}
		}
	}
	#else
	public function new(info:UpdateInfo) {}

	public function start():Void {}
	public function phase():String return 'error';
	public function percent():Float return 0;
	public function error():String return 'The in-engine updater is desktop-only.';
	public function isReady():Bool return false;
	public function needsElevation():Bool return false;
	public function popLogs():Array<String> return [];
	public function relaunch():Void {}

	public static function applyPendingOnBoot():Void {}
	public static function cleanupOnBoot():Void {}
	#end
}
