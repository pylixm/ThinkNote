---
layout : post
title : "Ngrok 服务搭建完全手册"
categories: [后端开发] 
date : 2019-01-09T16:04:08+08:00
tags : [后端开发, Ngrok, 内网穿透]
---

最近需要开发个微信公众号后台，需要内网穿透工具，之前使用过sunny-ngrok，这个现在也变成付费的了。这次决定自己搭建一个，顺便学习下。以下博文，是搭建过程，已在整理思路备查，也希望能给自己动手搭建的同学一些提示。

## Ngrok 简介

在说Ngrok之前，先来说下「内网穿透」。内网穿透是一种网络术语，是指局域网内部的服务，穿透内网的限制将服务暴露在公网供外部调用的技术。随着微信公众号开发的流行，改技术术语逐渐走向我们普通开发。

Ngrok 就是一种实现内网穿透的开源软件。Ngrok 借用在公网的服务端和局域网内部的服务端构建了一个代理通道。当有服务请求时，会先将请求达到公网服务端，再有公网服务端转发给内网服务端，以达到内网暴露公网的目的。

[https://ngrok.com](https://ngrok.com)，这是ngrok的官网，它提供一个免费的账户，我们可直接使用它提供的客户端来链接它们的代理服务器，以实现暴露服务的目的，不想折腾的同学可以尝试。

它官网提供的是2.0版本的软件，已不再开源，可见github描述[这里](https://github.com/inconshreveable/ngrok#ngrok-2x)。搭建我们自己的ngrok服务，我们只能使用1.0，命令和2.0稍有区别。

1.0的功能有：

- http/tcp 协议的转发
- 检查通过隧道传输的所有http请求/响应
- 重播通过隧道传输的任何请求

这些功能，足够我们开发微信使用了。下面这批是一些其他基于ngrok 二次开发的开源软件，大家可以参考。

- [可以实现内网穿透的几款工具](https://my.oschina.net/ZL520/blog/2086061)

## 搭建过程

### Ngrok 服务搭建及客户端的编译

根据Ngrok的原理，首先你需要有一台带有公网ip的服务器，还需要有一个域名用来做证书和认证key的生成。搭建的大体思路是这样的：

- 搭建编译ngrok需要的golang环境
- 生成客户端与服务端通讯的证书
- 编译服务端和客户端
- 启动使用

这里以阿里云的Ecs的centos7.4为例，来详细记录了安装过程，其他系统和环境大家可类推。

#### 第一步 安装 golang 环境 

因为ngrok是使用golang开发的，所以在编译时是需要golang环境的。对于Centos的系统环境可直接使用yum安装，如下：

```bash
yum install golang 
```

运行 `go env` 查看是否安装成功。也可参考我之前的博文 [Golang 环境搭建及相关概念](https://pylixm.cc/posts/2018-01-25-Go-install.html)。

#### 第二步 编译Ngrok客户端和服务端

首先，我们从github下载ngrok的源码：

```bash
git clone https://github.com/inconshreveable/ngrok.git ngrok
```

开始编译服务端：

```bash 
cd ngrok 
make release-server 
```
这样编译出来的服务端就可以在我们的服务器跑了，针对于其他类型的服务器，则需要配置golang的一些环境变量，如下：

```
# 编译64位windows客户端
GOOS=windows GOARCH=amd64 make release-server
```
这样编译出来的服务端才能拿到别的服务器使用。更简单的方式是，直接在用的服务器系统上编译，这样golang的默认环境变量就是你系统对应的。

编译客户端，同服务端类似。因为我客户端是在我自己本地电脑上使用，所以需要指定相关golang的环境变量，如下：

```
# windows 
GOOS=windows GOARCH=amd64 make release-client  

# mac 
GOOS=darwin GOARCH=amd64 make release-client
```
这样，我们的服务端和客户端都编译好了。

#### 第三步 生成证书

可使用如下命令生成证书和通讯的key：

```bash 
export NGROK_DOMAIN="ngrok.pylixm.top"

openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
openssl genrsa -out device.key 2048
openssl req -new -key device.key -subj "/CN=$NGROK_DOMAIN" -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
```

会生成如下的6个文件备用：

```
rootCA.key 
rootCA.pem
device.key
device.csr
device.crt 
rootCA.srl
```

#### 第四步 启动服务端和客户端

在启动服务端之前，需要将我们上一步生成的证书替换ngrok默认的证书，在通讯时使用。
`ngrok/assets/client/tls/` 是ngrok证书默认地址，启动时会从这个目录获取证书和相关key。

```
cp rootCA.pem ngrok/assets/client/tls/ngrokroot.crt
cp device.crt ngrok/assets/server/tls/snakeoil.crt
cp device.key ngrok/ssets/server/tls/snakeoil.key
```

启动服务端：

```
./bin/ngrokd -domain="ngrok.pylixm.top" -httpAddr=":80" -httpsAddr=":443" -tunnelAddr=":4443"
```

- `domain` 是生成证书时的域名。
- `httpAddr` 是http转发的端口，默认80。
- `httpsAddr` 是https转发的端口，默认443。
- `tunnelAddr` 是服务端和客户端通讯的端口，默认4443。

另外，还需要将域名 `ngrok.pylixm.top` 解析到服务端的ip。建议大家为了能支持子域名，大家可做泛解析。

```
A   *  xx.xx.xx.xx 
```

接下来是客户端，我们在服务器上编译好了客户端，怎么下载下来呢。有个小技巧，大多数linux系统都自带python，可使用python再带的`SimpleHTTPServer`模块来临时起一个web服务，在本地直接访问即可看到起服务时的目录下的所有文件。有点类似ftp服务，但这个更简单，无需额外安装其他工具。

将我们的客户端下载下来后，编写一个配置文件，如下：

```
server_addr: ngrok.pylixm.top:4443
trust_host_root_certs: false
```

使用如下命令启动：

```bash
ngrok -config=ngrok.cfg -log=ngrok.log -subdomain=test 8000
```

- `config` 指定配置文件
- `log` 指定日志文件
- `subdomain` 可指定一个子域名前缀
- `port` 本地服务的端口

看到如下日志，说明链接配置成功了。
```bash
ngrok                                                                                                                                                                                                                                                         (Ctrl+C to quit)

Tunnel Status                 online
Version                       1.7/1.7
Forwarding                    https://test.ngrok.pylixm.top:4443 -> 127.0.0.1:8000
Forwarding                    http://test.ngrok.pylixm.top:4443 -> 127.0.0.1:8000
Web Interface                 127.0.0.1:4040
# Conn                        0
Avg Conn Time                 0.00ms
```

到此，我们就可以使用域名`test.ngrok.pylixm.top` 来访问本的8000的服务了。

这里有几个注意的点：

- 在使用ECS时，注意是否在安全组中配置了相关端口。例如上边服务端和客户端使用的4443。
- 这里有些一键安装脚本，大家可参考，有些配置和版本已经过时：
    - https://gist.github.com/popucui/18c342baefefed2ba66f87a9420efae5
    - https://github.com/sunnyos/ngrok/blob/master/ngrok.sh

### Nginx 代理共享80出口

微信公众号开发时，要求后端服务没有端口。那么我们ngrok服务的http端口就需要设置为80。问题来了，我们服务器上还可能跑着其他应用，比如我的ECS上还跑了我的博客实例。这怎么办呢？解决方案是使用nginx的反向代理。

nginx 的安装配置，大家可自行百度，这里不做过多描述。

大家只需在nginx的配置中增加一段server配置，如下：

```
server {
        server_name *.ngrok.pylixm.top 
        listen 80;
        keepalive_timeout 70;
        proxy_set_header "Host" $host:8081;  # 必须, 8081 为ngrok http转发端口
        location / {
                proxy_pass_header Server;
                proxy_redirect off;
                proxy_pass http://127.0.0.1:8081;  # 必须, 8081 为ngrok http转发端口
        }
        access_log off;
        log_not_found off;
}
```

这样我们可以直接使用`*.ngrok.pylixm.top` 这个子域名访问ngrok代理的我们本地的服务了，同时还又不影响其他的80端口服务。


## 参考

- [10分钟教你搭建自己的ngrok服务器](https://blog.csdn.net/yjc_1111/article/details/79353718)
- [ubuntu安装ngrok并使用nginx代理](https://www.lylinux.org/ubuntu%E5%AE%89%E8%A3%85ngrok%E5%B9%B6%E4%BD%BF%E7%94%A8nginx%E4%BB%A3%E7%90%86.html)

