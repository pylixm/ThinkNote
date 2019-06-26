---
layout : post
title : 「译」如何选择python项目的基础docker镜像
categories: [Python,] 
date : 2019-06-26
url: /posts/2019-06-26-base-image-python-docker-images.html 
tags : [Python, Docker, 翻译]
---

> 最近在鼓捣自己的`sideproject`时，对如何选择Docker镜像犹豫了半天，这里找到了一片比较详细的选择基础镜像的考量，翻译记录，仅供参考。
> 原文作者：Itamar Turner-Trauring
> 原文地址：https://pythonspeed.com/articles/base-image-python-docker-images/


当您为Python应用程序构建Docker镜像时，您将构建在现有图像之上 - 并且有许多可能的选择。有像Ubuntu和CentOS这样的操作系统映像，并且有许多不同的python基本映像变体。

你应该使用哪一个？哪一个更好？有很多选择，可能并不明显哪种情况最适合您的情况。

因此，为了帮助您做出符合您需求的选择，在本文中，我将介绍一些相关标准，并建议一些适用于大多数人的合理默认值。

您想从基本图像中得到什么？
选择基本图像有许多常用标准，但您的特定情况可能会强调，添加或删除其中一些：

稳定性：您希望今天的构建能够为您提供与明天构建相同的基本库，目录结构和基础结构，否则您的应用程序将随机中断。
安全更新：您希望基础映像得到良好维护，以便及时获得基本操作系统的安全更新。
最新的依赖关系：除非您构建一个非常简单的应用程序，否则您可能依赖于操作系统安装的库和应用程序（例如编译器）。你希望他们不要太老。
广泛的依赖关系：对于某些应用程序，可能需要不太流行的依赖关系 - 可以访问大量库的基本映像使这更容易。
最新的Python：虽然可以通过自己安装Python来解决这个问题，但拥有最新的Python可以节省您的工作量。
小图像：在所有条件相同的情况下，拥有较小的Docker镜像比使用更大的Docker镜像更好。
对稳定性的需求表明不使用支持生命周期有限的操作系统，如Fedora或非LTS Ubuntu版本。

选项＃1：Ubuntu LTS，CentOS，Debian
有三种主要操作系统大致符合上述标准（日期和发布版本在撰写时是准确的;时间的流逝可能需要稍微不同的选择）。

Ubuntu 18.04（ubuntu:18.04图像）于2018年4月发布，由于它是长期支持版本，它将在2023年之前获得安全更新。
CentOS 7.6（centos:7.6.1810）于2018年10月发布，将在2020年第四季度完成更新，维护更新至2024年。目前正在开发 CentOS 8 ，基于2019年5月发布的RHEL 8。
Debian 9（又名“Stretch”）于2017年发布，到2020年更新，LTS支持到2022年。您可以通过backport获得更新的软件包，但backports 无法保证安全更新。Debian 10（“Buster”）应该会在2019年7月发布。
所有这些图像的一个问题是，如果你想要最新版本的Python，你必须自己安装它。

选项＃2：Python Docker镜像
另一个替代方案是Docker python镜像，它预先安装了特定版本的Python，并且有多种变体。对于我们的目的，有趣的是：

Alpine Linux，最初是为小型设备设计的操作系统，因此往往有小包装。
Debian Stretch，安装了许多常见软件包。图像本身很大，但理论上这些软件包是通过其他Docker镜像将使用的公共图像层安装的，因此整体磁盘使用率会很低。
Debian Stretch超薄款。这缺少了通用软件包的层，因此图像本身要小得多，但如果你使用Stretch以外的许多其他Docker镜像，整体磁盘使用量会更高一些。
一旦巴斯特于2019年7月上映，希望新的python图像将从巴斯特重建。

为什么你不应该使用Alpine Linux
对于想要小图像的人来说，一个常见的建议是使用Alpine Linux，但使用它会产生一些成本。首先，Alpine的库比我上面提到的其他Linux发行版少得多，因此您可能会缺少库。

Alpine和其他Linux发行版之间也存在重大差异：Alpine使用不同的C库，而不是更常见的glibc。 理论上，musl和glibc 大多是兼容的，但这些差异可能会导致问题，当问题确实发生时，它们会变得奇怪和意外。

一些例子：

Alpine具有较小的线程默认堆栈大小，这可能导致Python崩溃。
一位Alpine用户发现他们的Python应用程序因为musl分配内存与glibc的方式而慢得多。
在使用WeWork共享空间的WiFi时，我曾经无法在minikube（VM中的Kubernetes）上运行的Alpine图像中进行DNS查找。原因是WeWork的糟糕DNS设置，Kubernetes和minikube做DNS的方式，以及musl对这个边缘案例的处理与glibc的处理。musl没有错（它与RFC相匹配），但我不得不浪费时间找出问题，然后切换到基于glibc的图像。
另一位用户发现了时间格式化和解析的问题。
大多数这些问题已经得到解决，但毫无疑问需要发现更多问题。这种随机破损只是需要担心的一件事 - 而略小的图像的相应好处是不值得的。 因此，我建议不要使用Alpine。

那你应该怎么用？
直接使用Debian Stretch毫无意义，因为在pythonStretch上安装了最新Python的基本映像。

截至2019年6月：

python:3.7-slim-stretch或者python:3.7-stretch（或者你使用的任何Python版本而不是3.7）是一个合理的起点。我怀疑对于大多数人而言，slim变体将导致整体更小的磁盘使用量。
如果你需要比Debian Stretch提供的更新的库或编译器，你可能想要使用ubuntu:18.04，它比CentOS更新。
一旦发布了Debian Buster，python图像可能会有一个buster明显的胜利者：它将预装新版本的Python和等效或更新的软件包ubuntu:18.04。
当2020年4月到来时，ubuntu:20.04将率先拥有最新的软件包。
进一步了解 - 阅读用于Python的Docker包装指南的其余部分。