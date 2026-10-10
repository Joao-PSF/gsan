-- Delta — catálogos que a consistência e o faturamento em sequência exigem e a base reconstruída não tem (lote 5e:
-- consumo pela origem, na conta). Depende de mic-catalogos.sql e de batch-catalogos.sql.
--
-- EVIDÊNCIA (base reconstruída):
-- · faturamento.fatur_situacao_tipo e fatur_situacao_motivo estão VAZIAS: nenhuma situação especial de faturamento pode ser
--   atribuída a um imóvel. Ids pelas constantes de FaturamentoSituacaoTipo (PARALISAR_EMISSAO_CONTAS = 1,
--   PARALISAR_LEITURA_FATURAR_MEDIA = 2, PARALISAR_LEITURA_FATURAR_TAXA_MINIMA = 3, FATURAR_NORMAL = 5). Os INDICADORES e as
--   AÇÕES (consumo e leitura a faturar com e sem leitura, ids de LeituraAnormalidadeConsumo/LeituraAnormalidadeLeitura, já
--   presentes na base) são a CONFIGURAÇÃO de uma instalação — desconhecida; a baseline caracteriza o mecanismo com esta,
--   SINTÉTICA, coerente com o nome de cada situação:
--     1 PARALISAR EMISSÃO: paralisa o faturamento (água), lê normalmente;
--     2 PARALISAR LEITURA / FATURAR MÉDIA: paralisa a leitura; sem leitura, consumo = MÉDIA e leitura = ANTERIOR + MÉDIA;
--     3 PARALISAR LEITURA / FATURAR TAXA MÍNIMA: paralisa a leitura; sem leitura, consumo = MÍNIMO e leitura = ANTERIOR;
--     5 FATURAR NORMAL: nada paralisado; consumo e leitura NORMAIS.
-- · micromedicao.consumo_tipo (montada pelo lote 5) vai de 0 a 9: falta FIXO SITUAÇÃO ESPECIAL (ConsumoTipo = 10), que a
--   consistência grava quando a situação especial fatura o MÍNIMO (ControladorMicromedicao.dadosFaturamentoEspecialMedido).
-- · cadastro.poco_tipo está VAZIA: nenhum imóvel pode ter poço.
INSERT INTO faturamento.fatur_situacao_motivo (ftsm_id, ftsm_dsfatsitmotivo, ftsm_icuso, ftsm_tmultimaalteracao)
VALUES (1, 'SOLICITACAO DO CLIENTE (SINTETICO)', 1, '2026-01-01 00:00:00');
INSERT INTO faturamento.fatur_situacao_tipo (ftst_id, ftst_dsfaturamentosituacaotipo, ftst_icfaturamentoparalisacao, ftst_icleituraparalisacao,
                                         ftst_icuso, ftst_tmultimaalteracao, lacs_idconsacobrarsemleit, lacs_idconsacobrarcomleit,
                                         lalt_idleitafaturarsemleit, lalt_idleitafaturarcomleit, ftst_icfatmtparalisacaoesgoto,
                                         ftst_icvalidoagua, ftst_icvalidoesgoto) VALUES
  (1, 'PARALISAR EMISSAO DE CONTAS (SINTETICO)', 1, 2, 1, '2026-01-01 00:00:00', 3, 3, 4, 4, 2, 1, 2),
  (2, 'PARALISAR LEITURA FATURAR MEDIA (SINTETICO)', 2, 1, 1, '2026-01-01 00:00:00', 2, 3, 0, 4, 2, 1, 2),
  (3, 'PARALISAR LEITURA FATURAR TAXA MINIMA (SINT)', 2, 1, 1, '2026-01-01 00:00:00', 1, 3, 1, 4, 2, 1, 2),
  (5, 'FATURAR NORMAL (SINTETICO)', 2, 2, 1, '2026-01-01 00:00:00', 3, 3, 4, 4, 2, 1, 2);
INSERT INTO micromedicao.consumo_tipo (cstp_id, cstp_dsconsumotipo, cstp_dsabreviadaconsumotipo, cstp_icuso, cstp_tmultimaalteracao, cstp_iccalculomedia)
VALUES (10, 'FIXO SIT ESPECIAL', 'FSE', 1, '2026-01-01 00:00:00', 2);
INSERT INTO cadastro.poco_tipo (poco_id, poco_dspocotipo, poco_icuso, poco_tmultimaalteracao, poco_ichidrometro)
VALUES (1, 'POCO COM HIDROMETRO (SINTETICO)', 1, '2026-01-01 00:00:00', 1);
