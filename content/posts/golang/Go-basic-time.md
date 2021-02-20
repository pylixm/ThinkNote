---
type : posts
title : 「Go模块」- time
categories: [Golang,] 
date : 2020-08-17
url: /posts/2020-08-17-go-basic-time.html 
tags : [Golang, 语言学习, time]
---

## time

- 当前时间 time.Now()
- 把时间格式化成字符串(time->string) : time.Now().Format("2006-01-02 15:04:05")
- 把日期字符串转化为时间(string -> time) : time.Parse("01-02-2006", "06-17-2013")
- 把纳秒转化为时间字符串(int64 -> string): time.Unix(timestamp, 0).Format("2006-01-02 15:04:05")
- 获取当前时间纳秒时间戳 time.Now().UnixNano()
- 自己组装时间 time.Date() (看下面)
- 时间间隔多久time.Now().Truncate(时间)
  
### string to time

```go
layout := "2006-01-02 15:04:05"
str := "2016-07-25 11:45:26"
t, err := time.Parse(layout, str)
if err != nil {
    fmt.Println(err)
}
fmt.Println(t)
```

### unix 时间格式化， 将int转化为时间

```go
//普通unix时间转换
func(timestamp int64) string {
    tm := time.Unix(timestamp, 0)
    return tm.Format("2006-01-02 15:04:05")
}

// nano 纳秒转换
func(timestamp float64, nsec int64) string {
    //纳秒没什么用 前段不显示 直接将小数舍弃转化为int64
    tm := time.Unix(int64(timestamp), nsec)
    return tm.Format("2006-01-02 15:04:05")
}
```

### 组装时间

```
timeEnd := time.Date(timeNow.Year(), timeNow.Month(), timeNow.Day(), 23, 59, 59, 0, time.Local)
```

### 时间 加,减,比较


`type Duration int64` 表示一个持续的时间,单位是纳秒

- Add() 加
- Sub() 减
- Before() 比时间前的一段时间
- After()  比时间后的一段时间

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	t := time.Now()
	t2 := t.Add(24 * time.Hour) //当前时间加24小时,即明天的这个时间
	d := t2.Sub(t)
	fmt.Println(t)
	fmt.Println(t2)
	fmt.Println(d)
	if t.Before(t2) {
		//t 小 t2
		fmt.Println("t<t2")
	}
	if t2.After(t) {
    //t2大于 t 
    fmt.Println("t2>t")
		//t2-t1,相差24小时
	}
	if t.Equal(t) {
		//判断两个时间是否相等等
		fmt.Println("t=t")
	}
}
```

### 定时器

Go 里的定时器相关的函数有 time.After,time.AfterFunc,time.Tick 等

1.func After(d Duration) <-chan Time 等待一个时间段 d,然后把当前时间发送到 channel 中。与 NewTimer 等价

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println(time.Now())
	c := time.After(10 * time.Second) //返回 channel 类型,10秒后向 channel 发送当前时间
	t := <-c
	fmt.Println(t)
	tm := time.NewTimer(10 * time.Second) //NewTimer 返回 Timer 类型
	t = <-tm.C /*Timer 结构中有一个 channel C,10秒后,把当前时间发送到 C*/
	fmt.Println(t)
}
```

2.func AfterFunc(d Duration, f func()) *Timer,等待时间 d,然后调用函数 f。注意这里的 函数 f 是不带任何参数和返回值的

```go
package main

import (
	"fmt"
	"time"
)

func Test() {
	fmt.Println("Hello world!", time.Now())
}
func main() {
	fmt.Println(time.Now())
	time.AfterFunc(10 * time.Second, Test)
	var str string
	fmt.Scan(&str) /*这里主要是等待用户输入,不让进程结束,进程结束定时器也就无效了。*/
}
```
3.Tick 与 After 有点类似,唯的区别是 After 等待时间到期后,定时器就结束了。Tick 是 每隔一段时间 d 都会向 channel 发送当前时间。

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	c := time.Tick(10 * time.Second)
	for t := range c {
		fmt.Println(t)
	}
}
```

## refrence 

- [ttps://cloud.tencent.com/developer/article/1467743](https://cloud.tencent.com/developer/article/1467743)