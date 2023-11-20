---
title: how to install and use perf in ubuntu
date: 2023-11-20 20:07:38
tags:
---
perf是linux下自带的非常强大的性能分析工具，利用perf可以查找系统中的各种瓶颈，对于linux系统的内核分析有很大的帮助。

# ubuntu下安装perf工具

直接执行perf命令的时候，ubuntu下会提示需要安装的软件，按照对应的提示即可完成perf工具的安装，对应的cloud的工具，可以不用安装
```shell
apt install linux-tools-common
apt install linux-tools-5.4.0-162-generic
```

# 使用perf工具

### perf top
`perf top` 查看系统的实时性能问题，


### perf ftrace 
`perf ftrace ` perf工具对ftrace的包装，用于应用的系统调用相关的内容，可以利用该工具分析一个程序的系统调用情况，以及其各个方面的耗时情况



