CentOS 7 YUM 安装 LNMP 环境
=======

CentOS 7 YUM Installation: Nginx 1.8/1.9 + MySQL 5.5/5.6/5.7 + PHP 5.5/5.6/7.0

## 主要目录

站点： `/home/wwwroot/`

备份： `/home/backup/`

MySQL 数据： `/home/userdata/`

MySQL 配置： `/etc/my.cnf.d/`

Nginx 配置(启用)：`/etc/nginx/conf.d/`

Nginx 配置(禁用)：`/etc/nginx/conf.d.stop/`

PHP 配置(启用)：`/etc/php-fpm.d/`

PHP 配置(禁用)：`/etc/php-fpm.d.stop/`

phpMyAdmin 配置： `/etc/phpMyAdmin/`

## 安装

```
yum install -y wget unzip

wget https://github.com/maicong/LNMP/archive/master.zip

unzip master.zip && cd LNMP-master

bash lnmp.sh

# 将 log 输出到文件
# bash lnmp.sh 2>&1 | tee lnmp.log
```

## 服务管理

```
# 启动 MySQL
systemctl start mysqld.service

# 停止 MySQL
systemctl stop mysqld.service

# 重启 MySQL
systemctl restart mysqld.service

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
```

## 站点管理

```
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

 - `&lt;domain&gt;` 标识名称，默认：`domain`

 - `&lt;server_name&gt;` 域名列表，默认：`domain.com,www.domain.com`

 - `&lt;index_name&gt;` 首页文件，默认：`index.html,index.htm,index.php`

 - `&lt;rewrite_file&gt;` 伪静态规则文件，保存在 `/etc/nginx/rewrite/`，默认：`nomal.conf`

 - `&lt;host_subdirectory&gt;` 是否支持子目录绑定，`on` 或者 `off`，默认 `off`

#### 参数示例

添加一个标识为 `mysite` 的站点

```
# 增加一个空的伪静态文件
touch /etc/nginx/rewrite/mysite.conf

# 配置各项参数
service vhost add mysite mysite.com,www.mysite.com index.html,index.htm,index.php mysite.conf on

# 可以只配置名称和域名，其他保存默认：
service vhost add mysite mysite.com
```

启动标识为 `mysite` 的站点

```
service vhost start mysite
```

停止标识为 `mysite` 的站点

```
service vhost stop mysite
```

编辑标识为 `mysite` 的站点

```
service vhost edit mysite
```

删除标识为 `mysite` 的站点

```
service vhost del mysite
```

列出所有站点

```
service vhost list
```

## 备份

```
service vbackup (start,list,del) <delete name.tar.gz>
```

#### 参数说明

 - `start` 添加

 - `list` 列出

 - `del` 删除
 
 - `&lt;delete name.tar.gz&gt; ` 需要删除的备份文件名称，和 `del` 搭配使用，存放在 `/home/backup/`

#### 参数示例

添加一个新的备份

```
service vbackup start

```

列出备份文件

```
service vbackup list

```

删除一个备份

```
service vbackup del c7-20151010-101010.tar.gz

```

## 示例图

![](http://i13.tietuku.com/65bbbe289d44a5d0.png)


## 协议

The MIT License (MIT)
