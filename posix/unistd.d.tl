local record unistd
   STDIN_FILENO: integer
   STDOUT_FILENO: integer
   STDERR_FILENO: integer

   close: function(fd: integer): integer, string, integer
   dup2: function(fd: integer, newfd: integer): integer, string, integer
   exec: function(path: string, argt: {string}): nil, string, integer
   fork: function(): integer, string, integer
   getpid: function(): integer
   pipe: function(): (integer, (integer|string), integer)
   read: function(fd: integer, n: integer): string, string, integer
   write: function(fd: integer, buf: string): integer, string, integer
end

return unistd