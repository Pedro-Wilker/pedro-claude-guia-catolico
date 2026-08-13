---
name: redesign-fase-7-telas-restantes
description: "Redeseign completo 6 fases finalizado 2026-08-12; 6 shells + 4 cards + AdminPageHeader consolidados; 222/222 vitest, build 53 rotas, smoke 200"
metadata: 
  node_type: memory
  type: project
  originSessionId: 25358daf-4813-4327-b687-3db0fa95f2bb
---

Redesign visual completo do frontend (6 fases), finalizado 2026-08-12:

**Fase 0** — Foundation: 4 shells extraidos (ListingShell/DetailShell/AuthShellLayout/DashboardShell), CarouselShell com variant+aspect (default/compact/banner), getBrandPanelVerse() com 12 versiculos rotativos.

**Fase 1** — Listagens: `/profissionais`, `/vagas`, `/blog` migradas pra ListingShell + sidebar sticky + grid PartnerCard. Novas JobCardV2/ArticleCardV2 com surface-elevated-interactive + font-display.

**Fase 2** — Detalhes: `/profissionais/[slug]`, `/vagas/[slug]`, `/blog/[slug]` migradas pra DetailShell com hero/tabs anchor/main/sidebar. Try/catch 404 preservado. Novo ShareButton (navigator.share + clipboard fallback).

**Fase 3** — Sub-paginas: `/profissionais/categorias/[slug]`, `/profissionais/regioes/[slug]`, `/buscar`, `/seja-um-parceiro` (hero navy-gradient + beneficios surface-elevated-interactive + CTA). `/empresas/[id]` ja usava CompanyProfile.

**Fase 4** — Paineis+admin: 15 paginas com AdminPageHeader (eyebrow+icone+titulo+description+action). AdminTabs pill, AdminStats, surface-elevated consistente. CTAs "Nova vaga", "Novo artigo", "Adicionar banner".

**Fase 5** — Auth+conta: 5 auth pages ja usavam PageHeader + AuthShellLayout (split 2-col + brand panel verse). `/conta/candidaturas`+`/conta/dados` — font-serif→font-display (4 ocorrencias).

**Fase 6** — Banner+global: BannerCarousel refatorado pra CarouselShell variant=banner. Click tracking via api.banners.trackClick(id) ja wired.

**Validacao final**: TS 0, lint 0 (so warning pre-existente em banner-upload-form.tsx), 222/222 vitest, build 53 rotas, smoke 200 em 10 rotas-chave.

**Proxima fase (2026-08-12)**: usuario vai passar telas quebradas/feias pra corrigir design + mal funcionamento. Backend Go ativo PID 21588 (porta 8080) + frontend Next.js (porta 3000) para reproduzir bugs.

**How to apply**: ao retomar, usar admin-headers e shells existentes; manter superficie tokens + font-display consistente; TDD com looping validation por task; verificar TS+lint+vitest+build antes de declarar done.

Link: [[project-redesign-completo]]
