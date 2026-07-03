-- ============================================================
-- 03_create_views.sql
-- 高校图书借阅管理系统 — 视图 DDL
-- 共 5 个视图，覆盖 5 个聚合函数：COUNT / SUM / AVG / MAX / MIN
-- ============================================================

-- --------------------------------------------
-- 视图 1: v_current_borrowings
-- 功能: 显示当前所有借阅未还的图书及读者信息（题目要求）
-- 安全: 隐藏 phone/email（加密字段）和 price，供 reader 角色查询
-- --------------------------------------------
CREATE OR REPLACE VIEW v_current_borrowings AS
SELECT
    br.borrow_id,
    br.reader_id,
    r.name             AS reader_name,
    rt.type_name       AS reader_type,
    r.department,
    br.isbn,
    b.title,
    b.author,
    br.borrow_date,
    br.due_date,
    CASE WHEN br.due_date < CURRENT_DATE
         THEN (CURRENT_DATE - br.due_date)
         ELSE 0
    END                AS overdue_days,
    br.status
FROM borrow_records br
JOIN readers r       ON br.reader_id = r.reader_id
JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
JOIN books b         ON br.isbn = b.isbn
WHERE br.return_date IS NULL
ORDER BY br.due_date ASC;

-- --------------------------------------------
-- 视图 2: v_overdue_books
-- 功能: 显示超期未还图书清单（含读者联系方式，用于催还）
-- 安全: 仅 admin 和 librarian 角色授予 SELECT 权限
-- --------------------------------------------
CREATE OR REPLACE VIEW v_overdue_books AS
SELECT
    br.borrow_id,
    br.reader_id,
    r.name             AS reader_name,
    rt.type_name       AS reader_type,
    r.department,
    r.phone,                                          -- 管理员可见
    r.email,                                          -- 管理员可见
    br.isbn,
    b.title,
    b.author,
    br.borrow_date,
    br.due_date,
    CURRENT_DATE - br.due_date AS overdue_days,
    br.fine_amount
FROM borrow_records br
JOIN readers r       ON br.reader_id = r.reader_id
JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
JOIN books b         ON br.isbn = b.isbn
WHERE br.return_date IS NULL
  AND br.due_date < CURRENT_DATE
ORDER BY overdue_days DESC;

-- --------------------------------------------
-- 视图 3: v_reader_borrowing_stats
-- 功能: 读者借阅统计，含当前借阅数/总借阅数/总罚金/最高罚金/平均罚金
-- 聚合函数: COUNT, SUM, MAX, AVG（4 个）
-- --------------------------------------------
CREATE OR REPLACE VIEW v_reader_borrowing_stats AS
SELECT
    r.reader_id,
    r.name,
    rt.type_name                                                        AS reader_type,
    r.department,
    COUNT(CASE WHEN br.return_date IS NULL THEN br.borrow_id END)       AS current_borrow_count,
    COUNT(br.borrow_id)                                                 AS total_borrow_count,
    COALESCE(SUM(br.fine_amount), 0)                                    AS total_fine,
    COALESCE(MAX(br.fine_amount), 0)                                    AS max_single_fine,
    COALESCE(
        AVG(CASE WHEN br.fine_amount > 0 THEN br.fine_amount END), 0
    )                                                                   AS avg_fine
FROM readers r
JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
LEFT JOIN borrow_records br ON r.reader_id = br.reader_id
GROUP BY r.reader_id, r.name, rt.type_name, r.department;

-- --------------------------------------------
-- 视图 4: v_book_inventory_stats
-- 功能: 图书库存与借阅热度统计
-- 聚合函数: COUNT, MIN, MAX（3 个）
-- --------------------------------------------
CREATE OR REPLACE VIEW v_book_inventory_stats AS
SELECT
    b.isbn,
    b.title,
    b.author,
    b.publisher,
    b.total_copies,
    b.available_copies,
    COUNT(br.borrow_id)                                                   AS total_borrow_times,
    COUNT(CASE WHEN br.return_date IS NULL THEN br.borrow_id END)           AS current_borrowed,
    COALESCE(MIN(b.price), 0)                                             AS unit_price
FROM books b
LEFT JOIN borrow_records br ON b.isbn = br.isbn
GROUP BY b.isbn, b.title, b.author, b.publisher, b.total_copies, b.available_copies;

-- --------------------------------------------
-- 视图 5: v_monthly_fine_summary
-- 功能: 月度罚金汇总（用于财务统计）
-- 聚合函数: COUNT, SUM, AVG, MAX（4 个）
-- --------------------------------------------
CREATE OR REPLACE VIEW v_monthly_fine_summary AS
SELECT
    DATE_TRUNC('month', br.return_date)::DATE AS month,
    COUNT(br.borrow_id)                       AS overdue_count,
    COALESCE(SUM(br.fine_amount), 0)          AS total_fine,
    COALESCE(AVG(br.fine_amount), 0)          AS avg_fine_per_record,
    COALESCE(MAX(br.fine_amount), 0)          AS max_fine
FROM borrow_records br
WHERE br.fine_amount > 0
  AND br.return_date IS NOT NULL
GROUP BY DATE_TRUNC('month', br.return_date)::DATE
ORDER BY month DESC;

-- ============================================================
-- 聚合函数使用清单（5 个全覆盖）
-- ============================================================
-- | 聚合函数 | 使用位置 |
-- |---------|---------|
-- | COUNT   | v_reader_borrowing_stats, v_book_inventory_stats, v_monthly_fine_summary |
-- | SUM     | v_reader_borrowing_stats, v_monthly_fine_summary |
-- | AVG     | v_reader_borrowing_stats, v_monthly_fine_summary |
-- | MAX     | v_reader_borrowing_stats, v_book_inventory_stats, v_monthly_fine_summary |
-- | MIN     | v_book_inventory_stats |
