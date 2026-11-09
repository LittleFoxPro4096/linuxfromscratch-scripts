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
  cd /sources
  rm -rf $package_name
}

cd /sources

## 7.7. Gettext-1.0
begin gettext-1.0 tar.xz
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
end

## 7.8. Bison-3.8.2
begin bison-3.8.2 tar.xz
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make
make install
end

## 7.9. Perl-5.44.0
begin perl-5.44.0 tar.xz
sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.44/core_perl     \
             -D archlib=/usr/lib/perl5/5.44/core_perl     \
             -D sitelib=/usr/lib/perl5/5.44/site_perl     \
             -D sitearch=/usr/lib/perl5/5.44/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.44/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.44/vendor_perl
make
make install
end

## 7.10. Zlib-1.3.2
begin zlib-1.3.2 tar.gz
./configure --prefix=/usr
make
make install
rm -fv /usr/lib/libz.a
end

## 7.11. mpdecimal-4.0.1
begin mpdecimal-4.0.1 tar.gz
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpdecimal-4.0.1
make
make install
end

## 7.12. Python-3.14.7
begin Python-3.14.7 tar.xz
./configure --prefix=/usr       \
            --enable-shared     \
            --without-ensurepip \
            --without-static-libpython
make
make install
end

## 7.13. Texinfo-7.3
begin texinfo-7.3 tar.xz
./configure --prefix=/usr
make
make install
end

## 7.14. Util-linux-2.42.2
begin util-linux-2.42.2 tar.xz
mkdir -pv /var/lib/hwclock
./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.42.2
make
make install
end
