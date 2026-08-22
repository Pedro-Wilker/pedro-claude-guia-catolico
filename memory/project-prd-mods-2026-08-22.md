---
name: project-prd-mods-2026-08-22
description: Status do PRD de modificações pendentes (Fases A→D)
metadata:
  type: project
---

PRD criado em 2026-08-22 (`docs/superpowers/specs/2026-08-22-prd-modificacoes-pendentes.html`) com 4 fases + build→review→fix loop.

**Entregue:**
- Fase A — Backbone: mods #1 (tr cidade Feira), #3 (sub-categorias c/ anti-cycle), #4 (cascata cidade→bairro→rua)
- Fase B — Home premium: mods #2 (grid denso 5×6 categorias), #5 (logo 2xl 96px), #6 (labels destaque trocados), #9 ("Como funciona" após categorias)
- Fase C — Tempo/regras: mods #7 (recém-chegados ≤7d + badge "Novo"), #8 (vagas destaque = qualquer aprovada)

**Pendente:**
- Fase D — Saúde (mod #10): inventário rotas + fuzzing 401/403/404/500 + top-N fixes

**Why:** User pediu looping de análise por fase para não deixar item para trás.
**How to apply:** Consultar PRD HTML para spec detalhada de cada mod. Reabrir Fase D quando user pedir.