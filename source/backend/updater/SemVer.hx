package backend.updater;

using StringTools;

typedef Version = {major:Int, minor:Int, patch:Int};

/**
 * Utility class for parsing, comparing, and formatting semantic version strings.
 * Handles various version formats including prefixes like 'v', 'release-', and 'dev-'.
 */
class SemVer {
	/**
	 * Parses a semantic version string into a Version object.
	 * Handles prefixes like 'v', 'release-', and 'dev-'.
	 * @param raw The raw version string to parse
	 * @return A Version object with major, minor, and patch components
	 */
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

	/**
	 * Compares two Version objects.
	 * @param a The first version to compare
	 * @param b The second version to compare
	 * @return -1 if a < b, 1 if a > b, 0 if equal
	 */
	public static function compare(a:Version, b:Version):Int {
		if (a.major != b.major)
			return a.major < b.major ? -1 : 1;
		if (a.minor != b.minor)
			return a.minor < b.minor ? -1 : 1;
		if (a.patch != b.patch)
			return a.patch < b.patch ? -1 : 1;
		return 0;
	}

	/**
	 * Compares two version strings.
	 * @param a The first version string to compare
	 * @param b The second version string to compare
	 * @return -1 if a < b, 1 if a > b, 0 if equal
	 */
	public static inline function compareStr(a:String, b:String):Int
		return compare(parse(a), parse(b));

	/**
	 * Converts a Version object to a semantic version string.
	 * @param v The version object to convert
	 * @return A string in the format "major.minor.patch"
	 */
	public static inline function toString(v:Version):String
		return '${v.major}.${v.minor}.${v.patch}';

	/**
	 * Extracts the numeric portion from a version part string.
	 * @param parts The array of version parts
	 * @param i The index of the part to extract from
	 * @return The numeric value, or 0 if not found or out of bounds
	 */
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
