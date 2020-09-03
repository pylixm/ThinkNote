---
type : post
title : Kubernetes 学习笔记-基础篇
categories: [Kubernetes,] 
date : 2020-08-20 22:26:00
url: /posts/2020-08-20-k8s-base.html 
tags : [Kubernetes, docker]
---

> Kubernetes 学习笔记，是个人学习记录文章，主要内容为摘录、总结和自己实践的记录，希望能帮助到和我一样正在学习的朋友。作为学习笔记，难免有理解不到位的地方，还请指正。

## Kubernetes 学习笔记-基础篇

### 容器发展史

容器发展到今天，已成为各大公司保障快速响应复杂业务场景的利器。容器的发展史，可通过下面这张图了解，一图胜千言。

![](https://gitee.com/pylixm/picture/raw/master/2020-8-28/1598610145413-itops-history_of_containers.png)

（图片来源：https://searchcloudcomputing.techtarget.com/tip/The-future-of-the-Kubernetes-ecosystem-isnt-all-about-cloud）

网上能找到大量的资料，这里找了些不错的资料，可以参考：

- [40 年回顾，一文读懂容器发展史 - InfoQ](https://www.infoq.cn/article/SS6SItkLGoLExQP4uMr5)
- [漫谈容器发展史 - 兔子先生](https://liupzmin.com/2019/11/06/docker/container-chat/)
- [容器发展简史 - 英文版](https://medium.com/faun/the-missing-introduction-to-containerization-de1fbb73efc5)
- [容器发展简史 - 中译版](http://dockone.io/article/8832)

### Kubernetes 简介

Kubernetes ，简称`K8S`，是`Google`在2014年6月开源的一个容器集群管理系统，K8S主要用于自动化部署、扩展和管理容器应用，提供了资源调度、部署管理、服务发现、扩容缩容、监控等一套功能，`Kubernetes`目标是让部署容器化应用更简单。

K8S，这是一种数字缩写 (Numeronym) 方式。类似的如`internationalization`(国际化) 叫做`i18n`、`accessibility`叫做`a11y`等

Kubernetes 主要有以下特性：

**自我修复**

在节点故障时重新启动失败的容器，替换和重新部署，保证预期的副本数量，杀死健康检查失败的容器，并且在未准备好之前不会处理客户端请求，确保线上服务不中断

**弹性伸缩**

使用命令、UI或者基于CPU使用情况自动快速扩容和缩容程序实例，确保应用服务高峰并发时的高可用性，业务低峰时回收资源，以最小成本运行服务，这个比较流啤

**自动部署和回滚**

K8S采用滚动更新策略更新应用，一次更新一个`Pod`，如果过程中出现问题，将回滚更改，保证升级不会影响业务

**服务发现和负载均衡**

K8S为多个容器提供一个统一访问入口（内部IP地址和一个DNS名称），并且负载均衡关联所有容器，是用户无需考虑容器`IP`问题。

**机密和配置管理**

管理机密数据和应用程序配置，而不需要把敏感数据暴露在镜像里，提高敏感数据安全性，并可以将一些常用的配置存储在`K8S`里，方便应用程序使用。

**存储编排**

挂载外部存储系统，无论是来自本地存储，公有云，还是网络存储(如NFS)都作为集群资源的一部分使用，极大提高存储使用的灵活性。

**批处理**

提供一次性任务，定时任务，满足批量数据处理和分析场景。

### Kubernetes 架构组件

Kubernetes 集群架构可按角色分为Master 和 Node ,简单的架构图下图所示：

![](https://gitee.com/pylixm/picture/raw/master/2020-8-31/1598861072373-Chart_02_Kubernetes-Architecture.png)

（图片来源：https://thenewstack.io/kubernetes-an-overview/）

#### Master 节点

![](https://gitee.com/pylixm/picture/raw/master/2020-8-31/1598861072375-Chart_03_Kubernetes-Master.png)

Master 节点主要包括如下组件：

- Kube-apiserver 
  - Kubernetes API 集群统一入口，各组件协调者，以RESTful API 提供接口服务，所有对象资源的增删改查和监听都交给`APIServer`处理后在提交给`Etcd`存储。
- kube-controller-manager
  - 处理集群中常规后台任务，一个资源对应一个控制器，而Controller Manager 就是负责管理这些控制器的。管理维护集群的状态，比如故障检测、自动扩展、滚动更新等
- kube-scheduler
  - 负责集群pod的调度。根据调度算法为新创建的`Pod`选择一个`Node`节点，可以任意部署，可以部署在同一个节点上，也可以部署在不同的节点上。
- etcd
  - 分布式键值存储系统，用户保存集群状态数据，比如`Pod`、`Service`等对象信息

#### Node 节点

![](https://gitee.com/pylixm/picture/raw/master/2020-8-31/1598861072377-Chart_04_Kubernetes-Node.png)

- kubelet
  - 是`Master`在`Node`节点上的`Agent`，管理本机运行容器的生命周期，如创建容器、获取容器和节点状态等工作，同时也负责容器卷插件Volume（CVI）和容器网络插件（CNI）的管理。
- kube-proxy
  - 在`Node`节点上实现`Pod`网络代理并执行链接转发，维护网络规则和四层负载均衡工作。
- 容器运行时（docker 或 rocket）
  - 容器引擎，运行容器

### kubernetes 核心概念

#### Pod

- 最小部署单元
- 一组容器的集合
- 一个Pod中的容器共享网络命名空间
- Pod是短暂的

#### Controllers控制资源

- ReplicaSet：确保预期的Pod副本数量
- Deployment：无状态应用部署
- StatefulSet：有状态应用部署
- DaenonSet：确保所有的`Node`运行同一个`Pod`
- Job：一次性任务
- Cronjob：定时任务
- 更高层次对象，部署和管理Pod

#### Service

- Pod 的上层统一访问入口，防止pod 扩缩容后ip或端口变化后失联。
- 定义一组Pod访问策略：ClusterIP、NodePort 、LoadBalancer等。

#### Label

- 标签，附加到某个资源上，用于关联对象，查询和筛选

#### Namespaces

- 命名空间，将对象逻辑上隔离

#### Annotations

- 注释

至此，Kubernetes 基本概念学习完成了。后续我会根据自己对K8S的理解不定期更新，也请期待后续的学习笔记。希望能帮助到学习K8S的同学，欢迎留言交流，共同学习。

### 扩展阅读

- [Kubernetes官网](https://kubernetes.io)

- [KUBERNETES: AN OVERVIEW](https://thenewstack.io/kubernetes-an-overview/)

- [Kubernetes基础篇 - 小明明S À DOMICILE](https://www.dongwm.com/post/use-kubernetes-1)

- [Kubernetes配置管理最佳实践](http://www.k8smeetup.com/article/VyaHa$XRm)

- [Kubernetes初体验](https://www.qikqiak.com/k8s-book/docs/14.Kubernetes%E5%88%9D%E4%BD%93%E9%AA%8C.html)

- [从零开始入门 K8s：详解 K8s 核心概念 - InfoQ](https://www.infoq.cn/article/KNMAVdo3jXs3qPKqTZBw)

  