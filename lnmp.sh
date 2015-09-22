#!/bin/bash
#
## CentOS 7 YUM Installation: Nginx 1.8.x/1.9.x + MySQL 5.x + PHP 5.6.x/7.x
## https://github.com/maicong/LNMP
## Usage: bash lnmp.sh

clear;

## 检查 root 权限
[ $(id -g) != "0" ] && die "Script must be run as root.";

echo "================================================================";
echo "CentOS 7 YUM Installation: Nginx 1.8.x/1.9.x + MySQL 5.x + PHP 5.6.x/7.x";
echo "https://github.com/maicong/LNMP";
echo "Usage: bash lnmp.sh";
echo "================================================================";

lnmpDo="";
mysqlV="";
phpV="";
nginxV="";
startDate='';
startDateSecond='';
ipAddress=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`;

## 确认安装
function ConfirmInstall() {
    echo "[Notice] Please select: ";
    select lnmpDo in "Install" "Uninstall" "Upgrade" "Exit"; do break; done;
    if [ "$lnmpDo" == "Uninstall" ]; then
        read -p '[Notice] Did you backup data? (y/n) : ' confirmYN;
        [ "$confirmYN" != 'y' ] && exit;
        echo "[Notice] Uninstalling... ";
        systemctl stop mysqld.service;
        systemctl stop php-fpm.service;
        systemctl stop nginx.service;
        yum remove -y epel* epel-* mysql* mysql-* httpd* httpd-* nginx* nginx-* php* php-* remi* remi-*;
        rm -rf /etc/nginx;
        rm -rf /etc/my.cnf.d;
        rm -rf /etc/php*;
        rm -rf /etc/my.cnf*;
        rm -rf /home/userdata;
        rm -rf /home/wwwroot;
        ps -ef | grep "www" | awk '{ print $2 }' | uniq | xargs kill -9;
        userdel -r www;
        groupdel www;
        yum clean all;
        exit;
    elif [ "$lnmpDo" == "Upgrade" ]; then
        echo "[Notice] Upgrading... ";
        yum upgrade;
        exit;
    elif [ "$lnmpDo" == "Install" ]; then
        selectMySQL;
        selectPHP;
        selectNginx;
        CloseSelinux;
        InstallReady;
        InstallService;
        ConfigService;
        StartService;
    elif [ "$lnmpDo" == "Exit" ]; then
        exit;
    else  
        ConfirmInstall;
    fi;
}

## 选择 MySQL 版本
function selectMySQL() {
    echo "[Notice] Please select MySQL Version: ";
    select mysqlV in "MySQL-5.5" "MySQL-5.6" "MySQL-5.7-Dev" "Exit"; do
        break;
    done;

    [ "$mysqlV" == "Exit" ] && exit;

    if [ "$mysqlV" != "MySQL-5.5" ] && [ "$mysqlV" != "MySQL-5.6" ] && [ "$mysqlV" != "MySQL-5.7-Dev" ] && [ "$mysqlV" != "Exit" ]; then
        selectMySQL;
    fi;
}

## 选择 PHP 版本
function selectPHP() {
    echo "[Notice] Please select PHP Version: ";
    select phpV in "PHP-5.5" "PHP-5.6" "PHP-7.0-RC" "Exit"; do
        break;
    done;

    [ "$phpV" == "Exit" ] && exit;

    if [ "$phpV" != "PHP-5.5" ] && [ "$phpV" != "PHP-5.6" ] && [ "$phpV" != "PHP-7.0-RC" ] && [ "$phpV" != "Exit" ]; then
        selectPHP;
    fi;
}

## 选择 Nginx 版本
function selectNginx() {
    echo "[Notice] Please select Nginx Version: ";
    select nginxV in "Nginx-1.8" "Nginx-1.9-Dev" "Exit"; do
        break;
    done;

    [ "$nginxV" == "Exit" ] && exit;

    if [ "$nginxV" != "Nginx-1.8" ] && [ "$nginxV" != "Nginx-1.9-Dev" ] && [ "$nginxV" != "Exit" ]; then
        selectNginx;
    fi;
}

## 关闭并禁用 selinux
function CloseSelinux() {
    [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
    setenforce 0 >/dev/null 2>&1;
}

## 准备安装
function InstallReady() {
    yum_repos_s=`ls /etc/yum.repos.d | grep .repo | wc -l`;
    if [ "$yum_repos_s" == '0' ]; then
        wget -c -P /etc/yum.repos.d --tries=3 http://mirrors.aliyun.com/repo/Centos-7.repo;
        yum clean all;
        yum makecache;
    fi;

    yum install -y ntp;
    ntpdate -u pool.ntp.org;
    startDate=$(date);
    startDateSecond=$(date +%s);
    echo "Start time: ${startDate}";
    
    rm -rf /etc/localtime;
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;

    time=`date +%s`;
    mkdir -p /etc/yum.repos.d/bak.$time/;
    mv -bfu /etc/yum.repos.d/{epel*,mysql*,remi*,nginx*} /etc/yum.repos.d/bak.$time/ >& /dev/null;

    yum upgrade -y;
}

## 安装服务
function InstallService() {
    echo "[Notice] YUM install ... ";
    yum install -y epel-release;

    rpm --import mysql_pubkey.asc;
    rpm --import http://rpms.remirepo.net/RPM-GPG-KEY-remi;
    rpm --import http://nginx.org/packages/keys/nginx_signing.key;

    rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm;
    rpm -Uvh http://remi.mirrors.arminco.com/enterprise/remi-release-7.rpm;
    rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm;

    mysqlRepo=/etc/yum.repos.d/mysql-community.repo;
    if [ "$mysqlV" == "MySQL-5.5" ]; then
        sed -i "/yum\/mysql\-5\.5/{n;s/enabled=0/enabled=1/g}" $mysqlRepo;
        sed -i "/yum\/mysql\-5\.6/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
        sed -i "/yum\/mysql\-5\.7/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
    elif [ "$mysqlV" == "MySQL-5.6" ]; then
        sed -i "/yum\/mysql\-5\.5/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
        sed -i "/yum\/mysql\-5\.6/{n;s/enabled=0/enabled=1/g}" $mysqlRepo;
        sed -i "/yum\/mysql\-5\.7/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
    elif [ "$mysqlV" == "MySQL-5.7-Dev" ]; then
        sed -i "/yum\/mysql\-5\.5/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
        sed -i "/yum\/mysql\-5\.6/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
        sed -i "/yum\/mysql\-5\.7/{n;s/enabled=0/enabled=1/g}" $mysqlRepo;
    fi;

    phpRepo=/etc/yum.repos.d/remi.repo;
    php7Repo=/etc/yum.repos.d/remi-php70.repo;

    sed -i "/remi\/mirror/{n;s/enabled=0/enabled=1/g}" /etc/yum.repos.d/remi.repo;
    sed -i "/test\/mirror/{n;n;s/enabled=0/enabled=1/g}" /etc/yum.repos.d/remi.repo;

    if [ "$phpV" == "PHP-5.5" ]; then
        sed -i "/php55\/mirror/{n;n;s/enabled=0/enabled=1/g}" $phpRepo;
        sed -i "/php56\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php70\/mirror/{n;s/enabled=1/enabled=0/g}" $php7Repo;
    elif [ "$phpV" == "PHP-5.6" ]; then
        sed -i "/php55\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php56\/mirror/{n;n;s/enabled=0/enabled=1/g}" $phpRepo;
        sed -i "/php70\/mirror/{n;s/enabled=1/enabled=0/g}" $php7Repo;
    elif [ "$phpV" == "PHP-7.0-RC" ]; then
        sed -i "/php55\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php56\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php70\/mirror/{n;s/enabled=0/enabled=1/g}" $php7Repo;
    fi;

    nginxRepo=/etc/yum.repos.d/nginx.repo;
    if [ "$nginxV" == "Nginx-1.8" ]; then
        sed -i "s/\/mainline//g" $nginxRepo;
    elif [ "$nginxV" == "Nginx-1.9-Dev" ]; then
        sed -i "s/packages/packages\/mainline/g" $nginxRepo;
    fi;

    yum clean all;
    yum makecache;

    yum install -y mysql-community-server nginx php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pdo_dblib php-pgsql php-recode php-snmp php-soap php-xml php-pecl-zip phpMyAdmin;
}

## 配置服务
function ConfigService() {
    mkdir -p /etc/php-fpm.d.stop;
    mv -bfu /etc/php-fpm.d/* /etc/php-fpm.d.stop/;
    mv -bfu /etc/php.ini /etc/php.ini.bak;

    mkdir -p /etc/nginx/{conf.d.stop,rewrite,ssl};
    mv -bfu /etc/nginx/conf.d/* /etc/nginx/conf.d.stop/;
    mv -bfu /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak;
    mv -bfu /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.bak;

    mkdir -p /etc/phpMyAdmin/oldbak;
    mv -bfu /etc/phpMyAdmin/config.inc.php /etc/phpMyAdmin/oldbak;

    cp -a etc/* /etc/;

    chmod +x /etc/rc.d/init.d/vhost;

    newHash=`echo -n $RANDOM  | md5sum | sed "s/ .*//" | cut -b -18`;
    sed -i "s/739174021564331540/${newHash}/g" /etc/phpMyAdmin/config.inc.php;

    mkdir -p /home/{wwwroot,userdata};
    mkdir -p /home/wwwroot/index/web;
    cp -a home/wwwroot/index /home/wwwroot/;
    cp -a /usr/share/phpMyAdmin /home/wwwroot/index/web/;
    rm -rf /home/wwwroot/index/web/phpMyAdmin/doc/html;
    cp -a /usr/share/doc/phpMyAdmin-*/html /home/wwwroot/index/web/phpMyAdmin/doc/;

    groupadd www;
    useradd -m -s /sbin/nologin -g www www;

    chown www:www -R /home/wwwroot;
    chown mysql:mysql -R /home/userdata;
}

## 启动服务
function StartService() {
    systemctl enable mysqld.service;
    systemctl enable php-fpm.service;
    systemctl enable nginx.service;

    firewall-cmd --permanent --zone=public --add-service=http;
    firewall-cmd --permanent --zone=public --add-service=https;
    firewall-cmd --reload;

    systemctl start mysqld.service;
    systemctl start php-fpm.service;
    systemctl start nginx.service;

    InstallCompleted;

    echo -e "\n\n\033[42m mysql secure installation \033[0m";
    mysql_secure_installation;
}

## 安装完成
function InstallCompleted() {
    if [ -f "/usr/sbin/mysqld" ] && [ -f "/usr/sbin/php-fpm" ] && [ -f "/usr/sbin/nginx" ]; then
        echo "================================================================";
        echo -e "\033[42m [LNMP] Install completed. \033[0m";
        echo -e "\033[34m WebSite: \033[0m http://$ipAddress";
        echo -e "\033[34m WebDir: \033[0m /home/wwwroot/";
        echo -e "\033[34m Nginx: \033[0m /etc/nginx/";
        echo -e "\033[34m PHP: \033[0m /etc/php-fpm.d/";
        echo -e "\033[34m MySQL Data: \033[0m /home/userdata/";
        echo -e "\033[34m MySQL User: \033[0m root";
        echo -e "\033[34m MySQL Password: \033[0m <↓↓ mysql secure installation ↓↓>";
        echo -e "\033[34m Host Management: \033[0m service vhost (start,stop,list,add,edit,del,exit) <domain> <server_name> <index_name> <rewrite_file> <host_subdirectory>";
        echo "Start time: $startDate";
        echo "Completion time: $(date) (Use: $[($(date +%s)-startDateSecond)/60] minute)";
        echo "More help please visit: https://maicong.me/2015-09-17-mc-lnmp.html";
        echo "================================================================";
    else
        echo -e "\033[41m [LNMP] Sorry, Install Failed. \033[0m";
        echo "Please contact us: https://github.com/maicong/LNMP/issues";
    fi;
}

## 安装
ConfirmInstall;
