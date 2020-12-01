---
type : posts
title : 「Go模块」译-深入理解Golang channel 
categories: [Golang,] 
date : 2019-05-26
url: /posts/2019-05-26-Go-diving-into-channel.html 
tags : [Golang, 语言学习]
---

>原文地址：https://itnext.io/diving-into-golang-channels-e9e610d586e8

>作者：Robert Weber

>译者：DeanWu

**直接将C++或Java编写的程序代码转化为Go，并不是一个令人满意的方式。Java程序毕竟是使用Java语言编写的，而不是GO。相反的，如果我们从一开始就从使用Go的编程方式，那么我们会得到一个完全不同的结果**。- Effective Go


golang设计的核心目标之一是开发一种可以轻松实现多线程进程和无需重新编译即可夸平台的语言。 goroutine不是线程，但是它是在线程的基础上，来并行的调度您的程序执行，以达到并行化和提高性能。因此，在使用时，必须使用线程安全的数据结构。

## 对互斥锁的误解

在传统的多线程设计中，数据结构使用锁定结构（如互斥锁和信号量）进行保护。关键部分受这些“锁”保护，资源通过阻止一个线程访问另一个线程正在写入的数据来管理，直到事务完成为止。因为即使是简单的代码行也可以分解为多个指令，因此这些锁对于维护数据完整性至关重要。正确使用时，互斥锁可以避免竞争条件和无效数据，但如果过度地使用，它们也会削弱线性线程缩放。它们给出了多线程的“错觉”，因为代码似乎运行多个线程，但实际上它们只是按顺序执行多个线程。

如下代码：

```golang
//MutexProtection on a data string
type MutexProtection struct {
	data string
	lock *sync.Mutex
} 
//NewMutextProtection ...
func NewMutextProtection() *MutexProtection {
	return &MutexProtection{lock: &sync.Mutex{}}
}
//Read the current data
func (m MutexProtection) Read() string {
	m.lock.Lock()
	time.Sleep(10*time.Millisecond) // simulates "work" done to retrieve the data
	m.lock.Unlock()

	return "test"
}
//Write something to the data
func (m *MutexProtection) Write(s string) {
	m.lock.Lock()
	m.data = s
	time.Sleep(10*time.Millisecond) // simultes "work" done to save the data
	m.lock.Unlock()
}
```

下面我们对他做测试：

```golang
func benchMutex(workers int, workload int, b *testing.B) {
	m := NewMutextProtection()
	wg := &sync.WaitGroup{}
	b.ResetTimer()
	writer := func() {
		for i := 0; i < workload; i++ {
			m.Write("test")
		}
		wg.Done()
	}
	reader := func() {
		for i := 0; i < workload; i++ {
			_ = m.Read()
		}
		wg.Done()
	}
	for i := 0; i < workers; i++ {
		wg.Add(1)
		go writer()
		wg.Add(1)
		go reader()
  }
	wg.Wait()
}
func BenchmarkMutexWorks1by1000(b *testing.B) {
	benchMutex(1, 1000, b)
}
func BenchmarkMutexWorks10by100(b *testing.B) {
	benchMutex(10, 100, b)
}
func BenchmarkMutexWorks100by10(b *testing.B) {
	benchMutex(100, 10, b)
}
func BenchmarkMutexWorks1000by1(b *testing.B) {
	benchMutex(1000, 1, b)
}
```

随着线程数的添加，我们肯定会认为性能会提升。事实并非如此：

![](/static/imgs/go-channels.png)

即使线程数量减少，处理时间的变化也在合理的误差范围内。如果还不是很明显，这可能是代码设计方式的问题。虽然我们有许多线程，但他们都在互斥锁排队等候。如果没有互斥锁，这种虚构的工作机制就不安全，我们所做的只是添加了额外的 `goroutine`，一些同步对象，并且没有比串行的更好。显然，这不是我们的想要的结果。

在不仅仅是单个数据操作的关键逻辑附近使用互斥锁不会线性地提高性能。这个例子可能没有出现在您的计算机科学教科书中，因为互斥体通常放在示例中的数据元素中。不幸的是，关键部分通常通过API，套接字或其他慢速操作（如加密或身份验证）来操作复杂和缓慢的外部系统。因此，在内存紧密性的简单模型中互斥将不起作用。

## 基于channel 的安全对象

最好的是具有与互斥锁示例相同的接口的对象，但以某种方式阻止`Mutex`创建的资源阻塞。虽然有几种方法可以做到这一点 - 甚至一些使用互斥体 - 使用通道可以简化代码并增加系统的可能并行性。我们需要做的第一件事是增加界面。我们可以保留“读取”和“写入”公共方法，但我们还需要添加“开始”和“关闭”方法，以确保我们可以确保完全处理工作负载：

```golang
//Start the background processing
func (m ChannelProtection) Start() {
	m.wg.Add(1)
	go m.background()
}
//Close down the background resources
func (m ChannelProtection) Close() {
	m.shutdown <- struct{}{}
	m.wg.Wait()
}
```

与基准代码一样，我们使用`sync.WaitGroup`来确保后台线程在主程序关闭之前完成。后台线程是一个`for/select`循环，用于处理少数几个通道：

```golang 
func (m ChannelProtection) background() {
	mainloop:
	for {
		select {
		case <- m.shutdown:
			for {
				select {
				case newString := <- m.writeData:
					m.write(newString)
				case <- m.readRequest:
					go m.read()
				default:
					break mainloop
				}
			}
		case newString := <- m.writeData:
			m.write(newString)
		case <- m.readRequest:
			go m.read()
		}
	}
	m.wg.Done()
}
```

按照我们的预期，写入操作将被强制同步执行。在给定的时间内，已可以异步的读取数据。

```golang
//write is done in a different goroutine and the data in the input 
// no longer "belongs" to the sender.  This means that if it is a pointer 
// type like a map or a slice the sender must send a copy
func (m *ChannelProtection) write(s string) {
	m.data = s
	time.Sleep(10 * time.Millisecond) // Simulates "work" done to save the data
}
//read is done in a different gorioutine and the data returned 
// is "given" to the caller of Read through a channel and must be a 
// copy of the data at a given time and cannot reference internal data
func (m ChannelProtection) read() {
	time.Sleep(10 * time.Millisecond) // Simulates "work" done to retrieve the data
	m.readData <- "test"
}
```

这是完成模拟慢速资源的“工作”的地方。剩下的就是将Write和Read连接到后台线程：

```golang
//Read the current data
// this function runs in goroutine that calls it
func (m ChannelProtection) Read() string {
	m.readRequest <- struct{}{}
	currentData := <- m.readData
	return currentData
}
//Write something to the data
// this function runs in the goroutine that calls it
func (m ChannelProtection) Write(s string) {
	m.writeData <- s
}
```

并构建一个构造函数：

```golang
//ChannelProtection on a data string
type ChannelProtection struct {
	data string
	writeData chan string
	readRequest chan struct{}
	readData chan string
	shutdown chan struct{}
	wg *sync.WaitGroup
} 
//NewChannelProtection ...
func NewChannelProtection() *ChannelProtection {
	return &ChannelProtection{
		writeData: make(chan string, 10),
		readRequest: make(chan struct{}, 10),
		readData: make(chan string, 10),
		shutdown: make(chan struct{}, 10),
		wg: &sync.WaitGroup{},
	}

```

注释中解释了这些原则，但要记住的基本思想是通过通道在`goroutine`之间移动内存。我将详细介绍如何完成这项工作，但现在可以说它在现代处理器上非常有效。一旦数据被传递给“Write”，它就不再属于调用者（使用“-race”运行测试将保护您免受违反此规则）并且从“Read”返回的数据只是存储内容的副本在结构内（存储在内存中或通过API存储的抽象意义上）。

有了这个框架设置，这里是基准测试结果：

![](/static/go-channels-2.png)

即使有一个读写消费者，性能也优于互斥设计，并且随着更多工作人员的加入，它会快速接近理论最大值（因为我们设计的写入是同步的，最大值将达到10000000000 ns/op）。如果我们改为有一个系统可以按顺序处理“Write”，那么缩放是荒谬的:

![](/static/go-channels-3.png)

最后两个速度需要通过（迭代*速度）在120000000和20000000 ns/op处计算。

### 世上没有免费的午餐

像软件工程中的所有东西一样，这种设计的速度提高需要付出代价。如果必须按照收到的确切顺序处理读取和写入，或者正在完成的工作是在单个资源上（例如，如果您只有一个数据库连接），那么这种设计显然有点过分。如果您的系统无法使用并行工作负载建模，则线程永远不会为您提供更好的性能。但是，如果您可以容忍异步处理，“陈旧”但内部一致的读取，或者如果您的工作负载由开销（例如加密）控制，则在此类系统中安排线程将为您提供可能的扩展。当你开始将数据pipleine拼凑在一起时，这变得更加强大，但这是另一天的主题。

### 为什么选择channels 

您可能会问自己：当我可以想象以我一直以来的方式构建这些类型的工作负载分配系统时，为什么要使用`channels`？秘诀在于`channels`如何运作。`channels`使用两种关键技术来尽可能快地完成这些内存操作。第一个是**写屏障(Write Barriers)**的概念，第二个是使用`AMD64`的`CMPXCHG`指令，这是一个比较和交换或“CAS”操作。

### Write Barriers

当通道将数据发送到目标时，它必须执行非常快速的内存移动。在golang中，这是直接在汇编程序中编写的代码的少数部分之一。为了保证这个低级代码始终正确并且不被垃圾收集中断，创建了Write Barriers。这会创建一个位图来强制源和目标之间的写入按顺序发生，一旦设置，就可以安全地执行高度优化的内存移动汇编程序，而垃圾收集不会改变屏障下的数据。

### CAS Operations

CAS操作执行以下操作：

```
If (accumulator == destination) then (destination <- source)
else (accumulator <- destination)
```

这个单一的操作码本质上是“lazy barber”竞争条件的处理器级解决方案。 如果累加器用于存储在目标中找到的“lock”变量的值，并且源是您希望设置的“锁定状态”（例如，非零值），则可以使用CAS操作来验证 您没有在另一个设置锁定状态的进程之上设置锁定状态。 使用此操作可以大大降低通道`memmove`操作中写入障碍的成本，并将通道实现中的低级原子变量降低到仅使用互斥锁和高级代码无法实现的水平。 旁注：这也是golang中原子包的实现方式，所以如果通道不适合你的同步，你需要弄清楚你的代码，我鼓励你看看你会发现的`CompareAndSwap*`函数那里。

### 习惯用法

虽然每种语言都有其纯粹主义者，他们用不太高尚的推理来追求惯用的代码golang的原则是“通过沟通来分享记忆;不要通过分享记忆来沟通。“不仅仅是空话。因为golang既是托管内存又是托管线程（通过调度程序），当你遵循惯用模式时，例如避开共享内存，你的代码性能会提高。组织代码管道处理以通过通道传递数据不仅可以更清晰地封装关注点，还可以让golang系统更好地处理内存和线程资源。核心语言的最新更新已经改进了垃圾收集器的内部操作，以便更好地将内存与goroutine相关联，但是这些类型的优化是围绕这种惯用模式构建的。


本文所有的代码均可在此处找到：https://github.com/weberr13/Kata/tree/master/channels
