---
type : post
title : Python中的类属性和实例属性-补充篇
categories: [Python,] 
series: [Python进击,]
date : 2019-11-06 
url: /posts/2019-11-06-python-class-attribute.html 
tags : [Python,]
---

上篇文章[Python中的类属性和实例属性](https://pylixm.cc/posts/2019-11-06-python-class-attribute.html)，我们探讨了类属性和实例属性引发的一个小坑。总结了类属性和实例属性的区别如下：

- 类属性可以被类和实例调用，实例属性只能被实例调用
- 类属性不会随着实例的调用而改变
- 类属性的有效作用域只有类，实例属性的有效作用域只有本实例（**有效作用域**并非官方描述，而是我做的一个类比，大家可与作用域类别）。

其实第二点可以忽略，第三点已经涵盖了。我把文章发给了小伙伴们品读，有小伙伴针对第二三条提出了不同的看法。看如下例子：

```python
class Persion(object):
    count = 0
    info = {
        'name': '小明'
    }
    info_list = []

    def __init__(self):
        self.name = '人'


if __name__ == '__main__':
    p = Persion()

    p.count = 5
    print(p.count)  # 5
    print(Persion.count)  # 0

    p.count += 5
    print(p.count) # 10
    print(Persion.count) # 0

    p.info['name'] = '小红'
    print(p.info)  # {'name': '小红'}
    print(Persion.info)  # {'name': '小红'}

    p2 = Persion()

    p2.info = {'name': 'Tom'}
    print(p2.info)  # {'name': 'Tom'}
    print(Persion.info)  # {'name': '小红'}

```

实例中，info的值被修改了，那么是否可以说「实例可以修改类属性」了呢？我们来继续分析，来看count 和info 区别，不难想到它们一个是「不可变变量（immutable type）」，一个是「可变变量（mutable type）」，这两种变量类型的区别在于内存的使用。

Python变量中实际上保存的是内存中值的引用，「不可变变量」修改时，是改变了引用，「可变变量」修改时，是改变了内存块中的值。如下：

- **不可变变量**

```python
i = 20
j = 20 
print(id(i))  # 4299177184
print(id(j))  # 4299177184  不同变量引用了同一个值

i +=1 
print(id(i))  # 4340788480  值变了，变量的引用地址也变了
```

- **可变变量**

```python
d1 = [1, 2, 3]
d2 = [1, 2, 3]
print(id(d1))  # 4514412936
print(id(d2))  # 4511850248  # 相同值，变量的引用地址不同

d1.append(4)
print(id(d1))  # 4514412936  # 值变了，变量的引用地址没变
```

说回我们讨论的问题，当修改info的`name` key 所对应的值时，实际上是修改了内存块中的值，因为实例`p`和类`Person`的info属性都是指向了统一内存地址，所以类`Person`的info属性的值也变了。而当我们直接给实例`p`的info属性赋值时，它引用的是另一个内存地址的值，虽然值和类`Person`的info相同，但是引用不同，所以当`p`的属性修改时，`Person`的info属性没有变化的。

那我们来总结一下：

- 当类的属性为不可变变量时，实例属性是对类属性值的引用，修改实例属性仅仅是修改了引用，不会修改原来的值，即不会修改类属性。
- 当类的属性为可变变量时，分下面两种情况：
  - 当直接修改实例属性时，因为是可变变量，即把内存中的值修改了，所以类属性的值也修改了。
  - 当重新赋值实例属性时，因为和类属性的引用不同，即使值改变了，也不会影响类属性的值。

那么上篇中结论有些不太严谨，需要针对「可变变量」和「不可变变量」做些区分，这里有些类似函数传参时的作用域的关系。大家在实际应用中，一定要注意「可变变量」和「不可变变量」的区别。

更多「可变变量」和「不可变变量」资料可参阅：

- [How do I pass a variable by reference?](https://stackoverflow.com/questions/986006/how-do-i-pass-a-variable-by-reference/986145#986145)
- [ Facts and Myths about Python names and values](https://www.youtube.com/watch?v=_AEJHKGk9ns)

