---
name: measurement-driven-improvement
description: Trend quality metrics over time and target the worst offenders. Improvement is measured, not asserted. Use periodically and before refactors.
---

# Measurement-Driven Improvement

You can't improve what you don't measure. Track the gate metrics as time series; refactor
where the number is worst, prove the delta.

## Steps
1. **Snapshot** metrics each ship (coverage, CCN, mutation, cycles, token cost). Append to
   `docs/metrics/history.csv` (RTK-compressed capture).
2. **Rank hotspots** — highest complexity × churn (from graph history) = refactor first.
3. **Target one.** Refactor the single worst offender; re-measure; keep the delta or revert.
4. **Token metrics too.** Track `rtk gain` and graph-hit rate — context efficiency is a metric.

## Example
```
/graphify query "top 10 files by complexity*churn"
→ billing/engine.py CCN 24, churn high → refactor target
after: CCN 9, mutation 78%  ✅ keep
```

## Quality gates
- [ ] Metrics snapshotted per ship
- [ ] Hotspot chosen by data (complexity × churn), not vibes
- [ ] Delta proven before/after
- [ ] Token efficiency trended (rtk gain, graph-hit rate)

## Integration
quality-gates · Graphify (churn/complexity) · RTK (gain) · uncle-bob-discipline.
