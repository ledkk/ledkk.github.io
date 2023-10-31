---
title: script_for_windows
date: 2023-01-06 23:43:33
tags:
---
windows机器下的常用脚本，用作记录，都是内网ip，风险可控


# windows复制到虚拟机的脚本
```bat
PS D:\tools\bat> cat .\rcp.bat
scp -r %1 johnzb@192.168.0.68:/home/johnzb/
PS D:\tools\bat>


PS C:\Users\john.zb> rcp test1

C:\Users\john.zb>scp -r test1 johnzb@192.168.0.68:/home/johnzb/
test1                                                               100% 2513KB 103.2MB/s   00:00
PS C:\Users\john.zb>

```

# 登录虚拟机的脚本

```bat

PS D:\tools\bat> cat .\ubt.bat
ssh johnzb@192.168.0.68
PS D:\tools\bat>

```

# 登录NAS的脚本

```bat
PS D:\tools\bat> cat .\nas.bat
ssh admin@192.168.0.11
PS D:\tools\bat>

```