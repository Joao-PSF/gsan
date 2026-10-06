-- Delta — CEN-SEG-003 V5b: liga o controle de senhas anteriores (parm_icbloqueiosenhasantes = 1).
--
-- EVIDÊNCIA: na base reconstruída o parâmetro vale 2 e o histórico não é gravado nem consultado
-- (ControladorAcessoSEJB:2213 grava o histórico e validarNovaSenha → validarBloqueiSenhasAnteriores:4505 o
-- consulta, ambos só com o valor 1). V5 caracteriza a instância como está; V5b, o MECANISMO com o controle ligado.
-- Valor SINTÉTICO — nenhuma configuração de instalação real é conhecida.
UPDATE cadastro.sistema_parametros SET parm_icbloqueiosenhasantes = 1;
