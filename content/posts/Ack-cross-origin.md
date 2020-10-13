---
type : post
title : 谈谈前后端分离中的跨域问题
categories: [前后端分离,] 
series: [前后端分离,]
date : 2020-10-13
author : "DeanWu"
url: /posts/2020-10-13-cross-origin.html 
tags : [前后端分离, 跨域 ]
---

在前后端分离开发过程中常常出现下面这样的错误提示：

```
Access to XMLHttpRequest at 'http://127.0.0.1:8000/apis/users/login/' from origin 'http://127.0.0.1:8080' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
HelloWorld.vue?18db:50 err Error: Network Error
    at createError (createError.js?16d0:16)
    at XMLHttpRequest.handleError (xhr.js?ec6c:91)
```

看到关键字`CORS`、`Access-Control-Allow-Origin` 可以判断基本上就是跨域相关的错误了。

不了解的人常常一头雾水，本文咱们就来具体探讨下这种跨域问题，彻底搞懂它，解决它。

## 什么是跨域？造成跨域的原因？

跨域问题是由浏览器的同源策略引起的，在Http Client的调用中不会存在。同源策略中的同源是说站点的**协议**、**域名**、**端口**都需要相同。

![](/static/imgs/cross_origin/cross_origin.png)

**跨域**便是请求不同源的站点的一种行为操作。

为了更好的了解跨域，我们先来了解下**同源策略**。同源策略是一种安全策略，它只允许访问来自同一站点的资源。同源策略又分为两种：

- DOM 同源策略：禁止对不同源页面DOM进行操作；
- XMLHttpRequest同源策略：禁止使用XHR对象对不同源的服务地址发起HTTP请求；

DOM同源策略，常常发生在iframe的使用中，iframe 中如果嵌套了不同源的页面便会发生跨域。iframe跨域和XHR同源策略造成的跨域解决方法一样。

XMLHttpRequest同源策略便是引起文章开头跨域问题的主要原因。当浏览器请求后端不同源的数据时，会向后端发起一个XHR的HTTP请求，浏览器检测到后端服务和本服务不同源，触发XHR同源策略限制，抛出异常。

>XMLHttpRequest（简称XHR）对象用于与服务器交互。通过 XMLHttpRequest 可以在不刷新页面的情况下请求特定 URL，获取数据。除了浏览器的地址栏，浏览器和后端交互（通常是javascripts控制）都是通过XHR对象，在浏览器的console中可以看到XHR的请求。
>![](/static/imgs/cross_origin/xhr.png)


作为用户，同源策略是浏览器对我们上网行为的一种保护。作为开发者，在web开发中确实会用到夸域来获取资源的情况。如何解决呢？下面总结几种常用的跨域解决方法。

## 常用的解决方法

这里以vue作为前端、Django 作为后端举例说明。

- 前端服务地址为：http://127.0.0.1:8080
- 后端接口地址为：http://127.0.0.1:8000

详细完整代码可见：

### 跨域资源共享（CORS）

CORS（Cross-origin resource sharing，跨域资源共享）是一个 W3C 标准，定义了在必须访问跨域资源时，浏览器与服务器应该如何沟通。它的核心思想，使用自定的HTTP头部信息让浏览器和后端进行沟通，来决定是否允许跨域请求。

CORS 方式解决跨域，主要是后端支持，主流浏览器均已支持。站点在访问跨域资源的时候，浏览器会自动的添加HTTP头信息，自动完成与后端的交互，用户无感知。

例如在前端我们有个登录的POST请求，我们使用axios直接跨域请求后端接口。如下：

```
  handleClick(){
  this.$axios.post("http://127.0.0.1:8000/apis/users/login/", {
    username: this.username,
    password: this.password,
  }).then(res=>{
      console.log('res',res)
    }).catch(err=>{
      console.log('err',err)
    })
  },
```

前端服务端口为8080，后端服务为8000。两个服务的端口不一致，发生了跨域。

```
Access to XMLHttpRequest at 'http://127.0.0.1:8000/apis/users/login/' from origin 'http://127.0.0.1:8080' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
HelloWorld.vue?18db:50 err Error: Network Error
    at createError (createError.js?16d0:16)
    at XMLHttpRequest.handleError (xhr.js?ec6c:91)
```

Django 可通过第三方的跨域库`django-cors-headers`添加支持。我们`pip install django-cors-headers` 并增加如下配置：

```
INSTALLED_APPS = [
    ... 
    'corsheaders',
    'site_center.apps.SiteCenterConfig',
]
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    ...
]

# 跨域支持
CORS_ALLOWED_ORIGINS = ['http://127.0.0.1:8080']  # 授权进行跨站点 HTTP 请求的源列表

# 因为跨域之后需要传递sessionid 到浏览器cookie，所以添加如下配置。
CORS_ALLOW_CREDENTIALS = True  # 允许 Cookie 包含在跨站点 HTTP 请求中
SESSION_COOKIE_SAMESITE = None  # django 自己的安全策略
```

前端增加携带cookie的参数，不需要cookie时，可不用设置：

```
  handleClick(){
  this.$axios.post("http://127.0.0.1:8000/apis/users/login/", {
    username: this.username,
    password: this.password,
  }
  ,{
    withCredentials:true  // 携带和设置cookie 
  }
  ).then(res=>{
      console.log('res',res)
    }).catch(err=>{
      console.log('err',err)
    })
  },
```

重启服务，再次访问前端，成功登录。


### 使用代理解决

使用代理解决，vue框架自带了代理转发，在vue配置文件中增加如下配置解决：

```
    proxyTable: {
      // 这里就是代理了
      '/apis': {
        target: 'http://127.0.0.1:8000/apis/',   //设置你调用的接口域名和端口号 别忘了加http，就是后台服务地址
        changeOrigin: true,
        pathRewrite: {
          '^/apis': ''
        }
      }
    },
```

在生产环境中，可以使用Nignx作为代理来解决跨域问题。

以上两种方式，便是前后端分离中最常用的跨域解决方案了，除了这两种方案，还有如下几种：

- jsonp 
- location.hash 跨域
- postMessage 跨域
- window.name 跨域
- document.domain 跨域

这些都不常用，文本暂不讨论。

## 总结

跨域问题，不了解会一头雾水，了解之后解决便可信手拈来。针对 vue+django 架构中的两种解决方案，使用一种即可解决跨域。在使用CORS方案时，注意增加针对Cookie的携带问题的相关配置。

## 参考

- [XMLHttpRequest](https://developer.mozilla.org/zh-CN/docs/Web/API/XMLHttpRequest)
- [浏览器同源策略](https://www.cnblogs.com/laixiangran/p/9064769.html)