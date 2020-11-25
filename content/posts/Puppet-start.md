---
type : posts 
title : Puppet 简单入门 - 安装篇
categories: [Puppet] 
date : 2019-11-26
url: /posts/2019-11-26-Puppet-tutorial-two.html 
tags : [Puppet, 运维知识库] 
---

上一篇[「译」Puppet 简单入门 - 理论篇](https://pylixm.cc/posts/2019-07-23-Puppet-tutorial.html)文章我们分享了 Puppet的基本工作原理和基本概念，这篇文章我们来看下如何具体的安装。


Puppet有两种部署模式，如下：

- Master/Agent 模式，官方推荐的模式，该模式下Master和Agent部署在不同的机器，通过HTTPS通信。Master节点部署puppet server服务用来签发管理证书和控制agent的配置信息，agent通过请求mater的catalog来变更自身服务状态。

- 无Master模式, 该模式下只有Agent节点，无需通讯。通过执行 `puppet apply` 自己根据本地的配置信息生成catalog来变更服务状态。官方已不推荐该模式，应为配置文件分散在agent机器上，管理和安全无法保障。


注：puppet server 的安装只支持Linux系统，agent 支持Linux/Windows/Mac。

这里咱们来体验下第一种方式，部署的环境如下：

- 2台 centos7.3  
- puppet6

### 准备工作

**确保服务器之间的时间相同**

因为puppet agent 与master 通讯使用https ，若时间不一致，可能会导致证书过期问题。

可通过安装 NTP 服务来保持各服务器时间的一致性。如下操作：

```
yum -y install ntpdate
ntpdate 0.centos.pool.ntp.org
```

**DNS解析**

因为puppet各节点之间的同学是通过hostname，需要我们配置合理的DNS服务，确保各节点之间可以通过hostname 可以通信。我们测试期间，可以简单的配置`hosts`文件来解析。

### puppet server 安装 

1. 安装yum源，具体地址可根据自己的系统和要安装的puppet版本来选择，可参考[这里](https://puppet.com/docs/puppetserver/6.5/install_from_packages.html)

```
sudo rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
```

2. 安装puppet server 组件

```
yum install -y puppetserver 
```

如果你有对Puppet管理的机器的信息和catalog的查阅需求，你可以安装`PuppetDB`。步骤可参考[这里](https://puppet.com/docs/puppetdb/latest/install_via_module.html)，本文暂不展开。

### puppet server 配置 

**内存优化**

puppetserver 默认内存分配为2G, 可通过修改初始化文件中如下参数来修改：

```
# /etc/sysconfig/puppetserver

......
# Modify this if you'd like to change the memory allocation, enable JMX, etc
JAVA_ARGS="-Xms2g -Xmx2g"
......
```

**内嵌webserver配置**

puppet server 内嵌了一个机遇JVM的服务，用来颁发证书。配置在 `/etc/puppetlabs/puppetserver/conf.d/webserver.conf`，默认情况下我们无需改动，若你使用外部的ca服务器，那可以修改它。可参考[这里](https://puppet.com/docs/puppetserver/6.5/config_file_webserver.html)。


**修改puppetserver配置**

默认情况下，puppet server直接启动即可运行，直接采用默认配置接口。他默认的server通信地址为 `puppet`, 因此只需在agent 上添加 `server = puppet` 即可。

我们也可以自定义一些配置，可通过修改 `/etc/puppetlabs/puppet/puppet.conf` 配置文件实现，如下：

```
[master]
dns_alt_names = 55-01.local

[main]
certname = 55-01.local
server = 55-01.local
environment = production
runinterval = 1h
```

### puppet server 启动

**为保证puppet server和agent的同学，我们需要生成证书**

生成puppetserver证书：
   
```
puppetserver ca setup 
```

生成agent证书：

```
puppetserver ca sign <NAME>

# or
sudo puppetserver ca sign (<HOSTNAME> or --all) --allow-dns-alt-names
```
更多证书命令，可参考[这里](https://puppet.com/docs/puppet/6.10/puppet_server_ca_cli.html)

**启动服务**

```
systemctl start puppetserver
```

我们可以通过 ps 来查看puppetserver 进程，确保已启动。

注：puppet server 监听8140端口（可在webserver.conf中配置），确保机器的防火墙打开。

### puppet agent 安装

1. 同样现安装yum源。
2. yum安装 agent；
   
```
 yum install puppet-agent
```

### puppet agent 配置

**agent 配置**

agent的配置文件和master相同，都是`/etc/puppetlabs/puppet/puppet.conf`，可配置如下：

```
[main]
certname = 55-02.local
server = 55-01.local
environment = production
runinterval = 1h  
```

此处需要与server通信，确保`55-01.local`可以解析。


### puppet agnet 启动

通过如下命令启动并使agent自动运行：

```
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
```


### 证书签署

在agent 第一次连接到server 时，会请求证书。我们可以在server上，运行如下命令查看：

```
puppetserver ca list 
```

agent和server之间通信必须获取到server签署的证书。可通过如下命令签署：

```
puppetserver ca sign --certname 55-02.local
# or 
puppetserver ca sign --all   # 所有请求都签署
```

可通过如下命令撤销签署：

```
puppetserver ca revoke --certname <AGENT_NAME>
```

通过如下命令查看当前签署和为签署情况：

```
puppetserver ca list --all
```

证书签署后，我们可以在agent运行`puppet agent -t `来测试agent的连通性。我们看到如下信息，说明server和agent配置正确，可以正常通信。

```
Info: Using configured environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Retrieving locales
Info: Caching catalog for 55-2.local
Info: Applying configuration version '1558878523'
Notice: Applied catalog in 0.03 seconds
```

### 编写我们的配置文件，测试puppet 

上篇文章介绍到，puppet是通过配置文件也就是有资源和类组成的`manifest` 配置文件来控制agent的配置资源和包的。那么让我们来编写一个manifest，来测试下puppet 的基本功能。

puppet 的主配置文件在 `vi /etc/puppetlabs/code/environments/production/manifests/`。 

在该目录中创建文件 `site.pp`，添加内容如下：

```pp
node 'client.itzgeek.local' { # Applies only to mentioned node; if nothing mentioned, applies to all.
file { '/tmp/puppetesttdir': # Resource type file
 ensure => 'directory', # Create as a diectory
 owner => 'root', # Ownership
 group => 'root', # Group Name
 mode => '0755', # Directory permissions
}
}
```

在agent 上运行 `puppet agent -t`, 输出如下内容：

```
Info: Using configured environment 'production'
Info: Retrieving pluginfacts
Info: Retrieving plugin
Info: Retrieving locales
Info: Loading facts
Info: Caching catalog for 31-1-158-shx-core.jpool.sinaimg.cn
Info: Applying configuration version '1574997520'
Notice: /Stage[main]/Main/Node[31-1-158-shx-core.jpool.sinaimg.cn]/File[/tmp/puppetesttdir]/ensure: created
Notice: Applied catalog in 0.05 seconds
```

可以看到 tmp 目录下创建了一个 `puppettestdir`目录，如下：

```
# /tmp 
drwxr-xr-x   2 root root    4096 Nov 29 11:18 puppetesttdir
```

至此，我们的puppet Master/Agent 架构变安装好了，我们也进行了文件下发的体验。

### 重要的Topic 文档

其他重要的Topic，大家可参考对应文档。


- [重要的目录和文件说明](https://puppet.com/docs/puppet/6.10/dirs_important_directories.html)
- [puppet environments相关](https://puppet.com/docs/puppet/6.10/env_environments.html)
- [puppet modules使用](https://puppet.com/docs/puppet/6.10/modules.html)
- [puppet 配置文件语法](https://puppet.com/docs/puppet/6.10/puppet_language.html)
- [puppet server http api](https://puppet.com/docs/puppet/6.10/nodes_external.html)
- [puppet facter](https://puppet.com/docs/puppet/6.10/facter.html)
- [puppet 模块仓库](https://forge.puppet.com/)