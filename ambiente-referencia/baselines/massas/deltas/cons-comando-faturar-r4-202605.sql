-- Delta — o comando de FATURAR GRUPO de 05/2026 para a rota R4 (lote 5e: consumo pela origem, na conta). Depende de
-- batch-catalogos.sql (atividade FATURAR GRUPO = 5) e de mic-rota-r4-consistir-202605.sql (cronograma de 05/2026 do
-- G1 com o comando de CONSISTIR LEITURAS da R4).
--
-- O mesmo cronograma passa a ter os DOIS comandos da referência, como numa instalação em operação: primeiro consistir
-- (atividade 9, ftac 2), depois faturar (atividade 5, ftac 1) — a mesma rota, a mesma referência, a mesma massa. O
-- que a consistência grava (medição e consumo do mês) é o que o faturamento lê para gerar a conta. Vencimento da conta
-- SINTÉTICO.
INSERT INTO faturamento.fatur_ativ_cronograma (ftac_id, ftat_id, ftcm_id, ftac_dtprevista, ftac_tmcomando, ftac_tmultimaalteracao)
VALUES (1, 5, 1, '2026-06-02', '2026-06-02 08:00:00', '2026-06-02 08:00:00');
INSERT INTO faturamento.fatur_ativ_cron_rota (ftac_id, rota_id, facr_dtcontavencimento, facr_tmultimaalteracao)
VALUES (1, 4, '2026-06-10', '2026-06-02 08:00:00');
