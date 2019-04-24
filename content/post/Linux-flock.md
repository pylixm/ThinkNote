---
layout : post
title : Linux基础系列 - flock 命令
categories: [Linux,] 
date : 2019-04-24
url: /posts/2019-04-24-flock.html 
tags : [Linux, 运维知识库]
---

最近有这么一个场景，系统的定时任务执行时间长周期短，可能本周期执行时，上个周期的任务还没有执行完，这样便会造成相同的任务同一时间有过个任务进程在执行。如果任务有对互斥资源操作时，有可能产生死锁。

解决此问题这里有几种方法：

- 1、新增一个任务进程来控制任务的执行，每次启动新任务时，检测下是否有任务在执行。
- 2、使用Linux 系统自带的文件锁命令：flock 

第一种，比较简单，本文不再赘述。咱们来看下第二种方式，flock 命名。

## flock 命令

flock 命令，是Linux 的文件锁命令。可以通过一个锁文件，来控制在shell 中逻辑的互斥性。用法如下；

```bash 
Usage:
 flock [options] <file|directory> <command> [command args]
 flock [options] <file|directory> -c <command>
 flock [options] <file descriptor number>

Options:
 -s  --shared             get a shared lock
 -x  --exclusive          get an exclusive lock (default)
 -u  --unlock             remove a lock
 -n  --nonblock           fail rather than wait
 -w  --timeout <secs>     wait for a limited amount of time
 -E  --conflict-exit-code <number>  exit code after conflict or timeout
 -o  --close              close file descriptor before running command
 -c  --command <command>  run a single command string through the shell

 -h, --help     display this help and exit
 -V, --version  output version information and exit

For more details see flock(1).
```

用它来实现我们上边说的“任务互斥”。可如下配置：

```bash
# old 
*/10 * * * * /bin/bash do_somethings_with_long_time.sh 

# new 
*/10 * * * * flock -xn /tmp/my.lock -c "/bin/bash do_somethings_with_long_time.sh "
```

- x 表示文件锁为互斥文件锁，这个参数可以省略，默认即为互斥文件锁。
- n 表示当有任务执行时，直接退出，符合我们的逾期。

除了上边的功能，大家还可以实现排队等待、共享锁等功能。可如下配置：

```bash
# 排队执行  每个任务等待 20s，超时则退出
*/10 * * * * flock -w 20 /tmp/my.lock -c "/bin/bash do_somethings_with_long_time.sh "

# 共享锁
*/10 * * * * flock -s /tmp/my.lock -c "/bin/bash do_somethings_with_long_time.sh "

# 忽略锁，直接执行
*/10 * * * * flock -u /tmp/my.lock -c "/bin/bash do_somethings_with_long_time.sh "

# 自定义退出码
*/10 * * * * flock -E 1 -w 20 /tmp/my.lock -c "/bin/bash do_somethings_with_long_time.sh "
```

这里需要注意，在自定义退出码时，尽量使用1位的数字，当使用多位数字时，会出现不是自定义的其他返回码。


## 参考 
- https://linux.die.net/man/1/flock