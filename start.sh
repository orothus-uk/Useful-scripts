### Create the 32bit EFI boot loader
mkdir ~/boot32
cd ~/boot32
apt -y install git bison libopts25 libselinux1-dev autogen \
  m4 autoconf help2man libopts25-dev flex libfont-freetype-perl \
  automake autotools-dev libfreetype6-dev texinfo
git clone git://git.savannah.gnu.org/grub.git
cd grub
./autogen.sh
./configure --with-platform=efi --target=i386 --program-prefix=''
make
cd grub-core
../grub-mkimage -d . -o bootia32.efi -O i386-efi -p /boot/grub \
  ntfs hfs appleldr boot cat efi_gop efi_uga elf fat hfsplus iso9660 linux keylayouts \
  memdisk minicmd part_apple ext2 extcmd xfs xnu part_bsd part_gpt search search_fs_file \
  chain btrfs loadbios loadenv lvm minix minix2 reiserfs memrw mmap msdospart scsi loopback \
  normal configfile gzio all_video efi_gop efi_uga gfxterm gettext echo boot chain eval
# Store bootia32.efi in home dir to be copied later
mv ~/boot32/grub/grub-core/bootia32.efi ~

### Customize the LiveCD - based on https://help.ubuntu.com/community/LiveCDCustomization
# Install required tools
apt -y install squashfs-tools genisoimage

# Obtain 16.04.2 Desktop 64-bit ISO and extract content to work with
mkdir ~/livecdwip
cd ~/livecdwip
wget http://releases.ubuntu.com/16.04.2/ubuntu-16.04.2-desktop-amd64.iso
mkdir isomnt
mount -o loop ubuntu-16.04.2-desktop-amd64.iso isomnt
mkdir livecd
rsync --exclude=/casper/filesystem.squashfs -a isomnt/ livecd
unsquashfs isomnt/casper/filesystem.squashfs
mv squashfs-root systemroot
rmdir isomnt

# Backup specific files and dirs to be restored at cleanup
cp -a systemroot/etc/hosts systemroot/etc/hosts.orig
cp -a systemroot/root systemroot/root.orig
cp -a systemroot/tmp systemroot/tmp.orig

# Setup chroot environment
mount --bind /run/ systemroot/run
mount --bind /dev/ systemroot/dev
cp /etc/hosts systemroot/etc/

# chroot - change root to become systemroot
chroot systemroot
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
export HOME=/root
export LC_ALL=C

# chroot - download and install packaged kernel 4.10 - from http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10/
cd /tmp
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10/linux-headers-4.10.0-041000-generic_4.10.0-041000.201702191831_amd64.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10/linux-headers-4.10.0-041000_4.10.0-041000.201702191831_all.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10/linux-image-4.10.0-041000-generic_4.10.0-041000.201702191831_amd64.deb
dpkg -i *.deb

# chroot - remove previous kernel resources
apt -y purge linux-image-4.8.0-36-generic
apt -y purge linux-headers-4.8.0-36-generic
apt -y purge linux-headers-4.8.0-36
apt -y autoremove

# clean, exit chroot, and restore previously backed up files/dir
umount /proc
umount /sys
umount /dev/pts
exit
umount systemroot/run
umount systemroot/dev
mv systemroot/etc/hosts.orig systemroot/etc/hosts
rm -fr systemroot/root
mv systemroot/root.orig  systemroot/root
rm -fr systemroot/tmp
mv systemroot/tmp.orig systemroot/tmp

# install Broadcom 43340 wireless adapter config file
# file is available on a running x205ta system in /sys/firmware/efi/efivars/nvram-74b00bd9-805a-4d61-b51f-43268123d113
wget http://lopaka.github.io/files/instructions/brcmfmac43340-sdio.txt -O systemroot/lib/firmware/brcm/brcmfmac43340-sdio.txt

# Prep for ISO creation
chmod +w livecd/casper/filesystem.manifest
chroot systemroot dpkg-query -W --showformat='${Package} ${Version}\n' > livecd/casper/filesystem.manifest
cp livecd/casper/filesystem.manifest livecd/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' livecd/casper/filesystem.manifest-desktop
sed -i '/casper/d' livecd/casper/filesystem.manifest-desktop
# Move the bootia32.efi file previously created
mv ~/bootia32.efi livecd/EFI/BOOT/
mksquashfs systemroot livecd/casper/filesystem.squashfs
echo $(du -sx --block-size=1 systemroot | cut -f1) > livecd/casper/filesystem.size
# Overwrite livecd files to use new kernel and wireless adapter
cp systemroot/boot/vmlinuz-4.10.0-041000-generic livecd/casper/vmlinuz.efi
mkdir initrd
cd initrd
lzma -dc -S .lz ../livecd/casper/initrd.lz | cpio -imvd --no-absolute-filenames
rm -fr lib/modules/4.8.0-36-generic
cp -a ../systemroot/lib/modules/4.10.0-041000-generic lib/modules/
rm -fr lib/firmware/4.8.0-36-generic
cp -a ../systemroot/lib/firmware/4.10.0-041000-generic lib/firmware/
mkdir -p lib/firmware/brcm
cp -a ../systemroot/lib/firmware/brcm/brcmfmac43340-sdio* lib/firmware/brcm/
find . | cpio --quiet --dereference -o -H newc | lzma -7 > ../livecd/casper/initrd.lz
cd ..

# Edit livecd/README.diskdefines at this point if you wish to change name

# Create ISO
cd livecd
find -type f -print0 | xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt
mkisofs -J -l -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -z -iso-level 4 -c isolinux/isolinux.cat -joliet-long -o ../ubuntu-16.04.2-desktop-amd64-asus-x205ta-4.10-kernel.iso .
cd ..

# Write ISO to USB
# Assuming USB flashdrive assigned to /dev/sdb
# THIS WILL DELETE ALL DATA ON /dev/sdb - make sure you know what you are doing!
sgdisk --zap-all /dev/sdb
sgdisk --new=1:0:0 --typecode=1:ef00 /dev/sdb
mkfs.vfat -F32 /dev/sdb1
mount -t vfat /dev/sdb1 /mnt
7z x ubuntu-16.04.2-desktop-amd64-asus-x205ta-4.10-kernel.iso -o/mnt/
umount /mnt
