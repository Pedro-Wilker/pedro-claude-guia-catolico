---
name: project-fix-404-detail-pages
description: "Páginas server de detalhe (/vagas/[slug], /blog/[slug], /profissionais/[slug]) agora fazem try/catch ApiError 404/403 e chamam notFound()"
metadata: 
  node_type: memory
  type: project
  originSessionId: fb7c6f96-00a1-4d22-8f63-1d4a90bc43bc
---

Fix aplicado em 3 páginas de detalhe server-side:

- `app/(public)/vagas/[slug]/page.tsx`
- `app/(public)/blog/[slug]/page.tsx`
- `app/(public)/profissionais/[slug]/page.tsx`

Padrão: `try { await api.xxx.get(slug) } catch (err) { if (err instanceof ApiError && (err.status === 404 || err.status === 403)) notFound(); throw err; }`

Causa original: `api.xxx.get` lança `ApiError` em 4xx. Server component sem catch crasha o request com stack trace.

Gatilho: usuário clicou em card stale de vaga (cache 60s) ou acessou URL `/vagas/demo-job-010` direto. Backend seed define demo-job-007/008/009/010 como Pending/Pending/Rejected/Closed (visíveis só para admin/dono).

**Why:** crash de runtime polui UX; 404 page do Next é a forma correta.
**How to apply:** ao adicionar novas páginas de detalhe server-side, sempre envolver fetch em try/catch com notFound() para 404/403.

Status: TS clean, lint clean, 111 testes passando. Build travou em `.next/trace` (lock Windows), não relacionado.

Relacionado: [[project-gaps-perf-2026-08-05]]