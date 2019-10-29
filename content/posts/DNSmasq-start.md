---
type : post
title : DNS 相关知识记录
categories: [运维知识库] 
date : 2018-11-13
url: /posts/2018-11-13-DNSmasq-start.html 
tags : [运维知识库, DNS]
---

最近在处理问题时，看到 `dnsmasq` 这个工具，经查阅资料知道它是一款轻量级的网络相关的软件，可以配置作为DNS缓存服务器和DHCP服务器使用。

结合之前了解的DNS知识，总结下。

## 前提知识点

**DNS**

DNS是 Domain Name System 的缩写，中文意思为域名解析系统，用来做域名和IP的翻译解析，即可以根据有意义的域名找到无意义的IP，从而去请求该IP对应的服务。

DNS 根据域名的分级会有不同类型的DNS服务器来解析不同的域名。主要可参考下图：

![](/static/imgs/DNS.png)

DNS 服务器分为：

- 根域名服务器：最高层次的域名服务器，所有的根域名服务器都知道所有的顶级域名服务器的域名和IP地址。本地域名服务器解析域名，首先求助根域名服务器。在很多情况下，根域名服务器并不直接把待查询的域名直接解析出IP地址，而是告诉本地域名服务器下一步应当找哪一个顶级域名服务器进行查询。所有根服务器均由美国政府授权的互联网域名与号码分配机构ICANN统一管理，负责全球互联网域名根服务器、域名体系和IP地址等的管理。更多详情，可参阅[DNS根服务器、根服务器、全球13台根域名服务器、详细介绍](https://lcx.cc/post/2343/)

- 顶级域名服务器：负责管理在该顶级域名服务器注册的二级域名，如.com .cn 等。

- 权限域名服务器：负责一个“区”的域名服务器。

- 本地域名服务器：本地域名服务器，一般为本地网络的域名服务器。若我们直接连接的是运营商的网络，那么本地域名服务器便是运营商的域名服务器。


>以下内容转自：https://www.hi-linux.com/posts/30947.html

## DNSmasq 

### 介绍

DNSmasq提供DNS服务、DHCP服务和路由通告（Router Advertisement）等服务。作为域名解析服务器(DNS)，Dnsmasq可以通过缓存DNS请求来提高对访问过的网址的连接速度。作为DHCP服务器，Dnsmasq可以为局域网电脑提供内网ip地址和路由。DNS和DHCP两个功能可以同时或分别单独实现。Dnsmasq轻量且易配置，适用于个人用户或少于50台主机的网络。此外它还自带了一个PXE服务器。它还被广泛用于智能手机和便携式热点的网络共享，并支持虚拟化框架中的虚拟网络。 支持的平台包括Linux（带glibc和uclibc），Android，* BSD和Mac OS X.Dnsmasq包含在大多数Linux发行版和FreeBSD，OpenBSD和NetBSD的ports系统中。 Dnsmasq提供完整的IPv6支持。

### 工作原理

当接受到一个DNS请求时，Dnsmasq首先会查找/etc/hosts这个文件，然后查找/etc/resolv.conf中定义的外部DNS。所以说Dnsmasq是一个很不错的外部DNS中继。

配置Dnsmasq为DNS缓存服务器，同时在/etc/hosts文件中加入本地内网解析，这样一来每当内网机器查询时就会优先查询hosts文件，这就等于将/etc/hosts共享给全内网机器使用，从而解决内网机器互相识别的问题。相比逐台机器编辑hosts文件或者添加Bind DNS记录，仅编辑一个hosts文件，这就容易多了。

### 使用

#### 安装

**Ubuntu/Debian**

```bash
$ apt-get install dnsmasq
```

**Centos/RHEL**

```
$ yum install dnsmasq
```

#### 配置Dnsmasq

Dnsmasq处理DNS设置与BIND等其他DNS服务有所不同。所有的配置都在一个文件中完成/etc/dnsmasq.conf。默认情况下dnsmasq.conf中只开启了最后include项，可以在/etc/dnsmasq.d中自己写任意名字的配置文件。

配置文件说明

Dnsmasq配置文件是/etc/dnsmasq.conf，下面对Dnsmasq中和DNS相关的配置项进行说明。

```bash
用指定的端口代替默认的DNS 53端口，如果设置为0，则完全禁止DNS功能，只使用dhcp服务
port=5353

以下两个参数告诉Dnsmasq过滤一些查询：1.哪些公共DNS没有回答 2.哪些root根域不可达。

从不转发格式错误的域名
#domain-needed

从不转发不在路由地址中的域名
#bogus-priv

resolv-file配置Dnsmasq额外的向流的DNS服务器，如果不开启就使用linux主机默认的/etc/resolv.conf里的nameserver，通过下面的选项指定其他文件。
resolv-file=/etc/dnsmasq.d/upstream_dns.conf

默认情况下Dnsmasq会发送查询到它的任何上游DNS服务器上，如果取消注释，则Dnsmasq则会严格按照/etc/resolv.conf中的DNS Server顺序进行查询。
#strict-order

以下两个参数控制是否通过/etc/resolv.conf确定上游服务器，是否检测/etc/resolv.conf的变化，则取消注释。 

如果你不想Dnsmasq读取/etc/resolv.conf文件或者其他文件，获得它的servers
# If you don't want dnsmasq to read /etc/resolv.conf or any other
# file, getting its servers from this file instead (see below), then
# uncomment this.
#no-resolv

如果你不允许Dnsmasq通过轮询/etc/resolv.conf或者其他文件来获取配置的改变，则取消注释。 
#no-poll

增加一个name server，一般用于内网域名
#server=/localnet/192.168.0.1

设置一个反向解析，所有192.168.3.0/24的地址都到10.1.2.3去解析
#server=/3.168.192.in-addr.arpa/10.1.2.3

增加一个本地域名，会在/etc/hosts中进行查询
#local=/localnet/

增加一个域名，强制解析到你指定的地址上
#address=/double-click.net/127.0.0.1

同上，还支持ipv6
#address=/www.thekelleys.org.uk/fe80::20d:60ff:fe36:f83

增加查询yahoo google和它们的子域名到vpn、search查找
# Add the IPs of all queries to yahoo.com, google.com, and their
# subdomains to the vpn and search ipsets:
#ipset=/yahoo.com/google.com/vpn,search

你还可以控制Dnsmasq和Server之间的查询从哪个网卡出去
# server=10.1.2.3@eth1

指定源地址携带10.1.2.3地址和192.168.1.1的55端口进行通讯
# and this sets the source (ie local) address used to talk to
# 10.1.2.3 to 192.168.1.1 port 55 (there must be a interface with that
# IP on the machine, obviously).
# server=10.1.2.3@192.168.1.1#55

改变Dnsmasq默认的uid和gid
#user=
#group=

如果你想Dnsmasq监听某个端口为dhcp、dns提供服务
#interface=

你还可以指定哪个端口你不想监听
#except-interface=

设置想监听的地址，如果你本机要使用写上127.0.0.1。
#listen-address=


如果你想在某个端口只提供dns服务，则可以进行配置禁止dhcp服务
#no-dhcp-interface=

# On systems which support it, dnsmasq binds the wildcard address,
# even when it is listening on only some interfaces. It then discards
# requests that it shouldn't reply to. This has the advantage of
# working even when interfaces come and go and change address. If you
# want dnsmasq to really bind only the interfaces it is listening on,
# uncomment this option. About the only time you may need this is when
# running another nameserver on the same machine.
#bind-interfaces

如果你不想使用/etc/hosts，则取消下面的注释
#no-hosts

如果你项读取其他类似/etc/hosts文件，则进行配置
addn-hosts=/etc/banner_add_hosts

自动的给hosts中的name增加一个域名
#expand-hosts

给dhcp服务赋予一个域名
#domain=thekelleys.org.uk

给dhcp的一个子域赋予一个不同的域名
#domain=wireless.thekelleys.org.uk,192.168.2.0/24

同上，不过子域是一个范围
#domain=reserved.thekelleys.org.uk,192.68.3.100,192.168.3.200

dhcp分发ip的范围，以及每个ip的租约时间
#dhcp-range=192.168.0.50,192.168.0.150,12h

同上，不过给出了掩码
#dhcp-range=192.168.0.50,192.168.0.150,255.255.255.0,12h

自动加载conf-dir目录下的配置文件
conf-dir=/etc/dnsmasq.d
  
设置dns缓存大小,默认为150条
cache-size=150
```


#### 配置实例

**配置上游服务器地址**

resolv-file配置Dnsmasq额外的上游的DNS服务器，如果不开启就使用Linux主机默认的/etc/resolv.conf里的nameserver。

通过下面的选项指定其他文件来管理上游的DNS服务器

```
$ vi /etc/dnsmasq.conf

resolv-file=/etc/resolv.dnsmasq.conf
```

在指定文件中增加转发DNS的地址

```
$ vi /etc/resolv.dnsmasq.conf

nameserver 8.8.8.8
nameserver 8.8.4.4
```

本地启用Dnsmasq解析

```
$ vi /etc/resolv.conf

nameserver 127.0.0.1
```

添加解析记录
使用系统默认hosts
编辑hosts文件,简单列举一下格式

```
$ vi /etc/hosts

127.0.0.1  localhost 
192.168.101.107   web01.mike.com web01
192.168.101.107   web02.mike.com web02
```

hosts文件的强大之处还在于能够劫持解析，譬如mirror.centos.org是CentOS仓库所在，几乎是机器正常必访问一个域名，我将它解析成一个内网地址，搭建一个内网镜像站，不仅内网机器也可以及时得到安全更新，每月还可以节省很多流量。

使用自定义hosts文件
修改配置，增加自定义hosts文件位置。

```
$ vi /etc/dnsmasq.conf

addn-hosts=/etc/dnsmasq.hosts
```

在/etc/dnsmasq.hosts文件中添加DNS记录

```
$ vi /etc/dnsmasq.hosts

192.168.101.107   web01.mike.com    web01 
192.168.101.107   web02.mike.com    web02
```

使用自定义conf

```
$ vi /etc/dnsmasq.d/address.conf

# 指定dnsmasq默认查询的上游服务器，此处以Google Public DNS为例。
server=8.8.8.8
server=8.8.4.4

# 把所有.cn的域名全部通过114.114.114.114这台国内DNS服务器来解析
server=/cn/114.114.114.114

# 给*.apple.com和taobao.com使用专用的DNS
server=/taobao.com/223.5.5.5
server=/.apple.com/223.5.5.5

# 把www.hi-linux.com解析到特定的IP
address=/www.hi-linux.com/192.168.101.107

在这里hi-linux.com相当于*.mike.com泛解析
address=/hi-linux.com/192.168.101.107
```

注：也可以直接添加到/etc/dnsmasq.conf中,不过/etc/dnsmasq.d/*.conf的优先级大于/etc/dnsmasq.conf。

#### 修改iptables配置

允许本机的53端口可对外访问

```
$ iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT
$ iptables -A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
```

转发DNS请求

```
# 开启流量转发功能
$ echo '1' > /proc/sys/net/ipv4/ip_forward
$ echo '1' > /proc/sys/net/ipv6/ip_forward   # IPv6 用户选用

# 添加流量转发规则，将外部到53的端口的请求映射到Dnsmasq服务器的53端口
$ iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
$ iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53

# 如果要限制只允许内网的请求，方法如下
$ iptables -t nat -A PREROUTING -i eth1 -p upd --dport 53 -j REDIRECT --to-port 53
```

保存规则并重启

```
$ service iptables save
$ service iptables restart
```

#### 测试Dnsmasq

启动Dnsmasq

```
$ service dnsmasq start
```

测试Dnsmasq
将其他机器的DNS换成dnsmasq所在的IP即可，就这么容易。

```
$ dig @192.168.101.104 www.hi-linux.com
```

其他可参阅官网：http://www.thekelleys.org.uk/dnsmasq/

## 参考 

- [https://lcx.cc/post/2343/](https://lcx.cc/post/2343/)
- [https://blog.csdn.net/yipiankongbai/article/details/25031461](https://blog.csdn.net/yipiankongbai/article/details/25031461)
- [https://www.hi-linux.com/posts/30947.html](https://www.hi-linux.com/posts/30947.html)