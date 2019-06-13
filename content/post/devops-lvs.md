---
layout : post
title : LVS 相关原理说明
categories: [LVS] 
date : 2019-06-13
url: /posts/2019-06-13-lvs.html 
tags : [DevOps, LVS, 运维知识库]
---

## 简介

LVS是Linux virtual server的缩写，是一个高可用性、高性能的虚拟服务器集群系统。主要针对高可伸缩、高可用网络服务的需求，给出了基于IP层和基于内容请求分发的负载平衡调度解决方法，并在Linux内核中实现了这些方法，将一组服务器构成一个实现可伸缩的、高可用网络服务的虚拟服务器。

这是一个由章文嵩博士发起的一个开源项目，它的官方网是 `http://www.linuxvirtualserver.org` 现在 LVS 已经是 Linux 内核标准的一部分。使用 LVS 可以达到的技术目标是：通过 LVS 达到的负载均衡技术和 Linux 操作系统实现一个高性能高可用的 Linux 服务器集群，它具有良好的可靠性、可扩展性和可操作性。

LVS 常常和 keepalive 配合，来作为服务的4层（ISO七层协议的传输层）的负载均衡器使用，本文整理了lvs的一些原理性知识，来更好的理解和使用lvs。如何配置以及keepalive的知识，大家可参考[lvs官网](http://www.linuxvirtualserver.org/zh/lvs1.html)或其他资料。

## 结构组成

LVS集群架构：

- 负载调度器（load balancer/ Director），它是整个集群对外面的前端机，负责将客户的请求发送到一组后端服务器上执行，而客户端则认为返回来是同一个IP(通常把这个IP成为虚拟ip或VIP)
- 服务器池（server pool/ Realserver），是一组真正执行客户请求的服务器，执行的服务一般有WEB、MAIL、FTP和DNS等。
- 共享存储（shared storage），它为服务器池提供一个共享的存储区，这样很容易使得服务器池拥有相同的内容，提供相同的服务。

LVS软件组成：

- ipvs(ip virtual server)：一段代码工作在内核空间，叫ipvs，是真正生效实现调度的代码。
- ipvsadm：另外一段是工作在用户空间，叫ipvsadm，负责为ipvs内核框架编写规则，定义谁是集群服务，而谁是后端真实的服务器(Real Server)。

## 相关术语

- DS：Director Server。指的是前端负载均衡器节点
- RS：Real Server。后端真实的工作服务器
- VIP：向外部直接面向用户请求，作为用户请求的目标的IP地址，即lvs物理机外网ip。
- DIP：Director Server IP，主要用于和内部主机通讯的IP地址，即lvs物理机内网ip。
- RIP：Real Server IP，后端服务器的IP地址
- CIP：Client IP，访问客户端的IP地址，即请求的来源ip。

## LVS 基本工作原理

![](/static/imgs/lvs/lvs.jpg)

- 1.当用户向**负载均衡调度器**（VS或者叫LB）发起请求，调度器将请求发往至内核空间。
- 2.PREROUTING链首先会接收到用户请求，判断目标IP确定是本机IP，将数据包发往INPUT链。
- 3.IPVS是工作在INPUT链上的，当用户请求到达INPUT时，IPVS会将用户请求和自己**已定义好的集群服务**进行比对，如果用户请求的就是定义的集群服务，那么此时IPVS会强行**修改数据包里的目标IP地址及端口**，并将新的数据包发往POSTROUTING链。
- 4.POSTROUTING链接收数据包后发现目标IP地址刚好是自己的后端服务器，那么此时通过选路，将数据包最终发送给后端的服务器。

## 四种负载均衡模式

LVS 的负责均衡有四种常用模式，分别为DR模式、NAT模式、TUN模式、FULLNAT模式。

### NAT 模式

VS/NAT是一种最简单的方式，所有的RealServer只需要将自己的网关指向Director即可。客户端可以是任意操作系统，但此方式下，一个Director能够带动的RealServer比较有限。在VS/NAT的方式下，Director也可以兼为一台RealServer。

![](/static/imgs/lvs/nat.jpg)

**工作流程** 用户请求LVS到达director，director将请求的报文的目的IP有VIP改为RIP，同时将报文的目标端口也改为realserver的相应端口，最后将报文发送到realserver上，realserver将通过网关路由到director，将数据返回给director，director在相应客户端之前，把数据包的源ip有RIP改为VIP，然后响应用户，将数据发送给用户。

**特点**

- NAT模式修改的是目的ip，可根据目的ip找到realserver，所以VIP和RIP不需要在同一个网段内。
- NAT的包的进出都需要经过LVS，所以LVS可能会成为一个系统的瓶颈问题。

### FULLNAT 模式

FULLNAT模式和NAT相似，只是数据包在过lvs时，不只修改目的ip，源ip也一块修改了。

![](/static/imgs/lvs/fullnat.png)

**特点**

- FULLNAT模式也不需要DIP和RIP在同一网段。
- FULLNAT和NAT相比的话：会保证RS的回包一定可到达LVS。
- FULLNAT需要更新源IP，所以性能正常比NAT模式下降10%。

### DR 模式

VS/DR方式是通过改写请求报文中的MAC地址部分来实现的。Director和RealServer必需在统一个局域网内（相同机房）。 RealServer上绑定的VIP配置在各自Non-ARP的网络设备上(如lo或tunl),Director的VIP地址对外可见，而RealServer的VIP对外是不可见的。RealServer的ip可谓内网IP, 也可为公网IP。

![](/static/imgs/lvs/dr.png)

**工作流程** 用户请求LVS到达director，director将请求的报文的目的MAC地址改为后端的realserver的MAC地址，目的IP为VIP(不变)，源IP为client IP地址(不变)，然后director通过ARP广播将报文发送到realserver，realserver检测到目的地址为自己本地的VIP，如果在同一网段，将请求直接返回给用户，如果用户跟realserver不在同一个网段，则需要通过网关返回给用户。

**特点** 

- RS跟Director Server必须有一个网卡在同一个物理网络中
- 所有的请求报文经由Director Server，但响应报文不经过Director Server
- 所有的real server机器上必须配置VIP地址（通常绑定lo）

### TUN 模式 

IP隧道（IP tunneling）是将一个IP报文封装在另一个IP报文的技术，这可以使得目标为一个IP地址的数据报文能被封装和转发到另一个IP地址。IP隧道技术亦称为IP封装技术（IP encapsulation）。IP隧道主要用于移动主机和虚拟私有网络（Virtual Private Network），在其中隧道都是静态建立的，隧道一端有一个IP地址，另一端也有唯一的IP地址。

![](/static/imgs/lvs/tun.jpg)

**工作流程** 用户请求LVS到达director，director通过IP-TUN加密技术将请求报文的包封装到一个新的IP包里面，目的IP为VIP(不变)，然后director将报文发送到realserver，realserver基于IP-TUN解密，然后解析出来包的目的为VIP，检测网卡是否绑定了VIP，绑定了就处理这个包，如果在同一个网段，将请求直接返回给用户，否则通过网关返回给用户；如果没有绑定VIP就直接丢掉这个包。

**特点**

- TUNNEL必须在所有的realserver上绑定VIP
- realserver直接把包发给client
- 隧道模式运维起来会比较难，所以一般不用
- 不支持端口映射
- RIP、VIP、DIP全是公网地址

### 四种模式比较

![](/static/imgs/lvs/vs.png)

- 是否需要VIP和realserver在同一网段 
DR模式因为只修改包的MAC地址，需要通过ARP广播找到realserver，所以VIP和realserver必须在同一个网段，也就是说DR模式需要先确认这个IP是否只能挂在这个LVS下面；其他模式因为都会修改目的地址为realserver的IP地址，所以不需要在同一个网段内

- 是否需要在realserver上绑定VIP 
realserver在收到包之后会判断目的地址是否是自己的IP 
DR模式的目的地址没有修改，还是VIP，所以需要在realserver上绑定VIP 
IP TUN模式值是对包重新包装了一层，realserver解析后的包的IP仍然是VIP，所以也需要在realserver上绑定VIP

- 四种模式的性能比较 
DR模式、IP TUN模式都是在包进入的时候经过LVS，在包返回的时候直接返回给client；所以二者的性能比NAT高，但TUN模式更加复杂，所以性能不如DR 。FULLNAT模式不仅更换目的IP还更换了源IP，所以性能比NAT下降10% 。

**性能比较大致：DR>TUN>NAT>FULLNAT**


## 十种负载均衡算法

### 静态方法

仅根据算法本省进行调度：

**轮叫调度 rr**

均等地对待每一台服务器，不管服务器上的实际连接数和系统负载

**加权轮叫 wrr**

调度器可以自动问询真实服务器的负载情况，并动态调整权值

**目标地址散列调度算法 dh**

该算法是根据目标 IP 地址通过散列函数将目标 IP 与服务器建立映射关系，出现服务器不可用或负载过高的情况下，发往该目标 IP 的请求会固定发给该服务器。

**源地址散列调度算法 sh**

与目标地址散列调度算法类似，但它是根据源地址散列算法进行静态分配固定的服务器资源。

### 动态方法

主要根据每RS当前的负载状态及调度算法进行调度，`Overhead=value` 较小的RS将被调度。

**最少链接 lc**

动态地将网络请求调度到已建立的连接数最少的服务器上 
如果集群真实的服务器具有相近的系统性能，采用该算法可以较好的实现负载均衡

**加权最少链接 wlc**

调度器可以自动问询真实服务器的负载情况，并动态调整权值 
带权重的谁不干活就给谁分配，机器配置好的权重高

**基于局部性的最少连接调度算法 lblc**

这个算法是请求数据包的目标 IP 地址的一种调度算法，该算法先根据请求的目标 IP 地址寻找最近的该目标 IP 地址所有使用的服务器，如果这台服务器依然可用，并且有能力处理该请求，调度器会尽量选择相同的服务器，否则会继续选择其它可行的服务器

**复杂的基于局部性最少的连接算法 lblcr**

记录的不是要给目标 IP 与一台服务器之间的连接记录，它会维护一个目标 IP 到一组服务器之间的映射关系，防止单点服务器负载过高。

**最少期望延迟 sed**

不考虑非活动链接，谁的权重大，优先选择权重大的服务器来接收请求，但权重大的机器会比较忙

**永不排队 nq**

无需队列，如果有realserver的连接数为0就直接分配过去

## 参考

- http://www.yulongjun.com/lb/20170817-01-lvs-introduction/
- https://blog.csdn.net/lcl_xiaowugui/article/details/81701949
- https://yq.aliyun.com/articles/87257
- https://yq.aliyun.com/articles/53735
