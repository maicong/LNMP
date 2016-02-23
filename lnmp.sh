#!/bin/bash
#
## CentOS 7 YUM Installation: Nginx 1.8/1.9 + MySQL 5.5/5.6/5.7(MariaDB 5.5/10.0/10.1) + PHP 5.5/5.6/7.0 + phpMyAdmin(Adminer)
## https://github.com/maicong/LNMP
## Usage: bash lnmp.sh

clear;

## 检查 root 权限
[ $(id -g) != "0" ] && die "Script must be run as root.";

echo "================================================================";
echo "CentOS 7 YUM Installation: Nginx 1.8/1.9 + MySQL 5.5/5.6/5.7(MariaDB 5.5/10.0/10.1) + PHP 5.5/5.6/7.0 + phpMyAdmin(Adminer)";
echo "https://github.com/maicong/LNMP";
echo "Usage: bash lnmp.sh";
echo "================================================================";

lnmpDo='';
mysqlV='';
phpV='';
nginxV='';
dbV='';
startDate='';
startDateSecond='';
ipAddress=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`;
mysqlPWD=`echo -n $RANDOM  | md5sum | sed "s/ .*//" | cut -b -8`;
mysqlUrl='http://repo.mysql.com';
mariaDBUrl='http://yum.mariadb.org';
phpUrl='http://rpms.remirepo.net';
nginxUrl='http://nginx.org';
mysqlCDNUrl='http://cdn-mysql.b0.upaiyun.com';
mariaDBCDNUrl='http://cdn-mariadb.b0.upaiyun.com';
phpCDNUrl='http://cdn-remi.b0.upaiyun.com';
nginxCDNUrl='http://cdn-nginx.b0.upaiyun.com';
installDB='';

## 确认安装
function ConfirmInstall() {
    echo "[Notice] Please select: ";
    select lnmpDo in "Install" "Uninstall" "Upgrade" "Exit"; do break; done;
    if [ "$lnmpDo" == "Uninstall" ]; then
        read -p '[Notice] Are you sure? (y/n) : ' confirmYN;
        [ "$confirmYN" != 'y' ] && exit;
        echo "[Notice] Uninstalling... ";
        systemctl stop mysqld.service;
        systemctl stop php-fpm.service;
        systemctl stop nginx.service;
        yum autoremove -y epel* epel-* mysql* mysql-* MariaDB-* httpd* httpd-* nginx* nginx-* php* php-* remi* remi-*;
        rm -rf /etc/nginx;
        rm -rf /etc/my.cnf.d;
        rm -rf /etc/php*;
        rm -rf /etc/my.cnf*;
        rm -rf /home/userdata;
        rm -rf /home/wwwroot;
        ps -ef | grep "www" | grep -v grep | awk '{ print $2 }' | uniq | xargs kill -9;
        userdel -r www;
        groupdel www;
        yum clean all;
        exit;
    elif [ "$lnmpDo" == "Upgrade" ]; then
        echo "[Notice] Upgrading... ";
        yum upgrade;
        exit;
    elif [ "$lnmpDo" == "Install" ]; then
        InputIP;
        selectMySQL;
        selectPHP;
        selectNginx;
        selectDBMGT;
        freeDom;
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

## 输入 IP 地址
function InputIP()
{
    if [ "$ipAddress" == '' ]; then
        echo '[Error] Empty server ip.';
        read -p '[Notice] Please input server ip:' ipAddress;
        [ "$ipAddress" == '' ] && InputIP;
    else
        echo '[OK] Your server ip is:' && echo $ipAddress;
        read -p '[Notice] This is your server ip? : (y/n)' confirmDM;
        if [ "$confirmDM" == 'n' ]; then
            ipAddress='';
            InputIP;
        elif [ "$confirmDM" != 'y' ]; then
            InputIP;
        fi;
    fi;
}

## 选择 MySQL 版本
function selectMySQL() {
    echo "[Notice] Please select MySQL version: ";
    select mysqlV in "MySQL-5.5" "MySQL-5.6" "MySQL-5.7-Dev" "MariaDB-5.5" "MariaDB-10.0" "MariaDB-10.1" "Exit"; do
        break;
    done;

    [ "$mysqlV" == "Exit" ] && exit;

    if [ "$mysqlV" != "MySQL-5.5" ] &&
    [ "$mysqlV" != "MySQL-5.6" ] &&
    [ "$mysqlV" != "MySQL-5.7-Dev" ] &&
    [ "$mysqlV" != "MariaDB-5.5" ] &&
    [ "$mysqlV" != "MariaDB-10.0" ] &&
    [ "$mysqlV" != "MariaDB-10.1" ] &&
    [ "$mysqlV" != "Exit" ]; then
        selectMySQL;
    fi;
}

## 选择 PHP 版本
function selectPHP() {
    echo "[Notice] Please select PHP version: ";
    select phpV in "PHP-5.5" "PHP-5.6" "PHP-7.0" "Exit"; do
        break;
    done;

    [ "$phpV" == "Exit" ] && exit;

    if [ "$phpV" != "PHP-5.5" ] && [ "$phpV" != "PHP-5.6" ] && [ "$phpV" != "PHP-7.0" ] && [ "$phpV" != "Exit" ]; then
        selectPHP;
    fi;
}

## 选择 Nginx 版本
function selectNginx() {
    echo "[Notice] Please select Nginx version: ";
    select nginxV in "Nginx-1.8" "Nginx-1.9-Dev" "Exit"; do
        break;
    done;

    [ "$nginxV" == "Exit" ] && exit;

    if [ "$nginxV" != "Nginx-1.8" ] && [ "$nginxV" != "Nginx-1.9-Dev" ] && [ "$nginxV" != "Exit" ]; then
        selectNginx;
    fi;
}

## 选择数据库管理工具
function selectDBMGT() {
    echo "[Notice] Please select database management tool version: ";
    select dbV in "phpMyAdmin" "Adminer" "No need" "Exit"; do
        break;
    done;

    [ "$dbV" == "Exit" ] && exit;

    if [ "$dbV" != "phpMyAdmin" ] && [ "$dbV" != "Adminer" ] && [ "$dbV" != "No need" ] && [ "$dbV" != "Exit" ]; then
        selectDBMGT;
    fi;
}

## 启用 CDN 地址
function freeDom() {
    echo "[Notice] Are you in GFW ?";
    select freeV in "Yes" "No" "Exit"; do
        break;
    done;

    [ "$freeV" == "Exit" ] && exit;

    if [ "$freeV" != "Yes" ] && [ "$freeV" != "No" ] && [ "$freeV" != "Exit" ]; then
        freeDom;
    fi;
}

## 关闭并禁用 selinux
function CloseSelinux() {
    echo "[Notice] Close selinux ... ";
    [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
    setenforce 0 >/dev/null 2>&1;
}

## 准备安装
function InstallReady() {
    echo "[Notice] Install ready ... ";
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
    mv -bfu /etc/yum.repos.d/{epel*,mysql*,mariadb*,remi*,nginx*} /etc/yum.repos.d/bak.$time/ >& /dev/null;

    #yum upgrade -y;
}

## 安装服务
function InstallService() {
    echo "[Notice] Installing service ... ";
    yum install -y epel-release firewalld;

    if [ "$freeV" == "Yes" ]; then
        mysqlRepoUrl=$mysqlCDNUrl;
        mariaDBRepoUrl=$mariaDBCDNUrl;
        phpRepoUrl=$phpCDNUrl;
        nginxRepoUrl=$nginxCDNUrl;

        mv -bfu /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak;
        mv -bfu /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.bak;

        wget -c --tries=3 -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo;
    else
        mysqlRepoUrl=$mysqlUrl;
        mariaDBRepoUrl=$mariaDBUrl;
        phpRepoUrl=$phpUrl;
        nginxRepoUrl=$nginxUrl;
    fi;

    rpm --import ${phpRepoUrl}/RPM-GPG-KEY-remi;
    rpm --import ${nginxRepoUrl}/packages/keys/nginx_signing.key;

    rpm -Uvh ${phpRepoUrl}/enterprise/remi-release-7.rpm;
    rpm -Uvh ${nginxRepoUrl}/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm;

    if [ "$mysqlV" == "MySQL-5.5" ] || [ "$mysqlV" == "MySQL-5.6" ] || [ "$mysqlV" == "MySQL-5.7-Dev" ]; then
        rpm --import mysql_pubkey.asc;
        rpm -Uvh ${mysqlRepoUrl}/mysql-community-release-el7-5.noarch.rpm;

        mysqlRepo=/etc/yum.repos.d/mysql-community.repo;
        mysqlRepoS=/etc/yum.repos.d/mysql-community-source.repo;

        sed -i "s@${mysqlUrl}@${mysqlRepoUrl}@g" $mysqlRepo;
        sed -i "s@${mysqlUrl}@${mysqlRepoUrl}@g" $mysqlRepoS;

        if [ "$mysqlV" == "MySQL-5.5" ]; then
            sed -i "/yum\/mysql\-5\.5/{n;s/enabled=0/enabled=1/g}" $mysqlRepo;
            sed -i "/yum\/mysql\-5\.6/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
            sed -i "/yum\/mysql\-5\.7/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
            installDB='mysqld';
        elif [ "$mysqlV" == "MySQL-5.6" ]; then
            sed -i "/yum\/mysql\-5\.5/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
            sed -i "/yum\/mysql\-5\.6/{n;s/enabled=0/enabled=1/g}" $mysqlRepo;
            sed -i "/yum\/mysql\-5\.7/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
            installDB='mysqld';
        elif [ "$mysqlV" == "MySQL-5.7-Dev" ]; then
            sed -i "/yum\/mysql\-5\.5/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
            sed -i "/yum\/mysql\-5\.6/{n;s/enabled=1/enabled=0/g}" $mysqlRepo;
            sed -i "/yum\/mysql\-5\.7/{n;s/enabled=0/enabled=1/g}" $mysqlRepo;
            installDB='mysqld';
        fi;
    else
        if [ "$mysqlV" == "MariaDB-5.5" ]; then
            echo -e "[mariadb]\nname = MariaDB\nbaseurl = ${mariaDBRepoUrl}/5.5/centos7-amd64\ngpgkey=${mariaDBRepoUrl}/RPM-GPG-KEY-MariaDB\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo;
            installDB='mariadb';
        elif [ "$mysqlV" == "MariaDB-10.0" ]; then
            echo -e "[mariadb]\nname = MariaDB\nbaseurl = ${mariaDBRepoUrl}/10.0/centos7-amd64\ngpgkey=${mariaDBRepoUrl}/RPM-GPG-KEY-MariaDB\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo;
            installDB='mariadb';
        elif [ "$mysqlV" == "MariaDB-10.1" ]; then
            echo -e "[mariadb]\nname = MariaDB\nbaseurl = ${mariaDBRepoUrl}/10.1/centos7-amd64\ngpgkey=${mariaDBRepoUrl}/RPM-GPG-KEY-MariaDB\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo;
            installDB='mariadb';
        fi;
    fi;

    phpRepo=/etc/yum.repos.d/remi.repo;
    phpRepoS=/etc/yum.repos.d/remi-safe.repo;
    php7Repo=/etc/yum.repos.d/remi-php70.repo;

    sed -i "s@${phpUrl}@${phpRepoUrl}@g" $phpRepo;
    sed -i "s@${phpUrl}@${phpRepoUrl}@g" $phpRepoS;
    sed -i "s@${phpUrl}@${phpRepoUrl}@g" $php7Repo;

    if [ "$freeV" == "Yes" ]; then
        sed -i "s/#baseurl=/baseurl=/g" $phpRepo;
        sed -i "s/#baseurl=/baseurl=/g" $phpRepoS;
        sed -i "s/#baseurl=/baseurl=/g" $php7Repo;

        sed -i "s/mirrorlist=/#mirrorlist=/g" $phpRepo;
        sed -i "s/mirrorlist=/#mirrorlist=/g" $phpRepoS;
        sed -i "s/mirrorlist=/#mirrorlist=/g" $php7Repo;
    fi;

    sed -i "/remi\/mirror/{n;s/enabled=0/enabled=1/g}" $phpRepo;
    sed -i "/test\/mirror/{n;n;s/enabled=0/enabled=1/g}" $phpRepo;

    if [ "$phpV" == "PHP-5.5" ]; then
        sed -i "/php55\/mirror/{n;n;s/enabled=0/enabled=1/g}" $phpRepo;
        sed -i "/php56\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php70\/mirror/{n;s/enabled=1/enabled=0/g}" $php7Repo;
    elif [ "$phpV" == "PHP-5.6" ]; then
        sed -i "/php55\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php56\/mirror/{n;n;s/enabled=0/enabled=1/g}" $phpRepo;
        sed -i "/php70\/mirror/{n;s/enabled=1/enabled=0/g}" $php7Repo;
    elif [ "$phpV" == "PHP-7.0" ]; then
        sed -i "/php55\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php56\/mirror/{n;n;s/enabled=1/enabled=0/g}" $phpRepo;
        sed -i "/php70\/mirror/{n;s/enabled=0/enabled=1/g}" $php7Repo;
    fi;

    nginxRepo=/etc/yum.repos.d/nginx.repo;

    sed -i "s@${nginxUrl}@${nginxRepoUrl}@g" $nginxRepo

    if [ "$nginxV" == "Nginx-1.8" ]; then
        sed -i "s/\/mainline//g" $nginxRepo;
    elif [ "$nginxV" == "Nginx-1.9-Dev" ]; then
        sed -i "s/packages/packages\/mainline/g" $nginxRepo;
    fi;

    yum clean all;
    yum makecache;

    if [ "$installDB" == "mysqld" ]; then
        yum install -y mysql-community-server;
        sed -i "s@/var/lib/mysql@/home/userdata@g" /etc/my.cnf;
        echo -e "\n[client]\nsocket = /home/userdata/mysqld.sock" >> /etc/my.cnf;

        if [ "$mysqlV" != "MySQL-5.7-Dev" ]; then
            mysql_install_db --user=mysql;
        else
            mysqld --initialize-insecure --user=mysql;
        fi;
    elif [ "$installDB" == "mariadb" ]; then
        yum install -y MariaDB-server MariaDB-client;
        sed -i "s@\[client-server\]@\[client\]\nport = 3306\nsocket = /home/userdata/mysqld.sock\n\n[mysqld]\ndatadir = /home/userdata\nsocket = /home/userdata/mysqld.sock\nlog-basename = mysqld\nlog-error = /home/userdata/mysqld.log\ngeneral-log\ngeneral-log-file = /home/userdata/mysqld-general.log\nslow-query-log\nslow-query-log-file = /home/userdata/mysqld-slow.log\npid-file = /home/userdata/mysqld.pid\n@g" /etc/my.cnf;
        mysql_install_db --user=mysql;
    fi;

    yum install -y nginx php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pdo_dblib php-recode php-snmp php-soap php-xml php-pecl-zip;
}

## 配置服务
function ConfigService() {
    echo "[Notice] Config service ... ";
    mkdir -p /etc/php-fpm.d.stop;
    mv -bfu /etc/php-fpm.d/* /etc/php-fpm.d.stop/;
    mv -bfu /etc/php.ini /etc/php.ini.bak;

    mkdir -p /etc/nginx/{conf.d.stop,rewrite,ssl};
    mv -bfu /etc/nginx/conf.d/* /etc/nginx/conf.d.stop/;
    mv -bfu /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak;
    mv -bfu /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.bak;

    cp -a etc/* /etc/;

    chmod +x /etc/rc.d/init.d/vbackup;
    chmod +x /etc/rc.d/init.d/vhost;

    sed -i "s/localhost/${ipAddress}/g" /etc/nginx/conf.d/nginx-index.conf;

    mkdir -p /home/{wwwroot,userdata};
    cp -a home/wwwroot/index /home/wwwroot/;

    if [ "$dbV" == "phpMyAdmin" ]; then
        yum install -y phpMyAdmin;
        newHash=`echo -n $RANDOM  | md5sum | sed "s/ .*//" | cut -b -18`;
        sed -i "s/739174021564331540/${newHash}/g" /etc/phpMyAdmin/config.inc.php;
        cp -a /usr/share/phpMyAdmin /home/wwwroot/index/;
        rm -rf /home/wwwroot/index/phpMyAdmin/doc/html;
        cp -a /usr/share/doc/phpMyAdmin-*/html /home/wwwroot/index/phpMyAdmin/doc/;
    elif [ "$dbV" == "Adminer" ]; then
        cp -a DBMGT/Adminer /home/wwwroot/index/;
        sed -i "s/phpMyAdmin/Adminer/g" /home/wwwroot/index/index.html;
    fi;

    groupadd www;
    useradd -m -s /sbin/nologin -g www www;

    chown www:www -R /home/wwwroot;
    chown mysql:mysql -R /home/userdata;
}

## 启动服务
function StartService() {
    echo "[Notice] Start service ... ";
    systemctl enable ${installDB}.service;
    systemctl enable php-fpm.service;
    systemctl enable nginx.service;
    systemctl enable firewalld.service;

    systemctl start firewalld.service

    firewall-cmd --permanent --zone=public --add-service=http;
    firewall-cmd --permanent --zone=public --add-service=https;
    firewall-cmd --reload;

    systemctl start ${installDB}.service;
    systemctl start php-fpm.service;
    systemctl start nginx.service;

    mysqladmin -u root password "$mysqlPWD";
    mysqladmin -u root -p"$mysqlPWD" -h $(hostname) password "$mysqlPWD";
    mysql -u root -p"$mysqlPWD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';FLUSH PRIVILEGES;";
    rm -rf /home/userdata/test;
    echo $mysqlPWD > /home/userdata/initialPWD.txt;

    InstallCompleted;
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

        if [ "$installDB" == "mysqld" ]; then
            echo -e "\033[34m MySQL Data: \033[0m /home/userdata/";
            echo -e "\033[34m MySQL User: \033[0m root";
            echo -e "\033[34m MySQL Password: \033[0m ${mysqlPWD}";
        elif [ "$installDB" == "mariadb" ]; then
            echo -e "\033[34m MariaDB Data: \033[0m /home/userdata/";
            echo -e "\033[34m MariaDB User: \033[0m root";
            echo -e "\033[34m MariaDB Password: \033[0m ${mysqlPWD}";
        fi;

        echo -e "\033[34m Host Management: \033[0m service vhost (start,stop,list,add,edit,del,exit) <domain> <server_name> <index_name> <rewrite_file> <host_subdirectory>";
        echo "Start time: $startDate";
        echo "Completion time: $(date) (Use: $[($(date +%s)-startDateSecond)/60] minute)";
        echo "More help please visit: https://maicong.me/2015-09-23-mc-lnmp.html";
        echo "================================================================";
    else
        echo -e "\033[41m [LNMP] Sorry, Install Failed. \033[0m";
        echo "Please contact us: https://github.com/maicong/LNMP/issues";
    fi;
}

## 安装
ConfirmInstall;