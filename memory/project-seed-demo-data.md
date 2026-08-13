---
name: project-seed-demo-data
description: "Seed demo adicionado em 2026-07-29 com 20 empresas fictícias, 6 clientes, 30+ reviews, 8 promoções; imagens via picsum.photos"
metadata: 
  node_type: memory
  type: project
  originSessionId: 230de1f1-9f61-48cb-a7d6-f58a28448235
---

Adicionado em 2026-07-29 para popular site durante desenvolvimento:

**Backend (`backend/internal/database/seed_demo.go`):**
- Função `SeedDemo(db)` idempotente — checa emails `demo-*@meuguia.local` antes de popular
- 6 clientes demo (senha `senha12345`)
- 20 empresas fictícias com logo + capa + 3 fotos + business_hours + categorias + regionID
- 30+ avaliações (ratings 3-5, com respostas da empresa em algumas)
- 8 promoções ativas em empresas destacadas (com subscription active)
- Wired em `cmd/api/main.go` após `SeedBaseData`
- Imagens: `picsum.photos/seed/<seed>-{logo|cover|p1|p2|p3}/<w>/<h>` (determinístico), avatares `i.pravatar.cc`

**Frontend fixtures (`frontend/lib/fixtures/`):**
- `jobs.ts` — 12 vagas (CLT/PJ/estágio) cobrindo 9 categorias
- `articles.ts` — 8 artigos (Direito, Saúde, Gastronomia, Educação, Turismo Religioso, Negócios, Beleza, Automotivo)

**Why:** Usuário pediu em 2026-07-29 que site tivesse visibilidade durante dev com dados fictícios + URLs de imagem.

**How to apply:** Rodar `docker-compose up -d --build` para popular. Frontend já mostra dados via API real (empresas, reviews, promoções). Vagas e artigos só via fixtures até FASE 4/6. Ver [[project-pending-fase-4-6-jobs-blog]].