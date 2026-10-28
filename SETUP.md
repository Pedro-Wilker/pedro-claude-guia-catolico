# SETUP — Pedro ↔ Claude Guia Católico

Diretório cross-device. Tudo aqui serve pra retomar o trabalho em qualquer máquina sem perder contexto.

## Estrutura

```
pedro-claude-guia-catolico/
├── SETUP.md              ← este arquivo (meta + como retomar)
├── SYNC-2026-10-27-cadastro-bairro-catalogo.md  ← snapshot mais recente (LER PRIMEIRO)
├── SYNC-2026-10-20-asaas8-real-e2e.md           ← snapshot anterior
├── progress-ledger.md    ← ledger de tasks (espelho de .superpowers/sdd/progress.md)
├── context.md            ← decisões críticas, LGPD, race conditions, findings
├── commands.md           ← comandos copy-paste (docker, test, commit, VPS)
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

Backend `main` = `205eef9c`, frontend `master` = `688cd8b` — ambos no ar (API na VPS, front na Vercel). Última entrega: **cadastro de empresa com bairro do catálogo (seleção obrigatória) + campo "Número do endereço"**. Sem código pendente; próximas trilhas: SEO (Search Console/Perfil Google/conteúdo) e UI do Asaas.

## Caminho dos repos (mudaram em 2026-10)

```bash
BACK="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/backend"
FRONT="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/frontend"
```

O caminho antigo `C:/Users/conta/OneDrive/Desktop/meu-guia/` não existe mais.
