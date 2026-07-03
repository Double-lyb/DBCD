-- ============================================================
-- 07_borrow_applications.sql
-- 借阅申请表 — 读者申请→管理员审批 两阶段借书流程
-- 方案A：「申请即预留」：申请时扣库存，过期/驳回恢复库存
-- ============================================================

-- 1. 借阅申请表（6 小时有效期）
DROP TABLE IF EXISTS borrow_applications CASCADE;
CREATE TABLE borrow_applications (
    application_id  SERIAL        PRIMARY KEY,
    reader_id       VARCHAR(20)   NOT NULL REFERENCES readers(reader_id),
    isbn            VARCHAR(20)   NOT NULL REFERENCES books(isbn),
    status          VARCHAR(15)   NOT NULL DEFAULT 'pending'
                                  CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    applied_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at      TIMESTAMP     NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '6 hours'),
    processed_by    INTEGER       REFERENCES users(user_id),
    processed_at    TIMESTAMP,
    reject_reason   VARCHAR(200)
);

-- 2. 索引
CREATE INDEX IF NOT EXISTS idx_app_reader_status ON borrow_applications(reader_id, status);
CREATE INDEX IF NOT EXISTS idx_app_expires ON borrow_applications(expires_at);

-- 3. 自动过期函数（过期时恢复库存）
CREATE OR REPLACE FUNCTION fn_expire_applications()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT application_id, isbn FROM borrow_applications
        WHERE status = 'pending' AND expires_at < CURRENT_TIMESTAMP
    LOOP
        UPDATE books SET available_copies = available_copies + 1
        WHERE isbn = rec.isbn;
    END LOOP;
    UPDATE borrow_applications
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < CURRENT_TIMESTAMP;
END;
$$;

-- 4. 审批触发器：先恢复预留库存，再创建借阅记录（borrow 触发器会重新扣）
CREATE OR REPLACE FUNCTION fn_approve_application()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        -- 已过期则自动标记
        IF NEW.expires_at < CURRENT_TIMESTAMP THEN
            NEW.status := 'expired';
            UPDATE books SET available_copies = available_copies + 1
            WHERE isbn = NEW.isbn;
            RETURN NEW;
        END IF;
        -- 恢复预留库存（borrow 触发器会重新扣减）
        UPDATE books SET available_copies = available_copies + 1
        WHERE isbn = NEW.isbn;
        -- 创建实际借阅记录（trg_borrow_insert：扣库存 + 计算 due_date + 校验限额）
        INSERT INTO borrow_records (reader_id, isbn, borrow_date)
        VALUES (NEW.reader_id, NEW.isbn, CURRENT_DATE);
        NEW.processed_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_approve_application ON borrow_applications;
CREATE TRIGGER trg_approve_application
    BEFORE UPDATE ON borrow_applications
    FOR EACH ROW
    EXECUTE PROCEDURE fn_approve_application();
