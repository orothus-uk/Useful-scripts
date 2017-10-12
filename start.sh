

apt-add-repository ppa:ubuntu-mate-dev/xenial-mate
apt-get update
apt-get install mate
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

sudo apt-get update
sudo apt-get install get-iplayer youtube-dl terminator
cd /home/oro/Downloads
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome*.deb
apt-get -f install

git clone https://github.com/get-iplayer/get_iplayer.git
cd /home/oro/Desktop/get_iplayer
chmod 777 get_iplayer
./get_iplayer --prefs-add --output="/home/user/get_iplayer"

cd /home/oro 
git clone https://github.com/chessgriffin/mashpodder.git

# Reboot and use GUI to set default output - Sound Settings...
shutdown -r now


