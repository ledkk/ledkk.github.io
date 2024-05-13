---
title: no core segfault
date: 2024-05-08 12:11:35
tags:
---
没有产生coredump文件，但有segfault的异常的问题排查思路。
一般情况下，出现segfault后，内核会打印异常日志，内核打印的异常日志会里会打印出现异常的IP、SP等信息。基于这些信息可以大概知道出现异常的指令，如果有相应代码的源码是，可以直接通过源码查看segfault的原因，如果没有源码，则可以通过objdump反汇编，查看对应的反汇编代码。


```c


#include <stdio.h>
#include <string.h>
int main (){
   char cur_line[] = "http://www.aliyun.com";
   char * tmp;
   char *ret;

   tmp = strchr(cur_line, ']');
   if(tmp == NULL){
       printf("NULL\n");
	// 空指针错误
       ret = strrchr(tmp, '.');
   }else{
       printf("Well\n");
       ret = strrchr(tmp, '.');
   }
   printf("%s\n", ret);

   return(0);
}

```shell

# dmesg -T

[三 5月  8 12:13:30 2024] a[394735]: segfault at 0 ip 00007f9e4cf858e9 sp 00007ffe0124a518 error 4 in libc-2.31.so[7f9e4cef6000+178000]

```

上述的代码中存在一个Segment fault，访问了不允许访问的地址报错的异常。这种情况下，一版会有coredump产生，如果没有coredump产生，在内核的dmesg中也可以看到segfault错误，类似上面的描述。上面这行日志的解释如下：

- a[394735] : a 为执行的程序名， 394735 为当时执行的时候的进程号
- segfault at 0 ： 代表只是一个segment fault，表示访问了不能访问的内存地址。 不能访问的内存地址为 `0` , 代表NULL
- ip 00007f9e4cf858e9 sp 00007ffe0124a518 ： 当时的指令指针(instruction pointer) 的值为`00007f9e4cf858e9`， 说明段错误是在执行这个地址上的代码指令时发生的。 栈指针（stack pointer）其值为`00007ffe0124a518`，其代表当时段错误的栈顶指针。
- error 4 : error 后面的数字是表示引起错误的具体原因的内核错误代码，4 通常表示发生读取内存错误。
- libc-2.31.so[7f9e4cef6000+178000] : 这指出段错误是在动态链接库 libc-2.31.so 内，其载入地址是 7f9e4cef6000，错误地址 00007f9e4cf858e9 在这个库从载入地址起 178000 字节处

段错误的可能原因：
- 解引用空指针：进程试图通过空指针（NULL）读写内存。
- 数组越界访问：对数组进行越界访问。
- 无效的内存访问：试图访问未分配（或已释放）的内存。


如果没有coredump文件的话，可以通过如下方式简单分析可能报错的原因
1) 根据IP和库载入的基地址，可以推算出IP对应的指令在动态库中的地址偏移： `OFF_SET` = `IP` - `BASE_ADDR` = 00007f9e4cf858e9 - 7f9e4cef6000 = 0x8f8e9
2) 查看程序实际使用的动态库地址 `ldd app`
```shell
johnzb@johnzb-GK45:~/code$ ldd a
	linux-vdso.so.1 (0x00007ffcb6906000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fef73c94000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fef73ea3000)
johnzb@johnzb-GK45:~/code$ ll /lib/x86_64-linux-gnu/libc.so.6
lrwxrwxrwx 1 root root 12 4月  16 21:43 /lib/x86_64-linux-gnu/libc.so.6 -> libc-2.31.so*
```

2) 利用gdb或者objdump分析对应的`OFF_SET`的代码内容
```shell
johnzb@johnzb-GK45:~/code$ gdb /lib/x86_64-linux-gnu/libc-2.31.so
GNU gdb (Ubuntu 9.2-0ubuntu1~20.04.1) 9.2
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from /lib/x86_64-linux-gnu/libc-2.31.so...
Reading symbols from /usr/lib/debug/.build-id/87/b331c034a6458c64ce09c03939e947212e18ce.debug...
(gdb) list *0x8f8e9
0x8f8e9 is in _IO_new_file_xsputn (libioP.h:947).
942	libioP.h: 没有那个文件或目录.
(gdb)



```

4) 利用objdump反编译动态库，分析OFF_SET的偏移
```shell
objdump -D /lib/x86_64-linux-gnu/libc-2.31.so > /tmp/1.log
fgrep ' 8f8e' /tmp/1.log -C 10 

```

5) 利用gdbdebug分析
```shell


johnzb@johnzb-GK45:~/code$ gdb a
GNU gdb (Ubuntu 9.2-0ubuntu1~20.04.1) 9.2
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from a...
(No debugging symbols found in a)
(gdb) run
Starting program: /home/johnzb/code/a
NULL

Program received signal SIGSEGV, Segmentation fault.
__strrchr_sse2 () at ../sysdeps/x86_64/multiarch/../strrchr.S:32
32	../sysdeps/x86_64/multiarch/../strrchr.S: 没有那个文件或目录.
(gdb)


```

# ASLR (Address Space Layout Randomization) 

细心的人可能看出来了，上述的方式来查找代码在动态库中的位置，貌似实际找到的并不对，这个主要的原因是使用的linux开启了ASLR技术，ASLR技术主要是为了防止内存溢出类攻击的一种技术，其技术原理是在每次应用启动或者动态库载入的时候，他会随机安全一些关键数据区域的地址，包括栈（Stack）、堆（Heap）、共享库和执行文件映射区域。这种随机化使得攻击者难以找到编写的恶意代码或者存在漏洞的特定函数及数据结构体的准确位置，增加攻击者成功所需的成本。

- 查看是否开启了ASLR `cat /proc/sys/kernel/randomize_va_space`  如果其中的值是0，代表关闭了ASLR，否则就是开启了ASLR。
- 临时关闭ASLR， `echo 0 | sudo tee /proc/sys/kernel/randomize_va_space` 只对当前会话有用，重启或关闭当前会话后失效。
- 永久关闭ASLR， 编辑`/etc/sysctl.conf` ， 添加`kernel.randomize_va_space=0` , 随后运行`sudo sysctl -p ` 来重新加载系统配置文件。









