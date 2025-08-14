@echo off
echo 初始化Git仓库并上传到GitHub
echo ======================================

REM 初始化Git仓库
git init

REM 添加所有文件
git add .

REM 提交更改
git commit -m "初始提交：IPv6 VLESS+TCP+Reality一键安装脚本"

REM 重命名分支为main
git branch -M main

echo ======================================
echo 请输入您的GitHub仓库URL（例如：https://github.com/username/repo.git）
set /p REPO_URL="GitHub仓库URL: "

REM 添加远程仓库
git remote add origin %REPO_URL%

REM 推送到GitHub
git push -u origin main

echo ======================================
echo 上传完成！
echo 您的脚本现在可以通过以下命令在Ubuntu系统上运行：
echo curl -fsSL https://raw.githubusercontent.com/用户名/仓库名/main/fix_ipv6_vless.sh | bash
echo ======================================

pause