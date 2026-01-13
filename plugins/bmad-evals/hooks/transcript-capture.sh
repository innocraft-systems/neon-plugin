#!/bin/bash

# BMAD-Evals Transcript Capture Hook
# Captures tool use events for eval analysis

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Only capture if eval loop is active
EVAL_STATE_FILE=".claude/bmad-evals/eval-loop.state.json"
if [[ ! -f "$EVAL_STATE_FILE" ]]; then
  exit 0
fi

# Transcript log location
TRANSCRIPT_LOG=".claude/bmad-evals/tool-events.jsonl"
mkdir -p "$(dirname "$TRANSCRIPT_LOG")"

# Extract relevant info from hook input
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_input // {}')
TOOL_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_output // null')

# Create log entry
LOG_ENTRY=$(jq -n \
  --arg tool "$TOOL_NAME" \
  --argjson input "$TOOL_INPUT" \
  --arg output "$TOOL_OUTPUT" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    timestamp: $timestamp,
    tool: $tool,
    input: $input,
    output_preview: ($output | if length > 500 then .[0:500] + "..." else . end)
  }')

# Append to log
echo "$LOG_ENTRY" >> "$TRANSCRIPT_LOG"

exit 0
