"""Test trigger functions one by one in OpenGauss"""
import psycopg2

conn = psycopg2.connect(host='127.0.0.1', port=5432, database='library_db', user='gaussdb', password='Gauss123!')
conn.autocommit = True
cur = conn.cursor()

# Drop existing triggers first
for tbl, trig in [
    ('borrow_records', 'trg_borrow_insert'),
    ('borrow_records', 'trg_borrow_update_return'),
    ('borrow_records', 'trg_auto_mark_overdue'),
    ('borrow_records', 'trg_operation_log'),
    ('books', 'trg_prevent_book_delete'),
]:
    try:
        cur.execute(f'DROP TRIGGER IF EXISTS {trig} ON {tbl};')
    except:
        pass

# Test trigger function 1
sql1 = r'''
CREATE OR REPLACE FUNCTION func_borrow_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_available   INTEGER;
    v_borrow_days INTEGER;
    v_can_borrow  BOOLEAN;
BEGIN
    SELECT available_copies INTO v_available
    FROM books WHERE isbn = NEW.isbn;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'book not found';
    END IF;
    IF v_available <= 0 THEN
        RAISE EXCEPTION 'no copies';
    END IF;
    v_can_borrow := fn_can_borrow(NEW.reader_id);
    IF NOT v_can_borrow THEN
        RAISE EXCEPTION 'limit reached';
    END IF;
    SELECT rt.borrow_days INTO v_borrow_days
    FROM readers r
    JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
    WHERE r.reader_id = NEW.reader_id;
    NEW.due_date := COALESCE(NEW.borrow_date, CURRENT_DATE)
                    + COALESCE(v_borrow_days, 30);
    UPDATE books SET available_copies = available_copies - 1
    WHERE isbn = NEW.isbn;
    RETURN NEW;
END;
$$
'''
try:
    cur.execute(sql1)
    print('1. func_borrow_insert: OK')
except Exception as e:
    print(f'1. func_borrow_insert FAILED: {str(e)[:200]}')
    conn.rollback()

# Test trigger
try:
    cur.execute('CREATE TRIGGER trg_borrow_insert BEFORE INSERT ON borrow_records FOR EACH ROW EXECUTE PROCEDURE func_borrow_insert();')
    print('   Trigger created: OK')
except Exception as e:
    print(f'   Trigger FAILED: {str(e)[:200]}')

# Test trigger function 2
sql2 = r'''
CREATE OR REPLACE FUNCTION func_borrow_update_return()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        NEW.fine_amount := fn_calculate_overdue_fine(NEW.borrow_id);
        NEW.status := 'returned';
        UPDATE books SET available_copies = available_copies + 1
        WHERE isbn = NEW.isbn;
    END IF;
    RETURN NEW;
END;
$$
'''
try:
    cur.execute(sql2)
    print('2. func_borrow_update_return: OK')
except Exception as e:
    print(f'2. func_borrow_update_return FAILED: {str(e)[:200]}')
    conn.rollback()

try:
    cur.execute('CREATE TRIGGER trg_borrow_update_return BEFORE UPDATE ON borrow_records FOR EACH ROW EXECUTE PROCEDURE func_borrow_update_return();')
    print('   Trigger created: OK')
except Exception as e:
    print(f'   Trigger FAILED: {str(e)[:200]}')

# Test trigger function 3
sql3 = r'''
CREATE OR REPLACE FUNCTION func_auto_mark_overdue()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.due_date < CURRENT_DATE
       AND NEW.return_date IS NULL
       AND NEW.status = 'borrowed' THEN
        NEW.status := 'overdue';
    END IF;
    RETURN NEW;
END;
$$
'''
try:
    cur.execute(sql3)
    print('3. func_auto_mark_overdue: OK')
except Exception as e:
    print(f'3. func_auto_mark_overdue FAILED: {str(e)[:200]}')
    conn.rollback()

try:
    cur.execute('CREATE TRIGGER trg_auto_mark_overdue BEFORE INSERT OR UPDATE ON borrow_records FOR EACH ROW EXECUTE PROCEDURE func_auto_mark_overdue();')
    print('   Trigger created: OK')
except Exception as e:
    print(f'   Trigger FAILED: {str(e)[:200]}')

# Test trigger function 4
sql4 = r'''
CREATE OR REPLACE FUNCTION func_borrow_operation_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_detail TEXT;
    v_record_id VARCHAR(50);
BEGIN
    CASE TG_OP
        WHEN 'INSERT' THEN
            v_detail := 'insert';
            v_record_id := NEW.borrow_id::VARCHAR;
        WHEN 'UPDATE' THEN
            v_detail := 'update';
            v_record_id := NEW.borrow_id::VARCHAR;
        WHEN 'DELETE' THEN
            v_detail := 'delete';
            v_record_id := OLD.borrow_id::VARCHAR;
    END CASE;
    INSERT INTO operation_logs (user_id, operation_type, table_name, record_id, ip_address)
    VALUES (NULL, TG_OP, TG_TABLE_NAME, v_record_id, NULL);
    RETURN COALESCE(NEW, OLD);
END;
$$
'''
try:
    cur.execute(sql4)
    print('4. func_borrow_operation_log: OK')
except Exception as e:
    print(f'4. func_borrow_operation_log FAILED: {str(e)[:200]}')
    conn.rollback()

try:
    cur.execute('CREATE TRIGGER trg_operation_log AFTER INSERT OR UPDATE OR DELETE ON borrow_records FOR EACH ROW EXECUTE PROCEDURE func_borrow_operation_log();')
    print('   Trigger created: OK')
except Exception as e:
    print(f'   Trigger FAILED: {str(e)[:200]}')

# Test trigger function 5
sql5 = r'''
CREATE OR REPLACE FUNCTION func_prevent_book_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_borrowing_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_borrowing_count
    FROM borrow_records
    WHERE isbn = OLD.isbn AND return_date IS NULL;
    IF v_borrowing_count > 0 THEN
        RAISE EXCEPTION 'book has % unreturned records', v_borrowing_count;
    END IF;
    RETURN OLD;
END;
$$
'''
try:
    cur.execute(sql5)
    print('5. func_prevent_book_delete: OK')
except Exception as e:
    print(f'5. func_prevent_book_delete FAILED: {str(e)[:200]}')
    conn.rollback()

try:
    cur.execute('CREATE TRIGGER trg_prevent_book_delete BEFORE DELETE ON books FOR EACH ROW EXECUTE PROCEDURE func_prevent_book_delete();')
    print('   Trigger created: OK')
except Exception as e:
    print(f'   Trigger FAILED: {str(e)[:200]}')

cur.close()
conn.close()
print('Done.')
