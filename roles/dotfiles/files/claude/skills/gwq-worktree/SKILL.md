---
name: gwq-worktree
description: gwq で開発用 worktree を作成・削除する。作成は gwq add を使い最新の main(または master) を基点にする。ユーザーが「worktree を作って」「開発用ブランチを切って作業場所を用意して」等と依頼したとき、あるいは「worktree を削除して」「作業場所を片付けて」等と依頼したときに使う。引数でブランチ名を受け取る。
---

# gwq-worktree

`gwq` で開発用 worktree を作成・削除する skill。

- **作成**: `gwq add` でリモートの最新 main を基点にした worktree を作る → [作成の手順](#作成の手順)
- **削除**: `gwq remove` で worktree を片付ける → [削除の手順](#削除の手順)

ユーザーの依頼が作成・削除どちらかを判断し、該当するセクションの手順に従う。

## 前提

- `gwq` がインストールされ、対象リポジトリが ghq 配下にある（gwq の naming.template / worktree.basedir に従って配置される）。
- カレントが git リポジトリ内であること。

## 重要: なぜ「ブランチ先作成 → gwq add」なのか

`gwq add -b <branch>` は **現在の HEAD** から新ブランチを切る。作業中の feature ブランチ上で実行すると main 基点にならない。
そこで **先にローカルブランチを `origin/<main>` 指定で作成し、既存ブランチとして `gwq add <branch>` で worktree 化** する。
これにより現在のチェックアウトに一切触れず、確実に最新 main 基点の worktree を作れる。

## 作成の手順

### 1. ブランチ名の確定

- skill の引数でブランチ名が渡されていればそれを使う。
- 未指定なら、ユーザーにブランチ名を尋ねてから進める（プレフィックス例: `feature/`, `fix/` 等は強制しない。ユーザー指定をそのまま使う）。
- ブランチ名は変数 `BRANCH` として扱う。

### 2. デフォルトブランチ(main/master)を判定

```bash
# origin の HEAD からデフォルトブランチを取得（取れなければ main/master を順にフォールバック）
MAIN=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
if [ -z "$MAIN" ]; then
  if git show-ref --verify --quiet refs/remotes/origin/main; then MAIN=main
  elif git show-ref --verify --quiet refs/remotes/origin/master; then MAIN=master
  else echo "デフォルトブランチを特定できませんでした"; exit 1; fi
fi
echo "base branch: $MAIN"
```

### 3. 最新化（origin/<main> を fetch）

```bash
git fetch origin "$MAIN"
```

### 4. ブランチ名の重複チェック

```bash
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "ローカルブランチ '$BRANCH' は既に存在します。別名にするか、既存ブランチで worktree 化するか確認してください。"
  exit 1
fi
```

- 既存の場合は勝手に上書きせず、ユーザーに確認する。

### 5. origin/<main> を基点にローカルブランチを作成

```bash
# チェックアウトせずにブランチだけ作る（現在の作業ディレクトリに副作用なし）
git branch "$BRANCH" "origin/$MAIN"
```

### 6. gwq で worktree を作成

```bash
gwq add "$BRANCH"
# 作成された worktree の絶対パスを取得
WT=$(gwq get "$BRANCH")
echo "worktree: $WT"
```

### 7. ローカル設定ファイルのコピー

`.env` と `mise.local.toml` は通常 gitignore 対象で worktree には引き継がれない。
作業に必要なため、コピー元リポジトリのルートから worktree にコピーする。

> 注意: このステップは `cd "$WT"` する前（カレントがコピー元リポジトリ内）に実行すること。
> `git rev-parse --show-toplevel` でコピー元のルートを確定してからコピーする。

```bash
SRC=$(git rev-parse --show-toplevel)
for f in .env mise.local.toml; do
  if [ -f "$SRC/$f" ]; then
    cp "$SRC/$f" "$WT/$f"
    echo "copied $f to worktree"
  else
    echo "$f はコピー元に存在しないためスキップ"
  fi
done
```

### 8. 依存関係の自動セットアップ

worktree のルートで lockfile を検出し、対応するインストールコマンドを worktree 内で実行する。
（モノレポ等でルート直下に lockfile が無い場合はスキップし、その旨を報告する。）

```bash
cd "$WT"
if   [ -f pnpm-lock.yaml ];        then echo "pnpm install を実行";        pnpm install
elif [ -f yarn.lock ];             then echo "yarn install を実行";        yarn install
elif [ -f bun.lockb ];             then echo "bun install を実行";         bun install
elif [ -f package-lock.json ];     then echo "npm ci を実行";              npm ci
elif [ -f uv.lock ];               then echo "uv sync を実行";             uv sync
elif [ -f poetry.lock ];           then echo "poetry install を実行";      poetry install
elif [ -f Cargo.lock ];            then echo "cargo fetch を実行";         cargo fetch
elif [ -f go.sum ];                then echo "go mod download を実行";     go mod download
else echo "ルート直下に対応する lockfile が見つからないため依存セットアップはスキップしました"; fi
```

> 注意: JS 系で `node_modules/.bin/xxx` を直接呼ばず、必ずパッケージマネージャのランナー経由で実行する（プロジェクトの規約に従う）。

### 9. 完了報告

ユーザーに以下を伝える:

- 作成したブランチ名と基点（`origin/<main>` の最新）
- worktree の絶対パス
- コピーしたローカル設定ファイル（`.env` / `mise.local.toml`、またはスキップした旨）
- 実行した依存セットアップの内容（またはスキップした旨）
- 次のアクション例（`cd <worktree path>` で作業開始、`gwq cd <branch>` で移動）

## 失敗時のロールバック

`gwq add` が失敗した場合、手順5で作成したローカルブランチが残ることがある。不要なら削除する:

```bash
git branch -D "$BRANCH"
```

## 削除の手順

`gwq remove` で worktree を削除する。デフォルトでは worktree ディレクトリのみ削除し、ブランチは残す。

### 1. 削除対象の確定

- skill の引数でブランチ名（または pattern）が渡されていればそれを使い、変数 `BRANCH` として扱う。
- 未指定なら、現在の worktree 一覧を提示してユーザーに対象を選んでもらう。

```bash
gwq list
```

### 2. 削除前の安全確認

対象 worktree に未コミット・未 push の変更が残っていないかを確認する。

```bash
WT=$(gwq get "$BRANCH")
echo "target worktree: $WT"
git -C "$WT" status --short
git -C "$WT" log --oneline @{u}.. 2>/dev/null || echo "(upstream 未設定、または未 push のコミット判定不可)"
```

- **未コミットの変更や未 push のコミットがある場合は、勝手に削除せず必ずユーザーに確認する。**
- 何を消すと失われるのかを明示してから承認を得る。

### 3. マージ済みか確認（ブランチ削除の判断材料）

ブランチ削除を伴う場合や、未 push コミットが残っている場合は、その内容が既に main に取り込まれているかを確認する。
**squash / rebase merge では元コミットの SHA が変わり `git branch -d` や `merge-base --is-ancestor` では「未マージ」と判定される**ため、SHA だけで判断せず PR と変更内容ベースで確認する。

```bash
# 1. デフォルトブランチを最新化
MAIN=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
[ -z "$MAIN" ] && { git show-ref --verify --quiet refs/remotes/origin/main && MAIN=main || MAIN=master; }
git fetch origin "$MAIN" 2>&1 | tail -1

# 2. SHA ベースの素朴な判定（merge commit 方式ならこれで足りる）
git merge-base --is-ancestor "$BRANCH" "origin/$MAIN" 2>/dev/null \
  && echo "origin/$MAIN に取り込み済み (fast-forward/merge-commit)" \
  || echo "SHA 上は未マージ → squash/rebase の可能性あり。PR と変更内容を確認する"

# 3. gh があれば head ブランチ名で PR の MERGED 状態を確認（squash merge も拾える）
if command -v gh >/dev/null 2>&1; then
  gh pr list --state all --head "$BRANCH" \
    --json number,title,state,mergedAt,mergeCommit 2>/dev/null
fi

# 4. 念のため変更ファイルが origin/<main> に反映済みかを実ファイルで確認
for f in $(git diff --name-only "origin/$MAIN...$BRANCH" 2>/dev/null); do
  git cat-file -e "origin/$MAIN:$f" 2>/dev/null \
    && echo "反映済: $f" \
    || echo "未反映: $f （PR に含まれない新規/untracked か、本当に未マージ）"
done
```

- PR が `MERGED` で変更ファイルが全て origin/<main> に反映済みなら、SHA が違っても **内容はマージ済み** と判断してよい。安全にブランチ削除できる。
- 上記いずれかで取り込みが確認できない場合は **未マージ扱い**とし、ブランチ強制削除（`-D` / `--force-delete-branch`）の前に必ずユーザーに確認する。
- untracked ファイルは PR に含まれないため、ここで「未反映」と出たものは worktree 削除で失われる点を明示する。

### 4. ドライランで影響を確認

```bash
gwq remove --dry-run "$BRANCH"
```

- 何が削除されるかを要約してユーザーに報告する。

### 5. worktree の削除

ユーザーの承認を得たあとに実行する。

```bash
# worktree ディレクトリのみ削除（ブランチは残す）
gwq remove "$BRANCH"
```

ブランチも併せて削除したい場合（ユーザーが明示的に希望したときのみ）:

```bash
# worktree とブランチの両方を削除（未マージなら -b だけでは削除されない）
gwq remove -b "$BRANCH"

# 未マージのブランチも強制削除する場合
gwq remove -b --force-delete-branch "$BRANCH"
```

> dirty（未コミット変更あり）で削除を強行する必要がある場合のみ `-f` を付ける。安全確認を省略しないこと。
> 未マージのブランチを削除する場合は、手順3でマージ済みを確認してから `--force-delete-branch` を使う。

### 6. 後始末（prune）

削除済み worktree のメタ情報が残っている場合は掃除する。

```bash
gwq prune
```

### 7. 完了報告

ユーザーに以下を伝える:

- 削除した worktree のパスとブランチ名
- ブランチを残したか/削除したか（マージ済みかの確認結果も添える）
- `prune` を実行したか
- 未コミット変更・未マージ等で削除を見送った場合はその旨
