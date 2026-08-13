---
name: project-gaps-perf-2026-08-05
description: "Gaps fechados 2026-08-05 (aliases PT-BR, S3, decisão categorias) + otimizações perf (RSC cache, Suspense, dynamic imports, loading.tsx)"
metadata: 
  node_type: memory
  type: project
  originSessionId: fb7c6f96-00a1-4d22-8f63-1d4a90bc43bc
---

**Gaps fechados (FASE 5/6 + auditoria 2026-08-05):**

1. **Aliases PT-BR backend** — `routes.go` tem helpers `registerJobRoutes(g, ...)` e `registerArticleRoutes(g, ...)` montados em `/jobs`+`/oportunidades` e `/articles`+`/blog`. Frontend continua inglês; integrações externas podem usar PT-BR.
2. **S3 driver** — `internal/storage/s3.go` com AWS SDK v2. Config: `STORAGE_DRIVER=s3` + `S3_BUCKET`/`S3_REGION`/`S3_ACCESS_KEY_ID`/`S3_SECRET_ACCESS_KEY`/`S3_ENDPOINT`/`S3_PUBLIC_URL`. Suporta MinIO/R2 via endpoint custom + path-style. Default permanece filesystem.
3. **JobCategory/ArticleCategory** — decisão: NÃO criar tabelas separadas. Manter Category genérico compartilhado. Razão: comunidade pequena, CRUD duplicado, UX pior. Evolução futura = coluna `scope` se necessário.

**Otimizações perf (2026-08-05):**

- `lib/api.ts` `cacheProfile(path, method)` substituiu `cache: "no-store"` global: revalidate por path (10min estáticos, 60s lists, 120s reviews, no-store para auth/me/admin/mutações)
- Home `(public)/page.tsx`: removido await top-level, `CategoriesSection` agora em Suspense libera hero
- Loading states contextuais: `app/loading.tsx` skeleton completo, `app/(auth)/loading.tsx` form skeleton, `app/(admin)/admin/loading.tsx` table skeleton
- Dynamic imports: `CampaignWizard`, `CampaignDetail`, `DashboardSummary` com `ssr:false` + loading state. Bundle de `/admin/campanhas/nova` foi de inline para 3.23 kB
- `useCampaigns` staleTime 15s→60s; `useCampaignStats(id, status?)` pausa polling em terminais
- `next.config.ts`: removido `date-fns` morto de `optimizePackageImports`, removidos `picsum.photos`/`fastly.picsum.photos` de `remotePatterns`

**Status final build/test:**
- Frontend: TS 0 erros, lint 0 warnings, 15 test files / 111 testes passando, build 53 rotas / 102 kB shared
- Backend: `go build` OK, 6 packages testados OK

**Why:** usuario pediu fechar gaps ativos + suavizar lentidão.
**How to apply:** ao adicionar novas rotas server, usar `cacheProfile` automaticamente (já integrado). Ao criar componentes client >200L, aplicar dynamic import. Carregar dados em Suspense quando há hero above-the-fold.

Relacionado: [[project-audit-fases-3-7]], [[project-claude-md-auto-load]]