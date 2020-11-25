---
type : posts
title : 无法添加crontab 解决 No space left on device
categories: [Linux,] 
date : 2019-01-15T16:04:08+08:00
tags : [crontab, 计划任务, QA]
---

### Q & A：

今天在添加Linux 计划任务时，遇到如下问题，

```
/var/spool/cron/IBM11070003.tmp.XXXXQxX3UB: No space left on device
```

从错误信息看应该是磁盘空间满了，但是通过 `df -h`查看 `/var` 占用78%并没有满。
继续查阅资料，得知如下知识点：

>Linux 文件在创建时，除了占用磁盘空间外还占用「索引结点」，索引结点磁盘一样也是有限的。

可以使用 `df -i` 查看索引节点。使用该命令查看 `/var` 果然使用是 100%。

文件索引节点会使用如此之快，是因为：

>在配置crontab 时，并没有将脚本输出重定向到`/dev/null`，它会已邮件的形式发送给crontab 用户，但是我们没有配置这块逻辑，导致发送失败，它便以小文件的形式，堆积在`/var/spool/postfix/maildrop` 目录，占用磁盘空间不大，但是文件数量庞大，占用索引节点。

<!-- more -->

### 解决方案：

思路便是直接清理上述文件目录中的小文件即可。

```bash
cd /var/spool/postfix/maildrop
ls | xargs -n 100 rm -rf 
```

- 由于文件太多，直接删除回报 `/bin/rm:Argument list too long`错误 ，需要分批删除
- `-n 100` 每组100个文件，删除。