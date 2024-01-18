---
title: thread yield cost high load
date: 2024-01-18 14:20:57
tags:
---
Thread.yield 会让当前线程从运行状态进入到待运行状态，从而让出当前在在用的cpu资源，但是当大量的线程同时去做yield的时候，从内核看来，是同时有大量的待运行状态的线程在等待调度，从原理上看，表现为突然的load飙升。 同时由于调度的线程数突然增加，也导致应用的sys增加。 
示例代码程序
```java

public class YieldTest {

    public static void main(String[] args) throws InterruptedException {
        for(int i = 0 ; i < 100000 ; i++){
            YieldThread yieldThread = new YieldThread();
            yieldThread.start();
        }

        Thread.sleep(1000000);
    }


}


class YieldThread extends Thread {

    @Override
    public void run() {
        while(true){
            try{
                Thread.sleep(1);
            }catch (Exception e){}
            Thread.yield();
        }
    }
}


```
