---
title: Linux的syscall究竟是怎么实现的
date: 2023-11-04 16:09:57
tags:
---
当执行一个系统调用的时候，在linux系统中是如何流转的？ 这一直是我的一个疑问，比如我想看看一个网络包可能会走的流程，我通过`strace ` 可以指导最终会走到send这个系统调用中去，但是在send这个系统调用中，如何最终走到了网卡上，以及如何从网卡上把接收到的数据正确的返回，一直是我比较大的疑问之一。 

以ping 192.168.0.1 为例，通过strace可以看到其实际走到的调用为sendto这个系统调用，通过`man sendto` 可以看到这个系统调用实际做的操作，但仅仅通过文档是无法解释很多细节的问题的，比如这个网络包怎么进到了网卡中去的？于是带着这个问题，我们想走一遍网络栈

```shell

# 发送数据包
sendto(3, "\10\0\0\315\0\0\0\1\7\375Ee\0\0\0\0\350\374\2\0\0\0\0\0\20\21\22\23\24\25\26\27"..., 64, 0, {sa_family=AF_INET, sin_port=htons(0), sin_addr=inet_addr("192.168.0.1")}, 16) = 64

# 随后接收数据包
recvmsg(3, {msg_name={sa_family=AF_INET, sin_port=htons(0), sin_addr=inet_addr("192.168.0.1")}, msg_namelen=128->16, msg_iov=[{iov_base="\0\0\10\306\0\7\0\1\7\375Ee\0\0\0\0\350\374\2\0\0\0\0\0\20\21\22\23\24\25\26\27"..., iov_len=192}], msg_iovlen=1, msg_control=[{cmsg_len=32, cmsg_level=SOL_SOCKET, cmsg_type=SO_TIMESTAMP_OLD, cmsg_data={tv_sec=1699085575, tv_usec=197778}}, {cmsg_len=20, cmsg_level=SOL_IP, cmsg_type=IP_TTL, cmsg_data=[63]}], msg_controllen=56, msg_flags=0}, 0) = 64


```

1. 以下代码疑似sendto的系统调用入口。
   
   ```c
//net/socket.c

//疑似sendto系统调用的入口
SYSCALL_DEFINE6(sendto, int, fd, void __user *, buff, size_t, len,
                unsigned int, flags, struct sockaddr __user *, addr,
                int, addr_len)
{
        return __sys_sendto(fd, buff, len, flags, addr, addr_len);
}

```
这段代码里遇到了一个特殊的MICRO：`SYSCALL_DEFINE6`, 那么这里面做了什么呢？ 以及一些特殊的字符串 `void __user *` 、`struct sockaddr __user * `，那么这些分别时候什么呢？

###  SYSCALL_DEFINE6

对于`SYSCALL_DEFINE6`的定义放在了`include/linux/syscall.h`中，其定义的详细内容为

```c

//include/linux/syscall.h


// 为了简化代码的分析过程，人为在编译的时候，未开启`CONFIG_FTRACE_SYSCALLS`, 对于为开启`CONFIG_FTRACE_SYSCALLS` 时，`SYSCALL_METADATA` 不做任何事情，直接返回

#define SYSCALL_METADATA(sname, nb, ...)

static inline int is_syscall_trace_event(struct trace_event_call *tp_event)
{
        return 0;
}
#endif



#define SYSCALL_DEFINE1(name, ...) SYSCALL_DEFINEx(1, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE2(name, ...) SYSCALL_DEFINEx(2, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE3(name, ...) SYSCALL_DEFINEx(3, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE4(name, ...) SYSCALL_DEFINEx(4, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE5(name, ...) SYSCALL_DEFINEx(5, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE6(name, ...) SYSCALL_DEFINEx(6, _##name, __VA_ARGS__)

#define SYSCALL_DEFINE_MAXARGS  6

// `SYSCALL_DEFINEx` 内部调用`__SYSCALL_DEFINEx` 
#define SYSCALL_DEFINEx(x, sname, ...)                          \
        SYSCALL_METADATA(sname, x, __VA_ARGS__)                 \
        __SYSCALL_DEFINEx(x, sname, __VA_ARGS__)


#define __PROTECT(...) asmlinkage_protect(__VA_ARGS__)

/*
 * The asmlinkage stub is aliased to a function named __se_sys_*() which
 * sign-extends 32-bit ints to longs whenever needed. The actual work is
 * done within __do_sys_*().
 */
#ifndef __SYSCALL_DEFINEx
#define __SYSCALL_DEFINEx(x, name, ...)                                 \
        __diag_push();                                                  \  // 和编译相关的逻辑，现阶段不重要
        __diag_ignore(GCC, 8, "-Wattribute-alias",                      \  // 和编译相关的逻辑，现阶段不重要
                      "Type aliasing is used to sanitize syscall arguments");\  // 和编译相关的逻辑，现阶段不重要
        asmlinkage long sys##name(__MAP(x,__SC_DECL,__VA_ARGS__))       \    // include/linux/linkage.h  asmlinkage 不重要，这里实际是调用了long sys_sendto对应的系统调用，上述的数字6，仅仅代表其有6个参数而已
                __attribute__((alias(__stringify(__se_sys##name))));    \    // gcc相关的，应该也不重要。 ./include/linux/compiler_attributes.h
        ALLOW_ERROR_INJECTION(sys##name, ERRNO);                        \    //./include/asm-generic/error-injection.h 异常注入相关，参考Documentation/fault-injection/fault-injection.rst， 不重要
        static inline long __do_sys##name(__MAP(x,__SC_DECL,__VA_ARGS__));\  // 实际转换为 static inline long __do_sys_sendto的函数
        asmlinkage long __se_sys##name(__MAP(x,__SC_LONG,__VA_ARGS__)); \    // long __se_sys_sendto
        asmlinkage long __se_sys##name(__MAP(x,__SC_LONG,__VA_ARGS__))  \    //long __se_sys_sendto 
        {                                                               \
                long ret = __do_sys##name(__MAP(x,__SC_CAST,__VA_ARGS__));\  // __do_sys_sendto
                __MAP(x,__SC_TEST,__VA_ARGS__);                         \
                __PROTECT(x, ret,__MAP(x,__SC_ARGS,__VA_ARGS__));       \
                return ret;                                             \
        }                                                               \
        __diag_pop();                                                   \
        static inline long __do_sys##name(__MAP(x,__SC_DECL,__VA_ARGS__))    // static inline long __do_sys_sendto 
#endif /* __SYSCALL_DEFINEx */



// include/linux/linkage.h
#ifdef __cplusplus
#define CPP_ASMLINKAGE extern "C"
#else
#define CPP_ASMLINKAGE
#endif

#ifndef asmlinkage
#define asmlinkage CPP_ASMLINKAGE
#endif


// demo https://blog.csdn.net/weixin_42992444/article/details/108571515

```