
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
        local mime = res.header.content_type
        local data = res.body
        if not mime then
            mime = "video/mp4"
        end
        ngx.header.content_type = mime
        ngx.header.content_length = data:len()
        ngx.say(data)
        ngx.exit(ngx.HTTP_OK)
   end
else
    ngx.exit(ngx.HTTP_NOT_ALLOWED)
end
