---
type : posts
title : 「对比Python学习Go」- 高级数据结构
categories: [Golang,] 
series: [对比Python学习Go,]
date : 2020-12-09
url: /posts/2020-12-09-go-from-python-structure-advance-1.html 
tags : [Golang, 对比Python学习Go]
---

本篇是[「对比Python学习Go」](https://pylixm.top/posts/2020-12-02-go-from-python-intro.html) 系列的第四篇，本篇文章我们来看下Go的高级数据结构。本系列的其他文章可到 [「对比Python学习Go」- 开篇](https://pylixm.top/posts/2020-12-02-go-from-python-intro.html) 查看。

> Python数据结构底层完全依赖解释器的实现方式，没有特殊说明文中数据结构对应默认解释器CPython。

从数据结构上来讲，有「数组」和「链表」两种基本的数据结构，还有很多基于他们的高级数据结构如栈、队列、散列表等等。作为编程语言，Go和Python 是如何定义自己的数据结构的呢？根据数据结构的特性，我们大致可以将Go和Python的数据结构分如下几个类型：

- 「类数组的结构」，具有数组的一些特性，但不完全是数组。
- 「哈希类型」，即key-value类型或叫map类型。
- 语言自己特有的一些高级结构。

下边我们来逐一介绍。

## 类数组结构

数组，它是一个线性表的结构。它有如下特性：

- 使用一组**连续**的内存空间来存储数据。
- 存储的数据具有**相同类型**。
  
回顾了数组的特性，我们来看下Go和Python中有哪些类数组的数据结构。

### Go

在Go语言中，有「数组」和「切片」两个类数组数据结构。

**数组**

Go的数组特性可总结如下：

- **固定长度**：这意味着数组不可增长、不可缩减。想要扩展数组，只能创建新数组，将原数组的元素复制到新数组。
- **内存连续**：意味着可以通过下标的方式(arr[index])索引数组中的元素。
- **固定类型**：固定类型意味着限制了每个数组元素可以存放什么样的数据，以及每个元素可以存放多少字节的数据。

数组的初始化和操作如下：

```golang

package main

import "fmt"

func main() {
    // 类型 [n]T是一个有 n个类型为 T的值的数组
    // 先声明，后赋值
    var a [2]string
    a[0] = "Hello"
    a[1] = "World"

    // 声明时，直接赋值
    b := [5]int{10,20,30,40,50}

    // 可直接通过下标来访问数组
    fmt.Println(a)
    fmt.Println(a[0], a[1])
    fmt.Println(b)
    fmt.Println(b[1], b[2])

    // 通过len()函数可获取数组长度
    fmt.Println(len(a))
    fmt.Println(len(b))

    // 数组元素赋值
    b[1] = 25
    fmt.Println(b)
    fmt.Println(b[1])

}

```
除了普通数组之外，还有多维数组，即数组的数组。

```golang
// 声明一个二维整型数组，两个维度分别存储 4 个元素和 2 个元素
var arr [4][2]int
arr[0] = [2]int{10, 11}
arr[0][1] = 15

// 声明时，直接赋值
arr1 := [4][2]int{{10, 11}, {20, 21}, {30, 31}, {40, 41}}

// 声明时，使用下标赋值
arr2 := [4][2]int{1: {20, 21}, 3: {40, 41}}
arr3 := [4][2]int{1: {0: 20}, 3: {1: 41}}

// 使用数组类初始化数组
var arr4 [2]int = arr1[1]
// 使用数组元素来赋值普通元素
var value int = arr1[1][0]

// 使用索引获取数组值
fmt.Println(arr)
fmt.Println(arr1)
fmt.Println(arr1[0][1])
fmt.Println(arr2)
fmt.Println(arr3)
fmt.Println(arr4)
fmt.Println(value)

// [[10 15] [0 0] [0 0] [0 0]]
// [10 15]
// [[10 11] [20 21] [30 31] [40 41]]
// 11
// [[0 0] [20 21] [0 0] [40 41]]
// [[0 0] [20 0] [0 0] [0 41]]
// [20 21]
// 20

```

数组中未被初始化的元素，会自动初始化为各类型对应的「零值」。


**切片**

Go的数组长度是固定的，内存空间中存储了数据值，当存储的量特别大的时候，使用起来极不方便。在Go语言中，除了数组还定义了一个类数组结构，叫做「切片（slice）」。

切片是数组段的描述符。它由一个指向底层**数组的指针**，数组段**长度**及其**容量**（段的最大长度）组成。切片更像是数组的引用类型，而数组则是值类型。其结构如下：

![slice](https://gitee.com/pylixm/picture/raw/master/2020-12-14/1607933189325-slice.png)

在Go的编程中，由于数组的各种局限性，对数据集合类型的操作处理时，切片是首选的数据结构。切片的底层数据存储还是数组，所以数组的一些特性切片也有。

```golang
// 切片使用make(slice, len, cap) 声明, cap可省略，省略时，等于len
sli := make([]int, 2, 3)
fmt.Println(sli)  // 未赋值时，各元素为对应的零值
fmt.Printf("%p %v %v \n", sli, len(sli), cap(sli))

// 声明时，初始化
nums := []int{10, 20, 30, 40}
fmt.Println(nums)
fmt.Printf("%p %v %v \n", nums, len(nums), cap(nums))

// nil 切片，指针为空，长度和容量为0
var nums1 []int
fmt.Println(nums1)

// 空切片，指针为指向一个空数组，长度和容量为0
var nums2 = make([]int, 0)
nums3 := []int{}
fmt.Println(nums2)
fmt.Println(nums3)

nums[0] = 12
fmt.Println(nums)

// 从切片创建切片
fmt.Println(nums)
fmt.Println(nums[1:2]) // 长度为2-1 =1，容量1
fmt.Println(nums[1:2:4]) // 长度为2-1=1，容量为4-1=3
//slice[i:]  // 从 i 切到最尾部
//slice[:j]  // 从最开头切到 j(不包含 j)
//slice[:]   // 从头切到尾，等价于复制整个 slice

// 切片的追加, 使用内建函数 append(src, item) 返回 新的切片
nums = append(nums, 10) // 添加一个
nums = append(nums, 10, 20) // 同时添加多个
newNums := append(nums, nums1...)  // 合并两个切片
fmt.Println(newNums)
fmt.Println(nums)

// 切片的复制, 使用内建函数 copy(dst, src) 返回复制的元素个数
// 赋值时，接收的切片容量需要大于原切片，否则复制失败，且不会报错
copyNums := make([]int, 5)
count := copy(copyNums, nums)
fmt.Println(count)
fmt.Println(copyNums)
fmt.Println(nums)
```

上面说到，Go的切片归根接地是一个数据段的描述符。底层是引用的数组结构，当多个切片同时引用一个数组时，使用下标来修改切片，则会相互的影响，使用时，一定要注意。

```golang 
// 数组共享的切片
sli := make([]int, 3)  // 定义一个长度，大小都为3的切片
sli1 := sli[:2]  // 由切片再创建切片，sli 和sli1 底层引用同一个数组
// slice: 0xc0000160c0 ,len: 3 ,cap: 3
fmt.Printf("slice: %p ,len: %v ,cap: %v \n", sli, len(sli), cap(sli))
// slice1: 0xc0000160c0 ,len: 2 ,cap: 3
fmt.Printf("slice1: %p ,len: %v ,cap: %v \n", sli1, len(sli1), cap(sli1))


sli[0] = 10
fmt.Println(sli)   // [10 0 0]
fmt.Println(sli1)  // [10 0]

```

切片的容量，可在使用中动态增长。切片的动态增长是通过内置函数 `append()` 来实现的，它会自动的处理好切片扩缩容的所有细节。扩容长度通常是原来切片容量的一倍，当容量大于1024时，增长变为原来容量的1/4倍。

```golang
// 切片扩容
fmt.Printf("%p %v %v \n", sli, len(sli), cap(sli)) // 0xc0000160c0 3 3
sli = append(sli, 1)
sli = append(sli, 2)
fmt.Println(sli)  // [10 0 0 1 2]
fmt.Printf("%p %v %v \n", sli, len(sli), cap(sli)) // 0xc00001a0c0 5 6

```

上边代码中sli长度为3，容量为3。append 元素之后，因为容量已经被占满，所以自动扩容了一倍的容量，经过两次append之后，长度变为5，容量为6。除了长度和容量外，大家可能发现了，数组地址变了，这说明append函数在扩容的时候，会创建一个新的底层数组，而并非在原数组上进行直接追加扩容。

append 函数扩容创建新数组，这时候再通过下标来修改数据或继续执行append是不会覆盖原底层数组的，因为已经不是一个数组了。这个特点经常被用在从一个切片创建另一个切片时，防止切片赋值相互影响。

```golang
sli := make([]int, 3)  // 定义一个长度，大小都为3的切片
fmt.Println(sli)  // [0 0 0]
sli1 := sli[:3:3]  // sli1 长度3-0=3，容量为3-0=3 
fmt.Println(sli1)  // [0 0 0]
fmt.Printf("%p %v %v \n", sli, len(sli), cap(sli))  // 0xc0000160c0 3 3 
fmt.Printf("%p %v %v \n", sli1, len(sli1), cap(sli1))  // 0xc0000160c0 3 3 
sli1 = append(sli1, 2)  // 容量已满，新创建底层数组
fmt.Printf("%p %v %v \n", sli1, len(sli1), cap(sli1))  // 0xc00001a0c0 4 6 

```

### Python

Python 中的类数组数据结构，为列表（List）和元组（tuple）。

**List**

列表，与数组相比，更为高级，列表的底层结构如下：

```c
typedef struct {
    PyObject_VAR_HEAD  
    PyObject **ob_item;
    Py_ssize_t allocated;
} PyListObject;
```
抛去公共的头部变量`PyObject_VAR_HEAD`，列表由一个指针数组`ob_item`，和一个容量`allocated`组成。结构如下：

![list](https://gitee.com/pylixm/picture/raw/master/2020-12-14/1607946372784-list.png)

列表中，并未存储实际的数值，而是存储了数值的引用地址，引用地址可以指向任意类型的数据，也就可以理解为什么列表中可以有任意类型的元素了。另一个，列表中引用地址的大小相同，保存在一个连续的存储空间，也就有了数组的一些特性，可以通过下标快速定位。

根据列表底层结构和 Python 官方文档 [How are lists implemented in CPython?](https://docs.python.org/3/faq/design.html#how-are-lists-implemented-in-cpython) 总结List有如下特性：

- 列表元素可以使用下标索引取值，各元素是有位置顺序的，底层为连续的存储空间。
- 列表中存储的是数据的内存地址，并非真实数据。所以从上层结构看，list列表可以存储任意类型，即列表元素中的内存地址可以是指向任意类型的。
- 可以任意添加新元素，要能不断地添加新元素，其使用了「动态扩充」的策略。扩容策略的增长倍数大致是这样的：0, 4, 8, 16, 24, 32, 40, 52, 64, 76...，参考源码 [listobject.c](https://github.com/python/cpython/blob/master/Objects/listobject.c#L67)。

列表的初始化及操作如下：

```python
# 列表的初始化
l1 = []  # 推荐，更快速
l2 = list()
l3 = [1,2,3,4]

# 列表相加
print(l1+l2)
print(l1*2)  # 可使用*来复制列表

l3 += l1
print(l3)

# 列表取值
print(l1[2])
print(l3[1:2])  # 从下标1到下标2
print(l3[1:])  # 到结尾
print(l3[:2])  # 从0开始

# 列表的长度
print(len(l1))

# 删除索引为3的元素
del l1[3] 

```
Python 的列表作为内建的高级数据结构，实现了一系列的操作功能函数。

```python
dir(list)
['__add__', '__class__', '__contains__', '__delattr__', '__delitem__', '__dir__', '__doc__',
 '__eq__', '__format__', '__ge__', '__getattribute__', '__getitem__', '__gt__', '__hash__',
 '__iadd__', '__imul__', '__init__', '__init_subclass__', '__iter__', '__le__', '__len__',
 '__lt__', '__mul__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__reversed__',
 '__rmul__', '__setattr__', '__setitem__', '__sizeof__', '__str__', '__subclasshook__',
 'append', 'clear', 'copy', 'count', 'extend', 'index', 'insert', 'pop', 'remove', 'reverse', 'sort']

l1 = [1, 2, 3, 4, 5]
l2 = [6, 7, 8, 9, 10]

# 列表追加
l3 = l1.append(6)

# 列表合并
l4 = l1.extend(l2)

# 列表元素的索引
print(l1.index(2))  # 2在l1列表中的索引

# 插入列表元素
print(l1)  # [1, 2, 3, 4, 5, 6, 6, 7, 8, 9, 10]
l1.insert(2, 12)  # 在索引为2的位置插入值12，原值及后边的值后移。
print(l1)  # [1, 2, 12, 3, 4, 5, 6, 6, 7, 8, 9, 10]

# 弹出列表指定索引的元素
num = l1.pop()  # 默认为最大索引
print(num)  # 10
print(l1)  # [1, 2, 12, 3, 4, 5, 6, 6, 7, 8, 9]
num = l1.pop(3)  # 弹出索引为3的元素，后边的元素前移
print(l1)  # [1, 2, 12, 4, 5, 6, 6, 7, 8, 9]

# 删除指定值的元素
print(l1)  # [1, 2, 12, 4, 5, 6, 6, 7, 8, 9]
l1.remove(2)  # 删除值为2的元素, 后边的元素前移
print(l1)  # [1, 12, 4, 5, 6, 6, 7, 8, 9]

# 清空列表
print(l1)  # [1, 12, 4, 5, 6, 6, 7, 8, 9]
l1.clear()  # 清空列表l1
print(l1)  # []

# 列表排序
print(l2)  # [6, 7, 8, 9, 10]
l2.sort()
print(l2)  # [6, 7, 8, 9, 10]
l2.reverse()
print(l2)  # [6, 7, 8, 9, 10]

```

除了列表自带的一些操作，还适用一些内建的函数。

```python
# sorted 排序函数
print(l2)
l21 = sorted(l2, key=lambda x: x, reverse=False)
print(l21)

```

**元组**

Python 中除了列表，还有元组比较像数组。元组和列表相似，只是不能增加、删除、修改。底层结构如下：

```c
typedef struct {
    PyObject_VAR_HEAD
    PyObject *ob_item[1];
} PyTupleObject;
```
除了头字段，只有一个指针数组。没有想列表一样的容量字段`allocated`，这正映了元组的不可变特性。除了元素的不可变特性外，其他和列表一样，是列表类型的一个子集。

你可能会有这样的疑问，都有列表了，元组存在的意义在哪里？元组相比于列表，有以下几点优势：

- 1. 因为元素不可变性，它可以作为哈希类型的key值。这样使的key的描述意义更丰富，更易理解。
- 2. 对于元组，解释器会缓存一些小的静态变量使用的内存，这样在初始化时，就比列表快。


元组的初始化及常用操作：

```python

# 元组的初始化
a = (1, 2, 3)
b = ('1', [2, 3])
c = ('1', '2', (3, 4))
d = ()
e = (1,)  # 元组中只有一个元素时，需要使用逗号结尾

print(a, b, c, d, e)
# (1, 2, 3) ('1', [2, 3]) ('1', '2', (3, 4)) () (1,)

# 下标获取值
print(a[1])  # 2

# 元组合并
print(a+b)  # (1, 2, 3, '1', [2, 3])

# 内建函数使用
# 元组长度
print(len(a))  # 3

# 使用 * 是复制指针
f = a*2
print(f)  # (1, 2, 3, 1, 2, 3)
print(id(f[0]))  # 4376435920
print(id(a[0]))  # 4376435920
print(id(f[3]))  # 4376435920


# 无法更新编辑
# a[0] = 1
# Traceback (most recent call last):
#   File "/Users/deanwu/projects/01_LearnDocs/learn_codes/python/python_list.py", line 15, in <module>
#     a[0] = 1
# TypeError: 'tuple' object does not support item assignment

# 无法删除
# del a[0]
# Traceback (most recent call last):
#   File "/Users/deanwu/projects/01_LearnDocs/learn_codes/python/python_list.py", line 21, in <module>
#     del a[0]
# TypeError: 'tuple' object doesn't support item deletion

```

## 哈希结构

https://zhuanlan.zhihu.com/p/33496977

## 独有数据结构

### Go - 指针

### Go - 结构体 

### Python - 集合/元组

### Python - 迭代器/生成器


## 总结 

本篇我们我学习了Go和Python的高级数据结构中类数组的结构，它们都有一些数组的特性，但又都有自己语言的特点。Go的切片和Python的列表，底层都基于数组，但Go的切片更像是数组的描述符指针，而Python的列表，则是使用地址和数据分开存储，引用地址使用连续空间存储，继承数组快速查找的优点，外部存储实现任意类型元素的存储。整体下来，甚是巧妙。

不管何种语言，我们在使用时，既要了解结构的基本用法，还要了解其底层的逻辑结构，才能避免在使用时的一些莫名的坑。



## 扩展阅读

- [Golang slice](https://www.cnblogs.com/sparkdev/p/10704614.html)
- [python中的list类型](https://www.cnblogs.com/yifeixu/p/8893823.html)
- [CPython中list的实现](https://www.laurentluce.com/posts/python-list-implementation/)
- [listobject.c](https://github.com/python/cpython/blob/master/Objects/listobject.c)