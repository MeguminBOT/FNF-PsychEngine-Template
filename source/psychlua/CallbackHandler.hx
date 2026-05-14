#if LUA_ALLOWED
package psychlua;

import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.Types;
import llua.Convert;
import llua.Lua_helper;

/**
 * C-callable dispatcher for every Lua-exposed Haxe function.
 *
 * Each call site registered via `Lua_helper.add_callback` pushes a closure
 * with the callback name as upvalue 1 and points at this function. The
 * dispatcher then looks the name up first in the global
 * `Lua_helper.callbacks` map, then falls back to the `lastCalledScript`'s
 * per-instance `callbacks` map (set by `FunkinLua.addLocalCallback`),
 * and finally scans every running script's `callbacks` map for one whose
 * `lua` state pointer matches.
 */
class CallbackHandler {
	public static function call(L:cpp.RawPointer<Lua_State>):Int {
		final fname:String = Lua.tostring(L, Lua.upvalueindex(1));

		try {
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			// Local functions have the lowest priority -- only loop through
			// scripts when no global callback owns the name.
			if (cbf == null) {
				final last:FunkinLua = FunkinLua.lastCalledScript;
				if (last == null || last.lua != L) {
					for (script in PlayState.instance.luaArray)
						if (script != FunkinLua.lastCalledScript && script != null && script.lua == L) {
							cbf = script.callbacks.get(fname);
							break;
						}
				} else
					cbf = last.callbacks.get(fname);
			}

			if (cbf == null)
				return 0;

			final nparams:Int = Lua.gettop(L);
			final args:Array<Dynamic> = [];

			for (i in 0...nparams)
				args[i] = Convert.fromLua(L, i + 1);

			final ret:Dynamic = Reflect.callMethod(null, cbf, args);

			if (ret != null) {
				Convert.toLua(L, ret);
				return 1;
			}
		} catch (e:haxe.Exception) {
			if (Lua_helper.sendErrorsToLua) {
				LuaL.error(L, '%s', 'CALLBACK ERROR! ${e.details()}');
				return 0;
			}
			throw e;
		}
		return 0;
	}
}
#end
