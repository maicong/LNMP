CentOS yum 安装 LNMP 环境
=======

CentOS yum install: Nginx 1.8.x/1.9.x + MySQL 5.x + PHP 5.6.x/7.x

## 安装

```
yum install -y unzip

wget https://github.com/maicong/LNMP/archive/master.zip

unzip master.zip

cd LNMP-master

bash lnmp.sh 2>&1 | tee lnmp.log
```

## 管理

```
service vhost (start,stop,list,add,edit,del,exit) <domain> <server_name> <index_name> <rewrite_file> <host_subdirectory>
```

### 参数

start: 启动

stop: 停止

list: 列出

add: 添加

edit: 编辑

del: 删除

exit: 什么都不做

&lt;domain&gt;: 配置名称

&lt;server_name&gt;: 域名列表

&lt;index_name&gt;: 首页文件

&lt;rewrite_file&gt;: 伪静态规则文件

&lt;host_subdirectory&gt;: 是否支持子目录绑定


## 协议

The MIT License (MIT)
