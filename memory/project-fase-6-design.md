---
name: project-fase-6-design
description: "FASE 6 Blog/Artigos — design aprovado 2026-08-01, aguardando plano de implementação. 5 fatias: 6A empresa / 6B admin artigos / 6C admin comentários / 6D testes backend / 6E testes frontend+LGPD+OpenAPI+seed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 78650904-d617-4da4-bb78-73ce28db0de7
---

# FASE 6 — Blog / Artigos (design aprovado 2026-08-01)

## Estado atual
Backend já completo: `models/article.go` (Article + ArticleComment + status draft/pending/approved/rejected), `services/article.go` + `article_comment.go` (CRUD + moderação + slug + estimateReadingMinutes), `handlers/article.go` + `article_comment.go`, rotas em `routes.go` (público + autenticado + admin).
Frontend público OK: `/blog` (lista aprovados) + `/blog/[slug]` (artigo + CommentForm + CommentList). `lib/api.ts` tem `articles.*` e `articleComments.*` completos.

**Faltam:** painéis empresa/admin, testes backend services, testes frontend, LGPD nos comentários, OpenAPI dos 11 endpoints, seed demo, script de cleanup.

## Decisões de produto (aprovadas)
- Comentários: fila de aprovação obrigatória (LGPD-safe).
- Artigos de empresa: sempre passam por admin (não auto-publica).
- UI: replicar padrões existentes (`/painel/artigos`, `/admin/artigos`, `/admin/comentarios`).
- Conteúdo: markdown com sanitização (`react-markdown` + `rehype-sanitize` + `remark-gfm`).

## Plano em 5 fatias (~19h total)
| # | Entrega | Esforço |
|---|---------|---------|
| 6A | Painel empresa (rotas + ArticleManager + ArticleForm + useMyArticles hook) | ~6h |
| 6B | Admin artigos (ArticleQueue + página review + moderate) | ~3h |
| 6C | Admin comentários (CommentQueue + approve/reject) | ~2h |
| 6D | Testes backend (article_test + article_comment_test + extrair testutil/db.go) | ~4h |
| 6E | Testes frontend (ArticleContent/Form/CommentItem + useArticles) + LGPD `user.first_name` + OpenAPI + seed | ~4h |

## LGPD nos comentários
- Mostrar apenas `user.first_name` (split no primeiro espaço).
- `cmd/cleanup/main.go` apaga `is_approved=false` > 90 dias.
- Audit log em `/me/data` já cobre exclusão de conta (LGPDService existente).

## Arquivos novos
Backend:
- `services/article_test.go`, `services/article_comment_test.go`
- `testutil/db.go` (extrair de `middleware/auth_test.go`)
- `cmd/cleanup/main.go` (opcional, fora do MVP pode)
- `docs/openapi.yaml` — seção `/articles` com 11 endpoints

Frontend:
- `app/(company)/painel/artigos/{page,novo/page,[id]/page}.tsx`
- `app/(admin)/admin/artigos/{page,[id]/page}.tsx`
- `app/(admin)/admin/comentarios/page.tsx`
- `components/blog/{article-form,comment-item}.tsx`
- `components/dashboard/article-manager.tsx`
- `components/admin/{article-queue,comment-queue}.tsx`
- `hooks/{use-articles,use-article-comments}.ts`
- Tests: `tests/components/blog/*.test.tsx` + `tests/hooks/*.test.ts`

Dependências: `react-markdown`, `rehype-sanitize`, `remark-gfm`.

## Critérios de aceite
1. Empresa em `/painel/artigos` lista + cria (pending) + edita + exclui.
2. Admin em `/admin/artigos` modera pending → approved popula `published_at`.
3. Admin em `/admin/comentarios` aprova/rejeita.
4. Cliente comenta → vai para fila.
5. `/blog` lista só `approved`; `/blog/[slug]` mostra artigo + comentários `is_approved=true`.
6. Comentários públicos expõem só `user.first_name`.
7. Seed idempotente: 6 artigos + 6 comentários.
8. OpenAPI lista 11 endpoints.
9. Coverage services ≥ 80%; testes frontend OK.
10. Build limpo, typecheck 0, lint 0, 100% tests.

## Spec completo
`docs/superpowers/specs/2026-08-01-fase-6-blog-design.md`

**Why:** checkpoint do design aprovado para retomar execução.
**How to apply:** invocar `superpowers:writing-plans` para gerar plano de implementação detalhado a partir desta spec; executar na ordem 6A→6E.
