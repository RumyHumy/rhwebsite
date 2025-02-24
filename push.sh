#!/bin/bash
# ./push.sh SERV_IP MEDIA_IP
set -x
rsync -avh ~/rhwebsite root@$1:~ --delete --exclude .git
ssh -p 11911 root@$2 'rsync -avh ~/rumyhumymedia/* root@194.87.84.74:~/rhwebsite/src/media --delete'
ssh root@$1 'cd ~/rhwebsite; ./run.sh prod'
