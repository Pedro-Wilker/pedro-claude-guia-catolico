---
name: project-fase-d-finalizada
description: "Fase D (mod #10) finalizada 2026-08-22 — inventário rotas, probe 401/403/404/500, 5 fixes de UUID em handlers, 0 500s restantes"
metadata:
  type: project
---

Fase D (mod #10) do PRD 2026-08-22 entregue. Inventário + probe + 5 fixes de validação UUID.

**Entregue:**
- `meu-guia-api/cmd/routes-inventory/main.go` — parser Go que rastreia stack de grupos, gera CSV com path completo.
- `meu-guia-api/scripts/api-health-probe.sh` — login 3 roles + percorre matriz, testa 401/403/404/500, gera relatório.
- `docs/superpowers/specs/2026-08-22-api-health-matrix.csv` — 134 rotas anotadas (auth, role, expected_status por role).
- `docs/superpowers/specs/2026-08-22-api-health-report.md` — relatório final.
- `docs/superpowers/plans/2026-08-22-fase-d-api-health.md` — plano TDD.

**Fixes aplicados (TDD red-green):**
- `category.go:GetCompaniesByCategory` — uuid.Parse(id) → 400
- `review.go:ListByCompany` — uuid.Parse(companyId) → 400
- `banner_ad.go:TrackClick` — uuid.Parse(id) → 400
- `job.go:ListByCompany` — uuid.Parse(companyId) → 400
- `article_comment.go:ListApproved` — uuid.Parse(articleID) → 400

**Causa raiz comum:** Postgres rejeita UUID malformado (SQLSTATE 22P02), Recovery middleware convertia em 500.

**Resultado final:** 0 rotas retornam 500. Restantes 83 "inesperados" são artefatos da matrix (404 para sentinel 999999, 400 para POST sem body, 401 por rate limit).

**Pendência sistêmica:** Criar middleware `ValidateUUIDParam(name string)` para evitar validação repetida em cada handler. **Fora do escopo Fase D** — candidato para próxima fase.

**Why:** Encontrar 500s latentes que afetavam produção (cliente vê erro 500 sem entender).
**How to apply:** Rodar `bash scripts/api-health-probe.sh` em qualquer momento para baseline. Adicionar UUID validation a QUALQUER novo handler que recebe `:id`.

**Commits:**
- 22842d0 — feat(api): Fase D tools — inventory + health probe
- 560e29b — fix(api): valida UUID em handlers — 400 em vez de 500
- 2024b8b — fix(api): UUID validation em mais 3 handlers — 400 em vez de 500
