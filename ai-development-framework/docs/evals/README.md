# Agent-flow evals

Minimal harness to run the agent flow against a fixed task and **measure whether
it resolved** — the outer loop the inner build/gate loop can't see. Roadmap Fase 4.
Polyglot by design: the gate is a stdlib test runner, picked per fixture language.

## What a case is

```
fixtures/<case>/
  task.md            # the spec handed to the agent (goal + objective done criteria)
  solution.{js,py}   # what the agent edits
  test.js            # JS gate  — node --test (stdlib)
  test_*.py          # Python gate — python3 -m unittest discover (stdlib)
runs/<case>.trajectory.md   # reason/act/observe of a run (see runs/TEMPLATE.trajectory.md)
results.csv                 # one row per run: date,commit,case,resolved,iterations,est_tokens,gate
```

A fixture is **one language**: it has a `test.js` **or** `test_*.py`, and the harness
runs the matching stdlib runner. No new dependency — `node:test` and `unittest` ship
with the runtime. (The `unittest.TestCase` files also run under pytest unchanged, if
you install it.)

## Run it

```bash
make eval-agent-flow                 # default CASE=sum-bug (JS)
make eval-agent-flow CASE=median-bug # Python
```

- `resolved = fixture gate passed`. **Exit code = resolved** → it behaves like a gate.
- **Trajectory is mandatory** — no `runs/<case>.trajectory.md` ⇒ hard fail. Capturing
  what the agent thought/did/observed is first-class, not optional.
- Required runtime absent (`node`/`python3`) ⇒ honest skip (`resolved=na`, exit 0),
  never a fake pass.
- Result is appended to `results.csv`, idempotent per `commit+case`.

## How it proves the concept (fail → pass)

The fixture starts RED (a seeded bug). Run the harness ⇒ `resolved=no` (gate catches it).
Fix `solution.*` + write the trajectory ⇒ `resolved=yes`. Both rows land in `results.csv`.
After that the case is a **regression guard** for the agent flow. `median-bug` proves the
same loop closes in a second language.

## Adding a case

1. `cp -r fixtures/sum-bug fixtures/<case>` (or `median-bug` for Python).
2. Rewrite `task.md` with the goal + an objective done criterion.
3. Write the gate — `test.js` (JS) **or** `test_*.py` (Python) — small and objectively
   checkable. Seed the bug in `solution.*` so it ships RED.
4. Copy `runs/TEMPLATE.trajectory.md` to `runs/<case>.trajectory.md` and fill it in.
5. `make eval-agent-flow CASE=<case>` → records the row.

Keep each case small. Don't build a generic loop controller or a headless runner until
the roadmap earns them (Ponytail). Running every case at once is the next honest slice.
