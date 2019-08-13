---
title : 「WWH」「译」Puppet 简单入门 - 理论篇
categories: [Puppet] 
date : 2019-07-23
url: /posts/2019-07-23-Puppet-tutorial.html 
tags : [Puppet, WWH, 运维知识库] 
---

> WWH 为 What/Why/How，即是什么、为什么和怎么做。该系列文章，希望从这三点出发，用简单的语言说清楚一件事情，讲清楚一个工具或一个原理。

本文为译文，原文[Puppet Tutorial for Beginners: Resources, Classes, Manifest, Modules](https://www.guru99.com/puppet-tutorial.html)，主要讲解了`Puppet`工具的基本概念和用法。作为快速了解和备忘正合适，翻译记录，希望对大家有用，下面为译文。

<hr>

在了解`Puppet` 之前我们先来看下：什么是配置管理？

配置管理是将软件和计算机系统（如服务器，存储，网络）维持在已知的，期望的和一致的状态下的一个过程。它还允许你查看该状态的历史，以便用于项目管理和审计。

系统管理员常常需要执行许多重复性的工作，比如安装服务器、配置各种服务，他们往往写些服务安装的脚本来简化工作。当服务器台数增加到一定规模，脚本这种方式就不现实了。

Puppet 可以很好的解决上边说的问题。

## 什么是Puppet 

Puppet是一个开源的DevOps系统管理工具，用于集中配置管理和自动化配置管理。它常用于在整个基础架构中的配置和部署管理，及编排各种应用程序和服务，包括批量实现包安装、升级或删除，文件系统创建，用户创建或删除，服务器重启，IP配置更改等。

Puppet 可使用与Linux 和 Windows 系统。基于Ruby 语言开发，使用它自己特有的一种语言（Domain Specific Language - DSL）来编写服务配置文件。

## Puppet 版本

Puppet 有两个版本：

- **开源版本**：它是Puppet配置管理工具的基本版本,也称为Open Source Puppet。你可以从Puppet官网获取，它使用 Apache 2.0 开源许可。

- **企业版本**：它提供合规性报告、业务流程、基于角色的访问控制、GUI、API 和命令行工具等功能的商业版本，让你更有效的管理节点。

## Puppet DSL 语法和编程范式

在我们学习DSL前，先来了解下编程范式：编程范式是您在计算机编程中使用的一种风格。

常用的4中范式：

- Imperative. 命令式
- Declarative.  声明式
- Functional   函数式 
- Object-oriented.  面向对象

下面我们主要说下「命令式」和「声明式」：

- **命令式**：这种编程范式表达了计算的逻辑（怎么做）并描述了它的控制流程（怎么做）。假设您要去办公室，预订出租车并开始一步一步地向司机提供指示，直到您到达办公室。指定要做什么以及如何做是一种必要的风格。

- **声明式**：这种编程范式表达了计算的逻辑（怎么做）而没有描述它的控制流程（怎么做）。假设您要去办公室，预订出租车并指定最终目的地（办公室）。指定不该怎么做的是声明式样式。

### Puppet 使用声明式编程范式

我们用一个例子来说明：创建一个Linux系统用户。

它可以通过 shell 脚本使用命令式编程模式来完成。脚本大致如下：

```shell
#!/bin/bash 
if [ $(id -u) -eq 0 ];then
  $username=Puppetuser
  read -s -p "Enter password:" password
  Egrep "^$username" /etc/passwd > /dev/null 
  if [ $? -eq 0 ];then 
    echo "$username exists!"
    exit 1 
  else
    useradd -m -p $password $username 
    [ $? -eq 0 ] && echo "User has been added to the system!"||echo "Failed to add a user!"
  fi
fi
```

而使用Puppet来完成相同的功能，只需要几行代码的配置文件，如下：

```pp
user { "Puppetuser":
  ensure => "present"
}
```

## 配置管理工具常用的部署架构

业界常用的配置管理工具，有两种部署架构供选择：

- 基于push的部署模型：由主节点发起。
- 基于pull的部署模型：由代理启动。

### 基于push的部署模型

在此部署模型中，主服务器将配置和软件推送到各个代理。验证安全连接后，主服务器会在代理上远程运行命令。如： Ansible和Salt Stack。

### 基于pull的部署模型

在此部署模型中，各个服务器联系主服务器，验证并建立安全连接，下载其配置和软件，然后相应地进行自我配置。如：Puppet和Chef。

## Puppet 是如何工作的

Puppet基于Pull部署模型，其中代理节点在每1800秒后定期检查主节点，以查看是否需要在代理节点中更新配置的服务内容。如果需要更新任何内容，代理会从主服务器中提取必要的Puppet代码并执行所需的操作。

**Master 节点**

Master 节点是一台安装了 `Puppet master` 的Linux服务器。它负责维护Puppet管理的服务的配置。注意，Mater 节点只能为Linux系统。

**Agent 节点**

Agent 节点是安装了 `pupept agent` 的目标服务器。Agent 节点支持Linux、Windows和Mac系统。

Master 节点和Agent 节点之间通信通过SSL来确保安全。

### Master 和 Agent 节点的通信

- 1、在Agent和Master服务器之间建立连接后，Puppet Agent会将有关其服务状态的数据发送到Puppet Master服务器。 这些被称为`fasts`：此信息包括主机名，内核详细信息，IP地址，文件名详细信息等。

- 2、Puppet Master使用此数据和menifest文件(配置文件)编译一个应用于Agent的配置列表，这个列表被称为`catalog`。 catalog中描述了一些操作，例如包安装，升级或删除，文件系统创建，用户创建或删除，服务器重启，IP配置更改等。

- 3、Agent 在节点上应用此配置列表。如果配置中没有变动，则代理不会执行任何配置更改。

- 4、完成后，Agent 向 Puppet Master 报告，表明配置已应用并完成。

![](/static/imgs/puppet/master-agent.jpg)

<span style="algin:center;">图片来源：http://www.zsythink.net/archives/201 </span>

## Puppet 相关概念

Puppet 四个重要的概念：

- Resource 资源
- Class 类 
- Manifest 清单
- Modules 模块

### Puppet Resouce 

资源是Puppet 配置文件的构建基础。资源是在后端运行的内置函数，用于在puppet中执行所需的操作。通常，系统由files，users，services，processes，packages等组成。

在Puppet中，这些称为资源。资源是Puppet中的基本构建块。在Puppet中，所有的操作都是借助资源来完成的。

我们可以使用单个资源来完成任务和操作，也可以组合多个资源完成更复杂的服务配置。

常用的资源对应我们想要操作的对象，大致如下：

![](/static/imgs/puppet/resource.png)

资源也有不同的类型，Puppet通过资源和资源类型，描述系统的配置。

资源大致分为以下三种类型：

- Puppet 核心和内建的资源类型：核心或内置资源类型是puppet软件附带的预构建的puppet资源类型。所有核心或内置Puppet资源类型都由Puppet团队编写和维护。
- Puppet 定义的资源类型：定义的资源类型是使用现有资源类型的组合以Puppet声明性语言编写的轻量级资源类型。
- 自定义的Puppet 资源类型：自定义资源类型是用Ruby编写的完全自定义的资源类型。

### Puppet Class 

可以将不同资源的组合组合在一起，形成一个称为类的单元。

### Puppet Manifest

Manifest是一个包含puppet DSL文件的目录。这些文件的扩展名为.pp。 .pp扩展名代表Puppet程序。 puppet代码由Puppet Classes的定义或声明组成。

### Puppet Modules

模块是文件和目录的集合，像是Manifast和Class的定义。它们是Puppet中可重复使用和可共享的单元。

他们的关系大致如下：

![](/static/imgs/puppet/puppet-block.jpg)

## 扩展阅读

- http://www.zsythink.net/archives/185
- https://blog.csdn.net/xuejinliang/article/details/52923095
- https://www.upguard.com/articles/open-source-puppet-vs.-puppet-enterprise-which-is-right-for-you
- 可作为puppet的GUI替代方案：https://www.theforeman.org/

到这里，大家对运维中的配置管理工具Puppet的基本概念和工作原理，应该有大致的了解，后面的文章我会分享下如何简单的使用。