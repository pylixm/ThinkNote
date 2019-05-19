---
layout : post
title : "资源分享计划第四期 0518"
categories: [资源分享计划,] 
date : 2019-05-18
url: /posts/2019-05-18-share-resource.html 
tags : [资源分享计划]
---

>「资源分享计划」系列记录本周内我看到的一些好的编程学习资源及优秀的技术文章，在自己学习记录的同时，分享给大家希望对大家有帮助。

## 资源类

### 有赞前端团队开源的一套vue.js 移动端插件库

有赞前端团队开源的一套vue.jd的移动端插件库，使用vue_cli3构建，组件样式清新美观，可自定义主题。还有一个配套的小程序组件库。

> https://github.com/youzan/vant

### 一个python新闻的播客

`PythonBytes` 是一个python相关的博客网站，他会每周推送一些reddit、twitter等网站上的一些python相关新闻。作为播客，它的所有新闻都配有英语音频。

> python播客： https://pythonbytes.fm/

### python 入门路径指南

Realpython出品的python 入门路径指南，为入门python的新手指明了职业发展路径，大家可根据自己的兴趣爱好，选择路径对应的技术深入学习。

> https://realpython.com/learning-paths/?__s=qr4xvq2paygs9f8msmo8

### python 官方推出的一个强格式化工具 Black 
 
官方推出的一个强格式化工具，它是一年之前推出的，现在仍处于快速开发优化阶段。Django的[DEP0080](https://github.com/django/deps/blob/master/accepted/0008-black.rst#motivation)建议使用Black来强制格式化代码，最近已经被移到接受的目录中，待Black稳定后，便实施。各位Django 的开发者或要学习的开发者，可以提前看下这个库。

> https://github.com/python/black
 

## 文章类

### 如何选择合适的python docker 镜像

Docker 技术现在项目部署中，已相当的成熟。在使用docker技术部署的时候，docker镜像的大小，会对容器的启动速度有一定的影响。所以，在实际的生产环境中，镜像的体系越小越好。[DockerHub](https://hub.docker.com/)官方镜像仓库，给我提供了很多直接可用的镜像，还有许多开发者自己打包的镜像。在Python项目中，应该如何选择呢？这篇文章对常用镜像做了比较，并得出了Python项目的最佳选择。

> 原文地址：https://pythonspeed.com/articles/base-image-python-docker-images/
>
> PDF版链接：https://pan.baidu.com/s/1Tql7bb_1EWx6vboXGjK2gg 提取码: pss9 

### Python 子解释器

GIL锁让Python的多线程变得简单，在编写多线程代码的时候，不必考虑系统级别的互斥锁和进程的死锁。但是，它并不是真正的并发，同一时间，只能有一个线程在执行。为了解决这个问题，[PEP554](https://www.python.org/dev/peps/pep-0554/)提供了一种方案，在进程和线程之间增加了一层子解释器的概念，每个解释器拥有自己的GIL。该方案现仍在讨论中，有兴趣的可关注。

> 原文地址：https://medium.com/@anthonypjshaw/9440d28fa93d
>
> PDF版 链接: https://pan.baidu.com/s/10IZR2-98iCtUcTgeOsJBUA 提取码: yxnp 


### python 3+ 你应该使用的一些技巧

本文列举了一些实用的Python3的技巧，这些在我们的日常开发中经常会用到。但是，我们都习惯性的采用了python2的实现写法。实际上python3提供给我们了更好的实现写法。

> 原文地址：https://datawhatnow.com/things-you-are-probably-not-using-in-python-3-but-should/
> 
> 翻译：https://pylixm.cc/posts/2019-05-16-python-trick.html

### 构建可扩展的机器学习模型

如何构建可扩展的机器学习模型？

> 原文地址：https://www.codementor.io/blog/scalable-ml-models-6rvtbf8dsd?utm_content=posts&utm_source=sendgrid&utm_medium=email&utm_term=post-6rvtbf8dsd&utm_campaign=newsletter20190515
>
> PDF版 链接: https://pan.baidu.com/s/1wY3Lny2rKirFv87KYRmaTQ 提取码: 3zba 
