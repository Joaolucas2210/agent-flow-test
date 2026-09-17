#!/usr/bin/env bash
# eval-agent-flow.sh self-check: the harness must actually DETECT a regression.
# A green eval harness that can't go red is the worst kind of false green.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "~ eval-agent-flow self-test skipped (no node)"; exit 0; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fw="$tmp/fw"; fix="$fw/docs/evals/fixtures/demo"; runs="$fw/docs/evals/runs"; csv="$fw/docs/evals/results.csv"
mkdir -p "$fix" "$runs" "$fw/hooks"
cp "$ROOT/hooks/observability.sh" "$fw/hooks/"
( cd "$tmp" && git init -q . && git commit -q --allow-empty -m init )

echo 'export const answer = () => 41;' > "$fix/solution.js"
cat > "$fix/test.js" <<'JS'
import { test } from 'node:test'; import assert from 'node:assert';
import { answer } from './solution.js';
test('answer', () => assert.strictEqual(answer(), 42));
JS
echo '{"type":"module"}' > "$fix/package.json"
harness() { ( cd "$tmp" && ADF=fw "$ROOT/hooks/eval-agent-flow.sh" "$@" ); }

# 1. No trajectory = hard fail. The evidence of a run is not optional.
out="$(harness demo 2>&1)" && { echo "✗ passed without a trajectory" >&2; exit 1; }
grep -q 'no trajectory' <<< "$out"

printf -- '---\niterations: 2\nest_tokens: 100\n---\n# run\n' > "$runs/demo.trajectory.md"

# 2. RED: the seeded bug must make the case fail, and be recorded as failed.
harness demo >/dev/null 2>&1 && { echo "✗ a broken fixture reported resolved" >&2; exit 1; }
grep -q ',demo,no,2,100,fail$' "$csv"

# 3. GREEN after the fix, recorded with the trajectory's own metadata.
echo 'export const answer = () => 42;' > "$fix/solution.js"
harness demo >/dev/null 2>&1
grep -q ',demo,yes,2,100,pass$' "$csv"

# 4. One row per commit+case — reruns replace, never accumulate.
harness demo >/dev/null 2>&1
[ "$(grep -c ',demo,' "$csv")" = 1 ]

# 5. --all propagates a single regression; a missing fixture is an error, not a skip.
echo 'export const answer = () => 0;' > "$fix/solution.js"
harness --all >/dev/null 2>&1 && { echo "✗ --all hid a failing case" >&2; exit 1; }
harness nonexistent-case >/dev/null 2>&1 && { echo "✗ accepted a missing fixture" >&2; exit 1; }

# 6. The run is visible to the Learning Loop, not only to the CSV.
grep -q '"task":"eval-demo"' "$fw/docs/observability/events.jsonl"
grep -q '"outcome":"failure"' "$fw/docs/observability/events.jsonl"

echo "✓ eval-agent-flow self-test"
