#!/bin/bash
# Configuring the LFS system(chapter 9, 10 and 11).
set -e

cat > /etc/resolv.conf << "EOF"
nameserver 223.5.5.5
nameserver 8.8.8.8
EOF

echo "lfs" > /etc/hostname
cat > /etc/hosts << "EOF"
127.0.0.1    localhost
::1          localhost
EOF

systemctl disable systemd-timesyncd

cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
EOF

cat > /etc/inputrc << "EOF"
set bell-style none

set horizontal-scroll-mode Off
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On

"\eOd": backward-word
"\eOc": forward-word

"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[7~": beginning-of-line
"\e[3~": delete-char
"\e[2~": quoted-insert
EOF

cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

cat > /etc/fstab << EOF
# file-system    mount-point    type     options             dump  fsck-order

/dev/nvme0n1p2   /              ext4     defaults            1     1
EOF

tar -xf /sources/linux-5.13.12.tar.xz -C /usr/src
cd /usr/src/linux-5.13.12
make defconfig
make menuconfig
make
make modules_install
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.13.12
cp -iv System.map /boot/System.map-5.13.12
cp -iv .config /boot/config-5.13.12
install -dm755 /usr/share/doc/linux-5.13.12
cp -r Documentation/* /usr/share/doc/linux-5.13.12
install -dm755 /etc/modprobe.d

echo 11.0-systemd > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="11.0-systemd"
DISTRIB_CODENAME="Murkoff"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF
cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="11.0-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 11.0-systemd"
VERSION_CODENAME="Murkoff"
EOF
