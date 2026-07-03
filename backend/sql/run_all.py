"""Execute all SQL files in order against library_db"""
import psycopg2
import os

HOST = '127.0.0.1'
PORT = 5432
DB = 'library_db'
USER = 'gaussdb'
PASS = 'Gauss123!'

SQL_DIR = os.path.dirname(os.path.abspath(__file__))
FILES = [
    '01_create_tables.sql',
    '02_create_indexes.sql',
    '03_create_views.sql',
    '04_create_procedures.sql',
    '05_create_triggers.sql',
    '06_seed_data.sql',
    '07_borrow_applications.sql',
]

conn = psycopg2.connect(host=HOST, port=PORT, database=DB, user=USER, password=PASS)
conn.autocommit = True
cur = conn.cursor()

for f in FILES:
    path = os.path.join(SQL_DIR, f)
    with open(path, 'r', encoding='utf-8') as fh:
        sql = fh.read()
    try:
        cur.execute(sql)
        print(f'[OK] {f}')
    except Exception as e:
        print(f'[FAIL] {f}: {str(e)[:200]}')
        conn.rollback()

cur.close()
conn.close()
print('All done.')
