---
layout : post
title : "资源分享计划第一期 0427"
categories: [资源分享计划,] 
date : 2019-04-27
url: /posts/2019-04-29-share-resource.html 
tags : [资源分享计划]
---

>「资源分享计划」系列记录本周内我看到的一些好的Python学习资源及优秀的技术文章，在自己学习记录的同时，分享给大家希望对大家有帮助。

## 资源类

### 1、一本可同时学习R和Python的书籍

R 和 Python 语言一直是数据分析领域的明星语言，同时又是竞争语言。新入门的同学往往为应该用哪门语言而纠结，这里有一本同时讲解 R 和Python 的书籍，可为你排忧解难: 

  - https://github.com/rnorm/book_sample/blob/master/learn_R_Python_in_parallel.pdf


### 2、Python调试的选新选择：pysnooper

在Python编程中，除了使用IDE的调试功能和程序自带的pdb调试外，我们用的最多的就是`print`打印了。这里有了另一种选择，一个新的Python代码调试库 `pysnooper`, 只需要在我们要调试的代码函数上加描述器，即可实现打印代码执行情况及变量栈，大家可以尝试。

  - https://github.com/cool-RR/pysnooper


### 3、Google 制作的节奏紧凑、内容实用的机器学习简介课程

毫无疑问，机器学习是当今市场上最受欢迎的技术。这里是Google公司制作的一个机器学习的简介课程，关键的是`无效翻墙`。

  - https://developers.google.cn/machine-learning/crash-course/ml-intro


## 文章类

### 1、RealPython 的一篇Python time 模块的讲解

它主要讲解了time模块的使用，包括时区、UTC及各类型与时间转换，非常详细（需翻墙）。

  - https://realpython.com/python-time-module/


### 2、10篇机器学习的经典文章 

本文整理了10篇使用Python来进行机器学习的文章，Python系的同学可以参考：

  - https://www.coriers.com/10-great-articles-on-python-programming-machine-learning-and-its-future/

### 3、机器学习基础介绍

文章介绍了机器学习的3连问，为什么、是什么、怎么做。还附带有R语言的实例代码，可谓快速了解机器学习的好资料。

 - https://www.codementor.io/zulaikhageer/introduction-to-machine-learning-machine-learning-basics-u9jnkzsjc


### 4、django restful api demo

文章手把手的带你使用django restful 框架构建一个问答系统的api，是学习 django restful api 的不错的demo。

  - https://www.agiliq.com/blog/2019/04/drf-polls/


## 热点随想

本周 Bilibili 的主站后台代码泄露一事，可谓是沸沸扬扬。抛开事件本身不谈，我们从中又能得到那些警示呢。我结合个人工作经历总结了几点，希望和大家共勉。

- 首先，还是增强整体团队的安全意识，从根本上解决问题。外界的规则及措施，只能起到限制作用。有时还会适得其反，让员工厌恶。
- 其次，制定各种安全事故的应急方案，遇到问题及时处理，最大化的止损，防止事故的扩大化。
- 最后，从我们编程人员自身角度看，在构建代码的时候，多考虑安全因素，包括人为事故或者外部的攻击，增加工程的健壮性。

