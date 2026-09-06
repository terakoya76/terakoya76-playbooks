---
name: write-obsidian-note
description: Obsidian vault にノートを追加する。FleetingNote / LiteratureNote / PermanentNote / IndexNote に対応し、vault 側の命名規則・フロントマター・タグルールに従ってファイルを作成する。ユーザーが「Obsidian にノート追加して」「vault に FleetingNote 作って」「LiteratureNote を追加して」等と依頼したとき、あるいは直前に作った vault ノートに「追記して」と依頼されたときに使う。引数でノート種別・タイトル・source URL・タグを受け取れる。Daily ノートは対象外。既存ノートの検索・読み取りは query-obsidian-note skill で行う。
---

# write-obsidian-note

Obsidian vault に新規ノートを **作成** する、または既存ノートに **追記** する skill。ノート種別に応じた配置ディレクトリ・命名規則・フロントマターを適用する。

- 新規作成: [作成の手順](#作成の手順)
- 既存への追記: [追記の手順](#追記の手順)

## 前提

- vault は git リポジトリのカレントもしくは祖先ディレクトリにあり、ルート直下に `.obsidian/` を持つ。
- vault ルートに `CLAUDE.md` や `Rules/` があれば、そこの命名・タグ規則が **最優先**。この skill の記述はそれと矛盾しないデフォルト。
- **Daily ノートは対象外**。日次ノートの作成・追記は本 skill では扱わない。

## ノート種別と配置

| 種別 | ディレクトリ | ファイル名 |
|---|---|---|
| FleetingNote | `FleetingNote/` | `YYYYMMDDHHMM_<タイトル>.md` |
| LiteratureNote | `LiteratureNote/` | `YYYYMMDDHHMM_<タイトル>.md` |
| PermanentNote | `PermanentNote/` | `YYYYMMDDHHMM_<タイトル>.md` |
| IndexNote | `IndexNote/` | `<タイトル>.md` |

- 依頼から種別を判別できない場合の既定は **FleetingNote**。
- 対応ディレクトリが vault に無ければユーザーに配置先を確認する。勝手にディレクトリを作らない。

## 作成の手順

### 1. Vault ルートを特定

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

### 2. Vault のローカルルールを読む

`$VAULT/CLAUDE.md` と `$VAULT/Rules/` に目を通し、命名・タグ・禁止タグ・その他の制約を把握する。以降の手順は vault 側ルールを優先する。

### 3. ノート種別・タイトル・タグ・source を確定

skill 引数または依頼文から抽出。不足があれば以下の順で解決:

- **種別**: 依頼文の語彙から推定（「メモ」「fleeting」「作業メモ」→ FleetingNote、「読書」「記事」「文献」→ LiteratureNote、「洗練」「永続」→ PermanentNote、「目次」「index」→ IndexNote）。判別不能なら FleetingNote を既定として提示して確認。
- **タイトル**: 内容から簡潔な日本語見出しを提案し、ユーザーに確認。
- **source**: URL・書籍名・記事名などが会話にあれば拾う。無ければ空。
- **タグ**: ユーザー指定を最優先。指定が無ければコンテンツから 2〜4 個を提案。以下のタグルールを守る:
    - lowercase のみ
    - スペース禁止（`-` か `_`）
    - 最大 5 個
    - 内容タグのみ
    - vault 側で禁止タグが定義されていればそれを避ける（vault 既定の禁止例: `todo`, `routine`, `journal`, `study`, `exercise`）

### 4. ファイルパスを組み立て

タイトルを **安全な形式** に変換してからパスに使う。

```bash
# タイトル: 半角/全角スペース -> "_"、パス区切り文字は除去
SAFE_TITLE=$(printf '%s' "$TITLE" | tr ' 　' '__' | tr -d '/\\')
```

種別ごとにパスを決定:

```bash
case "$KIND" in
  FleetingNote|LiteratureNote|PermanentNote)
    TS=$(date +%Y%m%d%H%M)
    FILE="$VAULT/$KIND/${TS}_${SAFE_TITLE}.md"
    ;;
  IndexNote)
    FILE="$VAULT/IndexNote/${SAFE_TITLE}.md"
    ;;
esac
echo "target: $FILE"
```

### 5. 既存ファイル衝突チェック

```bash
if [ -e "$FILE" ]; then
  echo "既に存在: $FILE"
  echo "追記するか、別名で作るか、上書きするかをユーザーに確認する"
  exit 1
fi
```

- 衝突したときは、勝手に上書きせず必ずユーザーに確認する。追記が意図されているなら [追記の手順](#追記の手順) に切り替える。

### 6. フロントマターと本文を生成

既定フォーマット:

```markdown
---
title: <TITLE>
source: <SOURCE_or_empty>
created: <YYYY-MM-DD>
tags:
  - <tag1>
  - <tag2>
---

<本文>
```

- `created` は `date +%Y-%m-%d` の結果。
- `source` が無ければ空（キー自体は残す。既存フォーマットと揃えるため）。

### 7. 書き込み

`Write` ツールで作成する。`echo >` や `cat <<EOF` は使わない。

### 8. 完了報告

- 作成したファイルの絶対パス
- 適用した種別・タグ・source
- vault 内で関連しそうな既存ノートを見つけたら `[[別ノート名]]` 形式のリンク候補を **提案** する（勝手に追記はしない）

## 追記の手順

「同じノートに追記して」「このノートに続けて書いて」と依頼された場合:

### 1. 対象ファイルの確定

- 直前の会話で作成・言及した vault 内のファイルパスがあればそれを対象にする。
- 無ければユーザーに対象ファイル（相対パス可）を確認する。
- Daily ノートが対象になった場合は本 skill では扱わない旨を伝えて中断する。

### 2. 追記位置の確定

- 依頼文に「〜の下に」「末尾に」等の指定があればそれに従う。
- 指定が無ければ **末尾追記**。
- フロントマターは **触らない**（tags 追加をユーザーが明示的に依頼したときのみ更新可）。

### 3. 追記内容の整形

- 元ノートの見出しレベル・箇条書き・表記スタイルに合わせる。
- 新規セクションを足すなら適切な見出しレベル（既存の最上位が `##` なら `##` で始める）。

### 4. 書き込み

`Edit` ツールで既存ファイルに追記。`old_string` はファイル末尾の一意な行、`new_string` はそれ＋新規セクションにする。

### 5. 完了報告

- 追記したファイルの絶対パス
- 追加したセクション見出し

## してはいけないこと

- Vault のディレクトリ構造を勝手に変更（新規ディレクトリ作成含む）しない。ユーザーに確認する。
- 既存ファイルを黙って上書きしない。
- vault 側ルール（`CLAUDE.md`, `Rules/`）に反するタグ・命名を勝手に付けない。
- コミットや `git add` を skill 内で行わない（vault が git 管理でも別責務）。
- タグに絵文字や大文字を含めない。
- Daily ノートの作成・追記は行わない（別の仕組みで扱う）。
