---
title: the xdp test with netns
date: 2023-11-04 11:38:53
tags:
---

```shell



# Create 2 namespaces with two veth peers, and
# forward packets in-between using generic XDP
#
# NS1(veth11)     NS2(veth22)
#     |               |
#     |               |
#   (veth1, ------ (veth2,
#   id:111)         id:222)
#     | xdp forwarding |
#     ------------------




ip netns add ns1
ip netns add ns2

ip link add veth1 index 111 type veth peer name veth11 netns ns1
ip link add veth2 index 222 type veth peer name veth22 netns ns2

ip link set veth1 up
ip link set veth2 up
ip -n ns1 link set dev veth11 up
ip -n ns2 link set dev veth22 up

ip -n ns1 addr add 10.1.1.11/24 dev veth11
ip -n ns2 addr add 10.1.1.22/24 dev veth22



ip link set dev veth1 xdpgeneric off
ip -n ns1 link set veth11 xdpgeneric obj xdp_dummy.o sec xdp_dummy
ip -n ns2 link set veth22 xdpgeneric obj xdp_dummy.o sec xdp_dummy 
ip link set dev veth1 xdpgeneric obj test_xdp_redirect.o sec redirect_to_222
ip link set dev veth2 xdpgeneric obj test_xdp_redirect.o sec redirect_to_111
ip netns exec ns1 ping -c 1 10.1.1.22
ip netns exec ns2 ping -c 1 10.1.1.11






ip link del veth1 
ip link del veth2 
ip netns del ns1 
ip netns del ns2


```



```c

//xdp_dummy.c
#define KBUILD_MODNAME "xdp_dummy"
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

SEC("xdp_dummy")
int xdp_dummy_prog(struct xdp_md *ctx)
{
        return XDP_PASS;
}

char _license[] SEC("license") = "GPL";


```


```c

//test_xdp_redirect.c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

int _version SEC("version") = 1;

SEC("redirect_to_111")
int xdp_redirect_to_111(struct xdp_md *xdp)
{
        return bpf_redirect(111, 0);
}
SEC("redirect_to_222")
int xdp_redirect_to_222(struct xdp_md *xdp)
{
        return bpf_redirect(222, 0);
}

char _license[] SEC("license") = "GPL";

```
