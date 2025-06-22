# Cursor ID 修改工具 - 快速安装脚本
# 使用方法: irm https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO_NAME/main/install.ps1 | iex

Write-Host "正在下载 Cursor ID 修改工具..." -ForegroundColor Green

try {
    # 下载主脚本
    $scriptUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO_NAME/main/reset.ps1"
    $scriptContent = Invoke-RestMethod -Uri $scriptUrl
    
    # 保存到临时文件
    $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
    $scriptContent | Out-File -FilePath $tempFile -Encoding UTF8
    
    Write-Host "下载完成，正在运行..." -ForegroundColor Green
    
    # 运行脚本
    & $tempFile
    
    # 清理临时文件
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "下载或运行失败: $_" -ForegroundColor Red
    Write-Host "请检查网络连接或手动下载脚本" -ForegroundColor Yellow
}
