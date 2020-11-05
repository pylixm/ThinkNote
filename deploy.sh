echo '\033[31m >>>>>>> 清理老的html文件 \033[0m'
rm -rf ./public
echo '\033[31m >>>>>>> 清理完成 \033[0m'
echo '\033[31m >>>>>>> 开始生成新的html文件 \033[0m'
hugo 
echo '\033[31m >>>>>>> 生成完成 \033[0m'
echo '\033[31m >>>>>>> 开始提交静态文件 \033[0m'
cp -r ./public/* ./deploy/
cd deploy
git add .
git commit -am $1
git push 
echo '\033[31m >>>>>>> 静态文件提交完成 \033[0m'
echo '\033[31m >>>>>>> 主库文件受控更新  \033[0m'
pwd 
cd ..
git add .
git commit -am $1
git push 
echo '\033[31m >>>>>>> 发布完成！！！ <<<<<<<<  \033[0m'