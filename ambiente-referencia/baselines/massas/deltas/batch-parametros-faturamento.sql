-- Delta — parâmetros do sistema que o faturamento em grupo lê e que a base reconstruída deixa NULOS (lote 5).
-- EVIDÊNCIA: gerarConta calcula a validade da conta com sistemaParametro.getNumeroMesesValidadeConta()
-- (ControladorFaturamentoFINAL:53628) — nulo, o faturamento de todo imóvel quebra com NPE. Valores SINTÉTICOS: nenhum
-- valor de instalação real é conhecido; a baseline caracteriza o mecanismo com eles.
UPDATE cadastro.sistema_parametros SET parm_nnmesesvalidadeconta = 3;
