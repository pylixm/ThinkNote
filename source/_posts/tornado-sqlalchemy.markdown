---
layout : post
title : SQLAlchemy 数据库链接池问题排查记录
category : tornado
date : 2017-08-29
tags : [tornado, sqlalchemy]
---


## 环境

web框架：tornado 
ORM： SQLAlchemy 
DB: MySQL

## 问题描述

我们的项目为tornado 开发的API服务，使用SQLALchemy 作为ORM与数据库做交互，SQLAlchemy我们使用了链接池的方式。代码如下：
```python
connect_str = "mysql+pymysql://%s:%s@%s:%s/%s?charset=utf8" % (settings.get("user"), settings.get("password"),
                                                    settings.get("host"), settings.get("port"), settings.get("name"))
engine = create_engine(connect_str, pool_size=10, pool_recycle=300, echo=False, max_overflow=5)
```

在线上运行中，我们发现每隔一段时间会报数据库链接的错误，错误日志如下：
```
    Traceback (most recent call last):
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/pool.py", line 687, in _finalize_fairy
        fairy._reset(pool)
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/pool.py", line 827, in _reset
        self._reset_agent.rollback()
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/engine/base.py", line 1612, in rollback
        self._do_rollback()
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/engine/base.py", line 1650, in _do_rollback
        self.connection._rollback_impl()
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/engine/base.py", line 703, in _rollback_impl
        self._handle_dbapi_exception(e, None, None, None, None)
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/engine/base.py", line 1393, in _handle_dbapi_exception
        exc_info
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/util/compat.py", line 203, in raise_from_cause
        reraise(type(exception), exception, tb=exc_tb, cause=cause)
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/util/compat.py", line 186, in reraise
        raise value.with_traceback(tb)
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/engine/base.py", line 701, in _rollback_impl
        self.engine.dialect.do_rollback(self.connection)
      File "/usr/local/connector/env/lib/python3.6/site-packages/sqlalchemy/dialects/mysql/base.py", line 1572, in do_rollback
        dbapi_connection.rollback()
      File "/usr/local/connector/env/lib/python3.6/site-packages/pymysql/connections.py", line 788, in rollback
        self._execute_command(COMMAND.COM_QUERY, "ROLLBACK")
      File "/usr/local/connector/env/lib/python3.6/site-packages/pymysql/connections.py", line 1088, in _execute_command
        self._write_bytes(packet)
      File "/usr/local/connector/env/lib/python3.6/site-packages/pymysql/connections.py", line 1040, in _write_bytes
        "MySQL server has gone away (%r)" % (e,))
    sqlalchemy.exc.OperationalError: (pymysql.err.OperationalError) (2006, "MySQL server has gone away (BrokenPipeError(32, 'Broken pipe'))")
```
或如下错误：
```
(pymysql.err.OperationalError) (2014, 'Command Out of Sync')
```

## 初步分析

1、根据错误，怀疑是SQLAlchemy 链接池回收的问题。通过阅读链接池的官方文档, 看到如下描述：
>Above, any DBAPI connection that has been open for more than one hour will be invalidated and replaced, upon next checkout. Note that the invalidation only occurs during checkout - not on any connections that are held in a checked out state. pool_recycle is a function of the Pool itself, independent of whether or not an Engine is in use.

[这里](http://docs.sqlalchemy.org/en/latest/core/pooling.html?highlight=pool_recycle#setting-pool-recycle)

可知，链接的回收并不会导致正在被使用的链接的异常。

将回收时间调小测试，确实并没有引起以上的报错。


2、根据错误信息查询，发现github社区有人遇到同样的报错，是因为mysql数据库的数据包太大导致，见[这里](https://github.com/PyMySQL/PyMySQL/issues/426)。后来`pymysql`的维护者，针对此问题做了修正。查看我们数据的参数 `max_allowed_packet`足够大，所以也不回一切上边的报错。pymysql 默认这个值为 16M([这里](http://pymysql.readthedocs.io/en/latest/modules/connections.html?highlight=max_allowed_packet)),也足够大。

3、查询stackoverflow, 发下如下问题：[Python SQLAlchemy - “MySQL server has gone away”](https://stackoverflow.com/questions/18054224/python-sqlalchemy-mysql-server-has-gone-away)。按照此解决方法，增加链接池的监听函数，问题顺利解决。代码如下：
```python
def checkout_listener(dbapi_con, con_record, con_proxy):
    try:
        try:
            dbapi_con.ping(False)
        except TypeError:
            dbapi_con.ping()
    except dbapi_con.OperationalError as exc:
        if exc.args[0] in (2006, 2013, 2014, 2045, 2055):
            raise DisconnectionError()
        else:
            raise

event.listen(engine, 'checkout', checkout_listener)
```
代码解读：
1、使用SQLAlchemy 的`PoolListener`监听链接池的可用性，
2、在链接被`checkout`使用时，先验证链接的有效性，若无效则抛出`DisconnectionError`错误，让链接池回收，重新创建个新的链接。

更多SQLAlchemy无效链接的描述，见[官方文档](http://docs.sqlalchemy.org/en/latest/core/pooling.html#dealing-with-disconnects)

## 原理分析

在上边分析3中，我通读了[https://discorporate.us/jek/talks/SQLAlchemy-EuroPython2010.pdf](https://discorporate.us/jek/talks/SQLAlchemy-EuroPython2010.pdf)，文中有个案例提到了SQLAlchemy的链接池监听
>The connection pool should always dispense valid connections.

就是说我们应该保证链接池分配出去的链接的有效性，查阅了SQLAchemy的官方文档链接池部分，并没有发现对分配链接有效性保证的措施。所以说，链接池并不能够保证分配出去的链接是可用的，以此导致文章开头的错误。

到此，问题便清晰了，即：`错误的、无效的、没有到回收时间的数据库链接被链接池分配出去，导致访问数据库异常。`

## 参考

- [https://discorporate.us/jek/talks/SQLAlchemy-EuroPython2010.pdf](https://discorporate.us/jek/talks/SQLAlchemy-EuroPython2010.pdf)
- [SQLAlchemy无效链接描述](http://docs.sqlalchemy.org/en/latest/core/pooling.html#dealing-with-disconnects)
- [SQLALchemy事件描述](http://docs.sqlalchemy.org/en/latest/core/pooling.html#pool-events)