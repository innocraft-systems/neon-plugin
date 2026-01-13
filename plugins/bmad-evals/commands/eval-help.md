---
description: "BMAD-Evals plugin help and documentation"
argument-hint: ""
allowed-tools: []
---

# BMAD-Evals Plugin Help

A hybrid plugin combining BMAD methodology structured testing with Ralph-wiggum iterative execution for comprehensive AI agent evaluation.

## Quick Start

```bash
# Initialize eval suite
/eval-init

# Add an eval task
/eval-task-add fix-auth-bug "Fix the authentication bypass vulnerability in auth.py"

# Run the eval
/eval-run --task fix-auth-bug --max-iterations 20

# View results
/eval-report
```

## Commands

| Command | Description |
|---------|-------------|
| `/eval-init` | Initialize eval suite (optionally from BMAD stories) |
| `/eval-run` | Start eval loop with grading |
| `/eval-task-add` | Add a new eval task |
| `/eval-report` | Generate comprehensive report |
| `/eval-cancel` | Cancel active eval loop |
| `/eval-help` | Show this help |

## Architecture

This plugin combines three systems:

### 1. BMAD Methodology
- Structured task creation with clear success criteria
- Test-driven development principles (red-green-refactor)
- Systematic approach to implementation

### 2. Ralph-Wiggum Loop
- Self-referential execution loop
- Stop hook prevents exit until completion
- Iteration tracking with max limits
- Completion promise detection

### 3. Eval Infrastructure
- Multiple grader types (deterministic, LLM-based, state checks)
- Transcript capture for analysis
- pass@k and pass^k metrics
- Comprehensive reporting

## Grader Types

### Deterministic Tests
```json
{
  "type": "deterministic_tests",
  "name": "unit-tests",
  "command": "npm test"
}
```

### Static Analysis
```json
{
  "type": "static_analysis",
  "name": "lint-check",
  "commands": ["npm run lint", "npm run typecheck"]
}
```

### State Check
```json
{
  "type": "state_check",
  "name": "file-verification",
  "expect": {
    "files": ["src/auth.ts", "tests/auth.test.ts"],
    "contains": {
      "src/auth.ts": "validatePassword"
    }
  }
}
```

### Tool Calls
```json
{
  "type": "tool_calls",
  "name": "required-tools",
  "required": [
    {"tool": "Read"},
    {"tool": "Edit"},
    {"tool": "Bash"}
  ]
}
```

### LLM Rubric
```json
{
  "type": "llm_rubric",
  "name": "code-quality",
  "rubric": "Evaluate code for: clarity, error handling, test coverage"
}
```

## Metrics Explained

### pass@k
Probability of at least ONE success in k attempts.
- Higher k = higher pass@k (more chances)
- Useful when one success is enough

### pass^k
Probability of ALL k attempts succeeding.
- Higher k = lower pass^k (harder to maintain)
- Useful for measuring consistency

## Best Practices

### Writing Good Eval Tasks

1. **Clear Success Criteria**
   - Specify exactly what "done" looks like
   - Include measurable outcomes

2. **Appropriate Graders**
   - Use deterministic graders where possible
   - Reserve LLM graders for subjective quality

3. **Reasonable Iteration Limits**
   - Set max-iterations to prevent infinite loops
   - Start with 20-50, adjust based on complexity

4. **Completion Promises**
   - Use specific, verifiable statements
   - "ALL TESTS PASS" not just "DONE"

### Debugging Failed Evals

1. Check iteration results: `ls .claude/bmad-evals/results/`
2. Read specific iteration: `cat .claude/bmad-evals/results/iteration-N.json`
3. Review tool events: `cat .claude/bmad-evals/tool-events.jsonl`
4. Generate report: `/eval-report`

## File Structure

```
.claude/bmad-evals/
├── eval-loop.state.json    # Active loop state
├── eval-tasks.json         # Task definitions
├── graders/                # Grader configurations
│   └── default.json
├── results/                # Iteration results
│   ├── iteration-1.json
│   └── iteration-N.json
├── tool-events.jsonl       # Captured tool calls
├── transcripts/            # Full transcripts
└── eval-report.md          # Generated report
```

## Integration with BMAD

If using BMAD Method for your project:

1. Create stories with clear acceptance criteria
2. Run `/eval-init --from-bmad .bmad/stories/`
3. Tasks are auto-generated with appropriate graders
4. Use `/eval-run --suite sprint-1` to run all tasks

## Troubleshooting

### Loop won't stop
- Check max-iterations is set
- Verify completion promise matches exactly
- Run `/eval-cancel` to force stop

### Graders always fail
- Check grader commands work manually
- Verify paths in state_check
- Review grader output in results

### No results generated
- Ensure .claude/bmad-evals/ exists
- Check hook is executing (see tool-events.jsonl)
- Verify transcript capture is working
