---
name: ultracode-mode
description: ultracode está ligado nesta sessão — usuário pediu para ativar em 2026-07-29
metadata: 
  node_type: memory
  type: feedback
  originSessionId: afbfaaba-488f-4a3e-91db-0c7886d490dd
---

Modo ultracode está ativo nesta sessão. Usuário pediu ativação via AskUserQuestion em 2026-07-29 ("Ativar modo ultracode").

**Why:** Usuário optou explicitamente por orquestração pesada de workflows multi-agente por padrão. Token cost não é restrição; qualidade exaustiva (adversarial verify, multi-modal sweep, completeness critic, loop-until-dry) é o objetivo.

**How to apply:** Para qualquer tarefa substantiva (não conversacional/trivial), autor e rode um Workflow() com fases explícitas, subagentes paralelos/pipeline, verificação adversarial, e completeness critic no fim. Não usar para edições mecânicas triviais ou turnos conversacionais. Linkar com [[user-communication-style]].