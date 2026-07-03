# ============================================================
# routers/readers.py — 读者管理（含敏感数据加密存储）
# ============================================================
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Optional
from auth import require_role, get_current_user
from database import execute_query, execute_update
from schemas.reader import ReaderCreate, ReaderUpdate
from utils.encryption import encrypt_field, decrypt_field, encrypt_reader_sensitive

router = APIRouter()


# ---- 读者列表（分页 + 搜索） ----
@router.get('')
def list_readers(
    keyword: Optional[str] = Query(None, description='搜索：姓名/学工号'),
    reader_type: Optional[int] = Query(None, description='读者类型：1=学生, 2=教师'),
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    user: dict = Depends(require_role('admin', 'librarian')),
):
    conditions = []
    params = []

    if keyword:
        conditions.append('(r.reader_id ILIKE %s OR r.name ILIKE %s)')
        kw = f'%{keyword}%'
        params.extend([kw, kw])

    if reader_type:
        conditions.append('r.reader_type_id = %s')
        params.append(reader_type)

    where = 'WHERE ' + ' AND '.join(conditions) if conditions else ''
    offset = (page - 1) * page_size

    sql = f"""SELECT r.reader_id, r.name, rt.type_name, r.department,
                     r.status, r.created_at,
                     rt.max_borrow_count,
                     COALESCE((SELECT COUNT(*) FROM borrow_records br
                      WHERE br.reader_id = r.reader_id AND br.status IN ('borrowed','overdue')), 0) AS current_borrow_count
              FROM readers r
              JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
              {where}
              ORDER BY r.created_at DESC
              LIMIT %s OFFSET %s;"""
    params.extend([page_size, offset])

    rows = execute_query(sql, tuple(params))

    count_sql = f'SELECT COUNT(*) FROM readers r {where};'
    total = execute_query(count_sql, tuple(params[:-2]))[0][0]

    readers = []
    for r in rows:
        readers.append({
            'reader_id': r[0], 'name': r[1], 'reader_type': r[2],
            'department': r[3], 'status': r[4], 'created_at': str(r[5]),
            'max_borrow_count': r[6], 'current_borrow_count': r[7],
        })

    return {'total': total, 'page': page, 'page_size': page_size, 'data': readers}


# ---- 读者详情（含解密联系方式 + 借阅统计） ----
@router.get('/{reader_id}')
def get_reader(
    reader_id: str,
    user: dict = Depends(get_current_user),
):
    # 普通读者只能看自己的信息
    if user['role'] == 'reader' and user.get('reader_id') != reader_id:
        raise HTTPException(status_code=403, detail='只能查看自己的信息')

    sql = """SELECT r.reader_id, r.name, rt.type_name, r.department,
                    r.phone, r.email, r.status, r.created_at,
                    rt.max_borrow_count, rt.borrow_days,
                    COALESCE((SELECT COUNT(*) FROM borrow_records br
                     WHERE br.reader_id = r.reader_id AND br.status IN ('borrowed','overdue')), 0) AS current_borrow_count
             FROM readers r
             JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
             WHERE r.reader_id = %s;"""
    rows = execute_query(sql, (reader_id,))
    if not rows:
        raise HTTPException(status_code=404, detail='读者不存在')
    r = rows[0]

    # 解密敏感字段（管理员可见）
    phone = None
    email = None
    if r[4] and user['role'] in ('admin', 'librarian'):
        phone = decrypt_field(bytes(r[4])) if isinstance(r[4], memoryview) else decrypt_field(r[4])
    if r[5] and user['role'] in ('admin', 'librarian'):
        email = decrypt_field(bytes(r[5])) if isinstance(r[5], memoryview) else decrypt_field(r[5])

    return {
        'reader_id': r[0], 'name': r[1], 'reader_type': r[2],
        'department': r[3], 'phone': phone, 'email': email,
        'status': r[6], 'created_at': str(r[7]),
        'max_borrow_count': r[8], 'borrow_days': r[9],
        'current_borrow_count': r[10],
    }


# ---- 创建读者（admin 直接创建，不经过注册流程） ----
@router.post('', status_code=201)
def create_reader(
    reader: ReaderCreate,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    existing = execute_query(
        'SELECT reader_id FROM readers WHERE reader_id = %s;',
        (reader.reader_id,)
    )
    if existing:
        raise HTTPException(status_code=400, detail='读者编号已存在')

    from auth import hash_password
    pwd_hash = hash_password(reader.password)

    execute_update(
        """INSERT INTO readers (reader_id, name, reader_type_id, department, password_hash)
           VALUES (%s, %s, %s, %s, %s);""",
        (reader.reader_id, reader.name, reader.reader_type_id,
         reader.department, pwd_hash)
    )

    # 加密敏感字段
    if reader.phone or reader.email:
        encrypt_reader_sensitive(reader.reader_id, reader.phone, reader.email)

    # 同时创建系统用户
    execute_update(
        """INSERT INTO users (username, password_hash, role, reader_id)
           VALUES (%s, %s, 'reader', %s);""",
        (reader.reader_id, pwd_hash, reader.reader_id)
    )

    return {'message': '读者创建成功', 'reader_id': reader.reader_id}


# ---- 修改读者信息 ----
@router.put('/{reader_id}')
def update_reader(
    reader_id: str,
    reader: ReaderUpdate,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    existing = execute_query(
        'SELECT reader_id FROM readers WHERE reader_id = %s;',
        (reader_id,)
    )
    if not existing:
        raise HTTPException(status_code=404, detail='读者不存在')

    # 处理敏感字段加密
    if reader.phone is not None or reader.email is not None:
        encrypt_reader_sensitive(
            reader_id,
            reader.phone or '',
            reader.email or ''
        )

    # 更新非敏感字段
    fields = {k: v for k, v in reader.dict().items()
              if v is not None and k not in ('phone', 'email')}
    if fields:
        set_clause = ', '.join(f'{k} = %s' for k in fields.keys())
        values = list(fields.values()) + [reader_id]
        sql = f'UPDATE readers SET {set_clause} WHERE reader_id = %s;'
        execute_update(sql, tuple(values))

    return {'message': '读者信息修改成功'}
