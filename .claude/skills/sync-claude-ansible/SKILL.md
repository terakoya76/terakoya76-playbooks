---
name: sync-claude-ansible
description: ローカル ~/.claude/ 配下の Claude Code 設定 (CLAUDE.md, settings.json, mcp.json, agents/, hooks/, rules/, skills/) を、ansible が管理する terakoya76-playbooks リポジトリの roles/dotfiles/files/claude/ にミラーする。「ansible に反映」「claude config を sync」「dotfiles に取り込み」等と依頼されたとき、あるいは local で skill / agent / settings を更新した直後に使う。
allowed-tools: Read, Bash(pwd:*), Bash(ls:*), Bash(test:*), Bash(stat:*), Bash(diff:*), Bash(rsync:*), Bash(cp:*), Bash(grep:*), Bash(git status:*), Bash(git diff:*)
---

# Sync Claude Config to Ansible

ローカルの `~/.claude/` 設定を、ansible が管理する `roles/dotfiles/files/claude/` にコピー（ミラー）する skill。
ansible を再実行すれば他マシンや初期化後の自分にも同じ設定が再現できる状態を保つことが目的。

## 前提

- 実行 cwd が `terakoya76-playbooks` リポジトリ直下であること（`ansible.cfg` と `roles/dotfiles/files/claude/` が存在）。それ以外なら中断してユーザーに伝える。
- 同期は **片方向**: `~/.claude/` (source) → `roles/dotfiles/files/claude/` (dest)。逆向きは行わない。
- ミラー方針: dest にあって source に無いものは **削除** する（`rsync --delete` 相当）。削除した skill / agent / rule が ansible 側に残骸として残らないようにするため。
- commit は **行わない**。同期完了後、ユーザーが diff を確認してから自分で commit する。

## 対象

ファイル:
- `~/.claude/CLAUDE.md` → `roles/dotfiles/files/claude/CLAUDE.md`
- `~/.claude/settings.json` → `roles/dotfiles/files/claude/settings.json`
- `~/.claude/mcp.json` → `roles/dotfiles/files/claude/mcp.json`

ディレクトリ（mirror。末尾の `/` を必ず付ける）:
- `~/.claude/agents/` → `roles/dotfiles/files/claude/agents/`
- `~/.claude/hooks/` → `roles/dotfiles/files/claude/hooks/`
- `~/.claude/rules/` → `roles/dotfiles/files/claude/rules/`
- `~/.claude/skills/` → `roles/dotfiles/files/claude/skills/`

これ以外の `~/.claude/` 配下（history.jsonl, sessions/, statsig/, projects/, tasks/, todos/, cache/, file-history/, backups/, plans/, plugins/, shell-snapshots/, session-env/, telemetry/, .credentials.json 等）は **絶対に触らない**。実行時データであり、リポジトリで管理する対象ではない。

## 実行ワークフロー

### 1. Pre-flight

並列で確認する（独立なので 1 メッセージ内で並列実行）:

- `pwd` → 末尾が `terakoya76-playbooks` か
- `test -f ansible.cfg && test -d roles/dotfiles/files/claude && echo ok`
- `test -d ~/.claude && echo ok`

いずれか満たさない場合は中断し、何が無いかを 1 行でユーザーに伝える。
（例: 「`roles/dotfiles/files/claude/` が見つかりません。playbooks リポジトリ直下で実行してください」）

### 2. Dry-run diff

7 アイテム分の diff を **並列** で取得する。

**ファイル 3 個** (CLAUDE.md, settings.json, mcp.json):

```bash
diff -u roles/dotfiles/files/claude/<name> ~/.claude/<name>
```

差分が無ければ exit 0、あれば patch 形式。巨大な場合は冒頭 50 行程度に切る判断をしてよい（要約はユーザー提示時に行う）。

**ディレクトリ 4 個** (agents, hooks, rules, skills):

```bash
rsync -an --delete --itemize-changes ~/.claude/<name>/ roles/dotfiles/files/claude/<name>/
```

`-a` mirror, `-n` dry-run, `--delete` で dest 側余剰を可視化, `--itemize-changes` で行頭フラグを得る。

`--itemize-changes` の行頭フラグの読み方:
- `>f` 始まり: source → dest にファイル送信（新規 or 更新）
- `>d` 始まり: source → dest にディレクトリ送信
- `*deleting` 始まり: dest 側で削除される（source に無いため）
- `cd+++++++++` のようなパターン: 新規ディレクトリ作成
- 何も出力されない: 同期不要

### 3. secret スキャン

適用前に diff 内容を簡易チェックする。次のパターンが現れたらユーザー提示時に **強調警告**:

- `sk-`, `sk_live_`, `sk_test_` (Anthropic / OpenAI / Stripe 系)
- `ghp_`, `gho_`, `ghs_`, `github_pat_` (GitHub token)
- `AKIA[0-9A-Z]{16}` (AWS access key)
- `xoxb-`, `xoxp-` (Slack)
- `Bearer ` + 長い文字列
- `"password"`, `"api_key"`, `"secret"` の値が空文字以外

ヒットした場合: 該当ファイル名と該当行を提示し、「commit 前に環境変数化したほうがよくないか」と問う。ユーザーがそれでも進めると明言したら適用する。

### 4. ユーザーに提示

1 メッセージで以下のフォーマットにまとめる:

```
## 同期プレビュー (~/.claude/ → roles/dotfiles/files/claude/)

### ファイル
- CLAUDE.md: <変更なし | N 行差分>
- settings.json: <変更なし | N 行差分>
- mcp.json: <変更なし | N 行差分>

### ディレクトリ
- agents/: 追加 N / 更新 N / 削除 N
- hooks/: 追加 N / 更新 N / 削除 N
- rules/: 追加 N / 更新 N / 削除 N
- skills/: 追加 N / 更新 N / 削除 N

### 削除されるもの（dest 側に残っているが source に無い）
- roles/dotfiles/files/claude/skills/<old-skill>/
- roles/dotfiles/files/claude/rules/<old-rule>.md
（無ければこのセクションごと省略）

### secret 警告（あれば）
- settings.json:23 に "sk-..." 風の文字列。commit 前に確認推奨

---
適用してよいか? (yes / 修正指示 / "skip <名前>" で個別除外可)
```

差分が全く無い場合: 「全項目で差分なし。同期不要です」とだけ伝えて skill 終了。

### 5. 適用

承認後（"yes" / 「適用して」/「OK」等）、各アイテムを順次適用する。`skip <名前>` 指示があれば該当のみ除外。

**ファイル**:

```bash
cp -f ~/.claude/<name> roles/dotfiles/files/claude/<name>
```

**ディレクトリ**:

```bash
rsync -a --delete ~/.claude/<name>/ roles/dotfiles/files/claude/<name>/
```

`--delete` を必ず付ける（ミラー方針）。末尾 `/` も忘れない。
ファイルモードは ansible 側 task が `mode: "0755"` で上書きするため、source のモードを保つ必要はない。

### 6. 完了レポート

`git status --short -- roles/dotfiles/files/claude/` を実行し、変更ファイル数を数える。

出力は 2 行で締める:

```
同期完了: <N> 件のファイルが変更されました
次: `git diff -- roles/dotfiles/files/claude/` で確認 → 問題なければ commit
```

## してはいけないこと

- ユーザー承認前に書き込み系コマンド（`cp`, `rsync` の `-n` 無し）を実行しない
- ansible → local の逆方向同期はこの skill では行わない（別 skill にすべき）
- `~/.claude/` 配下の対象外ファイル（history.jsonl, sessions/, statsig/, projects/, tasks/, todos/, .credentials.json 等）は読まない・触らない
- `--delete` を外す独自判断はしない（ミラー方針が崩れる）。意図的に dest 側のファイルを残したい場合は `skip <名前>` で対象アイテム自体を除外する
- 同期完了後に `git add` / `git commit` を勝手に走らせない
- ansible task（`roles/dotfiles/tasks/main.yml`）の編集はしない（対象が増減したら別途相談）

## エッジケース

- **source に新規ファイル**: 通常通り追加。新しい skill / agent / rule を追加した直後の利用想定
- **dest 側にしか無いファイル**: `--delete` で消える。プレビューで明示し、残したい場合は `skip` を促す
- **`~/.claude/agents/` が空ディレクトリ**: source が空なら dest も空にする（mirror）。ただし source 自体が存在しない場合は pre-flight で中断
- **改行コードや末尾改行のみの差分**: `diff -u` で実差分 0 行なら「変更なし」扱い
- **巨大な diff**（settings.json が数百行変わる等）: 全行貼らず、追加 / 削除の代表行 + 「他 N 行」で要約
- **`.git` や `node_modules` らしきもの**: 対象 7 アイテム配下にあるはずがないが、もし出現したら警告（ユーザーがミスっている可能性）
- **CLAUDE.md が無いマシン**: skip。Pre-flight ではファイル単位で存在チェックし、無いものは静かに対象から外す（中断はしない）
- **rsync が無い環境**: 中断してユーザーに `rsync` のインストールを案内（mac/Linux ともに標準で入っているはずだが念のため）
