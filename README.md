CentOS 7 YUM 安装 LNMP 环境
=======

CentOS 7 YUM Installation: Nginx 1.8.x/1.9.x + MySQL 5.x + PHP 5.6.x/7.x

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

## 协议

The MIT License (MIT)
