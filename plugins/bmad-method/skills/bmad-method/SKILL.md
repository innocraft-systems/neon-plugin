---
name: bmad-method
description: |
  This skill provides guidance on the BMAD Method (Breakthrough Method of Agile AI-Driven Development).
  Use when the user asks about "BMAD", "BMAD method", "BMAD workflow", "AI-driven development methodology",
  "how to use BMAD", "BMAD best practices", or needs help with BMAD artifacts like PRD, architecture docs,
  epics, stories, or sprint tracking.
version: 1.0.0
---

# BMAD Method Knowledge

The BMAD Method is a structured approach to AI-assisted software development that emphasizes progressive artifact creation, incremental progress, and context continuity.

## Core Concepts

### Progressive Artifact Creation

BMAD follows a deliberate sequence where each artifact builds on the previous:

1. **PRD (Product Requirements Document)** - Defines WHAT to build
   - Problem statement and goals
   - User personas and use cases
   - Feature requirements and priorities
   - Success metrics

2. **Architecture Document** - Defines HOW to build it
   - Technology stack decisions
   - System design and patterns
   - Data models and APIs
   - Integration points

3. **Epics and Stories** - Breaks work into implementable units
   - Epics group related features
   - Stories are atomic, implementable tasks
   - Each story has clear acceptance criteria

4. **Sprint Status** - Tracks progress
   - Current sprint scope
   - Active story tracking
   - Velocity and completion metrics

### Incremental Progress Principle

Work on ONE story at a time. Each session should:
- Start with orientation (check status, git history)
- Focus on a single story
- End with code in a committable state
- Update tracking artifacts

### Context Continuity

BMAD is designed for AI assistants with limited context windows:
- Artifacts serve as persistent memory
- Sprint status tracks current focus
- Git commit messages include context notes
- Recovery protocols restore session state

## BMAD Workflows

### Project Initialization
```
/bmad-init [--with-git]
```
Creates the BMAD directory structure and CLAUDE.md configuration.

### Requirements Phase
1. Discuss project goals with stakeholder
2. Create PRD.md in `_bmad-output/`
3. Review and iterate on requirements

### Architecture Phase
1. Review PRD.md
2. Make technology decisions
3. Create architecture.md in `_bmad-output/`
4. Document key patterns and constraints

### Planning Phase
1. Break PRD into epics
2. Create story files in `_bmad-output/epics/`
3. Initialize sprint-status.yaml
4. Prioritize and assign to sprints

### Development Phase
1. Select next story from sprint
2. Update sprint-status.yaml (mark in-progress)
3. Implement following architecture guidelines
4. Write tests, commit with context
5. Update sprint-status.yaml (mark complete)

### Review Phase
1. Review implemented code
2. Check against acceptance criteria
3. Ensure tests pass
4. Update documentation if needed

## Directory Structure

```
project/
├── CLAUDE.md                    # AI assistant configuration
└── _bmad-output/
    ├── PRD.md                   # Product requirements
    ├── architecture.md          # Technical architecture
    ├── sprint-status.yaml       # Progress tracking
    └── epics/
        ├── epic-1/
        │   ├── story-1.md
        │   └── story-2.md
        └── epic-2/
            └── story-1.md
```

## Sprint Status Format

```yaml
sprint:
  number: 1
  start_date: 2024-01-15
  end_date: 2024-01-29

active_story: epic-1/story-2

stories:
  - id: epic-1/story-1
    status: completed
    completed_date: 2024-01-16
  - id: epic-1/story-2
    status: in_progress
    started_date: 2024-01-17
  - id: epic-1/story-3
    status: pending

notes: |
  Working on authentication flow.
  Blocked on API key decision - see architecture.md
```

## Best Practices

### Commit Messages
Use the format:
```
type(scope): description

- Detail 1
- Detail 2

BMAD-CONTEXT: Brief note about what to work on next
```

### Story Files
Include:
- Clear title and description
- Acceptance criteria (checkboxes)
- Technical notes from architecture
- Dependencies on other stories

### Session Discipline
- Always check status before starting work
- Focus on one story per session
- Commit frequently with good messages
- Update status before ending session

## Recovery After Compaction

When context is limited:
1. Read sprint-status.yaml
2. Read active story file
3. Check git log for recent work
4. Review architecture.md for decisions
5. Continue from last known state
