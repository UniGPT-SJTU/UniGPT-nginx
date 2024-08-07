local mysql = require "resty.mysql"
local cjson = require "cjson"

-- 从 cookie 中获取 token
local cookie = ngx.var.http_cookie
local token_pattern = "token=([^;]+)"
local token = cookie:match(token_pattern)  -- 使用模式匹配从 cookie 中解析 token

if not token then
    ngx.log(ngx.ERR, "Token not found in cookies")
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say(cjson.encode({ success = false, message = "Unauthorized" }))
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

ngx.log(ngx.INFO, "Token: ", token)

-- 连接到 MySQL 数据库
local db, err = mysql:new()
if not db then
    ngx.log(ngx.ERR, "Failed to instantiate MySQL: ", err)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(cjson.encode({ success = false, message = "Internal Server Error" }))
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

db:set_timeout(1000)  -- 设置超时时间为 1 秒

local ok, err, errcode, sqlstate = db:connect(db_config)

if not ok then
    ngx.log(ngx.ERR, "Failed to connect to MySQL: ", err, ": ", errcode, " ", sqlstate)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(cjson.encode({ success = false, message = "Internal Server Error" }))
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- 查询 token 对应的 user_id 和 is_admin
local res, err, errcode, sqlstate = db:query("SELECT user_id, is_admin FROM auth WHERE token = " .. ngx.quote_sql_str(token))
if not res then
    ngx.log(ngx.ERR, "Bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(cjson.encode({ success = false, message = "Internal Server Error" }))
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

if #res == 0 then
    ngx.log(ngx.ERR, "Token not found in database")
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say(cjson.encode({ success = false, message = "Unauthorized" }))
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local user_id = res[1].user_id
local is_admin = res[1].is_admin

-- 返回 JSON 响应
ngx.status = ngx.HTTP_OK
ngx.header["Content-Type"] = "application/json"
ngx.say(cjson.encode({ id = user_id, admin = is_admin }))

-- 关闭 MySQL 连接
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR, "Failed to set keepalive: ", err)
    return
end
