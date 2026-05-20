---
name: use-uv-run
description: uv で管理された Python プロジェクト内で Python スクリプト/CLI を実行する際は、`.venv/bin/xxx` や `python -m xxx` ではなく `uv run xxx` を使う。uv.lock または pyproject.toml が存在するディレクトリで Python ベースのコマンド（ansible-lint、pytest、ruff、mypy、ansible-playbook など）を Bash 経由で起動する直前に発動する。
allowed-tools: Bash, Read, Glob
---

# Use `uv run` for Python execution

uv で管理された Python プロジェクトでは、Python スクリプト・CLI を実行するときに必ず `uv run <command>` を使う。`.venv/bin/<command>` を直接呼び出さない。

## なぜ `uv run` か

- `uv run` は実行前に `uv.lock` と venv の同期を保証する。`.venv/bin/xxx` を直接叩くと、ロックファイル更新後に同期されないまま古い依存で実行されることがある。
- venv の activate 状態に依存しない。サブシェルや CI でも同じコマンドが再現する。
- 仮想環境のパス（`.venv/bin/`）はプロジェクト構成によって変わる可能性があるが、`uv run` はそれを吸収する。
- プロジェクトのルート判定（pyproject.toml の探索）を uv が行うため、サブディレクトリからでも動く。

## 発動条件

以下のいずれかが成り立つとき、Python 由来のコマンドを Bash で実行する直前にこの skill を適用する。

- カレントもしくは祖先ディレクトリに `uv.lock` が存在する
- `pyproject.toml` に `[tool.uv]` セクション、もしくは `requires-python` と uv 系の設定が記載されている
- ユーザーが「uv プロジェクトだ」と明示している
- プロジェクト直下に `.venv/` があり、かつ上記いずれかと併存する

判定に迷うときは `ls -a` や `Read` で `uv.lock` / `pyproject.toml` を確認する。

## 置き換えルール

| 避ける書き方                           | 正しい書き方                       |
| -------------------------------------- | ---------------------------------- |
| `.venv/bin/ansible-lint ...`           | `uv run ansible-lint ...`          |
| `.venv/bin/pytest tests/`              | `uv run pytest tests/`             |
| `.venv/bin/ruff check .`               | `uv run ruff check .`              |
| `.venv/bin/python script.py`           | `uv run python script.py`          |
| `source .venv/bin/activate && pytest`  | `uv run pytest`                    |
| `python -m pytest`（venv 前提）        | `uv run python -m pytest`          |
| `pip install -r requirements.txt`      | `uv pip install -r requirements.txt`（または `uv sync`） |

スクリプト引数はそのまま後ろに渡す。例：

```bash
# Before
.venv/bin/ansible-lint roles/wordpress/tasks/wordpress.yml

# After
uv run ansible-lint roles/wordpress/tasks/wordpress.yml
```

サブディレクトリ指定で実行したいときは `--project` または `--directory` を併用する。

```bash
uv run --directory ansible-examples ansible-lint roles/wordpress/tasks/wordpress.yml
```

## してはいけないこと

- ユーザーが提示したエラーログ中の `.venv/bin/xxx` 表記をそのままコピーして実行しない。`uv run xxx` に置き換えてから実行する。
- `uv run` の前に `source .venv/bin/activate` を入れない（不要・冗長）。
- venv の存在チェックを `ls .venv/bin/<tool>` で行わない。`uv run --help` または `uv run <tool> --version` で確認する。
- グローバルにインストールされた同名コマンド（例：システムの `ansible-lint`）にフォールバックしない。uv プロジェクト配下では必ず `uv run` 経由で実行する。

## 例外

以下は `uv run` を使わなくてよい。

- 対象プロジェクトに `uv.lock` も `pyproject.toml` も存在しないとき（uv プロジェクトではない）
- Poetry / pipenv / rye など別ツールで管理されているとき。その場合はそのツールの実行コマンド（`poetry run`, `pipenv run`, `rye run`）を使う
- ユーザーが明示的に `.venv/bin/xxx` で実行するよう指示したとき

## 自己チェック

Bash で Python ツールを起動するコマンドを書く前に、以下を心の中で確認する。

1. 実行先プロジェクトに `uv.lock` があるか？
2. コマンドの先頭が `uv run` で始まっているか？
3. `.venv/bin/` や `source .venv/bin/activate` を書いていないか？

3 つ揃っていれば送信する。揃っていなければ書き換える。
