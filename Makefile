# Description: Makefile for building and running the nginx container
all:
	@echo "Please choose your target!"
	exit 1

# 编译nginx镜像
build:
	@docker build -t uni_nginx .

run:
	@docker run --network host -it --name uni_nginx_1 -p 8081:8081 uni_nginx bash 

# 清理nginx容器和镜像
clear:
	@docker rm -f uni_nginx_1
	@docker image remove uni_nginx

