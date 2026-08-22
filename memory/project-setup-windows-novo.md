---
name: project-setup-windows-novo
description: Setup do projeto em novo device Windows (Postgres local + Docker)
metadata:
  type: project
---

**Stack deste device:**
- Windows 11, sem Go nativo (backend roda via Docker)
- Docker Desktop + Node
- Postgres 17 LOCAL (não Docker): DB `meuguiadb`, user `postgres`, senha `161011`
- Backend roda via Docker e acessa host Postgres via `host.docker.internal`

**Configuração crítica:**
- `meu-guia-api/docker-compose.yml`: sem serviço postgres, `extra_hosts: ["host.docker.internal:host-gateway"]`
- `meu-guia-api/.env`: `DB_HOST=host.docker.internal`, `DB_NAME=meuguiadb`, `DB_PASSWORD=161011`
- `meu-guia-api/Dockerfile`: `golang:1.24-alpine` (go.mod exige 1.24)
- `meu-guia-front/.env.local`: `NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1`

**Why:** Setup inicial em 2026-08-22; user tem Postgres local e Node/Docker, não Go.
**How to apply:** Ao recriar device, replicar essas configs antes de subir backend.