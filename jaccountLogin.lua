local cjson = require "cjson"
local http = require "resty.http"
local uuid = require("uuid")
local ltn12 = require("ltn12")
local json = require("dkjson")  -- Ensure you have a JSON library like dkjson
local mysql = require "resty.mysql"

local function request_access_token(code)
    local httpc = http.new()

    -- 从环境变量中获取client_id, client_secret和redirect_uri
    local client_id = "ov3SLrO4HyZSELxcHiqS"
    local client_secret = "B9919DDA3BD9FBF7ADB9F84F67920D8CB6528620B9586D1C"
    local redirect_uri = "http://123.60.187.205:3000/login"

    -- 检查REDIRECT_URI是否被正确设置
    if not redirect_uri then
        return nil, "Environment variable REDIRECT_URI is not set"
    end

    -- 检查环境变量是否正确读取
    if not client_id or not client_secret or not redirect_uri then
        ngx.log(ngx.ERR, "Environment variables CLIENT_ID, CLIENT_SECRET, or REDIRECT_URI are not set")
        return nil, "Environment variables not set"
    end

    -- 打印环境变量
    ngx.log(ngx.INFO, "CLIENT_ID: ", client_id)
    ngx.log(ngx.INFO, "CLIENT_SECRET: ", client_secret)
    ngx.log(ngx.INFO, "REDIRECT_URI: ", redirect_uri)

    -- the 202.120.2.109 is jaccount.sjtu.edu.cn but since the DNS is unstable so I choose to use the IP address
    local res, err = httpc:request_uri("http://202.120.2.109/oauth2/token", {
        method = "POST",
        body = ngx.encode_args({
            grant_type = "authorization_code",
            code = code,
            client_id = client_id,
            client_secret = client_secret,
            redirect_uri = redirect_uri
        }),
        headers = {
            ["Authorization"] = "Basic " .. ngx.encode_base64(client_id .. ":" .. client_secret),
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["Accept"] = "*/*"
        }
    })

    -- for debug 
    -- return "01349df7878294d514eb2b035b34ef00"

    if not res then
        ngx.log(ngx.ERR, "Failed to request access token: ", err)
        return nil, "Failed to request access token"
    end

    local response_body = cjson.decode(res.body)
    if not response_body.access_token then
        return nil, "Failed to get access token"
    end

    return response_body.access_token
end

local function get_user_profile(access_token)
    -- 打印access_token
    ngx.log(ngx.INFO, "Access Token: ", access_token)

    local httpc = http.new()

    -- 202.120.35.146 is the IP address of the jaccount.sjtu.edu.cn
    -- since the DNS is unstable so I choose to use the IP address
    local res, err = httpc:request_uri("https://202.120.35.146/v1/me/profile?access_token=" .. access_token, {
        method = "GET",
        headers = {
            ["Accept"] = "*/*"
        },
        ssl_verify = false
    })

    
    if not res then
        ngx.log(ngx.ERR, "Failed to get user profile: ", err)
        return nil, "Failed to get user profile"
    end

    -- 打印res，指定打印的内容和位置
    ngx.log(ngx.INFO, "Response: ", res.body)

    local response_body = cjson.decode(res.body)
    if not response_body.entities or not response_body.entities[1] then
        return nil, "Failed to get user profile"
    end
    
    local user = response_body.entities[1]
    ngx.log(ngx.INFO, "User: ", cjson.encode(user))
    local user_profile = {
        name = user.name,
        account = user.account,
        email = user.email
    }
    
    ngx.log(ngx.INFO, "name: ", user_profile.name)
    ngx.log(ngx.INFO, "account: ", user_profile.account)
    ngx.log(ngx.INFO, "email: ", user_profile.email)

    return user_profile
end

-- Function to send request and get id
local function getUserId(account, name, email)
    -- Encode the query parameters
    local encoded_account = ngx.escape_uri(account)
    local encoded_name = ngx.escape_uri(name)
    local encoded_email = ngx.escape_uri(email)

    -- Construct the query parameters
    local query = string.format("account=%s&name=%s&email=%s", encoded_account, encoded_name, encoded_email)
    local url = "http://123.60.187.205:8082/internal/users?" .. query

    -- Create a new HTTP client instance
    local httpc = http.new()

    -- Log the URL
    ngx.log(ngx.INFO, "URL: ", url)

    -- Send the HTTPS request
    local res, err = httpc:request_uri(url, {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })

    -- Check if the request was successful
    if not res then
        -- Handle error (you can customize this part)
        error("HTTP request failed: " .. tostring(err))
    end

    if res.status == 200 then
        -- Parse the JSON response
        local response_json = require("cjson").decode(res.body)
        -- Return the id from the response
        ngx.log(ngx.INFO, "User ID: ", response_json)
        return response_json
    else
        -- Handle error (you can customize this part)
        error("HTTP request failed with status: " .. tostring(res.status))
    end
end

-- Function to send request and post user info in other service
local function postUser(id, name, base_url)
    -- Encode the query parameters
    local encoded_id = ngx.escape_uri(id)
    local encoded_name = ngx.escape_uri(name)

    -- Construct the query parameters
    -- local query = string.format("account=%s&name=%s&email=%s", encoded_account, encoded_name, encoded_email)
    local query = string.format("id=%s&name=%s", encoded_id, encoded_name)
    local url = base_url .. "?" .. query
    -- local bot_service_url = "http://123.60.187.205:8083/internal/users?" .. query
    -- local chat_service_url = "http://123.60.187.205:8084/internal/users?" .. query
    -- local plugin_service_url = "http://123.60.187.205:8085/internal/users?" .. query

    -- Create a new HTTP client instance
    local httpc = http.new()

    -- Log the URL
    ngx.log(ngx.INFO, "URL: ", url)

    -- Send the HTTPS request
    local res, err = httpc:request_uri(url, {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })

    -- Check if the request was successful
    if not res then
        -- Handle error (you can customize this part)
        error("HTTP request failed: " .. tostring(err))
    end

    if res.status == 200 then
        -- Parse the JSON response
        local response_json = require("cjson").decode(res.body)
        -- Return the id from the response
        return response_json
    else
        -- Handle error (you can customize this part)
        error("HTTP request failed with status: " .. tostring(res.status))
    end
end

local function generate_auth_token(user)
    -- Initialize the UUID library
    uuid.seed()

    -- Generate a UUID
    local auth_token = uuid()

    return auth_token
end

local function update_or_insert_user(user_id, token)
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR, "Failed to instantiate MySQL: ", err)
        return ngx.exit(500)
    end

    db:set_timeout(1000)

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

    local res, err, errcode, sqlstate = db:query("SELECT user_id FROM auth WHERE user_id = " .. ngx.quote_sql_str(user_id))
    if not res then
        ngx.log(ngx.ERR, "Bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
        return ngx.exit(500)
    end

    if #res == 0 then
        local insert_res, insert_err, insert_errcode, insert_sqlstate = db:query("INSERT INTO auth (user_id, token, is_admin) VALUES (" .. ngx.quote_sql_str(user_id) .. ", " .. ngx.quote_sql_str(token) .. ", false)")
        if not insert_res then
            ngx.log(ngx.ERR, "Failed to insert new user: ", insert_err, ": ", insert_errcode, ": ", insert_sqlstate, ".")
            return ngx.exit(500)
        end
    else
        local update_res, update_err, update_errcode, update_sqlstate = db:query("UPDATE auth SET token = " .. ngx.quote_sql_str(token) .. " WHERE user_id = " .. ngx.quote_sql_str(user_id))
        if not update_res then
            ngx.log(ngx.ERR, "Failed to update token: ", update_err, ": ", update_errcode, ": ", update_sqlstate, ".")
            return ngx.exit(500)
        end
    end

    local ok, err = db:set_keepalive(10000, 100)
    if not ok then
        ngx.log(ngx.ERR, "Failed to set keepalive: ", err)
        return
    end
end

local function main()
    ngx.req.read_body()
    local body_data = ngx.req.get_body_data()
    local body = cjson.decode(body_data)
    local code = body.code

    local access_token, err = request_access_token(code)
    if not access_token then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say(cjson.encode({ ok = false, message = err }))
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    local user, err = get_user_profile(access_token)
    if not user then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say(cjson.encode({ ok = false, message = err }))
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    local user_id = getUserId(user.account, user.name, user.email)

    if not user_id then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say(cjson.encode({ ok = false, message = "Failed to get user ID" }))
        return ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end

    -- postUser(user_id, user.name, "http://123.60.187.205:8083/internal/users")
    -- postUser(user_id, user.name, "http://123.60.187.205:8084/internal/users")
    -- postUser(user_id, user.name, "http://123.60.187.205:8085/internal/users")

    local token = generate_auth_token(user)

    update_or_insert_user(user_id, token)

    ngx.header["Set-Cookie"] = "token=" .. token .. "; Path=/; Max-Age=" .. tostring(24 * 60 * 60)

    ngx.status = ngx.HTTP_OK
    ngx.say(cjson.encode({ ok = true, token = token }))
end

main()
