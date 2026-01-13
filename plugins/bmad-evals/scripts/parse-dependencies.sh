#!/bin/bash

# BMAD Sprint Runner - Dependency Parser
# Parses sprint-status.yaml, builds dependency graph, returns ready stories
#
# Usage:
#   parse-dependencies.sh <sprint-status.yaml> [epic-filter]
#   parse-dependencies.sh --check-circular <sprint-status.yaml>
#
# Output: JSON array of ready stories in execution order

set -euo pipefail

# Check for circular dependencies mode
if [[ "${1:-}" == "--check-circular" ]]; then
  SPRINT_STATUS="${2:-}"
  CHECK_ONLY=true
else
  SPRINT_STATUS="${1:-}"
  EPIC_FILTER="${2:-}"
  CHECK_ONLY=false
fi

if [[ -z "$SPRINT_STATUS" ]] || [[ ! -f "$SPRINT_STATUS" ]]; then
  echo "[]"
  exit 0
fi

# ============================================
# PARSE SPRINT STATUS YAML
# ============================================

# We'll parse the YAML into a format we can work with
# Expected structure:
# epics:
#   - id: epic-1
#     stories:
#       - id: story-1-1
#         status: TODO
#         file: path/to/story.md
#         dependencies: [story-1-0]  # optional

# Use a simple state machine parser since yq might not be available
parse_stories() {
  local file="$1"
  local filter="$2"

  local current_epic=""
  local current_story=""
  local in_story=false
  local in_dependencies=false

  # Output format: id|epic|status|file|deps
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Remove leading/trailing whitespace for comparison
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Detect epic
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*id:[[:space:]]*([^[:space:]]+) ]] && [[ "$line" =~ epic ]]; then
      current_epic="${BASH_REMATCH[1]}"
      continue
    fi

    # Alternative epic detection
    if [[ "$trimmed" =~ ^id:[[:space:]]*\"?(epic-[^\"[:space:]]+)\"? ]]; then
      current_epic="${BASH_REMATCH[1]}"
      continue
    fi

    # Detect story start
    if [[ "$trimmed" =~ ^-[[:space:]]*id:[[:space:]]*\"?(story-[^\"[:space:]]+)\"? ]]; then
      # Output previous story if exists
      if [[ -n "$current_story" ]]; then
        echo "${story_id}|${story_epic}|${story_status}|${story_file}|${story_deps}"
      fi

      current_story="${BASH_REMATCH[1]}"
      story_id="$current_story"
      story_epic="$current_epic"
      story_status="TODO"
      story_file=""
      story_deps=""
      in_story=true
      in_dependencies=false
      continue
    fi

    # Detect story id on separate line
    if [[ "$in_story" == "false" ]] && [[ "$trimmed" =~ ^id:[[:space:]]*\"?(story-[^\"[:space:]]+)\"? ]]; then
      current_story="${BASH_REMATCH[1]}"
      story_id="$current_story"
      story_epic="$current_epic"
      story_status="TODO"
      story_file=""
      story_deps=""
      in_story=true
      in_dependencies=false
      continue
    fi

    if [[ "$in_story" == "true" ]]; then
      # Detect status
      if [[ "$trimmed" =~ ^status:[[:space:]]*\"?([^\"[:space:]]+)\"? ]]; then
        story_status="${BASH_REMATCH[1]}"
        continue
      fi

      # Detect file path
      if [[ "$trimmed" =~ ^file:[[:space:]]*\"?([^\"]+)\"? ]]; then
        story_file="${BASH_REMATCH[1]}"
        continue
      fi

      # Alternative: path field
      if [[ "$trimmed" =~ ^path:[[:space:]]*\"?([^\"]+)\"? ]]; then
        story_file="${BASH_REMATCH[1]}"
        continue
      fi

      # Detect dependencies start
      if [[ "$trimmed" =~ ^dependencies:[[:space:]]*$ ]] || [[ "$trimmed" =~ ^depends_on:[[:space:]]*$ ]]; then
        in_dependencies=true
        continue
      fi

      # Inline dependencies array
      if [[ "$trimmed" =~ ^dependencies:[[:space:]]*\[([^\]]*)\] ]] || [[ "$trimmed" =~ ^depends_on:[[:space:]]*\[([^\]]*)\] ]]; then
        deps="${BASH_REMATCH[1]}"
        # Clean up: remove quotes, spaces
        story_deps=$(echo "$deps" | tr -d '"' | tr -d "'" | tr ',' ' ' | tr -s ' ')
        in_dependencies=false
        continue
      fi

      # Collect dependency items
      if [[ "$in_dependencies" == "true" ]]; then
        if [[ "$trimmed" =~ ^-[[:space:]]*\"?([^\"[:space:]]+)\"? ]]; then
          dep="${BASH_REMATCH[1]}"
          if [[ -n "$story_deps" ]]; then
            story_deps="$story_deps $dep"
          else
            story_deps="$dep"
          fi
          continue
        elif [[ ! "$trimmed" =~ ^- ]] && [[ -n "$trimmed" ]] && [[ ! "$trimmed" =~ ^# ]]; then
          # End of dependencies list
          in_dependencies=false
        fi
      fi

      # End of story (next story or epic starts, or unindented line)
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(id:|name:) ]] && [[ ! "$line" =~ story- ]]; then
        # Output current story
        echo "${story_id}|${story_epic}|${story_status}|${story_file}|${story_deps}"
        in_story=false
        current_story=""
      fi
    fi

  done < "$file"

  # Output last story
  if [[ -n "$current_story" ]]; then
    echo "${story_id}|${story_epic}|${story_status}|${story_file}|${story_deps}"
  fi
}

# ============================================
# BUILD DEPENDENCY GRAPH AND FIND READY STORIES
# ============================================

# Parse stories into array
declare -A STORY_STATUS
declare -A STORY_FILE
declare -A STORY_EPIC
declare -A STORY_DEPS
ALL_STORIES=()

while IFS='|' read -r id epic status file deps; do
  if [[ -n "$id" ]]; then
    # Apply epic filter if specified
    if [[ -n "${EPIC_FILTER:-}" ]] && [[ "$epic" != "$EPIC_FILTER" ]]; then
      continue
    fi

    ALL_STORIES+=("$id")
    STORY_STATUS["$id"]="$status"
    STORY_EPIC["$id"]="$epic"
    STORY_FILE["$id"]="$file"
    STORY_DEPS["$id"]="$deps"
  fi
done < <(parse_stories "$SPRINT_STATUS" "${EPIC_FILTER:-}")

# ============================================
# CHECK FOR CIRCULAR DEPENDENCIES
# ============================================

check_circular() {
  local story="$1"
  local path="$2"

  # Check if story is in current path (cycle)
  if [[ " $path " =~ " $story " ]]; then
    return 1  # Circular dependency found
  fi

  # Check dependencies
  local deps="${STORY_DEPS[$story]:-}"
  for dep in $deps; do
    if [[ -n "${STORY_STATUS[$dep]:-}" ]]; then
      if ! check_circular "$dep" "$path $story"; then
        return 1
      fi
    fi
  done

  return 0
}

if [[ "$CHECK_ONLY" == "true" ]]; then
  for story in "${ALL_STORIES[@]}"; do
    if ! check_circular "$story" ""; then
      echo "Circular dependency detected involving: $story" >&2
      exit 1
    fi
  done
  exit 0
fi

# ============================================
# FIND READY STORIES (TOPOLOGICAL SORT)
# ============================================

# A story is ready if:
# 1. Status is TODO (not DONE, not IN_PROGRESS)
# 2. All dependencies have status DONE

is_ready() {
  local story="$1"
  local status="${STORY_STATUS[$story]:-}"

  # Must be TODO
  if [[ "$status" != "TODO" ]]; then
    return 1
  fi

  # Check all dependencies are DONE
  local deps="${STORY_DEPS[$story]:-}"
  for dep in $deps; do
    local dep_status="${STORY_STATUS[$dep]:-DONE}"
    if [[ "$dep_status" != "DONE" ]]; then
      return 1
    fi
  done

  return 0
}

# Build ordered list of ready stories
READY_STORIES=()

# First pass: stories with no dependencies
for story in "${ALL_STORIES[@]}"; do
  if is_ready "$story"; then
    deps="${STORY_DEPS[$story]:-}"
    if [[ -z "$deps" ]]; then
      READY_STORIES+=("$story")
    fi
  fi
done

# Second pass: stories with satisfied dependencies
for story in "${ALL_STORIES[@]}"; do
  if is_ready "$story"; then
    deps="${STORY_DEPS[$story]:-}"
    if [[ -n "$deps" ]]; then
      # Check if not already added
      if [[ ! " ${READY_STORIES[*]} " =~ " $story " ]]; then
        READY_STORIES+=("$story")
      fi
    fi
  fi
done

# ============================================
# OUTPUT JSON
# ============================================

# Build JSON array
echo -n "["
first=true
for story in "${READY_STORIES[@]}"; do
  if [[ "$first" == "true" ]]; then
    first=false
  else
    echo -n ","
  fi

  file="${STORY_FILE[$story]:-}"
  epic="${STORY_EPIC[$story]:-}"

  # If file path is empty, try to find it
  if [[ -z "$file" ]]; then
    # Try common patterns
    for pattern in "_bmad-output/epics/$epic/stories/$story.md" "_bmad-output/epics/*/stories/$story.md" "docs/stories/$story.md"; do
      found=$(find . -path "./$pattern" 2>/dev/null | head -1 || true)
      if [[ -n "$found" ]]; then
        file="$found"
        break
      fi
    done

    # Fallback: search for story file
    if [[ -z "$file" ]]; then
      found=$(find . -name "$story.md" -type f 2>/dev/null | head -1 || true)
      if [[ -n "$found" ]]; then
        file="$found"
      fi
    fi
  fi

  # Escape for JSON
  file_escaped=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
  deps="${STORY_DEPS[$story]:-}"
  deps_json=$(echo "$deps" | tr ' ' '\n' | grep -v '^$' | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')

  cat << EOF
{
    "id": "$story",
    "epic": "$epic",
    "file": "$file_escaped",
    "dependencies": [$deps_json]
  }
EOF
done
echo "]"
