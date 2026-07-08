#!/usr/bin/env bash
# setup-adf.sh — activate the AI Development Framework (agents, commands, skills,
# hooks, Graphify, RTK) for Claude Code and/or Codex.
#
# Usage:
#   ./setup-adf.sh [claude|codex|all]   # default: all
#   ./setup-adf.sh --check              # verify tools, don't change anything
#   ./setup-adf.sh --help
#
# Idempotent: re-running relinks without duplicating. Never overwrites a real file
# (only replaces symlinks it owns). ponytail: symlinks, not copies — one source of truth.
set -euo pipefail

# ---------------------------------------------------------------------------- paths
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADF="$ROOT/ai-development-framework"
CLAUDE_DIR="$ROOT/.claude"
CODEX_DIR="$ROOT/.codex"
CURSOR_DIR="$ROOT/.cursor"
PLATFORM="claude"   # graphify --platform; set from the target in main()
GRAPHIFY_PKG="graphifyy"   # ⚠ verify at https://github.com/safishamsi/graphify

# ---------------------------------------------------------------------------- output
c_reset=$'\033[0m'; c_bold=$'\033[1m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_red=$'\033[31m'; c_blu=$'\033[36m'
info()  { printf '%s▶%s %s\n' "$c_blu" "$c_reset" "$*"; }
ok()    { printf '%s✓%s %s\n' "$c_grn" "$c_reset" "$*"; }
warn()  { printf '%s!%s %s\n' "$c_yel" "$c_reset" "$*"; }
err()   { printf '%s✗%s %s\n' "$c_red" "$c_reset" "$*" >&2; }
die()   { err "$*"; exit 1; }

# ---------------------------------------------------------------------------- helpers
# link SRC -> DEST. Skips real files/dirs (warns); replaces stale symlinks.
link() {
  local src="$1" dest="$2"
  [ -e "$src" ] || { warn "source missing, skip: $src"; return 0; }
  if [ -L "$dest" ]; then rm -f "$dest"
  elif [ -e "$dest" ]; then warn "exists (not a symlink), skip: ${dest#$ROOT/}"; return 0; fi
  ln -s "$src" "$dest"
  ok "linked ${dest#$ROOT/} -> ${src#$ROOT/}"
}

# link every child of SRC dir into DEST dir (per-item; used when DEST is pre-populated).
link_children() {
  local src="$1" dest="$2"
  [ -d "$src" ] || { warn "source dir missing, skip: $src"; return 0; }
  mkdir -p "$dest"
  local child
  for child in "$src"/*; do
    [ -e "$child" ] || continue
    link "$child" "$dest/$(basename "$child")"
  done
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------- steps
setup_claude() {
  info "Claude Code — linking agents / commands / skills into .claude/"
  mkdir -p "$CLAUDE_DIR"
  link "$ADF/agents"   "$CLAUDE_DIR/agents"
  link "$ADF/commands" "$CLAUDE_DIR/commands"
  link "$ADF/skills"   "$CLAUDE_DIR/skills"
}

setup_codex() {
  info "Codex — linking skills into .codex/skills and commands into .codex/prompts"
  # .codex/skills is usually pre-populated → link per-item, skipping conflicts.
  link_children "$ADF/skills"   "$CODEX_DIR/skills"
  link_children "$ADF/commands" "$CODEX_DIR/prompts"
  link "$ADF/agents" "$CODEX_DIR/agents"
}

setup_cursor() {
  info "Cursor — linking commands into .cursor/commands (AGENTS.md is read natively at root)"
  # ponytail: Cursor has no agents/skills runtime; only commands map cleanly. Its
  # rules want .mdc — AGENTS.md already carries the flow, so we don't duplicate rules/.
  link_children "$ADF/commands" "$CURSOR_DIR/commands"
}

setup_hooks() {
  info "Git hooks — installing pre-commit"
  chmod +x "$ADF/hooks/"*.sh "$ADF/hooks/pre-commit" 2>/dev/null || true
  if [ -d "$ROOT/.git" ]; then
    link "$ADF/hooks/pre-commit" "$ROOT/.git/hooks/pre-commit"
  else
    warn "no .git dir — skipping git hook install"
  fi
}

# GitHub Actions is intentionally out of the default flow for now.
# Use `make ci` to place the workflow when you want it.

setup_graphify() {
  info "Graphify — knowledge graph (per-project, --platform $PLATFORM)"
  # Auto-install if missing. ponytail: pip if graphify absent, else use what's there.
  if ! have graphify; then
    warn "graphify not found — installing '$GRAPHIFY_PKG' (⚠ verify pkg name at the repo)"
    if have pip; then pip install "$GRAPHIFY_PKG" 2>/dev/null || true
    elif have pip3; then pip3 install "$GRAPHIFY_PKG" 2>/dev/null || true
    else warn "no pip/pip3 — install Python then rerun"; fi
  fi
  if have graphify; then
    ok "graphify present: $(graphify --version 2>/dev/null || echo '?')"
    ( cd "$ROOT" && graphify install --platform "$PLATFORM" 2>/dev/null ) \
      && ok "graphify skill installed (--platform $PLATFORM)" || warn "graphify install skipped/failed"
    # ponytail: the graph is built by the /graphify skill in-agent, not a shell command.
    info "build the graph in-agent:  /graphify .   → writes graphify-out/graph.json"
  else
    err "graphify still unavailable after install attempt."
    printf '    pip install %s && graphify install --platform %s\n' "$GRAPHIFY_PKG" "$PLATFORM"
    printf '    then in-agent:  /graphify .\n'
  fi
}

check_rtk() {
  info "RTK — output compression"
  if have rtk; then
    ok "rtk present: $(rtk --version 2>/dev/null || echo '?')"
    rtk gain >/dev/null 2>&1 && ok "'rtk gain' works" || warn "'rtk gain' failed — check for the rtk name collision (see skills/rtk-integration)"
  else
    warn "rtk not found — install from https://github.com/rtk-ai/rtk (⚠ verify)"
  fi
}

doctor() {
  info "Environment check (no changes made)"
  [ -d "$ADF" ] && ok "framework dir present" || die "missing $ADF — run from the project root"
  for t in git graphify rtk; do have "$t" && ok "$t: $(command -v "$t")" || warn "$t: not installed"; done
  [ -d "$ROOT/.git" ] && ok ".git present" || warn "not a git repo"
}

summary() {
  echo
  printf '%sNext:%s\n' "$c_bold" "$c_reset"
  echo "  1. Open Claude Code here — /plan /build /review /ship /graphify are available."
  echo "  2. /graphify .         # build the codebase graph (in-agent) -> graphify-out/graph.json"
  echo "  3. rtk gain            # confirm token savings"
  echo "  4. make quality        # run the gate locally"
}

usage() {
  cat <<EOF
${c_bold}setup-adf.sh${c_reset} — activate the AI Development Framework

Usage:
  ./setup-adf.sh [claude|codex|cursor|all]   Link framework + hooks + CI, then Graphify/RTK setup
                                             (default: all)
  ./setup-adf.sh --check | --doctor          Verify tools only, make no changes
  ./setup-adf.sh --help

Targets:
  claude   Link agents/commands/skills into .claude/
  codex    Link skills->.codex/skills, commands->.codex/prompts (skips conflicts)
  cursor   Link commands->.cursor/commands (AGENTS.md read natively at root)
  all      All of the above
EOF
}

# ---------------------------------------------------------------------------- main
main() {
  [ -d "$ADF" ] || die "ai-development-framework/ not found next to this script."
  local target="${1:-all}"
  case "$target" in
    -h|--help)         usage; exit 0 ;;
    --check|--doctor)  doctor; exit 0 ;;
    claude)  PLATFORM="claude"; setup_claude ;;
    codex)   PLATFORM="codex";  setup_codex ;;
    cursor)  PLATFORM="cursor"; setup_cursor ;;
    all)     PLATFORM="claude"; setup_claude; setup_codex; setup_cursor ;;
    *)       err "unknown target: $target"; usage; exit 2 ;;
  esac
  setup_hooks
  echo
  setup_graphify
  check_rtk
  summary
  ok "Done."
}
main "$@"
