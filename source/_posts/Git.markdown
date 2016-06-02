---
layout : post
title : Git使用学习笔记
category : vcs
tagline: ""
date : 2015-11-01
tags : [vcs,]
---


### 一、Git知识点

1. 将发生变化的文件全部保存。为了减少磁盘使用，只保存发生变化的文件。使用sha1算法的20字节（40位）值作为对象的唯一标识。
![][1]

2. 三个域：
repository -- 仓库
working directory -- 工作区
staging area/index -- 过渡区
![][2]

3. 三个对象：
tree ：记录文件名，及指向blob的指针 
blob ：记录文件内容
commit ：和tree是一一对应的
find .git/objects/ -type f |wc -l
git cat-file -t sha1码
git show -s --pretty=raw xxx

4. 三个引用：
HEAD
branch
remote branch

5. 其他：
对象是静止的，引用是动态的。


### 二、操作使用

#### git配置

1.文件位置

用户目录下的全局配置文件：
C:\Users\Administrator\.gitconfig
各仓库自己的配置文件：
D:\gitdemo\.git\config

2.用户配置：

```bash
# 全局，
git config --global user.name 'pyli.xm'
git config --global user.email 'pyli.xm@gmail.com'
# 局部，
git config  user.name 'pyli.xm'
git config  user.email 'pyli.xm@gmail.com'
```
#### 命令

1、git初始化

```bash
    git init 
```
    
2、添加文件

    git add # 文件名

3、提交

```bash
git commit -m '说明'
# 添加并提交 
git commit -a -m '说明'
```

4、标签

```bash
# 创建：
git tag 标签名
# 打包：
git archive --format=tar --prefix=gitdemo/ 标签名|gzip > /gitdemo/gitdemo.tar.gz
# 检出：
git checkout 标签名
# 提交tag到远程
git push [origin] --tags
# 删除远程tag
$ git push origin :refs/tags/tagname
```

5、分支 

```bash
#列出
git branch -l/-all
#创建：
git branch 分支名
#分支切换 
git checkout  分支名
# 创建分之并切换分之
git checkout -b 分支名
#分支合并：
git merge 分支名A  在B分之下执行，将A合并到B分支上。
#删掉分支  
git branch -D 分支名A
#删除远程分支（>v1.7）
git push origin --delete <branchName>
```

6、回溯

单个文件：

```bash
git log -3
```

![][3]

```bash
# 使用此方法回溯单个文件的版本。
git check f0a843a92216d103cec18c746dd7a0b1ed5b0020  [文件路径] 
```

整个版本库：

```bash
本地库回滚：
git reset --hard <commit ID号> 或者 git reset --hard HEAD^
远程库回滚：
原理：先将本地分支退回到某个commit，删除远程分支，再重新push本地分支
操作步骤：
1、git checkout the_branch
2、git pull
3、git branch the_branch_backup //备份一下这个分支当前的情况
4、git reset --hard the_commit_id //把the_branch本地回滚到the_commit_id
5、git push origin :the_branch //删除远程 the_branch
6、git push origin the_branch //用回滚后的本地分支重新建立远程分支
7、git push origin :the_branch_backup //如果前面都成功了，删除这个备份分支
```


![][5]


7、查看当前修改了那些文件

![][4]



**更多实例参考 ``git --help``** 


---

[1]:/images/git-1.png
[2]:/images/git-2.png
[3]:/images/git-3.png
[4]:/images/git-4.png
[5]:/images/git-5.png