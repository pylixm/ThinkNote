---
title : Django 简单入门及最佳实践
category : django
date : 2016-05-08 18:00
tags : [django,]
---

# django 简单入门

## django 简介

Django 是由 Python 开发的一个免费的开源网站框架。

官网介绍：Django makes it easier to build better Web apps more quickly and with less code.

在各种 python web 框架中，Django是功能最全的，自身包含了从前端模板（Template）到后端逻辑（View）再到数据库端的ORM（Model）的所有功能模块。

### 特点

- 强大的数据库功能

- 自带的强大的后台功能

- 优雅的网址

- 模板系统

- 缓存系统

- 国际化

### 项目结构

Django的应用称做project。一个项目由多个应用或者apps组成。应用是一组拥有特定功能的Python包。

理论上说，每个app都必须是可以重复使用的。你可以按照自己的需要创建尽可能多的app。

django 可通过 python 的包管理工具pip 来安装。执行如下命令：

    pip install django 

安装完成后，生成django项目代码：

    django-admin.py startproject django_demo

项目目录结构如下：

```bash
    django_demo
    ├── manage.py
    └── django_demo
        ├── __init__.py
        ├── settings.py
        ├── urls.py
        └── wsgi.py
     └── app01
        ├── __init__.py
        ├── admin.py
        ├── migrations
        ├── models.py
        ├── tests.py
        └── views.py
```

**更多**

详细介绍：http://djangobook.py3k.cn/2.0/chapter01/

学习文档：http://www.ziqiangxuetang.com/django/django-tutorial.html

django1.8 中文文档：http://python.usyiyi.cn/django/index.html

django 命令总结： http://www.pylixm.cc/posts/2016-01-29-Django-cmd.html


## django 快速入门

以一个博客展示列表页面为例，说下django项目的开发流程：

### 第一步，模型设计

- 编写models

```python
# app01/models.py
from django.db import models

class Blogs(models.Model):
    title = models.CharField(r'标题',max_length=50)
    author = models.CharField(r'作者',max_length=20)
    create_time = models.DateTimeField(r'发表时间')

```

- 配置数据库，创建数据表：

```python
    # django_demo/settings.py
    ······
    INSTALLED_APPS = (
        'django.contrib.admin',
        'django.contrib.auth',
        'django.contrib.contenttypes',
        'django.contrib.sessions',
        'django.contrib.messages',
        'django.contrib.staticfiles',
        'app01',
    )
    ······
    'default': {
        'ENGINE': 'django.db.backends.mysql', # Add 'postgresql_psycopg2', 'mysql', 'sqlite3' or 'oracle'.
        'NAME': 'django_demo',                      # Or path to database file if using sqlite3.
        'USER': 'root',                      # Not used with sqlite3.
        'PASSWORD': 'root',                  # Not used with sqlite3.
        'HOST': '192.168.33.1',                      # Set to empty string for localhost. Not used with sqlite3.
        'PORT': '',                      # Set to empty string for default. Not used with sqlite3.
        'CHARSET': 'utf8'
    }
```

- 生成数据表：

```bash
#django1.7+
python manage.py makemigrations 
python manage.py migrate

#django1.7-
python manag.py syncdb
```


### 第二步，设计URL

```python
#django_demo/urls.py
from django.conf.urls import include, url
from django.contrib import admin
from app01 import views as app01_views 

urlpatterns = [
    url(r'^$', app01_views.index , name='home' ),
    #url(r'^add/(\d+)/(\d+)/$', app01_views.index, name='index'),
    url(r'^admin/', include(admin.site.urls)),
]

```

### 第三步，编写views

```python
#app01/views.py 
def index(request):
    blog_list = Blogs.objects.order_by('-create_time')[:5]
    context = {'blog_list': blog_list}
    #return render_to_response('index.html', context) # 无 request
    return render(request, 'index.html', context) # 带 request

```

### 第四步，编写template

```html
    # base.html
    <html>
        <head>
            <title>{% block title%}{% endblock%}</title>
            {% block css%}{% endblock %}
        </head>
        <body>
            {%block content%}{% endblock%}
            {% block js%}{% endblock %}
        </body>
    </html>

    #index.html 
    {% extends 'base.html' %}
    {% block title%}首页{% endblock%}

    {% block content %}
    <ul>
    {% for blog in blog_list %}
        <li>{{ blog.title }}</li>
    {% endfor %}
    </ul>
    {% endblock%}

```


# django 项目最佳实践

## django 开发环境篇

### 建议使用 virtualenv 来搭建开发环境：

    pip install virtualenv virtualenvwrapper

Linux/Mac OSX 下：

    export WORKON_HOME=$HOME/.virtualenvs
    export PROJECT_HOME=$HOME/workspace
    source /usr/local/bin/virtualenvwrapper.sh
    source ~/.bash_profile
    
Windows 下：

    pip install virtualenvwrapper-win
    
之后在此环境下，安装django 等开发包即可

    pip install django 
    

环境管理相关命令：
    
mkvirtualenv zqxt：创建运行环境zqxt

workon zqxt: 工作在 zqxt 环境 或 从其它环境切换到 zqxt 环境

deactivate: 退出终端环境

rmvirtualenv ENV：删除运行环境ENV

mkproject mic：创建mic项目和运行环境mic

mktmpenv：创建临时运行环境

lsvirtualenv: 列出可用的运行环境

lssitepackages: 列出当前环境安装了的包

### 使用 requirement 来管理环境中的包



## django配置文件管理篇

django 的配置项都在 settings 文件中，但是生成、测试和开发中的配置是不同的。这就使得我们不得不手工的修改各环境中的配置。

在使用版本管理工具时，不能够很好的发挥其功能。特从网上看了好几种方法解决此类问题，比较常用和推荐的方法如下：


### 第一种：本地设置

这个方法有一个 settings.py 文件，一些公共设置和一个特殊环境使用的 local_settings 文件。

demo：

```python
    ### settings.py 
    try:
        from proj.local_settings import *
    except ImportError:
        pass
    ### local_settings.py
    DEBUG = True
    DATABASES = {
        'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'django',
        'USER': 'django',
        'PASSWORD': '1234',
        'HOST': '',
        'PORT': '',
    }
```
优点：如果你只需要一个生产环境和开发环境的话这样很简单 —— local_settings.py 应该在源码管理的范围以外，你需要一个独立的文件来应对生产和开发环境。

缺点：这个方法限制了你对设置的权限，比如说修改 local_settings 的公共设置。但是这种方法在大多数简单的情况下都有用。


### 第二种：基于环境的管理

将各环境的配置项分模块管理，一种环境对应一个模块文件。将原来的settings.py 换成 settings 目录，结构如下

    settings
    |-- __init__.py：这个文件将让当前文件夹成为一个Python包
    |-- base.py：包含所有环境共有的设置。其他的配置文件将继承自它。
    |-- development.py：用于本地开发
    |-- testing.py：用于测试
    |-- production.py：将用于生产环境
    
通过virtualenvwrapper，我们可以配置不同的钩子，这些钩子将在激活虚拟环境前后，退出虚拟环境前后被刷新。这意味着我们可以定义一些将在虚拟环境工作周期的不同阶段运行的命令。

这些钩子保存在各虚拟环境主目录的bin文件夹下，即preactivate，postactivate，predeactivate，postdeactivate。

编辑postactivate文件，加上：
    
    export DJANGO_SETTINGS_MODULE="taskbuster.settings.development"

编辑predeactivate文件，加上：

    unset DJANGO_SETTINGS_MODULE

除了环境变量，一些秘钥可以放到虚拟环境变量中，使其只能在此环境中生效：

    #postactivate file
    export SECRET_KEY="your_secret_django_key"
    
    #predeactivate file
    unset SECRET_KEY
 
 
## django 开发篇

### models

关于models的开发建议：

- 保证模型远离任何不必要的依赖，或者导入任何的其他Django组件，比如视图。

- 不直接地引用User，而是使用更加普通的settings.AUTH_USER_MODEL来替代。

- 富模型，瘦视图。模型太大之后，也不好维护，此时可以将一组model的操作提取出来，放到service对象中。

- property cached_property 使模型的方法，可以当做属性来调用。
    
- 尽量延长QuerySets不求值的时间。

```python
    例: 合并结果集
    >>> from itertools import chain
    >>> recent = chain(posts, comments)
    >>> sorted(recent, key=lambda e: e.modified, reverse=True)[:3]
```

### views和urls

关于views和urls开发建议：

- 将视图中公共部分提取出来，做到最大限度的重用。

- 将views拆分模块，放到多个views文件中，再共同放到views目录下，以方便views的维护。

- urls的读取是自上而下的，把具有特殊性质的url放到前面，把广泛性的url放到后边。

### template 

关于模板开发建议：

- 善于使用filters，内建的filters https://docs.djangoproject.com/en/1.9/ref/templates/builtins/#ref-templates-builtins-filters

- 善于使用 tags，内建的tags https://docs.djangoproject.com/en/1.9/ref/templates/builtins/#ref-templates-builtins-tags

- 最佳实践 保证业务逻辑远离模板。

- 根据情况不同，通过设置上下文变量或者请求路径来改变活动链接的外观。

```html
    例：导航栏
    {% include "_navbar.html" with active_link='link2' %}
    
```


## 参考 

- http://blog.zedbez.com/2015/10/12/settings-different-environments-version-control/

- http://pycoders-weekly-chinese.readthedocs.io/en/latest/issue4/django-settings-for-production-and-development-best-practices.html

- https://www.gitbook.com/book/wizardforcel/django-design-patterns-and-best-practices/details

