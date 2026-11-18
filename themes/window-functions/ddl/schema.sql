-- ウィンドウ関数 (OVER (PARTITION BY)) の検証用スキーマ
-- 業務は人事 (部署・社員・給与・勤怠) に揃える。
-- 何度流しても同じ状態になるよう、テーブルは作り直す。
-- インデックスは主キーと外部キーだけにする。インデックスの有無による差は性能比較で見る。

CREATE DATABASE IF NOT EXISTS `window_functions`;
USE `window_functions`;

-- 外部キーで参照される側を後に消す
DROP TABLE IF EXISTS `attendance_records`;
DROP TABLE IF EXISTS `salary_payments`;
DROP TABLE IF EXISTS `salary_histories`;
DROP TABLE IF EXISTS `employees`;
DROP TABLE IF EXISTS `departments`;

CREATE TABLE `departments` (
    `id`   INT         NOT NULL AUTO_INCREMENT COMMENT '部署 ID',
    `name` VARCHAR(50) NOT NULL                COMMENT '部署名',
    PRIMARY KEY (`id`)
) COMMENT = '部署テーブル。社員は必ずどこかの部署に所属する。';

CREATE TABLE `employees` (
    `id`            INT         NOT NULL AUTO_INCREMENT COMMENT '社員 ID',
    `department_id` INT         NOT NULL                COMMENT '所属する部署の ID',
    `name`          VARCHAR(50) NOT NULL                COMMENT '社員名',
    `hired_on`      DATE        NOT NULL                COMMENT '入社日',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_employees_department`
        FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`)
) COMMENT = '社員テーブル。部署に所属する社員の情報を保持する。';

-- 上位 N 件の題材
CREATE TABLE `salary_histories` (
    `id`             INT  NOT NULL AUTO_INCREMENT COMMENT '給与改定履歴 ID',
    `employee_id`    INT  NOT NULL                COMMENT '改定された社員の ID',
    `monthly_salary` INT  NOT NULL                COMMENT '改定後の月給 (円)',
    `effective_from` DATE NOT NULL                COMMENT '改定後の月給が適用される日',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_salary_histories_employee`
        FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`)
) COMMENT = '給与改定履歴テーブル。改定のたびに 1 行増え、effective_from が最も新しい行が現在の月給';

-- 累計の題材
CREATE TABLE `salary_payments` (
    `id`          INT  NOT NULL AUTO_INCREMENT COMMENT '支給実績 ID',
    `employee_id` INT  NOT NULL                COMMENT '支給を受けた社員の ID',
    `amount`      INT  NOT NULL                COMMENT '支給額 (円)',
    `paid_on`     DATE NOT NULL                COMMENT '支給日',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_salary_payments_employee`
        FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`)
) COMMENT = '給与の支給実績テーブル。毎月の支給ごとに 1 行';

-- 重複除去の題材
CREATE TABLE `attendance_records` (
    `id`           INT      NOT NULL AUTO_INCREMENT COMMENT '勤怠 ID',
    `employee_id`  INT      NOT NULL                COMMENT '申請した社員の ID',
    `work_date`    DATE     NOT NULL                COMMENT '勤務日',
    `clock_in`     TIME     NOT NULL                COMMENT '出勤時刻',
    `clock_out`    TIME     NOT NULL                COMMENT '退勤時刻',
    `submitted_at` DATETIME NOT NULL                COMMENT '申請日時。修正申請のたびに新しい日時の行が増える',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_attendance_records_employee`
        FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`)
) COMMENT = '勤怠テーブル。修正申請のたびに同じ社員・同じ勤務日の行が増え、submitted_at が最も新しい行が有効';
