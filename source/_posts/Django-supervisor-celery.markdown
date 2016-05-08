---
layout : post
title : 使用 supervisor 来监控 django celery
category : supervisor
date : 2016-01-19
tags : [supervisor, django, celery]
---

之前启动celery时，使用nohup 方式启动。这种方式是不安全的，今天使者使用supervisor来管理监控celery，记录如下，备查。

### 0x00 安装 supervisor

    pip install supervisor
    
### 0x01 配置文件

    echo_supervisord_conf > /etc/supervisord.conf

在配置文件最后添加如下配置：

    [program:celeryd]

    command=python manage.py celery worker -l info #此处可使用绝对路径

    stdout_logfile=/path/to/your/logs/celeryd.log

    stderr_logfile=/path/to/your/logs/celeryd.log

    autostart=true

    autorestart=true

    startsecs=10

    stopwaitsecs=600
    
    
    
### 0x02 启动关闭supervisor

    # 启动
    supervisord
    # 进入supervisor命令行
    supervisorctl 
    # 直接执行启动
    supervisorctl start celery
    # 关闭没有发现好的方法只能kill了
    kill your-supervisor-pid
    

### 0x03 配置启停脚本

启停脚本地址：https://github.com/Supervisor/initscripts

- 使用redhat-init-mingalevme，将脚本保存为 /etc/init.d/supervisord

- 设置自启动

```bash
    chkconfig --add supervisord
    chkconfig supervisord on
```

- 启停命令

```bash
    service supervisord start
    #supervisorctl 命令
    supervisorctl start xxx
    supervisorctl stop xxx
    #重新加载配置文件
    supervisorctl reload
```






### Q&A 

1、FATAL Exited too quickly (process log may have details
    
   原因：配置文件命令行问题，错误前配置：python manage.py celery worker -l info >celery.log 
   
   改正：python manage.py celery worker -l info 
   
2、问题：

```bash

    [root@localhost ~]# echo_supervisord_conf > /etc/supervisord.conf
    Traceback (most recent call last):
      File "/usr/local/bin/echo_supervisord_conf", line 5, in <module>
        from pkg_resources import load_entry_point
      File "/usr/local/lib/python2.7/site-packages/setuptools-0.6c11-py2.7.egg/pkg_resources.py", line 2603, in <module>
      File "/usr/local/lib/python2.7/site-packages/setuptools-0.6c11-py2.7.egg/pkg_resources.py", line 666, in require
      File "/usr/local/lib/python2.7/site-packages/setuptools-0.6c11-py2.7.egg/pkg_resources.py", line 565, in resolve
    pkg_resources.DistributionNotFound: meld3>=0.6.5
    
```

解决方法：
注释掉 `/usr/local/lib/python2.7/site-packages/setuptools-0.6c11-py2.7.egg/require.txt` 文件中的 `meld3>=0.6.5`



### 参考：

- [https://micropyramid.com/blog/celery-with-supervisor/](https://micropyramid.com/blog/celery-with-supervisor/)
- [http://www.marswj.com/post/45/Installation-and-configuration-of-supervisor-in-CentOS](http://www.marswj.com/post/45/Installation-and-configuration-of-supervisor-in-CentOS)