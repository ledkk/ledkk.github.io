---
title: mem ecc error cause sys load high
date: 2023-11-07 21:08:34
tags:
---
线上应用遇到在业务水位比较低的时候，load相对非常高， 详细表现为sys低、user低，runq相对也不高，但是load非常高。 实际排查下来是由于内存异常导致。 对于该问题需要进一步总结下合适的排查思路

1. load高的表现一般是runq搞，或者dunq高，runq一般是由于系统的负载比较高导致的问题，这种会同时引起cpu的升高，dunq高，是一般是由于等待io导致的整体cpu高，此时iowait会相对比较稿，磁盘也会比较高。 当两者都不高但load非常高的情况，就说明由于cpu处理缓慢，导致cpu的执行队列慢。

所以排查思路为 

top 看cpu、load、iowait相关的数据，可以看到cpu低、load搞
tsar 看load 的详细信息，可以看到runq的表现，和磁盘的表现，排除是由于系统负载高以及磁盘io高导致的整机load高。
使用perf 看机器的cpu运行情况，重点看cpu的ips ，可以看看cpu的执行频率情况，确定是cpu负载稿，还是由于cpu的执行效率低导致`perf stat -a `
在所有问题查不清楚的时候，看看内核日志`dmesg -T` ，也许内核日志里有一些线索。。。。

```shell


sudo perf stat -a
^C
 Performance counter stats for 'system wide':

     326237.203455      task-clock (msec)         #   16.001 CPUs utilized
           750,189      context-switches          #    0.002 M/sec
            26,724      cpu-migrations            #    0.082 K/sec
           393,003      page-faults               #    0.001 M/sec
   229,354,281,442      cycles                    #    0.703 GHz
   <not supported>      stalled-cycles-frontend
   <not supported>      stalled-cycles-backend
   154,354,075,229      instructions              #    0.67  insns per cycle
    36,761,887,530      branches                  #  112.685 M/sec
       271,931,138      branch-misses             #    0.74% of all branches

      20.388467618 seconds time elapsed


```
