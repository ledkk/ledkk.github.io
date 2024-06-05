---
title: mock the malloc
date: 2024-06-05 23:10:00
tags:
---
有时候为了排查malloc内存分配相关的问题，需要对malloc的分配逻辑进行打印埋点，用于分析分配出来的内存是不是被正常释放掉，以及特定的大块内存分配的堆栈来源。基于这个问题，有了本文的一些尝试。 先看代码。

```c
//malloc_mock.c

#define _GNU_SOURCE
#include <stdlib.h>
#include <stddef.h>
#include <dlfcn.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <execinfo.h>

static void *(*real_malloc)(size_t) = NULL;

static void (*real_free)(void *) = NULL;

#define MAX_LOG_SIZE 1024*1024
#define BACKTRACE_SIZE 10

// void __attribute__((constructor)) init()
void init()
{
    real_malloc = (void *(*)(size_t))dlsym(RTLD_NEXT, "malloc");
    real_free = (void (*)(void *))dlsym(RTLD_NEXT, "free");
    printf("has init the malloc/free func , the real_malloc addr is %p , the real_free addr is %p \r\n ", real_malloc, real_free);
}

void *malloc(size_t size)
{
    if(real_malloc == NULL)
    {
        init();
    }
    pid_t pid = getpid();
    pid_t tid = gettid();
    void *addr = (*real_malloc)(size);
    if(size >  MAX_LOG_SIZE)
    {
        fprintf(stderr, "malloc(%ld) = %p , pid : %d , tid : %d \r\n", size, addr, pid, tid);
        void *array[BACKTRACE_SIZE];
        int i , s = backtrace(array, BACKTRACE_SIZE);
        char **stacks = backtrace_symbols(array,s);
        for(i = 0 ; i < s ; i++)
        {
            printf("%s\n", stacks[i]);
        }
    }
    return addr;
}

void free(void *ptr)
{
    pid_t pid = getpid();
    fprintf(stderr, "free(%p) , pid : %d \r\n", ptr, pid);

    return (*real_free)(ptr);
}

int main(int argc, char *argv[])
{
    if (real_malloc == NULL)
        init();

    void *ptr = malloc(10);
    free(ptr);
    return 0;
}


```
上述的代码中，有几个细节点，做一下记录
- `__attribute__((constructor))` 和 `__attribute__((destructor))` 在编译动态库的时候，gcc会自动编译成加载动态库会执行的函数，以及卸载动态库会执行的函数。 函数本身不会要求一定是static的。 
- `dlsym` 函数可以从动态库中获取指定函数的引用，同时使用`RTLD_NEXT`，可以从下一个加载的动态库中查找，而不会直接加载当前的动态库造成冲突
- `backtrace` 配合 `backtrace_symbols` 可以获取当前线程的堆栈信息。 具体的详细内容可以参考 man backtrace 
- `gdb ` 调试的时候，可以通过set environment LD_PRELOAD=./malloc_mock 进行调试。

```c
//malloc.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[])
{

    size_t size = 10 * 1024 * 1024; // 10 MB

    int pagesize = getpagesize();

    char *ptr = malloc(size);
    int i = 0;

    // touch the memory page
    for (i = 0; i < size; i += pagesize)
    {
        ptr[i] = 0;
    }

    printf("malloc the size %ld mem , the ptr is %p ,  just wait ! \r\n", size, ptr);
    int c = getchar();

    free(ptr);

    printf("free the ptr %p \r\n ", ptr);

    sleep(10);

    return 0;
}


```

- malloc 返回的是一个void** 指针类型，其可以正常转换为其他类型，但在做内存touch的时候，需要留意指针类型的长度

```shell

LD_PRELOAD=./malloc_mock.so java


```

参考：
- https://stackoverflow.com/questions/2053029/how-exactly-does-attribute-constructor-work
- https://stackoverflow.com/questions/10448254/how-to-use-gdb-with-ld-preload
- https://stackoverflow.com/questions/6083337/overriding-malloc-using-the-ld-preload-mechanism
- https://stackoverflow.com/questions/105659/how-can-one-grab-a-stack-trace-in-c
- https://stackoverflow.com/questions/11043313/im-getting-invalid-initializer-what-am-i-doing-wrong
