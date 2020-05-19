---
type : post
title : Python中一种轻松实现并发编程的方法 
categories: [Python,] 
series: [Python进击,]
date : 2020-05-18
url: /posts/2020-05-18-python-concurrent-feature.html 
tags : [Python, concurrent]
---

原文地址：https://rednafi.github.io/digressions/python/2020/04/21/python-concurrent-futures.html


使用Python编写并发代码需要额外的考虑一些问题，例如你手中的任务时I/O类型还是CPU密集型，是否还需要其他额外的处理才能实现并发。此外，由于全局解释锁的存在，进一步增加了编写真正的并发代码的限制。

基于现有状况，在Python中编写并发代码常常这样做：

>在Python中，如果任务时I/O绑定的，则可以使用标准库的`threading`模块，如果任务时CPU绑定的，则`multiprocessing`更合适。`threading`和`multiprocessing`API为您提供了很多控制和灵活性，但他们都是很低级别的代码，从而在我们业务核心逻辑上增加了额外的复杂性。当任务很简单的时候，不会有复杂性的问题。但是当目标任务很复杂的时候，添加并发特性会使任务变得更复杂，难以维护。

Python标准库很包含一个名为`concurrent.futrures`的模块。在Python3.2中添加了该模块，为开发人员提供了高级的异步任务接口。它是在`threading`和`multiprocessing`模块之上的通用抽象层，提供了使用线程池和进程池运行任务的接口。当你只想同时运行一段完好的代码，而不需要`threading`和`multiprocessing`API的额外模块化时，这是一个完美的工具。

## concurrent.futures 剖析

根据官方文档，

> concurrent.futures 模块为异步执行可调用对象提供了一个高级接口。

这意味着您可以通过通用的高级接口使用线程和进程异步运行子程序。该模块提供了一个名为`Excutor`的抽象类，你不能直接实例化它，而是需要使用它提供的两个子类之一来运行任务。

```
Executor (Abstract Base Class)
│
├── ThreadPoolExecutor
│   │A concrete subclass of the Executor class to
│   │manage I/O bound tasks with threading underneath
│
├── ProcessPoolExecutor
│   │A concrete subclass of the Executor class to
│   │manage CPU bound tasks with multiprocessing underneath
```

在模块内部，这两个类与池交互并管理工作单元(workers)。`Future`类用于管理Worker的计算结果。使用工作池时，应用程序会创建适当的`Executor`类（`ThreadPoolExecutor`或`ProcessPoolExecutor`）的实例，然后提交他们使其运行。启动每个任务时，将返回一个`Future`类的实例。当需要任务结果时，应用程序可以使用该`Future`对象进行阻塞，直到结果可用为止。

## Executor Objects 

由于`ThreadPoolExecutor`和`ProcessPoolExecutor`有相同的API接口，在这两种情况下，我们主要谈它们提供的两个方法。


### submit(func, args, *kwargs)

`func` 可调度对象，执行参数`args`, `kwargs`。返回一个可执行 `Future` 对象。

```python
with ThreadPoolExecutor(max_workers=1) as executor:
    future = executor.submit(pow, 323, 1235)
    print(future.result())
```
 
### map(fn, *iterables, timeout=None, chunksize=1)

除了下边部分其他同`submit`:

- 可迭代对象数据时立即收集的，不想其他情况是惰性的。
- `func` 是异步执行的，并且可以同时进行对`func`的多次调用。

返回的迭代器调用`__next__()`方法时，将会引发`concurrent.futures.TimeoutError`。从开始调用到`timeout`时间后，结果将不可用。`timeout`可以是`int`或`float`，如果未指定或者是None，则等待时间没有限制。

如果`func`调用引发异常，则从迭代器中检索其值时将已发该异常。

使用`ProcessPoolExecutor`时，此方法可将迭代项分为多个块，将其作为单独的任务提交给池。这些块的大小可以通过`chunksize`来设置。对应非常长的可迭代对象，`chunksize`与默认大小1相比，使用大的可以显著提高性能。

使用`ThreadPoolExecutor`时，`chunksize`无效。


## 运行并发任务的通用方法

