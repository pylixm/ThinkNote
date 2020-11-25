---
type : posts
title : Python 段错误（Segmentation fault）排查
categories: [Python,] 
series: [Python进击,]
date : 2019-12-26
url: /posts/2019-12-26-python-trick.html 
tags : [Python, Segementation fault]
---


## 现象 

今天在升级一个Python虚拟环境的时候，出现了这种错误 `OSError - setuptools pip wheel failed with error code -11`。我的操作步骤是这样的，先删除虚拟环境`rm -rf env`，再创建 `virtualenv env --python=python3`，没什么问题。看到退出码 `11`，查了下毫无头绪。在外部python3 的环境下执行了下 `pip3 list`, 报如下错误：

![](/static/imgs/python/segmentationfault.png)


## 分析调试

看到错误`Segmentation fault`，突然想起之前看过董大的一篇文章 [一次调试段错误(segmentation fault)的经验](https://www.dongwm.com/post/debug-segmentation-fault/)，很明显这是一个段错误。

考虑将pip，卸载重新安装。

```
python3 -m pip uninstall pip
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
```

但在安装的时候，直接就报错误`Segmentation fault`，便退出了。那便调试下吧，看看具体是哪里的问题。

**段错误 (segmentation fault)** 一般是由于 C 模块试图访问无法访问的内存引起的。我们都知道Python很多模块底层都调用C语言的接口，也就不难理解为什么会出现段错误了。但是仅适用Python的调试器的话，是无法调试该种错误的，它像上边一样只返回 `Segmentation fault`字样，并不会返回具体的错误信息和调用栈。此时我们需要调试工具`gdb`，`gdb`是`gcc`的调试工具，一般用来调试c/c++程序，该工具是支持python的，可以调试python到c的整个调用栈。

`gdb`可通过`yum install gdb`安装 , 在bash 窗口输入`gdb` 启动`gdb`调试窗口，可以通过`run` 命令来运行我们的py文件。

使用gdb调试查看得到如下信息：

![](/static/imgs/python/segmentationfault-gdb.png)

可以看到是库 `libcrypto.so`的问题。更多`gdb`介绍可参考扩展阅读。

## 解决

python3.7 的ssl 对openssl版本有要求，必须用openssl并且版本必须大于等于1.02或者libressl2.64。

之前安装的 openssl-1.1.0，这次安装libressl试试。操作如下：

```
# 安装libressl-2.8.0
wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.8.0.tar.gz
tar zxvf libressl-2.8.0.tar.gz
cd libressl-2.8.0/
./configure --prefix=/usr/local/ssllib
make
make install

# 创建配置文件
cd /etc/ld.so.conf.d
vim libressl-2.8.0.conf

# 将以下行加入文件，并保存
/usr/local/ssllib

ldconfig -v #重新加载库文件

# 把原来的命令建立新的硬连接
mv /usr/bin/openssl /usr/bin/openssl.bak
mv /usr/include/openssl /usr/include/openssl.bak
ln -s /usr/local/ssllib/bin/openssl /usr/bin/openssl
ln -s /usr/local/ssllib/include/openssl /usr/include/openssl

# 运行命令看是否成功
openssl version
libressl-2.8.0 
```

重新编译Python3.7.3，安装解决。

```
./configure --with-ensurepip=install
make && make install
```

## 总结

在Python中`段错误`一般出现在编译安装模块时，解决它的思路是：先考虑升级出现段错误的模块包。如果未解决问题，可通过`gdb`来调试定位问题，根据具体问题具体解决。

## 扩展阅读

- https://en.wikipedia.org/wiki/Segmentation_fault
- https://devguide.python.org/gdb/
- https://www.dongwm.com/post/debug-segmentation-fault
- https://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/gdb.html
- https://www.gnu.org/software/gdb/