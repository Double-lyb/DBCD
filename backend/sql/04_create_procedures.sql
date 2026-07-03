-- ============================================================
-- 04_create_procedures.sql
-- 高校图书借阅管理系统 — 存储过程 & 用户自定义函数
-- 1 个存储过程 + 3 个函数
-- ============================================================

-- --------------------------------------------
-- 存储过程（以函数形式实现，OpenGauss 5.0 兼容）
-- 功能: 按读者编号返回当前借阅图书及应还日期（题目要求）
-- 使用: SELECT * FROM sp_get_reader_borrowings('20210001');
-- --------------------------------------------
CREATE OR REPLACE FUNCTION sp_get_reader_borrowings(
    p_reader_id VARCHAR(20)
)
RETURNS TABLE(
    borrow_id      INTEGER,
    isbn           VARCHAR,
    title          VARCHAR,
    author         VARCHAR,
    publisher      VARCHAR,
    borrow_date    DATE,
    due_date       DATE,
    overdue_days   INTEGER,
    estimated_fine NUMERIC,
    status         VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            br.borrow_id,
            b.isbn,
            b.title,
            b.author,
            b.publisher,
            br.borrow_date,
            br.due_date,
            CASE
                WHEN br.due_date < CURRENT_DATE
                THEN (CURRENT_DATE - br.due_date)::INTEGER
                ELSE 0
            END,
            CASE
                WHEN br.due_date < CURRENT_DATE
                THEN (CURRENT_DATE - br.due_date)::INTEGER
                     * COALESCE(
                         (SELECT fine_per_day FROM fine_rules
                          WHERE effective_to IS NULL
                          ORDER BY effective_from DESC LIMIT 1),
                         0.50
                       )
                ELSE 0
            END,
            br.status
        FROM borrow_records br
        JOIN books b ON br.isbn = b.isbn
        WHERE br.reader_id = p_reader_id
          AND br.return_date IS NULL
        ORDER BY br.due_date ASC;
END;
$$;

-- --------------------------------------------
-- 函数 1: fn_calculate_overdue_fine
-- 功能: 计算单条借阅记录的超期罚金
-- 输入: borrow_id
-- 返回: 罚金金额 (DECIMAL(10,2))
-- --------------------------------------------
CREATE OR REPLACE FUNCTION fn_calculate_overdue_fine(
    p_borrow_id INTEGER
)
RETURNS DECIMAL(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_due_date      DATE;
    v_return_date   DATE;
    v_fine_per_day  DECIMAL(10,2);
    v_fine          DECIMAL(10,2) := 0;
    v_overdue_days  INTEGER;
BEGIN
    -- 获取借阅记录的应还日期和归还日期
    SELECT due_date, return_date
    INTO v_due_date, v_return_date
    FROM borrow_records
    WHERE borrow_id = p_borrow_id;

    IF NOT FOUND THEN
        RETURN 0;
    END IF;

    -- 未归还的用当前日期估算
    IF v_return_date IS NULL THEN
        v_return_date := CURRENT_DATE;
    END IF;

    -- 计算超期天数
    v_overdue_days := v_return_date - v_due_date;
    IF v_overdue_days <= 0 THEN
        RETURN 0;
    END IF;

    -- 获取当前有效的罚金费率
    SELECT fine_per_day INTO v_fine_per_day
    FROM fine_rules
    WHERE effective_to IS NULL
    ORDER BY effective_from DESC
    LIMIT 1;

    IF NOT FOUND THEN
        v_fine_per_day := 0.50;  -- 默认每日 0.5 元
    END IF;

    v_fine := v_overdue_days * v_fine_per_day;
    RETURN ROUND(v_fine::NUMERIC, 2);
END;
$$;

-- --------------------------------------------
-- 函数 2: fn_get_reader_current_borrow_count
-- 功能: 获取读者当前未还的借书数量（用于借书前限额检查）
-- 输入: reader_id
-- 返回: 当前借书数量 (INTEGER)
-- --------------------------------------------
CREATE OR REPLACE FUNCTION fn_get_reader_current_borrow_count(
    p_reader_id VARCHAR(20)
)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT COUNT(*)::INTEGER
    FROM borrow_records
    WHERE reader_id = p_reader_id
      AND return_date IS NULL;
$$;

-- --------------------------------------------
-- 函数 3: fn_can_borrow
-- 功能: 判断读者是否可以继续借书（比较当前借书数 vs 最大限额）
-- 输入: reader_id
-- 返回: TRUE 表示可继续借书，FALSE 表示已满
-- --------------------------------------------
CREATE OR REPLACE FUNCTION fn_can_borrow(
    p_reader_id VARCHAR(20)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_count  INTEGER;
    v_max_count      INTEGER;
BEGIN
    -- 获取当前借书数量
    v_current_count := fn_get_reader_current_borrow_count(p_reader_id);

    -- 获取该读者类型的最大借书数量
    SELECT rt.max_borrow_count INTO v_max_count
    FROM readers r
    JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
    WHERE r.reader_id = p_reader_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    RETURN v_current_count < v_max_count;
END;
$$;
