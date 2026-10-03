---
name: PRD asaas-sandbox release 2026-09-24
description: PRD 2026-09-23 asaas-sandbox released 6 tasks + tag local + F1-F4 followups pendentes Décio
metadata:
  type: project
---

# Cross-Device Sync — 2026-09-24 Asaas

PRD `2026-09-23-asaas-sandbox` RELEASED em 2026-09-24. Tag `asaas-sandbox-2026-09-23` aplicado LOCALMENTE no monorepo (push pendente para GitHub — Pedro decide).

## Status por task (6/6)

### Backend — `meu-guia-api`
- 9 packages 100% PASS, zero regressões
- Stripe coexiste (não removido)
- Last commit: `49c62cc8` (Asaas-6)

| # | Commit | Files |
|---|--------|-------|
| Asaas-1 | `46f608f5` | `internal/services/asaas.go` (172L) + `asaas_test.go` (113L, 5 tests) + `.env.example` + `cmd/api/main.go` |
| Asaas-2 | `0ffe62f4` | `internal/models/billing_event.go` + migration 000020 up/down + `testutil/db.go` |
| Asaas-3 | `5e5be393` `785646d6` | `internal/handlers/asaas.go` (163L) + `asaas_test.go` (6 tests) + `routes.go` + `cmd/api/main.go` |
| Asaas-4 | `0ebcc1c2` `6ff1e389` | `internal/services/billing_processor.go` + tests + migration 000021 + model sub fields + audit constants + handler integration + e2e tests |
| Asaas-5 | `43768add` | `cmd/asaas-smoke/main.go` + helpers no `asaas.go` + README |
| Asaas-6 | `49c62cc8` | `docs/asaas-sandbox.md` (103L PT-BR) + `scripts/asaas-e2e.sh` (84L bash) |

## Decisões

| Item | Escolha | Razão |
|------|---------|-------|
| Webhook auth | Bearer default + HMAC opcional | Asaas padrão; HMAC para defesa extra |
| Split % | `ASAAS_PLATFORM_FEE_PCT=10` (env) | Editável por Décio sem deploy |
| Idempotência | UNIQUE constraint + ProcessedAt guard | 2 camadas — Asaas reentrega + processor duplicado |
| Processor | Sync 5s timeout + log fail | Simples; Asaas não bloqueia em erro |
| Stripe | Coexiste | Não removido — Asaas é gateway adicional |
| LGPD audit | `billing.payment.received` etc em tx atômica | art. 37 compliance |

## Known follow-ups (Pedro decide ordem)

| ID | Descrição | Bloqueio |
|----|-----------|----------|
| F1 | Production Asaas API key + wallet ID | Aguarda Décio |
| F2 | % taxa split final | Aguarda negociação Décio |
| F3 | ngrok tunnel pra webhook dev OU túnel prod | Pedro decide infra |
| F4 | Asaas-7 worker assíncrono (se webhook começar lento) | Após F1-F3 |

## WIP — Push opcional do tag

```bash
cd C:/Users/conta/OneDrive/Desktop/meu-guia
git push origin asaas-sandbox-2026-09-23
```

## Smoke manual (Pedro)

```bash
cd meu-guia-api
export $(grep -E '^ASAAS_' .env | xargs)
go run ./cmd/asaas-smoke
# Salvar customer_id + subscription_id retornados em .env
```

## Pedro próximos passos

1. Substituir `ASAAS_API_KEY` sandbox → production (quando Décio mandar)
2. Atualizar ngrok URL → DNS público HTTPS produção
3. Decidir se Asaas-7 (worker async) é necessário após 1-2 semanas de uso
4. Push tag opcional
