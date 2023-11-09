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



```
### __sys_sendto 实际的数据发送入口

```c

/*
 *      Send a datagram to a given address. We move the address into kernel
 *      space and check the user space data area is readable before invoking
 *      the protocol.
 */
// __user  代表的是用户态的数据？
int __sys_sendto(int fd, void __user *buff, size_t len, unsigned int flags,
                 struct sockaddr __user *addr,  int addr_len)
{
        struct socket *sock;
        struct sockaddr_storage address;
        int err;
        struct msghdr msg;
        struct iovec iov;
        int fput_needed;
        // 检查数据，并将用户态的数据复制到内核态中，其操作的内容放在了msg_iter中
        err = import_single_range(ITER_SOURCE, buff, len, &iov, &msg.msg_iter);
        if (unlikely(err))
                return err;

        // 将fd转换成socket
        sock = sockfd_lookup_light(fd, &err, &fput_needed);
        if (!sock)
                goto out;

        msg.msg_name = NULL;
        msg.msg_control = NULL;
        msg.msg_controllen = 0;
        msg.msg_namelen = 0;
        msg.msg_ubuf = NULL;
        if (addr) {
                // 将地址移动到内核态
                err = move_addr_to_kernel(addr, addr_len, &address);
                if (err < 0)
                        goto out_put;
                msg.msg_name = (struct sockaddr *)&address;
                msg.msg_namelen = addr_len;
        }
        flags &= ~MSG_INTERNAL_SENDMSG_FLAGS;
        if (sock->file->f_flags & O_NONBLOCK)
                flags |= MSG_DONTWAIT;
        msg.msg_flags = flags;
        //内核态发送消息
        err = __sock_sendmsg(sock, &msg);

out_put:
        fput_light(sock->file, fput_needed);
out:
        return err;
}




static noinline void call_trace_sock_send_length(struct sock *sk, int ret,
                                                 int flags)
{
        // 未找到该函数的定义，但从名字看，应该是做trace 记录的 //TODO 后续分析
        trace_sock_send_length(sk, ret, 0);
}

static inline int sock_sendmsg_nosec(struct socket *sock, struct msghdr *msg)
{
        // INDIRECT_CALL_INET 用于处理ipv4、IPV6 相关的差异信息的内容, 如果开启了ipv6 就使用inet6_sendmsg ，否则用inet_sendmsg？
        // READ_ONCE 用于编译器相关的指令，用于告诉编译器，不要重复调用？
        int ret = INDIRECT_CALL_INET(READ_ONCE(sock->ops)->sendmsg, inet6_sendmsg,
                                     inet_sendmsg, sock, msg,
                                     msg_data_left(msg));
        BUG_ON(ret == -EIOCBQUEUED);

        if (trace_sock_send_length_enabled())
                // trace 相关的逻辑？
                call_trace_sock_send_length(sock->sk, ret, 0);
        return ret;
}

static int __sock_sendmsg(struct socket *sock, struct msghdr *msg)
{
        //校验是否允许通过soket发送msg，做安全校验相关的工作。
        int err = security_socket_sendmsg(sock, msg,
                                          msg_data_left(msg));

        return err ?: sock_sendmsg_nosec(sock, msg);
}

/**
 *      sock_sendmsg - send a message through @sock
 *      @sock: socket
 *      @msg: message to send
 *
 *      Sends @msg through @sock, passing through LSM.
 *      Returns the number of bytes sent, or an error code.
 */
int sock_sendmsg(struct socket *sock, struct msghdr *msg)
{
        struct sockaddr_storage *save_addr = (struct sockaddr_storage *)msg->msg_name;
        struct sockaddr_storage address;
        int ret;

        if (msg->msg_name) {
                memcpy(&address, msg->msg_name, msg->msg_namelen);
                msg->msg_name = &address;
        }

        ret = __sock_sendmsg(sock, msg);
        msg->msg_name = save_addr;

        return ret;
}
EXPORT_SYMBOL(sock_sendmsg);



```


### inet_sendmsg 发送ipv4数据

```c

// 判断socket是否已经准备好
int inet_send_prepare(struct sock *sk)
{
        sock_rps_record_flow(sk);

        /* We may need to bind the socket. */
        if (data_race(!inet_sk(sk)->inet_num) && !sk->sk_prot->no_autobind &&
            inet_autobind(sk))
                return -EAGAIN;

        return 0;
}
EXPORT_SYMBOL_GPL(inet_send_prepare);

// 针对ipv4，实际发送socket的逻辑
int inet_sendmsg(struct socket *sock, struct msghdr *msg, size_t size)
{
        struct sock *sk = sock->sk;
        // 判断socket 是否已经准备好发送数据
        if (unlikely(inet_send_prepare(sk)))
                return -EAGAIN;

        // 根据tcp的协议判断是通过tcp_sendmsg 还是通过udp_sendmsg 发送后续的消息
        return INDIRECT_CALL_2(sk->sk_prot->sendmsg, tcp_sendmsg, udp_sendmsg,
                               sk, msg, size);
}
EXPORT_SYMBOL(inet_sendmsg);



```


### udp_sendmsg

为了简化网络发送相关的分析，先研究一下udp协议的发送逻辑。其代码在 `"net/ipv4/udp.c"`

```c 

// 貌似在做dst的赋值操作，但是为什么这么做呢？
#define DECLARE_SOCKADDR(type, dst, src)        \
        type dst = ({ __sockaddr_check_size(sizeof(*dst)); (type) src; })

#define udp_test_bit(nr, sk)                    \
        test_bit(UDP_FLAGS_##nr, &udp_sk(sk)->udp_flags)


// arch/x86/boot/bitops.h
static inline bool constant_test_bit(int nr, const void *addr)
{
        const u32 *p = addr;
        return ((1UL << (nr & 31)) & (p[nr >> 5])) != 0;
}
static inline bool variable_test_bit(int nr, const void *addr)
{
        bool v;
        const u32 *p = addr;

        asm("btl %2,%1" CC_SET(c) : CC_OUT(c) (v) : "m" (*p), "Ir" (nr));
        return v;
}

#define test_bit(nr,addr) \
(__builtin_constant_p(nr) ? \
 constant_test_bit((nr),(addr)) : \
 variable_test_bit((nr),(addr)))

static inline void set_bit(int nr, void *addr)
{
        asm("btsl %1,%0" : "+m" (*(u32 *)addr) : "Ir" (nr));
}



// 发送udp包的核心入口
int udp_sendmsg(struct sock *sk, struct msghdr *msg, size_t len)
{
        struct inet_sock *inet = inet_sk(sk);
        struct udp_sock *up = udp_sk(sk);
	// 设置usin的值，
        DECLARE_SOCKADDR(struct sockaddr_in *, usin, msg->msg_name);
        struct flowi4 fl4_stack;
        struct flowi4 *fl4;
        int ulen = len;
        struct ipcm_cookie ipc;
        struct rtable *rt = NULL;
        int free = 0;
        int connected = 0;
        __be32 daddr, faddr, saddr;
        u8 tos, scope;
        __be16 dport;
        int err, is_udplite = IS_UDPLITE(sk);
        int corkreq = udp_test_bit(CORK, sk) || msg->msg_flags & MSG_MORE;
	// 定义函数指针
        int (*getfrag)(void *, char *, int, int, int, struct sk_buff *);
        struct sk_buff *skb;
        struct ip_options_data opt_copy;
        int uc_index;

	if (len > 0xFFFF)
                return -EMSGSIZE;

        /*
         *      Check the flags.
         */

        if (msg->msg_flags & MSG_OOB) /* Mirror BSD error message compatibility */
                return -EOPNOTSUPP;

        getfrag = is_udplite ? udplite_getfrag : ip_generic_getfrag;

        fl4 = &inet->cork.fl.u.ip4;
        if (up->pending) {
                /*
                 * There are pending frames.
                 * The socket lock must be held while it's corked.
                 */
                lock_sock(sk);
                if (likely(up->pending)) {
                        if (unlikely(up->pending != AF_INET)) {
                                release_sock(sk);
                                return -EINVAL;
                        }
                        goto do_append_data;
                }
                release_sock(sk);
        }
        ulen += sizeof(struct udphdr);

        /*
         *      Get and verify the address.
         */
        if (usin) {
                if (msg->msg_namelen < sizeof(*usin))
                        return -EINVAL;
                if (usin->sin_family != AF_INET) {
                        if (usin->sin_family != AF_UNSPEC)
                                return -EAFNOSUPPORT;
                }

                daddr = usin->sin_addr.s_addr;
                dport = usin->sin_port;
                if (dport == 0)
                        return -EINVAL;
        } else {
                if (sk->sk_state != TCP_ESTABLISHED)
                        return -EDESTADDRREQ;
                daddr = inet->inet_daddr;
                dport = inet->inet_dport;
                /* Open fast path for connected socket.
                   Route will not be used, if at least one option is set.
                 */
                connected = 1;
        }

        ipcm_init_sk(&ipc, inet);
        ipc.gso_size = READ_ONCE(up->gso_size);

        if (msg->msg_controllen) {
                err = udp_cmsg_send(sk, msg, &ipc.gso_size);
                if (err > 0)
                        err = ip_cmsg_send(sk, msg, &ipc,
                                           sk->sk_family == AF_INET6);
                if (unlikely(err < 0)) {
                        kfree(ipc.opt);
                        return err;
                }
                if (ipc.opt)
                        free = 1;
                connected = 0;
        }
        if (!ipc.opt) {
                struct ip_options_rcu *inet_opt;

                rcu_read_lock();
                inet_opt = rcu_dereference(inet->inet_opt);
                if (inet_opt) {
                        memcpy(&opt_copy, inet_opt,
                               sizeof(*inet_opt) + inet_opt->opt.optlen);
                        ipc.opt = &opt_copy.opt;
                }
                rcu_read_unlock();
        }

        if (cgroup_bpf_enabled(CGROUP_UDP4_SENDMSG) && !connected) {
                err = BPF_CGROUP_RUN_PROG_UDP4_SENDMSG_LOCK(sk,
                                            (struct sockaddr *)usin,
                                            &msg->msg_namelen,
                                            &ipc.addr);
                if (err)
                        goto out_free;
                if (usin) {
                        if (usin->sin_port == 0) {
                                /* BPF program set invalid port. Reject it. */
                                err = -EINVAL;
                                goto out_free;
                        }
                        daddr = usin->sin_addr.s_addr;
                        dport = usin->sin_port;
                }
        }

        saddr = ipc.addr;
        ipc.addr = faddr = daddr;

        if (ipc.opt && ipc.opt->opt.srr) {
                if (!daddr) {
                        err = -EINVAL;
                        goto out_free;
                }
                faddr = ipc.opt->opt.faddr;
                connected = 0;
        }
        tos = get_rttos(&ipc, inet);
        scope = ip_sendmsg_scope(inet, &ipc, msg);
        if (scope == RT_SCOPE_LINK)
                connected = 0;
        uc_index = READ_ONCE(inet->uc_index);
        if (ipv4_is_multicast(daddr)) {
                if (!ipc.oif || netif_index_is_l3_master(sock_net(sk), ipc.oif))
                        ipc.oif = READ_ONCE(inet->mc_index);
                if (!saddr)
                        saddr = READ_ONCE(inet->mc_addr);
                connected = 0;
        } else if (!ipc.oif) {
                ipc.oif = uc_index;
        } else if (ipv4_is_lbcast(daddr) && uc_index) {
                /* oif is set, packet is to local broadcast and
                 * uc_index is set. oif is most likely set
                 * by sk_bound_dev_if. If uc_index != oif check if the
                 * oif is an L3 master and uc_index is an L3 slave.
                 * If so, we want to allow the send using the uc_index.
                 */
                if (ipc.oif != uc_index &&
                    ipc.oif == l3mdev_master_ifindex_by_index(sock_net(sk),
                                                              uc_index)) {
                        ipc.oif = uc_index;
                }
        }

        if (connected)
                rt = (struct rtable *)sk_dst_check(sk, 0);

        if (!rt) {
                struct net *net = sock_net(sk);
                __u8 flow_flags = inet_sk_flowi_flags(sk);

                fl4 = &fl4_stack;

                flowi4_init_output(fl4, ipc.oif, ipc.sockc.mark, tos, scope,
                                   sk->sk_protocol, flow_flags, faddr, saddr,
                                   dport, inet->inet_sport, sk->sk_uid);

                security_sk_classify_flow(sk, flowi4_to_flowi_common(fl4));
                rt = ip_route_output_flow(net, fl4, sk);
                if (IS_ERR(rt)) {
                        err = PTR_ERR(rt);
                        rt = NULL;
                        if (err == -ENETUNREACH)
                                IP_INC_STATS(net, IPSTATS_MIB_OUTNOROUTES);
                        goto out;
                }

                err = -EACCES;
                if ((rt->rt_flags & RTCF_BROADCAST) &&
                    !sock_flag(sk, SOCK_BROADCAST))
                        goto out;
                if (connected)
                        sk_dst_set(sk, dst_clone(&rt->dst));
        }
        if (msg->msg_flags&MSG_CONFIRM)
                goto do_confirm;
back_from_confirm:

        saddr = fl4->saddr;
        if (!ipc.addr)
                daddr = ipc.addr = fl4->daddr;

        /* Lockless fast path for the non-corking case. */
        if (!corkreq) {
                struct inet_cork cork;

                skb = ip_make_skb(sk, fl4, getfrag, msg, ulen,
                                  sizeof(struct udphdr), &ipc, &rt,
                                  &cork, msg->msg_flags);
                err = PTR_ERR(skb);
                if (!IS_ERR_OR_NULL(skb))
                        err = udp_send_skb(skb, fl4, &cork);
                goto out;
        }

        lock_sock(sk);
        if (unlikely(up->pending)) {
                /* The socket is already corked while preparing it. */
                /* ... which is an evident application bug. --ANK */
                release_sock(sk);

                net_dbg_ratelimited("socket already corked\n");
                err = -EINVAL;
                goto out;
        }
        /*
         *      Now cork the socket to pend data.
         */
        fl4 = &inet->cork.fl.u.ip4;
        fl4->daddr = daddr;
        fl4->saddr = saddr;
        fl4->fl4_dport = dport;
        fl4->fl4_sport = inet->inet_sport;
        up->pending = AF_INET;

do_append_data:
        up->len += ulen;
        err = ip_append_data(sk, fl4, getfrag, msg, ulen,
                             sizeof(struct udphdr), &ipc, &rt,
                             corkreq ? msg->msg_flags|MSG_MORE : msg->msg_flags);
        if (err)
                udp_flush_pending_frames(sk);
        else if (!corkreq)
                err = udp_push_pending_frames(sk);
        else if (unlikely(skb_queue_empty(&sk->sk_write_queue)))
                up->pending = 0;
        release_sock(sk);

out:
        ip_rt_put(rt);
out_free:
        if (free)
                kfree(ipc.opt);
        if (!err)
                return len;
        /*
         * ENOBUFS = no kernel mem, SOCK_NOSPACE = no sndbuf space.  Reporting
         * ENOBUFS might not be good (it's not tunable per se), but otherwise
         * we don't have a good statistic (IpOutDiscards but it can be too many
         * things).  We could add another new stat but at least for now that
         * seems like overkill.
         */
        if (err == -ENOBUFS || test_bit(SOCK_NOSPACE, &sk->sk_socket->flags)) {
                UDP_INC_STATS(sock_net(sk),
                              UDP_MIB_SNDBUFERRORS, is_udplite);
        }
        return err;

do_confirm:
        if (msg->msg_flags & MSG_PROBE)
                dst_confirm_neigh(&rt->dst, &fl4->daddr);
        if (!(msg->msg_flags&MSG_PROBE) || len)
                goto back_from_confirm;
        err = 0;
        goto out;
}
EXPORT_SYMBOL(udp_sendmsg);

void udp_splice_eof(struct socket *sock)
{
        struct sock *sk = sock->sk;
        struct udp_sock *up = udp_sk(sk);

        if (!up->pending || udp_test_bit(CORK, sk))
                return;

        lock_sock(sk);
        if (up->pending && !udp_test_bit(CORK, sk))
                udp_push_pending_frames(sk);
        release_sock(sk);
}
EXPORT_SYMBOL_GPL(udp_splice_eof);
.....

}


```




### vim使用心得

由于远程的linux机器的性能比较弱，通过idea远程查看linux代码，最终会被oom-kill掉，没办法，为了最佳的效果，最终使用了vim作为linux源码的分析工具。相关记录如下

1. 安装ctags,cscope，用于快速检索

```shell

 sudo apt install ctags
 sudo apt install cscope


 # 生成ctags和cscope的索引数据，也可以重新申请

ctags -R *
cscope -qbR


# 删除ctags和cscope的索引数据
rm -rf tags
rm -rf cscope.*


	
```

### todo list 

虽然配置了很多关键字映射，但还不熟悉，安装上述两个命令后，可以通过`cs find g func_name` 查看函数的定义，相对来说还比较好用。 目前使用起来有一个困惑的地方就是，通过`vwy`复制完关键的符号后，如何快速的检索，以及快速的放到命令语句中？

