# Commands — copy-paste prontos

## Setup inicial (uma vez por máquina)

```bash
cd "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api"
git status  # working tree limpo
git log --oneline -10  # ver últimos commits
MSYS_NO_PATHCONV=1 docker ps  # Docker vivo?
```

## Git

```bash
# Status
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" status
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" log --oneline -10
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" branch --show-current

# Diff
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" diff --stat HASH_BASE..HASH_HEAD
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" diff HASH_BASE..HASH_HEAD -- path/file.go

# Race condition check (Pedro?)
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" log --oneline BASE..HEAD
```

## Docker tests (back)

```bash
cd "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api"

# Build
MSYS_NO_PATHCONV=1 docker run --rm -v "/c/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api":/src -w /src golang:1.24-alpine sh -c "go build ./... 2>&1" | tail -15

# Test específico
MSYS_NO_PATHCONV=1 docker run --rm -v "/c/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api":/src -w /src golang:1.24-alpine sh -c "go test ./internal/services/ -v -run TestContract 2>&1" | tail -20

# Suite completa
MSYS_NO_PATHCONV=1 docker run --rm -v "/c/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api":/src -w /src golang:1.24-alpine sh -c "go test ./... 2>&1" | tail -20
```

## Front tests

```bash
cd "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-front"
npm run dev  # porta 3000
npx tsc --noEmit  # typecheck
npx vitest run  # testes
```

## Commit pattern

```bash
git add file1 file2 file3
git status
git commit -m "feat(scope): description curta

Detalhes adicionais se necessário.

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

## Tag final (Task 21)

```bash
git tag planos-contrato-2026-09-13
git push origin main --tags
```

## Backup sync

```bash
# Atualizar SYNC-AAAAMM-DD.md a cada task completa (opcional mas recomendado)
# Estrutura:
# pedro-claude-guia-catolico/
#   ├── SYNC-2026-09-14.md  (hoje)
#   ├── SYNC-2026-09-15.md  (próxima)
#   └── ...
```
