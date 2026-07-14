package backend;

import flixel.util.FlxSave;

/**
 * Settings for the on-screen debug/performance counter (debug.FPSCounter).
 *
 * These intentionally live in their OWN save file, separate from
 * `ClientPrefs.data`, so that mod scripts cannot tamper with them: there is
 * nothing for `setProperty`/`Reflect.setProperty` against `ClientPrefs.data` to
 * hit, and `backend.DebugPrefs` itself is on the ModSecurity class blocklist
 * (so scripts can't resolve it to reach `DebugPrefs.data` either).
 *
 * Edited via options.FPSCounterSettingsSubState (and the master toggle in
 * VisualsSettingsSubState), applied live through `Main.fpsVar.updateConfiguration()`.
 */
@:structInit class DebugVariables {
	public var showFPS:Bool = true; // master visibility toggle
	// Anchor corner: 'Top Left' | 'Top Right' | 'Bottom Left' | 'Bottom Right'.
	public var fpsPosition:String = 'Top Left';
	public var fpsSize:Int = 14; // font size in points
	public var fpsUpdateMS:Int = 50; // minimum ms between text refreshes (0 = every frame)
	public var fpsColor:String = 'White'; // named color, see debug.FPSCounter.COLORS
	public var fpsBackground:Bool = false; // draw a dark panel behind the counter for readability
	public var fpsBackgroundAlpha:Float = 0.5; // 0..1 opacity of that panel
	// Which metrics the counter prints:
	public var fpsShowFPS:Bool = true;
	public var fpsShowMemory:Bool = true; // real process memory (or GC if no hxhardware)
	public var fpsShowMemoryPeak:Bool = false;
	public var fpsShowGCMemory:Bool = false; // hxcpp GC heap only (excludes LuaJIT)
	public var fpsShowLuaMem:Bool = false; // LuaJIT GC across all live scripts; needs LUA_ALLOWED
	public var fpsShowCPU:Bool = false; // requires HARDWARE_ALLOWED (hxhardware)
	public var fpsShowGPU:Bool = false; // requires HARDWARE_ALLOWED (hxhardware), Windows only
	public var fpsShowGPUMem:Bool = false; // dedicated VRAM usage; HARDWARE_ALLOWED + Windows (DXGI)
	// Column layout: which line each metric sits on (1-based). Metrics sharing a
	// line are joined with " | ", lines are ordered by number ascending.
	public var fpsRowFPS:Int = 1;
	public var fpsRowMemory:Int = 2;
	public var fpsRowMemoryPeak:Int = 3;
	public var fpsRowGCMemory:Int = 4;
	public var fpsRowLuaMem:Int = 5;
	public var fpsRowCPU:Int = 6;
	public var fpsRowGPU:Int = 7;
	public var fpsRowGPUMem:Int = 8;
}

class DebugPrefs {
	public static var data:DebugVariables = {};
	public static final defaultData:DebugVariables = {};

	static inline final SAVE_NAME:String = 'debugcounters';

	public static function save():Void {
		var s:FlxSave = new FlxSave();
		s.bind(SAVE_NAME, CoolUtil.getSavePath());
		for (key in Reflect.fields(data))
			Reflect.setField(s.data, key, Reflect.field(data, key));
		s.flush();
	}

	/**
	 * Loads the counter prefs from their own save. On first run after the split
	 * from ClientPrefs, any legacy values still sitting in the main `funkin` save
	 * are migrated over (and removed from there) so users keep their settings.
	 */
	public static function load():Void {
		var s:FlxSave = new FlxSave();
		s.bind(SAVE_NAME, CoolUtil.getSavePath());

		var migrated:Bool = false;
		final legacy:Dynamic = (FlxG.save != null) ? FlxG.save.data : null;
		for (key in Reflect.fields(data)) {
			if (Reflect.hasField(s.data, key))
				Reflect.setField(data, key, Reflect.field(s.data, key));
			else if (legacy != null && Reflect.hasField(legacy, key)) {
				Reflect.setField(data, key, Reflect.field(legacy, key));
				Reflect.deleteField(legacy, key); // de-orphan the old ClientPrefs entry
				migrated = true;
			}
		}

		if (migrated) {
			if (FlxG.save != null)
				FlxG.save.flush();
			save();
		}
	}
}
