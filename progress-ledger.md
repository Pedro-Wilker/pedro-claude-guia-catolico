# Progress Ledger — espelho de `.superpowers/sdd/progress.md`

Snapshot mais recente: **2026-10-27**. Atualizar após cada task.

## Ciclo 2026-10-23 — CADASTRO + PRODUÇÃO — COMPLETO ✓

Sem plano formal (trabalho pedido direto pelo Pedro). Entregas, todas no ar:

| # | Entrega | Commit (back) | Commit (front) | Status |
|---|---------|---------------|----------------|--------|
| 1 | SEO: metadados por página, sitemap, robots, JSON-LD | — | `4db39b0` | ✅ |
| 2 | Auth/UI: links duplicados, olhinho de senha, botão Pix fora, textos dos cards, páginas `/termos` + `/privacidade` | — | `48c35f6` | ✅ |
| 3 | **500 cadastro de cliente** — `consent_policies` faltando + tx abortada | `3d55c913` | — | ✅ |
| 4 | **500 cadastro de empresa** — `contract_acceptances`/`service_orders` faltando → `models.All()` (registro único) | `59dccd00` | — | ✅ |
| 5 | Contrato: 404 do PDF + PDF binário no git e no deploy | `b197371e` `ff2485a7` | — | ✅ |
| 6 | Rotas anunciam o próprio link com esquema real | `752ecc59` | — | ✅ |
| 7 | **Cadastro de empresa**: bairro do catálogo (seleção obrigatória) + "Número do endereço" | `205eef9c` | `688cd8b` | ✅ |

Verificado live em produção: cadastro com bairro do catálogo → **201** (número do endereço gravado); bairro fora do catálogo → **400**. Contas de teste apagadas do prod.

Detalhe completo em `SYNC-2026-10-27-cadastro-bairro-catalogo.md`.

## PRD 2026-09-13 ADMIN COVERAGE — COMPLETO ✓

- Fase K audit (9 tasks): Tasks 1-9
- Fase I clientes (7 tasks): Tasks 11-17
- Fase J empresas (10 tasks): Tasks 18-28
- Tags: `fase-i-clientes`, `fase-j-empresas`, `fase-i-j-admin-coverage-2026-09-13`
- Tag final: `fase-i-j-admin-coverage-2026-09-13` (commit `11fa94b`)

## PRD 2026-09-13 PLANOS CONTRATO — branch main (Pedro mergeou)

Plan: `docs/superpowers/plans/2026-09-13-planos-contrato.md`

- [x] **Task 1**: migration seed 9 categorias + 52 sub (commit `a497235`, review APPROVED)
- [x] **Task 2**: test categoria seed + asset contrato PDF (commit `b5f7864`, review APPROVED)
- [x] **Task 3**: migration refactor plans + seed 7 planos (commit `04cc860`, review APPROVED)
- [x] **Task 4**: Price cents + stripe.go + plan_test.go (commit `fed1909`, review APPROVED)
- [x] **Task 5**: ContractAcceptance model + migration (commit `57f663d`, review APPROVED)
- [x] **Task 6**: ContractService + SHA-256 hash (commit `10c49571`, review pendente)
- [ ] **Task 7**: Handlers contract + rotas ← PRÓXIMA
- [ ] Task 8: Bloqueio signup empresa sem contract_acceptance
- [ ] Task 9: Migration service_orders + model
- [ ] Task 10: Service service_order + test flow
- [ ] Task 11: Handlers service_order + rotas
- [ ] Task 12: Migration subscription readjustment + extend model
- [ ] Task 13: Service subscription Cancel + ApplyReadjustment
- [ ] Task 14: Handlers subscription cancel + readjustment + rotas
- [ ] Task 15: Tipos front + api client (Planos/Contrato/OS)
- [ ] Task 16: Páginas termos-aceite + empresa/os + admin/os/novo
- [ ] Task 17: Componentes admin subscription + readjustment dialog
- [ ] Task 18: Banner aceite pendente no painel empresa
- [ ] Task 19: Bloqueio signup empresa redirecionando para termos-aceite
- [ ] Task 20: Atualizar PlanForm admin com novos campos
- [ ] Task 21: Suite final back + front + tag `planos-contrato-2026-09-13`

## Resumo executivo

- **6/21 tasks completas** (28%)
- Tasks 1-6: back-end foundational (migrations + models + services)
- Próxima metade (Tasks 7-14): back-end handlers + services + rotas
- Última metade (Tasks 15-21): front-end + integração + tag final

## Conventional commits usados

- `chore(migration):` — seeds e DDL
- `feat(model):` — novos models
- `feat(services):` — services
- `test(seed):` — testes de regressão de seed
- `fix(plan):` — fixes pós-review
- Co-Authored-By: Claude Code <noreply@anthropic.com> em todos
