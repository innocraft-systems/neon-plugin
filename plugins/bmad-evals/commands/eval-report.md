---
description: "Generate comprehensive eval report with metrics"
argument-hint: "[--format md|json] [--output PATH]"
allowed-tools: ["Read", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/generate-report.sh:*)"]
---

# Generate Eval Report

Generate a comprehensive report of eval results including pass@k and pass^k metrics.

## Your Task

1. Run the report generation script
2. Read and present the generated report
3. Provide analysis and recommendations

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/generate-report.sh"
```

## Report Contents

The report includes:

### Summary Metrics
- Total iterations run
- Pass/fail counts
- Overall pass rate
- pass@1: Probability of success on first attempt
- pass^k: Probability of k consecutive successes

### Iteration Details
- Timestamp of each iteration
- Which graders passed/failed
- Failure messages for debugging

### Analysis
- Performance assessment
- Recommendations for improvement
- Comparison with baseline (if available)

## Interpreting Metrics

| Metric | Meaning |
|--------|---------|
| pass@1 = 100% | Perfect first-attempt success |
| pass@1 > 80% | Highly reliable task |
| pass@1 50-80% | Achievable but needs refinement |
| pass@1 < 50% | Task needs clearer criteria |
| pass^k high | Consistent, predictable behavior |
| pass^k low | High variance between attempts |

## After Reading Report

Summarize:
1. Overall success of the eval run
2. Key failure patterns if any
3. Recommendations for improving pass rate
4. Whether the task/graders need adjustment
