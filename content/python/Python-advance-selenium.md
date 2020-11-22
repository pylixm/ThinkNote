---
type : post
title : CentOS 7 部署Selenium相关脚本
categories: [Python,] 
series: [Python进击,]
date : 2020-07-14
url: /posts/2020-07-14-python-selenium.html 
tags : [Python,]
---

Selenium 库不必多说，是Python 生态中的神器，在动态网页爬取和自动化测试中有广泛的应用。之前公司前辈，用它搞了个抢会议室的脚本，今天加了点功能，优化了下。有些问题，总结记录下，分享出来，希望对你有帮助。

## 关于驱动的问题

使用`Selenium`时，需要用到浏览器驱动。常用的浏览器驱动有 chromedriver 和 geckodriver，分别对应chrome浏览器和firefox浏览器。`Phantomjs`不再建议使用，它已经停止开发，可见这里 [issue](phantomjs)。新版本的`Selenium `也计划不再对它进行支撑，已标记为过时。`Phantomjs` 被广泛应用，无非是它的无头模式（静默不会显式的启动浏览器窗口），随着各大浏览器的无头模式的发布，它已经变得不再那么必要。

在选用浏览器和驱动的时候，针对Linux环境，强烈建议 chrome 和chromefriver。下边是我测试的日志，相同的启动方式，感受下速度。

```
# chrome 
2020-07-14 18:55:29 - start set driver
2020-07-14 18:55:31 - driver set success
2020-07-14 18:55:31 - start login
2020-07-14 18:55:32 - get url succ at 2020-07-14 18:55:32
2020-07-14 18:55:33 - Login succ at 2020-07-14 18:55:33
2020-07-14 18:55:33 - login success~
2020-07-14 18:55:33 - get date info
2020-07-14 18:55:33 - targetday is: 2020-07-28
2020-07-14 18:55:33 - target calendar is: [[0, 0, 1, 2, 3, 4, 5], [6, 7, 8, 9, 10, 11, 12], [13, 14, 15, 16, 17, 18, 19], [20, 21, 22, 23, 24, 25, 26], [27, 28, 29, 30, 31, 0, 0]]
2020-07-14 18:55:33 - weeknum is 5, targetdayweekday is 2, monthcount is 0
2020-07-14 18:55:36 - <selenium.webdriver.remote.webelement.WebElement (session="8f38492d2a48f310c52eb9df69311ca1", element="274676f7-5929-4e0c-aeb2-11e311abf9bc")>
2020-07-14 18:55:40 - Success to book meetingroom !
2020-07-14 18:55:40 - finish

# firefox 
2020-07-14 18:58:48 - start set driver
2020-07-14 18:59:02 - driver set success
2020-07-14 18:59:02 - start login
2020-07-14 18:59:28 - get url succ at 2020-07-14 18:59:28
2020-07-14 18:59:33 - Login succ at 2020-07-14 18:59:33
2020-07-14 18:59:33 - login success~
2020-07-14 18:59:33 - get date info
2020-07-14 18:59:33 - targetday is: 2020-07-28
2020-07-14 18:59:33 - target calendar is: [[0, 0, 1, 2, 3, 4, 5], [6, 7, 8, 9, 10, 11, 12], [13, 14, 15, 16, 17, 18, 19], [20, 21, 22, 23, 24, 25, 26], [27, 28, 29, 30, 31, 0, 0]]
2020-07-14 18:59:33 - weeknum is 5, targetdayweekday is 2, monthcount is 0
2020-07-14 18:59:37 - Message: Unable to locate element: [id="o_date"]
> 直接加载不出元素，卡死
```

## 在CentOS 7 上部署selenium相关服务

**chrome浏览器及驱动安装**

浏览器安装：

```
yum install https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
```

yum 安装的时候注意看下，chrome 的版本，安装驱动的时候需要。

```
============================================================================================================================================================================================================================================
 Package                                                     Arch                                       Version                                              Repository                                                                Size
============================================================================================================================================================================================================================================
Installing:
 google-chrome-stable                                        x86_64                                     83.0.4103.116-1                                      /google-chrome-stable_current_x86_64                                     225 M
 ....
```

驱动安装：

直接从如下地址，找到对应浏览器版本的驱动下载解压即可。

https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

**firefox浏览器即驱动安装**

浏览器安装：

```
# 直接yum 安装即可
yum install firefox 
```

驱动安装：

直接从如下地址，找到对应浏览器版本的驱动下载解压即可。

https://github.com/mozilla/geckodriver/releases

下载时，注意版本对应关系:

![](/static/imgs/selenium/selenium_firefox.png)

## 扩展阅读

- [How to run Selenium tests on Firefox using Firefox Driver](https://www.browserstack.com/guide/run-selenium-tests-using-firefox-driver)