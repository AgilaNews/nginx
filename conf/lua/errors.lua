local cjson = require "cjson"
local _M = {
   OK = 0,
   ERR_BODY = 40001,
   ERR_BODY_FORAMT = 40002,
   ERR_HEADER = 40002,

   ERR_SIGN_ERR = 40101,

   ERR_INTERAL = 50000,
}

function _M.check_exists(tb, key)
   if not tb[key] then
      _M.r400(_M.ERR_BODY, 
        string.format("'%s' non exists", key))
   end
end

function _M.r400(code, msg)
   ngx.status = ngx.HTTP_BAD_REQUEST
   
   ngx.print(cjson.encode({
                   code = code,
                   message = msg
   }))
   return ngx.exit(ngx.HTTP_OK)
end

function _M.r401(code, msg)
   ngx.status = ngx.HTTP_UNAUTHORIZED
   
   ngx.print(cjson.encode({
                   code = code,
                   message = msg
   }))
   return ngx.exit(ngx.HTTP_OK)
end

function _M.r500(code, msg)
   ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
   
   ngx.print(cjson.encode({
                   code = ERR_BODY,
                   message = msg
   }))
   return ngx.exit(ngx.HTTP_OK)
end


return _M
