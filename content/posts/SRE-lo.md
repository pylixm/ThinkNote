---
type : posts
title : 「SRE知识总结」lo 网卡到底干什么用的
categories: [SRE,]
series: [SRE知识总结,] 
date : 2021-01-16
url: /posts/2021-01-16-SRE-lo.html 
tags : [SRE知识总结, ]
---

当我们在 Linux 系统中执行`ip a` 或 `ifconfig` 命令时，我们可以看到系统的网卡信息。如下：

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

上面说的这种用法属于本地系统内部服务交互的一个典型用法。**lo除了作为内部服务交互的接口外，还可作为 IP 的暂存接口使用**。一个典型的应用场景「LVS DR模式」：

- 在 DR 模式中，RS 需要在 non-arp 的网卡上配置 vip，lo 即可作为这个 non-arp 网卡配合内核参数`arp_ignore=1`将 ARP 包仅限定真实网卡信息本身，即只回答目标 IP 地址是来访网络接口本地地址的 ARP 查询请求，说白了，就是只回 LVS 服务器的 ARP 包，避免 vip 冲突。

- RS 回包，利用参数`arp_announce=2`发送 ARP 报文时，使用了本地真实网卡的 ip 地址，这样顺利拿到客户机的 mac 地址。IP 层并没有变化，还是源地址为 VIP，目标地址为客户端 IP。

LVS DR 的原理，可阅读下边文章，写的比较清晰明了：

- [关于 LVS-DR 中一次数据的完整旅行](https://my.oschina.net/u/2487485/blog/780346 "关于LVS-DR中一次数据的完整旅行")
- [LVS 那些你不知道的秘密](http://dockone.io/article/10052 "LVS那些你不知道的秘密")

**另外，这个 lo 绑定 ip 时有坑，在我们不使用时需要及时清理。否则，当我们访问解析为 lo 绑定的 ip 的域名的时候，请求会达到本地的 lo 网卡，本地有这个 ip 对应的服务还好，若没有，那请求直接报错。**

总结下，lo 网卡的主要功能：

- 作为本地系统服务的内部交互接口。
- 作为 ip 的暂存虚拟网卡。

欢迎留言，讨论 lo 的其他有意思的功能。
