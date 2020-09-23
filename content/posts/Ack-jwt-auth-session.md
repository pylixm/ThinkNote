---
type : post
title : 前后端分离认证的最佳实践：JWT Auth vs Session-Cookie
categories: [知识库,] 
series: [知识库,]
date : 2020-06-04
author : "DeanWu"
url: /posts/2020-06-04-jwt-auth-session.html 
tags : [知识库,]
---

前几年，web开发领域中「前后端分离」比较火，现如今已逐渐成为事实标准。但是究竟什么是前后端分离？又为什么要前后端分离呢？

## 什么是前后端分离？为什么要前后端分离？

前后端分离，说的更多的是一种架构上的概念。在传统的web架构中，比如经典的MVC，会分数据层、逻辑层、视图层。这个视图层即我们所说的前端了，映射到代码层面，就是html、js、css等代码文件。数据层和逻辑层更多的是后端部分，例如我们的 `.java` 、`.go`、`.py`等文件。这些文件会在一个工程中，并不会单独的开发、测试、部署。

![](/static/imgs/jwt_cookie/mvc.jpg)

在前后端分离的架构中，前端和后端是分开的，分别在不同的工程中。前端有专门的前端开发人员来进行开发、测试，后端则有后端开发人员来进行开发、测试，他们之间通过API来交互。

![](/static/imgs/jwt_cookie/back_frond.jpg)

前后端分离有这么几个好处：

**1/ 解耦了前后端的工作人员** 让前端和后端分别交给更擅长的人来做，细化了工种，可以更加的专精。前端人员来关心用户体验、UI设计、交互渲染；后端人员更关注业务逻辑、性能保障、安全等方面。在项目进度方面，前后端可以并行开发，而互不影响，加快了整体的项目进度。

**2/ 解耦了前后端的代码** 后端只需提供API服务，不再与静态文件交互。后端可以使用更复杂的分布式、微服务架构，提供更好的性能和稳定性保障。同时前端除了PC端之外，移动端也可以使用相同的一套后端服务。

看到这里，前后端分离被广泛应用也可以理解了。

大家需要注意，并不是所有的项目都需要前后端分离，像是大型的项目，开发人员很多，人员分工明确，这种团队配置下，使用前后端分离可增加工作效率提高系统质量。但是团队人员少，分工不那么明确的情况下，再采用前后端分离的架构，只会增加开发成本和系统复杂度。前后端分离是一个好的架构思路，但是需要看具体的业务和人员情况，切勿盲目的跟从。

## 前后端分离常用的认证方式

前后端分离中前后端的交互是通过API进行的，那么其中的认证是少不了的。前后端分离中常用的认证方式有下面几种：

- **Session-Cookie** 
- **Token 验证**
- **OAuth(开放授权)**

### Session-Cookie 方式

Session-Cookie 方式是我们开发web应用时最常用的认证方式。它的认证过程一般是这样的：

![](/static/imgs/jwt_cookie/session_cookie.png)

- 1/ 用户浏览器向服务器发起认证请求，将用户名和密码发送给服务器。
- 2/ 服务器认证用户名和密码，若通过则创建一个session对话，并将用户信息保存到session中。session的信息可以是保存到服务器文件、共享外部存储、数据库等存储中，等下次请求时查询验证使用。
- 3/ 服务器会将该session的唯一标识ID，返回给用户浏览器，并保存在cookie中。
- 4/ 用户请求其他页面时，浏览器会自动将用户的cookie携带上，并发起接口请求，服务端收到请求后，从cookie解析出sessionID， 根据这个sessionID 查询登录后并保存好的session，若有则说明用户已登录，放行。

该方式是MVC架构中最常用的认证方案，在前后端分离中也是可以用的。几乎所有的Web框架都默认集成了Session-Cookie的认证方式，而且对Session-Cookie方式的安全性和稳定性方面都有很成熟的处理方案。

**当前端使用后端web框架当做web容器驱动时，Session-Cookie 方案作为首先建议的认证方案。**

### Token 方式 

Token 方式是不通系统交互、前后端架构常用的认证方式。Token 方式的认证流程如下：

![](/static/imgs/jwt_cookie/token.png)

- 1/ 用户使用用户名和密码登录，将用户名和密码发送给服务器。
- 2/ 服务器验证用户名和密码，若正确，则签发token，返回给用户。
- 3/ 用户收到token后，将其存储起来，web服务一般为localStrage 或cookie。
- 4/ 用户请求其他资源页面时，会携带token，一般放到header 或参数中，发送给服务端。
- 5/ 服务器收到后，验证token，判断用户的正确性。

JWT(JSON Web Token)是最常用的一种Token认证方式，已成为Token认证的标准事实。JWT 方式将Token 分段，使其可以保持少量数据，增加了签名验证，确保了token的安全性。JWT 网上介绍的资料很多，这里不再赘述。不了解的，可参考下边这些资料：

- [JSON Web Token 入门教程](https://www.ruanyifeng.com/blog/2018/07/json_web_token-tutorial.html)
- [JWT官网](https://jwt.io/)

### OAuth 方式

OAuth（Open Authorization）是一个开放标准，允许用户授权第三方网站访问他们存储在服务端的用户信息。我们常见的的QQ、微信等第三方登录便是Auth认证方式。OAuth协议有1.0和2.0两个版本。相比较1.0版，2.0版整个授权验证流程更简单更安全，也是目前最主要的用户身份验证和授权方式。

OAuth更像是一种授权机制。数据的所有者告诉系统，同意授权第三方应用进入系统，获取这些数据。系统从而产生一个短期的进入令牌（token），用来代替密码，供第三方应用使用。

在单纯的前后端分离系统中，OAuth并不是常用的方式，它更多的应用在不同系统之间的授权交互。


## 对比思考

跑去不常用的OAuth，这里对比两种前两种常用的认证方式 JWT Auth 和 Session-Cookie Auth ，到底谁才是前后端分离认证的最佳实践呢。从下面几个方向分析比对。

### 可扩展性

Session-Cookie 是有状态的服务，在服务端保存了session的信息。当服务端扩容的时候，需要考虑到session的共享问题，这个问题已有成熟的解决放方案，可使用session复制、共享、持久化等方式解决，大多数的分布式Web框架已经集成了处理方案。JWT 验证方式是无状态的服务，服务端可随意扩缩容。

Session-Cookie 方式基于Cookie，也就是必须是浏览器或支持Cookie的浏览器封装的框架，纯移动端无法使用。JWT 不同，不依赖Cookie, 只要在本地可存储即可。

### 安全性

Web开发中常见的两个安全问题 XSS（跨站点脚本攻击） 和 CRSF （跨站点请求伪造）。前者利用注入脚本到用户认证网站上，执行业务脚本代码。后者则利用浏览器访问后端自动携带cookie机制，来跨站的伪造请求。XSS 只要我们对注入端，进行过滤、转义就能解决。CRSF 是我们重点关注的。

在Session-Cookie认证方式中，因为把SessionID保存在了Cookie中，很容易引起CRSF攻击，在大多数的WEB框架中有集成解决方案，如Django 的csrftoken 、Beego的xsrfToken 等。在使用Session-Cookie方案中建议开启web框架的csrf功能。

JWT 认证，可以把Token存放在Cookie或localstorage。建议存在localstorage，这样就彻底避免了 CRSF 攻击。

另外JWT有几个安全性的问题，需要注意：

- 1/ **JWT明文编码** JWT 的编码是明文的Base64的一个编码，是可以反编译的。在使用JWT传输信息的时候，最好使用https。
- 2/ **JWT 泄露问题** 解决JWT的泄露问题是一个平衡的问题。有几种处理方式：
  - 将JWT 的过期时间设置的很短，及时泄露也无关紧要。
  - 在数据库设计JWT的黑名单机制，这样无形之中增加了验证的逻辑复杂度。
  - 保存签发的JWT，当JWT泄露时，直接设置失效。

以上三种处理方式由轻到重，看你业务重要性酌情选择。


### 性能

Session-Cookie方案，因为后端服务存储了Session信息，在认证的时候需要查询，当有大量认证的时候是非常耗费资源的。JWT 可以把信息放到token中，只需要验证解码，使用签名验证token即可，相对来说效率会有提升。



## 参考及扩展阅读

- [傻傻分不清之 Cookie、Session、Token、JWT](https://juejin.im/post/6844904034181070861)
- [四种认证方式](https://juejin.im/post/5d67662ee51d45621655353f)
- [JWT简介](https://www.jianshu.com/p/576dbf44b2ae)
- [JWT勿用](https://www.jianshu.com/p/af8360b83a9f)
- [（译）别再使用 JWT 作为 Session 系统！问题重重且很危险。](https://learnku.com/articles/22616)
- [OAuth 2.0 的一个简单解释](http://www.ruanyifeng.com/blog/2019/04/oauth_design.html)
- [OAuth 2.0 的四种方式](http://www.ruanyifeng.com/blog/2019/04/oauth-grant-types.html)