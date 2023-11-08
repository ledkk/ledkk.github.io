---
title: how netstat know the socketlist and who use it
date: 2023-11-08 17:39:31
tags:
---
在Linux系统下，可以通过`netstat -anop` 快速查看当前用户可以看到的所有的socket列表，以及这些socket的状态、使用线程id等信息，那么`netstat -anop` 实际是如何实现该功能的？ 一般来说linux下的proc文件内会有标识系统运行状态的内存文件，与netstat相关的文件有如下几个

1. /proc/net/tcp , /proc/net/udp 网络相关的文件，这些文件存放了linux系统中tcp/udp的socket 表信息，详细的信息描述可以通过`man proc `查看proc中内存文件的格式信息。其中uid代表创建的用户id，inode字段代表该socket对应的文件句柄信息。从这个文件中可以得到系统当前打开的socket列表
```shell

# cat /proc/net/tcp
  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
   0: 3500007F:0035 00000000:0000 0A 00000000:00000000 00:00000000 00000000   101        0 16340 1 ffff912ca9da9a40 100 0 0 10 0
   1: 00000000:0016 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 21253 1 ffff912ca9dacec0 100 0 0 10 0
   2: 0100007F:0277 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 2084053 1 ffff912ca9da88c0 100 0 0 10 0
   3: E30AA8C0:C564 7DA76464:01BB 06 00000000:00000000 03:000007D4 00000000     0        0 0 3 ffff912caca4e7c0
   4: E30AA8C0:8BC6 9F9AD374:01BB 06 00000000:00000000 03:0000060B 00000000     0        0 0 3 ffff912caca4ee88
   5: E30AA8C0:B3A0 6A2D6464:0050 06 00000000:00000000 03:000001F5 00000000     0        0 0 3 ffff912caca4eba0
   6: E30AA8C0:AA0E 7DA76464:01BB 06 00000000:00000000 03:00000603 00000000     0        0 0 3 ffff912caca4e2e8
   7: E30AA8C0:EBB4 191E6464:0050 01 00000000:00000000 00:00000000 00000000     0        0 2129881 1 ffff912cacca4600 20 4 24 16 30
   8: E30AA8C0:BDA6 31724B92:01BB 01 00000000:00000000 00:00000000 00000000   126        0 412949 1 ffff912c19dfabc0 73 4 30 2 2
   9: E30AA8C0:824E 9F9AD374:01BB 06 00000000:00000000 03:000007DC 00000000     0        0 0 3 ffff912caca4e000
  10: E30AA8C0:0016 CA4A782A:C98C 01 00000024:00000000 01:00000014 00000000     0        0 2124753 4 ffff912ca9dae040 20 4 31 99 23

```

2. /proc/pid/fd 目录下有很多链接，这些链接代表的是当前线程打开的文件列表，文件列表包含网络、文件等信息，其中可以看到网卡相关的信息,网卡的信息内可以包含网卡对应的inode信息

```shell

/proc/1/fd# ll -rth
total 0
dr-xr-xr-x 9 root root  0 Oct 17 00:23 ../
lrwx------ 1 root root 64 Nov  8 14:55 99 -> 'socket:[228038]'
lrwx------ 1 root root 64 Nov  8 14:55 98 -> 'socket:[228037]'
lrwx------ 1 root root 64 Nov  8 14:55 97 -> 'socket:[227870]'
lrwx------ 1 root root 64 Nov  8 14:55 96 -> 'socket:[227869]'
lrwx------ 1 root root 64 Nov  8 14:55 95 -> 'socket:[225861]'
lrwx------ 1 root root 64 Nov  8 14:55 94 -> 'socket:[185385]'
lrwx------ 1 root root 64 Nov  8 14:55 93 -> 'socket:[177208]'
lrwx------ 1 root root 64 Nov  8 14:55 92 -> 'socket:[176781]'
lrwx------ 1 root root 64 Nov  8 14:55 91 -> 'socket:[167248]'
lrwx------ 1 root root 64 Nov  8 14:55 90 -> 'socket:[22247]'

```

3. 根据上述的两个数据进行关联，就可以得到系统当前打开的所有的socket信息，以及打开这些socket的进程以及用户信息。 


4. 从linux代码中也可以看到，在通过`socket`系统调用内部会创建socket，并做socket和fd之间的映射。 

```c
SYSCALL_DEFINE3(socket, int, family, int, type, int, protocol)
{
        return __sys_socket(family, type, protocol);
}

int __sys_socket(int family, int type, int protocol)
{
        struct socket *sock;
        int flags;
	
	// 创建socket信息
        sock = __sys_socket_create(family, type,
                                   update_socket_protocol(family, type, protocol));
        if (IS_ERR(sock))
                return PTR_ERR(sock);

        flags = type & ~SOCK_TYPE_MASK;
        if (SOCK_NONBLOCK != O_NONBLOCK && (flags & SOCK_NONBLOCK))
                flags = (flags & ~SOCK_NONBLOCK) | O_NONBLOCK;

        return sock_map_fd(sock, flags & (O_CLOEXEC | O_NONBLOCK));
}

static int sock_map_fd(struct socket *sock, int flags)
{
        struct file *newfile;
        int fd = get_unused_fd_flags(flags);
        if (unlikely(fd < 0)) {
                sock_release(sock);
                return fd;
        }

	// 创建socket对应的文件信息
        newfile = sock_alloc_file(sock, flags, NULL);
        if (!IS_ERR(newfile)) {
                fd_install(fd, newfile);
                return fd;
        }

        put_unused_fd(fd);
        return PTR_ERR(newfile);
}


/*
 *      Obtains the first available file descriptor and sets it up for use.
 *
 *      These functions create file structures and maps them to fd space
 *      of the current process. On success it returns file descriptor
 *      and file struct implicitly stored in sock->file.
 *      Note that another thread may close file descriptor before we return
 *      from this function. We use the fact that now we do not refer
 *      to socket after mapping. If one day we will need it, this
 *      function will increment ref. count on file by 1.
 *
 *      In any case returned fd MAY BE not valid!
 *      This race condition is unavoidable
 *      with shared fd spaces, we cannot solve it inside kernel,
 *      but we take care of internal coherence yet.
 */

/**
 *      sock_alloc_file - Bind a &socket to a &file
 *      @sock: socket
 *      @flags: file status flags
 *      @dname: protocol name
 *
 *      Returns the &file bound with @sock, implicitly storing it
 *      in sock->file. If dname is %NULL, sets to "".
 *
 *      On failure @sock is released, and an ERR pointer is returned.
 *
 *      This function uses GFP_KERNEL internally.
 */

struct file *sock_alloc_file(struct socket *sock, int flags, const char *dname)
{
        struct file *file;

        if (!dname)
                dname = sock->sk ? sock->sk->sk_prot_creator->name : "";

        file = alloc_file_pseudo(SOCK_INODE(sock), sock_mnt, dname,
                                O_RDWR | (flags & O_NONBLOCK),
                                &socket_file_ops);
        if (IS_ERR(file)) {
                sock_release(sock);
                return file;
        }

        file->f_mode |= FMODE_NOWAIT;
        sock->file = file;
        file->private_data = sock;
        stream_open(SOCK_INODE(sock), file);
        return file;
}
EXPORT_SYMBOL(sock_alloc_file);


```

