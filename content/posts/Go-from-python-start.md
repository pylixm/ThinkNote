---
type : posts
title : 「对比Python学习Go」- 环境篇
categories: [Golang,] 
series: [对比Python学习Go,]
date : 2020-12-03
url: /posts/2020-12-03-go-from-python-start.html 
tags : [Golang, 对比Python学习Go]
---


## 环境搭建

### Go 的安装 

Go 的官方网址 https://golang.org， 国内用户可访问国内官网 https://golang.google.cn/。


Go安装相对来说还是比较简单的，主要有如下安装包：

![go_install](https://gitee.com/pylixm/picture/raw/master/2020-12-3/1607007629415-go_install.png)

按系统来说，可通过如下方式安装:

#### Linux

源码方式安装：

```bash
# 使用二进制包安装
wget https://golang.org/dl/go1.15.5.linux-amd64.tar.gz

# 解压到 /usr/local
tar -C /usr/local -xzf go1.15.5.linux-amd64.tar.gz

# 配置环境变量  $HOME/.bash_profile
export PATH=$PATH:/usr/local/go/bin
source .bash_profile 
```

也可直接通过包管理工具来安装：

```bash
yum install golang 
apt-get install golang 
```

####  Mac OS X

Mac 系统可以官网提供的PKG包安装。

```bash
# 下载 pkg 包，点击安装即可。
wget https://golang.org/dl/go1.15.5.darwin-amd64.pkg

```

也使用 brew 等包管理工具安装。

```bash
brew install go 
```

#### windows 

可直接在官方下载地址下载 msi 格式安装包安装。 官方下载地址： [https://golang.google.cn/dl/](https://golang.google.cn/dl/)

默认安装位置， c:\Go。

#### 测试安装 

在任意位置执行 `go version` 可看到go 的相关版本信息。

```bash
# go version
go version go1.15.5 linux/amd64
```

### Python 的安装

Python 的官网 https://python.org。 主要有如下安装包：

![python_install](https://gitee.com/pylixm/picture/raw/master/2020-12-3/1607007323031-python_install.png)

可对应系统下载相应的安装包，点击安装即可。

Mac和Windows 没啥好说的，直接图形下一步即可。Linux 下，Python 的安装使用源码需要编译下。Go 安装包是一个二进制的包，直接下载解压配置好环境变量即可。

```bash 
./configure --prefix=/usr/local/python [其他需要的模块或参数]
make && make install 
```


## Go 常用环境变量 

Go 在开发之前，先来熟悉几个常用的环境变量，在Go项目开发中会经常使用。

- **$GOROOT** 表示 Go 在你的电脑上的安装位置，它的值一般都是 $HOME/go，当然，你也可以安装在别的地方。
- **$GOARCH** 表示目标机器的处理器架构，它的值可以是 386、amd64 或 arm。
- **$GOOS** 表示目标机器的操作系统，它的值可以是 darwin、freebsd、linux 或 windows。
- **$GOBIN** 表示编译器和链接器的安装位置，默认是 $GOROOT/bin，如果你使用的是 Go 1.0.3 及以后的版本，一般情况下你可以将它的值设置为空，Go 将会使用前面提到的默认值。
- **$GOPATH** GO项目工作目录。默认采用和 $GOROOT 一样的值，但从 Go 1.1 版本开始，你必须修改为其它路径。它可以包含多个包含 Go 语言源码文件、包文件和可执行文件的路径，而这些路径下又必须分别包含三个规定的目录：src、pkg 和 bin，这三个目录分别用于存放源码文件、包文件和可执行文件。
  
环境变量常在编译时使用，如交叉编译时，在mac下编译Linux上可用的go 二进制程序：

```bash 
GOOS=linux GOARCH=amd64 go build -o demo -ldflags="-s -w"
```

可用 `go env` 查看所有环境变量。

## 工作区和GOPATH

### Go

工作区，是放置 Go 源码文件的目录，通过设置环境变量`GOPATH`来指定。一般情况下，Go 源码文件都需要放到工作区中，但是对于命令源码文件（包含main函数的入口文件）来说，不是必须的。

工作区结构如下：

```bash 
$ tree -d -L 1
.
├── src  # src 用于放置源码文件，以代码包为组织形式。
├── pkg  # pkg 用于存放归档文件，以 .a 为后缀的文件，存放在相关平台目录下，同样以代码包为组织形式。 目录结构为： $GOPATH/pkg/$GOOS_$GOARCH/<一级代码包>/<二级代码包>/<末级代码包>.a
└── bin  # bin 用于存放当前工作区的 Go 程序的可执行文件。
#- 当环境变量设置 GOBIN 时，bin目录变得无意义，所有可执行文件（编译文件）会放到 GOBIN 的目录中；
#- 当 GOPATH 设置了多个目录时，必须设置 GOBIN 否则无法成功安装 Go 程序的可执行文件。
```
### Python 

Python 的工作目录可在任意目录，并没有特别要求。这和Go是静态编译性语言有很大关系，工作目录的这些规定，大都是为了更方便的编译和安装编译后的二进制文件。


## 代码包的相关知识

### Go

**代码包的作用：**

- 编译和归档 Go 程序的最基本单位。
- 代码划分、集结和依赖的有效组织形式，也是权限控制的辅助手段。

**代码包的规则：**

- 一个代码包实际上就是一个有导入路径代表的目录。导入路径即 <工作区目录>/src 或 <工作区目录>/pkg/<平台相关目录> 之下的某段子路径。
- 每个源码文件必须声明其所属的代码包。
- 同一个代码包中的所有源码文件声明的代码包应该是相同的。
- 只有开头大写的对象，可以让包外引用。
  
代码包声明与代码包导入路径的区别：

代码包声明语句中的包名称应该是该代码包的导入路径的最右子路径。如： 

- 代码包导入路径： `GoPL/tools`
- 代码包声明：`package tools` 

**代码包的导入：**

代码包导入语句中使用的包名称应该与其导入路径一至，如代码包 `fmt` 的导入：

```
import (
    "fmt"
)
```

代码包的导入方法：

- 带别名的导入： 
  
```go
import str "strings" 

str.HasPrefix("abc","a")
```

- 本地化的导入：
  
```go
import . "strings" 

HasPrefix("abc","a")
```

- 仅仅初始化
  
```go
import _ "strings"

// 仅执行代码包中的初始化函数
```


**代码包初始化：**

代码包初始化函数即：无参数声明和结果声明的 init 函数。init 函数可以被声明在任何文件中，且可以有多个。

init 函数执行时机：

- 单一代码包：当导入代码包时，对代码包的所有全局变量进行求值，之后执行所有 init 函数。同一代码包中的 init 函数执行顺序是不确定的。
- 不同代码包：先执行被导入的代码包中的 init 函数，再执行本代码包的 init 函数。同一代码包中被导入多个代码包的 init 函数执行顺序不定。
- 所有涉及到的代码包：在程序入口，在 main 函数执行之前执行。所有的 init 函数，都只会被执行一次。

### Python 

Python 中最小的编程单元为模块，即一个py文件。含有`__init__.py` 文件的目录，叫做包。

包的作用更多的是为了组织和分割代码。

**包的引用**

直接引入包：

```python
import sys 
print(sys.path)
```

引入包中的模块或对象：

```python 
from sys import path 
print(path)
```

重命名对象：

```python 
from sys import path as sys_path 
print(sys_path)
```

**包的规则**

- 一个包中的模块（py文件）不能重名，一个模块中的对象不能重名。否则会相互覆盖。
- 包引用时，不要相互引用，否则会出现循环引用错误。
- 包中可使用关键字 `__all__` 来限制可以引用的对象。


## 总结

本篇文章讲述了Go和Python的安装及一些基本的概念区别。接下来，会正式进入语法的学习，接下来和笔者一起开启 Go 的对比学习之旅吧！