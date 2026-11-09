#!/bin/bash
# Building the basic system software(chapter 8).
set -e

package_name=""
package_ext=""

begin() {
  package_name=$1
  package_ext=$2
  tar -xf $package_name.$package_ext
  cd $package_name
}

end() {
  cd /sources
  rm -rf $package_name
}

cd /sources
mv -v tcl8.6.18-src.tar.gz tcl8.6.18.tar.gz

## 8.3. Man-pages-6.18
begin man-pages-6.18 tar.xz
rm -v man3/crypt*
make -R GIT=false prefix=/usr install
end

## 8.4. Iana-Etc-20260805
begin iana-etc-20260805 tar.gz
cp -v services protocols /etc
end

## 8.5. Glibc-2.44
begin glibc-2.44 tar.xz
patch -Np1 -i ../glibc-fhs-1.patch
patch -Np1 -i ../glibc-2.44-upstream_fixes-1.patch
mkdir build && cd build
../configure --prefix=/usr                   \
             --disable-werror                \
             --disable-nscd                  \
             libc_cv_slibdir=/usr/lib        \
             --enable-stack-protector=strong \
             --enable-kernel=5.10
make
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
rm -f /usr/sbin/nscd
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/*.so.* /usr/lib
DIR=$(dirname $(gcc -print-libgcc-file-name))
[ -e $DIR/include/limits.h ]    || mv $DIR/include{-fixed,}/limits.h
[ -e $DIR/include/syslimits.h ] || mv $DIR/include{-fixed,}/syslimits.h
rm -rfv $DIR/include-fixed/*
unset DIR
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
localedef -i C -f UTF-8 C.UTF-8 || true
localedef -i en_US -f UTF-8 en_US.UTF-8 || true
localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 || true
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
tar -xf ../../tzdata2026c.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done
cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz
ln -sfv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
end

## 8.6. Zlib-1.3.2
begin zlib-1.3.2 tar.gz
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libz.a
end

## 8.7. Bzip2-1.0.8
begin bzip2-1.0.8 tar.gz
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so
ln -sfv libbz2.so.1.0.8 /usr/lib/libbz2.so.1
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
end

## 8.8. Xz-5.8.3
begin xz-5.8.3 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.8.3
make
make install
end

## 8.9. Lz4-1.10.0
begin lz4-1.10.0 tar.gz
make BUILD_STATIC=no PREFIX=/usr
make BUILD_STATIC=no PREFIX=/usr install
end

## 8.10. Zstd-1.5.7
begin zstd-1.5.7 tar.gz
make prefix=/usr
make prefix=/usr install
rm -v /usr/lib/libzstd.a
end

## 8.11. File-5.48
begin file-5.48 tar.gz
./configure --prefix=/usr
make
make install
end

## 8.12. Readline-8.3
begin readline-8.3 tar.gz
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
sed -e '270a\
     else\
       chars_avail = 1;'      \
    -e '288i\   result = -1;' \
    -i.orig input.c
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.3
make SHLIB_LIBS="-lncursesw"
make install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3
end

## 8.13. Pcre2-10.47
begin pcre2-10.47 tar.bz2
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/pcre2-10.47 \
            --enable-unicode                    \
            --enable-jit                        \
            --enable-pcre2-16                   \
            --enable-pcre2-32                   \
            --enable-pcre2grep-libz             \
            --enable-pcre2grep-libbz2           \
            --enable-pcre2test-libreadline      \
            --disable-static
make
make install
end

## 8.14. M4-1.4.21
begin m4-1.4.21 tar.xz
./configure --prefix=/usr
make
make install
end

## 8.15. Bc-7.0.3
begin bc-7.0.3 tar.xz
CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r
make
make install
end

## 8.16. Flex-2.6.4
begin flex-2.6.4 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/flex-2.6.4
make
make install
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1
end

## 8.17. Tcl-8.6.18
begin tcl8.6.18 tar.gz
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath
make
sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.13|/usr/lib/tdbc1.1.13|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.13/generic|/usr/include|"     \
    -e "s|$SRCDIR/pkgs/tdbc1.1.13/library|/usr/lib/tcl8.6|"  \
    -e "s|$SRCDIR/pkgs/tdbc1.1.13|/usr/include|"             \
    -i pkgs/tdbc1.1.13/tdbcConfig.sh
sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.7|/usr/lib/itcl4.3.7|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.7/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.7|/usr/include|"            \
    -i pkgs/itcl4.3.7/itclConfig.sh
unset SRCDIR
make install
chmod 644 /usr/lib/libtclstub8.6.a
chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv -v /usr/share/man/man3/{Thread,Tcl_Thread}.3
cd ..
tar -xf ../tcl8.6.18-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.18
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.18
end

## 8.18. Expect-5.45.4
begin expect5.45.4 tar.gz
patch -Np1 -i ../expect-5.45.4-gcc15-1.patch
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
make
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
end

## 8.19. DejaGNU-1.6.3
begin dejagnu-1.6.3 tar.gz
mkdir build && cd build
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
end

## 8.20. Ninja-1.13.2
begin ninja-1.13.2 tar.gz
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap --verbose
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
end

## 8.21. Pkgconf-3.0.5
begin pkgconf-3.0.5 tar.xz
tar -xf ../meson-1.12.0.tar.gz
mkdir build && cd build
python3 ../meson-1.12.0/meson.py setup --prefix=/usr --buildtype=release ..
ninja
ninja install
mv /usr/share/doc/pkgconf{,-3.0.5}
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
end

## 8.22. Binutils-2.47
begin binutils-2.47 tar.xz
mkdir build && cd build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --with-lib-path=/usr/lib \
             --enable-default-hash-style=gnu
make tooldir=/usr
make tooldir=/usr install
rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/
end

## 8.23. GMP-6.3.0
begin gmp-6.3.0 tar.xz
sed -i '/long long t1;/,+1s/()/(...)/' configure
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
make
make html
make install
make install-html
end

## 8.24. MPFR-4.2.2
begin mpfr-4.2.2 tar.xz
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.2
make
make html
make install
make install-html
end

## 8.25. MPC-1.4.1
begin mpc-1.4.1 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.4.1
make
make html
make install
make install-html
end

## 8.26. Attr-2.6.0
begin attr-2.6.0 tar.gz
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.6.0
make
make install
end

## 8.27. Acl-2.4.0
begin acl-2.4.0 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/acl-2.4.0
make
make install
end

## 8.28. Libcap-2.78
begin libcap-2.78 tar.xz
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make prefix=/usr lib=lib install
end

## 8.29. Libxcrypt-4.5.2
begin libxcrypt-4.5.2 tar.xz
sed -i '/strchr/s/const//' lib/crypt-{sm3,gost}-yescrypt.c
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens
make
make install
make distclean
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=glibc  \
            --disable-static             \
            --disable-failure-tokens
make
cp -av --remove-destination .libs/libcrypt.so.1* /usr/lib
end

## 8.30. Shadow-4.20.2
begin shadow-4.20.2 tar.xz
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -e 's:#ENCRYPT_METHOD SHA512:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                      \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                     \
    -i etc/login.defs
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --disable-logind    \
            --with-group-name-max-length=32
make
make exec_prefix=/usr install
make -C man install-man
pwconv
grpconv
mkdir -p /etc/default
useradd -D --gid 999
sed -i '/MAIL/s/yes/no/' /etc/default/useradd
touch /etc/sub{u,g}id
end

## 8.31. Gawk-5.4.1
begin gawk-5.4.1 tar.xz
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make
rm -f /usr/bin/gawk-5.4.1
make install
ln -sv gawk.1 /usr/share/man/man1/awk.1
install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.4.1
end

## 8.32. GCC-16.2.0
begin gcc-16.2.0 tar.xz
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir build && cd build
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --enable-targets=all     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib
make
make install
chown -v -R root:root $(gcc -print-file-name=include){,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfvr $(gcc -print-prog-name=liblto_plugin.so) /usr/lib/bfd-plugins/
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
end

## 8.33. Ncurses-6.6
begin ncurses-6.6 tar.gz
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
make
make DESTDIR=$PWD/dest install
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp --remove-destination -av dest/* /
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done
ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.6
make distclean
./configure --prefix=/usr    \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding \
            --with-abi-version=5
make sources libs
cp -av lib/lib*.so.5* /usr/lib
end

## 8.34. Sed-4.10
begin sed-4.10 tar.xz
./configure --prefix=/usr
make
make html
make install
install -vDm644 doc/sed.html -t /usr/share/doc/sed-4.10
end

## 8.35. Psmisc-23.7
begin psmisc-23.7 tar.xz
./configure --prefix=/usr
make
make install
end

## 8.36. Gettext-1.0
begin gettext-1.0 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-1.0
make
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
end

## 8.37. Bison-3.8.2
begin bison-3.8.2 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make
make install
end

## 8.38. Grep-3.12
begin grep-3.12 tar.xz
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
make
make install
end

## 8.39. Bash-5.3
begin bash-5.3 tar.gz
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.3
make
make install
end

## 8.40. Libtool-2.6.2
begin libtool-2.6.2 tar.xz
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libltdl.a
end

## 8.41. GDBM-1.26
begin gdbm-1.26 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
make
make install
end

## 8.42. Gperf-3.3
begin gperf-3.3 tar.gz
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.3
make
make install
end

## 8.43. Expat-2.8.3
begin expat-2.8.3 tar.xz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.8.3
make
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.8.3
end

## 8.44. Inetutils-2.8
begin inetutils-2.8 tar.gz
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make
make install
mv -v /usr/{,s}bin/ifconfig
end

## 8.45. Less-704
begin less-704 tar.gz
./configure --prefix=/usr --sysconfdir=/etc
make
make install
end

## 8.46. Perl-5.44.0
begin perl-5.44.0 tar.xz
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.44/core_perl      \
             -D archlib=/usr/lib/perl5/5.44/core_perl      \
             -D sitelib=/usr/lib/perl5/5.44/site_perl      \
             -D sitearch=/usr/lib/perl5/5.44/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.44/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.44/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads
make
make install
unset BUILD_ZLIB BUILD_BZIP2
end

## 8.47. Autoconf-2.73
begin autoconf-2.73 tar.xz
./configure --prefix=/usr
make
make install
end

## 8.48. Automake-1.18.1
begin automake-1.18.1 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.18.1
make
make install
end

## 8.49. OpenSSL-4.0.1
begin openssl-4.0.1 tar.gz
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
make INSTALL_LIBS= MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-4.0.1
cp -vfr doc/* /usr/share/doc/openssl-4.0.1
end

## 8.50. Libelf from Elfutils-0.195
begin elfutils-0.195 tar.bz2
./configure --prefix=/usr        \
            --disable-debuginfod \
            --enable-libdebuginfod=dummy
make -C lib
make -C libelf
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
end

## 8.51. Libffi-3.8.0
begin libffi-3.8.0 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --with-gcc-arch=native
make
make install
end

## 8.52. Sqlite-3530400
begin sqlite-autoconf-3530400 tar.gz
python3 -m zipfile -e ../sqlite-doc-3530400.zip .
./configure --prefix=/usr     \
            --disable-static  \
            --enable-fts{4,5} \
            CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 \
                      -D SQLITE_ENABLE_UNLOCK_NOTIFY=1   \
                      -D SQLITE_ENABLE_DBSTAT_VTAB=1     \
                      -D SQLITE_SECURE_DELETE=1"
make LDFLAGS.rpath=""
make install
cp -v -R sqlite-doc-3530400 -T /usr/share/doc/sqlite-3.53.4
end

## 8.53. mpdecimal-4.0.1
begin mpdecimal-4.0.1 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpdecimal-4.0.1
make
make install
end

## 8.54. Python-3.14.7
begin Python-3.14.7 tar.xz
patch -Np1 -i ../Python-3.14.7-openssl_4-1.patch
./configure --prefix=/usr          \
            --enable-shared        \
            --with-system-expat    \
            --enable-optimizations \
            --without-static-libpython
make
make install
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
install -v -dm755 /usr/share/doc/python-3.14.7/html
tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.14.7/html \
    -xvf ../python-3.14.7-docs-html.tar.bz2
end

## 8.55. Flit-Core-4.0.2
begin flit_core-4.0.2 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist flit_core
end

## 8.56. Packaging-26.3
begin packaging-26.3 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist packaging
end

## 8.57. Wheel-0.48.0
begin wheel-0.48.0 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist wheel
end

## 8.58. Setuptools-84.0.0
begin setuptools-84.0.0 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools
end

## 8.59. Meson-1.12.0
begin meson-1.12.0 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
end

## 8.60. Kmod-34.2
begin kmod-34.2 tar.xz
mkdir -p build
cd       build
meson setup --prefix=/usr ..    \
            --buildtype=release \
            -D manpages=false
ninja
ninja install
end

## 8.61. Coreutils-9.11
begin coreutils-9.11 tar.xz
patch -Np1 -i ../coreutils-9.11-i18n-1.patch
autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr
make
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
end

## 8.62. Diffutils-3.12
begin diffutils-3.12 tar.xz
./configure --prefix=/usr
make
make install
end

## 8.63. Findutils-4.11.0
begin findutils-4.11.0 tar.xz
./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make install
end

## 8.64. Groff-1.24.1
begin groff-1.24.1 tar.gz
PAGE=A4 ./configure --prefix=/usr
make -j1
make install
end

## 8.65. GRUB-2.14
begin grub-2.14 tar.xz
unset {C,CPP,CXX,LD}FLAGS
sed 's/--image-base/--nonexist-linker-option/' -i configure
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-efiemu  \
            --disable-werror
make
make install
make clean
./configure --prefix=/usr       \
            --sysconfdir=/etc   \
            --target=x86_64     \
            --with-platform=efi \
            --disable-efiemu    \
            --disable-werror
make
make install
make clean
./configure --prefix=/usr       \
            --sysconfdir=/etc   \
            --target=i386       \
            --with-platform=efi \
            --disable-efiemu    \
            --disable-werror
make
make install
end

## 8.66. Gzip-1.14
begin gzip-1.14 tar.xz
./configure --prefix=/usr
make
make install
end

## 8.67. IPRoute2-7.1.0
begin iproute2-7.1.0 tar.xz
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
install -vDm644 COPYING README* -t /usr/share/doc/iproute2-7.1.0
end

## 8.68. Kbd-2.10.0
begin kbd-2.10.0 tar.xz
patch -Np1 -i ../kbd-2.10.0-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make
make install
cp -R -v docs/doc -T /usr/share/doc/kbd-2.10.0
end

## 8.69. Libpipeline-1.5.8
begin libpipeline-1.5.8 tar.gz
./configure --prefix=/usr
make
make install
end

## 8.70. Make-4.4.1
begin make-4.4.1 tar.gz
./configure --prefix=/usr
make
make install
end

## 8.71. Patch-2.8
begin patch-2.8 tar.xz
./configure --prefix=/usr
make
make install
end

## 8.72. Tar-1.35
begin tar-1.35 tar.xz
patch -Np1 -i ../tar-1.35-acl_fix-1.patch
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
make
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35
end

## 8.73. Texinfo-7.3
begin texinfo-7.3 tar.xz
./configure --prefix=/usr
make
make install
make TEXMF=/usr/share/texmf install-tex
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null || true
  done
popd
end

## 8.74. Vim-9.2.1025
begin vim-9.2.1025 tar.gz
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make
make install
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
ln -sv ../vim/vim92/doc /usr/share/doc/vim-9.2.1025
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
end

## 8.75. MarkupSafe-3.0.3
begin markupsafe-3.0.3 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Markupsafe
end

## 8.76. Jinja2-3.1.6
begin jinja2-3.1.6 tar.gz
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Jinja2
end

## 8.77. Systemd-261.2
begin systemd-261.2 tar.gz
sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //'               \
    -i rules.d/50-udev-default.rules.in
mkdir -p build
cd build
meson setup ..                \
      --prefix=/usr           \
      --buildtype=release     \
      -D default-dnssec=no    \
      -D firstboot=false      \
      -D install-tests=false  \
      -D ldconfig=false       \
      -D sysusers=false       \
      -D rpmmacrosdir=no      \
      -D homed=disabled       \
      -D man=disabled         \
      -D mode=release         \
      -D pamconfdir=no        \
      -D dev-kvm-mode=0660    \
      -D nobody-group=nogroup \
      -D sysupdate=disabled   \
      -D ukify=disabled       \
      -D docdir=/usr/share/doc/systemd-261.2
ninja
ninja install
tar -xf ../../systemd-man-pages-261.2.tar.xz \
    --no-same-owner --strip-components=1     \
    -C /usr/share/man
systemd-machine-id-setup
systemctl preset-all
end

## 8.78. D-Bus-1.16.2
begin dbus-1.16.2 tar.xz
mkdir build
cd build
meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..
ninja
ninja install
ln -sfv /etc/machine-id /var/lib/dbus
end

## 8.79. Man-DB-2.13.1
begin man-db-2.13.1 tar.xz
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.13.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap
make
make install
end

## 8.80. Procps-ng-4.0.7
begin procps-ng-4.0.7 tar.xz
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.7 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit                      \
            --with-systemd
make
make install
end

## 8.81. Util-linux-2.42.2
begin util-linux-2.42.2 tar.xz
./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.42.2
make
make install
end

## 8.82. E2fsprogs-1.47.4
begin e2fsprogs-1.47.4 tar.gz
mkdir -v build
cd build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-elf-shlibs \
             --disable-libblkid  \
             --disable-libuuid   \
             --disable-uuidd     \
             --disable-fsck
make
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf
end
