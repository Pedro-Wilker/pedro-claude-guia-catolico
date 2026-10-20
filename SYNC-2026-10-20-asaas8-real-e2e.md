---
name: Sync 2026-10-20 Asaas-8 + E2E real validado
description: Asaas-8 ServiceOrder via Asaas + E2E real validado contra sandbox do Pedro + Frontend Asaas UI é o próximo
metadata:
  type: project
---

# Sync — 2026-10-20 Asaas-8 + E2E Real

## Estado atual

### Backend `meu-guia-api`
- Branch: `main`, working tree **clean**
- Last commit: `2cffd140` fix(asaas): Company.AsaasCustomerID + orphan payment guard + cancelled SO guard
- Suite: 9 packages PASS, zero regressões (handlers 17s + services 26s + outros)
- Docker container `meu-guia-api` up (healthy), Asaas webhook habilitado

### Commits Asaas (8 tasks, todas RELEASED)

| # | Commit | Descrição |
|---|--------|-----------|
| Asaas-1 | `46f608f5` | Cliente HTTP Asaas v3 + 5 testes mock |
| Asaas-2 | `0ffe62f4` | BillingEvent model + migration 000020 |
| Asaas-3 | `5e5be393` `785646d6` | POST /webhooks/asaas + bearer/HMAC + 6 testes |
| Asaas-4 | `0ebcc1c2` `6ff1e389` | BillingProcessor + Asaas fields em Subscription + 5+2 testes |
| Asaas-5 | `43768add` | cmd/asaas-smoke + PlatformFeePct/SplitPercentPtr |
| Asaas-6 | `49c62cc8` | docs/asaas-sandbox.md + scripts/asaas-e2e.sh |
| Asaas-7 | `ca3ef0d1` | **wire BillingProcessor em main.go + migration BillingEvent no AutoMigrate + env vars compose** |
| Asaas-8 | `7b9ce7f9` `2cffd140` | ServiceOrder via Asaas + Company.AsaasCustomerID + guards |

## E2E REAL validado 2026-10-03

Pedro criou conta Asaas sandbox própria (não do Décio). Fluxo completo testado:

1. **Smoke** `go run ./cmd/asaas-smoke` → customer `cus_000009328348` + subscription `sub_9w7kg29nqebfc0mi` (R$ 69.90 PIX mensal, split 10%)
2. **Pedro marca pagamento** no painel Asaas
3. **Webhook** chega `POST /webhooks/asaas` → HTTP 200 received
4. **Processor** roda → `billing_events.processed_at = true`
5. **Audit LGPD** art. 37 → `billing.payment.received` criado

**Bugs achados em E2E real que unit tests não pegaram:**
- Asaas-7: handler nunca recebia processor (main.go usava `NewAsaasWebhookHandler` sem processor) — webhook persistia mas processor não rodava
- Asaas-7: `BillingEvent` faltava no AutoMigrate → 500 `relation "billing_events" does not exist`
- Asaas-7: env vars Asaas não estavam no docker-compose → rota nem registrava

## Credenciais (sandbox Pedro, em `.env` gitignored)

- Asaas sandbox API key: `$$aact_hmlg_...` (prefixo `$$` no .env por causa do escaping do docker-compose)
- Wallet ID: `9bab3a43-d4c3-48c6-92bc-c8370a6b0acb`
- Webhook token (bearer): `whsec_ySwwzqPq1c412h8GgawAmaH4wSEWRXQezzGQa3MOq_M`
- Split: `ASAAS_PLATFORM_FEE_PCT=10`

**Contas demo frontend:**
- Admin: `admin@meuguiacatolico.com` / `admin123456`
- Cliente: `demo-cliente-1@meuguia.local` … `demo-cliente-6@meuguia.local` / `senha12345`
- Empresa: `padaria-feira@meuguia.local`, `colegio-santo@meuguia.local`, `livraria-domus@meuguia.local`, `restaurante-sabor@meuguia.local`, `viagens-tur@meuguia.local` … / `senha12345`

## Migrations aplicadas (000020-000023)

| Migration | Conteúdo |
|-----------|----------|
| 000020 | `billing_events` table + 3 indexes (event_id UNIQUE idempotência) |
| 000021 | `subscriptions` + asaas_customer_id / asaas_subscription_id / asaas_external_ref |
| 000022 | `service_orders` + asaas_payment_id / asaas_external_ref / billing_type |
| 000023 | `companies` + asaas_customer_id |

Todas aplicadas via `AutoMigrate` no startup (GORM lê struct) + DDL versionado em `migrations/`.

## Modelo de negócio confirmado (Pedro)

**Empresa paga 1x (subscription mensal) + pode pagar mais (ServiceOrder avulso).**

- Subscription = plano (Vitrine/Premium/etc) com N `BannerSlots` inclusos
- ServiceOrder = cobrança avulsa (banner extra, OS adicional, destaque temporário) via Asaas
- **Banners NÃO têm Asaas individual** — slots vêm inclusos na subscription
- Se quiser monetizar banner individual depois = novo model `BannerSubscription` (fora do escopo atual)

## Próximo: Frontend Asaas UI (Pedro escolheu entre MVP/completo — **pendente resposta**)

**MVP enxuto (3 itens, ~1 dia):**
1. `SubscriptionCard` (empresa) — status active/overdue/canceled + próxima cobrança + valor
2. `BillingEventsDashboard` (admin) — tabela `billing_events` com filtros
3. Usar `POST /admin/service-orders/:id/asaas-checkout` (Asaas-8, já existe)

**Completo (7 itens, 1-2 dias):**
4. `PaymentHistoryTable` (empresa)
5. Banner "Pagamento pendente" (empresa, se overdue)
6. Botão "Comprar destaque extra" (empresa, modal)
7. `PaymentLinkModal` (admin)

**APIs backend que faltam:**
- `GET /admin/billing/events?event=&processed=&from=&to=` — NOVO
- `GET /company/subscription/payment-link` — NOVO (consulta última fatura Asaas)

## Débitos pendentes

| ID | Descrição | Owner |
|----|-----------|-------|
| F1 | Production Asaas API key + wallet ID do Décio | Décio |
| F2 | % taxa split final (sandbox=10%) | Décio/negociação |
| F3 | Tag `planos-contrato-2026-09-13` + `asaas-sandbox-2026-09-23` push GitHub | Pedro decide |
| F4 | Planos-contrato F1 `GET /admin/subscriptions?company_id=...` | Pedro decide |
| F5 | Asaas ngrok tunnel ou DNS prod pro webhook | Pedro decide infra |
| F6 | Stripe coexist decisão (manter/remover) | Pedro decide |

## WIP — Push tags opcional

```bash
cd C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api
git tag -a asaas-sandbox-2026-10-20 -m "Asaas 1-8 RELEASED + E2E real validado"
git push origin asaas-sandbox-2026-10-20
```