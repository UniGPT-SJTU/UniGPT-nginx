local mysql = require "resty.mysql"
local cjson = require "cjson"
local db_config = require "db_config"

-- 从 cookie 中获取 token
local cookie = ngx.var.http_cookie

if not cookie then
    ngx.log(ngx.ERR, "No cookies found in the request")
    return ngx.exit(401)
end

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

local ok, err, errcode, sqlstate = db:connect(db_config)

if not ok then
    ngx.log(ngx.ERR, "Failed to connect to MySQL: ", err, ": ", errcode, " ", sqlstate)
    return ngx.exit(500)
end

-- 查询 token 对应的 user_id和is_admin
local res, err, errcode, sqlstate = db:query("SELECT user_id, is_admin FROM auth WHERE token = " .. ngx.quote_sql_str(token))
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

-- 如果is_admin为null，则默认为0
if is_admin == nil then
    is_admin = 0
end

-- 将 user_id 添加到请求头部
ngx.req.set_header("X-User-Id", user_id)
ngx.req.set_header("X-Is-Admin", is_admin)

-- log user_id and is_admin
ngx.log(ngx.INFO, "User ID: ", user_id)

-- 关闭 MySQL 连接
local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.log(ngx.ERR, "Failed to set keepalive: ", err)
    return
end

