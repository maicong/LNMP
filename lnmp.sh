#!/bin/bash
#
# CentOS yum install: Nginx 1.8.x/1.9.x + MySQL 5.x + PHP 5.6.x/7.x
#
# https://maicong.me/2015-09-17-mc-lnmp.html
#
# Usage: bash lnmp.sh 2>&1 | tee lnmp.log

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin;
clear;

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root.";

echo "#";
echo "# CentOS yum install: Nginx 1.8.x/1.9.x + MySQL 5.x + PHP 5.6.x/7.x";
echo "#";
echo "# https://maicong.me/2015-09-17-mc-lnmp.html";
echo "#";
echo "# Usage: bash lnmp.sh 2>&1 | tee lnmp.log";
echo "#";

mysqlV='';
phpV='';
nginxV='';

echo "[Notice] Please select MySQL Version: ";
select mysqlV in 'MySQL-5.5' 'MySQL-5.6' 'MySQL-5.7-Dev' 'Exit'; do
    break;
done;

echo "[Notice] Please select PHP Version: ";
select phpV in 'PHP-5.5' 'PHP-5.6' 'PHP-7.0-RC' 'Exit'; do
    break;
done;

echo "[Notice] Please select Nginx Version: ";
select nginxV in 'Nginx-1.8' 'Nginx-1.9-Dev' 'Exit'; do
    break;
done;

echo "[Notice] Synchronize the local time... ";
yum install -y ntp;
rm -rf /etc/localtime;
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;
ntpdate -u pool.ntp.org;
systemctl enable ntpd.service;
systemctl start ntpd.service;

StartDate=$(date);
StartDateSecond=$(date +%s);
echo "Start time: ${StartDate}";

echo "[Notice] Removing some packages... ";
yum remove -y epel* epel-* mysql* mysql-* httpd* httpd-* nginx* nginx-* php* php-* remi* remi-*;

time=`date +%s`;
mkdir -p /etc/yum.repos.d/bak.$time/;
mv -bfu /etc/yum.repos.d/{epel*,mysql*,remi*,nginx*} /etc/yum.repos.d/bak.$time/ >& /dev/null;

echo "[Notice] Make yum cache ... ";
yum clean all;
rpm --rebuilddb;
yum makecache;

yum install -y epel-release;

rpm --import mysql_pubkey.asc;
rpm --import http://rpms.remirepo.net/RPM-GPG-KEY-remi;
rpm --import http://nginx.org/packages/keys/nginx_signing.key;

rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm;
rpm -Uvh http://remi.mirrors.arminco.com/enterprise/remi-release-7.rpm;
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm;

mysqlRepo=/etc/yum.repos.d/mysql-community.repo;

if [ "$mysqlV" == 'MySQL-5.5' ]; then
    sed -i '/yum\/mysql\-5\.5/{n;s/enabled=0/enabled=1/g}' $mysqlRepo;
    sed -i '/yum\/mysql\-5\.6/{n;s/enabled=1/enabled=0/g}' $mysqlRepo;
    sed -i '/yum\/mysql\-5\.7/{n;s/enabled=1/enabled=0/g}' $mysqlRepo;
elif [ "$mysqlV" == 'MySQL-5.6' ]; then
    sed -i '/yum\/mysql\-5\.5/{n;s/enabled=1/enabled=0/g}' $mysqlRepo;
    sed -i '/yum\/mysql\-5\.6/{n;s/enabled=0/enabled=1/g}' $mysqlRepo;
    sed -i '/yum\/mysql\-5\.7/{n;s/enabled=1/enabled=0/g}' $mysqlRepo;
elif [ "$mysqlV" == 'MySQL-5.7-Dev' ]; then
    sed -i '/yum\/mysql\-5\.5/{n;s/enabled=1/enabled=0/g}' $mysqlRepo;
    sed -i '/yum\/mysql\-5\.6/{n;s/enabled=1/enabled=0/g}' $mysqlRepo;
    sed -i '/yum\/mysql\-5\.7/{n;s/enabled=0/enabled=1/g}' $mysqlRepo;
fi;

remiRepo=/etc/yum.repos.d/remi.repo;
remi7Repo=/etc/yum.repos.d/remi-php70.repo;

sed -i '/remi\/mirror/{n;s/enabled=0/enabled=1/g}' /etc/yum.repos.d/remi.repo;
sed -i '/test\/mirror/{n;n;s/enabled=0/enabled=1/g}' /etc/yum.repos.d/remi.repo;

if [ "$phpV" == 'PHP-5.5' ]; then
    sed -i '/php55\/mirror/{n;n;s/enabled=0/enabled=1/g}' $remiRepo;
    sed -i '/php56\/mirror/{n;n;s/enabled=1/enabled=0/g}' $remiRepo;
    sed -i '/php70\/mirror/{n;s/enabled=1/enabled=0/g}' $remi7Repo;
elif [ "$phpV" == 'PHP-5.6' ]; then
    sed -i '/php55\/mirror/{n;n;s/enabled=1/enabled=0/g}' $remiRepo;
    sed -i '/php56\/mirror/{n;n;s/enabled=0/enabled=1/g}' $remiRepo;
    sed -i '/php70\/mirror/{n;s/enabled=1/enabled=0/g}' $remi7Repo;
elif [ "$phpV" == 'PHP-7.0-RC' ]; then
    sed -i '/php55\/mirror/{n;n;s/enabled=1/enabled=0/g}' $remiRepo;
    sed -i '/php56\/mirror/{n;n;s/enabled=1/enabled=0/g}' $remiRepo;
    sed -i '/php70\/mirror/{n;s/enabled=0/enabled=1/g}' $remi7Repo;
fi;

nginxRepo=/etc/yum.repos.d/nginx.repo;

if [ "$nginxV" == 'Nginx-1.8' ]; then
    sed -i 's/packages\/mainline\/centos/packages\/centos/g' $nginxRepo;
elif [ "$nginxV" == 'Nginx-1.9-Dev' ]; then
    sed -i 's/packages\/centos/packages\/mainline\/centos/g' $nginxRepo;
fi;

yum clean all;
rpm --rebuilddb;
yum makecache;
yum upgrade -y;

echo "[Notice] Disabled SELINUX... ";

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
setenforce 0 >/dev/null 2>&1;

echo "[Notice] Installing some packages... ";

yum install -y mysql-community-server nginx php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pdo_dblib php-pgsql php-recode php-snmp php-soap php-xml php-zip phpMyAdmin;

echo "[Notice] Move and copy some files... ";

mkdir -p /etc/php-fpm.d.stop;
mv -bfu /etc/php-fpm.d/* /etc/php-fpm.d.stop/;
mv -bfu /etc/php.ini /etc/php.ini.bak;
mv -bfu /etc/php-fpm.conf /etc/php-fpm.conf.bak;

mkdir -p /etc/nginx/{conf.d.stop,rewrite,ssl};
mv -bfu /etc/nginx/conf.d/* /etc/nginx/conf.d.stop/;
mv -bfu /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak;
mv -bfu /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.bak;

mkdir -p /etc/phpMyAdmin/oldbak;
mv -bfu /etc/phpMyAdmin/config.inc.php /etc/phpMyAdmin/oldbak;

cp -a etc/* /etc/;

chmod +x /etc/rc.d/init.d/vhost;

secret=`cat /dev/urandom | head -n 18 | head -c 18`;
sed -i "s#739174021564331540#$secret#g" /etc/phpMyAdmin/config.inc.php;

mkdir -p /home/{wwwroot,userdata};
mkdir -p /home/wwwroot/index/web;
cp -a home/wwwroot/index /home/wwwroot/;
cp -a /usr/share/phpMyAdmin /home/wwwroot/index/web/;
rm -rf web/phpMyAdmin/doc/html;
cp -a /usr/share/doc/phpMyAdmin-*/html /home/wwwroot/index/web/phpMyAdmin/doc/;

if [ `cat /etc/group | grep 'www'` -ne 0 ]; then
    groupadd www;
fi;    
if [ `cat /etc/passwd | grep 'www'` -ne 0 ]; then
    useradd -m -s /sbin/nologin -g www www;
fi;

chown www:www -R /home/wwwroot;
chown mysql:mysql -R /home/userdata;

echo "[Notice] Start LNMP service... ";

systemctl start mysqld.service;
systemctl start php-fpm.service;
systemctl start nginx.service;

systemctl enable mysqld.service;
systemctl enable php-fpm.service;
systemctl enable nginx.service;

firewall-cmd --permanent --zone=public --add-service=http;
firewall-cmd --permanent --zone=public --add-service=https;
firewall-cmd --reload;

echo "[Notice] MySQL secure installation... ";

mysql_secure_installation;

echo "########################################";
echo "LNMP install completed.";
echo "WebSite: http://$ipAddr";
echo "WebDir: /home/wwwroot/";
echo "Nginx: /etc/nginx/";
echo "PHP: /etc/php-fpm.d/";
echo 'MySQL Data: /home/userdata/';
echo "MySQL User: root";
echo "MySQL Password: ";
echo "Host: service vhost (start,stop,list,add,edit,del,exit) <domain> <server_name> <index_name> <rewrite_file> <host_subdirectory>";
echo "Upgrade : yum upgrade -y";
echo "Start time: $StartDate";
echo "Completion time: $(date) (Use: $[($(date +%s)-StartDateSecond)/60] minute)";
echo "More help please visit: https://maicong.me/2015-09-17-mc-lnmp.html";
echo ""########################################";";