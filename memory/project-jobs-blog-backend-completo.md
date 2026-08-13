---
name: project-jobs-blog-backend-completo
description: "FASE 4 (Jobs) + FASE 6 (Blog) backend pronto 2026-07-31: models/services/handlers/routes todos implementados. Faltam só painéis frontend + testes + seed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 78650904-d617-4da4-bb78-73ce28db0de7
---

# Jobs + Blog — Backend completo (2026-07-31, atualizado 2026-08-01)

## Jobs (FASE 4)
Backend: `models/job.go` (Job + JobApplication + JobCategory), `services/job.go` + `job_application.go`, `handlers/job.go` + `job_application.go`, rotas em `routes.go`.
Frontend: fixtures em `lib/fixtures/jobs.ts`, rotas `app/(public)/vagas/{page,[slug]/page}.tsx` criadas. Falta painel empresa + admin + integração API.

## Blog (FASE 6)
Backend: `models/article.go` (Article + ArticleComment), `services/article.go` + `article_comment.go`, `handlers/article.go` + `article_comment.go`, rotas em `routes.go`.
Frontend: rotas `app/(public)/blog/{page,[slug]/page}.tsx` já integradas com `api.articles.*` + `api.articleComments.*`.
Design aprovado 2026-08-01. Ver `project-fase-6-design.md` para plano completo (5 fatias, 6A→6E, ~19h).

**Why:** estado unificado de Jobs e Blog — backend já não é mais gap.
**How to apply:** Jobs podem seguir padrão similar ao Blog quando usuário priorizar. FASE 6 (Blog) é próxima fila de execução.
