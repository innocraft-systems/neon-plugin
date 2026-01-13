#!/bin/bash

# Setup BMAD Story Harness
# Initializes the Ralph-ish loop for BMAD dev-story execution
#
# Usage: setup-bmad-harness.sh <story-file> [options]
# Options:
#   --max-iterations <n>    Maximum iterations (default: 100)
#   --promise <text>        Completion promise phrase (default: "STORY COMPLETE")

set -euo pipefail

# Parse arguments
STORY_FILE=""
MAX_ITERATIONS=100
COMPLETION_PROMISE="STORY COMPLETE"

while [[ $# -gt 0 ]]; do
  case $1 in
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --promise)
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    *)
      if [[ -z "$STORY_FILE" ]]; then
        STORY_FILE="$1"
      fi
      shift
      ;;
  esac
done

# Validate story file
if [[ -z "$STORY_FILE" ]]; then
  echo "Error: Story file path required"
  echo "Usage: setup-bmad-harness.sh <story-file> [--max-iterations <n>] [--promise <text>]"
  exit 1
fi

if [[ ! -f "$STORY_FILE" ]]; then
  echo "Error: Story file not found: $STORY_FILE"
  exit 1
fi

# Create harness directory
BMAD_HARNESS_DIR=".claude/bmad-harness"
mkdir -p "$BMAD_HARNESS_DIR"

# Read story file to extract context
STORY_TITLE=$(grep -m1 '^# Story' "$STORY_FILE" | sed 's/^# Story [0-9.]*: //' || echo "BMAD Story")
TOTAL_TASKS=$(grep -c '^\s*- \[' "$STORY_FILE" 2>/dev/null || echo "0")
COMPLETED_TASKS=$(grep -c '^\s*- \[x\]' "$STORY_FILE" 2>/dev/null || echo "0")

# Build the dev-story prompt
DEV_STORY_PROMPT="You are the BMAD DEV agent implementing a story.

## Your Mission

Implement the following story completely, following red-green-refactor TDD methodology.

## Story File

Read and implement the story at: $STORY_FILE

## Workflow

1. **Read the story file** - Understand acceptance criteria and tasks
2. **For each task:**
   - Write failing tests first (RED)
   - Implement minimal code to pass (GREEN)
   - Refactor if needed (REFACTOR)
   - Update the task checkbox to [x] when complete
3. **Validate** - Run all tests, ensure they pass
4. **Complete** - Update story Status to 'done' when all acceptance criteria are met

## Critical Rules

- NEVER skip tests - TDD is mandatory
- Update checkboxes in the story file as you complete tasks
- All existing tests must continue to pass
- Follow project coding standards and patterns

## Progress Tracking

Current: $COMPLETED_TASKS / $TOTAL_TASKS tasks completed
Story: $STORY_TITLE

When fully complete, output: <promise>$COMPLETION_PROMISE</promise>

Begin by reading the story file and understanding the requirements."

# Create state file
STATE_FILE="$BMAD_HARNESS_DIR/story-loop.state.md"

cat > "$STATE_FILE" << EOF
---
story_file: "$STORY_FILE"
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: "$COMPLETION_PROMISE"
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$DEV_STORY_PROMPT
EOF

echo ">>> BMAD Harness initialized!"
echo ""
echo "Story: $STORY_TITLE"
echo "File: $STORY_FILE"
echo "Tasks: $COMPLETED_TASKS / $TOTAL_TASKS completed"
echo "Max iterations: $MAX_ITERATIONS"
echo "Completion: <promise>$COMPLETION_PROMISE</promise>"
echo ""
echo "The harness will persist story execution across context windows."
echo "Cancel with: /bmad-cancel or delete $STATE_FILE"
echo ""
echo "Starting dev-story workflow..."
