#!/bin/bash

#set -x

cd ~/rhwebsite || { echo "Could't find ~/rhwebsite directory"; exit 1; }

if [ "$1" != "-test" ] && [ "$1" != "-prod" ]; then
	echo "./run.sh -test/-prod [-resproxy <IP>]"
	echo "-test - self-signed SSL keys"
	echo "-prod - let's encrypt signature with rumyhumy.ru domain"
	echo "-resproxy <IP> - use proxy at 8080 for resources at /res URI"
	exit 1
fi

# D E P E N D E N C I E S

all_present=0
hascmd() {
	if command -v "$1" 2>&1 >/dev/null; then
		echo "[run.sh/LOG] '$1' present"
		return 1
	fi
	all_present=1
	echo "[run.sh/ERR] '$1' not present!"
	return 0
}

all_present=1
hascmd "nginx"
hascmd "openssl"
[ "$1" = "-prod" ] && hascmd "crontab"
[ "$1" = "-prod" ] && hascmd "certbot"

if [ "$all_present" = "0" ]; then
	echo "[run.sh/ERR] Some dependencies are not present"
	exit 1
fi

# P L A T F O R M   D E P E N D E N C I E S

echo "[run.sh/LOG] Setuping platform dependencies..."
static_dir=$(pwd)/src
etc_dir=/etc
nginx_dir=/etc/nginx
sudo=""; hascmd "sudo" || sudo="sudo"
if [ `echo $PREFIX | grep -o "com.termux"` ]; then 
	etc_dir="/data/data/com.termux/files/usr/etc"
	nginx_dir="$etc_dir/nginx"
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
$sudo sed -E ./nginx/templ.nginx.conf \
	-e "s@<NGINX-DIR>@$nginx_dir@" \
	> ./nginx/nginx.conf
$sudo sed -E ./nginx/templ.rhstatic.conf \
	-e "s@<NGINX-DIR>@$nginx_dir@" \
	-e "s@<SERVER-NAMES>@$server_names@" \
	-e "s@<SERVER-REDIRECT>@$https_redirect@" \
	-e "s@<ROOT-DIR>@$static_dir@" \
	-e "s@<PORT>@$port@" \
	-e "s@<SSL-PORT>@$ssl_port@" \
	-e "s@<SSL-CRT-PATH>@$ssl_crt_path@" \
	-e "s@<SSL-KEY-PATH>@$ssl_key_path@" \
	> ./nginx/rhstatic.conf
if [ "$2" = "-resproxy" ]; then
	$sudo sed -E ./nginx/templ.rhres.conf \
		-e "s@<RES-IP>@$3@" \
		-e "s@<RES-PORT>@$4@" \
		> ./nginx/rhres.conf
else
	echo "" > ./nginx/rhres.conf
fi

# C O P Y I N G   C O N F I G S

echo "[run.sh] Copying configs..."
mkdir "$nginx_dir/conf.d"
$sudo rm "$nginx_dir/nginx.conf"
$sudo rm "$nginx_dir/conf.d/rhres.conf"
$sudo rm "$nginx_dir/conf.d/rhstatic.conf"
$sudo cp ./nginx/nginx.conf "$nginx_dir/nginx.conf"
$sudo cp ./nginx/rhstatic.conf "$nginx_dir/conf.d/rhstatic.conf"
$sudo cp ./nginx/rhres.conf "$nginx_dir/conf.d/rhres.conf"

# S T A R T U P

echo "[run.sh] Les go..."
echo "[run.sh] Preparing SSL certificate & key..."
echo "[run.sh] Here comes the NGINX..."
$sudo nginx -s quit
sleep 1
$sudo nginx
