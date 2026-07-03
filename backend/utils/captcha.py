# ============================================================
# captcha.py — 图形验证码生成与校验
# ============================================================
import io
import random
import string
import base64
from typing import Tuple
from PIL import Image, ImageDraw, ImageFont


# 内存存储验证码（简易方案，生产环境应用 Redis）
_captcha_store: dict = {}


def generate_captcha() -> Tuple[str, str]:
    """
    生成图形验证码
    返回: (captcha_token, captcha_image_base64)
    """
    # 生成随机字符
    chars = string.ascii_uppercase + string.digits
    # 排除易混淆字符
    chars = chars.replace('O', '').replace('0', '').replace('I', '').replace('1', '')
    code = ''.join(random.choices(chars, k=4))

    # 创建图片
    width, height = 120, 44
    image = Image.new('RGB', (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(image)

    # 绘制干扰线
    for i in range(5):
        x1 = random.randint(0, width)
        y1 = random.randint(0, height)
        x2 = random.randint(0, width)
        y2 = random.randint(0, height)
        draw.line([(x1, y1), (x2, y2)], fill=(200, 200, 200), width=1)

    # 绘制干扰点
    for i in range(50):
        x = random.randint(0, width)
        y = random.randint(0, height)
        draw.point((x, y), fill=(180, 180, 180))

    # 绘制文字
    try:
        font = ImageFont.truetype('arial.ttf', 28)
    except OSError:
        font = ImageFont.load_default()

    for i, char in enumerate(code):
        x = 10 + i * 25 + random.randint(-3, 3)
        y = random.randint(3, 10)
        r = random.randint(0, 100)
        g = random.randint(0, 100)
        b = random.randint(0, 100)
        draw.text((x, y), char, font=font, fill=(r, g, b))

    # 保存为 base64
    buffer = io.BytesIO()
    image.save(buffer, format='PNG')
    img_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')

    # 存储验证码（用 token 关联）
    token = ''.join(random.choices(string.ascii_letters + string.digits, k=32))
    _captcha_store[token] = code

    return token, img_base64


def verify_captcha(token: str, user_input: str) -> bool:
    """验证用户输入的验证码"""
    stored = _captcha_store.pop(token, None)
    if stored is None:
        return False
    return stored.upper() == user_input.upper()
