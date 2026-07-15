# ==============================================================================
# UniSeek 兼职招聘平台 - 密码加密工具
# ==============================================================================
# 兼容 Java PasswordUtil 的 MD5 + Salt 方案：
#   1. salt = 16 随机字节 → 32 位十六进制字符串
#   2. password = MD5(password + salt)
#   3. verify = 比较 MD5(input + salt) 与 stored_password

import hashlib
import secrets


def generate_salt() -> str:
    """
    生成随机盐值。

    Returns:
        32 位十六进制字符串（16 随机字节）
    """
    return secrets.token_hex(16)


def encrypt_password(password: str, salt: str) -> str:
    """
    MD5 加密密码。

    算法：MD5(password + salt)

    Args:
        password: 明文密码
        salt: 盐值（32 位十六进制字符串）

    Returns:
        32 位十六进制 MD5 摘要
    """
    return hashlib.md5((password + salt).encode('utf-8')).hexdigest()


def verify(input_password: str, stored_password: str, salt: str) -> bool:
    """
    验证密码是否正确。

    Args:
        input_password: 用户输入的明文密码
        stored_password: 数据库中存储的 MD5 哈希值
        salt: 数据库中存储的盐值

    Returns:
        True 如果密码匹配，否则 False
    """
    return stored_password == encrypt_password(input_password, salt)
