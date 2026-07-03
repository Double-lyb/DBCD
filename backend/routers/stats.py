# ============================================================
# routers/stats.py — 统计报表（利用视图 + 聚合函数）
# 聚合函数：COUNT / SUM / AVG / MAX / MIN 全用
# ============================================================
from fastapi import APIRouter, Depends
from auth import get_current_user
from database import execute_query

router = APIRouter()


# ---- 当前借阅未还（v_current_borrowings 视图） ----
@router.get('/current-borrowings')
def current_borrowings(user: dict = Depends(get_current_user)):
    sql = """SELECT borrow_id, reader_id, reader_name, reader_type,
                    title, borrow_date, due_date, overdue_days, status
             FROM v_current_borrowings;"""
    rows = execute_query(sql)
    return {
        'total': len(rows),
        'data': [
            {
                'borrow_id': r[0], 'reader_id': r[1],
                'reader_name': r[2], 'reader_type': r[3],
                'title': r[4], 'borrow_date': str(r[5]),
                'due_date': str(r[6]), 'overdue_days': r[7],
                'status': r[8],
            }
            for r in rows
        ]
    }


# ---- 读者借阅统计（COUNT/SUM/MAX/AVG） ----
@router.get('/readers')
def reader_stats(user: dict = Depends(get_current_user)):
    sql = """SELECT reader_id, name, reader_type, department,
                    current_borrow_count, total_borrow_count,
                    total_fine, max_single_fine, avg_fine
             FROM v_reader_borrowing_stats
             WHERE total_borrow_count > 0
             ORDER BY total_borrow_count DESC;"""
    rows = execute_query(sql)
    return {
        'aggregate_functions': 'COUNT, SUM, MAX, AVG',
        'data': [
            {
                'reader_id': r[0], 'name': r[1], 'reader_type': r[2],
                'department': r[3],
                'current_borrow_count': r[4],   # COUNT(CASE WHEN)
                'total_borrow_count': r[5],     # COUNT
                'total_fine': str(r[6]),         # SUM
                'max_single_fine': str(r[7]),    # MAX
                'avg_fine': str(round(r[8], 2)), # AVG
            }
            for r in rows
        ]
    }


# ---- 图书库存与借阅热度（COUNT/MIN） ----
@router.get('/books')
def book_stats(user: dict = Depends(get_current_user)):
    sql = """SELECT isbn, title, author, publisher, total_copies,
                    available_copies, total_borrow_times, unit_price
             FROM v_book_inventory_stats
             ORDER BY total_borrow_times DESC
             LIMIT 20;"""
    rows = execute_query(sql)
    return {
        'aggregate_functions': 'COUNT, MIN',
        'data': [
            {
                'isbn': r[0], 'title': r[1], 'author': r[2],
                'publisher': r[3], 'total_copies': r[4],
                'available_copies': r[5],
                'total_borrow_times': r[6],    # COUNT
                'unit_price': str(r[7]),        # MIN
            }
            for r in rows
        ]
    }


# ---- 月度罚金汇总（COUNT/SUM/AVG/MAX） ----
@router.get('/monthly-fines')
def monthly_fine_summary(user: dict = Depends(get_current_user)):
    sql = """SELECT month, overdue_count, total_fine,
                    avg_fine_per_record, max_fine
             FROM v_monthly_fine_summary
             ORDER BY month DESC
             LIMIT 12;"""
    rows = execute_query(sql)
    return {
        'aggregate_functions': 'COUNT, SUM, AVG, MAX',
        'data': [
            {
                'month': str(r[0]),
                'overdue_count': r[1],          # COUNT
                'total_fine': str(r[2]),         # SUM
                'avg_fine_per_record': str(round(r[3], 2)),  # AVG
                'max_fine': str(r[4]),           # MAX
            }
            for r in rows
        ]
    }
