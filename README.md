CentOS 7 安装 LNMP 环境
=======

### 可供安装的版本

yum 源方式:

```
Nginx 1.12/1.13
MySQL 5.5/5.6/5.7/8.0
MariaDB 5.5/10.0/10.1/10.2/10.3
PHP 5.4/5.5/5.6/7.0/7.1/7.2
phpMyAdmin
Adminer
```

源码编译方式:

```
OpenSSL 1.1.0f
Nginx 1.13.7
PHP 7.2.0
```

### 安装

使用 yum 源安装:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/maicong/LNMP/master/lnmp.sh)"
```

使用源码编译安装:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/maicong/LNMP/master/source.sh)"
```

### 使用

**服务管理**

```bash
# MySQL
systemctl {start,stop,status,restart} mysqld.service

# MariaDB
systemctl {start,stop,status,restart} mariadb.service

# PHP
systemctl {start,stop,status,restart} php-fpm.service

# Nginx
systemctl {start,stop,status,restart,reload} nginx.service
```

**站点管理**

```bash
# 列表
service vhost list

# 启动(重启)、停止
service vhost {start,stop} [<domain>]

# 新增、编辑
service vhost {add, edit} [<domain>] [<server_name>] [<index_name>] [<rewrite_file>] [<host_subdirectory>]

# 删除
service vhost del [<domain>]
```

参数说明

- `start` 启动、重启
- `stop` 停止
- `add` 新增
- `edit` 编辑
- `del` 删除
- `<domain>` 站点标识，默认：`domain`
- `<server_name>` 域名列表，使用 `,` 隔开，默认：`domain.com,www.domain.com`
- `<index_name>` 首页文件，依次生效，默认：`index.html,index.htm,index.php`
- `<rewrite_file>` 伪静态规则文件，保存在 `/etc/nginx/rewrite/`，默认：`nomal.conf`
- `<host_subdirectory>` 是否支持子目录绑定，`on` 或者 `off`，默认 `off`

示例

```bash
# 启动或重启所有站点
service vhost start

# 停止所有站点
service vhost stop

# 列出所有站点
service vhost list

# 添加一个标识为 `mysite`，域名为 `mysite.com` 的站点
service vhost add mysite mysite.com

# 启动或重启标识为 `mysite` 的站点
service vhost start mysite

# 停止标识为 `mysite` 的站点
service vhost stop mysite

# 编辑标识为 `mysite` 的站点
service vhost edit mysite

# 删除标识为 `mysite` 的站点
service vhost del mysite
```

**备份**

```bash
# 新建一个备份
service vbackup start

# 删除一个备份
service vbackup del [<file>.tar.gz]

# 列出所有备份
service vbackup list
```

### 协议

The MIT License (MIT)
