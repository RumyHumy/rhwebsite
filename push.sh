#!/bin/bash
if [ -z $1 ] || [ -z user ] || [ -z ip ] || [ -z port ]; then
	echo "user= ip= port= ./push.sh -local/-prod"
	echo "user= ip= port= - ssh server credentials"
	echo "Access with key!"
	exit
fi

rsync -avz -e "ssh -p $port" ~/rhwebsite $user@$ip:~/rhwebsite --exclude ~/rhwebsite/src/res
ssh -p $port $user@$ip "mkdir $HOME/rhres; ln -s $HOME/rhres $HOME/rhwebsite/src/res; cd ~/rhwebsite; ./run.sh $1"
