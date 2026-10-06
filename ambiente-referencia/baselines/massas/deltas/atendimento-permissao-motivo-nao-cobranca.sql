-- Delta — o operador da caracterização recebe a permissão especial INFORMAR_MOTIVO_NAO_COBRANCA
-- (PermissaoEspecial.INFORMAR_MOTIVO_NAO_COBRANCA = 30), que a tela de Efetuar Ligação de Água consulta para exibir o
-- motivo de não cobrança, o percentual e as parcelas (ExibirEfetuarLigacaoAguaAction: sem ela, 100% e 1 parcela).
-- EVIDÊNCIA: a permissão 30 não existe no catálogo da base reconstruída. Operação associada SINTÉTICA (257, a da
-- própria ligação); descrição SINTÉTICA.
INSERT INTO seguranca.permissao_especial (pmep_id, pmep_dspermissaoespecial, pmep_icuso, oper_id, pmep_tmultimaalteracao)
VALUES (30, 'INFORMAR MOTIVO NAO COBRANCA', 1, 257, '2026-01-01 00:00:00');
INSERT INTO seguranca.usuario_permissao_espec (usur_id, pmep_id, upes_tmultimaalteracao)
VALUES (1001, 30, '2026-01-01 00:00:00');
