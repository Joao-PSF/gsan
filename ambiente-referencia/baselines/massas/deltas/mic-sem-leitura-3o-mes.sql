-- Delta — o IMV-M06 também SEM leitura em 03/2026: 05/2026 é o 3º mês seguido (lote 5c: CEN-MIC-001 V3c). Depende de
-- mic-sem-leitura-2o-mes.sql. O consumo de 03/2026 fica como a consistência o teria estimado (média de então: 20, tipo
-- MEDIA_HIDROMETRO). SINTÉTICO.
UPDATE micromedicao.consumo_historico SET cshi_nnconsumofaturadomes = 20, cshi_nnconsumocalculomedia = 20, cstp_id = 3 WHERE cshi_id = 305;
