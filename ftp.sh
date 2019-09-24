#!/bin/bash
HOST=192.168.1.135
USER=oro
PASSWORD=monkeys01/
 
ftp -n -v $HOST << EOF
ascii
user $USER $PASSWD
prompt
cd /home/oro/get_iplayer
mput *.mp4
bye
EOF
