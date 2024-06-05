---
title: what is linux bridge
date: 2024-06-05 20:48:14
tags:
---
网桥原本是一个二层的物理设备，在同一个网桥内的设备相互之间通过mac地址进行访问。在linux系统内，可以通过`brctl`添加网桥设备，并将网络虚拟机的虚拟网卡添加到同一个网桥内，让这个写虚拟设备可以相互之间进行通信。

相关的安装脚本，以及测试脚本：

```shell


# 安装相关的控制器
sudo apt install bridge-utils


# 添加网桥设备

sudo brctl add bridge testbridge


```


Openvswitch VS linux bridge : https://kumul.us/switches-ovs-vs-linux-bridge-simplicity-rules/


openswitch: https://pve.proxmox.com/wiki/Open_vSwitch

vs : https://ioflood.com/s3-5-callegati-performance.pdf

