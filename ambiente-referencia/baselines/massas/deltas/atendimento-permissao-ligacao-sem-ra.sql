-- Delta — CEN-SEG-008: o operador da caracterização recebe a permissão especial EFETUAR_LIGACAO_DE_AGUA_SEM_RA
-- (PermissaoEspecial.EFETUAR_LIGACAO_DE_AGUA_SEM_RA = 65), que a tela de Efetuar Ligação de Água consulta para habilitar
-- a matrícula sem OS (ExibirEfetuarLigacaoAguaAction: permissaoAlterarOSsemRA). EVIDÊNCIA: a permissão 65 não existe no
-- catálogo da base reconstruída. Operação associada SINTÉTICA (257); descrição SINTÉTICA.
INSERT INTO seguranca.permissao_especial (pmep_id, pmep_dspermissaoespecial, pmep_icuso, oper_id, pmep_tmultimaalteracao)
VALUES (65, 'EFETUAR LIGACAO DE AGUA SEM RA', 1, 257, '2026-01-01 00:00:00');
INSERT INTO seguranca.usuario_permissao_espec (usur_id, pmep_id, upes_tmultimaalteracao)
VALUES (1001, 65, '2026-01-01 00:00:00');
