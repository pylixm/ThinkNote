---
type : post
title : 【 python 基础系列 】 - 卸载通过pkg安装的python 
categories: [Python,] 
date : 2020-07-02
url: /posts/2020-07-02-python-uninstall-for-mac.html 
tags : [Python, uninstall, mac]
---

Python 开发时，都是自己安装一个用户自己的Python, 很少使用系统自带的。一是版本老旧，另一个是怕安装开发包时和系统依赖包冲突，对系统造成不必要的破坏。Python 官方提供了Linux、mac和Windows 下Python的安装包，高版本的python安装包，在安装时是允许多版本存在的，对已有python并不会造成破坏。但早期的一些旧版本安装包，还是会覆盖已有的版本，对多版本共存支持的不是很好。

Windows 系统下还好，我们可以选择安装目录。安装错误时，可以方便的卸载。但是针对于Mac 来说，不是很友好。下边是Mac 安装包卸载的方法，适用大多数的Python版本安装包，目前最新为`Python3.8.3`。


## Mac 下 pkg 安装Python 卸载

以`Python3.8` 卸载为例，其他版本大致相同。

**一/ 删除Python文件：**

```bash
sudo rm -rf /Library/Frameworks/Python.framework/Versions/3.8
```

**二/ 删除Python应用程序**

```bash
sudo rm -rf "/Applications/Python 3.8"
```

***三/ 还原`/usr/local/bin`目录下的Python连接恢复：***

若该目录下有其他版本Python软连，python或python3 修改会之前版本。

```
# python3 修改为其他版本
ln -s ../Cellar/python/3.6.5/bin/python3 python3
```

删除Python3.8相关的其他模块软连。

```bash
rm -rf pip3.8
rm -rf easy_install-3.8
rm -rf 2to3-3.8
```

其他版本卸载时，确保`/usr/bin/python`还是系统自带的python（一般不会改），如果被动了，则需要将

```bash
/System/Library/Frameworks/Python.framework/Versions/Current/bin/python
```
做一个软链接至`/usr/bin/python`。

**四/ 删除安装包所定义的环境变量(若有)**

```bash
vim ~/.bash_profile
```

删除

```bash
PATH="/usr/local/opt/python@3.8/bin:${PATH}"
export PATH
```

Mac 下推荐使用 brew 来安装Python，亦或是使用`pyenv`之类来管理。brew 安装不同版本的python 可使用 @ + 版本号来安装，如`brew install python@3.8`，pyenv的使用可参阅我另一篇文章[使用 pyenv + virtualenv 打造多版本python开发环境](https://pylixm.cc/posts/2016-06-19-Virtualenv-install.html)。


## 参考

- [https://blog.bbzhh.com/index.php/archives/97.html](https://blog.bbzhh.com/index.php/archives/97.html)