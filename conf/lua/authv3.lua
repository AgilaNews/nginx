local method = ngx.var.request_method
local errors = require "errors"

ngx.req.read_body()
local body = ngx.req.get_body_data()
local body_sign = ""
if not body then
   body = ""
else
   body_sign = ngx.md5(body)
end

local sk = ngx.var.sign_sk or "7intJWbSmtjkrIrb"
if not ngx.var.req_path then
    errors.r500(errors.ERR_INTERNAL, "internal config error")
end

local path = ngx.var.req_path
   
local headers = ngx.req.get_headers()
errors.check_exists(headers, "CONTENT-TYPE")
--errors.check_exists(headers, "DATE")
errors.check_exists(headers, "AUTHORIZATION")
local content_type = headers["CONTENT-TYPE"]
local date = headers["DATE"]
local sign = string.upper(headers["AUTHORIZATION"])

local used_headers = {}
local uris = ngx.req.get_uri_args()
local used_uris = {}
local valid_header = {["X-USER-A"] = true, 
                      ["X-USER-D"] = true, 
                      ["X-DENSITY"] = true, 
                      ["X-SESSION"] = true}

for header, value in pairs(headers) do
    if valid_header[string.upper(header)] == true then
        table.insert(used_headers, header .. ":" .. value)
    end
end

for k, v in pairs(uris) do
    table.insert(used_uris, k .. ":" .. v)
end

local header_param = ""

if #used_headers ~= 0 then
   table.sort(used_headers)
   header_param = table.concat(used_headers, "\n")
end

local uri_param = ""
if #used_uris ~= 0 then
    table.sort(used_uris)
    uri_param = table.concat(used_uris, "\n")
end


local needed =
   string.upper(method .. "\n" ..
   body_sign .. "\n" ..
   content_type .. "\n" ..
   date .. "\n" ..
   header_param .. "\n" ..
   path .. "\n" ..
   uri_param)

local cal_sign = string.upper(ngx.encode_base64(ngx.hmac_sha1(sk, needed)))

if sign ~= cal_sign then
   ngx.log(ngx.WARN, "sig error: [" .. cal_sign .. "~=" .. sign .. "]:" .. needed)
   --errors.r401(errors.ERR_SIGN_ERR, "signature error")
end
return
