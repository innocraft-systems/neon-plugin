---
description: "Initialize BMAD-Evals suite from BMAD stories or scratch"
argument-hint: "[--from-bmad PATH] [--suite NAME]"
allowed-tools: ["Read", "Write", "Bash", "Glob"]
---

# Initialize BMAD-Evals Suite

This command initializes an eval suite, optionally importing from existing BMAD story files.

## Your Task

Based on the arguments provided, set up the eval infrastructure:

### If --from-bmad PATH is provided:

1. Read the BMAD story/sprint files at the specified path
2. Extract tasks and acceptance criteria
3. Convert each task into an eval task with:
   - `id`: Derived from story/task ID
   - `prompt`: The task description
   - `graders`: Appropriate graders based on acceptance criteria
   - `success_criteria`: Clear pass/fail conditions

### If creating from scratch:

1. Create the eval directory structure:
   ```
   .claude/bmad-evals/
   ├── eval-tasks.json
   ├── graders/
   │   └── default.json
   └── results/
   ```

2. Create a template eval-tasks.json:
   ```json
   {
     "tasks": [],
     "suites": {
       "default": {
         "name": "Default Suite",
         "tasks": []
       }
     },
     "config": {
       "default_max_iterations": 50,
       "grader_timeout": 30000
     }
   }
   ```

3. Create default graders:
   ```json
   [
     {
       "type": "deterministic_tests",
       "name": "unit-tests",
       "command": "npm test"
     },
     {
       "type": "static_analysis",
       "name": "lint",
       "commands": ["npm run lint"]
     }
   ]
   ```

## BMAD Story to Eval Mapping

When converting BMAD stories:

| BMAD Element | Eval Element |
|--------------|--------------|
| Story ID | Task ID prefix |
| Task description | Eval prompt |
| Acceptance Criteria | Grader assertions |
| Test requirements | deterministic_tests grader |
| File deliverables | state_check grader |

## Example Output

After initialization, confirm:
- Number of tasks created
- Suites configured
- Graders set up
- Path to eval-tasks.json
