# AI Development Framework Roadmap

Data: 2026-07-08

## Diagnostico

Este projeto ja tem uma tese clara: desenvolvimento com IA precisa de contexto controlado, verificacao executavel, revisao por metricas e economia de tokens. A arquitetura tambem esta no caminho certo: `ai-development-framework/` e o core, enquanto `.claude/`, `.codex/` e `.cursor/` sao adaptadores/symlinks para ferramentas diferentes.

O ponto fraco atual nao e falta de ideias; e falta de fechamento operacional. Muitos gates existem como contrato em docs e skills, mas ainda nao sao medidos de verdade no fluxo padrao. `make quality` passa mesmo com coverage, mutation, complexidade e ciclos comentados. O grafo tambem esta stale: `graphify-out/GRAPH_REPORT.md` foi gerado no commit `59e5a3b3`, enquanto o HEAD local inspecionado era `4b05bd97015cee6251fb83fa2735a9ce217c2cc3`.

## Referencias Externas

- Anthropic, "Building effective agents": comecar simples, usar workflows previsiveis antes de agentes autonomos, adicionar complexidade so quando melhora resultados medidos. Tambem reforca ground truth via ambiente, testes, tool feedback e human checkpoints. Fonte: https://www.anthropic.com/engineering/building-effective-agents
- Anthropic, "Model Context Protocol": MCP resolve integracao N x M entre modelos e fontes de dados, mas deve ser tratado como superficie de seguranca, nao como atalho irrestrito. Fonte: https://www.anthropic.com/news/model-context-protocol
- Claude Code best practices: explore first, plan, implement, verify; hooks sao deterministas; skills devem ser carregadas sob demanda para nao inflar contexto. Fonte: https://code.claude.com/docs/en/best-practices
- OpenAI Codex best practices: prompts efetivos declaram objetivo, contexto, restricoes e criterio de pronto; `AGENTS.md` e orientacao duravel; loops de melhoria devem usar traces, feedback, evals e handoff implementavel. Fontes: https://developers.openai.com/codex/learn/best-practices, https://developers.openai.com/codex/guides/agents-md, https://developers.openai.com/cookbook/examples/agents_sdk/agent_improvement_loop
- SWE-bench e SWE-bench Verified: agentes de software precisam lidar com contexto longo, multiplos arquivos e ambiente executavel; avaliacoes precisam ter tarefas bem especificadas e harness confiavel. Fontes: https://arxiv.org/abs/2310.06770, https://openai.com/index/introducing-swe-bench-verified/
- SWE-Skills-Bench: skills so ajudam quando sao especializadas, compativeis com o contexto e verificadas por criterios executaveis; muitas skills aumentam tokens sem melhorar pass rate. Fonte: https://arxiv.org/abs/2603.15401
- Estudos de seguranca MCP: MCP introduz riscos especificos como tool poisoning, execucao maliciosa e exfiltracao; scanners e allowlists devem vir antes de adocao ampla. Fontes: https://arxiv.org/abs/2506.13538, https://arxiv.org/abs/2504.03767
- Context engineering: a disciplina relevante nao e escrever prompts melhores isoladamente, e entregar a informacao, ferramentas, estado e formato certos no momento certo. Fontes: https://simonwillison.net/2025/jun/27/context-engineering/, https://www.philschmid.de/context-engineering

## Principios Para o Roadmap

1. Fechar o ciclo primeiro: todo comando importante precisa produzir sinal verificavel.
2. Medir antes de automatizar: sem baseline de qualidade, token cost e graph freshness, autonomia so acelera erro.
3. Skills poucas e especializadas: cortar ou fundir skills que so repetem principios genericos.
4. MCP com seguranca por padrao: nenhum servidor MCP novo sem inventario, permissao minima e auditoria.
5. Um core, adaptadores finos: evitar divergencia entre Claude, Codex e Cursor.

## Roadmap

### Fase 0 - Estabilizar o contrato atual

Objetivo: fazer o que ja esta prometido realmente funcionar.

Features:
- `make quality` real por stack detectado:
  - JS/TS: `npm test`, `npm run lint`, `npx madge --circular`, `npx stryker` quando configurado.
  - Python: `pytest`, `coverage`, `radon/lizard`, `mutmut` quando configurado.
  - fallback honesto: se nao houver runner, falhar em modo CI ou emitir aviso local configuravel.
- `make graph-check`: comparar commit do `graphify-out/GRAPH_REPORT.md` com `git rev-parse HEAD` e reportar stale.
- `docs/metrics/history.csv`: snapshot por ship com coverage, mutation, complexity, cycles, graph freshness e `rtk gain`.
- Corrigir drift de documentacao: README e Makefile ainda divergem em partes do uso real de Graphify.

Arquivos provaveis:
- `Makefile`
- `ai-development-framework/hooks/ci-quality-gates.sh`
- `ai-development-framework/hooks/pre-commit`
- `ai-development-framework/rules/quality-thresholds.md`
- `ai-development-framework/docs/metrics/history.csv`
- `README.md`

Validacao:
- `make check`
- `make quality`
- `make graph-check`
- um teste de fixture pequeno em `sandbox/` para provar que gate falha quando deveria.

### Fase 1 - Observabilidade e evidencia

Objetivo: transformar claims em dados.

Features:
- `make metrics-snapshot`: coleta metricas locais e anexa em CSV/JSON.
- `make rtk-report`: salva ganho de token por comando sem depender so do output interativo.
- `graph-hit-rate`: registrar quando uma tarefa usou `graphify query` antes de abrir arquivos grandes.
- Template de PR com tabela obrigatoria: tests, gates, graph freshness, token cost, riscos.

Arquivos provaveis:
- `Makefile`
- `ai-development-framework/hooks/ci-quality-gates.sh`
- `ai-development-framework/skills/measurement-driven-improvement/SKILL.md`
- `ai-development-framework/skills/pr-review/SKILL.md`
- `.github/pull_request_template.md`

Validacao:
- rodar snapshot duas vezes e garantir append idempotente.
- confirmar que PR template nao exige dados impossiveis em projetos pequenos.

### Fase 2 - Skill governance

Objetivo: evitar que o framework vire uma colecao grande de instrucoes redundantes.

Features:
- `make skill-audit`: lista skills, tamanho, overlap de palavras-chave e referencias a arquivos inexistentes.
- Metadata obrigatoria em toda skill: objetivo, quando usar, quando nao usar, validacao esperada.
- Suite de smoke prompts: tarefas pequenas que verificam se skills carregam e produzem saida no formato esperado.
- Politica de depreciacao: skill generica sem ganho medido vira regra comum ou e removida.

Arquivos provaveis:
- `ai-development-framework/skills/*/SKILL.md`
- `ai-development-framework/rules/token-optimization.md`
- `ai-development-framework/docs/skill-governance.md`

Validacao:
- `make skill-audit`
- fixture com uma skill invalida para provar que o auditor falha.

### Fase 3 - MCP seguro e util

Objetivo: conectar ferramentas externas sem abrir uma superficie de ataque ampla.

Features:
- Inventario MCP em `ai-development-framework/mcp/servers.json`.
- Allowlist por servidor: comandos, recursos, escopos e variaveis permitidas.
- `make mcp-audit`: scanner estatico simples para detectar servidores sem allowlist, comandos shell amplos, acesso a secrets e descricao ambigua de tools.
- Guia de threat model para MCP: private data + untrusted content + external communication precisa de revisao humana.

Arquivos provaveis:
- `ai-development-framework/mcp/servers.json`
- `ai-development-framework/docs/mcp-security.md`
- `ai-development-framework/hooks/ci-quality-gates.sh`

Validacao:
- fixture com MCP inseguro bloqueado.
- fixture com MCP local read-only aceito.

### Fase 4 - Agent improvement loop

Objetivo: evoluir o framework com traces, evals e regressao controlada.

Features:
- `docs/evals/`: casos de aceitacao para comandos `/spec`, `/plan`, `/build`, `/review`, `/ship`.
- `make eval-agent-flow`: roda prompts fixture em modo nao interativo quando a ferramenta suportar.
- `docs/traces/`: amostras anonimizadas de runs reais, com resultado, falha e correcao.
- Handoff padronizado: cada falha de eval gera uma proposta pequena de mudanca em skill/hook/doc.

Arquivos provaveis:
- `ai-development-framework/docs/evals/*.md`
- `ai-development-framework/docs/traces/`
- `Makefile`
- skills e commands especificos que falharem nos evals.

Validacao:
- evals devem falhar antes de uma melhoria e passar depois.
- nenhuma melhoria sem evidencia em trace/eval.

### Fase 5 - Produto e distribuicao

Objetivo: sair de repo local para framework instalavel e versionado.

Features:
- `adf doctor`: CLI fina para check, install, link, graph-check e quality.
- Releases versionadas do core.
- Compatibilidade declarada por plataforma: Claude, Codex, Cursor.
- Exemplos completos: repo JS, repo Python e monorepo com graph stale + gates.
- Docs de migracao entre versoes.

Arquivos provaveis:
- `setup-adf.sh`
- `Makefile`
- `ai-development-framework/docs/install.md`
- `ai-development-framework/docs/releases.md`

Validacao:
- install limpo em diretorio temporario.
- idempotencia: rodar setup duas vezes nao altera arquivos reais.
- rollback documentado.

## Ordem Recomendada

1. Fase 0: gates reais e graph freshness.
2. Fase 1: historico de metricas.
3. Fase 2: auditor de skills.
4. Fase 3: MCP seguro.
5. Fase 4: eval loop.
6. Fase 5: CLI/distribuicao.

## Riscos

- Automacao antes de verificacao: o projeto pareceria mais avancado, mas com menos confianca.
- Skills demais: aumenta custo de contexto e pode piorar resultado, como indicado pelo SWE-Skills-Bench.
- MCP sem threat model: risco de exfiltracao, prompt injection e execucao indevida.
- Claims nao medidos: percentuais de economia de tokens/codigo devem virar metricas locais ou ficar explicitamente rotulados como referencias externas.

## Primeiro Slice

Implementar Fase 0 em uma PR pequena:

1. Adicionar `make graph-check`.
2. Fazer `make quality` falhar em CI quando nao houver runner real configurado, mantendo modo local informativo se necessario.
3. Criar `docs/metrics/history.csv` com cabecalho.
4. Atualizar README com estado honesto: o framework tem contratos e alguns checks ativos, mas quality gates completos ainda dependem da configuracao do stack.

Definition of done:
- `make check` passa.
- `make graph-check` reporta stale no estado atual.
- `make quality` nao pode dizer "all gates green" quando os gates principais estao comentados.
- README nao promete gate que nao roda.
