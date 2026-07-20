---
name: archetype-orchestrator
description: Classify a task into one of Cherny's five archetypes (Prototyper/Builder/Sweeper/Grower/Maintainer) and route it to the right loop, skills, and gates. Use at the start of a task when the phase is unclear.
---

# Archetype Orchestrator

The dispatcher for archetype-guided work. It answers one question — *what mode is this?* —
then hands off. It does not do the work itself; it routes to `loops/` and the skills below.

## Classify (first match wins)
1. Unknown whether the idea works, or "will this fly?" → **Prototyper**
2. A proven prototype must become production code → **Builder**
3. Code is bloated, duplicated, or too token-expensive → **Sweeper**
4. Question is "is it moving the metric / PMF?" → **Grower**
5. Question is safety, reliability, or health at scale → **Maintainer**

Genuinely ambiguous → default **Prototyper** (cheapest to be wrong in), escalate as evidence arrives.

## Route

| Archetype | Loop | Skills it activates | Gate posture |
|---|---|---|---|
| Prototyper | `loops/prototyper.md` | `skills/planning`, `skills/ddd-agent-skill` | loose (1 check) |
| Builder | `loops/builder.md` | `skills/implementation`, `skills/uncle-bob-discipline`, `skills/quality-gates` | hard |
| Sweeper | `loops/sweeper.md` | `skills/ponytail`, `skills/rtk-integration` | behavior-unchanged |
| Grower | `loops/grower.md` | `skills/measurement-driven-improvement` | trend-must-move |
| Maintainer | `loops/maintainer.md` | `skills/security-review`, `skills/quality-gates` | strictest |

`skills/graphify` is cross-cutting — every archetype queries the graph before deep reads.

## Cross-archetype defaults
- **RTK + Graphify** auto-activate in **Sweeper** (aggressive token/dedup pass).
- The normal lifecycle is a **sequence**: Prototyper → Builder → Sweeper → Grower → Maintainer.
  A task may skip stages, never gates. Reviewer agents run in Builder and Maintainer.
- Human owns taste/irreversible calls at every hand-off (`agents/staff-architect.md`).

## Output format
```
ARCHETYPE: <one of five>  (because <the deciding signal>)
LOOP: loops/<file>.md
ACTIVATE: <skills>
GATES: <posture>
NEXT: <likely next archetype>
```

## When NOT to use
Skip this when the archetype is already obvious or the user named a command
(`/build` = Builder, `/review` = Maintainer). Don't classify a one-line edit — just do it.
Not a state machine: it routes once; re-run it only when the task's phase actually changes.

## Integration
`loops/` (mode context) · every skill in `skills/` (the work) · `agents/staff-architect.md` (taste).
