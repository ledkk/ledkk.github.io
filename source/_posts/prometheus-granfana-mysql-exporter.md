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
