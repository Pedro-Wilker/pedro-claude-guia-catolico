# pedro-claude-guia-catolico

Configuração Claude Code dedicada ao projeto **meu-guia-catolico**.

**Repo:** https://github.com/Pedro-Wilker/pedro-claude-guia-catolico.git

## Setup device novo

```bash
cd /c/Users/conta/OneDrive/Documentos/projeto/artonbyte/meu-guia-catolico
git clone https://github.com/Pedro-Wilker/pedro-claude-guia-catolico.git
cd pedro-claude-guia-catolico
./setup.sh
```

## Salvar progresso

```bash
cp ~/.claude/projects/*/memory/*.md memory/
cp ../meu-guia-catolico/CLAUDE.md CLAUDE.md
git add . && git commit -m "chore: salva progresso YYYY-MM-DD" && git push
```

## Outros repos

- `pedro-claude-unni` — UnniChat
- `pedro-claude-gitlab` — 4 sistemas SAEB
- `pedro-claude-guia-catolico` — você está aqui