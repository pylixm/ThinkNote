---
type : post
title : 【 python 基础系列 】 - 「译」10个一行代码的Python小技巧
categories: [Python,] 
series: [PythonTips,]
date : 2020-08-05
url: /posts/2020-08-05-10-One-liners.html 
tags : [Python, Python Tips]
---


> 作者：Andreas
>
> 原文地址：https://dev.to/devmount/10-awesome-pythonic-one-liners-explained-3doc


自从我用Python写了第一行代码以来，我就对它的简单性，出色的可读性和受欢迎「一行式」（one-liners，注释：一行代码解决复杂问题的编写风格）着迷。在下文中，我将介绍其中一些「一行式」，希望对您的下一个Python项目有用。

## 1.交换两个变量

```python
# a = 1; b = 2
a, b = b, a
# print(a,b) >> 2 1
```

让我们先看一个经典的一行式，通过简单地交换赋值位置来交换变量的值。我认为这是最直观的方法，不需要使用临时变量。它还支持使用两个以上的变量。

## 2.多变量分配

```python
a, b, *c = [1,2,3,4,5]
# print(a,b,c) >> 1 2 [3, 4, 5]
```

**交换变量**实际上是Python一次分配多个变量的一种特殊情况。在这里，您可以使用它来将列表元素分配给特定的变量，这也称为unpacking。该*会将剩余的值放到一个子列表中，然后赋值给c。这种用法也适用于列表的其他位置（例如，列表的开头或中间部分）。

## 3.对列表的相隔元素求和

```python
# a = [1,2,3,4,5,6]
s = sum(a[1::2])
# print(s) >> 12
```

这里不需要特殊的reduce函数，sum只需添加一个可迭代的项。再扩展切片语法 [::]用在这里会返回每次循环的第二个元素。您可以将其读取为[start：stop：step]，因此[1::2]可理解为从索引1的元素（第二个元素）开始，直到列表结束（第二个参数都未指定参数）。

## 4.删除列表相隔元素

```python
# a = [1,2,3,4,5]
del a[::2]
# print(a) >> [2, 4]
```
扩展切片语法也可以用于一次删除多个列表元素。

## 5.将文件读入行数组

```python
c = [line.strip() for line in open('file.txt')]
# print(c) >> ['test1', 'test2', 'test3', 'test4']
```

使用Pythons inline for循环，您可以轻松地将文件读入行数组。用`strip()`删除尾部的换行符。如果想保留它们或你不关心，则可以使用更短的「一行式」：

```python
c = list(open('file.txt'))
# print(c) >> ['test1\n', 'test2\n', 'test3\n', 'test4\n']
```

用Python读取文件真的很简单。旁注：您也可以根据需要使用此readlines()方法。

## 6.将字符串写入文件

```python
with open('file.txt', 'a') as f: f.write('hello world')
# print(list(open('file.txt'))) >> ['test1\n', 'test2\n', 'test3\n', 'test4\n', 'hello world']
```

借助该with语句，您可以直接将内容写入文件。确保使用正确的模式打开文件（这里'a'为追加内容模式）。

## 7.清单创建

```python
l = [('Hi '​ + x) ​for​ x ​in​ [​'Alice'​, ​'Bob'​, ​'Pete'​]]
# print(l) >> ['Hi Alice', 'Hi Bob', 'Hi Pete']
```

可以使用内联for循环从其他列表中动态创建列表。也可以直接修改值，例如本示例中的字符串连接。

## 8.列表映射

```python
l = list(map(int, ['1', '2', '3']))
# print(l) >> [1, 2, 3]
```

您还可以使用Pythons map()函数将每个列表元素转换为另一种类型。

## 9.集合创建

```python
squares = { x**2 for x in range(6) if x < 4 }
# print(squares) >> {0, 1, 4, 9}
```
与set类似。除了内联for循环，您甚至可以直接附加条件！

## 10.回文检查

```python 
# phrase = 'deleveled'
isPalindrome = phrase == phrase[::-1]
# print(isPalindrome) >> true
```
回文集是一系列字符，向前和向后都读取相同的字符时相同。通常，如果给定的字符串是回文，则需要使用循环和条件来检查。在Python中，您只需将字符串与其反向字符串进行比较。除了使用切片运算符之外[::-1]，您还可以使用reverse()函数来反转字符串。

## 另外，Python之禅

```python
import this
```
好吧，这个不需要多说。只需在Python shell中输入它即可，自己可以尝试😊🎉。

## 总结

我们已经看到了一些Python「一行式」示例（非常简单），这些示例功能强大且可读性强。欢迎在评论中留言，讨论你所知道的「一行式」技巧!

