---
title: prometheus_granfana_mysql_exporter
date: 2023-01-06 22:49:56
tags:
---

# 安装prometheus、granfana
```shell
sudo apt install prometheus

sudo apt install granfana

```

# 配置mysql数据源
```shell
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ cat my.cnf
[client]
port=3306
host=127.0.0.1
user=grafanaReader
password=grafanaReader

```

对应的账号需要必要的权限
- `grant process, replication client , select on *.* to 'grafanaReader'@'%';`
- `flush privileges;`

# 启动mysqld_exporter
    使用如下脚本在本机启动mysqld_exporter，启动后，mysqld_exporter会监听9104端口， 通过`curl 'http://127.0.0.1:9104/metrics'` 可以看到exporter吐出的信息。

```shell
./mysqld_exporter --config.my-cnf=./my.cnf

johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ ./mysqld_exporter --config.my-cnf=./my.cnf
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:277 level=info msg="Starting mysqld_exporter" version="(version=0.14.0, branch=HEAD, revision=ca1b9af82a471c849c529eb8aadb1aac73e7b68c)"
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:278 level=info msg="Build context" (gogo1.17.8,userroot@401d370ca42e,date20220304-16:25:15)=(MISSING)
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:293 level=info msg="Scraper enabled" scraper=global_status
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:293 level=info msg="Scraper enabled" scraper=global_variables
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:293 level=info msg="Scraper enabled" scraper=slave_status
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:293 level=info msg="Scraper enabled" scraper=info_schema.innodb_cmp
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:293 level=info msg="Scraper enabled" scraper=info_schema.innodb_cmpmem
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:293 level=info msg="Scraper enabled" scraper=info_schema.query_response_time
ts=2023-01-06T12:30:52.566Z caller=mysqld_exporter.go:303 level=info msg="Listening on address" address=:9104
```

# 配置prometheus，采集mysqld_exporter吐出的metrics信息

    配置prometheus的采集job，采集job会定时将对应的数据采集到prometheus中存储（prometheus本身是一个时序数据库）
```shell

johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ sudo vim /etc/prometheus/prometheus.yml

johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ sudo service prometheus restart

johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ cat /etc/prometheus/prometheus.yml
# Sample config for Prometheus.

global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'example'

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    scrape_timeout: 5s

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ['localhost:9090']

  - job_name: node
    # If prometheus-node-exporter is installed, grab stats about the local
    # machine by default.
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'mysqld_exporter'
    static_configs:
      - targets: ['localhost:9104']
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$


```

# granfana上配置Prometheus数据源

1. config datasource --> add prometheus datasource 
2. import via granfana config json  `https://grafana.com/grafana/dashboards/7362` , 配置prometheus的数据源
3. 生成Mysql Overview视图




# 利用systemd管理mysqld_explorter
1. 添加mysqld_exporter.service 配置文件 `vim /etc/systemd/system/mysqld_exporter.service`
```shell
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ cat /etc/systemd/system/mysqld_exporter.service
[Unit]
Description= Prometheus MySQL Exporter
Wants=network-online.target
After=network-online.target



[Service]
User=johnzb
Group=johnzb
Type=simple
Restart=always
ExecStart=/home/johnzb/mysqld_exporter-0.14.0.linux-amd64/mysqld_exporter \
--config.my-cnf /home/johnzb/mysqld_exporter-0.14.0.linux-amd64/my.cnf \
--collect.auto_increment.columns \
--collect.binlog_size \
--collect.engine_innodb_status \
--collect.engine_tokudb_status \
--collect.global_status



[Install]
WantedBy=multi-user.target
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$

```

2. 重新加载systemd的配置文件 `sudo systemctl daemon-reload`
3. ` systemctl status mysqld_exporter` 查看mysqld_exporter的状态
4. `systemctl start mysqld_exporter` 启动mysqld_exporter服务

```shell
johnzb@ubuntu:/etc/systemd/system$ systemctl status mysqld_exporter
● mysqld_exporter.service - Prometheus MySQL Exporter
     Loaded: loaded (/etc/systemd/system/mysqld_exporter.service; disabled; vendor preset: enabled)
     Active: inactive (dead)
johnzb@ubuntu:/etc/systemd/system$ systemctl start mysqld_exporter
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ===
Authentication is required to start 'mysqld_exporter.service'.
Authenticating as: Ubuntu2123qwe,,, (johnzb)
Password:
==== AUTHENTICATION COMPLETE ===
johnzb@ubuntu:/etc/systemd/system$ systemctl status mysqld_exporter
● mysqld_exporter.service - Prometheus MySQL Exporter
     Loaded: loaded (/etc/systemd/system/mysqld_exporter.service; disabled; vendor preset: enabled)
     Active: active (running) since Fri 2023-01-06 07:12:34 PST; 10s ago
   Main PID: 8890 (mysqld_exporter)
      Tasks: 6 (limit: 9413)
     Memory: 5.8M
     CGroup: /system.slice/mysqld_exporter.service
             └─8890 /home/johnzb/mysqld_exporter-0.14.0.linux-amd64/mysqld_exporter --config.my-cnf /h>

Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:29>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:29>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:29>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:29>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:29>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:29>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:29>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.412Z caller=mysqld_exporter.go:30>
Jan 06 07:12:34 ubuntu mysqld_exporter[8890]: ts=2023-01-06T15:12:34.413Z caller=tls_config.go:195 lev>
```



# redis指标监控
```
127.0.0.1:6379> INFO
# Server
redis_version:5.0.7
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:66bd629f924ac924
redis_mode:standalone
os:Linux 5.15.0-57-generic x86_64
arch_bits:64
multiplexing_api:epoll
atomicvar_api:atomic-builtin
gcc_version:9.3.0
process_id:82854
run_id:44e7a00b34086201289d2b40eef90d56b324427b
tcp_port:6379
uptime_in_seconds:5824
uptime_in_days:0
hz:10
configured_hz:10
lru_clock:12759570
executable:/usr/bin/redis-server
config_file:/etc/redis/redis.conf

# Clients
connected_clients:1
client_recent_max_input_buffer:2
client_recent_max_output_buffer:0
blocked_clients:0

# Memory
used_memory:859152
used_memory_human:839.02K
used_memory_rss:5881856
used_memory_rss_human:5.61M
used_memory_peak:859152
used_memory_peak_human:839.02K
used_memory_peak_perc:100.11%
used_memory_overhead:845926
used_memory_startup:796232
used_memory_dataset:13226
used_memory_dataset_perc:21.02%
allocator_allocated:1399728
allocator_active:1761280
allocator_resident:9273344
total_system_memory:8300367872
total_system_memory_human:7.73G
used_memory_lua:41984
used_memory_lua_human:41.00K
used_memory_scripts:0
used_memory_scripts_human:0B
number_of_cached_scripts:0
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
allocator_frag_ratio:1.26
allocator_frag_bytes:361552
allocator_rss_ratio:5.27
allocator_rss_bytes:7512064
rss_overhead_ratio:0.63
rss_overhead_bytes:-3391488
mem_fragmentation_ratio:7.20
mem_fragmentation_bytes:5064704
mem_not_counted_for_evict:0
mem_replication_backlog:0
mem_clients_slaves:0
mem_clients_normal:49694
mem_aof_buffer:0
mem_allocator:jemalloc-5.2.1
active_defrag_running:0
lazyfree_pending_objects:0

# Persistence
loading:0
rdb_changes_since_last_save:0
rdb_bgsave_in_progress:0
rdb_last_save_time:1673698130
rdb_last_bgsave_status:ok
rdb_last_bgsave_time_sec:-1
rdb_current_bgsave_time_sec:-1
rdb_last_cow_size:0
aof_enabled:0
aof_rewrite_in_progress:0
aof_rewrite_scheduled:0
aof_last_rewrite_time_sec:-1
aof_current_rewrite_time_sec:-1
aof_last_bgrewrite_status:ok
aof_last_write_status:ok
aof_last_cow_size:0

# Stats
total_connections_received:1
total_commands_processed:5
instantaneous_ops_per_sec:0
total_net_input_bytes:185
total_net_output_bytes:13473
instantaneous_input_kbps:0.00
instantaneous_output_kbps:0.00
rejected_connections:0
sync_full:0
sync_partial_ok:0
sync_partial_err:0
expired_keys:0
expired_stale_perc:0.00
expired_time_cap_reached_count:0
evicted_keys:0
keyspace_hits:0
keyspace_misses:1
pubsub_channels:0
pubsub_patterns:0
latest_fork_usec:0
migrate_cached_sockets:0
slave_expires_tracked_keys:0
active_defrag_hits:0
active_defrag_misses:0
active_defrag_key_hits:0
active_defrag_key_misses:0

# Replication
role:master
connected_slaves:0
master_replid:fe414aa04d80c89b7ce90a0d71cc4cddb6f72724
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0

# CPU
used_cpu_sys:11.487869
used_cpu_user:14.901686
used_cpu_sys_children:0.000000
used_cpu_user_children:0.000000

# Cluster
cluster_enabled:0

# Keyspace
127.0.0.1:6379>

```