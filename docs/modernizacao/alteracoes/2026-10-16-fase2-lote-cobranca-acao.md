# [2026-10-16] Fase 2 — lote 8: Cobrança — ação de cobrança e conta em cobrança

> Décimo sétimo lote de baselines da Fase 2, no EAR em modo Batch. **Não implementa o OpenGSAN** e **não altera o
> legado**. A Fase 2 **continua em andamento**.

- **Motivo**: a ação de cobrança — o aviso de corte comandado pela rota, com o documento e um item por conta — e o efeito do
  pagamento antes ou depois do documento (pelo código de barras do documento ou da conta); e o que acontece à cobrança em
  curso quando a conta cobrada é retificada, cancelada ou prescrita — ao centavo, com as situações dos itens, das contas e dos
  pagamentos e a posição antes e depois.
- **Impacto**: 11 baselines novas — CEN-COB-002 V1, V1b, V2, V3, V3b, V4 e CEN-COB-007 V1, V1b, V2, V2b, V3 (cenários novos);
  2 deltas de massa e 1 passo de relógio; o roteiro `faturar_grupo` ganhou os passos `comandar_acao_cobranca` e
  `processo_cobranca`, o registro `documento_cobranca` no movimento e o bloco de detalhes `acao_cobranca` — nenhuma linha
  existente mudou de comportamento. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Integração externa**: nenhuma chamada. A ação de aviso não gera ordem de serviço nem boleto; a emissão do arquivo dos
  documentos (etapa 1312, arquivo da gráfica no disco do servidor) fica fora da fronteira.
- **Testes**: 6 rodadas de exploração dirigida (20 execuções, sem gravar); captura com 2 execuções idênticas; verificação
  independente; regressão dos lotes 7, 7b, 7c, 6, 6b e 6c (68/68); `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `06ae63d` (lote 7c). Cobertura: 36 de 42 P0 da classe A; 213 baselines; 46 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 11 baselines — COB-002 V1/V1b/V2/V3/V3b/V4, COB-007 V1/V1b/V2/V2b/V3 | `ambiente-referencia/baselines/golden/cobranca/CEN-COB-002/`, `golden/cobranca/CEN-COB-007/` |
| Cenários CEN-COB-002 e CEN-COB-007 | `ambiente-referencia/baselines/cenarios/` |
| O que a ação de cobrança exige (situações, tipos e formas de documento, motivos de não geração, critério, ação, atividades, processo, concessões); a conta antiga de IMV-01; o passo de relógio da emissão do documento | `ambiente-referencia/baselines/massas/deltas/cob-acao-cobranca.sql`, `massas/deltas/cob-conta-antiga-imv01.sql`, `massas/passos/cob-relogio-documento-emitido.sql` |
| Achados F2-183 a F2-194; candidatos CAND-50 a CAND-52 | [relatório §31](../testes/fase2/fase2-caracterizacao-baselines.md#31-lote-8--cobrança-ação-de-cobrança-e-conta-em-cobrança-2026-10-16), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-50** | O item do documento só muda pelo pagamento do documento e pelo cancelamento; a conta paga por outro canal e a prescrita deixam o item PENDENTE (COB-002 V4, COB-007 V3) | O item acompanha a situação da dívida, qualquer que seja o canal ou a operação |
| **CAND-51** | A atualização do item compara a emissão com a data sem a hora: no dia da emissão, nem o pagamento do documento nem o cancelamento chegam ao item (COB-002 V3b, COB-007 V2b) | Comparar com o instante, ou não condicionar à emissão |
| **CAND-52** | A retificação não toca o documento: o aviso cobra o valor original; pago, o pagamento vai para a conta retificada como VALOR NÃO CONFERE, com excedente de R$ 16,35 (COB-007 V1, V1b) — **toca valor** | A retificação revê o documento em curso; o pagamento do documento vencido pela retificação tem tratamento explícito |

Nenhum aprovado. Continuam pendentes, sem decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-52 (CAND-41 e CAND-52 no
oráculo 1, porque tocam valor; CAND-44 com a evidência executável do lote 7c), a leitura final de D-15, o alcance de D-14 e
F2-157.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§31, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/cobranca.md` (CEN-COB-002, CEN-COB-007; nota em CEN-COB-001) · `testes/cenarios-criticos.md` §11 ·
`testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` (estado) · `modulos/cobranca.md` (§5, §19, §33) ·
`modulos/arrecadacao.md` (§12, §23) · `alteracoes/README.md` · `ambiente-referencia/baselines/README.md`.
**Código das ferramentas**: `baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 8 capturado: **11/11** variações com as duas execuções idênticas, **11/11** conferidas numa
verificação independente e os lotes 7, 7b, 7c, 6, 6b e 6c de novo **68/68**; 46 conferências dos documentos contra os goldens,
sem divergência. **224** baselines em 48 cenários; P0 da classe A **38 de 42** (+2: CEN-COB-002, CEN-COB-007). CAND-50 a
CAND-52 pendentes (CAND-52 toca valor — oráculo 1). Próximo lote: **9 — Financeiro: lançamentos contábeis e devedores
duvidosos** (CEN-FIN-001, CEN-FIN-002); depois CEN-REL-001 e CEN-INT-001. MIC-005 e a baseline de performance seguem pendentes.
