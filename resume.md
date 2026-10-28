# Resume — como retomar em outra máquina

## TL;DR

1. Abrir `pedro-claude-guia-catolico/`
2. Ler `SYNC-2026-10-28-cadastro-empresa-bloqueado.md` (mais recente) + `context.md`
3. Verificar git status dos 2 repos (working tree deve estar limpo)
4. Continuar da próxima task do ledger

## Caminhos (valem em 2026-10)

```bash
BACK="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/backend"
FRONT="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/frontend"
SYNC="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/pedro-claude-guia-catolico"
```

O caminho antigo `C:/Users/conta/OneDrive/Desktop/meu-guia/` não existe mais.

## Passo-a-passo detalhado

### 1. Verificar ambiente

```bash
cd "$BACK"
git status            # esperado: working tree limpo
git log --oneline -5  # esperado: 205eef9c no topo
git branch --show-current  # esperado: main

cd "$FRONT"
git log --oneline -5  # esperado: 6048796 no topo
git branch --show-current  # esperado: master
```

### 2. Rodar suite pra confirmar saúde

```bash
cd "$BACK" && go build ./... && go test ./...
# esperado: 13/13 packages OK

cd "$FRONT" && npx vitest run && npm run typecheck
# esperado: 44 arquivos / 271 testes OK
```

Sem Docker: Go 1.24 e Node 20 instalados local funcionam (o repo é testado direto aqui).

### 3. Identificar próxima task

Abrir `progress-ledger.md` e ver a primeira task com `[ ]` (não-marcada).

Hoje as trilhas abertas são: **SEO** (Search Console / Perfil Google / conteúdo real) e **UI do Asaas** (F1–F6 do SYNC-2026-10-20). O PRD `planos-contrato-2026-09-13` já está todo entregue.

### 4. Ver produção

```bash
# API
curl -s https://api.meuguiacatolico.com.br/health
# Site
curl -sI https://meuguiacatolico.com.br

# VPS (chave do CI, sem passphrase)
ssh -o BatchMode=yes -i ~/.ssh/gh_actions_deploy root@144.91.86.204 \
  "systemctl is-active meu-guia-api; journalctl -u meu-guia-api -n 30 --no-pager"
```

### 5. Ler brief + report das tasks anteriores

Para tasks do fluxo SDD: `task-N-brief.md`, `task-N-report.md`, `tasks-N-review.md` em `.superpowers/sdd/`.

### 6. Despachar implementer

Se você é Claude, criar brief file (`task-N-brief.md`) e despachar implementer subagent. Se você é Pedro, fazer manualmente seguindo o plan literal.

### 7. Após implementer → reviewer

- Implementer escreve `task-N-report.md` com hash do commit + outputs de teste
- Reviewer escreve `tasks-N-review.md` com verdict (APPROVED/NEEDS_FIX)
- Se NEEDS_FIX: dispatch fix subagent

### 8. Atualizar ledger + sync

- Marcar task como `[x]` em `progress-ledger.md`
- Atualizar/criar `SYNC-AAAAMM-DD.md` com novo commit + próxima task
- Commit + push do diretório de sync (repo `pedro-claude-guia-catolico`)

## Quando você NÃO tem Go/Node local

```bash
MSYS_NO_PATHCONV=1 docker run --rm -v "$BACK":/src -w /src golang:1.24-alpine sh -c "go test ./... 2>&1" | tail -15
```

Se não tiver Docker também, pular testes e revisar código manualmente. **Não commitar sem testar** — deixar pendente até conseguir rodar.

## Quando git está dirty (Pedro mexeu)

```bash
git status  # ver o que mudou
git diff    # ver diff
```

Opções:
- **Mudanças são suas** (ex: progresso da task anterior): `git stash` → implementar nova task → `git stash pop`
- **Mudanças são do Pedro**: parar e perguntar via SendMessage ou comentário no SYNC

## Quando tem conflito de merge

```bash
git status  # identificar arquivos em conflito
git diff <file>  # ver conflito
# Resolver manualmente
git add <file>
git commit  # completa o merge
```

## Armadilhas (ler antes de mexer)

- `gofmt -w` em pasta inteira gera diff de ruído (CRLF↔LF). Formatar só o arquivo editado.
- `git status` pode marcar "M" sem diff real — `git add -A` normaliza.
- AutoMigrate de produção e `testutil` consumem `models.All()` — nunca duplicar a lista de models.
- Ordem no `RegisterCompany`: contrato (422) ANTES da localização (400).
- `~/.ssh/id_ed25519` tem passphrase e o agent não está rodando — use `~/.ssh/gh_actions_deploy`.

## Comandos rápidos (resumo)

```bash
git -C "$BACK" status
git -C "$BACK" log --oneline -5
git -C "$FRONT" log --oneline -5

cd "$BACK" && go test ./...
cd "$FRONT" && npx vitest run
```

Lista completa em `commands.md`.
