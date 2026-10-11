-- Delta — a tela de envio confere o valor total do trailer (lote 6: CEN-ARR-001 V2b). Depende de arr-parametros.sql.
--
-- EVIDÊNCIA: RegistrarMovimentoArrecadadoresAction:204-227 só soma os valores dos registros F e G e os compara com o total
-- do registro Z quando parm_icvlmovarrec = 1 ("atencao.valor_registros_arquivo_invalido"); a base traz 2 (não confere), e o
-- processamento (ControladorArrecadacao.registrarMovimentoArrecadadores) nunca confere o valor — só a quantidade de
-- registros (:1867). Variação SINTÉTICA de configuração: a mesma instalação com a conferência ligada.
UPDATE cadastro.sistema_parametros SET parm_icvlmovarrec = 1;
