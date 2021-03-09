---
type : posts
title : 「译」Kubernetes新手入门指南
categories: [Kubernetes,] 
date : 2020-08-11 22:26:00
url: /posts/2020-08-11-k8s-start.html 
tags : [Kubernetes, docker, 翻译]
---

> 原文地址：https://dzone.com/articles/a-beginners-guide-to-kubernetes

Kubernetes现已成为在私有云，公共云以及混合云环境中大规模部署容器化应用程序的事实标准。业内最大的几家公有云平台`AWS`，`Google Cloud`，`Azure`，`IBM Cloud`以及`Oracle Cloud`现已提供`Kubernetes`托管服务。几年前，RedHat完全重写了他们的`Openshift`实现以适配`Kubernetes`，并且和`Kubernetes`社区一起合作实现了下一代容器平台。在Kubernetes变得受欢迎后不久，`Mesosphere`便将`Kubernetes`的主要功能（如容器分组，覆盖网络，4层路由，secret管理等）整合到他们的容器平台`DC/OS`中。`DC/OS`还将[`Kubernetes`作为一个和`Marathon`相似的容器调度器](https://mesosphere.com/blog/kubernetes-dcos/)集成进来。`Pivotal`最近推出了基于`Kubernetes`的[Pivotal Container Service（PKS）](https://pivotal.io/platform/pivotal-container-service)，用于在`Pivotal Cloud Foundry`上部署第三方服务，直到目前为止，还有很多其他组织和技术厂商处在一个加速适配它的阶段。

`Kubernetes`项目创立于2014年，它的背后是拥有在谷歌运行生产工作负载超过十年经验的谷歌内部容器集群管理平台Borg和Omega。在我看来，它让用户更加方便去适配一些新兴的软件架构模式（如微服务，无服务器功能，服务网格和事件驱动应用程序），并且为整个云原生系统生态铺平了道路。最重要的是，它的云不相关性的设计使得容器化的应用程序无需经过任何修改便可以跑在任何平台上。如今，大型企业的部署可以使用`Kubernetes`的生态系统，而从长远来看，任何中小型企业也可以通过使用`Kubernetes`节省大量的基础设施和维护成本。在这篇文章里，我将会介绍到`Kubernetes`整体上的架构，其应用程序的部署模型，服务发现和负载平衡，内部/外部路由分离，持久卷的使用，在节点上部署守护进程，部署有状态的分布式系统，运行后台作业，部署数据库，配置管理，凭据管理，滚动更新，自动伸缩以及包管理。

## Kubernetes架构

![](/static/imgs/k8s/k8s_struct.png)

这个接近完美的集群管理器采取的基本设计决策之一是能够部署在虚拟机上运行的现有应用程序，而无需对应用程序代码做出任何修改。从整体上来说，任何在虚拟机上运行的应用程序都可以通过简单地容器化其组件的方式部署在`Kubernetes`上。这是通过其核心功能实现的：容器分组，容器编排，覆盖网络，基于4层虚拟IP路由系统的容器间路由，服务发现，对运行守护程序的支持，部署有状态的应用程序组件，而且最重要的是，它还能够通过扩展容器编排器以支持复杂的编排要求。

从一个相对宏观的层面来讲，Kubernetes提供了**一组动态可扩展的主机**（node节点），用于承载运行工作负载的容器，并使用一组称为master的**管理主机**（master节点），提供用于管理整个容器基础设施的**API**。工作负载可能包括长期运行的服务，批处理作业和运行在特定容器主机上的守护程序。所有容器主机使用**覆盖网络**连接在一起以提供容器间的路由。部署在`Kubernetes`上的应用程序在集群网络是可以动态发现的，而且可以通过传统的负载均衡器暴露到外部网络。集群管理器的状态存放在**高度分布式组织的k/v存储里**（etcd），该存储运行在master实例上。

`Kubernetes scheduler`将始终确保每个应用程序组件都是经过健康检查的，提供高可用的服务，当副本数量设置为多个时，每个实例在多个主机上进行调度，并且如果其中一个主机变为不可用时，所有在该台主机上运行的容器都会被调度到剩余的其他主机。`Kubernetes`提供的一项迷人功能是两级自动扩缩。首先，通过使用一个叫做`Horizontal Pod Autoscaler`（Pod自动水平扩缩器）的资源，它可以为用户提供容器的自动扩缩功能，该资源将会监视资源的消耗并相应地扩展所需的容器数量。其次，它可以根据资源需求添加或删除主机来扩展容器集群本身。 此外，随着`集群联盟（cluster federation）`功能的引入，它甚至可以使用单个API端点管理一组`Kubernetes`集群，这些集群甚至可能跨越多个数据中心。

以上只是Kubernetes所提供的开箱即用的功能的概览。在接下来的几节里，本人将为你介绍`Kubernetes`的核心功能，并说明用户该如何设计自己的软件应用，以便能够立即部署在上面。

>方便理解，译者补充：
>
>- 控制管理器 (kube-controller-manager)。Controller 负责维护集群的状态，比如故障检测、自动扩展、滚动更新等
>- 调度器 (kube-scheduler)。Scheduler 负责资源的调度，按照预定的调度策略将 Pod 调度到相应的机器上

## 应用部署模型

![](/static/imgs/k8s/k8s_app.png)

上图展示的是`Kubernetes`宏观层面的应用程序部署模型。它使用一个叫做`ReplicaSet`的资源来编排容器。我们不妨将`ReplicaSet`视为基于YAML或基于JSON的一个*元数据文件*，该文件里定义了容器镜像，端口，副本数，激活运行状况检查（health check），存活状况检查（liveness health check），环境变量，挂载卷以及创建和管理容器所需的一些安全规则。在`Kubernetes`上，容器总是以所谓`Pods`的形式成组创建，它是`Kubernetes`的一个元数据定义或者说是一个资源。每个pod允许在使用了`Linux namespace`，`cgroup`和其他内核功能的容器之间共享文件系统，网络接口和操作系统用户。`ReplicaSet`可以由另外一个名为`Deployments`的高级资源管理，它被设计用于提供*滚动更新*和*处理回滚*等功能。

通过执行下面这样一条简单的CLI命令，用户便可以通过定义一个`deployment`，在`Kubernetes`上部署一个容器化的应用程序：

```bash
kubectl run <application-name> --image=<container-image> --port=<port-no>
```

执行上述CLI命令后，它将使用给定的容器镜像创建一个`Deployment`声明，一个副本集以及一个采用了指定容器镜像的Pod；添加一个应用名的选择器标签。根据当前的设计，由此创建的每个pod将会拥有两个容器，一个用于指定的应用程序组件，另外一个即所谓的pause容器，用于连接网络接口。

## 服务发现 & 负载均衡

![](/static/imgs/k8s/k8s_lb.png)

`Kubernetes`的一个关键特性便是由*SkyDNS*和*4层虚拟IP路由系统*提供的服务发现和内部路由模型。这些功能可以为面向service的应用请求提供内部路由。可以使用集群网络里的service对通过副本集创建的一组pod提供负载平衡。service使用选择器标签连接到pod。每个service都将会分配一个唯一的IP地址，一个由它的名称派生出的主机名，并且将会以round robin的方式路由pods的请求。这些service甚至可以为可能需要支持会话亲和性的应用程序提供基于IP哈希的路由机制。service可以指定一组端口，而针对指定的service定义的一系列属性将会以相同的形式同样应用到所有端口上。因此，如果只是某个给定端口需要支持会话亲和性，而所有的其他端口只需要round robin的方式路由的情况下，可能需要用到多个service。

## service内部工作原理

![](/static/imgs/k8s/k8s_service_work.png)

`Kubernetes service`背后是通过一个叫做kube-proxy的组件实现。`kube-proxy`实例运行在每个节点上，并提供了三种代理模式：userspace，iptables和IPVS。目前的默认值是iptables。

在userspace模式下，kube-proxy本身将充当代理服务器的角色，并且将被一条iptable规则接受的请求代理到后端pod。在这种模式下，kube-proxy将在用户空间中运行，并且将会在消息流上额外增加一跳（hop）。

在iptables模式下，kube-proxy将创建一个iptable规则集合，用于将来自客户端的入口请求在网络层面直接转发到后端pod的端口上，而不会在中间额外增加一跳。这种代理模式比第一种模式快得多，因为它是在内核空间中操作而不是在中间增加一台额外的代理服务器。

第三种代理模式是在Kubernetes v1.8中添加的，它和第二种代理模式非常相似，该模式使用的是基于IPVS的虚拟服务器来路由请求，而无需用到iptable规则。IPVS是一个传输层的负载均衡功能，可以在基于Netfilter的Linux内核中使用，并且提供了一组负载均衡算法。在iptables上使用IPVS的主要原因是在使用iptables时同步代理规则带来的性能开销。当创建数千个service时，更新iptable规则需要相当长的时间，相比之下，使用IPVS只需几毫秒。此外，IPVS使用哈希表线性的扫描iptables来查找代理规则。有关介绍IPVS代理模式的更多信息，请参阅华为在KubeCon 2017上的“[Scaling Kubernetes to Support 50,000 Services](https://docs.google.com/presentation/d/1BaIAywY2qqeHtyGZtlyAp89JIZs59MZLKcFLxKE6LyM/edit#slide=id.p3)”演示文稿。

## 内外路由分离

![](/static/imgs/k8s/k8s_route.png)

`Kubernetes service`可以通过两种主流方式暴露给外部网络。第一种是使用节点端口（node port），通过暴露节点上的动态端口，这些端口会将流量转发到service端口。第二种是使用一个ingress controller配置的负载均衡器，它将会连接到同一个覆盖网络并将请求代理给service。ingress controller是一个后台进程，它可以跑在容器里，该容器将会监听`Kubernetes API`，根据指定的一组ingress动态配置并重新加载给定的负载均衡器。一个ingress定义了一组基于service的主机名及上下文路径的路由规则。

一旦通过执行kubectl run命令，在Kubernetes上跑起来应用后，我们可以通过一个负载均衡器将其暴露给外部网络，如下所示：

```
kubectl expose deployment <application-name> --type=LoadBalancer --name=<service-name>
```

上述命令将创建一个负载均衡器类型的service，并且使用在POD创建之初建立的选择器标签映射到相同的一组pod。这样一来，根据Kubernetes集群不同的配置方式，一个负载均衡器类型的service将会在底层基础设施上创建出来，通过service或直接路由的形式将请求转发到指定的一组pod。

## 持久卷用法

![](/static/imgs/k8s/k8s_volume.png)

需要在文件系统上持久化存储数据的应用程序可以使用卷将存储设备挂载到临时容器，这和虚拟机的使用方式类似。Kubernetes巧妙地重新设计了这一概念，通过引入一个所谓的持久卷声明（PVC）的中间资源，在物理存储设备和容器之间做了解耦。一个PVC定义了磁盘大小，磁盘类型（ReadWriteOnce，ReadOnlyMany，ReadWriteMany），并将存储设备动态链接到在pod中定义了的卷。该绑定过程可以使用PV这样一个静态的形式，也可以使用一个持久化存储的provider动态实现。在这两种方法里，卷将一对一地链接到PV，并且取决于其配置，给定的数据即便pod被终止也将会被保留。根据使用的磁盘类型，多个pod将能够连接到同一磁盘并进行读/写。

支持ReadWriteOnce的磁盘将只能连接到单个pod，并且无法同时在多个pod之间共享。但是，支持ReadOnlyMany的磁盘将能够在只读模式下同时在多个pod之间共享。相反地，顾名思义，支持ReadWriteMany的磁盘可以连接到多个pod，以便在读写模式下共享数据。 Kubernetes提供了一系列的卷插件，用于支持公有云平台上可用的存储服务，例如AWS EBS，GCE Peristent Disk，Azure File，Azure Disk和许多其他众所周知的存储系统，如NFS，Glusterfs，Cinder等。

## 在节点上部署守护程序

![](/static/imgs/k8s/k8s_daemon.png)

Kubernetes提供了一个名为DaemonSets的资源，用于在每个Kubernetes节点上以守护进程的形式运行pod的副本。DaemonSets的一些用例如下：

- 需要部署到每个节点上提供持久化存储的集群存储守护程序（如glusterd，ceph）。
- 需要在每个节点上运行的监控容器宿主机的节点监控守护程序，例如Prometheus Node Exporter。
- 需要在每个节点上运行的，用作采集容器及Kubernetes组件日志的日志采集守护程序，例如fluentd或是logstash。
- 需要在一组节点上运行的提供外部路由的ingress controll pod

## 部署有状态的分布式系统

![](/static/imgs/k8s/k8s_deploy.png)

容器化应用程序最艰巨的任务之一莫过于设计有状态分布式组件部署架构的流程。无状态组件可以很容易地进行容器化，因为它们可能没有预定的启动顺序，集群要求，点对点的TCP连接，唯一的网络标识符，优雅的启动和终止需求等。像数据库，大数据分析系统，分布式k/v存储以及消息代理这样的系统，可能拥有需要支持上述这些功能的复杂分布式架构。Kubernetes引入了StatefulSets资源来解决这些复杂的需求。

从整体上来说，StatefulSets类似于ReplicaSet，除了提供处理pod的启动顺序的能力，唯一地标识每个pod以保留其状态之外，它还同时提供以下特性：

- 稳定，唯一的网络标识符。
- 稳定，持久化的存储。
- 有序，优雅的部署和扩容。
- 有序，优雅的删除和终止。
- 有序，自动地滚动更新

这里面的“稳定”指的是在跨pod重新调度时它将会保留网络标识符和持久化存储。如上图所示，唯一的网络标识符可以通过使用headless service提供。Kubernetes提供了一些StatefulSets的示例，包括以分布式的形式部署Cassandra以及Zookeeper。

## 执行后台任务

除了ReplicaSet和StatefulSets之外，Kubernetes还提供了两个额外的控制器，用于在后台运行称为Jobs和CronJobs的工作负载。Jobs和CronJobs之间的区别在于Jobs执行一次即终止，而CronJobs会按照与标准Linux cron作业类似的给定时间间隔
定期地执行。

## 部署数据库

由于存在对集群，点对点连接，复制同步，灰度，备份管理等需求，在容器平台上部署数据库用于生产环境将会比部署应用程序稍微困难一些。正如之前所提到的那样，Statefulsets专门为解决此类复杂需求而设计，而如今已经有一些在Kubernetes上运行PostgreSQL和MongoDB集群的方案。YouTube的数据库集群系统Vitess现如今已经是一个CNCF项目，对于在Kubernetes上大规模灰度运行MySQL是一个很好的选择。说是如此，我们最好注意一下，这些方案目前仍然处于非常早期的开发阶段，而如果现有的生产级别数据库系统，仍然可用于给定的基础架构，例如AWS上的RDS，GCP上的Cloud SQL，或是内部按需部署的数据库集群，考虑到安装的复杂性以及维护成本，选择这其中的一种方案可能更合适些。

## 配置管理

容器通常使用环境变量来参数化它们的运行时配置。但是，常见的企业应用程序往往使用大量的配置文件为一个指定的部署提供所需的静态配置。Kubernetes则提供了一个绝妙的办法，使用名为ConfigMaps的一种简单资源来管理此类配置文件，而无需将它们打包到容器镜像里。可以通过执行以下CLI命令，使用目录，文件或文本值创建ConfigMaps：

```
kubectl create configmap <map-name> <data-source>
# map-name: name of the config map
# data-source: directory, file or literal value
```

创建ConfigMap后，可以通过卷的形式将其挂载到pod。通过这种松耦合的架构，一个已经在运行的系统的配置可以通过更新相关的ConfigMaps的方式无缝更新，而其滚动更新的执行流程这块我将在下一节中详细说明。值得一提的是，ConfigMaps现在不支持嵌套的目录结构；因此，如果应用程序的嵌套目录结构中存放有配置文件的话，则需要为每一个目录层级创建一个ConfigMap。

## 凭证管理

与ConfigMaps类似，Kubernetes提供了另一种名为Secrets的宝贵资源，用于管理密码，OAuth令牌和ssh密钥等敏感信息。否则，在已运行的系统上更新该信息可能需要重建容器镜像。

可以使用以下方式创建用于管理基本身份验证凭据的密钥：

```
# write credentials to two files
$ echo -n 'admin' > ./username.txt
$ echo -n '1f2d1e2e67df' > ./password.txt
# create a secret
$ kubectl create secret generic app-credentials --from-file=./username.txt --from-file=./password.txt
```

创建secret后，pod可以使用环境变量或挂载卷的方式来读取它。类似地，可以使用相同的方法将任何其他类型的敏感信息注入到pod中。

## 滚动更新

![](/static/imgs/k8s/k8s_rollback.gif)

上面这个动画描述了如何使用蓝/绿部署的方法为已经运行的应用程序发布应用程序更新，而无需任何宕机成本。这是Kubernetes提供的另一个重磅功能，它允许应用程序不费吹灰之力即可无缝地发布安全更新和向后兼容的变更。如果变更不向后兼容，则可能需要使用单独的部署定义手动执行蓝/绿部署。

这一方案允许通过一条简单的CLI命令，发起一个部署以更新容器镜像：

```
$ kubectl set image deployment/<application-name> <container-name>=<container-image-name>:<new-version>
```
一旦发起部署，可以通过如下方式检查部署进度的状态：

```
$ kubectl rollout status deployment/<application-name>Waiting for rollout to finish: 2 out of 3 new replicas have been updated...deployment "<application-name>" successfully rolled out
```

使用相同的CLI命令kubectl set image deployment，可以让部署更新回滚到之前的状态。

## 自动扩缩

![](/static/imgs/k8s/k8s_scaling.png)

Kubernetes允许使用ReplicaSet或Deployments手动调整pod数量。这可以通过执行如下CLI命令来实现：

```
kubectl scale --replicas=<desired-instance-count> deployment/<application-name>
```
如上图所示，可以通过向Deployment添加另一个名为Horizontal Pod Autoscaler（HPA）的资源来扩展此功能，以便根据实际资源使用情况动态扩缩容器。HPA将通过资源指标的API监视每个pod的资源使用情况，并通知Deployment相应地更改ReplicaSet的副本数。Kubernetes使用高档延迟（upscale delay）和缩减延迟（downscale delay）来避免某些情况下频繁的资源使用波动而可能导致的颠簸。目前，HPA仅支持基于CPU的使用情况进行扩展。如果有必要的话，还可以通过Custom Metrics API加入自定义指标，这具体视应用程序的自然属性而定。

## 包管理

![](/static/imgs/k8s/k8s_package_m.png)

Kubernetes社区发起了一个单独的项目，为Kubernetes实现了一个称为Helm的包管理器。它允许用户使用一个名为Chart的资源模板化并打包Kubernetes资源，比如Deployment，Service，ConfigMap，Ingress等，并允许在安装时使用输入参数配置它们。更重要的是，它允许在使用依赖项实现包的安装时复用现有图表。Helm存储库可以托管在公有云或私有云环境中，用于管理应用程序的Chart。Helm提供了一个CLI，用于从给定的Helm存储库里安装应用程序到指定的Kubernetes环境中。

一些众所周知的软件应用程序的各种稳定Helm图表可以在它的Github存储库中找到，也可以在中心化的Helm服务器中找到：Kubeapps Hub。

## 小结

Kubernetes的设计源自于Google内部大规模运行容器化应用程序十多年来积累的经验。它已经被一些顶级的公有云厂商和技术厂商采用，并且在撰写本文时正在被更多的软件厂商和企业所接受。 它甚至促成了2015年云原生计算基金会（CNCF）的成立，并且是第一个在CNCF下毕业的项目，随后开始了同其他与容器相关的项目一起精简容器生态系统的道路，如CNI，Containerd，Envoy，Fluentd，gRPC，Jagger，Linkerd，Prometheus，rkt和Vitess。 Kubernetes受欢迎并得到如此认可的关键原因可能源自其完美的设计，与行业领导者的合作，其开源属性，以及始终对创意和贡献持开放态度的精神。

## 参考文献

- [1] What is Kubernetes: https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/
- [2] Borg, Omega and Kubernetes: https://ai.google/research/pubs/pub44843
- [3] Kubernetes Components: https://kubernetes.io/docs/concepts/overview/components/
- [4] Kubernetes Services: https://kubernetes.io/docs/concepts/services-networking/service/
- [5] IPVS (IP Virtual Server) http://www.linuxvirtualserver.org/software/ipvs.html
- [6] Introduction of IPVS Proxy Mode: https://github.com/kubernetes/kubernetes/issues/44063
- [7] Kubernetes Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- [8] Kubernetes Configuration Best Practices: https://kubernetes.io/docs/concepts/configuration/overview/
- [9] Customer Resources & Custom Controllers: https://kubernetes.io/docs/concepts/api-extension/custom-resources/
- [10] Understanding Vitess: https://vitess.io/overview/
- [11] Skaffold, CI/CD for Kubernetes: https://github.com/GoogleContainerTools/skaffold
- [12] Kaniko, Build Container Images in Kubernetes: https://github.com/GoogleContainerTools/kaniko
- [13] Apache Spark 2.3 with Native Kubernetes Support https://kubernetes.io/blog/2018/03/apache-spark-23-with-native-kubernetes/
- [14] Deploying Apache Kafka using StatefulSets: https://github.com/kubernetes/contrib/tree/master/statefulsets/kafka
- [15] Deploying Apache Zookeeper using StatefulSets: https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper