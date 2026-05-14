package llua;

// Re-export hxluajit's Lua bindings under the legacy `llua` package
// so existing `import llua.Lua;` usages keep compiling.
typedef Lua = hxluajit.Lua;
