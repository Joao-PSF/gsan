-- P3 — linhas de referência pressupostas por 20160902145028 (credito_tipo com lict_id = 2).
-- Evidência: LancamentoItem.GRUPO_CONTABIL = 3 (src/gcom/financeiro/lancamento/LancamentoItem.java);
-- LancamentoItemContabil.ACRESCIMOS_POR_IMPONTUALIDADE = 2 (LancamentoItemContabil.java);
-- vínculo item contábil -> lancamento_item 3: 20170925195225 insere o item contábil 14 com lcit_id = 3.
-- Sintético (sem evidência): abreviaturas e indicadores.
INSERT INTO financeiro.lancamento_item (lcit_id, lcit_dsitemlancamento, lcit_dsabreviado, lcit_icitemcontabil, lcit_tmultimaalteracao)
VALUES (3, 'GRUPO CONTABIL', 'GRPCONTAB', 2, now());
INSERT INTO financeiro.lancamento_item_contabil (lict_id, lict_dsitemlancamentocontabil, lict_dsabreviado, lict_nnsequenciaimpressao, lict_tmultimaalteracao, lcit_id, lict_icuso)
VALUES (2, 'ACRESCIMOS POR IMPONTUALIDADE', 'ACIMP', NULL, now(), 3, 1);
