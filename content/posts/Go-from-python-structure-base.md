---
type : posts
title : 「对比Python学习Go」- 基本数据结构
categories: [Golang,] 
series: [对比Python学习Go,]
date : 2020-12-05
url: /posts/2020-12-05-go-from-python-structure-base.html 
tags : [Golang, 对比Python学习Go]
---

> update 2020-12-13 

本篇是[「对比Python学习Go」](https://pylixm.top/posts/2020-12-02-go-from-python-intro.html) 系列的第三篇，本篇文章我们来看下Go的基本数据结构。Go的环境搭建，可参考之前的文章[「对比Python学习Go」- 环境篇](https://pylixm.top/posts/2020-12-03-go-from-python-start.html)。废话不多说，下面开始我们的对比学习。


## 基本数据类型

### Go 的基本类型

Go的基本数据类型主要如下：

```golang 
bool
string
int int8 int16 int32 int64
uint uint8 uint16 uint32 uint64 uintptr
byte // uint8 的别名
rune // int32 的别名
// 代表一个Unicode码
float32 float64
complex64 complex128
```

Go 语言本身更偏向底层，对内存占用和性能的要求更高，除了有普通的数据类型之外，还有定长的数据类型，方便在不同场景使用，提高性能。

int，uint 和 uintptr 类型在32位的系统上一般是32位，而在64位系统上是64位。官方推荐在使用整数时，首选 `int` 类型，仅当有特别的理由（你知道为什么要这么做）才使用定长整数类型或者无符号整数类型。

### Python 的基本类型

Python 的基本数据类型如下：

```python 
int 
long  # 仅在python 2 版本中有
float
complex  # 复数型
str   # 字符串 python2中有bytes（str）和unicode，python3中只有str类型 默认支持unicode编码
bool  # 布尔型 
None  # 空值类型
```

在Python中，各类型占用的字节大小有Python解释器动态分配。不同的Python版本，分配机制也略有区别。用户可使用`sys.getsizeof()`来具体查看各类型占用的字节数。Python3 中大致如下：

```base 
Bytes  type        scaling notes
28     int         +4 bytes about every 30 powers of 2
37     bytes       +1 byte per additional byte
49     str         +1-4 per additional character (depending on max width)
48     tuple       +8 per additional item
64     list        +8 for each additional
224    set         5th increases to 736; 21nd, 2272; 85th, 8416; 341, 32992
240    dict        6th increases to 368; 22nd, 1184; 43rd, 2280; 86th, 4704; 171st, 9320
136    func def    does not include default args and other attrs
1056   class def   no slots 
56     class inst  has a __dict__ attr, same scaling as dict above
888    class def   with slots
16     __slots__   seems to store in mutable tuple-like structure
                   first slot grows to 48, and so on.
```

有兴趣深入研究的，可参考这个[stackoverflow](https://stackoverflow.com/questions/449560/how-do-i-determine-the-size-of-an-object-in-python)的讨论。

其实，在大多数情况下，我们使用Python来编写代码，不用太考虑类型的占用大小问题，解释器已经帮我们做好了内存的分配。对于内存而言，我们更应该关注的是大内存占用的对象的及时释放问题。

## 常量和变量

### Go 的常量和变量 

```golang
package main

import "fmt"

// 常量定义和赋值 ，常量可以是字符、字符串、布尔或数字类型，有关键字 const 定义
const Pi = 3.14 

// 变量定义和赋值 使用关键字 var 定义
var a = "initial"
var (
  x int 
  y int 
)

func main() {

    fmt.Println(a)

    // 相同类型定义可省略前边变量的数据类型
    var b, c int = 1, 2
    fmt.Println(b, c)

    // 定义布尔型并赋值
    var d = true
    fmt.Println(d)

    // 只定义没有赋值
    var e int
    fmt.Println(e)

    // := 为变量赋值简写形式，只有在函数中才能使用。常量在哪都不能使用。
    f := "short"
    fmt.Println(f)
}
```

代码中 `e` 只定义并没有赋值，此时它会有一个默认的初始值，在Go中把这个初始值叫做「零值」。

- 数值类型为 0，
- 布尔类型为 false ，
- 字符串为 “”（空字符串）

在使用数值类型0值的时候一定要注意精度问题，在不同语言中精度要求可能不同，这很可能造成你序列化和反序列化的失败。

### Python 的常量和变量

Python 是动态，弱类型语言。在赋值前不需要声明，左侧对象的类型由值的类型确定。

```python
>>> a = 123
>>> b = '123'
>>> c = True
>>> print(type(a),type(b),type(c))
(<type 'int'>, <type 'str'>, <type 'bool'>)

a,b = 1,2  # 批量复制
c = d = 3  # 连续复制

a,b = b,a  # ab 值交换 
```

## 类型转换

### Go 


```go
// 数值型可直接使用 表达式 T(v)将值 v 转换为类型 T
var i int = 42
// int --> float64
var f float64 = float64(i)
// int --> uint 
var u uint = uint(f)

// 数值和字符串的转换 需要使用 strconv 库，它为我们提供了很多转换方法
s := "123456"
// string --> int
i, _ := strconv.Atoi(s)
fmt.Println("i type:", reflect.TypeOf(i))
// string --> int64
i64, _ := strconv.ParseInt(s, 10, 64)
fmt.Println("i64 type:", reflect.TypeOf(i64))
// string --> float64
f64, _ := strconv.ParseFloat(s, 64)
fmt.Println("f64 type:", reflect.TypeOf(f64))
// int --> string
s1 := strconv.Itoa(i) //数字变成字符串
fmt.Println("s1 type:", reflect.TypeOf(s1))
// int64 --> string
s2:=strconv.FormatInt(i64,10)
fmt.Println("s1 type:", reflect.TypeOf(s2))
```

### Python 


Python中可直接将各类型对象使用类型方法转换。

```python
n = 20 
# int --> float 
f = float(n)
# int --> str
s = str(n)
# str --> int 
n1 = int(s)
# str --> float 
f1 = float(s)

```

## 字符串操作

### Go

```golang
// strings 包提供了大多数字符串操作

name := "DeanWu"
// 相加
fmt.Println("我叫" + name)

// 下标取值
fmt.Println(name[0])  // 直接取，是对应的ascii码，需要传下
fmt.Printf("%c\n", name[0])
fmt.Println(name[:3])

// 使用内建函数len获取字符串长度
fmt.Println(len(name))

// 字符串包含
fmt.Println(strings.Contains(name, "a"))
fmt.Println(strings.Contains("failure", "a & o"))                // false
fmt.Println(strings.Contains("foo", ""))                         // true
fmt.Println(strings.Contains("", ""))                            // true

fmt.Println(strings.ContainsAny("failure", "a & o"))             // true
fmt.Println(strings.ContainsAny("foo", ""))                      // false
fmt.Println(strings.ContainsAny("", ""))                         // false
fmt.Println(strings.ContainsAny("好树结好果", "好树"))             // true

// 获取字符串索引
fmt.Println(strings.Index("Hi I'm Nick, Hi", "Nick"))                // 7
fmt.Println(strings.Index("Hi I'm Nick, Hi", "Hi"))                  // 0
fmt.Println(strings.Index("Hi I'm Nick, Hi", "abc"))                 // -1
fmt.Println(strings.LastIndex("Hi I'm Nick, Hi", "Hi"))              // 13

// 替换字符串
fmt.Println(strings.Replace("你好世界", "世界", "地球", 1))

// 大小写转化
s := "A good tree bears good fruit"
s1 := "HOW ARE YOU?"
fmt.Printf("%s\n", strings.ToUpper(s))
fmt.Printf("%s\n", strings.ToLower(s1))

// 去除字符
fmt.Printf("%q\n", strings.Trim(" Golang ", " "))
fmt.Printf("%q\n", strings.TrimLeft(" Golang ", " "))
fmt.Printf("%q\n", strings.TrimRight(" Golang ", " "))

// 字符串开头，结尾
fmt.Println(strings.HasPrefix(name, "D"))
fmt.Println(strings.HasSuffix(name, "u"))

// 字符串分割组合
arr := strings.Split(name, "e")
fmt.Println(strings.Join(arr, "e"))

// 字符串格式化
fmt.Printf("%s, %.2f \n", a, f64)
fmt.Println(fmt.Sprintf("我叫，%s", name))

/*
%v 相应值的默认格式。在打印结构体时，“加号”标记（%+v）会添加字段名
%#v 相应值的 Go 语法表示
%T 相应值的类型的 Go 语法表示
%% 字面上的百分号，并非值的占位符
%t 单词 true 或 false。
%b 二进制表示
%c 相应 Unicode 码点所表示的字符
%d 十进制表示
%o 八进制表示
%q 单引号围绕的字符字面值，由 Go 语法安全地转义
%x 十六进制表示，字母形式为小写 a-f
%X 十六进制表示，字母形式为大写 A-F
%U Unicode 格式：U+1234，等同于 “U+%04X”
%b 无小数部分的，指数为二的幂的科学计数法，与 strconv.FormatFloat 的 ‘b’ 转换格式一致。例如 -123456p-78
%e 科学计数法，例如 -1234.456e+78
%E 科学计数法，例如 -1234.456E+78
%f 有小数点而无指数，例如 123.456
%g 根据情况选择 %e 或 %f 以产生更紧凑的（无末尾的 0）输出
%G 根据情况选择 %E 或 %f 以产生更紧凑的（无末尾的 0）输出
%s 字符串或切片的无解译字节
%q 双引号围绕的字符串，由 Go 语法安全地转义
%x 十六进制，小写字母，每字节两个字符
%X 十六进制，大写字母，每字节两个字符
%p 十六进制表示，前缀 0x
*/ 
```

### Python


```python

name = "DeanWu"
# 相加
print("我叫" + name)

# 下标取值
print(name[0])
print(name[:3])

# 使用内建函数len获取字符串长度
print(len(name))

# 字符串包含
print("a" in name)

# 大小写转化
print(name.upper())
print(name.lower())

# 去除字符
print(name.strip())
print(name.rstrip())
print(name.lstrip())

# 字符串开头，结尾
print(name.startswith("D"))
print(name.endswith("u"))

# 字符串分割组合
name_list = name.split("e")
print("e".join(name_list))

# 字符串格式化
print("%s " % name )
%d	整数
%f	浮点数
%s	字符串
%x	十六进制整数

# format 格式化 
print("你好，{}".format(name))
print("你好，{0}, {1}".format(name, "我是第二个"))

# fstring 格式化
print(f'我是，{name}')
```

## 其他 

**编码**

Go 原生支持Unicode，常用编码为UTF-8。

Python2中的默认编码为ASCII编码，Python3中使用的则是UTF-8编码。

篇幅有限，更多编码问题可参考我之前总结的Python教程：[字符串与编码](https://pylixm.top/python_start/#/src/c03_start?id=%e5%ad%97%e7%ac%a6%e7%bc%96%e7%a0%81)章节

**操作符**

go操作符：

```
+    &     +=    &=     &&    ==    !=    (    )
-    |     -=    |=     ||    <     <=    [    ]
*    ^     *=    ^=     <-    >     >=    {    }
/    <<    /=    <<=    ++    =     :=    ,    ;
%    >>    %=    >>=    --    !     ...   .    :
     &^          &^=
```

python操作符：

```
+    ==   =    &   and
-    !=   +=   |   or
*    <>   -=   ^   not
/    >    *=   ~    
%    <    /=   <<   
**   >=        >>   
//   <=             

```

**关键字**

go关键字：

```golang
break    default    func    interface    select
case    defer    go    map    struct
chan    else    goto    package    switch
const    fallthrough    if    range    type
continue    for    import    return    var
```

python 关键字：


```python
>>> import keyword
>>> keyword.kwlist
['and', 'as', 'assert', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'exec', 'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'not', 'or', 'pass', 'print', 'raise', 'return', 'try', 'while', 'with', 'yield']
```

**注释**

go 注释：

```golang
// 单行注释

/*
多行
注释
*/ 
```

python 注释：

```python
# 单行注释

'''
多行
注释
'''

"""
多行
注释
"""
```

## 总结 

本篇文章我们对比学习了Go的基本数据结构，从基本数据结构的设计，我们可以看出Go的基本类型，更精细，对用户暴露出更多的可控性。在使用上，都比较简单，清晰明了。

好了，本篇到这里了，敬请期待下篇更新。

我是DeanWu，一个努力成为真正SRE的人。

---

>关注公众号「码农吴先生」, 可第一时间获取最新文章。回复关键字「go」「python」获取我收集的学习资料，也可回复关键字「小二」，加我wx，聊技术聊人生~ 

![](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f55c515758eb4effbe9555573df93bd7~tplv-k3u1fbpfcp-zoom-1.image)
