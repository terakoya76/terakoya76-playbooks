# Standards axis

Does the diff conform to this repo's **documented** coding standards?

## Sources

Anything that documents how code should be written here: the repo's `CLAUDE.md` and the user-level `CLAUDE.md` with the rule files it pulls in (`~/.claude/rules/`), plus `CODING_STANDARDS.md`, `CONTRIBUTING.md` and similar.

## What to report

Every place the diff breaches a documented rule. Cite the rule (file + the rule itself) and quote the hunk.

- Skip anything tooling (linter, formatter, type checker) already enforces.
- Judgements about code shape that no document states belong to the Simplicity axis, not here.

## Severity

- **must-fix** — a breach of a documented rule.
- **nit** — the rule itself leaves the point to judgement, or the breach is purely cosmetic.
