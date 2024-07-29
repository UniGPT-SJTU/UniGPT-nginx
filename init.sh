#!/bin/sh

mkdir -p /var/log/nginx
service openresty restart
mysql --defaults-file=.my.cnf
