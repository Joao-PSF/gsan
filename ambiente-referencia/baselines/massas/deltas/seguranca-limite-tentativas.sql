-- Delta — limite de tentativas de login falhas para CEN-SEG-002.
--
-- EVIDÊNCIA: na instância de referência, cadastro.sistema_parametros.parm_nnmaximologinfalho é NULO — nenhuma
-- migração o define — e EfetuarLoginAction lê getNumeroMaximoLoginFalho().intValue() a cada senha errada.
-- O valor abaixo é SINTÉTICO (nenhum valor de instalação real é conhecido): só fixa o parâmetro para que o
-- mecanismo de bloqueio seja caracterizável. O comportamento com o valor nulo da semente é registrado à parte.
-- Alteração de parâmetro na PREPARAÇÃO do estado; a operação caracterizada (o login) é executada pelo GSAN.
UPDATE cadastro.sistema_parametros SET parm_nnmaximologinfalho = 3;
