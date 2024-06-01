---
title: crac尝试
date: 2024-05-25 22:57:50
tags:
---
CRAC通过快照的方式，可以快速的启动应用程序，在springboot3.2之后的版本中也提供了相关的支持，基于这个背景，对CRAC做一定的尝试，看看是否能在启动速度这块有更好的体验。主要参考`spring-boot-crac-demo`中的示例。

### JDK 版本
CRAC需要特定的jdk版本支持才可以，最初使用的是openjdk17的版本做测试，过程中还出现了比较多的的问题。这里建议使用：https://cdn.azul.com/zulu/bin/zulu17.44.55-ca-crac-jdk17.0.8.1-linux_x64.tar.gz

-- crac 底层依赖了criu，很多原理性的内容，可以参考 https://criu.org/Main_Page

### 代码执行示例
理论上使用springboot-3.2.2版本就可以支持crac了，但需要在classpath下添加crac的依赖

```xml

                <dependency>
                        <groupId>org.crac</groupId>
                        <artifactId>crac</artifactId>
                </dependency>

```

### 启动的国产中自动做checkpoint

```shell

$JAVA_HOME/bin/java -Dspring.context.checkpoint=onRefresh -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true"  -XX:CRaCCheckpointTo=/tmp/cr -jar ./target/spring-boot-crac-demo-1.0.0-SNAPSHOT.jar

```

如果在使用过程中存在异常，可以添加额外的参数，让异常信息更丰富 `-Djdk.crac.collect-fd-stacktraces=true`

### 从快照中恢复 

```shell

$JAVA_HOME/bin/java -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true" -XX:CRaCRestoreFrom=/tmp/cr

```

### 恢复过程中的异常

如果恢复过程中，程序使用的pid已经被占了，会导致恢复不出来，此时可以通过unshare -p -m --fork --mount-proc 来启动恢复的程序。详细参考： https://criu.org/When_C/R_fails

```

sudo unshare -p -m --fork --mount-proc $JAVA_HOME/bin/java -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true" -XX:CRaCRestoreFrom=/tmp/cr

```


### checkpoint和恢复的示例
```shell

johnzb@DESKTOP-2RFOQOL:~/code/spring-boot-crac-demo$ $JAVA_HOME/bin/java -Dspring.context.checkpoint=onRefresh -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true"  -XX:CRaCCheckpointTo=/tmp/cr -jar ./target/spring-boot-crac-demo-1.0.0-SNAPSHOT.jar
----- the begin ------

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.2.2)

2024-05-25T23:22:09.070+08:00  INFO 862 --- [           main] com.example.Application                  : Starting Application v1.0.0-SNAPSHOT using Java 17.0.8.1 with PID 862 (/home/johnzb/code/spring-boot-crac-demo/target/spring-boot-crac-demo-1.0.0-SNAPSHOT.jar started by johnzb in /home/johnzb/code/spring-boot-crac-demo)
2024-05-25T23:22:09.074+08:00  INFO 862 --- [           main] com.example.Application                  : No active profile set, falling back to 1 default profile: "default"
2024-05-25T23:22:10.153+08:00  INFO 862 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2024-05-25T23:22:10.165+08:00  INFO 862 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2024-05-25T23:22:10.165+08:00  INFO 862 --- [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.18]
2024-05-25T23:22:10.197+08:00  INFO 862 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2024-05-25T23:22:10.199+08:00  INFO 862 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1038 ms
2024-05-25T23:22:10.652+08:00  INFO 862 --- [           main] o.s.b.a.e.web.EndpointLinksResolver      : Exposing 1 endpoint(s) beneath base path '/actuator'
2024-05-25T23:22:10.682+08:00  INFO 862 --- [           main] o.s.c.support.DefaultLifecycleProcessor  : Triggering JVM checkpoint/restore
2024-05-25T23:22:10.685+08:00  INFO 862 --- [           main] jdk.crac                                 : /home/johnzb/code/spring-boot-crac-demo/target/spring-boot-crac-demo-1.0.0-SNAPSHOT.jar is recorded as always available on restore
CR: Checkpoint ...
Killed
johnzb@DESKTOP-2RFOQOL:~/code/spring-boot-crac-demo$ $JAVA_HOME/bin/java -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true" -XX:CRaCRestoreFrom=/tmp/cr
Error (criu/cr-restore.c:1518): Can't fork for 862: Operation not permitted
Error (criu/cr-restore.c:2605): Restoring FAILED.
johnzb@DESKTOP-2RFOQOL:~/code/spring-boot-crac-demo$ sudo $JAVA_HOME/bin/java -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true" -XX:CRaCRestoreFrom=/tmp/cr
[sudo] password for johnzb:
shm_open: Permission denied
2024-05-25T23:22:24.331+08:00  INFO 862 --- [           main] o.s.c.support.DefaultLifecycleProcessor  : Restarting Spring-managed lifecycle beans after JVM restore
2024-05-25T23:22:24.390+08:00  INFO 862 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''
2024-05-25T23:22:24.409+08:00  INFO 862 --- [           main] com.example.Application                  : Restored Application in 0.096 seconds (process running for 0.096)
^Cjohnzb@DESKTOP-2RFOQOL:~/code/spring-boot-crac-demo$ ^C

```


### 快照的内容

```bash

johnzb@DESKTOP-2RFOQOL:~/code/spring-boot-crac-demo$ ll /tmp/cr/
total 263464
drwx------  2 johnzb johnzb     12288 May 25 22:49 ./
drwxrwxrwt 20 root   root        4096 May 25 23:02 ../
-rw-r--r--  1 johnzb johnzb      2156 May 25 22:42 core-151378.img
-rw-r--r--  1 johnzb johnzb         7 May 25 22:49 cppath
-rw-------  1 johnzb johnzb    508299 May 25 22:49 dump4.log
-rw-r--r--  1 johnzb johnzb       116 May 25 22:49 fdinfo-2.img
-rw-r--r--  1 johnzb johnzb      4284 May 25 22:49 files.img
-rw-r--r--  1 johnzb johnzb        18 May 25 22:49 fs-155623.img
-rw-r--r--  1 johnzb johnzb        36 May 25 22:49 ids-155623.img
-rw-r--r--  1 johnzb johnzb        46 May 25 22:49 inventory.img
-rw-r--r--  1 johnzb johnzb     12383 May 25 22:42 mm-151378.img
-rw-r--r--  1 johnzb johnzb     12319 May 25 22:49 mm-155623.img
-rw-r--r--  1 johnzb johnzb      9626 May 25 22:42 pagemap-151378.img
-rw-r--r--  1 johnzb johnzb      9792 May 25 22:43 pagemap-151815.img
-rw-r--r--  1 johnzb johnzb       229 May 25 22:49 pstree.img
-rw-r--r--  1 johnzb johnzb        12 May 25 22:49 seccomp.img
-rw-r--r--  1 johnzb johnzb        54 May 25 22:49 stats-dump
-rw-r--r--  1 johnzb johnzb        36 May 25 22:49 timens-0.img
-rw-r--r--  1 johnzb johnzb       207 May 25 22:49 tty-info.img

```

### Crac 面临的问题
由于crac是通过对运行中的程序做checkpoint，随后在新的机器上做restore，快速启动程序，这里就面对几个需要解决的问题

1. checkpoint做的时机选择，如果checkpoint选择的比较早，那么restore后需要做的事情还会很多，checkpoint、restore没有意义。如果选择的点比较晚的话，程序中会有很多状态信息，会导致restore的时候，需要处理非常多的异常情况。
2. 由于crac是对进程信息做快照，实际一个程序中会有非常多的静态final变量，以及和机器设备有关系的全局变量，比如ip信息、时间信息等内容。 这块多且复杂，目前没有一个比较简单快速的方式处理。这是一个必须要面对的问题。

### 参考资料：
1. https://docs.spring.io/spring-framework/reference/integration/checkpoint-restore.html
2. https://github.com/sdeleuze/spring-boot-crac-demo
3. https://openjdk.org/projects/leyden/notes/02-shift-and-constrain
