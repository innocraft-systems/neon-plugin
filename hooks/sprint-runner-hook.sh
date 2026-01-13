#!/bin/bash

# BMAD Sprint Runner - Stop Hook
# Two-level loop handler:
# 1. Story-level: persists through context exhaustion within a story
# 2. Sprint-level: chains stories together automatically
#
# Flow:
#   Context Exit →
#     Story complete? →
#       YES → Mark DONE → Next story ready? →
#         YES → Feed next story prompt
#         NO  → All done, allow exit
#       NO → Re-feed current story prompt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# RAG Integration - Path to bmad-rag scripts
BMAD_RAG_ROOT="${BMAD_RAG_ROOT:-}"
RAG_SCRIPT=""

# Try to find bmad-rag in common locations
if [[ -z "$BMAD_RAG_ROOT" ]]; then
  for rag_path in \
    "$HOME/projects/bmad-rag" \
    "$HOME/bmad-rag" \
    "/opt/bmad-rag" \
    "$(dirname "$PLUGIN_ROOT")/bmad-rag" \
    "E:/projects/bmad-rag"; do
    if [[ -f "$rag_path/scripts/get_story_context.py" ]]; then
      BMAD_RAG_ROOT="$rag_path"
      break
    fi
  done
fi

if [[ -n "$BMAD_RAG_ROOT" ]] && [[ -f "$BMAD_RAG_ROOT/scripts/get_story_context.py" ]]; then
  RAG_SCRIPT="$BMAD_RAG_ROOT/scripts/get_story_context.py"
fi

# Function to get RAG context for a story
get_rag_context() {
  local story_id="$1"
  local story_title="${2:-}"
  local project_root="${3:-.}"

  if [[ -z "$RAG_SCRIPT" ]]; then
    return 0  # RAG not available, silent return
  fi

  # Call the RAG script
  local rag_output
  if [[ -n "$story_title" ]]; then
    rag_output=$(python3 "$RAG_SCRIPT" "$story_id" --title "$story_title" --project "$project_root" 2>/dev/null || echo "")
  else
    rag_output=$(python3 "$RAG_SCRIPT" "$story_id" --project "$project_root" 2>/dev/null || echo "")
  fi

  echo "$rag_output"
}

# Read hook input from stdin
HOOK_INPUT=$(cat)

# State files
SPRINT_DIR=".claude/sprint-runner"
STATE_FILE="$SPRINT_DIR/sprint.state.json"
SPRINT_STATUS_DEFAULT="_bmad-output/sprint-status.yaml"

# ============================================
# CHECK IF SPRINT RUNNER IS ACTIVE
# ============================================

if [[ ! -f "$STATE_FILE" ]]; then
  # No active sprint runner - allow exit
  exit 0
fi

# Parse state
STATE=$(cat "$STATE_FILE")
ACTIVE=$(echo "$STATE" | jq -r '.active // false')

if [[ "$ACTIVE" != "true" ]]; then
  exit 0
fi

# Extract state values
SPRINT_ID=$(echo "$STATE" | jq -r '.sprint_id // "unknown"')
ITERATION=$(echo "$STATE" | jq -r '.iteration // 1')
CURRENT_STORY=$(echo "$STATE" | jq -r '.current_story // ""')
CURRENT_STORY_FILE=$(echo "$STATE" | jq -r '.current_story_file // ""')
STORIES_COMPLETED=$(echo "$STATE" | jq -r '.stories_completed // 0')
STORIES_FAILED=$(echo "$STATE" | jq -r '.stories_failed // 0')
STORIES_TOTAL=$(echo "$STATE" | jq -r '.stories_total // 0')
STOP_ON_FAIL=$(echo "$STATE" | jq -r '.options.stop_on_fail // false')
SKIP_REVIEW=$(echo "$STATE" | jq -r '.options.skip_review // false')
SPRINT_STATUS=$(echo "$STATE" | jq -r '.config.sprint_status_file // ""')
ARCH_DOC=$(echo "$STATE" | jq -r '.config.architecture_doc // ""')
SPEC_DOC=$(echo "$STATE" | jq -r '.config.spec_doc // ""')

# Use default if not set
if [[ -z "$SPRINT_STATUS" ]] || [[ ! -f "$SPRINT_STATUS" ]]; then
  SPRINT_STATUS="$SPRINT_STATUS_DEFAULT"
fi

# ============================================
# GET TRANSCRIPT AND CHECK FOR COMPLETION
# ============================================

TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo ">>> Sprint Runner: Transcript not found, continuing..." >&2
  # Re-feed current story
  NEXT_ITERATION=$((ITERATION + 1))
  jq ".iteration = $NEXT_ITERATION" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"

  # Build continuation prompt
  CONTINUE_PROMPT="Continue implementing the current story.

Story: $CURRENT_STORY
File: $CURRENT_STORY_FILE
Progress: $((STORIES_COMPLETED + 1)) of $STORIES_TOTAL

Read the story file and continue where you left off.
When complete, output: <story-complete>$CURRENT_STORY</story-complete>"

  jq -n \
    --arg prompt "$CONTINUE_PROMPT" \
    --arg msg ">>> Sprint Runner: Iteration $NEXT_ITERATION | Story $((STORIES_COMPLETED + 1))/$STORIES_TOTAL" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }'
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 || echo "")
LAST_OUTPUT=""

if [[ -n "$LAST_LINE" ]]; then
  LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
    .message.content //
    .content |
    if type == "array" then
      map(select(.type == "text")) |
      map(.text) |
      join("\n")
    else
      . // ""
    end
  ' 2>/dev/null || echo "")
fi

# ============================================
# CHECK FOR STORY COMPLETION
# ============================================

STORY_COMPLETE=false

# Check for <story-complete>STORY_ID</story-complete> tag
if [[ -n "$LAST_OUTPUT" ]]; then
  COMPLETION_TAG=$(echo "$LAST_OUTPUT" | grep -oP '<story-complete>\K[^<]+' 2>/dev/null || echo "")

  if [[ -n "$COMPLETION_TAG" ]]; then
    # Verify it matches current story (or accept any completion)
    if [[ "$COMPLETION_TAG" == "$CURRENT_STORY" ]] || [[ "$COMPLETION_TAG" == *"$CURRENT_STORY"* ]]; then
      STORY_COMPLETE=true
      echo ">>> Sprint Runner: Story complete signal detected: $CURRENT_STORY" >&2
    fi
  fi
fi

# Also check for sprint completion
SPRINT_COMPLETE=false
if echo "$LAST_OUTPUT" | grep -q '<sprint-complete>' 2>/dev/null; then
  SPRINT_COMPLETE=true
fi

# ============================================
# STORY INCOMPLETE - CONTINUE CURRENT STORY
# ============================================

if [[ "$STORY_COMPLETE" != "true" ]] && [[ "$SPRINT_COMPLETE" != "true" ]]; then
  NEXT_ITERATION=$((ITERATION + 1))

  # Update iteration in state
  jq ".iteration = $NEXT_ITERATION" "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"

  # Git checkpoint
  if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      git add -A 2>/dev/null || true
      git commit -m "Sprint $SPRINT_ID: $CURRENT_STORY iteration $ITERATION checkpoint" --no-verify 2>/dev/null || true
    fi
  fi

  # Read current story to get remaining tasks
  REMAINING_TASKS=""
  if [[ -f "$CURRENT_STORY_FILE" ]]; then
    TOTAL_TASKS=$(grep -c '^\s*- \[' "$CURRENT_STORY_FILE" 2>/dev/null || echo "0")
    COMPLETED_TASKS=$(grep -c '^\s*- \[x\]' "$CURRENT_STORY_FILE" 2>/dev/null || echo "0")

    REMAINING=$(grep '^\s*- \[ \]' "$CURRENT_STORY_FILE" 2>/dev/null | head -5 | sed 's/^\s*- \[ \]/  •/' || echo "")
    if [[ -n "$REMAINING" ]]; then
      REMAINING_TASKS="
Completed: $COMPLETED_TASKS / $TOTAL_TASKS tasks

Remaining tasks:
$REMAINING"
    fi
  fi

  # Build continuation prompt
  CONTINUE_PROMPT="Continue implementing the story.

## Current Story

Story ID: $CURRENT_STORY
File: $CURRENT_STORY_FILE
Sprint Progress: $((STORIES_COMPLETED + 1)) of $STORIES_TOTAL
$REMAINING_TASKS

## Instructions

1. Read the story file: $CURRENT_STORY_FILE
2. Continue from where you left off
3. Follow TDD: red-green-refactor
4. Update task checkboxes as you complete them
5. When ALL acceptance criteria are met, output:

   <story-complete>$CURRENT_STORY</story-complete>"

  if [[ -n "$ARCH_DOC" ]]; then
    CONTINUE_PROMPT+="

Reference architecture: $ARCH_DOC"
  fi

  # Get RAG context for continuation
  CONT_RAG_CONTEXT=$(get_rag_context "$CURRENT_STORY" "" "$(pwd)")
  if [[ -n "$CONT_RAG_CONTEXT" ]]; then
    CONTINUE_PROMPT+="

$CONT_RAG_CONTEXT"
  fi

  SYSTEM_MSG=">>> Sprint Runner: Iteration $NEXT_ITERATION | Story $((STORIES_COMPLETED + 1))/$STORIES_TOTAL | $CURRENT_STORY"

  jq -n \
    --arg prompt "$CONTINUE_PROMPT" \
    --arg msg "$SYSTEM_MSG" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }'
  exit 0
fi

# ============================================
# STORY COMPLETE - MARK DONE AND MOVE TO NEXT
# ============================================

echo ">>> Sprint Runner: Marking $CURRENT_STORY as DONE" >&2

# Update sprint-status.yaml
if [[ -f "$SPRINT_STATUS" ]]; then
  # Replace TODO/IN.PROGRESS with DONE for this story
  sed -i "s/\(id:[[:space:]]*$CURRENT_STORY\)/\1/; /id:[[:space:]]*$CURRENT_STORY/,/status:/{s/status:[[:space:]]*TODO/status: DONE/; s/status:[[:space:]]*IN.PROGRESS/status: DONE/}" "$SPRINT_STATUS" 2>/dev/null || true
fi

# Update story file status if it has one
if [[ -f "$CURRENT_STORY_FILE" ]]; then
  sed -i 's/^Status:[[:space:]]*TODO/Status: DONE/i; s/^Status:[[:space:]]*in.progress/Status: DONE/i' "$CURRENT_STORY_FILE" 2>/dev/null || true
fi

# Git commit for completed story
if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
  git add -A 2>/dev/null || true
  git commit -m "Sprint $SPRINT_ID: Completed $CURRENT_STORY [$((STORIES_COMPLETED + 1))/$STORIES_TOTAL]" --no-verify 2>/dev/null || true
fi

# Update state: increment completed count
NEW_COMPLETED=$((STORIES_COMPLETED + 1))
jq ".stories_completed = $NEW_COMPLETED" "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"

# ============================================
# FIND NEXT READY STORY
# ============================================

echo ">>> Sprint Runner: Finding next ready story..." >&2

# Remove completed story from queue and find next
STORY_QUEUE=$(echo "$STATE" | jq -r '.story_queue // []')
REMAINING_QUEUE=$(echo "$STORY_QUEUE" | jq --arg id "$CURRENT_STORY" '[.[] | select(.id != $id)]')
REMAINING_COUNT=$(echo "$REMAINING_QUEUE" | jq 'length')

# Update queue in state
jq --argjson queue "$REMAINING_QUEUE" '.story_queue = $queue' "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"

# ============================================
# CHECK IF SPRINT IS COMPLETE
# ============================================

if [[ "$REMAINING_COUNT" == "0" ]] || [[ "$SPRINT_COMPLETE" == "true" ]]; then
  echo ">>> Sprint Runner: ALL STORIES COMPLETE!" >&2
  echo ">>> Sprint $SPRINT_ID finished: $NEW_COMPLETED stories" >&2

  # Generate completion report
  cat > "$SPRINT_DIR/sprint-report.md" << EOF
# Sprint Completion Report

**Sprint ID:** $SPRINT_ID
**Completed:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Summary

| Metric | Value |
|--------|-------|
| Stories Completed | $NEW_COMPLETED |
| Stories Failed | $STORIES_FAILED |
| Total Stories | $STORIES_TOTAL |
| Total Iterations | $ITERATION |

## Status

All stories have been implemented and marked DONE.

---

*Generated by BMAD Sprint Runner*
EOF

  # Mark sprint as inactive
  jq '.active = false' "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"

  # Allow exit
  exit 0
fi

# ============================================
# LOAD NEXT STORY
# ============================================

# Get next story from queue
NEXT_STORY=$(echo "$REMAINING_QUEUE" | jq -r '.[0]')
NEXT_STORY_ID=$(echo "$NEXT_STORY" | jq -r '.id')
NEXT_STORY_FILE=$(echo "$NEXT_STORY" | jq -r '.file')
NEXT_STORY_EPIC=$(echo "$NEXT_STORY" | jq -r '.epic')

echo ">>> Sprint Runner: Next story: $NEXT_STORY_ID" >&2

# Update state with new current story
jq --arg id "$NEXT_STORY_ID" --arg file "$NEXT_STORY_FILE" \
  '.current_story = $id | .current_story_file = $file | .iteration = 1' \
  "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"

# ============================================
# BUILD NEXT STORY PROMPT
# ============================================

NEXT_PROMPT="## New Story Starting

You've completed $CURRENT_STORY. Now implementing the next story.

### Sprint Progress

Story: $((NEW_COMPLETED + 1)) of $STORIES_TOTAL
Current Story: $NEXT_STORY_ID
Epic: $NEXT_STORY_EPIC

### Your Mission

Implement this story completely, following red-green-refactor TDD methodology.

### Story File

Read and implement: $NEXT_STORY_FILE

### Reference Documents"

if [[ -n "$ARCH_DOC" ]]; then
  NEXT_PROMPT+="
- Architecture: $ARCH_DOC"
fi

if [[ -n "$SPEC_DOC" ]]; then
  NEXT_PROMPT+="
- Specification: $SPEC_DOC"
fi

# Get RAG context for the story
RAG_CONTEXT=$(get_rag_context "$NEXT_STORY_ID" "" "$(pwd)")

if [[ -n "$RAG_CONTEXT" ]]; then
  NEXT_PROMPT+="

$RAG_CONTEXT"
fi

NEXT_PROMPT+="

### Workflow

1. **Read the story file** - Understand acceptance criteria and tasks
2. **For each task:**
   - Write failing tests first (RED)
   - Implement minimal code to pass (GREEN)
   - Refactor if needed (REFACTOR)
   - Mark task checkbox [x] when complete
3. **Validate** - Run all tests, ensure they pass
4. **Complete** - When ALL acceptance criteria are met, output:

   <story-complete>$NEXT_STORY_ID</story-complete>

### Critical Rules

- NEVER skip tests - TDD is mandatory
- Update checkboxes in the story file as you complete tasks
- All existing tests must continue to pass
- Follow project coding standards and patterns

Begin by reading the story file: $NEXT_STORY_FILE"

SYSTEM_MSG=">>> Sprint Runner: Story $((NEW_COMPLETED + 1))/$STORIES_TOTAL | Starting $NEXT_STORY_ID"

jq -n \
  --arg prompt "$NEXT_PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
