---
name: PRD planos-contrato release 2026-09-16
description: PRD 2026-09-13 planos-contrato released com tag local + critical gaps resolvidos via Tasks 19b/20b
metadata:
  type: project
---

# Cross-Device Sync — 2026-09-16 Final

PRD `2026-09-13-planos-contrato` RELEASED em 2026-09-16. Tag `planos-contrato-2026-09-13` aplicado LOCALMENTE no monorepo (push pendente para GitHub — Pedro decide).

## Status final por task (21 + 2 fix)

### Backend (Tasks 1-14) — `meu-guia-api`
- 9 packages 100% PASS, zero regressões
- Last commit: `b706aac` (auth inline aceite)
- Migration `000019` (subscription readjustment) não roda em testutil SQLite por design (isSeedOnly filter)

### Frontend (Tasks 15-20) — `meu-guia-front`
- vitest 253/253 PASS (41 test files)
- tsc 0 erros paths novos
- Last commit: `b5fb44c` (PlanForm migration net -254)

### Fix tasks (19b, 20b)
- 19b: signup empresa envia `contract_version` + `contract_hash` (commit `a3333c0`)
- 20b: PlanoFormModal migrado para PlanForm standalone (commit `b5fb44c`)

## Decisões críticas

Pedro escolheu via AskUserQuestion: **"Criar Tasks 19b/20b + suite + tag"**.

Alternativas rejeitadas: tag com gaps, rollback, suite+tag sem gaps.

## Known follow-ups (pos-tag)

| ID | Descrição | Owner |
|----|-----------|-------|
| F1 | Backend `GET /admin/subscriptions?company_id=...` | Pedro decide |
| F2 | `Subscription.amount` reais vs cents padronização | Pedro decide |
| F3 | Provider sidebar link `/empresa/os/*` | Task 16 C2 menor |

## WIP — Pedro pode escolher push do tag

```bash
cd C:/Users/conta/OneDrive/Desktop/meu-guia
git push origin planos-contrato-2026-09-13
```
