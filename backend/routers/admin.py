# ============================================================
# routers/admin.py — 系统管理（日志/备份/恢复）
# ============================================================
import os
import subprocess
from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Optional
from auth import require_role
from database import execute_query, execute_update
from config import BACKUP_DIR

router = APIRouter()


# ---- 操作日志查询（分页） ----
@router.get('/logs')
def get_operation_logs(
    operation_type: Optional[str] = Query(None, description='操作类型'),
    table_name: Optional[str] = Query(None, description='表名'),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: dict = Depends(require_role('admin')),
):
    conditions = []
    params = []

    if operation_type:
        conditions.append('operation_type = %s')
        params.append(operation_type)
    if table_name:
        conditions.append('table_name = %s')
        params.append(table_name)

    where = 'WHERE ' + ' AND '.join(conditions) if conditions else ''
    offset = (page - 1) * page_size

    sql = f"""SELECT log_id, user_id, operation_type, table_name,
                     record_id, ip_address, created_at
              FROM operation_logs {where}
              ORDER BY created_at DESC
              LIMIT %s OFFSET %s;"""
    params.extend([page_size, offset])

    rows = execute_query(sql, tuple(params))

    count_sql = f'SELECT COUNT(*) FROM operation_logs {where};'
    total = execute_query(count_sql, tuple(params[:-2]))[0][0]

    return {
        'total': total, 'page': page,
        'data': [
            {
                'log_id': r[0], 'user_id': r[1],
                'operation_type': r[2], 'table_name': r[3],
                'record_id': r[4], 'ip_address': r[5],
                'created_at': str(r[6]),
            }
            for r in rows
        ]
    }


# ---- 数据库备份记录 ----
@router.get('/backup-records')
def get_backup_records(user: dict = Depends(require_role('admin'))):
    sql = """SELECT backup_id, backup_type, file_path, file_size,
                    backup_date, status, created_by
             FROM backup_records ORDER BY backup_date DESC LIMIT 20;"""
    rows = execute_query(sql)
    return {
        'data': [
            {
                'backup_id': r[0], 'backup_type': r[1],
                'file_path': r[2], 'file_size': r[3],
                'backup_date': str(r[4]), 'status': r[5],
            }
            for r in rows
        ]
    }


# ---- 手动全量备份 ----
@router.post('/backup/full')
def full_backup(user: dict = Depends(require_role('admin'))):
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'full_backup_{timestamp}.dump'
    filepath = os.path.join(BACKUP_DIR, filename)

    os.makedirs(BACKUP_DIR, exist_ok=True)

    # 使用 gs_dump 执行全量备份
    cmd = [
        'gs_dump',
        '-h', '127.0.0.1',
        '-p', '5432',
        '-U', 'gaussdb',
        '-d', 'library_db',
        '-F', 'c',
        '-f', filepath,
    ]
    env = os.environ.copy()
    env['PGPASSWORD'] = 'Gauss123!'

    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            file_size = os.path.getsize(filepath)
            execute_update(
                """INSERT INTO backup_records
                   (backup_type, file_path, file_size, status, created_by)
                   VALUES ('full', %s, %s, 'success', %s);""",
                (filepath, file_size, user['user_id'])
            )
            return {
                'message': '全量备份成功',
                'file': filename,
                'size': file_size,
            }
        else:
            execute_update(
                """INSERT INTO backup_records
                   (backup_type, file_path, status, created_by)
                   VALUES ('full', %s, 'failed', %s);""",
                (filepath, user['user_id'])
            )
            raise HTTPException(status_code=500, detail=f'备份失败: {result.stderr}')
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail='gs_dump 未找到，请确认 OpenGauss 客户端工具已安装')


# ---- 手动差异备份 ----
@router.post('/backup/diff')
def diff_backup(user: dict = Depends(require_role('admin'))):
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'diff_backup_{timestamp}.sql'
    filepath = os.path.join(BACKUP_DIR, filename)

    os.makedirs(BACKUP_DIR, exist_ok=True)

    # 使用 gs_dump 导出自上次全量以来的变更（--data-only + --inserts）
    cmd = [
        'gs_dump',
        '-h', '127.0.0.1',
        '-p', '5432',
        '-U', 'gaussdb',
        '-d', 'library_db',
        '--data-only',
        '--inserts',
        '-f', filepath,
    ]
    env = os.environ.copy()
    env['PGPASSWORD'] = 'Gauss123!'

    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            file_size = os.path.getsize(filepath)
            execute_update(
                """INSERT INTO backup_records
                   (backup_type, file_path, file_size, status, created_by)
                   VALUES ('differential', %s, %s, 'success', %s);""",
                (filepath, file_size, user['user_id'])
            )
            return {
                'message': '差异备份成功',
                'file': filename,
                'size': file_size,
            }
        else:
            raise HTTPException(status_code=500, detail=f'备份失败: {result.stderr}')
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail='gs_dump 未找到')
