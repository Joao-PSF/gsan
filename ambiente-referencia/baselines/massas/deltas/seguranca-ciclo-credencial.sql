-- Delta — ciclo de vida da credencial (CEN-SEG-003): USR-04 (INATIVO), USR-05 (PENDENTE SENHA), USR-06A (acesso
-- expirado), USR-06B (acesso a expirar, prazo de aviso já aberto) e USR-07 (trocas de senha sucessivas).
-- Depende de seguranca-usuarios.sql (situações e grupo A, que concede F1 "Consultar Imovel").
--
-- EVIDÊNCIA (EfetuarLoginAction:121-160): INATIVO lança exceção antes de criar a sessão; outra situação que não
-- ATIVO/PENDENTE mostra a recusa; PENDENTE SENHA e data de expiração ANTERIOR a agora encaminham para a troca de
-- senha (forward "alterarSenha") — depois de gravar o usuário na sessão. usur_dtexpiracaoacesso é java.sql.Date
-- (Usuario.hbm.xml:14): vale a meia-noite do dia.
--
-- Datas RELATIVAS ao dia da execução (current_date do banco): o que importa é a posição em relação a hoje, e o
-- arquivo não muda de um dia para o outro. Ids, nomes e datas SINTÉTICOS.
INSERT INTO seguranca.usuario
  (usur_id, utip_id, usur_nmlogin, usur_nmsenha, usur_tmultimaalteracao, usst_id, usab_id, empr_id, usur_nmusuario,
   usur_ictiporelatoriopadrao, usur_icexibemensagem, usur_icrotinabatch, usur_icinternet, usur_dtnascimento,
   usur_dtexpiracaoacesso, usur_dtprazomsgexpiracao) VALUES
  (2004, 1, 'seg.usr04', NULL, '2026-01-01 00:00:00', 4, 1, 1, 'USUARIO SEG 04 INATIVO (SINTETICO)', 1, 1, 2, 2, '1990-01-01', NULL, NULL),
  (2005, 1, 'seg.usr05', NULL, '2026-01-01 00:00:00', 2, 1, 1, 'USUARIO SEG 05 PENDENTE (SINTETICO)', 1, 1, 2, 2, '1990-01-01', NULL, NULL),
  (2061, 1, 'seg.usr06a', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 06A EXPIRADO (SINTETICO)', 1, 1, 2, 2, '1990-01-01',
   current_date - 1, current_date - 6),
  (2062, 1, 'seg.usr06b', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 06B A EXPIRAR (SINTETICO)', 1, 1, 2, 2, '1990-01-01',
   current_date + 5, current_date - 1),
  (2007, 1, 'seg.usr07', NULL, '2026-01-01 00:00:00', 1, 1, 1, 'USUARIO SEG 07 HISTORICO (SINTETICO)', 1, 1, 2, 2, '1990-01-01', NULL, NULL);
INSERT INTO seguranca.usuario_grupo (grup_id, usur_id, usgr_tmultimaalteracao) VALUES
  (2001, 2004, '2026-01-01 00:00:00'),
  (2001, 2005, '2026-01-01 00:00:00'),
  (2001, 2061, '2026-01-01 00:00:00'),
  (2001, 2062, '2026-01-01 00:00:00'),
  (2001, 2007, '2026-01-01 00:00:00');
