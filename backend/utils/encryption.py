# ============================================================
# encryption.py — OpenGauss 敏感字段加密/解密
# 使用 OpenGauss 原生函数 gs_encrypt_aes128 / gs_decrypt_aes128
# ============================================================
from database import execute_query, execute_update
from config import ENCRYPTION_KEY


def encrypt_field(plaintext: str) -> bytes:
    """
    加密敏感字段（如 phone、email）
    调用 OpenGauss gs_encrypt_aes128，返回 BYTEA
    """
    if not plaintext:
        return None
    sql = "SELECT gs_encrypt_aes128(%s, %s);"
    result = execute_query(sql, (plaintext, ENCRYPTION_KEY))
    return result[0][0] if result else None


def decrypt_field(cipher_bytes: bytes) -> str:
    """
    解密敏感字段
    调用 OpenGauss gs_decrypt_aes128，返回明文
    """
    if not cipher_bytes:
        return None
    sql = "SELECT gs_decrypt_aes128(%s, %s);"
    result = execute_query(sql, (cipher_bytes, ENCRYPTION_KEY))
    return result[0][0] if result else None


def encrypt_reader_sensitive(reader_id: str, phone: str, email: str):
    """
    更新读者的 phone 和 email 为加密值
    """
    enc_phone = encrypt_field(phone)
    enc_email = encrypt_field(email)
    sql = 'UPDATE readers SET phone = %s, email = %s WHERE reader_id = %s;'
    execute_update(sql, (enc_phone, enc_email, reader_id))
