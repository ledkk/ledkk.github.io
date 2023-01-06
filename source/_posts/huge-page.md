---
title: huge_page
date: 2023-01-04 20:00:29
tags:
---


```c
// huge_page.c
/// gcc huge_page.c 
// strace ./a.out
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h> // Also used for various posix functions, cross platform
#include <stdio.h>
const int alignment = 1 << 21;
const int size = 16 << 21;
int main( void ) {
    void *x = aligned_alloc( alignment, size );

#ifdef MADV_HUGEPAGE
    if ( x != NULL ) {
        madvise( x, size, MADV_HUGEPAGE  );
        for ( int i = 0; i < size; i += alignment ) {
            ((char *)x)[i] = 0;
        }
    }
#endif

    printf( "Go run: grep -i hugepage /proc/meminfo\nPausing for 60 seconds.\n" );
    sleep( 60 );

    return 0;
}


```


输出



```shell

# 程序执行的结果，以及内部的内核调用，可以看到正确调用了madvise
johnzb@ubuntu:~/code/cstd$ strace ./a.out
execve("./a.out", ["./a.out"], 0x7ffe08bb8de0 /* 24 vars */) = 0
brk(NULL)                               = 0x55ca63615000
arch_prctl(0x3001 /* ARCH_??? */, 0x7fff72f082e0) = -1 EINVAL (Invalid argument)
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
fstat(3, {st_mode=S_IFREG|0644, st_size=75093, ...}) = 0
mmap(NULL, 75093, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f6955d09000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\300A\2\0\0\0\0\0"..., 832) = 832
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0\20\0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0", 32, 848) = 32
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0\30x\346\264ur\f|Q\226\236i\253-'o"..., 68, 880) = 68
fstat(3, {st_mode=S_IFREG|0755, st_size=2029592, ...}) = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f6955d07000
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0\20\0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0", 32, 848) = 32
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0\30x\346\264ur\f|Q\226\236i\253-'o"..., 68, 880) = 68
mmap(NULL, 2037344, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f6955b15000
mmap(0x7f6955b37000, 1540096, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x22000) = 0x7f6955b37000
mmap(0x7f6955caf000, 319488, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x19a000) = 0x7f6955caf000
mmap(0x7f6955cfd000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1e7000) = 0x7f6955cfd000
mmap(0x7f6955d03000, 13920, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f6955d03000
close(3)                                = 0
arch_prctl(ARCH_SET_FS, 0x7f6955d08540) = 0
mprotect(0x7f6955cfd000, 16384, PROT_READ) = 0
mprotect(0x55ca62d5c000, 4096, PROT_READ) = 0
mprotect(0x7f6955d49000, 4096, PROT_READ) = 0
munmap(0x7f6955d09000, 75093)           = 0
mmap(NULL, 35655680, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f6953914000
madvise(0x7f6953a00000, 33554432, MADV_HUGEPAGE) = 0
fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}) = 0
brk(NULL)                               = 0x55ca63615000
brk(0x55ca63636000)                     = 0x55ca63636000
write(1, "Go run: grep -i hugepage /proc/m"..., 39Go run: grep -i hugepage /proc/meminfo
) = 39
write(1, "Pausing for 60 seconds.\n", 24Pausing for 60 seconds.
) = 24
clock_nanosleep(CLOCK_REALTIME, 0, {tv_sec=60, tv_nsec=0}, 0x7fff72f08270) = 0
exit_group(0)                           = ?
+++ exited with 0 +++



# 查看透明大页的使用情况，透明大页默认是匿名大页
root@ubuntu:/sys/kernel/debug/tracing# grep -i huge /proc/meminfo
AnonHugePages:     32768 kB
ShmemHugePages:        0 kB
FileHugePages:         0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:               0 kB



```


使用透明大页可能会产生碎片，当申请一个大页，但只使用了其中一部分空间的时候，其他的空间无法被使用，就造成了内存的浪费，同时在内存无法申请的时候，会导致继续申请4k的basepage，性能无法达到预期。[透明大页压缩器的patch](https://lwn.net/Articles/906511/)，提供了一种可能，简单来说就是每秒收集系统中大页的利用率（扫描大页中为0的地址大小，这种方式不太合理，但是一个比较简单有效的方法），随后再分配basepage的时候，优先使用使用率比较低的page。

针对使用了jemalloc的程序，可以利用[jemalloc 优化项](https://github.com/jemalloc/jemalloc/blob/dev/TUNING.md)优化性能，可以调整回收线程的数量，metadata_thp、回收延迟等措施来优化性能