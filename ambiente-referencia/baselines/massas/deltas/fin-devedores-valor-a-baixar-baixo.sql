-- Delta — o parâmetro de devedores duvidosos da referência contábil 06/2026 com VALOR A BAIXAR de R$ 100,00 (lote 9: CEN-FIN-002
-- V1b). Depende de fin-devedores-duvidosos.sql. O valor a baixar é o teto da baixa do mês (com 10% de tolerância —
-- ControladorFinanceiro.gerarResumoDevedoresDuvidosos:5979); as contas elegíveis de V1 somam R$ 260,40 — acima dele.
UPDATE financeiro.param_deved_duvid SET pded_vlvalorabaixar = 100.00 WHERE pded_id = 7101;
