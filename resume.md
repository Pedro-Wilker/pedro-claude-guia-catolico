# Resume — como retomar em outra máquina

## TL;DR

1. Abrir `pedro-claude-guia-catolico/`
2. Ler `SYNC-AAAAMM-DD.md` (mais recente) + `context.md`
3. Verificar git status (working tree deve estar limpo)
4. Continuar da próxima task do ledger

## Passo-a-passo detalhado

### 1. Verificar ambiente

```bash
cd "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api"
git status
# Esperado: working tree limpo

git log --oneline -10
# Esperado: último commit é o do SYNC

git branch --show-current
# Esperado: main

MSYS_NO_PATHCONV=1 docker ps
# Esperado: Docker Desktop rodando
```

### 2. Rodar suite pra confirmar saúde

```bash
cd "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api"
MSYS_NO_PATHCONV=1 docker run --rm -v "/c/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api":/src -w /src golang:1.24-alpine sh -c "go test ./... 2>&1" | tail -15
# Esperado: 9/9 packages OK, zero regressões
```

### 3. Identificar próxima task

Abrir `progress-ledger.md` e ver primeira task com `[ ]` (não-marcada).

Exemplo HOJE: próxima é **Task 7 — Handlers contract + rotas**.

### 4. Ler brief + report das tasks anteriores

Para entender contexto:

- `task-N-brief.md` (brief completo da task)
- `task-N-report.md` (o que foi feito)
- `tasks-N-review.md` (verdict do reviewer + findings)

Path: `C:\Users\conta\OneDrive\Desktop\meu-guia\.superpowers\sdd\`

### 5. Ler plan task detalhada

```bash
cd "C:/Users/conta/OneDrive/Desktop/meu-guia"
grep -A 100 "^### Task 7:" docs/superpowers/plans/2026-09-13-planos-contrato.md | head -100
```

### 6. Despachar implementer

Se você é Claude, criar brief file (`task-N-brief.md`) e despachar implementer subagent. Se você é Pedro, fazer manualmente seguindo o plan literal.

### 7. Após implementer → reviewer

- Implementer escreve `task-N-report.md` com hash do commit + outputs de teste
- Reviewer escreve `tasks-N-review.md` com verdict (APPROVED/NEEDS_FIX)
- Se NEEDS_FIX: dispatch fix subagent

### 8. Atualizar ledger + sync

- Marcar task como `[x]` em `progress-ledger.md`
- Atualizar SYNC-AAAAMM-DD.md com novo commit + próxima task
- (Opcional) criar novo SYNC se mudou muito

## Quando você NÃO tem Docker

```bash
# Tentar build/test direto no Go local (se tiver Go 1.24 instalado)
cd "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api"
go build ./...
go test ./...
```

Se Go local não disponível, pular testes e revisar código manualmente. **Não commitar sem testar** — deixar pendente até conseguir Docker.

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

## Quick reference: próximas tasks (2026-09-14)

| # | O que fazer | Bloqueio |
|---|-------------|----------|
| 7 | Handlers contract + rotas (3 endpoints) | Task 6 ✅ |
| 8 | Bloqueio signup empresa sem contract_acceptance | Task 7 |
| 9 | Migration service_orders + model | Task 5 ✅ |
| 10 | Service service_order + test flow | Task 9 |
| 11 | Handlers service_order + rotas | Task 10 |
| 12 | Migration subscription readjustment | Task 4 ✅ |
| 13 | Service subscription Cancel + ApplyReadjustment | Task 12 |

Detalhes completos no `progress-ledger.md`.

## Comandos rápidos (resumo)

```bash
# Status
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" status
git -C "C:/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api" log --oneline -5

# Build
MSYS_NO_PATHCONV=1 docker run --rm -v "/c/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api":/src -w /src golang:1.24-alpine sh -c "go build ./... 2>&1" | tail -10

# Test all
MSYS_NO_PATHCONV=1 docker run --rm -v "/c/Users/conta/OneDrive/Desktop/meu-guia/meu-guia-api":/src -w /src golang:1.24-alpine sh -c "go test ./... 2>&1" | tail -15
```

Lista completa em `commands.md`.
