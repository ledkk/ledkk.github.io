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


10. 通过sar查看系统监控相关的数据，默认情况下只能查看当天的数据，可以通过如下脚本查看之前某一天的数据, 其原理就是通过sar产生的数据文件读取相关的数据，并做展示。

```shell

sar -f /var/log/sysstat/sa$(date +%d -d yesterday)

```

11. 安装sar工具后，默认情况下并不会默认开启，需要主动打开，操作的方式为，修改`/etc/default/sysstat` 文件，设置`ENABLED="true"` 即可


12. 查看整个操作系统的内存使用情况，直接通过free命令只能看到整体的内容使用情况，这些内存使用情况，还需要进一步分区分内存是被slabinfo占用，还是被Pagetable占用，或者是被应用的rss占用。可以通过如下脚本进行采集分析, 由于RSS包含程序和程序之间公用的部分，所以已下的内容加起来要比实际的内容要多。操作系统分配的内存还有一部分是通过allocpage方式直接申请的，这部分内存无法被统计到。

```shell
# cat mem.sh

for PROC in `ls /proc/ | grep "^[0-9]"`
do
	if [ -f /proc/$PROC/statm ]; then
		TEP=`cat /proc/$PROC/statm | awk '{print $2}'`
		RSS=`expr $RSS + $TEP`
	fi
done

RSS=`expr $RSS \* 4 / 1024`
PageTable=`grep PageTables /proc/meminfo | awk '{print $2/1024}'`
SlabInfo=`cat /proc/slabinfo | awk 'BEGIN{sum=0;}{sum=sum+$3*$4;}END{print sum/1024/1024}'`
echo "RSS:"$RSS"MB", "PageTable: " $PageTable"MB", "SlabInfo: " $SlabInfo"MB"

```


13. 在网络收包的时候，`NET_RX_SOFTIRQ` 主要是由`net_rx_action` 处理，`receive_mergeable` 是和`virtio_net`驱动有关系。 网络相关的内容，通过ss命令可以快速的分析其网络状态。

```shell
~# ss -s
Total: 1165
TCP:   10 (estab 3, closed 1, orphaned 0, timewait 1)

Transport Total     IP        IPv6
RAW	  1         0         1
UDP	  9         6         3
TCP	  9         6         3
INET	  19        12        7
FRAG	  0         0         0

~# ss -ltnpamO
State                    Recv-Q                Send-Q                                Local Address:Port                                  Peer Address:Port                Process
LISTEN                   0                     4096                                  127.0.0.53%lo:53                                         0.0.0.0:*                    users:(("systemd-resolve",pid=451,fd=13)) skmem:(r0,rb131072,t0,tb16384,f0,w0,o0,bl0,d0)
LISTEN                   0                     128                                         0.0.0.0:22                                         0.0.0.0:*                    users:(("sshd",pid=806,fd=3)) skmem:(r0,rb131072,t0,tb16384,f0,w0,o0,bl0,d5837)
LISTEN                   0                     5                                         127.0.0.1:631                                        0.0.0.0:*                    users:(("cupsd",pid=215026,fd=7)) skmem:(r0,rb131072,t0,tb16384,f0,w0,o0,bl0,d0)
TIME-WAIT                0                     0                                    192.168.10.227:47610                               100.100.45.106:443
ESTAB                    0                     0                                    192.168.10.227:60340                                100.100.30.25:80                   users:(("AliYunDun",pid=58400,fd=11)) skmem:(r0,rb2519636,t0,tb87040,f0,w0,o0,bl0,d1)
TIME-WAIT                0                     0                                    192.168.10.227:43566                               100.100.45.106:80
ESTAB                    0                     0                                    192.168.10.227:48550                                146.75.114.49:443                  users:(("fwupdmgr",pid=62734,fd=10)) skmem:(r0,rb847456,t0,tb87040,f8192,w0,o0,bl0,d13)
ESTAB                    0                     0                                    192.168.10.227:22                                   42.120.74.223:56563                users:(("sshd",pid=215910,fd=4)) skmem:(r0,rb2509544,t0,tb3951616,f4096,w0,o0,bl0,d328)
LISTEN                   0                     2                                                 *:3389                                             *:*                    users:(("xrdp",pid=54176,fd=11)) skmem:(r0,rb131072,t0,tb65536,f0,w0,o0,bl0,d4685)
LISTEN                   0                     2                                             [::1]:3350                                          [::]:*                    users:(("xrdp-sesman",pid=54158,fd=7)) skmem:(r0,rb131072,t0,tb65536,f0,w0,o0,bl0,d0)
LISTEN                   0                     5                                             [::1]:631                                           [::]:*                    users:(("cupsd",pid=215026,fd=6)) skmem:(r0,rb131072,t0,tb16384,f0,w0,o0,bl0,d0)


~# cat /proc/net/sockstat
sockets: used 1165
TCP: inuse 6 orphan 0 tw 1 alloc 9 mem 3
UDP: inuse 6 mem 3
UDPLITE: inuse 0
RAW: inuse 0
FRAG: inuse 0 memory 0


```







