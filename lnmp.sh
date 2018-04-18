#!/bin/bash
#
#
# CentOS 7 LNMP
#
# * Nginx 1.12/1.13
# * MySQL 5.5/5.6/5.7/8.0(MariaDB 5.5/10.0/10.1/10.2/10.3)
# * PHP 5.4/5.5/5.6/7.0/7.1/7.2
# * phpMyAdmin(Adminer)
#
# https://github.com/maicong/LNMP
#
# Usage: sh lnmp.sh
#

# check root
[ "$(id -g)" != '0' ] && die 'Script must be run as root.'

# declare variables
envType='master'
ipAddress=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^192\\.168|^172\\.1[6-9]\\.|^172\\.2[0-9]\\.|^172\\.3[0-2]\\.|^10\\.|^127\\.|^255\\." | head -n 1) || '0.0.0.0'
mysqlPWD=$(echo -n ${RANDOM} | md5sum | cut -b -16)

mysqlUrl='https://repo.mysql.com'
mariaDBUrl='https://yum.mariadb.org'
phpUrl='https://rpms.remirepo.net'
nginxUrl='https://nginx.org'
mysqlUrl_CN='https://mirrors.ustc.edu.cn/mysql-repo'
mariaDBUrl_CN='https://mirrors.ustc.edu.cn/mariadb/yum'
phpUrl_CN='https://mirrors.ustc.edu.cn/remi'
nginxUrl_CN='https://cdn-nginx.b0.upaiyun.com'

# show success message
showOk(){
  echo -e "\\033[34m[OK]\\033[0m $1"
}

# show error message
showError(){
  echo -e "\\033[31m[ERROR]\\033[0m $1"
}

# show notice message
showNotice(){
  echo -e "\\033[36m[NOTICE]\\033[0m $1"
}

# install
runInstall(){

  showNotice 'Update...'

  while true; do
    read -p "Update YUM packages? [Y/n]" yn
    case $yn in
      [Yy]* ) yum update -y; break;;
      [Nn]* ) exit;;
      * ) echo "Please answer yes or no.";;
    esac
  done

  showNotice 'Installing...'

  showNotice '(Step 1/6) Input server IPv4 Address'
  read -p "IP address: " -r -e -i "${ipAddress}" ipAddress
  if [ "${ipAddress}" = '' ]; then
    showError 'Invalid IP Address'
    exit
  fi

  showNotice "(Step 2/6) Select the MySQL version"
  echo "1) MariaDB-5.5"
  echo "2) MariaDB-10.0"
  echo "3) MariaDB-10.1"
  echo "4) MariaDB-10.2"
  echo "5) MariaDB-10.3"
  echo "6) MySQL-5.5"
  echo "7) MySQL-5.6"
  echo "8) MySQL-5.7"
  echo "9) MySQL-8.0"
  echo "0) Not need"
  read -p 'MySQL [1-9,0]: ' -r -e -i 5 mysqlV
  if [ "${mysqlV}" = '' ]; then
    showError 'Invalid MySQL version'
    exit
  fi

  showNotice "(Step 3/6) Select the PHP version"
  echo "1) PHP-5.4"
  echo "2) PHP-5.5"
  echo "3) PHP-5.6"
  echo "4) PHP-7.0"
  echo "5) PHP-7.1"
  echo "6) PHP-7.2"
  echo "0) Not need"
  read -p 'PHP [1-6,0]: ' -r -e -i 6 phpV
  if [ "${phpV}" = '' ]; then
    showError 'Invalid PHP version'
    exit
  fi

  showNotice "(Step 4/6) Select the Nginx version"
  echo "1) Nginx-1.12"
  echo "2) Nginx-1.13"
  echo "0) Not need"
  read -p 'Nginx [1-2,0]: ' -r -e -i 2 nginxV
  if [ "${nginxV}" = '' ]; then
    showError 'Invalid Nginx version'
    exit
  fi

  showNotice "(Step 5/6) Select the DB tool version"
  echo "1) Adminer"
  echo "2) phpMyAdmin"
  echo "0) Not need"
  read -p 'DB tool [1-3]: ' -r -e -i 0 dbV
  if [ "${dbV}" = '' ]; then
    showError 'Invalid DB tool version'
    exit
  fi

  showNotice "(Step 6/6) Use a mirror server to download rpms"
  echo "1) Source station"
  echo "2) Mirror station"
  read -p 'Proxy server [1-2]: ' -r -e -i 1 freeV
  if [ "${freeV}" = '' ]; then
    showError 'Invalid Proxy server'
    exit
  fi

  [ ! -x "/usr/bin/curl" ] && yum install curl -y
  [ ! -x "/usr/bin/unzip" ] && yum install unzip -y

  if [ ! -d "/tmp/LNMP-${envType}" ]; then
    cd /tmp || exit
    if [ ! -f "LNMP-${envType}.zip" ]; then
      if ! curl -L --retry 3 -o "LNMP-${envType}.zip" "https://github.com/maicong/LNMP/archive/${envType}.zip"
      then
        showError "LNMP-${envType} download failed!"
        exit
      fi
    fi
    unzip -q "LNMP-${envType}.zip"
  fi

  [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0 >/dev/null 2>&1

  yumRepos=$(find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" -type f | wc -l)

  if [ "${yumRepos}" = '0' ]; then
    curl --retry 3 -o /etc/yum.repos.d http://mirrors.aliyun.com/repo/Centos-7.repo
    yum clean all
    yum makecache
  fi

  startDate=$(date)
  startDateSecond=$(date +%s)

  showNotice 'Installing'

  mysqlRepoUrl=${mysqlUrl}
  mariaDBRepoUrl=${mariaDBUrl}
  phpRepoUrl=${phpUrl}
  nginxRepoUrl=${nginxUrl}

  if [ "${freeV}" = "2" ]; then
    mysqlRepoUrl=${mysqlUrl_CN}
    mariaDBRepoUrl=${mariaDBUrl_CN}
    phpRepoUrl=${phpUrl_CN}
    nginxRepoUrl=${nginxUrl_CN}
  fi

  yum install -y epel-release yum-utils firewalld firewall-config

  if [ "${mysqlV}" != '0' ]; then
    if [[ "${mysqlV}" = "1" || "${mysqlV}" = "2" || "${mysqlV}" = "3" || "${mysqlV}" = "4" || "${mysqlV}" = "5" ]]; then
      mariadbV='10.1'
      installDB='mariadb'
      case ${mysqlV} in
        1)
        mariadbV='5.5'
        ;;
        2)
        mariadbV='10.0'
        ;;
        3)
        mariadbV='10.1'
        ;;
        4)
        mariadbV='10.2'
        ;;
        5)
        mariadbV='10.3'
        ;;
      esac
      echo -e "[mariadb]\\nname = MariaDB\\nbaseurl = ${mariaDBRepoUrl}/${mariadbV}/centos7-amd64\\ngpgkey=${mariaDBRepoUrl}/RPM-GPG-KEY-MariaDB\\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo
    elif [[ "${mysqlV}" = "6" || "${mysqlV}" = "7" || "${mysqlV}" = "8" || "${mysqlV}" = "9" ]]; then
      rpm --import /tmp/LNMP-${envType}/keys/RPM-GPG-KEY-mysql
      rpm -Uvh ${mysqlRepoUrl}/mysql57-community-release-el7-11.noarch.rpm
      find /etc/yum.repos.d/ -maxdepth 1 -name "mysql-community*.repo" -type f -print0 | xargs -0 sed -i "s@${mysqlUrl}@${mysqlRepoUrl}@g"
      installDB='mysqld'

      case ${mysqlV} in
        6)
        yum-config-manager --enable mysql55-community
        yum-config-manager --disable mysql56-community mysql57-community mysql80-community
        ;;
        7)
        yum-config-manager --enable mysql56-community
        yum-config-manager --disable mysql55-community mysql57-community mysql80-community
        ;;
        8)
        yum-config-manager --enable mysql57-community
        yum-config-manager --disable mysql55-community mysql56-community mysql80-community
        ;;
        9)
        yum-config-manager --enable mysql80-community
        yum-config-manager --disable mysql55-community mysql56-community mysql57-community
        ;;
      esac
    fi
  fi

  if [ "${phpV}" != '0' ]; then
    sedPhpRepo() {
      find /etc/yum.repos.d/ -maxdepth 1 -name "remi*.repo" -type f -print0 | xargs -0 sed -i "$1"
    }

    rpm --import /tmp/LNMP-${envType}/keys/RPM-GPG-KEY-remi
    rpm -Uvh ${phpRepoUrl}/enterprise/remi-release-7.rpm

    sedPhpRepo "s@${phpUrl}@${phpRepoUrl}@g"

    if [ "${freeV}" = "1" ]; then
      sedPhpRepo "/\$basearch/{n;s/^baseurl=/#baseurl=/g}"
      sedPhpRepo "/\$basearch/{n;n;s/^#mirrorlist=/mirrorlist=/g}"
    elif [ "${freeV}" = "2" ]; then
      sedPhpRepo "/\$basearch/{n;s/^#baseurl=/baseurl=/g}"
      sedPhpRepo "/\$basearch/{n;n;s/^mirrorlist=/#mirrorlist=/g}"
    fi

    yum-config-manager --enable remi remi-test

    case ${phpV} in
      1)
      yum-config-manager --enable remi-php54
      yum-config-manager --disable remi-php55 remi-php56 remi-php70 remi-php71 remi-php72
      ;;
      2)
      yum-config-manager --enable remi-php55
      yum-config-manager --disable remi-php54 remi-php56 remi-php70 remi-php71 remi-php72
      ;;
      3)
      yum-config-manager --enable remi-php56
      yum-config-manager --disable remi-php54 remi-php55 remi-php70 remi-php71 remi-php72
      ;;
      4)
      yum-config-manager --enable remi-php70
      yum-config-manager --disable remi-php54 remi-php55 remi-php56 remi-php71 remi-php72
      ;;
      5)
      yum-config-manager --enable remi-php71
      yum-config-manager --disable remi-php54 remi-php55 remi-php56 remi-php70 remi-php72
      ;;
      6)
      yum-config-manager --enable remi-php72
      yum-config-manager --disable remi-php54 remi-php55 remi-php56 remi-php70 remi-php71
      ;;
    esac
  fi

  if [ "${nginxV}" != '0' ]; then
    rpm --import /tmp/LNMP-${envType}/keys/nginx_signing.key
    rpm -Uvh ${nginxRepoUrl}/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

    nginxRepo=/etc/yum.repos.d/nginx.repo

    sed -i "s@${nginxUrl}@${nginxRepoUrl}@g" ${nginxRepo}

    if [ "${nginxV}" = "1" ]; then
      sed -i "s/\\/mainline//g" ${nginxRepo}
    elif [ "${nginxV}" = "2" ]; then
      sed -i "s/packages/packages\\/mainline/g" ${nginxRepo}
    fi
  fi

  yum clean all && yum makecache fast

  if [ "${mysqlV}" != '0' ]; then
    if [ "${installDB}" = "mariadb" ]; then
      yum install -y MariaDB-server MariaDB-client MariaDB-common
      mysql_install_db --user=mysql
    elif [ "${installDB}" = "mysqld" ]; then
      yum install -y mysql-community-server

      if [ "${mysqlV}" = "6" ]; then
        mysql_install_db --user=mysql
      elif [ "${mysqlV}" = "7" ]; then
        mysqld --initialize-insecure --user=mysql --explicit_defaults_for_timestamp
      else
        mysqld --initialize-insecure --user=mysql
      fi
    fi
  fi

  if [ "${phpV}" != '0' ]; then
    yum install -y php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pecl-crypto php-pecl-mcrypt php-pecl-geoip php-pecl-zip php-recode php-snmp php-soap php-xml

    mkdir -p /etc/php-fpm.d.stop

    if [ -d "/etc/php-fpm.d/" ]; then
      mv -bfu /etc/php-fpm.d/* /etc/php-fpm.d.stop/
    fi

    if [ -f "/etc/php.ini" ]; then
      mv -bfu /etc/php.ini /etc/php.ini.bak
    fi

    cp -a /tmp/LNMP-${envType}/etc/php* /etc/
  fi

  if [ "${nginxV}" != '0' ]; then
    yum install -y nginx

    mkdir -p /etc/nginx/{conf.d.stop,rewrite,ssl}

    if [ -d "/etc/nginx/" ]; then
      mv -bfu /etc/nginx/conf.d/* /etc/nginx/conf.d.stop/
      mv -bfu /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
      mv -bfu /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.bak
    fi

    cp -a /tmp/LNMP-${envType}/etc/nginx /etc/

    sed -i "s/localhost/${ipAddress}/g" /etc/nginx/conf.d/nginx-index.conf

    groupadd www
    useradd -m -s /sbin/nologin -g www www

    mkdir -p /home/{wwwroot,userdata}
    chown -R www:www /home/wwwroot

    cp -a "/tmp/LNMP-${envType}/home/wwwroot/index/" /home/wwwroot/
  fi

  if [[ "${phpV}" != '0' && "${nginxV}" != '0' ]]; then
    if [ "${dbV}" = "1" ]; then
      cp -a /tmp/LNMP-${envType}/DB/Adminer /home/wwwroot/index/
      sed -i "s/phpMyAdmin/Adminer/g" /home/wwwroot/index/index.html
    elif [ "${dbV}" = "2" ]; then
      yum install -y phpMyAdmin
      newHash=$(echo -n ${RANDOM} | md5sum | sed "s/ .*//" | cut -b -18)
      cp -a /tmp/LNMP-${envType}/etc/phpMyAdmin /etc/
      sed -i "s/739174021564331540/${newHash}/g" /etc/phpMyAdmin/config.inc.php
      cp -a /usr/share/phpMyAdmin /home/wwwroot/index/
      rm -rf /home/wwwroot/index/phpMyAdmin/doc/html
      cp -a /usr/share/doc/phpMyAdmin-*/html /home/wwwroot/index/phpMyAdmin/doc/
    fi
  fi

  cp -a /tmp/LNMP-${envType}/etc/rc.d /etc/

  chmod +x /etc/rc.d/init.d/vbackup
  chmod +x /etc/rc.d/init.d/vhost

  showNotice "Start service"

  systemctl enable firewalld.service
  systemctl restart firewalld.service

  firewall-cmd --permanent --zone=public --add-service=http
  firewall-cmd --permanent --zone=public --add-service=https
  firewall-cmd --reload

  if [ "${mysqlV}" != '0' ]; then
    if [[ "${mysqlV}" = '1' || "${mysqlV}" = '2' ]]; then
      service mysql start
    else
      systemctl enable ${installDB}.service
      systemctl start ${installDB}.service
    fi

    mysqladmin -u root password "${mysqlPWD}"
    mysqladmin -u root -p"${mysqlPWD}" -h "localhost" password "${mysqlPWD}"
    mysql -u root -p"${mysqlPWD}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';FLUSH PRIVILEGES;"

    socket=$(mysqladmin variables -u root -p"${mysqlPWD}" | grep -o -m 1 -E '\S*mysqld?\.sock')
    if [ -f "/etc/phpMyAdmin/config.inc.php" ]; then
      sed -i "s/mysql.sock/${socket}/g" /etc/phpMyAdmin/config.inc.php
    fi

    echo "${mysqlPWD}" > /home/initialPWD.txt
    rm -rf /var/lib/mysql/test
  fi

  if [ "${phpV}" != '0' ]; then
    systemctl enable php-fpm.service
    systemctl start php-fpm.service
  fi

  if [ "${nginxV}" != '0' ]; then
    systemctl enable nginx.service
    systemctl start nginx.service
  fi

  if [[ -f "/usr/sbin/mysqld" || -f "/usr/sbin/php-fpm" || -f "/usr/sbin/nginx" ]]; then
    echo "================================================================"
    echo -e "\\033[42m [LNMP] Install completed. \\033[0m"

    if [ "${nginxV}" != '0' ]; then
      echo -e "\\033[34m WebSite: \\033[0m http://${ipAddress}"
      echo -e "\\033[34m WebDir: \\033[0m /home/wwwroot/"
      echo -e "\\033[34m Nginx: \\033[0m /etc/nginx/"
      /usr/sbin/nginx -v
    fi

    if [ "${phpV}" != '0' ]; then
      echo -e "\\033[34m PHP: \\033[0m /etc/php-fpm.d/"
      /usr/sbin/php-fpm -v
    fi

    if [[ "${mysqlV}" != '0' && -f "/usr/sbin/mysqld" ]]; then
      if [ "${installDB}" = "mariadb" ]; then
        echo -e "\\033[34m MariaDB Data: \\033[0m /var/lib/mysql/"
        echo -e "\\033[34m MariaDB User: \\033[0m root"
        echo -e "\\033[34m MariaDB Password: \\033[0m ${mysqlPWD}"
      elif [ "${installDB}" = "mysqld" ]; then
        echo -e "\\033[34m MySQL Data: \\033[0m /var/lib/mysql/"
        echo -e "\\033[34m MySQL User: \\033[0m root"
        echo -e "\\033[34m MySQL Password: \\033[0m ${mysqlPWD}"
      fi
      /usr/sbin/mysqld -V
    fi

    echo "Start time: ${startDate}"
    echo "Completion time: $(date) (Use: $((($(date +%s)-startDateSecond)/60)) minute)"
    echo "Use: $((($(date +%s)-startDateSecond)/60)) minute"
    echo "For more details see \\033[4mhttps://git.io/lnmp\\033[0m"
    echo "================================================================"
  else
    echo -e "\\033[41m [LNMP] Sorry, Install Failed. \\033[0m"
    echo "Please contact us: https://github.com/maicong/LNMP/issues"
  fi
}

# uninstall
runUninstall(){
    read -p 'Are you sure? (y/n): ' -r -e confirmYN
    if [ "${confirmYN}" = 'y' ]; then
      showNotice "Uninstalling..."
      pgrep -u www | xargs -r kill
      pgrep mysql | xargs -r kill
      pgrep php | xargs -r kill
      pgrep nginx | xargs -r kill
      yum remove -y epel* mysql* MariaDB* nginx* php* remi*
      systemctl delete mysqld.service
      systemctl delete mariadb.service
      systemctl delete php-fpm.service
      systemctl delete nginx.service
      rm -rf /etc/nginx
      rm -rf /etc/php*
      rm -rf /etc/my.cnf*
      rm -rf /etc/yum.repos.d/mariadb.repo
      rm -rf /var/lib/mysql
      rm -rf /home/wwwroot
      rm -rf /tmp/LNMP-${envType}*
      userdel -r www
      yum clean all
    else
      showNotice "Uninstall aborted!"
    fi
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
  echo -e "For more details see \033[4mhttps://git.io/lnmp\033[0m"
  echo ''
  showNotice 'Please select your operation:'
  echo '1) Install'
  echo '2) Uninstall'
  echo '3) Upgrade packages'
  echo '4) Exit'
  read -p 'Select an option [1-4]: ' -r -e operation
  case ${operation} in
    1)
      clear
      runInstall
    exit
    ;;
    2)
      clear
      runUninstall
    exit
    ;;
    3)
      clear
      showNotice "Checking..."
      yum upgrade
    exit
    ;;
    4)
      showNotice "Nothing to do..."
    exit
    ;;
  esac
done
