# Cobertura de baselines — Fase 2

> ⚠️ **Gerado por script** — `ambiente-referencia/baselines/ferramentas/cobertura.py gerar`, a partir da
> [matriz de caracterização](matriz-caracterizacao.md), das definições executáveis
> (`ambiente-referencia/baselines/cenarios/`) e das baselines gravadas (`ambiente-referencia/baselines/golden/`).
> Não editar à mão. Leitura: [relatório da Fase 2](fase2-caracterizacao-baselines.md).

## Totais

| Classe | Cenários | Com definição executável | Com baseline | Massas iniciais (matriz) | Variações definidas | Baselines gravadas |
| ------ | -------- | ------------------------ | ------------ | ------------------------ | ------------------- | ------------------ |
| **A** | 74 | 14 | 14 | 221 | 58 | 58 |
| **C** | 6 | 2 | 2 | 13 | 3 | 3 |

**P0 da classe A com baseline**: 12 de 42. Cenários que exigem execução do GSAN (A + C com registro): 80; com ao menos uma baseline: 16.

## Por domínio (classe A)

| Domínio | Cenários A | Com baseline | Baselines gravadas |
| ------- | ---------- | ------------ | ------------------ |
| Arrecadação | 11 | 0 | 0 |
| Batch, relatórios e integrações | 11 | 0 | 0 |
| Cadastro e atendimento | 13 | 4 | 17 |
| Cobrança | 7 | 0 | 0 |
| Faturamento | 11 | 3 | 10 |
| Financeiro e operacional | 8 | 0 | 0 |
| Micromedição | 5 | 0 | 0 |
| Segurança | 8 | 7 | 31 |

## Cenários com definição executável

| Cenário | Prioridade | Lote | Variações definidas | Baselines | Fora do lote | Fora desta fronteira |
| ------- | ---------- | ---- | ------------------- | --------- | ------------ | -------------------- |
| CEN-CAD-001 | P1 | cadastro-faturamento | V1, V2, V3 | V1, V2, V3 | — | matrícula nunca reaproveitada, DV na digitação |
| CEN-CAD-002 | P0 | cadastro-faturamento | V1, V2, V3, V4 | V1, V2, V3, V4 | — | cliente de um papel NUMA DATA, aba Dados Cadastrais do Consultar Imóvel |
| CEN-CAD-003 | P0 | piloto | V1, V2, V3 | V1, V2, V3 | — | categoria principal, coerência do denormalizado |
| CEN-CAD-004 | P0 | cadastro-faturamento | V1, V2, V3, V4, V5, V6, V7 | V1, V2, V3, V4, V5, V6, V7 | — | semântica do valor 4 e completude de imovel_situacao, forma de faturamento (leitura, média, mínimo) por situação especial, situação derivada do imóvel e tipos de solicitação habilitados |
| CEN-FAT-001 | P0 | piloto | V1, V2, V3, V6, V7 | V1, V2, V3, V6, V7 | V4, V5 | a, b, c, e, f |
| CEN-FAT-002 | P0 | piloto | V1, V2, V3 | V1, V2, V3 | — | parcela por vigência, contexto congelado |
| CEN-FAT-003 | P0 | cadastro-faturamento | V1, V1b | V1, V1b | V2, V3 | percentuais fotografados na conta, composição do volume de esgoto pelo consumo da ligação |
| CEN-SEG-001 | P0 | seguranca | V1 | V1 | — | concessoes no contexto (c) |
| CEN-SEG-002 | P0 | seguranca | V1, V2, V3 | V1, V2, V3 | — | — |
| CEN-SEG-003 | P1 | seguranca | V1, V2, V3, V4, V5, V5b, V6 | V1, V2, V3, V4, V5, V5b, V6 | — | valor das senhas e do histórico, troca obrigatória pela tela completa |
| CEN-SEG-004 | P0 | seguranca | V1, V2, V3, V4, V5, V6, V7a, V7b, V7c, V7c2, V5b | V1, V2, V3, V4, V5, V5b, V6, V7a, V7b, V7c, V7c2 | — | unidade de concessão |
| CEN-SEG-005 | P0 | seguranca | V1 | V1 | — | — |
| CEN-SEG-006 | P0 | seguranca | V1, V2, V3 | V1, V2, V3 | — | leitura da trilha pela aplicação, valor da senha redefinida (V1) |
| CEN-SEG-007 | P0 | seguranca | V1, V2, V3, V4, V5 | V1, V2, V3, V4, V5 | — | outras superfícies que chamam a verificação, superfícies sem verificação, RA, conta exibida |
| CEN-SEG-010 | P1 | seguranca | V1, V2 | V1, V2 | — | qual elo nega (internamente) |
| CEN-SEG-012 | P1 | seguranca | V1 | V1 | — | origem cruzada real |
