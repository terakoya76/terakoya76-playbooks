---
name: dev-medium
description: Multi-agent problem solving with architect and planner subagents for medium complexity tasks.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Agent, mcp__sequential-thinking__sequentialthinking
---

Use sequential-thinking mcp and all its tools that you will need about the problem and how to solve it. You must ultrathink for the solution and use reasoning.

You must consider edge cases and follow best coding practices for everything. Never do bandaid fixes.

## Configuration

STEP 1: Launch the **architect** agent in parallel with the following prompt:
  - Investigate the problem and the relevant codebase.
  - Analyze the current architecture, data flow, and affected components.
  - Write an "INVESTIGATION_REPORT.md" inside the `claude-code-storage/claude-instance-{id}/` directory covering: current state analysis, affected files, root cause or feature scope, and integration points.

STEP 2: Once the architect agent completes, launch the **planner** agent with the following prompt:
  - Read the "INVESTIGATION_REPORT.md" from the `claude-code-storage/claude-instance-{id}/` directory.
  - Based on the investigation, create a "PLAN.md" in the same directory covering: implementation steps with file paths, dependency order, testing strategy, risks and mitigations.

STEP 3: After the planner agent finishes, enter plan mode and read the "PLAN.md" file and present the plan to the user so that they can either accept or adjust it.

Problem: $ARGUMENTS
