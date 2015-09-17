CentOS yum 安装 LNMP 环境
=======

CentOS yum install: Nginx 1.8.x/1.9.x + MySQL 5.x + PHP 5.6.x/7.x/1.9

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

<domain>: 配置名称
<server_name>: 域名列表
<index_name>: 首页文件
<rewrite_file>: 伪静态规则文件
<host_subdirectory>: 是否支持子目录绑定

## 协议

The MIT License (MIT)

Copyright (c) 2015 MaiCong

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
