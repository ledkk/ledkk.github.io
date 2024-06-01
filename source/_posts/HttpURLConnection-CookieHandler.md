---
title: HttpURLConnection  CookieHandler
date: 2024-06-01 14:33:04
tags:
---
在Android的代码实现逻辑中，HttpUrlConnection底层的实现会被代理到OkHttpConnection上，但不论是对于HttpUrlConnection还是OkHttpConnection，其对Cookie的处理逻辑有一定的相似之处。都可以通过`CookieHandler.setDefault`来配置一个全局的CookieManager。 当客户端的网络库实现使用了默认的HttpURLConnection时，如果被其他业务代码主动设置了CookieHandler.setDefault， 那么可能在没有感知的情况下，被增加了CookieManager的实现逻辑。可能会影响正常的Cookie代码实现逻辑。
