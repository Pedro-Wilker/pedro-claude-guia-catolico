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

### 6. Registro único de models — `internal/models/registry.go` (2026-10-23)

`models.All()` é a **fonte única** da lista de models. `database.AutoMigrate` (produção) e `testutil.NewTestDB` (testes) consomem a mesma.

**Por que:** antes o AutoMigrate de produção tinha uma lista própria. Faltaram `consent_policies` (500 `SQLSTATE 25P02` no cadastro de cliente) e `contract_acceptances`/`service_orders` (500 `relation "contract_acceptances" does not exist` no cadastro de empresa) — **os testes passavam porque o `testutil` tinha a lista completa**. Duas listas = drift garantido.

**Guardas:** `TestAll_CobreTodoStructDoPacote` (parse do pacote com `go/parser` + `os.ReadDir`, confere que todo struct está em `All()`) e `TestAutoMigrate_CriaTabelasCriticas` (sqlite in-memory).

**Regra: nunca duplicar a lista de models em dois lugares.**

### 7. Bairro = linha do catálogo, não texto livre (2026-10-23)

Cadastro de empresa: o bairro tem que existir em `neighborhoods` e pertencer à cidade informada. A tela deixa **digitar para buscar**, mas o valor gravado tem que ser uma linha do catálogo — bairro digitado à mão vira empresa invisível nos filtros por bairro (o slug não resolve).

- `resolveNeighborhood(db, city, name, slug)`: **slug do cliente tem precedência** (é a chave que o dropdown entregou); sem slug, deriva o slug do nome; a busca é presa na `region_id` da cidade (dois "Centro" em cidades diferentes não podem se misturar).
- `ValidateNeighborhood`: bairro fora do catálogo / inativo / de outra cidade → erro. **Valida DEPOIS do contrato** (erro de contrato é 422 com código próprio; a ordem não pode virar o erro que o usuário vê).
- `ApplyNeighborhood`: grava nome+slug da **linha do catálogo** (o que o usuário digitou e o que o dropdown mostrou podem divergir em caixa/acento).
- **Rua continua texto livre** (com sugestão): só 10 dos 43 bairros têm ruas catalogadas (30 ruas). Rua digitada fora da lista é mantida.
- `neighborhood_slug` tem unique index **composto** `(slug, region_id)` — o slug sozinho não identifica o bairro.

### 8. Pipeline de deploy (2026-10-23)

- **Backend**: `main` → GH Actions "Deploy Backend" → vet + test → build linux/amd64 → scp do binário + `docs/contracts/v1.pdf` → `/usr/local/bin/meu-guia-api` → `systemctl restart meu-guia-api` → health check.
- **Frontend**: `master` → GH Actions "Verificar Frontend" (typecheck + test + build). **O deploy é da Vercel**; a VPS hospeda só a API. (Antes era PM2 na VPS — trocado.)
- `AutoMigrate` roda **em todo boot, inclusive produção** → schema do prod acompanha o código no deploy.
- PDF do contrato marcado como binário no `.gitattributes` — o SHA-256 é o que o usuário assina; CRLF do Windows mudaria o hash.

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
| Raiz do monorepo | `C:\Users\conta\OneDrive\Documentos\projeto\artonbyte\meu-guia-catolico\` |
| Plan principal | `backend/docs/superpowers/plans/2026-09-13-planos-contrato.md` |
| Spec | `backend/docs/superpowers/specs/2026-09-13-prd-planos-contrato.html` |
| Contrato Word | `C:\Users\conta\OneDrive\Documentos\projeto\artonbyte\meu-guia-catolico\Contrato Meu Guia Catolico - Revisado.docx` |
| Contrato TXT | `C:\Users\conta\OneDrive\Documentos\projeto\artonbyte\meu-guia-catolico\Contrato Meu Guia Catolico - Revisado.txt` |
| PDF asset | `backend/docs/contracts/v1.pdf` (vai no deploy para `/opt/meuguia/docs/contracts/v1.pdf`) |
| Registro de models | `backend/internal/models/registry.go` ← **fonte única**, não duplicar |
| Migrations back | `backend/migrations/000015..000017*.sql` |
| Models back | `backend/internal/models/` |
| Services back | `backend/internal/services/` (endereço: `company_address.go`) |
| Handlers back | `backend/internal/handlers/` |
| Routes | `backend/internal/routes/routes.go` |
| Test util | `backend/internal/testutil/db.go` + `migrate.go` |
| Front types | `frontend/lib/types.ts` |
| Front api | `frontend/lib/api.ts` |
| Combobox (novo) | `frontend/components/ui/combobox.tsx` |
| Cascata de endereço | `frontend/components/dashboard/address-cascade.tsx` |
| Front pages | `frontend/app/(public)/termos/`, `(public)/privacidade/`, `(public)/termos-aceite/`, `(provider)/empresa/os/`, `(admin)/admin/empresas/[id]/os/novo` |

## Modelo de agents

- **Implementer**: Haiku (transcrição + 1-3 arquivos)
- **Reviewer**: Haiku (review mecânico spec + quality)
- **Complexos**: Sonnet (multi-arquivo + integration)

Brief file: `task-N-brief.md`. Report: `task-N-report.md`. Review: `tasks-N-review.md` (note plural). Path: `.superpowers/sdd/`.

## Docker / Ambiente

- Windows 11, Git Bash, Docker Desktop
- Raiz do monorepo: `C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico` (o caminho antigo `Desktop/meu-guia` não existe mais)
- Padrão: `MSYS_NO_PATHCONV=1 docker run --rm -v "$BACK":/src -w /src golang:1.24-alpine sh -c "COMMAND 2>&1"` — mas Go 1.24 e Node 20 locais funcionam, suíte roda direto
- Test em SQLite in-memory (`testutil.NewTestDB`)
- Branch protection: NÃO commitar em main sem verificar — mas como Pedro já está em main, ok prosseguir

## Acesso ao servidor

- VPS Contabo `144.91.86.204` (Ubuntu 24.04), systemd `meu-guia-api`, binário em `/usr/local/bin/meu-guia-api`, contrato em `/opt/meuguia/docs/contracts/v1.pdf`
- SSH: usar `~/.ssh/gh_actions_deploy` (mesma chave do CI, **sem passphrase**). A chave pessoal `~/.ssh/id_ed25519` tem passphrase e o `ssh-agent` não está rodando nesta máquina.
- Banco de produção: `meuguiadb` (via `sudo -u postgres psql -d meuguiadb` no host)
- `gh` CLI **não** está instalado — token via credential helper do git (`printf 'protocol=https\nhost=github.com\n\n' | git credential fill`)

## Lembretes

- ❌ NÃO usar `gen_random_uuid()` — usar `uuid()` (PG) ou `lower(hex(randomblob(16)))` (SQLite via migrate.go) ou `uuid.New().String()` (Go)
- ❌ NÃO criar arquivo de teste em `package models` se ele importar testutil (cycle) — usar `package models_test`
- ✅ Co-Authored-By em todo commit
- ✅ TDD: red → green → refactor → commit
- ✅ Subagent fresh por task + reviewer entre tasks
