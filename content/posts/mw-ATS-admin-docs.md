---
type : post
title : 译-Apache Traffic server 管理员手册(未完待续)
categories: [ATS,] 
date : 2019-11-21 20:00:00
url: /posts/2019-11-21-ats-admin-docs.html 
tags : [ATS, 运维, 翻译]
---

`Apache Traffic Server`（ATS或TS）是一个高性能的、模块化的 HTTP 代理和缓存服务器。`Traffic Server` 最初是 Inktomi 公司的商业产品，该公司在 2003 年被 Yahoo 收购，之后 `Traffic Server` 一直在 Yahoo 内部使用长达 4 年，直到 2009 年 8 月 Yahoo 向 Apache 软件基金会（ASF）贡献了源代码，并于 2010 年 4 月成为了 ASF 的顶级项目（Top-Level Project）。 `Apache Traffic Server` 现在是一个开源项目，开发语言为C++。

[Traffic Server](https://twitter.com/trafficserver)的开发团队曾经由 [Chuck Neerdaels](https://twitter.com/chucknscratch) 领导，他也是 Harvest 项目的早期创始人之一，Harvest 项目后来发展为十分流行的 `Squid` 项目；[Leif Hedstrom](https://twitter.com/zwoop) 管理着现在的 `Traffic Server` 开发团队。目前 `Chuck Neerdaels` 和 `Leif Hedstrom`都已加盟知名 CDN 服务提供商 [Akamai](https://www.akamai.com)。

下面为官方文档管理员手册翻译，在此以下原文基础上做了更新，记录备查。

> 原文地址：https://www.infvie.com/ops-notes/apache-traffic-server.html
> 
> 作者：Einic Yeo

# 一、简介

全球化的数据网络已经成为日常生活的一部分：互联网用户每天向世界各地请求10亿次的文本和PB级别的数据。信息是免费的，丰富且易获取。但是全球的网络环境使IT专业人士在服务器超负荷和网络拥堵中苦苦挣扎，这对他们来说简直是一场恶梦。不断的适应不断增长的全球数据肯呢过是一项挑战。

Traffic Server 是一个高性能的 web 代理缓存，它通过将频繁访问的信息缓存在网络的边缘来改善网络的效率和性能。这使访问内容在地理上更接近终端用户，在更快分发的同时也减少了带宽的占用。Traffic Server 致力于通过充分利用现有可用的带宽，来改善企业、ISP、骨干网提供商和大型企业内部网的内容分发效率。

# 二、Traffic Server 部署选项

Traffic Server 有如下部署方式：

- 作为一个 web 代理缓存
- 作为一个反向代理
- 部署在多级缓存

## 1. Traffic Server 作为 web 代理缓存

作为 web 代理缓存，`Traffic Server` 接收用户直接发往 web server（源服务器）的 web 内容请求。如果 Traffic Server 包含请求的内容，它将直接提供服务。如果请求的内容不在缓存里，Traffic Server 将作为一个代理：为用户从源服务器取得请求的内容，并在本地保存一份拷贝以服务于将来相同的请求。

Traffic Server 提供直接代理缓存功能，这需要配置用户的客户端软件将请求直接发送给 Traffic Server。可参阅[直接代理缓存](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/explicit-forward-proxying.en.html#explicit-proxy-caching)。

Traffic Server 也可以作为透明代理缓存服务器，其中客户端软件不需要特殊配置甚至不需要知道代理的存在。可参阅[透明代理](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/transparent-proxy.en.html#transparent-proxy)。

## 2. Traffic Server 作为反向代理

作为反向代理，Traffic Server 需要配置为用户直接连接的源服务器（典型的用法是将源服务器的主机名解析到 Traffic Server）。反向代理的功能也被称为服务器加速。反向代理的更多细节可参阅 [反向代理和HTTP重定向](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/redirecting-http-requests.en.html#reverse-proxy-and-http-redirects)。

## 3. Traffic Server 部署在多级缓存

Traffic Server 可以灵活地参与多级缓存，当 Internet 请求不能在一个缓存中得到满足的时候，将被路由到其他区域的缓存，从而利用附近缓存的内容。在一个多级代理中，Traffic Server 可以作为其他 Traffic Server 系统或者和其相似的缓存产品的父节点或者子节点。

Traffic Server 支持 ICP（Internet Cache Protocol）互连。多级缓存的更多细节将在多级缓存中介绍。

## 4. Traffic Server 作为负载均衡

Traffic Server 可以充当第7层HTTP负载平衡器，在多个服务器之间分配请求。它可以使用请求属性（例如Host:Header，URL属性，scheme，method和客户端IP地址）选择下一跳服务器。它具有一些选择策略，例如加权轮询和URL一致性哈希。

# 三、Traffic Server 组件

Traffic Server 由若干一起工作的组件来组成一个便于监控和配置的 web 代理缓存。

## 1. Traffic Server 缓存

Traffic Server 缓存由高速对象数据库 Object store 组成。对象数据库通过 URL 和相关的头部来索引对象。使用先进的对象管理，Object store 可以缓存同一个对象（可能是不同的语言或编码类型）的替换版本。它同样可以高效地存储非常小和非常大的对象，从而使浪费的空间最小化。当缓存被占满后，Traffic Server 通过删除过期的数据来保证经常被请求的对象有效并容易获取。

Traffic Server 被设计为容忍缓存磁盘的任何失效。如果磁盘完全失效，Traffic Server 会标记整个磁盘为被占用同时继续使用余下的磁盘。如果缓存的所有磁盘都失效了，Traffic Server 会自动切换为纯代理模式。可以对缓存进行分区，来为专门的协议和源服务器存储数据预存一定数量的磁盘空间。更多关于缓存的信息见 [HTTP 代理缓存](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#http-proxy-caching)。

## 2. RAM 缓存

Traffic Server 维护着一个包含热点对象的微型 RAM 缓存。这个 RAM 缓存在尽可能快地服务大部分热点对象的同时也减少了磁盘负载，特别是在一些流量的高峰。可以根据需要来配置 RAM 缓存的大小。更多的细节见 改变 RAB 缓存的大小。

## 3. Host 数据库

Traffic Server host 数据库负责存储连接的源服务器 DNS 记录。这个信息用来适应未来协议的交互以及性能的优化。host 数据库信息包含：

- DNS 信息（加速主机名和 IP 地址的转换）
- 每个 host 的 HTTP 版本（可以在新版的服务器上使用增强的协议功能）
- host 的可靠性和可用性信息（用户可以不用等待不工作的服务器）

## 4. DNS 解析器

Traffic Server 包含一个快速的、异步的 DNS 解析器来简化主机名和 IP 地址的转换。Traffic Server 最初实现的 DNS 解析器就是直接发送 DNS 命令数据包而不是依赖传统的慢速解析库。由于许多 DNS 查询可以并行发送，同时在内存的高速 DNS 缓存中维持着热点绑定（DNS，IP），使 DNS 流量减少。

## 5. Traffic Server 进程

Traffic Server 包括三个一起工作的进程来服务 Traffic Server 的请求，管理/控制/监控系统的健康状况。下图说明了三个进程的关系，三个进程将会在下面描述。

- `traffic_server` 进程是 Traffic Server 的事务处理引擎。它负责接收连接、处理协议请求以及从本地缓存或源服务器提供资源。
- `traffic_manager` 进程是用来命令和控制 Traffic Server 的工具，负责启动、监控以及重新配置 traffic_server 进程。traffic_manager 进程同时负责代理自动配置端口、统计接口、集群管理以及 VIP 故障转移。
如果 traffic_manager 进程检测到 traffic_server 进程失败，它不仅会立即重启该进程，而且会为所有传入的请求维护一个连接队列。在 traffic_server 重新启动前的几秒内传入的所有连接将被保存在一个队列，并以 FIFO 的方式处理。这个连接队列接收任何 server 故障重启时的连接。
- `traffic_cop` 进程监控 traffic_server 和 traffic_manager 进程的健康状况。traffic_cop 进程通过抓取合成 web 页面的心跳请求方式周期性地（每分钟若干次）查询 traffic_server 和 traffic_manager 进程。如果失败事件发生（如果在超时时间间隔内没有收到请求或者收到错误的请求），traffic_cop 重启 traffic_server 和 traffic_manager 进程。

![](/static/imgs/ats/process.jpg)

## 6. 管理员工具

Traffic Server 提供如下的管理选项：

- `traffic_ctl` 命令行接口是一个基于文本的接口，通过它不但可以监控 Traffic Server 的性能和网络流量，而且可以配置 Traffic Server 系统。
- 各种各样的配置文件可以通过一个简单的文件编辑器以及信号处理接口来配置 Traffic Server。任何通过 traffic_ctl 的更改都会自动地同步到配置文件。
- 最后，有一个简洁的 C API，可以很好地利用多种语言。Traffic Server Admin Client 为 Perl 演示了这一点。

# 四、流量分析选项

Traffic Server 为流量分析和监控提供了若干选项：

- `traffic_ctl` 可以用来收集和处理从网络流量信息中获取的统计数据。
- 事务日志记录了（在一个日志文件中）Traffic Server 接收的每个请求以及每个检测到的错误。通过分析日志文件，可以确定有多少人使用了 Traffic Server 缓存，每人请求了多少信息以及哪些页面是最热的。同样也可以查看一个特定事务出错的原因以及特定时间 Traffic Server 的状态。比如，可以看到 Traffic Server 重启或者集群通信超时等状况。
Traffic Server 支持若干标准的日志文件格式，比如 Squid 和Netscape， 以及其自定义的格式。可以通过现成的分析包来分析标准格式的日志文件。为了便于日志文件分析，可以按协议或者主机来分开生成日志文件。
Traffic Server 事件和错误日志，监控以及分析的详细介绍参见 [Monitoring](https://docs.trafficserver.apache.org/en/latest/admin-guide/monitoring/index.en.html#admin-monitoring)。

# 五、Traffic Server 安全选项

Traffic Server 提供了许多选项来确保 Traffic Server 系统和网络上其他计算机进行安全的通信。安全选项如下：

- 控制客户端对 Traffic Server 代理缓存的访问。
- 通过配置 Traffic Server 使用多个 DNS 服务器来匹配站点的安全配置。比如，Traffic Server 可以使用不同的 DNS 服务器来解析防火墙内部或外部的主机名。这使得在保持内部网络配置安全的情况下，同时可以继续透明地访问 Internet 外部网络。
- 配置 Traffic Server 在用户访问 Traffic Serer 缓存内容之前对其做身份验证。
- 在反向代理模式中，客户端和 Traffic Server，以及 Traffic Server 和源服务器之间使用 SSL 终止选项来进行安全连接。
- 通过 SSL 控制访问。
  
Traffic Server 安全选项的详细描述在 [Security](https://docs.trafficserver.apache.org/en/latest/admin-guide/security/index.en.html#admin-security)。

# 六、代理缓存配置

## 1. 会话协议

Traffic Server 支持一些会话级协议来代替 HTTP 或在 HTTP 之上。这些可以通过插件（参阅新协议插件）提供，也可以由 Traffic Server 直接支持。

会话协议由显式名称指定：

```bash 
http/0.9
http/1.0
http/1.1
http/2
```

代理端口上支持的会话协议是这些值的子集。为方便起见，根据这些基本协议定义了一些伪值：

- http 意味着 http/0.9，http/1.0 和 http/1.1
- http2 即 http/2
  
可以在 `proxy.config.http.server_ports` 中配置每个代理的端口，以支持这些会话协议的子集。对于启用 TLS 的连接，此配置控制 NPN 提供的协议。协议嗅探用于非 TLS 代理端口，以确定客户端正在使用哪个协议。如果该代理端口不支持检测到的协议，则断开连接。

## 2. HTTP 代理缓存

Web 代理缓存可以用来存储高频访问的 web 对象（比如文档、图片等）并为用户的请求提供这些信息。在改善网络性能的同时，也为其他任务空出了 Internet 的带宽。

### 1. 理解 HTTP web 代理缓存

Internet 用户向遍布全球的 web 服务器发送请求。缓存服务器必须扮演成一个 web 代理服务器才能服务于这些请求。当 web 代理服务器收到 web 对象的请求时，它可以选择响应这些请求或者将它们传递给源服务器（包含被请求信息源文件的服务器）。Traffic Server 代理支持直接代理缓存方式，这种方式需要客户端软件配置成直接发送请求给 Traffic Server 代理。下面大概描述下 Traffic Server 如何响应用户的请求：

- 1、Traffic Server 收到一个用户对 web 对象的请求。
- 2、Traffic Server 尝试着在其对象数据库（缓存）中用被请求对象的地址来定位该对象。
- 3、如果对象在缓存中，Traffic Server 会检查该对象是否过期，如果对象没有过期，Traffic Server 以缓存命中的方式用该对象来响应用户。如下图

![](/static/imgs/ats/cache_hit.jpg)

- 4、如果缓存中的数据已经过期，Traffic Server 连接源服务器并检查该对象是否仍然可用（重新生效）。如果生效，Traffic Server 直接发送缓存中的对象给用户。
- 5、如果对象没有在缓存中（缓存未命中）或者源服务器显示缓存中的对象已经失效，Traffic Server 会从源服务器重新获取该对象。该对象会同时发送给用户以及 Traffic Server 的本地缓存。由于本地已经有了最新的缓存，后期对该对象的请求将会被更快的响应。

![](/static/imgs/ats/cache_miss.jpg)

实际的缓存会比上面的概述复杂得多。尤其是概述中没有讲述 Traffic Server 如何确保对象有效，正确地响应不同的 HTTP 版本以及处理那些对不能或不该被缓存的对象的请求。下面的部分将更细致地讨论这些问题。

### 2. 确保被缓存对象的有效性

当 Traffic Server 收到一个 web 对象的请求，它首先尝试着在缓存中定位该对象。如果该对象在缓存中，Traffic Server 将会检查该对象是否仍然有效。对于 HTTP 对象而言，Traffic Server 支持可选的请求者自定义的有效期。Traffic Server 首先根据有效期判断；如果有效期不存在，它会在对象被改变的频率和管理员选择的有效期方案之间挑选一个有效期。可以通过源服务器检查对象有效性的方式来重新生效对象。

**HTTP 对象保鲜**

Traffic Server 通过如下的方式来判断缓存中的 HTTP 对象是否有效：

- 检查 `Expires` 或者 `max-age` 头
一些 HTTP 对象包含 `Expires` 头或者 `max-age` 头来明确定义对象可以被缓存的时间。Traffic Server 通过比较当前时间和有效期时间来决定该对象是否仍然有效。

- 检查 `Last-Modified` / `Date` 头
如果 HTTP 对象没有 `Expires` 头或者 `max-age` 头，Traffic Server 使用下面的公式来计算对象有效期：

```
freshness_limit = ( date - last_modified ) * 0.10
```

这里的 `date` 是对象服务器返回的响应头的日期，而 `last_modified` 是 `Last-Modified` 头部的日期。如果没有 `Last-Modified` 头部，Traffic Server 就使用对象写入缓存的日期。因子` 0.1（10%）` 可以根据需要来增加或减少（见 [Modifying Aging Factor for Freshness Computations](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#modifying-aging-factor-for-freshness-computations)）。
计算的有效期被限制在一个最小值和最大值之间，更多信息见 [Setting Absolute Freshness Limits](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#setting-absolute-freshness-limits)。

- 检查绝对有效期极值
如果 HTTP 对象既没有 `Expires` 头部也没有 `Last-Modified` 和 `Date` 头部，Traffic Server 使用一个最大和最小有效期（见 [Setting Absolute Freshness Limits](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#setting-absolute-freshness-limits)）.

- 检查 cache.config 文件中的重新生效规则
重新生效规则为特殊的对象提供有效期极值。可以为来自特殊的域或 IP 地址的对象，URL 中包含指定的正则表达式的对象，来自特殊客户端的对象等设置有效期极值。参见 [cache.config](https://docs.trafficserver.apache.org/en/latest/admin-guide/files/cache.config.en.html#std:configfile-cache.config)。

**为有效期的计算修改老化因子**

如果一个对象没有包含任何截止信息，Traffic Server 可以根据其 `Last-Modified` 和 `Date` 头部来估计它的有效期。默认地，Traffic Server 存储该对象的时长是该对象最近一次被修改后到某个固定时间的 `10%`。可以根据需要来增大或减少这个百分比。

为有效期的计算修改老化因子：

- 修改位于 records.config 配置文件中 `proxy.config.http.cache.heuristic_lm_factor` 的值。
- 应用更改后的配置：`traffic_ctl config reload`。
`proxy.config.http.cache.heuristic_lm_factor`：设置这个变量来指定计算有效期的老化因子。Traffic Server 存储对象的时间依赖于这个变量。默认置为 `0.1`，即 10%。

**设置绝对有效期极值**

一些对象既没有 `Expires` 头部也没有 `Last-Modified` 和 `Date` 头部。为了控制这些对象在缓存中的时间，需要指定一个绝对有效期极值。

设置一个绝对有效期极值：

- 修改位于 records.config 配置文件中的` proxy.config.http.cache.heuristic_min_lifetime` 和 `proxy.config.http.cache.heuristic_max_lifetime` 这两个变量的值。
- 应用更改后的配置：`traffic_ctl config reload`。
  - proxy.config.http.cache.heuristic_min_lifetime：指定没有截止时间的 HTTP 对象在缓存中有效期的最小值。默认值为 3600 秒（1 小时）。
  - proxy.config.http.cache.heuristic_max_lifetime：指定没有截止时间的 HTTP 对象在缓存中有效期的最大值。默认值为 86400 秒（1 天）。

**指定头部的必要条件**

为了更好的确保缓存中对象的有效性，可以配置 Traffic Server 只缓存有特殊头部的对象。默认地，Traffic Server 缓存所有的对象（包括没有头部的对象）；可以为特殊的代理情况改变默认设置。如果配置 Traffic Server 只缓存有 `Expires` 或者 `max-age` 头部的 HTTP 对象，缓存命中率将会明显下降（因为几乎没有对象有明确的截止信息）。

配置 Traffic Server 只缓存有特殊头部的对象：

- 修改 records.config 配置文件中的 `proxy.config.http.cache.required_headers` 变量的值。
- 应用更改后的配置：`traffic_ctl config reload`。

proxy.config.http.cache.required_headers：设置这个变量为下列值之一：
- 0：对头部没有特殊要求
- 1：需要是 Last-Modified 头部，或者有明确生命期的头部，Expires 或者 Cache-Control: max-age
- 2：需要明确的生命期，Expires 或者 Cache-Control: max-age

**Cache-Control 头部**

尽管一个对象在缓存中可能是有效的，但是客户端或者服务器经常强加它们自己的不从缓存中获取对象的约束。比如，一个客户端请求一个对象时可能不通过缓存，即使通过缓存，对象的缓存时间也不能超过 10 分钟。Traffic Server 可以给一个缓存的对象在客户端请求和服务器响应中加上 Cache-Control 头部。下面的 Cache-Control 头影响着对象是否可以通过缓存来服务：

- 客户端发送的 `no-cache` 头部，告诉 Traffic Server 不能直接从缓存获取任何对象；因此，Traffic Server 总是从源服务器获取对象。可以配置 Traffic Server 忽略客户端的 no-cache 头部，更多信息见 [Configuring Traffic Server to Ignore Client no-cache Headers](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#configuring-traffic-server-to-ignore-client-no-cache-headers).
- 服务器发送的 `max-age` 头部，用来表示对象的使用期限。如果使用期限小于 `max-age`，表明对象是有效的，可以直接从缓存获取对象。
- 客户端发送的 `min-fresh`头部，是一个可接收的有效期容忍。这意味着客户端想让对象至少这次是有效的。如果一个对象在未来的这样一段时间内不再有效，那它会重新生效。
- 客户端发送的 `max-stale` 头部，允许 Traffic Server 使用过期的对象，倘若这些对象不是太老的话。一些浏览器倾向于使用过期不久的对象来改善性能，尤其是在 Internet 不是很发达的时期。

Traffic Server 在 HTTP 有效期标准之后使用 Cache-Control 标准。比如，一个对象可能被认为是有效的，但是如果它的使用期限大于它的 max-age，它将不会用于响应请求。

**重新生效 HTTP 对象(Revalidating HTTP Objects)**

当客户端请求一个在缓存中过期的对象，Traffic Server 将重新生效这个对象。重新生效是询问源服务器检查这个对象有没有被修改。重新生效的结果是下列情况之一：

- 如果对象还是有效的，Traffic Server 将重新设置这个对象的有效期极值，同时用这个对象来服务。
- 如果这个对象有新拷贝，Traffic Server 缓存这个对象（替换过期对象），同时用新的对象来服务用户。
- 如果对象在源服务器已经不存在了，Traffic Server 将不为这个对象提供服务。
- 如果源服务器没有响应重新生效查询，Traffic Server 在用这个过期对象服务的同时，会返回一个`111 Revalidation Failed`的警告。

默认情况下，Traffic Server 会重新生效一个缓存中的对象，如果它认为该对象已经过期。Traffic Server 如何评估对象的有效性已在 [HTTP Object Freshness](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#http-object-freshness) 中描述。可以选择如下选项之一来重新配置 Traffic Server 评估有效性的方式：

- Traffic Server 认为所有在缓存中的对象都是过期的：总是对在缓存中的对象进行重新生效。
- Traffic Server 认为所有在缓存中的对象都是有效的：从不对在缓存中的对象进行重新生效。
- Traffic Server 认为所有没有 Expires 或 Cache-Control 头部的 HTTP 对象都是过期的：重新生效所有没有 Expires 或 Cache-Control 头部的 HTTP 对象。

可以通过在 cache.config 文件中设置特殊的重新生效规则来配置 Traffic Server 重新生效缓存中对象的方式。

配置重新生效选项：

- 修改 records.config 配置文件中 `proxy.config.http.cache.when_to_revalidate` 变量的值。
- 应用更改后的配置：`traffic_ctl config reload`。
proxy.版权声明：本文遵循 CC 4.0 BY-SA 版权协议，若要转载请务必附上原文出处链接及本声明，谢谢合作！config.http.cache.when_to_revalidate：设置这个变量为下列值之一：
- 0：配置 Traffic Server 重新生效 HTTP 对象，当它认为该对象在缓存中已过期（如果可以的话，Traffic Server 检查对象头部和有效期极值）。这是默认配置。
- 1：配置 Traffic Server 重新生效没有 Expires 或 Cache-Control 头部的 HTTP 对象。
- 2：配置 Traffic Server 总是重新生效 HTTP 对象；Traffic Server 总是认为 HTTP 对象是过期的。
- 3：配置 Traffic Server 从不重新生效 HTTP 对象；Traffic Server 总是认为 HTTP 对象是有效的。

**定时更新本地缓存内容**

为了进一步增加性能并确保缓存中 HTTP 对象的有效性，可以使用预定更新选项。这个配置可以使 Traffic Server 定时加载特殊的对象到缓存。当使用 Traffic Server 作为反向代理的时候，定时更新功能显得非常有用，它可以根据预计的需求来预加载内容。

为了使用定时更新选项，必须完成如下的工作：

- 指定想定时更新对象的 URL 列表，更新发生的时间以及 URL 递归的深度。
- 开启定时更新选项，同时配置可选的重试次数。

Traffic Server 通过指定的信息来确定相关的 URL。Traffic Server 为每个 URL 获取所有递归的 URL （如果可以的话）并生成唯一的 URL 列表。Traffic Server 使用这个列表为每个未访问的 URL 发起的 HTTP GET 操作，在任意给定的时间内，确保用户定义的极值下 HTTP 的流通性。这个系统记录了所有 HTTP GET 操作的完成过程，可以基于此来监控定时更新的性能状况。

Traffic Server 也通过一个强制立刻更新的选项，可以在不等待指定更新时间的情况下立刻更新 URL。可以用这个选项来测试定时更新配置（见 Forcing an Immediate Update）.

配置定时更新选项需要下面几步：

- 在 update.config 文件中写入每个要更新的 URL。
- 在 records.config 中修改如下几个变量的值：
  - `proxy.config.update.enabled`：设置这个变量为 1 来开启定时更新选项。
  - `proxy.config.update.retry_count`：设置这个变量来指定当定时更新一个 URL 失败时重试的次数。默认值为 0.
  - `proxy.config.update.retry_interval`：设置这个变量来指定当定时更新一个 URL 失败时重试的时间间隔（单位：秒）。默认值为 2.
  - `proxy.config.update.concurrent_update`：设置这个变量来指定在任意同一时间点允许同时更新的最大请求数。这个选项来防止定时更新进程给主机带来超负荷。默认值为 100.
- 应用更改后的配置：`traffic_ctl config reload`。


**强制立刻更新**

Traffic Server 提供一个强制立刻更新选项，便于立刻验证 update.config 文件中的 URL 列表。这个强制更新选项忽略 update.config 中设置的更新时间间隔并且立刻更新 URL 列表。

配置强制更新选项需要如下几步：

- 修改 records.config 文件中 `proxy.config.update.force` 变量的值：
  - `proxy.config.update.force`：设置这个变量为 1 来开启强制更新选项。确保 `proxy.config.update.enabled` 变量设置为 1.
- 应用更改后的配置：`traffic_ctl config reload`。

当你开启了强制更新选项，Traffic Server 将不断地更新 update.config 文件中指定的 URL 直至关闭了该选项。要关闭强制更新选项，设置 `proxy.config.update.force` 变量为 0.

### 3. 将内容 PUSH 到缓存

Traffic Server 支持 HTTP PUSH 方法的内容分发。使用 HTTP PUSH，可以不借助用户请求直接将内容传递到缓存。

**配置 Traffic Server 接受 PUSH 请求**

在使用 HTTP PUSH 传递内容到缓存之前，必须先设置 Traffic Server 接受 PUSH 请求。

配置 Traffic Server 接受 PUSH 请求：

- 向 ip_allow.config 文件添加如下过滤规则来确保只有某些 IP 地址可以向缓存发送 PUSH 请求（示例）：

```
src_ip=0.0.0.0-255.255.255.255   action=ip_allow  method=PUSH
```

- 启用 records.config 文件中 `proxy.config.http.push_method_enabled` 变量
  - proxy.config.http.push_method_enabled：设置这个变量为 1 来开启 Traffic Server 接受 PUSH 请求。

```
CONFIG proxy.config.http.push_method_enabled INT 1
```

- 应用更改后的配置：`traffic_ctl config reload`。

ip_allow 的详细描述在 ip_allow.config.

**理解 HTTP PUSH**

PUSH 使用 HTTP 1.1 的消息格式。PUSH 请求的实体包括响应的头部以及想在缓存中替换的响应实体。下面是一个 PUSH 请求的例子：

```
PUSH http://www.company.com HTTP/1.0
Content-length: 84
 
HTTP/1.0 200 OK
Content-type: text/html
Content-length: 17
 
<HTML>
a
</HTML>
```

注：头部必须包括 `Content-Length`；`Content-Length` 必须包括头部和实体的字节数。

**有助于管理 PUSH 的工具**

Traffic Server 附带一个用于 PUSH 的脚本，`tpush`。这有助于了解如何编写脚本以自行推送内容。

### 4. 保留缓存中的内容

固定缓存选项配置 Traffic Server 保证一些 HTTP 对象一段指定的时间内都在缓存中。可以使用这个选项来确保一些最热点的对象在需要的时候会在缓存中，阻止 Traffic Server 删除重要的对象。Traffic Server 观测 Cache-Control 头部并只会保留一个确定可缓存的对象在缓存中。

设置缓存固定规则并开启缓存固定功能：

- 启用 records.config 文件中 `proxy.config.cache.permit.pinning` 变量
  - proxy.config.cache.permit.pinning：设置这个变量为 1 来开启固定缓存选项。

```
CONFIG proxy.config.cache.permit.pinning INT 1
```

- 为每个想让 Traffic Server 保留在缓存中的 URL 添加一条规则到 cache.config 中。比如：

```
url_regex=^https?://(www.)?apache.org/dev/ pin-in-cache=12h
```
正则表达式中指定的 URL 即为想让 Traffic Server 固定在缓存中的 URL。时间的格式可以是 d（天）、h（小时）、m（分钟）以及 s（秒）。也可以使用混合格式，如：1h15m20s。

- 应用更改后的配置：`traffic_ctl config reload`。

### 5. 缓存 HTTP 对象

当 Traffic Serer 收到一个对没有在缓存中的对象的请求时，它从源服务器取回这个对象并用其来响应用户。同时，在缓存中缓存这个对象以便服务后来的请求之前，Traffic Server 先检查这个对象是否可以缓存。

Traffic Server 响应来自客户端、源服务器以及通过配置选项和文件指定的缓存指示。

**客户端指示**

默认情况下，Traffic Server 不缓存含有如下**请求头部**的对象：

- `Authorization`
- `Cache-Control: no-store`
- `Cache-Control: no-cache`
为了配置 Traffic Server 忽略该请求头部，参见 [Configuring Traffic Server to Ignore Client no-cache Headers](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#configuring-traffic-server-to-ignore-client-no-cache-headers)。
- `Cookie（文本对象）`
默认情况下，Traffic Server 缓存包含 cookies 请求服务的响应对象（除了文本对象）。可以配置 Traffic Server 不缓存任何类型的 cookies 内容、缓存所有的 cookies 内容或者只缓存图片类型的 cookies 内容。更多信息参见 - [Caching Cookied Objects](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#caching-cookied-objects)。

**配置 Traffic Server 忽略客户端的 no-cache 头部**

默认情况下，Traffic Server 严格遵守客户端 `Cache-Control: no-cache` 的指示。如果一个被请求的对象包含 no-cache 头部，即使它在缓存中仍然有效，Traffic Server 也会将该请求传递给源服务器。可以配置 Traffic Server 忽略客户端 no-cache 指示，这样它将忽略客户端请求的 no-cache 头部并用缓存中的对象服务该请求。

- 配置 Traffic Server 忽略客户端的 no-cache 头部：
编辑 records.config 文件中 `proxy.config.http.cache.ignore_client_no_cache` 变量。
  - proxy.config.http.cache.ignore_client_no_cache：设置这个变量为 1 来忽略客户端的 no-cache 头部。

```
CONFIG proxy.config.http.cache.ignore_client_no_cache INT 1
```
- 应用更改后的配置：traffic_ctl config reload。

**源服务器指示**

默认情况下，Traffic Server 不缓存包含如下**响应头部**的对象：

- `Cache-Control: no-store`
- `Cache-Control: private`
- `WWW-Authenticate`
为了配置 Traffic Server 忽略 WWW-Authenticate 头部，参见 [Configuring Traffic Server to Ignore WWW-Authenticate Headers](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#configuring-traffic-server-to-ignore-www-authenticate-headers).
- `Set-Cookie`
- `Cache-Control: no-cache`
为了配置 Traffic Server 忽略 no-cahce 头部，参见 [Configuring Traffic Server to Ignore Server no-cache Headers](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#configuring-traffic-server-to-ignore-server-no-cache-headers)。
- `Expires` 头部包含 0 值或过去时间
  
**配置 Traffic Server 忽略服务器 no-cache 头部**

默认情况下，Traffic Server 严格遵守 `Cache-Control: no-cache` 指示。一个来自源服务器的带有 `no-cache` 头部的响应将不会被存储在缓存，该对象之前的缓存中的拷贝也会被删除。如果配置 Traffic Server 忽略 `no-cache` 头部，Traffic Server 同时也忽略 `no-store` 头部。在大多数情况下是应该遵守 `no-cache` 指示的。

配置 Traffic Server 忽略服务器的 no-cache 头部：

- 编辑 records.config 中 `proxy.config.http.cache.ignore_server_no_cache` 变量。
  - `proxy.config.http.cache.ignore_server_no_cache`：设置这个变量为 1 来忽略服务器的 no-cache 头部。

```
CONFIG proxy.config.http.cache.ignore_server_no_cache INT 1
```
- 应用更改后的配置：traffic_ctl config reload。
  
**配置 Traffic Server 忽略 WWW-Authenticate 头部**

默认情况下，Traffic Server 不缓存包含 `WWW-Authenticate` 响应头部的对象。`WWW-Authenticate` 头部包含着客户端准备用来响应源服务器质询应答的鉴定参数。

当配置 Traffic Server 忽略源服务器的 WWW-Authenticate 头部，所有带 WWW-Authenticate 头部的对象将被存储在缓存中被用来服务后来的请求，在大多数情况下，应该使用默认的不缓存带 WWW-Authenticate 头部对象的行为。只有在对 HTTP 1.1 深入理解的基础上，再尝试配置 Traffic Server 忽略服务器 WWW-Authenticate 头部。

配置 Traffic Server 忽略 WWW-Authenticate 头部：

- 编辑 records.config 文件中的 `proxy.config.http.cache.ignore_authentication` 变量。
  - proxy.config.http.cache.ignore_authentication：设置这个变量为 1 来缓存带 WWW-Authenticate 头部的对象。

```
CONFIG proxy.config.http.cache.ignore_authentication INT 1
```
- 应用更改后的配置：`traffic_ctl config reload`。

**配置指示**

除了客户端和服务器的指示，Traffic Server 同样响应配置选项和文件的指示。

可以按如下步骤来配置 Traffic Server：

- 不缓存任何对象（参见 [Disabling HTTP Object Caching](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#disabling-http-object-caching)）.
- 缓存动态内容 — 对象的 URL 以 `.asp` 结尾或者包含问号（？）、分号（:）或者 cgi。更多信息参加 [Caching Dynamic Content](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#caching-dynamic-content)。
- 缓存响应 Cookie: 头部的对象。参见 [Caching Cookied Objects](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/cache-basics.en.html#caching-cookied-objects).
- 遵守 cache.config 文件中的 nerver-cache 规则。
  
**关闭 HTTP 对象缓存**

默认情况下，Traffic Server 缓存除了在 cache.config 文件中设置了 never-cache 的所有对象。可以关闭 HTTP 对象缓存功能，所有的对象都直接由源服务器服务而且从不缓存。

手动配置关闭 HTTP 对象缓存：

- 设置 records.config 文件中 `proxy.config.http.cache.http` 变量为 0.
  - proxy.config.http.cache.http：设置这个变量为 0 来关闭 HTTP 对象缓存功能。

```
CONFIG proxy.config.http.cache.http INT 0
```
- 应用更改后的配置：traffic_ctl config reload。

**缓存动态内容**

一个以 `.asp` 结尾或包含问号（？）、分号（;）或者 cgi 的 URL 被认为是动态的。Traffic Server 默认缓存动态内容。可以配置系统忽略动态内容，但仅当内容是真正动态时才推荐，但是不能通过适当的 Cache-Control 头部来 advertise。

配置 Traffic Server 关于动态内容的缓存行为：

- 编辑 records.config 文件中的 `proxy.config.http.cache.cache_urls_that_look_dynamic` 变量。是禁止缓存则设置该变量为 0，若是显式允许缓存则设置为 1.

```
CONFIG proxy.config.http.cache.cache_urls_that_look_dynamic INT 0
```
- 应用更改后的配置：traffic_ctl config reload。

**缓存 Cookied 对象**

默认情况下，Traffic Server 缓存包含 cookies 请求服务的响应对象（除了文本对象）。Traffic Server 之所以不缓存文本内容的 cookied，是因为对象的头部和对象是一起存储的，而带有隐私的 cookie 头部是不能和对象一起保存的。对于非文本对象，不能确定是否使用了带有隐私的 cookie 头部。

可以配置 Traffic Server：

- 不缓存任何类型的 cookies 内容。
- 只缓存图片类型的 cookies 内容。
- 缓存所有的 cookies 内容。

配置 Traffic Server 缓存 cookied 内容的方式：

- 编辑 records.config 文件中 `proxy.config.http.cache.cache_responses_to_cookies` 变量。
  - proxy.config.http.cache.cache_responses_to_cookies：设置这个变量来指定 Traffic Server 缓存 cookied 内容的方式：
    - 0：不缓存任何 cookies 响应。
    - 1：缓存所有的 cookies 响应。
    - 2：只缓存图片类型的 cookies 响应。
    - 3：缓存除了文本内容类型的所有 cookies 响应。
- 应用更改后的配置：`traffic_ctl config reload`。

### 6. 强制对象缓存

可以强制 Traffic Server 缓存特殊的 URL（包括动态 URL）一段指定的时间，而不考虑 Cache-Control 响应头部。

强制缓存文档：

- 为每个想让 Traffic Server 强制缓存的 URL 添加一条规则到 cache.config 文件中。比如：

```
url_regex=^https?://(www.)?apache.org/dev/ ttl-in-cache=6h
```
- 应用更改后的配置：`traffic_ctl config reload`。


### 7. 缓存 HTTP Alternates

一些源服务器用多种对象来响应同一个 URL 的请求。这些对象的内容是多种多样的，比如提供不同语言内容的服务、为不同的目标浏览器提供不同的表达方式、或者提供不同的文档格式（HTML、PDF）。同一对象的不同版本被称为 Alternates，Traffic Server 基于 Vary 响应头部来缓存它们。可以为特殊的 Content-Type 值指定附加的请求和响应头部来让 Traffic Server 识别其为 Alternates 并缓冲之。也可以限制一个对象允许缓存不同版本的数目。

**配置 Traffic Server 如何缓存 Alternates**

配置 Traffic Server 如何缓存 alternates：

编辑 records.config 中的如下变量：
- `proxy.config.http.cache.enabled_default_vary_headers`：设置这个变量为 1 来缓存不包含 Vary 头部的 HTTP 对象的不同版本。
- `proxy.config.http.cache.vary_default_text`：设置这个变量来指定在请求是文本时 HTTP 头部的多种格式：比如，HTML 文档。
- `proxy.config.http.cache.vary_default_images`：设置这个变量来指定在请求是图像时 HTTP 头部的多种格式，比如，.gif 文件。
- `proxy.config.http.cache.vary_default_other`：设置这个变量来指定在请求不是文本和图像时 HTTP 头部的多种格式。
- 应用更改后的配置：`traffic_ctl config reload`。
  
> 注：如果在上述变量中指定 Cookie 作为头部变化格式，必须确保正确设置了 proxy.config.http.cache.cache_responses_to_cookies 变量。

比如，如果设置 `proxy.config.http.cache.cache_responses_to_cookies` 变量为 2（只缓存图片格式的 cookies 响应），同时设置 proxy.config.http.cache.vary_default_text 变量为指定的 cookie，cookie 的 alternates 将不接受文本格式。

**限制一个对象的 Alternates 个数**

可以限制 Traffic Server 缓存每个对象 alternates 的个数（默认值为 3）。

alternates 的数量太多会影响 Traffic Server 的性能，因为所有的 版权声明：本文遵循 CC 4.0 BY-SA 版权协议，若要转载请务必附上原文出处链接及本声明，谢谢合作！alternates 有同一个 URL。尽管 Traffic Server 可以从索引中快速查找 URL，但是必须在对象存储中顺序扫描直到找到可用的 alternates。

限制 alternates 的数目：

- 编辑 records.config 文件中 proxy.config.cache.limits.http.max_alts 变量。
  - proxy.config.cache.limits.http.max_alts：设置这个变量来指定想让 Traffic Server 缓存一个对象不同版本的数目。默认值为 3.

```
CONFIG proxy.config.cache.limits.http.max_alts INT 5
```
- 应用更改后的配置：`traffic_ctl config reload`。


### 8. 使用事务缓存控制

默认情况下，I/O 操作以全速运行，与 Traffic Server 的网络或缓存可以支持的速度一样快。如果客户端连接很慢，则对于大型对象可能会出现问题。在这种情况下，内容将缓存在 RAM 中，同时等待发送给客户端。如果客户端连接速度很快，但源服务器连接很慢，则 POST 请求也可能发生这种情况。如果使用非常大的对象，则可能导致 Traffic Server 的内存使用量变得非常大。

通过控制事务使用的缓存空间量可以改善这种问题。根据事务使用的字节数设置高阈值或低阈值。如果使用的缓存空间量超过了标记的高阈值，则会限制连接以防止其他外部数据到达。内部操作继续全速运行，直到使用的缓存空间量低于低阈值，才重新启用外部数据 I/O。

虽然这主要是为了限制 Traffic Server 的内存使用量，但它也可以通过设置缓存区限制，然后在外部或通过事务限制客户端连接来充当**原始速率限制器**。这将导致与源服务器的连接大致限制为客户端连接速度。

Traffic Server 以大块（32k 左右）进行网络 I/O，因此事务缓存控制的粒度限制在类似的精度。

缓存区大小的计算值包括事务中的所有元素，包括与转换插件关联的任何缓冲区。

可以使用配置变量或插件中的 `TSHttpTxnConfigIntSet()` 来全局启用事务缓存控制：

Value |	Variable | `TSHttpTxnConfigIntSet()` key
--- | --- | --- | --- 
Enable buffering | proxy.config.http.flow_control.enabled |	TS_CONFIG_HTTP_FLOW_CONTROL_ENABLED
Set high water | proxy.config.http.flow_control.high_water | TS_CONFIG_HTTP_FLOW_CONTROL_HIGH_WATER_MARK
Set low water | proxy.config.http.flow_control.low_water | TS_CONFIG_HTTP_FLOW_CONTROL_LOW_WATER_MARK

注意始终使低阈值小于或等于高阈值。如果只设置一个，则另一个将设置为相同的值。

如果使用 `TSHttpTxnConfigIntSet()`，必须在不迟于 `TS_HTTP_READ_RESPONSE_HDR_HOOK` 的情况下调用它。

### 9. 减少源服务器请求（避免惊群）

当无法从缓存中提供对象时，请求将被代理到源服务器。对于较热的对象，许多接近同时达到源服务器，可能会导致其相关资源负载过重。Traffic Server 中有几个功能可以避免这种情况。

**read while writer**

当 Traffic Server 从源服务器获取内容时，并在收到响应后，一旦接收到 `background_fill_completed_threshold%` 的对象数据，就可以允许为任意数量的客户端开始提供部分填充的缓存对象。

虽然一些其他的 HTTP 代理工具允许客户端在代理从源服务器接收到数据时立即开始读取响应，但 ATS 仅在读取和处理完整的 HTTP 响应头之后，才允许客户端读取。这是因为 ATS 不区分**缓存刷新**和**冷缓存**，必须读取HTTP头部信息来判断。

来自源服务器的不可缓存响应通常是由于该内容对于不同的客户端请求是唯一的，在确定它能够被缓存之前，ATS 将不会启用 read-while-writer 功能。

必须进行如下设置 records.config 以启用 ATS 的 read-while-writer 功能：

```
CONFIG proxy.config.cache.enable_read_while_writer INT 1
CONFIG proxy.config.http.background_fill_active_timeout INT 0
CONFIG proxy.config.http.background_fill_completed_threshold FLOAT 0.000000
CONFIG proxy.config.cache.max_doc_size INT 0
```
由于以下原因，所有四种配置都是必需的：

- 设置 `proxy.config.cache.enable_read_while_writer` 为 1 以打开该功能，因为它默认为 0。
- 为每个可能的情况应该允许启用后台填充功能（`proxy.config.http.background_fill_active_timeout` 和 `proxy.config.http.background_fill_completed_threshold`）。必要下，如果一个 writer（第一个请求对象的客户端会话，将触发 ATS 连接源服务器）消失，则另一个客户端会话必须接管 writer。
因此，应该将后台填充超时和阈值设置为 0，这可以保证它们永不超时，并且总是被允许进入。

- `proxy.config.cache.max_doc_size` 变量应该是无限制的（设置为 0），因为对象的大小可能是未知的，超过此限制将导致所服务的对象断开连接。

一旦启用这些功能，则可以获得与 `Squid` 的 `Coolapsed Forwarding` 非常接近但又不完全相同的东西。

除了上述设置，设置 `proxy.config.cache.read_while_writer.max_retries` 和 `proxy.config.cache.read_while_writer_retry.delay` 允许控制 TS 尝试触发 read-while-writer 的次数，直到完成对象的第一个片段的下载：

```
CONFIG proxy.config.cache.read_while_writer.max_retries INT 10
CONFIG proxy.config.cache.read_while_writer_retry.delay INT 50
```

**打开读取重试超时（Open Read Retry Timeout）**

open read retry 配置尝试减少向源服务器并发获取对象的数量。当从源服务器获取对象时，后续请求将在检查对象是否可以从缓存中提供之前等待 `proxy.config.http.cache.open_read_retry_time` 毫秒。如果仍然在获取对象，则后续请求将重试 `proxy.config.http.cache.max_open_read_retries` 次。因此，后续请求在建立自己的原始连接之前等待总共 (`max_open_read_retries` * `open_read_retry_time`) 毫秒。例如，如果它们分别设置为 5 和 10，则连接将等待长达 50ms 的时间，等待响应从以前的请求返回，直到允许该请求通过为止。

当对象不可缓存时，这些设置是不合适的。在这种情况下，对对象的请求有效地被序列化。后续的请求在代理到源服务器之前至少等待 `open_read_retry_time` 毫秒。

将以将此设置与 `Read While Writer` 结合使用，用于比较大的（那些需要超过 (max_open_read_retries * open_read_retry_time) 毫秒来传输的）可缓存对象。如果未启用 `read-while-writer` 设置，则当初始获取正在进行时，不仅后续的请求将延迟最长时间，而且这些请求会导致对源服务器不必要的请求。

由于现在 ATS 支持根据每个请求或重新映射规则来设置这些设置，所以可以更容易地将其配置为适合自己的设置。

默认配置如下：

```
CONFIG proxy.config.http.cache.max_open_read_retries INT -1
CONFIG proxy.config.http.cache.open_read_retry_time INT 10
```

默认设置是禁用该功能，并允许每个连接在没有人为延迟的情况下转到源服务器。启用后，将尝试 `max_open_read_retries` 次，每次都有一个 `open_read_retry_time` 超时。

**开写入失败操作**

除了 open read retry 设置之外，ATS 支持新的设置 proxy.config.http.cache.open_write_fail_action，在 hit-stale 的情况下，或者在除了其中一个请求之外的所有缓存未命中时发生错误的情况下，它允许通过返回过期的副本来进一步减少多个并发请求对同一个对象的命中。

## 3. 反向代理和 HTTP 重定向

作为反向代理缓存，Traffic Server 为源服务器服务请求。Traffic Server 被配置成对客户端而言是正常的源服务器的方式。

### 1. 理解反向代理缓存

通过正向代理缓存，Traffic Server 为客户端处理发往源服务器的 web 请求。反向代理缓存（又称服务器加速或虚拟主机托管）和正向代理不同，因为 Traffic Server 作为源服务器的代理缓存并存储内容。Traffic Server 被配置为用户直接连接的源服务器（典型的用法是将源服务器的主机名解析到 Traffic Server），直接为客户端请求提供服务，在必要的时候向真正的源服务器获取内容。

### 2. 反向代理解决问题场景

有多种方式使用 Traffic Server 作为一个反向代理。下面是一些示例场景。

- 为负载过高的源服务器减负。
- 为地理上分散的区域高效地分发内容。
- 为包含机密信息的源服务器提供安全屏障。

**为负载过高的源服务器减负**

Traffic Server 可以吸收发向源服务器的请求，通过减少源服务器的负载和热点来改善 web 服务的速度和质量。比如，一个网络托管商可以用一系列低价格、低性能、低可靠性的 PC 作为后备服务器来维护一个可扩展的 Traffic Server 服务引擎。事实上，单个 Traffic Server 可以为多个后台源服务器充当虚拟源服务器。

![](/static/imgs/ats/revproxy.jpg)

**为地理上分散的区域分发内容**

Traffic Server 可以使用反向代理模式来加速为地理上不邻近的区域提供服务。缓存更易于管理并且比复制数据更划算。比如，Traffic Server 可以在大洋彼岸充当镜像站点，不需要通过昂贵的国际连接发送请求和获取内容就可以服务用户。

相比于硬件必须要配置成复制所有的数据，并且要处理高峰情况下的复制，Traffic Server 可以通过动态调整来最好的利用硬件的服务和存储能力。Traffic Server 同时可以自动保持内容的有效性，从而排除了复杂的更新源服务器的操作。

**为源服务器提供安全保障**

Traffic Server 可以使用反向代理模式来为源服务器提供安全保障。如果想让包含机密信息的源服务器位于防火墙内来保证安全，可以在防火墙外用 Traffic Server 作为源服务器的反向代理。当外面的客户端试图访问源服务器，请求会被发送到 Traffic Server。如果请求的内容不是机密的，可以通过缓存来服务。如果内容是机密的并且没有缓存，Traffic Server 就从源服务器获取该内容（防火墙只允许 Traffic Server 访问源服务器）。位于源服务器的机密内容就可以安全地留在防火墙内。

**反向代理的工作方式**

当浏览器有请求，它一般直接发送这些请求到源服务器。当 Traffic Server 工作在反向代理模式，它在这些请求到达源服务器之前就拦截它们。典型的用法是**将源服务器的 DNS 入口（主机名）解析成 Traffic Server 的 IP 地址**。当 Traffic Server 被配置为源服务器，浏览器会和 Traffic Server 而非源服务器建立连接。更多的信息参见 [HTTP Reverse Proxy](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/redirecting-http-requests.en.html#http-reverse-proxy)。

为了避免 DNS 冲突，源服务器的主机名和外在 DNS 主机名必须不同。

### 3. HTTP 反向代理

在反向代理模式中，Traffic Server 为 web 服务器处理 HTTP 请求。反向代理模式下，Traffic Server 处理来自客户端浏览器 HTTP 请求的方式如下图所示。

![](/statiic/imgs/ats/httprvs.jpg)

图上包含的步骤如下：

- 客户端浏览器在 80 端口向名为 www.host.com 的 host 发送一个 HTTP 请求。Traffic Server 以源服务器的角色接收这个请求（源服务器的对外主机名被解析到 Traffic Server）。
- Traffic Server 在 remap.config 文件中定位映射规则并重新映射这个请求到一个指定的源服务器（readlhost.com）。Traffic Server 建立一个和源服务器的 HTTP 连接。
- 如果请求在缓存中命中而且内容是有效的，Traffic Server 直接从缓存中向客户端发送被请求的对象。
- 否则，Traffic Server 从源服务器获取被请求的对象，发送给客户端，同时在缓存中保存一份该对象的拷贝。

> 注：当从源服务器更新自己的缓存时，Traffic Server 将在更新缓存数据库时同时将该内容发送给客户端。一旦 Traffic Server 收到并处理了来自源服务器的完整响应头，就开始响应客户端包含的请求对象。

要配置 HTTP 反向代理，步骤如下：

- 在 remap.config 文件中生成映射规则（参见 [Creating Mapping Rules for HTTP Request](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/redirecting-http-requests.en.html#creating-mapping-rules-for-http-requests)）.
  
```  
map http://www.host.com http://realhost.com
```
- 启用反向代理选项（参见 Enabling HTTP Reverse Proxy）。

除了上述步骤，也可以参见 [Setting Optional HTTP Reverse Proxy Options](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/redirecting-http-requests.en.html#setting-optional-http-reverse-proxy-options)。

**处理源服务器重定向响应**

源服务器经常给浏览器返回重定向到不同页面的响应。比如，如果源服务器超载，它会重定向浏览器到一个低负载的服务器。源服务器也重定向已经被移到不同位置下的 web 页面。当 Traffic Server 被配置成一个反向代理，它必须通过改写来自源服务器的重定向来使浏览器重定向到 Traffic Server 而不是其他的源服务器。

Traffic Server 使用反向映射规则来改写重定向。除非启用了 `proxy.config.url_remap.pristine_host_hdr`（默认），否则需要为每个映射规则生成一个反向映射规则。参见 [Using Mapping Rules for HTTP Request](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/redirecting-http-requests.en.html#using-mapping-rules-for-http-requests) 来创建反向映射规则。

**为 HTTP 请求使用映射规则**

Traffic Server 为 HTTP 反向代理使用两种类型的映射规则。

- map rule

一个映射规则是将一个客户端的请求 URL 转换为定位内容的 URL。当 Traffic Server 使用反向代理模式并接收客户端的 HTTP 请求，它必须从相关的 URL 和头部来构造一个完整的 URL。Traffic Server 接下来使用这个完整的 URL 在 remap.config 文件中查找其匹配的目标 URL。要使请求 URL 匹配目标 URL，下面的条件必须满足：

  - 两个 URL 必须是一个组合。
  - 两个 URL 的 host 必须相同。如果请求 URL 中包含一个不合格的主机名，它不可能匹配到一个具有合格的主机名的目标 URL。
  - 两个 URL 的端口号必须相同。如果指定的 URL 中没有端口号，URL 的组合将使用默认的端口号。
  - 目标 URL 的路径部分必须可以和请求 URL 的前缀匹配。

如果 Traffic Server 找到一个匹配，它将请求 URL 转换为映射规则中的替换 URL：它设置请求 URL 的 host 和路径去匹配替换 URL。如果 URL 包含 path 前缀，Traffic Server 去掉 path 的和目标 URL 匹配的前缀，同时用替换 URL 中 path 来替换该 path。如果一个请求 URL 有两个对应的匹配，Traffic Server 接受 remap.config 文件中的第一个匹配。

- reverse-map rule
  
一个反向映射规则是将源服务器重定向响应中的 URL 转换为指向 Traffic Server，这样客户端会再次重定向到 Traffic Server 而不是直接访问一个源服务器。比如，在源服务器 www.molasses.com 上有一个 /pub 目录，一个客户端向该源服务器发送一个 /pub 的请求，源服务器可能回复一个 Location: http://realhost.com/pub/ 的重定向来告诉客户端它请求的是一个目录，而不是文档（重定向通常的应用是标准化 URL，这样客户端可以正确地标记文档）。

Traffic Server 使用 reverse_map 规则来阻止客户端（从源服务器收到重定向）绕过 Traffic Server 直接访问源服务器。

map 和 reverse-map 规则都由一个目标（源）URL 和一个替换（目的）URL 组成。在一个 map 规则中，目标 URL 指向 Traffic Server 而替换 URL 指定源服务器内容的位置。在一个 reverse-map 规则中，目标 URL 指定源服务器内容的位置而替换 URL 指向 Traffic Server。Traffic Server 在位于 Traffic Server 的 config 目录下的 remap.config 文件中存储映射规则。

**为 HTTP 请求创建映射规则**

- 将 map 和 reverse-map 规则写入到 remap.config 中。
- 应用更改后的配置：traffic_ctl config reload.

**启用 HTTP 反向代理**

- 编辑 records.config 中 proxy.config.reverse_proxy.enabled 变量来开启反向代理模式。

```
CONFIG proxy.config.reverse_proxy.enabled INT 1
```
- 应用更改后的配置：traffic_ctl config reload.

**设置可选的 HTTP 反向代理选项**

Traffic Server 在 records.config 中提供了几个反向代理配置选项，可以启用它们：

- 配置 Traffic Server 在转换的时候保存客户端的 host 头部信息。参见 proxy.config.url_remap.pristine_host_hdr.
  - proxy.config.url_remap.pristine_host_hdr：
    - 1：Traffic Server 将保存客户端请求的 host 头部。
    - 0：Traffic Server 将转换客户端请求的 host 头部。
- 配置 Traffic Server 只服务发往映射规则中的源服务器的请求。因此，发往不在映射规则中源服务器的请求将不会被服务。参见 proxy.config.url_remap.remap_required。
  - proxy.config.url_remap.remap_required：
    - 1：Traffic Server 只为在 remap.config 文件的映射规则中的源服务器的请求服务。
    - 0：Traffic Server 服务所有源服务器的请求。
  - 为来自老版本客户端的请求指定一个替换的 URL（比如，没有提供 host 头部的客户端）。参见 proxy.config.header.parse.no_host_url_redirect。
    - proxy.config.header.parse.no_host_url_redirect：没有 host 头部的请求重定向的 URL。
- 执行 traffic_ctl config reload 以应用上面的配置更新。

### 4. 重定向 HTTP 请求

可以配置 Traffic Server 不需要联系任何源服务器就可以重定向 HTTP 请求。比如，如果想重定向所有去 www.ultraseek.com 的请求到 http://www.server1.com/products/portal/search/，则所有去 http://www.ultraseek.com 的请求将直接去 www.server1.com/products/portal/search。

可以通过 Traffic Server 配置永久或临时重定向。永久重定向通知浏览器 URL 的变更（通过返回 HTTP 状态码 `301`），这样浏览器就可以更新标签。临时重定向通知浏览器指示当前请求的 URL 变更（通过返回 HTTP 状态码 `307`）。

设置重定向规则：

- 为每个重定向设置一条映射规则到 remap.config 文件中。每个映射规则必须用一个分开的行并且必须由三个确定位置的区域：type、target 和 replacement 组成。如下描述了每个区域的格式。
  - type：输入其中的一个：
  - redirect：不联系源服务器而永久重定向 HTTP 请求。
  - redirect-temporary：不联系源服务器而临时重定向 HTTP 请求。
  - target：输入源 URL。可以由四部分组成：scheme://host:port/path_prefix。
  - replacement：输入目标 URL。可以由四部分组成：scheme://host:port/path_prefix。
- 执行 “traffic_ctl config reload“` 应用更改后的配置。

如下示例将到 www.server1.com 的所有的 HTTP 请求永久重定向到 www.server2.com：

```
redirect http://www.server1.com http://www.server2.com
```

## 4. 显式代理缓存（Explicit Proxy Caching）

>TODO [origin article](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/explicit-forward-proxying.en.html)

## 5. 透明代理缓存（Transparent Proxy Caching）

>TODO [origin article](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/transparent-proxy.en.html)

## 6. 转发代理（Forward Proxy）

>TODO [origin article](https://docs.trafficserver.apache.org/en/latest/admin-guide/configuration/transparent-forward-proxying.en.html)

## 7. 多级缓存（Hierarchical Caching）

Traffic Server 可以工作在多级缓存中，请求在一个缓存不能完成时可以路由到别的区域的缓存，从而利用附近缓存的内容。

### 1. 理解多级缓存

一个多级缓存由可以相互通信的多层缓存组成。Traffic Server 支持若干种类型的多级缓存。所有的缓冲层级都通过父节点和子节点来识别。一个父节点缓存位于层级的高层，Traffic Server 可以向其转发请求。一个子节点缓存是以 Traffic Server 为父节点的缓存。

Traffic Server 支持如下的层级缓存选项。

### 2. 父节点缓存

如果 Traffic Server 在自己的缓存中没有找到被请求的对象，在从源服务器取回这个对象之前，它会先找一个父节点缓存（这个节点也可以去找别的缓存）。可以配置 Traffic Server 节点使用一个或多个父节点缓存，这样如果一个父节点缓存不可用时，其它的父节点可以来响应请求。这就是 父节点故障转移。Traffic Server 支持 HTTP 和 HTTPS 的父节点缓存。

如果不想让所有的请求都去父节点缓存，可以配置 Traffic Server 将特定的请求（比如包含特殊的 URL）直接路由到源服务器。简单的父节点设置规则见 parent.config.

下图展示了一个简单的 Traffic Server 节点配置了父节点缓存的多级缓存。客户端向在多级缓存中位于子节点（因为它配置了转发未命中的请求到父节点缓存）的 Traffic Server 发送请求。请求在缓存中未命中，Traffic Server 就将其转发给了其父节点缓存并且在父节点缓存中命中。随后这个内容的请求可以直接由 Traffic Server来服务（直到数据过期或失效）。

![](/static/imgs/ats/cachehrc.jpg)

如果请求在父节点缓存中也未命中，父节点会从源服务器获取请求的内容（或者从其他缓存，取决于父节点的配置）。父节点缓存该内容并将内容的拷贝发送给 Traffic Server（其子节点），Traffic Server 缓存该内容并响应客户端。

**父节点选择策略**

Traffic Server 子节点可以使用多种策略：

- 一致性哈希。子节点为每个 URI 选择一个特定的父节点。这有效地使父节点缓存大小等于每个父节点缓存大小的总和。
- 轮询。子节点循环访问父节点。子节点可以基于客户端 IP（”true”）或者严格循环(“strict”) 中选择父节点。
- （未命名）。子节点选择列出的第一个 live 父节点。这种策略有两种变体。
当策略设置为 “false” 时，子节点将使用第一个列出的父节点（为了清晰起见，称为 p1），直到标记为 down，则子节点将切换到第二个列出的父节点（p2）。然后，当重新检测到 p1 为 live 时，子节点将重新使用 p1。
选择策略设置为 “latched”，子节点将使用 p1 直到它被标记为 down，此时它将切换到 p2。当重新检测发现 p1 为 live 时，子节点将继续使用 p2，直到它被标记为 down。

**与 remap.config 的交互**

如果需要重新映射规则（proxy.config.reverse_proxy.enabled），当请求发送到子节点时，将在 parent selection 之前评估 remap.config。这意味着客户端请求是按照重新映射规则进行转换的，因此，应根据重新映射的主机名进行任意的 parent selection。无论是否启用了 pristine host 头部（proxy.config.url_remap.pristine_host_hdr）都是如此。父节点将接收已经转换的请求（因此需要配置为接受它）。

示例：

客户端向 Traffic Server 请求 http://example.com，请求的源服务器是 http://origin.example.com；父节点是 parent1.example.com，子节点配置为反向代理。

如果子节点的 remap.config 包含：

```
map http://example.com http://origin.example.com
```
并且子节点的 parent.config 包含：

```
dest_domain=origin.example.com method=get parent="parent1.example.com:80"
```

父节点缓存（parent1.example.com）需要有一个和 remap.config 行类似的：

```
map http://origin.example.com http://origin.example.com
```

在此示例中，如果 parent1.example.com 为 down，则子节点将在缓存未命中时自动直接联系 origin.exampel.com。

**父节点故障转移**

Traffic Server 支持使用若干个父节点缓存。这样确保一个父节点缓存不可用的情况下，其它的父节点缓存仍然可以服务客户端请求。

当配置 Traffic Server 使用的父节点缓存多于一个，Traffic Server 在检测到一个父节点不可用时，会发送未命中的请求到另一个父节点缓存。如果指定了多余两个父节点缓存，父节点被询问的顺序取决于父节点代理规则在 parent.config 配置文件中的顺序。默认情况下，父节点缓存被询问的顺序是它们在配置文件中的顺序。

**配置 Traffic Server 使用父节点缓存**

要配置 Traffic Server 使用一个或多个父节点缓存，则必须执行下述步骤。

> 注：仅需要配置子节点缓存。假设配置父节点为子节点的源服务器，则作为 Traffic Server 父节点缓存的节点不需要额外的配置。

- 通过编辑位于 records.config 文件中的 proxy.config.http.parent_proxy.routing_enable 来启用父节点缓存选项。

```
CONFIG proxy.config.http.parent_proxy_routing_enable INT 1
```
- 识别服务未命中请求的父节点缓存。要使用父节点故障转移，必须识别多个父节点缓存，这样当一个不可用时，请求可以发送到其它的父节点缓存。
编辑 parent.config 以设置父节点代理规则，该规则将指定当未命中请求时想要转发请求的父节点缓存。

下面的示例配置 Traffic Server 将所有包含正则表达式 politics 和路径 /viewpoint 的请求直接路由到其他源服务器（绕过任何的父节点缓存）：

```
url_regex=politics prefix=/viewpoint go_direct=true
```

下面的示例配置 Traffic Server 将所有以 mms://host1 开头的 URL 未命中请求路由到父节点缓存 parent1。如果 parent1 不能服务这种请求，请求会被转发到 parent2。因为 round-robin=true，Traffic Server 基于客户端 IP 地址轮询的方式来查询父节点缓存。

```
dest_host=host1 scheme=http parent="parent1;parent2" round-robin=strict
```
最后执行 `traffic_ctl config reload` 以应用更改后的配置。

# 七、安全（Security）

## 控制访问（Controlling Access）
Traffic Server 可以配置仅允许某些客户端使用代理缓存。

- 为每个允许访问 Traffic Server 的 IP 地址或 IP 地址段在 ip_allow.config 文件中添加一行。
- 加载配置：traffic_ctl config reload。


## SSL 终端（SSL Termination）

使能 Traffic Server SSL 终端选项可以在客户端和 Traffic Server 或者 Traffic Server 和源服务器之间以反向代理模式安全地连接。

以下描述了如何使能并配置 SSL termination 选项。

- 为客户端/Traffic Server 的连接使能和配置 SSL termination：[Client and Traffic Server Connections](https://docs.trafficserver.apache.org/en/latest/admin-guide/security/index.en.html#client-and-traffic-server-connections).
- 为 Traffic Server/源服务器的连接使能并配置 SSL termination：[Traffic Server and Origin Server Connections](https://docs.trafficserver.apache.org/en/latest/admin-guide/security/index.en.html#traffic-server-and-origin-server-connections).

## 客户端和 Traffic Server 连接

下图说明了在 SSL 终端选项仅开启和配置了客户端和 Traffic Server 连接时客户端和 Traffic Server（以及 Traffic Server 和源服务器）之间的通信。

![](/static/imgs/ats/ssl_c.jpg)

上图描述了以下步骤：

1.客户端发送一个 HTTPS 内容请求。Traffic Server 接收请求并完成 SSL 握手来鉴别客户端（取决于鉴别选项的配置）并决定接下来使用的加密算法。如果客户端的访问被允许，Traffic Server 在其缓存中查找被请求的内容。
2.如果请求在缓存命中且内容有效，Traffic Server 加密内容并发送给客户端。客户端解码内容（使用握手时决定的方法）并展示它。
3.如果请求在缓存未命中或内容过期，Traffic Server 通过 HTTP 和源服务器通信并获取明文的内容信息。Traffic Server 将明文内容信息保存到缓存，同时将内容加密并发送给客户端。客户端解密并展示内容。

要配置 Traffic Server 为客户端和 Traffic Server 之间的连接使用 SSL 终端选项，步骤如下：

1.从公认的认证授权机构（如 VeriSign）获取并安装 SSL 服务证书。SSL 服务证书包含使客户端鉴别 Traffic Server 以及交互加密密钥的信息。
2.使用 records.config 文件中的 proxy.config.http.server_ports 为 SSL 通信设置端口号。
3.在 records.config 设置合适的 SSL 证书和密钥路径：

```
CONFIG proxy.config.ssl.server.cert.path STRING "/opt/ts/etc/ssl/certs/"
CONFIG proxy.config.ssl.server.private_key.path STRING "/opt/ts/etc/ssl/keys/"
```
4.为每个证书和密钥添加一个条目到 ssl_multicert.config 中，以便 Traffic Server 系统用于终止与客户端的 SSL 连接。

```
ip_dest=1.2.3.4 ssl_cert_name=example.com.pem
ip_dest=* ssl_cert_name=default.pem
```

5.可选地：使用 records.config 中的变量 proxy.config.ssl.client.certification_level 来配置客户端证书的使用。如果配置 Traffic Server 需要客户端证书，则 Traffic Server 必须在 SSL 握手阶段验证客户端的证书。如果配置 Traffic Server 不需要客户端证书，或者如果将证书配置为可选地，并且连接客户端不提供证书，然后通过已经设置的其他 Traffic Server 选项（如 ip_allow.config 中的规则）管理对 Traffic Server 的访问。

```
CONFIG proxy.config.ssl.client.certification_level INT 0
```

该变量允许设置为以下值之一：
- 0：不需要客户端证书
- 1：客户端证书可选。如果存在，则用于验证。
- 2：需要客户端证书，并必须基于配置的 CA 进行验证。

6.可选地：配置使用 Certification Authorities（CAs）。CAs 通过验证请求人员的身份来增加安全性。在 records.config 中通过 proxy.config.ssl.CA.cert.path 来配置可接受的 CA 签名。
CONFIG proxy.config.ssl.CA.cert.path STRING "/opt/CA/certs/private-ca.pem"
7.加载配置：traffic_ctl config reload。

## Traffic Server 和源服务器的连接

下图说明了当为 Traffic Server 和源服务器的连接启用了 SSL 终端选项时，Traffic Server 和源服务器之间的通信。

![](/static/imgs/ats/ssl_os.jpg)

上图描述的步骤如下：

1.如果客户端请求在缓存未命中或已过期，Traffic Server 向源服务器发送一个 HTTPS 内容请求。源服务器接收请求并完成 SSL 握手来鉴别 Traffic Server 并决定接下来使用的加密算法。
2.如果 Traffic Server 被允许访问，源服务器将内容加密并发送给 Traffic Server，Traffic Server 使用握手阶段决定的方式来解密该内容。内容的明文（可缓存的情况下）被保存在缓存。
3.如果 SSL 终端开启了客户端和 Traffic Server 之间的连接，Traffic Server 将再次加密内容并通过 HTTPS 发送给客户端，客户端解密并展示内容。如果 SSL 终端没有开启了客户端和 Traffic Server 之间连接，Traffic Server 将通过 HTTP 发送明文内容给客户端。

为了配置 Traffic Server 在 Traffic Server 和源服务器之间启用 SSL 终端选项，步骤如下：

1.首先确保源服务器可以正确响应 SSL 请求，并且如果打算使用其作为访问控制方案的一部分，则配置它以进行客户端证书验证。
更多细节参见源服务器文档。如果源服务器是另一个 Traffic Server 系统，则可以按照 客户端和 Traffic Server 连接 中的步骤概述来配置源服务器以验证客户端证书。
2.可选地：如果源服务器需要客户端证书验证以进行访问控制，则从公认的证书授权机构中获取并安装 SSL 客户端证书。客户端证书必须由源服务器识别的证书颁发机构签名。
如果使用的是客户端证书，则必须在设置 proxy.config.ssl.client.cert.path 和 proxy.config.ssl.client.cert.filename 中将其位置添加到 records.config 。

```
CONFIG proxy.config.ssl.client.cert.path STRING "/opt/ts/etc/ssl/certs/"
CONFIG proxy.config.ssl.client.cert.filename STRING "client.pem"
```
必须提供此证书的私钥路径，除非私钥包含在与证书同一个文件中：

```
CONFIG proxy.config.ssl.client.private_key.path STRING "/opt/ts/etc/ssl/keys/"
CONFIG proxy.config.ssl.client.private_key.filename STRING "client.pem"
```
3.根据安全策略，使用 records.config 中的 proxy.config.ssl.client.verify.server 变量来启用或禁用服务器 SSL 证书验证：

```
CONFIG proxy.config.ssl.client.verify.server INT 1
```
4.设置 records.config 中的 proxy.config.ssl.client.CA.cert.path 和 proxy.config.ssl.client.CA.cert.filanem 来将授权证书颁发机构的集合添加到 Traffic Server 配置中。

```
CONFIG proxy.config.ssl.client.CA.cert.path STRING "/opt/ts/etc/ssl/certs/"
CONFIG proxy.config.ssl.client.CA.cert.filename STRING "CAs.pem"
```
5.更新配置：traffic_ctl config reload。


## Rotating TLS Session Ticket Keys
可以通过 session tickets 恢复 TLS 会话，session tickets 使用 session ticket key 加密并存储在客户端上。为了更好的安全性，可以定期轮换 ticket key，如每 24 小时轮换一次。ticket key 作为 48-byte 块中的反向队列存储在 ticket key 文件中。

生成一个新的 ticket key，并将其 push 到 ticket key 文件的开头。
可选地：从 ticket key 文件中删除上一个 ticket key。
touch ssl_multicert.config 以指示 SSL 配置是过期的。
加载更新后的配置：traffic_ctl config reload。

## OCSP Stapling
OCSP Stapling 是使用在线证书状态协议来检测 SSL 证书撤销状态的另一种方法。

在最初的 OCSP 实现下，客户端直接从颁发证书的证书颁发机构（CA）请求证书的撤销状态。这可能会导致 CA 服务器上出现大量负载，因为它们需要定时向给定证书的每个客户端提供响应。

启用 OCSP Stapling 指示 Traffic Server 去检索并缓存所有已配置 SSL 证书的撤销状态，并当客户端请求状态时将其提供给客户端。Traffic Server 将会自动查询 SSL 证书中指定的 OCSP 响应器，以收集最新的撤销状态。Traffic Server 将缓存每个配置证书的结果。OCSP 响应器的位置取自签名证书的 “Authority Information Access” 字段。比如：

```
Authority Information Access:
            OCSP - URI:http://ocsp.digicert.com
            CA Issuers - URI:http://cacerts.digicert.com/DigiCertSHA2SecureServerCA.crt
```
可以使用 OpenSSL 客户端的 -status 选项测试对 OCSP Stapling 的支持：

```
$ openssl s_client -connect mozillalabs.com:443 -status
...
======================================
OCSP Response Data:
    OCSP Response Status: successful (0x0)
    Response Type: Basic OCSP Response
    Version: 1 (0x0)
...
```
OCSP Stapling TLS 扩展的详细信息位于 [RFC 6961](https://tools.ietf.org/html/rfc6961.html)。

为了配置 Traffic Server 使用 OCSP Stapling，编辑位于 records.config 文件中的如下变量：

- proxy.config.ssl.ocsp.enabled
- proxy.config.ssl.ocsp.cache_timeout
- proxy.config.ssl.ocsp.request_timeout
- proxy.config.ssl.ocsp.update_period

## Split DNS

启用 Split DNS 选项可以配置 Traffic Server 使用多个 DNS 服务器，这取决于安全需求。比如，可以配置 Traffic Server 使用一组 DNS 服务器来解析内部网络的主机名，同时允许防火墙外的 DNS 服务器解析网络上的主机。这可以维护 internet 的安全性，同时继续提供对 organization 外站点的直接访问。

配置 Split DNS：

- 基于目标域，目标主机，或者 URL 正则表达式指定执行 DNS 服务器选择的规则。这些规则位于 splitdns.config：
- 通过 records.config 中的 proxy.config.dns.splitDNS.enabled 来启用 Split DNS：

```
CONFIG proxy.config.dns.splitDNS.enabled INT 1
```
- 加载配置：traffic_ctl config reload.

# 八、缓存存储

# 九、插件

# 十、日志

# 十一、监控

# 十二、配置TS 

# 十三、四层路由

# 十四、优化

# 十五、配置文件

# 十二、实例部署

## 部署环境初始化

```bash
cat << 'EOT' >> /etc/sysctl.conf
fs.file-max=655350
net.ipv4.tcp_max_tw_buckets = 300000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.core.rmem_default=98304
net.core.wmem_default=98304
net.core.rmem_max=2097152
net.core.wmem_max=2097152
net.ipv4.tcp_rmem=4096 98304 2097152
net.ipv4.tcp_wmem=4096 98304 2097152
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_syncookies = 0
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024 65000
EOT
 
sysctl -p /etc/sysctl.conf
```

修改文件最大打开数

```
cat << 'EOT' >> /etc/security/limits.d/nofile.conf
* soft nofile 655350
* hard nofile 655350
EOT
 
cat <<EOF>>/etc/rc.local
#open files
ulimit -HSn 655350
#stack size
ulimit -s 655350
EOF
```

安装ATS的必须的环境

```
yum install -y gcc gcc-c++ pkgconfig pcre-devel tcl-devel expat-devel openssl-devel perl-ExtUtils-MakeMaker bzip2
yum install -y libcap libcap-devel hwloc hwloc-devel ncurses-devel libcurl-devel nwind libunwind-devel autoconf automake libtool
yum install centos-release-scl scl-utils-build
yum install devtoolset-8-gcc* devtoolset-8-toolchain -y
scl enable devtoolset-8 bash
```

## 开始编译ATS

```
#创建属组和用户
groupadd ats
useradd -g ats ats
#下载与编译
wget http://mirrors.tuna.tsinghua.edu.cn/apache/trafficserver/trafficserver-8.0.5.tar.bz2 && tar -xvf trafficserver-8.0.5.tar.bz2 && cd trafficserver-8.0.5 && ./configure --prefix=/usr/local/trafficserver --with-user=ats --with-group=ats --enable-experimental-plugins && make -j $(nproc) && make install
```

`trafficserver start` 启动服务
`traffic_top` 查看缓存状态


## 常用的命令

```
1.启动
trafficserver start 
2.关闭
trafficserver stop
3.重启
trafficserver restart 
4.重载配置文件
traffic_ctl config reload
5.监控ats的状况 类似于top命令
traffic_top
6.清理所有缓存
traffic_server -C clear
```

## 配置目录简介

```
[root@infvie trafficserver]# tree -L 2 etc/trafficserver/
etc/trafficserver/
├── body_factory
│ └── default
├── cache.config                     #Cache规则配置
├── hosting.config                   #磁盘分区分配配置
├── ip_allow.config                  #ip访问控制配置
├── logging.yaml                     #日志系统配置
├── parent.config                    #parent回源配置
├── plugin.config                    #插件配置
├── records.config                   #TS控制参数配置
├── remap.config                     #业务规则配置
├── socks.config
├── splitdns.config                  #splitdns配置
├── ssl_multicert.config             #SSL 配置
├── ssl_server_name.yaml                 
├── storage.config                   #存储配置
├── trafficserver-release
└── volume.config                    #磁盘分区配置
 
2 directories, 15 files
```

# 扩展阅读

- [阿里ATS团队博客](http://zymlinux.net/trafficserver/)
- [ATS官方文档](https://docs.trafficserver.apache.org/en/latest/admin-guide/index.en.html)

