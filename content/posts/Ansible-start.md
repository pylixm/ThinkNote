---
type : posts
title : Ansible 快速入门
categories: [Ansible,] 
date : 2021-02-09
url: /posts/2021-02-09-ansible-start.html 
tags : [ansible, ]
---

Ansible 是自动化运维领域一款常用的服务器集群管理工具，他有丰富的文档和活跃的社区。

与同类型的竞品开源工具SaltStack/Puppet 相比，各有特色。可参考：

- https://www.edureka.co/blog/chef-vs-puppet-vs-ansible-vs-saltstack/
- https://www.educba.com/saltstack-vs-ansible/

本文旨在让读者快速掌握或回顾 Ansible 的一些概念和用法，所以并不会涉及细节的东西。如想进一步掌握，可阅读 Ansible 的[官方文档](https://docs.ansible.com/ansible/latest/index.html)。


## 介绍

Ansible是一款简单的运维自动化工具，只需要使用ssh协议连接就可以来进行系统管理，自动化执行命令，部署等任务。

### Ansible的特点

- 1、ansible不需要单独安装客户端，也不需要启动任何服务
- 2、ansible是python中的一套完整的自动化执行任务模块
- 3、ansible playbook 采用yaml配置，对于自动化任务执行过程一目了然
- 3、ansible 执行任务时幂等的。

### Ansible组成结构

**控制机**

安装ansible 的机器，截止目前`2.9`，只支持Linux 和 Mac 作为控制机，不支持 Windows。配置文件默认路径`/etc/ansible/ansible.cfg`。

- 官方文档：[配置文件字段详解](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings-locations)


**被控机** 

在 ansible hosts 清单里的机器，控制机可ssh 登录。ssh 登录时，可使用用户名密码或私钥公钥登录。

**清单（Inventory）**

Ansible管理主机的清单，可ip、hostname，可分组控制。默认是 `/etc/ansible/hosts`文件，可使用 `-i <path>` 参数在命令行中指定。

* 配置文件中，清单可以是文件或目录。当是目录的时候，ansible会合并目录中所有的静态清单和动态清单的数据。
* 官方文档：[如何构建清单文件](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#intro-inventory)
* 清单理解：[Ansible_静态和动态清单文件管理](https://www.cnblogs.com/itwangqiang/p/13640601.html)

**集合（Collections）**

一种ansible 的分发格式，包含剧本、角色、模块和插件。

**模块（Modules）**

Ansible执行命令的功能模块，执行代码的基本单元。Ansible2.3版本为止，共有1039个模块。还可以自定义模块。

* 官方文档：[可用模块列表](https://docs.ansible.com/ansible/latest/collections/index.html#list-of-collections)

**任务（Tasks）**

ansible 执行的任务单元。

**剧本（Playbooks）**

任务剧本（又称任务集），编排定义Ansible任务集的配置文件，由Ansible顺序依次执行，可重复执行，yaml格式。

* 官方文档：[编写playbook的技巧](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#playbooks-tips-and-tricks)

**ansible**

是`ansible`的命令工具，核心执行工具；一次性或临时执行的操作都是通过该命令执行。

**Plugins**

插件，模块功能的补充，常有连接类型插件，循环插件，变量插件，过滤插件，插件功能用的较少。

- 官方文档：[插件列表](https://docs.ansible.com/ansible/latest/plugins/plugins.html)

**API**

提供给第三方程序调用的应用程序编程接口。

* [API 文档: ansible runner](https://ansible-runner.readthedocs.io/en/latest/)

## Ansible 基本概念

### 变量 

清单文件中的变量：

```yml
[all:vars]
foo1=bar
foo2=bar2

[group1]
host1
host2

[group1:vars]
foo3=bar3
PlayBook
```

Playbook 中的变量：

```yml
---
- hosts: all
  vars:
    http_port: 80
  vars_prompt:
    - name: service_name
      prompt: "Which service do you want to remove?"
      private: no
  vars_files:
    - /vars/external_vars.yml
```

角色专用变量，一般位于 `defaults/mian.yml` 或者 `vars/ `目录下。官方文档，[角色（Roles）](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)

ansible 内部自定的变量，可以通过下面命令查看：

```bash
$ ansible hostname -m setup
{
    "ansible_all_ipv4_addresses": [
        "REDACTED IP ADDRESS"
    ],
    "ansible_all_ipv6_addresses": [
        "REDACTED IPV6 ADDRESS"
    ],
    "ansible_apparmor": {
        "status": "disabled"
    },
    "ansible_architecture": "x86_64",
    "ansible_bios_date": "11/28/2013"
        ......
}
```

#### 变量作用域

ansible 的变量作用域主要有 3 种：

- Global：ansible 配置文件，环境变量，命令行
- Play：playbook vars, vars_prompt, vars_files; role defaults, vars
- Host: Inventory 中定义的的 host vars; facts

#### 变量使用

ansible 允许你在各处通过 jinja2 的语法使用变量。jinja2 是一个用 Python 开发的模版引擎，本身并不复杂，核心东西就 3 个：变量的输出，控制流，过滤器。

需要注意的是，在 Ansible 中如果你要使用 jinja2 的语法去引用一个变量，必须用双引号内使用。

```yaml
- hosts: all
  vars:
    deploy_path: "{{ home_dir }}/apps"
```

比如我们想根据各种上下文生成 nginx 的配置文件，可以通过 template 命令来渲染。首先定一个模版文件 `nginx.conf.j2`

```
server {
  server_name {{ server_name }};
  listen 80;
  
  location / {
    try_files $uri $uri/ /index.html;
  }
}
```

我们希望这个配置文件可以覆盖默认的 nginx 配置：

```yaml
- hosts: nginx
  vars:
    server_name: gio.com
    nginx_user: nginx
    nginx_group: "{{ nginx_user }}"
  tasks:
    - name: generate nginx config file
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: "{{ nginx_user }}"
        group: "{{ nginx_group }}"
      become: yes
```

### 角色 

统一管理playbook文件，可理解为一个标准的目录规范。可使用如下命令初始化一个角色目录：

`ansible-galaxy init roles/role_nginx`

```目录结构
└── role_nginx
    ├── defaults
    │   └── main.yml
    ├── files
    ├── handlers
    │   └── main.yml
    ├── meta
    │   └── main.yml
    ├── README.md
    ├── tasks
    │   └── main.yml
    ├── templates
    ├── tests
    │   ├── inventory
    │   └── test.yml
    └── vars
        └── main.yml
```

roles 同目录，创建调用play文件，即可应用整个角色。

```
---
# this playbook deploy the whole application stack in this site
- name: configuration and deploy webservers and application code
  hosts: webservers
  
  roles:
    - role_nginx
```

角色文件的寻找目录：

- play 文件同级目录的role同名目录
- play 文件统计目录的roles 目标下 
- `~/.ansible/roles` 用户目录下 
- ansible.cfg 配置的角色目录下 
- /etc/ansible/roles 目录下
- 也可使用绝对路径配置角色

## 使用指南

### 命令行方式 

```
ansible [pattern] -m [module] -a "[module options]"
```

- pattern 匹配主机的模式
- `-m` 指定调用的模块
- `-a` 模块需要的参数
- 其他参数文档，[官方文档](https://docs.ansible.com/ansible/latest/cli/ansible.html#ansible)

### playbook 方式（yaml配置文件）

```
ansible-playbook <playbook name>.yml 
```

- 参数文档，[官方文档](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html#ansible-playbook)

```yaml
# test.yaml
- hosts: all
  tasks:
    - name: install vim
      yum:
        name: vim
        state: present

    - name: install jdk
      yum:
        name: openjdk
        state: present
```

运行如下命令执行：

```bash
ansible-playbook test.yaml 
```

## 更多文档

- [朱双印ansible 系列文章](http://www.zsythink.net/archives/category/%e8%bf%90%e7%bb%b4%e7%9b%b8%e5%85%b3/ansible/)