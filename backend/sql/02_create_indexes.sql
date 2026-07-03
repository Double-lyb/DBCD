-- ============================================================
-- 02_create_indexes.sql
-- 高校图书借阅管理系统 — 索引 DDL
-- 共 12 个索引（含 1 个复合索引）
-- ============================================================

-- --------------------------------------------
-- readers 表索引
-- --------------------------------------------
-- 按姓名查询读者（借书时先查读者，支持 LIKE '张%' 前缀匹配）
CREATE INDEX idx_readers_name ON readers(name);

-- 按读者类型筛选（连接 reader_types 查询，统计场景常用）
CREATE INDEX idx_readers_type ON readers(reader_type_id);

-- 按状态筛选（查询活跃/禁用读者）
CREATE INDEX idx_readers_status ON readers(status);

-- --------------------------------------------
-- books 表索引
-- --------------------------------------------
-- 按书名检索（读者/管理员最常用的图书搜索入口）
CREATE INDEX idx_books_title ON books(title);

-- 按作者检索（第二常用的图书查询路径）
CREATE INDEX idx_books_author ON books(author);

-- 按分类浏览（分类统计和前台分类展示）
CREATE INDEX idx_books_category ON books(category);

-- --------------------------------------------
-- borrow_records 表索引
-- --------------------------------------------
-- 按读者查借阅记录（存储过程 sp_get_reader_borrowings 的核心查询条件）
CREATE INDEX idx_borrow_reader_id ON borrow_records(reader_id);

-- 按图书查借阅历史（查询某本书的借阅记录，中频）
CREATE INDEX idx_borrow_isbn ON borrow_records(isbn);

-- 按状态筛选（视图 v_current_borrowings 和 v_overdue_books 依赖此列）
CREATE INDEX idx_borrow_status ON borrow_records(status);

-- 按应还日期查超期（每日超期检测: due_date < CURRENT_DATE AND return_date IS NULL）
CREATE INDEX idx_borrow_due_date ON borrow_records(due_date);

-- ★ 复合索引：覆盖存储过程最核心查询
-- WHERE reader_id = ? AND status = 'borrowed'（或 'overdue'）
-- 复合索引比两个单列索引效率更高，避免回表
CREATE INDEX idx_borrow_reader_status ON borrow_records(reader_id, status);

-- --------------------------------------------
-- operation_logs 表索引
-- --------------------------------------------
-- 按时间倒序查日志（日志查询几乎总是按时间降序，DESC 索引避免额外排序）
CREATE INDEX idx_logs_created_at ON operation_logs(created_at DESC);

-- ============================================================
-- 索引设计说明
-- ============================================================
-- 1. 未在 borrow_records.return_date 上建索引：对 NULL 的过滤
--    使用 status 列已足够，且维护 NULL 索引的代价高于收益。
-- 2. idx_borrow_reader_status 复合索引将 reader_id 放在前、
--    status 放在后，因为 reader_id 的区分度远高于 status。
-- 3. operation_logs 使用 BIGSERIAL 主键，写入优先于查询，
--    仅在审计关键列上建少量索引，避免拖慢写入性能。
-- 4. users.username 已有 UNIQUE 约束，自带索引，无需额外创建。
