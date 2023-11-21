---
title: jdk certificate store
date: 2023-11-21 18:04:26
tags:
---
在通过java应用程序发起https的网络请求的时候，会涉及到网络证书的验证以及交换，默认情况下jdk内部会有大部分的根证书认证的，这部分数据会随着jdk进行分发。

`$JAVA_HOME/bin/keytool -list -keystore $JAVA_HOME/lib/security/cacerts ` 对应的密码为默认密码：`changeit` ，jdk8的该文件的目录有所差异，其文件地址为`$JAVA_HOME/jre/lib/security/cacerts`
