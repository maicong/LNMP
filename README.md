CentOS 7 YUM 安装 LNMP 环境 (开发版)
=======

CentOS 7 YUM Installation: Nginx 1.12/1.13 + MySQL 5.5/5.6/5.7/8.0(MariaDB 5.5/10.0/10.1/10.2/10.3) + PHP 5.4/5.5/5.6/7.0/7.1/7.2 + phpMyAdmin(Adminer) ( **Development** )

## 说明

此分支为 LNMP 项目开发版，主要用于新功能的测试和 BUG 的修复。

## 安装

```bash
## 确保 wget 命令已经安装，已安装请忽略此步
yum install wget -y

## 执行安装脚本
sh -c "$(wget https://cdn.rawgit.com/maicong/LNMP/dev/lnmp.sh -O -)"

# 如果想保存安装日志，请将 log 输出到指定文件
# sh -c "$(wget https://cdn.rawgit.com/maicong/LNMP/dev/lnmp.sh -O -)" 2>&1 | tee lnmp.log
```

## 帮助
除安装命令不同外，其他操作方法和说明事项请查看 [README](https://github.com/maicong/LNMP/blob/master/README.md)。

如果有新的差异操作，这里会具体说明。

## 协议

The MIT License (MIT)
