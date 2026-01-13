#!/bin/bash

# BMAD-Evals Loop Setup Script
# Initializes eval loop state with task configuration

set -euo pipefail

# Default values
TASK_ID=""
TASK_PROMPT=""
MAX_ITERATIONS=50
COMPLETION_PROMISE="null"
MODE="single"
GRADERS_CONFIG=""
RUN_SUITE=false
SUITE_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
BMAD-Evals Loop - Structured eval execution with grading

USAGE:
  /eval-run [OPTIONS] [PROMPT...]

OPTIONS:
  --task <id>                  Run specific task from eval-tasks.json
  --suite <name>               Run entire eval suite
  --max-iterations <n>         Max iterations before stopping (default: 50)
  --completion-promise <text>  Promise phrase signaling completion
  --graders <config>           Path to graders config or inline JSON
  -h, --help                   Show this help

MODES:
  Single Task: Run one eval task until graders pass
  Suite Mode: Run all tasks in a suite sequentially

EXAMPLES:
  /eval-run --task auth-bypass-fix --max-iterations 20
  /eval-run --suite regression --max-iterations 100
  /eval-run "Fix the auth bug" --completion-promise "ALL TESTS PASS"

GRADER TYPES:
  - deterministic: Unit tests, static analysis, exact matches
  - llm_rubric: Model-based grading with criteria
  - state_check: Verify environment state (files, DB, etc.)
  - tool_calls: Verify specific tools were used

MONITORING:
  cat .claude/bmad-evals/eval-loop.state.json
  ls .claude/bmad-evals/results/
HELP_EOF
      exit 0
      ;;
    --task)
      TASK_ID="$2"
      shift 2
      ;;
    --suite)
      SUITE_NAME="$2"
      RUN_SUITE=true
      shift 2
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo ">>> Error: --max-iterations requires a positive integer" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo ">>> Error: --completion-promise requires text argument" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --graders)
      GRADERS_CONFIG="$2"
      shift 2
      ;;
    *)
      # Collect as prompt parts
      if [[ -z "$TASK_PROMPT" ]]; then
        TASK_PROMPT="$1"
      else
        TASK_PROMPT="$TASK_PROMPT $1"
      fi
      shift
      ;;
  esac
done

# Create eval directories
mkdir -p .claude/bmad-evals/results
mkdir -p .claude/bmad-evals/graders
mkdir -p .claude/bmad-evals/transcripts

# Initialize or load tasks file
EVAL_TASKS_FILE=".claude/bmad-evals/eval-tasks.json"
if [[ ! -f "$EVAL_TASKS_FILE" ]]; then
  echo '{"tasks": [], "suites": {}}' > "$EVAL_TASKS_FILE"
fi

# Determine task prompt
if [[ -n "$TASK_ID" ]]; then
  # Load task from tasks file
  TASK_DATA=$(jq -r --arg id "$TASK_ID" '.tasks[] | select(.id == $id)' "$EVAL_TASKS_FILE")
  if [[ -z "$TASK_DATA" ]] || [[ "$TASK_DATA" == "null" ]]; then
    echo ">>> Error: Task '$TASK_ID' not found in $EVAL_TASKS_FILE" >&2
    echo "    Run /eval-task-add to create tasks first" >&2
    exit 1
  fi
  TASK_PROMPT=$(echo "$TASK_DATA" | jq -r '.prompt')
  GRADERS_CONFIG=$(echo "$TASK_DATA" | jq -r '.graders // []')
elif [[ -z "$TASK_PROMPT" ]]; then
  echo ">>> Error: No task specified" >&2
  echo "    Provide --task <id>, --suite <name>, or inline prompt" >&2
  exit 1
fi

# Set task ID if not provided
if [[ -z "$TASK_ID" ]]; then
  TASK_ID="inline-$(date +%s)"
fi

# Create state file
STATE_FILE=".claude/bmad-evals/eval-loop.state.json"

cat > "$STATE_FILE" <<EOF
{
  "active": true,
  "iteration": 1,
  "max_iterations": $MAX_ITERATIONS,
  "current_task": "$TASK_ID",
  "mode": "$MODE",
  "prompt": $(echo "$TASK_PROMPT" | jq -Rs .),
  "completion_promise": $(if [[ "$COMPLETION_PROMISE" == "null" ]]; then echo "null"; else echo "\"$COMPLETION_PROMISE\""; fi),
  "graders_config": $(echo "$GRADERS_CONFIG" | jq -Rs .),
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "run_id": "eval-$(date +%s)"
}
EOF

# Output setup confirmation
cat <<EOF
>>> BMAD-Evals loop activated!

Task ID: $TASK_ID
Max iterations: $MAX_ITERATIONS
Completion promise: $(if [[ "$COMPLETION_PROMISE" == "null" ]]; then echo "none (graders only)"; else echo "$COMPLETION_PROMISE"; fi)

The eval loop is now active. After each attempt:
1. Graders will evaluate your work
2. If graders fail, you'll receive feedback and continue
3. If graders pass (or promise detected), the loop ends

Results saved to: .claude/bmad-evals/results/

>>> TASK PROMPT:
$TASK_PROMPT
EOF

# Display grader info if configured
if [[ -n "$GRADERS_CONFIG" ]] && [[ "$GRADERS_CONFIG" != "null" ]] && [[ "$GRADERS_CONFIG" != "[]" ]]; then
  echo ""
  echo ">>> CONFIGURED GRADERS:"
  echo "$GRADERS_CONFIG" | jq -r '.[] | "  - " + .type + ": " + .name' 2>/dev/null || echo "  (inline graders)"
fi

if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "==============================================================="
  echo "COMPLETION REQUIREMENT"
  echo "==============================================================="
  echo ""
  echo "When complete, output: <promise>$COMPLETION_PROMISE</promise>"
  echo ""
  echo "ONLY output this when the statement is TRUE."
  echo "Do NOT lie to exit the loop."
  echo "==============================================================="
fi

echo ""
echo "$TASK_PROMPT"
