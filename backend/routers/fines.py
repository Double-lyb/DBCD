# ============================================================
# routers/fines.py — 罚金规则管理 + 罚金查询
# ============================================================
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Optional
from decimal import Decimal
from auth import require_role, get_current_user
from database import execute_query, execute_update

router = APIRouter()


# ---- 当前罚金规则 ----
@router.get('/rules')
def get_fine_rules(user: dict = Depends(get_current_user)):
    sql = """SELECT rule_id, fine_per_day, effective_from, effective_to
             FROM fine_rules ORDER BY effective_from DESC;"""
    rows = execute_query(sql)
    rules = []
    for r in rows:
        rules.append({
            'rule_id': r[0],
            'fine_per_day': str(r[1]),
            'effective_from': str(r[2]),
            'effective_to': str(r[3]) if r[3] else '当前有效',
        })
    return {'data': rules}


# ---- 调整罚金规则（admin） ----
@router.put('/rules')
def update_fine_rules(
    fine_per_day: float = Query(..., gt=0, description='每日罚金'),
    user: dict = Depends(require_role('admin')),
):
    # 旧的当前规则置为过期
    execute_update(
        "UPDATE fine_rules SET effective_to = CURRENT_DATE WHERE effective_to IS NULL;"
    )
    # 创建新规则
    execute_update(
        "INSERT INTO fine_rules (fine_per_day, effective_from) VALUES (%s, CURRENT_DATE);",
        (Decimal(str(fine_per_day)),)
    )
    return {'message': f'罚金规则已更新为 {fine_per_day} 元/天'}


# ---- 读者罚金明细 ----
@router.get('/reader/{reader_id}')
def get_reader_fines(
    reader_id: str,
    user: dict = Depends(get_current_user),
):
    if user['role'] == 'reader' and user.get('reader_id') != reader_id:
        raise HTTPException(status_code=403, detail='只能查看自己的罚金记录')

    sql = """SELECT br.borrow_id, b.title, br.due_date, br.return_date,
                    br.fine_amount
             FROM borrow_records br
             JOIN books b ON br.isbn = b.isbn
             WHERE br.reader_id = %s AND br.fine_amount > 0
             ORDER BY br.return_date DESC;"""
    rows = execute_query(sql, (reader_id,))
    fines = []
    for r in rows:
        fines.append({
            'borrow_id': r[0], 'title': r[1], 'due_date': str(r[2]),
            'return_date': str(r[3]), 'fine_amount': str(r[4]),
        })
    return {'reader_id': reader_id, 'total': len(fines), 'data': fines}
