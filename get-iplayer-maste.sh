#!/bin/bash

git clone https://github.com/get-iplayer/get_iplayer.git
cd get_iplayer
./get_iplayer --prefs-add --output="/home/oro/get-iplayer"
./get_iplayer
./get_iplayer --get Dragons Den

