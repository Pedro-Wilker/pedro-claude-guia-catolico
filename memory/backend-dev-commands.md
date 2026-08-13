---
name: backend-dev-commands
description: How to start backend and frontend dev servers locally
metadata: 
  node_type: memory
  type: project
  originSessionId: b806adcb-527d-4390-a5f5-94e9acc18ced
---

**Ambiente:** Windows 10 Pro (`win32`), shell Git Bash no Claude Code.

**Backend** (Go + Gin + GORM; porta 8080):

```bash
cd "C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/backend"
docker compose up -d --build        # recomendado
# Health check:
curl http://localhost:8080/health
```

**Frontend** (Next.js; porta 3000):

```bash
cd "C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/frontend"
cp .env.example .env.local          # se for a primeira vez na sessão
npm install                        # se node_modules não existir
npm run dev                        # http://localhost:3000
```

**Contas seed documentadas no README:**
- Admin: `admin@meuguiacatolico.com` / `admin123456`
- Empresa: `contato@padariafeira.com` / `senha12345` (se existir)
- Cliente: `maria@cliente.com` / `senha12345` (se existir)

**Limitações de processo:** o agente (Claude) não consegue manter serviços
em background entre turnos do usuário. O usuário roda os servidores em
terminais próprios; o agente só consegue iniciá-los enquanto o turno está
ativo.

**Why:** evitar troubleshooting desnecessário quando o usuário reporta
"site não carrega" — provavelmente é o backend/frontend que não está rodando.

**How to apply:** quando o usuário pedir para rodar ou verificar algo,
lembrá-lo de iniciar ambos os servidores primeiro. Os processos do backend
também foram patcheados (ver [[project-frontend-mvp-status]]): rotas
estáticas antes de `/:id`, `CompanyRequired` em `/subscriptions/me/*` e
`/companies/me/photos`.

Ver também: [[project-frontend-mvp-status]].
