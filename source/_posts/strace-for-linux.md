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

 sudo apt install strace


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
johnzb@ubuntu:~$

```


 strace -e trace=process ./a.out



strace -e trace=file ./a.out
strace -e trace=network ./a.out

strace -e trace=file -T -tt ./a.out

strace -e trace=file -C -w -d ./a.out