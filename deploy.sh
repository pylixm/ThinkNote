echo '\033[31m >>>>>>> 开始生成html文件 \033[0m'
hexo g 
echo '\033[31m >>>>>>> 开始提交静态文件 \033[0m'
cd public 
git add .
git commit -am 'update'
git push 
echo '\033[31m >>>>>>> 主库文件受控更新  \033[0m'
cd ..
git add .
git commit -am 'update'
git push 
echo '\033[31m >>>>>>> 发布完成！！！ <<<<<<<<  \033[0m'