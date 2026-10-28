# Commands — copy-paste prontos

## Setup inicial (uma vez por máquina)

```bash
export BACK="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/backend"
export FRONT="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/frontend"
export SYNC="C:/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico/pedro-claude-guia-catolico"

git -C "$BACK" status    # working tree limpo
git -C "$FRONT" status
```

## Git

```bash
# Status
git -C "$BACK" status
git -C "$BACK" log --oneline -10
git -C "$BACK" branch --show-current
git -C "$FRONT" log --oneline -10
git -C "$FRONT" branch --show-current

# Diff
git -C "$BACK" diff --stat HASH_BASE..HASH_HEAD
git -C "$BACK" diff HASH_BASE..HASH_HEAD -- path/file.go

# Race condition check (Pedro?)
git -C "$BACK" log --oneline BASE..HEAD
```

## Testes backend

```bash
cd "$BACK"
go build ./...
go vet ./...
go test ./...              # 13/13 packages

# Test específico
go test ./internal/services/ -v -run TestRegisterCompany
```

## Testes frontend

```bash
cd "$FRONT"
npm run dev        # porta 3000
npm run typecheck  # tsc --noEmit
npx vitest run     # 42 arquivos / 264 testes
npm run build
```

## Produção

```bash
# Health
curl -s https://api.meuguiacatolico.com.br/health
curl -sI https://meuguiacatolico.com.br

# SSH na VPS — chave do CI (sem passphrase)
ssh -o BatchMode=yes -i ~/.ssh/gh_actions_deploy root@144.91.86.204

# Service + log
ssh -o BatchMode=yes -i ~/.ssh/gh_actions_deploy root@144.91.86.204 \
  "systemctl status meu-guia-api; journalctl -u meu-guia-api -n 50 --no-pager"

# psql no banco de produção (meuguiadb)
ssh -o BatchMode=yes -i ~/.ssh/gh_actions_deploy root@144.91.86.204 \
  "sudo -u postgres psql -d meuguiadb -t -A -F'|' -c \"select ...;\""

# Catálogo de localização
ssh -o BatchMode=yes -i ~/.ssh/gh_actions_deploy root@144.91.86.204 \
  "sudo -u postgres psql -d meuguiadb -t -A -F'|' -c \
  \"select (select count(*) from neighborhoods) bairros, (select count(*) from streets) ruas, (select count(*) from regions) regioes;\""
```

> A chave pessoal `~/.ssh/id_ed25519` tem passphrase e o `ssh-agent` não está rodando nesta máquina — use `~/.ssh/gh_actions_deploy`.

## CI (sem gh CLI)

```bash
TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | grep '^password=' | cut -d= -f2-)

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/Pedro-Wilker/meu-guia-api/actions/runs?per_page=3"

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/Pedro-Wilker/meu-guia-front/actions/runs?per_page=3"
```

## Deploy

```bash
# Backend: push em main dispara CI (test → build → VPS). Frontend: push em master
# dispara CI de qualidade; o deploy é da Vercel.
git -C "$BACK" push origin main
git -C "$FRONT" push origin master
```

## Commit pattern

```bash
git add file1 file2 file3
git status
git commit -m "feat(scope): description curta

Detalhes adicionais se necessário.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Backup sync

```bash
# Criar snapshot no fim de cada entrega
$EDITOR "$SYNC/SYNC-AAAAMM-DD-descricao.md"
git -C "$SYNC" add -A && git -C "$SYNC" commit -m "save: descricao curta"
git -C "$SYNC" push origin main
```
