-- ============================================================
-- 01_create_tables.sql
-- 高校图书借阅管理系统 — 建表 DDL
-- 数据库: OpenGauss (PostgreSQL 兼容)
-- ============================================================

-- 注意：OpenGauss 5.0 不支持 pgcrypto 扩展
-- 敏感字段（phone/email）加密使用 OpenGauss 原生函数 gs_encrypt_aes128 / gs_decrypt_aes128
-- 在应用层（FastAPI + psycopg2）调用加密函数，加密后的 BYTEA 数据存入对应列

-- ============================================================
-- 1. reader_types（读者类型表）
-- 独立提取以满足 3NF，避免 reader_id → reader_type → max_borrow_count 传递依赖
-- ============================================================
DROP TABLE IF EXISTS reader_types CASCADE;
CREATE TABLE reader_types (
    reader_type_id   SERIAL        PRIMARY KEY,
    type_name        VARCHAR(20)   NOT NULL UNIQUE,
    max_borrow_count INTEGER       NOT NULL CHECK (max_borrow_count > 0),
    borrow_days      INTEGER       NOT NULL CHECK (borrow_days > 0)
);

-- ============================================================
-- 2. readers（读者表）
-- 学号/工号作主键；phone/email 使用 pgcrypto 加密存储
-- ============================================================
DROP TABLE IF EXISTS readers CASCADE;
CREATE TABLE readers (
    reader_id       VARCHAR(20)   PRIMARY KEY
                                  CHECK (reader_id ~ '^[A-Za-z0-9]+$'),
    name            VARCHAR(50)   NOT NULL,
    reader_type_id  INTEGER       NOT NULL REFERENCES reader_types(reader_type_id),
    department      VARCHAR(100)  NOT NULL,
    phone           BYTEA,                         -- pgp_sym_encrypt 加密
    email           BYTEA,                         -- pgp_sym_encrypt 加密
    password_hash   VARCHAR(255)  NOT NULL,        -- bcrypt 哈希
    status          VARCHAR(10)   NOT NULL DEFAULT 'active'
                                  CHECK (status IN ('active', 'disabled')),
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. books（图书表）
-- ISBN 作主键；CHECK 约束保证库存合理性
-- ============================================================
DROP TABLE IF EXISTS books CASCADE;
CREATE TABLE books (
    isbn            VARCHAR(20)   PRIMARY KEY
                                  CHECK (isbn ~ '^[0-9\-]+$'),
    title           VARCHAR(200)  NOT NULL,
    author          VARCHAR(100)  NOT NULL,
    publisher       VARCHAR(100)  NOT NULL,
    total_copies    INTEGER       NOT NULL CHECK (total_copies >= 0),
    available_copies INTEGER      NOT NULL CHECK (available_copies >= 0),
    price           DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    category        VARCHAR(50),
    publish_year    INTEGER,
    location        VARCHAR(50),
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_avail_le_total CHECK (available_copies <= total_copies)
);

-- ============================================================
-- 4. borrow_records（借阅记录表）
-- 借书/还书核心业务表，触发器自动维护 available_copies 和 fine_amount
-- ============================================================
DROP TABLE IF EXISTS borrow_records CASCADE;
CREATE TABLE borrow_records (
    borrow_id       SERIAL        PRIMARY KEY,
    reader_id       VARCHAR(20)   NOT NULL REFERENCES readers(reader_id),
    isbn            VARCHAR(20)   NOT NULL REFERENCES books(isbn),
    borrow_date     DATE          NOT NULL DEFAULT CURRENT_DATE,
    due_date        DATE          NOT NULL,
    return_date     DATE,
    fine_amount     DECIMAL(10,2) DEFAULT 0,
    status          VARCHAR(15)   NOT NULL DEFAULT 'borrowed'
                                  CHECK (status IN ('borrowed', 'returned', 'overdue')),
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_due_after_borrow CHECK (due_date >= borrow_date),
    CONSTRAINT chk_return_after_borrow CHECK (return_date IS NULL OR return_date >= borrow_date)
);

-- ============================================================
-- 5. users（系统用户表）
-- RBAC 三角色：admin / librarian / reader
-- ============================================================
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    user_id         SERIAL        PRIMARY KEY,
    username        VARCHAR(50)   NOT NULL UNIQUE,
    password_hash   VARCHAR(255)  NOT NULL,
    role            VARCHAR(20)   NOT NULL
                                  CHECK (role IN ('admin', 'librarian', 'reader')),
    reader_id       VARCHAR(20)   UNIQUE REFERENCES readers(reader_id),
    status          VARCHAR(10)   NOT NULL DEFAULT 'active'
                                  CHECK (status IN ('active', 'disabled')),
    last_login      TIMESTAMP,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 6. fine_rules（罚金规则表）
-- 独立配置表，支持按时间段调整罚金标准
-- ============================================================
DROP TABLE IF EXISTS fine_rules CASCADE;
CREATE TABLE fine_rules (
    rule_id         SERIAL        PRIMARY KEY,
    fine_per_day    DECIMAL(10,2) NOT NULL CHECK (fine_per_day >= 0),
    effective_from  DATE          NOT NULL,
    effective_to    DATE,
    CONSTRAINT chk_date_range CHECK (effective_to IS NULL OR effective_to > effective_from)
);

-- ============================================================
-- 7. operation_logs（操作日志表）
-- 审计日志，记录所有借阅相关操作，含变更前后数据快照
-- ============================================================
DROP TABLE IF EXISTS operation_logs CASCADE;
CREATE TABLE operation_logs (
    log_id           BIGSERIAL     PRIMARY KEY,
    user_id          INTEGER       REFERENCES users(user_id),
    operation_type   VARCHAR(30)   NOT NULL,
    table_name       VARCHAR(50),
    record_id        VARCHAR(50),
    operation_detail JSONB,
    ip_address       VARCHAR(45),
    created_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 8. backup_records（备份记录表）
-- 追踪每次备份操作，支持恢复验证
-- ============================================================
DROP TABLE IF EXISTS backup_records CASCADE;
CREATE TABLE backup_records (
    backup_id    SERIAL         PRIMARY KEY,
    backup_type  VARCHAR(20)    NOT NULL CHECK (backup_type IN ('full', 'differential')),
    file_path    VARCHAR(500)   NOT NULL,
    file_size    BIGINT,
    backup_date  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       VARCHAR(10)    NOT NULL DEFAULT 'success'
                                CHECK (status IN ('success', 'failed')),
    created_by   INTEGER        REFERENCES users(user_id)
);

-- ============================================================
-- 完成
-- ============================================================
-- 可通过 \dt 查看所有表
-- 可通过 \d+ 表名 查看表结构详情
