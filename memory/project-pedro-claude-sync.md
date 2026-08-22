---
name: project-pedro-claude-sync
description: Setup cross-device Claude Code sync via repo dedicado pedro-claude-guia-catolico
metadata: 
  node_type: memory
  type: project
  originSessionId: d18fe4f0-761e-49f2-a57d-1d8086bd3ca4
---

Repo cross-device criado 2026-08-13 em `pedro-claude-guia-catolico/` (sibling de `meu-guia-catolico/`). GitHub: https://github.com/Pedro-Wilker/pedro-claude-guia-catolico.git

**Estrutura:** README.md, CLAUDE.md (mirror + Regra 0), SETUP.md, setup.sh (detect OSTYPE), settings.json.template (sed __PROJECT_ROOT__/__HOME__), .gitignore (local/env/secrets), memory/ (17 .md + MEMORY.md).

**Fluxos:**
- "onde paramos" → `git -C pedro-claude-guia-catolico pull --ff-only` + ler memory/MEMORY.md
- "salvar progresso" → cp memory/*.md + CLAUDE.md → commit → push
- Device novo → `git clone … && ./setup.sh`

**Regra 0** adicionada ao CLAUDE.md raiz e mirror: cross-device sync → `pedro-claude-guia-catolico/SETUP.md`.

**Não usar:** agents/, commands/, hooks/ (zero custom). settings.local.json gitignored.

**Why:** Continuar trabalho entre devices sem perder contexto de fases, fixes, decisões.
**How to apply:** Em qualquer sessão deste projeto, se user falar "onde paramos" ou "salvar progresso", seguir fluxo acima antes de qualquer outra ação.

Relacionado: [[project-claude-md-auto-load]]