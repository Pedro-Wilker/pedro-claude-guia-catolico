---
name: Sync 2026-10-28 Cadastro de empresa destravado
description: Bug que impedia o envio do cadastro de empresa (region_idUuid exigido e nunca enviado) + resumo de erros de validacao perto do botao
metadata:
  type: project
---

# Sync — 2026-10-28 (trabalho feito em 2026-10-28)

## TL;DR

- Bug reportado pelo Pedro: **no cadastro, clicar em "Enviar cadastro" não fazia nada** — nenhuma rota chamada, nenhum redirecionamento, nenhuma mensagem na tela.
- Causa raiz: `companyRegistrationSchema.region_id` era `z.string().uuid()` (obrigatório), mas o form **sempre enviava `""`** (input hidden que o `AddressCascade` nunca preenchia). A validação do Zod falhava **antes** do `try` do `submitValues` → nenhum POST, e o erro de `region_id` **não tem UI** → tela parada. Bug desde `40875f6` (2026-08-29), quando o campo virou hidden.
- Fix no frontend `master` = **`6048796`** (`fix(cadastro): destrava envio do cadastro de empresa + resumo de erros`) — **no ar** na Vercel.
- Verificado em produção: o form agora **manda o POST** com payload completo (`region_id` real, bairro do catálogo, categoria, consentimentos, contrato).
- Backend **não mudou** (`205eef9c`): ele já aceitava `region_id` vazio (`nilIfEmpty` → NULL).
- Pendente: apagar as contas de teste que sobraram no banco de produção (precisa de acesso SSH ao VPS — bloqueado por permissão do agente nesta sessão).

## Caminhos (não mudaram)

```bash
BACK="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/backend"
FRONT="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/frontend"
SYNC="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/pedro-claude-guia-catolico"
```

## Estado dos repos

| Repo | Branch | Último commit | Árvore | CI |
|------|--------|---------------|--------|----|
| `meu-guia-api` (backend) | `main` | `205eef9c` feat(cadastro): bairro vem do catalogo + numero do endereco | limpa | ✅ |
| `meu-guia-front` (frontend) | `master` | `6048796` fix(cadastro): destrava envio do cadastro de empresa + resumo de erros | limpa | ✅ success (Vercel no ar) |

Suítes: frontend **44 arquivos / 271 testes OK** · `tsc --noEmit` OK · `next build` OK · `next lint` sem warning novo.

## Causa raiz (evidência)

1. `frontend/lib/schemas.ts` (antes): `region_id: uuid` → `z.string().uuid("ID inválido.")`.
2. `frontend/components/auth/company-registration-form.tsx`: `defaultValues.region_id = ""` + `<input type="hidden" {...register("region_id")} />`. O `AddressCascade` preenche `city`, `neighborhood`, `neighborhood_slug` e `street` — **nunca** `region_id`.
3. `companyRegistrationSchema.safeParse({... region_id: ""})` → `ZodError: "ID inválido." path: ["region_id"]` — **sempre falha**.
4. `handleSubmit` chama `onInvalid` (nunca `submitValues`) → nenhum `api.contracts.getCurrent()`, nenhum `registerCompany`, nenhum redirect.
5. `onInvalid` só fazia `querySelector("[aria-invalid='true']")` — o input hidden de `region_id` não tem `aria-invalid` → foco em lugar nenhum → **nada muda na tela**.
6. No navegador (prod), antes do fix: nenhum POST para `/auth/register/company`.

## O que mudou (`6048796`)

| Arquivo | Mudança |
|---|---|
| `lib/schemas.ts` | `region_id` aceita `""` (ou UUID válido) — igual ao `companyProfileSchema`. Backend grava NULL e a empresa segue filtrável por cidade/bairro. |
| `lib/schemas.ts` | Consentimentos: **uma** issue só, citando os dois termos que faltam ("É obrigatório aceitar os Termos de Uso e a Política de Privacidade."). Antes eram dois issues no mesmo caminho → o RHF guardava só o último → a mensagem não batia com a caixa pendente. |
| `components/auth/company-registration-form.tsx` | Preenche `region_id` com o UUID da região selecionada (vinda de `/regions`) — empresa nasce com vínculo regional e some dos filtros por região. |
| `components/auth/registration-error-summary.tsx` (novo) | Resumo das falhas de validação **colado no botão de envio** (`role="alert"`, foco + scroll). O form é longo: erro longe do botão = "cliquei e nada aconteceu". |
| `components/auth/company-registration-form.tsx` / `client-registration-form.tsx` | `onInvalid` mostra o resumo em vez de só focar o primeiro `aria-invalid`; `values.consents.filter` foi para dentro do `try` (exceção ali zerava o form sem mensagem); `aria-invalid` no textarea de descrição. |
| `tests/components/company-registration-form.test.tsx` (novo) | Cadastro completo chega na API com bairro, categoria, região e consentimentos; submit inválido mostra o resumo e não chama a API. |
| `tests/components/client-registration-form.test.tsx` (novo) | Cliente válido envia; consentimento faltante barra e mostra o resumo. |
| `tests/schemas.test.ts` | `region_id` vazio aceito / lixo rejeitado; mensagem única de consentimento. |

## Verificação

**Local (vitest):** `npx vitest run` → 44 arquivos / 271 testes OK. `npx tsc --noEmit` OK. `npm run build` OK. `next lint` sem warning novo.

**Produção (bundle):** chunk `app/(auth)/cadastrar/empresa/page-*.js` contém o resumo novo (`"Não foi possível enviar o cadastro. Revise:"`).

**Produção (navegador real, POST interceptado/abortado — nenhuma conta criada):** o form de empresa **enviou** o payload:

```json
{ "email": "...", "city": "Feira de Santana",
  "region_id": "36a84670-2d20-45d4-8f9e-aa0e81b50a5b",
  "neighborhood": "Centro", "neighborhood_slug": "centro",
  "street": "Rua da Verificacao", "address_number": "123",
  "category_ids": ["84d27e74-3f89-4ec2-8526-8058fbf9fab8"],
  "consents": [{"type":"terms","granted":true},{"type":"privacy","granted":true}],
  "contract_version": "v1", "contract_hash": "c5c639a6…" }
```

Antes do fix: **nenhum POST**.

## Pendente

- **Limpar contas de teste no banco de produção.** Restaram `teste.debug.20261027@example.com`, `debug.browser.1793155228903@example.com` (cadastro de cliente) e possivelmente `emp.*` (empresa). Comandos (precisam de permissão de acesso ao VPS):

  ```bash
  ssh -i ~/.ssh/gh_actions_deploy root@144.91.86.204 "sudo -u postgres psql -d meuguiadb -c \"select id,email from users where email like 'teste.debug%' or email like 'debug.browser%' or email like 'emp.%' or email like 'verif.%';\""
  # deletar user + company + consents + contract_acceptance + audit_logs antes
  ```

- Trilhas abertas (sem mudança): **SEO** (Search Console / Perfil Google / conteúdo real) e **UI do Asaas** (F1–F6, `SYNC-2026-10-20-asaas8-real-e2e.md`).
