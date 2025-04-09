#!/bin/bash
# Additive synchronization for src/res with server
# ./res.sh USER IP PORT
rsync -av -e "ssh -p $3" --ignore-existing ~/rhwebsite/src/res/* $1@$2:~/rhres
ssh -p $3 $1@$2 "rsync avz ~/rhres ~/rhres.bak"
