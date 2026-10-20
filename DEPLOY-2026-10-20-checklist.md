---
name: Deploy 2026-10-20 checklist prod
description: Checklist completo para deploy prod Contabo — o que falta antes de subir, o que fazer no dia, smoke test pos-deploy
metadata:
  type: project
---

# Deploy Servidor Prod — Checklist

**Status:** backend RELEASED + E2E real validado, aguardando inputs Decio + infra para subir prod.

**Target ambiente:**
- VPS Contabo (hostinger/docker conforme decisão)
- Postgres prod (já provisionado? IP/porta na env)
- Domínio `api.meuguia.com.br` (assumindo, confirmar)

---

## Bloco 1 — Credenciais Asaas prod (BLOQUEIO — Decio)

| # | Item | Onde fica | Status |
|---|------|-----------|--------|
| B1.1 | `ASAAS_API_KEY` prod (`$aact_prod_...`) | Decio — pedir painel Asaas conta empresarial | ⬜ |
| B1.2 | `ASAAS_WALLET_ID` prod | Decio — mesmo lugar | ⬜ |
| B1.3 | Decisão % taxa split final (sandbox=10% default; prod geralmente maior 15-20%) | Pedro negocia | ⬜ |
| B1.4 | Webhook URL prod cadastrada no painel Asaas (`https://api.meuguia.com.br/webhooks/asaas`) | Pedro cadastra após DNS | ⬜ |

**Não subir prod sem B1.1 — vai dar `401 unauthorized` em qualquer POST.**

---

## Bloco 2 — DNS / Domínio (BLOQUEIO — infra)

| # | Item | Status |
|---|------|--------|
| B2.1 | Domínio `api.meuguia.com.br` apontando para IP do VPS Contabo | ⬜ |
| B2.2 | TLS/HTTPS via Caddy/Nginx (recomendado: Caddy auto-TLS) | ⬜ |
| B2.3 | DNS CAA record permitindo Let's Encrypt | ⬜ |
| B2.4 | Firewall liberando 80/443 (e fecha 8080) | ⬜ |

**Sem DNS público, Asaas painel não consegue chamar webhook.**

---

## Bloco 3 — Banco Postgres prod

| # | Item | Status |
|---|------|--------|
| B3.1 | Postgres rodando no VPS (porta 5432, IP `localhost` ou `host.docker.internal`?) | ⬜ |
| B3.2 | DB `meuguiadb` criado | ⬜ |
| B3.3 | User `postgres` com permissão DDL (pra AutoMigrate) | ⬜ |
| B3.4 | Migrations 000020-000023 aplicadas (via AutoMigrate no startup, **NÃO** manual) | ⬜ |
| B3.5 | Backup automatizado configurado (cron pg_dump diário) | ⬜ |

**AutoMigrate roda sozinho no startup do container** se `&models.BillingEvent{}` + todas as outras models estiverem na lista. Verificar em `internal/database/database.go` antes do deploy.

---

## Bloco 4 — Secrets .env prod

`pedro-claude-guia-catolico/.env.prod` (gitignored) — copiar de `.env` sandbox ajustando:

```bash
APP_ENV=production
APP_URL=https://api.meuguia.com.br

# DB prod (IP/host conforme Contabo)
DB_HOST=<postgres-host>
DB_PORT=5432
DB_USER=meuguia
DB_PASSWORD=<gerar 32 chars random>
DB_NAME=meuguiadb
DB_SSLMODE=require          # prod EXIGE SSL

# JWT — GERAR NOVO (sandbox = Kj9mP2xR8nQ4wL6tY3hJ7cF1bN5sA0dG8eU2iO4rM6zT9xW3yB5vK8nQ1mZ4pL7)
JWT_SECRET=<openssl rand -hex 32>

# SMTP prod (Brevo/SES/Mailgun) — não usar SMTP vazio
SMTP_HOST=smtp-relay.brevo.com
SMTP_PORT=587
SMTP_USER=<brevo-user>
SMTP_PASS=<brevo-pass>
SMTP_FROM=no-reply@meuguia.com.br

# Upload path
UPLOAD_PATH=/var/meuguia/uploads
MAX_UPLOAD_SIZE_MB=10

# Cache
CACHE_TTL_SECONDS=300

# Asaas prod (B1.1 + B1.2 + B1.3)
ASAAS_API_KEY=$$aact_prod_...                # escape $$ no compose
ASAAS_WALLET_ID=<wallet-uuid>
ASAAS_ENV=production
ASAAS_WEBHOOK_MODE=bearer
ASAAS_WEBHOOK_TOKEN=<gerar novo random>
ASAAS_PLATFORM_FEE_PCT=<15 ou 20>

# CORS — frontend prod
APP_FRONTEND_URL=https://meuguia.com.br
```

**NUNCA commit .env.prod. Criptografar com ansible-vault ou bitwarden.**

---

## Bloco 5 — Docker prod

| # | Item | Status |
|---|------|--------|
| B5.1 | `docker-compose.prod.yml` criado (ou override) com env vars por `${VAR:-}` | ⬜ |
| B5.2 | Imagem `meu-guia-api:prod-2026-10-XX` buildada (`docker build -t ... .`) | ⬜ |
| B5.3 | Container restart policy `unless-stopped` | ⬜ |
| B5.4 | Volume `/var/meuguia/uploads` montado | ⬜ |
| B5.5 | Caddy/Nginx reverse proxy → `127.0.0.1:8080` | ⬜ |
| B5.6 | Healthcheck `curl https://api.meuguia.com.br/health` retorna 200 | ⬜ |

---

## Bloco 6 — Smoke test pos-deploy

```bash
# 1. API health
curl https://api.meuguia.com.br/health
# esperado: {"status":"ok",...}

# 2. Asaas webhook endpoint existe
curl -X POST https://api.meuguia.com.br/webhooks/asaas -H "Content-Type: application/json" -d '{}'
# esperado: 400 (sem event_id) — significa que rota registrou

# 3. Frontend aponta pra prod
# no .env do frontend meuguia-front/.env.prod:
#   NEXT_PUBLIC_API_BASE_URL=https://api.meuguia.com.br
# build: npm run build && reiniciar container front

# 4. Asaas smoke binário contra prod
go run ./cmd/asaas-smoke
# esperado: cria customer + subscription reais, imprime IDs

# 5. Marcar pagamento manual no painel Asaas prod
# esperado em ~30s:
#   - webhook recebido (log: "💳 Asaas webhook habilitado")
#   - DB: billing_events.processed_at = true
#   - DB: subscriptions.status = 'active'
#   - DB: audit_logs nova row billing.payment.received
```

---

## Bloco 7 — Rollback plan

Se algo der errado pós-deploy:

| Sintoma | Ação |
|---------|------|
| 500 em massa | `docker logs meu-guia-api` + reverter imagem `docker tag meu-guia-api:prod-2026-10-XX meu-guia-api:current` |
| Webhook não processa | log: "Asaas webhook desabilitado" → conferir env vars, restart |
| Postgres erro migração | `docker exec -it postgres psql -U postgres -d meuguiadb` → rollback manual migrations 000020-000023 (drop tables) |
| Asaas 401 | conferir ASAAS_API_KEY prod vs sandbox (prefixos diferentes) |

**Nunca rodar `DROP DATABASE` em prod. Backup B3.5 é o seguro.**

---

## Inputs Pedro pedir Decio (template email)

```
Decio, para subir prod do Meu Guia Católico preciso de 3 coisas da conta Asaas:

1. Production API key (começa com $aact_prod_) — painel Asaas → Integrações → API
2. Wallet ID da conta
3. Qual % de taxa split a plataforma fica? (sandbox estava em 10%, prod geralmente 15-20%)

Quando o sistema subir, precisamos também cadastrar a URL do webhook
no painel Asaas (Minha Conta → Webhooks):
  URL: https://api.meuguia.com.br/webhooks/asaas
  Eventos: PAYMENT_RECEIVED, PAYMENT_CONFIRMED, PAYMENT_OVERDUE, SUBSCRIPTION_CANCELED
```

---

## Inputs Pedro decidir

| Decisão | Opções |
|---------|--------|
| Host VPS | Contabo (já tem) / Hostinger / DigitalOcean |
| Reverse proxy | Caddy (auto-TLS) / Nginx / Traefik |
| SMTP prod | Brevo / SES / Mailgun |
| Backups DB | cron local + rsync offsite / pg_dump + S3 |
| Monitoramento | UptimeRobot (free) / Hetrixtools / nada por enquanto |
| Stripe coexist | manter paralelo ou remover (F6) |

---

## WIP — Próxima sessão "onde paramos"

1. Pedro traz B1.1-B1.4 (Decio respondeu?)
2. Pedro decide B2.1-B2.4 (DNS/TLS pronto?)
3. Setup DB prod (B3)
4. Build imagem + push pra VPS
5. Caddy config
6. Smoke test Bloco 6

**Estimativa:** 2-4h setup + 1h smoke = ½ dia útil quando B1+B2 prontos.
