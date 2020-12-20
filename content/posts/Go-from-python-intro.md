---
type : posts
title : 「对比Python学习Go」- 开篇
categories: [Golang,] 
series: [对比Python学习Go,]
date : 2020-12-02
url: /posts/2020-12-02-go-from-python-intro.html 
tags : [Golang, 对比Python学习Go]
---

> 文章首发公众号「CoderMrWu」，欢迎关注订阅！
## 前言

当前Go语言已然成为很多后端项目的主力语言，在互联官网企业开发中甚至有和Java一较高下的趋势。Go 语言也属于静态语言，与Java类似，需要先编译后执行，但它性能更好，天生支持并发。与Python这种动态语言相比，灵活性不足，但它优秀的性能并发性，也成为很多基础设施保障类系统青睐的语言。

工作中一直使用Python作为主力语言，主要是web相关的开发，也涉猎后端大型分布式集群管理系统开发。最近几年，公司部分系统使用了Go语言作为开发语言，有幸参与其中，对Go语言有了实践的机会。老实说，用习惯了Python再去写Go的代码时，会多少带着原来语言的思路而忽视了语言本身的特性，写出四不像的代码。这便是这个系列文章的由来，想把Python和Golang 的一些语法做一个对比，方便使用的时候做查询。其次，放一块对比，也方便记忆。

编程语言很多，掌握其中一门作为自己的主语言，其他作为辅助，在实现具体产品需求时，能够快速学习使用，落地到生产中。这是我的对编程语言的一个基本想法。

Python 动态语言，灵活方便，适合快速实现需求。Go 静态语言，严谨高性能，适合构建高质量的服务。一动一静，相辅相成。

## 文章计划

文章计划如下：

- [「对比Python学习Go」- 基础篇(环境搭建及相关概念)](https://pylixm.top/posts/2020-12-03-go-from-python-start.html)
- [「对比Python学习Go」- 基本数据结构](https://pylixm.top/posts/2020-12-05-go-from-python-structure-base.html)
- [「对比Python学习Go」- 高级数据结构](https://pylixm.top/posts/2020-12-09-go-from-python-structure-advance.html)
- 「对比Python学习Go」- 流程控制
- 「对比Python学习Go」- 函数、类和接口
- 「对比Python学习Go」- 并发编程（协程）
- 「对比Python学习Go」- 包管理
- 「对比Python学习Go」- 发布包
- 「对比Python学习Go」- 时间处理
- 「对比Python学习Go」- 正则处理
- TODO 

后期可能会对比一些常用模块的使用，或常用场景的对比处理。宗旨便是，**对比Python和Golang的各种语法、业务场景实现，方便查阅和记忆学习。**

## Go学习资料

下边是整理的一些Go语言学习的在线免费资料，推荐给大家。

### 入门类 

- [官方文档：A Tour of Go](https://tour.golang.org/welcome/1), [官方教程翻译](https://pylixm.top/2018/10/go-start-1/)
- [The way to go 中文版](https://github.com/unknwon/the-way-to-go_ZH_CN) 
- [Go by example 中文版](https://gobyexample-cn.github.io/)

### 进阶类

- [Effective Go](https://golang.org/doc/effective_go.html)
- [Go语言圣经 中文版](https://books.studygolang.com/gopl-zh/)
- [Go语言高级编程](https://chai2010.gitbooks.io/advanced-go-programming-book/content/)
- [Go语言设计与实现](https://draveness.me/golang/)
- [Go语言原本](https://golang.design/under-the-hood/)
- [mojotv终结](https://mojotv.cn/404#Golang)
- [跟煎鱼学Go](https://eddycjy.gitbook.io/golang/)


### 其他类

- [Uber 编码规范](https://github.com/uber-go/guide/blob/master/style.md)
- [Go 语言实战: 编写可维护 Go 语言代码建议](https://github.com/llitfkitfk/go-best-practice)


## 扩展阅读

- [Python vs Go: What’s The Difference?](https://www.bmc.com/blogs/go-vs-python/)


好了，本篇到这里了，敬请期待下篇更新。

我是DeanWu，一个努力成为真正SRE的人。

---

>关注公众号「码农吴先生」, 可第一时间获取最新文章。回复关键字「go」「python」获取我收集的学习资料，也可回复关键字「小二」，加我wx，聊技术聊人生~ 

![](https://gitee.com/pylixm/picture/raw/master/2020-12-14/deanwu_wechat.png)
