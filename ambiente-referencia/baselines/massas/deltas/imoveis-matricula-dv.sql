-- Delta — imóveis cujas matrículas cobrem as fronteiras do dígito verificador e um imóvel excluído logicamente
-- (CEN-CAD-001). Depende de territorio-l1.sql e de imoveis-imv-01-02-03.sql (perfil, envio de conta, situação de
-- atualização cadastral e subcategoria 101).
--
-- Matrícula = número-base seguido do dígito de gcom.util.Util.obterDigitoVerificadorModulo11(Long): pesos 2..9 da
-- direita para a esquerda; resto 0 ou 1 → 0; resto 10 → 1; senão 11 − resto. Fronteiras:
--   100080  base 10008, resto 0  → dígito 0
--   100170  base 10017, resto 1  → dígito 0
--   100161  base 10016, resto 10 → dígito 1
--   100099  base 10009, resto 2  → dígito 9 (o maior possível)
--   100110  base 10011, resto 0  → dígito 0 — imóvel EXCLUÍDO logicamente (imov_icexclusao = 1, ConstantesSistema.SIM)
--   100019  base 10001 com dígito 9 — DV INVÁLIDO de propósito (o correto é 3, o do IMV-01): o legado nunca gera essa
--           matrícula ao inserir; existe aqui para responder se a CONSULTA confere o DV ou só procura o id.
-- Como o IMV-01 (residencial, 1 economia), na quadra 1 de L1. Tudo SINTÉTICO.
INSERT INTO cadastro.imovel (imov_id, loca_id, stcm_id, qdra_id, imov_nnlote, imov_nnsublote, imov_nnimovel, imov_icimovelcondominio,
                             last_id, lest_id, iper_id, imov_icemsextfatmt, imov_icdebitoconta, imov_icexclusao, imov_tmultimaalteracao,
                             cstf_id, icte_id, imov_icvencimentomesseguinte, imov_icnivelinstalacaoesgoto, imov_icimovelareacomum,
                             logr_id, bair_id, lgbr_id, lgcp_id, cep_id, imov_qteconomia, imov_idcategoriaprincipal,
                             imov_idsubcategoriaprincipal, imov_nnsequencialrota) VALUES
  (100080, 1, 1, 1, 4, 0, '80', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 4),
  (100170, 1, 1, 1, 5, 0, '170', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 5),
  (100161, 1, 1, 1, 6, 0, '161', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 6),
  (100099, 1, 1, 1, 7, 0, '99', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 7),
  (100110, 1, 1, 1, 8, 0, '110', 2, 3, 1, 5, 2, 2, 1, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 8),
  (100019, 1, 1, 1, 9, 0, '19', 2, 3, 1, 5, 2, 2, 2, '2026-01-01 00:00:00', 1, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 101, 9);
INSERT INTO cadastro.imovel_subcategoria (imov_id, scat_id, imsb_qteconomia, imsb_tmultimaalteracao) VALUES
  (100080, 101, 1, '2026-01-01 00:00:00'),
  (100170, 101, 1, '2026-01-01 00:00:00'),
  (100161, 101, 1, '2026-01-01 00:00:00'),
  (100099, 101, 1, '2026-01-01 00:00:00'),
  (100110, 101, 1, '2026-01-01 00:00:00'),
  (100019, 101, 1, '2026-01-01 00:00:00');
