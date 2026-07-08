# Quality thresholds (tune per repo)

The numbers the gates enforce. Change them here; hooks and `skills/quality-gates` read from here.

| Gate | Metric | Default | Rationale |
|---|---|---|---|
| Coverage | changed-line % | ≥ 80% | necessary floor, not the real gate |
| Mutation | killed / total | ≥ 70% | the real gate — tests must catch breakage |
| Complexity | cyclomatic / fn | ≤ 10 | one-thing functions |
| Size | fn length | ≤ 50 lines | readability |
| Args | params / fn | ≤ 3 | low coupling |
| Dependency | import cycles | 0 | acyclic architecture |

## Notes
- Mutation > coverage. A 95%-covered file with surviving mutants still fails.
- Raise thresholds gradually via `skills/measurement-driven-improvement`; never lower to pass.
- Security gates are pass/fail and **not** tunable down (see `skills/security-review`).
