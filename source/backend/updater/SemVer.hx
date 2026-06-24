package backend.updater;

using StringTools;

typedef Version = {major:Int, minor:Int, patch:Int};

class SemVer {
	public static function parse(raw:String):Version {
		var s:String = (raw == null) ? '' : raw.trim().toLowerCase();

		if (s.startsWith('release-'))
			s = s.substr('release-'.length);
		else if (s.startsWith('dev-'))
			s = s.substr('dev-'.length);

		if (s.startsWith('v.'))
			s = s.substr(2);
		else if (s.startsWith('v'))
			s = s.substr(1);

		s = s.trim();

		var parts:Array<String> = s.split('.');
		return {
			major: numAt(parts, 0),
			minor: numAt(parts, 1),
			patch: numAt(parts, 2)
		};
	}

	public static function compare(a:Version, b:Version):Int {
		if (a.major != b.major)
			return a.major < b.major ? -1 : 1;
		if (a.minor != b.minor)
			return a.minor < b.minor ? -1 : 1;
		if (a.patch != b.patch)
			return a.patch < b.patch ? -1 : 1;
		return 0;
	}

	public static inline function compareStr(a:String, b:String):Int
		return compare(parse(a), parse(b));

	public static inline function toString(v:Version):String
		return '${v.major}.${v.minor}.${v.patch}';

	static function numAt(parts:Array<String>, i:Int):Int {
		if (i >= parts.length)
			return 0;
		var digits:String = '';
		for (c in 0...parts[i].length) {
			var ch:String = parts[i].charAt(c);
			if (ch >= '0' && ch <= '9')
				digits += ch;
			else
				break;
		}
		var n:Null<Int> = Std.parseInt(digits);
		return n == null ? 0 : n;
	}
}
