-- P3 — tipo de financiamento pressuposto por 20220831201946 (debito_tipo com fntp_id = 1).
-- Evidência: FinanciamentoTipo.SERVICO_NORMAL = 1 (src/gcom/financeiro/FinanciamentoTipo.java).
-- As migrações criam os tipos 11 e 12; os demais tipos das constantes ficam para a massa da Fase 2.
INSERT INTO financeiro.financiamento_tipo (fntp_id, fntp_dsfinanciamentotipo, fntp_dsabreviado, fntp_icuso, fntp_tmultimaalteracao, fntp_icinclusao)
VALUES (1, 'SERVICO NORMAL', 'SN', 1, now(), 2);
