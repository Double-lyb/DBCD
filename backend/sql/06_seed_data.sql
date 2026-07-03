-- ============================================================
-- 06_seed_data.sql
-- 高校图书借阅管理系统 — 种子数据
-- ============================================================

-- --------------------------------------------
-- 1. 读者类型（学生 10 本/30 天，教师 15 本/60 天）
-- --------------------------------------------
INSERT INTO reader_types (type_name, max_borrow_count, borrow_days) VALUES
    ('student', 10, 30),
    ('teacher', 15, 60);

-- --------------------------------------------
-- 2. 罚金规则（当前有效：0.5 元/天）
-- --------------------------------------------
INSERT INTO fine_rules (fine_per_day, effective_from) VALUES
    (0.50, '2024-01-01');

-- --------------------------------------------
-- 3. 管理员账号（密码: admin123，bcrypt 哈希）
--    bcrypt hash of 'admin123' — 实际使用时替换为真实哈希值
-- --------------------------------------------
INSERT INTO users (username, password_hash, role) VALUES
    ('admin', '$2b$12$IMrQaLLlXNHJsMFxTphUkOsC.AsH59h/MCxXSXGRhyWulp2f3oGK2', 'admin');

-- --------------------------------------------
-- 4. 示例图书（15 本，涵盖不同分类）
-- --------------------------------------------
INSERT INTO books (isbn, title, author, publisher, total_copies, available_copies, price, category, publish_year, location) VALUES
    ('978-7-111-1', '数据库系统概论（第5版）', '王珊', '高等教育出版社', 5, 5, 39.90, '计算机', 2014, 'A-01-01'),
    ('978-7-302-2', '数据库系统概念（第6版）', 'Abraham Silberschatz', '机械工业出版社', 3, 3, 89.00, '计算机', 2012, 'A-01-02'),
    ('978-7-111-3', '高性能MySQL（第4版）', 'Silvia Botros', '电子工业出版社', 3, 3, 119.00, '计算机', 2022, 'A-01-03'),
    ('978-7-302-4', '深入浅出PostgreSQL', '陈臣', '清华大学出版社', 4, 4, 79.00, '计算机', 2020, 'A-02-01'),
    ('978-7-111-5', '计算机网络：自顶向下方法', 'James Kurose', '机械工业出版社', 5, 5, 89.00, '计算机', 2018, 'A-02-02'),
    ('978-7-302-6', '操作系统概念（第9版）', 'Abraham Silberschatz', '机械工业出版社', 4, 4, 79.00, '计算机', 2018, 'A-02-03'),
    ('978-7-111-7', '数据结构与算法分析', 'Mark Allen Weiss', '机械工业出版社', 5, 5, 69.00, '计算机', 2019, 'B-01-01'),
    ('978-7-302-8', '线性代数及其应用', 'David C. Lay', '机械工业出版社', 4, 4, 65.00, '数学', 2018, 'B-01-02'),
    ('978-7-111-9', '高等数学（第7版）', '同济大学数学系', '高等教育出版社', 6, 6, 49.90, '数学', 2014, 'B-01-03'),
    ('978-7-302-10', '大学物理（第3版）', '张三慧', '清华大学出版社', 4, 4, 55.00, '物理', 2013, 'B-02-01'),
    ('978-7-111-11', '深入理解Java虚拟机', '周志明', '机械工业出版社', 3, 3, 79.00, '计算机', 2019, 'A-03-01'),
    ('978-7-111-12', 'Python编程：从入门到实践', 'Eric Matthes', '人民邮电出版社', 4, 4, 89.00, '计算机', 2020, 'A-03-02'),
    ('978-7-302-13', '机器学习', '周志华', '清华大学出版社', 3, 3, 88.00, '人工智能', 2016, 'C-01-01'),
    ('978-7-111-14', '深度学习', 'Ian Goodfellow', '人民邮电出版社', 2, 2, 168.00, '人工智能', 2017, 'C-01-02'),
    ('978-7-302-15', '英语语法新思维', '张满胜', '清华大学出版社', 3, 3, 45.00, '英语', 2018, 'D-01-01');

-- --------------------------------------------
-- 5. 示例读者（密码均为 reader123，bcrypt 哈希）
--    学生 3 人 + 教师 2 人
-- --------------------------------------------
-- 读者账号（密码: reader123，bcrypt 哈希）
INSERT INTO readers (reader_id, name, reader_type_id, department, password_hash) VALUES
    ('20210001', '张三', 1, '计算机科学与技术学院', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652'),
    ('20210002', '李四', 1, '数学与统计学院', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652'),
    ('20210003', '王五', 1, '物理与电子工程学院', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652'),
    ('T2021001', '赵教授', 2, '计算机科学与技术学院', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652'),
    ('T2021002', '钱教授', 2, '数学与统计学院', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652');

-- 用户登录账号（关联读者，密码: reader123）
INSERT INTO users (username, password_hash, role, reader_id) VALUES
    ('zhangsan', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652', 'reader', '20210001'),
    ('lisi', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652', 'reader', '20210002'),
    ('wangwu', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652', 'reader', '20210003'),
    ('zhaojs', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652', 'reader', 'T2021001'),
    ('qianjs', '$2b$12$4NOTkV5jMmFkOTrQKI7X4eAWLMApuGOGYW/Q5xkM06JCWHZJc5652', 'reader', 'T2021002');

-- --------------------------------------------
-- 6. 示例借阅记录（用于测试）
--    — 张三借了 2 本书（在借中）
--    — 李四借了 1 本已归还
--    — 赵教授借了 3 本（1 本已超期）
-- --------------------------------------------
-- 张三的借阅
INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, status)
VALUES ('20210001', '978-7-111-1', '2026-06-15', '2026-07-15', 'borrowed');

INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, status)
VALUES ('20210001', '978-7-302-2', '2026-06-20', '2026-07-20', 'borrowed');

-- 李四的借阅（已归还）
INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, return_date, status)
VALUES ('20210002', '978-7-111-3', '2026-06-01', '2026-07-01', '2026-06-28', 'returned');

-- 赵教授的借阅（3 本，其中 1 本制造超期场景：借书日期很早，应还日期已过）
INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, status)
VALUES ('T2021001', '978-7-111-5', '2026-04-01', '2026-06-01', 'borrowed'); -- 教师借60天，应还5月31日，已超期

INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, status)
VALUES ('T2021001', '978-7-302-6', '2026-06-10', '2026-07-10', 'borrowed');

INSERT INTO borrow_records (reader_id, isbn, borrow_date, due_date, status)
VALUES ('T2021001', '978-7-111-7', '2026-06-25', '2026-07-25', 'borrowed');

-- ============================================================
-- 种子数据完成
-- 注意: 触发器 05_create_triggers.sql 已先执行，INSERT borrow_records 时：
--   trg_borrow_insert 自动扣减 available_copies、计算 due_date
--   trg_auto_mark_overdue 自动将超期记录标记为 'overdue'
-- 无需手动同步库存
-- ============================================================
