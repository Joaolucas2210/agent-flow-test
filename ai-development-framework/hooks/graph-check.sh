#!/usr/bin/env bash
# Knowledge-graph freshness gate.
#
# The graph indexes CODE TOPOLOGY. A commit that only touches docs/config (or files graphify
# parses no topology from, e.g. shell) does not stale it — but graphify only re-stamps
# GRAPH_REPORT.md on a topology change, so its "Built from commit" line lags behind HEAD on
# topology-neutral commits. Comparing stamp == HEAD alone therefore reports a false STALE.
#
# Fresh when: stamp == HEAD, OR stamp is an ancestor of HEAD (graph was built from a commit in
#   HEAD's history; when graphify is present it is re-run first, so any real code drift rebuilds
#   and re-stamps to HEAD, and the pre-commit hook does the same on every commit).
# Stale when: stamp is not in HEAD's history (graph built on a divergent/rewound line, or missing).
#
# Env: GRAPH_REPORT overrides the report path; GRAPH_CHECK_NO_REFRESH=1 skips `graphify update`.
set -uo pipefail

read_stamp() { grep -oE 'Built from commit: `[0-9a-f]{7,40}`' "$1" | grep -oE '[0-9a-f]{7,40}' | head -1; }

check() {
  # Resolve per-call (not at load) so GRAPH_REPORT overrides work when check() is called in-process.
  local report="${GRAPH_REPORT:-graphify-out/GRAPH_REPORT.md}"
  [ -f "$report" ] || { echo "✗ graph-check: $report missing — build in-agent with /graphify ."; return 1; }
  # graphify is the authority on topology drift: re-run it so real code changes rebuild + re-stamp.
  # No-op (no writes) when the graph already matches the code. Skipped for CI / custom reports.
  if [ -z "${GRAPH_CHECK_NO_REFRESH:-}" ] && [ "$report" = "graphify-out/GRAPH_REPORT.md" ] && command -v graphify >/dev/null 2>&1; then
    graphify update >/dev/null 2>&1 || true
  fi
  local built head
  built=$(read_stamp "$report")
  [ -n "$built" ] || { echo "✗ graph-check: no 'Built from commit' line in $report"; return 1; }
  head=$(git rev-parse --short="${#built}" HEAD 2>/dev/null) || { echo "✗ graph-check: not a git repo"; return 1; }
  if [ "$built" = "$head" ]; then echo "✓ graph fresh (commit $head)"; return 0; fi
  if git merge-base --is-ancestor "$built" HEAD 2>/dev/null; then
    echo "✓ graph fresh (built at $built, an ancestor of HEAD $head — no code-topology drift since; stamp lags only on topology-neutral commits)"
    return 0
  fi
  echo "✗ graph STALE: built from $built, not in HEAD ($head) history — run /graphify . to rebuild"
  return 1
}

# ONE runnable check for the non-trivial logic (ancestor tolerance): fake reports, real git history.
self_test() {
  local tmp anc pass=0 fail=0
  tmp=$(mktemp)
  anc=$(git rev-parse --short "HEAD~1" 2>/dev/null || git rev-parse --short HEAD)
  printf 'Built from commit: `%s`\n' "$anc" > "$tmp"
  if GRAPH_REPORT="$tmp" GRAPH_CHECK_NO_REFRESH=1 check >/dev/null; then echo "✓ ancestor stamp → fresh"; pass=$((pass+1)); else echo "✗ ancestor stamp should be fresh"; fail=$((fail+1)); fi
  printf 'Built from commit: `deadbeef`\n' > "$tmp"
  if GRAPH_REPORT="$tmp" GRAPH_CHECK_NO_REFRESH=1 check >/dev/null; then echo "✗ non-ancestor stamp should be stale"; fail=$((fail+1)); else echo "✓ non-ancestor stamp → stale"; pass=$((pass+1)); fi
  rm -f "$tmp"
  echo "self-test: $pass passed, $fail failed"
  [ "$fail" -eq 0 ]
}

case "${1:-}" in
  --self-test) self_test ;;
  *)           check ;;
esac
