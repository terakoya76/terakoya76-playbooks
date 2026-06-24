---
name: claude-profile
description: Claude Code の認証アカウントを切り替えるための profile dir を管理する。`CLAUDE_CONFIG_DIR` で参照する `~/.claude`（private）と `~/.claude-<name>`（会社等）を分離しつつ、認証以外の設定（CLAUDE.md, settings.json, mcp.json, rules/, agents/, skills/, commands/, hooks/）は `~/.claude` から symlink して一元管理する。ユーザーが「Claude の認証を切り替えたい」「会社用 Claude profile を作って」等と依頼したときに使う。引数で profile 名（例: `my-company`）を受け取る。env の設定はユーザーの責務で、本 skill は profile dir の作成と symlink のメンテのみを行う。
allowed-tools: Bash, Read, Edit, Write
---

# claude-profile

`CLAUDE_CONFIG_DIR` を使って Claude Code のアカウントを切り替えるための **profile dir 管理 skill**。

- `~/.claude` は **private アカウント**（デフォルト）。
- `~/.claude-<name>` は **別アカウント**（例: `~/.claude-my-company`）。
- 認証関連 (credentials, sessions, history, projects, todos, plugins 等) は profile ごとに完全分離。
- 認証以外の共有したい設定 (`CLAUDE.md`, `settings.json`, `mcp.json`, `rules/`, `agents/`, `skills/`, `commands/`, `hooks/`) は `~/.claude` から symlink で取り込み、一元管理する。

## スコープ外

**`CLAUDE_CONFIG_DIR` の export は本 skill では扱わない**。
ユーザーは direnv / shell alias / 手動 export / mise hook など好きな方法で設定する。skill は profile dir の中身だけを面倒見る。

## 前提

- macOS / Linux。
- `~/.claude` が既に存在し、private アカウントで login 済み。
- macOS では各 profile の credentials は Keychain に **`CLAUDE_CONFIG_DIR` ごとに別エントリ**として保存される（Claude Code が config dir 単位で service name を分けるため）。`.credentials.json` は通常生成されない。

## サポートする operation

| operation | 説明 |
|---|---|
| `setup <name>` | profile 用 dir `~/.claude-<name>` を作成 (idempotent) し、shared 項目を `~/.claude` から symlink。何度実行しても安全。 |
| `list` | `~/.claude-*` を列挙し、それぞれの shared 項目の symlink 状態を表示。 |

引数が省略された場合は **operation = `setup`**、name はユーザーに尋ねる。

`skills/` `agents/` `commands/` `hooks/` `rules/` は **directory ごと symlink** するので、`~/.claude/skills/foo` のように内部にファイルを足しても profile 側から自動で見える。symlink を貼り直す専用 operation は持たない (top-level の `SHARED` 配列を変えたとき等は `setup` を再実行すれば idempotent に反映される)。

## shared / per-profile の境界

**shared (symlink する項目 — `~/.claude` を実体に)**

```
CLAUDE.md
settings.json
mcp.json
agents/
commands/
hooks/
rules/
skills/
```

**per-profile (symlink しない — 各 dir で独立)**

```
.credentials.json        # Linux のみ。macOS は Keychain。
projects/
sessions/
todos/
plans/
history.jsonl
statsig/
telemetry/
debug/
cache/
shell-snapshots/
file-history/
session-env/
paste-cache/
tasks/
backups/
plugins/
mcp-needs-auth-cache.json
policy-limits.json
remote-settings.json
stats-cache.json
.last-cleanup
.last-update-result.json
.update.lock
.DS_Store
```

`~/.claude` 直下にあって上記いずれにも分類されない unknown 項目が出てきたら、**勝手に symlink せず** ユーザーに尋ねる（後述）。

## setup の手順

### 1. profile 名の確定

- 引数で profile 名 (`NAME`) が渡されていればそれを使う。未指定なら `AskUserQuestion` で尋ねる。
- `NAME` は `[a-z0-9-]+` のみ許可。`PROFILE_DIR="$HOME/.claude-$NAME"` とする。

### 2. 前提チェック

```bash
test -d "$HOME/.claude" || { echo "~/.claude が存在しません。先に private アカウントで claude を一度起動して setup してください。"; exit 1; }
```

### 3. profile dir 作成 (idempotent)

```bash
mkdir -p "$PROFILE_DIR"
chmod 700 "$PROFILE_DIR"
```

### 4. shared 項目の symlink 化

shared 項目ごとに以下のロジック:

```bash
SHARED=(CLAUDE.md settings.json mcp.json agents commands hooks rules skills)

for item in "${SHARED[@]}"; do
  src="$HOME/.claude/$item"
  dst="$PROFILE_DIR/$item"

  # ~/.claude 側に無い項目は skip
  [ -e "$src" ] || { echo "skip (source missing): $item"; continue; }

  if [ -L "$dst" ]; then
    # 既に symlink。指す先が正しければ何もしない。違えば貼り直す。
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "ok (already linked): $item"
      continue
    fi
    rm "$dst"
  elif [ -e "$dst" ]; then
    # 実体がある。ユーザーに確認 (上書きしない)
    echo "WARN: $dst は実体 (非 symlink) です。手動で確認してください。skip。"
    continue
  fi

  ln -s "$src" "$dst"
  echo "linked: $item -> $src"
done
```

- **絶対パスで symlink を貼る** (`$HOME/.claude/...`)。relative にしない（profile dir を移動する想定が薄いので、絶対の方が事故りにくい）。
- 既存実体は **絶対に上書きしない**。WARN 出してユーザーに判断を委ねる。

### 5. unknown 項目の検知

```bash
KNOWN_SHARED=(CLAUDE.md settings.json mcp.json agents commands hooks rules skills)
KNOWN_PER_PROFILE=(.credentials.json projects sessions todos plans history.jsonl statsig telemetry debug cache shell-snapshots file-history session-env paste-cache tasks backups plugins mcp-needs-auth-cache.json policy-limits.json remote-settings.json stats-cache.json .last-cleanup .last-update-result.json .update.lock .DS_Store)

# ~/.claude 直下を列挙して、上記いずれにも入らないものを抽出
# 検出したものはユーザーに「shared 扱いにするか per-profile 扱いにするか」尋ねる
```

迷ったら **per-profile 扱い (= 何もしない)** をデフォルトとして提案する。

### 6. 結果サマリと次アクションの案内

最後に以下を表示する:

- 作成/更新した profile dir のパス
- 貼った symlink の一覧
- **ユーザーが次にやること** (env 設定 + 初回 login)

例:

```
profile dir: ~/.claude-my-company
linked: CLAUDE.md, settings.json, mcp.json, agents, commands, hooks, rules, skills

次のステップはユーザー側で実施してください:

1. `CLAUDE_CONFIG_DIR=$HOME/.claude-my-company` を該当 repo / shell で export する
   （direnv の .envrc, shell alias, 手動 export など、好みの方法で）

2. その shell から `claude` を起動して会社アカウントで login

3. login 後、`ls ~/.claude-my-company/sessions ~/.claude-my-company/projects` で
   session/project state が作られていることを確認
```

env の export 方法を skill が決め打ちで案内しない。ユーザーが既に方針 (direnv, alias, mise 等) を持っている前提で進める。

## list の手順

```bash
for d in "$HOME"/.claude-*; do
  [ -d "$d" ] || continue
  echo "=== $d ==="
  for item in CLAUDE.md settings.json mcp.json agents commands hooks rules skills; do
    target="$d/$item"
    if [ -L "$target" ]; then
      echo "  $item -> $(readlink "$target")"
    elif [ -e "$target" ]; then
      echo "  $item (実体 / 非 symlink)"
    else
      echo "  $item (なし)"
    fi
  done
done
```

加えて、現在のシェルで `CLAUDE_CONFIG_DIR` が何に向いているか (`echo "${CLAUDE_CONFIG_DIR:-(unset = ~/.claude)}"`) も表示すると便利。

## やってはいけないこと

- `~/.claude` の中身を **書き換えない / 削除しない**。本 skill は読み取り側 (symlink source) として扱うだけ。
- 既存の `~/.claude-<name>/` にある実体ファイルを **勝手に消したり symlink で上書きしない**。WARN を出してユーザーに判断させる。
- ユーザーの shell 設定 (`.envrc`, `.zshrc`, `.bashrc`, alias 等) を勝手に編集しない。env 設定はスコープ外。
- shared 項目に **`.credentials.json` / `projects/` / `sessions/` / `history.jsonl` / `plugins/` を絶対に含めない**。アカウント混線の原因になる。

## 動作確認のチェックリスト

setup 後、ユーザー側で env を設定したうえで以下を確認:

1. 該当 shell で `echo $CLAUDE_CONFIG_DIR` が `~/.claude-<name>` を指している。
2. `claude` を起動して **新規 login flow** が走ること (= 認証が分離されている証拠)。
3. login 後、`ls ~/.claude-<name>/sessions ~/.claude-<name>/projects` に session/project state が作られていること。
4. 別ターミナルで `CLAUDE_CONFIG_DIR` 未設定のまま `claude` 起動すると、private アカウントのまま使えること。
5. `diff <(cat ~/.claude-<name>/CLAUDE.md) <(cat ~/.claude/CLAUDE.md)` が空 (= symlink 経由で共有できている)。

## トラブルシュート

- **アカウントが切り替わらない**: 該当 shell で `echo $CLAUDE_CONFIG_DIR` が空なら env が読まれていない。ユーザー側の export 方法 (direnv allow 忘れ、alias 名違い等) を確認。
- **`claude` が既存 session を引き継いでしまう**: `CLAUDE_CONFIG_DIR` が古いプロセスに焼き付いている。新しい terminal tab を開き直す。
- **Keychain で credentials が衝突**: macOS で同じ Apple ID 下の Keychain に複数 entry が並ぶのは正常。`security find-generic-password -s "Claude Code"` で複数件確認できる。
- **symlink が壊れた / 消えた**: `setup <name>` を再実行すれば idempotent に貼り直される。実体が残っている場合は WARN で skip されるので、手動で退避してから setup する。
