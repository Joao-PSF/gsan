-- Delta — parâmetros do sistema que a recepção e a classificação leem (lote 6). Depende de arr-arrecadador.sql.
--
-- EVIDÊNCIA (base reconstruída: parm_cdempresafebraban e parm_nnlayoutfebraban NULOS, parm_amreferenciaarrecadacao 201411):
-- · validarArquivoMovimentoArrecadador:4278-4282 compara a versão do layout do cabeçalho com parm_nnlayoutfebraban
--   (Short) — nulo, NullPointerException já na tela de envio.
-- · processarPagamentosCodigoBarras:8451-8466 compara a identificação da empresa no código de barras (posições 16–19) com
--   parm_cdempresafebraban — nulo, todo registro é rejeitado ("CÓDIGO DE BARRAS NÃO PERTENCE A ...").
-- · O pagamento recebe a referência de arrecadação max(mês do pagamento, parm_amreferenciaarrecadacao)
--   (processarPagamentosCodigoBarrasConta:5187-5199) e a classificação só olha pagamentos com referência de arrecadação
--   <= parm_amreferenciaarrecadacao (RepositorioArrecadacaoHBM.pesquisarPagamentosPorConta:2463): a arrecadação do
--   sistema está em 06/2026, o mês dos pagamentos das contas de 05/2026 (vencimento 10/06/2026).
-- · Referência de faturamento = a do grupo (05/2026), como numa instalação em operação durante o mês (a base parou em
--   201410 — F2-70, F2-80; mesmo valor de conta-ciclo-catalogos.sql): é com ela que a classificação compara a
--   referência contábil da conta (classificarPagamentosConta:34252); o passo arr-faturamento-encerrado-202605.sql a
--   avança depois do faturamento.
-- Valores SINTÉTICOS: código FEBRABAN da empresa 0901, layout 04.
UPDATE cadastro.sistema_parametros SET parm_cdempresafebraban = 901, parm_nnlayoutfebraban = 4,
                                       parm_amreferenciaarrecadacao = 202606, parm_amreferenciafaturamento = 202605;
