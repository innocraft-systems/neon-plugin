---
description: "Cancel active BMAD-Evals loop"
argument-hint: ""
allowed-tools: ["Read", "Bash"]
---

# Cancel BMAD-Evals Loop

This command cancels any active eval loop.

## Steps to Cancel

1. Check if an eval loop is active by looking for the state file
2. If active, remove the state file to stop the loop
3. Generate a partial report if there are results

## Instructions

Check for active loop:
```bash
if [ -f ".claude/bmad-evals/eval-loop.state.json" ]; then
  echo "Active eval loop found"
  cat .claude/bmad-evals/eval-loop.state.json
else
  echo "No active eval loop"
fi
```

If active, to cancel:
```bash
rm -f .claude/bmad-evals/eval-loop.state.json
echo "Eval loop cancelled"
```

Optionally generate partial report:
```bash
if [ -d ".claude/bmad-evals/results" ] && [ "$(ls -A .claude/bmad-evals/results 2>/dev/null)" ]; then
  "${CLAUDE_PLUGIN_ROOT}/scripts/generate-report.sh"
fi
```

## After Cancellation

- The Stop hook will no longer block session exit
- Results from completed iterations are preserved
- A partial report can still be generated

Run `/eval-report` to see results from completed iterations.
