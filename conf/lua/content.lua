local method = ngx.var.request_method
local cjson = require "cjson"
local errors = require "errors"

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
      
   errors.check_exists(args, "sessions")
   for i, session in ipairs(args["sessions"]) do
      errors.check_exists(session, "id")
      errors.check_exists(session, "events")
      
      local session_id = session["id"]
      for i, event in ipairs(session["events"]) do
         local msg = {}
         for k, v in pairs(event) do
            if k == "id" then
               msg["event-id"] = v
               else
                  msg[k] = v
            end
         end
         
         msg["session"] = session_id
         msg["did"] = headers["X-USER-D"]
         msg["uid"] = headers["X-USER-A"] or "unknown"
         msg["density"] = headers["X-DENSITY"] or "unknown"
         table.insert(ngx.ctx.messages, msg)
      end
   end

   ngx.say(cjson.encode({code = 0, message = "ok"}))
   return
else
   ngx.exit(ngx.HTTP_NOT_ALLOWED)
   return
end
