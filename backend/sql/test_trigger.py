"""Test OpenGauss trigger syntax"""
import psycopg2

conn = psycopg2.connect(host='127.0.0.1', port=5432, database='library_db', user='gaussdb', password='Gauss123!')
conn.autocommit = True
cur = conn.cursor()

# Test 1: Just create a simple trigger function
func_sql = '''
CREATE OR REPLACE FUNCTION func_test_trg()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN NEW;
END;
$$;
'''
try:
    cur.execute(func_sql)
    print('1. Trigger function created OK')
except Exception as e:
    print(f'1. Function FAILED: {str(e)[:150]}')
    conn.rollback()

# Test 2: CREATE TRIGGER with semicolon separator
trg_sql = '''
DROP TRIGGER IF EXISTS trg_test ON reader_types;
CREATE TRIGGER trg_test
    BEFORE INSERT ON reader_types
    FOR EACH ROW
    EXECUTE PROCEDURE func_test_trg();
'''
try:
    cur.execute(trg_sql)
    print('2. Trigger (semicolon separator) OK')
except Exception as e:
    print(f'2. Trigger FAILED: {str(e)[:150]}')
    conn.rollback()

# Test 3: Combined in one statement
try:
    cur.execute('''
CREATE OR REPLACE FUNCTION func_test_trg2()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_test2 ON reader_types;
CREATE TRIGGER trg_test2
    BEFORE INSERT ON reader_types
    FOR EACH ROW
    EXECUTE PROCEDURE func_test_trg2();
''')
    print('3. Function + trigger combined OK')
except Exception as e:
    print(f'3. Combined FAILED: {str(e)[:150]}')
    conn.rollback()

cur.close()
conn.close()
print('Done.')
