---
layout : post
title : Django 中如何使用 sass
categories: [Django,] 
date : 2019-07-08 12:20:00
url: /posts/2019-07-08-how-to-use-sass-in-django.html 
tags : [Django, sass]
---

作为一个运维开发，不像业务开发只专注后端业务开发即可，常常需要自己来构建前端的东西，当然系统交互体验说的过去就行，要求也没有业务系统那么高。但是还是会接触很多前端的知识，像是css、html、javascript 是必不可少的，你可以不精通，但必须会用。最近前端发展迅猛，已向着工程化大前端进发。常常开玩笑说，前端才是全栈，前后端、各平台全端通吃，现在貌似已成为事实。

今天，和大家分享下前端样式工具 `sass`如何在`Django`中应用。

## 什么是 sass 

> Sass or (Syntactically awesome style sheets) is a preprocessor scripting language that is interpreted or compiled into Cascading Style Sheets (CSS). - Wikipedia

以上是wiki百科的解释，简单来说，sass 是一种方便大家来编写css的一种高级的样式预编译语言。只所以叫「预编译」,是因为使用它的时候，需要编译成浏览器能识别的css。

官方网站：https://sass-lang.com/

`Sass` 3版本以后，新引入了`Scss`语法，它完全兼容`Css3`，并且继承了 Sass 的强大功能。关于Scss和Sass，这里不做过多解释，有兴趣的可参考官方文档介绍。

话说回来，`Sass` 除了编写方便外，还有那些优势，大家可阅读这篇经典的文章[why sass?](https://alistapart.com/article/why-sass/#section1)。

关于`Sass`的常用方法，推荐大家阅读阮老师的这篇[sass用法指南](http://www.ruanyifeng.com/blog/2012/06/sass.html)。

下面，来说下怎么在我们的常用web框架 Django 中如何集成。

## 在Django中使用sass 

下面我们来一步步的配置`Sass`。环境如下：

- Python：3.6 
- Django: 2.2 

### 创建Django项目

1、创建Python的开发虚拟环境：

```bash
$ python3 -m venv env
$ source env/bin/active 
```

2、安装`django`, 创建`django`项目；

```bash
$ pip install django
$ django-admin startproject sass_demo
```

3、增加相关配置

```python
# settings.py 

TEMPLATES = [
    {
      ...
      'DIRS': [
          os.path.join(BASE_DIR, 'templates')
      ],
    } ... 
]
```

并创建一个`index.html`模板，如下：

```html
<html>
  <head>
    <title>Django sass demo</title>
  </head>
  <body>
    <div class="content">
      Django sass demo 
    </div>
  </body>
</html>
```

运行 `python manaage.py runserver ` 检查Django项目是否配置好。

### 安装Django sass 

这里我们采用了两个Django的第三方应用[django-compressor](https://github.com/django-compressor/django-compressor) 和 [django-sass-processor](https://github.com/jrief/django-sass-processor), 分别对`css`进行压缩和编译。

1、安装django sass 应用库

```bash 
$ pip install libsass django-compressor django-sass-processor
```

2、settings 中增加如下配置

```python

INSTALLED_APPS = [
    …
    'sass_processor',
    …
]

STATICFILES_FINDERS = [
  'django.contrib.staticfiles.finders.FileSystemFinder',
  'django.contrib.staticfiles.finders.AppDirectoriesFinder',
  'sass_processor.finders.CssFinder',
]

# Django Sass 编译后css 的存放位置
SASS_PROCESSOR_ROOT = os.path.join(BASE_DIR,'static','css')

```

3、添加sass文件

创建sass 文件。

```bash
$ mkdir static && touch static/css/demo.scss
```

在`index.html` 中加入如下配置：

```html
{% load sass_tags %}
<html>
  <head>
    <title>Django sass demo</title>
    <link href="{% sass_src 'css/demo.scss' %}" rel="stylesheet" type="text/css" />
  </head>
  <body>
    <div class="content">
      Django sass demo 
    </div>
  </body>
</html>
```

`demo.scss ` 添加sass 的样式代码：

```scss
body {
  .content{
    width: 100%;
    padding: 20px;
    text-align: center;
    background: grey;
    p {
      padding: 20px;
      background: pink;
    }
  }
}
```

在浏览器，再次刷新会看到样式生效。打开开发者工具，查看html代码，会发现，sass代码已替换为css，如下：

```html
<link href="/static/css/demo.css" rel="stylesheet" type="text/css">
```

至此，整个Sass 的集成工作就完成了。

## 总结

django-compressor 和 django-sass-processor 很好的完成了css的编译和压缩工作，上文只是简单快速的描述了下配置的过程，还有更多功能大家可参阅他们的使用文档。另外他们的压缩功能是根据`Debug` 来控制的，只有生产环境，即`Debug`为false 的时候才会压缩。测试环境中，可通过添加如下参数尝试：

```python
SASS_OUTPUT_STYLE = 'compressed'
```

以上代码的完整版本，可从这里获取：https://github.com/pylixm/django-sass-demo
