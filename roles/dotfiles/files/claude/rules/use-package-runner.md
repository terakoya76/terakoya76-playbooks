# Package Runner Conventions

プロジェクト配下で CLI / スクリプトを Bash 経由で起動するときは、各エコシステムのランナー経由で実行する。`node_modules/.bin/xxx` や `.venv/bin/xxx` を直接呼ばない。

## なぜランナー経由か

- PATH 解決やシェルの状態に依存しないので、サブシェルや CI でも同じコマンドが再現する。
- lock ファイルで固定されたバージョンが必ず使われる。
- モノレポ / ワークスペース構造（pnpm の symlink、`.venv` のサブディレクトリ配置など）を吸収できる。
- ロックファイル更新後に環境同期されていないまま古い依存で実行する事故を防げる。

## Node.js（package-manager runners）

### 発動条件

以下のいずれかが成り立つとき、JS 由来のコマンドを Bash で実行する直前にこのルールを適用する。

- カレントもしくは祖先ディレクトリに `package.json` が存在する
- `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` / `bun.lockb` のいずれかが同階層に存在する
- プロジェクト直下に `node_modules/.bin/` があり、そこに実行したいバイナリが存在する

### パッケージマネージャの判別

lock ファイルと `package.json` の `packageManager` フィールドから、使うべきランナーを決める。

| 判別材料                                                       | パッケージマネージャ | 使うランナー    |
| -------------------------------------------------------------- | -------------------- | --------------- |
| `pnpm-lock.yaml` / `packageManager: pnpm@*`                    | pnpm                 | `pnpm exec xxx` |
| `package-lock.json`                                            | npm                  | `npx xxx`       |
| `yarn.lock` + `packageManager: yarn@1.*` または `.yarnrc` のみ | yarn classic (v1)    | `npx xxx`       |
| `yarn.lock` + `packageManager: yarn@2+` または `.yarnrc.yml`   | yarn berry (v2+)     | `yarn dlx xxx`  |
| `bun.lockb`                                                    | bun                  | `bunx xxx`      |
| なし（`package.json` のみ）                                    | npm 互換             | `npx xxx`       |

複数 lock ファイルが共存する場合は `package.json` の `packageManager` フィールドを最優先する。それも無ければ、より新しい lock ファイル（`pnpm-lock.yaml` など）を優先する。

### 置き換えルール

| 避ける書き方                              | 正しい書き方                                                                  |
| ----------------------------------------- | ----------------------------------------------------------------------------- |
| `node_modules/.bin/eslint .`              | `pnpm exec eslint .` / `npx eslint .` / `yarn dlx eslint .` / `bunx eslint .` |
| `node_modules/.bin/prettier --write .`    | `pnpm exec prettier --write .` 等                                             |
| `node_modules/.bin/tsc --noEmit`          | `pnpm exec tsc --noEmit` 等                                                   |
| `node_modules/.bin/vitest run`            | `pnpm exec vitest run` 等                                                     |
| `node_modules/.bin/jest --ci`             | `pnpm exec jest --ci` 等                                                      |
| `node_modules/.bin/prh README.md`         | `pnpm exec prh README.md` 等                                                  |
| `./node_modules/.bin/next build`          | `pnpm exec next build` 等                                                     |
| `PATH=./node_modules/.bin:$PATH eslint .` | `pnpm exec eslint .` 等                                                       |

サブディレクトリで実行したい場合は各 pm のオプションを使う。

```bash
# pnpm
pnpm --dir packages/web exec vitest run

# npm / yarn v1
( cd packages/web && npx vitest run )

# yarn berry
( cd packages/web && yarn dlx vitest run )
```

### `pnpm exec` と `pnpm dlx` の使い分け

pnpm には用途の異なる 2 つのコマンドがある。既定では **`pnpm exec` を使う**。

- `pnpm exec xxx`: `node_modules` にインストール済みのバイナリを実行する。ネットワーク不要・最速・lock のバージョンが必ず使われる。
- `pnpm dlx xxx`: プロジェクトに無いコマンドを一時取得して実行する。ad hoc な利用向け（例：`pnpm dlx create-next-app my-app`）。

プロジェクト配下で実行する CLI（eslint, vitest, tsc 等）は `package.json` の `devDependencies` 経由で入っているのが普通で、それを実行するなら `pnpm exec` が意味的に正しい。

> npm / yarn v1 ではこの区別が無いため、ローカルでも一時取得でも `npx` で統一する。yarn berry も同様に、CLI 実行は `yarn dlx` で統一する（`yarn exec` もあるが、berry エコシステムでは `dlx` が主流）。

### してはいけないこと

- ユーザーが提示したエラーログ中の `node_modules/.bin/xxx` 表記をそのままコピーして実行しない。対応するランナーに置き換えてから実行する。
- `PATH=./node_modules/.bin:$PATH xxx` のような PATH 汚染を挟まない。
- グローバルにインストールされた同名コマンド（例：システム install の `eslint`）にフォールバックしない。プロジェクト配下では必ずランナー経由で実行する。
- `node node_modules/<pkg>/bin/cli.js` のような直接 `node` 起動も避ける（bin マッピングと shebang を尊重する）。
- pnpm プロジェクトで安易に `pnpm dlx` を使わない。dev 依存に入っているコマンドは `pnpm exec` で実行する。

### 例外

以下はランナーを使わなくてよい。

- 対象ディレクトリに `package.json` も lock ファイルも存在しないとき（Node プロジェクトではない）
- 純粋な Node スクリプトを `node script.js` で実行する場合（CLI バイナリではない）
- `package.json` の `scripts` を実行するとき。これは `npm run xxx` / `pnpm xxx` / `yarn xxx` を使う（ランナーではない）
- ユーザーが明示的に `node_modules/.bin/xxx` で実行するよう指示したとき

## Python（uv run）

### 発動条件

以下のいずれかが成り立つとき、Python 由来のコマンドを Bash で実行する直前にこのルールを適用する。

- カレントもしくは祖先ディレクトリに `uv.lock` が存在する
- `pyproject.toml` に `[tool.uv]` セクション、もしくは uv 系の設定が記載されている
- ユーザーが「uv プロジェクトだ」と明示している
- プロジェクト直下に `.venv/` があり、かつ上記いずれかと併存する

### 置き換えルール

| 避ける書き方                          | 正しい書き方                                             |
| ------------------------------------- | -------------------------------------------------------- |
| `.venv/bin/ansible-lint ...`          | `uv run ansible-lint ...`                                |
| `.venv/bin/pytest tests/`             | `uv run pytest tests/`                                   |
| `.venv/bin/ruff check .`              | `uv run ruff check .`                                    |
| `.venv/bin/python script.py`          | `uv run python script.py`                                |
| `source .venv/bin/activate && pytest` | `uv run pytest`                                          |
| `python -m pytest`（venv 前提）       | `uv run python -m pytest`                                |
| `pip install -r requirements.txt`     | `uv pip install -r requirements.txt`（または `uv sync`） |

サブディレクトリ指定で実行したいときは `--project` または `--directory` を併用する。

```bash
uv run --directory ansible-examples ansible-lint roles/wordpress/tasks/wordpress.yml
```

### してはいけないこと

- ユーザーが提示したエラーログ中の `.venv/bin/xxx` 表記をそのままコピーして実行しない。`uv run xxx` に置き換えてから実行する。
- `uv run` の前に `source .venv/bin/activate` を入れない（不要・冗長）。
- venv の存在チェックを `ls .venv/bin/<tool>` で行わない。`uv run --help` または `uv run <tool> --version` で確認する。
- グローバルにインストールされた同名コマンド（例：システムの `ansible-lint`）にフォールバックしない。uv プロジェクト配下では必ず `uv run` 経由で実行する。

### 例外

以下は `uv run` を使わなくてよい。

- 対象プロジェクトに `uv.lock` も `pyproject.toml` も存在しないとき（uv プロジェクトではない）
- Poetry / pipenv / rye など別ツールで管理されているとき。その場合はそのツールの実行コマンド（`poetry run`, `pipenv run`, `rye run`）を使う
- ユーザーが明示的に `.venv/bin/xxx` で実行するよう指示したとき

## 自己チェック

Bash でツールを起動するコマンドを書く前に、以下を確認する。

1. 実行先プロジェクトの種別（Node / Python / どちらでもない）を判定したか？
2. 対応するランナー（`pnpm exec` / `npx` / `yarn dlx` / `bunx` / `uv run`）を選んだか？
3. コマンドの先頭がランナーで始まっているか？
4. `node_modules/.bin/` / `.venv/bin/` / `PATH=./node_modules/.bin:$PATH` / `source .venv/bin/activate` を書いていないか？
5. pnpm の場合、dev 依存にあるコマンドを `pnpm dlx` ではなく `pnpm exec` で起動しているか？

すべて揃っていれば送信する。揃っていなければ書き換える。
