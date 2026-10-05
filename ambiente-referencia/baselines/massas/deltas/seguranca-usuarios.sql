-- Delta — usuários e grupos SINTÉTICOS do lote de Segurança (perfis USR-01, USR-01B, USR-02, USR-03 de
-- cenarios-criticos.md §13.4). Independentes do operador da caracterização (fase2.oper), que nenhum
-- cenário de Segurança usa: bloquear ou restringir um usuário de cenário nunca afeta o executor.
--
-- 🔴 Sem senha: usur_nmsenha fica nula. O executor gera senhas aleatórias a cada execução (uma por rótulo
-- do cenário — USR-01 e USR-01B recebem a MESMA, como o perfil exige) e grava só o hash no formato do
-- legado; nada disso é versionado ou registrado.
--
-- Matriz de concessões (CEN-SEG-004), com ids do catálogo das migrações:
--   F1 = 241 Consultar Imóvel      O1 = 303 Dados Cadastrais (concedida)   O2 = 311 Débitos (NÃO concedida)
--   F2 = 364 Simular Cálculo       operação 458
--   F4 = 4   Manter Cliente        dependente de F1 (funcionalidade_depend SINTÉTICA — a base não tem nenhuma)
--   Grupo A: F1/O1 · Grupo B: F2/458 e F1/O1 · Grupo SEM CONCESSÃO: nenhuma
--   USR-01 e USR-01B: A · USR-02: A e B · USR-03: SEM CONCESSÃO
-- Situação ATIVO = 1 (gcom.seguranca.acesso.usuario.UsuarioSituacao); abrangência, tipo e empresa como
-- o admin da semente. Data de nascimento SINTÉTICA: a troca de senha do legado a exige.

-- Catálogo de situações do usuário: a base reconstruída só tem ATIVO (1, semente das migrações). O código
-- grava as outras — EfetuarLoginAction.bloquearSenha grava SENHA_BLOQUEADA — e, sem a linha, a gravação viola
-- a chave estrangeira fk3_usuario (HTTP 500; achado F2-15). Ids das constantes de
-- gcom.seguranca.acesso.usuario.UsuarioSituacao (PENDENTE_SENHA = 2, SENHA_BLOQUEADA = 3, INATIVO = 4);
-- descrições e indicadores SINTÉTICOS, no padrão da linha ATIVO.
INSERT INTO seguranca.usuario_situacao (usst_id, usst_dsusuariosituacao, usst_dsabreviado, usst_icuso, usst_tmultimaalteracao, usst_icusosistema) VALUES
  (2, 'PENDENTE SENHA', 'PENDSE', 1, '2026-01-01 00:00:00', 1),
  (3, 'SENHA BLOQUEADA', 'BLOQUE', 1, '2026-01-01 00:00:00', 1),
  (4, 'INATIVO', 'INATIV', 1, '2026-01-01 00:00:00', 1);

INSERT INTO seguranca.grupo (grup_id, grup_dsgrupo, grup_dsabreviado, grup_icuso, grup_tmultimaalteracao, grup_icsuperintendencia) VALUES
  (2001, 'SEG GRUPO A (SINTETICO)', 'SGA', 1, '2026-01-01 00:00:00', 2),
  (2002, 'SEG GRUPO B (SINTETICO)', 'SGB', 1, '2026-01-01 00:00:00', 2),
  (2003, 'SEG SEM CONCESSAO (SINTETICO)', 'SGC', 1, '2026-01-01 00:00:00', 2);

INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (2001, 303, 241, '2026-01-01 00:00:00'),
  (2002, 458, 364, '2026-01-01 00:00:00'),
  (2002, 303, 241, '2026-01-01 00:00:00');

INSERT INTO seguranca.usuario
  (usur_id, utip_id, usur_nmlogin, usur_nmsenha, usur_tmultimaalteracao, usst_id, usab_id, empr_id, usur_nmusuario,
   usur_ictiporelatoriopadrao, usur_icexibemensagem, usur_icrotinabatch, usur_icinternet, usur_dtnascimento) VALUES
  (2001, 1, 'seg.usr01', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 01 (SINTETICO)', 1, 1, 2, 2, '1990-01-01'),
  (2011, 1, 'seg.usr01b', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 01B (SINTETICO)', 1, 1, 2, 2, '1990-01-01'),
  (2002, 1, 'seg.usr02', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 02 (SINTETICO)', 1, 1, 2, 2, '1990-01-01'),
  (2003, 1, 'seg.usr03', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 03 (SINTETICO)', 1, 1, 2, 2, '1990-01-01');

INSERT INTO seguranca.usuario_grupo (grup_id, usur_id, usgr_tmultimaalteracao) VALUES
  (2001, 2001, '2026-01-01 00:00:00'),
  (2001, 2011, '2026-01-01 00:00:00'),
  (2001, 2002, '2026-01-01 00:00:00'),
  (2002, 2002, '2026-01-01 00:00:00'),
  (2003, 2003, '2026-01-01 00:00:00');

INSERT INTO seguranca.funcionalidade_depend (fncd_id, fncd_iddependencia, fndp_tmultimaalteracao) VALUES
  (4, 241, '2026-01-01 00:00:00');
