#/bin/bash
sudo -i pass ""
apt-get update && apt-get upgrade
cd mashpodder
./mashpodder -v
cd get_iplayer
./get_iplayer <iPlayer.txt
nano iPlayer.txt
