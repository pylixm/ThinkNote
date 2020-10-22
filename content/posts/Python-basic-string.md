---
type : post
title : 【 python 基础系列 】 - 30+种Python string处理的常用语法 
categories: [Python,] 
date : 2020-10-21
url: /posts/2020-10-21-python-string.html 
tags : [Python]
---


今天看了篇文章总结了Python String类型使用的40种常用处理语法，觉着很有趣，分享给大家。尽管有些语法你可能用不到，但也算是掌握一种奇思巧技。

## 1/ 创建字符串 

```python
s1 = 'This is a test.'
```

## 2/ 使用print语句查看输出

```python
# python3/python2
>>> print('this is a test.')
this is a test.
# python3/python2
>>> print ('test')
test
# python2
>>> print '123' 
123
```

## 3/ 单行查看输出

```
>>> s1 = 'this is'
>>> s2 = ' a test'
>>> print(s1+s2)
this is a test
```

## 4/ 单行 \n 查看输出

```python
>>> print(s1+'\n'+s2)
this is
 a test
```

## 5/ 字符串下标表示法

```python
>>> print(s1[0])
t
>>> print(s1[1])
h
>>> print(s1[8])
Traceback (most recent call last):
  File "<input>", line 1, in <module>
IndexError: string index out of range
```

## 6/ 下标字符串相加

```python
>>> print(s1[1]+s1[3]+s1[4])
hs 
```

## 7/ 切片字符串

```python
>>> print(s1[0:5])
this 
>>> print(s1[0:])
this is
>>> print(s1[:])
this is
>>> print(s1[:-1])
this i
>>> print(s1[::2])
ti s
```

## 8/ 负索引切片

```python
>>> print(s1[-5:-1])
is i
>>> print(s1[-1::-1])  # 反转字符串
si siht
```


## 9/ %格式化操作符

```python
>>> print('this is a %s' % 'test')
this is a test
>>> print('this is a %(test)s' % {'test':'12345'})
this is a 12345
```

## 10/ 带整数的%

```python
>>> print('1+1 = %(num)01d' % {'num': 2})
1+1 = 2
>>> print('1+1 = %(num)02d' % {'num': 2})
1+1 = 02
>>> print('1+1 = %(num)03d' % {'num': 2})
1+1 = 002
```

## 11/ %用于站位 

```python
>>> print( '%(a)s %(n)03d - program is the best.' % {'a':'Python','n':3})
Python 003 - program is the best.
```

## 12/ 利用 `\n` 分拆字符串

```python
>>> print(' %(a)s %(n)03d - program is the best \n %(a)s helped me understand programming.' % {"a":"Python","n":3})
Python 003 - program is the best 
Python helped me understand programming.
```

## 13/ 多个`\n` 

```python
>>> print(' I love %(a)s. \n I like %(b)s. \n I like to %(c)s. \n my %(d)s is %(num)03d.'%{"a":"to code","b":"ice-cream","c":"travel","d":"age","num":32})
I love to code. 
I like ice-cream. 
I like to travel. 
my age is 032.
```

## 14/ 其他方式使用%

```python
>>> print('Hello everyone I am using Python %d.7 version.' % 3.7)
Hello everyone I am using Python 3.7 version.

>>> print('%s %s %d %d %f %f' % ('Hercules', 'Zeus', 100, 20, 3.2, 1))
Hercules Zeus 100 20 3.200000 1.000000

>>> print('This is a +%d integer' % 10)
This is a +10 integer

>>> print('This is a negative -%d integer' % 250)
This is a negative -250 integer

>>> print('This is a confused -%d integer' % 300)
This is a confused -300 integer
```

## 15/ 字串符转为整数

```python
>>> s3 = '123'
>>> print(10*int(s3))  # 乘法
1230
>>> print(10*s3)  # 倍数
123123123123123123123123123123
>>> print('1'+'45')
145

>>> print('1'+45)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: can only concatenate str (not "int") to str


>>> print(float('1')+float('45'))
46.0
```

## 16/ 获取单个字符在字符串中出现的次数

```python
>>> text = 'this is a test.'
>>> print(text.count('t'))
3
>>> print(text.count('is'))
2
```

## 17/ 将字符串变为大写

```python
>>> text = 'this is a test.'
>>> print(text.upper())
THIS IS A TEST.

```

## 18/ 将字符串变为小写

```python
>>> text = 'THIS IS A TEST.'
>>> print(text.upper())
this is a test.
```

## 19/ 组合字符串

```python
>>> ' '.join(text)
't h i s   i s   a   t e s t .'

>>> ','.join(['hello', 'Dean'])
'hello,Dean'

```

## 20/ 分拆字符串

```python
>>> text = 'this is a test.'
>>> print(text.split(' '))
['this', 'is', 'a', 'test.']

```

## 21/ 判断字符串是否是大写

```python
>>> text
'this is a test.'
>>> up_text = text.upper()
>>> print(up_text.isupper())
True
```

## 22/ 判断字符串是否是小写 

```python
>>> low_text = text.lower()
>>> print(low_text.islower())
True

```

## 23/ 判断字符串是否有字母数字构成 

```python
>>> text1 = 'Lession 01'
>>> print(text1.isalnum())
False
>>> text2 = 'Lession01'
>>> print(text2.isalnum())
True
```

## 24/ 获取字符串的长度

```python
>>> text
'this is a test.'
>>> print(len(text))
15

```

## 25/ 将字符串转化为10进制的asscii码

```python
>>> print(ord('A'))
65
>>> print(ord('B'))
66
>>> print(ord('a'))
97
>>> print(ord('b'))
98
```

## 26/ 将10进制的asscii码转化为字符串

```python
>>> print(chr(65))
A
>>> print(chr(42))
*
>>> print(chr(118))
v
>>> print(chr(60))
<
```

## 27/ 避免自动转义字符 

```python
>>> print('What\'s up?')
What's up?

>>> # the apostrophe is not needed in this case.
>>> print("What's up?")
What's up?

>>> # the apostrophe is needed to add on the quotes to the text
>>> print("\"What's up?\"")
"What's up?"

>>> # triple quotes can escape single, double, and a lot more.
>>> print("""What's up? Does the "" need an escape?""")
What's up? Does the "" need an escape?
```

## 28/ 使用逗号格式化字符串

```python
>>> print('这里有', 10, '个苹果')
这里有 10 个苹果

```

## 29/ format 格式化字符串

```python
>>> text
'this is a test.'
>>> print('This is a {}'.format(text))
This is a this is a test.
>>> print('Number {1} and number {0}'.format(100, 200))  # keyword position
Number 200 and number 100
```

## 30/ format中通过名字传递字符

```python
>>> print('这里有{num}个{type}。'.format(num=10, type='苹果'))
这里有10个苹果。
>>> tmp = {'num': 10, 'type': '苹果'}
>>> print('这里有{num}个{type}。'.format(**tmp))
这里有10个苹果。

```

## 31/ format中通过参数顺序传递字符

```python
>>> print('这里有{1}个{0}。'.format('苹果',10))
这里有10个苹果。
```


## 32/ format中访问属性

```python
>>> class Rectangle:
 def __init__(self, length, width):
  self.length = length
  self.width = width
 def __str__(self):
  return 'Rectangle({self.length}, {self.width})'.format(self=self)

 
>>> rect = Rectangle(10, 5.5)
>>> print(rect.__str__())
Rectangle(10, 5.5)
```

## 33/ 对齐文本 

```python
>>> print('{:<10}'.format('X')) # left align
X         
>>> print('{:>10}'.format('X')) # right align
         X
>>> print('{:^10}'.format('X')) # center
    X     
>>> print('{:?^10}'.format('X')) # add a fill character
????X?????
```

## 34/ 格式化二进制、八进制和十六进制

```python
>>> print('Binary number: {0:b}'.format(50))
Binary number: 110010

>>> print('Octal number: {0:o}'.format(100))
Octal number: 144

>>> print('Hexadecimal number: {0:x}'.format(2555))
Hexadecimal number: 9fb
```

## 35/ 使用逗号作为分隔符

```python
>>> print('{:,}'.format(2783727282727)) 
2,783,727,282,727

>>> print('{:.2%}'.format(90.60/100))   
90.60%
```

## 36/ 使用`f`来格式刷字符串

```python
>>> item_1, item_2, item_3 = 'computer', 'mouse', 'browser'

>>> print(f"He uses a {item_1}.")
He uses a computer.

>>> print(f"He uses a {item_2} and a {item_3}.")
He uses a mouse and a browser.

>>> print(f"He uses a {item_1} 3 times a day.")
He uses a computer 3 times a day.
```

## 37/ 使用模板格式化字符串

```python
# docs: https://docs.python.org/3/library/string.html#template-strings
>>> from string import Template
>>> poem = Template('$x are red and $y are blue')

>>> print(poem.substitute(x='roses', y='violets'))
roses are red and violets are blue
```

## 38/ 字符串的遍历

```python
>>> text
'this is a test.'
>>> for item in text:
...     print(item)
... 
t
h
i
s
 
i
s
 
a
 
t
e
s
t
.

```

## 39/ 使用while 循环

```python
>>> i = 0
>>> while i < len(text):
        print(text[i])
```

## 40/ 使用三引号保存字符串

```python
>>> def triple_quote_docs():
 """
 In the golden lightning
 Of the sunken sun,
 O'er which clouds are bright'ning,
 Thou dost float and run,
 Like an unbodied joy whose race is just begun.
 """
 return

>>> print(triple_quote_docs.__doc__)

 In the golden lightning
 Of the sunken sun,
 O'er which clouds are bright'ning,
 Thou dost float and run,
 Like an unbodied joy whose race is just begun.
 
>>>
```
