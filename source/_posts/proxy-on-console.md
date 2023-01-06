---
title: proxy_on_console
date: 2023-01-06 23:36:40
tags:
---
# 配置

```shell

$ cat ~/.bash_aliases
alias proxyon="export http_proxy=socks5://192.168.0.46:1080;export https_proxy=socks5://192.168.0.46:1080;"
alias proxyoff="export http_proxy='';export https_proxy='';"
```


# 效果
```shell

johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ proxyoff
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ curl 'http://www.google.com' -I
^C
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ ls^C
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ proxyon
johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$ curl 'http://www.google.com' -I
HTTP/1.1 200 OK
Content-Type: text/html; charset=ISO-8859-1
Cross-Origin-Opener-Policy-Report-Only: same-origin-allow-popups; report-to="gws"
Report-To: {"group":"gws","max_age":2592000,"endpoints":[{"url":"https://csp.withgoogle.com/csp/report-to/gws/other"}]}
P3P: CP="This is not a P3P policy! See g.co/p3phelp for more info."
Date: Fri, 06 Jan 2023 15:36:20 GMT
Server: gws
X-XSS-Protection: 0
X-Frame-Options: SAMEORIGIN
Transfer-Encoding: chunked
Expires: Fri, 06 Jan 2023 15:36:20 GMT
Cache-Control: private
Set-Cookie: 1P_JAR=2023-01-06-15; expires=Sun, 05-Feb-2023 15:36:20 GMT; path=/; domain=.google.com; Secure
Set-Cookie: AEC=AakniGO59ggmF3pyLwO78sM7mqVwm3lHUXga4zSJhKeoWoseCCHXnX-KiPU; expires=Wed, 05-Jul-2023 15:36:20 GMT; path=/; domain=.google.com; Secure; HttpOnly; SameSite=lax
Set-Cookie: NID=511=hvX-lQ5BTnjX_gt62kQtMAbEshFXr0f9JhzXGgEelHCP6dcgfw7M-OfzZ5oE9Zl5VGk0whTW2y9lZ_xVt0UvzRrw_ffFXbszSfonzcVuuZYoPz1qJmmw5KGaAQSnbmLd-xOxXPM2Fzh-cTgoEoDn11UhSa8kBOuSfUIBk0g8R-U; expires=Sat, 08-Jul-2023 15:36:20 GMT; path=/; domain=.google.com; HttpOnly

johnzb@ubuntu:~/mysqld_exporter-0.14.0.linux-amd64$


```

# 注意事项

使用过程中，发现wget无法识别socks5的代理，这个时候可以通过curl 代替，但还有其他替代方式，暂时未有时间尝试，参考：https://zhuanlan.zhihu.com/p/483868947



