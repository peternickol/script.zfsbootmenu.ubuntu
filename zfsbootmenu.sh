#!/bin/bash
#
# This script is provided as-is with no warranty or guarantee of fitness for a particular purpose.
# Use this script at your own risk.
#
# The author of this script is not responsible for any damage or loss that may occur as a result of using this script.
#
# peter@peternickol.com
#
HOSTNAME=spc-dual1
export MIRRORENABLED=yes
export VARDEVICEENABLED=yes

export BOOT_DISK1="/dev/sda"
export BOOT_PART1="1"
export BOOT_DEVICE1="${BOOT_DISK1}${BOOT_PART1}"

export BOOT_DISK2="/dev/sdb"
export BOOT_PART2="1"
export BOOT_DEVICE2="${BOOT_DISK2}${BOOT_PART2}"

export POOL_DISK1="/dev/sda"
export POOL_PART1="2"
export POOL_DEVICE1="${POOL_DISK1}${POOL_PART1}"

export POOL_DISK2="/dev/sdb"
export POOL_PART2="2"
export POOL_DEVICE2="${POOL_DISK2}${POOL_PART2}"

export VAR_DISK1="/dev/nvme0n1"
export VAR_PART1="p1"
export VAR_DEVICE1="${VAR_DISK1}${VAR_PART1}"

export VAR_DISK2="/dev/nvme1n1"
export VAR_PART2="p1"
export VAR_DEVICE2="${VAR_DISK2}${VAR_PART2}"

if [ `id -u` -ne 0 ]; then
	echo "This script requires sudo permissions"
	exit 1
fi

if [ $MIRRORENABLED == yes ]; then
	echo MIRRORENABLED = $MIRRORENABLED
fi

if [ $VARDEVICEENABLED == yes ]; then
	echo VARDEVICEENABLED = $VARDEVICEENABLED
fi

echo Source /etc/os-release...
source /etc/os-release
export ID

echo Install helpers... 
apt update
apt install --yes debootstrap gdisk zfsutils-linux

echo Generate /etc/hostid...
zgenhostid -f 0x00bab10c

echo Wipe partitions...
wipefs -a "$POOL_DISK1"
wipefs -a "$POOL_DISK2"
sgdisk --zap-all "$POOL_DISK1"
sgdisk --zap-all "$BOOT_DISK1"

if [ $MIRRORENABLED == yes ]; then
	wipefs -a "$BOOT_DISK1"
	wipefs -a "$BOOT_DISK2"
	sgdisk --zap-all "$POOL_DISK2"
	sgdisk --zap-all "$BOOT_DISK2"
fi

if [ $VARDEVICEENABLED == yes ]; then
	wipefs -a "$VAR_DISK1"
	sgdisk --zap-all "$VAR_DISK1"
	if [ $MIRRORENABLED == yes ]; then
		wipefs -a "$VAR_DISK2"
		sgdisk --zap-all "$VAR_DISK2"
	fi
fi


echo Create EFI boot partition...
sgdisk -n "${BOOT_PART1}:1m:+512m" -t "${BOOT_PART1}:ef00" "$BOOT_DISK1"

if [ $MIRRORENABLED == yes ]; then
	sgdisk -n "${BOOT_PART2}:1m:+512m" -t "${BOOT_PART2}:ef00" "$BOOT_DISK2"
fi

echo Create zpool partition...
sgdisk -n "${POOL_PART1}:0:-10m" -t "${POOL_PART1}:bf00" "$POOL_DISK1"

if [ $MIRRORENABLED == yes ]; then
	sgdisk -n "${POOL_PART2}:0:-10m" -t "${POOL_PART2}:bf00" "$POOL_DISK2"
fi

echo Create var partition...

if [ $VARDEVICEENABLED == yes ]; then
	sgdisk -n "${VAR_PART1}:0:-10m" -t "${VAR_PART1}:bf00" "$VAR_DISK1"
	if [ $MIRRORENABLED == yes ]; then
		sgdisk -n "${VAR_PART2}:0:-10m" -t "${VAR_PART2}:bf00" "$VAR_DISK2"
	fi
fi

if [ $MIRRORENABLED == yes ]; then
	echo Create the zpool...
	zpool create -f -o ashift=12 \
	 -O compression=lz4 \
	 -O acltype=posixacl \
	 -O xattr=sa \
	 -O relatime=on \
	 -o autotrim=on \
	 -o compatibility=openzfs-2.1-linux \
	 -m none \
	 zroot mirror \
	 "$POOL_DEVICE1" \
	 "$POOL_DEVICE2" 
else
	echo Create the zpool...
	zpool create -f -o ashift=12 \
	 -O compression=lz4 \
	 -O acltype=posixacl \
	 -O xattr=sa \
	 -O relatime=on \
	 -o autotrim=on \
	 -o compatibility=openzfs-2.1-linux \
	 -m none zroot "$POOL_DEVICE"
fi

if [ $VARDEVICEENABLED == yes ]; then
	if [ $MIRRORENABLED == yes ]; then
		echo Create the zvar...
		zpool create -f -o ashift=12 \
		 -O compression=lz4 \
		 -O acltype=posixacl \
		 -O xattr=sa \
		 -O relatime=on \
		 -o autotrim=on \
		 -o compatibility=openzfs-2.1-linux \
		 -m none \
		 zvar mirror \
		 "$VAR_DEVICE1" \
		 "$VAR_DEVICE2" 
	else
		echo Create the zvar...
		zpool create -f -o ashift=12 \
		 -O compression=lz4 \
		 -O acltype=posixacl \
		 -O xattr=sa \
		 -O relatime=on \
		 -o autotrim=on \
		 -o compatibility=openzfs-2.1-linux \
		 -m none zvar "$VAR_DEVICE"
	fi
fi

echo Create initial file systems... 
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/${ID}
zfs create -o mountpoint=/home zroot/home

if [ $VARDEVICEENABLED == yes ]; then
	zfs create -o mountpoint=/var zvar/var
fi

zpool set bootfs=zroot/ROOT/${ID} zroot 

echo Export, then re-import with a temporary mountpoint of /mnt...
zpool export zroot

if [ $VARDEVICEENABLED == yes ]; then
	zpool export zvar
fi

zpool import -N -R /mnt zroot

if [ $VARDEVICEENABLED == yes ]; then
	zpool import -N -R /mnt zvar
fi

zfs mount zroot/ROOT/${ID}
zfs mount zroot/home

if [ $VARDEVICEENABLED == yes ]; then
	zfs mount zvar/var
fi

echo Update device symlinks...
udevadm trigger

echo Install Ubuntu...
debootstrap jammy /mnt

echo Copy files into the new install...
cp /etc/hostid /mnt/etc
cp /etc/resolv.conf /mnt/etc

echo set hostname...
hostname $HOSTNAME
hostname > /mnt/etc/hostname

echo "127.0.1.1       $HOSTNAME" >> /mnt/etc/hosts

cat /mnt/etc/hosts

echo setup netplan...

touch /mnt/etc/netplan/01-network-manager-all.yaml
    
echo "network:" > /mnt/etc/netplan/01-network-manager-all.yaml
echo "  version: 2" >> /mnt/etc/netplan/01-network-manager-all.yaml
echo "  renderer: NetworkManager" >> /mnt/etc/netplan/01-network-manager-all.yaml

chmod 600 /mnt/etc/netplan/01-network-manager-all.yaml

cat /mnt/etc/netplan/01-netcfg.yaml

echo setup apt sources...

echo "deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse" > /mnt/etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse" >> /mnt/etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse" >> /mnt/etc/apt/sources.list
echo "deb http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse" >> /mnt/etc/apt/sources.list
echo "deb http://archive.canonical.com/ubuntu/ jammy partner" >> /mnt/etc/apt/sources.list

cat /mnt/etc/apt/sources.list

echo Copy seconday setup script...
cp secondary.sh /mnt

echo Chroot into the new OS...
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -B /dev /mnt/dev
mount -t devpts pts /mnt/dev/pts

chroot /mnt /bin/bash

echo Remove seconday setup script...
rm /mnt/secondary.sh

echo Exit the chroot, unmount everything...
umount -n -R /mnt  

echo Export the zpool...
zpool export zroot

if [ $VARDEVICEENABLED == yes ]; then
	zpool export zvar
fi
exit 
