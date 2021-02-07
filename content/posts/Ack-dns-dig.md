---
type : posts
title : 实现简单的httpDNS的一种思路
categories: [程序员杂谈,] 
date : 2021-02-07
url: /posts/2021-02-07-dns-dig.html 
tags : [Dns, dig ]
---
互联网公司，基本都有针对[DNS](https://zh.wikipedia.org/wiki/%E5%9F%9F%E5%90%8D%E7%B3%BB%E7%BB%9F "DNS")域名解析的优化处理。有些公司甚至会构建自己的智能 DNS 解析系统，来解决 LocalDNS 存在的[一系列问题](http://www.52im.net/thread-2121-1-1.html "一系列问题")，如域名劫持、调用精度和实时性等。

现如今，HttpDNS 已经成为一种比较常用优化方案之一。HttpDNS 是基于 http 协议具有 DNS 域名解析能力的一种服务，现在各大云厂商都已经构建了自己的 HttpDNS 服务。如[阿里云 HttpDNS](https://help.aliyun.com/product/30100.html "阿里云HttpDNS")、[腾讯云 HttpDNS](https://cloud.tencent.com/product/hd "腾讯云HttpDNS")等。

## HttpDNS 原理分析

HttpDNS 的原理非常简单：

- 客户端访问 HttpDNS 解析接口，HttpDNS 根据客户端 IP，从业务提前在域名配置管理系统中配置好的 IP 中根据一定的策略选择最优 IP 返回。若没有，则返回原域名，走运营商 LocalDNS 解析域名的方式；
- 客户端再向获取到的 IP 发送业务协议请求即可。以 Http 请求为例，通过在 header 中指定 host 字段，向该 IP 发送标准的 Http 请求即可。

HttpDNS 将域名解析过程显式的体现了出来。绕过 LocalDNS 的域名递归解析过程，这样就直接避免了 LocalDNS 的一系列问题。

通过 HttpDNS 原理，可以看出 HttpDNS 需要高度的可用，很容易成为整个系统的瓶颈。除此之外，还需要一个高效的域名解析配置管理系统来做域名解析和选优策略的管理。

## HttpDNS 的一种简单实现思路

下面我们来探讨另一种简单的实现方式，利用自己可控的 DNS 系统和 dig 命令来实现简单 HttpsDNS 服务。

思路如下：

- 1、将域名和 ip 的配置在公司自建 DNS 或第三方的 DNS 系统配置好，可实现地区或运营商的动态调用。
- 2、开发 http api 服务，用来提供域名查询服务接口。
- 3、在 http api 服务接口业务逻辑中，拿到客户端的 IP，通过如下命令查询域名的解析 IP，返回该 IP 即可。

```
dig @ns服务器 www.baidu.com +subnet=客户端ip
```

该方式利用了 DNS 系统的动态调度功能和域名 IP 的管理功能，结合 Http api 服务提供 Http 协议的 DNS 解析能力。绕过了 LocalDNS 的递归查询，解决了 DNS 劫持问题和精度问题。

该方式，只是一个简单的思路探索，其中还有很多细节的问题需要深究。DNS 解析是业务系统的一个强依赖服务，可用性和稳定性不容忽视。

好了，今天的分享就到这里，欢迎留言探讨！

我是 DeanWu，一个努力成为真正 SRE 的人。

> 关注公众号「码农吴先生」, 可第一时间获取最新文章。回复关键字「go」「python」获取我收集的学习资料，也可回复关键字「小二」，加我 wx 拉你进技术交流群，聊技术聊人生~

![](https://gitee.com/pylixm/picture/raw/master/2020-12-14/deanwu_wechat.png)
