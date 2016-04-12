#!/bin/bash
#
#
# CentOS 7 LNMP
#
# Nginx 1.8/1.9 + MySQL 5.5/5.6/5.7(MariaDB 5.5/10.0/10.1) + PHP 5.5/5.6/7.0 + phpMyAdmin(Adminer)
#
# https://github.com/maicong/LNMP
#
# Usage: bash lnmp.sh
#

## 检查 root 权限
[[ $(id -g) != '0' ]] && die 'Script must be run as root.'

lnmpDo=''
mysqlV=''
phpV=''
nginxV=''
dbV=''
startDate=''
startDateSecond=''
installDB=''
ipAddress=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1)
mysqlPWD=$(echo -n $RANDOM  | md5sum | sed "s/ .*//" | cut -b -8)
mysqlUrl='http://repo.mysql.com'
mariaDBUrl='http://yum.mariadb.org'
phpUrl='http://rpms.remirepo.net'
nginxUrl='http://nginx.org'
mysqlCDNUrl='http://cdn-mysql.b0.upaiyun.com'
mariaDBCDNUrl='http://cdn-mariadb.b0.upaiyun.com'
phpCDNUrl='http://cdn-remi.b0.upaiyun.com'
nginxCDNUrl='http://cdn-nginx.b0.upaiyun.com'

## 输出正确信息
showOk(){
    echo -e "\033[34m[OK]\033[0m $1"
}

## 输出错误信息
showError(){
    echo -e "\033[31m[ERROR]\033[0m $1"
}

## 输出提示信息
showNotice(){
    echo -e "\033[36m[NOTICE]\033[0m $1"
}

## 安装
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
    showNotice 'What do you want to do?'
    echo '1) Install'
    echo '2) Uninstall'
    echo '3) Check upgrade'
    echo '4) Exit'
    read -p 'Select an option [1-4]: ' -r -e lnmpDo
    case $lnmpDo in
        1)
        clear

        showNotice 'Installing...'

        showNotice '(Step 1/6) Please input server IPv4 Address'
        read -p "IP address: " -r -e -i "$ipAddress" ipAddress
        if [[ "$ipAddress" = '' ]]; then
            showError 'Invalid IP Address' && exit
        fi

        showNotice "(Step 2/6) Please select the MySQL version"
        echo "1) MariaDB-5.5"
        echo "2) MariaDB-10.0"
        echo "3) MariaDB-10.1"
        echo "4) MySQL-5.5"
        echo "5) MySQL-5.6"
        echo "6) MySQL-5.7 (Dev)"
        read -p 'MySQL [1-6]: ' -r -e -i 3 mysqlV
        if [[ "$mysqlV" = '' ]]; then
            showError 'Invalid MySQL version' && exit
        fi

        showNotice "(Step 3/6) Please select the PHP version"
        echo "1) PHP-5.5"
        echo "2) PHP-5.6"
        echo "3) PHP-7.0"
        read -p 'PHP [1-3]: ' -r -e -i 3 phpV
        if [[ "$phpV" = '' ]]; then
            showError 'Invalid PHP version' && exit
        fi

        showNotice "(Step 4/6) Please select the Nginx version"
        echo "1) Nginx-1.8"
        echo "2) Nginx-1.9 (Dev)"
        read -p 'Nginx [1-2]: ' -r -e -i 2 nginxV
        if [[ "$nginxV" = '' ]]; then
            showError 'Invalid Nginx version' && exit
        fi

        showNotice "(Step 5/6) Please select the DB tool version"
        echo "1) Adminer"
        echo "2) phpMyAdmin"
        echo "3) Not need"
        read -p 'DB tool [1-3]: ' -r -e -i 1 dbV
        if [[ "$dbV" = '' ]]; then
            showError 'Invalid DB tool version' && exit
        fi

        showNotice "(Step 6/6) Use a proxy server to download rpms"
        echo "1) Source station"
        echo "2) Upaiyun CDN"
        read -p 'Proxy server [1-2]: ' -r -e -i 1 freeV
        if [[ "$freeV" = '' ]]; then
            showError 'Invalid Proxy server' && exit
        fi

        [[ -s /etc/selinux/config ]] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0 >/dev/null 2>&1

        yum_repos=$(find /etc/yum.repos.d/ -name "*.repo" -type f | wc -l)
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

        rm -rf /etc/localtime
        ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        yum_repos_s=$(find /etc/yum.repos.d/ -name '*.repo*' | grep 'epel\|mysql\|mariadb\|remi\|nginx' -c)
        if [[ "$yum_repos_s" -gt '0' ]]; then
            time=$(date +%s)
            mkdir -p "/etc/yum.repos.d/bak.$time"
            mv -bfu /etc/yum.repos.d/{epel*,mysql*,mariadb*,remi*,nginx*} "/etc/yum.repos.d/bak.$time" >& /dev/null
        fi

        showNotice 'Installing'

        yum install -y epel-release firewalld yum-utils unzip

        mysqlRepoUrl=$mysqlUrl
        mariaDBRepoUrl=$mariaDBUrl
        phpRepoUrl=$phpUrl
        nginxRepoUrl=$nginxUrl

        if [[ "$freeV" = "2" ]]; then
            mysqlRepoUrl=$mysqlCDNUrl
            mariaDBRepoUrl=$mariaDBCDNUrl
            phpRepoUrl=$phpCDNUrl
            nginxRepoUrl=$nginxCDNUrl

            mv -bfu /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak
            mv -bfu /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.bak

            wget -c --tries=3 -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
        fi

        rpm --import ${phpRepoUrl}/RPM-GPG-KEY-remi
        rpm --import ${nginxRepoUrl}/packages/keys/nginx_signing.key
        rpm -Uvh ${phpRepoUrl}/enterprise/remi-release-7.rpm
        rpm -Uvh ${nginxRepoUrl}/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

        if [[ "$mysqlV" = "1" || "$mysqlV" = "2" || "$mysqlV" = "3" ]]; then
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
            esac
            echo -e "[mariadb]\nname = MariaDB\nbaseurl = ${mariaDBRepoUrl}/${mariadbV}/centos7-amd64\ngpgkey=${mariaDBRepoUrl}/RPM-GPG-KEY-MariaDB\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo
        elif [[ "$mysqlV" = "4" || "$mysqlV" = "5" || "$mysqlV" = "6" ]]; then
            rpm --import mysql_pubkey.asc
            rpm -Uvh ${mysqlRepoUrl}/mysql-community-release-el7-5.noarch.rpm
            sed -i "s@${mysqlUrl}@${mysqlRepoUrl}@g" "$(find /etc/yum.repos.d/ -name "mysql-community*.repo" -type f)"
            installDB='mysqld'

            case $mysqlV in
                4)
                yum-config-manager --enable mysql55-community
                yum-config-manager --disable mysql56-community mysql57-community-dmr
                ;;
                5)
                yum-config-manager --enable mysql56-community
                yum-config-manager --disable mysql55-community mysql57-community-dmr
                ;;
                6)
                yum-config-manager --enable mysql57-community-dmr
                yum-config-manager --disable mysql55-community mysql56-community
                ;;
            esac
        fi

        phpRepo=$(find /etc/yum.repos.d/ -name "remi*.repo" -type f)

        sed -i "s@${phpUrl}@${phpRepoUrl}@g" "$phpRepo"

        if [[ "$freeV" = "1" ]]; then
            sed -i "/\$basearch/{n;s/^baseurl=/#baseurl=/g}" "$phpRepo"
            sed -i "/\$basearch/{n;n;s/^#mirrorlist=/mirrorlist=/g}" "$phpRepo"
        elif [[ "$freeV" = "2" ]]; then
            sed -i "/\$basearch/{n;s/^#baseurl=/baseurl=/g}" "$phpRepo"
            sed -i "/\$basearch/{n;n;s/^mirrorlist=/#mirrorlist=/g}" "$phpRepo"
        fi

        yum-config-manager --enable remi remi-test

        case $phpV in
            1)
            yum-config-manager --enable remi-php55
            yum-config-manager --disable remi-php56 remi-php70
            ;;
            2)
            yum-config-manager --enable remi-php56
            yum-config-manager --disable remi-php55 remi-php70
            ;;
            3)
            yum-config-manager --enable remi-php70
            yum-config-manager --disable remi-php55 remi-php56
            ;;
        esac

        nginxRepo=/etc/yum.repos.d/nginx.repo

        sed -i "s@${nginxUrl}@${nginxRepoUrl}@g" $nginxRepo

        if [[ "$nginxV" = "1" ]]; then
            sed -i "s/\/mainline//g" $nginxRepo
        elif [[ "$nginxV" = "2" ]]; then
            sed -i "s/packages/packages\/mainline/g" $nginxRepo
        fi

        yum clean all && yum makecache

        if [[ "$installDB" = "mariadb" ]]; then
            yum install -y MariaDB-server MariaDB-client
            sed -i "s@\[client-server\]@\[client\]\nport = 3306\nsocket = /home/userdata/mysqld.sock\n\n[mysqld]\ndatadir = /home/userdata\nsocket = /home/userdata/mysqld.sock\nlog-basename = mysqld\nlog-error = /home/userdata/mysqld.log\ngeneral-log\ngeneral-log-file = /home/userdata/mysqld-general.log\nslow-query-log\nslow-query-log-file = /home/userdata/mysqld-slow.log\npid-file = /home/userdata/mysqld.pid\n@g" /etc/my.cnf
            mysql_install_db --user=mysql
        elif [[ "$installDB" = "mysqld" ]]; then
            yum install -y mysql-community-server
            sed -i "s@/var/lib/mysql@/home/userdata@g" /etc/my.cnf
            sed -i "s@mysql.sock@mysqld.sock@g" /etc/my.cnf
            echo -e "\n[client]\nsocket = /home/userdata/mysqld.sock" >> /etc/my.cnf

            if [[ "$mysqlV" != "6" ]]; then
                [[ "$mysqlV" = "5" ]] && \
                sed -i "s@symbolic-links=0@symbolic-links=0\nexplicit_defaults_for_timestamp@g" /etc/my.cnf
                mysql_install_db --user=mysql
            else
                mysqld --initialize-insecure --user=mysql
            fi
        fi

        yum install -y nginx php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pdo_dblib php-recode php-snmp php-soap php-xml php-pecl-zip

        showNotice "Configurationing"

        wget -c --tries=3 -O LNMP-dev.zip https://github.com/maicong/LNMP/archive/dev.zip
        unzip LNMP-dev.zip
        cd LNMP-dev || showError "Configuration file not found" && exit;

        mkdir -p /etc/php-fpm.d.stop
        mv -bfu /etc/php-fpm.d/* /etc/php-fpm.d.stop/
        mv -bfu /etc/php.ini /etc/php.ini.bak

        mkdir -p /etc/nginx/{conf.d.stop,rewrite,ssl}
        mv -bfu /etc/nginx/conf.d/* /etc/nginx/conf.d.stop/
        mv -bfu /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        mv -bfu /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.bak

        cp -a etc/* /etc/

        chmod +x /etc/rc.d/init.d/vbackup
        chmod +x /etc/rc.d/init.d/vhost
        chmod +x /etc/rc.d/init.d/svnserve

        sed -i "s/localhost/${ipAddress}/g" /etc/nginx/conf.d/nginx-index.conf

        mkdir -p /home/{wwwroot,userdata}
        cp -a home/wwwroot/index/ /home/wwwroot/

        if [[ "$dbV" = "1" ]]; then
            cp -a DBMGT/Adminer /home/wwwroot/index/
            sed -i "s/phpMyAdmin/Adminer/g" /home/wwwroot/index/index.html
        elif [[ "$dbV" = "2" ]]; then
            yum install -y phpMyAdmin
            newHash=$(echo -n $RANDOM  | md5sum | sed "s/ .*//" | cut -b -18)
            sed -i "s/739174021564331540/${newHash}/g" /etc/phpMyAdmin/config.inc.php
            cp -a /usr/share/phpMyAdmin /home/wwwroot/index/
            rm -rf /home/wwwroot/index/phpMyAdmin/doc/html
            cp -a /usr/share/doc/phpMyAdmin-*/html /home/wwwroot/index/phpMyAdmin/doc/
        fi

        groupadd www
        useradd -m -s /sbin/nologin -g www www

        chown www:www -R /home/wwwroot
        chown mysql:mysql -R /home/userdata

        showNotice "Starting"

        systemctl enable ${installDB}.service
        systemctl enable php-fpm.service
        systemctl enable nginx.service
        systemctl enable firewalld.service

        systemctl start firewalld.service

        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --add-service=https
        firewall-cmd --reload

        systemctl start ${installDB}.service
        systemctl start php-fpm.service
        systemctl start nginx.service

        mysqladmin -u root password "$mysqlPWD"
        mysqladmin -u root -p"$mysqlPWD" -h "$(hostname)" password "$mysqlPWD"
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
                echo -e "\033[34m MariaDB Password: \033[0m ${mysqlPWD}"
            elif [[ "$installDB" = "mysqld" ]]; then
                echo -e "\033[34m MySQL Data: \033[0m /home/userdata/"
                echo -e "\033[34m MySQL User: \033[0m root"
                echo -e "\033[34m MySQL Password: \033[0m ${mysqlPWD}"
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
        exit
        ;;
        2)
        read -p 'Are you sure? (y/n): ' -r -e confirmYN
        if [[ "$confirmYN" = 'y' ]]; then
            showNotice "Uninstalling..."
            pgrep -u www 2>/dev/null | xargs -r kill
            pgrep mysql | xargs -r kill
            pgrep php | xargs -r kill
            pgrep nginx | xargs -r kill
            yum autoremove -y epel* epel-* mysql* mysql-* MariaDB-* httpd* httpd-* nginx* nginx-* php* php-* remi* remi-* 2>/dev/null
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
        exit
        ;;
        3)
        showNotice "Checking..."
        yum upgrade
        exit
        ;;
        4)
        showNotice "Nothing to do..."
        exit;;
    esac
done