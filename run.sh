#!/bin/bash

#set -x

cd ~/rhwebsite || { echo "Could't find ~/rhwebsite folder"; exit 1; }

if [ "$1" != "-test" ] && [ "$1" != "-prod" ]; then
	echo "./run.sh -test/-prod"
	echo "-test - self-signed SSL keys"
	echo "-prod - Let's Encrypt signature"
	exit 1
fi

# D E P E N D E N C I E S

all_present=1
hascmd() {
	if command -v "$1" 2>&1 >/dev/null; then
		echo "[run.sh/LOG] '$1' present"
		return 0
	fi
	all_present=0
	echo "[run.sh/ERR] '$1' not present!"
	return 1
}

hascmd "nginx"
hascmd "openssl"
hascmd "crontab"
[ "$1" != "-prod" ] || hascmd "certbot"

if [ "$all_present" = "0" ]; then
	echo "[run.sh/ERR] Some dependencies are not present"
	exit 1
fi

# P L A T F O R M   D E P E N D E N C I E S

echo "[run.sh/LOG] Setuping platform dependencies..."
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
		croncmd="0 0 1 * * certbot renew | tee ~/.certbot-renew-log # [RH-CERT-RENEW]"
		$sudo certbot certonly --webroot -w $static_dir -d rumyhumy.ru
		$sudo crontab -l | grep -v "[RH-CERT-RENEW]" | crontab -
		echo "$croncmd" | crontab -u root
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
$sudo cat ./nginx/templ.rhstatic.conf \
	| sed "s@<SERVER-NAMES>@$server_names@" \
	| sed "s@<SERVER-REDIRECT>@$https_redirect@" \
	| sed "s@<ROOT-DIR>@$static_dir@" \
	| sed "s@<PORT>@$port@" \
	| sed "s@<SSL-PORT>@$ssl_port@" \
	| sed "s@<SSL-CRT-PATH>@$ssl_crt_path@" \
	| sed "s@<SSL-KEY-PATH>@$ssl_key_path@" \
	> ./nginx/rhstatic.conf

# C O P Y I N G   C O N F I G S

echo "[run.sh] Copying configs..."
mkdir "$nginx_dir/conf.d"
$sudo cp ./nginx/nginx.conf "$nginx_dir/nginx.conf"
$sudo cp ./nginx/rhstatic.conf "$nginx_dir/conf.d/rhstatic.conf"

# S T A R T U P
echo "[run.sh] Les go..."
echo "[run.sh] Preparing SSL certificate & key..."
echo "[run.sh] Here comes the NGINX..."
$sudo nginx -s quit
sleep 1
$sudo nginx
