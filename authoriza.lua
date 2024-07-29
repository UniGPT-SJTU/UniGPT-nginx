local mysql = require "resty.mysql"
local cjson = require "cjson"

-- 从 cookie 中获取 token
local cookie = ngx.var.http_cookie
local token_pattern = "token=([^;]+)"
local token = cookie:match(token_pattern)  -- 使用模式匹配从 cookie 中解析 token

if not token then
    ngx.log(ngx.ERR, "Token not found in cookies")
    return ngx.exit(401)
end

ngx.log(ngx.INFO, "Token: ", token)

-- 连接到 MySQL 数据库
local db, err = mysql:new()
if not db then
    ngx.log(ngx.ERR, "Failed to instantiate MySQL: ", err)
    return ngx.exit(500)
end

db:set_timeout(1000)  -- 设置超时时间为 1 秒

local ok, err, errcode, sqlstate = db:connect{
    host = "123.60.187.205",
    port = 3310,
    database = "unigpt_auth",
    user = "nginx",
    password = "Kiwi339bleavescreeper",
    max_packet_size = 1024 * 1024,
}

if not ok then
    ngx.log(ngx.ERR, "Failed to connect to MySQL: ", err, ": ", errcode, " ", sqlstate)
    return ngx.exit(500)
end

-- 查询 token 对应的 user_id
local res, err, errcode, sqlstate = db:query("SELECT user_id FROM auth WHERE token = " .. ngx.quote_sql_str(token))
if not res then
    ngx.log(ngx.ERR, "Bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    return ngx.exit(500)
end

if #res == 0 then
    ngx.log(ngx.ERR, "Token not found in database")
    return ngx.exit(401)
end

local user_id = res[1].user_id
local is_admin = res[1].is_admin

-- 将 user_id 添加到请求头部
ngx.req.set_header("X-User-Id", user_id)
ngx.req.set_header("X-Is-Admin", is_admin)

-- 关闭 MySQL 连接
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR, "Failed to set keepalive: ", err)
    return
end

