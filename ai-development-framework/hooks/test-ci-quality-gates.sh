#!/usr/bin/env bash
# ci-quality-gates.sh self-check. The one invariant worth more than all the others:
# **it must never print green for gates that never ran.** Plus: a failing gate blocks
# AND feeds the learning loop.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fw="$tmp/fw"; mkdir -p "$fw/hooks" "$fw/rules"
# Only the hooks under test — no test-*.sh, so the contract loop can't recurse into this file.
for h in thresholds.sh shell-complexity.sh shell-complexity.awk observability.sh eval-agent-flow.sh eval-required.sh; do
  cp "$ROOT/hooks/$h" "$fw/hooks/"
done
cp "$ROOT/rules/quality-thresholds.md" "$fw/rules/"
( cd "$tmp" && git init -q . && git config user.email t@t && git config user.name t )
gates() { ( cd "$tmp" && ADF=fw CI="${CI:-}" "$ROOT/hooks/ci-quality-gates.sh" 2>&1 ); }

# 1. Nothing to measure + CI → hard failure. A green CI run with zero gates is the lie this prevents.
out="$(CI=1 gates)" && { echo "✗ CI passed with zero gates evaluated" >&2; exit 1; }
grep -q 'no quality gates evaluated' <<< "$out"

# 2. Same situation locally: allowed to exit 0, but must say it is NOT a pass.
out="$(gates)"
grep -q 'local mode, not a pass' <<< "$out"
grep -q '✓ .* gate(s) green' <<< "$out" && { echo "✗ claimed green with zero gates" >&2; exit 1; }

# 3. A shell file over the complexity threshold blocks the merge...
{ echo 'bad() {'; for i in $(seq 1 12); do echo "  [ -f $i ] && echo $i"; done; echo '}'; echo bad; } > "$tmp/bad.sh"
( cd "$tmp" && git add bad.sh )
out="$(CI=1 gates)" && { echo "✗ over-threshold shell passed" >&2; exit 1; }
grep -q 'complexity (shell' <<< "$out"
# ...and the failure reaches the learning loop as a recorded signal.
grep -q '"task":"gate-complexity-shell' "$fw/docs/observability/events.jsonl"

# 4. Clean shell = a real, counted gate. Shell is no longer an unmeasured stack.
printf 'ok_fn() {\n  echo fine\n}\nok_fn\n' > "$tmp/bad.sh"
out="$(CI=1 gates)"
grep -q '✓ 1 gate(s) green' <<< "$out"
grep -q 'skipped: evals (no fixtures)' <<< "$out"

echo "✓ ci-quality-gates self-test"
