#!/bin/bash
ver="1.2.6"
export ARCH=x86_64
function build(){
    [ -f musl-${ver}.tar.gz ] || wget https://musl.libc.org/releases/musl-${ver}.tar.gz
    tar -xf musl-${ver}.tar.gz
    cd musl-${ver}
    ./configure --prefix=$DESTDIR/toolchain
    make -j`nproc`
    make install DESTDIR=/
    for tool in ar strip ; do
        ln -s /usr/bin/$tool $DESTDIR/toolchain/bin/musl-$tool
    done
    for dir in mtd asm asm-generic linux ; do
        ln -s /usr/include/$dir $DESTDIR/toolchain/include/
    done
}
function package(){
    :
}