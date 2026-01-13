---
description: "Run BMAD-Evals loop with grading and iteration tracking"
argument-hint: "[PROMPT] [--task ID] [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-eval-loop.sh:*)"]
hide-from-slash-command-tool: "true"
---

# BMAD-Evals Run Command

Execute the setup script to initialize the eval loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-eval-loop.sh" $ARGUMENTS
```

You are now in a BMAD-Evals loop. This combines BMAD methodology's structured approach with Ralph-wiggum's iterative execution.

## How This Works

1. You work on the task as described
2. When you attempt to exit, graders evaluate your work
3. If graders FAIL: you receive feedback and continue iterating
4. If graders PASS: the loop ends and a report is generated

## Key Principles (from BMAD)

- Follow red-green-refactor: write failing test, make it pass, refactor
- Execute tasks in order as specified
- Every change should be testable
- Document what you implement

## Key Principles (from Ralph-Wiggum)

- Iteration over perfection - let the loop refine your work
- Failures are data - use grader feedback to improve
- Persistence wins - keep iterating until success

## Grader Types

- **deterministic_tests**: Unit tests, integration tests
- **static_analysis**: Linting, type checking
- **state_check**: Verify files exist, contain patterns
- **tool_calls**: Verify you used required tools
- **llm_rubric**: Model-based quality grading

CRITICAL: If a completion promise is set, you may ONLY output it when the statement is TRUE. Do not output false promises to escape the loop.
