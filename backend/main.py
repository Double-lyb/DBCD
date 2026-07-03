# ============================================================
# main.py — FastAPI 应用入口
# ============================================================
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, books, readers, borrow, fines, stats, admin, ai

app = FastAPI(
    title='高校图书借阅管理系统 API',
    description='基于 FastAPI + OpenGauss 的图书借阅管理系统',
    version='1.0.0',
)

# ---- CORS 跨域（允许 Vue.js 前端开发服务器访问） ----
app.add_middleware(
    CORSMiddleware,
    allow_origins=['http://localhost:8080', 'http://127.0.0.1:8080'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

# ---- 注册路由 ----
app.include_router(auth.router, prefix='/api/auth', tags=['认证'])
app.include_router(books.router, prefix='/api/books', tags=['图书管理'])
app.include_router(readers.router, prefix='/api/readers', tags=['读者管理'])
app.include_router(borrow.router, prefix='/api/borrow', tags=['借阅管理'])
app.include_router(fines.router, prefix='/api/fines', tags=['罚金管理'])
app.include_router(stats.router, prefix='/api/stats', tags=['统计报表'])
app.include_router(admin.router, prefix='/api/admin', tags=['系统管理'])
app.include_router(ai.router, prefix='/api/ai', tags=['AI 助手'])


@app.get('/')
def root():
    return {'message': '高校图书借阅管理系统 API', 'version': '1.0.0'}


if __name__ == '__main__':
    import uvicorn
    uvicorn.run('main:app', host='127.0.0.1', port=8000, reload=True)
