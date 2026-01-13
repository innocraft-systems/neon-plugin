---
name: eval-methodology
description: "Knowledge and best practices for writing effective agent evals"
triggers: ["how to write evals", "eval best practices", "grader design", "eval task", "evaluation criteria"]
---

# Agent Evaluation Methodology

This skill provides knowledge about designing, implementing, and maintaining effective evaluations for AI agents, based on Anthropic's "Demystifying Evals for AI Agents" and BMAD methodology.

## Core Concepts

### What is an Eval?
An evaluation is a test for an AI system: give an AI an input, apply grading logic to its output to measure success.

### Key Components

| Component | Description |
|-----------|-------------|
| **Task** | Single test with defined inputs and success criteria |
| **Trial** | One attempt at a task (run multiple for consistency) |
| **Grader** | Logic that scores agent performance |
| **Transcript** | Complete record of a trial (messages, tool calls, reasoning) |
| **Outcome** | Final state in environment after trial |

## Grader Types

### 1. Code-Based Graders (Deterministic)

**Strengths**: Fast, cheap, objective, reproducible
**Weaknesses**: Brittle to valid variations, limited nuance

```yaml
graders:
  - type: deterministic_tests
    command: npm test
  - type: static_analysis
    commands: [eslint, tsc --noEmit]
  - type: string_match
    pattern: "function validatePassword"
```

### 2. Model-Based Graders (LLM)

**Strengths**: Flexible, captures nuance, handles open-ended tasks
**Weaknesses**: Non-deterministic, more expensive, needs calibration

```yaml
graders:
  - type: llm_rubric
    rubric: |
      Evaluate the code for:
      - Clarity and readability (0-25)
      - Error handling (0-25)
      - Test coverage (0-25)
      - Security practices (0-25)
```

### 3. Human Graders

**Strengths**: Gold standard quality, matches expert judgment
**Weaknesses**: Expensive, slow, requires expert access

Use for:
- Calibrating model-based graders
- Complex subjective assessments
- Spot-check validation

## Task Design Best Practices

### 1. Unambiguous Success Criteria

**Bad**: "Make the code better"
**Good**: "Refactor the auth module to: (1) extract password validation to separate function, (2) add input sanitization, (3) maintain 100% test pass rate"

### 2. Reference Solutions

Create a known-working output that passes all graders. This:
- Proves the task is solvable
- Verifies graders are correctly configured
- Provides calibration baseline

### 3. Balanced Problem Sets

Test both positive and negative cases:
- When behavior SHOULD occur
- When behavior SHOULD NOT occur

### 4. Incremental Goals

**Bad**: "Build a complete e-commerce platform"
**Good**:
```
Phase 1: User authentication (tests required)
Phase 2: Product catalog (tests required)
Phase 3: Shopping cart (tests required)
```

## Metrics

### pass@k
Probability of at least ONE success in k attempts.
- Higher k = higher pass@k
- Useful when one success is enough

### pass^k
Probability of ALL k attempts succeeding.
- Higher k = lower pass^k
- Measures consistency and reliability

### When to Use Each

| Scenario | Prefer |
|----------|--------|
| Finding any working solution | pass@k |
| User-facing reliability | pass^k |
| Regression testing | pass^k (should be ~100%) |
| Capability testing | pass@k (expected to start low) |

## Eval Types

### Capability Evals
"What can this agent do well?"
- Start at low pass rate
- Target tasks agent struggles with
- Give teams a hill to climb

### Regression Evals
"Does the agent still handle tasks it used to?"
- Should have ~100% pass rate
- Protect against backsliding
- Decline signals something broke

## Common Anti-Patterns

### 1. Overly Specific Path Checking
**Bad**: Requiring exact sequence of tool calls
**Good**: Grading the outcome, not the path

### 2. One-Sided Evals
**Bad**: Only testing when search should occur
**Good**: Testing both search and no-search cases

### 3. Ignoring Non-Determinism
**Bad**: Running one trial and drawing conclusions
**Good**: Running multiple trials, using pass@k/pass^k

### 4. Brittle Graders
**Bad**: Exact string match "96.12"
**Good**: Approximate match within tolerance

## Integration with BMAD

BMAD's structured approach maps well to evals:

| BMAD Element | Eval Element |
|--------------|--------------|
| Story | Eval Task |
| Acceptance Criteria | Grader Assertions |
| Task/Subtask | Grader Checkpoints |
| Test Requirements | Deterministic Graders |
| Definition of Done | Completion Promise |

## Workflow

1. **Define Success** - What does "done" look like?
2. **Design Tasks** - Clear, unambiguous specifications
3. **Configure Graders** - Match grader type to verification needs
4. **Set Limits** - max_iterations, completion promises
5. **Run Eval** - Execute with iteration loop
6. **Analyze Results** - Interpret metrics, identify patterns
7. **Iterate** - Refine tasks, graders, or agent

## References

- Anthropic: "Demystifying Evals for AI Agents"
- BMAD Method: Test Architecture Module
- Ralph Wiggum: Iterative Development Loops
