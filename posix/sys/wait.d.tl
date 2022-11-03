local record wait
   WNOHANG: integer
   WUNTRACED: integer

   wait: function(pid: integer, options: integer): integer, string, integer
end

return wait
