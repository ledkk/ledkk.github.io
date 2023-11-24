---
title: jdk certificate store
date: 2023-11-21 18:04:26
tags:
---
在通过java应用程序发起https的网络请求的时候，会涉及到网络证书的验证以及交换，默认情况下jdk内部会有大部分的根证书认证的，这部分数据会随着jdk进行分发。

`$JAVA_HOME/bin/keytool -list -keystore $JAVA_HOME/lib/security/cacerts ` 对应的密码为默认密码：`changeit` ，jdk8的该文件的目录有所差异，其文件地址为`$JAVA_HOME/jre/lib/security/cacerts`


TLS协议中提供了很多的扩展，在与服务端进行协商的时候，通过Client Hello消息同步到服务端，服务端针对传递的扩展内容，相互约定。随后协商出做加解密的密钥信息， 从实际的表现看，jdk8的早期版本和后续的版本中，对TLS的协议处理上存在差异，一方面扩展的数量存在差异，另外一方面对扩展的差异也有变化。从前后两个的抓包看，server name 扩展在jdk8的早期版本里，如果Client Hello 不携带的话， 服务端也能正常返回，同时做好协商。 但在后期的版本中，如果server name 这个扩展没有生效，或者传递的servername是存在差异的情况下， 就会存在异常。关于SNIServerName的详细信息，可以参考RFC6066（https://www.rfc-editor.org/rfc/rfc6066#page-19）， 如果在访问一个https的服务的时候，如果未执行域名，直接通过ip进行访问就会出现类似的问题。
