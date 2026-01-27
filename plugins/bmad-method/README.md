# BMAD Method Plugin

**Breakthrough Method of Agile AI-Driven Development**

A complete toolkit for structured AI-assisted development workflows in Claude Code.

## Features

- **Project Initialization**: `/bmad-init` command sets up BMAD project structure
- **Session Recovery**: Auto-orients Claude on session start/resume in BMAD projects
- **Methodology Guidance**: Built-in knowledge of BMAD workflows and best practices

## Installation

```bash
claude plugins add bmad-method
```

Or add to your project's `.claude/plugins.json`:

```json
{
  "plugins": ["bmad-method"]
}
```

## Usage

### Initialize a New Project

```bash
/bmad-init              # Creates BMAD structure
/bmad-init --with-git   # Creates structure and stages for git
```

This creates:
- `CLAUDE.md` - Project configuration for Claude
- `_bmad-output/` - Directory for BMAD artifacts
- `_bmad-output/epics/` - Directory for epic/story files

### Session Recovery

When working in a BMAD project, Claude automatically:
1. Checks `_bmad-output/sprint-status.yaml` for current state
2. Reviews recent git history
3. Orients itself to continue work seamlessly

## BMAD Workflow Overview

| Phase | Artifact | Purpose |
|-------|----------|---------|
| 1. Requirements | PRD.md | Define WHAT to build |
| 2. Architecture | architecture.md | Define HOW to build it |
| 3. Planning | epics/*.md | Break work into stories |
| 4. Tracking | sprint-status.yaml | Track progress |
| 5. Development | Code + commits | Implement stories |

## Directory Structure

After initialization, your project will have:

```
your-project/
├── CLAUDE.md                    # Claude configuration
└── _bmad-output/
    ├── PRD.md                   # (created during workflow)
    ├── architecture.md          # (created during workflow)
    ├── sprint-status.yaml       # (created during workflow)
    └── epics/
        └── epic-1/              # (created during workflow)
            └── story-1.md
```

## License

MIT
