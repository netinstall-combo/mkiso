#!/bin/bash
umask 022
set -e
if [[ ! -d build ]] ; then
    rm -rf build
fi
# fetch & extract rootfs
mkdir -p build
cd build
uri="https://dl-cdn.alpinelinux.org/alpine/edge/releases/$(uname -m)/"
tarball=$(wget -O - "$uri" |grep "alpine-minirootfs" | grep "tar.gz<" | \
    sort -V | tail -n 1 | cut -f2 -d"\"")
wget -O "$tarball" "$uri/$tarball"
mkdir -p chroot
cd chroot
tar -xvf ../*$tarball
# fix resolv.conf
install /etc/resolv.conf ./etc/resolv.conf
# add repositories
cat > ./etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/edge/main
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF
# upgrade if needed
chroot ./ apk upgrade
# hooks
cd ../../hooks
for file in $(ls . | sort -V) ; do
    echo "Executing: $file"
    install $file ../build/chroot/tmp/hook
    chroot ../build/chroot/ ash /tmp/hook
done
if [[ -d ../build/isowork ]] ; then
    rm -rf ../build/isowork
fi
# copy rootfs files
cp -rf ../airootfs/* ../build/chroot/ || true
mkdir -p ../build/isowork
cd ../build/isowork
# copy kernel
cd ../chroot
install ./boot/vmlinuz ../isowork/linux
rm -rf ./boot
ln -s /netinstall/init.sh ./init
find . | cpio -H newc -o | gzip -9 > ../isowork/initramfs
cd ../isowork
mkdir -p boot/grub/
cat > boot/grub/grub.cfg <<EOF
insmod all_video
terminal_output console
terminal_input console
clear
linux /linux quiet
initrd /initramfs
boot
EOF
# create iso
cd ../
grub-mkrescue isowork -o alpine.iso --fonts="" --install-modules="linux normal fat all_video" --compress=xz --locales=""
# create pxeroot
chroot chroot apk add syslinux
mkdir -p pxeroot/pxelinux.cfg
cp -f isowork/linux pxeroot
cp -f isowork/initramfs pxeroot
cp -f chroot/usr/share/syslinux/{ldlinux,vesamenu,libcom32,libutil}.c32 \
    chroot/usr/share/syslinux/pxelinux.0  pxeroot
cat > pxeroot/pxelinux.cfg/default <<EOF
DEFAULT netinstall-combo

LABEL netinstall-combo
	LINUX /linux
	INITRD /initramfs
	APPEND quiet
EOF
zip -r alpine-pxe.zip pxeroot
