-- Delta — o histórico de consumo de IMV-01 como a consistência de leituras o deixaria (lote 5d: CEN-FAT-007 V2 e V2b, a
-- retificação que muda o consumo). Depende de batch-faturamento-g1-202605.sql (o consumo de 05/2026, 27 m³).
--
-- Por que: a massa do lote 5 grava só o consumo FATURADO de 05/2026 (27 m³) — sem o consumo "para média" nem a média,
-- que a retificação oferece substituir ("O novo consumo substituirá o consumo anterior para o cálculo da média…").
-- Sem eles, a pergunta "o valor anterior é recuperável?" (observável g) não teria valor anterior a perder. Aqui: o
-- consumo para média de 05/2026 é o próprio consumo (27) e a média, 25 — a dos três meses REAIS anteriores
-- (24 + 26 + 25 = 75, ÷ 3), que entram também no histórico. Tipo REAL (ConsumoTipo.REAL = 1), água (LigacaoTipo = 1).
-- Valores e datas SINTÉTICOS.
UPDATE micromedicao.consumo_historico SET cshi_nnconsumocalculomedia = 27, cshi_nnconsumomedio = 25
WHERE imov_id = 100013 AND cshi_amfaturamento = 202605 AND lgti_id = 1;
INSERT INTO micromedicao.consumo_historico (cshi_id, imov_id, lgti_id, cshi_amfaturamento, cshi_nnconsumofaturadomes,
                                            cshi_nnconsumocalculomedia, cshi_icfaturamento, cstp_id, rota_id, cshi_tmultimaalteracao) VALUES
  (11, 100013, 1, 202602, 24, 24, 1, 1, 1, '2026-03-01 07:00:00'),
  (12, 100013, 1, 202603, 26, 26, 1, 1, 1, '2026-04-01 07:00:00'),
  (13, 100013, 1, 202604, 25, 25, 1, 1, 1, '2026-05-01 07:00:00');
