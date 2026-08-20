#!/usr/bin/env bash
# CI quality gates: the full metric wall. Any failing number blocks the merge.
# Gates run only for a DETECTED stack; anything skipped is reported, never counted as green.
# ponytail: detection over config — edit the tool lines to match your stack's thresholds.
set -euo pipefail

run()  { command -v rtk >/dev/null 2>&1 && rtk "$@" || "$@"; }
fail() { echo "✗ $1"; exit 1; }

CI="${CI:-}"                     # set CI=1 (any CI runner sets this) → "no gates" becomes a hard failure
ADF="${ADF:-ai-development-framework}"
gates_run=0
skipped=()

echo "▶ CI quality gates (thresholds in rules/quality-thresholds.md)"

# 1. Graph freshness — built in-agent (/graphify .), not here. Warn only; `make graph-check` is the gate.
if [ -f graphify-out/graph.json ]; then
  [ -f graphify-out/.stale ] && echo "::warning::graph is stale — run '/graphify . --update' in-agent"
else
  echo "::notice::no graphify-out/graph.json — build in-agent with '/graphify .' for the dependency gate"
fi

# 2-5. Real gates, only for a detected stack. Each either runs (counts) or is recorded as skipped.
js_dir=""
[ -f package.json ] && js_dir=.
[ -z "$js_dir" ] && [ -f sandbox/package.json ] && js_dir=sandbox
if [ -n "$js_dir" ]; then
  echo "▶ stack: JS/TS ($js_dir)"
  if command -v npm   >/dev/null 2>&1; then run npm --prefix "$js_dir" test || fail "tests (npm)"; gates_run=$((gates_run+1)); else skipped+=("tests (no npm)"); fi
  if command -v madge >/dev/null 2>&1; then run madge --circular "$js_dir" || fail "dependency cycles (madge)"; gates_run=$((gates_run+1)); else skipped+=("cycles (no madge)"); fi
  if command -v npx >/dev/null 2>&1 && { [ -f "$js_dir/stryker.conf.js" ] || [ -f "$js_dir/stryker.conf.json" ] || [ -f "$js_dir/stryker.config.mjs" ]; }; then
    ( cd "$js_dir" && run npx stryker run ) || fail "mutation (stryker)"; gates_run=$((gates_run+1)); else skipped+=("mutation (no stryker config)"); fi
elif [ -f pyproject.toml ] || [ -f setup.cfg ] || [ -f pytest.ini ] || [ -f setup.py ]; then
  echo "▶ stack: Python"
  if command -v pytest >/dev/null 2>&1; then run pytest              || fail "tests/coverage (pytest)"; gates_run=$((gates_run+1)); else skipped+=("tests/coverage (no pytest)"); fi
  if command -v lizard >/dev/null 2>&1; then run lizard -C 10 -L 50 . || fail "complexity/size (lizard)"; gates_run=$((gates_run+1)); else skipped+=("complexity (no lizard)"); fi
  if command -v mutmut >/dev/null 2>&1; then run mutmut run          || fail "mutation (mutmut)";        gates_run=$((gates_run+1)); else skipped+=("mutation (no mutmut)"); fi
else
  skipped+=("all gates (no JS/TS or Python stack detected)")
fi

# 6. Token efficiency report (informational).
command -v rtk >/dev/null 2>&1 && rtk gain || true

# 7. Observability contract — task hand-offs must remain structured and trajectory-capable.
"$ADF/hooks/test-observability.sh" || fail "observability contract"

# Honest verdict — never claim green for gates that never ran.
if [ ${#skipped[@]} -gt 0 ]; then printf '  skipped: %s\n' "${skipped[@]}"; fi
if [ "$gates_run" -eq 0 ]; then
  msg="no quality gates evaluated (coverage/mutation/complexity/cycles NOT checked)"
  if [ -n "$CI" ]; then fail "$msg — configure runners for your stack"; fi
  echo "⚠ $msg — local mode, not a pass. Configure your stack in rules/quality-thresholds.md"
  exit 0
fi
echo "✓ $gates_run gate(s) green"
