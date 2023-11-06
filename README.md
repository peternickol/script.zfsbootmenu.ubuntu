# THIS SCRIPT WILL WIPE YOUR DATA!!! DO NOT RUN UNLESS YOU KNOW WHAT YOU ARE DOING!!!

This script is provided as-is with no warranty or guarantee of fitness for a particular purpose.
Use this script at your own risk.

The author of this script is not responsible for any damage or loss that may occur as a result of using this script.

### This a simple script for creating a ZFS Ubuntu installation using ZFS Boot Menu. 

The script is primarily a compilation of the instructions on the ZFSBootMenu website. 
<https://docs.zfsbootmenu.org/en/latest/guides/ubuntu/uefi.html>

With some changes from the OpenZFS website.
<https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2022.04%20Root%20on%20ZFS.html>

It supports a singe disk and dual drive ZFS mirror configurations. It also supports a seprate /var device.

This was made for a specific use case and will probably never be finished. 

1.) To use the script boot up the system into an Ubuntu Desktop 22.04 Installer and select "Try Ubuntu"

2.) Open a terminal and determine your disk configuration 

~~~
lsblk
~~~

3.) Edit the script for use your specific needs

populate the variable to suit your needs

~~~
MIRRORENABLED
~~~

4.) Navigate terminal to the script directory and start the script. THIS WILL WIPE DATA!!!

~~~
sudo bash zfsbootmenu.sh
~~~

5.) The script will have created the appropriate partitions, pools and datasets. It will make a base Ubuntu install drop you in a chroot of your new install in order to install the specific packages. There is a secondary script on the root of your new install that will install the desktop packages, drivers and configure ZFS boot menu

~~~
bash secondary.sh
~~~

You will need to set a root password and select timezones. Since this is a bare install you need to install at lease one locale. Navigate the list until you find "en_US.UTF-8 UTF-8" and then make it your default. The other questions you can simply use the default options. You will be asked again durring the systems first boot. 

![1](/docs/locale1.png)

![1](/docs/locale2.png)

6.)  Once secondary.sh completes you will be left at a prompt in case you want to do any more changes to the final system. If not then just exit

~~~
exit
~~~
