#!/bin/bash

echo Set a root password...
passwd

echo Update the repository cache and system...
apt update
apt upgrade --yes

echo Install additional base packages...
apt install --yes --no-install-recommends linux-generic locales keyboard-configuration console-setup

echo Configure packages to customize local and console properties...
dpkg-reconfigure locales tzdata keyboard-configuration console-setup

echo Install required packages...
apt install --yes dosfstools zfs-initramfs zfsutils-linux nano curl efibootmgr

echo Install desktop packages...
apt install --yes ubuntu-desktop
apt install --yes nvidia-driver-535

echo Enable systemd ZFS services...
systemctl enable zfs.target
systemctl enable zfs-import-cache
systemctl enable zfs-mount
systemctl enable zfs-import.target

if [ $VARDEVICEENABLED == yes ]; then
	echo Set zvar to automount...
	zpool set cachefile=/etc/zfs/zpool.cache zvar
fi

echo Rebuild the initramfs...
update-initramfs -c -k all

echo Install and configure ZFSBootMenu...
zfs set org.zfsbootmenu:commandline="quiet loglevel=4" zroot/ROOT

echo Create a vfat filesystem...
mkfs.vfat -F32 "$BOOT_DEVICE1"
if [ $MIRRORENABLED == yes ]; then
	mkfs.vfat -F32 "$BOOT_DEVICE2"
fi

if [ $MIRRORENABLED == yes ]; then
	echo Create backup Bootmenu entry....
	echo Create an fstab entry and mount...
	
	echo "$BOOT_DEVICE2 /boot/efi vfat defaults 0 0" > /etc/fstab

	mkdir -p /boot/efi
	mount /boot/efi

	echo Install ZFSBootMenu...

	mkdir -p /boot/efi/EFI/ZBM
	curl -k -o /boot/efi/EFI/ZBM/VMLINUZ.EFI -L https://get.zfsbootmenu.org/efi
	cp /boot/efi/EFI/ZBM/VMLINUZ.EFI /boot/efi/EFI/ZBM/VMLINUZ-BACKUP.EFI

	echo Configure EFI boot entries...
	mount -t efivarfs efivarfs /sys/firmware/efi/efivars

	efibootmgr -c -d "$BOOT_DISK2" -p "$BOOT_PART2" \
	  -L "ZFSBootMenu (Backup)" \
	  -l '\EFI\ZBM\VMLINUZ-BACKUP.EFI'

	efibootmgr -c -d "$BOOT_DISK2" -p "$BOOT_PART2" \
	  -L "ZFSBootMenu" \
	  -l '\EFI\ZBM\VMLINUZ.EFI'

	echo Umount temporary EFI...
	umount /boot/efi
	
fi

echo Create main Bootmenu entry....

echo Create an fstab entry and mount...

echo "$BOOT_DEVICE1 /boot/efi vfat defaults 0 0" > /etc/fstab

mkdir -p /boot/efi
mount /boot/efi


echo Install ZFSBootMenu...

mkdir -p /boot/efi/EFI/ZBM
curl -k -o /boot/efi/EFI/ZBM/VMLINUZ.EFI -L https://get.zfsbootmenu.org/efi
cp /boot/efi/EFI/ZBM/VMLINUZ.EFI /boot/efi/EFI/ZBM/VMLINUZ-BACKUP.EFI

echo Configure EFI boot entries...
mount -t efivarfs efivarfs /sys/firmware/efi/efivars

efibootmgr -c -d "$BOOT_DISK1" -p "$BOOT_PART1" \
  -L "ZFSBootMenu (Backup)" \
  -l '\EFI\ZBM\VMLINUZ-BACKUP.EFI'

efibootmgr -c -d "$BOOT_DISK1" -p "$BOOT_PART1" \
  -L "ZFSBootMenu" \
  -l '\EFI\ZBM\VMLINUZ.EFI'
  
echo Please preform any final configuration your new installation and then exit to complete...  
  
exit
