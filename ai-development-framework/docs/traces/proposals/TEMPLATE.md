# Improvement proposal — <case>

> One failing eval case → one small, verifiable change. `eval-diagnose` generates
> this stub from the Evidence; a human fills the rest. The eval validates the fix.

## Evidence
- Failing runs: **<n>** across **<n>** commit(s) [RECURRING if ≥2]
- Last failure: `<date> <commit>`
- Trajectory: `docs/evals/runs/<case>.trajectory.md`
- Gate/results: `docs/evals/results.csv` (rows where case=<case>, resolved=no|gate=fail)

## Hypothesis (human)
_Why does the agent flow fail this case? Which step — reason, act, or gate reading?_

## Proposed change (human)
_Target ONE of: a skill, a hook, or a prompt. Smallest change that could fix it._
- [ ] skill: `…`
- [ ] hook: `…`
- [ ] prompt/command: `…`

## Validation
- [ ] `make eval-agent-flow CASE=<case>` → resolved=yes after the change
- [ ] no regression in other cases (`make eval-agent-flow-all`)
