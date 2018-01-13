---
layout : post
title : pipenv 试用过程分享
category : python
date : 2018-01-13
tags : [python ]
---

最近常看到`pipenv`这个管理工具，今天有时间查了下，是 [Kennethreitz](https://www.kennethreitz.org/values) 大神的作品，看了下github的仓库，是2017年1月份创建的，仅仅一年的时间变获得了7k+的收藏，最新一次的提交时间为2天前，可见该仓库活跃程度。自己之前写过一篇文章[《使用 pyenv + virtualenv 打造多版本python开发环境》](http://www.pylixm.cc/posts/2016-06-19-Virtualenv-install.html),遗留个问题，一直没有找到合理的同时管理python和python依赖包的工具，试用了下	`pipenv`，可以说完美的解决了python版本及包的管理问题。并且`pipebv` 还是`Python.org`正式推荐的python包管理工具。原文如下：

>Pipenv — the officially recommended Python packaging tool from Python.org, free (as in freedom).

那么接下来，分享下我的试用过程，供大家参考：

## 准备工作

### 试用环境及相关文档

**环境**
- pipenv 9.0.1 
- python3.6
- python2.7

**文档**
- github仓库地址：[pipenv](https://github.com/pypa/pipenv)  
- [pipenv 官方文档](https://docs.pipenv.org/)

### pipenv 基本概念理解

1. 之前我们使用pip + virtualenv 来管理python依赖包，使用 `--python=`参数来区分python版本（不再使用pyenv,减少包依赖）。而pipenv的思路简单理解便是把pip和virutalenv 2个工具统一起来，使用 `pipenv` 来代替。
2. `pipenv` 使用 Pipfile 来代替 requirement.txt 文件记录python包。
3. 增加了`Pipfile.lock` 文件来锁定python软件的包名及版本，以及其依赖关系的列表。
4. 它参考了其他语言的包管理工具（bundler, composer, npm, cargo, yarn, etc.），旨在将最好的包管理工具带入python世界。


## pipenv 功能试用

### pipenv 安装

#### 普通安装
`pipenv` 可使用 pip 直接安装。

```
pip install pipenv 
```

作者推荐在`python3`下边安装，会提高与virtualenv的兼容性。

```
The use of Python 3 is highly preferred over Python 2, when installing Pipenv. Compatibility with three virtualenvs is greatly improved when using Python 3 as the installation target.

—Kenneth Reitz
```
#### 用户模式安装

为防止和系统python库产生影响，可使用此种方案安装。
```
pip install --user pipenv
```
pip 默认安装包路径为`/usr/local/lib/python2.7/site-packages`。此模式下，pip安装包保存路径为用户库路径,一般为`/Users/pylixm/Library/Python/3.6/lib/python/site-packages`, 可使用命令`python3 -m site --user-site` 具体查看。如果在安装后你的shell中pipenv不可用，你需要把用户库的二进制目录`/Users/pylixm/Library/Python/3.6/bin`添加到你的PATH中。

### pipenv 使用

#### 初始化虚拟环境

执行`pipenv install`，创建虚拟环境，如下：

```
~/laboratory/pip_test_project ⌚ 20:42:10
$ pipenv install
Creating a virtualenv for this project…
⠋New python executable in /Users/pylixm/.local/share/virtualenvs/pip_test_project-MXA0TC90/bin/python2.7
Also creating executable in /Users/pylixm/.local/share/virtualenvs/pip_test_project-MXA0TC90/bin/python
Installing setuptools, pip, wheel...done.

Virtualenv location: /Users/pylixm/.local/share/virtualenvs/pip_test_project-MXA0TC90
Creating a Pipfile for this project…
Pipfile.lock not found, creating…
Locking [dev-packages] dependencies…
Locking [packages] dependencies…
Updated Pipfile.lock (c23e27)!
Installing dependencies from Pipfile.lock (c23e27)…
  🐍   ▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉▉ 0/0 — 00:00:00
To activate this project's virtualenv, run the following:
 $ pipenv shell
```

从打印信息可见，它在目录用户目录`.local`下创建了个和项目同名的虚拟环境(可通过配置环境变量来自定义虚拟环境目录，`export WORKON_HOME=~/.venvs`)，python使用的是默认的python2.7 。
可通过参数`--two` 和`--three` 来泛指python版本，也可通过`--python 3.5` 来明确知道python版本，但是这些参数的前提是你系统上有此python版本，否则会报如下错误：
```
$ pipenv --python 3.5
Warning: Python 3.5 was not found on your system…
You can specify specific versions of Python with:
  $ pipenv --python path/to/python

```
有点像 virtualenv 的 `--python`参数。

初始化好虚拟环境后，会在项目目录下生成2个文件`Pipfile`和`Pipfile.lock`。为pipenv包的配置文件，代替原来的 requirement.txt。项目提交时，可将`Pipfile` 文件和`Pipfile.lock`文件受控提交,待其他开发克隆下载，根据此Pipfile 运行命令`pipenv install [--dev]`生成自己的虚拟环境。

`Pipfile.lock` 文件是通过hash算法将包的名称和版本，及依赖关系生成哈希值，可以保证包的完整性。


#### 安装python模块

##### 正常安装 

安装 `requests` 模块：
```
$ pipenv install requests
Installing requests…
Collecting requests
  Using cached requests-2.18.4-py2.py3-none-any.whl
Collecting certifi>=2017.4.17 (from requests)
  Using cached certifi-2017.11.5-py2.py3-none-any.whl
Collecting idna<2.7,>=2.5 (from requests)
  Using cached idna-2.6-py2.py3-none-any.whl
Collecting urllib3<1.23,>=1.21.1 (from requests)
  Using cached urllib3-1.22-py2.py3-none-any.whl
Collecting chardet<3.1.0,>=3.0.2 (from requests)
  Using cached chardet-3.0.4-py2.py3-none-any.whl
Installing collected packages: certifi, idna, urllib3, chardet, requests
Successfully installed certifi-2017.11.5 chardet-3.0.4 idna-2.6 requests-2.18.4 urllib3-1.22

Adding requests to Pipfile's [packages]…
  PS: You have excellent taste! ✨ 🍰 ✨
Locking [dev-packages] dependencies…
Locking [packages] dependencies…
Updated Pipfile.lock (2f8679)! 
```

可通过命令`pipenv graph` 查看已安装模块，同时可查看他们直接的相互依赖情况。

```bash
$ pipenv graph
requests==2.18.4
  - certifi [required: >=2017.4.17, installed: 2017.11.5]
  - chardet [required: <3.1.0,>=3.0.2, installed: 3.0.4]
  - idna [required: >=2.5,<2.7, installed: 2.6]
  - urllib3 [required: >=1.21.1,<1.23, installed: 1.22]
```

##### 只安装开发环境

可通过以下命令，仅安装在开发环境,
```
pipenv install --dev requests --three
```

区别反映在`Pipfile` 上为:
```
[[source]]

url = "https://pypi.python.org/simple"
verify_ssl = true
name = "pypi"

[dev-packages]


[packages]

requests = "*"
flask = "==0.10"

[requires]
python_version = "3.6"

```
安装包记录是在`[dev-packages]` 部分，还是`[packages]` 部分。在安装时，指定`--dev`参数，则只安装`[dev-packages]`下的包,若安装时不定指定`--dev`参数，只会安装`[packages]` 包下面的模块。

`[requires]` 下的python在构建新的虚拟环境时，若没有会自动下载安装。

##### 通过 requirements.txt 安装

```
pipenv install -r requirements.txt
```

这样我们可以重用之前的requirement.txt 文件来构建我们新的开发环境，可以把我们的项目顺利的迁到pipenv。

可通过以下命令生成requirements 文件：
```
pipenv lock -r [--dev] > requirements.txt
```

#### 运行虚拟环境

可使用以下命令来运行项目：
```
pipenv run python xxx.py
```

或者启动虚拟环境的shell环境：
```
~/laboratory/pip_test_project
$ pipenv shell --anyway
Spawning environment shell (/bin/zsh). Use 'exit' to leave.
source /Users/pylixm/.local/share/virtualenvs/pip_test_project-MXA0TC90/bin/activate

~/laboratory/pip_test_project 
$ source /Users/pylixm/.local/share/virtualenvs/pip_test_project-MXA0TC90/bin/activate
(pip_test_project-MXA0TC90)
~/laboratory/pip_test_project
$ exit

~/laboratory/pip_test_project
$ pipenv shell
Shell for UNKNOWN_VIRTUAL_ENVIRONMENT already activated.
No action taken to avoid nested environments.

```
直接运行`pipenv shell` 并不会出现shell命令行，是应为没有配置环境变量。还需要进一步研究，貌似需要配置环境变了，一直没找到。

`pipenv` 提供了`.env` 文件，放在项目目录下，提供项目所需的环境变量，运行`pipenv shell` 时，会自动加载。

#### 删除虚拟环境及包

删除包:
```
pipenv uninstall reuqests
```

删除虚拟环境：
```
pipenv --rm 
```

## 总结

- `pipenv` 完美的解决了python的包和版本的管理。
- 并对包之间的依赖关系也管理起来，方便了开发者构建自己的开发运行环境。

时间有限，以上列举的仅为部分功能，更多的强大功能详见[官方文档](https://docs.pipenv.org/)。


## 参考
- [https://docs.pipenv.org/](https://docs.pipenv.org/)