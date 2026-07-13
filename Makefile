# AI Development Framework — task runner
# `make` or `make help` lists targets. Thin wrappers over setup-adf.sh + the framework hooks.
.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash
ADF   := ai-development-framework
PLATFORM ?= claude          # graphify --platform (override: make setup-graphify PLATFORM=codex)
GRAPHIFY_PKG := graphifyy    # ⚠ verify pkg name at https://github.com/safishamsi/graphify

# rtk if present, else raw. ponytail: don't force a dep that may be absent.
RTK := $(shell command -v rtk 2>/dev/null)
RUN := $(if $(RTK),rtk,)

.PHONY: help setup adf-claude adf-codex adf-cursor setup-graphify check quality graph-check metrics-snapshot rtk-report graph-hit-rate skill-audit eval-agent-flow eval-agent-flow-all eval-diagnose test-loop hooks ci clean-links

help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' \
	  | sort

setup: ## Full activation for Claude + Codex + Cursor (links, hooks, Graphify, RTK)
	@./setup-adf.sh all

adf-claude: ## Activate framework for Claude Code (.claude/) + Graphify
	@./setup-adf.sh claude

adf-codex: ## Activate framework for Codex (.codex/) + Graphify
	@./setup-adf.sh codex

adf-cursor: ## Activate framework for Cursor (.cursor/commands/) + Graphify
	@./setup-adf.sh cursor

setup-graphify: ## Install (pip) + wire the Graphify skill (PLATFORM=claude|codex). Build the graph in-agent with /graphify .
	@echo "▶ Graphify setup (--platform $(PLATFORM))"
	@command -v graphify >/dev/null 2>&1 || { \
	  echo "  installing $(GRAPHIFY_PKG)"; \
	  (command -v pip >/dev/null 2>&1 && pip install $(GRAPHIFY_PKG)) \
	    || (command -v pip3 >/dev/null 2>&1 && pip3 install $(GRAPHIFY_PKG)) \
	    || echo "  no pip/pip3 — install Python first"; }
	@command -v graphify >/dev/null 2>&1 \
	  && { graphify install --platform $(PLATFORM) \
	       && echo "✓ graphify skill installed for $(PLATFORM)" \
	       && echo "→ build the graph in-agent:  /graphify .   (writes graphify-out/graph.json)"; } \
	  || echo "✗ graphify unavailable — see ai-development-framework/skills/graphify"

check: ## Verify tools (git/graphify/rtk) without changing anything
	@./setup-adf.sh --check

quality: ## Run the full CI quality gates locally (coverage/complexity/mutation/cycles)
	@chmod +x $(ADF)/hooks/ci-quality-gates.sh && $(ADF)/hooks/ci-quality-gates.sh

graph-check: ## Report if the knowledge graph is stale vs HEAD (git rev-parse)
	@report="graphify-out/GRAPH_REPORT.md"; \
	[ -f "$$report" ] || { echo "✗ graph-check: $$report missing — build in-agent with /graphify ."; exit 1; }; \
	built=$$(grep -oE 'Built from commit: `[0-9a-f]{7,40}`' "$$report" | grep -oE '[0-9a-f]{7,40}' | head -1); \
	[ -n "$$built" ] || { echo "✗ graph-check: no 'Built from commit' line in $$report"; exit 1; }; \
	head=$$(git rev-parse --short=$${#built} HEAD); \
	if [ "$$built" = "$$head" ]; then echo "✓ graph fresh (commit $$head)"; \
	else echo "✗ graph STALE: built from $$built, HEAD is $$head — run /graphify . to update"; exit 1; fi

metrics-snapshot: ## Append this commit's metrics to docs/metrics/history.csv (idempotent per commit)
	@csv="$(ADF)/docs/metrics/history.csv"; \
	commit=$$(git rev-parse --short HEAD); \
	date=$$(git show -s --format=%cs HEAD); \
	report="graphify-out/GRAPH_REPORT.md"; graph=na; \
	if [ -f "$$report" ]; then \
	  built=$$(grep 'Built from commit' "$$report" | grep -oE '[0-9a-f]{7,40}' | head -1); \
	  if [ -n "$$built" ]; then head=$$(git rev-parse --short=$${#built} HEAD); \
	    [ "$$built" = "$$head" ] && graph=fresh || graph=stale; fi; \
	fi; \
	gain=na; command -v rtk >/dev/null 2>&1 && gain=$$(rtk gain 2>/dev/null | grep -oE '\([0-9.]+%\)' | head -1 | tr -d '()'); \
	[ -n "$$gain" ] || gain=na; \
	row="$$date,$$commit,na,na,na,na,$$graph,$$gain"; \
	tmp=$$(mktemp); grep -v ",$$commit," "$$csv" > "$$tmp" || true; mv "$$tmp" "$$csv"; \
	echo "$$row" >> "$$csv"; \
	echo "✓ snapshot: $$row"; \
	echo "  (coverage/mutation/complexity/cycles = na until a stack runner fills them — same honesty as 'make quality')"

rtk-report: ## Save RTK token-savings (global + per-command) to docs/metrics/rtk-report.txt
	@out="$(ADF)/docs/metrics/rtk-report.txt"; \
	if command -v rtk >/dev/null 2>&1; then \
	  { rtk gain; echo; rtk gain --history; } > "$$out" 2>&1 && echo "✓ rtk report → $$out"; \
	else echo "⚠ rtk absent — nothing to report (install RTK to capture token savings)"; fi

graph-hit-rate: ## Report graph-query hit rate from docs/metrics/graph-hits.log (agents append hit/miss)
	@log="$(ADF)/docs/metrics/graph-hits.log"; \
	[ -f "$$log" ] || { echo "⚠ no graph-hits log yet ($$log) — append 'hit' when a task queried the graph before reading big files, 'miss' otherwise"; exit 0; }; \
	hits=$$(grep -c '^hit' "$$log" || true); miss=$$(grep -c '^miss' "$$log" || true); total=$$((hits+miss)); \
	[ "$$total" -gt 0 ] && echo "graph-hit-rate: $$hits/$$total ($$((hits*100/total))%)" || echo "⚠ graph-hits log empty"

skill-audit: ## Audit skills: valid metadata, no broken refs, size/overlap/when-not warnings
	@chmod +x $(ADF)/hooks/skill-audit.sh && $(ADF)/hooks/skill-audit.sh

eval-agent-flow: ## Run one agent-flow eval case (CASE=sum-bug): objective gate + trajectory + record to docs/evals/results.csv
	@chmod +x $(ADF)/hooks/eval-agent-flow.sh && $(ADF)/hooks/eval-agent-flow.sh $(CASE)

eval-agent-flow-all: ## Run every fixture case (doesn't abort on a failing case) — refreshes all rows in results.csv
	@chmod +x $(ADF)/hooks/eval-agent-flow.sh; rc=0; \
	for d in $(ADF)/docs/evals/fixtures/*/; do \
	  c=$$(basename "$$d"); $(ADF)/hooks/eval-agent-flow.sh "$$c" || rc=1; \
	done; \
	echo "▶ all cases run (see docs/evals/results.csv) — next: make eval-diagnose"; exit $$rc

eval-diagnose: ## Diagnose recurring eval failures → improvement-proposal stubs in docs/traces/proposals
	@chmod +x $(ADF)/hooks/eval-diagnose.sh && $(ADF)/hooks/eval-diagnose.sh

hooks: ## (Re)install the git pre-commit hook
	@chmod +x $(ADF)/hooks/*.sh $(ADF)/hooks/pre-commit \
	  && ln -sf ../../$(ADF)/hooks/pre-commit .git/hooks/pre-commit \
	  && echo "✓ pre-commit installed"

ci: ## Copy the GitHub Actions workflow to .github/workflows/ (repo root)
	@mkdir -p .github/workflows \
	  && cp $(ADF)/.github/workflows/quality-gates.yml .github/workflows/ \
	  && echo "✓ workflow at .github/workflows/quality-gates.yml"

test-loop: ## Smoke-test the framework loop (graph build + gates + rtk gain)
	@echo "▶ 1/3 rebuild graph"; command -v graphify >/dev/null 2>&1 && graphify build || echo "  (graphify absent — skipped)"
	@echo "▶ 2/3 quality gates"; $(MAKE) -s quality
	@echo "▶ 3/3 token savings"; $(if $(RTK),rtk gain,echo "  (rtk absent — skipped)")
	@echo "✓ loop OK — now drive /spec → /plan → /build → /test → /review → /ship in your agent"

clean-links: ## Remove framework symlinks from .claude/ and .codex/
	@for l in .claude/agents .claude/commands .claude/skills .codex/agents; do \
	  [ -L "$$l" ] && rm -f "$$l" && echo "removed $$l" || true; done
	@echo "✓ per-item .codex/.cursor links left intact (remove manually if needed)"
