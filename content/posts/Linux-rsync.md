---
type : post
title : Linux基础系列 - rsync
categories: [Linux,] 
date : 2019-06-03
url: /posts/2019-06-03-Linux-rsync.html 
tags : [Linux, Linux基础系列, 运维知识库]
---

## 介绍

rsync 是一个快速的、多功能的本地和远端的文件同步工具。官方网站：https://rsync.samba.org/ ，可以在上边找到使用方法和提bug。

rsync 支持增量的同步文件，它使用特有的“rsync 算法”计算文件的不同，只同步差异的部分，所以它的同步非常快。
rsync 支持远端的文件同步，使用原生的rsync传输协议，也可通过SSH协议传输，是`rcp`和`scp`理想的替代品。

在现在的许多Linux发行版本上都默认安装了，若没有按照，可使用 `yum install rsync` 安装。

## 使用场景

rsync 可以分为3种传输数据的常用场景：

- 本地的文件复制
- 远端主机的文件传输
- 作为daemon服务的方式提供服务

下面咱们来逐一介绍。

### 本机复制内容

本机复制很简单，类似`cp`，命令如下。

```bash
rsync source.txt destination.txt 
```

可以加些参数，来定制化，如添加 `-P`来显示进度。

```bash
$ rsync -P source.txt destination.txt
source.txt
          52 100%    0.00kB/s    0:00:00 (xfer#1, to-check=0/1)

sent 138 bytes  received 42 bytes  360.00 bytes/sec
total size is 52  speedup is 0.29
```

其他常用的参数：

```
-v --verbose 详细模式输出，传输时的进度等信息。
-z --compress 传输时进行压缩以提高传输效率,
--compress-level=NUM可按级别压缩

```

### 远端同步内容

远端主机的文件传输，类似`scp`和`rcp`。用法如下：

```bash
rsync source host:destination
rsync host:source destination
```

将本地文件同步到远端：

```bash
# 默认rsync协议
$ rsync -v source.txt root@192.168.33.12:/root/dst.txt
root@192.168.33.12's password:
source.txt

sent 143 bytes  received 42 bytes  33.64 bytes/sec
total size is 52  speedup is 0.28

# 指定ssh 协议
$ rsync -v -e "ssh -p 22" source.txt root@192.168.33.12:/root/dst.txt
root@192.168.33.12's password:
source.txt

sent 91 bytes  received 48 bytes  39.71 bytes/sec
total size is 52  speedup is 0.37
```

常用的参数：

```bash
-a --archive 归档模式，表示以递归方式传输文件，并保持所有文件属性，等价于-rtopgDl
-r 对子目录以递归模式，即目录下的所有目录都同样传输，注意是小写的r.
-o 保持文件属性信息
-p 保持文件权限
-g 保持文件属组信息
-P 显示同步的过程及传输时的进度等信息
-D 保持设备文件信息
-l 保持软连接
-avzP 提示：这里的 相当于 -vzrtopgDlP(还多了Dl功能)生产环境常用 
-avz 定时任务就不用输出过程了可以-az
-e 使用的信道协议，指定替代rsh的shell程序，例如：ssh
--exclude=PATTERN 指定排除不需要传输的文件模式（和tar参数一样）--exclude=file（文件名所在的目录文件）（和tar参数一样）--delete 无差异同步，即全部同步。
```

该场景下，要注意下面几个问题：

- 1、同步的2台主机必须都有`rsync`命令，否则无法同步。
- 2、同步文件时，注意带宽消耗，尽量在流量小的时间段做文件的同步。

### 以服务形式同步

该场景应该是使用最广泛的一种，我们实际开发中，常常搭建`rsync`服务来作为文件的暂存服务器或备份服务器。rsync daemon 模式下，支持用户名认证和读写的权限控制。

该场景下，`rsync`分为服务端和客户端。服务端以daemon形式对外提供服务，客户端即其他安卓`rsync`命令的服务器。

服务端，只需添加些配置即可。默认的配置文件在 `/etc/rsyncd.conf`，可按如下说明修改配置：

```bash
# 配置参考 https://www.linuxidc.com/Linux/2016-12/138768.htm
pid file = /var/run/rsyncd.pid # 进程 pid 文件所在位置
port = 888 # 监听端口，默认是873
address = 192.168.33.12 # 服务器监听的IP地址, 默认为出口ip
uid = rsync # 守护进程所属的uid，默认是nobody，最好新建用户，并配置相关目录权限。
gid = rysnc # 守护进程的gid

# chroot，即改变程序执行时所参考的根目录位置，在传输文件之前，服务器守护程序在将chroot 到文件系统中的目录中
#这样做的好处是可能保护系统被安装漏洞侵袭的可能。缺点是需要超级用户权限。另外对符号链接文件，将会排除在外
#也就是说，你在 rsync服务器上，如果有符号链接，你在备份服务器上运行客户端的同步数据时，只会把符号链接名同步下来，并不会同步符号链接的内容
use chroot = yes 

read only = no #只读选择，只让客户端从服务器上读取文件
write only = yes #只写选择，只让客户端到服务器上写入

#允许访问的IP，可以指定单个IP，也可以指定整个网段，能提高安全性。格式是 ip 与 ip 之间、ip 和网段之间、网段和网段之间要用空格隔开；
hosts allow = 192.168.1.0/255.255.255.0 10.0.1.0/255.255.255.0 
max connections = 5 #客户端最多连接数
#当用户登录时会看到这个信息。比如显示当前时间、公告等
motd file = /etc/rsyncd/rsyncd.motd
log file = /var/log/rsync.log #rsync 服务器的日志；
transfer logging = yes #记录传输文件的日志
log format = %t %a %m %f %b #日志格式
syslog facility = local3 #日志级别

#通过该选项可以覆盖客户指定的IP超时时间。可以确保rsync服务器不会永远等待一个崩溃的客户端。超时单位为秒钟，0表示没有超时定义，这也是默认值。对于匿名rsync服务器来说，一个理想的数字是600。
timeout = 300 

#模块定义
#主要是定义服务器哪个目录要被同步。
#每个模块都要以[name]形式。这个名字就是在 rsync 客户端看到的名字。
#但是服务器真正同步的数据是通过 path 指定的。可以依次创建多个模块。
#每个模块要指定认证用户、密码文件、排除，并不是必须的。
[ backup ] #模块名，以下配置都属于此模块
path = /opt/backup #文件目录所在位置
list = no #当查看服务器上提供了哪些目录时是否列出来，no比较安全
ignore errors #忽略I/O错误

#指定由空格或逗号分隔的用户名列表，只有这些用户才允许连接该模块。这里的用户和系统用户没有任何关系，是 rsyncd.secrets 中的用户名！
#如果"auth users"被设置，那么客户端发出对该模块的连接请求以后会被rsync请求challenged进行验证身份。
#这里使用的 challenge/response 认证协议。
#用户的名和密码以明文方式存放在"secrets file"选项指定的文件中。默认情况下无需密码就可以连接模块(也就是匿名方式)。
auth users = deanwu
secrets file = /etc/rsyncd/rsyncd.secrets #密码文件

exclude = error_log httpd.pid #忽略的文件或目录
comment this is my log #本模块注释，可选
```

配置好后，启动服务端，若使用yum安装，服务为`systemd`管理的话，直接 `systemctl start rsyncd`即可。若不是，则需手动启动，如下：

```bash
/usr/local/rsync/bin/rsync --daemon --config=/etc/rsyncd.conf
```

服务器端启动后，客户端可执行如下命令拉取或推送文件。

```
# 拉取文件
 rsync -vzrtp --progress --port 888 192.168.33.12::backup/source.txt  source.txt

# 推送文件
 rsync -vzrtp --progress --port 888  source.txt 192.168.33.12::backup/source.txt 
```

若配置了用户和密码，则需要将密码明文保存到文件`/etc/rsyncd/rsyncd.pass`并附相关权限`chmod 600 /etc/rsync.pass`, 在执行时指定密码文件。如下：

```
# 拉取文件
rsync -vzrtp --progress --port 888 --password-file=/etc/rsyncd/rsyncd.pass rsync@192.168.33.12::backup  source.txt

# 推送文件
rsync -vzrtp --progress --port 888 --password-file=/etc/rsyncd/rsyncd.pass source.txt  rsync@192.168.33.12::backup/source.txt 
```

除了可以同步文件外，还可以对整个目录做同步。

```
# 拉取目录
rsync -vzrtp --progress --port 888 --password-file=/etc/rsyncd/rsyncd.pass rsync@192.168.33.12::backup  source/

# 推送目录
rsync -vzrtp --progress --port 888 --password-file=/etc/rsyncd/rsyncd.pass source/ rsync@192.168.33.12::backup/
```

## 总结

到这里，`rsync`便介绍完成了。我们了解了几种`rsync`常用的场景，这些已经涵盖了我们实际开发中能够用到它的大部分场景。如果还有什么不明白的地方，可以翻阅其文档，或留言交流。

## 参考 
https://zh.wikipedia.org/wiki/Rsync
https://rsync.samba.org/
https://linux.die.net/man/1/rsync
https://wiki.archlinux.org/index.php/Rsync_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)