#!/bin/bash
# Entering chroot and building additional temporary tools(chapter 7).
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
  cd $LFS/sources
  rm -rf $package_name
}

cd $LFS/sources

## 7.7. Libstdc++ from GCC-11.2.0, Pass 2
begin gcc-11.2.0 tar.xz
ln -s gthr-posix.h libgcc/gthr-default.h
mkdir build && cd build
../libstdc++-v3/configure CXXFLAGS="-g -O2 -D_GNU_SOURCE"  \
                          --prefix=/usr                    \
                          --disable-multilib               \
                          --disable-nls                    \
                          --host=$(uname -m)-lfs-linux-gnu \
                          --disable-libstdcxx-pch
make
make install
end

## 7.8. Gettext-0.21
begin gettext-0.21 tar.xz
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
end

## 7.9. Bison-3.7.6
begin bison-3.7.6 tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.7.6
make
make install
end

## 7.10. Perl-5.34.0
begin perl-5.34.0 tar.xz
sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Dprivlib=/usr/lib/perl5/5.34/core_perl     \
             -Darchlib=/usr/lib/perl5/5.34/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.34/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.34/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.34/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.34/vendor_perl
make
make install
end

## 7.11. Python-3.9.6
begin Python-3.9.6 tar.xz
./configure --prefix=/usr       \
            --enable-shared     \
            --without-ensurepip
make build_all
make install
end

## 7.12. Texinfo-6.8
begin texinfo-6.8 tar.xz
sed -e 's/__attribute_nonnull__/__nonnull/' -i gnulib/lib/malloc/dynarray-skeleton.c
./configure --prefix=/usr
make
make install
end

## 7.13. Util-linux-2.37.2
begin util-linux-2.37.2 tar.xz
mkdir -pv /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime     \
            --libdir=/usr/lib                         \
            --docdir=/usr/share/doc/util-linux-2.37.2 \
            --disable-chfn-chsh                       \
            --disable-login                           \
            --disable-nologin                         \
            --disable-su                              \
            --disable-setpriv                         \
            --disable-runuser                         \
            --disable-pylibmount                      \
            --disable-static                          \
            --without-python                          \
            runstatedir=/run
make
make install
end
