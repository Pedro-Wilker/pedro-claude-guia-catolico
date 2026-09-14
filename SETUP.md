# SETUP — Pedro ↔ Claude Guia Católico

Diretório cross-device. Tudo aqui serve pra retomar o trabalho em qualquer máquina sem perder contexto.

## Estrutura

```
pedro-claude-guia-catolico/
├── SETUP.md              ← este arquivo (meta + como retomar)
├── SYNC-2026-09-14.md    ← snapshot detalhado do estado HOJE
├── progress-ledger.md    ← ledger de tasks (espelho de .superpowers/sdd/progress.md)
├── context.md            ← decisões críticas, LGPD, race conditions, findings
├── commands.md           ← comandos copy-paste (docker, test, commit)
└── resume.md             ← passo-a-passo pra retomar em outra máquina
```

## Quando usar

- **"onde paramos"** ou **"salvar progresso"** → gerar/atualizar SYNC-AAAAMM-DD.md
- **"retomar"** ou **"continuar de onde parou"** → ler SYNC mais recente + progress-ledger + context

## Regra 0 do projeto (CLAUDE.md)

Cross-device sync = este diretório. Salvar snapshot completo:
- branch + último commit
- tasks completas + próximas
- contexto crítico (decisões, findings, race conditions)
- paths de artifacts (briefs, reports, reviews)
- comandos prontos

## Estado atual (resumo 1 linha)

Branch `main`, commit `10c49571`. PRD `planos-contrato-2026-09-13` em andamento — **6/21 tasks completas** (Tasks 1-6 do plan). Próxima: **Task 7 (handlers contract + rotas)**.
