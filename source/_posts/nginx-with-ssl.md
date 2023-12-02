---
title: nginx with ssl
date: 2023-12-02 12:22:27
tags:
---
nginx上添加ssl访问，对后端服务做代理

```shell

~# cat /etc/nginx/conf.d/website.conf
server {
        listen      443 ssl;
        server_name abc.abc.ltd;

        ssl_certificate /root/cert/abc.abc.ltd.pem;
        ssl_certificate_key  /root/cert/abc.abc.ltd.key;
        ssl_session_timeout  5m;    #缓存有效期
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;    #加密算法
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;    #安全链接可选的加密协议
        ssl_prefer_server_ciphers on;   #使用服务器端的首选算法

        location / {
                proxy_pass http://127.0.0.1:8080;
        }

}

server {
        listen 80;

        return 301 https://$server_name$request_uri;
}

```
