---
description: Initialize BMAD project structure
argument-hint: "[--with-git]"
allowed-tools: ["Read", "Write", "Bash(mkdir:*)", "Bash(git:*)"]
---

# Initialize BMAD Project

Set up this project for BMAD Method development.

## Steps to Execute

1. **Create directory structure:**
   - Create `_bmad-output/` directory
   - Create `_bmad-output/epics/` subdirectory

2. **Copy CLAUDE.md template:**
   - Read template from `$CLAUDE_PLUGIN_ROOT/templates/CLAUDE.md`
   - Write to `./CLAUDE.md` in current project

3. **Create .gitkeep files:**
   - Add `.gitkeep` to `_bmad-output/epics/` to preserve empty directory

4. **If `--with-git` argument provided:**
   - Run `git add CLAUDE.md _bmad-output/`
   - Show git status

5. **Confirm completion** with summary of created files and next steps:
   - List created files
   - Suggest next workflow step (usually creating a PRD)

## Template Location

The CLAUDE.md template is located at: `$CLAUDE_PLUGIN_ROOT/templates/CLAUDE.md`
