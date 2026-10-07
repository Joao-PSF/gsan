-- Delta — o parcelamento de fat-parcelamento-6x.sql feito em 04/2026 — mês ANTERIOR ao da conta (05/2026), mas
-- POSTERIOR à referência de faturamento do sistema (201410) (lote 5b: CEN-FAT-004 V2b). Depende de fat-parcelamento-6x.sql.
-- Pela regra [FS0005] a primeira prestação não entra nesta conta. SINTÉTICO.
UPDATE cobranca.parcelamento SET parc_tmparcelamento = '2026-04-20 10:00:00', parc_amreferenciafaturamento = 202604,
                                 parc_tmultimaalteracao = '2026-04-20 10:00:00' WHERE parc_id = 9101;
UPDATE faturamento.debito_a_cobrar SET dbac_tmatudebito = '2026-04-20 10:00:00', dbac_amreferenciadebito = 202604,
                                       dbac_amcobrancadebito = 202604, dbac_amreferenciacontabil = 202604 WHERE dbac_id = 9102;
