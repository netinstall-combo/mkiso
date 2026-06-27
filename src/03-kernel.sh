#!/bin/bash

_kver="7.1.1"

export CFLAGS="-O3 -Os -s -flto"

function build(){
    # fetch kernel
    [ -f linux-${_kver}.tar.xz ] || wget https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-${_kver}.tar.xz
    [ -d linux-${_kver} ] || tar -xf linux-${_kver}.tar.xz
    # build kernel
    cd linux-${_kver}
    make defconfig
    {
        find ./drivers/net/ethernet -iname Kconfig -exec grep "config " {} \;
        find ./drivers/scsi -iname Kconfig -exec grep "config " {} \;
        find ./drivers/mmc -iname Kconfig -exec grep "config " {} \;
        find ./drivers/usb/storage -iname Kconfig -exec grep "config " {} \;
        find ./drivers/hid -iname Kconfig -exec grep "config " {} \;
        find ./drivers/virtio -iname Kconfig -exec grep "config " {} \;
        find ./fs -iname Kconfig -exec grep "config " {} \;
    } | cut -f 2 -d " " | while read line ; do
         echo "CONFIG_$line"
         ./scripts/config --enable CONFIG_$line
    done
    {
        find ./drivers/gpu -iname Kconfig -exec grep "config " {} \;
        find ./drivers/media -iname Kconfig -exec grep "config " {} \;
    } | cut -f 2 -d " " | while read line ; do
         echo "CONFIG_$line"
         ./scripts/config --disable CONFIG_$line
    done

    ./scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE
    ./scripts/config --enable CONFIG_DRM_SIMPLEDRM
    ./scripts/config --enable CONFIG_DRM_VESADRM
    grep "CONFIG_[A-Z0-9]*_FS" .config  | cut -f2 -d" " | while read cfg ; do
        ./scripts/config --enable $cfg
    done
    ./scripts/config --disable CONFIG_ACPI
    cat .config | grep -v "#" | grep "DEBUG" \
        | sed "s/=.*//g" | sed "s|^|./scripts/config --disable |g" | sh
    ./scripts/config --enable TRIM_UNUSED_KSYMS
    ./scripts/config --enable LTO_MENU
    ./scripts/config --enable CONFIG_KERNEL_XZ
    ./scripts/config --enable CONFIG_OPTIMIZE_INLINING
    ./scripts/config --enable CONFIG_SLOB
    ./scripts/config --enable CONFIG_CORE_SMALL
    ./scripts/config --enable CONFIG_NET_SMALL
    cd ..
    yes "" | make bzImage -j`nproc` -C linux-${_kver}
}

function package(){
    install linux-${_kver}/arch/x86/boot/bzImage $DESTDIR/linux
}