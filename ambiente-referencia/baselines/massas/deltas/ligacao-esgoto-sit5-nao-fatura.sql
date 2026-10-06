-- Delta — CEN-CAD-004: situação de esgoto 5 com indicador de faturamento INATIVO (2).
--
-- Mostra se a faturabilidade vem do DADO da situação ou do id: a MESMA situação (id 5, a constante LIG_FORA_DE_USO de
-- LigacaoEsgotoSituacao) recebe dados diferentes conforme a variação. EVIDÊNCIA do mecanismo esperado:
-- ControladorFaturamentoFINAL.permiteFaturamentoParaEsgoto (:2019) decide por lest_icfaturamento e lest_nnvolumeminimo, não pelo id; a simulação
-- valida o consumo informado contra o mínimo da situação (verificarConsumoFaturadoEsgoto, :36770).
-- A base reconstruída não tem nenhuma situação de ligação (as da massa base também são sintéticas); a semântica da
-- instalação real (inclusive o valor 4 de água) não é caracterizável aqui. Valores SINTÉTICOS (a descrição tem 20 caracteres no máximo).
INSERT INTO atendimentopublico.ligacao_esgoto_situacao
  (lest_id, lest_dsligacaoesgotosituacao, lest_icuso, lest_tmultimaalteracao, lest_dsabreviado,
   lest_icfaturamento, lest_nnvolumeminimo, lest_icexistenciarede, lest_icexistencialigacao,
   lest_iccadastradaesgoto, lest_icativaesgoto, lest_icdesligadaesgoto, lest_icanaliseesgoto) VALUES
  (5, 'LIG FORA DE USO', 1, '2026-01-01 00:00:00', 'LFU', 2, 0, 1, 1, 1, 2, 1, 2);
