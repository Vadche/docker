#!/bin/bash

mkdir ~/ubuntu
cd ~/ubuntu
sudo cat << EOF | sudo tee ~/ubuntu/Dockerfile
FROM ubuntu
MAINTAINER Vadim Cherenev(vad.cherenev@gmail.com)
RUN ln -snf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && echo Europe/Moscow > /etc/timezone
RUN apt update
RUN apt install linux-image-generic libguestfs-tools debootstrap  git qemu-system-x86 make gcc bison flex bc libelf-dev -y && rm -rf /var/cache/apt
RUN mkdir -p /media/ubuntu/root/etc/apt
WORKDIR /media/ubuntu
RUN debootstrap --include=linux-image-generic,ssh,vim,nano --arch amd64 focal root http://ru.archive.ubuntu.com/ubuntu
RUN echo 'root:root' | chroot "/media/ubuntu/root/" chpasswd && echo "/dev/sda / ext4 defaults 0 1" >> /media/ubuntu/root/etc/fstab
RUN cp /etc/apt/sources.list /media/ubuntu/root/etc/apt/sources.list && cp /etc/resolv.conf /media/ubuntu/root/etc/resolv.conf
RUN mkdir -p /media/ubuntu/root/etc/netplan
RUN echo \
'network:\n\
   version: 2\n\
   renderer: networkd\n\
   ethernets:\n\
     enp0s3:\n\
       dhcp4: true\n'\
 >> /media/ubuntu/root/etc/netplan/01-netconfig.yaml
WORKDIR /root
RUN git clone --depth 1 --branch v4.18 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
WORKDIR /root/linux
RUN echo \
'CONFIG_SYSVIPC=y\n\
CONFIG_IKCONFIG=y\n\
CONFIG_IKCONFIG_PROC=y\n\
CONFIG_CGROUPS=y\n\
CONFIG_BLK_DEV_INITRD=y\n\
CONFIG_KALLSYMS_ALL=y\n\
CONFIG_MODULES=y\n\
CONFIG_MODULE_UNLOAD=y\n\
CONFIG_MODVERSIONS=y\n\
CONFIG_MODULE_SRCVERSION_ALL=y\n\
CONFIG_SMP=y\n\
CONFIG_HYPERVISOR_GUEST=y\n\
CONFIG_PARAVIRT=y\n\
CONFIG_NET=y\n\
CONFIG_PACKET=y\n\
CONFIG_UNIX=y\n\
CONFIG_INET=y\n\
CONFIG_NET_9P=y\n\
CONFIG_NET_9P_VIRTIO=y\n\
CONFIG_NET_9P_DEBUG=y\n\
CONFIG_DEVTMPFS=y\n\
CONFIG_DEVTMPFS_MOUNT=y\n\
CONFIG_CONNECTOR=y\n\
CONFIG_VIRTIO_BLK=y\n\
CONFIG_DUMMY_IRQ=m\n\
CONFIG_BLK_DEV_SD=y\n\
CONFIG_SCSI_VIRTIO=y\n\
CONFIG_ATA=y\n\
CONFIG_ATA_PIIX=y\n\
CONFIG_NETDEVICES=y\n\
CONFIG_VIRTIO_NET=y\n\
CONFIG_NE2K_PCI=y\n\
CONFIG_8139CP=y\n\
CONFIG_INPUT_EVDEV=y\n\
CONFIG_SERIAL_8250=y\n\
CONFIG_SERIAL_8250_CONSOLE=y\n\
CONFIG_VIRTIO_CONSOLE=y\n\
CONFIG_HW_RANDOM_VIRTIO=m\n\
CONFIG_DRM=y\n\
CONFIG_DRM_QXL=y\n\
CONFIG_DRM_BOCHS=y\n\
CONFIG_DRM_VIRTIO_GPU=y\n\
CONFIG_FRAMEBUFFER_CONSOLE_ROTATION=y\n\
CONFIG_LOGO=y\n\
CONFIG_SOUND=y\n\
CONFIG_SND=y\n\
CONFIG_SND_HDA_INTEL=y\n\
CONFIG_SND_HDA_GENERIC=y\n\
CONFIG_USB=y\n\
CONFIG_USB_XHCI_HCD=y\n\
CONFIG_USB_EHCI_HCD=y\n\
CONFIG_USB_UHCI_HCD=y\n\
CONFIG_USB_STORAGE=y\n\
CONFIG_UIO=m\n\
CONFIG_UIO_PDRV_GENIRQ=m\n\
CONFIG_UIO_DMEM_GENIRQ=m\n\
CONFIG_UIO_PCI_GENERIC=m\n\
CONFIG_VIRTIO_PCI=y\n\
CONFIG_VIRTIO_BALLOON=y\n\
CONFIG_VIRTIO_INPUT=y\n\
CONFIG_VIRTIO_MMIO=y\n\
CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES=y\n\
CONFIG_EXT4_FS=y\n\
CONFIG_AUTOFS4_FS=y\n\
CONFIG_OVERLAY_FS=y\n\
CONFIG_TMPFS=y\n\
CONFIG_TMPFS_POSIX_ACL=y\n\
CONFIG_CONFIGFS_FS=y\n\
CONFIG_SQUASHFS=y\n\
CONFIG_9P_FS=y\n\
CONFIG_9P_FS_POSIX_ACL=y\n\
CONFIG_9P_FS_SECURITY=y\n\
CONFIG_DYNAMIC_DEBUG=y\n\
CONFIG_DEBUG_INFO=y\n\
CONFIG_GDB_SCRIPTS=y\n\
CONFIG_DEBUG_KERNEL=y\n\
CONFIG_IRQSOFF_TRACER=y\n\
CONFIG_SCHED_TRACER=y\n\
CONFIG_HWLAT_TRACER=y\n\
CONFIG_FTRACE_SYSCALLS=y\n\
CONFIG_STACK_TRACER=y\n\
CONFIG_FUNCTION_PROFILER=y\n\
CONFIG_KGDB=y\n\
CONFIG_KGDB_TESTS=y\n\
CONFIG_KGDB_LOW_LEVEL_TRAP=y\n\
CONFIG_KGDB_KDB=y\n\
CONFIG_KDB_KEYBOARD=y\n\
CONFIG_X86_PTDUMP=y\n\
CONFIG_UNWINDER_FRAME_POINTER=y\n'\
>> .config
RUN make olddefconfig && make -j`nproc`
EOF
sudo docker build -t ubuntu1 .
if [ -z "$1" ]; then 
sudo docker run --name ubuntu -ti -v /tmp/qcow:/tmp/qcow ubuntu1 virt-make-fs --format qcow2 --size +5G --type ext4 /media/ubuntu/root /root/ubuntu.qcow2
else
sudo docker run --name ubuntu -ti -v /tmp/qcow:/tmp/qcow ubuntu1 virt-make-fs --format qcow2 --size +$1 --type ext4 /media/ubuntu/root /root/ubuntu.qcow2
fi
sudo docker cp ubuntu:/root/ubuntu.qcow2 ~/ubuntu
sudo docker cp -L ubuntu:/root/linux/arch/x86/boot/bzImage ~/ubuntu
sudo docker rm ubuntu
sudo qemu-system-x86_64 \
     -append 'console=ttyS0 root=/dev/sda' \
     -drive "file=ubuntu.qcow2,format=qcow2" \
     -enable-kvm \
     -serial mon:stdio \
     -m 4G \
     -kernel "bzImage" \
     -device rtl8139,netdev=net0 \
     -netdev user,id=net0 \

