---
title: usfully bash shell
date: 2023-11-07 15:00:48
tags:
---

1. 查看本机上的timer服务列表 `systemctl list-timers` , 查看对应服务的详细信息 `systemctl cat anacron.timer`
```shell
systemctl list-timers

root@ss20231017:~# systemctl cat anacron.timer
# /lib/systemd/system/anacron.timer
[Unit]
Description=Trigger anacron every hour

[Timer]
OnCalendar=*-*-* 07..23:30
RandomizedDelaySec=5m
Persistent=true

[Install]
WantedBy=timers.target
root@ss20231017:~#

```

2. `chrt` 查看linux程序的调度器以及调度的优先级。查看各个调度器的最大最小优先级`chrt -m` , 查看某个线程的优先级信息`chrt -p pid` ， 以某个优先级启动某个程序`chrt -f 99 sleep 10000` 

```shell
#chrt -m 
SCHED_OTHER min/max priority	: 0/0
SCHED_FIFO min/max priority	: 1/99
SCHED_RR min/max priority	: 1/99
SCHED_BATCH min/max priority	: 0/0
SCHED_IDLE min/max priority	: 0/0
SCHED_DEADLINE min/max priority	: 0/0


# pid = 166459
#chrt -f 99 sleep 1000

#chrt -p 166459
pid 166459's current scheduling policy: SCHED_FIFO
pid 166459's current scheduling priority: 99


```


3. 列出CPU消耗高的进程top10 
```shell

ps -eT -o%cpu,pid,tid,ppid,comm | grep -v CPU | sort -n -r | head -10

```


4. 端口查看进程

```shell

fuser -n tcp 22

```

5. shell中使用`$` 获取当前程序的pid，由于shell中$用于取变量，一般打印当前程序的PID，可以用`$$`来表示
```shell
# cat 1.sh
echo $$
cat /proc/$$/cgroup

```

6. 通过shell打印某一个pid的rss内存使用
该能力有几种方式都可以实现，第一种方式是通过统计`/proc/$pid/smaps`中的Rss，然后将所有的数据加起来，统计出来的就是Rss的大小。第二种方式是通过`ps `的方式来统计，具体如下:（从原理上看，两者实际是完全一样的，PS同样是读取/proc文件来获取资源的）

```shell

# 利用ps来统计所有的程序的资源开销，包括Rss 和Size，在实际使用的过程中，可以通过info top查看详细的命令说明情况
ps -axo stat,euid,ruid,tty,tpgid,sess,pgrp,ppid,pid,pcpu,comm,rss,size

# 利用/proc/$pid/smaps 分析内存的利用率情况，统计其Rss的使用
cat /proc/$pid/smaps | grep Rss | awk '{sum += $2}END{print sum/1024"MB"}' 

```

7. 查看某一个命令的详细使用文档，可以考虑使用info指令来查看,该命令可以查看这个指令的info 文档 : `info top` , `info chtr` ， `info ps `

8. 一些可以探索使用方式的工具: `cut `, `paste` , `xargs`


9. 下载一些gun库的源码，可以直接通过apt-get 进行下载 `apt-get source iputils-ping`

