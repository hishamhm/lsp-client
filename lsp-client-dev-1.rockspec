package = "lsp-client"
version = "dev-1"
source = {
   url = "git://github.com/hishamhm/lsp-client"
}
description = {
   summary = "A Lua library written in Teal for implementing Language Server Protocol clients.",
   detailed = [[
A Lua library written in Teal for implementing Language Server Protocol clients.
]],
   homepage = "github.com/hishamhm/lsp-client",
   license = "MIT"
}
dependencies = {
   "luaposix",
   "lua-cjson",
}
build = {
   type = "builtin",
   modules = {
      lsp = "lsp.lua"
   }
}
