#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear

libiconvVersion='libiconv-1.15'
libgdVersion='libgd-2.2.5'
pcreVersion='pcre-8.41'
zlibVersion='zlib-1.2.11'
opensslVersion='openssl-1.1.0f'
phpVersion='php-7.2.0'
nginxVersion='nginx-1.13.7'

cpuNum=$(grep -c 'processor' < /proc/cpuinfo)

function showNotice() {
  echo -e "\n\033[36m[NOTICE]\033[0m $1"
}

function installReady() {
  showNotice "Install packages ..."
  if [ "$(rpm -qa epel-release | wc -l)" == "0" ]
  then
    yum install -y epel-release
    yum makecache fast
  fi
  yum install -y make gcc gcc-c++ perl libpng-devel libjpeg-devel libwebp-devel libXpm-devel libtiff-devel libxml2-devel libcurl-devel libmcrypt-devel fontconfig-devel freetype-devel libzip-devel bzip2-devel gmp-devel readline-devel recode-devel GeoIP-devel bison re2c

  [ -f /etc/ld.so.conf.d/custom-libs.conf ] && rm -rf /etc/ld.so.conf.d/custom-libs.conf

  groupadd www
  useradd -m -s /sbin/nologin -g www www
}

function installPackage() {
  if [ ! -d "/usr/local/$1" ]
  then
    first=$(echo "${1:0:1}" | tr '[:lower:]' '[:upper:]')
    other="${1:1}"
    func="install${first}${other}"
    $func 'Install'
  else
    showNotice "$1 is installed"
  fi
}

function upgradePackage() {
  if [ -d "/usr/local/$1" ]
  then
    first=$(echo "${1:0:1}" | tr '[:lower:]' '[:upper:]')
    other="${1:1}"
    func="install${first}${other}"
    $func 'Upgrade'
  else
    showNotice "$1 is not installed"
  fi
}

function installLibiconv() {
  cd /tmp || exit

  if [ ! -f "${libiconvVersion}.tar.gz" ]
  then
    showNotice "Download ${libiconvVersion} ..."
    curl -O --retry 3 https://ftp.gnu.org/pub/gnu/libiconv/${libiconvVersion}.tar.gz
  fi

  showNotice "$1 ${libiconvVersion} ..."
  tar -zxf ${libiconvVersion}.tar.gz

  cd ${libiconvVersion} || exit
  ./configure --prefix=/usr/local/libiconv
  make -j "$cpuNum"
  make install
  echo '/usr/local/libiconv/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function installPcre() {
  cd /tmp || exit

  if [ ! -f "${pcreVersion}.tar.gz" ]
  then
    showNotice "Download ${pcreVersion} ..."
    curl -O --retry 3 https://ftp.pcre.org/pub/pcre/${pcreVersion}.tar.gz
  fi

  showNotice "$1 ${pcreVersion} ..."
  tar -zxf ${pcreVersion}.tar.gz -C /usr/local/src/

  cd /usr/local/src/${pcreVersion} || exit
  ./configure \
    --prefix=/usr/local/pcre \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties
  make -j "$cpuNum"
  make install
  echo '/usr/local/pcre/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function installZlib() {
  cd /tmp || exit

  if [ ! -f "${zlibVersion}.tar.gz" ]
  then
    showNotice "Download ${zlibVersion} ..."
    curl -O --retry 3 http://zlib.net/${zlibVersion}.tar.gz
  fi

  showNotice "$1 ${zlibVersion} ..."
  tar -zxf ${zlibVersion}.tar.gz -C /usr/local/src/

  cd /usr/local/src/${zlibVersion} || exit
  ./configure --prefix=/usr/local/zlib
  make -j "$cpuNum"
  make install
  echo '/usr/local/zlib/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function installLibgd() {
  cd /tmp || exit

  if [ ! -f "${libgdVersion}.tar.gz" ]
  then
    showNotice "Download ${libgdVersion} ..."
    curl -O --retry 3 -L https://github.com/libgd/libgd/releases/download/${libgdVersion/lib/}/${libgdVersion}.tar.gz
  fi

  showNotice "$1 ${libgdVersion} ..."
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
  make -j "$cpuNum"
  make install
  echo '/usr/local/libgd/lib' >> /etc/ld.so.conf.d/custom-libs.conf
  ldconfig
}

function installOpenssl() {
  cd /tmp || exit

  if [ ! -f "${opensslVersion}.tar.gz" ]
  then
    showNotice "Download ${opensslVersion} ..."
    curl -O --retry 3 https://www.openssl.org/source/${opensslVersion}.tar.gz
  fi

  showNotice "$1 ${opensslVersion} ..."
  tar -zxf ${opensslVersion}.tar.gz -C /usr/local/src/

  cd /usr/local/src/${opensslVersion} || exit
  ./config --prefix=/usr/local/openssl -fPIC
  make -j "$cpuNum"
  make install
  ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl
}

function installPhp {
  cd /tmp || exit

  if [ ! -f "${phpVersion}.tar.gz" ]
  then
    showNotice "Download ${phpVersion} ..."
    curl -O --retry 3 http://php.net/distributions/${phpVersion}.tar.gz
  fi

  showNotice "$1 ${phpVersion} ..."
  tar -zxf ${phpVersion}.tar.gz

  cd ${phpVersion} || exit
  ./configure \
    --prefix=/usr/local/php \
    --sysconfdir=/etc/php \
    --with-config-file-path=/etc/php \
    --with-config-file-scan-dir=/etc/php/php-fpm.d \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-curl \
    --with-mhash \
    --with-gd \
    --with-gmp \
    --with-bz2 \
    --with-recode \
    --with-readline \
    --with-gettext \
    --with-pcre-jit \
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
  make -j "$cpuNum"
  make install
  ln -sf /usr/local/php/bin/php /usr/bin/php
  ln -sf /usr/local/php/bin/phpize /usr/bin/phpize
  ln -sf /usr/local/php/sbin/php-fpm /usr/bin/php-fpm
  cp -v php.ini-production /etc/php/php.ini
}

function installNginx() {
  cd /tmp || exit

  if [ ! -f "${nginxVersion}.tar.gz" ]
  then
    showNotice "Download ${nginxVersion} ..."
    curl -O --retry 3 http://nginx.org/download/${nginxVersion}.tar.gz
  fi

  showNotice "$1 ${nginxVersion} ..."
  tar -zxf ${nginxVersion}.tar.gz

  cd ${nginxVersion} || exit
  mkdir -p /var/cache/nginx
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
  make -j "$cpuNum"
  make install
  ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx
}

function cleanFiles() {
  showNotice "Clean files ..."
  rm -rfv /tmp/${libiconvVersion}*
  rm -rfv /tmp/${libgdVersion}*
  rm -rfv /tmp/${pcreVersion}*
  rm -rfv /tmp/${zlibVersion}*
  rm -rfv /tmp/${opensslVersion}*
  rm -rfv /tmp/${phpVersion}*
  rm -rfv /tmp/${nginxVersion}*
}

while :
do
clear
  echo ' _         _   _      __  __      ____  '
  echo '| |       | \ | |    |  \/  |    |  _ \ '
  echo '| |       |  \| |    | |\/| |    | |_) |'
  echo '| |___    | |\  |    | |  | |    |  __/ '
  echo '|_____|   |_| \_|    |_|  |_|    |_|    '
  echo ''
  echo -e 'For more details see \033[4mhttps://git.io/lnmp\033[0m'
  echo ''
  showNotice 'Please select your operation:'
  echo '1) Install'
  echo '2) Uninstall'
  echo '3) Upgrade packages'
  echo '4) Exit'
  read -p 'Select an option [1-4]: ' -r -e operation
  case $operation in
    1)
      installReady
      installPackage 'libiconv'
      installPackage 'pcre'
      installPackage 'zlib'
      installPackage 'libgd'
      installPackage 'openssl'
      installPackage 'php'
      installPackage 'nginx'
      cleanFiles
      /usr/bin/openssl version
      /usr/bin/php -v
      /usr/bin/nginx -v
      showNotice 'Install complete!'
    exit
    ;;
    2)
      rm -rfv /etc/ld.so.conf.d/custom-libs.conf
      rm -rfv /usr/local/libiconv
      rm -rfv /usr/local/pcre
      rm -rfv /usr/local/zlib
      rm -rfv /usr/local/libgd
      rm -rfv /usr/local/openssl
      rm -rfv /usr/local/php
      rm -rfv /usr/local/nginx
      rm -rfv /usr/bin/php
      rm -rfv /usr/bin/phpize
      rm -rfv /usr/bin/php-fpm
      rm -rfv /usr/bin/nginx
      rm -rfv /etc/php
      rm -rfv /etc/nginx
      rm -rfv /var/cache/nginx
      rm -rfv /var/log/nginx
      showNotice "All packages have been uninstalled"
    exit
    ;;
    3)
      showNotice "Checking, please wait..."
      yum upgrade
      if [ -f /etc/ld.so.conf.d/custom-libs.conf ]
      then
        rm -rf /etc/ld.so.conf.d/custom-libs.conf
      fi
      upgradePackage 'libiconv'
      upgradePackage 'pcre'
      upgradePackage 'zlib'
      upgradePackage 'libgd'
      upgradePackage 'openssl'
      upgradePackage 'php'
      upgradePackage 'nginx'
      cleanFiles
    exit
    ;;
    4)
      showNotice "Nothing to do..."
    exit;;
  esac
done
