CentOS 7 YUM 安装 LNMP 环境 (开发版)
=======

CentOS 7 YUM Installation: Nginx 1.8/1.9 + MySQL 5.5/5.6/5.7(MariaDB 5.5/10.0/10.1) + PHP 5.5/5.6/7.0 + phpMyAdmin(Adminer) ( **Development** )

## 说明

此分支为 LNMP 项目开发版，主要用于新功能的测试和 BUG 的修复。

## 安装

```bash
## 一键安装命令
yum install -y wget unzip && wget https://git.io/vaztP -O LNMP-dev.zip && unzip LNMP-dev.zip && cd LNMP-dev && bash lnmp.sh


## 分步骤安装命令

# 1、安装 wget 和 unzip
yum install -y wget unzip

# 2、下载并解压安装包
wget https://github.com/maicong/LNMP/archive/dev.zip -O LNMP-dev.zip

# 3、解压安装包
unzip LNMP-dev.zip

# 4、进入安装包目录
cd LNMP-dev

# 5、执行安装命令
bash lnmp.sh

# 如果想保存安装日志，请将 log 输出到指定文件
# bash lnmp.sh 2>&1 | tee lnmp.log
```

## 帮助
除安装命令不同外，其他操作方法和说明事项请查看 [README](https://github.com/maicong/LNMP/blob/master/README.md)。

如果有新的差异操作，这里会具体说明。

## 协议

The MIT License (MIT)
