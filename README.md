# docker
Deploy Ubuntu qcow2 image from docker.

Run with Docker and QEMU installed!

1. Copy file "deploy_ubuntu.sh" to a folder, such as /home/user/
2. Go to the folder with the script and give the rights to execute the script with the command: 
$ chmod +x deploy_ubuntu.sh
3. Run the script:
$ ./deploy_ubuntu.sh 10G
* Where 10G is the size of qcow2 in gigabytes (and plus the operating system), the default is 5 gigabytes.
4. Go to drink coffee for 15 minutes =)
5. At the end of the build, the qemu terminal will open. In the terminal that opens, enter the root username/password:
root/root
6. In the subsequent run, being in the same directory, the line: 
$ sudo qemu-system-x86_64 -append 'console=ttyS0 root=/dev/sda' -drive "file=ubuntu.qcow2,format=qcow2" -enable-kvm -serial mon:stdio -m 4G -kernel "bzImage" -device rtl8139,netdev=net0 -netdev user,id=net0

The image in the qcow2 format is located in the home directory in the ~/ubuntu folder

Or:

7. For further use of this image(ubuntu.qcow2) via virt-manager, I recommend performing the following actions in the qemu terminal of the newly installed image:
# apt update
# apt install grub2
# update-grub
# grub-install /dev/sda --force

(after importing the qcow2 image via virtmanager, the interface name may change, the recommendation is to double-check, and, in case of changes, fix it in the file /etc/netplan/01-netconfig. yaml).

Optionally, you can put a light desktop:
# apt install lxde-core
