-- Passo da execução (lote 6) — a referência de faturamento do sistema avança para 06/2026, como o encerramento do
-- faturamento de 05/2026 a deixaria. Aplicado DEPOIS do faturamento do grupo (as contas de 05/2026 nascem com a referência
-- contábil 202605) e ANTES do envio do movimento.
--
-- EVIDÊNCIA: a classificação compara a referência contábil da conta com parm_amreferenciafaturamento
-- (ControladorArrecadacao.classificarPagamentosConta:34252): com a conta do mês de faturamento ainda aberto, o pagamento
-- passa por DOCUMENTO A CONTABILIZAR antes de ser apropriado — o caso de CEN-ARR-003 V5, que NÃO aplica este passo. O
-- encerramento do faturamento é outra operação (fora desta fronteira); aqui só o parâmetro que ela avança.
UPDATE cadastro.sistema_parametros SET parm_amreferenciafaturamento = 202606;
