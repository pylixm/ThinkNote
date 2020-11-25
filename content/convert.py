# -*- coding:utf-8 -*- 
import os
import re 


def run():
    n = 0
    for root, dirs, files in os.walk('./posts'):
        print(root, dirs)
        for filename in files: 
            # convert(filename)
            n +=1 
            print('--->',n, filename)
            convert_to_posts(filename)


def convert_to_posts(filename):
    file = open(os.path.join('./posts',filename))
    out_file = open(os.path.join('./out', filename), 'w')
    for line in file.readlines():
        if line.startswith('type :'):
            line = line.replace('post', 'posts')
        
        out_file.write(line)    
            


            

def convert(filename):
    file = open(filename)
    out_file = open(os.path.join('../../out', filename), 'w')
    url = '/posts/' 
    for line in file.readlines():
        if line.startswith('category'):
            # line = line.replace('category','categories')
            cate = line.split(':')[1]
            print(cate)
            line = 'categories: [%s] \n' % cate.replace('\n', '')


        if line.startswith('date') and ':' in line:
            r = re.compile('\d{4}-\d{2}-\d{2}')
            date_str = re.findall(r, line)
            if not date_str:
                print(line)
                print(date_str)
                print('>>>>>>>',filename)
            url += '%s-%s.html' % (date_str[0], filename.replace('.md', '').replace('.markdown', ''))
            out_file.write(line)
            line = 'url: %s \n' % url 

        out_file.write(line)


if __name__=='__main__':
    run() 