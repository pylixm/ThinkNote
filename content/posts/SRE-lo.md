---
type : posts
title : 「SRE知识总结」lo 网卡到底干什么用的
categories: [SRE,]
series: [SRE知识总结,] 
date : 2021-01-16
url: /posts/2021-01-16-SRE-lo.html 
tags : [SRE知识总结, ]
---

当我们在Linux系统中执行`ip a ` 或 `ifconfig` 命令时，我们可以看到系统的网卡信息。如下：

```bash
[root@pylixm-27-192 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:16:3e:02:3e:d7 brd ff:ff:ff:ff:ff:ff
    inet 172.26.90.158/20 brd 172.26.95.255 scope global dynamic eth0
       valid_lft 298248735sec preferred_lft 298248735sec
[root@pylixm-27-192 ~]# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.26.90.158  netmask 255.255.240.0  broadcast 172.26.95.255
        ether 00:16:3e:02:3e:d7  txqueuelen 1000  (Ethernet)
        RX packets 46225179  bytes 32277903077 (30.0 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 32412060  bytes 22789919573 (21.2 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 5440800  bytes 9157089685 (8.5 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5440800  bytes 9157089685 (8.5 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

类似`eth0`的便是物理网卡对应的系统接口，这里只有一个`eth0` 说明我的机器只有一个物理网卡。`lo` 大家肯定多少有所耳闻，它是一个虚拟的网络接口，并没有对应的物理网卡，我们知道它的地址是`127.0.0.1`，主要作为本地地址使用。在程序开发中，我们常常把服务启动在这个地址上，通过浏览器来访问`127.0.0.1`或其解析的`localhost` 来访问本地的服务进行调试。 

上面说的这种用法属于本地系统内部的服务交互的一个典型用法。除了内部服务的交互外，还可作为IP的暂存使用。主要应用场景在LVS DR中：

- 在DR模式中，RS需要在none-arp的网卡上配置vip，lo即可作为这个non-arp网卡配合内核参数`arp_ignore=1`将arp包仅限定真实网卡信息本身，即只回答目标IP地址是来访网络接口本地地址的ARP查询请求，说白了，就是只会LVS服务器的ARP包，避免vip冲突。 

- RS回报的时候，利用参数`arp_announce=2`发送ARP报文时使用了本地真实网卡的ip地址，这样顺利拿到客户机的mac地址。IP层并没有变化，还是源地址为VIP，目标地址为客户端IP。

LVS DR的原理，可阅读下边文章，写的比较清晰明了：

- [关于LVS-DR中一次数据的完整旅行](https://my.oschina.net/u/2487485/blog/780346)
- [LVS那些你不知道的秘密](http://dockone.io/article/10052) 

**另外，这个lo绑定ip时有坑，在我们不使用时需要及时清理。否则，当我们访问解析为lo绑定的ip的域名的时候，请求会达到本地的lo网卡，本地有这个ip对应的服务还好，若没有，那请求直接报错。**

总结下，lo 网卡的主要功能：

- 作为本地系统服务的内部交互接口。
- 作为ip的暂存虚拟网卡。

欢迎留言，讨论lo的具体作用。