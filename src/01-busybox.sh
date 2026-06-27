#!/bin/bash
_bver="1.38.0"
export CFLAGS="-Wno-all -Os -s"
export LDFLAGS="-fno-link-libatomic"
export CC=musl-gcc
export LD=musl-ld
function build(){
    [ -f busybox_${_bver}.orig.tar.bz2 ] || wget http://deb.debian.org/debian/pool/main/b/busybox/busybox_${_bver}.orig.tar.bz2
    tar -xf busybox_${_bver}.orig.tar.bz2
    make defconfig -C busybox-${_bver}
    sed -i "s|.*CONFIG_STATIC.*|CONFIG_STATIC=y|" busybox-${_bver}/.config
    sed -i "s|CONFIG_TC=.*|# CONFIG_TC is not set|" busybox-${_bver}/.config
    yes "" | make oldconfig -j`nproc` -C busybox-${_bver}
    sed -i 's|CONFIG_CROSS_COMPILER_PREFIX=.*|CONFIG_CROSS_COMPILER_PREFIX="musl-"|' busybox-${_bver}/.config
    make -C busybox-${_bver} LIBS= -j`nproc`
}

function package(){
    install busybox-${_bver}/busybox $DESTDIR/busybox
}
