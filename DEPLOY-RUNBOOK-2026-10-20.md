---
name: Deploy Runbook 2026-10-20 prod Contabo
description: Runbook completo deploy prod Contabo — SSH, pacotes, Go binary nativo, Nginx + Cloudflare Origin SSL, Postgres, Node + PM2, backups cron, monitor
metadata:
  type: reference
---

# Deploy Runbook — Produção Contabo + Cloudflare

**Stack final:**
- Backend: Go binary nativo (systemd)
- Frontend: Next.js via PM2
- Proxy: Nginx (Full Strict via Cloudflare Origin cert)
- DB: Postgres 16 local
- DNS: Cloudflare (proxy orange cloud)

**Domínio assumido:** `api.meuguia.com.br` (backend) + `app.meuguia.com.br` ou `meuguia.com.br` (frontend)

**IP público Contabo:** provisionar, hipotético `<VPS_IP>` aqui (substituir)

---

## Bloco 0 — Pré-requisitos Pedro precisa ter em mãos

| Item | Fonte |
|------|-------|
| IP VPS Contabo | Email Contabo / painel cliente |
| Senha root SSH inicial | Email Contabo |
| Domínio `meuguia.com.br` no Cloudflare | Pedro provisionar |
| Asaas prod API key (`$aact_prod_...`) | Decio |
| Asaas prod Wallet ID (UUID) | Decio |

---

## Bloco 1 — Primeiro acesso SSH + hardening (30min)

### 1.1 — Conectar como root

```bash
# Local (Windows PowerShell ou Git Bash)
ssh root@<VPS_IP>

# Conferir SO
cat /etc/os-release
# Ubuntu 22.04 LTS esperado
```

### 1.2 — Criar usuário deploy (não usar root)

```bash
adduser deploy --disabled-password --gecos ""
# Colocar senha depois: passwd deploy
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh

# Copiar sua chave pública local
# (na sua máquina local:)
# cat ~/.ssh/id_ed25519.pub

# Cole no servidor:
nano /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
```

### 1.3 — Sudo sem senha pro deploy (escopo limitado)

```bash
apt install sudo -y
echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/deploy
chmod 440 /etc/sudoers.d/deploy
```

### 1.4 — Hardening SSH

```bash
nano /etc/ssh/sshd_config
```

Mudar:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 2222   # trocar porta default reduz brute-force 90%
```

```bash
systemctl restart sshd
# Nova conexão: ssh -p 2222 deploy@<VPS_IP>
```

### 1.5 — Firewall UFW

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH custom port'
sudo ufw allow 80/tcp comment 'HTTP (Cloudflare only)'
sudo ufw allow 443/tcp comment 'HTTPS (Cloudflare only)'
sudo ufw enable
sudo ufw status verbose
```

**IMPORTANTE:** portas 80/443 ficam expostas mas com Nginx limitando só IPs Cloudflare (Bloco 4).

---

## Bloco 2 — Pacotes base (15min)

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  build-essential git curl wget htop tmux \
  nginx postgresql postgresql-contrib \
  ufw fail2ban unattended-upgrades \
  certbot python3-certbot-nginx \
  rsync logrotate

sudo systemctl enable --now fail2ban
sudo systemctl enable --now unattended-upgrades
```

---

## Bloco 3 — Postgres (20min)

### 3.1 — Setup inicial

```bash
sudo -u postgres psql
```

```sql
-- Criar role dedicado (não usar postgres superuser)
CREATE ROLE meuguia WITH LOGIN PASSWORD '<GERAR_SENHA_FORTE_32CHARS>';
CREATE DATABASE meuguiadb OWNER meuguia;
GRANT ALL PRIVILEGES ON DATABASE meuguiadb TO meuguia;

-- Permitir conexões locais (Postgres default OK pra 127.0.0.1)
\du
\l
\q
```

### 3.2 — Configurar `pg_hba.conf` (manter local trust pro socket + md5 TCP)

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Confirmar:
```
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

### 3.3 — Conexões (não escutar 0.0.0.0 — segurança)

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

```ini
listen_addresses = '127.0.0.1'   # só local, Nginx/Go acessa via socket
port = 5432
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 128MB
```

```bash
sudo systemctl restart postgresql
sudo -u postgres psql -c "SHOW listen_addresses;"
# esperado: 127.0.0.1
```

### 3.4 — Senha deploy usará

```bash
sudo -u postgres psql -c "ALTER ROLE meuguia WITH PASSWORD '<SENHA_FORTE>';"
```

### 3.5 — Conectividade teste

```bash
psql -h 127.0.0.1 -U meuguia -d meuguiadb -c "SELECT version();"
# esperado: PostgreSQL 16.x ...
```

---

## Bloco 4 — Nginx + Cloudflare (45min)

**Decisão chave:** Cloudflare proxy + Origin Certificate = TLS full strict sem precisar Let's Encrypt no servidor.

### 4.1 — Cloudflare painel (Pedro faz)

1. Adicionar site `meuguia.com.br` no Cloudflare (free tier OK)
2. Apontar nameservers Contabo pros do Cloudflare
3. **DNS records:**
   - `A api` → `<VPS_IP>` **proxied** (laranja)
   - `A app` (ou `CNAME @`) → `<VPS_IP>` **proxied**
   - `A root @` → `<VPS_IP>` **proxied** (frontend landing)
4. SSL/TLS → modo **Full (Strict)**
5. Edge Certificates → **Origin Certificate** → criar certificado 15 anos:
   - Hostnames: `*.meuguia.com.br`, `meuguia.com.br`
   - Baixar `cert.pem` + `key.pem` (vou subir pro servidor no 4.3)

### 4.2 — Cloudflare IPs (Nginx só aceita esses)

```bash
sudo mkdir -p /etc/nginx/cloudflare-ips
sudo tee /etc/nginx/cloudflare-ips/cloudflare.conf << 'EOF'
# Cloudflare IPv4 (atualizado 2024)
# https://www.cloudflare.com/ips-v4
set $cf_ipv4 true;
EOF
```

Baixar lista oficial atualizada:
```bash
sudo curl -s https://www.cloudflare.com/ips-v4 > /etc/nginx/cloudflare-ips/ips-v4.txt
sudo curl -s https://www.cloudflare.com/ips-v6 > /etc/nginx/cloudflare-ips/ips-v6.txt
```

### 4.3 — Subir Origin cert

```bash
sudo mkdir -p /etc/nginx/ssl
sudo nano /etc/nginx/ssl/meuguia.com.br.pem    # colar cert.pem
sudo nano /etc/nginx/ssl/meuguia.com.br.key    # colar key.pem
sudo chmod 600 /etc/nginx/ssl/meuguia.com.br.key
sudo chmod 644 /etc/nginx/ssl/meuguia.com.br.pem
```

### 4.4 — Config backend (api.meuguia.com.br)

```bash
sudo nano /etc/nginx/sites-available/api.meuguia.com.br
```

```nginx
# Backend API
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

    # Restringir a IPs Cloudflare (mitigar DDoS direto)
    include /etc/nginx/cloudflare-ips/restrict.cf.conf;

    # Uploads maiores que default
    client_max_body_size 20M;

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

    # Health check sem checar IP CF (usado por monitoring)
    location /health {
        allow all;
        satisfy any;
        proxy_pass http://127.0.0.1:8080/health;
    }
}
```

**NOTA:** `$cf_connecting_ip` é header real do visitante. Sem Cloudflare na frente seria `$remote_addr`.

### 4.5 — Restrição IPs Cloudflare (gerar dinamicamente)

```bash
sudo nano /etc/nginx/cloudflare-ips/restrict.cf.conf
```

```bash
#!/bin/bash
# Regenera lista IPs Cloudflare permitidos
OUT=/etc/nginx/cloudflare-ips/restrict.cf.conf
echo "# Auto-generated $(date)" > $OUT
echo "allow 127.0.0.1;" >> $OUT
for ip in $(curl -s https://www.cloudflare.com/ips-v4) $(curl -s https://www.cloudflare.com/ips-v6); do
    echo "allow $ip;" >> $OUT
done
echo "deny all;" >> $OUT
```

```bash
sudo chmod +x /etc/nginx/cloudflare-ips/restrict.cf.conf
sudo /etc/nginx/cloudflare-ips/restrict.cf.conf  # gera primeira vez
```

### 4.6 — Habilitar site

```bash
sudo ln -s /etc/nginx/sites-available/api.meuguia.com.br /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4.7 — Frontend (app.meuguia.com.br)

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

```bash
sudo ln -s /etc/nginx/sites-available/app.meuguia.com.br /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Bloco 5 — Backend Go binary nativo (30min)

### 5.1 — Setup estrutura

```bash
sudo mkdir -p /opt/meuguia/{api,front,backups,uploads,logs}
sudo chown -R deploy:deploy /opt/meuguia
```

### 5.2 — Install Go 1.24+

```bash
wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/go.sh
source /etc/profile.d/go.sh
go version
# esperado: go1.24.0 linux/amd64
```

### 5.3 — Clone do repo (deploy key)

```bash
# Na sua máquina local: gerar deploy key dedicada pro VPS
ssh-keygen -t ed25519 -C "vps-meuguia-deploy" -f ~/.ssh/meuguia-deploy
# Adicionar pub key como Deploy Key (read-only) no GitHub: repo Settings → Deploy keys

# No VPS:
cat ~/.ssh/meuguia-deploy.pub   # adicionar no GitHub
ssh-add ~/.ssh/meuguia-deploy   # já deixar carregada
```

```bash
cd /opt/meuguia/api
git clone git@github.com:pedro/meu-guia.git .
git checkout main
```

### 5.4 — Build

```bash
cd /opt/meuguia/api/meu-guia-api
go build -o /opt/meuguia/api/meuguia-api ./cmd/api
ls -lh /opt/meuguia/api/meuguia-api
# esperado: binário ~30-50MB
```

### 5.5 — `.env.prod`

```bash
sudo nano /opt/meuguia/api/.env
chmod 600 /opt/meuguia/api/.env
```

```bash
APP_ENV=production
APP_PORT=8080
APP_URL=https://api.meuguia.com.br
APP_FRONTEND_URL=https://app.meuguia.com.br

# DB
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=meuguia
DB_PASSWORD=<SENHA_POSTGRES_BLOCO_3>
DB_NAME=meuguiadb
DB_SSLMODE=disable

# JWT (gerar novo prod — NUNCA usar sandbox)
JWT_SECRET=$(openssl rand -hex 32)

# Uploads
UPLOAD_PATH=/opt/meuguia/uploads

# Asaas prod (Decio)
ASAAS_API_KEY=$$aact_prod_...
ASAAS_WALLET_ID=<UUID_PROD>
ASAAS_ENV=production
ASAAS_WEBHOOK_MODE=bearer
ASAAS_WEBHOOK_TOKEN=$(openssl rand -hex 32)
ASAAS_PLATFORM_FEE_PCT=10
```

### 5.6 — systemd service

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

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/meuguia/uploads /opt/meuguia/logs

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now meuguia-api
sudo systemctl status meuguia-api
# esperado: active (running)

sudo journalctl -u meuguia-api -f
# esperado: "🚀 Servidor rodando em http://localhost:8080"
# esperado: "💳 Asaas webhook habilitado" (se credenciais OK)
```

---

## Bloco 6 — Frontend Next.js (30min)

### 6.1 — Node 20 LTS + PM2

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version   # v20.x
npm --version

sudo npm install -g pm2
pm2 --version
```

### 6.2 — Clone + build

```bash
cd /opt/meuguia/front
git clone git@github.com:pedro/meu-guia.git .
git checkout main
cd meu-guia-front
npm ci --production=false
```

### 6.3 — `.env.prod`

```bash
nano /opt/meuguia/front/meu-guia-front/.env.production
```

```bash
NEXT_PUBLIC_API_BASE_URL=https://api.meuguia.com.br
NEXT_PUBLIC_APP_URL=https://app.meuguia.com.br
NODE_ENV=production
```

```bash
npm run build
# Aguardar ~1-2min, deve terminar com sucesso
```

### 6.4 — PM2

```bash
pm2 start npm --name "meuguia-front" -- start
pm2 save
pm2 startup systemd   # gera comando, copiar e rodar
# copiar o comando que aparece (sudo env PATH=... pm2 startup systemd -u deploy --hp /home/deploy)
```

```bash
pm2 list
# esperado: meuguia-front online
pm2 logs meuguia-front --lines 50
```

---

## Bloco 7 — DNS Cloudflare (15min — Pedro faz no painel)

Esperar Bloco 4 (Origin cert) pronto antes:

```
Tipo  Nome  Conteúdo        Proxy
A     api   <VPS_IP>        Proxied   # laranja
A     app   <VPS_IP>        Proxied
A     @     <VPS_IP>        Proxied   # meuguia.com.br raiz
CNAME www  meuguia.com.br   Proxied
```

**Tempo propagação:** 1-5min dentro Cloudflare, 24-48h fora (mas como SOA já tá no CF, é instantâneo).

---

## Bloco 8 — Testes smoke pós-deploy (Bloco 6 do checklist)

```bash
# 1. Backend health
curl -i https://api.meuguia.com.br/health
# esperado: 200, body {"status":"ok",...}

# 2. Frontend renderiza
curl -i https://app.meuguia.com.br
# esperado: 200, HTML com <title>Meu Guia Católico</title>

# 3. Webhook Asaas recebe POST vazio
curl -i -X POST https://api.meuguia.com.br/webhooks/asaas \
  -H "Content-Type: application/json" -d '{}'
# esperado: 400 (event_id required) — significa rota registrou

# 4. Asaas smoke binário (cria customer + sub real)
cd /opt/meuguia/api/meu-guia-api
set -a; source /opt/meuguia/api/.env; set +a
go run ./cmd/asaas-smoke
# esperado: customer + subscription IDs impressos
```

**Depois (Pedro no painel Asaas):**
- Marcar pagamento manual
- Checar log: `sudo journalctl -u meuguia-api -f` → webhook received
- Checar DB: `SELECT * FROM billing_events ORDER BY created_at DESC LIMIT 1;`
- Checar DB: `SELECT * FROM subscriptions ORDER BY updated_at DESC LIMIT 1;`

---

## Bloco 9 — Backups (45min)

### 9.1 — Backup Postgres (cron diário)

```bash
sudo mkdir -p /opt/meuguia/backups/db
sudo chown deploy:deploy /opt/meuguia/backups/db

sudo nano /opt/meuguia/backups/db/backup.sh
```

```bash
#!/bin/bash
# Backup Postgres diário
set -e
DATA=$(date +%Y%m%d_%H%M)
BACKUP_DIR=/opt/meuguia/backups/db
LOG=/opt/meuguia/logs/backup.log

mkdir -p $BACKUP_DIR
PGPASSWORD=$DB_PASSWORD pg_dump \
  -h 127.0.0.1 -U meuguia -d meuguiadb \
  -Fc -f $BACKUP_DIR/db_${DATA}.dump

# Apagar backups > 7 dias
find $BACKUP_DIR -name "db_*.dump" -mtime +7 -delete

echo "Backup $DATA OK" >> $LOG
```

```bash
chmod +x /opt/meuguia/backups/db/backup.sh

# DB_PASSWORD precisa estar disponível — alternativa via .pgpass
echo "127.0.0.1:5432:meuguiadb:meuguia:$DB_PASSWORD" > /home/deploy/.pgpass
chmod 600 /home/deploy/.pgpass
chown deploy:deploy /home/deploy/.pgpass
```

Refatorar backup.sh pra usar `.pgpass`:
```bash
sudo sed -i 's/^PGPASSWORD=.*/PGPASSFILE=\/home\/deploy\/.pgpass/' /opt/meuguia/backups/db/backup.sh
```

### 9.2 — Cron

```bash
sudo crontab -u deploy -e
```

Adicionar:
```
# Backup diário 03:00 UTC
0 3 * * * /opt/meuguia/backups/db/backup.sh

# Backup offsite (rsync pra Backblaze B2 / S3) — opcional
# 0 4 * * * /opt/meuguia/backups/db/offsite.sh
```

### 9.3 — Backup uploads (semanal)

```bash
sudo nano /opt/meuguia/backups/uploads-backup.sh
```

```bash
#!/bin/bash
DATA=$(date +%Y%m%d)
tar -czf /opt/meuguia/backups/uploads/uploads_${DATA}.tar.gz \
  /opt/meuguia/uploads
find /opt/meuguia/backups/uploads -name "uploads_*.tar.gz" -mtime +30 -delete
```

```bash
chmod +x /opt/meuguia/backups/uploads-backup.sh
sudo crontab -u deploy -e
```

Adicionar:
```
0 4 * * 0 /opt/meuguia/backups/uploads-backup.sh
```

### 9.4 — logrotate

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

---

## Bloco 10 — Monitoramento + alertas (20min)

### 10.1 — UptimeRobot free (externo)

- Criar conta em uptimerobot.com (free)
- Adicionar monitor HTTP(s):
  - `https://api.meuguia.com.br/health` → 5min check
  - `https://app.meuguia.com.br` → 5min check
- Email/SMS alerta se down

### 10.2 — Watchdog interno

```bash
sudo nano /opt/meuguia/backups/watchdog.sh
```

```bash
#!/bin/bash
# Se API down por >2min, tenta restart
if ! curl -sf http://127.0.0.1:8080/health > /dev/null; then
    if ! curl -sf http://127.0.0.1:8080/health > /dev/null; then
        systemctl restart meuguia-api
        echo "$(date) API down, restart triggered" >> /opt/meuguia/logs/watchdog.log
    fi
fi
```

```bash
chmod +x /opt/meuguia/backups/watchdog.sh
sudo crontab -u deploy -e
```

Adicionar:
```
*/5 * * * * /opt/meuguia/backups/watchdog.sh
```

---

## Bloco 11 — Deploy sem downtime (próximos deploys)

```bash
# Na máquina local
cd /path/to/meu-guia-api
git pull
./deploy.sh  # script que vamos criar
```

`deploy.sh` (na raiz do monorepo, Pedro criar):
```bash
#!/bin/bash
set -e
VPS="deploy@<VPS_IP>"
rsync -avz --exclude '.git' --exclude 'node_modules' \
  ./meu-guia-api/ $VPS:/opt/meuguia/api/meu-guia-api/
ssh $VPS << 'EOF'
  cd /opt/meuguia/api/meu-guia-api
  go build -o /opt/meuguia/api/meuguia-api ./cmd/api
  sudo systemctl restart meuguia-api
  sleep 2
  curl -sf https://api.meuguia.com.br/health && echo "API OK" || echo "API FAIL"
EOF
```

---

## Resumo Blocos × Tempo

| Bloco | Tempo | Responsável |
|-------|-------|-------------|
| 0 — Inputs | 5min | Pedro |
| 1 — SSH + hardening | 30min | Pedro |
| 2 — Pacotes base | 15min | Pedro |
| 3 — Postgres | 20min | Pedro |
| 4 — Nginx + CF | 45min | Pedro |
| 5 — Go backend | 30min | Pedro |
| 6 — Frontend Next | 30min | Pedro |
| 7 — DNS CF | 15min | Pedro |
| 8 — Smoke test | 15min | Pedro + Decio |
| 9 — Backups | 45min | Pedro |
| 10 — Monitor | 20min | Pedro |
| **Total** | **~4h** | **1 dia útil** |

**Pré-requisito paralelo enquanto Bloco 1-3 rodam:** email Decio pedindo Asaas prod key + wallet.

---

## Bloqueios ativos (do DEPLOY-CHECKLIST)

- **B1.1** Asaas prod key (Decio) — pode chegar no dia ou na semana
- **B1.2** Wallet ID (Decio) — idem
- **B1.4** Webhook URL cadastrada painel Asaas (Pedro, depois Bloco 7 pronto)
- **Frontend Asaas UI (F5)** separado desse deploy — pode ir depois

Tudo resto é independente.
