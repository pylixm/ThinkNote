---
type : posts
title : FastApi 纯 SQLAlchemy 异步试用 
categories: [FastApi,] 
date : 2021-03-24
url: /posts/2021-03-24-fastapi-sqlalchemy.html 
tags : [FastApi, SQLAlchemy]
---

今天整理邮件看到 SQLAlchemy 发布了 1.4 版本，其中针对异步的相关功能完全开发了出来，包括 core 和 ORM 的异步能力。虽然文档中说异步功能还处于 alpha 阶段，API随时可能变动，但并不影响我们来尝鲜测试。

FastApi 组件的 ORM 模块中，使用了两个组件 SQLAlchemy 和 databases（encode 开源的异步链接库）。这下我们可以把 databases 去掉了。

之前我分享了一个 FastApi 的使用demo代码（https://github.com/pylixm/docker-fastapi-demo），我们在它上面修改。

去除异步链接库databases，使用纯SQLAlchemy构建异步回话 session。

```python
# https://github.com/pylixm/docker-fastapi-demo/blob/e6719e0de878fdfb7cd1dc655bb22614876e059a/core/db.py#L22
# async
# mysql+aiomysql://user:password@host:port/dbname
async_engine = create_async_engine(
    SQLALCHEMY_ASYNC_DATABASE_URL, echo=True,
)

async_session = sessionmaker(
        async_engine, expire_on_commit=False, class_=AsyncSession
    )
```

为实现 session 回话的重复使用，我们把它挂到app 实例上。

```python
# https://github.com/pylixm/docker-fastapi-demo/blob/e6719e0de878fdfb7cd1dc655bb22614876e059a/main.py#L28

    @app.on_event("startup")
    async def startup():
        app.state.se = async_session()
```

View 视图中直接调用 session 回话来操作数据库。

```python
# https://github.com/pylixm/docker-fastapi-demo/blob/e6719e0de878fdfb7cd1dc655bb22614876e059a/service/views.py#L11

@router.get('/')
async def index(request: Request):
    print(posts.select())
    # post_list = await database.fetch_all(query=posts.select())
    post_list = await request.app.state.se.execute(posts.select())
    return templates.TemplateResponse(
        'index.html',
        {
            'request': request,
            'post_list': post_list
        }
    )

```

完整代码，可见GitHub：https://github.com/pylixm/docker-fastapi-demo/tree/sqlalchemy_async

这样，我们就把 databases 组件去除了，ORM 层只用 SQLAlchemy 来实现。我们在后期的开发和维护中，只关心 SQLAlchemy 技术栈便可以了。



