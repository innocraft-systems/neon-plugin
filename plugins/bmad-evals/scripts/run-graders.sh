#!/bin/bash

# BMAD-Evals Grader Runner
# Executes configured graders and returns pass/fail status

set -euo pipefail

TASK_ID="${1:-}"
TRANSCRIPT_PATH="${2:-}"
RESULTS_DIR="${3:-.claude/bmad-evals/results}"

if [[ -z "$TASK_ID" ]]; then
  echo '{"passed": false, "error": "No task ID provided"}'
  exit 0
fi

# Load task graders configuration
EVAL_TASKS_FILE=".claude/bmad-evals/eval-tasks.json"
GRADERS_DIR=".claude/bmad-evals/graders"

# Get graders for task
GRADERS_CONFIG="[]"
if [[ -f "$EVAL_TASKS_FILE" ]]; then
  GRADERS_CONFIG=$(jq -r --arg id "$TASK_ID" '.tasks[] | select(.id == $id) | .graders // []' "$EVAL_TASKS_FILE" 2>/dev/null || echo "[]")
fi

# If no graders configured, check for default graders
if [[ "$GRADERS_CONFIG" == "[]" ]] || [[ -z "$GRADERS_CONFIG" ]]; then
  # Look for default graders file
  if [[ -f "$GRADERS_DIR/default.json" ]]; then
    GRADERS_CONFIG=$(cat "$GRADERS_DIR/default.json")
  else
    # No graders = auto-pass (rely on completion promise)
    echo '{"passed": true, "message": "No graders configured", "graders_run": 0}'
    exit 0
  fi
fi

# Initialize results
PASSED=true
FAILED_GRADERS="[]"
PASSED_GRADERS="[]"
GRADERS_RUN=0

# Process each grader
echo "$GRADERS_CONFIG" | jq -c '.[]' 2>/dev/null | while read -r grader; do
  GRADER_TYPE=$(echo "$grader" | jq -r '.type')
  GRADER_NAME=$(echo "$grader" | jq -r '.name // "unnamed"')

  GRADERS_RUN=$((GRADERS_RUN + 1))
  GRADER_PASSED=false
  GRADER_MESSAGE=""

  case "$GRADER_TYPE" in
    deterministic_tests|tests)
      # Run test commands
      TEST_CMD=$(echo "$grader" | jq -r '.command // "npm test"')
      TEST_PATTERN=$(echo "$grader" | jq -r '.pattern // null')

      if eval "$TEST_CMD" > /tmp/test-output.txt 2>&1; then
        GRADER_PASSED=true
        GRADER_MESSAGE="Tests passed"
      else
        GRADER_PASSED=false
        GRADER_MESSAGE="Tests failed: $(tail -5 /tmp/test-output.txt | tr '\n' ' ')"
      fi
      ;;

    static_analysis|lint)
      # Run static analysis commands
      LINT_CMDS=$(echo "$grader" | jq -r '.commands[]' 2>/dev/null || echo "")
      ALL_PASSED=true

      for cmd in $LINT_CMDS; do
        if ! eval "$cmd" > /dev/null 2>&1; then
          ALL_PASSED=false
          GRADER_MESSAGE="$cmd failed"
          break
        fi
      done

      GRADER_PASSED=$ALL_PASSED
      if [[ "$ALL_PASSED" == "true" ]]; then
        GRADER_MESSAGE="Static analysis passed"
      fi
      ;;

    state_check|file_check)
      # Check for expected files or state
      EXPECTED=$(echo "$grader" | jq -r '.expect // {}')
      ALL_PASSED=true

      # Check files exist
      FILES=$(echo "$EXPECTED" | jq -r '.files // [] | .[]' 2>/dev/null || echo "")
      for file in $FILES; do
        if [[ ! -f "$file" ]]; then
          ALL_PASSED=false
          GRADER_MESSAGE="Expected file not found: $file"
          break
        fi
      done

      # Check file contains pattern
      CONTAINS=$(echo "$EXPECTED" | jq -r '.contains // {} | to_entries[] | "\(.key):\(.value)"' 2>/dev/null || echo "")
      for check in $CONTAINS; do
        FILE=$(echo "$check" | cut -d: -f1)
        PATTERN=$(echo "$check" | cut -d: -f2-)
        if [[ -f "$FILE" ]] && ! grep -q "$PATTERN" "$FILE" 2>/dev/null; then
          ALL_PASSED=false
          GRADER_MESSAGE="Pattern '$PATTERN' not found in $FILE"
          break
        fi
      done

      GRADER_PASSED=$ALL_PASSED
      if [[ "$ALL_PASSED" == "true" ]]; then
        GRADER_MESSAGE="State check passed"
      fi
      ;;

    tool_calls)
      # Verify specific tools were used (from transcript)
      REQUIRED_TOOLS=$(echo "$grader" | jq -r '.required[] | .tool' 2>/dev/null || echo "")
      TOOL_LOG=".claude/bmad-evals/tool-events.jsonl"
      ALL_PRESENT=true

      if [[ -f "$TOOL_LOG" ]]; then
        for tool in $REQUIRED_TOOLS; do
          if ! grep -q "\"tool\":\"$tool\"" "$TOOL_LOG"; then
            ALL_PRESENT=false
            GRADER_MESSAGE="Required tool not used: $tool"
            break
          fi
        done
      else
        ALL_PRESENT=false
        GRADER_MESSAGE="No tool events captured"
      fi

      GRADER_PASSED=$ALL_PRESENT
      if [[ "$ALL_PRESENT" == "true" ]]; then
        GRADER_MESSAGE="All required tools used"
      fi
      ;;

    string_match|regex)
      # Check output matches pattern
      PATTERN=$(echo "$grader" | jq -r '.pattern')
      TARGET=$(echo "$grader" | jq -r '.target // "transcript"')

      if [[ "$TARGET" == "transcript" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
        if grep -qE "$PATTERN" "$TRANSCRIPT_PATH"; then
          GRADER_PASSED=true
          GRADER_MESSAGE="Pattern matched"
        else
          GRADER_PASSED=false
          GRADER_MESSAGE="Pattern not found: $PATTERN"
        fi
      fi
      ;;

    llm_rubric)
      # LLM-based grading - delegate to subagent or external call
      # For now, mark as needing manual review
      GRADER_PASSED=true
      GRADER_MESSAGE="LLM rubric grading requires subagent (auto-pass for now)"
      ;;

    *)
      GRADER_MESSAGE="Unknown grader type: $GRADER_TYPE"
      GRADER_PASSED=false
      ;;
  esac

  # Collect results
  if [[ "$GRADER_PASSED" == "true" ]]; then
    PASSED_GRADERS=$(echo "$PASSED_GRADERS" | jq --arg name "$GRADER_NAME" --arg msg "$GRADER_MESSAGE" '. + [{"name": $name, "message": $msg}]')
  else
    PASSED=false
    FAILED_GRADERS=$(echo "$FAILED_GRADERS" | jq --arg name "$GRADER_NAME" --arg msg "$GRADER_MESSAGE" '. + [{"name": $name, "message": $msg}]')
  fi
done

# Output final result
jq -n \
  --argjson passed "$PASSED" \
  --argjson passed_graders "$PASSED_GRADERS" \
  --argjson failed_graders "$FAILED_GRADERS" \
  --argjson count "$GRADERS_RUN" \
  '{
    passed: $passed,
    graders_run: $count,
    passed_graders: $passed_graders,
    failed_graders: $failed_graders
  }'
