#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear

libiconvVersion='libiconv-1.15'
libgdVersion='libgd-2.2.4'
pcreVersion='pcre-8.40'
zlibVersion='zlib-1.2.11'
opensslVersion='openssl-1.0.2k'
phpVersion='php-7.1.4'
nginxVersion='nginx-1.12.0'

showNotice() {
  echo -e "\n\033[36m[NOTICE]\033[0m $1"
}

function install_ready() {
  showNotice "Install packages ..."
  if [ "$(rpm -qa epel-release | wc -l)" == "0" ]
  then
    yum install -y epel-release
    yum clean all
    yum makecache fast
  fi
  yum install -y gcc gcc-c++ perl libpng-devel libjpeg-devel libwebp-devel libXpm-devel libtiff-devel libxml2-devel libcurl-devel libmcrypt-devel freetype-devel libzip-devel bzip2-devel gmp-devel readline-devel recode-devel GeoIP-devel bison re2c

  [ -f /etc/ld.so.conf.d/custom-libs.conf ] && rm -rf /etc/ld.so.conf.d/custom-libs.conf
}

function install_libiconv() {
  if [ ! -d '/usr/local/libiconv' ]
  then
    showNotice "Download ${libiconvVersion} ..."
    curl -O --retry 3 https://ftp.gnu.org/pub/gnu/libiconv/${libiconvVersion}.tar.gz

    showNotice "Install ${libiconvVersion} ..."
    tar -zxf ${libiconvVersion}.tar.gz
    cd ${libiconvVersion} || exit
    ./configure --prefix=/usr/local/libiconv
    make
    make install
  fi
  echo '/usr/local/libiconv/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function install_pcre() {
  if [ ! -d '/usr/local/pcre' ]
  then
    showNotice "Download ${pcreVersion} ..."
    curl -O --retry 3 https://ftp.pcre.org/pub/pcre/${pcreVersion}.tar.gz

    showNotice "Install ${pcreVersion} ..."
    tar -zxf ${pcreVersion}.tar.gz
    cd ${pcreVersion} || exit
    ./configure --prefix=/usr/local/pcre
    make
    make install
  fi
  echo '/usr/local/pcre/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function install_zlib() {
  if [ ! -d '/usr/local/zlib' ]
  then
    showNotice "Download ${zlibVersion} ..."
    curl -O --retry 3 http://zlib.net/${zlibVersion}.tar.gz

    showNotice "Install ${zlibVersion} ..."
    tar -zxf ${zlibVersion}.tar.gz
    cd ${zlibVersion} || exit
    ./configure --prefix=/usr/local/zlib
    make
    make install
  fi
  echo '/usr/local/zlib/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function install_gd() {
  if [ ! -d '/usr/local/libgd' ]
  then
    showNotice "Download ${libgdVersion} ..."
    curl -O --retry 3 http://7xn5mr.dl1.z0.glb.clouddn.com/${libgdVersion}.tar.gz

    showNotice "Install ${libgdVersion} ..."
    tar -zxf ${libgdVersion}.tar.gz
    cd ${libgdVersion} || exit
    ./configure \
      --prefix=/usr/local/libgd \
      --with-libiconv-prefix=/usr/local/libiconv \
      --with-zlib=/usr/local/zlib \
      --with-jpeg=/usr \
      --with-png=/usr \
      --with-webp=/usr \
      --with-xpm=/usr \
      --with-freetype=/usr \
      --with-fontconfig=/usr \
      --with-tiff=/usr
    make
    make install
  fi
  echo '/usr/local/libgd/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function install_openssl() {
  if [ ! -d '/usr/local/openssl' ]
  then
    showNotice "Download ${opensslVersion} ..."
    curl -O --retry 3 http://7xn5mr.dl1.z0.glb.clouddn.com/${opensslVersion}.tar.gz

    showNotice "Install ${opensslVersion} ..."
    tar -zxf ${opensslVersion}.tar.gz
    cd ${opensslVersion} || exit
    ./config --prefix=/usr/local/openssl -fPIC
    make
    make install
  fi
}

function install_php() {
  if [ ! -d '/usr/local/php71' ]
  then
    showNotice "Download ${phpVersion} ..."
    curl -O --retry 3 http://cn2.php.net/distributions/${phpVersion}.tar.gz

    showNotice "Install ${phpVersion} ..."
    tar -zxf ${phpVersion}.tar.gz
    cd ${phpVersion} || exit
    # ln -sf /usr/lib64/libc-client.so /usr/lib/libc-client.so
    ./configure \
      --prefix=/usr/local/php71 \
      --sysconfdir=/etc/php \
      --with-config-file-path=/etc/php71 \
      --with-config-file-scan-dir=/etc/php71/conf.d \
      --with-fpm-user=www \
      --with-fpm-group=www \
      --with-curl \
      --with-mhash \
      --with-mcrypt \
      --with-gd \
      --with-gmp \
      --with-bz2 \
      --with-recode \
      --with-readline \
      --with-gettext \
      --with-mysqli=mysqlnd \
      --with-pdo-mysql=mysqlnd \
      --with-openssl=/usr/local/openssl \
      --with-openssl-dir=/usr/local/openssl \
      --with-pcre-regex=/usr/local/pcre \
      --with-pcre-dir=/usr/local/pcre \
      --with-zlib=/usr/local/zlib \
      --with-zlib-dir=/usr/local/zlib \
      --with-iconv-dir=/usr/local/libiconv \
      --with-libxml-dir=/usr \
      --with-libzip=/usr \
      --with-gd=/usr/local/libgd \
      --with-jpeg-dir=/usr \
      --with-png-dir=/usr \
      --with-webp-dir=/usr \
      --with-xpm-dir=/usr \
      --with-freetype-dir=/usr \
      --enable-fpm \
      --enable-ftp \
      --enable-gd-native-ttf \
      --enable-gd-jis-conv \
      --enable-calendar \
      --enable-exif \
      --enable-pcntl \
      --enable-soap \
      --enable-shmop \
      --enable-sysvmsg \
      --enable-sysvsem \
      --enable-sysvshm \
      --enable-wddx \
      --enable-inline-optimization \
      --enable-bcmath \
      --enable-mbstring \
      --enable-mbregex \
      --enable-re2c-cgoto \
      --enable-xml \
      --enable-mysqlnd \
      --enable-embedded-mysqli \
      --enable-opcache \
      --disable-fileinfo \
      --disable-debug
    make
    make install
    ln -sf /usr/local/php71/bin/php /usr/bin/php
    ln -sf /usr/local/php71/bin/phpize /usr/bin/phpize
    ln -sf /usr/local/php71/sbin/php-fpm /usr/bin/php-fpm
  fi
}

function install_nginx() {
  if [ ! -d '/usr/local/nginx' ]
  then
    [ ! -d "/usr/local/src/${pcreVersion}" ] && cp -a ${pcreVersion}/ /usr/local/src/
    [ ! -d "/usr/local/src/${zlibVersion}" ] && cp -a ${zlibVersion}/ /usr/local/src/
    [ ! -d "/usr/local/src/${opensslVersion}" ] && cp -a ${opensslVersion}/ /usr/local/src/

    show_notice "Download ${nginxVersion} ..."
    curl -O --retry 3 http://nginx.org/download/${nginxVersion}.tar.gz

    show_notice "Install ${nginxVersion} ..."
    tar -zxf ${nginxVersion}.tar.gz
    cd ${nginxVersion} || exit

    ./configure \
      --prefix=/usr/local/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
      --user=www \
      --group=www \
      --with-threads \
      --with-file-aio \
      --with-http_ssl_module \
      --with-http_v2_module \
      --with-http_realip_module \
      --with-http_addition_module \
      --with-http_geoip_module \
      --with-http_sub_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_auth_request_module \
      --with-http_random_index_module \
      --with-http_secure_link_module \
      --with-http_degradation_module \
      --with-http_slice_module \
      --with-http_stub_status_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_ssl_module \
      --with-stream_realip_module \
      --with-stream_geoip_module \
      --with-stream_ssl_preread_module \
      --with-compat \
      --with-pcre-jit \
      --with-pcre=/usr/local/src/${pcreVersion} \
      --with-zlib=/usr/local/src/${zlibVersion} \
      --with-openssl=/usr/local/src/${opensslVersion}
    make
    make install
    ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx
  fi
}

function clean_files() {
  showNotice "Clean files ..."
  rm -rfv ${libiconvVersion}.tar.gz ${libiconvVersion:?}/
  rm -rfv ${libgdVersion}.tar.gz ${libgdVersion:?}/
  rm -rfv ${pcreVersion}.tar.gz ${pcreVersion:?}/
  rm -rfv ${zlibVersion}.tar.gz ${zlibVersion:?}/
  rm -rfv ${opensslVersion}.tar.gz ${opensslVersion:?}/
  rm -rfv ${phpVersion}.tar.gz ${phpVersion:?}/
  rm -rfv ${nginxVersion}.tar.gz ${nginxVersion:?}/
}

install_ready
install_libiconv
install_pcre
install_zlib
install_gd
install_openssl
install_php
install_nginx
clean_files
