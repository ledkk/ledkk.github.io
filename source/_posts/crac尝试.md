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

如果恢复过程中，程序使用的pid已经被占了，会导致恢复不出来，此时可以通过unshare -p -m --fork --mount-proc 来启动恢复的程序

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
-rw-r--r--  1 johnzb johnzb       815 May 25 22:42 core-151379.img
-rw-r--r--  1 johnzb johnzb       772 May 25 22:42 core-151380.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:42 core-151381.img
-rw-r--r--  1 johnzb johnzb       788 May 25 22:42 core-151382.img
-rw-r--r--  1 johnzb johnzb       795 May 25 22:42 core-151383.img
-rw-r--r--  1 johnzb johnzb       790 May 25 22:42 core-151384.img
-rw-r--r--  1 johnzb johnzb       913 May 25 22:42 core-151385.img
-rw-r--r--  1 johnzb johnzb       816 May 25 22:42 core-151386.img
-rw-r--r--  1 johnzb johnzb       880 May 25 22:42 core-151387.img
-rw-r--r--  1 johnzb johnzb       860 May 25 22:42 core-151388.img
-rw-r--r--  1 johnzb johnzb       873 May 25 22:42 core-151389.img
-rw-r--r--  1 johnzb johnzb       889 May 25 22:42 core-151390.img
-rw-r--r--  1 johnzb johnzb       886 May 25 22:42 core-151391.img
-rw-r--r--  1 johnzb johnzb       812 May 25 22:42 core-151392.img
-rw-r--r--  1 johnzb johnzb       876 May 25 22:42 core-151393.img
-rw-r--r--  1 johnzb johnzb       910 May 25 22:42 core-151394.img
-rw-r--r--  1 johnzb johnzb       885 May 25 22:42 core-151395.img
-rw-r--r--  1 johnzb johnzb       815 May 25 22:42 core-151396.img
-rw-r--r--  1 johnzb johnzb       874 May 25 22:42 core-151398.img
-rw-r--r--  1 johnzb johnzb       812 May 25 22:42 core-151399.img
-rw-r--r--  1 johnzb johnzb       870 May 25 22:42 core-151400.img
-rw-r--r--  1 johnzb johnzb       884 May 25 22:42 core-151401.img
-rw-r--r--  1 johnzb johnzb       880 May 25 22:42 core-151402.img
-rw-r--r--  1 johnzb johnzb       886 May 25 22:42 core-151403.img
-rw-r--r--  1 johnzb johnzb       883 May 25 22:42 core-151411.img
-rw-r--r--  1 johnzb johnzb       901 May 25 22:42 core-151412.img
-rw-r--r--  1 johnzb johnzb       832 May 25 22:42 core-151413.img
-rw-r--r--  1 johnzb johnzb       891 May 25 22:42 core-151414.img
-rw-r--r--  1 johnzb johnzb       844 May 25 22:42 core-151415.img
-rw-r--r--  1 johnzb johnzb       834 May 25 22:42 core-151416.img
-rw-r--r--  1 johnzb johnzb       876 May 25 22:42 core-151417.img
-rw-r--r--  1 johnzb johnzb       875 May 25 22:42 core-151418.img
-rw-r--r--  1 johnzb johnzb       866 May 25 22:42 core-151419.img
-rw-r--r--  1 johnzb johnzb       874 May 25 22:42 core-151420.img
-rw-r--r--  1 johnzb johnzb       928 May 25 22:42 core-151421.img
-rw-r--r--  1 johnzb johnzb       797 May 25 22:42 core-151422.img
-rw-r--r--  1 johnzb johnzb       880 May 25 22:42 core-151433.img
-rw-r--r--  1 johnzb johnzb       856 May 25 22:42 core-151436.img
-rw-r--r--  1 johnzb johnzb       796 May 25 22:42 core-151437.img
-rw-r--r--  1 johnzb johnzb       796 May 25 22:42 core-151438.img
-rw-r--r--  1 johnzb johnzb       788 May 25 22:42 core-151439.img
-rw-r--r--  1 johnzb johnzb       796 May 25 22:42 core-151440.img
-rw-r--r--  1 johnzb johnzb       860 May 25 22:42 core-151443.img
-rw-r--r--  1 johnzb johnzb       852 May 25 22:42 core-151444.img
-rw-r--r--  1 johnzb johnzb       836 May 25 22:42 core-151445.img
-rw-r--r--  1 johnzb johnzb       877 May 25 22:42 core-151446.img
-rw-r--r--  1 johnzb johnzb       874 May 25 22:42 core-151447.img
-rw-r--r--  1 johnzb johnzb       888 May 25 22:42 core-151448.img
-rw-r--r--  1 johnzb johnzb       852 May 25 22:42 core-151449.img
-rw-r--r--  1 johnzb johnzb       822 May 25 22:42 core-151451.img
-rw-r--r--  1 johnzb johnzb       888 May 25 22:42 core-151452.img
-rw-r--r--  1 johnzb johnzb      2158 May 25 22:43 core-151815.img
-rw-r--r--  1 johnzb johnzb       819 May 25 22:43 core-151816.img
-rw-r--r--  1 johnzb johnzb       759 May 25 22:43 core-151817.img
-rw-r--r--  1 johnzb johnzb       781 May 25 22:43 core-151818.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:43 core-151819.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:43 core-151820.img
-rw-r--r--  1 johnzb johnzb       793 May 25 22:43 core-151821.img
-rw-r--r--  1 johnzb johnzb       913 May 25 22:43 core-151822.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:43 core-151823.img
-rw-r--r--  1 johnzb johnzb       885 May 25 22:43 core-151824.img
-rw-r--r--  1 johnzb johnzb       865 May 25 22:43 core-151825.img
-rw-r--r--  1 johnzb johnzb       876 May 25 22:43 core-151826.img
-rw-r--r--  1 johnzb johnzb       892 May 25 22:43 core-151827.img
-rw-r--r--  1 johnzb johnzb       891 May 25 22:43 core-151828.img
-rw-r--r--  1 johnzb johnzb       794 May 25 22:43 core-151829.img
-rw-r--r--  1 johnzb johnzb       878 May 25 22:43 core-151830.img
-rw-r--r--  1 johnzb johnzb       831 May 25 22:43 core-151831.img
-rw-r--r--  1 johnzb johnzb       891 May 25 22:43 core-151832.img
-rw-r--r--  1 johnzb johnzb       815 May 25 22:43 core-151833.img
-rw-r--r--  1 johnzb johnzb       870 May 25 22:43 core-151834.img
-rw-r--r--  1 johnzb johnzb       812 May 25 22:43 core-151835.img
-rw-r--r--  1 johnzb johnzb       810 May 25 22:43 core-151836.img
-rw-r--r--  1 johnzb johnzb       816 May 25 22:43 core-151837.img
-rw-r--r--  1 johnzb johnzb       822 May 25 22:43 core-151838.img
-rw-r--r--  1 johnzb johnzb       797 May 25 22:43 core-151840.img
-rw-r--r--  1 johnzb johnzb       849 May 25 22:43 core-151841.img
-rw-r--r--  1 johnzb johnzb       865 May 25 22:43 core-151842.img
-rw-r--r--  1 johnzb johnzb       861 May 25 22:43 core-151843.img
-rw-r--r--  1 johnzb johnzb       838 May 25 22:43 core-151844.img
-rw-r--r--  1 johnzb johnzb       844 May 25 22:43 core-151845.img
-rw-r--r--  1 johnzb johnzb       835 May 25 22:43 core-151846.img
-rw-r--r--  1 johnzb johnzb       861 May 25 22:43 core-151847.img
-rw-r--r--  1 johnzb johnzb       832 May 25 22:43 core-151848.img
-rw-r--r--  1 johnzb johnzb       887 May 25 22:43 core-151849.img
-rw-r--r--  1 johnzb johnzb       865 May 25 22:43 core-151850.img
-rw-r--r--  1 johnzb johnzb       879 May 25 22:43 core-151851.img
-rw-r--r--  1 johnzb johnzb       895 May 25 22:43 core-151853.img
-rw-r--r--  1 johnzb johnzb       810 May 25 22:43 core-151854.img
-rw-r--r--  1 johnzb johnzb       841 May 25 22:43 core-151873.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:43 core-151874.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:43 core-151875.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:43 core-151876.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:43 core-151877.img
-rw-r--r--  1 johnzb johnzb       860 May 25 22:43 core-151879.img
-rw-r--r--  1 johnzb johnzb       853 May 25 22:43 core-151880.img
-rw-r--r--  1 johnzb johnzb       837 May 25 22:43 core-151881.img
-rw-r--r--  1 johnzb johnzb       852 May 25 22:43 core-151883.img
-rw-r--r--  1 johnzb johnzb       850 May 25 22:43 core-151884.img
-rw-r--r--  1 johnzb johnzb       852 May 25 22:43 core-151885.img
-rw-r--r--  1 johnzb johnzb       860 May 25 22:43 core-151886.img
-rw-r--r--  1 johnzb johnzb       826 May 25 22:43 core-151888.img
-rw-r--r--  1 johnzb johnzb       851 May 25 22:43 core-151889.img
-rw-r--r--  1 johnzb johnzb      2159 May 25 22:49 core-155623.img
-rw-r--r--  1 johnzb johnzb       819 May 25 22:49 core-155624.img
-rw-r--r--  1 johnzb johnzb       754 May 25 22:49 core-155625.img
-rw-r--r--  1 johnzb johnzb       803 May 25 22:49 core-155626.img
-rw-r--r--  1 johnzb johnzb       789 May 25 22:49 core-155627.img
-rw-r--r--  1 johnzb johnzb       802 May 25 22:49 core-155628.img
-rw-r--r--  1 johnzb johnzb       793 May 25 22:49 core-155629.img
-rw-r--r--  1 johnzb johnzb       913 May 25 22:49 core-155630.img
-rw-r--r--  1 johnzb johnzb       804 May 25 22:49 core-155631.img
-rw-r--r--  1 johnzb johnzb       885 May 25 22:49 core-155632.img
-rw-r--r--  1 johnzb johnzb       857 May 25 22:49 core-155633.img
-rw-r--r--  1 johnzb johnzb       871 May 25 22:49 core-155634.img
-rw-r--r--  1 johnzb johnzb       884 May 25 22:49 core-155635.img
-rw-r--r--  1 johnzb johnzb       896 May 25 22:49 core-155636.img
-rw-r--r--  1 johnzb johnzb       790 May 25 22:49 core-155637.img
-rw-r--r--  1 johnzb johnzb       871 May 25 22:49 core-155638.img
-rw-r--r--  1 johnzb johnzb       911 May 25 22:49 core-155639.img
-rw-r--r--  1 johnzb johnzb       891 May 25 22:49 core-155640.img
-rw-r--r--  1 johnzb johnzb       815 May 25 22:49 core-155641.img
-rw-r--r--  1 johnzb johnzb       794 May 25 22:49 core-155642.img
-rw-r--r--  1 johnzb johnzb       816 May 25 22:49 core-155643.img
-rw-r--r--  1 johnzb johnzb       816 May 25 22:49 core-155645.img
-rw-r--r--  1 johnzb johnzb       816 May 25 22:49 core-155646.img
-rw-r--r--  1 johnzb johnzb       828 May 25 22:49 core-155647.img
-rw-r--r--  1 johnzb johnzb       807 May 25 22:49 core-155648.img
-rw-r--r--  1 johnzb johnzb       901 May 25 22:49 core-155650.img
-rw-r--r--  1 johnzb johnzb       830 May 25 22:49 core-155651.img
-rw-r--r--  1 johnzb johnzb       880 May 25 22:49 core-155652.img
-rw-r--r--  1 johnzb johnzb       921 May 25 22:49 core-155653.img
-rw-r--r--  1 johnzb johnzb       869 May 25 22:49 core-155654.img
-rw-r--r--  1 johnzb johnzb       904 May 25 22:49 core-155655.img
-rw-r--r--  1 johnzb johnzb       921 May 25 22:49 core-155656.img
-rw-r--r--  1 johnzb johnzb       887 May 25 22:49 core-155657.img
-rw-r--r--  1 johnzb johnzb       839 May 25 22:49 core-155658.img
-rw-r--r--  1 johnzb johnzb       867 May 25 22:49 core-155659.img
-rw-r--r--  1 johnzb johnzb       896 May 25 22:49 core-155660.img
-rw-r--r--  1 johnzb johnzb       819 May 25 22:49 core-155663.img
-rw-r--r--  1 johnzb johnzb       909 May 25 22:49 core-155681.img
-rw-r--r--  1 johnzb johnzb       781 May 25 22:49 core-155682.img
-rw-r--r--  1 johnzb johnzb       789 May 25 22:49 core-155683.img
-rw-r--r--  1 johnzb johnzb       797 May 25 22:49 core-155684.img
-rw-r--r--  1 johnzb johnzb       780 May 25 22:49 core-155685.img
-rw-r--r--  1 johnzb johnzb       853 May 25 22:49 core-155688.img
-rw-r--r--  1 johnzb johnzb       837 May 25 22:49 core-155689.img
-rw-r--r--  1 johnzb johnzb       834 May 25 22:49 core-155690.img
-rw-r--r--  1 johnzb johnzb       877 May 25 22:49 core-155691.img
-rw-r--r--  1 johnzb johnzb       878 May 25 22:49 core-155692.img
-rw-r--r--  1 johnzb johnzb       890 May 25 22:49 core-155693.img
-rw-r--r--  1 johnzb johnzb       882 May 25 22:49 core-155694.img
-rw-r--r--  1 johnzb johnzb       826 May 25 22:49 core-155696.img
-rw-r--r--  1 johnzb johnzb       890 May 25 22:49 core-155697.img
-rw-r--r--  1 johnzb johnzb         7 May 25 22:49 cppath
-rw-------  1 johnzb johnzb    508299 May 25 22:49 dump4.log
-rw-r--r--  1 johnzb johnzb       116 May 25 22:49 fdinfo-2.img
-rw-r--r--  1 johnzb johnzb      4284 May 25 22:49 files.img
-rw-r--r--  1 johnzb johnzb        18 May 25 22:42 fs-151378.img
-rw-r--r--  1 johnzb johnzb        18 May 25 22:43 fs-151815.img
-rw-r--r--  1 johnzb johnzb        18 May 25 22:49 fs-155623.img
-rw-r--r--  1 johnzb johnzb        36 May 25 22:42 ids-151378.img
-rw-r--r--  1 johnzb johnzb        36 May 25 22:43 ids-151815.img
-rw-r--r--  1 johnzb johnzb        36 May 25 22:49 ids-155623.img
-rw-r--r--  1 johnzb johnzb        46 May 25 22:49 inventory.img
-rw-r--r--  1 johnzb johnzb     12383 May 25 22:42 mm-151378.img
-rw-r--r--  1 johnzb johnzb     12540 May 25 22:43 mm-151815.img
-rw-r--r--  1 johnzb johnzb     12319 May 25 22:49 mm-155623.img
-rw-r--r--  1 johnzb johnzb      9626 May 25 22:42 pagemap-151378.img
-rw-r--r--  1 johnzb johnzb      9792 May 25 22:43 pagemap-151815.img
-rw-r--r--  1 johnzb johnzb      9334 May 25 22:49 pagemap-155623.img
-rw-r--r--  1 johnzb johnzb 268439552 May 25 22:49 pages-1.img
-rw-------  1 johnzb johnzb     32768 May 25 22:49 perfdata
-rw-r--r--  1 johnzb johnzb       229 May 25 22:49 pstree.img
-rw-r--r--  1 johnzb johnzb        12 May 25 22:49 seccomp.img
-rw-r--r--  1 johnzb johnzb        54 May 25 22:49 stats-dump
-rw-r--r--  1 johnzb johnzb        36 May 25 22:49 timens-0.img
-rw-r--r--  1 johnzb johnzb       207 May 25 22:49 tty-info.img

```

### 参考资料：
1. https://docs.spring.io/spring-framework/reference/integration/checkpoint-restore.html
2. https://github.com/sdeleuze/spring-boot-crac-demo

