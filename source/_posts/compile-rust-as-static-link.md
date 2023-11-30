---
title: compile_rust_as_static_link
date: 2023-11-04 10:46:19
tags:
---
由于环境的不同，个人远程服务器上使用的gcc版本比较旧，而本地编译机器使用的操作系统版本又比较高，对应的gcc版本和服务器版本差异比较大，之前测试java程序的时候，还感受不出来运行环境的差异，对系统部署的影响。近期尝试rust写一些小脚本的时候，经常发现本地可以正常跑起来的程序，部署到了远程就无法跑出来了。把两套环境完全搞成一样的，成本又相对比较高。使用Docker进行部署，相对来说又比较复杂，而且远程服务器性能较弱，不太适合直接本地编译，因此需要考虑对rust做静态编译。这里做一下记录。

```shell

# 安装x86_64-unknown-linux-musl target
rustup target add x86_64-unknown-linux-musl

# 安装musl相关的工具
sudo apt-get install musl-tools

# build release 文件，产出静态链接的目标文件
cargo build --release --target x86_64-unknown-linux-musl

# 文件产出的目录为target/x86_64-unknown-linux-musl/release/xx


# 通过ldd 可以看到对应的生成程序已经是静态链接的了

ldd target/x86_64-unknown-linux-musl/release/we
        statically linked

```

## 一些关于Rust使用的记录

1. env_logger可以通过环境变量传递日志的等级，比如在使用的时候使用了如下的方式初始化日志。那么默认情况下日志为debug等级，如果想把debug调整成info或者error，可以通过如下方式调整
```rust

   env_logger::init_from_env(env_logger::Env::new().default_filter_or("debug"));

   // 调整日志等级，只要在启动的过程中传入日志等级即可，比如： `RUST_LOG=error ./website `

```


2. actix_web 可以通过app_data传递一些初始化比较困难的对象，比如数据库的连接池，http的客户端等。大家可以共用，即可统一控制


3. 客户端在使用ab进行流量施压的时候，由于会对服务端发起大量的建联请求（和启动的并发数有关），由于客户端可用的端口有限（`net.ipv4.ip_local_port_range= 32768 65000`) ，同时TIME_WAIT状态的回收时间有限制（`net.ipv4.tcp_fin_timeout = 60` ) ， 导致施压机在发起请求的过程中（尤其在连续发起多个并发请求的情况下），由于端口可用数有限制，导致发起链接耗时增加。为了缓解这种问题，可以考虑TW状态的复用（`net.ipv4.tcp_tw_reuse = 1`) 
