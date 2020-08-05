---
type : post
title : Python中的类属性和实例属性
categories: [Python,] 
series: [Python进击,]
date : 2019-11-06
url: /posts/2019-11-06-python-class-attribute.html 
tags : [Python,]
---



## 问题 

今天在项目中遇到了个奇怪的问题，实例的一个时间属性并没有根据时间变化而变化，分析之后恍然大悟，总结下分享给大家。大家先看一段代码：

```python
import datetime
import time 


class Person(object):
    NOW = datetime.datetime.now()

    def __init__(self):
        self.now = self.NOW

    def dosomething():
      """
      使用self.now 处理了些逻辑
      """

if __name__=='__main__':
    for i in range(10):
        p = Person()
        print(p.now)
        time.sleep(1)
```

且不说代码的优劣，大家觉着最后的打印会是什么样的呢？按照逻辑分析，在`for`循环中实例化了`Person`类，而`now`属性是实例的属性，每次调用在循环中打印，输出的一定是当时循环执行到该次循环的时间，即10次循环打印出的时间是不一样的。然而结果是这样的：

```
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
2019-11-06 11:27:28.695771
```

## 分析 

这里边体现了`类属性`和`实例属性`的区别。`NOW` 属于类属性，`now`属于实例属性。我们知道类属性可以被类和实例调用，实例属性只能被实例调用。我们在日常的业务逻辑开发中，并不会特意的去区分类属性和实例属性，而是直接使用实例来调用所有的属性，几乎不会使用类来调用属性。上边的代码在`__init__`中将类属性赋值给了实例属性，调用实例属性`now`时，间接的调用了类属性`NOW`。而类属性，在类加载的时候就执行了，即获取了当时的时间。它并不会随着实例的调用而改变。

## 总结

这里总结下类属性和实例属性的区别：

- 类属性可以被类和实例调用，实例属性只能被实例调用
- 类属性不会随着实例的调用而改变
- 类属性的有效作用域只有类，实例属性的有效作用域只有本实例（**有效作用域**并非官方描述，而是我做的一个类比，大家可与作用域类别）。

其中第三句需要再解释下，当类属性被实例属性调用修改时，修改的只是实例作用域内的该属性值，并不会修改类的属性。大家可以看如下例子:

```python
class Persion(object):
    count = 0

    def __init__(self):
        self.name = '人'


if __name__ == '__main__':
    p = Persion()
    p.count += 1

    print(p.count)
    print(Persion.count)

# output 
1
0
```

## 推荐阅读

更多关于类属性和实例属性的资料，大家可阅读如下资料：

- [https://www.python-course.eu/python3_class_and_instance_attributes.php](https://www.python-course.eu/python3_class_and_instance_attributes.php)
- [https://www.geeksforgeeks.org/class-instance-attributes-python/](https://www.geeksforgeeks.org/class-instance-attributes-python/)