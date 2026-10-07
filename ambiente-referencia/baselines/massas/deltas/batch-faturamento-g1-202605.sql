-- Delta — o grupo G1 pronto para FATURAR a referência 05/2026 (lote 5). Depende de batch-catalogos.sql, de
-- territorio-l1.sql e de imoveis-imv-01-02-03.sql.
--
-- O que vem por SQL é o que as etapas ANTERIORES do ciclo deixariam e que não é o objeto do lote:
-- · o cronograma mensal do grupo e o COMANDO da atividade FATURAR GRUPO, com a rota R1 (o que "Inserir Comando de
--   Atividade de Faturamento" gravaria);
-- · o consumo de água de 05/2026 de cada imóvel (o que "Consistir Leituras e Calcular Consumos" gravaria): os MESMOS
--   consumos das simulações do piloto — IMV-01 27 m³ (CEN-FAT-001 V1), IMV-02 47 m³ (V2), IMV-03 58 m³ (V3) — para
--   comparar a conta do lote com o cálculo individual (CEN-BAT-005). Tipo REAL (ConsumoTipo.REAL = 1), água
--   (LigacaoTipo.LIGACAO_AGUA = 1). Esgoto POTENCIAL nos três: sem consumo de esgoto.
-- O que a operação sob teste faz — iniciar o processo e faturar — fica para a tela e o agendador.
-- Datas, ids e vencimentos SINTÉTICOS.
INSERT INTO faturamento.fatur_grupo_crg_mensal (ftcm_id, ftgr_id, ftcm_amreferencia, ftcm_tmultimaalteracao)
VALUES (1, 1, 202605, '2026-01-01 00:00:00');
INSERT INTO faturamento.fatur_ativ_cronograma (ftac_id, ftat_id, ftcm_id, ftac_dtprevista, ftac_tmcomando, ftac_tmultimaalteracao)
VALUES (1, 5, 1, '2026-05-31', '2026-06-01 08:00:00', '2026-06-01 08:00:00');
INSERT INTO faturamento.fatur_ativ_cron_rota (ftac_id, rota_id, facr_dtcontavencimento, facr_tmultimaalteracao)
VALUES (1, 1, '2026-06-10', '2026-06-01 08:00:00');

INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes, cshi_icfaturamento,
                                            cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (1, 100013, 1, 202605, 27, 1, 1, 1, '2026-06-01 07:00:00'),
  (2, 100021, 1, 202605, 47, 1, 1, 1, '2026-06-01 07:00:00'),
  (3, 100030, 1, 202605, 58, 1, 1, 1, '2026-06-01 07:00:00');
