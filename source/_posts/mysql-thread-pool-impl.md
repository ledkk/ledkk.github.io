---
title: mysql_thread_pool_impl
date: 2024-04-29 14:05:16
tags:
---
mysql的企业版本和Percona server 实现版本里都对mysql实现了线程池模式，默认情况下，mysql会为每一个链接创建一个线程，在高并发场景下，mysql会因为并发度过高，导致数据库的负载偏高。有了线程池后，一组线程池服务一组用户请求链接，降低了线程数的数量，减少了系统的并发

比较详细的介绍: https://segmentfault.com/a/1190000044344747
