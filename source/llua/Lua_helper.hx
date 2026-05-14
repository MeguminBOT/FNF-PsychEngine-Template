package llua;

import hxluajit.Lua;
import hxluajit.Types;

/**
 * Compatibility shim for linc_luajit's `Lua_helper`.
 *
 * linc_luajit installed a single global C dispatcher (set via
 * `Lua.set_callbacks_function`) and made `Lua.register` route every named
 * callback through that dispatcher. hxluajit has no such hook, so each
 * `add_callback` here pushes a per-name C closure whose upvalue carries
 * the callback name; the closure forwards into `psychlua.CallbackHandler.call`
 * which preserves Psych's existing global + per-script lookup semantics.
 */
class Lua_helper {
	public static var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var sendErrorsToLua:Bool = false;

	public static function add_callback(L:State, name:String, fn:Dynamic):Bool {
		if (L == null) return false;

		// `fn == null` means "register only as a per-script callback"; the
		// global map is left untouched so that Psych's per-script
		// `FunkinLua.callbacks` map remains the source of truth (used by
		// `addLocalCallback`, etc.).
		if (fn != null) callbacks.set(name, fn);

		// Push the callback name as an upvalue and register a C closure
		// that forwards into our Haxe dispatcher.
		Lua.pushstring(L, name);
		Lua.pushcclosure(L, cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call), 1);
		Lua.setglobal(L, name);
		return true;
	}
}
