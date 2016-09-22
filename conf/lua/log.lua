local logger = require "logger"
local cjson = require "cjson"
local category = ngx.var.logger_category

if not logger.initted() then
    local ok, err = logger.init {
        host = ngx.var.logger_host or "0.0.0.0",
        port = ngx.var.logger_port or 7070,
        flush_limit = ngx.var.logger_flush_limit or 1024 * 1024,
        drop_limit = ngx.var.logger_drop_limit or 1024 * 1024 * 1024,
        timeout = 3000, -- timeout 3 s
        periodic_flush = 60, -- 1 min
        debug = false,
    }

    if not ok then
        ngx.log(ngx.ERR, "failed to init logger", err)
        return
    end
end

if ngx.ctx.messages then
    for i, item in pairs(ngx.ctx.messages) do
       local bytes, err = logger.log(category, cjson.encode(item))
       if err then
          ngx.log(ngx.ERR, "failed to log message: ", err)
          return
       end
    end
end
