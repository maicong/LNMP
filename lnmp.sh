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

# 检查 root 权限
[[ $(id -g) != '0' ]] && die 'Script must be run as root.'

# 声明变量
ipAddress=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1) || '0.0.0.0'
mysqlPWD=$(echo -n $RANDOM | md5sum | sed "s/ .*//" | cut -b -8)

mysqlUrl='https://repo.mysql.com'
mariaDBUrl='https://yum.mariadb.org'
phpUrl='https://rpms.remirepo.net'
nginxUrl='https://nginx.org'
mysqlUrl_CN='https://mirrors.ustc.edu.cn/mysql-repo'
mariaDBUrl_CN='https://mirrors.ustc.edu.cn/mariadb/yum'
phpUrl_CN='https://mirrors.ustc.edu.cn/remi'
nginxUrl_CN='https://cdn-nginx.b0.upaiyun.com'

# 输出正确信息
showOk(){
  echo -e "\033[34m[OK]\033[0m $1"
}

# 输出错误信息
showError(){
  echo -e "\033[31m[ERROR]\033[0m $1"
}

# 输出提示信息
showNotice(){
  echo -e "\033[36m[NOTICE]\033[0m $1"
}

# 安装
runInstall(){
  showNotice 'Installing...'

  showNotice '(Step 1/6) Input server IPv4 Address'
  read -p "IP address: " -r -e -i "$ipAddress" ipAddress
  if [[ "$ipAddress" = '' ]]; then
    showError 'Invalid IP Address' && exit
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
  read -p 'MySQL [1-9]: ' -r -e -i 5 mysqlV
  if [[ "$mysqlV" = '' ]]; then
    showError 'Invalid MySQL version' && exit
  fi

  showNotice "(Step 3/6) Select the PHP version"
  echo "1) PHP-5.4"
  echo "2) PHP-5.5"
  echo "3) PHP-5.6"
  echo "4) PHP-7.0"
  echo "5) PHP-7.1"
  echo "6) PHP-7.2"
  read -p 'PHP [1-6]: ' -r -e -i 6 phpV
  if [[ "$phpV" = '' ]]; then
    showError 'Invalid PHP version' && exit
  fi

  showNotice "(Step 4/6) Select the Nginx version"
  echo "1) Nginx-1.12"
  echo "2) Nginx-1.13"
  read -p 'Nginx [1-2]: ' -r -e -i 2 nginxV
  if [[ "$nginxV" = '' ]]; then
    showError 'Invalid Nginx version' && exit
  fi

  showNotice "(Step 5/6) Select the DB tool version"
  echo "1) Adminer"
  echo "2) phpMyAdmin"
  echo "3) Not need"
  read -p 'DB tool [1-3]: ' -r -e -i 3 dbV
  if [[ "$dbV" = '' ]]; then
    showError 'Invalid DB tool version' && exit
  fi

  showNotice "(Step 6/6) Use a mirror server to download rpms"
  echo "1) Source station"
  echo "2) Mirror station"
  read -p 'Proxy server [1-2]: ' -r -e -i 1 freeV
  if [[ "$freeV" = '' ]]; then
    showError 'Invalid Proxy server' && exit
  fi

  [[ -s /etc/selinux/config ]] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0 >/dev/null 2>&1

  yum_repos=$(find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" -type f | wc -l)
  if [[ "$yum_repos" = '0' ]]; then
    wget -c -P /etc/yum.repos.d --tries=3 http://mirrors.aliyun.com/repo/Centos-7.repo
    yum clean all
    yum makecache
  fi

  yum install -y ntp

  showNotice 'Syncing time'

  ntpdate -u pool.ntp.org
  startDate=$(date)
  startDateSecond=$(date +%s)

  yum_repos_s=$(find /etc/yum.repos.d/ -maxdepth 1 -name '*.repo*' | grep 'epel\|mysql\|mariadb\|remi\|nginx' -c)
  if [[ "$yum_repos_s" -gt '0' ]]; then
    time=$(date +%s)
    mkdir -p "/etc/yum.repos.d/bak.$time"
    mv -bfu /etc/yum.repos.d/{epel*,mysql*,mariadb*,remi*,nginx*} "/etc/yum.repos.d/bak.$time" >& /dev/null
  fi

  showNotice 'Installing'

  yum install -y epel-release yum-utils firewalld firewall-config unzip

  mysqlRepoUrl=$mysqlUrl
  mariaDBRepoUrl=$mariaDBUrl
  phpRepoUrl=$phpUrl
  nginxRepoUrl=$nginxUrl

  if [[ "$freeV" = "2" ]]; then
    mysqlRepoUrl=$mysqlUrl_CN
    mariaDBRepoUrl=$mariaDBUrl_CN
    phpRepoUrl=$phpUrl_CN
    nginxRepoUrl=$nginxUrl_CN

    mv -bfu /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak
    mv -bfu /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.bak

    wget -c --tries=3 -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
  fi

  rpm --import ./keys/RPM-GPG-KEY-remi
  rpm --import ./keys/nginx_signing.key
  rpm -Uvh $phpRepoUrl/enterprise/remi-release-7.rpm
  rpm -Uvh $nginxRepoUrl/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

  if [[ "$mysqlV" = "1" || "$mysqlV" = "2" || "$mysqlV" = "3" || "$mysqlV" = "4" || "$mysqlV" = "5" ]]; then
    mariadbV='10.1'
    installDB='mariadb'
    case $mysqlV in
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
    echo -e "[mariadb]\nname = MariaDB\nbaseurl = $mariaDBRepoUrl/$mariadbV/centos7-amd64\ngpgkey=$mariaDBRepoUrl/RPM-GPG-KEY-MariaDB\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo
  elif [[ "$mysqlV" = "6" || "$mysqlV" = "7" || "$mysqlV" = "8" || "$mysqlV" = "9" ]]; then
    rpm --import ./keys/RPM-GPG-KEY-mysql
    rpm -Uvh $mysqlRepoUrl/mysql57-community-release-el7-11.noarch.rpm
    find /etc/yum.repos.d/ -maxdepth 1 -name "mysql-community*.repo" -type f -print0 | xargs -0 sed -i "s@$mysqlUrl@$mysqlRepoUrl@g"
    installDB='mysqld'

    case $mysqlV in
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

  sedPhpRepo() {
    find /etc/yum.repos.d/ -maxdepth 1 -name "remi*.repo" -type f -print0 | xargs -0 sed -i "$1"
  }

  sedPhpRepo "s@$phpUrl@$phpRepoUrl@g"

  if [[ "$freeV" = "1" ]]; then
    sedPhpRepo "/\$basearch/{n;s/^baseurl=/#baseurl=/g}"
    sedPhpRepo "/\$basearch/{n;n;s/^#mirrorlist=/mirrorlist=/g}"
  elif [[ "$freeV" = "2" ]]; then
    sedPhpRepo "/\$basearch/{n;s/^#baseurl=/baseurl=/g}"
    sedPhpRepo "/\$basearch/{n;n;s/^mirrorlist=/#mirrorlist=/g}"
  fi

  yum-config-manager --enable remi remi-test

  case $phpV in
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

  nginxRepo=/etc/yum.repos.d/nginx.repo

  sed -i "s@$nginxUrl@$nginxRepoUrl@g" $nginxRepo

  if [[ "$nginxV" = "1" ]]; then
    sed -i "s/\/mainline//g" $nginxRepo
  elif [[ "$nginxV" = "2" ]]; then
    sed -i "s/packages/packages\/mainline/g" $nginxRepo
  fi

  yum clean all && yum makecache fast

  if [[ "$installDB" = "mariadb" ]]; then
    yum install -y MariaDB-server MariaDB-client
    sed -i "s@\[client-server\]@\[client\]\nport=3306\nsocket=/home/userdata/mysqld.sock\n\n[mysqld]\ndatadir=/home/userdata\nsocket=/home/userdata/mysqld.sock\nbind-address=0.0.0.0\nlog-basename=mysqld\nlog-error=/home/userdata/mysqld.log\ngeneral-log\ngeneral-log-file=/home/userdata/mysqld-general.log\nslow-query-log\nslow-query-log-file=/home/userdata/mysqld-slow.log\npid-file=/home/userdata/mysqld.pid\n@g" /etc/my.cnf
    mysql_install_db --user=mysql
  elif [[ "$installDB" = "mysqld" ]]; then
    yum install -y mysql-community-server
    sed -i "s@/var/lib/mysql@/home/userdata@g" /etc/my.cnf
    sed -i "s@mysql.sock@mysqld.sock@g" /etc/my.cnf
    sed -i "s@/var/log@/home/userdata@g" /etc/my.cnf
    sed -i "s@symbolic-links=0@symbolic-links=0\nbind-address=0.0.0.0@g" /etc/my.cnf
    echo -e "\n[client]\nsocket=/home/userdata/mysqld.sock" >> /etc/my.cnf

    if [[ "$mysqlV" = "6" ]]; then
      mysqld --initialize-insecure --user=mysql --explicit_defaults_for_timestamp
    else
      mysql_install_db --user=mysql --explicit_defaults_for_timestamp
    fi
  fi

  yum install -y nginx php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pdo_dblib php-recode php-snmp php-soap php-xml php-pecl-zip

  showNotice "Configurationing"

  [[ -f LNMP-dev.zip ]] && rm -rf LNMP-dev LNMP-dev.zip

  wget -c --tries=3 -O LNMP-dev.zip https://github.com/maicong/LNMP/archive/dev.zip
  unzip -q LNMP-dev.zip

  [[ ! -d LNMP-dev ]] && showError "Configuration file not found"
  cd LNMP-dev || exit

  mkdir -p /etc/php-fpm.d.stop
  mv -bfu /etc/php-fpm.d/* /etc/php-fpm.d.stop/
  mv -bfu /etc/php.ini /etc/php.ini.bak

  mkdir -p /etc/nginx/{conf.d.stop,rewrite,ssl}
  mv -bfu /etc/nginx/conf.d/* /etc/nginx/conf.d.stop/
  mv -bfu /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
  mv -bfu /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.bak

  cp -a ./etc/* /etc/

  chmod +x /etc/rc.d/init.d/vbackup
  chmod +x /etc/rc.d/init.d/vhost
  chmod +x /etc/rc.d/init.d/svnserve

  sed -i "s/localhost/$ipAddress/g" /etc/nginx/conf.d/nginx-index.conf

  mkdir -p /home/{wwwroot,userdata}
  cp -a ./home/wwwroot/index/ /home/wwwroot/

  if [[ "$dbV" = "1" ]]; then
    cp -a ./DBMGT/Adminer /home/wwwroot/index/
    sed -i "s/phpMyAdmin/Adminer/g" /home/wwwroot/index/index.html
  elif [[ "$dbV" = "2" ]]; then
    yum install -y phpMyAdmin
    newHash=$(echo -n $RANDOM  | md5sum | sed "s/ .*//" | cut -b -18)
    sed -i "s/739174021564331540/$newHash/g" /etc/phpMyAdmin/config.inc.php
    cp -a /usr/share/phpMyAdmin /home/wwwroot/index/
    rm -rf /home/wwwroot/index/phpMyAdmin/doc/html
    cp -a /usr/share/doc/phpMyAdmin-*/html /home/wwwroot/index/phpMyAdmin/doc/
  fi

  groupadd www
  useradd -m -s /sbin/nologin -g www www

  chown www:www -R /home/wwwroot
  chown mysql:mysql -R /home/userdata

  showNotice "Starting"

  systemctl enable $installDB.service
  systemctl enable php-fpm.service
  systemctl enable nginx.service
  systemctl enable firewalld.service

  systemctl restart firewalld.service

  firewall-cmd --permanent --zone=public --add-service=http
  firewall-cmd --permanent --zone=public --add-service=https
  firewall-cmd --reload

  systemctl start $installDB.service
  systemctl start php-fpm.service
  systemctl start nginx.service

  mysqladmin -u root password "$mysqlPWD"
  mysqladmin -u root -p"$mysqlPWD" -h "localhost" password "$mysqlPWD"
  mysql -u root -p"$mysqlPWD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';FLUSH PRIVILEGES;"
  rm -rf /home/userdata/test
  echo "$mysqlPWD" > /home/userdata/initialPWD.txt

  if [[ -f "/usr/sbin/mysqld" && -f "/usr/sbin/php-fpm" && -f "/usr/sbin/nginx" ]]; then
    echo "================================================================"
    echo -e "\033[42m [LNMP] Install completed. \033[0m"
    echo -e "\033[34m WebSite: \033[0m http://$ipAddress"
    echo -e "\033[34m WebDir: \033[0m /home/wwwroot/"
    echo -e "\033[34m Nginx: \033[0m /etc/nginx/"
    echo -e "\033[34m PHP: \033[0m /etc/php-fpm.d/"

    if [[ "$installDB" = "mariadb" ]]; then
      echo -e "\033[34m MariaDB Data: \033[0m /home/userdata/"
      echo -e "\033[34m MariaDB User: \033[0m root"
      echo -e "\033[34m MariaDB Password: \033[0m $mysqlPWD"
    elif [[ "$installDB" = "mysqld" ]]; then
      echo -e "\033[34m MySQL Data: \033[0m /home/userdata/"
      echo -e "\033[34m MySQL User: \033[0m root"
      echo -e "\033[34m MySQL Password: \033[0m $mysqlPWD"
    fi

    echo -e "\033[34m Host Management: \033[0m service vhost (start,stop,list,add,edit,del,exit) <domain> <server_name> <index_name> <rewrite_file> <host_subdirectory>"
    echo "Start time: $startDate"
    echo "Completion time: $(date) (Use: $((($(date +%s)-startDateSecond)/60)) minute)"
    echo "More help please visit: https://github.com/maicong/LNMP"
    echo "================================================================"
  else
    echo -e "\033[41m [LNMP] Sorry, Install Failed. \033[0m"
    echo "Please contact us: https://github.com/maicong/LNMP/issues"
  fi
}

# 卸载
runUninstall(){
    read -p 'Are you sure? (y/n): ' -r -e confirmYN
    if [[ "$confirmYN" = 'y' ]]; then
      showNotice "Uninstalling..."
      pgrep -u www 2>/dev/null | xargs -r kill
      pgrep mysql | xargs -r kill
      pgrep php | xargs -r kill
      pgrep nginx | xargs -r kill
      yum autoremove -y epel* epel-* mysql* mysql-* MariaDB-* httpd* httpd-* nginx* nginx-* php* php-* remi* remi-* 2>/dev/null
      systemctl delete mysqld.service 2>/dev/null
      systemctl delete mariadb.service 2>/dev/null
      systemctl delete php-fpm.service 2>/dev/null
      systemctl delete nginx.service 2>/dev/null
      rm -rf /etc/nginx
      rm -rf /etc/my.cnf.d
      rm -rf /etc/php*
      rm -rf /etc/my.cnf*
      rm -rf /etc/yum.repos.d/mariadb.repo
      rm -rf /home/userdata
      rm -rf /home/wwwroot
      userdel -r www 2>/dev/null
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
