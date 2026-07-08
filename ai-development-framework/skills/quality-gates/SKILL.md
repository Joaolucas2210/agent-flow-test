---
name: quality-gates
description: The objective merge gate — coverage, cyclomatic complexity, mutation score, dependency structure. Metrics block the ship, not opinions. Use for /test and /ship.
---

# Quality Gates

Uncle Bob's discipline made mechanical: **the number is the gate.**

## The gates (tune thresholds per repo in `rules/quality-thresholds.md`)

| Gate | Metric | Default threshold | Tool (example) |
|---|---|---|---|
| Coverage | changed-line % | ≥ 80% | pytest-cov / c8 / jacoco |
| Complexity | cyclomatic / fn | ≤ 10 | radon / lizard / eslint-complexity |
| Mutation | killed / total | ≥ 70% | mutmut / stryker / pitest |
| Dependency | cycles, fan-in/out | 0 cycles | pydeps / madge / dependency-cruiser |
| Size | fn length | ≤ 50 lines | lizard |

## Steps
1. Run each gate via RTK (`rtk <tool>`), capture the number, not the wall of output.
2. Compare to threshold. Any miss = **block**.
3. Mutation survivors → strengthen tests (don't pad line coverage).
4. Dependency cycles → route to `staff-architect` (boundary problem).
5. Update the graph so metrics reflect the shipped state.

## Example
```
rtk pytest --cov       # coverage: 84% ✅
rtk lizard src/        # max CCN 7 ✅  fn length 41 ✅
rtk mutmut run         # killed 73% ✅
rtk pydeps --show-cycles   # 0 cycles ✅  → SHIP
```

## Quality gates (meta)
- [ ] Every gate has a number, checked against threshold
- [ ] No line-by-line review substituted for a failing metric
- [ ] Survivors/cycles escalated, not ignored

## Integration
RTK (compressed metric output) · Graphify (dependency structure) · uncle-bob-discipline ·
measurement-driven-improvement (trend the numbers).
