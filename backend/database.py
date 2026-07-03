# ============================================================
# database.py — OpenGauss 数据库连接池管理
# ============================================================
import psycopg2
from psycopg2 import pool
from config import DB_CONFIG

# 全局连接池（min=2, max=10）
connection_pool = pool.SimpleConnectionPool(2, 10, **DB_CONFIG)


def get_connection():
    """获取一个数据库连接"""
    return connection_pool.getconn()


def release_connection(conn):
    """归还数据库连接到连接池"""
    connection_pool.putconn(conn)


def execute_query(sql: str, params: tuple = None, fetch: bool = True):
    """
    执行单条查询，自动管理连接
    返回：fetch=True 时返回 [(row1), (row2), ...]，否则返回 None
    """
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql, params)
        if fetch:
            result = cur.fetchall()
        else:
            conn.commit()
            result = None
        cur.close()
        return result
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        release_connection(conn)


def execute_update(sql: str, params: tuple = None):
    """
    执行 INSERT/UPDATE/DELETE，返回影响行数
    """
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql, params)
        conn.commit()
        rowcount = cur.rowcount
        cur.close()
        return rowcount
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        release_connection(conn)


def execute_procedure(proc_sql: str, params: tuple = None):
    """执行存储过程/函数并返回结果"""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(proc_sql, params)
        result = cur.fetchall()
        conn.commit()
        cur.close()
        return result
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        release_connection(conn)
