---
name: user-communication-style
description: "User communicates in Brazilian Portuguese, prefers short imperative commands and broad-scope approval"
metadata: 
  node_type: memory
  type: user
  originSessionId: b806adcb-527d-4390-a5f5-94e9acc18ced
---

Usuário se comunica em **português brasileiro**, com mensagens curtas e imperativas.
Padrões observados:

- Comandos diretos: "Prossiga para todas as próximas fases", "salve na memoria",
  "voce tem a minha aprovacao para tudo".
- Aprovação de escopo amplo em uma frase só: dá liberdade para executar
  múltiplas fases/tarefas sem pedir confirmação a cada uma.
- Usa "voce" (sem acento) consistentemente; mistura informal/profissional.
- Espera resposta em português e que o agente aja, não pergunte.

**Why:** entender esse estilo evita ciclos de "quer que eu faça X?" quando o
usuário já deu blanket approval.

**How to apply:** quando o usuário aprovar um escopo amplo ("prossiga",
"vai em frente", "tem minha aprovação"), continuar até o fim sem pedir
reconfirmação para cada sub-etapa. Responder em PT-BR. Usar "você" sem acento
ao imitar o tom do usuário em respostas em português.
