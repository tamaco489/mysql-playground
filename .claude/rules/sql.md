# SQL の書き方

`themes/` 配下の SQL ファイルは、以下のルールで書く。

## インデント

- スペース 4 つ。タブは使わない
- `ON` は `JOIN` の次の行に置く。条件が 1 つのときも同じ
- 続く条件は、`ON` と `AND` を同じ深さに揃える

```sql
INNER JOIN latest AS l
    ON l.employee_id = sh.employee_id
    AND l.latest_effective_from = sh.effective_from
INNER JOIN employees AS e
    ON e.id = sh.employee_id
```

## 行末コメント

- コメント付きの行が連続している範囲ごとに、コメントの位置を揃える
- 位置は、その範囲で一番長いコードの行の末尾から、半角スペース 2 つ空けたところにする
- 途中にコメントのない行が挟まったら、そこで範囲を区切る

```sql
ROW_NUMBER() OVER (
    PARTITION BY sh.employee_id      -- 社員ごとに番号を振り直す
    ORDER BY sh.effective_from DESC  -- 新しい給与改定日から 1, 2, 3 ... と振る
) AS rn
```

## 結合

- 内部結合は `JOIN` ではなく `INNER JOIN` と明示する

## 別名

- テーブルの別名にも列の別名にも、必ず `AS` を付ける
  - テーブル: `FROM salary_histories AS sh`
  - 列: `MAX(effective_from) AS effective_from`

## 識別子

- `ddl/` では、DB 名・テーブル名・カラム名・制約名をバッククォートで囲む
  (`` `employees` ``、`` `department_id` ``)

## コメント

- `ddl/` では、テーブルとすべてのカラムに `COMMENT` を付ける
- テーブルの `COMMENT` には、行が増えるタイミングや、どの行が有効かなど、データの読み方も書く
- 金額のカラムには単位を書く (`COMMENT '支給額 (円)'`)

## キーワード

- `SELECT` `FROM` `WHERE` などの SQL のキーワードと関数名は大文字で書く
- テーブル名・列名・別名は小文字のスネークケースで書く

## ファイルの構成

- 先頭で `USE <テーマの DB>;` を書く。`make sql` は DB を指定せずに実行するため
- `ddl/` と `seed/` は、何度流しても同じ状態になるように書く
- `queries/` は、題材ごとのディレクトリ (`10-top-n/` など) に分ける
  - ディレクトリ名とファイル名の区切りはハイフンにする。アンダースコアは使わない
  - 1 ファイルには、本題のクエリ 1 つと、その途中経過を確かめる補助クエリを書く
  - 本題と補助は `-- # ===` の見出しで区切る
  - 各クエリの直後に、実行結果をコメントで貼る。日本語の列も罫線が揃うように整える
  - ファイル名は `<番号>-<問い>-<without-window|with-window>.sql` にし、比べる 2 つが名前で対になるようにする
  - 比較ではなく仕組みを見せるだけのファイルは `<番号>-<内容>.sql` にする (`02-row-number-mechanism.sql`)
  - 先頭のコメントに、問い・書き方・比べる相手のファイル名を書く
