local rocks = require "luarocks.loader"
local magick = require "magick"

local _M = {}
local mt = { __index = _M }
local play_img = magick.load_image(ngx.var.play_image)

function _M:new()
    return setmetatable({
    }, mt)
end

function _M:check_w_h(w, h)
end

function _M:p(params, img)
    local iter, err = ngx.re.gmatch(params, "([^=]*)=([^\\|]*)\\|?")
    if not iter then
        return nil, "match pipe pattern error: " .. err
    end

    while true do
        local m, err = iter()
        if err then
            return nil, "pipe iter error"
        end

        if not m then
            break
        end

        local cmd, sub_param = m[1], m[2]
        do
            if not self[cmd] then
                return nil, "unknown subcmd " .. cmd
            end

            local img, err = self[cmd](self, sub_param, img)
            if not img then
                return nil, err
            end
        end
    end

    return img, nil
end

function _M:q(params, img)
   -- sampling -- 
    local quality = tonumber(params) or 100
    img:set_quality(quality)
    return img, nil
end


function _M:numberOrPercent(str, total)
    if not str or str:len() == 0 then
        return 0
    end

    local number = 0

    if str:sub(-1) == 'p' then
        number = (total * tonumber(str:sub(1, -2))) / 100
    else
        number = tonumber(str)
    end

    return number
end

function _M:t(params, img)
   -- thumbnail --
    local m = ngx.re.match(params, "(\\d*)x(\\d*)", "i")
    if m then
        local w = img:get_width()
        local h = img:get_height()
        local tw = self:numberOrPercent(m[1], w)
        local th = self:numberOrPercent(m[2], h)

        img:resize_and_crop(tw, th)
        return img
    end

    return nil, "match thumbnail fails"
end

function _M:c(params, img)
   -- crop --
    local m = ngx.re.match(params, "(\\d*p?)?x(\\d*p?)?(?:@(\\d+p?)x(\\d+)p?)?", "i")
    if m then
        local w = self:numberOrPercent(m[1], img:get_width()) 
        local h = self:numberOrPercent(m[2], img:get_height())
        self:check_w_h(w, h)
        local x = self:numberOrPercent(m[3], img:get_width())
        local y = self:numberOrPercent(m[4], img:get_height())

        img:crop(w, h, x, y)
        return img, nil
    end

    local m = ngx.re.match(params, "(\\d*)x(\\d*)(?:@([\\w+]))", "i")
    if m then
        local w = m[1] and tonumber(m[1]) or img:get_width()
        local h = m[2] and tonumber(m[2]) or img:get_height()
        self:check_w_h(w, h)
        local ow = img:get_width()
        local oh = img:get_height()
        local x, y
        local mode = m[3]

        if mode == "c" then
        end
    end

    return nil, "match crop pattern error"
end


function _M:s(params, img)
   -- scaling --
    local m = ngx.re.match(params, '(\\d*)x(\\d*)(?:_([wh]))?', "i")
    if not m then
        return nil, "scale pattern error"
    end
    
    local w = m[1] and tonumber(m[1]) or img:get_width()
    local h = m[2] and tonumber(m[2]) or img:get_height()
    self:check_w_h(w, h)
    local mode = m[3] or 'w'
    local ow = img:get_width()
    local oh = img:get_height()
    local aw, ah

    if mode == 'w' then
        ah = w * oh / ow
        img:resize(w, ah)
    else
        aw = h * ow / oh
        img:resize(aw, h)
    end

    return img, nil
end

function _M:v(params, img)
   if play_img == nil then
      return nil, "play image not found"
   else
      vm = tonumber(params)
      local p = play_img

      if vm >= 30 then
         p = p:clone()
         p:resize(vm, vm)
      end
      img:composite(p,
                    (img:get_width() - p:get_width()) / 2,
                    (img:get_height() - p:get_height()) / 2,
                    "OverCompositeOp")
      return img, nil
   end   
  
end

function _M:doimg(args, data, mime)
    local img = nil

    if data then
        img, err = magick.load_image_from_blob(data)    
        if not img then
            return nil, err
        end
    end
    img:strip()
    if mime == "image/png" then
        img:set_format("png")
    else
        img:set_format("jpg")
    end

    for k, v in pairs(args) do
        if not self[k] then
            return nil, "unknown cmd" .. k
        end

        img, err = self[k](self, v, img)
        if not img then
            return nil, err
        end
    end

    return img:get_blob(), nil
end

return _M
