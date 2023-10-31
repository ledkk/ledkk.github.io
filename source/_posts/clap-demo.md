---
title: clap demo
date: 2022-10-28 23:48:27
tags:
---

# Clap 使用记录

Rust工程中，添加clap依赖

```shell
# 添加clap依赖
$cargo add clap 

```

```rust


fn main() {
    let rpc_server_config = RpcServerConfig::parse();
    let addr = rpc_server_config.addr.unwrap_or("127.0.0.1".to_owned());
    let port = rpc_server_config.port.unwrap_or(9999);
}


#[derive(Debug, Parser)]
#[clap(name = "rpcServer", version, author, about = "a rpc server")]
struct RpcServerConfig {
    #[clap(short, long)]
    addr: Option<String>,
    #[clap(short, long)]
    port: Option<u32>,
}


```

输出结果

```shell

PS D:\code\website\target\debug> .\rpc-server.exe -h
a rpc server

Usage: rpc-server.exe [OPTIONS]

Options:
  -a, --addr <ADDR>
  -p, --port <PORT>
  -h, --help         Print help information
  -V, --version      Print version information


```