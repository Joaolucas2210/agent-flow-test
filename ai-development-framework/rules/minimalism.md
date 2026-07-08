# Minimalism rules (Ponytail, canonical)

Stop at the first rung that holds:
1. Does it need to exist? Speculative → skip, say so. (YAGNI)
2. Stdlib does it? Use it.
3. Native platform feature? Use it (CSS over JS, DB constraint over app code).
4. Existing dependency solves it? Use it — no new dep for a few lines.
5. One line? One line.
6. Only then: minimum code that works.

## Always
- Fewest files, shortest diff, boring over clever.
- Mark shortcuts: `// ponytail: <what>, upgrade when <trigger>`.
- One runnable check per non-trivial logic.

## Never simplify away
Input validation at trust boundaries · error handling that prevents data loss · security ·
accessibility · anything explicitly requested · hardware calibration knobs.

See `skills/ponytail/SKILL.md` for levels (`lite|full|ultra`, default full).
