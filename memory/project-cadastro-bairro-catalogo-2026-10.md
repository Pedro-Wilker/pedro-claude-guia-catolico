---
name: project-cadastro-bairro-catalogo-2026-10
description: Cadastro de empresa exige bairro do catalogo + numero do endereco; 500s de prod corrigidos; estado do repo em 2026-10-27
metadata:
  type: project
---

# Cadastro de empresa — bairro do catálogo (2026-10-23, no ar)

Backend `main` = `205eef9c` · Frontend `master` = `688cd8b` — ambos em produção (API na VPS, front na Vercel).

**O que mudou:** bairro no cadastro de empresa virou **seleção obrigatória** — o usuário digita para buscar, mas precisa escolher uma linha de `neighborhoods`. Rua continua **texto livre** com sugestão (só 10 dos 43 bairros têm ruas catalogadas). Novo campo **"Número do endereço"** (`companies.address_number`, size 20).

**Por que:** bairro digitado à mão nascia empresa invisível nos filtros (o slug não resolvia).

**Como ficou no código:** `resolveNeighborhood(db, city, name, slug)` — slug do cliente tem precedência, senão deriva do nome, e a busca é presa na `region_id` da cidade. `ValidateNeighborhood` recusa bairro fora do catálogo/inativo/de outra cidade, **depois** da validação do contrato (erro de contrato é 422 com código próprio). `ApplyNeighborhood` grava nome+slug da linha do catálogo.

**Armadilhas que custaram tempo (repetir não):**
- `gofmt -w internal/services/*.go` reformatou ~30 arquivos (CRLF↔LF). Formatar só o arquivo editado.
- `models.All()` em `internal/models/registry.go` é a **fonte única** de models — AutoMigrate de prod e `testutil` consomem a mesma. Duas listas = drift (já faltou `consent_policies` e `contract_acceptances` em prod).
- `~/.ssh/id_ed25519` tem passphrase e o agent não roda; usar `~/.ssh/gh_actions_deploy` para SSH na VPS.

**Pendências:** SEO (Search Console + Perfil Google + conteúdo real) e UI do Asaas (F1–F6 do SYNC-2026-10-20). Detalhe em `pedro-claude-guia-catolico/SYNC-2026-10-27-cadastro-bairro-catalogo.md`.
