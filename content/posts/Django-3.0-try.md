---
type : post
title : Django 3.0 异步试用分享
categories: [Django,] 
date : 2019-12-12 
url: /posts/2019-12-12-Django-3.0.html 
tags : [Django, ]
---

上周`Django`官方正式发布了`Django 3.0`版本，其中最重要的更新莫过于对`ASGI`的支持。今天对`Django 3.0`的异步功能做了简单的试用，分析下过程，希望对大家有帮助。

具体的详细更新列表可参考官方 [Django 3.0 release notes](https://docs.djangoproject.com/en/3.0/releases/3.0/), 这里不再赘述，下面我们开始。

## 准备工作

在开始之前我们先来准备下环境，直接使用Pycharm 新建一个项目，并新建虚拟环境.

![](/static/imgs/django/django3-1.png)

得到如下项目：

![](/static/imgs/django/django3-asgi.png)

相比之前版本的django项目，多了一个`asgi.py`。这便是`ASGI`的服务的入口文件了，内容基本同`wsgi.py`。

## ASGI 协议知识

在使用`ASGI` 特性之前，先让我们了解下，什么是ASGI?

`ASGI`和`WSGI`，都是一种Web服务网关接口协议，是在`CGI`的标准上构建的。

`CGI`（通用网关接口， Common Gateway Interface），简单来说就是解析浏览器等客户端发送给服务端的请求，并组装需要返回的HTTP请求的一种通用协议，处理这个过程的程序，我们就可以叫CGI脚本。互联网早起的动态网页都是基于`CGI`标准的。

![](/static/imgs/django/django3-cgi.png)

`WSGI`，是一种Python专用的Web服务器网关接口，它分为两部分"服务器（或网关）"和"应用程序（或应用框架）"。「服务器」，一般独立于应用框架，为应用程序运行提供环境信息和一个回调函数（Callback Function）。当应用程序完成处理请求后，透过回调函数，将结果回传给服务器。常用的`WSGI`服务器有: `uwsgi`、`gunicon`。「应用程序」，是各种实现了`WSGI`标准的Python web 框架了，常用的有`Django`、`Flask`等。

`ASGI`（Asynchronous Server Gateway Interface)是Django团队提出的一种具有异步功能的Python web 服务器网关接口协议。能够处理多种通用的协议类型，包括HTTP，HTTP2和WebSocket。`WSGI`是基于HTTP协议模式的，不支持`WebSocket`，而`ASGI`的诞生则是为了解决Python常用的WSGI不支持当前Web开发中的一些新的协议标准(WebSocket、Http2等)。同时，`ASGI`向下兼容`WSGI`标准，可以通过一些方法跑`WSGI`的应用程序。常用的「服务器」有`Daphne`、`Uvicorn`。

更多`ASGI`资料可参考[文档](https://asgi.readthedocs.io/en/latest/index.html)

## 使用过程 

了解了`ASGI`，我们进入正题。关于`ASGI`在`Django release Notes`文档中并没有过多的介绍，只有一个部署的文档 [How to deploy with ASGI](https://docs.djangoproject.com/zh-hans/3.0/howto/deployment/asgi/)

看了下，有用的大概只有这句"**必须使用 `Daphne`或`Uvicorn`部署，才会是 ASGI 服务，直接runnerserver 是同步服务**"。

我们随便选一个，并启动服务：

```
# 安装
pip install  uvicorn 

# 启动服务
uvicorn django3_demo.asgi:application
```
启动日志如下：

```
$ uvicorn django3_demo.asgi:application
INFO:     Started server process [48508]
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Waiting for application startup.
INFO:     ASGI 'lifespan' protocol appears unsupported.
INFO:     Application startup complete.
```

那我们来测试下，根据`ASGI`的特性，可以支持HTTP、HTTP2和WebSocket。那我们来进行下 websocket 和http 的测试。

### **websocket 测试** 

![](/static/imgs/django/django3-websocket.png)

看服务错误如下：

```
INFO:     Application startup complete.
ERROR:    Exception in ASGI application
Traceback (most recent call last):
  File "/Users/xiumin1/.local/share/virtualenvs/django3_demo/lib/python3.6/site-packages/uvicorn/protocols/websockets/websockets_impl.py", line 153, in run_asgi
    result = await self.app(self.scope, self.asgi_receive, self.asgi_send)
  File "/Users/xiumin1/.local/share/virtualenvs/django3_demo/lib/python3.6/site-packages/uvicorn/middleware/proxy_headers.py", line 45, in __call__
    return await self.app(scope, receive, send)
  File "/Users/xiumin1/.local/share/virtualenvs/django3_demo/lib/python3.6/site-packages/django/core/handlers/asgi.py", line 146, in __call__
    % scope['type']
ValueError: Django can only handle ASGI/HTTP connections, not websocket.

```

`Django can only handle ASGI/HTTP connections, not websocket` ，貌似Django 的ASGI还没有完全实现，仅支持HTTP。

### **http 测试**

在浏览器输入`http://127.0.0.1:8000` 出现了我们熟悉的小火箭页面。这只是简单的启动页面，我们需要写个异步的view和model来具体操作下。

翻阅了一遍文档，在一个小角落里，令我失望的找到了如下说明：

![](/static/imgs/django/django3-model-async.png)

>Django has developing support for asynchronous (“async”) Python, but does not yet support asynchronous views or middleware; they will be coming in a future release.

主要意思是现阶段不支持异步的view和中间件。那也就说明没法使用Django原生的方式来实现`ASGI`了。

到此，异步功能的试用告一段落。结论，现阶段`Django`原生还是无法完全的支持`ASGI`的服务。如果想完全实现`ASGI`服务，还是需要 [`Channels`](https://channels.readthedocs.io/en/latest/) 或 [`starlette`](https://www.starlette.io/)。

经过翻阅资料，我找到了 Django原生异步建议的作者 Andrew Godwin的一篇blog https://www.aeracode.org/2018/06/04/django-async-roadmap/， 描述开发的时间轴。大致如下：

- Django 2.1：当前进行中的版本。没有异步工作。
- Django 2.2：添加异步ORM和查看功能的初始工作，但默认情况下所有内容默认都同步，并且异步支持主要基于线程池。
- Django 3.0：将内部请求处理堆栈重写为完全异步的，添加异步中间件，表单，缓存，会话，身份验证。对所有变为仅异步的API开始弃用过程。
- Django 3.1：继续改善异步支持，潜在的异步模板更改
- Django 3.2：完成不推荐使用的过程，并拥有一个异步的Django。

从现在3.0发布的功能看，实现貌似与该时间抽差了一个版本，只实现了应该到2.2的功能。

到这里今天的分享就结束了。最后，还是希望Django 的异步功能早点来临。因为现在从框架到ORM，再到数据库驱动，想凑齐一整套异步的框架，真的是太难了。

## 扩展阅读

- [Daphne 文档](https://pypi.org/project/daphne/)
- [DEP0009](https://github.com/django/deps/blob/master/accepted/0009-async.rst#views-http-handling)
- [Django 3.0 is going async!](https://hub.packtpub.com/django-3-0-is-going-async/)
- [A Django Async Roadmap](https://www.aeracode.org/2018/06/04/django-async-roadmap/)
- [django developers goolge groups](https://groups.google.com/forum/#!msg/django-developers/5CVsR9FSqmg/qKD3QCrLCAAJ)
- [刘江-Django3.0初体验](http://www.liujiangblog.com/blog/47/)