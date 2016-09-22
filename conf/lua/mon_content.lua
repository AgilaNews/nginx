local method = ngx.var.request_method
local cjson = require "cjson"
local errors = require "errors"
local uris = ngx.req.get_uri_args()

ngx.req.read_body()

if method == "POST" then
   local headers = ngx.req.get_headers()
   ngx.ctx.messages = {}
   local body = ngx.req.get_body_data()
   local args = nil

   if body then
      ret, args = pcall(cjson.decode, body)
   end

   if not ret then
      return errors.r400(errors.ERR_BODY_FORMAT, "json decode error")
   end

   if not headers["X-USER-D"] then
      return errors.r400(errors.ERR_HEADER, "not device id found")
   end
      
   args["did"] = headers["X-USER-D"]
   args["uid"] = headers["X-USER-A"] or ""
   args["density"] = headers["X-DENSITY"] or ""
   args["ua"] = headers["USER-AGENT"] or ""
   
   for k, v in pairs(uris) do
       args[k] = v
   end

   table.insert(ngx.ctx.messages, args)

   ngx.say(cjson.encode({code = 0, message = "ok"}))
   return
else
   ngx.exit(ngx.HTTP_NOT_ALLOWED)
   return
end
