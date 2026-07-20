# AI Development Framework

**Staff-level agentic development for Claude Code · Cursor · Codex**

![Stars](https://img.shields.io/github/stars/Joaolucas2210/agent-flow-test?style=flat&color=f5c518)
![Forks](https://img.shields.io/github/forks/Joaolucas2210/agent-flow-test?style=flat)
![Last commit](https://img.shields.io/github/last-commit/Joaolucas2210/agent-flow-test)
![Issues](https://img.shields.io/github/issues/Joaolucas2210/agent-flow-test)

![Ponytail](https://img.shields.io/badge/Ponytail-minimalism-6e56cf)
![Graphify](https://img.shields.io/badge/Graphify-knowledge%20graph-2ea043)
![RTK](https://img.shields.io/badge/RTK-token%20killer-e0562b)
![Uncle Bob](https://img.shields.io/badge/Uncle%20Bob-discipline-1f6feb)
![Clean Code](https://img.shields.io/badge/Clean%20Code-metrics%20%3E%20line--by--line-555)

<!-- demo: grave o fluxo /plan → /graphify → /build e troque este placeholder pelo GIF -->
<!-- ![Demo](docs/demo.gif) -->

---

## Finalidade

Orquestração de desenvolvimento com IA nível **Staff / AI Engineer**: agentes revisores,
skills, quality gates e slash-commands que impõem disciplina de engenharia sênior — e economizam
tokens de forma agressiva. Agentes propõem; humanos decidem *taste* e arquitetura.

Quatro apostas centrais:

| Aposta | Alavanca | Efeito |
| --- | --- | --- |
| Agentes super-engenheiram | **Ponytail** (dev sênior preguiçoso) | até ~94% menos código gerado |
| Output de terminal inunda o contexto | **RTK** (Rust Token Killer) | 60–90% menos tokens em ops de dev |
| Reler arquivos inteiros a cada tarefa | **Graphify** (knowledge graph) | consulta o grafo em vez de reler |
| Review linha-a-linha não escala | **Quality Gates** (métricas) | coverage/complexity/mutation como gate — ativos por stack detectado (veja abaixo) |

---

## Resultados & Benchmarks

Alavancas medidas pelos vendors das ferramentas (metas do framework, ainda **não** re-medidas
neste repo — abra um PR com seus próprios números):

| Métrica | Alavanca | Efeito relatado |
| --- | --- | --- |
| Código gerado | Ponytail | até **~94%** menos código por feature |
| Tokens em ops de dev | RTK | **60–90%** menos output de terminal |
| Releitura de arquivos | Graphify | consulta o grafo em vez de reler (1 build, N queries) |

> Tem números de um projeto real? Rode `rtk gain` e `/graphify query ...`, e mande via PR —
> esta seção existe para virar dado medido, não claim de vendor.

---

## Como o projeto está organizado

```
agent-flow-test/                     ← raiz: entrypoints + config das ferramentas
├── setup-adf.sh                     # ativador (claude|codex|cursor|all) — links, hooks, Graphify, RTK
├── Makefile                         # task runner (make help)
├── README.md                        # este arquivo
├── AGENTS.md                        # config lida por Codex e Cursor (fica na raiz de propósito)
│
├── sandbox/                         # código de teste do projeto, isolado do framework
│   ├── index.js
│   └── package.json
│
├── ai-development-framework/        # ← o CORE (a estrutura reutilizável)
│   ├── agents/      backend / database / qa / security reviewers + staff-architect
│   ├── commands/    /spec /plan /build /test /review /ship /graphify
│   ├── skills/      planning, implementation, quality-gates, pr-review, security-review,
│   │                test-review, clean-code-enforcement, measurement-driven-improvement,
│   │                ddd-agent-skill, uncle-bob-discipline, ponytail, rtk-integration, graphify
│   ├── docs/        PRD-template, ADRs, base CLAUDE.md
│   ├── hooks/       rtk-wrap, graph-update, pre-commit, ci-quality-gates
│   ├── rules/       architecture, anti-patterns, token-optimization, minimalism, thresholds
│   └── CLAUDE.md    regras persistentes (raiz do core)
│
├── .claude/                         # symlinks p/ o core (criados pelo setup)
│   ├── agents → ../ai-development-framework/agents
│   ├── commands → …/commands
│   └── skills → …/skills
├── .codex/                          # symlinks por-item p/ Codex (skills, prompts)
└── .cursor/                         # symlinks p/ Cursor (commands); AGENTS.md lido da raiz
```

**Princípio da arquitetura:** o *core* (`ai-development-framework/`) é a única fonte de verdade;
`.claude/`, `.codex/` e `.cursor/` são só **symlinks** para ele. O `sandbox/` é o código sob teste, separado
do framework. Os entrypoints (`Makefile`, `setup-adf.sh`) vivem na raiz.

> GitHub Actions/CI está **fora do fluxo padrão** por enquanto. O workflow existe em
> `ai-development-framework/.github/workflows/` e pode ser posicionado depois com `make ci`.

---

## Instalação

### Opção 1 — Makefile (recomendado)

```bash
make setup            # ativação completa: links + hooks + Graphify + RTK (Claude + Codex + Cursor)
make adf-claude       # só Claude Code (.claude/) + Graphify
make adf-codex        # só Codex (.codex/) + Graphify
make adf-cursor       # só Cursor (.cursor/commands/) + Graphify
make setup-graphify   # só o knowledge graph (pip install + install + build)
make check            # verifica ferramentas, sem alterar nada
```

`make` (ou `make help`) lista todos os targets:

| Target | O que faz |
| --- | --- |
| `make setup` | ativação completa (Claude + Codex + Cursor + hooks + Graphify + RTK) |
| `make adf-claude` / `make adf-codex` / `make adf-cursor` | ativa para uma plataforma + Graphify |
| `make setup-graphify` | `pip install` + `graphify install --platform` + `graphify build` |
| `make check` | doctor: verifica git/graphify/rtk |
| `make quality` | roda os quality gates do stack detectado (JS/TS ou Python); pula e avisa se não houver runner — nunca reporta verde falso |
| `make graph-check` | reporta se o grafo (`graphify-out/GRAPH_REPORT.md`) está stale vs `git rev-parse HEAD` |
| `make test-loop` | smoke-test: grafo + gates + `rtk gain` |
| `make hooks` | (re)instala o git pre-commit |
| `make ci` | (opcional) posiciona o workflow de CI |
| `make clean-links` | remove os symlinks do framework |

### Opção 2 — setup-adf.sh direto

Idempotente, nunca sobrescreve arquivos reais (só troca symlinks que ele mesmo cria):

```bash
./setup-adf.sh all       # Claude + Codex + Cursor (default) — já instala e constrói o Graphify
./setup-adf.sh claude    # só .claude/  (--platform claude no Graphify)
./setup-adf.sh codex     # só .codex/   (--platform codex)
./setup-adf.sh cursor    # só .cursor/  (--platform cursor)
./setup-adf.sh --check   # doctor, sem alterações
./setup-adf.sh --help
```

Ambas as opções **já chamam o Graphify automaticamente** (instala via pip se faltar, roda
`graphify install --platform <plataforma>` e `graphify build`).

### Graphify (knowledge graph) — instalação por projeto

O pip + a instalação do skill são feitos por `make setup` / `setup-adf.sh`. **A construção do
grafo é feita no agente** com o skill `/graphify` (não há `graphify build` no shell). Manualmente:

```bash
pip install graphifyy                       # pacote real: graphifyy (v0.9.10 verificada aqui)
graphify install --platform claude          # instala o skill (ou: --platform codex)
```
Depois, dentro do Claude/Codex:
```text
/graphify .                                 # constrói o grafo → graphify-out/graph.json
```

Repo: <https://github.com/safishamsi/graphify>

**Uso diário — consulte o grafo (skill `/graphify`) antes de ler arquivos inteiros:**

```text
/graphify query "how does auth work?"       # BFS (contexto amplo)
/graphify query "what calls charge()" --dfs # DFS (rastreia um caminho)
/graphify query "..." --budget 1500         # limita a resposta a N tokens
/graphify . --update                        # re-indexa após mudanças grandes
```
Ferramentas de shell sobre o grafo já construído:
```bash
graphify path "AuthModule" "Database"       # menor caminho entre dois nós
graphify explain "PaymentService"           # explicação em linguagem natural de um nó
graphify add https://exemplo.com/doc        # adiciona uma URL ao corpus e atualiza o grafo
graphify install --platform claude --neo4j  # exporta cypher.txt (Neo4j) — também --falkordb
```

Rebuild automático: `PostToolUse(Edit|Write)` → `hooks/graph-update.sh` (dispara `/graphify . --update`).

> ⚠ **Correção verificada:** comandos como `graphify build`, `graphify query` e
> `graphify export --obsidian` **não existem** no Graphify real — build/query são via o skill
> `/graphify`. As versões acima foram testadas contra o binário `graphifyy` 0.9.10.

---

## Workflow: PRD → PR

```
/spec  → PRD a partir de uma ideia          (skills/planning)
/plan  → breakdown mínimo + query no grafo   (skills/planning + graphify)
/build → implementação mínima                (skills/implementation + ponytail)
/test  → testes + mutation + coverage gate   (skills/test-review + quality-gates)
/review→ painel multi-agente (métricas)      (agents/* + skills/pr-review)
/graphify . --update → atualiza o grafo      (skills/graphify)
/ship  → gates verdes → PR                   (hooks/ + skills/quality-gates)
```

---

## Archetype-Guided Agent Workflows

Todo trabalho roda em um de cinco **arquétipos** (Boris Cherny). Eles não são papéis novos —
são *modos* sobre as skills/agents/commands que já existem. O modo decide **qual skill lidera**
e **quão estritos são os gates**; as diretivas primárias (grafo-first, Ponytail, RTK, métricas,
humano-no-loop) valem em todos.

Roteie um a tarefa com a skill `archetype-orchestrator`, ou `make loop` (listar) / `make loop-<nome>` (entrar).

| Arquétipo | Foco | Skills que lideram | Agents | Commands | Gates | Loop |
|---|---|---|---|---|---|---|
| **Prototyper** | explorar rápido, alto churn | `planning`, `ddd-agent-skill` | staff-architect (taste) | `/spec`, `/plan` | frouxos (1 check) | `loops/prototyper.md` |
| **Builder** | protótipo → produção | `implementation`, `uncle-bob-discipline`, `clean-code-enforcement`, `test-review`, `quality-gates` | backend/database/qa-reviewer | `/build`, `/test` | duros (`make quality`) | `loops/builder.md` |
| **Sweeper** | deletar, simplificar, cortar tokens | `ponytail`, `rtk-integration`, `graphify` | — | — | comportamento inalterado | `loops/sweeper.md` |
| **Grower** | iterar por métricas reais / PMF | `measurement-driven-improvement`, `quality-gates` | staff-architect (Grower) | `/test` (evals) | tendência tem de melhorar | `loops/grower.md` |
| **Maintainer** | segurança, confiabilidade, escala | `security-review`, `quality-gates`, `pr-review` | security-reviewer, staff-architect (Maintainer) | `/review`, `/ship` | os mais estritos | `loops/maintainer.md` |

`graphify` é transversal — todo arquétipo consulta o grafo antes de leituras profundas.
**Sweeper auto-ativa RTK + Graphify.** Cada `skills/*/SKILL.md` declara seu arquétipo primário
na linha `> **Archetype:**`.

### Exemplo end-to-end (o ciclo completo)

Feature: *"cachear respostas de uma API externa."*

```
1. Prototyper   make loop-exploration
   /spec → /plan. Query no grafo p/ achar o call site. Rascunho em sandbox/,
   caminho feliz só. Aprende: um lru_cache resolve? → sim. Descartar o resto.

2. Builder      make loop-implementation
   /build → @lru_cache(maxsize=1000)  # ponytail: stdlib; TTL só se medir que falha
   /test → teste primeiro; coverage + complexity + mutation verdes (make quality).

3. Sweeper      make loop-optimization   (RTK + Graphify auto)
   Grafo mostra um wrapper de cache duplicado morto → deletar. rtk gain reportado.
   make quality continua verde (comportamento inalterado).

4. Grower       make loop-growth
   make metrics-snapshot; hit-rate do cache vira métrica. make eval-diagnose
   se recorrer falha. Muda só o que a métrica pede; confirma que mexeu o número.

5. Maintainer   make loop-maintenance
   security-reviewer: a chave de cache vaza PII? make token-budget em workflow longo.
   make mcp-audit / skill-audit. Verde estável → ADR do "porquê".
```

Cada seta é um hand-off onde o **humano decide taste**. Pule etapas, nunca gates.

---

## Benefícios

- **Ponytail** — dev sênior preguiçoso: o menor código que funciona; questiona se algo precisa existir (YAGNI). Menos código = menos manutenção e menos contexto.
- **RTK** — comprime output de terminal (60–90% menos tokens); comandos rodam como `rtk <cmd>`.
- **Graphify** — grafo consultável de todo o codebase; agentes consultam em vez de reler arquivos.
- **Uncle Bob** — TDD, boundaries limpos, review por **métricas** (coverage/complexity/mutation), humano no loop para arquitetura.

A combinação: **output nível Staff** + **forte economia de tokens** (Ponytail menos código × RTK menos output × Graphify menos releituras) + **contexto inteligente** (o grafo é a memória).

---

## Community & Ecosystem

- **Graphify** (knowledge graph) — <https://github.com/safishamsi/graphify>
- **awesome-claude-skills** (Composio) — <https://github.com/composiohq/awesome-claude-skills>
- **agency-agents** — <https://github.com/agency-ai-solutions/agency-agents>

> Links do ecossistema não verificados neste ambiente — confirme antes de confiar.

## Como contribuir

1. Abra uma issue descrevendo o problema/ideia antes de um PR grande.
2. `make check` e `make quality` devem passar localmente.
3. Um skill/agent novo mora em `ai-development-framework/`; os symlinks (`.claude/`,
   `.codex/`, `.cursor/`) apontam pra lá — não edite os links.
4. Commits sem trailer de atribuição a IA.

---

## Próximos passos

1. `make setup` — ativa e conecta tudo (inclui Graphify).
2. Ajuste thresholds em `ai-development-framework/rules/quality-thresholds.md`.
3. `make quality` detecta o stack (JS/TS via `package.json`, Python via `pyproject/setup/pytest`) e roda só as ferramentas presentes; ajuste os comandos/thresholds em `ai-development-framework/hooks/ci-quality-gates.sh`. Sem stack/runner, ele pula e avisa (e falha em CI com `CI=1`) — não há gate verde falso.
4. `/graphify .` no agente — constrói o grafo (`graphify-out/graph.json`); `--neo4j`/`--falkordb` p/ exportar.
5. (Quando quiser CI) `make ci` e faça commit do workflow.

> ⚠ **RTK e Graphify são ferramentas de terceiros.** Os comandos seguem os docs do vendor mas
> **não foram verificados** neste ambiente. Confirme em cada repo antes de usar em produção/CI.
