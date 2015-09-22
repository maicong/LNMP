CentOS 7 YUM 安装 LNMP 环境
=======

CentOS 7 YUM Installation: Nginx 1.8/1.9 + MySQL 5.5/5.6/5.7 + PHP 5.5/5.6/7.0

## 主要目录

站点文件存放目录： `/home/wwwroot/`

备份文件存放目录： `/home/backup/`

MySQL 文件存放目录： `/home/userdata/`

MySQL 配置文件目录： `/etc/my.cnf.d/`

Nginx 启用站点目录：`/etc/nginx/conf.d/`

Nginx 停用站点目录：`/etc/nginx/conf.d.stop/`

PHP 启用站点目录：`/etc/php-fpm.d/`

PHP 停用站点目录：`/etc/php-fpm.d.stop/`

phpMyAdmin 配置文件目录： `/etc/phpMyAdmin/`

## 安装

![](http://ww4.sinaimg.cn/large/67f51f75gw1ewbbw5zog8j20gt0f0tbn.jpg)

```
yum install -y unzip

wget https://github.com/maicong/LNMP/archive/master.zip

unzip master.zip

cd LNMP-master

bash lnmp.sh

# 输出到指定文件
# bash lnmp.sh 2>&1 | tee lnmp.log
```

## 管理

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

 - &lt;domain&gt;: 配置名称，例如：`domain`

 - &lt;server_name&gt;: 域名列表，例如：`domain.com,www.domain.com`

 - &lt;index_name&gt;: 首页文件，例如：`index.html,index.htm,index.php`

 - &lt;rewrite_file&gt;: 伪静态规则文件，保存在 `/etc/nginx/rewrite/` 例如：`nomal.conf`

 - &lt;host_subdirectory&gt;: 是否支持子目录绑定，`on` 或者 `off`

#### 参数示例

添加一个标识为 domain 的站点

```
service vhost add domain domain.com,www.domain.com index.html,index.htm,index.php nomal.conf on
```

启动标识为 domain 的站点

```
service vhost start domain
```

停止标识为 domain 的站点

```
service vhost stop domain
```

编辑标识为 domain 的站点

```
service vhost edit domain
```

删除标识为 domain 的站点

```
service vhost del domain
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
service vbackup del name.tar.gz

```

## 协议

The MIT License (MIT)
