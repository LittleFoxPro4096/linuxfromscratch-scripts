#!/bin/bash
# Configuring the LFS system(chapter 9, 10 and 11).
set -e

systemctl disable systemd-networkd-wait-online
systemctl disable systemd-resolved
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

echo "FONT=Lat2-Terminus16" > /etc/vconsole.conf

cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
EOF

cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf

  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi

# End /etc/profile
EOF

cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# uncomment for history search mode with up/down
# "\e[A": history-search-backward
# "\e[B": history-search-forward

# End /etc/inputrc
EOF

cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

cat > /etc/fstab << EOF
# file-system    mount-point    type     options             dump  fsck-order

/dev/nvme0n1p2   /              ext4     defaults            1     1
EOF

tar -xf /sources/linux-7.1.8.tar.xz -C /usr/src
cd /usr/src/linux-7.1.8
make mrproper
make defconfig
make menuconfig
make
make modules_install
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-7.1.8-lfs-13.1-systemd
cp -iv System.map /boot/System.map-7.1.8
cp -iv .config /boot/config-7.1.8
cp -r Documentation -T /usr/share/doc/linux-7.1.8
install -dm755 /etc/modprobe.d

echo 13.1-systemd > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="13.1-systemd"
DISTRIB_CODENAME="Ezio"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF
cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="13.1-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 13.1-systemd"
VERSION_CODENAME="Ezio"
HOME_URL="https://www.linuxfromscratch.org/lfs/"
RELEASE_TYPE="stable"
EOF
