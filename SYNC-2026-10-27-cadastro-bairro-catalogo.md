---
name: Sync 2026-10-27 Cadastro de empresa com bairro do catalogo
description: Bairro virou selecao obrigatoria (catalogo) + campo numero do endereco; bugs de 500 no cadastro de cliente/empresa corrigidos; deploy prod ok
metadata:
  type: project
---

# Sync — 2026-10-27 (trabalho feito em 2026-10-23)

## TL;DR

- Backend `main` = `205eef9c` · Frontend `master` = `688cd8b` — **ambos no ar** (API na VPS, front na Vercel), CI verde.
- Entrega principal: **cadastro de empresa exige bairro do catálogo** (seleção obrigatória) + **campo "Número do endereço"**.
- Antes disso foram corrigidos dois 500 que quebravam o cadastro em produção (`consent_policies` e `contract_acceptances`/`service_orders` faltando no banco).
- Nada pendente de código nesta entrega. Próximos: SEO (Search Console / Perfil Google / conteúdo real) e UI do Asaas (F1–F6).

## Caminhos (mudaram desde 2026-09!)

```bash
BACK="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/backend"
FRONT="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/frontend"
SYNC="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/pedro-claude-guia-catolico"
```

Diretório antigo `C:/Users/conta/OneDrive/Desktop/meu-guia/` **não existe mais**.

## Estado dos repos

| Repo | Branch | Último commit | Árvore | CI |
|------|--------|---------------|--------|----|
| `meu-guia-api` (backend) | `main` | `205eef9c` feat(cadastro): bairro vem do catalogo + numero do endereco | limpa | ✅ success |
| `meu-guia-front` (frontend) | `master` | `688cd8b` feat(cadastro): busca de bairro com selecao obrigatoria + numero do endereco | limpa | ✅ success |

Suítes na última rodada: backend `go test ./...` 13/13 packages OK · frontend 42 arquivos / 264 testes OK + `tsc --noEmit` + `next build` OK.

## Entrega 1 — Cadastro de empresa: bairro do catálogo + número do endereço

Pedido do Pedro (verbatim):

> "No cadastro de uma empresa precisamos corrigir dois pontos:
> - Digitação e seleção dos dados: ... O usuário poderá digitar o endereço, mas precisará selecionar uma das opções disponíveis, pois os dados de localização precisam corresponder aos que já estão cadastrados na plataforma. (atualmente temos somente um bairro que possui ruas, precisamos deixar os usuarios digitar a rua e caso nao tenha ele pode deixar a rua que ele digitou.)
> - Número do endereço: também vou adicionar esse campo ao cadastro."

**Decisão de produto:** bairro = **seleção obrigatória** (valor gravado tem que ser uma linha de `neighborhoods`); rua = **texto livre** com sugestão da lista (poucas ruas catalogadas).

### Backend `205eef9c`

| Arquivo | O que mudou |
|---|---|
| `internal/services/company_address.go` | novo `resolveNeighborhood(db, city, name, slug)` — slug do cliente tem precedência, senão deriva do nome; busca presa na `region_id` da cidade (dois "Centro" em cidades diferentes não se misturam). `ValidateNeighborhood` (bairro fora do catálogo / inativo / de outra cidade → erro) e `ApplyNeighborhood` (grava nome+slug da **linha do catálogo**, não do texto digitado) |
| `internal/services/auth.go` | `RegisterCompanyInput.AddressNumber` (`address_number`, size 20) + validação do bairro/enderço; **validação do bairro vem DEPOIS do contrato** (erro de contrato é 422 com código próprio — a ordem não pode virar o erro que o usuário vê); persiste `address_number` |
| `internal/handlers/auth_test.go` | fixture semeia região + bairro do catálogo; payload usa `city: Feira de Santana` + `neighborhood: Centro`; novo caso "bairro fora do catálogo → 400 e nada gravado" |
| `internal/services/company_address_test.go` | `seedCatalogoBairros` agora cria a região e liga os bairros a ela; novos casos: número do endereço persistido, bairro fora do catálogo, bairro de outra cidade, bairro vazio, bairro inativo, cidade inexistente |

### Frontend `688cd8b`

| Arquivo | O que mudou |
|---|---|
| `components/ui/combobox.tsx` (novo) | input com busca: filtra ignorando acento/caixa, `role="combobox"` + `listbox` + `option`, setas/Enter/Esc, fecha ao clicar fora; **sem `onFreeText` o texto não selecionado é descartado no blur** (modo bairro); **com `onFreeText` o texto é mantido** (modo rua) |
| `components/dashboard/address-cascade.tsx` | Bairro = combobox com seleção obrigatória ("Digite para buscar e escolha um bairro da lista"); Rua = combobox com texto livre + sugestão |
| `components/auth/company-registration-form.tsx` | campo **"Número do endereço"** (placeholder `123, 45-A ou s/n`, hint "Use s/n se o local não tiver número"), ao lado do UF; `address_number` no payload |
| `lib/schemas.ts` / `lib/types.ts` | `address_number` opcional, max 20 |
| `tests/components/combobox.test.tsx` (novo) | 10 casos: filtro, acento/caixa, seleção, match exato no blur, texto livre, descarte do texto não selecionado, Enter, lista vazia, desabilitado |
| `tests/schemas.test.ts` | caso `address_number` (aceita / vazio / recusa 21 chars) |

## Entregas anteriores da mesma semana (já no ar)

| Commit (back) | O quê |
|---|---|
| `59dccd00` | `models.All()` — **registro único de models**; AutoMigrate de produção usava lista própria e faltavam tabelas → 500 `relation "contract_acceptances" does not exist` no cadastro de empresa. Guardas: `TestAll_CobreTodoStructDoPacote` + `TestAutoMigrate_CriaTabelasCriticas` |
| `3d55c913` | `consent_policies` faltando → 500 `SQLSTATE 25P02` no cadastro de cliente. `currentConsentVersion()` lê fora da tx + wrapper `ErroBanco` (SQL cru nunca vai pro browser) |
| `b197371e` / `ff2485a7` | 404 do contrato corrigido + PDF do contrato marcado binário no git e enviado no deploy |
| `752ecc59` | rotas anunciam o próprio link com esquema real |

| Commit (front) | O quê |
|---|---|
| `48c35f6` | links duplicados removidos (login + 2 cadastros), **olhinho de senha**, botão "Apoiar com Pix" removido, textos dos cards "Planos Flexíveis"/"Processo Simples" corrigidos, páginas `/termos` e `/privacidade` + links legais no footer |
| `4db39b0` | SEO: metadados por página, sitemap, robots, JSON-LD |

## Verificação real em produção (2026-10-23)

| Teste | Resultado |
|---|---|
| `POST /auth/register/company` com `neighborhood: Centro`, `address_number: 123` | **201** — banco gravou `neighborhood=Centro`, `neighborhood_slug=centro`, rua digitada mantida (`Rua Teste do Cadastro`), `address_number=123`, `status=pending` |
| `POST /auth/register/company` com `neighborhood: Bairro Que Nao Existe` | **400** — `bairro inválido: selecione um bairro da lista disponível` |
| `GET /regions` (público) | 1 região (Feira de Santana) — cidade travada |
| Página `/cadastrar/empresa` no ar | contém "Número do endereço" e o hint do novo campo |

Conta de teste do prod **apagada** depois (users 0, companies 0 para o email de teste).

## Catálogo de localização (estado real do banco prod, 2026-10-27)

- **43 bairros**, todos com `region_id`, todos da região Feira de Santana, nenhum inativo.
- **30 ruas** em **10 bairros** (3 por bairro) — Kalilândia, Ponto Central, Parque Ipê, Tomba, Conceição, Cidade Nova, São João, Centro, Brasília, Queimadinha. Os outros 33 bairros não têm rua catalogada → rua continua texto livre.
- **5 regiões** no banco; só `feira-de-santana` tem `is_featured=true` → `/regions` público devolve 1 e a cidade fica travada no formulário.

## Pipeline (como o deploy funciona hoje)

- **Backend** (`main` → GitHub Actions "Deploy Backend"): `go vet` + `go test` → build linux/amd64 (CGO off, `-trimpath`) → scp do binário + `docs/contracts/v1.pdf` → `install` em `/usr/local/bin/meu-guia-api` → `systemctl restart meu-guia-api` → health check em `127.0.0.1:8080/health` (30 tentativas).
- **Frontend** (`master` → GitHub Actions "Verificar Frontend"): typecheck + testes + build. **O deploy é da Vercel** (integração Git) — a VPS hospeda só a API.

Produção: API `https://api.meuguiacatolico.com.br/api/v1` · site `https://meuguiacatolico.com.br` · VPS Contabo `144.91.86.204` (Ubuntu 24.04, systemd `meu-guia-api`).

## Comandos prontos

```bash
# SSH na VPS — usar a chave do CI (NÃO pede passphrase)
ssh -o BatchMode=yes -i ~/.ssh/gh_actions_deploy root@144.91.86.204
# A chave pessoal ~/.ssh/id_ed25519 tem passphrase; o agent não está rodando.

# psql no banco de produção
ssh -i ~/.ssh/gh_actions_deploy root@144.91.86.204 \
  "sudo -u postgres psql -d meuguiadb -t -A -F'|' -c 'select ...;'"

# service + log
ssh -i ~/.ssh/gh_actions_deploy root@144.91.86.204 \
  "systemctl status meu-guia-api; journalctl -u meu-guia-api -n 50 --no-pager"

# Status do CI (sem gh CLI — token do credential helper)
TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | grep '^password=' | cut -d= -f2-)
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/Pedro-Wilker/meu-guia-api/actions/runs?per_page=3"

# Testes
cd "$BACK" && go test ./...
cd "$FRONT" && npx vitest run && npm run typecheck
```

## Pendências / próximos passos

| # | Item | Status |
|---|---|---|
| 1 | **SEO**: cadastrar no Google Search Console + Perfil Google + conteúdo real nas páginas | falta (base técnica pronta em `4db39b0`) |
| 2 | **Asaas UI no frontend** (F1–F6 do SYNC-2026-10-20): `SubscriptionCard` (empresa), `BillingEventsDashboard` (admin), `PaymentHistoryTable`, banner "Pagamento pendiente" | pendente |
| 3 | Asaas **produção**: API key + wallet ID do Décio | bloqueado (Depósito) |
| 4 | % final do split (sandbox = 10%) | Décio/negociação |
| 5 | Push das tags `planos-contrato-2026-09-13` / `asaas-sandbox-2026-09-23` | Pedro decide |
| 6 | Asaas ngrok/DNS prod pro webhook | Pedro decide infra |
| 7 | Stripe: manter ou remover (coexiste com Asaas) | Pedro decide |

## Armadilhas conhecidas (custaram tempo nesta sessão)

1. **`gofmt -w internal/services/*.go` reformatou o repo inteiro** — o working tree é CRLF (`core.autocrlf=true`) e o gofmt escreve LF. Isso gera diff de ruído em ~30 arquivos. Use `gofmt -w` só no arquivo editado, e se precisar reverter: `git checkout -- <arquivo>`.
2. **`git status` mostra "M" em arquivo sem diff real** — depois do gofmt, `git diff` fica vazio mas o status marca. `git add -A` normaliza.
3. **Model registry** (`internal/models/registry.go`) é a fonte única: AutoMigrate de produção e `testutil` consomem a MESMA lista. Não voltar a duplicar a lista em dois lugares — a classe de bug "tabela faltando só em prod" volta.
4. **Ordem das validações no `RegisterCompany`**: contrato antes da localização. Senão o 422 do contrato (que o front trata com redirect) vira 400 genérico.
5. **`slug` do bairro é a chave, não o nome** — mesmo nome em duas cidades exige o filtro por `region_id`.
6. **Grep no site live**: o chunk da rota tem parênteses (`static/chunks/app/(auth)/entrar/page-*.js`) — regex que exclui `(` não acha nada.
7. **VPS**: `~/.ssh/id_ed25519` tem passphrase e o agent não está rodando nesta máquina. Use `~/.ssh/gh_actions_deploy` (mesma chave que o CI usa, sem passphrase).
