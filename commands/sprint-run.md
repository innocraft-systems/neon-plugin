---
description: "Run all stories in sprint automatically with cross-context persistence"
argument-hint: "[--epic EPIC_ID] [--max-stories N] [--stop-on-fail] [--skip-review]"
allowed-tools: [
  "Read", "Write", "Edit", "Glob", "Grep", "Task",
  "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint-runner.sh:*)",
  "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/parse-dependencies.sh:*)",
  "Bash(mkdir:*)", "Bash(rm:*)", "Bash(cp:*)", "Bash(mv:*)", "Bash(touch:*)",
  "Bash(cat:*)", "Bash(ls:*)", "Bash(pwd:*)", "Bash(find:*)", "Bash(grep:*)",
  "Bash(npm:*)", "Bash(npx:*)", "Bash(node:*)", "Bash(pnpm:*)", "Bash(yarn:*)", "Bash(bun:*)",
  "Bash(git:*)",
  "Bash(jest:*)", "Bash(vitest:*)", "Bash(pytest:*)", "Bash(mocha:*)", "Bash(ava:*)",
  "Bash(tsc:*)", "Bash(eslint:*)", "Bash(prettier:*)", "Bash(biome:*)",
  "Bash(cargo:*)", "Bash(go:*)", "Bash(python:*)", "Bash(pip:*)",
  "Bash(docker:*)", "Bash(docker-compose:*)",
  "Bash(curl:*)", "Bash(wget:*)",
  "Bash(echo:*)", "Bash(printf:*)", "Bash(sed:*)", "Bash(awk:*)",
  "Bash(chmod:*)", "Bash(chown:*)",
  "Bash(head:*)", "Bash(tail:*)", "Bash(wc:*)", "Bash(sort:*)", "Bash(uniq:*)",
  "Bash(diff:*)", "Bash(patch:*)",
  "Bash(tar:*)", "Bash(zip:*)", "Bash(unzip:*)",
  "Bash(env:*)", "Bash(export:*)", "Bash(source:*)",
  "Bash(sleep:*)", "Bash(date:*)", "Bash(time:*)"
]
---

# /sprint-run - Automated Sprint Execution

Run all stories in your sprint automatically. The agent will build each story sequentially, respecting dependencies across epics, persisting through context windows until all stories are complete.

## Usage

```bash
# Run all ready stories in sprint
/sprint-run

# Run stories from a specific epic only
/sprint-run --epic epic-1-auth

# Limit number of stories (for testing)
/sprint-run --max-stories 5

# Stop immediately on first failure
/sprint-run --stop-on-fail

# Skip code review (faster, less safe)
/sprint-run --skip-review
```

## Pre-Flight Checklist

Before starting, the runner validates:

- [ ] `sprint-status.yaml` exists and is valid
- [ ] Architecture document exists
- [ ] PRD or tech-spec exists
- [ ] At least one story has status `TODO`
- [ ] Story files exist for all TODO stories
- [ ] No circular dependencies detected

If any check fails, you'll receive guidance on how to fix it.

## How It Works

```
SPRINT RUNNER LOOP
       │
       ▼
┌─────────────────────────────────────┐
│ 1. Parse sprint-status.yaml         │
│ 2. Build dependency graph           │
│ 3. Find next READY story            │
│    (TODO + all deps DONE)           │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ 4. Execute dev-story workflow       │
│    • Read story file                │
│    • Reference architecture         │
│    • Implement with TDD             │
│    • Run tests                      │
│    • Update story checkboxes        │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ 5. Code review (unless --skip)      │
│ 6. Mark story DONE                  │
│ 7. Git commit checkpoint            │
│ 8. Update sprint-status.yaml        │
└─────────────────────────────────────┘
       │
       ▼
   All stories DONE? ──NO──► Loop to step 3
       │
      YES
       │
       ▼
   Generate sprint report & exit
```

## Context Exhaustion Handling

If context exhausts mid-story:
1. Progress is checkpointed via git commit
2. Current story state is preserved
3. Sprint runner re-feeds the story prompt
4. Development continues seamlessly

If context exhausts between stories:
1. Completed stories remain DONE
2. Sprint state is preserved
3. Next ready story is loaded
4. No work is lost

## Instructions

Initialize and run the sprint:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint-runner.sh $ARGUMENTS
```

You are now the DEV agent executing a sprint. Follow these principles:

### From BMAD Method
- Read each story's acceptance criteria carefully
- Reference architecture document for technical decisions
- Follow existing code patterns and conventions
- Write tests FIRST (red-green-refactor)
- Update story checkboxes as you complete tasks
- Ensure all acceptance criteria are met before marking complete

### From Ralph-Wiggum Technique
- Persistence over perfection - the loop will continue
- Each context window builds on the last
- Git commits preserve your progress
- Keep working until the sprint is complete

### Completion Signals

For each story, when ALL acceptance criteria are met:
1. All tests pass
2. All task checkboxes marked [x]
3. Output: `<story-complete>STORY_ID</story-complete>`

For the entire sprint:
1. All stories marked DONE in sprint-status.yaml
2. Output: `<sprint-complete>SPRINT_ID</sprint-complete>`

## Troubleshooting

### Sprint Won't Start
- Check sprint-status.yaml exists and is valid YAML
- Verify at least one story has TODO status
- Run pre-flight manually: `${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint-runner.sh --check-only`

### Story Keeps Failing
- Check story dependencies are marked DONE
- Verify story file has clear acceptance criteria
- Check for circular dependencies

### To Cancel Mid-Sprint
```bash
/sprint-stop
# Or manually:
rm .claude/sprint-runner/sprint.state.json
```

### To Resume After Manual Stop
```bash
/sprint-run --resume
```
