#!/bin/bash

# This script will run 2 instances of Bonnie
# and also a wget of ubuntu minimal

# Checksum info
# Our download files are here
# http://ftp.belnet.be/packages/damnsmalllinux/current/
# File: http://ftp.belnet.be/packages/damnsmalllinux/current/kernel/linux-2.4.31.tar.gz
# md5 checksum: ea3f99fc82617886059d58d0644dab26

DOWNLOAD="http://ftp.belnet.be/packages/damnsmalllinux/current/kernel/linux-2.4.31.tar.gz"
TIMESTAMP=`date +20%y%m%d-%H%M`
COMMAND="nohup /usr/sbin/bonnie -d /home/stan -n 256 -u stan -r 1024 "
CORRECT_CHECKSUM="ea3f99fc82617886059d58d0644dab26"
FILE="linux-2.4.31.tar.gz"

cd /home/stan
rm -rf /home/stan/*
sudo $COMMAND > /home/stan/$TIMESTAMP.bonnie-1 &
#sudo $COMMAND > /home/stan/$TIMESTAMP.bonnie-2 &
wget $DOWNLOAD
DL_CHECKSUM=`md5sum $FILE | cut -f 1 -d " "`

if [ $DL_CHECKSUM != $CORRECT_CHECKSUM ] ; then
	touch "FAIL_MD5.$TIMESTAMP"	
fi
