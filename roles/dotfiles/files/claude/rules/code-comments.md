# Code Comment Conventions

コードコメントは **WHY を説明するコメント** と **言語固有のインターフェースコメント** の 2 種類に限定する。それ以外のコメント（WHAT を再説明するもの、変更履歴、TODO の垂れ流し等）は書かない。

## Core Principle

- コードは **WHAT**（何をしているか）を語る。命名と構造で自己説明できるようにする。
- コメントは **WHY**（なぜそうしているか）を語る。コードを読むだけでは分からない意図・制約・背景を残す。
- インターフェース（公開 API）は使う側のために **契約** を書く（JSDoc / docstring / doc comment）。

## 許容されるコメント

### 1. WHY コメント

コードだけでは伝わらない、以下のような情報を残すためのコメント。

- ビジネスルール・ドメイン制約（例: 「税法上、この計算は円未満切り捨て」）
- パフォーマンス上のトレードオフ（例: 「N+1 を避けるためあえて事前フェッチ」）
- 外部システムのバグ・仕様回避（例: 「Safari の bfcache 対策で明示 reload」）
- 一見不自然な実装の理由（例: 「順序依存があるため sort より前に filter」）
- セキュリティ上の意図（例: 「タイミング攻撃対策のため定数時間比較」）
- 参照リンク（RFC, issue, ADR, incident report）

```typescript
// GOOD: WHY - 制約と理由が書かれている
// Stripe webhook は最大 3 回リトライされるため冪等キーで重複を弾く
// https://stripe.com/docs/webhooks/best-practices#retry-logic
if (await hasProcessed(event.id)) return;

// BAD: WHAT - コードを読めば分かる
// event.id で処理済みかチェックする
if (await hasProcessed(event.id)) return;
```

### 2. インターフェースコメント（言語固有ドキュメント）

公開 API（他モジュール・他パッケージから使われる関数・型・クラス）に対して、その言語のドキュメント記法で **契約** を書く。

| 言語               | 記法                    |
| ------------------ | ----------------------- |
| TypeScript / JavaScript | JSDoc (`/** */`)        |
| Python             | docstring (`"""..."""`) |
| Go                 | doc comment (`// FuncName ...`) |
| Rust               | doc comment (`/// ...`) |
| Java               | Javadoc (`/** */`)      |

書く内容:

- この関数が **何を約束するか**（返り値・副作用）
- 前提条件・事後条件
- 例外・エラーケース
- 非自明なパラメータの意味・単位

書かない内容:

- 型システムで表現できる情報の再説明（TypeScript で `@param name {string}` を書き直す等）
- 実装の詳細（呼び出し側が知る必要のない内部処理）

```typescript
// GOOD: 契約（副作用・単位・例外）を書いている
/**
 * 注文を確定し、在庫を減算する。
 *
 * 在庫が不足している場合は `InsufficientStockError` を投げ、
 * どのアイテムが不足したかを `error.items` に含める。
 *
 * @param order - 確定対象の注文
 * @returns 確定後の注文（`confirmedAt` が設定される）
 * @throws {InsufficientStockError} 在庫不足のとき
 */
export async function confirmOrder(order: Order): Promise<Order> { ... }

// BAD: 型を再説明しているだけ
/**
 * 注文を確定する
 * @param order Order 型の注文
 * @returns Order を返す
 */
export async function confirmOrder(order: Order): Promise<Order> { ... }
```

### 3. 内部関数のコメント

公開 API でない private/internal な関数には、原則 JSDoc / docstring を書かない。命名で伝わらない WHY があるときだけ、通常のコメントを 1〜2 行添える。

```typescript
// GOOD: WHY だけ
// 空配列だと reduce が初期値未指定で throw するのでガードする
function averageOrZero(nums: number[]): number { ... }

// BAD: private 関数に契約コメント
/**
 * 平均を計算する。空なら 0。
 * @param nums 数値配列
 * @returns 平均
 */
function averageOrZero(nums: number[]): number { ... }
```

## 書いてはいけないコメント

### 1. WHAT の再説明

コードを読めば分かる内容を日本語 / 英語で言い換えるコメント。命名で自己説明できるように直す。

```typescript
// BAD
// user の id を取得
const id = user.id;

// BAD
// ループで users を回す
for (const user of users) { ... }
```

### 2. 変更履歴コメント

git log / blame が正しい情報源。コード中には残さない。

```typescript
// BAD
// 2024-03-15: XXX さんが追加
// 2024-04-01: YYY のリファクタで signature 変更
export function foo() { ... }
```

### 3. 現在の task / PR / issue を指すコメント

- 「今回の変更で追加」「PR #123 で修正」「issue #456 対応」等。
- 数ヶ月後には意味を失う。PR 本文・commit message に書く。

```typescript
// BAD
// PR #2781 で追加。Sentry の feedback を扱う
export function fetchFeedback() { ... }
```

### 4. コメントアウトされた旧コード

git 履歴に残っているので削除する。「参考のため」も残さない。

```typescript
// BAD
// 旧実装
// export function oldImpl() { ... }

export function newImpl() { ... }
```

### 5. 冗長な TODO / FIXME

追跡する仕組み（issue tracker, TODO 管理）がない TODO は腐る。書くなら:

- 対応する issue / ticket URL を付ける
- 期限や条件を明示する（例: 「Node 22 に上げたら削除」）

```typescript
// GOOD
// TODO(https://github.com/org/repo/issues/123): Node 22 EOL 後に削除

// BAD
// TODO: あとで直す
// FIXME: なんとかする
```

### 6. セクションヘッダー的コメント

`// ===== Helpers =====` のような装飾コメント。ファイル分割 or 関数の並び順（step-down rule）で表現する。

## 判定フロー

コメントを書く前に次の順で自問する。

1. **命名やコードで表現し直せないか？** → 直せるなら直す。コメントを書かない。
2. **このコードを 3 ヶ月後に読む人が「なぜこう書いた？」と思うか？** → 思うなら WHY を書く。
3. **他モジュールから呼ばれる公開 API か？** → その言語のドキュメント記法で契約を書く。
4. 上記いずれにも当てはまらない → コメントを書かない。

## 例: 悪い→良い のリファクタ

```typescript
// BAD
/**
 * ユーザーを取得する関数
 * @param id ID
 * @returns ユーザー
 */
// キャッシュがあればそれを返す。なければ DB から取得する。
// 2024-05-01 加藤さんが追加
// TODO: あとで最適化
async function getUser(id: string): Promise<User> {
  const cached = await cache.get(id);
  if (cached) return cached; // キャッシュがあれば返す
  const user = await db.user.findUnique({ where: { id } }); // DB から取得
  await cache.set(id, user); // キャッシュに保存
  return user;
}

// GOOD
/**
 * ID からユーザーを取得する。
 *
 * ホットパスでの DB 負荷を避けるため 5 分の read-through cache を挟む。
 * cache miss 時は DB を叩き、結果を cache に書き戻す。
 *
 * @throws {NotFoundError} 該当ユーザーが存在しないとき
 */
async function getUser(id: string): Promise<User> {
  const cached = await cache.get(id);
  if (cached) return cached;
  const user = await db.user.findUnique({ where: { id } });
  if (!user) throw new NotFoundError(id);
  await cache.set(id, user);
  return user;
}
```

## AI コーディング時の適用

- 生成したコードにコメントを付ける前に、上記「判定フロー」を通す。
- ユーザーが指示していない限り、変更 diff の解説コメント（「XXX を追加」「YYY に変更」）はコード中に残さない。PR description / commit message に書く。
- 既存コードに WHAT コメントや変更履歴コメントがあった場合、そのファイルを触る PR で削除して構わない（ただし削除だけの diff は避け、実質的な変更と一緒にする）。
