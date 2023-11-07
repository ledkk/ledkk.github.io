---
title: GNU m4
date: 2023-11-07 12:49:49
tags:
---

在看一些C语言相关的系统的时候，经常会遇到M4后缀的文件，为了了解清楚文件的作用，于是有了这个文件记录。 

首先M4 是一个宏处理器，其输入是一个文本流，输出同样也是文本流。对于输入中的宏内容进行展开。这种在脚本语言中使用比较多。
`define` 用于定义一个macro，其有两个参数，一个标识宏的名字，另外一个标识宏的内容。当随后的文本中出现了宏名字的文本时，就会被替换成定义的宏内容。如果宏内容中还包含其他宏名字，对应的宏也会被展开，最终在文本输出流中表现出来。 `dnl` 也是m4中的一个关键字，其代表的意思是删除当前行以及换行符，一般在宏定义的结尾跟上`dnl`关键字，并在dnl关键字后补充宏定义的备注，在实际宏展开的时候，也不会影响宏的展示。一般情况下,dnl 用作备注使用。`changequote` 也是m4中预定义的函数，可以修改m4中quote的字符，比如可以从原本的``修改成{}中括号。quote在m4中代表把里面的内容当做文本处理，默认使用的是单引号，但一个文本中单引号过多表现的比较复杂时，可以考虑使用`changequote` 修改quote字符，比如可以使用`changequote({,})` 指令之后，中括号括起来的内容会当做文本直接处理,使用`man m4` 可以查看m4工具的基本使用方式，使用`info m4` 可以查看m4的完整手册

## common m4 test 

```m4
dnl cat 1.m4 
dnl m4 1.m4
dnl the output should be `this is a test 100 should be 100 and 100 also be 100, the 1000 is 1000, this all ~~~~`
define(A,100)dnl
define(B,A)dnl
define(C,1000)dnl
this is a test A should be 100 and B also be 100, the C is 1000, this all ~~~~

```


## demo changequote

```m4
dnl cat 2.m4
dnl m4 2.m4
dnl the output should be `this is a test 100 should be 100 and 100 should be 100, but A should be A ....`
changequote([[,]])dnl
define([[A]],100)dnl
define([[B]],[[A]])dnl
this is a test A should be 100 and B should be 100, but [[A]] should be [[A]] ....


```

