---
title: mysql-profile-monitor
date: 2022-12-31 15:34:27
tags:
---
mysql观测性的方式，`show profile`, `show profiles` , `performance_schema` 三种相关的命令。

profile数据默认是关闭的，可以通过`SET profiling = 1;` 打开，随后可以通过`show profile` 查看查询在各个阶段的耗时及开销。 show profie 默认情况下显示各个阶段的执行耗时情况，可以增加额外的参数，观察更多的系统参数情况。例如  `BLOCK IO`,`CONTEXT SWITCHES`,`CPU`,`IPC`,`MEMORY`,`PAGE FAULTS`,`SOURCE`,`SWAPS` 等数据类型。`show profile`, `show profiles`这些语句在未来会逐步废弃，相关的功能会用`performance_schema`来进行代替。

# show profie 的语法规则

```sql

SHOW PROFILE [type [, type] ... ]
    [FOR QUERY n]
    [LIMIT row_count [OFFSET offset]]

type: {
    ALL
  | BLOCK IO
  | CONTEXT SWITCHES
  | CPU
  | IPC
  | MEMORY
  | PAGE FAULTS
  | SOURCE
  | SWAPS
}

```

默认情况下，profile是记录是关闭的，可以通过set profiling = 1; 打开。打开后在当前会话中执行查询后，再通过访问show profile 语句就可以查看对应的性能指标情况。可以指定type查看更多的信息。

```
MariaDB [test]> show profile;
+------------------------+----------+
| Status                 | Duration |
+------------------------+----------+
| Starting               | 0.000572 |
| checking permissions   | 0.000015 |
| Opening tables         | 0.000068 |
| After opening tables   | 0.000014 |
| System lock            | 0.000008 |
| table lock             | 0.000052 |
| Opening tables         | 0.040610 |
| After opening tables   | 0.000013 |
| System lock            | 0.000016 |
| table lock             | 0.000078 |
| Unlocking tables       | 0.000003 |
| closing tables         | 0.000011 |
| init                   | 0.000025 |
| Optimizing             | 0.000008 |
| Statistics             | 0.000011 |
| Preparing              | 0.000013 |
| Executing              | 0.000002 |
| Sending data           | 0.000550 |
| End of update loop     | 0.000005 |
| Query end              | 0.000002 |
| Commit                 | 0.000003 |
| closing tables         | 0.000002 |
| Unlocking tables       | 0.000001 |
| closing tables         | 0.000005 |
| Starting cleanup       | 0.000002 |
| Freeing items          | 0.000004 |
| Updating status        | 0.000049 |
| Logging slow query     | 0.000799 |
| Reset for next command | 0.000005 |
+------------------------+----------+
29 rows in set (0.001 sec)



MariaDB [test]> show profiles;
+----------+------------+--------------------+
| Query_ID | Duration   | Query              |
+----------+------------+--------------------+
|        1 | 0.06815796 | show databases     |
|        2 | 0.00631887 | SELECT DATABASE()  |
|        3 | 0.00637146 | show databases     |
|        4 | 0.00289117 | show tables        |
|        5 | 0.00135971 | show tables        |
|        6 | 0.04294308 | select * from db_2 |
+----------+------------+--------------------+
6 rows in set (0.001 sec)


MariaDB [test]> show profile for query 5;
+------------------------+----------+
| Status                 | Duration |
+------------------------+----------+
| Starting               | 0.000183 |
| checking permissions   | 0.000015 |
| Opening tables         | 0.000144 |
| After opening tables   | 0.000014 |
| System lock            | 0.000005 |
| table lock             | 0.000018 |
| init                   | 0.000045 |
| Optimizing             | 0.000023 |
| Statistics             | 0.000042 |
| Preparing              | 0.000060 |
| Executing              | 0.000006 |
| Filling schema table   | 0.000050 |
| checking permissions   | 0.000568 |
| Executing              | 0.000008 |
| Sending data           | 0.000089 |
| End of update loop     | 0.000009 |
| Query end              | 0.000004 |
| Commit                 | 0.000005 |
| closing tables         | 0.000004 |
| Removing tmp table     | 0.000011 |
| closing tables         | 0.000006 |
| Unlocking tables       | 0.000002 |
| closing tables         | 0.000003 |
| Starting cleanup       | 0.000005 |
| Freeing items          | 0.000011 |
| Updating status        | 0.000026 |
| Reset for next command | 0.000005 |
+------------------------+----------+
27 rows in set (0.000 sec)


MariaDB [test]> show profile for query 4;
+------------------------+----------+
| Status                 | Duration |
+------------------------+----------+
| Starting               | 0.000881 |
| checking permissions   | 0.000017 |
| Opening tables         | 0.000275 |
| After opening tables   | 0.000010 |
| System lock            | 0.000003 |
| table lock             | 0.000012 |
| init                   | 0.000032 |
| Optimizing             | 0.000020 |
| Statistics             | 0.000033 |
| Preparing              | 0.000375 |
| Executing              | 0.000028 |
| Filling schema table   | 0.000008 |
| checking permissions   | 0.001078 |
| Executing              | 0.000007 |
| Sending data           | 0.000029 |
| End of update loop     | 0.000006 |
| Query end              | 0.000002 |
| Commit                 | 0.000003 |
| closing tables         | 0.000002 |
| Removing tmp table     | 0.000008 |
| closing tables         | 0.000005 |
| Unlocking tables       | 0.000002 |
| closing tables         | 0.000002 |
| Starting cleanup       | 0.000003 |
| Freeing items          | 0.000007 |
| Updating status        | 0.000042 |
| Reset for next command | 0.000003 |
+------------------------+----------+
27 rows in set (0.000 sec)



MariaDB [test]> show profile all;
+------------------------+----------+----------+------------+-------------------+---------------------+--------------+---------------+---------------+-------------------+-------------------+-------------------+-------+-----------------+---------------+-------------+
| Status                 | Duration | CPU_user | CPU_system | Context_voluntary | Context_involuntary | Block_ops_in | Block_ops_out | Messages_sent | Messages_received | Page_faults_major | Page_faults_minor | Swaps | Source_function | Source_file   | Source_line |
+------------------------+----------+----------+------------+-------------------+---------------------+--------------+---------------+---------------+-------------------+-------------------+-------------------+-------+-----------------+---------------+-------------+
| Starting               | 0.000213 | 0.000108 |   0.000099 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | NULL            | NULL          |        NULL |
| Opening tables         | 0.000160 | 0.000160 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 1 |     0 | <unknown>       | sql_base.cc   |        4222 |
| After opening tables   | 0.000013 | 0.000013 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_base.cc   |        4505 |
| System lock            | 0.000005 | 0.000005 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         337 |
| table lock             | 0.000020 | 0.000019 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         342 |
| init                   | 0.000048 | 0.000048 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        4956 |
| Optimizing             | 0.000023 | 0.000023 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        1971 |
| Statistics             | 0.000050 | 0.000050 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 1 |     0 | <unknown>       | sql_select.cc |        2449 |
| Preparing              | 0.000321 | 0.000323 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        2524 |
| Executing              | 0.000012 | 0.000009 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        4522 |
| Filling schema table   | 0.015526 | 0.000105 |   0.000836 |                 3 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                13 |     0 | <unknown>       | sql_show.cc   |        8723 |
| Executing              | 0.000020 | 0.000008 |   0.000007 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_show.cc   |        8838 |
| Sending data           | 0.000047 | 0.000025 |   0.000023 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 1 |     0 | <unknown>       | sql_select.cc |        4720 |
| End of update loop     | 0.000010 | 0.000005 |   0.000005 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        5000 |
| Query end              | 0.000003 | 0.000002 |   0.000001 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        6005 |
| Commit                 | 0.000004 | 0.000002 |   0.000002 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        6051 |
| closing tables         | 0.000001 | 0.000001 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_base.cc   |         786 |
| Removing tmp table     | 0.000012 | 0.000006 |   0.000006 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |       20294 |
| closing tables         | 0.000007 | 0.000003 |   0.000004 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |       20327 |
| Unlocking tables       | 0.000001 | 0.000001 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         429 |
| closing tables         | 0.000002 | 0.000001 |   0.000001 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         442 |
| Starting cleanup       | 0.000004 | 0.000002 |   0.000002 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        6117 |
| Freeing items          | 0.000007 | 0.000003 |   0.000003 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        8043 |
| Updating status        | 0.000024 | 0.000013 |   0.000012 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        2401 |
| Reset for next command | 0.000003 | 0.000002 |   0.000001 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        2433 |
+------------------------+----------+----------+------------+-------------------+---------------------+--------------+---------------+---------------+-------------------+-------------------+-------------------+-------+-----------------+---------------+-------------+
25 rows in set (0.001 sec)



MariaDB [test]> show profile block io for query 2;
+------------------------+----------+--------------+---------------+
| Status                 | Duration | Block_ops_in | Block_ops_out |
+------------------------+----------+--------------+---------------+
| Starting               | 0.000383 |            0 |             0 |
| checking permissions   | 0.000019 |            0 |             0 |
| Opening tables         | 0.000084 |            0 |             0 |
| After opening tables   | 0.000015 |            0 |             0 |
| System lock            | 0.000011 |            0 |             0 |
| table lock             | 0.000027 |            0 |             0 |
| init                   | 0.000083 |            0 |             0 |
| Optimizing             | 0.000036 |            0 |             0 |
| Statistics             | 0.000052 |            0 |             0 |
| Preparing              | 0.000083 |            0 |             0 |
| Executing              | 0.000008 |            0 |             0 |
| Sending data           | 0.000166 |            0 |             0 |
| End of update loop     | 0.000018 |            0 |             0 |
| Query end              | 0.000006 |            0 |             0 |
| Commit                 | 0.000012 |            0 |             0 |
| closing tables         | 0.000006 |            0 |             0 |
| Unlocking tables       | 0.000005 |            0 |             0 |
| closing tables         | 0.000017 |            0 |             0 |
| Starting cleanup       | 0.000005 |            0 |             0 |
| Freeing items          | 0.000012 |            0 |             0 |
| Updating status        | 0.000027 |            0 |             0 |
| Logging slow query     | 0.011532 |            0 |             0 |
| Reset for next command | 0.000090 |            0 |             0 |
+------------------------+----------+--------------+---------------+
23 rows in set (0.000 sec)



MariaDB [test]> select * from information_schema.profiling where query_id = 2;
+----------+-----+------------------------+----------+----------+------------+-------------------+---------------------+--------------+---------------+---------------+-------------------+-------------------+-------------------+-------+-----------------+---------------+-------------+
| QUERY_ID | SEQ | STATE                  | DURATION | CPU_USER | CPU_SYSTEM | CONTEXT_VOLUNTARY | CONTEXT_INVOLUNTARY | BLOCK_OPS_IN | BLOCK_OPS_OUT | MESSAGES_SENT | MESSAGES_RECEIVED | PAGE_FAULTS_MAJOR | PAGE_FAULTS_MINOR | SWAPS | SOURCE_FUNCTION | SOURCE_FILE   | SOURCE_LINE |
+----------+-----+------------------------+----------+----------+------------+-------------------+---------------------+--------------+---------------+---------------+-------------------+-------------------+-------------------+-------+-----------------+---------------+-------------+
|        2 |   2 | Starting               | 0.000383 | 0.000000 |   0.000380 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | NULL            | NULL          |        NULL |
|        2 |   3 | checking permissions   | 0.000019 | 0.000000 |   0.000016 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        6699 |
|        2 |   4 | Opening tables         | 0.000084 | 0.000000 |   0.000084 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_base.cc   |        4222 |
|        2 |   5 | After opening tables   | 0.000015 | 0.000000 |   0.000015 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_base.cc   |        4505 |
|        2 |   6 | System lock            | 0.000011 | 0.000000 |   0.000011 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         337 |
|        2 |   7 | table lock             | 0.000027 | 0.000000 |   0.000027 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         342 |
|        2 |   8 | init                   | 0.000083 | 0.000000 |   0.000083 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        4956 |
|        2 |   9 | Optimizing             | 0.000036 | 0.000015 |   0.000021 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        1971 |
|        2 |  10 | Statistics             | 0.000052 | 0.000027 |   0.000025 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        2449 |
|        2 |  11 | Preparing              | 0.000083 | 0.000083 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        2524 |
|        2 |  12 | Executing              | 0.000008 | 0.000008 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        4522 |
|        2 |  13 | Sending data           | 0.000166 | 0.000167 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        4720 |
|        2 |  14 | End of update loop     | 0.000018 | 0.000018 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_select.cc |        5000 |
|        2 |  15 | Query end              | 0.000006 | 0.000006 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        6005 |
|        2 |  16 | Commit                 | 0.000012 | 0.000012 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        6051 |
|        2 |  17 | closing tables         | 0.000006 | 0.000006 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_base.cc   |         786 |
|        2 |  18 | Unlocking tables       | 0.000005 | 0.000005 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         429 |
|        2 |  19 | closing tables         | 0.000017 | 0.000017 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | lock.cc       |         442 |
|        2 |  20 | Starting cleanup       | 0.000005 | 0.000005 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        6117 |
|        2 |  21 | Freeing items          | 0.000012 | 0.000012 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        8043 |
|        2 |  22 | Updating status        | 0.000027 | 0.000123 |   0.000000 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        2401 |
|        2 |  23 | Logging slow query     | 0.011532 | 0.000458 |   0.000985 |                 9 |                   4 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        2557 |
|        2 |  24 | Reset for next command | 0.000090 | 0.000040 |   0.000037 |                 0 |                   0 |            0 |             0 |             0 |                 0 |                 0 |                 0 |     0 | <unknown>       | sql_parse.cc  |        2433 |
+----------+-----+------------------------+----------+----------+------------+-------------------+---------------------+--------------+---------------+---------------+-------------------+-------------------+-------------------+-------+-----------------+---------------+-------------+
23 rows in set (0.002 sec)

```



# MySQL Performance Schema

https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html

https://developer.aliyun.com/article/640177

MySQL Performance Schema 用于在底层监控mysqlserver 执行情况的工具，他本身是一个独立的数据库，使用的是performance schema 存储引擎。他有以下几个特点
1. performance schema 用于收集mysql 性能相关的信息，在mysql中表现为一个独立的数据库，以及独立的存储引擎`performance schema` ， 和informance schema 收集元数据不同，performance schema 主要专注于收集性能数据。
2. performance schema监控mysql 服务器的事件，事件是指在mysql中服务器所做的任何需要时间的事情，并进行监控，并收集下来。一般来说，事件可以是函数调用，操作系统的等待，sql语句执行过程中的一个状态（比如解析、排序等），或者一个完整的语句。事件集合提供了对服务器和多个存储引擎的同步调用（如互斥锁）文件和表I/O、表锁等信息的访问。
3. performance schema的事件和binlog event、event shceduler events 不同
4. 



```sql

select * from information_schema.tables where table_schema = 'performance_schema' and table_rows > 0;




# 查看当前库支持的引擎类型。
MariaDB [performance_schema]> SELECT * FROM INFORMATION_SCHEMA.ENGINES ;
ERROR 2006 (HY000): Server has gone away
No connection. Trying to reconnect...
Connection id:    10
Current database: performance_schema

+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| ENGINE             | SUPPORT | COMMENT                                                                                         | TRANSACTIONS | XA   | SAVEPOINTS |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
| CSV                | YES     | Stores tables as CSV files                                                                      | NO           | NO   | NO         |
| MRG_MyISAM         | YES     | Collection of identical MyISAM tables                                                           | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                                       | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage. Used for internal temporary tables and privilege tables | NO           | NO   | NO         |
| MyISAM             | YES     | Non-transactional engine with good performance and small data footprint                         | NO           | NO   | NO         |
| SEQUENCE           | YES     | Generated tables filled with sequential values                                                  | YES          | NO   | YES        |
| InnoDB             | DEFAULT | Supports transactions, row-level locking, foreign keys and encryption for tables                | YES          | YES  | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                                              | NO           | NO   | NO         |
+--------------------+---------+-------------------------------------------------------------------------------------------------+--------------+------+------------+
8 rows in set (0.069 sec)



MariaDB [performance_schema]> SHOW VARIABLES LIKE 'performance_schema';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| performance_schema | OFF   |
+--------------------+-------+
1 row in set (0.002 sec)

```

