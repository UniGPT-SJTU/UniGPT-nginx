FROM ubuntu:22.04
LABEL author="kiwi<qiweic10.sjtu.edu.cn>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg ca-certificates lsb-release \
    build-essential \
    libssl-dev \
    luarocks \
    libmysqlclient-dev

# Install OpenResty
RUN wget -O - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/openresty.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/openresty.list > /dev/null
RUN apt-get update && apt-get install -y openresty git
RUN apt install -y mysql-client

# Install resty.rsa library
RUN luarocks install lua-resty-rsa
RUN luarocks install lua-resty-mysql
RUN luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql
RUN luarocks install uuid
RUN luarocks install lua-resty-http
RUN luarocks install luasocket
RUN luarocks install luasec
RUN luarocks install dkjson
RUN update-ca-certificates

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
# copy the authorize lua script
COPY authoriza.lua /usr/local/openresty/nginx/conf/lua/authorize.lua
COPY jaccountLogin.lua /usr/local/openresty/nginx/conf/lua/jaccountLogin.lua
COPY logout.lua /usr/local/openresty/nginx/conf/lua/logout.lua
COPY getUserId.lua /usr/local/openresty/nginx/conf/lua/getUserId.lua
COPY authorizaWithId.lua /usr/local/openresty/nginx/conf/lua/authorizaWithId.lua
COPY authorizaOnlyAdmin.lua /usr/local/openresty/nginx/conf/lua/authorizaOnlyAdmin.lua
COPY db_config.lua /usr/local/openresty/lualib/db_config.lua
# copy the init script
COPY init.sh /init.sh
COPY .my.cnf /.my.cnf


# ENV CLIENT_ID="ov3SLrO4HyZSELxcHiqS"
# ENV CLIENT_SECRET="B9919DDA3BD9FBF7ADB9F84F67920D8CB6528620B9586D1C"
# ENV REDIRECT_URI="http://123.60.187.205:3000/login"

EXPOSE 8081

# execute the init script and hang the container up
CMD /bin/sh init.sh && tail -f /dev/null
# CMD bash
