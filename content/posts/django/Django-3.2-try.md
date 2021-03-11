---
type : posts
title : Django 3.2 新功能尝鲜
categories: [Django,] 
date : 2021-03-09
url: /posts/2021-03-09-django-3.2.html 
tags : [Django, ]
---

Django 3 版本系列的 LTS（长期支持版本）马上就要在 4 月份发布，这个版本将会陪伴我们两年之久。在新版本发布前夕来提前了解下有哪些有趣的新功能，这些功能在发布时应该不会变动了。

![image](https://gitee.com/pylixm/picture/raw/master/2021-3-10/1615385007400-image.png)

## 安装一个 3.2 的 Django 版本

截止到 3 月 9 日，已发布[Django beta2](https://github.com/django/django/releases "Django beta2")版本。Django 3.2 仅支持 Python3.6、3.7、3.8 和 3.9，安装时注意 Python 版本。

1、创建虚拟环境

```bash
$ mkdir django3
$ cd django3
$ python3.6 -m venv venv
$ source venv/bin/activate
```

2、安装 django3.2 b1

```bash
(venv) $ pip install git+https://github.com/django/django@3.2b1
```

3、创建新的项目和 app ，防止你本地环境影响，这里直接使用虚拟环境中的命令来创建

```bash
(venv) $ venv/bin/django-admin startproject django3
(venv) $ cd django3
(venv) $ python manage.py startapp blog

```

4、将 app 添加到 settings。

```python
# settings.py

INSTALLED_APPS = [
    # ...
    'blog',
]

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'django3',
        'USER': 'root',
        'PASSWORD': 'Root1024',
        'HOST': '127.0.0.1',
        'PORT': '3306',
    }
}
```

5、创建 model 用来测试：

```python
from django.db import models


class Blog(models.Model):
    title = models.CharField(max_length=1000)
    create_at = models.DateTimeField()
```

6、生成数据表：

```bash
(venv) $ python manage.py makemigrations
(venv) $ python manage.py migrate
```

7、随便构造点数据：

```python
import string
import datetime
import random
import pytz
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
sys.path.append(os.path.join(BASE_DIR, '..'))
os.environ['DJANGO_SETTINGS_MODULE'] = 'django3.settings'
import django

django.setup()

from blog.models import Blog

starting_at = pytz.UTC.localize(datetime.datetime(2020, 1, 1))
DAY = datetime.timedelta(days=1)

Blog.objects.bulk_create((Blog(
    title=''.join(random.choices(string.ascii_letters + ' ' * 10, k=random.randint(10, 20))),
    create_at=starting_at + (DAY * random.random() * 365),
) for _ in range(10000)))
```

好了，现在我们有 Django3.2 的环境了，下面开始搞起。

## 新功能体验

### 模型自增主键的类型修改

在之前的版本中，当模型中没有定义主键时，django 会自动增加一个类型为 AutoField 的字段 id作为主键，它是 IntegerField 的子类，范围为-2147483648 to 2147483647 。

在 Django 3.2 版本中，自增主键的类型替换为 BigAutoField 范围为 1 to 9223372036854775807。除此之外，在`settings`配置中显式的增加了 `DEFAULT_AUTO_FIELD` 变量。若你不想修改源数据库的字段类型话，在升级时，在`settings`中最好显式的添加如下配置：

```
DEFAULT_AUTO_FIELD = 'django.db.models.AutoField'
```

## admin 站点新的装饰器

在自定义 admin 模型展示字段的时候，之前是在所需字段直接赋值，现在使用 display 使代码变得更优雅。

```python
# docs see https://docs.djangoproject.com/en/dev/releases/3.2/#new-decorators-for-the-admin-site
from django.contrib import admin

from .models import Blog


@admin.register(Blog)
class BlogAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'create_at',
        'create_at_year',
        'title',
    )

    # 老的实现方式
    # def create_at_year(self, obj: Blog) -> str:
    #     return obj.create_at.year
    # create_at_year.admin_order_field = 'create_at__year'
    # create_at_year.short_description = 'Year created'

    @admin.display(ordering='create_at__year', description='Year created')
    def create_at_year(self, obj: Blog) -> str:
        return obj.create_at.year
```

### admin 后端支持主题配置

admin 的样式颜色采用了 css 变量来定义，我们可以直接重新 base.html 模板，在其中定义 css变量即可，不用再去重新覆盖具体的css文件。官网的例子：

```
{% extends 'admin/base.html' %}

{% block extrahead %}{{ block.super }}
<style>
:root {
  --primary: #9774d5;
  --secondary: #785cab;
  --link-fg: #7c449b;
  --link-selected-fg: #8f5bb2;
}
</style>
{% endblock %}
```

我们会看到如下的 admin 页面。

![image](https://gitee.com/pylixm/picture/raw/master/2021-3-10/1615371734860-image.png)

### Model 增加了个 JSONObject 函数

我们可以使用`JSONOject`功能函数实现自定义 json 字段的功能，如下 blog对象实例多了一个json格式的json_obj字段：

```python
>>> from django.db.models.functions import JSONObject, Lower, TruncDay
>>> import pytz
>>> Blog.objects.annotate(json_obj=JSONObject(title=Lower('title'), creat_year=TruncDay('create_at', tzinfo=pytz.UTC)))
>>> blog = Blog.objects.annotate(json_obj=JSONObject(title=Lower('title'), creat_year=TruncDay('create_at', tzinfo=pytz.UTC))).first()
>>> blog.json_obj
{'title': 'zjy dqaiab ', 'creat_year': '2020-02-12 00:00:00.000000'}
```

### 带省略号的分页器

Django3.2 分页器 `Paginator` 对象增加了`get_elided_page_range`方法 ，它类似`page_range` ，输出的是页数区间的生成器，会根据配置将中间页数用省略号代替。该方法有两个参数`on_each_side`和`on_ends`，省略号前边显示页数个数为`on_each_side`+1，省略号后边页数个数为`on_ends`。以后我们在写分页的时候，再也不用自己处理了，期待。

```python
>>> from django.core.paginator import Paginator
>>> page_obj = Paginator(blogs, page_size)
>>> page_obj.get_elided_page_range(on_each_side=3, on_ends=2)
<generator object Paginator.get_elided_page_range at 0x10fb2f620>
>>> list(page_obj.get_elided_page_range(on_each_side=3, on_ends=2))
[1, 2, 3, 4, '…', 999, 1000]
```

## 其他可能会用到的更新

- 覆盖索引，文档描述「[include is ignored for databases besides PostgreSQL.](https://docs.djangoproject.com/en/dev/ref/models/indexes/#django.db.models.Index.include "include is ignored for databases besides PostgreSQL.") 」，在 mysql 数据库上使用，只会创建单字段索引，mysql 中只能使用联合索引以达到覆盖查询字段的效果。
- 函数索引，文档描述[Functional indexes are ignored with MySQL < 8.0.13 and MariaDB as neither supports them.](https://docs.djangoproject.com/en/dev/ref/models/indexes/#expressions "Functional indexes are ignored with MySQL < 8.0.13 and MariaDB as neither supports them.")，但我使用 8.0.17 测试仍有语法问题，期待正式版发布吧。
- 文件上传增加新的[FileUploadHandler.upload_interrupted()](https://docs.djangoproject.com/en/dev/ref/files/uploads/#django.core.files.uploadhandler.FileUploadHandler.upload_interrupted "FileUploadHandler.upload_interrupted( "FileUploadHandler.upload_interrupted()")")信号用来通知上传中断，可以做些后续的工作。
- `QuerySet.select_for_update()` 查询锁的实现，目前支持不是很好，需要的数据库版本都比较高。「Currently, the postgresql, oracle, and mysql database backends support select_for_update(). However, MariaDB 10.3+ supports only the nowait argument and MySQL 8.0.1+ supports the nowait, skip_locked, and of arguments. The no_key argument is supported only on PostgreSQL.」期待后续更新吧。
- PostgreSQL 9.5 的上游支持将于 2021 年 2 月结束。Django3.2 支持 PostgreSQL 9.6 及更高版本。
- 对 MySQL 5.6 的上游支持将于 2021 年 4 月结束。Django 3.2 支持 MySQL 5.7 和更高版本。

## 总结

总的来说 Django3.2 并没有大的更新，延续了 3.1 的很多功能，对 Model 性能和实用性方面做了不少优化，针对 postgreSQL 偏多，有些功能要求 mysql 版本都在 8.0 以上。期待的异步功能并没有更新，看来“异步 Django”的愿望实现还需要时间。

上边完整代码可从github获取，地址为 [https://github.com/pylixm/django_32_demo](https://github.com/pylixm/django_32_demo "https://github.com/pylixm/django_32_demo")

好了，今天的分享就到这里吧，欢迎留言讨论你觉着超赞的Django新功能~ 

我是DeanWu，一个努力成为真正SRE的人。

>关注公众号「码农吴先生」, 可第一时间获取最新文章。回复关键字「go」「python」获取我收集的学习资料，也可回复关键字「小二」，加我wx拉你进技术交流群，聊技术聊人生~ 

![](https://gitee.com/pylixm/picture/raw/master/2020-12-14/deanwu_wechat.png)

## 扩展阅读

- [Mysql优化覆盖索引](https://www.haoyizebo.com/posts/e9b9d3be/ "Mysql优化覆盖索引")
- [Exciting New Features in Django 3.2](https://hakibenita.com/django-32-exciting-features "Exciting New Features in Django 3.2")