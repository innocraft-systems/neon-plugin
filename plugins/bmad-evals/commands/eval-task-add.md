---
description: "Add a new eval task with graders"
argument-hint: "<TASK_ID> <PROMPT>"
allowed-tools: ["Read", "Write", "Edit"]
---

# Add Eval Task

Add a new eval task to the eval-tasks.json file.

## Your Task

1. Read the current eval-tasks.json file (create if doesn't exist)
2. Add a new task with the provided ID and prompt
3. Configure appropriate graders based on the task type

## Task Structure

```json
{
  "id": "TASK_ID",
  "prompt": "Full task description including requirements and success criteria",
  "graders": [
    {
      "type": "deterministic_tests",
      "name": "task-tests",
      "command": "npm test -- --grep 'TASK_ID'"
    },
    {
      "type": "state_check",
      "name": "file-check",
      "expect": {
        "files": ["path/to/expected/file.ts"]
      }
    }
  ],
  "success_criteria": "Description of what success looks like",
  "max_iterations": 20,
  "completion_promise": "TASK COMPLETE"
}
```

## Grader Selection Guide

Choose graders based on task type:

### For Coding Tasks:
- `deterministic_tests`: Run test suite
- `static_analysis`: Run linter/type checker
- `state_check`: Verify files created/modified

### For Bug Fixes:
- `deterministic_tests`: Verify fix with regression test
- `state_check`: Check security logs (if applicable)

### For Documentation:
- `state_check`: Verify files exist
- `llm_rubric`: Check quality/completeness

### For Refactoring:
- `deterministic_tests`: All existing tests pass
- `static_analysis`: Code quality improved

## Interaction

Ask the user for:
1. Task type (coding, bug fix, docs, refactor, other)
2. Specific success criteria
3. Any special grading requirements

Then add the task with appropriate configuration.
