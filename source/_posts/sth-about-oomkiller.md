---
title: sth about oomkiller
date: 2023-12-07 11:39:33
tags:
---
经常会遇到oomkiller，但是oomkiller内部的机制是什么样子的？ oomkiller选择的时机是什么样子的？ oomkiller选择的pid是有什么背景以及机制？ 也想做一个仔细的探讨。如下是一个线上的oomkiller的内核日志
```shell

[Thu Dec  7 00:29:05 2023] dnf cpuset=kubeNodeAgent.service mems_allowed=0-1
[Thu Dec  7 00:29:05 2023] CPU: 32 PID: 95251 Comm: dnf Kdump: loaded Tainted: GF       W  OE K   4.19.91-xxx.xxxx.x86_64 #1
[Thu Dec  7 00:29:05 2023] Hardware name: xxxxxx ECS/xxxx  BIOS 3.3.44 01/08/2021
[Thu Dec  7 00:29:05 2023] Call Trace:
[Thu Dec  7 00:29:05 2023]  dump_stack+0x66/0x8b
[Thu Dec  7 00:29:05 2023]  dump_memcg_header+0x12/0x40
[Thu Dec  7 00:29:05 2023]  oom_kill_process+0x201/0x2f0
[Thu Dec  7 00:29:05 2023]  out_of_memory+0x12f/0x510
[Thu Dec  7 00:29:05 2023]  mem_cgroup_out_of_memory+0xdd/0x100
[Thu Dec  7 00:29:05 2023]  try_charge+0x847/0x870
[Thu Dec  7 00:29:05 2023]  ? __ext4_journal_get_write_access+0x36/0x70 [ext4]
[Thu Dec  7 00:29:05 2023]  mem_cgroup_charge+0xe2/0x220
[Thu Dec  7 00:29:05 2023]  ? ext4_mark_iloc_dirty+0x5e/0x80 [ext4]
[Thu Dec  7 00:29:05 2023]  __add_to_page_cache_locked+0x5f/0x220
[Thu Dec  7 00:29:05 2023]  add_to_page_cache_lru+0x4a/0xc0
[Thu Dec  7 00:29:05 2023]  pagecache_get_page+0xfc/0x310
[Thu Dec  7 00:29:05 2023]  grab_cache_page_write_begin+0x1f/0x40
[Thu Dec  7 00:29:05 2023]  ext4_da_write_begin+0xdc/0x490 [ext4]
[Thu Dec  7 00:29:05 2023]  generic_perform_write+0xba/0x1b0
[Thu Dec  7 00:29:05 2023]  ext4_buffered_write_iter+0x94/0x120 [ext4]
[Thu Dec  7 00:29:06 2023]  ext4_file_write_iter+0x6c/0x6d0 [ext4]
[Thu Dec  7 00:29:06 2023]  ? try_to_release_page+0x60/0x60
[Thu Dec  7 00:29:06 2023]  new_sync_write+0xeb/0x150
[Thu Dec  7 00:29:06 2023]  vfs_write+0xb0/0x190
[Thu Dec  7 00:29:06 2023]  ksys_write+0x5a/0xd0
[Thu Dec  7 00:29:06 2023]  ? get_vtime_delta+0x13/0xb0
[Thu Dec  7 00:29:06 2023]  do_syscall_64+0x7b/0x200
[Thu Dec  7 00:29:06 2023]  entry_SYSCALL_64_after_hwframe+0x44/0xa9
[Thu Dec  7 00:29:06 2023] RIP: 0033:0x7f5f528376fd
[Thu Dec  7 00:29:06 2023] Code: cd 20 00 00 75 10 b8 01 00 00 00 0f 05 48 3d 01 f0 ff ff 73 31 c3 48 83 ec 08 e8 4e fd ff ff 48 89 04 24 b8 01 00 00 00 0f 05 <48> 8b 3c 24 48 89 c2 e8 97 fd ff ff 48 89 d0 48 83 c4 08 48 3d 01
[Thu Dec  7 00:29:06 2023] RSP: 002b:00007ffdfef524b0 EFLAGS: 00000293 ORIG_RAX: 0000000000000001
[Thu Dec  7 00:29:06 2023] RAX: ffffffffffffffda RBX: 0000000000008000 RCX: 00007f5f528376fd
[Thu Dec  7 00:29:06 2023] RDX: 0000000000008000 RSI: 00007ffdfef52550 RDI: 000000000000001c
[Thu Dec  7 00:29:06 2023] RBP: 0000000000fbc600 R08: 00000000968d04df R09: 000000006570a150
[Thu Dec  7 00:29:06 2023] R10: 00007ffdfef524a0 R11: 0000000000000293 R12: 0000000000923be0
[Thu Dec  7 00:29:06 2023] R13: 00007ffdfef52550 R14: 00007f5f417b53a0 R15: 0000000000008000
[Thu Dec  7 00:29:06 2023] Task in /infra.slice/kubeNodeAgent.service killed as a result of limit of /infra.slice/kubeNodeAgent.service
[Thu Dec  7 00:29:06 2023] memory: usage 1048576kB, limit 1048576kB, failcnt 77296
[Thu Dec  7 00:29:06 2023] memory+swap: usage 1048576kB, limit 9007199254740988kB, failcnt 0
[Thu Dec  7 00:29:06 2023] kmem: usage 0kB, limit 9007199254740988kB, failcnt 0
[Thu Dec  7 00:29:06 2023] Memory cgroup stats for /infra.slice/kubeNodeAgent.service: cache:1188KB rss:1052304KB rss_huge:0KB shmem:0KB mapped_file:396KB dirty:1584KB writeback:0KB swap:0KB workingset_refault_anon:0KB workingset_refault_file:396528KB workingset_activate_anon:0KB workingset_activate_file:15840KB workingset_restore_anon:0KB workingset_restore_file:4092KB workingset_nodereclaim:0KB inactive_anon:1051908KB active_anon:0KB inactive_file:0KB active_file:0KB unevictable:0KB
[Thu Dec  7 00:29:06 2023] Tasks state (memory values in pages):


```

# 什么时机会触发OOMKiller ？ 





# oomkiller怎么选择杀那些进程？
