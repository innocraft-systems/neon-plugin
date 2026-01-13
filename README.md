# BMAD-Evals Plugin v2.0

**Run 100+ stories unattended.** Press play, go to sleep, wake up to a built app.

A Claude Code plugin that "Ralphanizes" the BMAD methodology - combining structured TDD story execution with Ralph-wiggum cross-context persistence for fully automated sprint development.

## The Dream

```
You: /sprint-run
You: *goes to sleep*

Agent: Story 1/120 → implement → test → DONE
Agent: Story 2/120 → implement → test → DONE
...
Agent: Story 120/120 → implement → test → DONE

You: *wakes up* → Full app built, all tests passing
```

## Quick Start

### Run Entire Sprint Unattended

```bash
# Run all stories in your sprint
/sprint-run

# Run stories from one epic
/sprint-run --epic epic-2-dashboard

# Limit for testing
/sprint-run --max-stories 5

# Stop if needed
/sprint-stop

# Resume where you left off
/sprint-run --resume
```

### Pre-requisites

Before running `/sprint-run`, ensure your BMAD project has:

1. `sprint-status.yaml` - Created by BMAD's sprint-planning workflow
2. Story files in `_bmad-output/epics/*/stories/`
3. Architecture document (for technical decisions)
4. Git initialized (for checkpoints)

## How It Works

```
/sprint-run
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│  PRE-FLIGHT CHECKS                                          │
│  ✓ sprint-status.yaml exists                                │
│  ✓ Architecture doc exists                                  │
│  ✓ Stories have TODO status                                 │
│  ✓ No circular dependencies                                 │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│  SPRINT LOOP (repeats until all done)                       │
│                                                             │
│  1. Find next READY story (TODO + deps met)                 │
│  2. Execute dev-story with TDD                              │
│     ├── If context exhausts → checkpoint, continue          │
│     └── If story complete → mark DONE                       │
│  3. Git commit checkpoint                                   │
│  4. Update sprint-status.yaml                               │
│  5. Load next story → repeat                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
   All stories DONE → Generate report → Exit
```

### Two-Level Persistence

**Story Level:** If context exhausts mid-story, the hook re-feeds the same story prompt with progress context.

**Sprint Level:** When a story completes, the hook automatically loads the next ready story.

### Dependency-Aware Ordering

Stories are executed in dependency order:
- Story 2-1 depends on Story 1-3? → 1-3 runs first
- Cross-epic dependencies respected
- Circular dependencies detected and blocked

### Zero Permission Interrupts

The `/sprint-run` command pre-authorizes 50+ common dev tools:
- File operations: mkdir, rm, cp, mv, etc.
- Package managers: npm, pnpm, yarn, bun
- Build tools: tsc, vite, webpack
- Test runners: jest, vitest, pytest, mocha
- Git operations
- And more...

## Commands

| Command | Description |
|---------|-------------|
| `/sprint-run` | **NEW** Run all stories automatically |
| `/sprint-stop` | **NEW** Stop sprint runner |
| `/brun` | Run single story with persistence |
| `/bstop` | Stop single story harness |
| `/eval-run` | Run with graders (for benchmarking) |
| `/eval-report` | Generate eval metrics report |

## File Structure

```
.claude/
├── sprint-runner/              # Sprint state (NEW)
│   ├── sprint.state.json       # Current sprint progress
│   └── sprint-report.md        # Completion report
├── bmad-harness/               # Single story state
│   └── story-loop.state.md
└── bmad-evals/                 # Eval infrastructure
    ├── eval-loop.state.json
    └── results/

_bmad-output/
├── sprint-status.yaml          # Master story tracker
├── architecture.md
├── prd.md
└── epics/
    ├── epic-1-auth/
    │   └── stories/
    │       ├── story-1-1.md
    │       └── story-1-2.md
    └── epic-2-dashboard/
        └── stories/
            └── story-2-1.md
```

## When To Use What

| Scenario | Command | Why |
|----------|---------|-----|
| Build entire sprint unattended | `/sprint-run` | Chains all stories automatically |
| Build one complex story | `/brun story.md` | Single story persistence |
| Benchmark agent performance | `/eval-run` | Grading and metrics |
| Test sprint setup | `/sprint-run --max-stories 3` | Verify before full run |

## Troubleshooting

### Sprint Won't Start

```bash
# Check pre-flight manually
${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint-runner.sh --check-only
```

Common issues:
- Missing `sprint-status.yaml`
- No stories with TODO status
- Story files not found

### Sprint Stuck on Story

The story might have unclear acceptance criteria. Check:
- Story file has `- [ ]` task checkboxes
- Acceptance criteria are testable
- Dependencies are marked DONE

Force skip to next story:
```bash
# Mark current story done manually in sprint-status.yaml
# Then resume
/sprint-run --resume
```

### Want to Stop Mid-Sprint

```bash
/sprint-stop
# or
rm .claude/sprint-runner/sprint.state.json
```

Progress is preserved - resume anytime with `/sprint-run --resume`.

## Architecture

### Hooks

The plugin uses Claude Code's hook system:

1. **Stop Hook** - Intercepts exit to check completion
2. **PostToolUse Hook** - Captures tool events for debugging

### State Files

- `sprint.state.json` - Current story, queue, progress
- `sprint-status.yaml` - BMAD's master tracker (modified on completion)

### Completion Signals

Stories signal completion with:
```
<story-complete>story-1-1</story-complete>
```

Sprint signals completion with:
```
<sprint-complete>sprint-20240115</sprint-complete>
```

## Best Practices

### Before Running

1. Run BMAD's `implementation-readiness` workflow
2. Ensure all story dependencies are documented
3. Initialize git for checkpoints
4. Start with `--max-stories 5` to test

### Story Design

- Clear, testable acceptance criteria
- Task checkboxes for progress tracking
- Explicit dependencies in sprint-status.yaml

### Monitoring

- Watch git commits for progress
- Check `sprint-status.yaml` for DONE count
- Review `sprint.state.json` for current story

## License

MIT License

## Acknowledgments

- **BMAD Method** by BMad Code
- **Ralph Wiggum technique** by Geoffrey Huntley
- **Anthropic's Evals** framework for grading patterns
