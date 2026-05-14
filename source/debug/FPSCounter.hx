package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField {
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	// Ring buffer of frame timestamps. The old impl used Array.push +
	// Array.shift each frame, where shift() is O(n) and reallocates the
	// backing storage. With a fixed-size ring we get O(1) per frame and
	// zero allocations once warm.
	@:noCompletion private static inline var TIMES_CAPACITY:Int = 1024;
	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var timesHead:Int = 0;
	@:noCompletion private var timesCount:Int = 0;
	@:noCompletion private var lastFPSValue:Int = -1;
	@:noCompletion private var lastMemValue:Float = -1;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000) {
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [for (i in 0...TIMES_CAPACITY) 0];
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void {
		final now:Float = haxe.Timer.stamp() * 1000;
		final cap:Int = TIMES_CAPACITY;

		// Push current timestamp; overwrite oldest if we'd overflow (only
		// happens at sustained >1000 FPS, but be defensive).
		if (timesCount < cap) {
			times[(timesHead + timesCount) % cap] = now;
			timesCount++;
		} else {
			times[timesHead] = now;
			timesHead = (timesHead + 1) % cap;
		}

		// Drop entries older than 1000ms.
		final cutoff:Float = now - 1000;
		while (timesCount > 0 && times[timesHead] < cutoff) {
			timesHead = (timesHead + 1) % cap;
			timesCount--;
		}

		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = timesCount < FlxG.updateFramerate ? timesCount : FlxG.updateFramerate;
		updateText();
		deltaTimeout = 0.0;
	}

	public dynamic function updateText():Void { // so people can override it in hscript
		// Skip text reassignment when nothing changed -- avoids a TextField
		// invalidate + redraw on every refresh tick.
		final mem:Float = memoryMegas;
		if (currentFPS != lastFPSValue || mem != lastMemValue) {
			lastFPSValue = currentFPS;
			lastMemValue = mem;
			text = 'FPS: ${currentFPS}' + '\nMemory: ${flixel.util.FlxStringUtil.formatBytes(mem)}';
		}

		final col:Int = (currentFPS < FlxG.drawFramerate * 0.5) ? 0xFFFF0000 : 0xFFFFFFFF;
		if (textColor != col)
			textColor = col;
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
}
