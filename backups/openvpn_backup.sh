#!/bin/bash

HOST=host.com
BACKUP_DIR="/home/stan/Documents/openvpn_backups"
TODAY=`date +%F`
mkdir $BACKUP_DIR/$TODAY
ssh $HOST "cd /usr/local/openvpn_as/etc; sudo  tar -czvf /tmp/$TODAY.tar.gz db as.conf" 
scp -r $HOST:/tmp/$TODAY.tar.gz $BACKUP_DIR/$TODAY
ssh $HOST "sudo rm /tmp/$TODAY.tar.gz"
