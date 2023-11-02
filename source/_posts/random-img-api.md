---
title: random_img_api
date: 2023-11-01 13:34:42
tags:
---

在捣鼓github page的时候，学到了一个新的名词`random image server api ` ， 页面可以利用这些服务随机的展示图片，丰富自己网站的表现形式。第一映像觉得很不现实，在网络上，流量费用是相当贵的，而对于一些高清的图片，费用更贵，不太可能会存在免费的提供图片下载的站点。不然就是做公益了。 基于这个问题，就想弄清楚这些网站的背后机制是什么？

分析了我自己在使用的这个随机图片api后，其原理大概已经清楚了，简单来说，这些随机图片api本身并不提供图片的展示服务，其只是将客户端的请求随机的302到一个图片的地址上，而图片的地址就是用网上大范围的图片服务提供的地址即可。比较简单的一个示例如下：

```shell

	curl -s  'https://cn.bing.com/'  | egrep 'preload" href="[^"]+"' -o  | egrep 'https[^"]+' -o
	# 上述脚本会将bing首页展示的背景图片的地址扣出来，随机图片服务就利用这个原理，达到了图片随机的效果。
	# https://s.cn.bing.net/th?id=OHR.HautBarr_ZH-CN8274813404_1920x1080.webp&amp;qlt=50
```

对于网络上的图床，其效果也是类似的效果，比如某一个业务有图片上传能力，那么一个简单的图床就产生了，对这个业务的上传接口做包装，图片上传后的地址就作为可以外链访问的地址即可。


## but...
实际尝试下来，不同的页面访问bing的首页，返回的页面格式存在差异，重新分析了下bing的返回内容以及接口，发现了一个比较合适的接口，简单的代码片段如下, 实际可以访问的地址为`http://www.royjo.ltd/bing_img`

```rust

    if let Ok(client) = reqwest::ClientBuilder::new().connect_timeout(Duration::from_secs(5)).build(){
        let t = client.get("https://cn.bing.com/hp/api/v1/imagegallery?format=json").send().await.unwrap().json::<serde_json::Value>().await.unwrap();
        let v :Vec<String> = t["data"]["images"].as_array().unwrap().iter().map(|k|{
            let m = &k["imageUrls"]["landscape"]["highDef"];
            format!("https://cn.bing.com{}", m.as_str().unwrap())
        }).collect::<Vec<String>>();
        let i  = random::<usize>();
        let index = i % v.len();
        let rand_url = v.get(index).unwrap();
        return Ok(Redirect::to(rand_url.clone()));
    }

```


