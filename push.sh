#!/bin/bash
if [ -z $1 ] || [ -z $ssh_user ] || [ -z $ssh_ip ] || [ -z $ssh_port ]; then
	echo "ssh_user= ssh_ip= ssh_port= ./push.sh -local/-prod"
	echo "ssh_user= ssh_ip= ssh_port= - ssh server credentials"
	echo "Access with key!"
	exit
fi

rsync -avz --delete -e "ssh -p $ssh_port" ~/rhwebsite $ssh_user@$ssh_ip:~/rhwebsite --exclude ~/rhwebsite/src/res

ssh -p $ssh_port $ssh_user@$ssh_ip "mkdir ~/rhres; ln -s ~/rhres ~/rhwebsite/src/res; cd ~/rhwebsite; ./run.sh $1"
