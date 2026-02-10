#!/bin/bash
function build(){
  :
}

function package(){
    # build iso image
    mkdir -p $DESTDIR/iso/boot/grub
    install $DESTDIR/linux $DESTDIR/iso/linux
    install $DESTDIR/initramfs $DESTDIR/iso/initrd
    echo "insmod all_video" > $DESTDIR/iso/boot/grub/grub.cfg
    echo "menuentry netinstall-combo {" > $DESTDIR/iso/boot/grub/grub.cfg
    echo "linux /linux quiet console=ttyS0 console=tty1" >> $DESTDIR/iso/boot/grub/grub.cfg
    echo "initrd /initrd" >> $DESTDIR/iso/boot/grub/grub.cfg
    echo "}" >> $DESTDIR/iso/boot/grub/grub.cfg
    grub-mkrescue -o $DESTDIR/netinstall-combo.iso --fonts="" --compress=xz --locales="" $DESTDIR/iso
}

