---
type : post
title : Linux基础系列 - 三剑客之 grep 命令使用总结
categories: [Linux,] 
date : 2018-10-23
url: /posts/2018-10-23-Linux-grep.html 
tags : [Linux, Linux基础系列, 运维知识库]
---

## 简介

`grep` 命令是用来搜索文本的命令行工具，现在大部分Linux发行版本都集成了该命令行工具。该命令行是英文“ globally search a regular expression and print ”的简写，就是可以通过正则来搜索并打印结果。

`grep` 最早是unix系统中的命令行工具，有多个扩展版本，如下：
- `egrep` 使用更复杂的正则表达式来搜索。
- `fgrep` 用于固定样式搜索fixed pattern searches。

不过，以上扩展版本基本都可以使用参数来获取相同的功能，可分别使用`-E`和`-F`。其他相似的命令还有 `zgrep` ，它可以直接搜索使用`gzip`压缩的文件内容。

<!-- more -->

## 使用方法

```bash
# 语法
grep [options] match_pattern file_name
grep [options] "match_pattern" file_name
```

### 常用参数选项

```bash
-a 不要忽略二进制数据。
-A<显示列数> 除了显示符合范本样式的那一行之外，并显示该行之后的内容。
-b 在显示符合范本样式的那一行之外，并显示该行之前的内容。
-c 计算符合范本样式的列数。
-C<显示列数>或-<显示列数>  除了显示符合范本样式的那一列之外，并显示该列之前后的内容。
-d<进行动作> 当指定要查找的是目录而非文件时，必须使用这项参数，否则grep命令将回报信息并停止动作。
-e<范本样式> 指定字符串作为查找文件内容的范本样式。
-E 将范本样式为延伸的普通表示法来使用，意味着使用能使用扩展正则表达式。
-f<范本文件> 指定范本文件，其内容有一个或多个范本样式，让grep查找符合范本条件的文件内容，格式为每一列的范本样式。
-F 将范本样式视为固定字符串的列表。
-G 将范本样式视为普通的表示法来使用。
-h 在显示符合范本样式的那一列之前，不标示该列所属的文件名称。
-H 在显示符合范本样式的那一列之前，标示该列的文件名称。
-i 忽略字符大小写的差别。
-l 列出文件内容符合指定的范本样式的文件名称。
-L 列出文件内容不符合指定的范本样式的文件名称。
-n 在显示符合范本样式的那一列之前，标示出该列的编号。
-q 不显示任何信息。
-R/-r 此参数的效果和指定“-d recurse”参数相同。
-s 不显示错误信息。
-v 反转查找。
-w 只显示全字符合的列。
-x 只显示全列符合的列。
-y 此参数效果跟“-i”相同。
-o 只输出文件中匹配到的部分。
```

### 常用实例 

```bash
# 多个文件搜索
grep "match_pattern" file_1 file_2 file_3
grep "match_pattern" file_*

# 反向搜索
grep -v "match_pattern" file_name

# 标记匹配颜色
grep "match_pattern" file_name --color=auto

# 搜索本目录及子目录中所有文件
grep "text" . -r 

# 搜索文件中排除，或包含指定文件
grep "main()" . -r --include *.{php,html}
grep "main()" . -r --exclude "README"

# 静默执行。不会输出任何信息，如果命令运行成功返回0，失败则返回非0值。一般用于条件测试。
grep -q "test" filename

# 打印匹配，之前或之后的行
grep "5" -A 3  # 打印匹配结果行之前3行
grep "5" -B 3  # 打印匹配结果行之后3行
grep "5" -C 3  # 打印匹配结果行之前和之后各3行
```

## 参考

- [http://man.linuxde.net/grep](http://man.linuxde.net/grep)
- [https://zh.wikipedia.org/wiki/Grep](https://zh.wikipedia.org/wiki/Grep)