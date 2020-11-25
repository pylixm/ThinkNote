---
type : posts
title : Linux基础系列 - 网络监测利器 mtr
categories: [Linux,]
series: [Linux基础系列,] 
date : 2019-09-19
url: /posts/2019-09-19-Linux-mtr.html 
tags : [Linux, Linux基础系列, 运维知识库]
---

## 介绍

我们在查看网络的联通性时，常常使用 ping。在查看网络走向路由时，使用 traceroute。除此之外，还有一个网络检测的利器--mtr。它结合了ping和 trasceroute，在显示路由ip的同事，把网络联通情况也显示出来了。

traceroute默认使用UDP数据包探测，而mtr默认使用ICMP报文探测，ICMP在某些路由节点的优先级要比其他数据包低，所以测试得到的数据可能低于实际情况。

这几个常用工具的工作流程如下：

### ping

通过 ping 命令，可以判断网络的通断、丢包和延时情况。Ping 使用 ICMP 协议，当 ping 某目的主机时，源主机发出 ICMP echo 报文，根据实际情况，返回 ICMP echo reply 或 ICMP 差错消息报文。如果返回 echo reply 说明源目的地址直接可以通，并可以携带源目的地址间的延时；如果不能通信，则根据返回的 ICMP 差错报文，可以判断不能通信的原因。

### traceroute

Traceroute 工具用来定位源和目的地址之间的路径。使用traceroute 命令可以显示从源地址出发，到目的地址之间所经过的所有路由器。使用 traceroute 命令时，源地址首先发出一个 TTL 为 1 的 UDP 报文，当经过路径的第一条时，TTL 减一变成零，于是第一跳路由器返回一个 TTL 超时的 ICMP 差错报文，于是源 server 知道了第一跳路由器的 IP 地址；然后源 server 发送一个 TTL 为 2 的 UDP 报文，过程类似，源 server 知道了第二跳路由器的 IP 地址；以此类推，当数据包到达最后一跳时，目的地址将返回一个端口不可达的 ICMP 差错报文，于是，源 server 知道数据包已经到达了目的地址，traceroute 结束。

### mtr

mtr 工具集成了 ping 和 traceroute 两种工具的优点，可以看成是两者的结合体。
mtr 工具首先使用 traceroute 得出经过的每一跳路由器，然后使用 ping 命令，得出每一跳的延时和丢包率。通过 MTR 命令，可以很直观的看到数据包所经过的路径，以及路径网络质量。

## 安装 

mtr 不是Linux自带的命令，需要安装，如下：

```
# CentOS
yum install mtr
# Ubuntu
apt-get install mtr
# macOS
brew install mtr # mac 下安装完成后，运行需要使用sudo 
# Windows
BestTrace - https://www.ipip.net/product/client.html
```

## 使用

语法格式如下：

```bash
Usage:
 mtr [options] hostname

 -F, --filename FILE        read hostname(s) from a file
 -4                         use IPv4 only
 -6                         use IPv6 only
 -u, --udp                  use UDP instead of ICMP echo
 -T, --tcp                  use TCP instead of ICMP echo
 -a, --address ADDRESS      bind the outgoing socket to ADDRESS
 -f, --first-ttl NUMBER     set what TTL to start
 -m, --max-ttl NUMBER       maximum number of hops
 -U, --max-unknown NUMBER   maximum unknown host
 -P, --port PORT            target port number for TCP, SCTP, or UDP
 -L, --localport LOCALPORT  source port number for UDP
 -s, --psize PACKETSIZE     set the packet size used for probing
 -B, --bitpattern NUMBER    set bit pattern to use in payload
 -i, --interval SECONDS     ICMP echo request interval
 -G, --gracetime SECONDS    number of seconds to wait for responses
 -Q, --tos NUMBER           type of service field in IP header
 -e, --mpls                 display information from ICMP extensions
 -Z, --timeout SECONDS      seconds to keep probe sockets open
 -r, --report               output using report mode
 -w, --report-wide          output wide report
 -c, --report-cycles COUNT  set the number of pings sent
 -j, --json                 output json
 -x, --xml                  output xml
 -C, --csv                  output comma separated values
 -l, --raw                  output raw format
 -p, --split                split output
 -t, --curses               use curses terminal interface
     --displaymode MODE     select initial display mode
 -n, --no-dns               do not resove host names
 -b, --show-ips             show IP numbers and host names
 -o, --order FIELDS         select output fields
 -y, --ipinfo NUMBER        select IP information in output
 -z, --aslookup             display AS number
 -h, --help                 display this help and exit
 -v, --version              output version information and exit

```

使用例子：

```
mtr 8.8.8.8
```
返回报告 ：

```bash
Keys:  Help   Display mode   Restart statistics   Order of fields   quit
                               Packets               Pings
Host                        Loss%   Snt   Last   Avg  Best  Wrst StDev
1. 10.85.134.145            92.4%    67    1.3   1.4   1.3   1.7   0.0
2. 10.85.244.49              0.0%    67    1.0   1.7   0.8  10.9   2.2
3. ???
4. 125.94.53.93              0.0%    67    3.5  27.2   3.3  70.9  17.2
5. 113.96.6.142              0.0%    67    1.7   5.7   1.4  15.4   2.8
6. 113.108.208.189           0.0%    67    5.3   4.2   1.8  17.4   2.6
7. 202.97.94.150            59.7%    67    3.4   5.2   3.1  21.6   4.4
8. 202.97.94.98              1.5%    67    5.8  10.0   4.5  21.9   3.3
9. 202.97.89.54              1.5%    67   83.4  84.4  63.5 109.0   9.5
10. 202.97.62.214             1.5%    67    7.5   9.6   7.4  19.8   2.1
11. 108.170.241.79            1.5%    67   15.1  12.9   9.6  21.9   2.6
12. 209.85.250.133            3.0%    67   12.3  15.2   9.4  49.0   9.2
13. 172.253.50.219            7.5%    67   21.6  25.4  19.8  74.8   8.2
14. 216.239.46.231            1.5%    67   23.6  22.7  20.5  28.0   1.6
15. ???
```
输出各列分别表示：

- host是经过的IP地址
- 丢包率：Loss
- 已发送的包数：Snt
- 最后一个包的延时：Last
- 平均延时：Avg
- 最低延时：Best
- 最差延时：Wrst
- 方差（稳定性）：StDev

在交互页面按 H 键，可以显示帮助：

```bash
Command:
?|h     help
p       pause (SPACE to resume)
d       switching display mode
e       toggle MPLS information on/off
n       toggle DNS on/off
r       reset all counters
o str   set the columns to display, default str='LRS N BAWV'
j       toggle latency(LS NABWV)/jitter(DR AGJMXI) stats
c <n>   report cycle n, default n=infinite
i <n>   set the ping interval to n seconds, default n=1
f <n>   set the initial time-to-live(ttl), default n=1
m <n>   set the max time-to-live, default n= # of hops
s <n>   set the packet size to n or random(n<0)
b <c>   set ping bit pattern to c(0..255) or random(c<0)
Q <t>   set ping packet's TOS to t
u       switch between ICMP ECHO and UDP datagrams
y       switching IP info
z       toggle ASN info on/off

press any key to go back...
```

几个常用的按键:

- 按 p 键可以暂停，空格键恢复工作
- 按 d 键可以切换显示方式
- n 开启/关闭 DNS 解析
- r 清空所有统计信息，重新统计
- c 接数字，表示循环的次数，默认无限循环
- i 接数字，设置 ping 的间隔，默认 1s
- f 接数字，设置初始的 TTL 值，若设置为 3，则从第三行开始显示
- m 接数字，设置最大的 TTL 值
- s 接数字，设置包的大小，如果数字小于零，则为随机大小

## 参考
### 名词解释
**ICMP(Internet Control Message Protocol)**
IP 协议族的一员，主要用于网络设备间发送错误指示信息, 一般不用于传输数据，常见部署在用户端网络程序中，诸如 traceroute 或 ping 等程序

**TTL(Time To Live)**
此处的 Time 表示的是次数，而不是时间，表达的是一个包在结束之前还能经过的跳数

**Hop**
跳数: 网络中两个端路径上的节点，路由器的数目

**ISP(Internet Service Provider)**
互联网服务提供商

### 扩展阅读

- 如何分析mtr报告：https://wsgzao.github.io/post/mtr/