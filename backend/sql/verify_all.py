"""Verify all database objects are created correctly"""
import psycopg2

conn = psycopg2.connect(host='127.0.0.1', port=5432, database='library_db', user='gaussdb', password='Gauss123!')
conn.autocommit = True
cur = conn.cursor()

print('='*60)
print('DATABASE VERIFICATION')
print('='*60)

# 1. Check tables
print('\n[1] Tables:')
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY table_name;")
tables = [r[0] for r in cur.fetchall()]
for t in tables:
    cur.execute(f"SELECT COUNT(*) FROM {t};")
    count = cur.fetchone()[0]
    print(f'    {t}: {count} rows')
print(f'  Total: {len(tables)} tables')

# 2. Check views
print('\n[2] Views:')
cur.execute("SELECT table_name FROM information_schema.views WHERE table_schema='public' ORDER BY table_name;")
views = [r[0] for r in cur.fetchall()]
for v in views:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {v};")
        count = cur.fetchone()[0]
        print(f'    {v}: {count} rows')
    except Exception as e:
        print(f'    {v}: ERROR - {str(e)[:80]}')
print(f'  Total: {len(views)} views')

# 3. Check procedures/functions
print('\n[3] Functions & Procedures:')
cur.execute("SELECT routine_name, routine_type FROM information_schema.routines WHERE routine_schema='public' ORDER BY routine_name;")
funcs = cur.fetchall()
for name, rtype in funcs:
    print(f'    {name} ({rtype})')
print(f'  Total: {len(funcs)}')

# 4. Check triggers
print('\n[4] Triggers:')
cur.execute("SELECT trigger_name, event_object_table FROM information_schema.triggers ORDER BY trigger_name;")
triggers = cur.fetchall()
for tname, ttable in triggers:
    print(f'    {tname} ON {ttable}')
print(f'  Total: {len(triggers)} triggers')

# 5. Check indexes
print('\n[5] Indexes (custom):')
cur.execute("SELECT indexname, tablename FROM pg_indexes WHERE schemaname='public' AND indexname LIKE 'idx_%' ORDER BY indexname;")
indexes = cur.fetchall()
for iname, itable in indexes:
    print(f'    {iname} ON {itable}')
print(f'  Total: {len(indexes)} custom indexes')

# 6. Test stored procedure
print('\n[6] Test sp_get_reader_borrowings:')
try:
    cur.execute("SELECT * FROM sp_get_reader_borrowings('20210001');")
    rows = cur.fetchall()
    print(f'    Reader 20210001: {len(rows)} borrowed books')
    for r in rows:
        print(f'      - {r[1]} (due: {r[5]})')
except Exception as e:
    print(f'    ERROR: {str(e)[:120]}')

# 7. Test view
print('\n[7] Test v_current_borrowings:')
cur.execute("SELECT borrow_id, reader_name, title, due_date, status FROM v_current_borrowings LIMIT 5;")
rows = cur.fetchall()
for r in rows:
    print(f'    #{r[0]} {r[1]} -> {r[2]} (due: {r[3]}, status: {r[4]})')

# 8. Test trigger: borrow INSERT
print('\n[8] Test borrow trigger:')
cur.execute("SELECT available_copies FROM books WHERE isbn='978-7-111-9';")
before = cur.fetchone()[0]
print(f'    Book 高等数学 available copies BEFORE: {before}')

try:
    cur.execute("INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, status) VALUES ('20210003', '978-7-111-9', '2026-07-02', '2026-08-01', 'borrowed');")
    conn.commit()
    cur.execute("SELECT available_copies FROM books WHERE isbn='978-7-111-9';")
    after = cur.fetchone()[0]
    print(f'    Book 高等数学 available copies AFTER: {after}')
    if after == before - 1:
        print('    TRIGGER WORKS: available_copies decreased by 1')
    else:
        print(f'    WARNING: expected {before-1}, got {after}')
except Exception as e:
    print(f'    ERROR: {str(e)[:120]}')
    conn.rollback()

# 9. Test trigger: return
print('\n[9] Test return trigger:')
cur.execute("SELECT available_copies FROM books WHERE isbn='978-7-111-9';")
before = cur.fetchone()[0]
try:
    cur.execute("UPDATE borrow_records SET return_date='2026-07-05' WHERE reader_id='20210003' AND isbn='978-7-111-9' AND return_date IS NULL;")
    conn.commit()
    cur.execute("SELECT available_copies FROM books WHERE isbn='978-7-111-9';")
    after = cur.fetchone()[0]
    cur.execute("SELECT fine_amount, status FROM borrow_records WHERE reader_id='20210003' AND isbn='978-7-111-9';")
    fine_info = cur.fetchone()
    print(f'    Available copies: {before} -> {after}')
    print(f'    Fine: {fine_info[0]}, Status: {fine_info[1]}')
    if after == before + 1:
        print('    RETURN TRIGGER WORKS: available_copies increased by 1')
except Exception as e:
    print(f'    ERROR: {str(e)[:120]}')
    conn.rollback()

# 10. Test CHECK constraint
print('\n[10] Test CHECK constraint:')
try:
    cur.execute("INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, status) VALUES ('20210001', '978-7-111-1', '2026-07-10', '2026-07-01', 'borrowed');")
    conn.commit()
    print('    WARNING: CHECK constraint did not fire!')
except Exception as e:
    print(f'    CHECK WORKS: due_date < borrow_date rejected')
    conn.rollback()

# 11. Test aggregate functions in views
print('\n[11] Test aggregate views:')
cur.execute("SELECT name, total_borrow_count, total_fine, max_single_fine, ROUND(avg_fine::NUMERIC,2) FROM v_reader_borrowing_stats WHERE total_borrow_count > 0;")
rows = cur.fetchall()
for r in rows:
    print(f'    {r[0]}: borrows={r[1]}, total_fine={r[2]}, max_fine={r[3]}, avg_fine={r[4]}')
print('    COUNT, SUM, MAX, AVG all used')

cur.execute("SELECT title, unit_price FROM v_book_inventory_stats WHERE total_borrow_times > 0;")
rows = cur.fetchall()
for r in rows:
    print(f'    {r[0]}: price(MIN)={r[1]}')
print('    MIN used')

cur.close()
conn.close()
print('\n' + '='*60)
print('VERIFICATION COMPLETE')
print('='*60)
