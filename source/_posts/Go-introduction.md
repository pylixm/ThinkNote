---
layout : post
title : 【 Go语言学习笔记 】 - Golang 初步了解
category : golang
date : 2018-01-24
tags : 
  - golang
  - 语言学习
---

## 前言

第一次听说 Golang 语言是通过小米开源的 Open-Falcon ，它是用 Go 开发的，速度上是python的好几倍，天生适合并发程序的开发。后来得知大名鼎鼎的 Dorker 也是用 Golang 开发的,便是对这么语言产生了浓厚的兴趣。一直想学习下，拖到现在，有些闲空，便深入的学习下。

《程序员修炼之道》中有这么一个观点：程序员每年要学习一门语言。这个我也是极力赞同的，只有通过不同语言的对比，你才会加深对语言本身的理解，在业务逻辑中充分发挥语言的特性，不会一味的只关心业务逻辑。 

当然不同角色的程序员的侧重点不同，”对于大多数的程序员来说，其实我们只需要关注问题域；做底层平台开发的，关注机器模型、通信原理 以及OS原理和实现细节；做算法的，很荣幸，那才是正统的程序设计的核心；前端攻城师则更多关注用户的体验。“（引自[关于编程语言学习的一些体会](https://studygolang.com/articles/1975)）。

所以说，我们在学习语言的时候也不要过于钻牛角尖，只要学以致用便好。即使不能立即在工作中使用，语言中的思想也会潜移默化的影响我们，当遇到合适的场景时，便可发挥相应语言的长处，解决实际业务中的问题。语言只不过是工具，我们要做到一门精通，其他拿来可用便好。


## 简介

Go，又称 golang，是 Google 开发的一种静态强类型，编译型，并发型，并具有垃圾回收功能的开源编程语言。

Go 语言于2009年11月正式宣布推出，自2012年发布1.0，最新稳定版1.9.3, 国内官方文档地址：https://golang.google.cn/ 。目前，Go的相关工具和生态已逐渐趋于完善，也不乏重量级项目，如 Docker, Kubernetes, Etcd, InfluxDB 等。

下图为 Go 语言的起源：
![](/images/go_history.png)

其他更多，见这里 [《The way to go》- Go 语言的起源，发展与普及](https://github.com/Unknwon/the-way-to-go_ZH_CN/blob/master/eBook/01.1.md)

### Golang 的特点 

- 静态类型、编译性、开源。
- 脚本话语法，支持多种编程范式：函数式、面向对象编程。
- 原生支持并发编程，不同于通过函数库支持。

### Golang 设计目标及解决的问题 

- 将静态语言的安全性和高效性与动态语言的易开发性进行有机结合，达到完美平衡，从而使编程变得更加有乐趣，而不是在艰难抉择中痛苦前行。
- 对于网络通信、并发和并行编程的极佳支持，从而更好地利用大量的分布式和多核的计算机。
- 高效的构建速度，不必浪费大量的时间在等待程序的构建上。
- 通过采用包模型，严格的依赖关系检查机制来加快程序构建的速度。
- 实现高效快速的垃圾回收（使用了一个简单的标记-清除算法）
- Go 语言还能够在运行时进行反射相关的操作。

更多语言特性，请这里：[语言的主要特性与发展的环境和影响因素](https://github.com/Unknwon/the-way-to-go_ZH_CN/blob/master/eBook/01.2.md#125-%E8%AF%AD%E8%A8%80%E7%9A%84%E7%89%B9%E6%80%A7)

### Golang 优点与缺点

#### 优点
- 脚本化的语法，新手可以很容易上手。
- 静态类型和编译性，保证了运行效率
- 原生支持并发编程，可以更容易的编写并发程序，降低了开发和维护成本。

#### 缺点 
- 语法糖少、第三方库较少。
- 语言设计上的特性缺陷，见[这里](https://github.com/Unknwon/the-way-to-go_ZH_CN/blob/master/eBook/01.2.md#127-%E5%85%B3%E4%BA%8E%E7%89%B9%E6%80%A7%E7%BC%BA%E5%A4%B1)

- 为了避免各种依赖问题，golang将runtime 一块打包进了二进制文件，导致文件体积大，部署比较困难。
- golang 语言的错误处理机制。（ // TODO 待考究 ）


### Golang 与 Python 比较的优点 

这里引用一段[知乎](https://www.zhihu.com/question/21409296)上某大牛的回答，如下：

**1.部署简单。** Go 编译生成的是一个静态可执行文件，除了 glibc 外没有其他外部依赖。这让部署变得异常方便：目标机器上只需要一个基础的系统和必要的管理、监控工具，完全不需要操心应用所需的各种包、库的依赖关系，大大减轻了维护的负担。这和 Python 有着巨大的区别。由于历史的原因，Python 的部署工具生态相当混乱【比如 setuptools, distutils, pip, buildout 的不同适用场合以及兼容性问题】。官方 PyPI 源又经常出问题，需要搭建私有镜像，而维护这个镜像又要花费不少时间和精力。
**2.并发性好。** Goroutine 和 channel 使得编写高并发的服务端软件变得相当容易，很多情况下完全不需要考虑锁机制以及由此带来的各种问题。单个 Go 应用也能有效的利用多个 CPU 核，并行执行的性能好。这和 Python 也是天壤之比。多线程和多进程的服务端程序编写起来并不简单，而且由于全局锁 GIL 的原因，多线程的 Python 程序并不能有效利用多核，只能用多进程的方式部署；如果用标准库里的 multiprocessing 包又会对监控和管理造成不少的挑战【我们用的 supervisor 管理进程，对 fork 支持不好】。部署 Python 应用的时候通常是每个 CPU 核部署一个应用，这会造成不少资源的浪费，比如假设某个 Python 应用启动后需要占用 100MB 内存，而服务器有 32 个 CPU 核，那么留一个核给系统、运行 31 个应用副本就要浪费 3GB 的内存资源。
**3.良好的语言设计。** 从学术的角度讲 Go 语言其实非常平庸，不支持许多高级的语言特性；但从工程的角度讲，Go 的设计是非常优秀的：规范足够简单灵活，有其他语言基础的程序员都能迅速上手。更重要的是 Go 自带完善的工具链，大大提高了团队协作的一致性。比如 gofmt 自动排版 Go 代码，很大程度上杜绝了不同人写的代码排版风格不一致的问题。把编辑器配置成在编辑存档的时候自动运行 gofmt，这样在编写代码的时候可以随意摆放位置，存档的时候自动变成正确排版的代码。此外还有 gofix, govet 等非常有用的工具。
**4.执行性能好。** 虽然不如 C 和 Java，但通常比原生 Python 应用还是高一个数量级的，适合编写一些瓶颈业务。内存占用也非常省。

## 小结 

通过阅读基本 Golang 入门的书籍，基本了解了 Golang 诞生的时机，及语言的特性、主要解决的问题和专注的方向，总结如下：

- 诞生时机：人们需要一门 介于 C/C++ 和高级语言之间的新语言，既有C/C++的安全高效，又有高级语言的便捷性。

- 语言特性：高效、代码简洁、格式统一、并发性、垃圾回收。

- 主要解决问题：解决了部分系统语言与高级语言特性结合问题，如：运行性能、开发效率及维护难度。

- 专注方向：后台分布式、高并发中间件系统开发。


## 引申阅读

- [Go的50度灰：Golang新开发者要注意的陷阱和常见错误](http://outofmemory.cn/golang/golang-beginer-note)
- [Go的50度灰：Golang新开发者要注意的陷阱和常见错误- 英文原版](http://devs.cloudimmunity.com/gotchas-and-common-mistakes-in-go-golang/)


## 参考

- [Python 程序员的 Golang 学习指南（I）: Go 之初体验](https://startover.github.io/articles/2016/08/15/golang-for-pythonistas/)
- [The way to Go: 起源与发展](https://github.com/Unknwon/the-way-to-go_ZH_CN/blob/master/eBook/01.1.md)
- [视频：Go语言第一课 郝林](https://www.imooc.com/learn/345)
