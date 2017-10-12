#!/bin/bash

# Download firmware file and install it
wget http://lopaka.github.io/files/instructions/BCM43341B0.hcd -O /lib/firmware/brcm/BCM43341B0.hcd

# Create systemd service file
cat >/etc/systemd/system/btattach.service <<EOL
[Unit]
Description=Btattach
[Service]
Type=simple
ExecStart=/usr/bin/btattach --bredr /dev/ttyS1 -P bcm
ExecStop=/usr/bin/killall btattach
[Install]
WantedBy=multi-user.target
EOL

# Enable service
systemctl enable btattach

# Required lib and packages not installed by default
apt -y install git libssl-dev

# Retrieve the Linux kernel source tree fork - will take some time
git clone https://github.com/plbossart/sound.git -b experimental/codecs
cd sound

# Obtain the kernel config already done - otherwise you will have to run
# 'make localmodconfig', 'make menuconfig', and answer questions.
# Original file from:
#   ftp://x205ta.myftp.org:1337/kernel/.config
wget http://lopaka.github.io/files/instructions/x205ta.config -O .config

# reverse patch the commit that causes the keyboard to malfunction
git diff 3ae02c1^ 3ae02c1 | patch -Rp1

# Add patch that attempts to fix non-functioning FN-keys
# Original file from:
#   https://raw.githubusercontent.com/harryharryharry/x205ta-patches/master/fn-brightness-hack.patch
wget http://lopaka.github.io/files/instructions/fn-brightness-hack.patch
patch -p1 < fn-brightness-hack.patch

# Build - will take some time
make -j6

# Install modules
make modules_install

# Install kernel to the boot dir
export KERNELRELEASE=$(<include/config/kernel.release)
cp -va arch/x86/boot/bzImage /boot/vmlinuz-$KERNELRELEASE

# Build initramfs
update-initramfs -c -k $KERNELRELEASE

# Rebuild /boot/grub/grub.cfg
update-grub

# Obtain HiFi.conf and install it at /usr/share/alsa/ucm/chtrt5645/
# Original files from:
#   https://raw.githubusercontent.com/plbossart/UCM/master/chtrt5645/HiFi.conf
#   https://raw.githubusercontent.com/plbossart/UCM/master/chtrt5645/chtrt5645.conf
mkdir -p /usr/share/alsa/ucm/chtrt5645
wget http://lopaka.github.io/files/instructions/HiFi.conf -O /usr/share/alsa/ucm/chtrt5645/HiFi.conf
wget http://lopaka.github.io/files/instructions/chtrt5645.conf -O /usr/share/alsa/ucm/chtrt5645/chtrt5645.conf

# Install audio packages
apt -y install pulseaudio alsa-base alsa-utils pavucontrol

# Install usefull apps
cd /home/oro/Downloads
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome*.deb
apt -y install mate-desktop-environment-extras

# Reboot and use GUI to set default output - Sound Settings...
shutdown -r now
