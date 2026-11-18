-- 実行計画の比較 (queries/02-explain/) の検証データ
-- 部署・社員・給与改定履歴を大量に生成する。
-- 01-latest-per-group.sql の小さいデータでは、どの書き方もすぐに終わり、実行計画の差が見えにくいため。
--
-- 何度流しても同じ状態になるよう、全テーブルを空にしてから入れる。
-- 流すと 01-latest-per-group.sql のデータは消える。01 に戻すときは、01-latest-per-group.sql を流し直す。
--
-- 乱数は使わず、社員 ID から計算した値でデータを作る。何度流しても同じデータになり、実行計画を比べ直せるようにするため。

USE window_functions;

-- 件数はここで変える
SET @department_count = 10;       -- 部署の数
SET @employee_count   = 100000;   -- 社員の数。給与改定履歴は 1 人あたり 1〜5 件 (平均 3 件) 作る

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE attendance_records;
TRUNCATE TABLE salary_payments;
TRUNCATE TABLE salary_histories;
TRUNCATE TABLE employees;
TRUNCATE TABLE departments;
SET FOREIGN_KEY_CHECKS = 1;

-- 部署
-- 部署 01、部署 02 ... と連番の名前を付ける
INSERT INTO departments (id, name)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < @department_count
)
SELECT
    n,
    CONCAT('部署 ', LPAD(n, 2, '0'))
FROM seq;

-- 社員
-- 部署には社員 ID の順に 1 人ずつ割り振る (部署ごとの人数がほぼ同じになる)
-- 入社日は 2010-04-01〜2021-04-01 の 12 通り。給与改定履歴を最大 5 件作っても、2025-04-01 までに収まるようにしている
INSERT INTO employees (id, department_id, name, hired_on)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < @employee_count
)
SELECT
    n,
    MOD(n - 1, @department_count) + 1,
    CONCAT('社員 ', LPAD(n, 6, '0')),
    DATE '2010-04-01' + INTERVAL MOD(n, 12) YEAR
FROM seq;

-- 給与改定履歴
-- 社員ごとに 1〜5 件 (MOD(社員 ID, 5) + 1 件) 作る
-- 1 件目は入社日、2 件目以降は 1 年ごとの 4 月 1 日に改定する。同じ社員に同じ給与改定日の行はできない
-- 月給は入社時に 250000〜340000 で、改定のたびに 20000 ずつ上がる
INSERT INTO salary_histories (employee_id, monthly_salary, effective_from)
WITH RECURSIVE revision (k) AS (
    SELECT 1
    UNION ALL
    SELECT k + 1 FROM revision WHERE k < 5
)
SELECT
    e.id,
    250000 + MOD(e.id * 37, 10) * 10000 + (r.k - 1) * 20000,
    e.hired_on + INTERVAL (r.k - 1) YEAR
FROM employees AS e
INNER JOIN revision AS r
    ON r.k <= MOD(e.id, 5) + 1
ORDER BY e.id, r.k;

-- 実行計画の見積もりが、入れたデータに合うよう統計情報を更新する
ANALYZE TABLE departments, employees, salary_histories;
