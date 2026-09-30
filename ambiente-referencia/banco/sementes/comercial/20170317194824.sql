-- P3 — item contábil pressuposto por 20170317194824 (credito_tipo com lict_id = 6).
-- Evidência: LancamentoItemContabil.OUTROS_SERVICOS_AGUA = 6; vínculo com lancamento_item 3 como em 20160902145028.
INSERT INTO financeiro.lancamento_item_contabil (lict_id, lict_dsitemlancamentocontabil, lict_dsabreviado, lict_nnsequenciaimpressao, lict_tmultimaalteracao, lcit_id, lict_icuso)
VALUES (6, 'OUTROS SERVICOS AGUA', 'OSAGU', NULL, now(), 3, 1);
