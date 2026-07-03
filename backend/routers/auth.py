# ============================================================
# routers/auth.py — 认证路由（登录/验证码/刷新）
# ============================================================
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from auth import (
    hash_password, verify_password, create_access_token,
    get_current_user, require_role
)
from database import execute_query
from utils.captcha import generate_captcha, verify_captcha

router = APIRouter()


class LoginRequest(BaseModel):
    username: str
    password: str
    captcha_token: str
    captcha_code: str


class CaptchaResponse(BaseModel):
    token: str
    image_base64: str


# ---- 获取验证码 ----
@router.get('/captcha')
def get_captcha() -> CaptchaResponse:
    token, img_base64 = generate_captcha()
    return CaptchaResponse(token=token, image_base64=img_base64)


# ---- 登录 ----
@router.post('/login')
def login(req: LoginRequest):
    # 1. 校验验证码
    if not verify_captcha(req.captcha_token, req.captcha_code):
        raise HTTPException(status_code=400, detail='验证码错误')

    # 2. 查系统用户表
    sql = """SELECT user_id, username, password_hash, role, reader_id
             FROM users WHERE username = %s AND status = 'active';"""
    result = execute_query(sql, (req.username,))
    if not result:
        raise HTTPException(status_code=401, detail='用户名或密码错误')

    user = result[0]
    user_id, username, pwd_hash, role, reader_id = user

    # 3. 验证密码（bcrypt）
    if not verify_password(req.password, pwd_hash):
        raise HTTPException(status_code=401, detail='用户名或密码错误')

    # 4. 生成 JWT
    token = create_access_token({
        'sub': username,
        'user_id': user_id,
        'role': role,
        'reader_id': reader_id,
    })

    return {
        'access_token': token,
        'token_type': 'bearer',
        'username': username,
        'role': role,
        'reader_id': reader_id,
    }


# ---- 注册读者（同时创建 readers + users 记录） ----
class RegisterRequest(BaseModel):
    reader_id: str
    name: str
    reader_type_id: int
    department: str
    password: str

@router.post('/register')
def register(req: RegisterRequest):
    from database import execute_update
    from utils.encryption import encrypt_reader_sensitive

    # 检查是否已存在
    existing = execute_query(
        'SELECT reader_id FROM readers WHERE reader_id = %s;',
        (req.reader_id,)
    )
    if existing:
        raise HTTPException(status_code=400, detail='读者编号已存在')

    # 创建读者
    pwd_hash = hash_password(req.password)
    execute_update(
        """INSERT INTO readers (reader_id, name, reader_type_id, department, password_hash)
           VALUES (%s, %s, %s, %s, %s);""",
        (req.reader_id, req.name, req.reader_type_id, req.department, pwd_hash)
    )

    # 创建系统用户
    execute_update(
        """INSERT INTO users (username, password_hash, role, reader_id)
           VALUES (%s, %s, 'reader', %s);""",
        (req.reader_id, pwd_hash, req.reader_id)
    )

    return {'message': '注册成功', 'reader_id': req.reader_id}


# ---- 获取当前用户信息 ----
@router.get('/me')
def get_me(user: dict = Depends(get_current_user)):
    return user
