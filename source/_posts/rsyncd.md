---
title: rsyncd
date: 2024-09-27 17:26:53
tags:
---

1. rsync config 

```shell
root@al20231110:~# cat /etc/rsyncd.conf
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsyncd.lock


[note]
	comment = note
	path = /root/note
	uid = test
	gid = test
	use chroot = yes
	read only = no
	list = yes
	hosts allow=10.0.8.10

```


2. rsync deamon start 

`rsync --daemon`

3. rsync client 

rsync -vrtaz rsync://johnzb@10.0.8.1/note ./
