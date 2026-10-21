---
name: Plan Deploy 2026-10-20 prod Contabo
description: Plano SDD 11 tasks — SSH hardening, pacotes, Postgres, Nginx+CF, Go backend, Next+PM2, DNS, smoke, backups, monitor
metadata:
  type: project
---

# Deploy Produção Contabo + Cloudflare — Plano de Execução

> **For agentic worker:** Cada task = comando exato + critério de aceite. Executar em ordem. Marcar checkbox ao completar. **NÃO pular tasks** — pré-requisito da próxima.

**Goal:** Subir `api.meuguia.com.br` (Go) + `app.meuguia.com.br` (Next) na VPS Contabo com Nginx + TLS Cloudflare + Postgres local + backups diários.

**Architecture:**
- Backend: Go binary compilado + systemd (NÃO Docker)
- Frontend: Next.js + PM2
- Proxy: Nginx com Origin Certificate Cloudflare (Full Strict)
- DB: Postgres 16 local (127.0.0.1 only)
- DNS: Cloudflare proxy (orange cloud)

**Tech Stack:**
- Ubuntu 22.04 LTS
- Go 1.24 (golang.org)
- Next 15 + Node 20 LTS + PM2
- Postgres 16 (apt)
- Nginx 1.18 (apt)
- Cloudflare Origin Certificate (15 anos)
- systemd + cron + logrotate
- UFW firewall + fail2ban

**Pré-requisitos fora do plano (Pedro obtém antes Task 1):**

| # | Item | Origem |
|---|------|--------|
| P0.1 | IP VPS Contabo (`<VPS_IP>`) | Email Contabo |
| P0.2 | Senha root SSH inicial | Email Contabo |
| P0.3 | Domínio `meuguia.com.br` registrado | Registro.br / Cloudflare |
| P0.4 | Asaas prod API key + wallet ID (Decio) | Email Decio |
| P0.5 | Deploy key SSH (`~/.ssh/id_ed25519` local) | Máquina local Pedro |

**Conventions:**
- `<VPS_IP>` = IP da VPS Contabo (substituir em todos os comandos)
- `<SENHA_*>` = senha gerada em runtime, NUNCA commit
- `deploy` = usuário criado em Task 1, NUNCA usar `root` depois
- Working dir produção: `/opt/meuguia/{api,front,backups,uploads,logs}`

---

## Global Constraints

1. **SSH non-root após Task 1** — `root` login desabilitado, `PermitRootLogin no`
2. **Postgres só escuta 127.0.0.1** — `listen_addresses = '127.0.0.1'` em `postgresql.conf`
3. **Nginx só aceita IPs Cloudflare** — `include /etc/nginx/cloudflare-ips/restrict.cf.conf` em cada server block
4. **Secrets com chmod 600** — `.env`, `.pgpass`, `ssl/*.key` — NUNCA 644
5. **systemd hardening** — `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`, `ReadWritePaths` explícito
6. **PM2 com deploy user** — não rodar como root, usar `pm2 startup systemd -u deploy`
7. **Backup offsite é separado** — este plano cobre backup local; rsync pra B2/S3 fica em task futura
8. **Origem Cloudflare Full Strict** — não usar Let's Encrypt no servidor (Cloudflare gera cert 15 anos)
9. **Cada task tem critério de aceite objetivo** — comando específico + output esperado
10. **Tasks executadas em ordem** — Task N+1 depende do critério aceite da Task N estar verde

---

## Task 1: SSH hardening + user deploy

**Files:**
- Create: `/home/deploy/.ssh/authorized_keys`
- Modify: `/etc/ssh/sshd_config`
- Create: `/etc/sudoers.d/deploy`

**Pré-requisitos:** P0.1 (IP), P0.2 (senha root), P0.5 (chave pública local)

**Passo 1 — Conectar como root**

```bash
# Local (PowerShell ou Git Bash)
ssh root@<VPS_IP>
```

Aceite fingerprint, login com senha do P0.2.

Critério aceite: prompt `#` root.

**Passo 2 — Criar usuário deploy**

```bash
adduser deploy --disabled-password --gecos ""
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
```

Cole conteúdo de `cat ~/.ssh/id_ed25519.pub` (máquina local) em `/home/deploy/.ssh/authorized_keys`:

```bash
nano /home/deploy/.ssh/authorized_keys   # colar pub key
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
```

Critério aceite: `ssh deploy@<VPS_IP>` funciona sem pedir senha.

**Passo 3 — Sudo sem senha para deploy**

```bash
apt install sudo -y
echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/deploy
chmod 440 /etc/sudoers.d/deploy
```

Critério aceite: `ssh deploy@<VPS_IP> "sudo whoami"` retorna `root`.

**Passo 4 — Hardening SSH**

```bash
sudo nano /etc/ssh/sshd_config
```

Mudar:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 2222
```

```bash
sudo systemctl restart sshd
```

**NÃO feche esta sessão até confirmar Passo 5.**

**Passo 5 — Conectar nova porta**

Em nova janela local (NÃO fechar Passo 4):
```bash
ssh -p 2222 deploy@<VPS_IP>
```

Critério aceite: login OK sem senha, via porta 2222. Confirmar `sudo -i` pedir senha? Não — está configurado NOPASSWD.

**Passo 6 — Confirmar root não entra mais**

```bash
ssh root@<VPS_IP>
# esperado: Permission denied (publickey)
```

Critério aceite: `root` login rejeitado.

Commit checkpoint (não versionado, é server config):
```bash
# Não há repo git no server ainda, nada pra commitar
```

---

## Task 2: Firewall UFW + pacotes base

**Files:**
- Modify: UFW rules
- Install: `ufw fail2ban unattended-upgrades build-essential git curl wget htop tmux nginx postgresql postgresql-contrib rsync logrotate certbot python3-certbot-nginx`

**Pré-requisitos:** Task 1 concluída.

**Passo 1 — UFW regras**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH custom port'
sudo ufw allow 80/tcp comment 'HTTP (Cloudflare only)'
sudo ufw allow 443/tcp comment 'HTTPS (Cloudflare only)'
sudo ufw enable
sudo ufw status verbose
```

Critério aceite: lista mostra 2222, 80, 443 abertas; resto deny.

**Passo 2 — fail2ban**

```bash
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
sudo systemctl status fail2ban --no-pager
```

Critério aceite: `active (running)`.

**Passo 3 — Pacotes base restantes**

```bash
sudo apt install -y \
  build-essential git curl wget htop tmux \
  nginx postgresql postgresql-contrib \
  unattended-upgrades \
  certbot python3-certbot-nginx \
  rsync logrotate
```

Critério aceite: `nginx -v`, `psql --version`, `git --version` todos OK.

**Passo 4 — unattended-upgrades**

```bash
sudo dpkg-reconfigure -plow unattended-upgrades
# Selecionar "Yes"
```

Critério aceite: arquivo `/etc/apt/apt.conf.d/20auto-upgrades` existe.

---

## Task 3: Postgres 16 setup

**Files:**
- Modify: `/etc/postgresql/16/main/pg_hba.conf`
- Modify: `/etc/postgresql/16/main/postgresql.conf`
- Create: `/home/deploy/.pgpass`

**Pré-requisitos:** Task 2 concluída (Postgres instalado).

**Passo 1 — Criar role dedicado**

```bash
SENHA_DB=$(openssl rand -hex 16)
echo "SENHA_DB=$SENHA_DB"  # GUARDAR, vai usar B.5 / Task 5
sudo -u postgres psql << EOF
CREATE ROLE meuguia WITH LOGIN PASSWORD '$SENHA_DB';
CREATE DATABASE meuguiadb OWNER meuguia;
GRANT ALL PRIVILEGES ON DATABASE meuguiadb TO meuguia;
EOF
```

Critério aceite: `\du` mostra role `meuguia`, `\l` mostra db `meuguiadb`.

**Passo 2 — Restringir escuta para 127.0.0.1**

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

```ini
listen_addresses = '127.0.0.1'
port = 5432
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 128MB
```

```bash
sudo systemctl restart postgresql
sudo -u postgres psql -c "SHOW listen_addresses;"
```

Critério aceite: `127.0.0.1`.

**Passo 3 — HBA manter md5**

```bash
sudo cat /etc/postgresql/16/main/pg_hba.conf | grep -v '^#' | grep -v '^$'
```

Esperado ter:
```
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

Critério aceite: TCP 127.0.0.1 usa `md5`.

**Passo 4 — Testar conexão como `meuguia`**

```bash
echo "127.0.0.1:5432:meuguiadb:meuguia:$SENHA_DB" > /home/deploy/.pgpass
chmod 600 /home/deploy/.pgpass
chown deploy:deploy /home/deploy/.pgpass

psql -h 127.0.0.1 -U meuguia -d meuguiadb -c "SELECT version();"
```

Critério aceite: `PostgreSQL 16.x ...` retornado.

**Passo 5 — Salvar senha fora do .pgpass pra Task 5**

```bash
sudo nano /root/.db_password
# Colar senha do Passo 1
chmod 600 /root/.db_password
```

Critério aceite: existe arquivo, root pode ler via sudo.

---

## Task 4: Nginx + Cloudflare Origin Certificate

**Files:**
- Create: `/etc/nginx/cloudflare-ips/`
- Create: `/etc/nginx/ssl/meuguia.com.br.pem`
- Create: `/etc/nginx/ssl/meuguia.com.br.key`
- Create: `/etc/nginx/sites-available/api.meuguia.com.br`
- Create: `/etc/nginx/sites-available/app.meuguia.com.br`
- Create: `/etc/nginx/cloudflare-ips/restrict.cf.conf`

**Pré-requisitos:** P0.3 (domínio no Cloudflare), Task 2 (Nginx instalado).

**Passo 1 — Cloudflare painel (Pedro faz manual)**

1. Cloudflare dashboard → `meuguia.com.br`
2. SSL/TLS → modo **Full (Strict)**
3. Edge Certificates → **Origin Certificate** → Create:
   - Hostnames: `*.meuguia.com.br`, `meuguia.com.br`
   - 15 anos
4. Baixar `cert.pem` e `key.pem`

**Passo 2 — Subir Origin cert pro servidor**

```bash
sudo mkdir -p /etc/nginx/ssl
sudo nano /etc/nginx/ssl/meuguia.com.br.pem   # colar conteúdo cert.pem
sudo nano /etc/nginx/ssl/meuguia.com.br.key   # colar conteúdo key.pem
sudo chmod 644 /etc/nginx/ssl/meuguia.com.br.pem
sudo chmod 600 /etc/nginx/ssl/meuguia.com.br.key
```

Critério aceite: arquivos existem, permissões OK.

**Passo 3 — Gerar lista IPs Cloudflare**

```bash
sudo mkdir -p /etc/nginx/cloudflare-ips
sudo nano /etc/nginx/cloudflare-ips/build-list.sh
```

```bash
#!/bin/bash
OUT=/etc/nginx/cloudflare-ips/restrict.cf.conf
echo "# Auto-generated $(date -u)" > $OUT
echo "allow 127.0.0.1;" >> $OUT
for ip in $(curl -s https://www.cloudflare.com/ips-v4) $(curl -s https://www.cloudflare.com/ips-v6); do
    echo "allow $ip;" >> $OUT
done
echo "deny all;" >> $OUT
```

```bash
sudo chmod +x /etc/nginx/cloudflare-ips/build-list.sh
sudo /etc/nginx/cloudflare-ips/build-list.sh
wc -l /etc/nginx/cloudflare-ips/restrict.cf.conf
```

Critério aceite: ~25 linhas (`15 IPv4 + 5 IPv6 + outros`).

**Passo 4 — Site config backend**

```bash
sudo nano /etc/nginx/sites-available/api.meuguia.com.br
```

```nginx
server {
    listen 80;
    server_name api.meuguia.com.br;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.meuguia.com.br;

    ssl_certificate     /etc/nginx/ssl/meuguia.com.br.pem;
    ssl_certificate_key /etc/nginx/ssl/meuguia.com.br.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    include /etc/nginx/cloudflare-ips/restrict.cf.conf;

    client_max_body_size 20M;

    # Health check sem restrição IP (probes externos)
    location = /health {
        allow all;
        satisfy any;
        proxy_pass http://127.0.0.1:8080/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $cf_connecting_ip;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_read_timeout 60s;
    }
}
```

**Passo 5 — Site config frontend**

```bash
sudo nano /etc/nginx/sites-available/app.meuguia.com.br
```

```nginx
server {
    listen 80;
    server_name app.meuguia.com.br meuguia.com.br www.meuguia.com.br;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name app.meuguia.com.br meuguia.com.br www.meuguia.com.br;

    ssl_certificate     /etc/nginx/ssl/meuguia.com.br.pem;
    ssl_certificate_key /etc/nginx/ssl/meuguia.com.br.key;
    ssl_protocols       TLSv1.2 TLSv1.3;

    include /etc/nginx/cloudflare-ips/restrict.cf.conf;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $cf_connecting_ip;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /_next/static {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Passo 6 — Habilitar + validar**

```bash
sudo ln -s /etc/nginx/sites-available/api.meuguia.com.br /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/app.meuguia.com.br /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

Critério aceite: `nginx -t` → `syntax is ok, test is successful`.

---

## Task 5: Go 1.24 + backend binary + systemd

**Files:**
- Modify: PATH (profile)
- Create: `/opt/meuguia/api/.env`
- Create: `/etc/systemd/system/meuguia-api.service`
- Create: `/opt/meuguia/{api,front,backups,uploads,logs}/`

**Pré-requisitos:** Task 3 (Postgres), Task 4 (Nginx ready), P0.5 (deploy key SSH pra clone).

**Passo 1 — Instalar Go 1.24**

```bash
cd /tmp
wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/go.sh
source /etc/profile.d/go.sh
go version
```

Critério aceite: `go1.24.0 linux/amd64`.

**Passo 2 — Setup estrutura diretórios**

```bash
sudo mkdir -p /opt/meuguia/{api,front,backups/db,backups/uploads,uploads,logs}
sudo chown -R deploy:deploy /opt/meuguia
```

Critério aceite: `ls /opt/meuguia/` mostra `api front backups uploads logs`.

**Passo 3 — Adicionar chave SSH pro GitHub**

```bash
ssh-keygen -t ed25519 -C "vps-meuguia-deploy" -f ~/.ssh/meuguia-deploy -N ""
cat ~/.ssh/meuguia-deploy.pub
```

Adicionar essa pub key em GitHub:
- Repo `meu-guia` → Settings → Deploy keys → Add (read-only OK)
- Cole o output do `cat`

```bash
ssh -T git@github.com
```

Critério aceite: `Hi pedro/meu-guia! You've been granted access.`.

**Passo 4 — Clone do repo**

```bash
cd /opt/meuguia/api
git clone git@github.com:pedro/meu-guia.git .
git checkout main
```

Critério aceite: `ls` mostra `meu-guia-api/`, `meu-guia-front/`, etc.

**Passo 5 — Build binary**

```bash
cd /opt/meuguia/api/meu-guia-api
go build -o /opt/meuguia/api/meuguia-api ./cmd/api
ls -lh /opt/meuguia/api/meuguia-api
```

Critério aceite: binário ~30-50MB, executável (`-rwxr-xr-x`).

**Passo 6 — Criar `.env.prod`**

```bash
sudo nano /opt/meuguia/api/.env
chmod 600 /opt/meuguia/api/.env
sudo chown deploy:deploy /opt/meuguia/api/.env
```

Conteúdo:

```bash
APP_ENV=production
APP_PORT=8080
APP_URL=https://api.meuguia.com.br
APP_FRONTEND_URL=https://app.meuguia.com.br

DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=meuguia
DB_PASSWORD=<SENHA_DB_DO_TASK3>
DB_NAME=meuguiadb
DB_SSLMODE=disable

JWT_SECRET=<openssl rand -hex 32>

UPLOAD_PATH=/opt/meuguia/uploads

ADMIN_EMAIL=admin@meuguiacatolico.com
ADMIN_PASSWORD=<GERAR_SENHA_FORTE>
ADMIN_NAME=Administrador

ASAAS_API_KEY=$$aact_prod_...
ASAAS_WALLET_ID=<UUID_PROD>
ASAAS_ENV=production
ASAAS_WEBHOOK_MODE=bearer
ASAAS_WEBHOOK_TOKEN=<openssl rand -hex 32>
ASAAS_PLATFORM_FEE_PCT=10
```

Critério aceite: arquivo existe, chmod 600.

**Passo 7 — systemd service**

```bash
sudo nano /etc/systemd/system/meuguia-api.service
```

```ini
[Unit]
Description=Meu Guia Catolico API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory=/opt/meuguia/api
EnvironmentFile=/opt/meuguia/api/.env
ExecStart=/opt/meuguia/api/meuguia-api
Restart=always
RestartSec=5
StandardOutput=append:/opt/meuguia/logs/api.log
StandardError=append:/opt/meuguia/logs/api.err

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/meuguia/uploads /opt/meuguia/logs

[Install]
WantedBy=multi-user.target
```

**Passo 8 — Iniciar serviço**

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now meuguia-api
sudo systemctl status meuguia-api --no-pager
sudo journalctl -u meuguia-api -f
```

Critério aceite: status `active (running)`. Log mostra:
- `🚀 Servidor rodando em http://localhost:8080`
- `💳 Asaas webhook habilitado`

**Passo 9 — Testar health local**

```bash
curl -i http://127.0.0.1:8080/health
```

Critério aceite: HTTP 200, body `{"status":"ok",...}`.

**Passo 10 — Testar webhook endpoint**

```bash
curl -i -X POST http://127.0.0.1:8080/webhooks/asaas \
  -H "Content-Type: application/json" -d '{}'
```

Critério aceite: HTTP 400 (event_id required) — significa rota registrada.

---

## Task 6: Node 20 + Next.js + PM2

**Files:**
- Create: `/opt/meuguia/front/meu-guia-front/.env.production`
- PM2 process: `meuguia-front`

**Pré-requisitos:** Task 5 (backend up).

**Passo 1 — Node 20 LTS**

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version
npm --version
```

Critério aceite: `v20.x.y`.

**Passo 2 — PM2 global**

```bash
sudo npm install -g pm2
pm2 --version
```

Critério aceite: versão PM2 impressa.

**Passo 3 — Clone do frontend**

```bash
cd /opt/meuguia/front
git clone git@github.com:pedro/meu-guia.git .
git checkout main
cd meu-guia-front
npm ci --production=false
```

Critério aceite: `node_modules/` populado.

**Passo 4 — `.env.production`**

```bash
nano /opt/meuguia/front/meu-guia-front/.env.production
```

```bash
NEXT_PUBLIC_API_BASE_URL=https://api.meuguia.com.br
NEXT_PUBLIC_APP_URL=https://app.meuguia.com.br
NODE_ENV=production
```

**Passo 5 — Build Next**

```bash
cd /opt/meuguia/front/meu-guia-front
npm run build
```

Critério aceite: termina com success, gera `.next/`.

**Passo 6 — PM2 start**

```bash
pm2 start npm --name "meuguia-front" -- start
pm2 save
pm2 startup systemd
```

O comando `pm2 startup systemd` retorna linha do tipo:
```
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u deploy --hp /home/deploy
```

Copiar e executar:

```bash
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u deploy --hp /home/deploy
```

Critério aceite: `systemctl list-units --type=service | grep pm2` mostra `pm2-deploy.service enabled`.

**Passo 7 — Verificar**

```bash
pm2 list
pm2 logs meuguia-front --lines 30
```

Critério aceite: status `online`. Log: `ready - started server on 0.0.0.0:3000`.

**Passo 8 — Testar localmente**

```bash
curl -i http://127.0.0.1:3000
```

Critério aceite: HTTP 200, HTML com `<title>Meu Guia Católico</title>` (ou similar).

---

## Task 7: DNS Cloudflare + smoke E2E

**Files:**
- Modify: Cloudflare DNS records (Pedro)

**Pré-requisitos:** Task 4 + 5 + 6 completas.

**Passo 1 — Cloudflare DNS records**

Dashboard `meuguia.com.br` → DNS → Records:

| Tipo | Nome | Conteúdo | Proxy |
|------|------|----------|-------|
| A | api | `<VPS_IP>` | **Proxied** (laranja) |
| A | app | `<VPS_IP>` | **Proxied** |
| A | @ | `<VPS_IP>` | **Proxied** |
| CNAME | www | meuguia.com.br | **Proxied** |

**Passo 2 — Aguardar propagação CF (instantâneo dentro rede CF)**

```bash
dig api.meuguia.com.br @1.1.1.1 +short
# esperado: <VPS_IP> ou IP CF proxy (104.x.x.x)
```

Critério aceite: retorna IP CF proxy ou IP real.

**Passo 3 — Smoke E2E público**

```bash
# Health
curl -i https://api.meuguia.com.br/health
# esperado: 200

# Frontend renderiza
curl -i https://app.meuguia.com.br
# esperado: 200, HTML

# Webhook Asaas (sem credenciais vai dar erro, mas rota registrada)
curl -i -X POST https://api.meuguia.com.br/webhooks/asaas \
  -H "Content-Type: application/json" -d '{}'
# esperado: 400 (event_id required) ou 401 (auth webhook) — não 404
```

Critério aceite: 3 endpoints acima retornam ≠ 404.

**Passo 4 — Painel Asaas: cadastrar webhook**

Pedro acessa painel Asaas → Minha Conta → Webhooks → Novo:

```
URL: https://api.meuguia.com.br/webhooks/asaas
Eventos: PAYMENT_RECEIVED, PAYMENT_CONFIRMED, PAYMENT_OVERDUE, SUBSCRIPTION_CANCELED
Tipo auth: Bearer
Token: <ASAAS_WEBHOOK_TOKEN do .env>
```

Critério aceite: webhook cadastrado, status "Ativo" no painel.

**Passo 5 — Testar webhook E2E real (Pedro marca pagamento)**

Pedro usa smoke binário (Pedro tem Asaas key agora via Decio):

```bash
cd /opt/meuguia/api/meu-guia-api
sudo -u deploy bash
set -a; source /opt/meuguia/api/.env; set +a
go run ./cmd/asaas-smoke
```

Script imprime `ASAAS_SMOKE_CUSTOMER_ID` + `ASAAS_SMOKE_SUBSCRIPTION_ID`.

Pedro entra painel Asaas → Cobranças → marcar payment da subscription criada → status RECEIVED.

Após ~30s no servidor:
```bash
sudo journalctl -u meuguia-api -f
# esperado: log mencionando webhook received
```

```bash
sudo -u postgres psql meuguiadb -c "SELECT id, event, processed_at IS NOT NULL AS processed FROM billing_events ORDER BY created_at DESC LIMIT 1;"
# esperado: 1 linha com processed=t
```

```bash
sudo -u postgres psql meuguiadb -c "SELECT id, status, asaas_subscription_id FROM subscriptions ORDER BY updated_at DESC LIMIT 1;"
# esperado: status=active, asaas_subscription_id preenchido
```

```bash
sudo -u postgres psql meuguiadb -c "SELECT action, target_id FROM audit_logs WHERE action LIKE 'billing.%' ORDER BY created_at DESC LIMIT 3;"
# esperado: billing.payment.received
```

Critério aceite: 4 queries retornam dados consistentes.

---

## Task 8: Backup Postgres + uploads + logrotate

**Files:**
- Create: `/opt/meuguia/backups/db/backup.sh`
- Create: `/opt/meuguia/backups/uploads/uploads-backup.sh`
- Create: `/etc/logrotate.d/meuguia`
- Modify: crontab `deploy`

**Pré-requisitos:** Task 7 (sistema operacional).

**Passo 1 — Script backup DB**

```bash
sudo nano /opt/meuguia/backups/db/backup.sh
```

```bash
#!/bin/bash
set -e
DATA=$(date +%Y%m%d_%H%M)
BACKUP_DIR=/opt/meuguia/backups/db
LOG=/opt/meuguia/logs/backup.log

mkdir -p $BACKUP_DIR

PGPASSFILE=/home/deploy/.pgpass pg_dump \
  -h 127.0.0.1 -U meuguia -d meuguiadb \
  -Fc -f $BACKUP_DIR/db_${DATA}.dump

find $BACKUP_DIR -name "db_*.dump" -mtime +7 -delete

echo "$(date -Iseconds) Backup db_${DATA}.dump OK ($(ls -lh $BACKUP_DIR/db_${DATA}.dump | awk '{print $5}'))" >> $LOG
```

```bash
sudo chmod +x /opt/meuguia/backups/db/backup.sh
```

**Passo 2 — Testar backup manual**

```bash
sudo -u deploy /opt/meuguia/backups/db/backup.sh
ls -lh /opt/meuguia/backups/db/
```

Critério aceite: arquivo `db_YYYYMMDD_HHMM.dump` existe, size > 1MB (dependendo volume).

**Passo 3 — Script backup uploads (semanal)**

```bash
sudo nano /opt/meuguia/backups/uploads/uploads-backup.sh
```

```bash
#!/bin/bash
DATA=$(date +%Y%m%d)
tar -czf /opt/meuguia/backups/uploads/uploads_${DATA}.tar.gz \
  /opt/meuguia/uploads
find /opt/meuguia/backups/uploads -name "uploads_*.tar.gz" -mtime +30 -delete
echo "$(date -Iseconds) Upload backup OK" >> /opt/meuguia/logs/backup.log
```

```bash
sudo chmod +x /opt/meuguia/backups/uploads/uploads-backup.sh
```

**Passo 4 — Cron jobs**

```bash
sudo crontab -u deploy -e
```

Adicionar:
```
# Backup Postgres diário 03:00 UTC
0 3 * * * /opt/meuguia/backups/db/backup.sh

# Backup uploads semanal (domingo 04:00 UTC)
0 4 * * 0 /opt/meuguia/backups/uploads/uploads-backup.sh
```

Critério aceite: `crontab -u deploy -l` mostra as 2 linhas.

**Passo 5 — logrotate**

```bash
sudo nano /etc/logrotate.d/meuguia
```

```
/opt/meuguia/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    copytruncate
    sharedscripts
    postrotate
        systemctl reload meuguia-api > /dev/null 2>&1 || true
        pm2 reloadLogs > /dev/null 2>&1 || true
    endscript
}
```

Critério aceite: arquivo existe, syntax válido (`logrotate -d /etc/logrotate.d/meuguia`).

---

## Task 9: Watchdog + monitor externo

**Files:**
- Create: `/opt/meuguia/backups/watchdog.sh`
- Modify: crontab `deploy`

**Pré-requisitos:** Task 7 (API rodando público), Task 8 (cron instalado).

**Passo 1 — Watchdog local**

```bash
sudo nano /opt/meuguia/backups/watchdog.sh
```

```bash
#!/bin/bash
# Se API down por 2 checks seguidos (5min × 2), restart
LOG=/opt/meuguia/logs/watchdog.log

if ! curl -sf http://127.0.0.1:8080/health > /dev/null 2>&1; then
    sleep 60
    if ! curl -sf http://127.0.0.1:8080/health > /dev/null 2>&1; then
        echo "$(date -Iseconds) API down, restart" >> $LOG
        sudo systemctl restart meuguia-api
    fi
fi
```

```bash
sudo chmod +x /opt/meuguia/backups/watchdog.sh
```

**Passo 2 — Cron watchdog**

```bash
sudo crontab -u deploy -e
```

Adicionar:
```
# Watchdog API a cada 5min
*/5 * * * * /opt/meuguia/backups/watchdog.sh
```

**Passo 3 — UptimeRobot externo (Pedro cria)**

1. uptimerobot.com → free tier
2. Add Monitor:
   - Tipo: HTTPS
   - URL: `https://api.meuguia.com.br/health`
   - Interval: 5min
3. Add Monitor:
   - Tipo: HTTPS
   - URL: `https://app.meuguia.com.br`
   - Interval: 5min
4. Alert contacts: email Pedro

Critério aceite: 2 monitors criados, status "Up".

---

## Task 10: Verificação final + handoff

**Files:** nenhum (verificação)

**Pré-requisitos:** Tasks 1-9 todas completas.

**Checklist final:**

```bash
# 1. API health
curl -i https://api.meuguia.com.br/health
# 200, body {"status":"ok"}

# 2. Frontend
curl -i https://app.meuguia.com.br
# 200, HTML

# 3. Webhook Asaas rota
curl -X POST https://api.meuguia.com.br/webhooks/asaas -d '{}' -H "Content-Type: application/json"
# != 404

# 4. Webhook real (Pedro marcou pagamento painel)
sudo journalctl -u meuguia-api -f
# log "💳 webhook received"

# 5. PM2
pm2 list
# meuguia-front online

# 6. systemd
systemctl status meuguia-api
# active (running)

# 7. Disk
df -h /opt
# < 80% usado

# 8. Backups existem
ls -lh /opt/meuguia/backups/db/
# arquivos recentes

# 9. Logs rotacionam
sudo logrotate -d /etc/logrotate.d/meuguia
# sem erro

# 10. UptimeRobot
# ambos monitors "Up"
```

Critério aceite: todos os 10 itens verdes.

**Documentar:**

```bash
# Criar README operacional no server
sudo nano /opt/meuguia/README.md
```

Conteúdo mínimo:
- Como reiniciar API: `sudo systemctl restart meuguia-api`
- Como reiniciar frontend: `pm2 restart meuguia-front`
- Onde logs: `/opt/meuguia/logs/`
- Onde backups: `/opt/meuguia/backups/`
- Quem decidir: Pedro
- Próxima sessão: `cd ~/oneDrive/Desktop/meu-guia/pedro-claude-guia-catolico`

Critério aceite: arquivo existe, completo.

---

## Resumo Tasks × Tempo × Pré-requisitos

| # | Task | Tempo | Pré-requisito externo |
|---|------|-------|-----------------------|
| 1 | SSH hardening + user deploy | 30min | P0.1, P0.2, P0.5 |
| 2 | Firewall + pacotes | 15min | Task 1 |
| 3 | Postgres setup | 20min | Task 2 |
| 4 | Nginx + CF Origin cert | 45min | P0.3, Task 2 |
| 5 | Go backend + systemd | 30min | Task 3 + 4, P0.4 (depois) |
| 6 | Next.js + PM2 | 30min | Task 5 |
| 7 | DNS CF + smoke | 15min | Task 4+5+6 |
| 8 | Backups + logrotate | 45min | Task 7 |
| 9 | Watchdog + UptimeRobot | 20min | Task 7 |
| 10 | Verificação final | 30min | Tasks 1-9 |
| | **TOTAL** | **~5h** | **1 dia útil** |

**Paralelo (não bloqueia):**
- Email Decio pedindo Asaas key (P0.4) → pode chegar a qualquer momento
- Cloudflare conta + domínio (P0.3) → Pedro configura antes Task 4

---

## Estado PRODUÇÃO (após Task 10 verde)

- API rodando: `https://api.meuguia.com.br`
- Frontend: `https://app.meuguia.com.br`
- DB local backupado diariamente
- API restart automático se cair (systemd Restart=always + watchdog)
- Monitor externo (UptimeRobot) alerta email
- Logs rotacionados diariamente, retidos 14 dias

**Próximo após deploy verde:**
- Conversão para SDD se houver tasks (F4 Planos-contrato, F5 Frontend Asaas UI)
- Setup backup offsite (Backblaze B2 ou similar) — não está nesse plano
