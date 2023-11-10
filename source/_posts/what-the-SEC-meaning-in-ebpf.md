---
title: what the SEC meaning in ebpf
date: 2023-11-10 13:36:17
tags:
---
由于没有扎实的C相关的基础，导致在学习ebpf的时候，一直对SEC感到困惑，为了搞清楚这个东西的原理，我翻找了linux的源码和gcc相关的资料，这里做一下简单的汇总总结。
1、SEC在`./tools/lib/bpf/bpf_helpers.h` 中定义，具体如下
```c

/*
 * Helper macro to place programs, maps, license in
 * different sections in elf_bpf file. Section names
 * are interpreted by libbpf depending on the context (BPF programs, BPF maps,
 * extern variables, etc).
 * To allow use of SEC() with externs (e.g., for extern .maps declarations),
 * make sure __attribute__((unused)) doesn't trigger compilation warning.
 */
#if __GNUC__ && !__clang__

/*
 * Pragma macros are broken on GCC
 * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=55578
 * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=90400
 */
#define SEC(name) __attribute__((section(name), used))

#else

#define SEC(name) \
        _Pragma("GCC diagnostic push")                                      \
        _Pragma("GCC diagnostic ignored \"-Wignored-attributes\"")          \
        __attribute__((section(name), used))                                \
        _Pragma("GCC diagnostic pop")                                       \

#endif

```
从描述看，这个宏的主要作用是将一些函数、maps、license放到指定的section中，在编译成elf_bpf文件。

2. __attribute__ 属于gcc中的补充定义，用于对一些函数添加一些定义属性，相关的参考资料有
a）https://gcc.gnu.org/onlinedocs/gcc/Attribute-Syntax.html  __attribute__的使用语法
b) https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html  __attribute__ 可以使用的常见的属性名字以及其含义。 对于SEC定义中使用的两个属性的解释如下

`section` 该属性用于标识将定义的内容移到指定的section中。 `used` 用于告诉gcc无论这个函数有没有被人引用，都不要在编译的时候优化掉，需要在编译的文件中，保留这部分内容。

3. 测试

```c

// cat b.c && gcc b.c -o b
#include <stdlib.h>
#include <stdio.h>

#define SEC_FOO __attribute__((section("foo"), used))

int main(int argc, char** argv)
{
	printf("this is a test %s \r\n","hello");
	bar();
	return 0;
}


void SEC_FOO bar() {
	printf("this is a foo invoke %s \r\n", "hello world");
}


```
使用`objdump -D -j foo b` 查看某个段的定义
```shell

# objdump -D -j foo b

b:     file format elf64-x86-64


Disassembly of section foo:

0000000000001205 <bar>:
    1205:	f3 0f 1e fa          	endbr64
    1209:	55                   	push   %rbp
    120a:	48 89 e5             	mov    %rsp,%rbp
    120d:	48 8d 35 0b 0e 00 00 	lea    0xe0b(%rip),%rsi        # 201f <_IO_stdin_used+0x1f>
    1214:	48 8d 3d 10 0e 00 00 	lea    0xe10(%rip),%rdi        # 202b <_IO_stdin_used+0x2b>
    121b:	b8 00 00 00 00       	mov    $0x0,%eax
    1220:	e8 2b fe ff ff       	callq  1050 <printf@plt>
    1225:	90                   	nop
    1226:	5d                   	pop    %rbp
    1227:	c3                   	retq



```

### 个人猜测

通过上面的了解，可以大胆的猜测一下，ebpf解释器在解析ebpf文件的过程中，实际是通过section来对某个环节应该使用什么函数做了约定，当某个section定义了函数的时候，就自动会执行对应的钩子，触发对应的程序执行，从而实现相关复杂的能力

ebpf 比较好的参考手册： git@github.com:eunomia-bpf/bpf-developer-tutorial.git
