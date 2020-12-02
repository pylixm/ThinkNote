---
type : posts
title : 「Go Tips」for range 遍历时变量取值的问题分析
categories: [Golang,] 
series: [Go Tips,]
date : 2020-12-01
url: /posts/2020-12-01-for-range-point.html 
tags : [Golang, ]
---

`for range` 遍历是go语言中常用的循环结构之一，在使用循环赋值时有时候需要注意指针的引用问题。在探讨之前，先让我们来回顾下Go的指针。

## Go 指针回顾

Go 语言中有指针类型，没有指针的计算，这在一定程度上削弱了指针的功能，但也减少了指针的复杂度，给使用者带了更好的使用体验。在Go 中，类型 `*T` 是指向类型`T`的值的指针，`&`符号会生成一个指向其作用对象的指针，`*`符号表示指针指向的底层的值。如下：

```go
var p *int      // 定义一个指针p 
i := 42         // 初始化一个整数类型 i 
p = &i          // p指针指向i,或者说将 i 的指针赋值给p  
fmt.Println(*p) // 通过指针 p 读取 i
*p = 21         // 通过指针 p 设置 i
```

可参考如下图理解：

![](/static/imgs/go/pointer.jpg)

有时候当变量值很大，在函数中传来传去，就会占用大量的内存空间。指针中存了指向变量值的地址，在一定程度上可以使用指针来代替变量值，这样在函数参数传递、各种计算逻辑中，就可以节省大量空间。

## for range 遍历取值的问题

我们来看一段示意代码，代码中在`append`赋值的时候为了节省内存使用了指针。猜猜遍历结果集是什么？

```go
package main

import "fmt"

type Person struct {
	name string
}

func main() {
	arr := []Person{
		Person{"小明"},
		Person{"小刚"},
	}
	var res []*Person

	for _, v := range arr {
		res = append(res, &v)
	}
	// 遍历查看结果集
	for _, person := range res{
		fmt.Println("name-->:", person.name)
	}
}
```

看结果：

```bash
name-->: 小刚
name-->: 小刚
```

可以看到在遍历 `arr` 这个数组时，后边的值把前边的覆盖了。让我们加点打印信息：

```go
···
	for _, v := range arr {
		fmt.Printf("v 指针 %p\n", &v)
		fmt.Println("v 的值", v)
		res = append(res, &v)
  }
  fmt.Println(res)
···
```

输出如下：

```bash 
v 指针 0xc0001101e0
v 的值 {小明}
v 指针 0xc0001101e0
v 的值 {小刚}
[0xc0001101e0 0xc0001101e0]

```

可以看到在结果集中的指针是一样的，也就是说在 `for range` 的时候，v 只**初始化了一次**，之后的遍历都是在原来遍历的基础上赋值，所有v的指针（地址）并没有变。该指针指向的是最后一次遍历的v的值，所以最后结果集中，也就都成了最后遍历的v的值。

这里正确的做法是使用下标。如下：

```go 
	for i, _ := range arr {
		fmt.Printf("v 指针 %p\n", &arr[i])
		fmt.Println("v 的值", arr[i])
		res = append(res, &arr[i])
	}
```

结果： 

```bash 
v 指针 0xc0000a6020
v 的值 {小明}
v 指针 0xc0000a6030
v 的值 {小刚}
[0xc0000a6020 0xc0000a6030]
name-->: 小明
name-->: 小刚
```

## 总结 

Go 语言中的指针在一定程度上可以节省内存的占用，但在使用时一定要注意前后语言环境中是否有变动，以免造成引用同值的锅。
