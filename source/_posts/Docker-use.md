---
layout : post
title : Docker学习笔记--简单使用记录
category : docker
date : 2017-08-26
tags : [devops, 自动化运维, docker]
---

## 安装 

docker 安装现在已非常简单，具体可参考[官方文档](https://docs.docker.com/engine/installation/).

安装成功后可以使用以下命令检测：
```bash
$ docker --version
Docker version 17.06.2-ce, build cec0b72

$ docker-compose --version
docker-compose version 1.14.0, build c7bdf9e

$ docker-machine --version  # 在windows 和mac os 上管理docker容器 
docker-machine version 0.12.2, build 9371605
```
注：
1、`docker-machine` [文档介绍](https://docs.docker.com/machine/overview/)
2、`docker-compose` 官方docker容器编排工具，[文档介绍](https://docs.docker.com/compose/overview/)
3、更换docker 源，[官方文档](https://docs.docker.com/registry/recipes/mirror/#use-case-the-china-registry-mirror),[网友文档](http://www.jianshu.com/p/9fce6e583669)


## Docker 使用案例：使用docker 来搭建python开发环境 

docker 容器的运行是基于docker镜像的，所以我们需要先获取镜像。镜像的获取有几种方法：
- 1、从docker cloud 上拉取所需要的镜像，修改打包使用。
- 2、自己编写Dockerfile, 基于现有镜像，自己构建新镜像。

### 第一步，镜像获取

我们这里通过编写Dockerfile来定制镜像。
```dockerfile
FROM python:2.7  # 依据python:2.7 镜像构建
ENV PYTHONUNBUFFERED 1  # 这是python环境变量
RUN mkdir /code    # 在docker容器内创建代码目录
RUN mkdir /code/db  # 在docker内创建db目录
WORKDIR /code  # 设置工作目录为 code 
ADD ./mysite/requirements.txt /code/  # 复制文件到code 目录下
RUN pip install -r requirements.txt  # 运行命令
ADD . /code/  # 复制当前目录下的所有文件到code目录下 
```

注：
1、如何编写Dockerfile, [官方文档](https://docs.docker.com/engine/reference/builder/)
2、copy vs add [官方文档](https://docs.docker.com/engine/reference/builder/#copy)，[网友解释](http://blog.csdn.net/liukuan73/article/details/52936045)

### 第二部，启动容器
>TODO

### 第三部，配置pycharm使用
>TODO



## Docker 其他知识点

### Docker for Mac 的安装路径
/Users/{YourUserName}/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/Docker.qcow2

## docker 常用命令
```
1、 #从官网拉取镜像
docker pull <镜像名:tag>
如：docker pull centos(拉取centos的镜像到本机)
2、#搜索在线可用镜像名
docker search <镜像名>
如：docker search centos( 在线查找centos的镜像)
3、#查询所有的镜像，默认是最近创建的排在最上
docker images
4、#查看正在运行的容器
docker ps
5、#删除单个镜像
docker rmi -f <镜像ID>
6、#启动、停止操作
docker stop <容器名or ID> #停止某个容器 
docker start <容器名or ID> #启动某个容器 
docker kill <容器名or ID> #杀掉某个容器
7、#查询某个容器的所有操作记录。
docker logs {容器ID|容器名称} 
8、# 制作镜像  使用以下命令，根据某个“容器 ID”来创建一个新的“镜像”：
docker commit 93639a83a38e  wsl/javaweb:0.1
9、#启动一个容器
docker run -d -p 58080:8080 --name javaweb wsl/javaweb:0.1 /root/run.sh
解释：-d：表示以“守护模式”执行/root/run.sh脚本
          -p：表示宿主机与容器的端口映射，此时将容器内部的 8080 端口映射为宿主机的 58080 端口，这样就向外界暴露了 58080 端口，可通过 Docker 网桥来访问容器内部的 8080 端口了。
          -name:为容器命名
命令行启动：
docker run -it --rm ubuntu:14.04 bash
docker run 就是运行容器的命令，具体格式我们会在后面的章节讲解，我们这里简要的说明一下上面用到的参数。
* -it：这是两个参数，一个是 -i：交互式操作，一个是 -t 终端。我们这里打算进入 bash 执行一些命令并查看返回结果，因此我们需要交互式终端。
* --rm：这个参数是说容器退出后随之将其删除。默认情况下，为了排障需求，退出的容器并不会立即删除，除非手动 docker rm。我们这里只是随便执行个命令，看看结果，不需要排障和保留结果，因此使用 --rm 可以避免浪费空间。
* ubuntu:14.04：这是指用 ubuntu:14.04 镜像为基础来启动容器。
* bash：放在镜像名后的是命令，这里我们希望有个交互式 Shell，因此用的是 bash。

10、#最后补充一个启动docker服务的命令
很简单：
service docker start

11、删除容器
docker rm $(docker ps -a -q)
```

## Docker 其他相关文档收集 

###  docker images 保存路径 及说明
http://blog.csdn.net/wanglei_storage/article/details/50299491

### docker 镜像与容器存储目录结构精讲 
http://blog.csdn.net/wanglei_storage/article/details/50299491



## 参考

- [http://blog.csdn.net/yhcvb/article/details/45696961](http://blog.csdn.net/yhcvb/article/details/45696961)