# SETUP — pedro-claude-guia-catolico

Configurar device novo com config Claude Code do projeto **meu-guia-catolico**.

## Passo a passo

### 1. Clonar repo de config

```bash
cd /c/Users/conta/OneDrive/Documentos/projeto/artonbyte
git clone https://github.com/Pedro-Wilker/pedro-claude-guia-catolico.git
```

Cria `pedro-claude-guia-catolico/` ao lado de `meu-guia-catolico/`.

### 2. Rodar setup.sh

```bash
cd pedro-claude-guia-catolico
chmod +x setup.sh
./setup.sh
```

Script:
- Detecta `~/.claude/projects/<hash>/memory/` (Windows/Linux/Mac)
- Copia `memory/*.md` → path do device
- Gera `.claude/settings.local.json`

### 3. Validar

```bash
ls ~/.claude/projects/*/memory/MEMORY.md
ls .claude/settings.local.json
ls ../meu-guia-catolico/CLAUDE.md
```

### 4. Testar

Iniciar Claude Code na raiz `meu-guia-catolico/`. Falar **"onde paramos"**.

## Salvar progresso

```bash
cd pedro-claude-guia-catolico
cp ~/.claude/projects/*/memory/*.md memory/
cp ../meu-guia-catolico/CLAUDE.md CLAUDE.md
git add . && git commit -m "chore: salva progresso YYYY-MM-DD" && git push
```

## Próximo device

```bash
git pull --ff-only
./setup.sh
```