---
name: project-fase-d-finalizada
description: "Fase D (mod #10) finalizada 2026-08-22 — 0 500s após validar UUID em 5 handlers"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3b1573dc-be02-4546-b8e0-938ab22678ee
  modified: 2026-08-23T00:48:48.915Z
---

Fase D do PRD 2026-08-22 entregue: inventário de rotas + probe 401/403/404/500 + 5 fixes de validação UUID.

**Bugs encontrados pelo probe:** 5 rotas retornavam 500 por UUID inválido → Postgres SQLSTATE 22P02 → Recovery middleware → 500.

**Fixes:** category.GetCompaniesByCategory, review.ListByCompany, banner_ad.TrackClick, job.ListByCompany, article_comment.ListApproved — todos com `uuid.Parse()` no início, retornando 400 se inválido.

**Pendência:** Middleware global `ValidateUUIDParam(name)` para evitar repetir esse padrão. Candidato para Fase E (próxima).

**Why:** Cliente via 500 sem contexto; bug silencioso que só aparecia em produção quando alguém colocava ID errado.
**How to apply:** Rodar `bash meu-guia-api/scripts/api-health-probe.sh` periodicamente. Todo novo handler com `:id` precisa de `uuid.Parse` no início.

Refs: [[project-prd-mods-2026-08-22]]
