# Observability

`hooks/observability.sh` records one JSONL event for every archetype hand-off and creates a
task trajectory when that task ends. It deliberately runs locally: no provider SDK, service,
secret, PII, or guessed price is introduced.

## Record a hand-off

```bash
make observability-record TASK=issue-42 ARCHETYPE=Builder PHASE=build \
  TOKENS_IN=1200 TOKENS_OUT=800 BUDGET_REMAINING=5000 DURATION_SECONDS=42
make observability-complete TASK=issue-42 ARCHETYPE=Maintainer PHASE=review \
  TOKENS_IN=500 TOKENS_OUT=300 BUDGET_REMAINING=4200 DURATION_SECONDS=18 OUTCOME=success
```

`SWITCHED=true TRIGGER=security-risk` records a dynamic mode change. Token and cost values
are `na` unless the agent runtime exposes them (stored as JSON `null`); never invent provider pricing. `complete`
writes `trajectories/<task>.trajectory.md` from the structured source of truth,
`events.jsonl`.

## Read the health summary

```bash
make metrics
```

The summary reports recorded tokens, successful/failed-task and switch rates, supplied cost
estimate, and eval-run count. `make eval-agent-flow` also records its outcome here, linking
the existing eval result and trajectory evidence to the same operational history.
