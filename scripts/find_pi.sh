#!/bin/bash

if [ -z $1 ]; then
	echo "needs ip address as parameter"
	exit 1
fi

echo "Searching for robo routers ..."

# this assumes that port 7 and 37 are open on the pi
nmap -Pn -p7,37 $1/24 -oG - | awk '/open/{print "  " $2}'