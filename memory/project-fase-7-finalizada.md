---
name: project-fase-7-finalizada
description: "FASE 7 Campanhas email finalizada 2026-08-01 — 14 endpoints admin, worker in-process, wizard frontend, LGPD via consent"
metadata: 
  node_type: memory
  type: project
  originSessionId: 03fb4c1c-6665-4b11-a372-f17f66548a2b
---

FASE 7 (campanhas de email) finalizada em 2026-08-01. Escopo acordado com cliente: apenas canal email, combinando base CSV do cliente + base da plataforma. WhatsApp/Instagram ficaram em **standby** (cliente não contratou).

**Decisões fixadas:**
- Canal: `email` apenas.
- CSV: header `email,nome[,telefone]`, max 5MB/50k linhas, dedup por email normalizado (lowercase+trim).
- Worker: in-process (goroutine + ticker), sem Redis/BullMQ. Rate 100/min, batch 50, tick 30s.
- Scheduling: imediato ou `scheduled_at` futuro (worker promove scheduled → sending no tick).
- LGPD: base plataforma filtra `consents WHERE type=marketing AND granted=true AND revoked_at IS NULL`. Base CSV do cliente bypassa consent (cliente é controlador). AuditLog por envio (`resource=campaign_dispatch`).

**Stack entregue:**
- Backend: 14 endpoints `/admin/campaigns*` + `/admin/client-contacts/lists*`, 4 models novos (Campaign, CampaignRecipient, ClientContactList, ClientContact), CampaignService + CampaignDispatchWorker + 2 handlers, AutoMigrate + wiring em `main.go` com lifecycle Start/Stop do worker.
- Frontend: 4 páginas (`/admin/campanhas`, `/nova`, `/[id]`, `/admin/bases`), wizard 3 passos, polling 3s durante `sending`, hooks `use-campaigns` + `use-client-contacts`.

**Qualidade final:**
- Backend Go: `ok services 3.5s` — 21 testes novos (10 CSV + 11 Campaign). `go build ./...` limpo.
- Frontend: 106 testes vitest passam (15 arquivos), `tsc --noEmit` 0 erros.
- OpenAPI: 14 endpoints novos em `docs/openapi.yaml`.
- Relatório: `backend/relatorio-fase-7.md` lista divergências + próximos passos.

**Por:** [[project-jobs-blog-backend-completo]] é o estado anterior; [[project-fase-3-lgpd-status]] é a base LGPD reutilizada.

**Como aplicar:** ao retomar em FASE 8 ou pós-venda, ler `relatorio-fase-7.md` para visão executiva e `docs/superpowers/specs/2026-08-01-fase-7-campanhas.md` para spec completa.