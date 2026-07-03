# ============================================================
# start_all.ps1 — 一键启动前后端
# ============================================================

$DBCD_DIR = "E:\大三下课程\数据库\DBCD"

Write-Host "╔══════════════════════════════════════════════════════════╗"
Write-Host "║           高校图书借阅管理系统 - 一键启动                 ║"
Write-Host "╚══════════════════════════════════════════════════════════╝"
Write-Host ""

# 启动后端（新窗口）
Write-Host "📡 启动后端服务..."
Start-Process powershell -ArgumentList "-Command", "cd $DBCD_DIR; .\start_backend.ps1"
Write-Host "   后端地址: http://127.0.0.1:8000"
Write-Host "   API文档: http://127.0.0.1:8000/docs"

Start-Sleep -Seconds 3

# 启动前端（新窗口）
Write-Host ""
Write-Host "🌐 启动前端服务..."
Start-Process powershell -ArgumentList "-Command", "cd $DBCD_DIR; .\start_frontend.ps1"
Write-Host "   前端地址: http://localhost:8080"

Write-Host ""
Write-Host "✅ 系统启动完成！"
Write-Host "请在浏览器中打开: http://localhost:8080"