-- Delta — catálogo de ações do usuário para o registro de operações (auditoria) do legado.
--
-- EVIDÊNCIA: a troca de senha (ControladorAcessoSEJB.efetuarAlteracaoSenha) registra a operação 52
-- (Operacao.OPERACAO_USUARIO_ALTERAR_SENHA, presente no catálogo das migrações) com
-- UsuarioAcao.USUARIO_ACAO_EFETUOU_OPERACAO (id 1). Na base reconstruída seguranca.usuario_acao está VAZIA
-- — nenhuma migração a povoa — e a gravação falha ("Erro de acesso ao banco de dados"; achado F2-17).
-- Ids das constantes de gcom.seguranca.acesso.usuario.UsuarioAcao (EFETUOU_OPERACAO = 1,
-- RESPONSAVEL_INFORMACAO = 2); descrições SINTÉTICAS.
INSERT INTO seguranca.usuario_acao (usac_id, usac_dsusuarioacao, usac_icuso, usac_tmultimaalteracao) VALUES
  (1, 'EFETUOU OPERACAO', 1, '2026-01-01 00:00:00'),
  (2, 'RESPONSAVEL INFORMACAO', 1, '2026-01-01 00:00:00');

-- Tipos de alteração da trilha por linha (seguranca.tabela_linha_alteracao.altp_id → alteracao_tipo), também
-- VAZIA na base reconstruída: o mesmo registro de operação da troca de senha grava a linha alterada.
-- Ids de gcom.seguranca.transacao.AlteracaoTipo (ALTERACAO = 1, INCLUSAO = 2, EXCLUSAO = 3); descrições SINTÉTICAS.
INSERT INTO seguranca.alteracao_tipo (altp_id, altp_dsalteracaotipo, altp_dsabreviado, altp_tmultimaalteracao) VALUES
  (1, 'ALTERACAO', 'ALTER', '2026-01-01 00:00:00'),
  (2, 'INCLUSAO', 'INCLU', '2026-01-01 00:00:00'),
  (3, 'EXCLUSAO', 'EXCLU', '2026-01-01 00:00:00');
