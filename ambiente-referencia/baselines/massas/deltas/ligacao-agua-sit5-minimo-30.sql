-- Delta — CEN-CAD-004: situação de água 5 que fatura (1) com consumo mínimo de faturamento 30 m³.
--
-- Mostra se a faturabilidade vem do DADO da situação ou do id: a MESMA situação (id 5, a constante CORTADO de
-- LigacaoAguaSituacao) recebe dados diferentes conforme a variação. EVIDÊNCIA do mecanismo esperado:
-- ControladorFaturamentoFINAL.permiteFaturamentoParaAgua (:1957) decide por last_icfaturamento e last_nnconsumominimo, não pelo id; a simulação
-- valida o consumo informado contra o mínimo da situação (verificarConsumoFaturadoAgua, :36725).
-- A base reconstruída não tem nenhuma situação de ligação (as da massa base também são sintéticas); a semântica da
-- instalação real (inclusive o valor 4 de água) não é caracterizável aqui. Valores SINTÉTICOS.
INSERT INTO atendimentopublico.ligacao_agua_situacao
  (last_id, last_dsligacaoaguasituacao, last_icuso, last_tmultimaalteracao, last_dsabreviado,
   last_icfaturamento, last_nnconsumominimo, last_icexistenciarede, last_icexistencialigacao,
   last_icabastecimento, last_iccadastradaagua, last_icativaagua, last_icdesligadaagua,
   last_icanaliseagua, last_icconsumoreal, last_nndiascorte) VALUES
  (5, 'CORTADO (SINTETICO)', 1, '2026-01-01 00:00:00', 'COR', 1, 30, 1, 1, 2, 1, 2, 1, 2, 1, NULL);
