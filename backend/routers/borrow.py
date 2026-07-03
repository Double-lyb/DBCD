# ============================================================
# routers/borrow.py — 借阅申请/审批 + 归还 核心业务
#
# 流程：
#   读者申请借书 → POST /apply（状态=pending，24h有效）
#   管理员审批     → PUT /applications/{id}/approve（触发器建 borrow_record）
#   管理员驳回     → PUT /applications/{id}/reject
#   管理员还书     → PUT /{borrow_id}/return（触发器计算罚金+恢复库存）
# ============================================================
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import Optional
from auth import require_role, get_current_user
from database import execute_query, execute_update, execute_procedure

router = APIRouter()


# ---- Pydantic 模型 ----
class ApplyRequest(BaseModel):
    isbn: str


class RejectRequest(BaseModel):
    reason: Optional[str] = None


# ================================================================
#  读者端：申请借书
# ================================================================
@router.post('/apply', status_code=201)
def apply_borrow(
    data: ApplyRequest,
    user: dict = Depends(get_current_user),
):
    """读者申请借阅一本图书，生成申请记录（24h 有效）"""
    if user['role'] != 'reader':
        raise HTTPException(status_code=400, detail='仅读者可提交借阅申请')
    if not user.get('reader_id'):
        raise HTTPException(status_code=400, detail='当前用户未绑定读者账号')

    reader_id = user['reader_id']

    # 检查读者状态
    reader = execute_query(
        "SELECT reader_id, status FROM readers WHERE reader_id = %s;",
        (reader_id,)
    )
    if not reader or reader[0][1] != 'active':
        raise HTTPException(status_code=400, detail='读者账号异常')

    # 检查图书
    book = execute_query(
        "SELECT isbn, available_copies FROM books WHERE isbn = %s;",
        (data.isbn,)
    )
    if not book:
        raise HTTPException(status_code=404, detail='图书不存在')
    if book[0][1] <= 0:
        raise HTTPException(status_code=400, detail='该图书暂无库存，无法申请')

    # 检查是否已有相同图书的待处理申请
    dup = execute_query(
        """SELECT application_id FROM borrow_applications
           WHERE reader_id = %s AND isbn = %s AND status = 'pending'
             AND expires_at > CURRENT_TIMESTAMP;""",
        (reader_id, data.isbn)
    )
    if dup:
        raise HTTPException(status_code=400, detail='你已申请过该图书，请等待管理员审批')

    # 先清理过期申请（会自动恢复过期申请的库存）
    execute_update("SELECT fn_expire_applications();")

    # 扣减库存（申请即预留）
    execute_update(
        "UPDATE books SET available_copies = available_copies - 1 WHERE isbn = %s AND available_copies > 0;",
        (data.isbn,)
    )

    # 创建申请
    execute_update(
        """INSERT INTO borrow_applications (reader_id, isbn)
           VALUES (%s, %s);""",
        (reader_id, data.isbn)
    )

    return {'message': '借阅申请已提交，有效期6小时，请等待管理员审批'}


# ================================================================
#  读者端：查看自己的申请记录
# ================================================================
@router.get('/applications/my')
def my_applications(
    user: dict = Depends(get_current_user),
):
    """读者查看自己的借阅申请列表"""
    if not user.get('reader_id'):
        return {'data': []}

    # 先清理过期
    execute_update("SELECT fn_expire_applications();")

    sql = """SELECT a.application_id, a.isbn, b.title, b.author,
                    a.status, a.applied_at, a.expires_at,
                    a.processed_at, a.reject_reason
             FROM borrow_applications a
             JOIN books b ON a.isbn = b.isbn
             WHERE a.reader_id = %s
             ORDER BY a.applied_at DESC
             LIMIT 50;"""
    rows = execute_query(sql, (user['reader_id'],))

    apps = []
    for r in rows:
        apps.append({
            'application_id': r[0], 'isbn': r[1], 'title': r[2],
            'author': r[3], 'status': r[4],
            'applied_at': str(r[5]), 'expires_at': str(r[6]),
            'processed_at': str(r[7]) if r[7] else None,
            'reject_reason': r[8],
        })

    return {'data': apps}


# ================================================================
#  管理员端：查看某读者的待审批申请
# ================================================================
@router.get('/applications/{reader_id}')
def get_reader_applications(
    reader_id: str,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    """管理员查看读者的待审批借阅申请"""
    execute_update("SELECT fn_expire_applications();")

    sql = """SELECT a.application_id, a.reader_id, a.isbn, b.title,
                    b.author, b.publisher, a.status, a.applied_at, a.expires_at
             FROM borrow_applications a
             JOIN books b ON a.isbn = b.isbn
             WHERE a.reader_id = %s AND a.status = 'pending'
             ORDER BY a.applied_at ASC;"""
    rows = execute_query(sql, (reader_id,))

    apps = []
    for r in rows:
        apps.append({
            'application_id': r[0], 'reader_id': r[1], 'isbn': r[2],
            'title': r[3], 'author': r[4], 'publisher': r[5],
            'status': r[6], 'applied_at': str(r[7]), 'expires_at': str(r[8]),
        })

    return {'reader_id': reader_id, 'data': apps}


# ================================================================
#  管理员端：审批通过（触发器自动创建 borrow_record）
# ================================================================
@router.put('/applications/{application_id}/approve')
def approve_application(
    application_id: int,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    """管理员审批通过借阅申请"""
    app = execute_query(
        """SELECT application_id, reader_id, isbn, status, expires_at
           FROM borrow_applications WHERE application_id = %s;""",
        (application_id,)
    )
    if not app:
        raise HTTPException(status_code=404, detail='申请记录不存在')
    if app[0][3] != 'pending':
        raise HTTPException(status_code=400, detail=f'申请状态为 {app[0][3]}，无法审批')

    # 检查库存
    book = execute_query(
        "SELECT available_copies FROM books WHERE isbn = %s;",
        (app[0][2],)
    )
    if book and book[0][0] <= 0:
        raise HTTPException(status_code=400, detail='该图书已无库存，无法借阅')

    try:
        # UPDATE 触发 trg_approve_application → INSERT borrow_records
        execute_update(
            """UPDATE borrow_applications
               SET status = 'approved', processed_by = %s
               WHERE application_id = %s;""",
            (user['user_id'], application_id)
        )
        return {'message': '审批通过，借阅成功', 'application_id': application_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e).split('\n')[0])


# ================================================================
#  管理员端：驳回申请
# ================================================================
@router.put('/applications/{application_id}/reject')
def reject_application(
    application_id: int,
    data: RejectRequest = RejectRequest(),
    user: dict = Depends(require_role('admin', 'librarian')),
):
    """管理员驳回借阅申请"""
    app = execute_query(
        "SELECT application_id, status FROM borrow_applications WHERE application_id = %s;",
        (application_id,)
    )
    if not app:
        raise HTTPException(status_code=404, detail='申请记录不存在')
    if app[0][1] != 'pending':
        raise HTTPException(status_code=400, detail=f'申请状态为 {app[0][1]}，无法驳回')

    # 恢复预留库存（安全上限：不超过 total_copies）
    isbn_result = execute_query(
        "SELECT isbn FROM borrow_applications WHERE application_id = %s;",
        (application_id,)
    )
    if isbn_result:
        execute_update(
            "UPDATE books SET available_copies = available_copies + 1 WHERE isbn = %s AND available_copies < total_copies;",
            (isbn_result[0][0],)
        )

    execute_update(
        """UPDATE borrow_applications
           SET status = 'rejected', processed_by = %s,
               processed_at = CURRENT_TIMESTAMP, reject_reason = %s
           WHERE application_id = %s;""",
        (user['user_id'], data.reason or '管理员驳回', application_id)
    )
    return {'message': '已驳回申请', 'application_id': application_id}


# ================================================================
#  读者端：撤销自己的申请
# ================================================================
@router.delete('/applications/{application_id}')
def cancel_application(
    application_id: int,
    user: dict = Depends(get_current_user),
):
    """读者撤销自己的待审批借阅申请"""
    app = execute_query(
        """SELECT application_id, reader_id, isbn, status
           FROM borrow_applications WHERE application_id = %s;""",
        (application_id,)
    )
    if not app:
        raise HTTPException(status_code=404, detail='申请记录不存在')
    if app[0][1] != user.get('reader_id'):
        raise HTTPException(status_code=403, detail='只能撤销自己的申请')
    if app[0][3] != 'pending':
        raise HTTPException(status_code=400, detail='只能撤销待审批的申请')

    # 恢复预留库存
    execute_update(
        "UPDATE books SET available_copies = available_copies + 1 WHERE isbn = %s AND available_copies < total_copies;",
        (app[0][2],)
    )
    # 删除申请记录
    execute_update(
        "DELETE FROM borrow_applications WHERE application_id = %s;",
        (application_id,)
    )
    return {'message': '申请已撤销', 'application_id': application_id}


# ================================================================
#  管理员端：查看读者当前在借图书（用于还书页面）
# ================================================================
@router.get('/reader/{reader_id}/borrows')
def get_reader_borrows(
    reader_id: str,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    """管理员查看读者的当前在借图书列表（含超期状态）"""
    try:
        rows = execute_procedure(
            'SELECT * FROM sp_get_reader_borrowings(%s);',
            (reader_id,)
        )
        borrowings = []
        for r in rows:
            borrowings.append({
                'borrow_id': r[0],
                'isbn': r[1], 'title': r[2], 'author': r[3],
                'publisher': r[4], 'borrow_date': str(r[5]),
                'due_date': str(r[6]), 'overdue_days': r[7],
                'estimated_fine': str(r[8]), 'status': r[9],
            })
        return {'reader_id': reader_id, 'data': borrowings}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ================================================================
#  还书（仅管理员/图书管理员操作）
# ================================================================
@router.put('/{borrow_id}/return')
def return_book(
    borrow_id: int,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    """管理员归还图书"""
    record = execute_query(
        """SELECT borrow_id, reader_id, return_date FROM borrow_records
           WHERE borrow_id = %s;""",
        (borrow_id,)
    )
    if not record:
        raise HTTPException(status_code=404, detail='借阅记录不存在')
    if record[0][2] is not None:
        raise HTTPException(status_code=400, detail='该记录已归还')

    try:
        sql = """UPDATE borrow_records SET return_date = CURRENT_DATE
                 WHERE borrow_id = %s;"""
        execute_update(sql, (borrow_id,))

        result = execute_query(
            """SELECT fine_amount, status FROM borrow_records
               WHERE borrow_id = %s;""",
            (borrow_id,)
        )
        fine = str(result[0][0]) if result else '0'
        return {
            'message': '还书成功',
            'borrow_id': borrow_id,
            'fine_amount': fine,
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e).split('\n')[0])


# ================================================================
#  查询读者当前借阅
# ================================================================
@router.get('/current/{reader_id}')
def get_current_borrowings(
    reader_id: str,
    user: dict = Depends(get_current_user),
):
    if user['role'] == 'reader' and user.get('reader_id') != reader_id:
        raise HTTPException(status_code=403, detail='只能查看自己的借阅记录')

    try:
        rows = execute_procedure(
            'SELECT * FROM sp_get_reader_borrowings(%s);',
            (reader_id,)
        )
        borrowings = []
        for r in rows:
            borrowings.append({
                'borrow_id': r[0],
                'isbn': r[1], 'title': r[2], 'author': r[3],
                'publisher': r[4], 'borrow_date': str(r[5]),
                'due_date': str(r[6]), 'overdue_days': r[7],
                'estimated_fine': str(r[8]), 'status': r[9],
            })
        return {'reader_id': reader_id, 'data': borrowings}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ================================================================
#  超期未还清单
# ================================================================
@router.get('/overdue')
def get_overdue_books(
    user: dict = Depends(get_current_user),
):
    if user['role'] == 'reader':
        sql = """SELECT borrow_id, reader_id, reader_name, reader_type,
                        department, isbn, title, author, borrow_date,
                        due_date, overdue_days, fine_amount
                 FROM v_overdue_books WHERE reader_id = %s;"""
        rows = execute_query(sql, (user.get('reader_id'),))
    else:
        sql = """SELECT borrow_id, reader_id, reader_name, reader_type,
                        department, isbn, title, author, borrow_date,
                        due_date, overdue_days, fine_amount
                 FROM v_overdue_books;"""
        rows = execute_query(sql)
    result = []
    for r in rows:
        result.append({
            'borrow_id': r[0], 'reader_id': r[1], 'reader_name': r[2],
            'reader_type': r[3], 'department': r[4], 'isbn': r[5],
            'title': r[6], 'author': r[7], 'borrow_date': str(r[8]),
            'due_date': str(r[9]), 'overdue_days': r[10],
            'fine_amount': str(r[11]),
        })
    return {'total': len(result), 'data': result}
