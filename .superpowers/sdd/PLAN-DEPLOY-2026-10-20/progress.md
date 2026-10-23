# SDD ledger — plan: pedro-claude-guia-catolico/PLAN-DEPLOY-2026-10-20.md

Executor: Claude (inline) + Pedro opera SSH na VPS.
Ambiente alvo: Contabo VPS `144.91.86.204`, Ubuntu 24.04.5 LTS (kernel 6.8.0-147), 192.69GB /, root login por senha ativo.

## Pre-flight

| Row | Finding | Ruling |
|-----|---------|--------|
| Task 1 (SSH) vs Task 2 (UFW) | Task 1 Passo 4 muda `Port 2222` e reinicia sshd; Task 2 Passo 1 só então libera 2222 no UFW | Inverter ordem de firewall vs porta: rodar UFW **antes** do hardening de porta, liberando 22 **e** 2222; fechar 22 só depois do login verificado na 2222 |
| Plano assume Ubuntu 22.04 | VPS real = 24.04.5 | Manter 24.04 — Postgres 16 nativo (22.04 instala 14), LTS até 2029. Path `/etc/postgresql/16/main/` confere |
| `<VPS_IP>` placeholder | IP real `144.91.86.204` | Substituir em todos os docs |
| P0.5 deploy key | `~/.ssh/id_ed25519` existe local (id_rsa tb) | Usar id_ed25519; Pedro precisa ter `~/.ssh/id_ed25519.pub` na máquina que vai pro deploy |
| Contabo firewall externo | Desconhecido (não documentado no plano) | Ruling: testar 2222 antes de remover 22 do UFW e nunca remover 22 até smoke E2E verde (Task 7) |
| Task 4 (Nginx + Cloudflare Origin cert) | Depende de domínio no Cloudflare — P0.3 não confirmado | Bloqueado até Pedro confirmar domínio + acesso Cloudflare. Tasks 1-3 não dependem |
| DNS real (verificado 2026-10-21 via 1.1.1.1) | Pedro disse "já configurado para Cloudflare" — **falso**: NS = ns1/ns2/ns3.**locaweb.com.br**; apex A = 186.202.153.38 (parking Locaweb); `api.meuguia.com.br` = NXDOMAIN | Precisa trocar NS no Registro.br pra NS do Cloudflare (caminho A) **ou** ficar na Locaweb e usar A record + Let's Encrypt (caminho B). Perguntar ao Pedro qual. Ruling pendente |

## Tasks

- [x] Prep Task 5: binário `linux/amd64` cross-compilado em `backend/dist/meu-guia-api` (20MB, `CGO_ENABLED=0 -trimpath -ldflags="-s -w"`). Suíte full verde em `golang:1.24-alpine` (9 packages ok). Pendente: `.env` + `uploads/` no servidor. `migrations/` **não** é necessária em prod (AutoMigrate no startup)
- [ ] Task 1: SSH hardening + user deploy
- [ ] Task 2: Firewall UFW + pacotes base
- [ ] Task 3: Postgres 16 setup
- [ ] Task 4: Nginx + Cloudflare Origin Certificate — **BLOQUEADO (domínio/Cloudflare)**
- [ ] Task 5: Go 1.24 + backend binary + systemd — parcial (precisa DB password da Task 3)
- [ ] Task 6: Node 20 + Next.js + PM2
- [ ] Task 7: DNS Cloudflare + smoke E2E — **BLOQUEADO (domínio)**
- [ ] Task 8: Backup Postgres + uploads + logrotate
- [ ] Task 9: Watchdog + monitor externo
- [ ] Task 10: Verificação final + handoff

## Rulings

- **Ruling (2026-10-21): `TestListAudit_NoFilters` falha só no Windows, não é bug de prod.** Debug: 3 `WriteAudit` seguidos gravam `created_at` **idêntico** (`2026-10-20T22:05:48.5775665-03:00`, typeof=text) porque o relógio do Windows tem granularidade de ~0.5–15ms. `audit_query.go:69` faz só `Order("created_at DESC")` → empate → SQLite devolve em ordem de rowid → u1 primeiro. Em Linux o relógio tem resolução de ns: `go test ./internal/handlers/ -run TestListAudit -count=3` **ok** em `golang:1.24-alpine`. Custo se estiver errado: nenhum em prod, mas paginação de `audit_logs` com `LIMIT/OFFSET` pode duplicar/pular linhas dentro de um empate de timestamp. Follow-up pós-deploy: adicionar tiebreaker `id DESC` + tornar o teste determinístico (timestamps explícitos em vez de depender do relógio)
- **Ruling (2026-10-21): suíte de referência é a do container Linux, não `go test` na máquina Windows** — as runs do SYNC sempre foram em Docker Linux; usar isso como baseline
- **Ruling (2026-10-21): binário cross-compilado local em vez de build na VPS** — evita instalar toolchain Go 1.24 + `go mod download` no servidor; Task 5 vira `scp` + unit + systemd. Custo se errado: arquitetura divergente se a VPS for ARM (Contabo é x86_64, conferido no `uname` do login)