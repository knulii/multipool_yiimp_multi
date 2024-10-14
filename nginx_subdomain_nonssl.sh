#!/usr/bin/env bash

#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################
source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

echo '#####################################################
# Source Generated by nginxconfig.io
# Updated by cryptopool.builders for crypto use...
#####################################################

# NGINX Simple DDoS Defense
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_conn conn_limit_per_ip 80;
limit_req zone=req_limit_per_ip burst=80 nodelay;
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:40m rate=5r/s;


sudo mkdir -p /etc/nginx/sites-available/${DomainName}
sudo mkdir -p /etc/nginx/sites-enabled/${DomainName}

server {
	listen 443 ssl;
	listen [::]:443 ssl;

	server_name '"${DomainName}"';
	set $base "/var/www/'"${DomainName}"'/html";
	root $base/web;

	# SSL
	ssl_certificate '"${STORAGE_ROOT}"'/ssl/ssl_certificate.pem;
	ssl_certificate_key '"${STORAGE_ROOT}"'/ssl/ssl_private_key.pem;

	# security
	include cryptopool.builders/security.conf;

	# logging
	access_log '"${STORAGE_ROOT}"'/yiimp/site/log/'"${DomainName}"'.app.access.log;
	error_log '"${STORAGE_ROOT}"'/yiimp/site/log/'"${DomainName}"'.app.error.log warn;

	# index.php
	index index.php;

	# index.php fallback
	location / {
		try_files $uri $uri/ /index.php?$args;
	}
	location @rewrite {
		rewrite ^/(.*)$ /index.php?r=$1;
	}

	# handle .php
	location ~ \.php$ {
		include cryptopool.builders/php_fastcgi.conf;
	}

	# additional config
	include cryptopool.builders/general.conf;
}

# HTTP redirect
server {
	listen 80;
	listen [::]:80;

	server_name .'"${DomainName}"';

	include cryptopool.builders/letsencrypt.conf;

	location / {
		return 301 https://'"${DomainName}"'$request_uri;
	}
}
' | sudo -E tee /etc/nginx/sites-available/${DomainName}.conf >/dev/null 2>&1;

sudo ln -s /etc/nginx/sites-available/${DomainName}.conf /etc/nginx/sites-enabled/${DomainName}.conf;
sudo ln -s $STORAGE_ROOT/yiimp/site/web /var/www/${DomainName}/html;
sudo rm -r /etc/nginx/sites-enabled/${DomainName}

restart_service nginx;
wait $!
restart_service php7.3-fpm;
wait $!
