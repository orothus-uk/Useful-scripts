#!/bin/bash

git clone https://github.com/get-iplayer/get_iplayer.git
cd /home/oro/Desktop/get_iplayer
./get_iplayer --prefs-add --output="/home/user/get_iplayer"
./get_iplayer
./get_iplayer --get Josh
./get_iplayer --get Dragons Den

