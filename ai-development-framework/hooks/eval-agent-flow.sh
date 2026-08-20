#!/usr/bin/env bash
# Agent-flow eval harness (Loop Engineering — Fase 4, minimal slice).
# Runs ONE fixture case's objective gate, requires a captured trajectory, and
# records the result. Reproducible without an LLM in the loop: the gate is the
# truth, the trajectory is the evidence of a run.
#
#   resolved = fixture gate passed.  Exit code = resolved (0 yes / 1 no) so this
#   behaves like a gate. Trajectory missing = hard fail (trajectory is first-class).
#   Runtime absent = honest skip (resolved=na, exit 0) — same policy as ci-quality-gates.
#
# Polyglot by the fixture's gate file (stdlib runners only, no new dep):
#   test.js     -> node --test              test_*.py -> python3 -m unittest discover
#
# Usage: eval-agent-flow.sh [CASE]     (default: sum-bug)
set -uo pipefail

ADF="ai-development-framework"
EVALS="$ADF/docs/evals"
CASE="${1:-sum-bug}"
FIX="$EVALS/fixtures/$CASE"
TRAJ="$EVALS/runs/$CASE.trajectory.md"
CSV="$EVALS/results.csv"
started=$SECONDS

echo "▶ eval-agent-flow ($CASE)"
[ -d "$FIX" ]  || { echo "✗ no fixture at $FIX"; exit 1; }
[ -f "$TRAJ" ] || { echo "✗ $CASE: no trajectory at $TRAJ — a run MUST capture reason/act/observe"; exit 1; }

# Pick the gate runtime by the fixture's gate file. One language per fixture.
if [ -f "$FIX/test.js" ]; then
  lang=js; need=node
elif ls "$FIX"/test_*.py >/dev/null 2>&1; then
  lang=py; need=python3
else
  echo "✗ $CASE: fixture has no gate (expected test.js or test_*.py)"; exit 1
fi

# Trajectory metadata (na if absent). frontmatter: iterations / est_tokens.
field() { awk -F': *' -v k="$1" '$1==k{print $2; exit}' "$TRAJ"; }
iters="$(field iterations)";  [ -n "$iters" ] || iters=na
tokens="$(field est_tokens)"; [ -n "$tokens" ] || tokens=na

# Objective gate. Runtime absent -> honest skip, not a fake pass.
run_gate() {
  case "$lang" in
    js) ( cd "$FIX" && node --test test.js ) ;;
    py) ( cd "$FIX" && python3 -m unittest discover ) ;;
  esac
}
if ! command -v "$need" >/dev/null 2>&1; then
  resolved=na; gate="skipped-no-$need"
  echo "⚠ $need absent — gate not evaluated (local mode, not a pass)"
elif run_gate >/dev/null 2>&1; then
  resolved=yes; gate=pass
else
  resolved=no;  gate=fail
fi

# Record — append idempotently per commit+case (dedup like metrics-snapshot).
commit="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
date="$(git show -s --format=%cs HEAD 2>/dev/null || echo nodate)"
[ -f "$CSV" ] || echo "date,commit,case,resolved,iterations,est_tokens,gate" > "$CSV"
row="$date,$commit,$CASE,$resolved,$iters,$tokens,$gate"
tmp="$(mktemp)"; grep -v ",$commit,$CASE," "$CSV" > "$tmp" 2>/dev/null || true; mv "$tmp" "$CSV"
echo "$row" >> "$CSV"

echo "✓ recorded: $row"
outcome=failure
[ "$resolved" = yes ] && outcome=success
[ "$resolved" = na ] && outcome=skipped
TASK="eval-$CASE" ARCHETYPE=Grower PHASE=eval TOKENS_IN=na TOKENS_OUT=na BUDGET_REMAINING=na \
  DURATION_SECONDS="$((SECONDS - started))" OUTCOME="$outcome" \
  "$ADF/hooks/observability.sh" complete
[ "$resolved" = "yes" ] || [ "$resolved" = "na" ]   # exit code = resolved
