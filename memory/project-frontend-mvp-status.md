---
name: project-frontend-mvp-status
description: "Status of the frontend MVP across all 6 phases — complete, with tests/lint/build clean"
metadata: 
  node_type: memory
  type: project
  originSessionId: b806adcb-527d-4390-a5f5-94e9acc18ced
---

**Projeto:** Meu Guia Católico — front + back.
**Repositório backend:** `Pedro-Wilker/meu-guia-api`.
**Local:** `C:\Users\conta\OneDrive\Documentos\projeto\artonbyte\meu-guia-catolico\`
(separado em `frontend/` e `backend/`).

**Frontend MVP — entregue em 2026-07-25** (todas as 6 fases do plano).

Stack: Next.js 15 (App Router) · React 19 · TypeScript · Tailwind CSS 3 ·
TanStack Query 5 · React Hook Form + Zod · Vitest + happy-dom.

Identidade visual: navy `#142B4B` · gold `#CAA972` · cream `#F8F4EC`. Logo SVG
pin + cruz em `components/layout/logo.tsx`.

Qualidade na entrega:
- `npm run build` — 15 rotas, 102 kB JS compartilhado, 0 erros.
- `npx tsc --noEmit` — 0 erros.
- `npx next lint` — 0 warnings.
- `npm test` — **45 testes** passando (5 arquivos em `tests/`).

Áreas implementadas:
- `(public)`: `/`, `/buscar`, `/empresas/[id]`, `/seja-um-parceiro`.
- `(auth)`: `/entrar`, `/cadastrar/cliente`, `/cadastrar/empresa`,
  `/esqueci-senha`, `/redefinir-senha`.
- `(company)/painel`: overview + `/painel/perfil`, `/painel/fotos`,
  `/painel/promocoes` (sidebar dedicada + AuthGuard).
- `(admin)/admin`: stats + fila de pendentes (approve/reject).

Bugs/quirks do backend tratados defensivamente:
- `data: null` → `ensureArray` antes de iterar.
- `/search` paginação DENTRO de `data` (sem `meta`) — normalizado no hook
  `useSearch` para `{ items, meta }`.
- `business_hours` pode ser `null` — fallback `{}`.
- `Promotion._is_active` → `isActive` na tipagem.
- URLs de imagem literais (sem prefixo API); validação de protocolo + fallback.
- Sem cookies — apenas `Authorization: Bearer` (CORS wildcard).
- Refresh mutex (`refreshPromise` em `lib/api.ts`) para 401s paralelos.
- 401 dispara refresh; 403 não.

**How to apply:** ao reabrir o projeto, o frontend já está completo. Próximas
melhorias (fora do MVP) estão listadas no README: upload real, integração
WhatsApp/Instagram, módulo Oportunidades, blog, IA, pagamento real.

Ver também: [[backend-dev-commands]] (como rodar backend/frontend localmente).
