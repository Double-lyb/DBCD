# ============================================================
# schemas/borrow.py — 借阅 Pydantic 数据模型
# ============================================================
from pydantic import BaseModel, Field
from typing import Optional
from datetime import date
from decimal import Decimal


class BorrowCreate(BaseModel):
    reader_id: str = Field(..., description='读者编号')
    isbn: str = Field(..., description='图书ISBN')


class BorrowReturn(BaseModel):
    return_date: Optional[date] = Field(None, description='归还日期（默认当天）')


class BorrowOut(BaseModel):
    borrow_id: int
    reader_id: str
    isbn: str
    borrow_date: date
    due_date: date
    return_date: Optional[date]
    fine_amount: Decimal
    status: str
