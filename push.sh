#!/bin/bash
# ./push.sh MODE SERV_IP MEDIA_IP

if [ "$1" != "-test" ] && [ "$1" != "-prod" ] && [ "$1" != "-media" ]; then
	echo "./push.sh -test/-prod/-media"
	exit 1
fi

set -x

rsync -avh ~/rhwebsite root@$2:~ --delete \
	--exclude .git \
	--exclude sync.sh \
	--exclude push.sh \
	--exclude README.md

#ssh -p 11911 root@$3 "rsync -avh ~/rumyhumymedia/* root@$2:~/rhwebsite/src/media --delete"

ssh root@$2 "~/rhwebsite/run.sh $1"
