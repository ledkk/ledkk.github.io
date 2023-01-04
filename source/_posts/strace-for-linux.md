---
title: strace_for_linux
date: 2022-12-30 22:31:39
tags:
---
近期在研究Linux相关的内容，比如透明大页对系统性能的影响，以及一些Linux程序的运行情况。由于对C以及Linux并不是特别熟悉，在学习一些程序的时候，总是有一种云里雾里的感觉，因此想找到一些观测工具，能看到Linux系统下程序的执行情况。类似java生态里的Arthas、btrace的工具。经过几番查找，找到了可能有用的几个工具：`strace`、`ebpf` 、`systemtap`、`kprobe`,从网上看了比较多的内容，但还是一知半解，因此决定逐个击破，今天先看看`strace`相关的内容。最终目的是熟悉linux下的观测工具，比能熟练解决linux下的系统问题。

# strace 是什么
    strace 是一个非常有用的诊断、debug工具。针对无法找到源码的程序，如果想要观察这个程序的执行过程时，strace可以很方便的跟踪程序的执行过程。

使用方式
```shell
 strace [-ACdffhikqqrtttTvVwxxyyzZ] [-I n] [-b execve] [-e expr]... [-a column] [-o file] [-s strsize] [-X format]
              [-P path]... [-p pid]... [--seccomp-bpf] { -p pid | [-DDD] [-E var[=val]]... [-u username] command [args] }

       strace -c [-dfwzZ] [-I n] [-b execve] [-e expr]... [-O overhead] [-S sortby] [-P path]... [-p pid]... [--seccomp-bpf] {
              -p pid | [-DDD] [-E var[=val]]... [-u username] command [args] }
```

```shell

# 安装strace 
 sudo apt install strace


# 查看程序的系统调用情况
johnzb@ubuntu:~$ strace ./a.out
execve("./a.out", ["./a.out"], 0x7ffd938259d0 /* 23 vars */) = 0
brk(NULL)                               = 0x55e35ace7000
arch_prctl(0x3001 /* ARCH_??? */, 0x7ffcccdee110) = -1 EINVAL (Invalid argument)
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=75093, ...}) = 0
mmap(NULL, 75093, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7fb422051000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\300A\2\0\0\0\0\0"..., 832) = 832
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0\20\0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0", 32, 848) = 32
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0\30x\346\264ur\f|Q\226\236i\253-'o"..., 68, 880) = 68
fstat(3, {st_mode=S_IFREG|0755, st_size=2029592, ...}) = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fb42204f000
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0\20\0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0", 32, 848) = 32
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0\30x\346\264ur\f|Q\226\236i\253-'o"..., 68, 880) = 68
mmap(NULL, 2037344, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7fb421e5d000
mmap(0x7fb421e7f000, 1540096, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x22000) = 0x7fb421e7f000
mmap(0x7fb421ff7000, 319488, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x19a000) = 0x7fb421ff7000
mmap(0x7fb422045000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1e7000) = 0x7fb422045000
mmap(0x7fb42204b000, 13920, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7fb42204b000
close(3)                                = 0
arch_prctl(ARCH_SET_FS, 0x7fb422050540) = 0
mprotect(0x7fb422045000, 16384, PROT_READ) = 0
mprotect(0x55e358d2c000, 4096, PROT_READ) = 0
mprotect(0x7fb422091000, 4096, PROT_READ) = 0
munmap(0x7fb422051000, 75093)           = 0
brk(NULL)                               = 0x55e35ace7000
brk(0x55e35ad08000)                     = 0x55e35ad08000
openat(AT_FDCWD, "strace_demo.txt", O_WRONLY|O_CREAT|O_TRUNC, 0666) = 3
fstat(3, {st_mode=S_IFREG|0664, st_size=0, ...}) = 0
write(3, "Write this to the file", 22)  = 22
close(3)                                = 0
exit_group(0)                           = ?
+++ exited with 0 +++




# 查看创建进程相关的系统调用
strace -e trace=process ./a.out


# 查看文件相关的系统调用
strace -e trace=file ./a.out

# 查看网络相关的系统调用
strace -e trace=network ./a.out

# 查看文件相关的系统调用，并打印时间及耗时
strace -e trace=file -T -tt ./a.out

# 打印系统调用的统计信息，并打印strace的debug信息。
strace -e trace=file -C -w -d ./a.out


# 打印程序的系统调用情况
johnzb@johnzb-GK45:~/code/linux_std$ strace -c ./a.out
hello world !
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
  0.00    0.000000           0         1           read
  0.00    0.000000           0         1           write
  0.00    0.000000           0         2           close
  0.00    0.000000           0         3           fstat
  0.00    0.000000           0         7           mmap
  0.00    0.000000           0         3           mprotect
  0.00    0.000000           0         1           munmap
  0.00    0.000000           0         3           brk
  0.00    0.000000           0         6           pread64
  0.00    0.000000           0         1         1 access
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         2         1 arch_prctl
  0.00    0.000000           0         2           openat
------ ----------- ----------- --------- --------- ----------------
100.00    0.000000                    33         2 total


```

https://www.howtogeek.com/732736/how-to-use-strace-to-monitor-linux-system-calls/


# Ftrace

1. Lightweight, flexible function and tracepoint tracer, profiler
2. Useful for data gathering, debugging, and performance tuning
3. In Ubuntu 9.10 and later releases
4. No need for kernel recompile or separate flavour!
5. Documentation/trace/{ftrace.txt,ftracedesign.txt}


# Ftrace's trick
1. Use gprof hooks. Add mcount() call at entry of each kernel function.
2. Require kernel to be compiled with -pg option
3. During compilation the mcount() call-sites are recorded
4. Convert the mcount() call to a NOP at boot time


# The Debugfs

- Debugfs officially be mounted at   /sys/kernel/debug
- ftrace 							   /sys/kernel/debug/tracing


# The Tracing Directory

```shell

root@ubuntu:/sys/kernel/debug# ls tracing/
available_events            enabled_functions         max_graph_depth      set_event_notrace_pid   stack_max_size      trace_options
available_filter_functions  error_log                 options              set_event_pid           stack_trace         trace_pipe
available_tracers           events                    per_cpu              set_ftrace_filter       stack_trace_filter  trace_stat
buffer_percent              free_buffer               printk_formats       set_ftrace_notrace      synthetic_events    tracing_cpumask
buffer_size_kb              function_profile_enabled  README               set_ftrace_notrace_pid  timestamp_mode      tracing_max_latency
buffer_total_size_kb        hwlat_detector            saved_cmdlines       set_ftrace_pid          trace               tracing_on
current_tracer              instances                 saved_cmdlines_size  set_graph_function      trace_clock         tracing_thresh
dynamic_events              kprobe_events             saved_tgids          set_graph_notrace       trace_marker        uprobe_events
dyn_ftrace_total_info       kprobe_profile            set_event            snapshot                trace_marker_raw    uprobe_profile
root@ubuntu:/sys/kernel/debug#

```

# Available Tracers

- blk – for blk device
- function – trace entry of all kernel functions
- function_graph – trace on both entry and exit of all functions. And provides C style of calling graph
- mmiotrace – In-kernel memory-mapped I/O tracing
- sched_switch – context switches and wakeups between tasks
- nop – trace nothing


# The Function Tracer
- `sudo su -c "echo function > current_tracer"`  跟踪所有的内核函数
- `cat trace | head -n 15	`   查看trace结果


```shell
root@ubuntu:/sys/kernel/debug/tracing# cat trace | head -n 15
# tracer: function
#
# entries-in-buffer/entries-written: 2934/2934   #P:4
#
#                                _-----=> irqs-off
#                               / _----=> need-resched
#                              | / _---=> hardirq/softirq
#                              || / _--=> preempt-depth
#                              ||| / _-=> migrate-disable
#                              |||| /     delay
#           TASK-PID     CPU#  |||||  TIMESTAMP  FUNCTION
#              | |         |   |||||     |         |
            sshd-91001   [003] ..... 1067412.298925: tcp_poll <-sock_poll
            sshd-91001   [003] ..... 1067412.298936: tcp_stream_memory_free <-tcp_poll
            sshd-91001   [003] ..... 1067412.299042: tcp_poll <-sock_poll
root@ubuntu:/sys/kernel/debug/tracing#

```


# Ftrace Filter
`cat available_filter_functions | head -n 5` 查看可用的filter function 
`sudo su -c "echo ext4* > set_ftrace_filter"` 设置filter function （可以使用匹配符）


```shell
root@ubuntu:/sys/kernel/debug/tracing# cat available_filter_functions  | head -n 16
__traceiter_initcall_level
__traceiter_initcall_start
__traceiter_initcall_finish
trace_initcall_finish_cb
initcall_blacklisted
do_one_initcall
do_one_initcall
match_dev_by_label
match_dev_by_uuid
rootfs_init_fs_context
name_to_dev_t
wait_for_initramfs
wait_for_initramfs
calibration_delay_done
calibrate_delay
vdso_fault

root@ubuntu:/sys/kernel/debug/tracing#  cat available_filter_functions | wc -l
61917

# 利用匹配符，设置过滤器
root@ubuntu:/sys/kernel/debug/tracing# echo ext4* > set_ftrace_filter
# 匹配到多种的function
root@ubuntu:/sys/kernel/debug/tracing# cat set_ftrace_filter  | wc -l
621
root@ubuntu:/sys/kernel/debug/tracing# cat set_ftrace_filter | head -n 5
ext4_has_free_clusters
ext4_validate_block_bitmap.part.0
ext4_validate_block_bitmap
ext4_get_group_no_and_offset
ext4_get_group_number

tail: trace: file truncated
# tracer: function
#
# entries-in-buffer/entries-written: 193/193   #P:4
#
#                                _-----=> irqs-off
#                               / _----=> need-resched
#                              | / _---=> hardirq/softirq
#                              || / _--=> preempt-depth
#                              ||| / _-=> migrate-disable
#                              |||| /     delay
#           TASK-PID     CPU#  |||||  TIMESTAMP  FUNCTION
#              | |         |   |||||     |         |
  grafana-server-1770    [002] ..... 1067716.379867: ext4_file_read_iter <-new_sync_read
  grafana-server-1770    [002] ..... 1067716.379903: ext4_file_getattr <-vfs_getattr_nosec
  grafana-server-1770    [002] ..... 1067716.379912: ext4_getattr <-ext4_file_getattr
  grafana-server-1770    [002] ..... 1067716.380236: ext4_file_read_iter <-new_sync_read
  grafana-server-1770    [002] ..... 1067716.380265: ext4_file_getattr <-vfs_getattr_nosec
  grafana-server-1770    [002] ..... 1067716.380274: ext4_getattr <-ext4_file_getattr
  

```


# Ftrace Filter (cont.)
- value* 		Select all functions that begin with ”value”
- \*value\*		Select all functions that contain the text ”value”
- *value		Select all functions that end with ”value”
- set_ftrace_notrace  不对某些function进行trace


# Filter Modules
```shell
/sys/kernel/debug/tracing % sudo su -c "echo :mod:nvidia > set_ftrace_filter"

/sys/kernel/debug/tracing % cat set_ftrace_filter | head -n 10		

/sys/kernel/debug/tracing % cat set_ftrace_filter | wc -l 

/sys/kernel/debug/tracing % sudo su -c "echo function > current_tracer"

/sys/kernel/debug/tracing % cat trace | head -n 15

```


# Function Graph Tracer
`echo function_graph > current_tracer`  开启function_graph 跟踪

`sudo su -c "echo sys_read > set_graph_function"` 设置跟踪特定的function

```shell
# 打开function graph （不知道什么原因，每次执行的时候，我自己的机器上都会有bug爆出来，原因未知，稍后再排查）
root@ubuntu:/sys/kernel/debug/tracing# echo function_graph > current_tracer

#  kernel:[  241.341363] watchdog: BUG: soft lockup - CPU#2 stuck for 22s! [bash:2592]
```


```shell 

cat ~/bin/ftrace-me
#!/bin/sh
DEBUGFS=`grep debugfs /proc/mounts | awk '{ print $2; }'`
sudo su -c " \
    echo 0 > $DEBUGFS/tracing/tracing_on; \
    echo $$ > $DEBUGFS/tracing/set_ftrace_pid; \
    echo function_graph > $DEBUGFS/tracing/current_tracer; \
    echo 1 > $DEBUGFS/tracing/tracing_on"
exec $*
sudo su -c "\
    echo -1 > $DEBUGFS/tracing/set_ftrace_pid; \
    echo 0 > $DEBUGFS/tracing/tracing_on"	 


```


# Who Call Me

/sys/kernel/debug/tracing % sudo su -c "echo kfree > set_ftrace_filter"
/sys/kernel/debug/tracing % cat set_ftrace_filter
/sys/kernel/debug/tracing % sudo su -c "echo function > current_tracer"
/sys/kernel/debug/tracing % sudo su -c "echo 1 > options/func_stack_trace"
/sys/kernel/debug/tracing % cat trace | tail -5 
/sys/kernel/debug/tracing % sudo su -c "echo 0 > options/func_stack_trace"
/sys/kernel/debug/tracing % sudo su -c "echo > set_ftrace_filter"



# Reference
- Debugging the kernel using Ftrace – part 1  http://lwn.net/Articles/365835/
- Debugging the kernel using Ftrace – part 2	http://lwn.net/Articles/366796/
- Secrets of the Ftrace function tracer http://lwn.net/Articles/370423/

