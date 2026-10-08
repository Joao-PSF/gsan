# Cobertura de baselines — Fase 2

> ⚠️ **Gerado por script** — `ambiente-referencia/baselines/ferramentas/cobertura.py gerar`, a partir da
> [matriz de caracterização](matriz-caracterizacao.md), das definições executáveis
> (`ambiente-referencia/baselines/cenarios/`) e das baselines gravadas (`ambiente-referencia/baselines/golden/`).
> Não editar à mão. Leitura: [relatório da Fase 2](fase2-caracterizacao-baselines.md).

## Totais

| Classe | Cenários | Com definição executável | Com baseline | Massas iniciais (matriz) | Variações definidas | Baselines gravadas |
| ------ | -------- | ------------------------ | ------------ | ------------------------ | ------------------- | ------------------ |
| **A** | 74 | 29 | 29 | 221 | 107 | 107 |
| **C** | 6 | 2 | 2 | 13 | 3 | 3 |

**P0 da classe A com baseline**: 24 de 42. Cenários que exigem execução do GSAN (A + C com registro): 80; com ao menos uma baseline: 31.

## Por domínio (classe A)

| Domínio | Cenários A | Com baseline | Baselines gravadas |
| ------- | ---------- | ------------ | ------------------ |
| Arrecadação | 11 | 0 | 0 |
| Batch, relatórios e integrações | 11 | 5 | 9 |
| Cadastro e atendimento | 13 | 6 | 25 |
| Cobrança | 7 | 0 | 0 |
| Faturamento | 11 | 7 | 24 |
| Financeiro e operacional | 8 | 0 | 0 |
| Micromedição | 5 | 3 | 16 |
| Segurança | 8 | 8 | 33 |

## Cenários com definição executável

| Cenário | Prioridade | Lote | Variações definidas | Baselines | Fora do lote | Fora desta fronteira |
| ------- | ---------- | ---- | ------------------- | --------- | ------------ | -------------------- |
| CEN-ATE-007 | P0 | atendimento | V1 | V1 | — | situação derivada do imóvel, V2 religação e V3 ligação de esgoto, o encerramento não é gatilho |
| CEN-ATE-008 | P0 | atendimento | V1, V1b, V2, V3, V3b, V4, V5 | V1, V1b, V2, V3, V3b, V4, V5 | — | valor de cada parcela e distribuição de centavos |
| CEN-BAT-001 | P1 | batch-faturamento | V1, V2 | V1, V2 | — | V3 processo de relatório, usuário técnico de batch (USR-11), parâmetros gravados |
| CEN-BAT-002 | P0 | batch-faturamento | V1, V2, V3 | V1, V2, V3 | — | texto técnico da exceção, correção da causa |
| CEN-BAT-003 | P0 | batch-faturamento | V1 | V1 | — | ordem dos imóveis na rota |
| CEN-BAT-004 | P0 | batch-faturamento | V1, V1b | V1, V1b | — | V2 disparos simultâneos |
| CEN-BAT-005 | P0 | batch-faturamento | V1 | V1 | — | comparação com o individual, rotas e imóveis de CEN-FAT-002 a 006, dados de impressão e e-mail |
| CEN-CAD-001 | P1 | cadastro-faturamento | V1, V2, V3 | V1, V2, V3 | — | matrícula nunca reaproveitada, DV na digitação |
| CEN-CAD-002 | P0 | cadastro-faturamento | V1, V2, V3, V4 | V1, V2, V3, V4 | — | cliente de um papel NUMA DATA, aba Dados Cadastrais do Consultar Imóvel |
| CEN-CAD-003 | P0 | piloto | V1, V2, V3 | V1, V2, V3 | — | categoria principal, coerência do denormalizado |
| CEN-CAD-004 | P0 | cadastro-faturamento | V1, V2, V3, V4, V5, V6, V7 | V1, V2, V3, V4, V5, V6, V7 | — | semântica do valor 4 e completude de imovel_situacao, forma de faturamento (leitura, média, mínimo) por situação especial, situação derivada do imóvel e tipos de solicitação habilitados |
| CEN-FAT-001 | P0 | piloto | V1, V2, V3, V6, V7 | V1, V2, V3, V6, V7 | V4, V5 | a, b, c, e, f |
| CEN-FAT-002 | P0 | piloto | V1, V2, V3 | V1, V2, V3 | — | parcela por vigência, contexto congelado |
| CEN-FAT-003 | P0 | cadastro-faturamento | V1, V1b | V1, V1b | V2, V3 | percentuais fotografados na conta, composição do volume de esgoto pelo consumo da ligação |
| CEN-FAT-004 | P0 | batch-faturamento-conta | V1, V1b, V2, V2b, V3, V3b, V3c, V4 | V1, V1b, V2, V2b, V3, V3b, V3c, V4 | — | V5 taxa de emissão, IMV-02 e IMV-03 |
| CEN-FAT-005 | P0 | batch-faturamento-conta | V1, V2, V3 | V1, V2, V3 | — | truncamento da base |
| CEN-FAT-006 | P0 | batch-faturamento-conta | V1, V2 | V1, V2 | — | consumo do principal e dos micros, esgoto |
| CEN-FAT-011 | P1 | batch-faturamento | V1 | V1 | — | V2, localizador da Fase 1 |
| CEN-MIC-001 | P0 | batch-micromedicao | V1, V2, V3, V3b, V3c, V4 | V1, V2, V3, V3b, V3c, V4 | — | V5 situação especial, reincidência em três consistências |
| CEN-MIC-002 | P0 | atendimento | V1, V2, V3, V4, V5, V6, V7 | V1, V2, V3, V4, V5, V6, V7 | — | precedência no faturamento, tipo de consumo quando o mínimo é faturado |
| CEN-MIC-003 | P0 | batch-micromedicao | V1, V2, V3 | V1, V2, V3 | — | a operação da OS (a–d, g, h), leitura de retirada |
| CEN-SEG-001 | P0 | seguranca | V1 | V1 | — | concessoes no contexto (c) |
| CEN-SEG-002 | P0 | seguranca | V1, V2, V3 | V1, V2, V3 | — | — |
| CEN-SEG-003 | P1 | seguranca | V1, V2, V3, V4, V5, V5b, V6 | V1, V2, V3, V4, V5, V5b, V6 | — | valor das senhas e do histórico, troca obrigatória pela tela completa |
| CEN-SEG-004 | P0 | seguranca | V1, V2, V3, V4, V5, V6, V7a, V7b, V7c, V7c2, V5b | V1, V2, V3, V4, V5, V5b, V6, V7a, V7b, V7c, V7c2 | — | unidade de concessão |
| CEN-SEG-005 | P0 | seguranca | V1 | V1 | — | — |
| CEN-SEG-006 | P0 | seguranca | V1, V2, V3 | V1, V2, V3 | — | leitura da trilha pela aplicação, valor da senha redefinida (V1) |
| CEN-SEG-007 | P0 | seguranca | V1, V2, V3, V4, V5 | V1, V2, V3, V4, V5 | — | outras superfícies que chamam a verificação, superfícies sem verificação, RA, conta exibida |
| CEN-SEG-008 | P1 | atendimento | V1, V2 | V1, V2 | — | demais permissões da especificação, usuários distintos |
| CEN-SEG-010 | P1 | seguranca | V1, V2 | V1, V2 | — | qual elo nega (internamente) |
| CEN-SEG-012 | P1 | seguranca | V1 | V1 | — | origem cruzada real |
