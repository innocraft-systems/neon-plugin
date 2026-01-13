---
description: "Stop the active sprint runner"
allowed-tools: ["Bash(rm:*)", "Bash(cat:*)"]
---

# /sprint-stop - Stop Sprint Runner

Stops the active sprint runner and generates a partial completion report.

## Usage

```bash
/sprint-stop
```

## What Happens

1. Current story progress is preserved (git commit)
2. Sprint state is marked inactive
3. Partial completion report is generated
4. You can resume later with `/sprint-run --resume`

## Instructions

```bash
# Check if sprint is active
if [ -f ".claude/sprint-runner/sprint.state.json" ]; then
  # Show current progress
  cat .claude/sprint-runner/sprint.state.json | jq '{
    sprint_id,
    current_story,
    stories_completed,
    stories_total,
    iteration
  }'

  # Mark as inactive
  rm .claude/sprint-runner/sprint.state.json

  echo ">>> Sprint runner stopped."
  echo ">>> Resume with: /sprint-run --resume"
else
  echo ">>> No active sprint runner found."
fi
```

## Notes

- Progress up to the current point is preserved in git
- The `sprint-status.yaml` reflects completed stories
- Incomplete current story remains in TODO state
- Use `/sprint-run --resume` to continue from where you stopped
