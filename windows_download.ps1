# Windows PowerShell脚本，用于下载并执行fix_ipv6_vless.sh

# 显示标题
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IPv6 VLESS+TCP+Reality 脚本下载器 (Windows版)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 下载脚本
Write-Host "正在从GitHub下载脚本..." -ForegroundColor Yellow
$scriptUrl = "https://raw.githubusercontent.com/1234sosuke/IPv6-VLESS-TCP-Reality/main/fix_ipv6_vless.sh"

try {
    # 使用Invoke-WebRequest下载脚本
    Invoke-WebRequest -Uri $scriptUrl -OutFile "$env:TEMP\fix_ipv6_vless.sh" -UseBasicParsing
    Write-Host "脚本下载成功！" -ForegroundColor Green
    
    # 显示下载的脚本内容
    Write-Host ""
    Write-Host "脚本内容预览:" -ForegroundColor Cyan
    Get-Content "$env:TEMP\fix_ipv6_vless.sh" -TotalCount 10 | ForEach-Object { Write-Host $_ }
    Write-Host "...（内容已省略）..." -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "脚本已下载到: $env:TEMP\fix_ipv6_vless.sh" -ForegroundColor Green
    Write-Host "请将此文件上传到您的Linux服务器，并使用以下命令运行:" -ForegroundColor Yellow
    Write-Host "bash fix_ipv6_vless.sh" -ForegroundColor White -BackgroundColor DarkGray
    Write-Host "========================================" -ForegroundColor Cyan
} catch {
    Write-Host "下载脚本时出错: $_" -ForegroundColor Red
    Write-Host "请检查您的网络连接或GitHub仓库是否可访问。" -ForegroundColor Red
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")