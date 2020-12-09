---
type : posts
title : 单文件 Django 服务构建 
categories: [Django,] 
date : 2020-11-13
url: /posts/2020-11-13-django-single-file.html 
tags : [Django, ]
---

今天在使用vue框架开发系统的时候，需要用到后端接口，但是接口还没有开发。便想使用最简单的方式构建一个极简的API服务，由于本人偏爱Django框架，便想能不能用Django框架简单的构建想Flask那样的单文件web服务。果然，被我找到了，摘录分享给大家。

```python
# app.py 
import os
import sys
from dataclasses import dataclass

from django.conf import settings
from django.core.wsgi import get_wsgi_application
from django.http import HttpResponseRedirect, JsonResponse
from django.urls import path
from django.utils.crypto import get_random_string

# django 的配置文件，相当于 settings.py 配置文件，可直接在这里添加和删除
# 下边已经是最简的Django 启动需要的参数了
settings.configure(
    DEBUG=(os.environ.get("DEBUG", "") == "1"),
    ALLOWED_HOSTS=["*"],  # Disable host header validation
    ROOT_URLCONF=__name__,  # Make this module the urlconf
    SECRET_KEY=get_random_string(
        50
    ),  # We aren't using any security features but Django requires this setting
    MIDDLEWARE=["django.middleware.common.CommonMiddleware"],
)

# 使用dataclass 装饰器模拟了 model。
@dataclass
class Character:
    name: str
    age: int

    def as_dict(self, id_):
        return {
            "id": id_,
            "name": self.name,
            "age": self.age,
        }

# 列举数据，完全可以直接使用字段来构造需要返回的数据
characters = {
    1: Character("Rick Sanchez", 70),
    2: Character("Morty Smith", 14),
}

# Django  View 部分，为方便简单直接使用 function base view  
def index(request):
    return HttpResponseRedirect("/characters/")

def characters_list(request):
    return JsonResponse(
        {"data": [character.as_dict(id_) for id_, character in characters.items()]}
    )

def characters_detail(request, character_id):
    try:
        character = characters[character_id]
    except KeyError:
        return JsonResponse(
            status=404,
            data={"error": f"Character with id {character_id!r} does not exist."},
        )
    return JsonResponse({"data": character.as_dict(character_id)})

# Django route 部分，同 url.py 
urlpatterns = [
    path("", index),
    path("characters/", characters_list),
    path("characters/<int:character_id>/", characters_detail),
]

# 构建 uwsgi 使用 application 可使用 uwsgi 等 WSGI 协议的软件启动。 
app = get_wsgi_application()

if __name__ == "__main__":
    # 引入命令行启动方式函数，方便直接启动测试, 同 manage.py 文件
    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)
```

直接运行如下命令即可启动服务：

```bash 
python app.py runserver
```

还可以使用 uwsgi 等应用程序启动。如使用 gunicorn 如下：

```bash
gunicorn app:app
```

希望可以帮助到你~ 

更多的Django 单文件的测试及构建方法可以到[Adam Johnson](https://adamj.eu/)(Django 技术委员会成员，英国Django MeetUp的组织者)的[博客](https://adamj.eu/tech/2020/10/15/a-single-file-rest-api-in-django/)查阅。

