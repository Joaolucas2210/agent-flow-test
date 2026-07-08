---
description: Gate check → update graph → open PR.
---

# /ship

Ship: **$ARGUMENTS**

Preconditions (all must hold):
1. `/review` clean (no blockers from any reviewer).
2. Quality gates green: coverage, complexity, mutation, dependency structure.
3. `/graphify .` run so the graph reflects the change.
4. ADR written if an architectural decision was made.

Then: create a branch (never commit to `main` directly), commit, open a PR with a summary
that links the ADR and shows the metrics table. Confirm with the human before pushing.

Uses: `hooks/`, `skills/quality-gates`.
