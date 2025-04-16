#!/bin/bash

if [ "$1" != "-test" ] && [ "$1" != "-prod" ]; then
	echo "[...] ./run.sh -test/-prod"
	echo "-test - self-signed SSL keys"
	echo "-prod - Let's Encrypt signature with rumyhumy.ru domain"
	echo "[...]"
	echo "-> port= ssl_port= - custom port setup"
	echo "-> workers= - gunicorn workers, optimal - GPU core count (default 2)"
	exit 1
fi

[ -z $workers] && workers=2

SERVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# P L A T F O R M   D E P E N D E N C I E S

echo "[run.sh] Setuping platform dependencies..."

static_dir=$(pwd)/src
etc_dir=/etc
sudo="sudo"
if [ `echo $PREFIX | grep -o "com.termux"` ]; then 
	etc_dir="$TERMUX__ROOTFS/usr/etc"
	sudo=""
fi
nginx_dir="$etc_dir/nginx"

if [ $(whoami) = "root" ]; then
	echo "[run.sh] Running as root!"
	sudo=""
fi
if [ ! -d "$nginx_dir" ]; then
	echo "[run.sh] NGINX config directory does not exists"
	exit
fi

# D E P E N D E N C I E S

echo "[run.sh] Setuping dependencies..."

all_there=1
hascmd() {
	if command -v "$1" 2>&1 >/dev/null; then
		echo "[run.sh] -> Command '$1' present"
		return 1
	fi
	all_there=0
	echo "[run.sh] -> Command '$1' NOT present!"
	return 0
}

hascmd "nginx"
hascmd "openssl"
hascmd "supervisorctl"
[ "$1" != "-prod" ] || hascmd "crontab"
[ "$1" != "-prod" ] || hascmd "certbot"

has_py_module() {
	if python3 -c "import $1" > /dev/null; then
		echo "[run.sh] -> Python module '$1' present"
		return 1
	fi
	echo "[run.sh] -> Python module '$1' NOT present"
	all_there=0
	return 0
}

has_py_module "uvicorn"
has_py_module "gunicorn"
has_py_module "fastapi"

if [ $all_there = 0 ]; then
	echo "Not all dependencies present."
	exit 1
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
		$sudo certbot certonly --standalone -d rumyhumy.ru
		$sudo crontab -l | grep -v "[RH-CERT-RENEW]" | crontab -
		echo "$croncmd" | crontab -u root
	fi
fi

if [ "$1" = "-test" ]; then
	server_names="localhost"
	[ -z $port ] && port="8080"
	[ -z $ssl_port ] && ssl_port="8443"
	https_redirect="https://localhost:$ssl_port"
	ssl_crt_path="$etc_dir/fakessl/fake.crt"
	ssl_key_path="$etc_dir/fakessl/fake.key"
	if [ ! -d "$etc_dir/fakessl" ]; then
		$sudo mkdir $etc_dir/fakessl
		$sudo openssl genrsa -out $etc_dir/fakessl/fake.key 2048
		$sudo openssl req -new -x509 -key $etc_dir/fakessl/fake.key -out $etc_dir/fakessl/fake.crt -days 365000
	fi
fi

# A P P
# TODO: NGINX as reverse proxy
supervisor_config="""
[program:rhuvicorn]
command=/usr/bin/python3 -m uvicorn --bind 0.0.0.0:8000 main:app
directory=/path/to/your/app
user=$(whoami)
autostart=false
autorestart=false
redirect_stderr=true
"""
echo $supervisor_config > $sudo tee $etc_dir/supervisor/conf.d/rhuvicorn.conf
$sudo supervisorctl update
$sudo supervisorctl start rhuvicorn
echo "supervisorctl stop - to stop the uvicorn server"
#echo "nginx -s quit - to stop the NGINX proxy"
