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

