-- Delta — CEN-ATE-008 V5: o tipo de serviço 619 COBRA JUROS no parcelamento (svtp_iccobrarjuros = 1). A taxa de juros de
-- financiamento da instância (sistema_parametros.parm_pctaxajurosfinanciamento) é NULA na base reconstruída e não é
-- alterada: a variação caracteriza o que o legado faz com ela (calcularValorPrestacaoAtendimentoPublico:13093).
-- Depende de atendimento-catalogos.sql. SINTÉTICO.
UPDATE atendimentopublico.servico_tipo SET svtp_iccobrarjuros = 1 WHERE svtp_id = 619;
