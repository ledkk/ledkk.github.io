---
title: sth about linux
date: 2023-12-04 11:25:39
tags:
---
1. 查看Linux系统的性能数据，可以从procfs文件中获得`cat /proc/stat` .其内包含了系统的基本信息，包括CPU、运行情况、中断、IO等。
```shell

# cat /proc/stat
cpu  2475801 26920 1543326 831255053 126353 0 8014 0 0 0
cpu0 1200337 13938 770224 415719375 48294 0 4445 0 0 0
cpu1 1275464 12981 773101 415535678 78058 0 3569 0 0 0
intr 3162925830 0 9 0 0 1257 0 3 0 0 0 0 34 15 0 0 0 0 0 0 0 0 0 0 0 0 50 0 4238742 0 1802026 2956565 1456602 992957 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 5997613057
btime 1697473419
processes 298842
procs_running 1
procs_blocked 0
softirq 783883930 0 284012127 16 7265487 4208089 0 37801 284186406 19679 204154325

```
2. 打印当前CPU在执行的内容`echo "l" > /proc/sysrq-trigger`
```shell
#dmesg -T

[Mon Dec  4 11:23:21 2023] sysrq: Show backtrace of all active CPUs
[Mon Dec  4 11:23:21 2023] NMI backtrace for cpu 0
[Mon Dec  4 11:23:21 2023] CPU: 0 PID: 298644 Comm: bash Tainted: G           OE     5.4.0-162-generic #179-Ubuntu
[Mon Dec  4 11:23:21 2023] Hardware name: Alibaba Cloud Alibaba Cloud ECS, BIOS 449e491 04/01/2014
[Mon Dec  4 11:23:21 2023] Call Trace:
[Mon Dec  4 11:23:21 2023]  dump_stack+0x6d/0x8b
[Mon Dec  4 11:23:21 2023]  ? lapic_can_unplug_cpu+0x80/0x80
[Mon Dec  4 11:23:21 2023]  nmi_cpu_backtrace.cold+0x14/0x53
[Mon Dec  4 11:23:21 2023]  nmi_trigger_cpumask_backtrace+0xe8/0xf0
[Mon Dec  4 11:23:21 2023]  arch_trigger_cpumask_backtrace+0x19/0x20
[Mon Dec  4 11:23:21 2023]  sysrq_handle_showallcpus+0x17/0x20
[Mon Dec  4 11:23:21 2023]  __handle_sysrq.cold+0x48/0x107
[Mon Dec  4 11:23:21 2023]  write_sysrq_trigger+0x28/0x40
[Mon Dec  4 11:23:21 2023]  proc_reg_write+0x43/0x70
[Mon Dec  4 11:23:21 2023]  __vfs_write+0x1b/0x40
[Mon Dec  4 11:23:21 2023]  vfs_write+0xb9/0x1a0
[Mon Dec  4 11:23:21 2023]  ksys_write+0x67/0xe0
[Mon Dec  4 11:23:21 2023]  __x64_sys_write+0x1a/0x20
[Mon Dec  4 11:23:21 2023]  do_syscall_64+0x57/0x190
[Mon Dec  4 11:23:21 2023]  entry_SYSCALL_64_after_hwframe+0x5c/0xc1
[Mon Dec  4 11:23:21 2023] RIP: 0033:0x7fbb5987c077
[Mon Dec  4 11:23:21 2023] Code: 64 89 02 48 c7 c0 ff ff ff ff eb bb 0f 1f 80 00 00 00 00 f3 0f 1e fa 64 8b 04 25 18 00 00 00 85 c0 75 10 b8 01 00 00 00 0f 05 <48> 3d 00 f0 ff ff 77 51 c3 48 83 ec 28 48 89 54 24 18 48 89 74 24
[Mon Dec  4 11:23:21 2023] RSP: 002b:00007ffff3a8dae8 EFLAGS: 00000246 ORIG_RAX: 0000000000000001
[Mon Dec  4 11:23:21 2023] RAX: ffffffffffffffda RBX: 0000000000000002 RCX: 00007fbb5987c077
[Mon Dec  4 11:23:21 2023] RDX: 0000000000000002 RSI: 00005560583b0020 RDI: 0000000000000001
[Mon Dec  4 11:23:21 2023] RBP: 00005560583b0020 R08: 000000000000000a R09: 0000000000000001
[Mon Dec  4 11:23:21 2023] R10: 0000556056fc9017 R11: 0000000000000246 R12: 0000000000000002
[Mon Dec  4 11:23:21 2023] R13: 00007fbb5995b6a0 R14: 00007fbb599574a0 R15: 00007fbb599568a0
[Mon Dec  4 11:23:21 2023] Sending NMI from CPU 0 to CPUs 1:
[Mon Dec  4 11:23:21 2023] NMI backtrace for cpu 1 skipped: idling at native_safe_halt+0xe/0x10


```
3. 向内核中输出内容`echo "sth " > /dev/kmsg `

4. 查看procfs文件的描述信息  `man procfs`
