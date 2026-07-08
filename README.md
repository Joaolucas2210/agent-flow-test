# AI Development Framework

**Staff-level agentic development for Claude Code · Cursor · Codex**

![Ponytail](https://img.shields.io/badge/Ponytail-minimalism-6e56cf)
![Graphify](https://img.shields.io/badge/Graphify-knowledge%20graph-2ea043)
![RTK](https://img.shields.io/badge/RTK-token%20killer-e0562b)
![Uncle Bob](https://img.shields.io/badge/Uncle%20Bob-discipline-1f6feb)
![Clean Code](https://img.shields.io/badge/Clean%20Code-metrics%20%3E%20line--by--line-555)

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
| Review linha-a-linha não escala | **Quality Gates** (métricas) | coverage/complexity/mutation como gate |

---

## Como o projeto está organizado

```
agent-flow-test/                     ← raiz: entrypoints + config das ferramentas
├── setup-adf.sh                     # ativador (claude|codex|all) — links, hooks, Graphify, RTK
├── Makefile                         # task runner (make help)
├── README.md                        # este arquivo
├── AGENTS.md                        # config lida pelo Codex (fica na raiz de propósito)
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
└── .codex/                          # symlinks por-item p/ Codex (skills, prompts)
```

**Princípio da arquitetura:** o *core* (`ai-development-framework/`) é a única fonte de verdade;
`.claude/` e `.codex/` são só **symlinks** para ele. O `sandbox/` é o código sob teste, separado
do framework. Os entrypoints (`Makefile`, `setup-adf.sh`) vivem na raiz.

> GitHub Actions/CI está **fora do fluxo padrão** por enquanto. O workflow existe em
> `ai-development-framework/.github/workflows/` e pode ser posicionado depois com `make ci`.

---

## Instalação

### Opção 1 — Makefile (recomendado)

```bash
make setup            # ativação completa: links + hooks + Graphify + RTK (Claude + Codex)
make adf-claude       # só Claude Code (.claude/) + Graphify
make adf-codex        # só Codex (.codex/) + Graphify
make setup-graphify   # só o knowledge graph (pip install + install + build)
make check            # verifica ferramentas, sem alterar nada
```

`make` (ou `make help`) lista todos os targets:

| Target | O que faz |
| --- | --- |
| `make setup` | ativação completa (Claude + Codex + hooks + Graphify + RTK) |
| `make adf-claude` / `make adf-codex` | ativa para uma plataforma + Graphify |
| `make setup-graphify` | `pip install` + `graphify install --platform` + `graphify build` |
| `make check` | doctor: verifica git/graphify/rtk |
| `make quality` | roda os quality gates localmente |
| `make test-loop` | smoke-test: grafo + gates + `rtk gain` |
| `make hooks` | (re)instala o git pre-commit |
| `make ci` | (opcional) posiciona o workflow de CI |
| `make clean-links` | remove os symlinks do framework |

### Opção 2 — setup-adf.sh direto

Idempotente, nunca sobrescreve arquivos reais (só troca symlinks que ele mesmo cria):

```bash
./setup-adf.sh all       # Claude + Codex (default) — já instala e constrói o Graphify
./setup-adf.sh claude    # só .claude/  (--platform claude no Graphify)
./setup-adf.sh codex     # só .codex/   (--platform codex)
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

## Benefícios

- **Ponytail** — dev sênior preguiçoso: o menor código que funciona; questiona se algo precisa existir (YAGNI). Menos código = menos manutenção e menos contexto.
- **RTK** — comprime output de terminal (60–90% menos tokens); comandos rodam como `rtk <cmd>`.
- **Graphify** — grafo consultável de todo o codebase; agentes consultam em vez de reler arquivos.
- **Uncle Bob** — TDD, boundaries limpos, review por **métricas** (coverage/complexity/mutation), humano no loop para arquitetura.

A combinação: **output nível Staff** + **forte economia de tokens** (Ponytail menos código × RTK menos output × Graphify menos releituras) + **contexto inteligente** (o grafo é a memória).

---

## Próximos passos

1. `make setup` — ativa e conecta tudo (inclui Graphify).
2. Ajuste thresholds em `ai-development-framework/rules/quality-thresholds.md`.
3. Descomente as ferramentas do seu stack em `ai-development-framework/hooks/ci-quality-gates.sh`.
4. `/graphify .` no agente — constrói o grafo (`graphify-out/graph.json`); `--neo4j`/`--falkordb` p/ exportar.
5. (Quando quiser CI) `make ci` e faça commit do workflow.

> ⚠ **RTK e Graphify são ferramentas de terceiros.** Os comandos seguem os docs do vendor mas
> **não foram verificados** neste ambiente. Confirme em cada repo antes de usar em produção/CI.
