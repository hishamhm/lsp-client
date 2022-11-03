local unistd = require("posix.unistd")
local wait = require("posix.sys.wait")
local json = require("cjson")

local record lsp
   record Server
      new: function(lang: string, pathname: string, args: {string}): Server, string
      send: function(Server, cmd: {string:any}): integer
      recv: function(Server): {string:any}, string
      done: function(Server)

      initialize: function(Server, params: {string:any})

      lang: string
      stdin: integer
      stdout: integer
      stderr: integer
      msgid: integer
      pid: integer
   end
end

function lsp.Server.new(lang: string, pathname: string, args: {string}): lsp.Server, string
   local self: lsp.Server = {}

   local stdin_r, stdin_w = unistd.pipe()
   if stdin_w is string then
      return nil, "failed creating pipe: " .. stdin_w
   end

   local stdout_r, stdout_w = unistd.pipe()
   if stdout_w is string then
      return nil, "failed creating pipe: " .. stdout_w
   end

   local stderr_r, stderr_w = unistd.pipe()
   if stderr_w is string then
      return nil, "failed creating pipe: " .. stderr_w
   end
   
   local pid = unistd.fork()
   if pid == 0 then
      unistd.close(stdin_w)
      unistd.close(stdout_r)
      unistd.close(stderr_r)
      
      unistd.dup2(stdin_r, unistd.STDIN_FILENO)
      unistd.dup2(stdout_w, unistd.STDOUT_FILENO)
      unistd.dup2(stderr_w, unistd.STDERR_FILENO)
      
      unistd.exec(pathname, args or {})
   end
   
   unistd.close(stdin_r)
   unistd.close(stdout_w)
   unistd.close(stderr_w)

   self.lang = lang   
   self.stdin = stdin_w
   self.stdout = stdout_r
   self.stderr = stderr_r
   self.pid = pid
   self.msgid = 1
   
   return setmetatable(self, { __index = lsp.Server })
end

function lsp.Server:send(cmd: {string:any}): integer
   local id = self.msgid
   self.msgid = self.msgid + 1

   cmd.jsonrpc = "2.0"
   cmd.id = id
   local j = json.encode(cmd)
   local out: {string} = {}
   table.insert(out, "Content-Length: " .. #j)
   table.insert(out, "")
   table.insert(out, j)
   unistd.write(self.stdin, table.concat(out, "\r\n"))
   
   return id
end

function lsp.Server:recv(): {string:any}, string
   local msg, err = unistd.read(self.stdout, 50)
   if #msg > 0 then
      local l, rest = msg:match("^[Cc]ontent%-[Ll]ength: ?(%d+)\r\n\r\n(.*)$")
      local len = math.tointeger(tonumber(l))
      if len > #rest then
         local more = unistd.read(self.stdout, len - #rest)
         if more then
            msg = rest .. more
         end
      else
         msg = rest
      end
      return json.decode(msg)
   else
      return nil, err
   end
end

local function recv_until(self: lsp.Server, id: integer): {string:any}
   local brk = false
   while not brk do
      local r = self:recv()
      if r.id == id then
         return r
      end
   end
end

function lsp.Server:initialize(params: {string:any})
   params.processId = unistd.getpid()
   if not params.rootUri then
      params.rootUri = json.null
   end
   local i = self:send({ method = "initialize", params = params })
   recv_until(self, i)
   i = self:send({ method = "initialized", params = {} })
   recv_until(self, i)
end

function lsp.Server:done()
   unistd.close(self.stdin)
   unistd.close(self.stdout)
   wait.wait(self.pid)
end

return lsp
