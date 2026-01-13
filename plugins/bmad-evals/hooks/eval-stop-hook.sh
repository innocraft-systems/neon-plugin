#!/bin/bash

# BMAD-Evals Stop Hook
# Combines Ralph-wiggum's self-referential loop with eval grading
# Runs graders after each iteration and tracks pass/fail metrics

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# State files
EVAL_STATE_FILE=".claude/bmad-evals/eval-loop.state.json"
EVAL_TASKS_FILE=".claude/bmad-evals/eval-tasks.json"
EVAL_RESULTS_DIR=".claude/bmad-evals/results"
TRANSCRIPT_LOG=".claude/bmad-evals/transcript.jsonl"

# Check if eval loop is active
if [[ ! -f "$EVAL_STATE_FILE" ]]; then
  # No active eval loop - allow exit
  exit 0
fi

# Parse state file
STATE=$(cat "$EVAL_STATE_FILE")
ACTIVE=$(echo "$STATE" | jq -r '.active')
ITERATION=$(echo "$STATE" | jq -r '.iteration')
MAX_ITERATIONS=$(echo "$STATE" | jq -r '.max_iterations')
CURRENT_TASK=$(echo "$STATE" | jq -r '.current_task')
MODE=$(echo "$STATE" | jq -r '.mode // "single"')
COMPLETION_PROMISE=$(echo "$STATE" | jq -r '.completion_promise // null')

# Validate state
if [[ "$ACTIVE" != "true" ]]; then
  exit 0
fi

if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo ">>> BMAD-Evals: State corrupted (invalid iteration)" >&2
  rm "$EVAL_STATE_FILE"
  exit 0
fi

# Check max iterations
if [[ "$MAX_ITERATIONS" != "0" ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo ">>> BMAD-Evals: Max iterations ($MAX_ITERATIONS) reached"

  # Generate final report
  "${CLAUDE_PLUGIN_ROOT}/scripts/generate-report.sh" "$EVAL_RESULTS_DIR"

  rm "$EVAL_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo ">>> BMAD-Evals: Transcript not found" >&2
  rm "$EVAL_STATE_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 || echo "")
if [[ -z "$LAST_LINE" ]]; then
  echo ">>> BMAD-Evals: No assistant messages in transcript" >&2
  rm "$EVAL_STATE_FILE"
  exit 0
fi

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
    echo ">>> BMAD-Evals: Completion promise detected: $COMPLETION_PROMISE"

    # Run final graders
    "${CLAUDE_PLUGIN_ROOT}/scripts/run-graders.sh" "$CURRENT_TASK" "$TRANSCRIPT_PATH" "$EVAL_RESULTS_DIR"

    # Generate report
    "${CLAUDE_PLUGIN_ROOT}/scripts/generate-report.sh" "$EVAL_RESULTS_DIR"

    rm "$EVAL_STATE_FILE"
    exit 0
  fi
fi

# Run graders for current iteration
GRADER_RESULT=$("${CLAUDE_PLUGIN_ROOT}/scripts/run-graders.sh" "$CURRENT_TASK" "$TRANSCRIPT_PATH" "$EVAL_RESULTS_DIR" 2>&1 || echo '{"passed": false}')
GRADERS_PASSED=$(echo "$GRADER_RESULT" | jq -r '.passed // false')

# Log iteration result
mkdir -p "$EVAL_RESULTS_DIR"
RESULT_FILE="$EVAL_RESULTS_DIR/iteration-$ITERATION.json"
cat > "$RESULT_FILE" <<EOF
{
  "iteration": $ITERATION,
  "task": "$CURRENT_TASK",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "graders_passed": $GRADERS_PASSED,
  "grader_output": $GRADER_RESULT
}
EOF

# Check if all graders passed (for single-task mode)
if [[ "$GRADERS_PASSED" == "true" ]] && [[ "$MODE" == "single" ]]; then
  echo ">>> BMAD-Evals: All graders PASSED on iteration $ITERATION!"

  # Generate success report
  "${CLAUDE_PLUGIN_ROOT}/scripts/generate-report.sh" "$EVAL_RESULTS_DIR"

  rm "$EVAL_STATE_FILE"
  exit 0
fi

# Continue loop - increment iteration
NEXT_ITERATION=$((ITERATION + 1))

# Update state
jq ".iteration = $NEXT_ITERATION" "$EVAL_STATE_FILE" > "${EVAL_STATE_FILE}.tmp"
mv "${EVAL_STATE_FILE}.tmp" "$EVAL_STATE_FILE"

# Get the task prompt
TASK_PROMPT=""
if [[ -f "$EVAL_TASKS_FILE" ]] && [[ "$CURRENT_TASK" != "null" ]]; then
  TASK_PROMPT=$(jq -r --arg task "$CURRENT_TASK" '.tasks[] | select(.id == $task) | .prompt' "$EVAL_TASKS_FILE" 2>/dev/null || echo "")
fi

if [[ -z "$TASK_PROMPT" ]]; then
  TASK_PROMPT=$(echo "$STATE" | jq -r '.prompt // "Continue working on the current task."')
fi

# Build grader feedback
GRADER_FEEDBACK=""
if [[ "$GRADERS_PASSED" == "false" ]]; then
  FAILED_GRADERS=$(echo "$GRADER_RESULT" | jq -r '.failed_graders // [] | .[] | "- " + .name + ": " + .message' 2>/dev/null || echo "")
  if [[ -n "$FAILED_GRADERS" ]]; then
    GRADER_FEEDBACK="

GRADER FEEDBACK (iteration $ITERATION):
The following graders did not pass:
$FAILED_GRADERS

Please address these issues and continue."
  fi
fi

# Build system message
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG=">>> BMAD-Evals iteration $NEXT_ITERATION | Graders: $(if [[ $GRADERS_PASSED == 'true' ]]; then echo 'PASSED'; else echo 'FAILED'; fi) | Complete: <promise>$COMPLETION_PROMISE</promise>"
else
  SYSTEM_MSG=">>> BMAD-Evals iteration $NEXT_ITERATION | Graders: $(if [[ $GRADERS_PASSED == 'true' ]]; then echo 'PASSED'; else echo 'FAILED'; fi)"
fi

# Output JSON to block stop and feed prompt back
jq -n \
  --arg prompt "${TASK_PROMPT}${GRADER_FEEDBACK}" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
