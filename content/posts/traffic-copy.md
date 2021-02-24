---
type : posts
title : 流量复制方案对比：Tcpcopy vs Goreplay 
categories: [流量复制,] 
date : 2021-02-20
url: /posts/2021-02-20-tcpcopy-vs-goreplay.html 
tags : [tcpcopy, goreplay]
---

「流量复制」常常应用在准生产环境的测试中，将线上的流量复制到一个准生产环境服务中，测试新功能和服务的承压能力。流量复制可以完全模拟线上的流量，对复杂的业务场景进行真实的服务测试，又不会对生产服务产生任何副作用。

对于复杂的流量复制应用场景和需求，完全可以立项开发一套完整的复制架构，可参考字节团队自研的 [ByteCopy](https://juejin.cn/post/6857688805835866126 "ByteCopy") 项目。而对于一些简单的需求，开源的工具基本可以搞定。开源的流量复制工具有很多，常用的有 goreplay、tcpreplay、tcpcopy 等。

本文主要来探讨下 tcpcopy 和 goreplay 的方案实现，废话不多说开整。

![目录](https://gitee.com/pylixm/picture/raw/master/2021-2-25/1614182639404-image.png)

## tcpcopy 方案实现

### tcpcopy 简介

tcpcopy 由网易技术部[王斌](https://github.com/wangbin579 "王斌")等开发，并于 2011 年 9 月开源的。tcpcopy 最新架构如下（来自作者王斌博客：https://blog.csdn.net/wangbin579/article/details/8949315）：

![架构](https://gitee.com/pylixm/picture/raw/master/2021-2-20/1613813332566-tcpcopy_arch_03.gif)

tcpcopy 主要有两个组件构成 tcpcopy client 和 intercept 。client 端负责复制流量和转发，intercept 负责对回应流量的拦截和 tcpcopy 的链接处理。

### tcpcopy 搭建

实例环境如下，下面来阐述下整个架构的搭建过程：

- 192.168.33.11 生产服务器，部署 tcpcopy client
- 192.168.33.12 辅助服务器，部署 intercept
- 192.168.33.13 测试服务器

各组件可直接从 github 下载源码包，编译安装：

```bash
# 起压机部署 tcpcopy client 192.168.33.11
wget https://github.com/session-replay-tools/tcpcopy/archive/1.0.0.tar.gz
tar xvf 1.0.0.tar.gz
cd tcpcopy-1.0.0
./configure --prefix=/opt/tcpcopy
make
make install

# 辅助机部署 intercept 192.168.33.12 , 截获包需要依赖 libpcap 抓包函数库
yum -y install libpcap-devel
# ubuntu
# apt install -y libpcap-dev
https://github.com/session-replay-tools/intercept/archive/1.0.0.tar.gz
tar xvf 1.0.0.tar.gz
cd intercept-1.0.0
./configure --prefix=/opt/tcpcopy/
make
make install
```

安装完之后，先启动 intercept，运行如下命令：

```
/opt/tcpcopy/sbin/intercept -i enp0s8 -F 'tcp and src port 8000' -d
# -i，指定网卡 enp0s8
# -F，过滤，语法和pcap抓包工具一直，如tcpdump
# -d，以domain的形式启动。
# 其他参数可 -h 查看。
```

启动 intercept 之后，再启动 tcpcopy client 。tcpcopy 启动依赖 intercept ，启动时确保 intercept 启动成功。

```
/opt/tcpcopy/sbin/tcpcopy -x 8000-192.168.33.13:8000 -s 192.168.33.12 -c 192.168.1.x -n 2 -d
# -x，复制本地8000端口的流量，转发到192.168.33.13机器的8000端口
# -s，辅助服务器intercept 地址
# -c，修改转发包的原地址为该地址段的地址，这里也可以是明确的ip。这个ip端用来伪装数据包，方便intercept做路由劫持。
# -n，流量倍数
# -d，以domain的形式运行
```

在测试服务器添加拦截路由，如下：

```
# 测试机 192.168.33.13
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.33.12
```

该路由相当于把到 192.168.1.0 网段的包都走网关 192.168.33.12，对测试服务器的回包做伪地址拦截。

这便是 tcpcopy 的整个架构部署了。

### 包流向分析

下面我们抓包看看这个过程中包是如何流动的。

我在 tcpcopy client 机器 192.168.33.11 和测试机器 192.168.33.13 使用 `python -m SimpleHTTPServer` 分别起了一个 8000 端口的服务用来测试，从我本机 192.168.33.1 发送请求，在三台机器上抓包。

tcpcopy client 机器 192.168.33.11 包信息如下：

![tcpcopy](https://gitee.com/pylixm/picture/raw/master/2021-2-23/1614072069449-image.png)

红色标注块为我本机（192.168.33.1）和 tcpcopy client 机器（192.168.33.11）的正常请求交换，从三次握手，到 http 请求，到最后的断链。

蓝色标注块则为 tcpcopy 复制的流量，可以看到为了让 intercepter 拦截回包流量，tcpcopy 已将包源 ip 地址替换为我们指定的伪网段（192.168.1.0）的地址，这样在回包时，就会根据测试服务器上的路由将回包指向辅助服务器 intercept，避免对生产流量造成影响。这也是为什么复制流量三次握手和 http 都没有回包的原因。

看测试服务器 192.168.33.13 的包：

![test server](https://gitee.com/pylixm/picture/raw/master/2021-2-23/1614074534400-image.png)

测试服务器的包和正常流量包一样，三次握手到 http 请求，最后断连。这里和测试服务器 192.168.33.13 交互的源地址 ip 已经被 tcpcopy 替换为伪 ip 192.168.1.1 。

看 intercept 192.168.33.12 的包：

![image](https://gitee.com/pylixm/picture/raw/master/2021-2-23/1614075683724-image.png)

可以看到辅助服务器拦截下来的请求，标注块 1 为复制流量三次握手时的回包，标注块 2 为 http 请求的回包，这便是 intercept 的拦截功能。可以看到在标注块 1、2 之后，辅助服务器（192.168.33.12）和 tcpcopy 服务器（192.168.33.11）进行了数据交换，这部分便是 intercept 的 tcp 处理功能，它把有用的信息返回给 tcpcopy 以便能使 tcpcopy 和测试机的 tcp 链接完成。

根据上边抓包，我们得到了和架构图一样的包流动过程，总结如下：

- 生产流量正常请求，服务正常回应。
- tcpcopy 服务在生产机器上复制流量，并修改流量包的源 ip 地址为我们指定的伪网络段(-c 参数指定)，之后将流量转发到测试服务器。
- 测试服务器，接受到流量，但包的源地址为伪网络段的地址，回包时根据提前配置好的伪路由，将回包导流到辅助服务器。
- 辅助服务器接收测试服务器的回包，但是并不转发。而是解包，只返回部分必要的信息给 tcpcopy，以便完成 tcpcopy 和测试服务器之间的 tcp 交互。

根据官方文档，我们还需要注意几个问题：

- 辅助服务器不做包的转发，需要关闭内核参数 `ip_forward`
- 在做测试时，注意上行流量的过滤和测试数据源的隔离，防止对生产数据造成多次操作的影响。
- 上边为在线实时的复制模式，tcpcopy 还支持离线方式，具体可查阅[文档](https://github.com/session-replay-tools/tcpcopy "文档")。
- 辅助机需要和测试机在一个网段，以便辅助机作为伪网段的网关使用。这里可以加一次代理，解除这个限制。如使用 nginx 作为测试中转机，将伪路由添加到 nginx 服务器上，测试机只需要向 nginx 注册即可，无需做其他配置。

## goreplay 方案实现

### goreplay 简介

Goreplay 是另一个比较常用的流量复制开源工具。与 tcpcopy 相比它的架构更简单，只有一个 gor 组件，如下：

![image](https://gitee.com/pylixm/picture/raw/master/2021-2-23/1614089477354-image.png)

只需要在生产服务器上启动一个 gor 进程，它负责所有的工作包括监听、过滤和转发。
它的设计遵循 Unix 设计哲学：_一切都是由管道组成的，各种输入将数据复用为输出_。

输入输出通常被成为插件，常见的有下面几种。

可用输入：

- --input-raw 用于捕获 HTTP 流量，您应该指定 IP 地址或接口和应用程序端口。
- --input-file 接受流量输出的文件（--output-file），用来离线流量重放。
- --input-tcp 如果您决定将来自多个转发器 Gor 实例的流量转发给它，则由 Gor 聚合实例使用。

可用输出：

- --output-http 重放 HTTP 流量到给定的端点，接受基础 URL。
- --output-file 记录传入的流量到文件。更多关于保存和从文件重播
- --output-tcp 将传入数据转发给另一个 Gor 实例，并与其一起使用--input-tcp。
- --output-stdout 用于调试，输出所有数据到 stdout。

你可以对数据进行限速、过滤、重新，还可以重用中间件实现一些自定义逻辑处理，如私有数据的过滤、认证等个性需求。

其他常用参数：

- --output-http "http://staging.com|10" 输出流量的 10%
- --http-allow-method 根据请求方式过滤。
- --http-allow-url url 白名单，其他请求将会被丢弃。
- --http-disallow-url 遇上一个 url 相反，黑名单，其他的请求会被捕获到。

本文不对中间件做过多描述，仅讨论常用功能，对中间件有需求的可参考[中间件文档](https://github.com/buger/goreplay/tree/master/middleware "中间件文档")。

### goreplay 搭建

Goreplay 是使用 golang 开发的，我们可以直接使用编译好的对应各系统的二进制文件，也可以自己编译，我们这里直接使用二进制文件。

```
wget https://github.com/buger/goreplay/releases/download/v1.3.0_RC1/gor_1.3_RC1_x64.tar.gz
tar zxvf gor_1.3_RC1_x64.tar.gz
# 解压出二进制文件 gor
gor
```

接下来，直接启动 gor 即可复制流量和转发。

```
sudo ./gor --input-raw :8000 --output-http="http://192.168.33.13:8001"
```

复制本地 8000 端口的流量到 http 远端服务`http://192.168.33.13:8001`。(复制同端口的流量时，流量会重复。这是 gor 的一个 bug，截止目前 1.3 版本仍可复现，可见[issue292](https://github.com/buger/goreplay/issues/292 "issue292"))

goreplay 的流量转发，并不是直接 tcp 包的转发，而是重新组织 http 协议级别的请求，发送到测试服务器。所以它是新的 gor 线程和测试服务器的交互，和监听线程无关，所以无需对流量进行拦截。

### 包流向分析

下面我们来看下 gor 复制的流量包的流向过程：

![gor](https://gitee.com/pylixm/picture/raw/master/2021-2-24/1614180572725-image.png)

红色标注块为正常流量，蓝色标注块为复制的流量。

看到此处，你可能会有疑问，为什么 gor 不用拦截流量？

大家仔细看 tcpcopy 和 gor 复制流量的端口，在生产机和测试机建立连接时，tcpcopy 虽然修改了 tcp 包的源 ip，但端口还是用的请求客户端的端口，是 tcp 数据链路层级别的流量复制。而 gor 这里严格来说并不是复制，而是重新构建了 http 请求。使用新端口来和测试机建连，相对的测试机在回包时，即使包是回到了生产机，但由于是和客户端不同的端口，也不会对生产流量造成影响。

## 对比总结

到此，我们对流量复制有了些基本的概念和应用了，也对 tcpcopy 和 goreplay 两款开源工具有了一定的认知。两款开源工具各有优缺点，我们来一块总结下。

- tcpcopy 部署架构相对复杂，goreplay 相对简单只需启动一个进程。
- tcpcopy 支持的协议比较丰富，goreplay 根据架构特点仅支持 http。
- tcpcopy 和 goreplay 都支持离线和在线录制回放。
- goreplay 有个中间件模块，可自定义部分过滤逻辑。

简单 http 复制 goreplay 完全可以胜任，稍复杂点或应用场景更复杂，那么推荐 tcpcopy。更复杂，要求更高的流量复制，那只能我们自己定制了。

好了，本篇到这结束了，欢迎留言讨论，你觉着最佳流量复制方案。

我是DeanWu，一个努力成为真正SRE的人。

>关注公众号「码农吴先生」, 可第一时间获取最新文章。回复关键字「go」「python」获取我收集的学习资料，也可回复关键字「小二」，加我wx拉你进技术交流群，聊技术聊人生~ 

![](https://gitee.com/pylixm/picture/raw/master/2020-12-14/deanwu_wechat.png)