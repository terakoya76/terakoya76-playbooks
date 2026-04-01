---
name: dev-easy
description: Use sequential-thinking MCP for problem solving and error fixing with ultrathink reasoning. Considers edge cases and best practices. Runs security review after code changes.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Agent, mcp__sequential-thinking__sequentialthinking
---

Use sequential-thinking mcp and all its tools that you will need about the problem and how to solve it. You must ultrathink for the solution and use reasoning.

You must consider edge cases and follow best coding practices for everything. Never do bandaid fixes.

## Post-Fix Verification

After applying any code changes, launch the **security-reviewer** agent with the following prompt:
- Review only the files that were modified.
- Check for security regressions: injection vulnerabilities, input validation gaps, error message leaks, and authentication/authorization issues.
- Report any findings before marking the task as complete.

Problem: $ARGUMENTS
