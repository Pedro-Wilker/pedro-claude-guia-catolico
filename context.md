# Context — Decisões críticas, findings, race conditions

Tudo que **não está no código ou no git** e que outro Claude (ou você) precisa saber pra retomar.

## LGPD Compliance (obrigatório)

PRD `2026-09-13-planos-contrato` materializa requisitos LGPD:

- **Art. 7 §V (consentimento inequívoco)**: ContractAcceptance com `contract_hash` (SHA-256 hex 64 chars) + `ip` (VARCHAR 45, IPv6-safe) + `user_agent` (VARCHAR 500) + `contract_version` (VARCHAR 20, ex: "v1"). Tabela `contract_acceptances` em migration `000017`.
- **Art. 37 (audit log)**: Toda escrita em PII/contrato gera `audit_logs`. Padrão já estabelecido nas Tasks admin-coverage.
- **Art. 18 §5 (mecanismo de descadastramento)**: **Placeholder para WhatsApp futuro** — provider não contratado ainda. Não implementar agora, deixar TODO em service.

## Decisões de arquitetura

### 1. SQLite/Postgres compat — `isSeedOnly` filter

`internal/testutil/migrate.go:64-90` rejeita migrations com `ALTER TABLE` em SQLite. Razão: SQLite in-memory não suporta todos os tipos (JSONB, custom).

**Implicação**: Migrations com DDL + seed misturados são puladas em SQLite. Workaround:
- DDL puro (CREATE TABLE): roda via `isSeedOnly` (passa) OU via `AutoMigrate` no struct
- Seed puro: roda em ambos
- Migrations mistas (DDL + INSERT): workaround = helper Go em `testutil/db.go`

Exemplo aplicado: migration `000016_refactor_plans.up.sql` tem `ALTER TABLE` + `INSERT INTO plans`. Em SQLite, é pulada. Helper `SeedPlans(t, db)` em `testutil/db.go` popula via GORM.

**Regra**: quando o plan pedir DDL + INSERT misturado, criar helper Go paralelo. NÃO split em 2 migrations (desalinharia numeração).

### 2. Price em cents (int64)

`Plan.Price` era `float64 decimal(10,2)` com valores seed em reais (6990 = R$6990). `stripe.go:85` fazia `int64(plan.Price * 100)` = 699000 cents = R$6990 (errado se intenção era R$69,90).

**Fix aplicado em Task 4 (commit `fed1909`)**:
- `Plan.Price float64` → `int64` cents (gorm bigint)
- Valores seed: 6990 = R$69,90, 5000 = R$50,00, etc.
- `stripe.go:85`: `int64(plan.Price * 100)` → `plan.Price` (direto)
- Migration `000016.up.sql`: `ALTER COLUMN price TYPE BIGINT USING (price::bigint)` (assumindo tabela vazia — TRUNCATE antes)
- Legacy seeds (`seed_demo.go`, `seed_banners.go`): ajustados para cents
- `handlers/admin.go:237`: API input `Price` agora int64 cents
- `plan_test.go`: novo, com `TestPlanCanonicalSeed` + `TestPlanPriceBRL`
- Helper `Plan.PriceBRL()` retorna "R$ 69,90" (usa `.` por convenção Go — pode polir pra `,` em task futura)

### 3. Contrato — 7 planos (não 8)

Contrato tem 8 serviços no Quadro-Resumo (vitrine + 3 destaque + alcance total + disparo nicho + criação logo + outro). Mapeamos para 7 Plan records (serviço "Outro" não vira Plan, é categoria sob demanda).

Planos:
1. **Assinatura Vitrine** — R$69,90 — `vitrine` — `free` cancel — min 30 dias
2. **Destaque 1ª linha** — R$50,00 — `destaque` — `proportional_multa` — min 90 dias
3. **Destaque 2ª linha** — R$30,00 — `destaque` — `proportional_multa` — min 90 dias
4. **Destaque 3ª linha** — R$20,00 — `destaque` — `proportional_multa` — min 90 dias
5. **Alcance Total** — R$0 (definido em OS) — `servico` — `free` — min 30 dias
6. **Disparo por Nicho** — R$0 — `servico` — `free` — min 30 dias
7. **Criação de Logotipo** — R$0 — `servico` — `free` — min 30 dias

### 4. Multa proporcional

Fórmula: `(min_end - now) / (min_end - start) * price`

Aplicada em cancelamento antecipado de planos `proportional_multa` (destaque). Implementar em Task 13 (service subscription Cancel).

### 5. IPCA reajuste — manual admin

Sem cron. Admin aplica manualmente via `ApplyReadjustment`. Log em `subscription.LastReadjustmentAt` + `subscription.ReadjustmentCount`. Implementar Tasks 12-14.

## Race condition com Pedro

Pedro (humano) trabalha em paralelo. Em Task 4,Pedro tinha commit `ef320329` "feat: refactor pricing..." fazendo parte do trabalho. Implementer detectou com `git log --oneline -5`, fez `git reset --soft HEAD~1` para recuperar mudanças, re-commitou limpo como `fed1909`.

**Lição**: SEMPRE verificar `git log --oneline -5` ANTES de começar implementer. Se houver commits não-esperados do Pedro entre o base commit e HEAD, parar e perguntar.

## Findings acumulados (não-bloqueantes)

### Task 1 (reviewer)
- `down.sql` 000015 não deleta 52 subcategorias órfãs (parent_id vira NULL via ON DELETE SET NULL). Fix sugerido: `DELETE FROM categories WHERE parent_id IN (SELECT id FROM categories WHERE slug IN (...))` antes do DELETE raiz. Não crítico.
- Subs usam icon genérico `'tag'` e cor herdada. Enrichment visual fica pra task futura.

### Task 2 (reviewer)
- `gofmt godoc nit` em `migrate.go:32-33` — continuação de bullet com indent extra.
- CRLF pré-existente em `db.go` (legado).
- Pre-flight Task 3: `isSeedOnly` rejeita ALTER TABLE → levou à decisão de helper Go (não split).

### Task 3 (reviewer)
- Implementer modificou `internal/models/subscription.go` (Plan struct está aqui, NÃO em `plan.go` que não existe).
- `db.Order("category, \"order\"")` em SQLite — funciona mas é frágil.
- `Price float64` issue → resolvido em Task 4.

### Task 4 (reviewer)
- `.gitignore` não cobre `.go-build-cache/` (pre-existente, não Task 4).
- `PriceBRL()` usa `.` ao invés de `,` pt-BR — pode polir com `golang.org/x/text/language/pt_BR`.

### Task 5 (reviewer)
- **F1 (resolvido em Task 6)**: `ContractAcceptance` sem `BeforeCreate` hook. Outros models têm. Implementer adicionou em Task 6.
- Sem newline final em up.sql/down.sql/contract_acceptance.go (cosmético).
- Sem `UNIQUE(user_id, contract_version)` — decisão de spec, idempotência fica no service.

## Paths importantes

| Item | Path |
|------|------|
| Plan principal | `docs/superpowers/plans/2026-09-13-planos-contrato.md` |
| Spec | `docs/superpowers/specs/2026-09-13-prd-planos-contrato.html` |
| Contrato Word | `C:\Users\conta\OneDrive\Desktop\meu-guia\Contrato Meu Guia Catolico - Revisado.docx` |
| Contrato TXT | `C:\Users\conta\OneDrive\Desktop\meu-guia\Contrato Meu Guia Catolico - Revisado.txt` |
| PDF asset | `meu-guia-api/docs/contracts/v1.pdf` (97 bytes, placeholder `%PDF-1.4`) |
| Migrations back | `meu-guia-api/migrations/000015..000017*.sql` |
| Models back | `meu-guia-api/internal/models/` |
| Services back | `meu-guia-api/internal/services/` |
| Handlers back | `meu-guia-api/internal/handlers/` |
| Routes | `meu-guia-api/internal/routes/routes.go` |
| Test util | `meu-guia-api/internal/testutil/db.go` + `migrate.go` |
| Front types | `meu-guia-front/lib/types.ts` |
| Front api | `meu-guia-front/lib/api.ts` |
| Front pages | `meu-guia-front/app/(public)/termos-aceite/`, `(provider)/empresa/os/`, `(admin)/admin/empresas/[id]/os/novo` |

## Modelo de agents

- **Implementer**: Haiku (transcrição + 1-3 arquivos)
- **Reviewer**: Haiku (review mecânico spec + quality)
- **Complexos**: Sonnet (multi-arquivo + integration)

Brief file: `task-N-brief.md`. Report: `task-N-report.md`. Review: `tasks-N-review.md` (note plural). Path: `.superpowers/sdd/`.

## Docker / Ambiente

- Windows 11, Git Bash, Docker Desktop
- Padrão: `MSYS_NO_PATHCONV=1 docker run --rm -v "/c/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api":/src -w /src golang:1.24-alpine sh -c "COMMAND 2>&1"`
- Test em SQLite in-memory (`testutil.NewTestDB`)
- Branch protection: NÃO commitar em main sem verificar — mas como Pedro já está em main, ok prosseguir

## Lembretes

- ❌ NÃO usar `gen_random_uuid()` — usar `uuid()` (PG) ou `lower(hex(randomblob(16)))` (SQLite via migrate.go) ou `uuid.New().String()` (Go)
- ❌ NÃO criar arquivo de teste em `package models` se ele importar testutil (cycle) — usar `package models_test`
- ✅ Co-Authored-By em todo commit
- ✅ TDD: red → green → refactor → commit
- ✅ Subagent fresh por task + reviewer entre tasks
