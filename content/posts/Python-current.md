---
type : post
title : Python中一种轻松实现并发编程的方法 
categories: [Python,] 
series: [Python进击,]
date : 2020-05-18
url: /posts/2020-05-18-python-concurrent-feature.html 
tags : [Python, concurrent]
---

>原文地址：https://rednafi.github.io/digressions/python/2020/04/21/python-concurrent-futures.html


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

我的许多脚本包含类似这样的代码：


```python
for task in get_tasks():
    perform(task)
```

`get_tasks`返回一个迭代器，该迭代器包含有特定功能任务的目标任务和参数。任务通常会阻塞可调用对象，它们依次运行，每次只能运行一个任务。由于逻辑是顺序执行的，因此很容易理解。当任务数量少或单个任务的执行时间少复杂度较低时，没有什么大问题。但是当任务数量巨大或单个任务很耗时时，这样很快就会变得不稳定。

根据一般经验`ThreadPoolExecutor` 在主要受I/O限制的任务时使用，例如发起多个http请求，将大量文件保存到磁盘等。`ProcessPoolExecutor` 在主要受CPU限制的任务中应用。如大运算量的任务，对大量图片处理应用，一次处理多个文本文件等。

### 使用 `Executor.submit` 运行任务

当你有许多任务时，可一次性执行它们，然后等待它们全部完成，再收集结果。

```python
import concurrent.futures


with concurrent.futures.Executor() as executor:
    futures = {executor.submit(perform, task) for task in get_tasks()}

    for fut in concurrent.futures.as_completed(futures):
        print(f"The outcome is {fut.result()}")
```

这里你首先创建一个执行器，该执行器再单独的进程或线程中执行所有任务。使用`with`语句将创建一个上下文管理器，该管理器可确保`executor.shutdown()`在完成后通过隐士调用该方法来清理所有线程或进程。

在真实的代码中，你需要将`Executor`替换为`ThreadPoolExecutor`或`ProcessPoolExecutor`这些可调用的类。然后使用推导式来开始所有的任务。使用`executor.submit()`来调度每一个任务执行。每个任务执行后，会生成一个`future`对象。一旦所有的任务都完成了，`concurrent.futures.as_completed()`方法便可获取所有任务的结果。`executor.result()`返回给你任务执行函数的返回值或抛出任务失败异常。

`executor.submit()`方法是异步来调用执行任务的，并不包含任务的任何上下文信息。所以如果你想获取每个任务的信息，你需要自己处理。

```python
import concurrent.futures


with concurrent.futures.Executor() as executor:
    futures = {executor.submit(perform, task): task for task in get_tasks()}

    for fut in concurrent.futures.as_completed(futures):
        original_task = futures[fut]
        print(f"The result of {original_task} is {fut.result()}")
```

注意，`futures`是一个任务结果对应任务的一个字典结构。

### 使用`Executor.map`来运行任务

按照预定的顺序收集结果的另一种方式是使用`executor.map()`方法：

```python
import concurrent.futures


with concurrent.futures.Executor() as executor:
    for arg, res in zip(get_tasks(), executor.map(perform, get_tasks())):
        print(f"The result of {arg} is {res}")
```

注意，`map`方法会一次性全部执行所有任务，不会像正常迭代器那样是有懒惰性。如果任务在执行的时候有问题，它会立即抛出，不在继续执行。

在Python3.5+中，`executor.map()`可以设置一个参数`chunksize`。当我们使用`ProcessPoolExecutor`时，会使用该参数设置的值来分批次的执行任务。每次执行`chunksize`个任务，该参数默认为1。当使用`ThreadPoolExecutor`时，参数无效。

## 真实的例子

在开始例子之前，我们先写一个简单的装饰器，来帮助我们更好的查看执行时间。

```python
import time
from functools import wraps


def timeit(method):
    @wraps(method)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = method(*args, **kwargs)
        end_time = time.time()
        print(f"{method.__name__} => {(end_time-start_time)*1000} ms")

        return result
    return wrapper
```

这个装饰器可以这样用：

```python
@timeit
def func(n):
return list(range(n))
```

它会打印执行方法的名字和执行时间。

### 使用多线程下载和保存文件

首先，让我们从这堆URL中下载一些pdf文件，并将它们保存到我们的磁盘。这是一个I/O行的任务，我们使用`ThreadPoolExecutor`类来操作。开始之前我们先看下顺序执行的代码：

```python
from pathlib import Path
import urllib.request


def download_one(url):
    """
    Downloads the specified URL and saves it to disk
    """

    req = urllib.request.urlopen(url)
    fullpath = Path(url)
    fname = fullpath.name
    ext = fullpath.suffix

    if not ext:
        raise RuntimeError("URL does not contain an extension")

    with open(fname, "wb") as handle:
        while True:
            chunk = req.read(1024)
            if not chunk:
                break
            handle.write(chunk)

    msg = f"Finished downloading {fname}"
    return msg


@timeit
def download_all(urls):
    return [download_one(url) for url in urls]


if __name__ == "__main__":
    urls = (
        "http://www.irs.gov/pub/irs-pdf/f1040.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040a.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040ez.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040es.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040sb.pdf",
    )

    results = download_all(urls)
    for result in results:
        print(result)
```

```
>>> download_all => 22850.6863117218 ms
... Finished downloading f1040.pdf
... Finished downloading f1040a.pdf
... Finished downloading f1040ez.pdf
... Finished downloading f1040es.pdf
... Finished downloading f1040sb.pdf
```

在上边的代码块中，我定义了两个方法。`download_one`方法负责从url下载pdf文件并保存到磁盘。它会检查url中的文件是否有扩展名，如果没有，它会抛出`RunTimeError`异常。如果有扩展名，它会下载文件，并保存到磁盘。第二个方法`download_all`仅仅遍历这些URL并一次对URL应用`download_one`方法。这个顺序执行的代码大概花费了22.8s的时间。现在让我们来看下多线程版本的代码：

```python
from pathlib import Path
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed


def download_one(url):
    """
    Downloads the specified URL and saves it to disk
    """

    req = urllib.request.urlopen(url)
    fullpath = Path(url)
    fname = fullpath.name
    ext = fullpath.suffix

    if not ext:
        raise RuntimeError("URL does not contain an extension")

    with open(fname, "wb") as handle:
        while True:
            chunk = req.read(1024)
            if not chunk:
                break
            handle.write(chunk)

    msg = f"Finished downloading {fname}"
    return msg


@timeit
def download_all(urls):
    """
    Create a thread pool and download specified urls
    """

    with ThreadPoolExecutor(max_workers=13) as executor:
        return executor.map(download_one, urls, timeout=60)


if __name__ == "__main__":
    urls = (
        "http://www.irs.gov/pub/irs-pdf/f1040.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040a.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040ez.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040es.pdf",
        "http://www.irs.gov/pub/irs-pdf/f1040sb.pdf",
    )

    results = download_all(urls)
    for result in results:
        print(result)
```

```
>>> download_all => 5042.651653289795 ms
... Finished downloading f1040.pdf
... Finished downloading f1040a.pdf
... Finished downloading f1040ez.pdf
... Finished downloading f1040es.pdf
... Finished downloading f1040sb.pdf
```

这个并发版本只花费了顺序版本大约1/4的时间。注意再找个并发版本中，`download_one`方法和之前是相同的，`download_all`方法，使用了`ThreadPoolExecutor`类和`execute.map()`方法。`timeout`参数是说在这个时间之后，就放弃执行任何任务。`max_works`参数是启动多少个工作线程，一般为`2*multiprocessing.cpu_count()+1`。我的机器是6和12线程的，所以我选择启动13个线程。

> 你也可以尝试使用`ProcessPoolExecutor`类相同的接口方法来跑上边的代码。但是因为任务本身的特性，还是使用线程的性能稍好。

### 使用多进程运行CPU密集型任务

下边的示例，展示一个CPU密集型哈希函数。核心方法是顺序多次执行CPU密集型的哈希算法，另一个方法是多次执行这个核心方法。让我们来看下这点代码：

```python
import hashlib


def hash_one(n):
    """A somewhat CPU-intensive task."""

    for i in range(1, n):
        hashlib.pbkdf2_hmac("sha256", b"password", b"salt", i * 10000)

    return "done"


@timeit
def hash_all(n):
    """Function that does hashing in serial."""

    for i in range(n):
        hsh = hash_one(n)

    return "done"


if __name__ == "__main__":
    hash_all(20)
```

```
>>> hash_all => 18317.330598831177 ms
```

如果你分析`hash_one`和`hash_all`方法，会发现一个共同点，他们都有一个CPU密集的for循环代码。它大概执行花费了18s，让我们来看下使用`ProcessPoolExecutor`版本：

```python
import hashlib
from concurrent.futures import ProcessPoolExecutor


def hash_one(n):
    """A somewhat CPU-intensive task."""

    for i in range(1, n):
        hashlib.pbkdf2_hmac("sha256", b"password", b"salt", i * 10000)

    return "done"


@timeit
def hash_all(n):
    """Function that does hashing in serial."""

    with ProcessPoolExecutor(max_workers=10) as executor:
        for arg, res in zip(range(n), executor.map(hash_one, range(n), chunksize=2)):
            pass

    return "done"


if __name__ == "__main__":
    hash_all(20)
```

```
>>> hash_all => 1673.842430114746 ms
```

仔细查看代码，你会发现在`hash_one`中for循环的代码，仍然是顺序执行的。但是，在`hash_all`中的for代码块是多进程执行的。这里我用10个工作进程按每个批次2个任务来并发执行。你可以尝试调整工作进程和并发任务数，已到达最佳的性能。这个并发版本比顺序版本快了近11倍。

## 并发中常遇到的坑

`ThreadPoolExecutor`和`ProcessPoolExecutor`它适用于简单的并发任务，有循环迭代的情况或仅允许一些子程序的情况。如果你的任务需要排队，或者需要用到多进程和多线程，你任然需要使用`threading`和`multiprocessing`模块。

在使用`ThreadPoolExecutor`时，可能会出现死锁问题。当与Future相关联的可调用对象等待另一个Future的结果时，它们可能永远不会释放对线程的控制从而导致死锁。让我们来看一个示例：

```python
import time
from concurrent.futures import ThreadPoolExecutor


def wait_on_b():
    time.sleep(5)
    print(b.result())  # b will never complete because it is waiting on a.
    return 5


def wait_on_a():
    time.sleep(5)
    print(a.result())  # a will never complete because it is waiting on b.
    return 6


with ThreadPoolExecutor(max_workers=2) as executor:
    # here, the future from a depends on the future from b
    # and vice versa
    # so this is never going to be completed
    a = executor.submit(wait_on_b)
    b = executor.submit(wait_on_a)

    print("Result from wait_on_b", a.result())
    print("Result from wait_on_a", b.result())
```

在这个例子中，`wait_on_b`函数依赖`wait_on_a`函数的结果。同时`wait_on_a`函数又依赖`wait_on_b`函数的结果。所以，代码由于死锁永远不会结束。让我们看一下另一种死锁情况：

```python
from concurrent.futures import ThreadPoolExecutor


def wait_on_future():
    f = executor.submit(pow, 5, 2)
    # This will never complete because there is only one worker thread and
    # it is executing this function.
    print(f.result())


with ThreadPoolExecutor(max_workers=1) as executor:
    future = executor.submit(wait_on_future)
    print(future.result())
```

上边的代码，在一个线程中，提交了一个子执行任务。在子任务结束之前，不会释放线程，但是线程又被主任务使用，便造成死锁。使用多个线程可解决这个问题，但是这种写法本身就非常糟糕的，不提倡的。

有时候，并发代码的性能可能不顺序执行代码效率低下。发生这种情况的原因有很多：

- 1、线程用于执行CPU密集的任务。
- 2、使用多进程处理I/O密集的任务。
- 3、任务非常繁碎，无法使用多线程或多进程来处理。

生成和释放线程或进程会带来额外的开销。通常线程的操作比进程快的多，但是错误的使用反而会拖慢你的代码性能。下边是一个繁碎的示例，`ThreadPoolExecutor`和`ProcessPoolExecutor`性能均比顺序对的性能差。

```python
import math

PRIMES = [num for num in range(19000, 20000)]


def is_prime(n):
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False

    sqrt_n = int(math.floor(math.sqrt(n)))
    for i in range(3, sqrt_n + 1, 2):
        if n % i == 0:
            return False
    return True


@timeit
def main():
    for number in PRIMES:
        print(f"{number} is prime: {is_prime(number)}")


if __name__ == "__main__":
    main()
```

```
>>> 19088 is prime: False
... 19089 is prime: False
... 19090 is prime: False
... ...
... main => 67.65174865722656 ms
```

上边的示例验证列表中的数是否为质数。顺序版本大约花费了67ms完成。但是并发版本却化了 140ms 才完成。

```python
from concurrent.futures import ThreadPoolExecutor
import math

num_list = [num for num in range(19000, 20000)]


def is_prime(n):
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False

    sqrt_n = int(math.floor(math.sqrt(n)))
    for i in range(3, sqrt_n + 1, 2):
        if n % i == 0:
            return False
    return True


@timeit
def main():
    with ThreadPoolExecutor(max_workers=13) as executor:
        for number, prime in zip(PRIMES, executor.map(is_prime, num_list)):
            print(f"{number} is prime: {prime}")


if __name__ == "__main__":
    main()
```

```
>>> 19088 is prime: False
... 19089 is prime: False
... 19090 is prime: False
... ...
... main => 140.17250061035156 ms
```

相同的代码，多进程版本：

```python
from concurrent.futures import ProcessPoolExecutor
import math

num_list = [num for num in range(19000, 20000)]


def is_prime(n):
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False

    sqrt_n = int(math.floor(math.sqrt(n)))
    for i in range(3, sqrt_n + 1, 2):
        if n % i == 0:
            return False
    return True


@timeit
def main():
    with ProcessPoolExecutor(max_workers=13) as executor:
        for number, prime in zip(PRIMES, executor.map(is_prime, num_list)):
            print(f"{number} is prime: {prime}")


if __name__ == "__main__":
    main()
```

```
>>> 19088 is prime: False
... 19089 is prime: False
... 19090 is prime: False
... ...
... main => 311.3126754760742 ms
```

从直观上看，检测质数应该是CPU密集型的操作，然而事实却想不到。合理的评估任务计算是否值得使用多线程或多进程也是非常重要的。否则，我们写出的代码性能不一定更高效。

## 参考

- [concurrent.fututures- the official documentation](https://docs.python.org/3/library/concurrent.futures.html)
- [Easy Concurrency in Python](http://pljung.de/posts/easy-concurrency-in-python/)
- [Adventures in Python with concurrent.futures](https://alexwlchan.net/2019/10/adventures-with-concurrent-futures/)