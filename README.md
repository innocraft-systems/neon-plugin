# Innocraft Plugins Marketplace

Official Claude Code plugin marketplace from Innocraft Systems.

## Installation

```bash
# Add the marketplace
/plugin marketplace add innocraft-systems/innocraft-plugin

# Install the BMAD-Evals plugin
/plugin install bmad-evals@innocraft-plugins
```

---

## Available Plugins

### BMAD-Evals v2.0

**Run 100+ stories unattended.** Press play, go to sleep, wake up to a built app.

A Claude Code plugin that combines structured TDD story execution with cross-context persistence for fully automated sprint development.

#### Quick Start

```bash
# Install the plugin
/plugin install bmad-evals@innocraft-plugins

# Run all stories in your sprint
/sprint-run

# Run stories from one epic
/sprint-run --epic epic-2-dashboard

# Stop if needed
/sprint-stop
```

#### The Dream

```
You: /sprint-run
You: *goes to sleep*

Agent: Story 1/120 → implement → test → DONE
...
Agent: Story 120/120 → implement → test → DONE

You: *wakes up* → Full app built, all tests passing
```

#### Features

- **Two-Level Persistence**: Story-level (context exhaustion) and sprint-level (story chaining)
- **Dependency-Aware Ordering**: Stories execute in proper dependency order
- **RAG Integration**: Automatic context injection from bmad-rag for each story
- **Zero Permission Interrupts**: Pre-authorizes 50+ common dev tools
- **TDD Enforcement**: Red-green-refactor methodology built-in

#### Commands

| Command | Description |
|---------|-------------|
| `/sprint-run` | Run all stories automatically |
| `/sprint-stop` | Stop sprint runner |
| `/brun` | Run single story with persistence |
| `/bstop` | Stop single story harness |
| `/eval-run` | Run with graders (for benchmarking) |
| `/eval-report` | Generate eval metrics report |

#### Pre-requisites

Before running `/sprint-run`, ensure your BMAD project has:

1. `sprint-status.yaml` - Created by BMAD's sprint-planning workflow
2. Story files in `_bmad-output/epics/*/stories/`
3. Architecture document (for technical decisions)
4. Git initialized (for checkpoints)

---

## Related Projects

- **[bmad-rag](https://github.com/innocraft-systems/bmad-rag)** - RAG system for BMAD context injection
- **[BMAD Method](https://github.com/bmad-method)** - The underlying methodology

## License

MIT License

## Acknowledgments

- **BMAD Method** by BMad Code
- **Ralph Wiggum technique** by Geoffrey Huntley
- **Anthropic's Evals** framework for grading patterns
