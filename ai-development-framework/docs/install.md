# Install & Distribution

The framework is one core (`ai-development-framework/`) plus thin per-tool adapters wired by
symlink. Install = link the core into `.claude/`, `.codex/`, `.cursor/`; nothing is copied.

## Install

```bash
./setup-adf.sh all        # Claude + Codex + Cursor + hooks + Graphify + RTK (default)
./setup-adf.sh claude     # one platform only
./setup-adf.sh --doctor   # health check: tools + read-only gates, no changes
./setup-adf.sh --version  # print VERSION
```

`make setup` / `make adf-claude` / `make check` are equivalents (see `make help`).

## Clean install (temp dir)

Prove a from-scratch install without touching your repo:

```bash
tmp=$(mktemp -d); git clone . "$tmp"; cd "$tmp"
./setup-adf.sh all && ./setup-adf.sh --doctor
```

## Idempotency

Re-running is safe. `link()` replaces stale symlinks and **skips real files** with a warning
(`setup-adf.sh:36-37`) — running `setup-adf.sh all` twice re-points the same links and changes
no real file. Verify:

```bash
./setup-adf.sh all >/dev/null && a=$(find .claude .codex .cursor -type l | sort)
./setup-adf.sh all >/dev/null && b=$(find .claude .codex .cursor -type l | sort)
[ "$a" = "$b" ] && echo "idempotent" || echo "DRIFT"
```

## Rollback

Symlinks only, so removal is clean:

```bash
git clean -ndx .claude .codex .cursor      # preview what setup created
git clean -fdx  .claude .codex .cursor     # remove it
```

Real (non-symlink) files are never overwritten by setup, so nothing of yours is lost.

## Platform compatibility

| Platform | Wiring | Commands surface | Notes |
| --- | --- | --- | --- |
| Claude Code | `agents/`, `commands/`, `skills/` → `.claude/` | `/spec /plan /build /review /ship /graphify` | primary target; hooks active |
| Codex | `skills/` → `.codex/skills`, `commands/` → `.codex/prompts` | prompts | conflicting files skipped, not overwritten |
| Cursor | `commands/` → `.cursor/commands`; `AGENTS.md` read natively | commands | AGENTS.md at repo root |

## Versioning & releases

`VERSION` (repo root) is the single source of truth; `./setup-adf.sh --version` reads it.
Bump it in the same PR as a breaking change to the core contract (gates, skill schema, hook API).

Not yet automated — no release tooling, example repos, or version-migration guide exist,
because there is one version and no external consumers. Add them when a real second version or
downstream user appears (YAGNI); until then this section is the honest state.
