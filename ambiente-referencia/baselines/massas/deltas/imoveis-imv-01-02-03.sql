-- Delta — imóveis dos perfis IMV-01, IMV-02 e IMV-03 (cenarios-criticos.md §13.1), só no que a
-- composição de economias exige (CEN-CAD-003). Depende de territorio-l1.sql e da massa base.
--
-- As composições são as mesmas das entradas de CEN-FAT-001 V1, V2 e V3 — o elo da cadeia
-- Cadastro → Faturamento: a composição que o Cadastro mostra é a que o cálculo recebe.
--   IMV-01  100013  residencial, 1 economia
--   IMV-02  100021  residencial, 3 economias (uma subcategoria)
--   IMV-03  100030  residencial 2 (duas subcategorias, 1 + 1) + comercial 1
--
-- Matrículas: número-base 10001..10003 seguido do dígito módulo 11 de
-- gcom.util.Util.obterDigitoVerificadorModulo11(Long) — escolha SINTÉTICA; a forma como o legado
-- atribui a matrícula ao inserir um imóvel é objeto de CEN-CAD-001, não deste delta.
-- ⚠️ Inserido por SQL, o total (imov_qteconomia) e a categoria/subcategoria principal são os que ESTE
-- arquivo grava, coerentes com a composição. Se o legado os mantém coerentes ao gravar é pergunta
-- do caminho de escrita (Inserir/Manter Imóvel) — fora desta massa (ver o relatório da Fase 2).
-- Perfil NORMAL = 5 (gcom.cadastro.imovel.ImovelPerfil); envio de conta ENVIAR_IMOVEL = 2
-- (gcom.cadastro.imovel.ImovelContaEnvio). Descrições SINTÉTICAS.

INSERT INTO cadastro.imovel_perfil (iper_id, iper_dsimovelperfil, iper_icuso, iper_tmultimaalteracao, iper_icgeracaoautomatica,
                                    iper_icinserirmanterperfil, iper_icgerardadosleitura, iper_icbloquearetificacao,
                                    iper_icgrandeconsumidor, iper_icbloqueadadossocial, iper_icgerardeb2aviaconta, iper_iccorporativo)
VALUES (5, 'NORMAL', 1, '2026-01-01 00:00:00', 2, 1, 1, 2, 2, 2, 2, 2);
INSERT INTO cadastro.imovel_conta_envio (icte_id, icte_dscontaenvio, icte_icuso, icte_tmultimaalteracao, icte_icclienteresponsavel)
VALUES (2, 'ENVIAR PARA O IMOVEL', 1, '2026-01-01 00:00:00', 2);
-- imovel.siac_id tem DEFAULT 0 no schema e chave estrangeira para esta tabela: a linha 0 é pressuposta.
-- DISPONIVEL = 0 (gcom.cadastro.SituacaoAtualizacaoCadastral).
INSERT INTO cadastro.situacao_atlz_cadastral (siac_id, siac_dssituacao, siac_icuso, siac_tmultimaalteracao)
VALUES (0, 'DISPONIVEL', 1, '2026-01-01 00:00:00');

INSERT INTO cadastro.subcategoria (scat_id, catg_id, scat_cdsubcategoria, scat_dssubcategoria, scat_icuso, scat_tmultimaalteracao,
                                   scat_nnfatorfiscalizacao, scat_icsazonalidade, scat_icrural) VALUES
  (101, 1, 1, 'RESIDENCIAL PADRAO (SINTETICA)', 1, '2026-01-01 00:00:00', 1, 2, 2),
  (102, 1, 2, 'RESIDENCIAL POPULAR (SINTETICA)', 1, '2026-01-01 00:00:00', 1, 2, 2),
  (201, 2, 1, 'COMERCIAL PADRAO (SINTETICA)', 1, '2026-01-01 00:00:00', 1, 2, 2);

-- Água LIGADO (3), esgoto POTENCIAL (1), tarifa TAR-01, quadra 1 de L1/setor 1.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota) VALUES
  (100013, 1, 1, 1, 1, 0, '10', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 1),
  (100021, 1, 1, 1, 2, 0, '20', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 3, 1, 101, 2),
  (100030, 1, 1, 1, 3, 0, '30', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 3, 1, 101, 3);

INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao) VALUES
  (100013, 101, 1, '2026-01-01 00:00:00'),
  (100021, 101, 3, '2026-01-01 00:00:00'),
  (100030, 101, 1, '2026-01-01 00:00:00'),
  (100030, 102, 1, '2026-01-01 00:00:00'),
  (100030, 201, 1, '2026-01-01 00:00:00');
