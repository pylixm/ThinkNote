---
type : posts
title : FastApi 简单入门，附生产级脚手架代码
categories: [FastApi,] 
date : 2021-01-05
url: /posts/2021-01-05-start.html 
tags : [FastApi, Python]
---

> 公司内部分享的话术稿

大家好，今天我分享的主题是Python技术栈中一个新崛起的框架`FastApi`。我们可以用它来快速的构建具有「异步」特性的RestAPI和web服务。

这个topic受众比较狭窄，但是还是希望今天的内容可以给到大家启发。今天分享的内容主要分下面几个模块：

- FastApi 介绍，简单了解FastApi的背景及优势
- FastApi 的一些预备知识
- FastApi 的简单使用 

学习好一个框架，一定要了解它的历史和它诞生的背景。FastApi，是在什么样的背景下诞生的呢？下面我们看下今天分享的第一部分「FastApi介绍」。

## FastApi 介绍

FastApi 的作者是一个德国人，叫 Sebastián Ramírez（这是一个西班牙语），他的Github ID 叫 tiangolo。 这是他的个人博客：https://tiangolo.com/，现在是 Datum Consultants（一家做精品数据科学和人工智能解决方案咨询的公司） 公司的CTO。

除了工作上的title之外，在开源领域，他是 Encode 组织的成员，Encode 组织你可能不了解，说下组织下的开源项目你一定听过。

- Django-rest-framework：Django 生态中最流行的rest api 框架。
- httpx：支持异步请求的 http client，完全兼容 requests 库 。
- uvicorn：最流行的 ASGI 协议的web server。

tiangolo 使用过各种不同的框架和插件，想着用把它们的优点以及一些新版本语言的优秀特性组合起来，但是所有框架都不能够满足他的需求。

Encode组织下边有个很火的异步web框架叫 [Starlette](https://www.starlette.io/) ，tiangolo 在它的基础上添加了基于[Pydantic](https://pydantic-docs.helpmanual.io/)的类型提示，以及依赖注入系统等功能，最后构建了FastApi。

FastApi 文档中有篇文档，详细的描述了作者从各个框架中吸收的优点，以及和各框架的对比。有兴趣的可以阅读下：

- [Alternatives, Inspiration and Comparisons](https://fastapi.tiangolo.com/zh/alternatives/)


### 优势和特点

说了这么多，FastApi 到期具有哪些吸引人的优点呢。我们用数据来说话，截止到数据统计日期（2021年1月6日），各框架的github数据：

- Flask   53.4K 第一个版本发布在2010年4月16日，最近一次提交昨天（20210105），issues 19 PR 5 
- Django  54.7K 2012年源码迁移到github, 最近一次提交昨天（20210105），issues 没开放 PR 179
- Tornado  19.7K 最早的一次提交 7年前，最近一次提交是2个月前，issues 185 PR 32 
- FastApi  25.4K 2018年11月24日第一次提交，最近一次提交4天前，issues 390 PR 207 
- Sanic  14.4K 2016年11月16发布第一个版本，最近一次提交8天前，issues 66 PR 10 

从上边的数据我们可以看出，FastAapi在短短的两年内就获得了25K的star数，issues 和PR 基本都是最近几个月的，数量也可以说明它的活跃程度。

再来看另一组数据：

![image](https://gitee.com/pylixm/picture/raw/master/2021-1-5/1609838930941-image.png)

这是国外一个专门做框架性能对比的网站（TechEmpower）的数据，这是对Python语言的常用web框架的测试报告，可见fastapi表现优异。

这是详细的链接，有兴趣的可以看下：
- [https://www.techempower.com/benchmarks/#section=data-r19&hw=ph&test=query&l=zijmrj-1r&f=1ekg-0-6bk-0-13ydkw-hrbf28-295p8i-hsp0yq-4fuwp4-4fxpu0-0](https://www.techempower.com/benchmarks/#section=data-r19&hw=ph&test=query&l=zijmrj-1r&f=1ekg-0-6bk-0-13ydkw-hrbf28-295p8i-hsp0yq-4fuwp4-4fxpu0-0)


除了在上边数据方面的优异表现外，它还具有如下特点：

- 可以自动生成API文档。
- 框架基于类型提示构建，编辑器可以给你提供更好的支持。
- 有一个非常强大的依赖注入系统。
- 微框架，不限制你使用的插件
- 基于优秀的框架Starlette和Pydantic

抛去这些，我觉着仅性能堪比Golang语言的gin框架这一条，就值得我们学习下。

下面我们来具体看下FastApi的使用。

## FastApi 知识预备

在看FastApi之前，我们先来回忆下Python的异步编程和协程。

### Python的异步编程

Python 语言诞生在1994年，当时对编程语言性能的要求并不像现在这么高，所以它在设计之初就更倾向于快速开发和便捷的语法。即便有性能的要求，多进程多线程也完全能够应付。但是随着现代互联网的发展，对编程语言自身的性能要求就越来越高。除了多进程和多线程模型，还逐渐演化出「协程」模型（协程，是一种用户态的更小力度的任务运行单元。基于线程，可实现多个任务的并行。）为代表的异步编程思想。

在早期，Python 实现异步编程，需要地方的库，如Twisted、Tornado 等。从Python3开始，加入了对异步编程的原生支持。

- python3.3 引入关键字`yield from`，用户可实现基于生成器的简易协程；
- python3.4 引入`asyncio` 库，正式引入协程概念，使用关键字` @asyncio.coroutine` 和`yield from`来表示协程调用；
- python3.5 引入关键字`async/await`代替`@asyncio.coroutine` 和`yield from`，可以让我们使用同步的方式写出异步的代码；

下面这种以`async def`定义函数，且用`await` 关键字来调用函数的代码，便是协程相关的代码。

```python
import asyncio

async def compute(x, y):
    print("Compute %s + %s ..." % (x, y))
    await asyncio.sleep(1.0)
    return x + y

async def print_sum(x, y):
    result = await compute(x, y)
    print("%s + %s = %s" % (x, y, result))

loop = asyncio.get_event_loop()
loop.run_until_complete(print_sum(1, 2))
loop.close()
```

协程的运行有3种方式，[参考](https://docs.python.org/zh-cn/3/library/asyncio-task.html#id2)

- `aysncio.run()` 用来运行最高层次的`main()`函数；
- `await` 调用协程函数；
- `asyncio.create_task()` 并发运行作为`asyncio`任务的多个协程；

一些其他概念：

**CGI**（通用网关接口， Common Gateway Interface），简单来说就是解析浏览器等客户端发送给服务端的请求，并组装需要返回的 HTTP 请求的一种通用协议，处理这个过程的程序，我们就可以叫 CGI 脚本。互联网早起的动态网页都是基于CGI标准的。

**WSGI** 是一种 Python 专用的 Web 服务器网关接口，它分为两部分"服务器（或网关）“和"应用程序（或应用框架）"。「服务器」，一般独立于应用框架，为应用程序运行提供环境信息和一个回调函数（Callback Function）。当应用程序完成处理请求后，透过回调函数，将结果回传给服务器。常用的WSGI服务器有: uwsgi、gunicon。「应用程序」，是各种实现了WSGI标准的 Python web 框架了，常用的有Django、Flask等。

**ASGI（Asynchronous Server Gateway Interface)** 是 Django 团队提出的一种具有异步功能的 Python web 服务器网关接口协议。能够处理多种通用的协议类型，包括 HTTP，HTTP2 和 WebSocket。WSGI是基于 HTTP 协议模式的，不支持WebSocket，而ASGI的诞生则是为了解决 Python 常用的 WSGI 不支持当前 Web 开发中的一些新的协议标准(WebSocket、Http2 等)。同时，ASGI向下兼容WSGI标准，可以通过一些方法跑WSGI的应用程序。常用的「服务器」有Daphne、Uvicorn。

## FastApi 快速开始

### Hello world

FastApi 要求Python在3.6以上，它应用了很多Python3的新特性。下面我们安装一下：

```
pip install fastapi uvicorn
```
我们使用`uvicorn`来启动异步的web server ，同时把`uvicorn`也安装上。

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}

```

uvicorn 有两种启动方式：

- 使用命令启动 `uvicorn main:app --reload`，生产推荐，生产中把reload去掉。
- 使用python 代码启动，`python main.py`，仅用于调试。

```python

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

整体代码看下来，和Flask的Hellow world类似，有程序实例app用来启动程序，有路由和路由处理函数。

我们来看下它自带的Swagger类型的文档：

![image](https://gitee.com/pylixm/picture/raw/master/2021-1-6/1609937500231-image.png)

是不是很方便。

接下来，让我们来看些复杂点的用法。

### 日常使用

使用get方法来请求数据：

```python
@app.get('/user')
async def user(user_id: int = Query(..., title="The ID of the user to get", gt=0)):
    # do somethings 
    return {'user_id': user_id}
```

QueryString 的传递使用了一个类`Query`来做参数的校验，Query类继承了相关pydandic库的类，实现了对参数的类型校验，附默认值等功能。

此处`...`是表示user_id参数时必须的。若此处为None，则表示user_id可选。


使用put方法来更新数据：

```python
@app.put('/user/{user_id}')
async def user(user_id: int = Path(..., title="The ID of the user to get", gt=0)):
    # do somethings 
    return {'user_id': user_id}
```

这里的路径参数，可以使用类`Path`来做类型校验，功能和`Query`类似。


使用post方法来创建数据：

```python
from pydantic import BaseModel

class User(BaseModel):
    name: str
    age: int

@app.post("/users/")
async def create_user(user: User):
    # do somethings 
    return user

```

这里定义了一个用户类，作为函数参数的类型。在请求时，FastApi会自动的将参数注入到该类型的各对应属性字段。该类也起到了参数类型校验的作用。在函数参数类型这块，`User`类有点类似Golang中结构体定义的函数参数类型。

使用delete方法来删除数据：

```python
@app.delete('/user/{user_id}')
async def user(user_id: int = Path(..., title="The ID of the user to get", gt=0)):
    # do somethings 
    return {'user_id': user_id}
```

同put 方法的用法。

看了这些基本的用法之后，我们对FastApi的使用有了一个初步的了解。

我们从之前的代码中可以看到路由和路由函数在一块的，这种方式在路由少的情况下是非常方便的，但是随着项目复杂度的提升，路由逐渐增多，如果路由设计不合理，便会非常的不好维护。

针对这种情况，FastApi 提供了 `APIRouter`类来规划设计路由，以便适应大型的项目架构。

### 路由分解和版本管理

`APIRouter` 类的基本用法如下：

```python
# 页面路由
page_routes = APIRouter()
page_routes.include_router(views.router, prefix="")

# api 相关路由
api_routes = APIRouter()
api_routes.include_router(api_v1_views.router, prefix='/v1')
api_routes.include_router(api_v2_views.router, prefix='/v2')
```

可以通过它来拆分管理路由，最后再将所有路由注册到根路由即可。

```python
app = FastAPI()
app.include_router(page_routes)
app.include_router(api_routes, prefix=config.API_PREFIX)
```

### 一个真实的项目实例

接下来，让我们看一个真实的生产环境中的项目案例：

![image](https://gitee.com/pylixm/picture/raw/master/2021-1-7/1610006889308-image.png)

我们从下边几点来详细说下这个项目案例：

**1/ ORM**

首先在ORM 选择方面，官方推荐了强大的`SQLAlchemy`，它可以说是Python web 开发中最好用的第三方ORM了。在同步框架Flask中，应该说已经成为标配。

`SQLAlchemy` 目前为止对异步的支持还不够完成，官方推荐使用 Encode组织下的异步驱动 `databases`（目前支持PostgreSQL/MySQL/SQLite），只所以叫他驱动没叫他ORM，是因为它仅提供了和数据库的异步链接的管理，并没有对象模型。在使用的时候，可以结合`SQLAlchemy`或直接写SQL。

使用`SQLAlchemy`来处理同步的数据操作，使用`SQLAlchemy`加`databases`来实现异步的数据操作，完美实现了我们的需求。


**2/ 数据库迁移**

`SQLAlchemy` 还有一个数据库迁移的问题，它自己不支持数据库表的变更迁移，只能删除重建。在Flask中可以使用插件`flask_migrate`来实现数据库表的变更迁移。

`SQLAlchemy`官方推荐使用`alembic`。一个迁移过程大概步骤如下：

```bash
# 1/ 初始化环境 
alembic init migrations 

# 2/ 修改配置参数

# migrations/env.py
import sys 
sys.path = ['', '..'] + sys.path[1:]

from core.config import DATABASE_URL
config.set_main_option("sqlalchemy.url", str(DATABASE_URL))

...
from models.posts import PostsBase
from models.posts2 import PostsBase2
target_metadata = Base.metadata  # 一个app model 
target_metadata = [PostsBase.metadata, PostBase2.metadata]  # 多个app model

# 3/ 生成迁移脚本
alembic revision --autogenerate -m "init"

# 4/ 应用迁移脚本到数据库
alembic upgrade head 
```

**3/ service 拆分**

从项目目录可以看到有个service目录，很显然，当业务逻辑服务度升高时，我们可以提取很多共用的逻辑作为底层的共用逻辑。这个就比较灵活了，完全有你自己控制。各种设计模式，就可以往上怼了。


**4/ Docker 化**

最后我们来看下docker化，Dockerfile 如下：

```Dockerfile 
# 我们选择了官方 slim 镜像，体积相对小
FROM python:3.9-slim-buster

LABEL maintainer="DeanWu <pyli.xm@gmail.com>"

# stdout 无缓冲，直接输出
ENV PYTHONUNBUFFERED 1

# 复制代码，调整工作目录和脚本权限
COPY . /app

WORKDIR /app

RUN chmod +x start.sh prestart.sh start-reload.sh

# 安装用到的工具和python 包 
RUN apt-get update && \
    apt-get install -y --no-install-recommends default-libmysqlclient-dev gcc libffi-dev make && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf requirements.txt && \
    pip install --no-cache-dir gunicorn

ENV PYTHONPATH=/app

EXPOSE 80

# 启动命令 可添加也可不添加  
#CMD ["sh", "start.sh"]

```

编译和启动，

```bash
docker build -t fastapi-mysql:v1.0 .

docker run -p 80:80 -d -e DB_CONNECTION="mysql://root:Root1024@xxxx/fastapi" fastapi-mysql:v1.0 ./start.sh 
```

项目完整的代码，可以从我的github 获取 ：
- [https://github.com/pylixm/docker-fastapi-demo](https://github.com/pylixm/docker-fastapi-demo)

## 总结 

到这里我们从背景到生产项目案例，已经介绍完`FastApi` 这个框架了，你有没有觉着这个框架很酷呢？我今天只是简单的介绍了框架的部分应用场景，还有很多好玩的功能，大家可以去参考它的官方文档。也可以关注我公众号，一起讨论学习。
