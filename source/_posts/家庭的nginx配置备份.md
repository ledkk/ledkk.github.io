---
title: 家庭的nginx配置备份
date: 2024-11-09 20:47:51
tags:
---
通过nginx对家用的服务器做集中路由，不用记住ip以及端口信息，这里做一下备份


```conf
server {
        listen 80;
        server_name inner-blog.royjo.ltd;

        location / {
                root /home/johnzb/code/ledkk.github.io/public/ ;
                index index.html;

        }

}


server {
        listen 80;
        server_name inner-nas.royjo.ltd;

        location / {
                proxy_pass http://192.168.0.11:8080;
                proxy_set_header Host $Host;
                proxy_set_header x-forwarded-for $remote_addr;
                proxy_set_header X-Real-IP $remote_addr;
                add_header Cache-Control no-store;
                add_header Pragma  no-cache;
                proxy_http_version 1.1;         # 这两个最好也设置
                proxy_set_header Connection "";

        }


}

client_max_body_size 0;


server {
        # https://distribution.github.io/distribution/recipes/nginx/
        listen 443 ssl;
        server_name inner-docker.royjo.ltd;
        ssl_certificate /etc/nginx/conf.d/inner-docker.royjo.ltd.crt;
        ssl_certificate_key /etc/nginx/conf.d/inner-docker.royjo.ltd.key;
        ssl_protocols TLSv1.1 TLSv1.2;
        ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
        ssl_prefer_server_ciphers on;
        # disable any limits to avoid HTTP 413 for large image uploads
        client_max_body_size 0;

        location / {

                proxy_pass http://127.0.0.1:5000;
                proxy_set_header  Authorization $http_authorization;
                proxy_pass_header Authorization;
                proxy_set_header  Host              $http_host;   # required for docker client's sake
                proxy_set_header  X-Real-IP         $remote_addr; # pass on real client's IP
                proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
                proxy_set_header  X-Forwarded-Proto $scheme;
                proxy_read_timeout                  900;

        }


}


server {
        listen 80;
        server_name inner-bt.royjo.ltd;
        location / {
                proxy_pass http://192.168.0.11:9091;
                proxy_set_header Host $Host;
                proxy_set_header x-forwarded-for $remote_addr;
                proxy_set_header X-Real-IP $remote_addr;
                add_header Cache-Control no-store;
                add_header Pragma  no-cache;
                proxy_http_version 1.1;
                proxy_set_header Connection "";

        }
}

# https://grafana.com/docs/grafana/latest/setup-grafana/set-up-grafana-live/
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }




server {

        listen 80;
        server_name inner.royjo.ltd;


        location / {
                proxy_pass http://127.0.0.1:8099;
                proxy_set_header Host $Host;
                 proxy_set_header x-forwarded-for $remote_addr;
                proxy_set_header X-Real-IP $remote_addr;
                add_header Cache-Control no-store;
                add_header Pragma  no-cache;
                proxy_http_version 1.1;         # 这两个最好也设置
                proxy_set_header Connection "";
        }

        location /grafana/ {
                proxy_pass http://127.0.0.1:9900/;
                proxy_set_header Host $Host;
                proxy_set_header x-forwarded-for $remote_addr;
                proxy_set_header X-Real-IP $remote_addr;
                add_header Cache-Control no-store;
                add_header Pragma  no-cache;
                proxy_http_version 1.1;         # 这两个最好也设置
                proxy_set_header Connection "";
        }


        location /grafana/api/live/ws {
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_set_header Host $http_host;
                proxy_pass http://127.0.0.1:9900/api/live/ws;

        }

        location /prometheus/ {
                proxy_pass http://127.0.0.1:9090/;
                proxy_set_header Host $Host;
                proxy_set_header x-forwarded-for $remote_addr;
                proxy_set_header X-Real-IP $remote_addr;
                add_header Cache-Control no-store;
                add_header Pragma  no-cache;
                proxy_http_version 1.1;         # 这两个最好也设置
                proxy_set_header Connection "";
        }


        location /nas/ {

                proxy_pass http://192.168.0.11:8080/;
                proxy_set_header Host $Host;
                proxy_set_header x-forwarded-for $remote_addr;
                proxy_set_header X-Real-IP $remote_addr;
                add_header Cache-Control no-store;
                add_header Pragma  no-cache;
                proxy_http_version 1.1;         # 这两个最好也设置
                proxy_set_header Connection "";

        }

        location /fs {

                root /tmp/share/;
                autoindex on;
                autoindex_exact_size on;
                autoindex_localtime on;
        }
}


```