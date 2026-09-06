---
name: query-obsidian-note
description: Obsidian vault からノートを検索・読み取りする。タイトル / ファイル名で開く、タグで絞る、本文キーワード検索、特定ノートへの backlink 検索、ディレクトリ配下の一覧、`[[wiki-link]]` を辿った関連ノート取得に対応する。ユーザーが「Obsidian で〜を検索して」「vault の〜ノートを見せて」「〜タグのノート一覧」「このノートに link してるノートは」「backlink を出して」等と依頼したとき、あるいは vault 内の既存ノートを内容ベースで参照したいときに使う。引数で検索モードとクエリを受け取れる。読み取り専用で、ファイルの作成・編集は行わない。新規作成・追記は write-obsidian-note skill で行う。
---

# query-obsidian-note

Obsidian vault からノートを **検索・読み取り** する skill。書き込みは行わない（新規作成・追記は `write-obsidian-note` skill）。

用途に応じて以下のモードを使い分ける:

- [1. タイトル / ファイル名で開く](#1-タイトル--ファイル名で開く)
- [2. タグで絞る](#2-タグで絞る)
- [3. 本文キーワード検索](#3-本文キーワード検索)
- [4. backlink 検索](#4-backlink-検索特定ノートへリンクしているノートを見つける)
- [5. ディレクトリ配下の一覧](#5-ディレクトリ配下の一覧)
- [6. `[[wiki-link]]` を辿って関連ノートを取得](#6-wiki-link-を辿って関連ノートを取得)

## 前提

- vault は git リポジトリのカレントもしくは祖先ディレクトリにあり、ルート直下に `.obsidian/` を持つ。
- vault ルートに `CLAUDE.md` や `Rules/` があれば、そこの命名・タグ規則を **必ず読む**。ノート種別ごとの配置ディレクトリを理解するのに使う。
- 検索は `rg`（ripgrep）を第一選択。無ければ `grep -R`。

## Vault ルートを特定

```bash
DIR=$(pwd)
VAULT=""
while [ "$DIR" != "/" ]; do
  if [ -d "$DIR/.obsidian" ]; then VAULT="$DIR"; break; fi
  DIR=$(dirname "$DIR")
done
[ -z "$VAULT" ] && { echo "Obsidian vault (.obsidian/) が見つかりません。vault のパスを指定してください"; exit 1; }
echo "vault: $VAULT"
```

## 共通の除外パス

vault 内の全文検索で除外すべきパス:

```
.obsidian/  .trash/  .git/  node_modules/
```

`rg` は `.gitignore` を尊重するので `.git/` は自動除外されるが、`.obsidian/` は明示除外する。

```bash
RG_OPTS="-uu --glob=!.obsidian --glob=!.trash --glob=!node_modules"
```

## 1. タイトル / ファイル名で開く

ユーザーが特定のノート名を指定した場合。

```bash
# 部分一致で候補を列挙
find "$VAULT" -type f -name '*.md' -not -path '*/.obsidian/*' -not -path '*/.trash/*' \
  | grep -i -- "$QUERY"
```

- 候補が 1 件 → `Read` で開いて内容を提示。
- 複数 → 上位候補（作成日時が新しい順など）を提示し、どれを開くかユーザーに確認。
- 0 件 → `obsidian-search` の別モード（本文検索・タグ検索）を試すことを提案。

ファイル名の命名規則（例: FleetingNote は `YYYYMMDDHHMM_タイトル.md`）を活かして、タイトル部分だけでヒットさせたい場合はプレフィックスを無視する grep パターンにする。

## 2. タグで絞る

Obsidian のタグは 2 箇所に現れる:

- フロントマター内 `tags:` の YAML リスト
- 本文中の `#tag`

両方を検索する。

```bash
TAG="$1"  # ハッシュ抜きの文字列（例: storage）

# フロントマター内 tags: 配下（次の --- または key: が来るまでの範囲に含まれる `- <tag>`）
rg $RG_OPTS -l -U --multiline-dotall \
  "^---$.*?^tags:\s*$(?:\n(?:\s*-.*)+)?\s*-\s*${TAG}\b.*?^---$" "$VAULT"

# 本文中の #tag（コードブロックや URL のフラグメント # と区別するため、単語境界を要求）
rg $RG_OPTS -l "(^|\s)#${TAG}\b" "$VAULT"
```

- 上記 2 つの結果を union して、重複除去。
- ヒットしたファイルの一覧（絶対パスまたは vault 相対パス）を提示。件数が多いときは種別ディレクトリで集計しつつ上位を提示。

タグ表記のルール（vault の `Rules/` で定義される）: lowercase、スペース不可、`-` / `_` 区切り。検索クエリも lowercase に正規化する。

## 3. 本文キーワード検索

```bash
rg $RG_OPTS -l -i -- "$QUERY" "$VAULT"
```

- 件数が多いとき（> 20）は、種別ディレクトリごとに件数集計してからユーザーに絞り込みを促す。
- 上位数件については `rg -C 2` で該当行前後のコンテキストを付けて提示すると読みやすい。

複数語 AND 検索:

```bash
rg $RG_OPTS -l -i -- "$WORD1" "$VAULT" | xargs -r rg -l -i -- "$WORD2"
```

## 4. backlink 検索（特定ノートへリンクしているノートを見つける）

対象ノートのファイル名から、拡張子とタイムスタンプ prefix を除いた **タイトル部分** を抽出。それを `[[...]]` の中で参照している他ノートを検索する。

```bash
# 例: FleetingNote/202607151100_写真バックアップ用ストレージ選定.md
TARGET="$VAULT/FleetingNote/202607151100_写真バックアップ用ストレージ選定.md"

# ベース名から .md を除いた文字列 (Obsidian は拡張子なしでも参照可)
BASE=$(basename "$TARGET" .md)
# タイムスタンプ prefix ありのパターンとタイトルのみのパターンの両方を試す
TITLE_ONLY=$(printf '%s' "$BASE" | sed -E 's/^[0-9]{8,14}_//')

rg $RG_OPTS -l -F "[[${BASE}]]" "$VAULT"
rg $RG_OPTS -l -F "[[${TITLE_ONLY}]]" "$VAULT"

# 埋め込み ![[...]] や alias 記法 [[name|alias]] も拾う
rg $RG_OPTS -l "\[\[${BASE}(\||\]\])" "$VAULT"
rg $RG_OPTS -l "\[\[${TITLE_ONLY}(\||\]\])" "$VAULT"
```

- 上記の結果を union & 重複除去。
- 対象ノート自身は除外する。
- ヒット数と、各ヒットで backlink が現れる行番号を提示。

## 5. ディレクトリ配下の一覧

種別ディレクトリ（`FleetingNote/`, `LiteratureNote/`, `PermanentNote/`, `IndexNote/` など）や `Daily/YYYY-MM/` 配下の一覧を返す。

```bash
KIND="FleetingNote"
find "$VAULT/$KIND" -type f -name '*.md' -printf '%T@ %p\n' \
  | sort -rn | head -30 | cut -d' ' -f2-
```

- 新しい順で最大 30 件を既定に。ユーザーが件数指定したらそれに合わせる。
- タイトルとタグ（フロントマターから抽出）を並べて提示すると見やすい:

```bash
for f in $FILES; do
  T=$(rg -N -m1 "^title:\s*" "$f" | sed 's/^title:\s*//')
  echo "$f  |  $T"
done
```

## 6. `[[wiki-link]]` を辿って関連ノートを取得

特定ノートに書かれた `[[link]]` を抽出し、それぞれ vault 内で解決する。

```bash
TARGET="$1"

# `[[...]]` から link 名を抽出（alias `[[name|alias]]` は name 部分だけ取る）
rg -oN --no-heading "\[\[([^\]|#]+)" "$TARGET" -r '$1' | sort -u
```

- 抽出した各 link 名について、`find` でファイルパスを解決:

```bash
for name in $LINKS; do
  # ベース名一致 or タイムスタンプ prefix 付きのファイル名末尾一致
  find "$VAULT" -type f -name "*${name}.md" -not -path '*/.obsidian/*'
done
```

- link 先が見つからないもの（未作成の「予定リンク」）はその旨を報告。
- ユーザーの依頼に応じて、リンク先のうち上位数件を `Read` で開いて要約する。

## 出力のまとめ方

- 件数が少ない（<= 5）: 各ファイルのパスとタイトルとタグを列挙。
- 件数が中程度（6〜30）: 種別ディレクトリごとに集計して概観を出し、ユーザーに詳細表示を尋ねる。
- 件数が多い（> 30）: クエリを絞ってもらう提案を先に出す。全件は列挙しない。

## してはいけないこと

- ファイルの作成・編集・削除・リネームを行わない（それは `obsidian-note` skill の責務）。
- vault 外のファイルを検索対象に含めない。
- `.obsidian/`, `.trash/` の中身をユーザーに提示しない（設定・削除済みのため）。
- タグやリンクの表記を勝手に正規化してユーザーに提示しない（vault 内の表記のまま扱う）。検索の内部処理での正規化は可。
