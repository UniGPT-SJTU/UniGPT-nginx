# UniGPT AuthGateway
## 简介
UniGPT-AuthGateway模块的主要功能包括：
- 用户认证：拦截未登录用户的请求
- 请求转发：将经过认证的请求转发到后端对应的微服务

## 技术栈
- Nginx: 作为反向代理服务器，处理HTTP请求
- OpenResty: 基于Nginx的高性能Web平台，支持Lua脚本
- Lua: 用于编写认证的业务逻辑脚本
- MySQL: 用于存储用户的认证信息
- Docker: 用于容器化部署

## 项目结构
- [nginx.conf](nginx.conf): Nginx配置文件，定义了服务器和请求处理规则
- [Dockerfile](Dockerfile): 定义Nginx镜像的构建过程
- [docker-compose.yml](docker-compose.yml): 定义多容器，包括上述的Nginx镜像容器，以及存储用户认证信息的MySQL容器（auth-db）
- [*.lua](): Lua脚本文件，包含具体认证和业务逻辑

## 运行
运行前，你需要保证`前端url`， `后端ip`，`db连接信息`配置正确。
- `前端url`： 修改`nginx.conf`的frontend_url
- `后端ip`：修改`nginx.conf`的backend_ip
- `db连接信息`: 修改`db_config.lua`和`.my.cnf`

使用`docker compose`运行：
```sh
docker compose up nginx auth_db -d 
```

如果运行过程中出现了问题，输入以下命令打印Nginx错误日志：
```sh
docker compose exec nginx cat /var/log/nginx/error.log
```