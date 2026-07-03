-- ============================================================
-- 05_create_triggers.sql
-- 高校图书借阅管理系统 — 触发器 DDL
-- 共 5 个触发器（3 个业务触发器 + 2 个安全触发器）
-- ============================================================

-- --------------------------------------------
-- 触发器 1: trg_borrow_insert
-- 功能: 借书时 — 校验库存 + 校验限额 + 自动计算应还日期 + 减少馆藏可借数量（题目要求）
-- 时机: BEFORE INSERT ON borrow_records
-- --------------------------------------------
CREATE OR REPLACE FUNCTION func_borrow_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_available   INTEGER;
    v_borrow_days INTEGER;
    v_can_borrow  BOOLEAN;
BEGIN
    -- 1. 检查馆藏可借数量
    SELECT available_copies INTO v_available
    FROM books WHERE isbn = NEW.isbn;

    IF NOT FOUND THEN
        RAISE EXCEPTION '图书 % 不存在', NEW.isbn;
    END IF;

    IF v_available <= 0 THEN
        RAISE EXCEPTION '图书 % 已全部借出，无法借阅', NEW.isbn;
    END IF;

    -- 2. 检查读者借书限额
    v_can_borrow := fn_can_borrow(NEW.reader_id);
    IF NOT v_can_borrow THEN
        RAISE EXCEPTION '读者 % 已达到最大借书数量限制', NEW.reader_id;
    END IF;

    -- 3. 自动计算应还日期（借书日期 + 该读者类型的可借天数）
    SELECT rt.borrow_days INTO v_borrow_days
    FROM readers r
    JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
    WHERE r.reader_id = NEW.reader_id;

    NEW.due_date := COALESCE(NEW.borrow_date, CURRENT_DATE)
                    + COALESCE(v_borrow_days, 30);

    -- 4. 减少馆藏可借数量
    UPDATE books
    SET available_copies = available_copies - 1
    WHERE isbn = NEW.isbn;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_borrow_insert ON borrow_records;
CREATE TRIGGER trg_borrow_insert
    BEFORE INSERT ON borrow_records
    FOR EACH ROW
    EXECUTE PROCEDURE func_borrow_insert();

-- --------------------------------------------
-- 触发器 2: trg_borrow_update_return
-- 功能: 还书时 — 自动计算罚金 + 增加馆藏可借数量（题目要求）
-- 时机: BEFORE UPDATE ON borrow_records
-- 条件: return_date 从 NULL 变为非 NULL（即执行还书操作）
-- --------------------------------------------
CREATE OR REPLACE FUNCTION func_borrow_update_return()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- 仅在设置归还日期时触发（还书操作）
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        -- 计算罚金
        NEW.fine_amount := fn_calculate_overdue_fine(NEW.borrow_id);

        -- 更新状态
        IF NEW.fine_amount > 0 THEN
            NEW.status := 'returned';
        ELSE
            NEW.status := 'returned';
        END IF;

        -- 增加馆藏可借数量
        UPDATE books
        SET available_copies = available_copies + 1
        WHERE isbn = NEW.isbn;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_borrow_update_return ON borrow_records;
CREATE TRIGGER trg_borrow_update_return
    BEFORE UPDATE ON borrow_records
    FOR EACH ROW
    EXECUTE PROCEDURE func_borrow_update_return();

-- --------------------------------------------
-- 触发器 3: trg_auto_mark_overdue
-- 功能: 自动检测超期 — 当前日期超过应还日期且未归还时，标记为 "overdue"
-- 时机: BEFORE INSERT OR UPDATE ON borrow_records
-- --------------------------------------------
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
$$;

DROP TRIGGER IF EXISTS trg_auto_mark_overdue ON borrow_records;
CREATE TRIGGER trg_auto_mark_overdue
    BEFORE INSERT OR UPDATE ON borrow_records
    FOR EACH ROW
    EXECUTE PROCEDURE func_auto_mark_overdue();

-- --------------------------------------------
-- 触发器 4: trg_operation_log（安全触发器 — 审计日志）
-- 功能: 记录 borrow_records 表的所有 INSERT/UPDATE/DELETE 操作
-- 时机: AFTER INSERT OR UPDATE OR DELETE ON borrow_records
-- --------------------------------------------
CREATE OR REPLACE FUNCTION func_borrow_operation_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_record_id VARCHAR(50);
BEGIN
    -- 确定记录ID
    IF TG_OP = 'DELETE' THEN
        v_record_id := OLD.borrow_id::VARCHAR;
    ELSE
        v_record_id := NEW.borrow_id::VARCHAR;
    END IF;

    INSERT INTO operation_logs (
        user_id, operation_type, table_name, record_id,
        ip_address
    ) VALUES (
        NULL, TG_OP, TG_TABLE_NAME, v_record_id,
        NULL
    );

    -- OpenGauss 不支持 COALESCE(NEW, OLD)，需用 IF 分支返回
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_operation_log ON borrow_records;
CREATE TRIGGER trg_operation_log
    AFTER INSERT OR UPDATE OR DELETE ON borrow_records
    FOR EACH ROW
    EXECUTE PROCEDURE func_borrow_operation_log();

-- --------------------------------------------
-- 触发器 5: trg_prevent_book_delete（安全触发器 — 业务规则拦截）
-- 功能: 阻止删除尚有未归还记录的图书
-- 时机: BEFORE DELETE ON books
-- --------------------------------------------
CREATE OR REPLACE FUNCTION func_prevent_book_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_borrowing_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_borrowing_count
    FROM borrow_records
    WHERE isbn = OLD.isbn
      AND return_date IS NULL;

    IF v_borrowing_count > 0 THEN
        RAISE EXCEPTION
            '图书 %（%）尚有 % 条未归还记录，无法删除',
            OLD.isbn, OLD.title, v_borrowing_count;
    END IF;

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_book_delete ON books;
CREATE TRIGGER trg_prevent_book_delete
    BEFORE DELETE ON books
    FOR EACH ROW
    EXECUTE PROCEDURE func_prevent_book_delete();
