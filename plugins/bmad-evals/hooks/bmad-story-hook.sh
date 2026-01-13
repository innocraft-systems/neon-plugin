#!/bin/bash

# BMAD Story Harness - Stop Hook
# Makes BMAD dev-story execution "Ralph-ish" with cross-context persistence
#
# Key features:
# - Persists story prompt across context windows
# - Tracks task completion from story file checkboxes
# - Uses git commits as state checkpoints
# - Re-feeds story prompt with progress context

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# State files
BMAD_HARNESS_DIR=".claude/bmad-harness"
BMAD_STATE_FILE="$BMAD_HARNESS_DIR/story-loop.state.md"

# Check if BMAD harness is active
if [[ ! -f "$BMAD_STATE_FILE" ]]; then
  # No active harness - allow exit
  exit 0
fi

# Parse markdown frontmatter (YAML between ---)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$BMAD_STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
STORY_FILE=$(echo "$FRONTMATTER" | grep '^story_file:' | sed 's/story_file: *//' | sed 's/^"\(.*\)"$/\1/')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo ">>> BMAD Harness: State file corrupted (invalid iteration: '$ITERATION')" >&2
  rm "$BMAD_STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo ">>> BMAD Harness: State file corrupted (invalid max_iterations: '$MAX_ITERATIONS')" >&2
  rm "$BMAD_STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo ">>> BMAD Harness: Max iterations ($MAX_ITERATIONS) reached."

  # Generate completion summary
  if [[ -f "$STORY_FILE" ]]; then
    TOTAL_TASKS=$(grep -c '^\s*- \[' "$STORY_FILE" 2>/dev/null || echo "0")
    COMPLETED_TASKS=$(grep -c '^\s*- \[x\]' "$STORY_FILE" 2>/dev/null || echo "0")
    echo ">>> BMAD Harness: Story progress: $COMPLETED_TASKS/$TOTAL_TASKS tasks completed"
  fi

  rm "$BMAD_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo ">>> BMAD Harness: Transcript not found" >&2
  rm "$BMAD_STATE_FILE"
  exit 0
fi

# Check story file for completion
if [[ -f "$STORY_FILE" ]]; then
  # Count total tasks (lines starting with "- [ ]" or "- [x]")
  TOTAL_TASKS=$(grep -c '^\s*- \[' "$STORY_FILE" 2>/dev/null || echo "0")
  COMPLETED_TASKS=$(grep -c '^\s*- \[x\]' "$STORY_FILE" 2>/dev/null || echo "0")

  # Check story status
  STORY_STATUS=$(grep -i '^Status:' "$STORY_FILE" | head -1 | sed 's/Status:\s*//' | tr -d '[:space:]' || echo "")

  # Check if story is complete
  if [[ "$STORY_STATUS" == "done" ]] || [[ "$STORY_STATUS" == "complete" ]] || [[ "$STORY_STATUS" == "DONE" ]]; then
    echo ">>> BMAD Harness: Story marked as DONE!"
    echo ">>> Story progress: $COMPLETED_TASKS/$TOTAL_TASKS tasks completed"
    rm "$BMAD_STATE_FILE"
    exit 0
  fi

  # Check if all tasks are complete
  if [[ "$TOTAL_TASKS" -gt 0 ]] && [[ "$COMPLETED_TASKS" -ge "$TOTAL_TASKS" ]]; then
    echo ">>> BMAD Harness: All tasks complete ($COMPLETED_TASKS/$TOTAL_TASKS)!"
    echo ">>> Note: Update story Status to 'done' for full completion"
    rm "$BMAD_STATE_FILE"
    exit 0
  fi
fi

# Read last assistant message for completion promise check
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 || echo "")
if [[ -n "$LAST_LINE" ]]; then
  LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
    .message.content |
    map(select(.type == "text")) |
    map(.text) |
    join("\n")
  ' 2>/dev/null || echo "")

  # Check for completion promise
  if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
    PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

    if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
      echo ">>> BMAD Harness: Completion promise detected: $COMPLETION_PROMISE"

      # Show final progress
      if [[ -f "$STORY_FILE" ]]; then
        TOTAL_TASKS=$(grep -c '^\s*- \[' "$STORY_FILE" 2>/dev/null || echo "0")
        COMPLETED_TASKS=$(grep -c '^\s*- \[x\]' "$STORY_FILE" 2>/dev/null || echo "0")
        echo ">>> Story progress: $COMPLETED_TASKS/$TOTAL_TASKS tasks completed"
      fi

      rm "$BMAD_STATE_FILE"
      exit 0
    fi
  fi
fi

# Not complete - continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Build progress context
PROGRESS_CONTEXT=""
if [[ -f "$STORY_FILE" ]]; then
  TOTAL_TASKS=$(grep -c '^\s*- \[' "$STORY_FILE" 2>/dev/null || echo "0")
  COMPLETED_TASKS=$(grep -c '^\s*- \[x\]' "$STORY_FILE" 2>/dev/null || echo "0")

  # Get list of incomplete tasks
  REMAINING_TASKS=$(grep '^\s*- \[ \]' "$STORY_FILE" 2>/dev/null | head -5 | sed 's/^\s*- \[ \]/  •/' || echo "")

  if [[ -n "$REMAINING_TASKS" ]]; then
    PROGRESS_CONTEXT="

---
PROGRESS CONTEXT (iteration $NEXT_ITERATION):
Completed: $COMPLETED_TASKS / $TOTAL_TASKS tasks

Remaining tasks:
$REMAINING_TASKS

Continue implementing the story. Update task checkboxes as you complete them.
When done, update the Status field to 'done'.
---"
  fi
fi

# Extract the story prompt (everything after closing ---)
STORY_PROMPT=$(awk '/^---$/{i++; next} i>=2' "$BMAD_STATE_FILE")

if [[ -z "$STORY_PROMPT" ]]; then
  echo ">>> BMAD Harness: No story prompt in state file" >&2
  rm "$BMAD_STATE_FILE"
  exit 0
fi

# Update iteration in frontmatter
TEMP_FILE="${BMAD_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$BMAD_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$BMAD_STATE_FILE"

# Create git checkpoint if changes exist
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    git add -A 2>/dev/null || true
    git commit -m "BMAD Harness: iteration $ITERATION checkpoint" --no-verify 2>/dev/null || true
  fi
fi

# Build system message
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG=">>> BMAD Harness iteration $NEXT_ITERATION | Tasks: $COMPLETED_TASKS/$TOTAL_TASKS | Complete: <promise>$COMPLETION_PROMISE</promise>"
else
  SYSTEM_MSG=">>> BMAD Harness iteration $NEXT_ITERATION | Tasks: $COMPLETED_TASKS/$TOTAL_TASKS | Mark Status: done when complete"
fi

# Output JSON to block stop and re-feed story prompt
jq -n \
  --arg prompt "${STORY_PROMPT}${PROGRESS_CONTEXT}" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
