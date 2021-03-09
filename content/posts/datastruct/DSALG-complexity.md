---
type : posts
title : 数据结构与算法 - 复杂度分析
categories: [数据结构与算法,] 
series: [数据结构与算法笔记,]
date : 2019-09-20
url: /posts/2019-09-20-complexity.html 
tags : [数据结构与算法, 复杂度分析]
---

> 《数据结构与算法-王争》学习笔记，记录备查

数据结构与算法，说到底是「快」和「省」的问题。那么如何衡量快和省，这就是「复杂度分析」做的事情。

复杂度算法分为**空间复杂度**和**时间复杂度**。

## 基本概念

### 为什么需要复杂度分析

- 系统的测试结果非常依赖测试环境。在不同的环境中，相同的程序执行效果可能不同。不能简单的使用“运行程序测试”来衡量程序的优劣。

- 测试结果受数据规模的相应很大。程序处理数据规模的不同，对结果也是有影响的。

所以，我们需要一个不用具体的测试数据来测试，就可以粗略地估计算法的执行效率的方法。

### 大O 复杂度表示法

程序中，我们简单的假设为每行的代码的执行时间相同，那么我们代码的执行时间和代码的执行次数成正比。总结这个规律得到如下公式：

> T(n) = O(f(n))

- `T(n)` 执行的时间
- `n` 表示数据规模的大小，每行代码的执行次数。
- `f(n)` 代码执行次数的总和。
- `O` 表示执行时间`T(n)`与`f(n)`成正比。

这就是大 O 时间复杂度表示法。大 O 时间复杂度实际上并不具体表示代码真正的执行时间，而是表示代码执行时间随数据规模增长的变化趋势，所以叫做渐进时间复杂度（asymptotic time complexity）,简称「时间复杂度」。

因为，随着n的增长，公式中的低阶、常量、系数并不左右增长趋势，所以公式可以简写为：`T(n)=O(n)`。

## 时间复杂度

上边已经说了什么是时间复杂度。即代码执行时间随数据规模的增长的变化趋势。

### 简单分类

**最好、最坏情况时间复杂度**

- 最好情况时间复杂度就是，在最理想的情况下，执行这段代码的时间复杂度。
- 最坏情况时间复杂度就是，在最糟糕的情况下，执行这段代码的时间复杂度。

**平均情况时间复杂度**

- 顾名思义，平均情况时间复杂度就是，各种复杂度的平均值。考虑到各种复杂度的概率，所以平均时间复杂度全称叫「加权平均时间复杂度」或「期望时间复杂度」。

大多数情况下，我们无需使用这三种复杂度，只有算法或程序在不同环境有量级的差别时，我们才使用。

**均摊时间复杂度**

- 在代码执行的所有复杂度情况中绝大部分是低级别的复杂度，个别情况是高级别复杂度且发生具有时序关系时，可以将个别高级别复杂度均摊到低级别复杂度上。基本上均摊结果就等于低级别复杂度。

### 如何分析时间复杂度 

**1、只关注循环执行次数最多的一段代码**

上边说了，`T(n)`和低阶、常量、系数没有关系，只需要记录一个最大阶的量及就可以了，所以说，我们在分析一个算法、一段代码的时间复杂度的时候，也只关注循环执行次数最多的那一段代码就可以了。

**2、加法原则：总复杂度等于量级最大的那段代码的复杂度**

总的时间复杂度就等于量级最大的那段代码的时间复杂度，总结公式如下：

>如果T1(n)=O(f(n))，T2(n)=O(g(n))；那么，T(n)=T1(n)+T2(n)=max(O(f(n)), O(g(n)))=O(max(f(n), g(n)))

**3、乘法法则：嵌套代码的复杂度等于嵌套内网代码复杂度的乘积**

>如果 T1(n)=O(f(n))，T2(n)=O(g(n))；那么， T(n)=T1(n)*T2(n)=O(O(f(n))*O(g(n)))=O(f(n)*g(n))

### 常用时间复杂度实例分析

- 常量阶：`O(1)`
- 指数阶：`O(2^n)`
- 对数阶：`O(logn)`
- 阶乘阶：`O(n!)`
- 线性阶：`O(n)`
- 线性对数阶：`O(nlogn)`
- 平方阶 `O(n^2)`、立方阶`O(n^3)`.... k次方阶`O(n^k)`

可分为两类：多项式量级和非多项式量级。其中 `O(2n)` 和 `O(n!)`为非多项式量级，其他都为多项式量级。

![](/static/imgs/complexity/complexity.jpg)

**常量阶**

一般情况下，只要算法中不存在循环语句、递归语句，即使有成千上万行的代码，其时间复杂度也是`O(1)`;

**对数阶O(logn)、O(nlogn)**


```c
i=1;
while (i <= n)  {
  i = i * 2;
}
```
如上实例，根据上边的分析原则，我们只需看第三行的代码执行次数即可。分析过程如下：

```
# 每执行一次i 乘以2，所以i的取值如下：

2^0 2^1 ... 2^k ... 2^x = n 
```
当 i 取值`2^x`时等于n，退出循环，即第三行弹代码执行了 x 次。得到如下等式：

```
2^x=n 
```
次数x和n成对数关系，即x=log2n 以2为底n对数。即第三行和执行的次数为 log2n次，时间复杂度为`O(log2n)`

对数之前是可以相互转化的，所以底数在这里是没有意义的，通过转化底数可以相互转化，不会影响复杂度。所以，以上复杂度可以简写为 `O(logn)`。

如果上边的代码执行n变，则时间复杂度为`O(nlogn)`。归并排序、快速排序时间复杂度为`O(nlogn)`。

**O(m+n)、O(m*n)**

有时候，一段代码**不能找到执行次数最大的那段或行，有两个或多个不确定的数据规模**。此时，加法原则就不适用了。时间复杂度应为`O(m+n)`，如果嵌套的话为`O(m*n)`。

## 空间复杂度

渐进空间复杂度（asymptotic space complexity），表示算法的存储空间与数据规模之间的增长关系。

- 我们说空间复杂度时，是说**除了原本数据的存储空间外，算法运行还需要额外的存储空间**。

常用的空间复杂度为：

- `O(1)`
- `O(n)`
- `O(n^2)`

分析方法可类别时间复杂度。


## 总结

低阶的复杂度的程序很大程度上优于高阶复杂度的算法和程序。但也不是绝对的，它依赖环境和数据，这点需要注意。复杂度的分析给我提供了一个抽象的不依赖环境和数据来评估算法或程序优劣的标准。让我们可以更简单的判断和书写出优质的代码。

## 参考

- 单项式：由数或字母的积组成的代数式叫做单项式，单独的一个数或一个字母也叫做单项式(例：0可看做0乘a，1可以看做1乘指数为0的字母，b可以看做b乘1)，分数和字母的积的形式也是单项式。
- 多项式：在数学中，由若干个单项式相加组成的代数式叫做多项式（若有减法：减一个数等于加上它的相反数）。多项式中的每个单项式叫做多项式的项，这些单项式中的最高项次数，就是这个多项式的次数。其中多项式中不含字母的项叫做常数项。
- 对数：在数学中，对数是对求幂的逆运算，正如除法是乘法的倒数，反之亦然。如果a的x次方等于N（a>0，且a不等于1），那么数x叫做以a为底N的对数（logarithm），记作x=logaN。其中，a叫做对数的底数，N叫做真数。
  - 特别地，我们称以10为底的对数叫做常用对数（common logarithm），并记为lg。
  - 称以无理数e（e=2.71828...）为底的对数称为自然对数（natural logarithm），并记为ln。
  - 零没有对数。 
  - 在实数范围内，负数无对数。 在虚数范围内，负数是有对数的。