---
name: project-fixes-buscar-blog
description: Fixes aplicados em /buscar e /blog durante Fases A→C
metadata:
  type: project
---

**`/buscar`:**
- SearchFilters duplicado (sidebar do ListingShell + dentro de SearchResults). Removido o de dentro; SearchResults agora só lista cards.
- Inputs livres Cidade/UF substituídos por selects cascateados Bairro→Rua (mod #4).
- Cidade destacada (Feira) como badge visual fixa (tr cidade mod #1).

**`/blog`:**
- Cards pequenos: ListingShell sempre aplicava `lg:grid-cols-[280px_1fr]` mesmo sem sidebar, comprimindo a coluna main. Fix: renderizar grid só quando `sidebar` setado; sem sidebar, full-width.
- Post `/blog/[slug]`: header (card título) colidia com cover/compartilhar. Fix: `mb-8` no `<header>` do hero.

**Backend (mod #4 cascata):**
- `GET /neighborhoods?city_slug=<slug>` e `GET /streets?neighborhood_slug=<slug>` (query string evita conflito Gin com `:id`).
- Backend filtra Company/Search por `LOWER(neighborhood)` e `LOWER(street)`.

**Why:** User pediu esses fixes como pre-requisito antes de Fase B.
**How to apply:** Validar visualmente ao tocar `/buscar` e `/blog` no próximo device.