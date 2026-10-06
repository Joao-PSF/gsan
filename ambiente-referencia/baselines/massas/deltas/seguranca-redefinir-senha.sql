-- Delta — CEN-SEG-006 V1: o grupo B concede a funcionalidade 607 "Alterar Senha Usuario pelo Login" com a
-- operação 818 (catálogo das migrações; oper_icregistratransacao = 1 — operação registrada). USR-02 (grupo B)
-- passa a poder executar, sobre outro login, a operação que EfetuarAlteracaoSenhaPorMatriculaAction registra
-- com RegistradorOperacao(OPERACAO_USUARIO_ALTERAR_SENHA_LOGIN, …): autor ≠ objeto. Concessão SINTÉTICA.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
VALUES (2002, 818, 607, '2026-01-01 00:00:00');
