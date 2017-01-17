local imagehandler = require "image.handler"
local cjson = require "cjson"

local method = ngx.var.request_method
local path = ngx.var.uri

ngx.req.read_body()

if method == "GET" then
    res = ngx.location.capture(
            "/r1" .. path
    )
    if res.status ~= 200 then
        ngx.log(ngx.WARN, "request [" .. path .. "] error :" .. res.status)
        ngx.exit(res.status)
    else
        local mime = res.header["Content-Type"]
        if mime == "image/gif" then
            data = res.body
        else
            if not mime then
                mime = "image/jpeg"
            end

            local handler = imagehandler:new()
            local data, err = handler:doimg(ngx.req.get_uri_args(), res.body, mime)
        end

        if not data then
            ngx.log(ngx.WARN, "do img fail: " .. err)
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        else
            ngx.header.content_type = mime
            ngx.header["Content-Length"] = data:len()
            ngx.say(data)
            ngx.exit(ngx.HTTP_OK)
        end
    end
else
   ngx.exit(ngx.HTTP_NOT_ALLOWED)
end
      
   
