# Spec axis

Does the diff faithfully implement the originating issue / PRD / spec?

## What to report

Quote the spec line for each finding.

- **(a) Missing or partial** — requirements the spec asked for that the diff lacks or only half-implements.
- **(b) Not asked for** — observable behaviour the spec did not ask for (scope creep). Internal abstraction or generality that changes no behaviour belongs to the Simplicity axis, not here.
- **(c) Implemented but wrong** — requirements that look implemented but where the implementation, including its edge cases, does not do what the spec says.

When the spec is text written alongside the diff — the PR description or the commit messages — a mismatch is a finding all the same. It can be fixed on either side, so say which side looks wrong: the code, or the description of it.

If no spec is available, report nothing and say so.

## Severity

- **must-fix** — any (a), (b) or (c) where the spec is unambiguous on the point.
- **nit** — the spec is ambiguous on the point; name the reading you assumed.
