---
title: mem ecc error cause sys load high
date: 2023-11-07 21:08:34
tags:
---
线上应用遇到在业务水位比较低的时候，load相对非常高， 详细表现为sys低、user低，runq相对也不高，但是load非常高。 实际排查下来是由于内存异常导致。 对于该问题需要进一步总结下合适的排查思路

```shell

[Wed Dec  6 21:24:46 2023] EDAC skx MC0: HANDLING MCE MEMORY ERROR
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: CPU 0: Machine Check Event: 0x0 Bank 7: 0xdc10000001010090
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: TSC 0x0
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: ADDR 0x20edba94c0
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: MISC 0x200006c307e01086
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: PROCESSOR 0:0x50654 TIME 1701869556 SOCKET 0 APIC 0x0
[Wed Dec  6 21:24:46 2023] EDAC MC0: 16384 CE memory read error on CPU_SrcID#0_MC#0_Chan#0_DIMM#1 (channel:0 slot:1 page:0x20edba9 offset:0x4c0 grain:32 syndrome:0x0 -  OVERFLOW err_code:0x0101:0x0090 socket:0 imc:0 rank:0 bg:3 ba:2 row:0x106ce col:0x258 retry_rd_err_log[0000a20d 00000000 0000ffff 0476f10f 0000fb4b] correrrcnt[0000 0000 0000 0000 a9b4 0000 0000 0000])
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: HANDLING MCE MEMORY ERROR
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: CPU 0: Machine Check Event: 0x0 Bank 13: 0xcc001380000800c0
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: TSC 0x0
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: ADDR 0xd6db0b8c0
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: MISC 0x12213fffffffc086
[Wed Dec  6 21:24:46 2023] EDAC skx MC0: PROCESSOR 0:0x50654 TIME 1701869556 SOCKET 0 APIC 0x0
[Wed Dec  6 21:24:46 2023] EDAC MC0: 78 CE memory scrubbing error on CPU_SrcID#0_MC#0_Chan#0_DIMM#1 (channel:0 slot:1 page:0xd6db0b offset:0x8c0 grain:32 syndrome:0x0 -  OVERFLOW err_code:0x0008:0x00c0 socket:0 imc:0 rank:0 bg:3 ba:2 row:0x6ecc col:0xe8 retry_rd_err_log[0000a20d 00000000 ffff0000 0434f10f 000091dd] correrrcnt[0000 0000 0000 0000 b424 0000 0000 0000])



```

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

查看当前任务的进程状态分布情况 `ps axl  | awk '{print $10}'  | sort | uniq -c | sort -n` ， 查看处于D状态的进程信息`ps axl | awk '$10 ~/D/ {print $0}'`
查看某一个进程的当前在执行的线程栈情况`cat /proc/pid/stack`


### 说明
`ps aux ` 和 `ps -axu ` 是存在差异的，`ps aux` 会添加线程stat信息，而`ps -aux`并不会


`top -H -b -d 1 -n 10 | awk '$3~/(^0$)|(^10$)|(-51)/'  | awk '$8~/D|R/'`
