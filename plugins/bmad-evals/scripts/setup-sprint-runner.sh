#!/bin/bash

# BMAD Sprint Runner - Setup Script
# Initializes the automated sprint execution loop
#
# Usage: setup-sprint-runner.sh [options]
# Options:
#   --epic <id>           Only run stories from this epic
#   --max-stories <n>     Maximum stories to run (default: unlimited)
#   --stop-on-fail        Stop on first story failure
#   --skip-review         Skip code review step
#   --check-only          Run pre-flight checks only, don't start
#   --resume              Resume from existing state

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default options
EPIC_FILTER=""
MAX_STORIES=0
STOP_ON_FAIL=false
SKIP_REVIEW=false
CHECK_ONLY=false
RESUME=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --epic)
      EPIC_FILTER="$2"
      shift 2
      ;;
    --max-stories)
      MAX_STORIES="$2"
      shift 2
      ;;
    --stop-on-fail)
      STOP_ON_FAIL=true
      shift
      ;;
    --skip-review)
      SKIP_REVIEW=true
      shift
      ;;
    --check-only)
      CHECK_ONLY=true
      shift
      ;;
    --resume)
      RESUME=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Paths
SPRINT_DIR=".claude/sprint-runner"
STATE_FILE="$SPRINT_DIR/sprint.state.json"
BMAD_OUTPUT="_bmad-output"
SPRINT_STATUS="$BMAD_OUTPUT/sprint-status.yaml"
BMM_CONFIG="_bmad/bmm/config.yaml"

# Story location detection
# Priority:
#   1. story_location in sprint-status.yaml (authoritative)
#   2. implementation_artifacts from _bmad/bmm/config.yaml + /stories
#   3. Fallback search order
STORY_LOCATION=""

detect_story_location() {
  # 1. Check sprint-status.yaml for story_location key
  if [[ -f "$SPRINT_STATUS" ]]; then
    local loc=$(grep -E "^story_location:" "$SPRINT_STATUS" 2>/dev/null | sed 's/story_location:\s*//' | tr -d '"' | tr -d "'" | xargs)
    if [[ -n "$loc" ]] && [[ -d "$loc" ]]; then
      STORY_LOCATION="$loc"
      return 0
    fi
  fi

  # 2. Check _bmad/bmm/config.yaml for implementation_artifacts path
  if [[ -f "$BMM_CONFIG" ]]; then
    local artifacts=$(grep -E "^implementation_artifacts:" "$BMM_CONFIG" 2>/dev/null | sed 's/implementation_artifacts:\s*//' | tr -d '"' | tr -d "'" | xargs)
    if [[ -n "$artifacts" ]]; then
      local stories_path="${artifacts}/stories"
      if [[ -d "$stories_path" ]]; then
        STORY_LOCATION="$stories_path"
        return 0
      fi
    fi
  fi

  # 3. Fallback search order
  for fallback in "_bmad-output/implementation-artifacts/stories" "_bmad-output/stories" "_bmad-output/epics"; do
    if [[ -d "$fallback" ]]; then
      STORY_LOCATION="$fallback"
      return 0
    fi
  done

  # No location found
  STORY_LOCATION=""
  return 1
}

# Validate story file has proper frontmatter (story_key: or status:)
is_valid_story_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  # Check for story frontmatter markers
  if grep -qE "^(story_key:|status:|Story ID:)" "$file" 2>/dev/null; then
    return 0
  fi
  # Also check for story title pattern
  if grep -qE "^# Story [0-9]" "$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "  BMAD SPRINT RUNNER - Pre-Flight Check"
echo "=========================================="
echo ""

# ============================================
# PRE-FLIGHT CHECKLIST
# ============================================

PREFLIGHT_PASSED=true

# Check 1: sprint-status.yaml exists
echo -n "[ ] sprint-status.yaml exists... "
if [[ -f "$SPRINT_STATUS" ]]; then
  echo -e "${GREEN}✓${NC}"
else
  # Try alternative locations
  if [[ -f "sprint-status.yaml" ]]; then
    SPRINT_STATUS="sprint-status.yaml"
    echo -e "${GREEN}✓${NC} (found at root)"
  elif [[ -f "docs/sprint-status.yaml" ]]; then
    SPRINT_STATUS="docs/sprint-status.yaml"
    echo -e "${GREEN}✓${NC} (found in docs/)"
  else
    echo -e "${RED}✗${NC}"
    echo "    → Create sprint-status.yaml using BMAD's sprint-planning workflow"
    PREFLIGHT_PASSED=false
  fi
fi

# Check 2: Architecture document exists
echo -n "[ ] Architecture document exists... "
ARCH_DOC=""
for path in "$BMAD_OUTPUT/architecture.md" "$BMAD_OUTPUT/docs/architecture.md" "docs/architecture.md" "ARCHITECTURE.md"; do
  if [[ -f "$path" ]]; then
    ARCH_DOC="$path"
    break
  fi
done

if [[ -n "$ARCH_DOC" ]]; then
  echo -e "${GREEN}✓${NC} ($ARCH_DOC)"
else
  echo -e "${YELLOW}⚠${NC} (optional for Quick Flow)"
fi

# Check 3: PRD or tech-spec exists
echo -n "[ ] PRD or tech-spec exists... "
SPEC_DOC=""
for path in "$BMAD_OUTPUT/prd.md" "$BMAD_OUTPUT/tech-spec.md" "docs/prd.md" "docs/tech-spec.md" "PRD.md" "TECH-SPEC.md"; do
  if [[ -f "$path" ]]; then
    SPEC_DOC="$path"
    break
  fi
done

if [[ -n "$SPEC_DOC" ]]; then
  echo -e "${GREEN}✓${NC} ($SPEC_DOC)"
else
  echo -e "${RED}✗${NC}"
  echo "    → Create PRD using BMAD's create-prd workflow"
  PREFLIGHT_PASSED=false
fi

# Check 4: Parse sprint-status.yaml for stories
echo -n "[ ] Parsing stories from sprint-status.yaml... "
if [[ -f "$SPRINT_STATUS" ]]; then
  # Count TODO stories
  TODO_COUNT=$(grep -c "status:.*TODO" "$SPRINT_STATUS" 2>/dev/null || echo "0")
  DONE_COUNT=$(grep -c "status:.*DONE" "$SPRINT_STATUS" 2>/dev/null || echo "0")
  TOTAL_COUNT=$((TODO_COUNT + DONE_COUNT))

  if [[ $TODO_COUNT -gt 0 ]]; then
    echo -e "${GREEN}✓${NC} ($TODO_COUNT TODO, $DONE_COUNT DONE, $TOTAL_COUNT total)"
  else
    echo -e "${RED}✗${NC}"
    echo "    → No stories with TODO status found"
    PREFLIGHT_PASSED=false
  fi
else
  echo -e "${RED}✗${NC}"
  PREFLIGHT_PASSED=false
fi

# Check 5: Story files exist
echo -n "[ ] Story files exist... "
MISSING_STORIES=0
FOUND_STORIES=0
VALID_STORIES=0

# Detect story location using priority order
detect_story_location

if [[ -n "$STORY_LOCATION" ]]; then
  # Find story files in detected location
  while IFS= read -r story_file; do
    if [[ -f "$story_file" ]]; then
      FOUND_STORIES=$((FOUND_STORIES + 1))
      # Validate story has proper frontmatter
      if is_valid_story_file "$story_file"; then
        VALID_STORIES=$((VALID_STORIES + 1))
      fi
    else
      MISSING_STORIES=$((MISSING_STORIES + 1))
    fi
  done < <(find "$STORY_LOCATION" -name "*.md" -type f 2>/dev/null || true)

  # Also search subdirectories (for epic-based organization)
  if [[ $FOUND_STORIES -eq 0 ]]; then
    while IFS= read -r story_file; do
      if [[ -f "$story_file" ]]; then
        FOUND_STORIES=$((FOUND_STORIES + 1))
        if is_valid_story_file "$story_file"; then
          VALID_STORIES=$((VALID_STORIES + 1))
        fi
      fi
    done < <(find "$STORY_LOCATION" -name "story-*.md" -type f 2>/dev/null || true)
  fi
fi

if [[ $VALID_STORIES -gt 0 ]]; then
  if [[ $MISSING_STORIES -gt 0 ]]; then
    echo -e "${YELLOW}⚠${NC} ($VALID_STORIES valid stories in $STORY_LOCATION, $MISSING_STORIES missing)"
  else
    echo -e "${GREEN}✓${NC} ($VALID_STORIES stories in $STORY_LOCATION)"
  fi
elif [[ $FOUND_STORIES -gt 0 ]]; then
  echo -e "${YELLOW}⚠${NC} ($FOUND_STORIES .md files found, but none with story frontmatter)"
  echo "    → Story files should contain 'story_key:', 'status:', or '# Story X.X' header"
else
  echo -e "${RED}✗${NC}"
  echo "    → No story files found"
  echo "    → Searched: sprint-status.yaml (story_location), _bmad/bmm/config.yaml (implementation_artifacts)"
  echo "    → Fallbacks: _bmad-output/implementation-artifacts/stories/, _bmad-output/stories/, _bmad-output/epics/"
  PREFLIGHT_PASSED=false
fi

# Check 6: Git repository initialized
echo -n "[ ] Git repository initialized... "
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${YELLOW}⚠${NC} (recommended for checkpoints)"
fi

# Check 7: No circular dependencies
echo -n "[ ] Checking for circular dependencies... "
# Run dependency parser in check mode
if [[ -x "$SCRIPT_DIR/parse-dependencies.sh" ]]; then
  if "$SCRIPT_DIR/parse-dependencies.sh" --check-circular "$SPRINT_STATUS" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
    echo "    → Circular dependencies detected. Fix in sprint-status.yaml"
    PREFLIGHT_PASSED=false
  fi
else
  echo -e "${YELLOW}⚠${NC} (parser not found, skipping)"
fi

echo ""
echo "=========================================="

# Exit if checks failed or check-only mode
if [[ "$PREFLIGHT_PASSED" == "false" ]]; then
  echo -e "${RED}Pre-flight checks FAILED${NC}"
  echo "Fix the issues above and try again."
  exit 1
fi

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo -e "${GREEN}Pre-flight checks PASSED${NC}"
  echo "Ready to run: /sprint-run"
  exit 0
fi

echo -e "${GREEN}Pre-flight checks PASSED${NC}"
echo ""

# ============================================
# INITIALIZE SPRINT STATE
# ============================================

mkdir -p "$SPRINT_DIR"

# Check for resume
if [[ "$RESUME" == "true" ]] && [[ -f "$STATE_FILE" ]]; then
  echo ">>> Resuming from existing sprint state..."
  CURRENT_STORY=$(jq -r '.current_story // ""' "$STATE_FILE")
  ITERATION=$(jq -r '.iteration // 1' "$STATE_FILE")
  STORIES_COMPLETED=$(jq -r '.stories_completed // 0' "$STATE_FILE")
  echo ">>> Current story: $CURRENT_STORY"
  echo ">>> Stories completed: $STORIES_COMPLETED"
  echo ">>> Iteration: $ITERATION"
else
  # Fresh start - parse dependencies and find first story
  echo ">>> Initializing fresh sprint run..."

  # Build story queue using dependency parser
  STORY_QUEUE=$("$SCRIPT_DIR/parse-dependencies.sh" "$SPRINT_STATUS" "$EPIC_FILTER" 2>/dev/null || echo "[]")
  QUEUE_LENGTH=$(echo "$STORY_QUEUE" | jq 'length')

  if [[ "$QUEUE_LENGTH" == "0" ]]; then
    echo ">>> No ready stories found (all have unmet dependencies or are DONE)"
    exit 0
  fi

  # Get first ready story
  FIRST_STORY=$(echo "$STORY_QUEUE" | jq -r '.[0]')
  FIRST_STORY_ID=$(echo "$FIRST_STORY" | jq -r '.id')
  FIRST_STORY_FILE=$(echo "$FIRST_STORY" | jq -r '.file')

  # Apply max-stories limit
  if [[ $MAX_STORIES -gt 0 ]] && [[ $QUEUE_LENGTH -gt $MAX_STORIES ]]; then
    QUEUE_LENGTH=$MAX_STORIES
    STORY_QUEUE=$(echo "$STORY_QUEUE" | jq ".[:$MAX_STORIES]")
  fi

  # Create state file
  cat > "$STATE_FILE" << EOF
{
  "active": true,
  "sprint_id": "sprint-$(date +%Y%m%d-%H%M%S)",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "iteration": 1,
  "current_story": "$FIRST_STORY_ID",
  "current_story_file": "$FIRST_STORY_FILE",
  "stories_completed": 0,
  "stories_failed": 0,
  "stories_total": $QUEUE_LENGTH,
  "story_queue": $STORY_QUEUE,
  "options": {
    "epic_filter": "$EPIC_FILTER",
    "max_stories": $MAX_STORIES,
    "stop_on_fail": $STOP_ON_FAIL,
    "skip_review": $SKIP_REVIEW
  },
  "config": {
    "sprint_status_file": "$SPRINT_STATUS",
    "story_location": "$STORY_LOCATION",
    "architecture_doc": "$ARCH_DOC",
    "spec_doc": "$SPEC_DOC"
  }
}
EOF

  echo ""
  echo ">>> Sprint initialized!"
  echo ">>> Sprint ID: sprint-$(date +%Y%m%d-%H%M%S)"
  echo ">>> Stories to build: $QUEUE_LENGTH"
  echo ">>> First story: $FIRST_STORY_ID"
  echo ""
fi

# ============================================
# BUILD DEV-STORY PROMPT
# ============================================

# Read current story details from state
CURRENT_STORY_ID=$(jq -r '.current_story' "$STATE_FILE")
CURRENT_STORY_FILE=$(jq -r '.current_story_file' "$STATE_FILE")
STORIES_TOTAL=$(jq -r '.stories_total' "$STATE_FILE")
STORIES_COMPLETED=$(jq -r '.stories_completed' "$STATE_FILE")
ITERATION=$(jq -r '.iteration' "$STATE_FILE")

# Validate story file exists
if [[ ! -f "$CURRENT_STORY_FILE" ]]; then
  echo ">>> ERROR: Story file not found: $CURRENT_STORY_FILE" >&2
  exit 1
fi

# Read architecture and spec paths
ARCH_DOC=$(jq -r '.config.architecture_doc // ""' "$STATE_FILE")
SPEC_DOC=$(jq -r '.config.spec_doc // ""' "$STATE_FILE")

# Build the dev-story prompt
DEV_STORY_PROMPT="You are the BMAD DEV agent executing an automated sprint.

## Sprint Progress

Story: $((STORIES_COMPLETED + 1)) of $STORIES_TOTAL
Current Story: $CURRENT_STORY_ID
Iteration: $ITERATION

## Your Mission

Implement the story completely, following red-green-refactor TDD methodology.

## Story File

Read and implement: $CURRENT_STORY_FILE

## Reference Documents
"

if [[ -n "$ARCH_DOC" ]]; then
  DEV_STORY_PROMPT+="
- Architecture: $ARCH_DOC"
fi

if [[ -n "$SPEC_DOC" ]]; then
  DEV_STORY_PROMPT+="
- Specification: $SPEC_DOC"
fi

DEV_STORY_PROMPT+="

## Workflow

1. **Read the story file** - Understand acceptance criteria and tasks
2. **For each task:**
   - Write failing tests first (RED)
   - Implement minimal code to pass (GREEN)
   - Refactor if needed (REFACTOR)
   - Mark task checkbox [x] when complete
3. **Validate** - Run all tests, ensure they pass
4. **Complete** - When ALL acceptance criteria are met, output:

   <story-complete>$CURRENT_STORY_ID</story-complete>

## Critical Rules

- NEVER skip tests - TDD is mandatory
- Update checkboxes in the story file as you complete tasks
- All existing tests must continue to pass
- Follow project coding standards and patterns
- Reference architecture decisions for technical choices

## Context Persistence

This sprint runner persists across context windows. If context exhausts:
- Your progress is saved via git checkpoint
- The next context will continue where you left off
- Keep working until the story is complete

Begin by reading the story file: $CURRENT_STORY_FILE"

echo ""
echo "=========================================="
echo "  STARTING: $CURRENT_STORY_ID"
echo "  ($((STORIES_COMPLETED + 1)) of $STORIES_TOTAL)"
echo "=========================================="
echo ""

# Output the prompt (this will be captured and used by the agent)
echo "$DEV_STORY_PROMPT"
