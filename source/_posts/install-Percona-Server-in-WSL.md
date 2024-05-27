---
title: install Percona Server in WSL
date: 2024-05-26 15:10:47
tags:
---
测试数据库链接存在的情况下，CRAC的恢复逻辑。同时由于windows的数据库下载比较慢，也想验证下mysql的企业特性，因此安装了Percona Server。后续会验证其线程池、代理、插件等特性。

# 安装
步骤参考： https://docs.percona.com/percona-server/innovation-release/apt-repo.html#install-percona-server-for-mysql-using-apt

```shell

# 替换安装的源
curl -O https://repo.percona.com/apt/percona-release_latest.generic_all.deb

sudo apt install gnupg2 lsb-release ./percona-release_latest.generic_all.deb

 sudo apt update

sudo percona-release enable-only ps-8x-innovation release

sudo percona-release enable tools release

sudo apt-get update

sudo apt install percona-server-server


```
