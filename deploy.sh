echo '>>>>>>> 开始生成html文件'
hexo g 
echo '>>>>>>> 开始提交静态文件'
cd public 
git add .
git commit -am 'update'
git push 
echo '>>>>>>> 主库文件受控更新'
cd ..
git add .
git commit -am 'update'
git push 
echo '>>>>>>> 发布完成！！！ <<<<<<<< '