# ============================================================
# routers/books.py — 图书管理 CRUD（模糊搜索 + 范围查询）
# ============================================================
from fastapi import APIRouter, HTTPException, Depends, Query
from typing import Optional
from auth import require_role, get_current_user
from database import execute_query, execute_update
from schemas.book import BookCreate, BookUpdate

router = APIRouter()


# ---- 图书列表（分页 + 模糊搜索 + 范围查询） ----
@router.get('')
def list_books(
    keyword: Optional[str] = Query(None, description='模糊搜索：书名/作者/ISBN'),
    category: Optional[str] = Query(None, description='分类筛选'),
    price_min: Optional[float] = Query(None, ge=0, description='最低价格'),
    price_max: Optional[float] = Query(None, ge=0, description='最高价格'),
    page: int = Query(1, ge=1, description='页码'),
    page_size: int = Query(10, ge=1, le=100, description='每页条数'),
    user: dict = Depends(get_current_user),
):
    conditions = []
    params = []

    if keyword:
        conditions.append(
            '(b.isbn ILIKE %s OR b.title ILIKE %s OR b.author ILIKE %s)'
        )
        kw = f'%{keyword}%'
        params.extend([kw, kw, kw])

    if category:
        conditions.append('b.category = %s')
        params.append(category)

    if price_min is not None:
        conditions.append('b.price >= %s')
        params.append(price_min)

    if price_max is not None:
        conditions.append('b.price <= %s')
        params.append(price_max)

    where = 'WHERE ' + ' AND '.join(conditions) if conditions else ''
    offset = (page - 1) * page_size

    sql = f"""SELECT isbn, title, author, publisher, total_copies,
                     available_copies, price, category, publish_year, location
              FROM books b {where}
              ORDER BY b.created_at DESC
              LIMIT %s OFFSET %s;"""
    params.extend([page_size, offset])

    rows = execute_query(sql, tuple(params))

    count_sql = f'SELECT COUNT(*) FROM books b {where};'
    total = execute_query(count_sql, tuple(params[:-2]))[0][0]

    books = []
    for r in rows:
        books.append({
            'isbn': r[0], 'title': r[1], 'author': r[2],
            'publisher': r[3], 'total_copies': r[4],
            'available_copies': r[5], 'price': str(r[6]),
            'category': r[7], 'publish_year': r[8], 'location': r[9],
        })

    return {'total': total, 'page': page, 'page_size': page_size, 'data': books}


# ---- 图书详情 ----
@router.get('/{isbn}')
def get_book(isbn: str, user: dict = Depends(get_current_user)):
    sql = """SELECT isbn, title, author, publisher, total_copies,
                    available_copies, price, category, publish_year, location
             FROM books WHERE isbn = %s;"""
    rows = execute_query(sql, (isbn,))
    if not rows:
        raise HTTPException(status_code=404, detail='图书不存在')
    r = rows[0]
    return {
        'isbn': r[0], 'title': r[1], 'author': r[2],
        'publisher': r[3], 'total_copies': r[4],
        'available_copies': r[5], 'price': str(r[6]),
        'category': r[7], 'publish_year': r[8], 'location': r[9],
    }


# ---- 新增图书（admin / librarian） ----
@router.post('', status_code=201)
def create_book(
    book: BookCreate,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    # 检查 ISBN 是否已存在
    existing = execute_query('SELECT isbn FROM books WHERE isbn = %s;', (book.isbn,))
    if existing:
        raise HTTPException(status_code=400, detail='ISBN 已存在')

    sql = """INSERT INTO books (isbn, title, author, publisher, total_copies,
              available_copies, price, category, publish_year, location)
             VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);"""
    execute_update(sql, (
        book.isbn, book.title, book.author, book.publisher,
        book.total_copies, book.available_copies, book.price,
        book.category, book.publish_year, book.location,
    ))
    return {'message': '图书添加成功', 'isbn': book.isbn}


# ---- 修改图书 ----
@router.put('/{isbn}')
def update_book(
    isbn: str,
    book: BookUpdate,
    user: dict = Depends(require_role('admin', 'librarian')),
):
    existing = execute_query('SELECT isbn FROM books WHERE isbn = %s;', (isbn,))
    if not existing:
        raise HTTPException(status_code=404, detail='图书不存在')

    # 动态构建 UPDATE
    fields = {k: v for k, v in book.dict().items() if v is not None}
    if not fields:
        return {'message': '无修改'}

    set_clause = ', '.join(f'{k} = %s' for k in fields.keys())
    values = list(fields.values()) + [isbn]
    sql = f'UPDATE books SET {set_clause} WHERE isbn = %s;'
    execute_update(sql, tuple(values))
    return {'message': '图书修改成功', 'isbn': isbn}


# ---- 删除图书（触发器拦截有未还记录的图书） ----
@router.delete('/{isbn}')
def delete_book(
    isbn: str,
    user: dict = Depends(require_role('admin')),
):
    existing = execute_query('SELECT isbn FROM books WHERE isbn = %s;', (isbn,))
    if not existing:
        raise HTTPException(status_code=404, detail='图书不存在')

    try:
        execute_update('DELETE FROM books WHERE isbn = %s;', (isbn,))
        return {'message': '图书删除成功'}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e).split('\n')[0])
