---
type : posts
title : 「对比Python学习Go」- 流程控制
categories: [Golang,] 
series: [对比Python学习Go,]
date : 2020-12-29
url: /posts/2020-12-29-go-from-python-flow.html 
tags : [Golang, 对比Python学习Go]
---

本篇是[「对比Python学习Go」](https://pylixm.top/posts/2020-12-02-go-from-python-intro.html) 系列的第五篇，本篇文章我们来看下Go的流程控制语法。本系列的其他文章可到 [「对比Python学习Go」- 开篇](https://pylixm.top/posts/2020-12-02-go-from-python-intro.html) 查看。

编程语言的中的常用的流程控制语法主要分为如下几类：

- 顺序结构：顾名思义，从上往下顺序依次执行。
- 分支结构：根据一定的条件，来判断执行的分支。
- 循环结构；根据一定的条件，来循环执行一个代码块，当满足条件，循环退出。
- 跳转结构：执行到关键字时，跳转到指定代码块继续执行。

知道了上边的结构，下面我们来看下GO语言中的流程控制结构。

## Go 语言中的顺序结构 

顺序结构很简单，我们之前写的代码几乎都是顺序结构。代码从上往下依次执行，并没有条件判断的分支、循环和跳转。

Python 中顺序结构也是如此，代码从上往下依次执行。

## Go 语言中的分支结构

Go 语言中的分支结构，由条件和代码块组成，代码块使用大括号包括。主要有如下两中：

- 使用关键字 `if`、`else`和`else if`来实现
- 使用关键字 `switch`来实现

第一种，主要用法如下：

```golang
x:= 5.5
n:= 6.1
lim := 20.0
v := math.Pow(x, n)
// if 判断
if v < lim {
  fmt.Println(fmt.Sprint("v --->:",v))
}
// if 简约形式，可赋值加判断
if v := math.Pow(x, n); v < lim {
  fmt.Println(fmt.Sprint("v --->:",v))
}
fmt.Println(fmt.Sprint("lim --->:",lim))

// if else
if v:=math.Pow(x,n);v<lim{
  fmt.Println(fmt.Sprint("v --->:",v))
}else{
  fmt.Println(fmt.Sprint("lim --->:",lim))
}
```

第二种，switch 应用：

```golang 
// switch 后边可以直接跟值，也可以赋值加值
os := runtime.GOOS
switch os {
case "darwin":
  fmt.Println("OS X.")
case "linux":
  fmt.Println("Linux.")
default:
  fmt.Printf("%s.", os)
}

switch os := runtime.GOOS; os {
// default 分支可放任意位置
default:
  fmt.Printf("%s.", os)
case "darwin":
  fmt.Println("OS X.")
case "linux":
  fmt.Println("Linux.")
}

// switch也可以没有条件，在case处再判断
t := time.Now()
switch {
case t.Hour() < 12:
  fmt.Println("Good morning!")
case t.Hour() < 17:
  fmt.Println("Good afternoon.")
default:
  fmt.Println("Good evening.")
}
```

switch 的条件从上到下的执行，当匹配成功的时候停止。若一个条件都不匹配，则会走 default 默认分支。

对比GO的分支结构Python中就简单的多了。主要有关键字`if`、`else`、`elif`来控制。

```python
# if 单独使用
if '1':
  print('这是真的')

# if 和 else 配合使用
if False:
  print('这是假的')
else:
  print('这是真的')

# if 和 elif 配合使用
if False:
  print('这是假的')
elif True:
  print('这是真的')

# 可以横向
a = '上午好' if now_time < 12 else '下午好' 
```

这里需要注意一个问题，Python 和GO 在分支语句中的作用域并不一样。

```golang
// golang 
m := 2
if n:=2; n !=0{
n = 1
fmt.Println(n)  // 1
fmt.Println(m)
m = 4
}
fmt.Println(m)  // 4
//fmt.Println(n)  // undefined: n
```

从上边的代码执行结果，可以看到，在GO语言中，`if`语句中是一个封闭的作用域，内部可以访问外部的变量，外部不可以访问内部的变量。`if`后边的赋值语句的作用域是if结构内部的。

```python
# python 
m = 1
if m:
  n = 2
  print(n)  # 2
  print(m)  # 1
  m = 3

print(n)  # 2
print(m)  # 3

```

Python 中分支语句的作用域和外部是同一个作用域。内网可访问外部的变量，外部也可以访问内部的变量。


## Go 语言中的循环结构

Go语言中只有一种循环结构，使用 `for`来实现。没有其他关键子，但是`for`的功能得到了加强。由初始化，条件表达式，后置语句组成，其中每个部分都可以省略。

主要用法如下：

```golang
sum := 0
// 标准的for 写法
for i := 0; i < 10; i++ {
  sum += i
}
fmt.Println(sum)
//fmt.Println(i)  // undefined: i

// 省略初始化语句
for ; sum < 1000; {
  sum += sum
}
fmt.Println(sum)

// 省略初始化和后置语句，用法类似python中的while
for sum < 1000 {
  sum += sum
}

// 无限循环
for {
}

// 可使用break 来退出信息，或使用continue 跳过本次循环的之后的语句
for i := 0; i < 10; i++ {
  sum += i
  if sum > 5{
    break
    //continue
  }
  fmt.Println(sum)
}
fmt.Println(sum)

// 遍历列表
ids := []int{1,2,3,4,5,6}
for i, v := range ids{
  fmt.Println(i, v)
}

// 遍历map 
own := map[string]string{
  "name": "DeanWu",
  "age": "30",
}
for k, v := range own{
  fmt.Println(k, v )
}


```

从`i`的打印报错，我们可以看出，`for`和`if` 一样，也是有自己独立的作用域。

再看Python 的循环结构，有`for`和`while`两种关键字来实现，主要用法如下：

```python

l = [1, 2, 3, 4, 5]
sum = 0
# 遍历列表
for i in l:
    sum += i
print(sum)

# 使用内建函数range 遍历从1到5的整数
for i in range(1, 6):
    sum += i
print(sum)

# 条件语句主要用while
while i <= 5:
    sum += i
    i += 1
print(sum)

# 无限循环
while True:
    pass

# break 和 continue的使用
while True:
    if sum > 10:
        print('sum已大于10')
        break
        # continue
    sum += 1
    print(sum)
```

通过对比我们可以看到循环结构主要用来做两件事：

- 第一，遍历复杂结构，如列表、字典或map ；
- 第二，通过条件表达，来循环执行一个代码块；

只不过在Go中，使用for 来实现了上边的两种功能，在Python中，使用for 来遍历复杂结构，使用while来循环执行条件代码块。


## 总结

本篇中，我们来对比学习了Go中的流程控制结构。分支结构和循环结构在Go中都是有自己的独立作用域的。在Python中，则没有独立作用域。在使用中，一定要注意。这种无独立作用域问题，在Python中，常被叫做"作用域溢出"，这是一种语法的习惯问题，在实际的编程中经常会犯错误。Go的独立作用域则彻底避免了这种作用域的问题。

