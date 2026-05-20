---
name: review
description: Initiate code-reviewer subagent to check files related to uncommitted changes.
context: fork
agent: code-reviewer
allowed-tools: Read, Glob, Grep, Bash(git diff:*), Bash(git diff --cached:*), Bash(git status:*)
---
