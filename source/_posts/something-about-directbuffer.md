---
title: something about directbuffer
date: 2023-11-24 13:54:58
tags:
---
堆外内存区别与堆内内存，其内存的回收以及管理，均不受JVM控制。但实际上在Java程序中，堆外内存可以分为三种，一种是通过ByteBuffer.allocateDirect分配产生的DirectBuffer， 再一个是FileChannel.map产生的MappedByteBuffer, 最后一个是比较头疼的由于JNI调用外部的动态库，由动态库中的代码逻辑向操作系统申请的内存。这三块的内存的回收机制，都是不同的。对于前两种的堆外内存，JVM是key感知，并且在持有这些堆外内存的引用不在使用的时候，主动回收掉。但是对于动态库中申请的内存，JVM是完全无法感知到的，这种情况下就需要动态库内部做到内存的管理以及回收。

1. JVM可以管理的堆外内存在没有使用的时候，可以被JVM回收掉么？ 
该问题的答案是可以的，这主要是由于在JVM内部针对这部分内存定义好了对应的清理方式，当这类引用没有新的使用的时候，就会被回收掉。关于这块的回收逻辑，可以看`java.nio.DirectByteBuffer.Deallocator`中的实现，其内部会通过UNSAFE中的freeMemory方法回收内存。其操作等价与C语言中的free。 而对于DirectBuffer的回收，其在初始化的时候，就会有一个Cleaner构建出来，利用Deallocator进行回收堆外内存。而对应的回收将由ReferenceHandler进行周期新的内存回收。 所以对于这部分堆外内存的回收，更多的需要关注内存中的DirectBuffer为何被其他对象应用。


2. JVM无法管理的由动态库生成的堆外内存，如果出现溢出了，应该怎么排查？ 
这部分堆外内存，一般是由动态库生成的，其申请的内存的地址、大小，JVM均无法直到，所以也不存在对这部分内存进行管理。 对于这部分内存，有一个简单的判断方式，看看当前程序中有没有使用特殊的动态库，一般情况下除了JVM自身需要的动态库外，如果存在其他动态库，就需要排查一下其是否合理，是否存在堆外内存的溢出情况。 如果动态库基本都是JVM内部使用的，一般情况下存在由于动态库导致的堆外内存溢出的概率比较低。另外一个点就是libc库中的分配器存在对内存进行缓存的情况，有一种情况是，由于JVM正常的释放了内存，但是由于libc内部做了缓存，导致整体看起来内存占用多于实际占用。在一种方式就是利用tcmalloc、jemalloc相关的工具，分析其产生堆外内存无法释放的堆栈。进而排查其调用是否合理。

3. 常见的堆外内存溢出产生的原因有那些？ 
在JVM领域中，一般使用堆外内存，用来网络请求中的0copy，避免大量的用户态和内核态之间的内存复制情况。从这个角度上看，网络库是重灾区，Netty内部会有对DirectBuffer的使用，早期的版本中默认不会使用池化的内存分配器，也并不会优先使用堆外内存。但在需要的时候，也会利用堆外内存，这部分堆外内存是属于线程级别的，这部分堆外内存的大小以及数量和netty的线程数有关系，但这种方案下线程的争强会变得很低。后续的版本中netty默认使用池化的方式申请内存，其分配器的结构类似jemalloc。内存池中会对内存的大小进行分类，tiny、small、normal之类的线程队列。随后每个线程上也会有一个线程级别的缓存，对公共的线程池进行引用，增加缓存的利用率的同时，避免了线程级别的锁争强。基于这种情况，优化对网络库的堆外内存的使用是一个关键的点。

4. 常见的directbytebuffer带来的性能优化，比如零拷贝，究竟是如何实现的？ 
从功能上看，零拷贝主要的使用场景是两个channel或者发送socket期间会存在零拷贝的技术。比如在服务端向一个socket发送数据的时候，或者在两个文件相互进行拷贝的时候。 在没有零拷贝之前，一般的处理策略是，使用一个for循环，从源文件中读取数据到缓存中，随后将缓存中的数据写到目标文件中。这个中间就会涉及到系统调用相关的操作。一般来说，会需要从linux内核中读取文件中的数据，读取到用户态后，再将用户态的数据写入到目标的文件中， 又会有一次用户态到内核态的转化过程。对于用户态和内核态之间的数据转换以及拷贝（消耗高的原理）会带来更多的性能开销，从而导致性能的衰减情况。那么在jdk层面是如何实现零拷贝A，进而通过零拷贝降低系统开销的呢？ 
首先对于DirectByteBuffer来说，会利用堆外内存进行系统优化工作, JVM中关于directBuffer的加速访问，可以统一查看`sun.nio.ch.IOUtil`类中的实现，当读的DirectByteBuffer和写到DirectByteBuffer时，会通过JNI的方式触发数据的读写操作。具体代码逻辑如下：

```java

package sun.nio.ch;
public class IOUtil {

    private static int writeFromNativeBuffer(FileDescriptor fd, ByteBuffer bb,
                                             long position, boolean directIO,
                                             int alignment, NativeDispatcher nd)
        throws IOException
    {
        int pos = bb.position();
        int lim = bb.limit();
        assert (pos <= lim);
        int rem = (pos <= lim ? lim - pos : 0);

        if (directIO) {
            Util.checkBufferPositionAligned(bb, pos, alignment);
            Util.checkRemainingBufferSizeAligned(rem, alignment);
        }

        int written = 0;
        if (rem == 0)
            return 0;
        if (position != -1) {
            written = nd.pwrite(fd,
                                ((DirectBuffer)bb).address() + pos,
                                rem, position);
        } else {
            written = nd.write(fd, ((DirectBuffer)bb).address() + pos, rem);
        }
        if (written > 0)
            bb.position(pos + written);
        return written;
    }



    private static int readIntoNativeBuffer(FileDescriptor fd, ByteBuffer bb,
                                            long position, boolean directIO,
                                            int alignment, NativeDispatcher nd)
        throws IOException
    {
        int pos = bb.position();
        int lim = bb.limit();
        assert (pos <= lim);
        int rem = (pos <= lim ? lim - pos : 0);

        if (directIO) {
            Util.checkBufferPositionAligned(bb, pos, alignment);
            Util.checkRemainingBufferSizeAligned(rem, alignment);
        }

        if (rem == 0)
            return 0;
        int n = 0;
        if (position != -1) {
            n = nd.pread(fd, ((DirectBuffer)bb).address() + pos, rem, position);
        } else {
            n = nd.read(fd, ((DirectBuffer)bb).address() + pos, rem);
        }
        if (n > 0)
            bb.position(pos + n);
        return n;
    }


}

```
对于文件和文件之间的转换以及文件的加载操作的过程中，也可以通过零拷贝的机制，加速数据的读取以及转换工作，MappedBuffer实际是一个特殊的DirectByteBuffer, 其内部是通过mmap来加载到内存中的，其在文件和文件之间copy的时候，也可以利用零拷贝加速，详细的代码细节在
```java
package sun.nio.ch;


public class FileChannelImpl
    extends FileChannel
{

    private long transferToDirectlyInternal(long position, int icount,
                                            WritableByteChannel target,
                                            FileDescriptor targetFD)
        throws IOException
    {
        assert !nd.transferToDirectlyNeedsPositionLock() ||
               Thread.holdsLock(positionLock);

        long n = -1;
        int ti = -1;
        try {
            beginBlocking();
            ti = threads.add();
            if (!isOpen())
                return -1;
            do {
                n = transferTo0(fd, position, icount, targetFD);
            } while ((n == IOStatus.INTERRUPTED) && isOpen());
            if (n == IOStatus.UNSUPPORTED_CASE) {
                if (target instanceof SinkChannelImpl)
                    pipeSupported = false;
                if (target instanceof FileChannelImpl)
                    fileSupported = false;
                return IOStatus.UNSUPPORTED_CASE;
            }
            if (n == IOStatus.UNSUPPORTED) {
                // Don't bother trying again
                transferSupported = false;
                return IOStatus.UNSUPPORTED;
            }
            return IOStatus.normalize(n);
        } finally {
            threads.remove(ti);
            end (n > -1);
        }
    }

}

```

5. 如果存在动态库的对外内存溢出，应该怎么解决？
对于堆外内存的溢出，一般是由于系统依赖的一些动态库产生的分配内存无法得到释放，导致的系统问题。这类问题，一般需要分析整个JVM的内存分配器，进而识别内存占用比较多的系统以及代码路径。常见的工具有两种：jemalloc、tcmalloc。这两个工具均可以作为内存的分配器进行后续的分析。以jemalloc为例：

a）下载并编译jemalloc，由于需要分析起内存产生的prof信息，因此在编译的过程中，需要开启prof能力。
```shell


 git clone https://github.com/jemalloc/jemalloc.git
git checout 5.3.0
./autogen.sh --enable-prof 
make
make install
# the jemalloc lib path is /usr/local/lib/libjemalloc.so

MALLOC_CONF=prof_leak:true,lg_prof_sample:0,prof_final:true \
LD_PRELOAD=/usr/local/lib/libjemalloc.so.2 \
ls


# 分析内存分配信息

~/code$ jeprof /usr/bin/ls jeprof.1139459.0.f.heap
Using local file /usr/bin/ls.
Using local file jeprof.1139459.0.f.heap.
addr2line: DWARF error: section .debug_info is larger than its filesize! (0xc14d2 vs 0x90f38)
addr2line: DWARF error: section .debug_info is larger than its filesize! (0x93ef57 vs 0x530f28)
Welcome to jeprof!  For help, type 'help'.
(jeprof) top
Total: 0.1 MB
     0.1  99.6%  99.6%      0.1  99.6% prof_backtrace_impl
     0.0   0.4% 100.0%      0.0  29.8% _obstack_begin
     0.0   0.0% 100.0%      0.1  70.2% GLIBC_2.2.5
     0.0   0.0% 100.0%      0.0   0.0% __ctype_init
     0.0   0.0% 100.0%      0.0   0.0% __gconv_destroy_spec
     0.0   0.0% 100.0%      0.0  29.8% __libc_start_main
     0.0   0.0% 100.0%      0.0   0.2% __strdup
     0.0   0.0% 100.0%      0.1  70.2% _dl_rtld_di_serinfo
     0.0   0.0% 100.0%      0.0   0.1% _obstack_memory_used
     0.0   0.0% 100.0%      0.0   0.0% bindtextdomain
(jeprof)


```



