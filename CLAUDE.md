## GitHub の運用 (gh-flow)

コミット・Issue・PR は gh-flow プラグインの規約に従う。規約は gh-flow のスキルが実行時に読み込む。

| 作業                      | スキル                           |
| ------------------------- | -------------------------------- |
| コミットから PR まで      | `/gh-flow:smart-commit`          |
| メイン Issue とサブ Issue | `/gh-flow:create-release-issues` |
| リリース PR               | `/gh-flow:create-release-pr`     |
| ラベルの GitHub への反映  | `/gh-flow:sync-labels`           |

- 規約に合わない操作は gh-flow の hooks が拒否する
- ラベルの一覧は `.claude/rules/github/labels.md` に置く
- 直下に新しい領域 (ディレクトリ、CI、CD) を追加したら `/gh-flow:setup` を実行する
