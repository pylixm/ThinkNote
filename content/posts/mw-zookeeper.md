---
type : post
title : Zookeeper 入门
categories: [zookeeper] 
date : 2019-12-31
url: /posts/2019-12-31-zookeeper.html 
tags : [DevOps, zookeeper]
---

Zookeeper 是`Apache`开源组织的一款分布式服务框架，常在分布式集群中扮演状态同步、集群管理、配置项管理等重要角色。业内比较流行的竞品软件有 etcd、consul，但是在Apache 开源组织中，它还是作为各分布式软件的首选来使用的，所以有必要学习一番。这边是一个简单地的入门搭建指南，根据[《Zookeeper入门看这篇就够了》](https://my.oschina.net/u/3796575/blog/1845035) 并加入了自己的操作及错误记录，大家可参阅。

## Zookeeper是什么

官方文档上这么解释zookeeper(常简称为ZK)，它是一个分布式服务框架，是Apache Hadoop 的一个子项目，它主要是用来解决分布式应用中经常遇到的一些数据管理问题，如：统一命名服务、状态同步服务、集群管理、分布式应用配置项的管理等。

上面的解释有点抽象，简单来说zookeeper=文件系统+监听通知机制。

### 文件系统

Zookeeper维护一个类似文件系统的数据结构：

![](/static/imgs/zk/zknamespace.jpg)

每个子目录项如 NameService 都被称作为 znode(目录节点)，和文件系统一样，我们能够自由的增加、删除znode，在一个znode下增加、删除子znode，唯一的不同在于znode是可以存储数据的。

有四种类型的znode：

- PERSISTENT-持久化目录节点:客户端与zookeeper断开连接后，该节点依旧存在

- PERSISTENT_SEQUENTIAL-持久化顺序编号目录节点:客户端与zookeeper断开连接后，该节点依旧存在，只是Zookeeper给该节点名称进行顺序编号

- EPHEMERAL-临时目录节点:客户端与zookeeper断开连接后，该节点被删除

- EPHEMERAL_SEQUENTIAL-临时顺序编号目录节点:客户端与zookeeper断开连接后，该节点被删除，只是Zookeeper给该节点名称进行顺序编号

### 监听通知机制

客户端注册监听它关心的目录节点，当目录节点发生变化（数据改变、被删除、子目录节点增加删除）时，zookeeper会通知客户端。

就这么简单，下面我们看看Zookeeper能做点什么呢？

## Zookeeper能做什么

zookeeper功能非常强大，可以实现诸如分布式应用配置管理、统一命名服务、状态同步服务、集群管理等功能，我们这里拿比较简单的分布式应用配置管理为例来说明。

假设我们的程序是分布式部署在多台机器上，如果我们要改变程序的配置文件，需要逐台机器去修改，非常麻烦，现在把这些配置全部放到zookeeper上去，保存在 zookeeper 的某个目录节点中，然后所有相关应用程序对这个目录节点进行监听，一旦配置信息发生变化，每个应用程序就会收到 zookeeper 的通知，然后从 zookeeper 获取新的配置信息应用到系统中。

![](/static/imgs/zk/zkservice.jpg)

如上，你大致应该了解zookeeper是个什么东西，大概能做些什么了，我们马上来学习下zookeeper的安装及使用。

### Zookeeper单机模式安装

- Step1：配置JAVA环境，检验环境：java -version

zookeeper 目前最新版本为 3.5.6，需要JDK1.8以上，否则回报如下错误：

```
Exception in thread "main" java.lang.UnsupportedClassVersionError: org/apache/zookeeper/server/quorum/QuorumPeerMain : Unsupported major.minor version 52.0
```

- Step2：下载并解压zookeeper

```bash
# cd /usr/local
# https://www-eu.apache.org/dist/zookeeper/zookeeper-3.5.6/apache-zookeeper-3.5.6-bin.tar.gz
# tar -zxvf apache-zookeeper-3.5.6.bin.tar.gz
# cd apache-zookeeper-3.5.6-bin
```
这里注意，该地址为IP6，若在服务器上直接下载，需要支持ipv6。

- Step3：重命名配置文件zoo_sample.cfg，并修改配置。

```bash
# cp conf/zoo_sample.cfg conf/zoo.cfg
# vim zoo.cfg 
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/opt/zookeeper
clientPort=2181

```

配置说明:

```
- tickTime：这个时间是作为 Zookeeper 服务器之间或客户端与服务器之间维持心跳的时间间隔，也就是每个 tickTime 时间就会发送一个心跳。
- initLimit：这个配置项是用来配置 Zookeeper 接受客户端（这里所说的客户端不是用户连接 Zookeeper 服务器的客户端，而是 Zookeeper 服务器集群中连接到 Leader 的 Follower 服务器）初始化连接时最长能忍受多少个心跳时间间隔数。当已经超过 10个心跳的时间（也就是 tickTime）长度后 Zookeeper 服务器还没有收到客户端的返回信息，那么表明这个客户端连接失败。总的时间长度就是 10*2000=20 秒
- syncLimit：这个配置项标识 Leader 与 Follower 之间发送消息，请求和应答时间长度，最长不能超过多少个 tickTime 的时间长度，总的时间长度就是 5*2000=10秒
- dataDir：顾名思义就是 Zookeeper 保存数据的目录，默认情况下，Zookeeper 将写数据的日志文件也保存在这个目录里。
- clientPort：这个端口就是客户端连接 Zookeeper 服务器的端口，Zookeeper 会监听这个端口，接受客户端的访问请求。
```

- Step4：启动zookeeper

```bash
# bin/zkServer.sh start
```
- Step5：检测是否成功启动，用zookeeper客户端连接下服务端

```bash
# bin/zkCli.sh
```

### zookeeper 命令行使用

使用客户端命令操作zookeeper

- 1、使用 ls 命令来查看当前 ZooKeeper 中所包含的内容

```bash 
# ./zkCli.sh  # 进入zk的命令行
[zk: localhost:2181(CONNECTED) 0] ls /
[zookeeper]
```

- 2、创建一个新的 znode ，使用 `create /zkPro myData`

```bash
[zk: localhost:2181(CONNECTED) 2] create /zkPro myData
Created /zkPro
```

- 3、再次使用 ls 命令来查看现在 zookeeper 中所包含的内容：

```bash
[zk: localhost:2181(CONNECTED) 5] ls /
[zkPro, zookeeper]
```


- 4、下面我们运行 get 命令来确认第二步中所创建的 znode 是否包含我们所创建的字符串：

```bash
[zk: localhost:2181(CONNECTED) 6] get /zkPro
myData
```

- 5、下面我们通过 set 命令来对 zk 所关联的字符串进行设置：

```bash 
[zk: localhost:2181(CONNECTED) 7] set /zkPro authorDate
[zk: localhost:2181(CONNECTED) 8] get /zkPro
authorDate
```

- 6、下面我们将刚才创建的 znode 删除

```bash
[zk: localhost:2181(CONNECTED) 9] delete /zkPro
[zk: localhost:2181(CONNECTED) 10] ls /
[zookeeper]
```

### Zookeeper集群模式安装

ZK 集群模式下，需要过半的机器是正常运行状态便可正常提供服务，所以建议集群机器数为奇数。例如5台设备的机器，允许你坏两台设备。可参考[这里](http://zookeeper.apache.org/doc/r3.5.6/zookeeperAdmin.html#sc_zkMulitServerSetup)。

如下我们来看下如何搭建ZK最小集群，三台设备：

```
10.10.10.1
10.10.10.2
10.10.10.3
```

- Step1：配置JAVA环境，检验环境：java -version

- Step2：下载并解压zookeeper

```bash 
# cd /usr/local
# https://www-eu.apache.org/dist/zookeeper/zookeeper-3.5.6/apache-zookeeper-3.5.6-bin.tar.gz
# tar -zxvf apache-zookeeper-3.5.6.bin.tar.gz
# cd apache-zookeeper-3.5.6-bin
```

- Step3：重命名 zoo_sample.cfg文件

```bash 
# cp conf/zoo_sample.cfg conf/zoo.cfg
```

- Step4：修改配置文件zoo.cfg，原配置文件里有的，修改成下面的值，没有的则加上

```
# vim conf/zoo.cfg
dataDir=/opt/zookeeper
clientPort=2181
server.1=10.10.10.1:2888:3888
server.2=10.10.10.2:2888:3888
server.3=10.10.10.3:2888:3898
```

配置说明：

```
- server.A=B：C：D：其中 A 是一个数字，表示这个是第几号服务器；B 是这个服务器的 ip 地址；C 表示的是这个服务器与集群中的 Leader 服务器交换信息的端口；D 表示的是万一集群中的 Leader 服务器挂了，需要一个端口来重新进行选举，选出一个新的 Leader，而这个端口就是用来执行选举时服务器相互通信的端口。
```

- Step5：载以同样的发放部署其他两台设备

- Step6：标识Server ID

在dataDir目录中创建集群机器的唯一标识文件`myid`的文件（每台服务器一个）。该ID在集群中必须唯一，且值介于1到255之间。启用TTL的集群，值介于1到254之间。

```
### 10.10.10.1 
# echo '1'> /opt/zookeeper/myid

### 10.10.10.2 
# echo '2'> /opt/zookeeper/myid

### 10.10.10.3
# echo '3'> /opt/zookeeper/myid
```

- Step7：启动三个ZK节点

```bash 
# bin/zkServer.sh start
```

- Step8：检测集群状态，也可以直接用命令“zkCli.sh -server IP:PORT”连接zookeeper服务端检测


至此，我们对zookeeper就算有了一个入门的了解，当然zookeeper远比我们这里描述的功能多，比如用zookeeper实现集群管理，分布式锁，分布式队列，zookeeper集群leader选举等等。

## 扩展阅读

- [Zookeeper 管理员手册](http://zookeeper.apache.org/doc/r3.5.6/zookeeperAdmin.html)


