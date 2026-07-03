# ============================================================
# start_frontend.ps1 — 前端启动脚本
# ============================================================

$FRONTEND_DIR = "E:\大三下课程\数据库\DBCD\frontend"

Write-Host "🚀 启动前端服务..."
Write-Host "地址: http://localhost:8080"
Write-Host ""

cd $FRONTEND_DIR
npm run dev