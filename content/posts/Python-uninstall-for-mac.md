---
type : post
title : 【 python 基础系列 】 - 卸载通过pkg安装的python 
categories: [Python,] 
date : 2018-01-18
url: /posts/2018-01-18-python-unittest.html 
tags : [Python, unittest]
---

Python 开发时，都是自己安装一个用户自己的Python, 很少使用系统自带的。一是版本老旧，另一个是怕安装开发包时和系统依赖包冲突，对系统造成不必要的破坏。Python 官方提供了Linux、mac和Windows 下Python的安装包，高版本的python安装包，在安装时是允许多版本存在的，对已有python并不会造成破坏。但早起的一些旧版本安装包，还是会覆盖已有的版本，对多版本共存支持的不是很好。

Windows 系统下还好，我们可以选择安装目录。安装错误时，可以方便的卸载。但是针对于Mac 来说，不是很友好。下边是Mac 安装包卸载的方法，适用大多数的Python版本安装包，目前最新为`Python3.8.3`。


**一：删除Python文件：**

```bash
sudo rm -rf /Library/Frameworks/Python.framework/Versions/x.x
```

**二：删除Python应用程序**

```bash
sudo rm -rf "/Applications/Python x.x"
```

***三：还原`/usr/local/bin`目录下的Python连接恢复：***

确保`/usr/bin/python`还是系统自带的python（一般不会改），如果被动了，则需要将

```bash
/System/Library/Frameworks/Python.framework/Versions/Current/bin/python
```

做一个软链接至/usr/bin/python

**四：删除安装包所定义的环境变量：**

```bash
vi ~/.bash_profile
```

删除

```bash
PATH="/Library/Frameworks/Python.framework/Versions/3.4/bin:${PATH}"
export PATH
```

Mac 下推荐使用 brew 来安装Python，亦或是使用`pyenv`之类来管理。brew 安装不同版本的python 可使用 @ + 版本号来安装，如`brew install python@3.8`，pyenv的使用可参阅我另一篇文章[使用 pyenv + virtualenv 打造多版本python开发环境](https://pylixm.cc/posts/2016-06-19-Virtualenv-install.html)。