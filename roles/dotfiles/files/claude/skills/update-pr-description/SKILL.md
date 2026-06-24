---
name: update-pr-description
description: 現在の branch に紐づく PR の description を、変更内容にもとづいてわかりやすく書き直す。既存 template のセクション構成・言語・issue 参照は保ったまま、Change Summary / Test/Verification 等を実装に合わせて具体化する。ユーザーが「PR description を更新して」「PR の本文を書き直して」等と依頼したとき、あるいは PR を開いた直後に本文を整えたいときに使う。
allowed-tools: Read, Grep, Glob, Bash(git rev-parse:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh pr edit:*), Bash(gh repo view:*)
---

# Update PR Description

現在の branch に紐づく Pull Request の本文を、実装に即したわかりやすい内容に更新する skill。
「何を / なぜ / どう確認したか」が第三者に伝わる状態まで書き換えるが、**元の意図・参照リンク・template 構成は保つ**。

## 前提

- `gh` CLI が認証済みであること
- 現在の branch が push されていて、対応する PR が存在すること（無ければ skill を抜けてユーザーに `gh pr create` を案内する）
- 本文の言語は「元の PR 本文」に合わせる。新規で書き起こす場合はリポジトリの最近の PR に合わせる（このリポジトリでは日本語）

## 実行ワークフロー

以下の順に実行する。各ステップの中間結果はユーザーへの最終レポートで要約し、冗長な途中経過は出さない。

### 1. コンテキスト取得

独立なコマンドは**並列**で実行すること。

- 現在の branch 名: `git rev-parse --abbrev-ref HEAD`
- base branch の特定: デフォルトは `main`。リポジトリが他を使っている場合は `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name` で確認
- 現在の PR 情報: `gh pr view --json number,title,body,baseRefName,headRefName,url,state,isDraft,files,additions,deletions`
  - PR が存在しない場合はここで中断し、作成コマンドを案内する
- 差分サマリ: `git log --oneline <base>...HEAD`, `git log <base>...HEAD --stat`, `git diff --stat <base>...HEAD`
- 変更ファイルの内訳を把握するため、必要に応じて `git diff <base>...HEAD -- <path>` で主要ファイルの詳細を追う（巨大な場合は `--stat` に留める）
- リポジトリ PR template: `.github/PULL_REQUEST_TEMPLATE.md`（存在すれば読む）
- 最近の PR スタイル参考: `gh pr list --state merged --limit 3 --json title,body` （言語・構成のトーンを合わせるため）

### 2. 変更内容の分析

取得したコンテキストから、以下を自力で組み立てる（ユーザーに聞き返さず、まず draft する）。

- **目的 / Why**: commit message、issue / ticket 参照（既存本文の `ref.` や `fixes #123` を必ず抜き出す）、branch 名から推定
- **変更点 / What**: 主要な追加・削除・修正を 3〜7 件のビジュレットに整理。ファイル or 機能単位でまとめる（行単位で羅列しない）
- **Change type**: commit の conventional prefix（`feat:` / `fix:` / `refactor:` 等）および diff 内容から判定し、template のチェックボックスを 1 つだけ `[x]` にする
- **Test / Verification**: 新規・変更されたテストファイル（`*.test.ts` 等）、手動確認が必要な箇所を列挙。無ければ「自動テストなし。手動確認手順:」として推定手順を書く
- **注意点 / Additional info**: breaking change、マイグレーション要否、feature flag、依存追加などがあれば挙げる（なければこのセクションは空欄のテンプレ文言のまま残す）

### 3. Draft 生成ルール

#### 3-1. PR template がある場合（最優先）

検出パス（順に探す。最初に見つかったものを採用）:

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE/*.md`（複数ある場合は既存 PR 本文とヘッダが一致するものを選ぶ）
- `docs/pull_request_template.md` / `PULL_REQUEST_TEMPLATE.md`（リポジトリ直下）

template を検出した場合、**以下は厳守**:

- **セクション見出しは template のものをそのまま使う**（`## Change Summary` など、記号・空白も含めて一致させる）
- **template に含まれる全セクションを出力に残す**。並び順も変えない
- **チェックボックス項目 (`- [ ] ...`) は必ず template と同じ行を残し**、該当するものを `- [x]` に変える。勝手に項目を追加・削除しない
  - 判定基準: commit message の conventional prefix（`feat:` / `fix:` / `refactor:` 等）を優先。複数該当する場合は主たるものを 1 つだけ `[x]` に
- **プレースホルダ文（例: "Provide summary of changes with issue number if any."）は、実装に即した本文で置き換える**。空のまま残さない
- **optional と明記されたセクション**（例: `## Additional information / screenshots (optional)`）は、書くことが無ければ template のプレースホルダ文（"Anything for maintainers to be made aware of" 等）のまま残してよい。**削除はしない**
- template にないセクションを独自に増やさない（「## 実装詳細」などを勝手に足さない）
- 既存 PR 本文が template に沿っていない場合でも、**更新後は template に揃える**ことを原則とする。ただし既存本文に含まれる issue 参照・関連 PR リンクは Change Summary 等の該当セクションに移して必ず残す

#### 3-2. template が存在しない場合

以下の標準構成で書く（日本語で書く場合も見出しはこの英語で OK、プロジェクト慣習に合わせる）:

```
## Summary
<1〜3 行。why を中心に>

## Changes
- <箇条書き 3〜7 件>

## Test plan
- <手動確認 or 自動テストの列挙>
```

#### 3-3. 共通ルール

- **既存本文の以下は温存する**:
  - issue / Linear / Notion への参照リンク（`ref.` / `fixes #` / `closes #`）
  - follow-up や関連 PR のリンク
  - 明示的に書かれた「背景」「制約」
- Change Summary は **結論ファースト + 1〜3 行の背景**。長い経緯は箇条書きに落とす
- 箇条書きは「動詞始まり・現在形」で統一（日本語なら「〜を追加」「〜を修正」「〜に対応」）
- ファイル名を本文に書くのは「読者が開きたくなるキーファイル」のみ。全ファイル列挙は diff で見れば済むので書かない
- 絵文字は使わない（ユーザー global rule）
- AI 生成を示すフッター（"Generated with Claude" 等）は**付けない**
- 言語判定: 既存本文に日本語文字（ひらがな・カタカナ・漢字）が一定数あれば日本語、そうでなければ英語。template の英語見出しは見出しだけ英語のまま、本文は判定言語で書いてよい

### 4. ユーザー確認（必須）

`gh pr edit` は **他者から見える共有状態の変更** なので、**適用前に必ず draft を提示して承認を取る**。

提示フォーマット:

```
## 更新案（PR #<番号> / <title>）

<draft 本文をそのまま>

---
差分の主な変更点:
- Change Summary: <旧 → 新の要約>
- Change type: <選んだ type> ([x] に変更)
- Test/Verification: <追加した内容の要約>

適用してよいか？ (yes / 修正指示)
```

ユーザーが `yes` / 「適用して」/「OK」等と答えたら Step 5 へ。
修正指示が入った場合は draft を直して再提示する。

### 5. 適用

ヒアドキュメントで `gh pr edit` に body を渡す。タイトルは **明示依頼がない限り触らない**。

```bash
gh pr edit <number> --body "$(cat <<'EOF'
<draft 本文>
EOF
)"
```

適用後、`gh pr view --json url --jq .url` で URL を表示し、「更新完了: <url>」の 1 行で締める。

## してはいけないこと

- ユーザー承認前に `gh pr edit` を実行しない
- 既存本文の issue 参照・follow-up リンクを黙って消さない
- 推測で issue 番号や担当者名を書き足さない（元本文に無い固有名詞は足さない）
- PR title を勝手に書き換えない（依頼された場合のみ）
- 絵文字・AI 生成フッター・"Co-Authored-By" を足さない
- 巨大な diff を本文にそのまま貼らない（要約する）
- `--no-verify` 相当の「確認スキップ」オプションを使わない

## エッジケース

- **PR が未作成**: 中断して `gh pr create` の案内だけ出す。`/commit` skill や本 skill の range 情報を使って title / body の下書きを提案するところまでは可
- **Draft PR**: そのまま更新して問題ない。状態は変えない
- **複数 PR がヒット**: `gh pr view` は current branch の open PR を返す。無ければ closed を含めて探す前にユーザーに確認
- **base branch が main でない**: `baseRefName` を尊重。diff range は `<baseRefName>...HEAD` を使う
- **commit が 0 件 / base と同一**: 更新する根拠がないので中断し、ユーザーに状況を伝える
- **既存本文が template と大きく乖離**: 原則 template に揃える。ただし既存に書かれた固有情報（issue 参照・背景・関連 PR）は該当セクションへ移して残す。どうしても判断に迷う場合のみユーザーに確認
- **template に `<!-- -->` HTML コメントでの注釈がある**: 注釈はそのまま残す（レビュワー向けガイドなので削除しない）
- **複数 template が存在（`.github/PULL_REQUEST_TEMPLATE/` 以下）**: 既存 PR 本文のセクション構成と最も一致するものを選ぶ。判断つかなければユーザーに確認
