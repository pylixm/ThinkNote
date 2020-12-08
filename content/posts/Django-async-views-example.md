---
type : posts
title : Django 三个异步使用的案例
categories: [Django,] 
date : 2020-12-08
url: /posts/2020-12-08-django-async-views-example.html 
tags : [Django, Django async]
---

Django3.0 发布的时候，我尝试着用了下它的异步功能。当时它仅仅添加了对ASGI的支持（可见之前的文章 [Django 3.0 异步试用分享](https://pylixm.top/posts/2019-12-12-django-3.0.html)，直到Django3.1的发布，才支持了视图和中间件的异步，但是关键的Django ORM层还是没有异步。这就导致整体的数据存储部分没法实现异步，Django生态对第三方异步的ORM支持不是很友好，使很多用户没法真正的使用Django的整体异步功能。

很过文章在描述Django view 和中间件的异步使用方法时，因为没有ORM的异步，在view中大多数用`asyncio.sleep`来代替，并没有真实的案例。这便导致读者误认为现阶段的 Django 异步是鸡肋，完全没生产使用价值。这观点完全是错误的，下边有3个来自[Arun Ravindran（<Django设计模式和最佳实践>作者）](https://arunrocks.com/django-async-views-examples/) 的 Django 异步使用场景，供大家参考。


## Django 异步的用例

### 微服务调用

现阶段，大多数系统架构已经从单一架构进化为微服务架构，在业务逻辑中调用其他服务的接口成为常有的事情。Django 的异步view 在这种情况下，并可以很大程度上提高性能。

让我们看下作者的例子：通过两个微服务的机构来获取最后展示在home页的数据。

```python
# 同步版本
def sync_home(request):
    """Display homepage by calling two services synchronously"""
    context = {}
    try:
        # httpx 支持异步http client ，可理解为requests的升级异步版，完全兼容requests 的api。
        response = httpx.get(PROMO_SERVICE_URL)
        if response.status_code == httpx.codes.OK:
            context["promo"] = response.json()
        response = httpx.get(RECCO_SERVICE_URL)
        if response.status_code == httpx.codes.OK:
            context["recco"] = response.json()
    except httpx.RequestError as exc:
        print(f"An error occurred while requesting {exc.request.url!r}.")
    return render(request, "index.html", context)


# 异步版本
async def async_home_inefficient(request):
    """Display homepage by calling two awaitables synchronously (does NOT run concurrently)"""
    context = {}
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(PROMO_SERVICE_URL)
            if response.status_code == httpx.codes.OK:
                context["promo"] = response.json()
            response = await client.get(RECCO_SERVICE_URL)
            if response.status_code == httpx.codes.OK:
                context["recco"] = response.json()
    except httpx.RequestError as exc:
        print(f"An error occurred while requesting {exc.request.url!r}.")
    return render(request, "index.html", context)

# 异步升级版
async def async_home(request):
    """Display homepage by calling two services asynchronously (proper concurrency)"""
    context = {}
    try:
        async with httpx.AsyncClient() as client:
            response_p, response_r = await asyncio.gather(
                client.get(PROMO_SERVICE_URL), client.get(RECCO_SERVICE_URL)
            )

            if response_p.status_code == httpx.codes.OK:
                context["promo"] = response_p.json()
            if response_r.status_code == httpx.codes.OK:
                context["recco"] = response_r.json()
    except httpx.RequestError as exc:
        print(f"An error occurred while requesting {exc.request.url!r}.")
    return render(request, "index.html", context)

```

同步版本很显然，当有一个服务慢时，整体的逻辑就会阻塞等待。服务的耗时依赖最后返回的那个接口的耗时。

再看异步版本，改用了异步http client 调用，这里的写法并不能增加该view 的速度，两个协程并不能同时执行。当一个协查await时，只是将控制器交还回了事件循环，而不是立即执行本view的其他逻辑和协程。对于本view来说，仍然是阻塞的。

最后看下异步升级版，使用了[asyncio.gather](https://docs.python.org/zh-cn/3/library/asyncio-task.html?highlight=gather#running-tasks-concurrently) ，它会同时执行两个协程，并在他们都完成的时候返回。升级版相当于并发，普通版相当于串行，Arun Ravindran说效率提升了一半（有待验证）。

### 文件提取

当django 视图需要从文件提取数据，来渲染到模板中时。不管是从本地磁盘还是网络环境，都会是一个潜在的阻塞I/O操作。在阻塞的这段时间内，完全可以干别的事情。我们可以使用`aiofile`库来进行异步的文件I/O操作。

```python
async def serve_certificate(request):
    timestamp = datetime.datetime.now().isoformat()

    response = HttpResponse(content_type="application/pdf")
    response["Content-Disposition"] = "attachment; filename=certificate.pdf"
    async with aiofiles.open("homepage/pdfs/certificate-template.pdf", mode="rb") as f:
        contents = await f.read()
        response.write(contents.replace(b"%timestamp%", bytes(timestamp, "utf-8")))
    return response
```

此实例，使用了本地的磁盘文件，如果使用网络文件时，记着修改对应代码。

### 文件上传

文件上传是一个很长的I/O阻塞操作，结合 `aiofile`的异步写入功能，我们可以实现高并发的上传功能。 

```python
async def handle_uploaded_file(f):
    async with aiofiles.open(f"uploads/{f.name}", "wb+") as destination:
        for chunk in f.chunks():
            await destination.write(chunk)


async def async_uploader(request):
    if request.method == "POST":
        form = UploadFileForm(request.POST, request.FILES)
        if form.is_valid():
            await handle_uploaded_file(request.FILES["file"])
            return HttpResponseRedirect("/")
    else:
        form = UploadFileForm()
    return render(request, "upload.html", {"form": form})
```

需要注意的是，这绕过了Django的默认文件上传机制，因此需要注意安全隐患。

## 总结

本文根据Arun Ravindran的三个准生产级别的实例，阐述了Django 现阶段异步的使用。从这些例子当中可以看出，Django 的异步加上一些异步的第三方库，已经完全可以应用到生产。我们生产系统的部分性能瓶颈，特别是I/O类型的，可以考虑使用Django 的异步特性来优化一把了。

我是DeanWu，一个努力成为真正SRE的人。

---

>关注公众号「码农吴先生」, 可第一时间获取最新文章。回复关键字「go」「python」获取我收集的学习资料，也可回复关键字「小二」，加我wx，聊技术聊人生~ 

![](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f55c515758eb4effbe9555573df93bd7~tplv-k3u1fbpfcp-zoom-1.image)
