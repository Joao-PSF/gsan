-- Passo da execução (lote 5d: CEN-FAT-007 V3) — o pagamento CLASSIFICADO da conta de 05/2026 de IMV-01, no valor da conta,
-- no estado em que a recepção do movimento do arrecadador e a classificação o deixariam. Aplicado DEPOIS do faturamento
-- (o pagamento aponta a conta gerada) e ANTES da retificação. Depende de conta-ciclo-arrecadacao.sql.
-- A conta é localizada pelo imóvel e pela referência, nunca pelo id. Datas e ids SINTÉTICOS.
INSERT INTO arrecadacao.pagamento (pgmt_id, pgmt_vlpagamento, pgmt_amreferenciapagamento, pgmt_dtpagamento, pgmt_amreferenciaarrecadacao,
                                   pgst_idatual, cnta_id, loca_id, dotp_id, avbc_id, imov_id, arfm_id, pgmt_tmultimaalteracao)
SELECT 901, c.cnta_vlagua + c.cnta_vlesgoto + c.cnta_vldebitos - c.cnta_vlcreditos - coalesce(c.cnta_vlimpostos, 0), 202605,
       '2026-06-08', 202606, 0, c.cnta_id, 1, 1, 901, c.imov_id, 1, '2026-06-08 12:00:00'
FROM faturamento.conta c WHERE c.imov_id = 100013 AND c.cnta_amreferenciaconta = 202605 AND c.dcst_idatual = 0;
