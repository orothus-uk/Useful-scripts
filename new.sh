#!/bin/bash

# Install usefull apps
cd /home/oro/Downloads
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome*.deb
apt -y install mate-desktop-environment-extras evolution
