---
title: fsuse
date: 2024-05-10 20:30:53
tags:
---
当应用使用fsuse作为后端文件的存储层时，文件的磁盘io以及磁盘访问的RT并不会在常见的磁盘监控工具上展示出来。
关于fsuse的使用场景说明如下： 
https://github.com/libfuse/libfuse

- fuse 提供了一套文件系统标准操作的api，同时提供回调接口，允许注册用户态自己的处理程序。当用户态程序fsuse管理的文件的时候，实际就会被映射到注册的回调函数中，从而实现自定义的文件系统代理。一半情况下，可以通过fsuse访问oss、httpserver等

```shell

sudo apt install libfuse2 libfuse-dev

gcc -o fuse_user fuse_main.c -D_FILE_OFFSET_BITS=64 -lfuse

mkdir /tmp/fuse_test

./fuse_user /tmp/fuse_test/




mount
/home/johnzb/code/fsuse_s/fuse_user on /tmp/fuse_test type fuse.fuse_user (rw,nosuid,nodev,relatime,user_id=1000,group_id=1000)


johnzb@johnzb-GK45:/tmp/fuse_test$ cd /tmp/fuse_test/
johnzb@johnzb-GK45:/tmp/fuse_test$ ll
总用量 0
-rw-r--r-- 0 root root 0 1月   1  1970 Hello-world
johnzb@johnzb-GK45:/tmp/fuse_test$

```

测试代码：
```c
//cat fuse_main.c


#define FUSE_USE_VERSION 26

#include <stdio.h>
#include <fuse.h>


static int test_readdir(const char* path, void* buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info* fi)
{
    printf("tfs_readdir		path: %s \r\n ", path);
    return filler(buf, "Hello-world", NULL,0);
}


static int test_getattr(const char* path, struct stat* stbuff)
{
    printf("test_getattr    path:%s \r\n ", path);
    if(strcmp(path, "/") == 0)
	stbuff->st_mode = 0755 | S_IFDIR;
    else
	stbuff->st_mode = 0644 | S_IFREG;
    return 0;
}


static struct fuse_operations tfs_ops = {
    .readdir = test_readdir,
    .getattr = test_getattr,
};


int main(int argc,  char* argv[])
{
    int ret = 0;
    ret = fuse_main(argc,argv,&tfs_ops,NULL);
    return ret;
}



```
