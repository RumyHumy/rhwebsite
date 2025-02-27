#!/bin/bash

cd ~/rhwebsite || { echo "Could't find ~/rhwebsite folder"; exit 1; }

if [ "$1" != "-test" ] && [ "$1" != "-prod" ]; then
	echo "./run.sh -test/-prod/-media"
	echo "-test - runs baker"
	echo "-prod - expecting that pages are baked"
	echo "-media - media server"
	exit 1
fi

#set -x

[ $? != 0 ] && exit 1

# P L A T F O R M   D E P E N D E N C I E S

echo "[run.sh] Setuping platform dependencies..."
static_dir=$(pwd)/src
etc_dir=/etc
nginx_dir=/etc/nginx
sudo="sudo"
if [ `echo $PREFIX | grep -o "com.termux"` ]; then 
	etc_dir="/data/data/com.termux/files/usr/etc"
	nginx_dir="$etc_dir/nginx"
	sudo=""
fi
if [ ! -d "$nginx_dir" ]; then
	echo "NGINX config directory does not exists"
	exit
fi

# P R O D / T E S T   M O D E S

if [ "$1" = "-prod" ]; then
	server_names="rumyhumy.ru"
	https_redirect="https://rumyhumy.ru"
	port="80"
	ssl_port="443"
	ssl_path="$etc_dir/letsencrypt/live"
	ssl_crt_path="$ssl_path/rumyhumy.ru/fullchain.pem"
	ssl_key_path="$ssl_path/rumyhumy.ru/privkey.pem"
	if [ ! -d "$ssl_path" ]; then
		$sudo certbot certonly --webroot -w $static_dir -d rumyhumy.ru
		echo "Add '0 0 1 * * /usr/bin/certbot renew' to crontab"
		echo "Enter to proceed..."
		read -n 1 -s -r input
		$sudo crontab -e
	fi
fi

if [ "$1" = "-test" ]; then
	server_names="localhost"
	https_redirect="https://localhost:8443"
	port="8080"
	ssl_port="8443"
	ssl_crt_path="$etc_dir/fakessl/fake.crt"
	ssl_key_path="$etc_dir/fakessl/fake.key"
	if [ ! -d "$etc_dir/fakessl" ]; then
		$sudo mkdir $etc_dir/fakessl
		$sudo openssl genrsa -out $etc_dir/fakessl/fake.key 2048
		$sudo openssl req -new -x509 -key $etc_dir/fakessl/fake.key -out $etc_dir/fakessl/fake.crt -days 365000
	fi
fi

# T E M P L A T I N G   C O N F I G S

echo "[run.sh] Templating configs..."
$sudo cat ./nginx/templ.nginx.conf \
	| sed "s@<NGINX-DIR>@$nginx_dir@" \
	> ./nginx/nginx.conf
$sudo cat ./nginx/templ.rumyhumyorg.conf \
	| sed "s@<SERVER-NAMES>@$server_names@" \
	| sed "s@<SERVER-REDIRECT>@$https_redirect@" \
	| sed "s@<ROOT-DIR>@$static_dir@" \
	| sed "s@<PORT>@$port@" \
	| sed "s@<SSL-PORT>@$ssl_port@" \
	| sed "s@<SSL-CRT-PATH>@$ssl_crt_path@" \
	| sed "s@<SSL-KEY-PATH>@$ssl_key_path@" \
	> ./nginx/rumyhumyorg.conf

# C O P Y I N G   C O N F I G S

echo "[run.sh] Copying configs..."
mkdir "$nginx_dir/conf.d"
$sudo cp ./nginx/nginx.conf "$nginx_dir/nginx.conf"
$sudo cp ./nginx/rumyhumyorg.conf "$nginx_dir/conf.d/rumyhumyorg.conf"

# S T A R T U P

echo "[run.sh] Baking static content..."
./baker/baker.sh

echo "[run.sh] Les go..."
echo "[run.sh] Preparing SSL certificate & key..."
echo "[run.sh] Here comes the NGINX..."
$sudo nginx -s quit
sleep 1
$sudo nginx
