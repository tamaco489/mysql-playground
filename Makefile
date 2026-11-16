.DEFAULT_GOAL := help

SERVICE    := mysql
MYSQL_EXEC := docker compose exec -e MYSQL_PWD=root $(SERVICE)

.PHONY: help up down restart reset ps logs sh mysql

help: ## コマンドの一覧を表示する
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

up: ## MySQL コンテナを起動し、healthcheck が通るまで待つ
	docker compose up -d --wait

down: ## コンテナを停止して削除する (データは残る)
	docker compose down

restart: ## コンテナを再起動する (my.cnf の変更を反映するとき)
	docker compose restart $(SERVICE)

reset: ## コンテナとデータをすべて削除する
	docker compose down -v

ps: ## コンテナの状態を表示する
	docker compose ps

logs: ## MySQL のログを追う
	docker compose logs -f $(SERVICE)

sh: ## コンテナに bash で入る
	docker compose exec $(SERVICE) bash

mysql: ## mysql クライアントで接続する
	$(MYSQL_EXEC) mysql -uroot
