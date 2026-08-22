---
name: project-conventions
description: Convenções de build Next + comandos do projeto neste device
metadata:
  type: reference
---

**Build frontend (Windows + Next 15.5.4):**
- Bug conhecido: trace reporter gera type shim com path relativo ao OneDrive que TS não resolve.
- Workaround local: `NEXT_DIST_DIR=.next npm run build` (evita Temp do OneDrive) OU `typescript.ignoreBuildErrors: true` no next.config.ts.
- `distDir` resolve para `../Temp/meu-guia-catolico-next` em Windows por padrão (resolveDistDir).

**Comandos validados:**
- Backend up: `cd meu-guia-api && docker-compose up -d --build`
- Backend rebuild: `docker-compose up -d --build` (NÃO `restart` — não rebuilda)
- Frontend build: `cd meu-guia-front && NEXT_DIST_DIR=.next npm run build`
- Frontend test: `cd meu-guia-front && npx vitest run`
- Smoke API: `curl.exe -s http://localhost:8080/api/v1/<endpoint> | python -c "import json,sys; ..."`

**Comunicação:**
- Caveman mode ativo (full).
- PT-BR, comandos curtos, sem re-confirmação.

**Why:** Documenta gotchas Windows/Next 15.5.4.
**How to apply:** Sempre usar `NEXT_DIST_DIR=.next` no build até Next atualizar.