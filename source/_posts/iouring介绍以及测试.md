---
title: iouring介绍以及测试
date: 2024-05-22 09:57:28
tags:
---
https://blogs.oracle.com/linux/post/an-introduction-to-the-io-uring-asynchronous-io-framework


An io_uring instance has two rings, a submission queue (SQ) and a completion queue (CQ), shared between the kernel and the application. The queues are single producer, single consumer, and power of two in size.

The queues provide a lock-less access interface, coordinated with memory barriers.

The application creates one or more SQ entries (SQE), and then updates the SQ tail. The kernel consumes the SQEs , and updates the SQ head.

The kernel creates CQ entries (CQE) for one or more completed requests, and updates the CQ tail. The application consumes the CQEs and updates the CQ head.

Completion events may arrive in any order but they are always associated with specific SQEs.
