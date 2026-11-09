### Linux From Scratch 13.1 Systemd Build Scripts

0. 前置说明

官方文档: [https://linuxfromscratch.org/lfs/downloads/13.1-systemd/LFS-BOOK-13.1.tar.xz](https://linuxfromscratch.org/lfs/downloads/13.1-systemd/LFS-BOOK-13.1.tar.xz)。

源码包镜像地址: [https://mirrors.ustc.edu.cn/lfs/lfs-packages/lfs-packages-13.1.tar](https://mirrors.ustc.edu.cn/lfs/lfs-packages/lfs-packages-13.1.tar)。

勘误列表: [https://linuxfromscratch.org/lfs/errata/13.1-systemd](https://linuxfromscratch.org/lfs/errata/13.1-systemd)。

脚本按手册中的安装命令编写, 不运行软件包测试套件。时区固定为`Asia/Shanghai`, 并额外生成`zh_CN.UTF-8`。`Groff`纸张为`A4`。网络、主机名和`fstab`沿用以往脚本中的取值, 构建前请按本机情况修改`4-config.sh`。

***注意事项***: 在构建过程中最好使用同一个终端执行命令, 否则容易出现Shell变量不存在的情况导致宿主机损坏。

1. 检查宿主机是否满足构建条件。

```bash
# any user
bash 0-check.sh
```

1. 创建分区并格式化。

```bash
# root
cfdisk /dev/<磁盘名>
mkfs.ext4 /dev/<分区名>
```

1. 挂载分区, 并将源码包解压到指定位置。

```bash
# root
export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v /dev/<分区名> $LFS
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
tar -xf <存放路径>/lfs-packages-13.1.tar -C $LFS/sources --strip-components=1
pushd $LFS/sources
md5sum -c md5sums
popd
```

1. 创建[FHS](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)标准目录。

```bash
# root
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
mkdir -pv $LFS/tools
```

1. 添加临时用户, 并配置用户环境。

```bash
# root
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
chown -v lfs $LFS/{usr{,/*},var,etc,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
su - lfs

# lfs
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

source ~/.bash_profile
```

1. 构建交叉工具链以及临时工具。

```bash
# lfs
set # 检查环境变量
export MAKEFLAGS="-j16" # 并行构建, 该值取决于CPU核心数
bash 1-build.sh
exit

# root
chown --from lfs -R root:root $LFS/{usr,var,etc,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac
userdel -f -r lfs
[ ! -e /etc/bash.bashrc.NOUSE ] || mv -v /etc/bash.bashrc.NOUSE /etc/bash.bashrc
```

1. 创建虚拟文件系统以及挂载目录。

```bash
# root
mkdir -pv $LFS/{dev,proc,sys,run}
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi
```

1. 进入到`Chroot`环境。

```bash
# root
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j16"            \
    TESTSUITEFLAGS="-j16"       \
    /bin/bash --login
```

1. 创建必要的文件和目录。

```bash
# (chroot) root
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << EOF
127.0.0.1  localhost
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
clock:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

exec /usr/bin/bash --login

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
```

1. 在`Chroot`环境中构建临时工具。

```bash
# (chroot) root
bash 2-build.sh

rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools
```

1. 构建`LFS`基本系统。

```bash
# (chroot) root
bash 3-build.sh
```

1. 剥离调试信息以及清理。

```bash
# (chroot) root
save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.36
             libitm.so.1.0.0
             libatomic.so.1.2.0"
cd /usr/lib
for LIB in $save_usrlib; do
  objcopy --only-keep-debug --compress-debug-sections=zstd $LIB $LIB.dbg
  cp $LIB /tmp/$LIB
  strip --strip-unneeded /tmp/$LIB
  objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
  install -vm755 /tmp/$LIB /usr/lib
  rm /tmp/$LIB
done
online_usrbin="bash find strip"
online_usrlib="libbfd-2.47.20260726.so
               libsframe.so.3.0.0
               libhistory.so.8.3
               libncursesw.so.6.6
               libm.so.6
               libreadline.so.8.3
               libz.so.1.3.2
               libzstd.so.1.5.7
               $(cd /usr/lib; find libnss*.so* -type f)"
for BIN in $online_usrbin; do
  cp /usr/bin/$BIN /tmp/$BIN
  strip --strip-unneeded /tmp/$BIN
  install -vm755 /tmp/$BIN /usr/bin
  rm /tmp/$BIN
done
for LIB in $online_usrlib; do
  cp /usr/lib/$LIB /tmp/$LIB
  strip --strip-unneeded /tmp/$LIB
  install -vm755 /tmp/$LIB /usr/lib
  rm /tmp/$LIB
done
for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
  case "$online_usrbin $online_usrlib $save_usrlib" in
    *$(basename $i)*) ;;
    *) strip --strip-unneeded $i ;;
  esac
done
unset BIN LIB save_usrlib online_usrbin online_usrlib

rm -rf /tmp/{*,.*}
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
```

1. 配置`LFS`系统(需要手动修改某些配置, 构建内核时终端窗口至少为80*19)。

```bash
# (chroot) root
bash 4-config.sh

passwd
rm -rf /sources
```

1. 若需要备份`LFS`, 则按以下步骤操作。

```bash
# (chroot) root
exit

# root
umount -Rv $LFS
mount -v /dev/<分区名> $LFS
cd $LFS
tar -I "zstd -11" -cf lfs-systemd-13.1.tar.zst bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv sys tmp usr var
```

1. 使用`GRUB`引导`LFS`。若磁盘的分区表为`MBR`格式, 则按照手册中10.4节进行配置即可; 若磁盘的分区表为`GPT`格式, 则使用宿主机的`GRUB`来引导`LFS`, 要求`LFS`的内核编译选项符合`BLFS`文档的“Using GRUB to Set Up the Boot Process with UEFI”小节, 并在宿主机的`/boot/grub/grub.cfg`文件中添加以下条目便可引导。

```
menuentry 'Linux From Scratch' --class linuxfromscratch --class gnu-linux --class gnu --class os {
  load_video
  set gfxpayload=keep
  insmod gzio
  insmod part_gpt
  insmod ext2
  search --no-floppy --fs-uuid --set=root <分区UUID>
  linux /boot/vmlinuz-7.1.8-lfs-13.1-systemd root=/dev/<分区名> rw loglevel=3
}
```
