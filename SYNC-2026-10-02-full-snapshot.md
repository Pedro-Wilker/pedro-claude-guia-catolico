---
name: Sync full snapshot 2026-10-02
description: Snapshot completo do monorepo — 2 PRDs released, tags locais, 5 tasks Asaas, débitos pendentes
metadata:
  type: project
---

# Sync Full Snapshot — 2026-10-02

## Monorepo state

### Backend `meu-guia-api`
- Branch: `main`
- Last commit: `49c62cc8` feat(docs): runbook + E2E script Asaas sandbox
- Working tree: clean
- Suite: 9 packages PASS, zero regressões

### Frontend `meu-guia-front`
- Branch: `main`
- Last commit: `b5fb44c` feat(admin): migrar PlanoFormModal para PlanForm com 4 campos novos
- Working tree: clean
- vitest: 253/253 PASS (41 test files), tsc 0 erros paths novos

### Cross-device repo `pedro-claude-guia-catolico`
- Last commit: `1c6357b` chore: add PRD planos-contrato release documentation for 2026-09-16
- Uncommitted: `SYNC-2026-09-24-asaas.md`

---

## PRDs RELEASED

### PRD `2026-09-13-planos-contrato` (RELEASED 2026-09-16)
- 21 tasks + 2 fix tasks (19b/20b)
- Tag local: `planos-contrato-2026-09-13` (push pendente)
- Backend commits: `b706aac` (auth inline aceite) + Tasks 11-14 service/handler
- Frontend commits: `b5fb44c` (PlanForm migration)
- Refs: [SYNC-2026-09-16-final.md](SYNC-2026-09-16-final.md)

### PRD `2026-09-23-asaas-sandbox` (RELEASED 2026-09-24)
- 6 tasks (cliente HTTP + webhook + processor + smoke + runbook)
- Tag local: `asaas-sandbox-2026-09-23` (push pendente)
- Backend commits: `46f608f5` (cliente) → `49c62cc8` (runbook)
- Stripe coexiste
- Refs: [SYNC-2026-09-24-asaas.md](SYNC-2026-09-24-asaas.md)

---

## Tasks Asaas — resumo

| # | Commit | Descrição |
|---|--------|-----------|
| Asaas-1 | `46f608f5` | cliente HTTP Asaas v3 + 5 testes mock |
| Asaas-2 | `0ffe62f4` | BillingEvent model + migration 000020 + idempotência UNIQUE |
| Asaas-3 | `5e5be393` `785646d6` | POST /webhooks/asaas + bearer/HMAC + 6 testes |
| Asaas-4 | `0ebcc1c2` `6ff1e389` | BillingProcessor + Asaas fields + 5 testes + 2 e2e |
| Asaas-5 | `43768add` | cmd/asaas-smoke + PlatformFeePct/SplitPercentPtr + helpers |
| Asaas-6 | `49c62cc8` | docs/asaas-sandbox.md PT-BR + scripts/asaas-e2e.sh bash |

**LGPD compliance Asaas:**
- art. 37 (audit): BillingProcessor gera `billing.payment.received` / `billing.subscription.canceled` em `audit_logs` em transação atômica
- art. 7 §V / art. 18 §5: não aplicáveis (pagamento = transação financeira, não envolve consentimento marketing nem WhatsApp)

---

## Smoke sandbox status (BLOQUEADO)

**Tentativa 2026-09-30:**
- Key `bd464309-2b8a-4103-a9d4-fa7ca0cf4168` (UUID) testada:
  - sandbox endpoint → **401 invalid_access_token**
  - prod endpoint → **404** (key rejeitada também)
- Conclusão: key revogada ou nunca válida

**PROD key do Décio (`$aact_prod_*`) coletada** mas NÃO testada contra prod (auto mode bloqueou POST real).

**Próximo passo aguardando Pedro:**
1. Pedro acessa senha própria `https://sandbox.asaas.com` (conta pessoal)
2. Menu → Integrações → API Key (sandbox) → copia
3. Cola aqui → eu rodo smoke + e2e

---

## Débitos PRD `planos-contrato` (F1-F3)

| ID | Descrição | Status | Prioridade |
|----|-----------|--------|-----------|
| F1 | `GET /admin/subscriptions?company_id=...` | Pendente backend | Média |
| F2 | `Subscription.amount` reais vs cents padronização | Pendente backend | Baixa |
| F3 | Provider sidebar link `/empresa/os/*` | Pendente frontend | Baixa |

---

## Débitos PRD `asaas-sandbox` (F1-F4)

| ID | Descrição | Status | Bloqueio |
|----|-----------|--------|----------|
| F1 | Production Asaas API key + wallet ID Décio | Aguarda Décio | Décio |
| F2 | % taxa split final (sandbox=10% default) | Aguarda negociação | Décio |
| F3 | ngrok tunnel dev OU DNS prod webhook | Aguarda Pedro | Pedro |
| F4 | Asaas-7 worker async (defesa webhook lento) | Após F1-F3 | - |

---

## Backlog priorizado (Pedro pode escolher)

### Curto prazo (não-depende Asaas real)

| # | Task | Escopo | Esforço |
|---|------|--------|--------|
| 1 | Planos-contrato F1 `GET /admin/subscriptions` | backend | pequeno |
| 2 | Asaas-7 worker async processar billing_events pending | backend | médio |
| 3 | LGPD art. 18 §5 WhatsApp descadastramento | backend+frontend | médio |
| 4 | Subscription create via Asaas (admin cria → Asaas sandbox) | backend | médio |
| 5 | Frontend painel empresa (status Asaas + próxima cobrança) | frontend | médio |
| 6 | Admin billing dashboard (lista billing_events) | frontend | médio |

### Médio prazo (depende Asaas real)

| # | Task | Bloqueio |
|---|------|----------|
| 7 | Promoção sandbox→prod (F1 + F3) | Décio key prod |
| 8 | Testes E2E reais via Asaas sandbox (Pedro tem senha) | Pedro sandbox key |
| 9 | Stripe coexist decisão (manter/remover) | Pedro decide |

---

## Smoke + E2E instructions (Pedro)

```bash
cd meu-guia-api
export $(grep -E '^ASAAS_' .env | xargs)
go run ./cmd/asaas-smoke           # cria no Asaas + imprime IDs
./scripts/asaas-e2e.sh              # verifica webhook→DB
```

---

## Push tags opcional

```bash
cd C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api
git push origin planos-contrato-2026-09-13
git push origin asaas-sandbox-2026-09-23
```

---

## WIP — Pedro próximos passos

1. **Imediato**: pegar sandbox API key da senha Asaas pessoal (`sandbox.asaas.com` → Integrações)
2. **Curto**: escolher próximo PRD do item 1-6 do backlog
3. **Médio**: Décio responder sobre prod key + % split
4. **Opcional**: push tags

---

## Arquivos importantes (paths absolutos)

- Backend root: `C:\Users\conta\OneDrive\Desktop\meu-guia\meu-guia-api`
- Frontend root: `C:\Users\conta\OneDrive\Desktop\meu-guia\meu-guia-front`
- Sync repo: `C:\Users\conta\OneDrive\Desktop\meu-guia\pedro-claude-guia-catolico`
- Memory: `C:\Users\conta\.claude\projects\c--Users-conta-OneDrive-Desktop-meu-guia\memory\`
- PRD plans: `C:\Users\conta\OneDrive\Desktop\meu-guia\.superpowers\plans\`
- PRD specs: `C:\Users\conta\OneDrive\Desktop\meu-guia\.superpowers\specs\`
- SDD reports: `C:\Users\conta\OneDrive\Desktop\meu-guia\.superpowers\sdd\`

---

## Última ação relevante (2026-09-30)

Pedro forneceu PRODUCTION API key do Décio (`$aact_prod_*`) mas **NÃO testada contra prod** (auto mode bloqueou POST real). Aguardando Pedro colar **SANDBOX key pessoal** (conta Asaas própria) pra smoke + e2e.