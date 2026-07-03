/*
 Navicat Premium Dump SQL

 Source Server         : DBCD
 Source Server Type    : PostgreSQL
 Source Server Version : 90204 (90204)
 Source Host           : 127.0.0.1:5432
 Source Catalog        : library_db
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 90204 (90204)
 File Encoding         : 65001

 Date: 03/07/2026 16:42:49
*/


-- ----------------------------
-- Sequence structure for backup_records_backup_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."backup_records_backup_id_seq";
CREATE SEQUENCE "public"."backup_records_backup_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for borrow_applications_application_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."borrow_applications_application_id_seq";
CREATE SEQUENCE "public"."borrow_applications_application_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for borrow_records_borrow_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."borrow_records_borrow_id_seq";
CREATE SEQUENCE "public"."borrow_records_borrow_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for fine_rules_rule_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."fine_rules_rule_id_seq";
CREATE SEQUENCE "public"."fine_rules_rule_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for operation_logs_log_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."operation_logs_log_id_seq";
CREATE SEQUENCE "public"."operation_logs_log_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for reader_types_reader_type_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."reader_types_reader_type_id_seq";
CREATE SEQUENCE "public"."reader_types_reader_type_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Sequence structure for users_user_id_seq
-- ----------------------------
DROP SEQUENCE IF EXISTS "public"."users_user_id_seq";
CREATE SEQUENCE "public"."users_user_id_seq" 
INCREMENT 1
MINVALUE  1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

-- ----------------------------
-- Table structure for backup_records
-- ----------------------------
DROP TABLE IF EXISTS "public"."backup_records";
CREATE TABLE "public"."backup_records" (
  "backup_id" int4 NOT NULL DEFAULT nextval('backup_records_backup_id_seq'::regclass),
  "backup_type" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "file_path" varchar(500) COLLATE "pg_catalog"."default" NOT NULL,
  "file_size" int8,
  "backup_date" timestamp(6) NOT NULL DEFAULT pg_systimestamp(),
  "status" varchar(10) COLLATE "pg_catalog"."default" NOT NULL DEFAULT 'success'::character varying,
  "created_by" int4
)
;

-- ----------------------------
-- Records of backup_records
-- ----------------------------

-- ----------------------------
-- Table structure for books
-- ----------------------------
DROP TABLE IF EXISTS "public"."books";
CREATE TABLE "public"."books" (
  "isbn" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "title" varchar(200) COLLATE "pg_catalog"."default" NOT NULL,
  "author" varchar(100) COLLATE "pg_catalog"."default" NOT NULL,
  "publisher" varchar(100) COLLATE "pg_catalog"."default" NOT NULL,
  "total_copies" int4 NOT NULL,
  "available_copies" int4 NOT NULL,
  "price" numeric(10,2) NOT NULL,
  "category" varchar(50) COLLATE "pg_catalog"."default",
  "publish_year" int4,
  "location" varchar(50) COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL DEFAULT pg_systimestamp()
)
;

-- ----------------------------
-- Records of books
-- ----------------------------
INSERT INTO "public"."books" VALUES ('978-7-302-8', '线性代数及其应用', 'David C. Lay', '机械工业出版社', 4, 4, 65.00, '数学', 2018, 'B-01-02', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-302-10', '大学物理（第3版）', '张三慧', '清华大学出版社', 4, 4, 55.00, '物理', 2013, 'B-02-01', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-11', '深入理解Java虚拟机', '周志明', '机械工业出版社', 3, 3, 79.00, '计算机', 2019, 'A-03-01', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-12', 'Python编程：从入门到实践', 'Eric Matthes', '人民邮电出版社', 4, 4, 89.00, '计算机', 2020, 'A-03-02', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-302-13', '机器学习', '周志华', '清华大学出版社', 3, 3, 88.00, '人工智能', 2016, 'C-01-01', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-14', '深度学习', 'Ian Goodfellow', '人民邮电出版社', 2, 2, 168.00, '人工智能', 2017, 'C-01-02', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-5', '计算机网络：自顶向下方法', 'James Kurose', '机械工业出版社', 5, 4, 89.00, '计算机', 2018, 'A-02-02', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-302-6', '操作系统概念（第9版）', 'Abraham Silberschatz', '机械工业出版社', 4, 3, 79.00, '计算机', 2018, 'A-02-03', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-7', '数据结构与算法分析', 'Mark Allen Weiss', '机械工业出版社', 5, 4, 69.00, '计算机', 2019, 'B-01-01', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-1', '数据库系统概论（第5版）', '王珊', '高等教育出版社', 5, 3, 39.90, '计算机', 2014, 'A-01-01', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-302-4', '深入浅出PostgreSQL', '陈臣', '清华大学出版社', 4, 3, 79.00, '计算机', 2020, 'A-02-01', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-3', '高性能MySQL（第4版）', 'Silvia Botros', '电子工业出版社', 3, 3, 119.00, '计算机', 2022, 'A-01-03', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-111-9', '高等数学（第7版）', '同济大学数学系', '高等教育出版社', 6, 5, 49.90, '数学', 2014, 'B-01-03', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-302-15', '英语语法新思维', '张满胜', '清华大学出版社', 3, 2, 45.00, '英语', 2018, 'D-01-01', '2026-07-02 12:11:57.472419');
INSERT INTO "public"."books" VALUES ('978-7-302-2', '数据库系统概念（第6版）', 'Abraham Silberschatz', '机械工业出版社', 3, 1, 89.00, '计算机', 2012, 'A-01-02', '2026-07-02 12:11:57.472419');

-- ----------------------------
-- Table structure for borrow_applications
-- ----------------------------
DROP TABLE IF EXISTS "public"."borrow_applications";
CREATE TABLE "public"."borrow_applications" (
  "application_id" int4 NOT NULL DEFAULT nextval('borrow_applications_application_id_seq'::regclass),
  "reader_id" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "isbn" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "status" varchar(15) COLLATE "pg_catalog"."default" NOT NULL DEFAULT 'pending'::character varying,
  "applied_at" timestamp(6) NOT NULL DEFAULT pg_systimestamp(),
  "expires_at" timestamp(6) NOT NULL DEFAULT (pg_systimestamp() + '06:00:00'::interval),
  "processed_by" int4,
  "processed_at" timestamp(6),
  "reject_reason" varchar(200) COLLATE "pg_catalog"."default"
)
;

-- ----------------------------
-- Records of borrow_applications
-- ----------------------------
INSERT INTO "public"."borrow_applications" VALUES (1, '2023217480', '978-7-111-1', 'rejected', '2026-07-03 05:03:37.902406', '2026-07-04 05:03:37.902406', 1, '2026-07-03 05:04:34.278081', '图书暂时维护中');
INSERT INTO "public"."borrow_applications" VALUES (2, '2023217480', '978-7-302-2', 'approved', '2026-07-03 05:05:00.368251', '2026-07-04 05:05:00.368251', 1, '2026-07-03 05:05:35.826794', NULL);
INSERT INTO "public"."borrow_applications" VALUES (3, '2023217457', '978-7-111-9', 'approved', '2026-07-03 05:09:02.720551', '2026-07-04 05:09:02.720551', 1, '2026-07-03 05:26:15.03866', NULL);
INSERT INTO "public"."borrow_applications" VALUES (4, '2023217457', '978-7-302-15', 'approved', '2026-07-03 05:09:10.937165', '2026-07-04 05:09:10.937165', 1, '2026-07-03 05:26:30.34865', NULL);

-- ----------------------------
-- Table structure for borrow_records
-- ----------------------------
DROP TABLE IF EXISTS "public"."borrow_records";
CREATE TABLE "public"."borrow_records" (
  "borrow_id" int4 NOT NULL DEFAULT nextval('borrow_records_borrow_id_seq'::regclass),
  "reader_id" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "isbn" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "borrow_date" date NOT NULL DEFAULT text_date('now'::text),
  "due_date" date NOT NULL,
  "return_date" date,
  "fine_amount" numeric(10,2) DEFAULT 0,
  "status" varchar(15) COLLATE "pg_catalog"."default" NOT NULL DEFAULT 'borrowed'::character varying,
  "created_at" timestamp(6) NOT NULL DEFAULT pg_systimestamp()
)
;

-- ----------------------------
-- Records of borrow_records
-- ----------------------------
INSERT INTO "public"."borrow_records" VALUES (1, '20210001', '978-7-111-1', '2026-06-15', '2026-07-15', NULL, 0.00, 'borrowed', '2026-07-02 12:11:57.518456');
INSERT INTO "public"."borrow_records" VALUES (2, '20210001', '978-7-302-2', '2026-06-20', '2026-07-20', NULL, 0.00, 'borrowed', '2026-07-02 12:11:57.570486');
INSERT INTO "public"."borrow_records" VALUES (3, '20210002', '978-7-111-3', '2026-06-01', '2026-07-01', '2026-06-28', 0.00, 'returned', '2026-07-02 12:11:57.572087');
INSERT INTO "public"."borrow_records" VALUES (4, 'T2021001', '978-7-111-5', '2026-04-01', '2026-05-31', NULL, 0.00, 'overdue', '2026-07-02 12:11:57.572791');
INSERT INTO "public"."borrow_records" VALUES (5, 'T2021001', '978-7-302-6', '2026-06-10', '2026-08-09', NULL, 0.00, 'borrowed', '2026-07-02 12:11:57.573527');
INSERT INTO "public"."borrow_records" VALUES (6, 'T2021001', '978-7-111-7', '2026-06-25', '2026-08-24', NULL, 0.00, 'borrowed', '2026-07-02 12:11:57.574131');
INSERT INTO "public"."borrow_records" VALUES (7, '20210003', '978-7-111-9', '2026-07-02', '2026-08-01', '2026-07-05', 0.00, 'returned', '2026-07-02 12:12:25.158487');
INSERT INTO "public"."borrow_records" VALUES (8, '20210001', '978-7-111-1', '2026-07-10', '2026-08-09', NULL, 0.00, 'overdue', '2026-07-02 12:12:25.196841');
INSERT INTO "public"."borrow_records" VALUES (10, '2023217480', '978-7-302-4', '2026-07-02', '2026-08-01', NULL, 0.00, 'borrowed', '2026-07-02 13:59:08.112161');
INSERT INTO "public"."borrow_records" VALUES (9, '2023217480', '978-7-302-4', '2026-07-02', '2026-08-01', '2026-07-03', 0.00, 'returned', '2026-07-02 13:55:45.107256');
INSERT INTO "public"."borrow_records" VALUES (11, '2023217480', '978-7-302-2', '2026-07-03', '2026-08-02', NULL, 0.00, 'borrowed', '2026-07-03 05:05:35.815535');
INSERT INTO "public"."borrow_records" VALUES (12, '2023217457', '978-7-111-9', '2026-07-03', '2026-08-02', NULL, 0.00, 'borrowed', '2026-07-03 05:26:15.016841');
INSERT INTO "public"."borrow_records" VALUES (13, '2023217457', '978-7-302-15', '2026-07-03', '2026-08-02', NULL, 0.00, 'borrowed', '2026-07-03 05:26:30.346802');

-- ----------------------------
-- Table structure for fine_rules
-- ----------------------------
DROP TABLE IF EXISTS "public"."fine_rules";
CREATE TABLE "public"."fine_rules" (
  "rule_id" int4 NOT NULL DEFAULT nextval('fine_rules_rule_id_seq'::regclass),
  "fine_per_day" numeric(10,2) NOT NULL,
  "effective_from" date NOT NULL,
  "effective_to" date
)
;

-- ----------------------------
-- Records of fine_rules
-- ----------------------------
INSERT INTO "public"."fine_rules" VALUES (1, .50, '2024-01-01', NULL);

-- ----------------------------
-- Table structure for operation_logs
-- ----------------------------
DROP TABLE IF EXISTS "public"."operation_logs";
CREATE TABLE "public"."operation_logs" (
  "log_id" int8 NOT NULL DEFAULT nextval('operation_logs_log_id_seq'::regclass),
  "user_id" int4,
  "operation_type" varchar(30) COLLATE "pg_catalog"."default" NOT NULL,
  "table_name" varchar(50) COLLATE "pg_catalog"."default",
  "record_id" varchar(50) COLLATE "pg_catalog"."default",
  "operation_detail" jsonb,
  "ip_address" varchar(45) COLLATE "pg_catalog"."default",
  "created_at" timestamp(6) NOT NULL DEFAULT pg_systimestamp()
)
;

-- ----------------------------
-- Records of operation_logs
-- ----------------------------
INSERT INTO "public"."operation_logs" VALUES (1, NULL, 'INSERT', 'borrow_records', '1', NULL, NULL, '2026-07-02 12:11:57.555735');
INSERT INTO "public"."operation_logs" VALUES (2, NULL, 'INSERT', 'borrow_records', '2', NULL, NULL, '2026-07-02 12:11:57.571798');
INSERT INTO "public"."operation_logs" VALUES (3, NULL, 'INSERT', 'borrow_records', '3', NULL, NULL, '2026-07-02 12:11:57.572607');
INSERT INTO "public"."operation_logs" VALUES (4, NULL, 'INSERT', 'borrow_records', '4', NULL, NULL, '2026-07-02 12:11:57.573367');
INSERT INTO "public"."operation_logs" VALUES (5, NULL, 'INSERT', 'borrow_records', '5', NULL, NULL, '2026-07-02 12:11:57.573971');
INSERT INTO "public"."operation_logs" VALUES (6, NULL, 'INSERT', 'borrow_records', '6', NULL, NULL, '2026-07-02 12:11:57.574571');
INSERT INTO "public"."operation_logs" VALUES (7, NULL, 'INSERT', 'borrow_records', '7', NULL, NULL, '2026-07-02 12:12:25.166105');
INSERT INTO "public"."operation_logs" VALUES (8, NULL, 'UPDATE', 'borrow_records', '7', NULL, NULL, '2026-07-02 12:12:25.184727');
INSERT INTO "public"."operation_logs" VALUES (9, NULL, 'INSERT', 'borrow_records', '8', NULL, NULL, '2026-07-02 12:12:25.198041');
INSERT INTO "public"."operation_logs" VALUES (10, NULL, 'INSERT', 'borrow_records', '9', NULL, NULL, '2026-07-02 13:55:45.117252');
INSERT INTO "public"."operation_logs" VALUES (11, NULL, 'INSERT', 'borrow_records', '10', NULL, NULL, '2026-07-02 13:59:08.115512');
INSERT INTO "public"."operation_logs" VALUES (12, NULL, 'UPDATE', 'borrow_records', '9', NULL, NULL, '2026-07-03 05:01:05.828276');
INSERT INTO "public"."operation_logs" VALUES (13, NULL, 'INSERT', 'borrow_records', '11', NULL, NULL, '2026-07-03 05:05:35.826794');
INSERT INTO "public"."operation_logs" VALUES (14, NULL, 'INSERT', 'borrow_records', '12', NULL, NULL, '2026-07-03 05:26:15.03866');
INSERT INTO "public"."operation_logs" VALUES (15, NULL, 'INSERT', 'borrow_records', '13', NULL, NULL, '2026-07-03 05:26:30.34865');

-- ----------------------------
-- Table structure for reader_types
-- ----------------------------
DROP TABLE IF EXISTS "public"."reader_types";
CREATE TABLE "public"."reader_types" (
  "reader_type_id" int4 NOT NULL DEFAULT nextval('reader_types_reader_type_id_seq'::regclass),
  "type_name" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "max_borrow_count" int4 NOT NULL,
  "borrow_days" int4 NOT NULL
)
;

-- ----------------------------
-- Records of reader_types
-- ----------------------------
INSERT INTO "public"."reader_types" VALUES (1, 'student', 10, 30);
INSERT INTO "public"."reader_types" VALUES (2, 'teacher', 15, 60);

-- ----------------------------
-- Table structure for readers
-- ----------------------------
DROP TABLE IF EXISTS "public"."readers";
CREATE TABLE "public"."readers" (
  "reader_id" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "name" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "reader_type_id" int4 NOT NULL,
  "department" varchar(100) COLLATE "pg_catalog"."default" NOT NULL,
  "phone" bytea,
  "email" bytea,
  "password_hash" varchar(255) COLLATE "pg_catalog"."default" NOT NULL,
  "status" varchar(10) COLLATE "pg_catalog"."default" NOT NULL DEFAULT 'active'::character varying,
  "created_at" timestamp(6) NOT NULL DEFAULT pg_systimestamp()
)
;

-- ----------------------------
-- Records of readers
-- ----------------------------
INSERT INTO "public"."readers" VALUES ('20210001', '张三', 1, '计算机科学与技术学院', NULL, NULL, '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'active', '2026-07-02 12:11:57.496186');
INSERT INTO "public"."readers" VALUES ('20210002', '李四', 1, '数学与统计学院', NULL, NULL, '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'active', '2026-07-02 12:11:57.496186');
INSERT INTO "public"."readers" VALUES ('20210003', '王五', 1, '物理与电子工程学院', NULL, NULL, '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'active', '2026-07-02 12:11:57.496186');
INSERT INTO "public"."readers" VALUES ('T2021001', '赵教授', 2, '计算机科学与技术学院', NULL, NULL, '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'active', '2026-07-02 12:11:57.496186');
INSERT INTO "public"."readers" VALUES ('T2021002', '钱教授', 2, '数学与统计学院', NULL, NULL, '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'active', '2026-07-02 12:11:57.496186');
INSERT INTO "public"."readers" VALUES ('2023217480', '刘奕博', 1, '计算机与信息学院', NULL, NULL, '$2b$12$YHrIJG52RH/eiKSP2EOg3Oe5z5u/9dWiCYZqmQPsREzu4cGNmagPO', 'active', '2026-07-02 13:26:59.734587');
INSERT INTO "public"."readers" VALUES ('2023217457', '张尚昆', 1, '计算机与信息学院', NULL, NULL, '$2b$12$IMkVJivPrgWVp5ENJ0JhAuoxPvbU9Wqps6hJXXBCenJC8Ivgmiv0y', 'active', '2026-07-03 05:08:07.86961');

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS "public"."users";
CREATE TABLE "public"."users" (
  "user_id" int4 NOT NULL DEFAULT nextval('users_user_id_seq'::regclass),
  "username" varchar(50) COLLATE "pg_catalog"."default" NOT NULL,
  "password_hash" varchar(255) COLLATE "pg_catalog"."default" NOT NULL,
  "role" varchar(20) COLLATE "pg_catalog"."default" NOT NULL,
  "reader_id" varchar(20) COLLATE "pg_catalog"."default",
  "status" varchar(10) COLLATE "pg_catalog"."default" NOT NULL DEFAULT 'active'::character varying,
  "last_login" timestamp(6),
  "created_at" timestamp(6) NOT NULL DEFAULT pg_systimestamp()
)
;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO "public"."users" VALUES (2, 'zhangsan', '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'reader', '20210001', 'active', NULL, '2026-07-02 12:11:57.517248');
INSERT INTO "public"."users" VALUES (3, 'lisi', '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'reader', '20210002', 'active', NULL, '2026-07-02 12:11:57.517248');
INSERT INTO "public"."users" VALUES (4, 'wangwu', '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'reader', '20210003', 'active', NULL, '2026-07-02 12:11:57.517248');
INSERT INTO "public"."users" VALUES (5, 'zhaojs', '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'reader', 'T2021001', 'active', NULL, '2026-07-02 12:11:57.517248');
INSERT INTO "public"."users" VALUES (6, 'qianjs', '$2b$12$LJ3m4ys3GZfnYKpVkGdZkeX1HcOyF5vJw5XNxO8nKfFtFbDZqYx5y', 'reader', 'T2021002', 'active', NULL, '2026-07-02 12:11:57.517248');
INSERT INTO "public"."users" VALUES (7, '2023217480', '$2b$12$YHrIJG52RH/eiKSP2EOg3Oe5z5u/9dWiCYZqmQPsREzu4cGNmagPO', 'reader', '2023217480', 'active', NULL, '2026-07-02 13:26:59.815587');
INSERT INTO "public"."users" VALUES (1, 'admin', '$2b$12$4qLu1ktM9AuxsWfv0TsRZuj2JpQuzR0HtWIStJgt7oooQ.jOnXLcG', 'admin', NULL, 'active', NULL, '2026-07-02 12:11:57.45173');
INSERT INTO "public"."users" VALUES (8, '2023217457', '$2b$12$IMkVJivPrgWVp5ENJ0JhAuoxPvbU9Wqps6hJXXBCenJC8Ivgmiv0y', 'reader', '2023217457', 'active', NULL, '2026-07-03 05:08:07.962459');

-- ----------------------------
-- Function structure for fn_approve_application
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."fn_approve_application"();
CREATE FUNCTION "public"."fn_approve_application"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
BEGIN
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        IF NEW.expires_at < CURRENT_TIMESTAMP THEN
            NEW.status := 'expired';
            UPDATE books SET available_copies = available_copies + 1
            WHERE isbn = NEW.isbn AND available_copies < total_copies;
            RETURN NEW;
        END IF;
        -- 恢复预留库存（安全上限）
        UPDATE books SET available_copies = available_copies + 1
        WHERE isbn = NEW.isbn AND available_copies < total_copies;
        -- 创建借阅记录
        INSERT INTO borrow_records (reader_id, isbn, borrow_date)
        VALUES (NEW.reader_id, NEW.isbn, CURRENT_DATE);
        NEW.processed_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for fn_calculate_overdue_fine
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."fn_calculate_overdue_fine"("p_borrow_id" int4);
CREATE FUNCTION "public"."fn_calculate_overdue_fine"("p_borrow_id" int4)
  RETURNS "pg_catalog"."numeric" AS $BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for fn_can_borrow
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."fn_can_borrow"("p_reader_id" varchar);
CREATE FUNCTION "public"."fn_can_borrow"("p_reader_id" varchar)
  RETURNS "pg_catalog"."bool" AS $BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for fn_expire_applications
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."fn_expire_applications"();
CREATE FUNCTION "public"."fn_expire_applications"()
  RETURNS "pg_catalog"."void" AS $BODY$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT application_id, isbn FROM borrow_applications
        WHERE status = 'pending' AND expires_at < CURRENT_TIMESTAMP
    LOOP
        -- 安全上限：库存不会超过总量
        UPDATE books SET available_copies = available_copies + 1
        WHERE isbn = rec.isbn AND available_copies < total_copies;
    END LOOP;
    UPDATE borrow_applications
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < CURRENT_TIMESTAMP;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for fn_get_reader_current_borrow_count
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."fn_get_reader_current_borrow_count"("p_reader_id" varchar);
CREATE FUNCTION "public"."fn_get_reader_current_borrow_count"("p_reader_id" varchar)
  RETURNS "pg_catalog"."int4" AS $BODY$
    SELECT COUNT(*)::INTEGER
    FROM borrow_records
    WHERE reader_id = p_reader_id
      AND return_date IS NULL;
$BODY$
  LANGUAGE sql STABLE
  COST 100;

-- ----------------------------
-- Function structure for func_auto_mark_overdue
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_auto_mark_overdue"();
CREATE FUNCTION "public"."func_auto_mark_overdue"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
BEGIN
    IF NEW.due_date < CURRENT_DATE
       AND NEW.return_date IS NULL
       AND NEW.status = 'borrowed' THEN
        NEW.status := 'overdue';
    END IF;
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for func_borrow_insert
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_borrow_insert"();
CREATE FUNCTION "public"."func_borrow_insert"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for func_borrow_operation_log
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_borrow_operation_log"();
CREATE FUNCTION "public"."func_borrow_operation_log"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for func_borrow_update_return
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_borrow_update_return"();
CREATE FUNCTION "public"."func_borrow_update_return"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for func_prevent_book_delete
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_prevent_book_delete"();
CREATE FUNCTION "public"."func_prevent_book_delete"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for func_t3
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_t3"();
CREATE FUNCTION "public"."func_t3"()
  RETURNS "pg_catalog"."trigger" AS $BODY$BEGIN RETURN NEW; END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for func_test_trg
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_test_trg"();
CREATE FUNCTION "public"."func_test_trg"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
BEGIN
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for func_test_trg2
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."func_test_trg2"();
CREATE FUNCTION "public"."func_test_trg2"()
  RETURNS "pg_catalog"."trigger" AS $BODY$
BEGIN
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- ----------------------------
-- Function structure for sp_get_reader_borrowings
-- ----------------------------
DROP FUNCTION IF EXISTS "public"."sp_get_reader_borrowings"("p_reader_id" varchar);
CREATE FUNCTION "public"."sp_get_reader_borrowings"("p_reader_id" varchar)
  RETURNS TABLE("borrow_id" int4, "isbn" varchar, "title" varchar, "author" varchar, "publisher" varchar, "borrow_date" date, "due_date" date, "overdue_days" int4, "estimated_fine" numeric, "status" varchar) AS $BODY$
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
            CASE WHEN br.due_date < CURRENT_DATE
                 THEN (CURRENT_DATE - br.due_date)::INTEGER ELSE 0 END,
            CASE WHEN br.due_date < CURRENT_DATE
                 THEN (CURRENT_DATE - br.due_date)::INTEGER
                      * COALESCE((SELECT fine_per_day FROM fine_rules
                                  WHERE effective_to IS NULL
                                  ORDER BY effective_from DESC LIMIT 1), 0.50)
                 ELSE 0 END,
            br.status
        FROM borrow_records br
        JOIN books b ON br.isbn = b.isbn
        WHERE br.reader_id = p_reader_id
          AND br.return_date IS NULL
        ORDER BY br.due_date ASC;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

-- ----------------------------
-- View structure for v_current_borrowings
-- ----------------------------
DROP VIEW IF EXISTS "public"."v_current_borrowings";
CREATE VIEW "public"."v_current_borrowings" AS  SELECT br.borrow_id, br.reader_id, r.name AS reader_name, 
    rt.type_name AS reader_type, r.department, br.isbn, b.title, b.author, 
    br.borrow_date, br.due_date, 
        CASE
            WHEN br.due_date < text_date('now'::text) THEN text_date('now'::text) - br.due_date
            ELSE 0
        END AS overdue_days, 
    br.status
   FROM borrow_records br
   JOIN readers r ON br.reader_id::text = r.reader_id::text
   JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
   JOIN books b ON br.isbn::text = b.isbn::text
  WHERE br.return_date IS NULL
  ORDER BY br.due_date;

-- ----------------------------
-- View structure for v_overdue_books
-- ----------------------------
DROP VIEW IF EXISTS "public"."v_overdue_books";
CREATE VIEW "public"."v_overdue_books" AS  SELECT br.borrow_id, br.reader_id, r.name AS reader_name, 
    rt.type_name AS reader_type, r.department, r.phone, r.email, br.isbn, 
    b.title, b.author, br.borrow_date, br.due_date, 
    text_date('now'::text) - br.due_date AS overdue_days, br.fine_amount
   FROM borrow_records br
   JOIN readers r ON br.reader_id::text = r.reader_id::text
   JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
   JOIN books b ON br.isbn::text = b.isbn::text
  WHERE br.return_date IS NULL AND br.due_date < text_date('now'::text)
  ORDER BY text_date('now'::text) - br.due_date DESC;

-- ----------------------------
-- View structure for v_reader_borrowing_stats
-- ----------------------------
DROP VIEW IF EXISTS "public"."v_reader_borrowing_stats";
CREATE VIEW "public"."v_reader_borrowing_stats" AS  SELECT r.reader_id, r.name, rt.type_name AS reader_type, r.department, 
    count(
        CASE
            WHEN br.return_date IS NULL THEN br.borrow_id
            ELSE NULL::integer
        END) AS current_borrow_count, 
    count(br.borrow_id) AS total_borrow_count, 
    COALESCE(sum(br.fine_amount), 0::numeric) AS total_fine, 
    COALESCE(max(br.fine_amount), 0::numeric) AS max_single_fine, 
    COALESCE(avg(
        CASE
            WHEN br.fine_amount > 0::numeric THEN br.fine_amount
            ELSE NULL::numeric
        END), 0::numeric) AS avg_fine
   FROM readers r
   JOIN reader_types rt ON r.reader_type_id = rt.reader_type_id
   LEFT JOIN borrow_records br ON r.reader_id::text = br.reader_id::text
  GROUP BY r.reader_id, r.name, rt.type_name, r.department;

-- ----------------------------
-- View structure for v_book_inventory_stats
-- ----------------------------
DROP VIEW IF EXISTS "public"."v_book_inventory_stats";
CREATE VIEW "public"."v_book_inventory_stats" AS  SELECT b.isbn, b.title, b.author, b.publisher, b.total_copies, 
    b.available_copies, count(br.borrow_id) AS total_borrow_times, 
    count(
        CASE
            WHEN br.return_date IS NULL THEN br.borrow_id
            ELSE NULL::integer
        END) AS current_borrowed, 
    COALESCE(min(b.price), 0::numeric) AS unit_price
   FROM books b
   LEFT JOIN borrow_records br ON b.isbn::text = br.isbn::text
  GROUP BY b.isbn, b.title, b.author, b.publisher, b.total_copies, b.available_copies;

-- ----------------------------
-- View structure for v_monthly_fine_summary
-- ----------------------------
DROP VIEW IF EXISTS "public"."v_monthly_fine_summary";
CREATE VIEW "public"."v_monthly_fine_summary" AS  SELECT date_trunc('month'::text, br.return_date::timestamp with time zone)::date AS month, 
    count(br.borrow_id) AS overdue_count, 
    COALESCE(sum(br.fine_amount), 0::numeric) AS total_fine, 
    COALESCE(avg(br.fine_amount), 0::numeric) AS avg_fine_per_record, 
    COALESCE(max(br.fine_amount), 0::numeric) AS max_fine
   FROM borrow_records br
  WHERE br.fine_amount > 0::numeric AND br.return_date IS NOT NULL
  GROUP BY date_trunc('month'::text, br.return_date::timestamp with time zone)::date
  ORDER BY date_trunc('month'::text, br.return_date::timestamp with time zone)::date DESC;

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."backup_records_backup_id_seq"
OWNED BY "public"."backup_records"."backup_id";
SELECT setval('"public"."backup_records_backup_id_seq"', 1, false);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."borrow_applications_application_id_seq"
OWNED BY "public"."borrow_applications"."application_id";
SELECT setval('"public"."borrow_applications_application_id_seq"', 5, true);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."borrow_records_borrow_id_seq"
OWNED BY "public"."borrow_records"."borrow_id";
SELECT setval('"public"."borrow_records_borrow_id_seq"', 13, true);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."fine_rules_rule_id_seq"
OWNED BY "public"."fine_rules"."rule_id";
SELECT setval('"public"."fine_rules_rule_id_seq"', 1, true);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."operation_logs_log_id_seq"
OWNED BY "public"."operation_logs"."log_id";
SELECT setval('"public"."operation_logs_log_id_seq"', 15, true);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."reader_types_reader_type_id_seq"
OWNED BY "public"."reader_types"."reader_type_id";
SELECT setval('"public"."reader_types_reader_type_id_seq"', 2, true);

-- ----------------------------
-- Alter sequences owned by
-- ----------------------------
ALTER SEQUENCE "public"."users_user_id_seq"
OWNED BY "public"."users"."user_id";
SELECT setval('"public"."users_user_id_seq"', 8, true);

-- ----------------------------
-- Checks structure for table backup_records
-- ----------------------------
ALTER TABLE "public"."backup_records" ADD CONSTRAINT "backup_records_status_check" CHECK (((status)::text = ANY ((ARRAY['success'::character varying, 'failed'::character varying])::text[])));
ALTER TABLE "public"."backup_records" ADD CONSTRAINT "backup_records_backup_type_check" CHECK (((backup_type)::text = ANY ((ARRAY['full'::character varying, 'differential'::character varying])::text[])));

-- ----------------------------
-- Primary Key structure for table backup_records
-- ----------------------------
ALTER TABLE "public"."backup_records" ADD CONSTRAINT "backup_records_pkey" PRIMARY KEY ("backup_id");

-- ----------------------------
-- Indexes structure for table books
-- ----------------------------
CREATE INDEX "idx_books_author" ON "public"."books" USING btree (
  "author" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_books_category" ON "public"."books" USING btree (
  "category" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_books_title" ON "public"."books" USING btree (
  "title" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Triggers structure for table books
-- ----------------------------
CREATE TRIGGER "trg_prevent_book_delete" BEFORE DELETE ON "public"."books"
FOR EACH ROW
EXECUTE PROCEDURE "public"."func_prevent_book_delete"();

-- ----------------------------
-- Checks structure for table books
-- ----------------------------
ALTER TABLE "public"."books" ADD CONSTRAINT "chk_avail_le_total" CHECK ((available_copies <= total_copies));
ALTER TABLE "public"."books" ADD CONSTRAINT "books_price_check" CHECK ((price >= (0)::numeric));
ALTER TABLE "public"."books" ADD CONSTRAINT "books_available_copies_check" CHECK ((available_copies >= 0));
ALTER TABLE "public"."books" ADD CONSTRAINT "books_total_copies_check" CHECK ((total_copies >= 0));
ALTER TABLE "public"."books" ADD CONSTRAINT "books_isbn_check" CHECK (((isbn)::text ~ '^[0-9\-]+$'::text));

-- ----------------------------
-- Primary Key structure for table books
-- ----------------------------
ALTER TABLE "public"."books" ADD CONSTRAINT "books_pkey" PRIMARY KEY ("isbn");

-- ----------------------------
-- Indexes structure for table borrow_applications
-- ----------------------------
CREATE INDEX "idx_app_expires" ON "public"."borrow_applications" USING btree (
  "expires_at" "pg_catalog"."timestamp_ops" ASC NULLS LAST
);

-- ----------------------------
-- Triggers structure for table borrow_applications
-- ----------------------------
CREATE TRIGGER "trg_approve_application" BEFORE UPDATE ON "public"."borrow_applications"
FOR EACH ROW
EXECUTE PROCEDURE "public"."fn_approve_application"();

-- ----------------------------
-- Checks structure for table borrow_applications
-- ----------------------------
ALTER TABLE "public"."borrow_applications" ADD CONSTRAINT "borrow_applications_status_check" CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'expired'::character varying])::text[])));

-- ----------------------------
-- Primary Key structure for table borrow_applications
-- ----------------------------
ALTER TABLE "public"."borrow_applications" ADD CONSTRAINT "borrow_applications_pkey" PRIMARY KEY ("application_id");

-- ----------------------------
-- Indexes structure for table borrow_records
-- ----------------------------
CREATE INDEX "idx_borrow_due_date" ON "public"."borrow_records" USING btree (
  "due_date" "pg_catalog"."date_ops" ASC NULLS LAST
);
CREATE INDEX "idx_borrow_isbn" ON "public"."borrow_records" USING btree (
  "isbn" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_borrow_reader_id" ON "public"."borrow_records" USING btree (
  "reader_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_borrow_reader_status" ON "public"."borrow_records" USING btree (
  "reader_id" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST,
  "status" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_borrow_status" ON "public"."borrow_records" USING btree (
  "status" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);

-- ----------------------------
-- Triggers structure for table borrow_records
-- ----------------------------
CREATE TRIGGER "trg_auto_mark_overdue" BEFORE INSERT OR UPDATE ON "public"."borrow_records"
FOR EACH ROW
EXECUTE PROCEDURE "public"."func_auto_mark_overdue"();
CREATE TRIGGER "trg_borrow_insert" BEFORE INSERT ON "public"."borrow_records"
FOR EACH ROW
EXECUTE PROCEDURE "public"."func_borrow_insert"();
CREATE TRIGGER "trg_borrow_update_return" BEFORE UPDATE ON "public"."borrow_records"
FOR EACH ROW
EXECUTE PROCEDURE "public"."func_borrow_update_return"();
CREATE TRIGGER "trg_operation_log" AFTER INSERT OR UPDATE OR DELETE ON "public"."borrow_records"
FOR EACH ROW
EXECUTE PROCEDURE "public"."func_borrow_operation_log"();

-- ----------------------------
-- Checks structure for table borrow_records
-- ----------------------------
ALTER TABLE "public"."borrow_records" ADD CONSTRAINT "chk_return_after_borrow" CHECK (((return_date IS NULL) OR (return_date >= borrow_date)));
ALTER TABLE "public"."borrow_records" ADD CONSTRAINT "chk_due_after_borrow" CHECK ((due_date >= borrow_date));
ALTER TABLE "public"."borrow_records" ADD CONSTRAINT "borrow_records_status_check" CHECK (((status)::text = ANY ((ARRAY['borrowed'::character varying, 'returned'::character varying, 'overdue'::character varying])::text[])));

-- ----------------------------
-- Primary Key structure for table borrow_records
-- ----------------------------
ALTER TABLE "public"."borrow_records" ADD CONSTRAINT "borrow_records_pkey" PRIMARY KEY ("borrow_id");

-- ----------------------------
-- Checks structure for table fine_rules
-- ----------------------------
ALTER TABLE "public"."fine_rules" ADD CONSTRAINT "chk_date_range" CHECK (((effective_to IS NULL) OR (effective_to > effective_from)));
ALTER TABLE "public"."fine_rules" ADD CONSTRAINT "fine_rules_fine_per_day_check" CHECK ((fine_per_day >= (0)::numeric));

-- ----------------------------
-- Primary Key structure for table fine_rules
-- ----------------------------
ALTER TABLE "public"."fine_rules" ADD CONSTRAINT "fine_rules_pkey" PRIMARY KEY ("rule_id");

-- ----------------------------
-- Indexes structure for table operation_logs
-- ----------------------------
CREATE INDEX "idx_logs_created_at" ON "public"."operation_logs" USING btree (
  "created_at" "pg_catalog"."timestamp_ops" DESC NULLS FIRST
);

-- ----------------------------
-- Primary Key structure for table operation_logs
-- ----------------------------
ALTER TABLE "public"."operation_logs" ADD CONSTRAINT "operation_logs_pkey" PRIMARY KEY ("log_id");

-- ----------------------------
-- Uniques structure for table reader_types
-- ----------------------------
ALTER TABLE "public"."reader_types" ADD CONSTRAINT "reader_types_type_name_key" UNIQUE ("type_name");

-- ----------------------------
-- Checks structure for table reader_types
-- ----------------------------
ALTER TABLE "public"."reader_types" ADD CONSTRAINT "reader_types_borrow_days_check" CHECK ((borrow_days > 0));
ALTER TABLE "public"."reader_types" ADD CONSTRAINT "reader_types_max_borrow_count_check" CHECK ((max_borrow_count > 0));

-- ----------------------------
-- Primary Key structure for table reader_types
-- ----------------------------
ALTER TABLE "public"."reader_types" ADD CONSTRAINT "reader_types_pkey" PRIMARY KEY ("reader_type_id");

-- ----------------------------
-- Indexes structure for table readers
-- ----------------------------
CREATE INDEX "idx_readers_name" ON "public"."readers" USING btree (
  "name" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_readers_status" ON "public"."readers" USING btree (
  "status" COLLATE "pg_catalog"."default" "pg_catalog"."text_ops" ASC NULLS LAST
);
CREATE INDEX "idx_readers_type" ON "public"."readers" USING btree (
  "reader_type_id" "pg_catalog"."int4_ops" ASC NULLS LAST
);

-- ----------------------------
-- Checks structure for table readers
-- ----------------------------
ALTER TABLE "public"."readers" ADD CONSTRAINT "readers_status_check" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'disabled'::character varying])::text[])));
ALTER TABLE "public"."readers" ADD CONSTRAINT "readers_reader_id_check" CHECK (((reader_id)::text ~ '^[A-Za-z0-9]+$'::text));

-- ----------------------------
-- Primary Key structure for table readers
-- ----------------------------
ALTER TABLE "public"."readers" ADD CONSTRAINT "readers_pkey" PRIMARY KEY ("reader_id");

-- ----------------------------
-- Uniques structure for table users
-- ----------------------------
ALTER TABLE "public"."users" ADD CONSTRAINT "users_username_key" UNIQUE ("username");
ALTER TABLE "public"."users" ADD CONSTRAINT "users_reader_id_key" UNIQUE ("reader_id");

-- ----------------------------
-- Checks structure for table users
-- ----------------------------
ALTER TABLE "public"."users" ADD CONSTRAINT "users_status_check" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'disabled'::character varying])::text[])));
ALTER TABLE "public"."users" ADD CONSTRAINT "users_role_check" CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'librarian'::character varying, 'reader'::character varying])::text[])));

-- ----------------------------
-- Primary Key structure for table users
-- ----------------------------
ALTER TABLE "public"."users" ADD CONSTRAINT "users_pkey" PRIMARY KEY ("user_id");

-- ----------------------------
-- Foreign Keys structure for table backup_records
-- ----------------------------
ALTER TABLE "public"."backup_records" ADD CONSTRAINT "backup_records_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users" ("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table borrow_applications
-- ----------------------------
ALTER TABLE "public"."borrow_applications" ADD CONSTRAINT "borrow_applications_isbn_fkey" FOREIGN KEY ("isbn") REFERENCES "public"."books" ("isbn") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "public"."borrow_applications" ADD CONSTRAINT "borrow_applications_processed_by_fkey" FOREIGN KEY ("processed_by") REFERENCES "public"."users" ("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "public"."borrow_applications" ADD CONSTRAINT "borrow_applications_reader_id_fkey" FOREIGN KEY ("reader_id") REFERENCES "public"."readers" ("reader_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table borrow_records
-- ----------------------------
ALTER TABLE "public"."borrow_records" ADD CONSTRAINT "borrow_records_isbn_fkey" FOREIGN KEY ("isbn") REFERENCES "public"."books" ("isbn") ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE "public"."borrow_records" ADD CONSTRAINT "borrow_records_reader_id_fkey" FOREIGN KEY ("reader_id") REFERENCES "public"."readers" ("reader_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table operation_logs
-- ----------------------------
ALTER TABLE "public"."operation_logs" ADD CONSTRAINT "operation_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users" ("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table readers
-- ----------------------------
ALTER TABLE "public"."readers" ADD CONSTRAINT "readers_reader_type_id_fkey" FOREIGN KEY ("reader_type_id") REFERENCES "public"."reader_types" ("reader_type_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- ----------------------------
-- Foreign Keys structure for table users
-- ----------------------------
ALTER TABLE "public"."users" ADD CONSTRAINT "users_reader_id_fkey" FOREIGN KEY ("reader_id") REFERENCES "public"."readers" ("reader_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
