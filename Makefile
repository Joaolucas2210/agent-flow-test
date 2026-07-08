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

.PHONY: help setup adf-claude adf-codex adf-cursor setup-graphify check quality test-loop hooks ci clean-links

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
