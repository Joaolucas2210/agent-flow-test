#!/usr/bin/env bash
# CI quality gates: the full metric wall. Any failing number blocks the merge.
# Wire into your CI (GitHub Actions/GitLab) as a required step.
# ponytail: thin wrapper over your existing tools — edit the tool commands to match the stack.
set -euo pipefail

run() { command -v rtk >/dev/null 2>&1 && rtk "$@" || "$@"; }
fail() { echo "✗ $1"; exit 1; }

echo "▶ CI quality gates (thresholds in rules/quality-thresholds.md)"

# 1. Graph freshness check. The graph is built in-agent (/graphify .), not in shell CI,
#    so here we only warn if it's missing/stale — we don't try to build it.
if [ -f graphify-out/graph.json ]; then
  [ -f graphify-out/.stale ] && echo "::warning::graph is stale — run '/graphify . --update' in-agent"
else
  echo "::notice::no graphify-out/graph.json — build in-agent with '/graphify .' for the dependency gate"
fi
# The dependency-cycle gate below uses a real static tool (madge/pydeps), not graphify.

# 2. Coverage — edit for your runner.
# run pytest --cov --cov-fail-under=80 || fail "coverage < 80%"

# 3. Complexity / size.
# command -v lizard >/dev/null 2>&1 && run lizard -C 10 -L 50 src/ || fail "complexity/size gate"

# 4. Mutation.
# command -v mutmut >/dev/null 2>&1 && run mutmut run || fail "mutation gate"

# 5. Dependency cycles.
# command -v madge   >/dev/null 2>&1 && run madge --circular src/ || fail "dependency cycles"

# 6. Token efficiency report (informational).
command -v rtk >/dev/null 2>&1 && rtk gain || true

echo "✓ all gates green (uncomment + tune the tool lines for your stack)"
