package llua;

import hxluajit.wrapper.LuaConverter;

// Compatibility shim mirroring linc_luajit's `Convert` class but
// delegating to hxluajit-wrapper's `LuaConverter`.
class Convert {
	public static inline function fromLua(L:State, idx:Int):Dynamic
		return LuaConverter.fromLua(L, idx);

	public static inline function toLua(L:State, val:Dynamic):Void
		LuaConverter.toLua(L, val);
}
