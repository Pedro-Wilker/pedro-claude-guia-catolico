---
name: project-audit-fases-3-7
description: "Auditoria factual 2026-08-05 confirmou FASE 4 frontend + FASE 6 Blog + FASE 7 Campanhas implementadas além do que memoria dizia; gaps: S3, JobCategory/ArticleCategory separados, rotas PT-BR"
metadata: 
  node_type: memory
  type: project
  originSessionId: fb7c6f96-00a1-4d22-8f63-1d4a90bc43bc
---

Auditoria dos diretórios `backend/` e `frontend/` revelou divergências entre `memoria.md` e código real.

**Mais completas que declarado:**
- FASE 4 Jobs frontend: painel empresa `/painel/vagas` + admin `/admin/vagas` + 4 testes (api-jobs, schemas-jobs, formatters-jobs, job-card) — memoria dizia "pendente"
- FASE 6 Blog: backend completo (`Article`+`Comment`+rotas `/articles`) + frontend completo (`/blog`, `/blog/[slug]`, `/admin/artigos`, painel empresa CRUD, fixtures, 3 testes) — memoria dizia "5 fatias 6A→6E pendentes ~19h"; spec não foi seguida
- FASE 7 Campanhas: Campaign + Recipient + dispatch worker + 14 endpoints admin + wizard frontend

**Gaps reais:**
- `JobCategory` e `ArticleCategory` models separados AUSENTES (reusa `Category` via FK)
- Rotas em inglês (`/jobs`, `/articles`) — frontend PT-BR (`/vagas`, `/blog`); sem alias `/oportunidades` ou `/blog` no backend
- Upload S3 AUSENTE (filesystem local em `internal/storage/filesystem.go`)
- WA/IG em standby

**Estado real:** pós-FASE 7. Próximas: FASE 8 Pagamento (Stripe), FASE 9 Mobile, S3 upload.

**Why:** usuario pediu auditoria antes de retomar; memoria estava desatualizada.
**How to apply:** ao retomar, não confiar em "FASE 6 pendente" — está pronta. Próximas fases reais são 8 (pagamento) e 9 (mobile). S3 é gap ativo da FASE 5.

Relacionado: [[project-fase-5-finalizada]], [[project-fase-6-design]], [[project-fase-7-finalizada]], [[project-jobs-blog-backend-completo]]