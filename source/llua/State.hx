package llua;

// Compatibility typedef so legacy `:State` annotations continue to work
// against hxluajit's raw pointer-typed API.
typedef State = cpp.RawPointer<hxluajit.Types.Lua_State>;
