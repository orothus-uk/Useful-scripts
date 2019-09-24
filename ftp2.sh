#!/bin/sh
sftp -oPort=2222 oro@192.168.1.135   << 'EOS'
monkeys01/
put -r /home/oro/get_iplayer
bye
EO
