---
name: project-fase-3-listings-details
description: "FASE 3 (cards+chips+headers) finalizada 2026-08-11 — PartnerCard nas listagens, CategoryChips helper, VerifiedBadge no detalhe, font-display polish"
metadata: 
  node_type: memory
  type: project
  originSessionId: 70194c7e-67c5-4acf-b701-35f0fcb8032a
---

FASE 3 do redesign (cards nas listagens + chips de categoria + headers) fechada em 2026-08-11.

**Mudanças:**
- `components/search/search-results.tsx`: CompanyCard → PartnerCard
- `app/(public)/profissionais/[slug]/page.tsx`: VerifiedBadge inline no h1
- `components/partner/category-chip.tsx`: slug opcional + prop `href` (override do default `/profissionais?category=...`)
- `components/partner/category-chips.tsx` (NOVO): helper server component para rails de chips em listagens; aceita `paramKey` + `basePath` (suporta `category_id` em vagas/blog, `category` em profissionais)
- `app/(public)/profissionais/page.tsx`, `vagas/page.tsx`, `blog/page.tsx`: + CategoryChips, fetch de categorias, font-serif → font-display
- `components/jobs/job-list-wrapper.tsx`: passa `category_id` pro useJobs
- `app/(public)/profissionais/categorias/[slug]/page.tsx`, `regioes/[slug]/page.tsx`, `buscar/page.tsx`: font-serif → font-display
- `tests/partner/category-chip.test.tsx`: cast `firstChild as HTMLElement | null` p/ TS strict
- `app/(auth)/layout.tsx`: quotes escapados p/ ESLint react/no-unescaped-entities

**Validação:** tsc CLEAN, lint CLEAN (1 warning pre-existente em banner-upload-form), vitest 186/186 PASS. Build não confirmado (rodava em background, user cortou — validar depois).

**Por que:** partner components (Phase 1) e home (Phase 2) já estavam prontos; faltava fechar ciclo nas listagens/detalhes antes de partir pra Phase 4 (admin/company painéis).

**Como aplicar:** ao criar nova listagem, importar CategoryChips de `@/components/partner/category-chips` com `paramKey` + `basePath` corretos. Qualquer h1 de página pública deve usar `font-display text-4xl text-navy sm:text-5xl tracking-tight`. Detalhes públicos sempre devem mostrar VerifiedBadge inline.
