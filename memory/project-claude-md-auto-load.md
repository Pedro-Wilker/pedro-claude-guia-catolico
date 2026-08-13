---
name: project-claude-md-auto-load
description: "CLAUDE.md na raiz lista 5 .md auto-load (README, REFERENCIAL, ANALISE, PADROES, memoria); logs ficam fora"
metadata: 
  node_type: memory
  type: project
  originSessionId: fb7c6f96-00a1-4d22-8f63-1d4a90bc43bc
---

CLAUDE.md criado em 2026-08-05 na raiz do projeto. Define que toda sessão lê automaticamente: `README.md`, `REFERENCIAL_SISTEMA.md`, `ANALISE_SISTEMA.md`, `PADROES_DESENVOLVIMENTO.md`, `memoria.md`. Logs runtime (`loglast.md`, `erro.md`) ficam fora do auto-load — só sob pedido.

**Why:** usuário pediu como padrão não precisar pedir esses arquivos toda vez.
**How to apply:** em qualquer task, ler esses 5 arquivos antes de agir se ainda não foram lidos nesta sessão. Se contexto rolou/sumiu, reler.