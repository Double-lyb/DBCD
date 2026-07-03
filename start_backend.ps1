# ============================================================
# start_backend.ps1 — 后端启动脚本（自动清理端口）
# ============================================================

$PORT = 8000
$BACKEND_DIR = "E:\大三下课程\数据库\DBCD\backend"

Write-Host "🔍 检查端口 $PORT 是否被占用..."

# 查找占用端口的进程
$processes = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique

if ($processes) {
    Write-Host "⚠️ 发现 $($processes.Count) 个进程占用端口 $PORT，正在终止..."
    foreach ($pid in $processes) {
        try {
            Stop-Process -Id $pid -Force -ErrorAction Stop
            Write-Host "   ✅ 已终止进程 PID: $pid"
        }
        catch {
            Write-Host "   ❌ 终止进程 $pid 失败: $_"
        }
    }
    Start-Sleep -Seconds 1
}
else {
    Write-Host "✅ 端口 $PORT 未被占用"
}

# 清除 Python 缓存
Write-Host "🧹 清除 Python 缓存..."
Remove-Item -Recurse -Force "$BACKEND_DIR\__pycache__" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$BACKEND_DIR\routers\__pycache__" -ErrorAction SilentlyContinue
Write-Host "✅ 缓存已清除"

# 启动后端
Write-Host ""
Write-Host "🚀 启动后端服务..."
Write-Host "地址: http://127.0.0.1:$PORT"
Write-Host "API文档: http://127.0.0.1:$PORT/docs"
Write-Host ""

cd $BACKEND_DIR
python -m uvicorn main:app --host 127.0.0.1 --port $PORT --reload