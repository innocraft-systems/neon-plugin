# BMAD Method Project Configuration

This project uses the **BMAD Method** (Breakthrough Method of Agile AI Driven Development). Follow these critical instructions at all times.

## Core BMAD Principles

1. **Fresh Context Per Workflow**: Each BMAD workflow should ideally run in a fresh context. If continuing after compaction, re-orient yourself first.

2. **Progressive Artifact Creation**: Documents build on each other:
   - PRD.md → defines WHAT to build
   - architecture.md → defines HOW to build it
   - epics/ → breaks work into implementable stories
   - sprint-status.yaml → tracks progress

3. **Incremental Progress**: Work on ONE story at a time. Leave the codebase in a clean, committable state.

## On Session Start / Resume / Post-Compaction

**ALWAYS** perform these steps when starting fresh or after compaction:

1. Check `_bmad-output/sprint-status.yaml` for current sprint state
2. Check `_bmad-output/epics/` for active stories
3. Review recent git commits: `git log --oneline -10`
4. If unclear, ask for guidance on what to work on next

## BMAD Workflow Quick Reference

These workflows can be performed manually or with custom commands:

| Workflow | Role | Purpose |
|----------|------|---------|
| Create PRD | PM | Create Product Requirements Document in `_bmad-output/PRD.md` |
| Create Architecture | Architect | Create architecture document in `_bmad-output/architecture.md` |
| Create Epics/Stories | PM | Break PRD into epics in `_bmad-output/epics/` |
| Sprint Planning | SM | Initialize `_bmad-output/sprint-status.yaml` |
| Develop Story | DEV | Implement a story following architecture |
| Code Review | DEV | Review implemented code against acceptance criteria |

## Progress Tracking

After completing any significant work:
1. Commit with descriptive message
2. Update `sprint-status.yaml` if working on stories
3. Leave notes for future context in commit messages

## Compaction Recovery Instructions

If you detect that compaction has occurred (context feels limited):
1. READ `_bmad-output/sprint-status.yaml`
2. READ the current story file if one is active
3. READ `_bmad-output/architecture.md` for technical decisions
4. CHECK `git log --oneline -10` for recent work
5. CONTINUE from where the last agent left off

## Import Project Context

@_bmad-output/PRD.md
@_bmad-output/architecture.md
@_bmad-output/sprint-status.yaml
