-- Delta — usuários de abrangência restrita (USR-08, um por nível) e o catálogo de níveis (CEN-SEG-007).
-- Depende de seguranca-usuarios.sql e de territorio-abrangencia.sql.
--
-- EVIDÊNCIA: seguranca.usuario_abrangencia da base reconstruída só tem ESTADO (1); os outros níveis que
-- ControladorAcessoSEJB.verificarAcessoAbrangencia distingue não existem e nenhum usuário poderia tê-los.
-- Ids das constantes de gcom.seguranca.acesso.usuario.UsuarioAbrangencia (GERENCIA_REGIONAL = 2,
-- ELO_POLO = 3, LOCALIDADE = 4, UNIDADE_NEGOCIO = 5); superiores e descrições SINTÉTICOS.
INSERT INTO seguranca.usuario_abrangencia (usab_id, usab_idsuperior, usab_dsusuarioabrangencia, usab_dsabreviado, usab_icuso,
                                           usab_tmultimaalteracao) VALUES
  (2, 1, 'GERENCIA REGIONAL', 'GER', 1, '2026-01-01 00:00:00'),
  (5, 2, 'UNIDADE NEGOCIO', 'UNE', 1, '2026-01-01 00:00:00'),
  (3, 5, 'ELO POLO', 'ELO', 1, '2026-01-01 00:00:00'),
  (4, 3, 'LOCALIDADE', 'LOC', 1, '2026-01-01 00:00:00');

-- Grupo com a funcionalidade 44 "Manter Conta" (exibirManterContaAction.do), a superfície de consulta em que a
-- GUI chama verificarAcessoAbrangencia (ExibirManterContaAction:125-128). A operação 57 do catálogo tem a mesma
-- URL da funcionalidade. Concessão SINTÉTICA.
INSERT INTO seguranca.grupo (grup_id, grup_dsgrupo, grup_dsabreviado, grup_icuso, grup_tmultimaalteracao, grup_icsuperintendencia)
VALUES (2004, 'SEG ABRANGENCIA (SINTETICO)', 'SGD', 1, '2026-01-01 00:00:00', 2);
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
VALUES (2004, 57, 44, '2026-01-01 00:00:00');

-- Todos lotados no mesmo ponto do território (G1, U1, elo L1, L1): só o NÍVEL muda entre eles.
INSERT INTO seguranca.usuario
  (usur_id, utip_id, usur_nmlogin, usur_nmsenha, usur_tmultimaalteracao, usst_id, usab_id, empr_id, usur_nmusuario,
   usur_ictiporelatoriopadrao, usur_icexibemensagem, usur_icrotinabatch, usur_icinternet, usur_dtnascimento,
   greg_id, uneg_id, loca_cdelo, loca_id) VALUES
  (2081, 1, 'seg.usr08e', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 08 ESTADO (SINTETICO)', 1, 1, 2, 2, '1990-01-01', 1, 1, 1, 1),
  (2082, 1, 'seg.usr08g', NULL, '2026-01-01 00:00:00', 1, 2, 1, 'USUARIO SEG 08 GERENCIA (SINTETICO)', 1, 1, 2, 2, '1990-01-01', 1, 1, 1, 1),
  (2083, 1, 'seg.usr08u', NULL, '2026-01-01 00:00:00', 1, 5, 1, 'USUARIO SEG 08 UNIDADE (SINTETICO)', 1, 1, 2, 2, '1990-01-01', 1, 1, 1, 1),
  (2084, 1, 'seg.usr08p', NULL, '2026-01-01 00:00:00', 1, 3, 1, 'USUARIO SEG 08 ELO (SINTETICO)', 1, 1, 2, 2, '1990-01-01', 1, 1, 1, 1),
  (2085, 1, 'seg.usr08l', NULL, '2026-01-01 00:00:00', 1, 4, 1, 'USUARIO SEG 08 LOCALIDADE (SINTETICO)', 1, 1, 2, 2, '1990-01-01', 1, 1, 1, 1);
INSERT INTO seguranca.usuario_grupo (grup_id, usur_id, usgr_tmultimaalteracao) VALUES
  (2004, 2081, '2026-01-01 00:00:00'),
  (2004, 2082, '2026-01-01 00:00:00'),
  (2004, 2083, '2026-01-01 00:00:00'),
  (2004, 2084, '2026-01-01 00:00:00'),
  (2004, 2085, '2026-01-01 00:00:00');
