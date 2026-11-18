-- # ====================================================================================
-- # 社員ごとの現在の月給を求めるクエリの実行計画を見るクエリ例
-- # ====================================================================================
-- 01-latest-per-group/01-current-salary-without-window.sql と 01-latest-per-group/03-current-salary-with-window.sql の本題のクエリに
-- EXPLAIN を付け、MySQL がそれぞれをどう実行するつもりかを比べる。
-- クエリ自体は実行されず、実行計画だけが返る。

USE window_functions;

-- 1. 01-latest-per-group/01-current-salary-without-window.sql (GROUP BY + JOIN) の実行計画
EXPLAIN
WITH latest AS (
    SELECT
        employee_id,
        MAX(effective_from) AS latest_effective_from
    FROM salary_histories
    GROUP BY employee_id
)
SELECT
    e.id,
    e.name,
    sh.monthly_salary,
    sh.effective_from
FROM salary_histories AS sh
INNER JOIN latest AS l
    ON l.employee_id = sh.employee_id
    AND l.latest_effective_from = sh.effective_from
INNER JOIN employees AS e
    ON e.id = sh.employee_id
ORDER BY e.id;
-- +----+-------------+------------------+------------+--------+------------------------------+------------------------------+---------+---------------+------+----------+---------------------------------+
-- | id | select_type | table            | partitions | type   | possible_keys                | key                          | key_len | ref           | rows | filtered | Extra                           |
-- +----+-------------+------------------+------------+--------+------------------------------+------------------------------+---------+---------------+------+----------+---------------------------------+
-- |  1 | PRIMARY     | <derived2>       | NULL       | ALL    | NULL                         | NULL                         | NULL    | NULL          |   23 |   100.00 | Using temporary; Using filesort |
-- |  1 | PRIMARY     | sh               | NULL       | ref    | fk_salary_histories_employee | fk_salary_histories_employee | 4       | l.employee_id |    2 |    10.00 | Using where                     |
-- |  1 | PRIMARY     | e                | NULL       | eq_ref | PRIMARY                      | PRIMARY                      | 4       | l.employee_id |    1 |   100.00 | NULL                            |
-- |  2 | DERIVED     | salary_histories | NULL       | index  | fk_salary_histories_employee | fk_salary_histories_employee | 4       | NULL          |   23 |   100.00 | NULL                            |
-- +----+-------------+------------------+------------+--------+------------------------------+------------------------------+---------+---------------+------+----------+---------------------------------+

-- 2. 01-latest-per-group/03-current-salary-with-window.sql (ROW_NUMBER) の実行計画
EXPLAIN
WITH ranked AS (
    SELECT
        sh.employee_id,
        sh.monthly_salary,
        sh.effective_from,
        ROW_NUMBER() OVER (
            PARTITION BY sh.employee_id
            ORDER BY sh.effective_from DESC
        ) AS rn
    FROM salary_histories AS sh
)
SELECT
    e.id,
    e.name,
    r.monthly_salary,
    r.effective_from
FROM ranked AS r
INNER JOIN employees AS e
    ON e.id = r.employee_id
WHERE r.rn = 1
ORDER BY e.id;
-- +----+-------------+------------+------------+--------+---------------+---------+---------+---------------+------+----------+----------------------------------------------+
-- | id | select_type | table      | partitions | type   | possible_keys | key     | key_len | ref           | rows | filtered | Extra                                        |
-- +----+-------------+------------+------------+--------+---------------+---------+---------+---------------+------+----------+----------------------------------------------+
-- |  1 | PRIMARY     | <derived2> | NULL       | ALL    | NULL          | NULL    | NULL    | NULL          |   23 |    10.00 | Using where; Using temporary; Using filesort |
-- |  1 | PRIMARY     | e          | NULL       | eq_ref | PRIMARY       | PRIMARY | 4       | r.employee_id |    1 |   100.00 | NULL                                         |
-- |  2 | DERIVED     | sh         | NULL       | ALL    | NULL          | NULL    | NULL    | NULL          |   23 |   100.00 | Using filesort                               |
-- +----+-------------+------------+------------+--------+---------------+---------+---------+---------------+------+----------+----------------------------------------------+
