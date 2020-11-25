---
type : posts
title : 「Python Tips」- 命名元祖（namedtuple）使用指南
categories: [Python,] 
series: [PythonTips,]
date : 2020-10-18
url: /posts/2020-10-18-namedtuple.html 
tags : [Python, Python Tips, 翻译]
---

> 原文地址：https://miguendes.me/everything-you-need-to-know-about-pythons-namedtuples
> 
> 作者：Miguel Brito
> 
> 译者：DeanWu 

本文将讨论python中`namedtuple`的重点用法。我们将由浅入深的介绍`namedtuple`的各概念。您将了解为什么要使用它们，以及如何使用它们，从而是代码更简洁。在学习本指南之后，你一定会喜欢上使用它。


## 学习目标

在本教程结束时，您应该能够：

- 了解为什么以及何时使用它
- 将常规元组和字典转换为`Namedtuple`
- 将`Namedtuple`转化为字典或常规元组
- 对`Namedtuple`列表进行排序
- 了解`Namedtuple`和数据类(DataClass)之间的区别
- 使用可选字段创建`Namedtuple`
- 将`Namedtuple`序列化为JSON
- 添加文档字符串(docstring)


## 为什么要使用`namedtuple`？

`namedtuple`是一个非常有趣（也被低估了）的数据结构。我们可以轻松找到严重依赖常规元组和字典来存储数据的Python代码。我并不是说，这样不好，只是有时候他们常常被滥用，且听我慢慢道来。

假设你有一个将字符串转换为颜色的函数。颜色必须在4维空间RGBA中表示。

```python
def convert_string_to_color(desc: str, alpha: float = 0.0):
    if desc == "green":
        return 50, 205, 50, alpha
    elif desc == "blue":
        return 0, 0, 255, alpha
    else:
        return 0, 0, 0, alpha
```
然后，我们可以像这样使用它：

```
r, g, b, a = convert_string_to_color(desc="blue", alpha=1.0)
```

好的，可以。但是我们这里有几个问题。第一个是，无法确保返回值的顺序。也就是说，没有什么可以阻止其他开发者这样调用

```
convert_string_to_color：
g, b, r, a = convert_string_to_color(desc="blue", alpha=1.0)
```

另外，我们可能不知道该函数返回4个值，可能会这样调用该函数：

```
r, g, b = convert_string_to_color(desc="blue", alpha=1.0)
```

于是，因为返回值不够，抛出`ValueError`错误，调用失败。

> 确实如此。但是，你可能会问，为什么不使用字典呢？

Python的字典是一种非常通用的数据结构。它们是一种存储多个值的简便方法。但是，字典并非没有缺点。由于其灵活性，字典很容易被滥用。让
我们看看使用字典之后的例子。

```python
def convert_string_to_color(desc: str, alpha: float = 0.0):
    if desc == "green":
        return {"r": 50, "g": 205, "b": 50, "alpha": alpha}
    elif desc == "blue":
        return {"r": 0, "g": 0, "b": 255, "alpha": alpha}
    else:
        return {"r": 0, "g": 0, "b": 0, "alpha": alpha}
```

好的，我们现在可以像这样使用它，期望只返回一个值：

```python
color = convert_string_to_color(desc="blue", alpha=1.0)
```
无需记住顺序，但它至少有两个缺点。第一个是我们必须跟踪密钥的名称。如果我们将其更改`{"r": 0, “g”: 0, “b”: 0, “alpha”: alpha}`为`{”red": 0, “green”: 0, “blue”: 0, “a”: alpha}`，则在访问字段时会得到`KeyError`返回，因为键`r，g，b`和`alpha`不再存在。

字典的第二个问题是它们不可散列。这意味着我们无法将它们存储在set或其他字典中。假设我们要跟踪特定图像有多少种颜色。如果我们使用`collections.Counter`计数，我们将得到`TypeError: unhashable type: ‘dict’`。

而且，字典是可变的，因此我们可以根据需要添加任意数量的新键。相信我，这是一些很难发现的令人讨厌的错误点。

好的，很好。那么现在怎么办？我可以用什么代替呢？

`namedtuple`！对，就是它！

将我们的函数转换为使用`namedtuple`：

```python 
from collections import namedtuple
...
Color = namedtuple("Color", "r g b alpha")
...
def convert_string_to_color(desc: str, alpha: float = 0.0):
    if desc == "green":
        return Color(r=50, g=205, b=50, alpha=alpha)
    elif desc == "blue":
        return Color(r=50, g=0, b=255, alpha=alpha)
    else:
        return Color(r=50, g=0, b=0, alpha=alpha)

```
与dict的情况一样，我们可以将值分配给单个变量并根据需要使用。无需记住顺序。而且，如果你使用的是诸如PyCharm和VSCode之类的IDE ，还可以自动提示补全。

```python
color = convert_string_to_color(desc="blue", alpha=1.0)
...
has_alpha = color.alpha > 0.0
...
is_black = color.r == 0 and color.g == 0 and color.b == 0
```

最重要的是`namedtuple`是不可变的。如果团队中的另一位开发人员认为在运行时添加新字段是个好主意，则该程序将报错。

```python
>>> blue = Color(r=0, g=0, b=255, alpha=1.0)

>>> blue.e = 0
---------------------------------------------------------------------------
AttributeError                            Traceback (most recent call last)
<ipython-input-13-8c7f9b29c633> in <module>
----> 1 blue.e = 0

AttributeError: 'Color' object has no attribute 'e'
```
不仅如此，现在我们可以使用它Counter来跟踪一个集合有多少种颜色。

```python
>>> Counter([blue, blue])
>>> Counter({Color(r=0, g=0, b=255, alpha=1.0): 2})
```

## 如何将常规元组或字典转换为 namedtuple

现在我们了解了为什么使用namedtuple，现在该学习如何将常规元组和字典转换为namedtuple了。假设由于某种原因，你有包含彩色RGBA值的字典实例。如果要将其转换为`Color namedtuple`，则可以按以下步骤进行：

```python
>>> c = {"r": 50, "g": 205, "b": 50, "alpha": alpha}
>>> Color(**c)
>>> Color(r=50, g=205, b=50, alpha=0)
```

我们可以利用该`**`结构将包解压缩`dict`为`namedtuple`。

> 如果我想从dict创建一个namedtupe，如何做？

没问题，下面这样做就可以了：

```python
>>> c = {"r": 50, "g": 205, "b": 50, "alpha": alpha}
>>> Color = namedtuple("Color", c)
>>> Color(**c)
Color(r=50, g=205, b=50, alpha=0)
```

通过将dict实例传递给namedtuple工厂函数，它将为你创建字段。然后，Color像上边的例子一样解压字典c，创建新实例。

## 如何将 namedtuple 转换为字典或常规元组

我们刚刚学习了如何将转换`namedtuple`为`dict`。反过来呢？我们又如何将其转换为字典实例？

实验证明，namedtuple它带有一种称为的方法`._asdict()`。因此，转换它就像调用方法一样简单。

```python
>>> blue = Color(r=0, g=0, b=255, alpha=1.0)
>>> blue._asdict()
{'r': 0, 'g': 0, 'b': 255, 'alpha': 1.0}
```

您可能想知道为什么该方法以`_`开头。这是与Python的常规规范不一致的一个地方。通常，`_`代表私有方法或属性。但是，`namedtuple`为了避免**命名冲突**将它们添加到了公共方法中。除了`_asdict`，还有`_replace`，`_fields`和`_field_defaults`。您可以在[这里](https://docs.python.org/3/library/collections.html#collections.somenamedtuple._asdict)找到所有这些。

要将`namedtupe`转换为常规元组，只需将其传递给tuple构造函数即可。

```python
>>> tuple(Color(r=50, g=205, b=50, alpha=0.1))
(50, 205, 50, 0.1)
```

## 如何对namedtuples列表进行排序

另一个常见的用例是将多个`namedtuple`实例存储在列表中，并根据某些条件对它们进行排序。例如，假设我们有一个颜色列表，我们需要按alpha强度对其进行排序。

幸运的是，Python允许使用非常Python化的方式来执行此操作。我们可以使用`operator.attrgetter`运算符。根据[文档](https://docs.python.org/3/library/operator.html#operator.attrgetter)，`attrgetter`“返回从其操作数获取attr的可调用对象”。简单来说就是，我们可以通过该运算符，来获取传递给sorted函数排序的字段。例：

```python
from operator import attrgetter
...
colors = [
    Color(r=50, g=205, b=50, alpha=0.1),
    Color(r=50, g=205, b=50, alpha=0.5),
    Color(r=50, g=0, b=0, alpha=0.3)
]
...
>>> sorted(colors, key=attrgetter("alpha"))
[Color(r=50, g=205, b=50, alpha=0.1),
 Color(r=50, g=0, b=0, alpha=0.3),
 Color(r=50, g=205, b=50, alpha=0.5)]
```

现在，颜色列表按alpha强度升序排列！

## 如何将namedtuples序列化为JSON

有时你可能需要将储存`namedtuple`转为JSON。Python的字典可以通过json模块转换为JSON。那么我们可以使用_asdict方法将元组转换为字典，然后接下来就和字典一样了。例如：

```python
>>> blue = Color(r=0, g=0, b=255, alpha=1.0)
>>> import json
>>> json.dumps(blue._asdict())
'{"r": 0, "g": 0, "b": 255, "alpha": 1.0}'
```

## 如何给namedtuple添加docstring 

在Python中，我们可以使用纯字符串来记录方法，类和模块。然后，此字符串可作为名为的特殊属性使用`__doc__`。话虽这么说，我们如何向我们的`Color namedtuple`添加docstring的？

我们可以通过两种方式做到这一点。第一个（比较麻烦）是使用包装器扩展元组。这样，我们便可以docstring在此包装器中定义。例如，请考虑以下代码片段：

```
_Color = namedtuple("Color", "r g b alpha")

class Color(_Color):
    """A namedtuple that represents a color.
    It has 4 fields:
    r - red
    g - green
    b - blue
    alpha - the alpha channel
    """

>>> print(Color.__doc__)
A namedtuple that represents a color.
    It has 4 fields:
    r - red
    g - green
    b - blue
    alpha - the alpha channel
>>> help(Color)
Help on class Color in module __main__:

class Color(Color)
 |  Color(r, g, b, alpha)
 |  
 |  A namedtuple that represents a color.
 |  It has 4 fields:
 |  r - red
 |  g - green
 |  b - blue
 |  alpha - the alpha channel
 |  
 |  Method resolution order:
 |      Color
 |      Color
 |      builtins.tuple
 |      builtins.object
 |  
 |  Data descriptors defined here:
 |  
 |  __dict__
 |      dictionary for instance variables (if defined)
```

如上，通过继承`_Color`元组，我们为namedtupe添加了一个`__doc__`属性。

添加的第二种方法，直接设置`__doc__`属性。这种方法不需要扩展元组。

```python
>>> Color.__doc__ = """A namedtuple that represents a color.
    It has 4 fields:
    r - red
    g - green
    b - blue
    alpha - the alpha channel
    """
```
注意，这些方法仅适用于`Python 3+`。

## namedtuples和数据类(Data Class)之间有什么区别？

### 功能

在Python 3.7之前，可使用以下任一方法创建一个简单的数据容器：

- namedtuple
- 常规类
- 第三方库，`attrs`

如果您想使用常规类，那意味着您将必须实现几个方法。例如，常规类将需要一种`__init__`方法来在类实例化期间设置属性。如果您希望该类是可哈希的，则意味着自己实现一个`__hash__`方法。为了比较不同的对象，还需要`__eq__`实现一个方法。最后，为了简化调试，您需要一种`__repr__`方法。

让我们使用常规类来实现下我们的颜色用例。

```python
class Color:
    """A regular class that represents a color."""

    def __init__(self, r, g, b, alpha=0.0):
        self.r = r
        self.g = g
        self.b = b
        self.alpha = alpha

    def __hash__(self):
        return hash((self.r, self.g, self.b, self.alpha))

    def __repr__(self):
        return "{0}({1}, {2}, {3}, {4})".format(
            self.__class__.__name__, self.r, self.g, self.b, self.alpha
        )

    def __eq__(self, other):
        if not isinstance(other, Color):
            return False
        return (
            self.r == other.r
            and self.g == other.g
            and self.b == other.b
            and self.alpha == other.alpha
        )
```

如上，你需要实现好多方法。您只需要一个容器来为您保存数据，而不必担心分散注意力的细节。同样，人们偏爱实现类的一个关键区别是常规类是可变的。

实际上，引入`数据类（Data Class）`的[PEP](https://www.python.org/dev/peps/pep-0557/#abstract)将它们称为“具有默认值的可变namedtuple”(译者注：Data Class python 3.7引入，参考：https://docs.python.org/zh-cn/3/library/dataclasses.html)。

现在，让我们看看如何用`数据类`来实现。

```python
from dataclasses import dataclass
...
@dataclass
class Color:
    """A regular class that represents a color."""
    r: float
    g: float
    b: float
    alpha: float
```

哇！就是这么简单。由于没有`__init__`，您只需在docstring后面定义属性即可。此外，必须使用类型提示对其进行注释。

除了可变之外，数据类还可以开箱即用提供可选字段。假设我们的Color类不需要alpha字段。然后我们可以设置为可选。

```python
from dataclasses import dataclass
from typing import Optional
...
@dataclass
class Color:
    """A regular class that represents a color."""
    r: float
    g: float
    b: float
    alpha: Optional[float]
```

我们可以像这样实例化它：

```pyuthon
>>> blue = Color(r=0, g=0, b=255)
```

由于它们是可变的，因此我们可以更改所需的任何字段。我们可以像这样实例化它：

```
>>> blue = Color(r=0, g=0, b=255)
>>> blue.r = 1
>>> # 可以设置更多的属性字段
>>> blue.e = 10
```

相较之下，`namedtuple`默认情况下没有可选字段。要添加它们，我们需要一点技巧和一些元编程。

提示：要添加`__hash__`方法，您需要通过将设置`unsafe_hash`为使其不可变`True`：

```python
@dataclass(unsafe_hash=True)
class Color:
    ...
```

另一个区别是，拆箱(unpacking)是namedtuples的自带的功能(first-class citizen)。如果希望`数据类`具有相同的行为，则必须实现自己。

```python
from dataclasses import dataclass, astuple
...
@dataclass
class Color:
    """A regular class that represents a color."""
    r: float
    g: float
    b: float
    alpha: float

    def __iter__(self):
        yield from dataclasses.astuple(self)
```

### 性能比较

仅比较功能是不够的，namedtuple和数据类在性能上也有所不同。数据类基于纯Python实现dict。这使得它们在访问字段时更快。另一方面，namedtuples只是常规的扩展tuple。这意味着它们的实现基于更快的C代码并具有较小的内存占用量。

为了证明这一点，请考虑在Python 3.8.5上进行此实验。


```python
In [6]: import sys

In [7]: ColorTuple = namedtuple("Color", "r g b alpha")

In [8]: @dataclass
   ...: class ColorClass:
   ...:     """A regular class that represents a color."""
   ...:     r: float
   ...:     g: float
   ...:     b: float
   ...:     alpha: float
   ...: 

In [9]: color_tup = ColorTuple(r=50, g=205, b=50, alpha=1.0)

In [10]: color_cls = ColorClass(r=50, g=205, b=50, alpha=1.0)

In [11]: %timeit color_tup.r
36.8 ns ± 0.109 ns per loop (mean ± std. dev. of 7 runs, 10000000 loops each)

In [12]: %timeit color_cls.r
38.4 ns ± 0.112 ns per loop (mean ± std. dev. of 7 runs, 10000000 loops each)

In [15]: sys.getsizeof(color_tup)
Out[15]: 72

In [16]: sys.getsizeof(color_cls) + sys.getsizeof(vars(color_cls))
Out[16]: 152

```

如上，数据类在中访问字段的速度稍快一些，但是它们比nametuple占用更多的内存空间。

## 如何将类型提示添加到 namedtuple

数据类默认使用类型提示。我们也可以将它们放在namedtuples上。通过导入Namedtuple注释类型并从中继承，我们可以对Color元组进行注释。

```python
from typing import NamedTuple
...
class Color(NamedTuple):
    """A namedtuple that represents a color."""
    r: float
    g: float
    b: float
    alpha: float
```

另一个可能未引起注意的细节是，这种方式还允许我们使用docstring。如果输入，help(Color)我们将能够看到它们。

```python
Help on class Color in module __main__:

class Color(builtins.tuple)
 |  Color(r: float, g: float, b: float, alpha: Union[float, NoneType])
 |  
 |  A namedtuple that represents a color.
 |  
 |  Method resolution order:
 |      Color
 |      builtins.tuple
 |      builtins.object
 |  
 |  Methods defined here:
 |  
 |  __getnewargs__(self)
 |      Return self as a plain tuple.  Used by copy and pickle.
 |  
 |  __repr__(self)
 |      Return a nicely formatted representation string
 |  
 |  _asdict(self)
 |      Return a new dict which maps field names to their values.
```

## 如何将可选的默认值添加到 namedtuple

在上一节中，我们了解了数据类可以具有可选值。另外，我提到要模仿上的相同行为，`namedtuple`需要进行一些技巧修改操作。事实证明，我们可以使用继承，如下例所示。

```python
from collections import namedtuple

class Color(namedtuple("Color", "r g b alpha")):
    __slots__ = ()
    def __new__(cls, r, g, b, alpha=None):
        return super().__new__(cls, r, g, b, alpha)
>>> c = Color(r=0, g=0, b=0)
>>> c
Color(r=0, g=0, b=0, alpha=None)
```

## 结论

元组是一个非常强大的数据结构。它们使我们的代码更清洁，更可靠。尽管与新的`数据类`竞争激烈，但他们仍有大量的场景可用。在本教程中，我们学习了使用`namedtuples`的几种方法，希望您可以使用它们。