# CLAUDE.md — Meu Guia Católico

## Regra 0 — Cross-device sync

Se user falar **"onde paramos"** ou **"salvar progresso"**, fluxo cross-device aplica — ver `pedro-claude-guia-catolico/SETUP.md`.

## Auto-load padrão (toda sessão)

Ler estes arquivos da raiz ANTES de qualquer resposta, sem o usuário pedir:

| Arquivo | Propósito |
|---------|-----------|
| `README.md` | Visão geral, stack, quick start, status MVP |
| `REFERENCIAL_SISTEMA.md` | Regras de negócio, requisitos não-funcionais, roadmap |
| `ANALISE_SISTEMA.md` | Gap analysis site-referência vs implementação |
| `PADROES_DESENVOLVIMENTO.md` | Clean Code, SOLID, segurança, LGPD, convenções Go/React/Mobile |
| `memoria.md` | Changelog datado por fase, contexto acumulado |

NÃO ler automaticamente:
- `loglast.md`, `erro.md` — logs runtime, só sob pedido

## Memória persistente

Sessão usa `~/.claude/projects/.../memory/` para fatos cross-conversa. Antes de salvar, checar duplicata. Index em `MEMORY.md`.

## Comandos dev

- Backend up: `cd backend && docker-compose up -d --build` (porta 8080)
- Frontend up: `cd frontend && npm run dev` (porta 3000)
- Backend test: `cd backend && go test ./...`
- Frontend test: `cd frontend && npx vitest run`

## Modo comunicação

PT-BR, comandos curtos, aprovações em bloco, age sem re-confirmação. Caveman mode ativo por padrão.

## Estrutura monorepo

```
meu-guia-catolico/
├── backend/      # Go + Gin + GORM + PostgreSQL
├── frontend/     # Next.js + TypeScript
├── docs/         # specs superpowers
├── docs-cliente/ # docs PDF para cliente
└── README.md
```