# ============================================================
# schemas/book.py — 图书 Pydantic 数据模型
# ============================================================
from pydantic import BaseModel, Field
from typing import Optional
from decimal import Decimal


class BookCreate(BaseModel):
    isbn: str = Field(..., description='ISBN号')
    title: str = Field(..., description='书名')
    author: str = Field(..., description='作者')
    publisher: str = Field(..., description='出版社')
    total_copies: int = Field(..., ge=0, description='馆藏总数')
    available_copies: int = Field(..., ge=0, description='可借数量')
    price: Decimal = Field(..., ge=0, description='价格')
    category: Optional[str] = Field(None, description='分类')
    publish_year: Optional[int] = Field(None, description='出版年份')
    location: Optional[str] = Field(None, description='馆藏位置')


class BookUpdate(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    publisher: Optional[str] = None
    total_copies: Optional[int] = Field(None, ge=0)
    available_copies: Optional[int] = Field(None, ge=0)
    price: Optional[Decimal] = Field(None, ge=0)
    category: Optional[str] = None
    publish_year: Optional[int] = None
    location: Optional[str] = None


class BookOut(BaseModel):
    isbn: str
    title: str
    author: str
    publisher: str
    total_copies: int
    available_copies: int
    price: Decimal
    category: Optional[str]
    publish_year: Optional[int]
    location: Optional[str]
