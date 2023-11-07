# THIS SCRIPT WILL WIPE YOUR DATA!!! DO NOT RUN UNLESS YOU KNOW WHAT YOU ARE DOING!!!

This script is provided as-is with no warranty or guarantee of fitness for a particular purpose.
Use this script at your own risk.

The author of this script is not responsible for any damage or loss that may occur as a result of using this script.

### This a simple script for creating a ZFS Ubuntu installation using ZFS Boot Menu. 

The script is primarily a compilation of the instructions on the ZFSBootMenu website. 

<https://docs.zfsbootmenu.org/en/latest/guides/ubuntu/uefi.html>

With some changes from the OpenZFS website.

<https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2022.04%20Root%20on%20ZFS.html>


At this time it this scripts supports a singe disk and ZFS mirror configurations. It also supports a seperate /var device.

This was made for a specific use case and will probably never be finished. 

<hr>

### 1.) To use the script boot up the system into an Ubuntu Desktop 22.04 Installer and select "Try Ubuntu". It is recomended to have a copy of this scipt on a second USB drive.

### 2.) Open a terminal and determine your disk configuration then edit the script for use your specific needs

This script has several configurable options:

HOSTNAME is your desired hostname on the finished system.

~~~
HOSTNAME=spc-dual1
~~~

MIRRORENABLED is if the systems should create a mirrored pool 

~~~
export MIRRORENABLED=yes
~~~

VARDEVICEENABLED is if the system has a seperate /var device on another disk

~~~
export VARDEVICEENABLED=yes
~~~

BOOT_DISK1 is the primary device where your /boot directory is located. This is where ZFSBootMenu will be installed and will NOT be a part of a ZFS pool. 

BOOT_PART1 is the partition the the /boot will be located. This will almost always be 1

~~~
export BOOT_DISK1="/dev/sda"
export BOOT_PART1="1"
~~~

BOOT_DISK2 is the drive the will be used if in a mirror for the backup installation of ZFSBootMenu.

~~~
export BOOT_DISK2="/dev/sdb"
export BOOT_PART2="1"
~~~

POOL_DISK1 is the drive where your main ZFS zroot partition will live

POOL_PART is the partition that zroot will be created. This is set to 2 because it is sharing the same device as the boot disk. If it is alone then it would be a 1

~~~
export POOL_DISK1="/dev/sda"
export POOL_PART1="2"
~~~

POOL_DISK2 is the drive the will be used if in a mirror for the zroot.

~~~
export POOL_DISK2="/dev/sdb"
export POOL_PART2="2"
~~~

VAR_DISK1 is the drive that the /var partition and zvar pool will be stored.

VAR_PART1 is the partition on that drive. (Notice the NVME disks list partiton differently than SATA and thus it is p1)

~~~
export VAR_DISK1="/dev/nvme0n1"
export VAR_PART1="p1"
~~~

VAR_DISK2 is the drive the will be used if in a mirror for the zvar.

~~~
export VAR_DISK2="/dev/nvme1n1"
export VAR_PART2="p1"
~~~

### 3.) Navigate terminal to the script directory and start the script. THIS WILL WIPE DATA!!!

~~~
sudo bash zfsbootmenu.sh
~~~

### 4.) The script will have created the appropriate partitions, pools and datasets. It will make a base Ubuntu install drop you in a chroot of your new install in order to install the specific packages. There is a secondary script on the root of your new install that will install the desktop packages, drivers and configure ZFS boot menu

~~~
bash secondary.sh
~~~

You will need to set a root password and select timezones. Since this is a bare install you need to install at lease one locale. Navigate the list until you find "en_US.UTF-8 UTF-8" and then make it your default. The other questions you can simply use the default options. You will be asked again durring the systems first boot. 

![1](/docs/locale1.png)

![2](/docs/locale2.png)

### 5.)  Once secondary.sh completes you will be left at a prompt in case you want to do any more changes to the final system. If not then just exit and once the script completes exporting the ZFS pools reboot.

~~~
exit
~~~
