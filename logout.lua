local function set_cookie(name, value, expires)
    local cookie_str = string.format("%s=%s; Path=/; Expires=%s; HttpOnly", name, value, expires)
    ngx.header["Set-Cookie"] = cookie_str
end

-- 获取当前时间并转换为GMT格式
local expires = ngx.cookie_time(ngx.time() - 3600) -- 设置为过去的时间以删除cookie

-- 清除token cookie
set_cookie("token", "", expires)

-- 返回响应
ngx.status = ngx.HTTP_OK
ngx.header["Content-Type"] = "application/json"
ngx.say('{"ok":true, "message":""}')
ngx.exit(ngx.HTTP_OK)
