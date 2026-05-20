---
name: use-package-runner
description: Node.js プロジェクト内で JS 製の CLI / スクリプトを実行する際は、`node_modules/.bin/xxx` を直接呼ばず、パッケージマネージャのランナー（npm/yarn v1 は `npx xxx`、pnpm は `pnpm exec xxx`、yarn berry は `yarn dlx xxx`、bun は `bunx xxx`）を使う。package.json と lock ファイル（package-lock.json / yarn.lock / pnpm-lock.yaml / bun.lockb）が存在するディレクトリで JS ベースのコマンド（eslint, prettier, tsc, vitest, jest, vite, next, prh など）を Bash 経由で起動する直前に発動する。
allowed-tools: Bash, Read, Glob
---

# Use package-manager runners for JS CLI execution

Node.js プロジェクトで JS 製の CLI・スクリプトを実行するときは、必ずパッケージマネージャのランナー（`npx` / `pnpm exec` / `yarn dlx` / `bunx`）経由で起動する。`node_modules/.bin/<command>` を直接呼ばない。

## なぜランナー経由か

- `node_modules/.bin/xxx` を直接叩くと、現在の PATH 解決やシェルの状態に依存し、サブシェルや CI で同じコマンドが再現しないことがある。
- ランナーは PATH に `node_modules/.bin` を一時的に通したうえでコマンドを起動するため、依存解決とバイナリ探索の順序が常に同じになる。
- モノレポやサブパッケージ配下では、`.bin/` のパスがワークスペースの深さによって変わる。ランナーはこれを吸収する。
- pnpm のように `node_modules` 構造が flat ではない場合、`./node_modules/.bin/xxx` を直接呼ぶと意図通り解決できないことがある。`pnpm exec` を使えば常に正しいバイナリが選ばれる。
- lock ファイル経由で固定されたバージョンが必ず使われるため、再現性が高い。

## 発動条件

以下のいずれかが成り立つとき、JS 由来のコマンドを Bash で実行する直前にこの skill を適用する。

- カレントもしくは祖先ディレクトリに `package.json` が存在する
- 同階層に `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` / `bun.lockb` のいずれかが存在する
- ユーザーが「Node プロジェクトだ」「pnpm プロジェクトだ」と明示している
- プロジェクト直下に `node_modules/.bin/` があり、そこに実行したいバイナリが存在する

判定に迷うときは `ls` や `Read` で lock ファイル種別と `package.json` の `packageManager` フィールドを確認する。

## パッケージマネージャの判別

lock ファイルと `package.json` の `packageManager` フィールドから、使うべきランナーを決める。

| 判別材料                                | パッケージマネージャ   | 使うランナー        |
| --------------------------------------- | ---------------------- | ------------------- |
| `pnpm-lock.yaml` / `packageManager: pnpm@*` | pnpm                   | `pnpm exec xxx`     |
| `package-lock.json`                     | npm                    | `npx xxx`           |
| `yarn.lock` + `packageManager: yarn@1.*` または `.yarnrc` のみ | yarn classic (v1)      | `npx xxx`           |
| `yarn.lock` + `packageManager: yarn@2+` または `.yarnrc.yml` | yarn berry (v2+)       | `yarn dlx xxx`      |
| `bun.lockb`                             | bun                    | `bunx xxx`          |
| なし（`package.json` のみ）             | npm 互換               | `npx xxx`           |

複数 lock ファイルが共存する場合は `package.json` の `packageManager` フィールドを最優先する。それも無ければ、より新しい lock ファイル（`pnpm-lock.yaml` など）を優先する。

## 置き換えルール

| 避ける書き方                              | 正しい書き方                                            |
| ----------------------------------------- | ------------------------------------------------------- |
| `node_modules/.bin/eslint .`              | `pnpm exec eslint .` / `npx eslint .` / `yarn dlx eslint .` / `bunx eslint .` |
| `node_modules/.bin/prettier --write .`    | `pnpm exec prettier --write .` 等                       |
| `node_modules/.bin/tsc --noEmit`          | `pnpm exec tsc --noEmit` 等                             |
| `node_modules/.bin/vitest run`            | `pnpm exec vitest run` 等                               |
| `node_modules/.bin/jest --ci`             | `pnpm exec jest --ci` 等                                |
| `node_modules/.bin/prh README.md`         | `pnpm exec prh README.md` 等                            |
| `./node_modules/.bin/next build`          | `pnpm exec next build` 等                               |
| `PATH=./node_modules/.bin:$PATH eslint .` | `pnpm exec eslint .` 等                                 |

スクリプト引数はそのまま後ろに渡す。例（pnpm プロジェクト）：

```bash
# Before
node_modules/.bin/prh --rules prh.yml README.md

# After
pnpm exec prh --rules prh.yml README.md
```

サブディレクトリで実行したい場合は各 pm のオプションを使う。

```bash
# pnpm
pnpm --dir packages/web exec vitest run

# npm / yarn v1
( cd packages/web && npx vitest run )

# yarn berry
( cd packages/web && yarn dlx vitest run )
```

## `pnpm exec` と `pnpm dlx` の使い分け

pnpm には用途の異なる 2 つのコマンドがある。この skill では既定で **`pnpm exec` を使う**。

- `pnpm exec xxx`: `node_modules` にインストール済みのバイナリを実行する。ネットワーク不要・最速・lock のバージョンが必ず使われる。
- `pnpm dlx xxx`: プロジェクトに無いコマンドを一時取得して実行する。ad hoc な利用向け。

理由：プロジェクト配下で実行する CLI（eslint, vitest, tsc 等）は `package.json` の `devDependencies` 経由で入っているのが普通で、それを実行するなら `pnpm exec` が意味的に正しい。`pnpm dlx` は依存に無いコマンドを一時的に叩きたいとき（例：`pnpm dlx create-next-app my-app`）に限る。

> npm / yarn v1 ではこの区別が無いため、ローカルでも一時取得でも `npx` で統一する。yarn berry も同様に、CLI 実行は `yarn dlx` で統一する（`yarn exec` もあるが、berry エコシステムでは `dlx` が主流）。

## してはいけないこと

- ユーザーが提示したエラーログ中の `node_modules/.bin/xxx` 表記をそのままコピーして実行しない。対応するランナーに置き換えてから実行する。
- `PATH=./node_modules/.bin:$PATH xxx` のような PATH 汚染を挟まない。
- グローバルにインストールされた同名コマンド（例：システム install の `eslint`）にフォールバックしない。プロジェクト配下では必ずランナー経由で実行する。
- `node node_modules/<pkg>/bin/cli.js` のような直接 `node` 起動も避ける（bin マッピングと shebang を尊重する）。
- pnpm プロジェクトで安易に `pnpm dlx` を使わない。dev 依存に入っているコマンドは `pnpm exec` で実行する。

## 例外

以下はランナーを使わなくてよい。

- 対象ディレクトリに `package.json` も lock ファイルも存在しないとき（Node プロジェクトではない）
- 純粋な Node スクリプトを `node script.js` で実行する場合（CLI バイナリではない）
- `package.json` の `scripts` を実行するとき。これは `npm run xxx` / `pnpm xxx` / `yarn xxx` を使う（ランナーではない）
- ユーザーが明示的に `node_modules/.bin/xxx` で実行するよう指示したとき

## 自己チェック

Bash で JS ツールを起動するコマンドを書く前に、以下を心の中で確認する。

1. 実行先プロジェクトに `package.json` があるか？
2. lock ファイルと `packageManager` フィールドから、対応するランナー（`pnpm exec` / `npx` / `yarn dlx` / `bunx`）を選んだか？
3. コマンドの先頭がランナーで始まっているか？
4. `node_modules/.bin/` や `PATH=./node_modules/.bin:$PATH` を書いていないか？
5. pnpm の場合、dev 依存にあるコマンドを `pnpm dlx` ではなく `pnpm exec` で起動しているか？

すべて揃っていれば送信する。揃っていなければ書き換える。
