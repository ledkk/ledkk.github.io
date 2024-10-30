---
title: get_ip_route
date: 2024-10-30 19:44:21
tags:
---
当前机器有多张网卡的时候，需要知道某一个请求从那个接口出去时，可以通过`ip route get $ip` 的方式获取出口IP；示例如下

```shell

@phy:~/code$ ip route get 8.8.8.8
8.8.8.8 via 192.168.0.1 dev enp3s0 src 192.168.0.4 uid 1000
    cache

```
