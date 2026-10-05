# Cobertura de baselines — Fase 2

> ⚠️ **Gerado por script** — `ambiente-referencia/baselines/ferramentas/cobertura.py gerar`, a partir da
> [matriz de caracterização](matriz-caracterizacao.md), das definições executáveis
> (`ambiente-referencia/baselines/cenarios/`) e das baselines gravadas (`ambiente-referencia/baselines/golden/`).
> Não editar à mão. Leitura: [relatório da Fase 2](fase2-caracterizacao-baselines.md).

## Totais

| Classe | Cenários | Com definição executável | Com baseline | Massas iniciais (matriz) | Variações definidas | Baselines gravadas |
| ------ | -------- | ------------------------ | ------------ | ------------------------ | ------------------- | ------------------ |
| **A** | 74 | 7 | 7 | 221 | 27 | 27 |
| **C** | 6 | 2 | 2 | 13 | 3 | 3 |

**P0 da classe A com baseline**: 7 de 42. Cenários que exigem execução do GSAN (A + C com registro): 80; com ao menos uma baseline: 9.

## Por domínio (classe A)

| Domínio | Cenários A | Com baseline | Baselines gravadas |
| ------- | ---------- | ------------ | ------------------ |
| Arrecadação | 11 | 0 | 0 |
| Batch, relatórios e integrações | 11 | 0 | 0 |
| Cadastro e atendimento | 13 | 1 | 3 |
| Cobrança | 7 | 0 | 0 |
| Faturamento | 11 | 2 | 8 |
| Financeiro e operacional | 8 | 0 | 0 |
| Micromedição | 5 | 0 | 0 |
| Segurança | 8 | 4 | 16 |

## Cenários com definição executável

| Cenário | Prioridade | Lote | Variações definidas | Baselines | Fora do lote | Fora desta fronteira |
| ------- | ---------- | ---- | ------------------- | --------- | ------------ | -------------------- |
| CEN-CAD-003 | P0 | piloto | V1, V2, V3 | V1, V2, V3 | — | categoria principal, coerência do denormalizado |
| CEN-FAT-001 | P0 | piloto | V1, V2, V3, V6, V7 | V1, V2, V3, V6, V7 | V4, V5 | a, b, c, e, f |
| CEN-FAT-002 | P0 | piloto | V1, V2, V3 | V1, V2, V3 | — | parcela por vigência, contexto congelado |
| CEN-SEG-001 | P0 | seguranca | V1 | V1 | — | concessoes no contexto (c) |
| CEN-SEG-002 | P0 | seguranca | V1, V2, V3 | V1, V2, V3 | — | — |
| CEN-SEG-004 | P0 | seguranca | V1, V2, V3, V4, V5, V6, V7a, V7b, V7c, V7c2, V5b | V1, V2, V3, V4, V5, V5b, V6, V7a, V7b, V7c, V7c2 | — | unidade de concessão |
| CEN-SEG-005 | P0 | seguranca | V1 | V1 | — | — |
| CEN-SEG-010 | P1 | seguranca | V1, V2 | V1, V2 | — | qual elo nega (internamente) |
| CEN-SEG-012 | P1 | seguranca | V1 | V1 | — | origem cruzada real |
