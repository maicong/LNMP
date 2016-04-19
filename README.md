CentOS 7 YUM 安装 LNMP 环境
=======

CentOS 7 YUM Installation: Nginx 1.8/1.9 + MySQL 5.5/5.6/5.7(MariaDB 5.5/10.0/10.1) + PHP 5.5/5.6/7.0 + phpMyAdmin(Adminer)

## 1、主要目录

站点： `/home/wwwroot/`

备份： `/home/backup/`

MySQL、MariaDB 数据： `/home/userdata/`

MySQL、MariaDB 配置： `/etc/my.cnf`、`/etc/my.cnf.d/`

Nginx 配置(启用)： `/etc/nginx/conf.d/`

Nginx 配置(禁用)： `/etc/nginx/conf.d.stop/`

PHP 配置(启用)： `/etc/php-fpm.d/`

PHP 配置(禁用)： `/etc/php-fpm.d.stop/`

phpMyAdmin 配置： `/etc/phpMyAdmin/`

SVN 配置： `/var/svn/repos/`

数据库 root 默认密码：`cat /home/userdata/initialPWD.txt`

## 2、安装

***建议安装 CentOS 7 Minimal (最小化安装) 后再使用本脚本安装环境***

```bash
## 一键安装命令
yum install -y wget unzip && wget https://git.io/v2OPx -O LNMP.zip && unzip LNMP.zip && cd LNMP-master && bash lnmp.sh


## 分步骤安装命令

# 1、安装 wget 和 unzip
yum install -y wget unzip

# 2、下载并解压安装包
wget https://github.com/maicong/LNMP/archive/master.zip

# 3、解压安装包
unzip master.zip

# 4、进入安装包目录
cd LNMP-master

# 5、执行安装命令
bash lnmp.sh

# 如果想保存安装日志，请将 log 输出到指定文件
# bash lnmp.sh 2>&1 | tee lnmp.log
```

## 3、服务管理

```bash
# 启动 MySQL
systemctl start mysqld.service

# 停止 MySQL
systemctl stop mysqld.service

# 重启 MySQL
systemctl restart mysqld.service

# 启动 MariaDB
systemctl start mariadb.service

# 停止 MariaDB
systemctl stop mariadb.service

# 重启 MariaDB
systemctl restart mariadb.service

# 启动 PHP
systemctl start php-fpm.service

# 停止 PHP
systemctl stop php-fpm.service

# 重启 PHP
systemctl restart php-fpm.service

# 启动 Nginx
systemctl start nginx.service

# 停止 Nginx
systemctl stop nginx.service

# 重启 Nginx
systemctl restart nginx.service

# 启动 SVN
systemctl start svnserve.service

# 停止 SVN
systemctl stop svnserve.service

# 重启 SVN
systemctl restart svnserve.service
```

## 4、站点管理

```bash
service vhost (start,stop,list,add,edit,del,exit) <domain> <server_name> <index_name> <rewrite_file> <host_subdirectory>
```

#### 参数说明

 - `start` 启动

 - `stop` 停止

 - `list` 列出

 - `add` 添加

 - `edit` 编辑

 - `del` 删除

 - `exit` 什么都不做

 - `<domain>` 标识名称，默认：`domain`

 - `<server_name>` 域名列表，默认：`domain.com,www.domain.com`

 - `<index_name>` 首页文件，默认：`index.html,index.htm,index.php`

 - `<rewrite_file>` 伪静态规则文件，保存在 `/etc/nginx/rewrite/`，默认：`nomal.conf`

 - `<host_subdirectory>` 是否支持子目录绑定，`on` 或者 `off`，默认 `off`

#### 参数示例

```bash
# 添加一个标识为 `mysite`，域名为 `mysite.com` 的站点
service vhost add mysite mysite.com

# 启动标识为 `mysite` 的站点
service vhost start mysite

# 停止标识为 `mysite` 的站点
service vhost stop mysite

# 编辑标识为 `mysite` 的站点
service vhost edit mysite

# 删除标识为 `mysite` 的站点
service vhost del mysite

# 列出所有站点
service vhost list
```

## 5、SVN 安装

***项目名称请和站点标识保持一致，不然无法正常 checkout***

```bash
# SVN 安装命令
bash svn.sh
```


## 6、伪静态文件

```bash
# 增加一个 `wordpress` 伪静态文件
touch /etc/nginx/rewrite/wordpress.conf

# 修改 `mysite` 站点的配置
service vhost edit mysite mysite.com,www.mysite.com index.html,index.php,default.php wordpress.conf on
```

## 7、备份

```bash
service vbackup (start,list,del) <delete name.tar.gz>
```

#### 参数说明

 - `start` 添加

 - `list` 列出

 - `del` 删除

 - `<delete name.tar.gz> ` 需要删除的备份文件名称，和 `del` 搭配使用，存放在 `/home/backup/`

#### 参数示例

```bash
# 添加一个新的备份
service vbackup start

# 列出备份文件
service vbackup list

# 删除一个备份
service vbackup del c7-20151010-101010.tar.gz
```

## 8、示例图

![](http://i13.piimg.com/1b0ce6885457c95b.png)

![](http://i13.piimg.com/184a2be1381e39a5.png)


## 9、协议

The MIT License (MIT)
