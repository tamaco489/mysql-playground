-- ウィンドウ関数 (OVER (PARTITION BY)) の検証用スキーマ
-- 業務は人事 (部署・社員・給与・勤怠) に揃える。
-- 何度流しても同じ状態になるよう、テーブルは作り直す。
-- インデックスは主キーと外部キーだけにする。インデックスの有無による差は性能比較で見る。

CREATE DATABASE IF NOT EXISTS window_functions;
USE window_functions;

-- 外部キーで参照される側を後に消す
DROP TABLE IF EXISTS attendance_records;
DROP TABLE IF EXISTS salary_payments;
DROP TABLE IF EXISTS salary_histories;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- 部署
CREATE TABLE departments (
  id   INT         NOT NULL AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  PRIMARY KEY (id)
);

-- 社員
CREATE TABLE employees (
  id            INT         NOT NULL AUTO_INCREMENT,
  department_id INT         NOT NULL,
  name          VARCHAR(50) NOT NULL,
  hired_on      DATE        NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_employees_department
    FOREIGN KEY (department_id) REFERENCES departments (id)
);

-- 給与改定履歴 (上位 N 件の題材)
-- 改定のたびに 1 行増える。effective_from が最も新しい行が現在の月給。
CREATE TABLE salary_histories (
  id             INT  NOT NULL AUTO_INCREMENT,
  employee_id    INT  NOT NULL,
  monthly_salary INT  NOT NULL,
  effective_from DATE NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_salary_histories_employee
    FOREIGN KEY (employee_id) REFERENCES employees (id)
);

-- 給与の支給実績 (累計の題材)
CREATE TABLE salary_payments (
  id          INT  NOT NULL AUTO_INCREMENT,
  employee_id INT  NOT NULL,
  amount      INT  NOT NULL,
  paid_on     DATE NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_salary_payments_employee
    FOREIGN KEY (employee_id) REFERENCES employees (id)
);

-- 勤怠 (重複除去の題材)
-- 修正申請のたびに、同じ社員・同じ日 (work_date) の行が増える。
-- submitted_at が最も新しい行が有効な勤怠。
CREATE TABLE attendance_records (
  id           INT      NOT NULL AUTO_INCREMENT,
  employee_id  INT      NOT NULL,
  work_date    DATE     NOT NULL,
  clock_in     TIME     NOT NULL,
  clock_out    TIME     NOT NULL,
  submitted_at DATETIME NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_attendance_records_employee
    FOREIGN KEY (employee_id) REFERENCES employees (id)
);
