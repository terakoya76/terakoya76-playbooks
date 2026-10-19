export const meta = {
  name: 'review-fix-loop',
  description: '現在の branch の差分を opus でレビューし、must-fix が出なくなるまで opus で修正を繰り返す。その後 nit だけの修正 round を最大 3 回続ける',
  whenToUse: '実装を終えた branch を、PR を出す前後にレビューと修正のループで詰めたいとき。args: { base?: "<ref。省略時は origin の default branch>", maxRounds?: 5, maxNitRounds?: 3, spec?: "PR 番号 / issue / 仕様書の path" }',
  phases: [
    { title: 'Scope', detail: 'base を固定し、差分が在って working tree が clean なことを確かめる' },
    { title: 'Review', detail: 'Standards / Spec / Simplicity の 3 軸を並列にレビュー', model: 'opus' },
    { title: 'Fix', detail: 'must-fix を、それが無くなったら nit を修正し、typecheck / lint / test を通して fixup commit を積む', model: 'opus' },
  ],
}

const BASE_REF = (args && args.base) || ''
const MAX_ROUNDS = (args && args.maxRounds) || 5
const MAX_NIT_ROUNDS = (args && args.maxNitRounds) ?? 3
const SPEC_HINT = (args && args.spec) || ''

const SCOPE_SCHEMA = {
  type: 'object',
  properties: {
    ok: { type: 'boolean' },
    reason: { type: 'string' },
    baseSha: { type: 'string' },
    commits: {
      type: 'array',
      items: {
        type: 'object',
        properties: { sha: { type: 'string' }, subject: { type: 'string' }, author: { type: 'string' } },
        required: ['sha', 'subject', 'author'],
      },
    },
    spec: { type: 'string' },
  },
  required: ['ok', 'reason', 'baseSha', 'commits', 'spec'],
}

const REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['must-fix', 'nit'] },
          summary: { type: 'string' },
          rationale: { type: 'string' },
          suggestion: { type: 'string' },
          relatesTo: { type: 'string' },
          rebuttal: { type: 'string' },
        },
        required: ['file', 'severity', 'summary', 'rationale', 'relatesTo', 'rebuttal'],
      },
    },
    note: { type: 'string' },
  },
  required: ['findings', 'note'],
}

const FIX_SCHEMA = {
  type: 'object',
  properties: {
    results: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          status: { type: 'string', enum: ['fixed', 'disputed'] },
          reason: { type: 'string' },
          commit: { type: 'string' },
        },
        required: ['id', 'status', 'reason', 'commit'],
      },
    },
    checks: {
      type: 'object',
      properties: {
        passed: { type: 'boolean' },
        commands: { type: 'array', items: { type: 'string' } },
        failures: { type: 'string' },
      },
      required: ['passed', 'commands', 'failures'],
    },
  },
  required: ['results', 'checks'],
}

const AXIS_DIR = '~/.claude/skills/code-review/axes'

// 観点と severity の基準は code-review skill と共有する。ここに書き写すと片方だけ古くなる
const AXES = [
  { key: 'standards', tag: 'S', extra: '' },
  {
    key: 'spec',
    tag: 'P',
    extra: '仕様の出所は上の「仕様」に従って自分で取得する (gh pr view / gh issue view / ファイル)。仕様が見つからなければ findings を空にし、note にそう書く。',
  },
  { key: 'simplicity', tag: 'C', extra: '' },
]

phase('Scope')
const scope = await agent(
  [
    '現在の branch のレビュー範囲を固定する。ファイルは変更しない。',
    BASE_REF
      ? `1. \`git merge-base HEAD ${BASE_REF}\` を baseSha とする。解決できなければ ok=false。`
      : '1. base ref を `git symbolic-ref --short refs/remotes/origin/HEAD` で決め、無ければ main、次に master を使う。`git merge-base HEAD <base ref>` を baseSha とする。解決できなければ ok=false。',
    `2. \`git log --format='%H%x09%an%x09%s' <baseSha>..HEAD\` を commits に入れる。空なら ok=false。`,
    '3. `git status --porcelain` が空でなければ ok=false (修正役の commit に未コミットの変更が混ざるため)。',
    `4. 仕様の出所を spec に 1 行で書く。指定: ${SPEC_HINT ? `\`${SPEC_HINT}\`` : '(なし)'}。`,
    '   指定が無ければ `gh pr view --json number,title,url` で現在の branch の PR、次に commit message 中の issue 参照を探す。',
    '   別 repo の issue は owner/repo#N で書く。何も無ければ空文字。',
    'ok=false のときは reason に理由を書く。ok=true のときの reason は空文字でよい。',
  ].join('\n'),
  { label: 'scope', phase: 'Scope', schema: SCOPE_SCHEMA, effort: 'low' },
)

if (!scope) return { status: 'agent-failed', stage: 'scope' }
if (!scope.ok) return { status: 'scope-rejected', reason: scope.reason }
log(`base ${scope.baseSha.slice(0, 8)} / ${scope.commits.length} commits / spec: ${scope.spec || '(なし)'}`)

const fixed = []
const disputed = []
const nitsByLocation = new Map()
const rounds = []
let mustFixRounds = 0
let nitRounds = 0
let status = 'max-rounds'
let stopDetail = ''

for (let round = 1; ; round++) {
  const reviews = await parallel(
    AXES.map((axis) => () =>
      agent(reviewPrompt(axis, round), {
        label: `review:${axis.key}:${round}`,
        phase: 'Review',
        schema: REVIEW_SCHEMA,
        model: 'opus',
      }).then((r) => (r ? { axis, findings: r.findings, note: r.note } : null)),
    ),
  )
  if (reviews.some((r) => !r)) {
    status = 'agent-failed'
    stopDetail = `round ${round} の review agent が結果を返さなかった`
    break
  }

  const findings = reviews.flatMap((r) =>
    r.findings.map((f, i) => ({ ...f, id: `R${round}-${r.axis.tag}${i + 1}`, axis: r.axis.key })),
  )
  // レビュアーは round ごとに新しく起動するので、直していない nit は毎 round 出し直される。場所で寄せて最新の文面だけ残す
  for (const f of findings.filter((f) => f.severity === 'nit')) {
    const key = locationKey(f)
    nitsByLocation.set(key, { ...f, rounds: [...(nitsByLocation.get(key)?.rounds ?? []), round] })
  }
  const mustFix = findings.filter((f) => f.severity === 'must-fix')

  const fixedIds = new Set(fixed.map((f) => f.id))
  const disputedIds = new Set(disputed.map((f) => f.id))
  const regressions = mustFix.filter((f) => fixedIds.has(f.relatesTo))
  const reRaised = mustFix.filter((f) => disputedIds.has(f.relatesTo) && f.rebuttal)
  const actionable = mustFix.filter((f) => !disputedIds.has(f.relatesTo))
  // nit は反論で覆す仕組みを持たせない。却下されたものは出し直されても直さない
  const actionableNits = findings.filter((f) => f.severity === 'nit' && !disputedIds.has(f.relatesTo))
  const roundRecord = { round, mustFix: mustFix.length, nits: findings.length - mustFix.length, notes: reviews.map((r) => `${r.axis.key}: ${r.note}`) }
  rounds.push(roundRecord)
  log(`round ${round}: must-fix ${mustFix.length} (actionable ${actionable.length}) / nit ${roundRecord.nits}`)

  // 直した箇所が再び指摘される・却下を覆す反論が来る、はどちらも agent 同士では決着しないので人へ返す
  if (regressions.length) {
    status = 'oscillation'
    stopDetail = '修正済みの指摘と同じ問題が再び must-fix として出た'
    roundRecord.blocking = regressions
    break
  }
  if (reRaised.length) {
    status = 'disagreement'
    stopDetail = '修正役が却下した指摘に、レビュアーが反論付きで再度 must-fix を出した'
    roundRecord.blocking = reRaised
    break
  }

  let targets
  let severity
  if (actionable.length) {
    if (mustFixRounds >= MAX_ROUNDS) break
    mustFixRounds++
    targets = actionable
    severity = 'must-fix'
  } else if (!actionableNits.length) {
    status = 'clean'
    break
  } else if (nitRounds >= MAX_NIT_ROUNDS) {
    status = 'nits-only'
    stopDetail = `nit だけの修正 round を ${MAX_NIT_ROUNDS} 回行っても nit が残った`
    break
  } else {
    nitRounds++
    targets = actionableNits
    severity = 'nit'
  }
  roundRecord.fixed = severity

  const fix = await agent(fixPrompt(targets, severity), {
    label: `fix:${round}`,
    phase: 'Fix',
    schema: FIX_SCHEMA,
    model: 'opus',
  })
  if (!fix) {
    status = 'agent-failed'
    stopDetail = `round ${round} の fix agent が結果を返さなかった`
    break
  }

  const byId = new Map(targets.map((f) => [f.id, f]))
  for (const r of fix.results) {
    const f = byId.get(r.id)
    if (!f) continue
    if (r.status === 'fixed') fixed.push({ ...f, commit: r.commit, fixNote: r.reason })
    else disputed.push({ ...f, disputeReason: r.reason })
  }
  const unanswered = targets.filter((f) => !fix.results.some((r) => r.id === f.id))
  if (unanswered.length) log(`round ${round}: 修正役が応答しなかった指摘 ${unanswered.map((f) => f.id).join(', ')} は次の round で再レビューに委ねる`)
  roundRecord.fix = { results: fix.results, checks: fix.checks, unanswered: unanswered.map((f) => f.id) }

  if (!fix.checks.passed) {
    status = 'checks-failed'
    stopDetail = fix.checks.failures
    break
  }
}

return {
  status,
  stopDetail,
  baseSha: scope.baseSha,
  spec: scope.spec,
  rounds,
  fixed: fixed.map(({ id, file, line, summary, commit, fixNote }) => ({ id, file, line, summary, commit, fixNote })),
  disputed: disputed.map(({ id, file, line, summary, rationale, disputeReason }) => ({ id, file, line, summary, rationale, disputeReason })),
  nits: [...nitsByLocation.values()]
    .filter((n) => !fixed.some((f) => locationKey(f) === locationKey(n)))
    .map(({ id, axis, file, line, summary, suggestion, rounds }) => ({ id, axis, file, line, summary, suggestion, rounds })),
  nextStep: fixed.length
    ? `fixup commit が積まれている。中身を確認したら \`git rebase -i --autosquash ${scope.baseSha}\` 相当で畳む (merge-base へ当てる)`
    : '',
}

function locationKey(f) {
  return `${f.axis}:${f.file}:${f.line ?? ''}`
}

function reviewPrompt(axis, round) {
  return [
    `現在の branch を PR レビューする (round ${round})。ファイルは一切変更しない。`,
    `差分: \`git diff ${scope.baseSha}...HEAD\` / commit 一覧: \`git log ${scope.baseSha}..HEAD\``,
    `仕様: ${scope.spec || '(見つからなかった)'}`,
    '',
    `${AXIS_DIR}/${axis.key}.md を読み、その観点でレビューする。severity はそのファイルの Severity 節に従い、決まらなければ nit にする。`,
    'rationale にはそのファイルが求める根拠 (規約・仕様の文言・smell 名と該当箇所) を書く。',
    axis.extra,
    '',
    'relatesTo / rebuttal は該当しなければ空文字にする。',
    historyBlock(),
  ].join('\n')
}

function historyBlock() {
  if (!fixed.length && !disputed.length) return ''
  const lines = ['', '過去の round の経緯:']
  for (const f of fixed) lines.push(`- [fixed] ${f.id} ${f.file}: ${f.summary}`)
  for (const f of disputed) lines.push(`- [disputed] ${f.id} ${f.file}: ${f.summary} / 却下理由: ${f.disputeReason}`)
  lines.push(
    '',
    '- fixed の指摘と同じ問題が再発していれば、その指摘の relatesTo に元の id を入れる',
    '- disputed と同じ指摘は、却下理由を覆す新しい根拠が無い限り出さない。出すなら relatesTo に元の id、rebuttal に却下理由への反論を書く',
  )
  return lines.join('\n')
}

function fixPrompt(items, severity) {
  return [
    `以下の ${severity} 指摘を現在の branch で修正する。`,
    `差分の base は ${scope.baseSha}。commit 一覧: \`git log --format='%H %an %s' ${scope.baseSha}..HEAD\``,
    '',
    '指摘:',
    JSON.stringify(items.map(({ id, axis, file, line, summary, rationale, suggestion }) => ({ id, axis, file, line, summary, rationale, suggestion })), null, 2),
    '',
    '進め方:',
    '- 指摘が誤っている・規約や仕様と矛盾する・直すと別の保証を壊す、と判断したものは直さず status=disputed にし、reason に根拠を書く。言いなりに直さない',
    '- 直したものは、その問題を持ち込んだ commit への `git commit --fixup=<sha>` として積む。その commit の author が自分 (git config user.name) でないときは通常の commit にする。commit には積んだ commit の sha を入れる',
    `- 食い違いの原因がコードではなく PR 本文や commit message の記述にある指摘は、記述の側を直し、どちらを直したかを reason に書く。仕様の出所: ${scope.spec || '(なし)'}`,
    '  - PR 本文: `gh pr view <番号> --json body` で今の本文を取り、該当箇所だけを書き換えて `gh pr edit <番号> --body-file <file>` で更新する。見出しの構成や他の節は変えない。commit には "pr-body" と入れる',
    '  - commit message: 1 行目を `amend! <直す commit の subject>`、空行を挟んで差し替え後の message 全体を書いたファイルを用意し、`git commit --allow-empty -F <file>` で積む (`--fixup=reword:` は -m / -F と併用できず editor が開くので使わない)',
    '- rebase / autosquash / push はしない',
    '- 修正後、その repo の CLAUDE.md や package の scripts が定める typecheck / lint / test を、触った範囲について通す',
    '- 外部の実環境 (本番・dev の API、クラウドの resource) を叩くコマンドは実行しない',
    '- checks.commands に実行したコマンド、通らなかったら checks.passed=false と failures に要点を書く',
  ].join('\n')
}
