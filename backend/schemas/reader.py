# ============================================================
# schemas/reader.py — 读者 Pydantic 数据模型
# ============================================================
from pydantic import BaseModel, Field
from typing import Optional


class ReaderCreate(BaseModel):
    reader_id: str = Field(..., description='学号/工号')
    name: str = Field(..., description='姓名')
    reader_type_id: int = Field(..., description='读者类型: 1=学生, 2=教师')
    department: str = Field(..., description='院系/部门')
    phone: Optional[str] = Field(None, description='联系电话')
    email: Optional[str] = Field(None, description='邮箱')
    password: str = Field(..., description='登录密码')


class ReaderUpdate(BaseModel):
    name: Optional[str] = None
    reader_type_id: Optional[int] = None
    department: Optional[str] = None
    status: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None


class ReaderLogin(BaseModel):
    reader_id: str
    password: str
