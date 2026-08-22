---
name: project-pending-mods-2026-08-22
description: "10 modificações pendentes definidas 2026-08-22, vindas de análise de erros + feedback cliente; tr cidade, sub-categoria, grid denso, cascata, API"
metadata:
  type: project
---

Lista de modificações definida 2026-08-22, ainda não iniciada implementação. Origem: análise de erros + feedback cliente.

**1. Tr cidade = Feira de Santa**
Backend + frontend: filtro cidades mostra **somente** "Feira de Santana". Demais escondidas/atendidas com fallback. Cascata bairro/rua condicionada a essa cidade.

**2. Grid denso categorias (5×6) — sessão única**
Bloco "Navegue por Categoria" renderiza **todas** categorias em grid denso único (estilo imagem-referência "tudo católico"): 5 linhas × 6 colunas, cada card = ícone azul + nome + "X indicações". **Não** exibir categoria-por-categoria em sessões separadas. Sub-categorias entram aqui.

**3. Sub-categoria em Categorias**
Modelo backend com `parent_id` (self-ref). CRUD admin permite criar sub. UI exibe hierarquia pai→filho.

**4. Cascata cidade→bairro→rua**
Selecionar cidade libera bairro; bairro libera rua. Telas: cadastro/edição parceiro + filtros busca. Base: Feira de Santa.

**5. Logo pequena em "encontre/cofie"**
Bug visual: logo aparece pequena no hero. Corrigir tamanho/priority.

**6. Trocar labels destaque**
"Mais bem avaliados" ↔ "Destaques da comunidade" — inverter nomenclatura dos blocos correspondentes.

**7. Recém-chegados/Novidades — sair após 7 dias**
Bloco exibe só parceiros/conteúdos < 7 dias. Após isso, some. Filtro helper.

**8. Vagas destaque = qualquer vaga anunciada**
Regra atual restringe demais. Mudar pra qualquer vaga publicada entra em "Vagas em destaque". Sem filtro destaque manual.

**9. Mover "Como funciona" pra depois de Categoria**
Reordenar home: Navegue por Categoria → Como funciona → próximos.

**10. Re-analisar API**
Mapear 401/403/404/500 recorrentes, causas, fixes. Logs sob pedido (loglast.md/erro.md).

**Ordem proposta (não confirmada):**
1 → 3 → 2 → 5 → 4 → 6-9 → 10

**Tr (status):** travada. User pediu save sem implementar.

**Why:** Concentrar decisões antes de implementação em TDD.

**How to apply:** Ao retomar, perguntar ordem antes de começar. Mudanças #1+#2+#3+#9 tocam home (frontend crítico).
