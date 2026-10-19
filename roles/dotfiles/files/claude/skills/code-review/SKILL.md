---
name: code-review
description: Review the changes since a fixed point (commit, branch, tag, or merge-base) along three axes — Standards (does the code follow this repo's documented coding standards?), Spec (does the code match what the originating issue/PRD asked for?), and Simplicity (could the same thing be done with less code or code that explains itself?). Runs the reviews in parallel sub-agents and reports them side by side. Use when the user wants to review a branch, a PR, work-in-progress changes, or asks to "review since X".
---

Three-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec** — does the code faithfully implement the originating issue / PRD / spec?
- **Simplicity** — could the same thing be done with less code, fewer moving parts, or code that explains itself?

What each axis looks for and how it grades severity (`must-fix` / `nit`) lives in `axes/<axis>.md` next to this file. Those files are the single source for the axes; other tools (such as the `review-fix-loop` workflow) read them too, so change an axis there, not here.

All axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings.

The issue tracker should have been provided to you — run `/setup-matt-pocock-skills` if `docs/agents/issue-tracker.md` is missing.

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch name, tag, `main`, `HEAD~5`, etc. If they didn't specify one, ask for it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here — not inside parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`, GitLab `!67`, etc.) — fetch via the workflow in `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. A PRD/spec file under `docs/`, `specs/`, or `.scratch/` matching the branch name or feature.
4. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

List the files in the repo that document how code should be written (see "Sources" in `axes/standards.md`), so the Standards sub-agent doesn't have to hunt for them.

### 4. Spawn the sub-agents in parallel

Send a single message with one `Agent` tool call per axis. Use the `general-purpose` subagent for each.

Every prompt includes:

- The diff command and commit list.
- The absolute path of that axis's file (`<this skill's dir>/axes/<axis>.md`), with the instruction to read it and review along it, grading each finding `must-fix` or `nit` by its Severity section.
- The brief: "Report per file/hunk: the finding, its severity, and the evidence the axis file asks for (the rule, the spec line, or the smell and the hunk). Under 400 words."

Add per axis:

- **Standards** — the list of standards-source files from step 3.
- **Spec** — the path or fetched contents of the spec. If the spec is missing, skip this sub-agent and note this in the final report.
- **Simplicity** — nothing extra; it searches the repo itself when checking for reimplementation.

### 5. Aggregate

Present the reports under `## Standards`, `## Spec` and `## Simplicity` headings, verbatim or lightly cleaned. Do **not** merge or rerank findings — the axes are deliberately separate (see _Why separate axes_).

End with a one-line summary: `must-fix` / `nit` counts per axis, and the worst issue _within each axis_ (if any). Don't pick a single winner across axes — that's the reranking the separation exists to prevent.

## Why separate axes

A change can pass one axis and fail another:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**
- Code that is correct and follows every written rule but carries an abstraction nobody needs → **Standards and Spec pass, Simplicity fail.**

Reporting them separately stops one axis from masking another. The axis files also draw the boundaries between them (documented rule → Standards, observable behaviour → Spec, code shape → Simplicity), so the same issue is not reported twice.
