-- Delta — o IMV-M06 de mic-imv-sem-leitura-anormalidade.sql também SEM leitura em 04/2026 (mesma anormalidade 101): 05/2026
-- é o 2º mês (lote 5c: CEN-MIC-001 V3b). Depende de mic-imv-sem-leitura-anormalidade.sql.
-- O que a consistência de 04/2026 teria gravado pela regra da anormalidade: consumo pela MÉDIA de então (21 — tipo
-- MEDIA_HIDROMETRO, que não entra na média seguinte) e leitura de faturamento ANTERIOR + MÉDIA (470 + 21 = 491).
-- SINTÉTICO.
UPDATE micromedicao.consumo_historico SET cshi_nnconsumofaturadomes = 21, cshi_nnconsumocalculomedia = 21, cstp_id = 3 WHERE cshi_id = 306;
UPDATE micromedicao.medicao_historico SET mdhi_dtleituraatualinformada = NULL, mdhi_nnleituraatualinformada = NULL,
       mdhi_nnleituraatualfaturamento = 491, mdhi_nnconsumomedidomes = NULL, ltan_idleitanorminformada = 101,
       ltan_idleitanormfatmt = 101, ltst_idleiturasituacaoatual = 2 WHERE mdhi_id = 31;
UPDATE micromedicao.medicao_historico SET mdhi_nnleitantfatmt = 491, mdhi_nnleitantinformada = NULL, mdhi_nnleituraatualfaturamento = 491,
       ltst_idleiturasituacaoanterior = 2 WHERE mdhi_id = 32;
