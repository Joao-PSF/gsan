-- Delta — índices de ACRÉSCIMOS POR IMPONTUALIDADE (lote 7: CEN-COB-001, CEN-ARR-002 V2b). Não depende de outro delta.
--
-- EVIDÊNCIA: cobranca.indices_acresc_impont está VAZIA na base; sem índice, ControladorCobranca.
-- calcularAcrescimoPorImpontualidade:5256-5266 zera multa, juros e atualização — nenhum acréscimo é observável.
-- Por que estes valores: a consulta de débitos e a posição de dívida calculam o acréscimo de uma conta NÃO paga com a data
-- de HOJE (dataPagamento nula → new Date(), :5157). Para que o resultado não dependa do dia da execução:
-- · multa MENSAL (iaci_icmultamensal = 1): percentual fixo sobre o valor, sem contar dias (:5280-5298);
-- · juros DIÁRIOS (iaci_icjurosmensal = 2) com TETO (iaci_pclimitejuros): 0,0333% ao dia × dias de atraso, limitado a
--   1,00% (:5338-5354) — o teto é atingido 31 dias depois do vencimento e não muda mais;
-- · atualização monetária pela razão entre o fator do mês anterior ao vencimento (05/2026) e o do último mês cadastrado
--   antes do mês do cálculo (06/2026: pesquisarMenorIndiceAcrescimoImpontualidade, RepositorioCobrancaHBM:1153) — 1,0100
--   ÷ 1,0000, fixo enquanto não houver outro índice.
-- No encerramento (conta paga em atraso) as datas são as do pagamento e do vencimento — fixas.
-- Valores SINTÉTICOS (não são os índices de nenhuma companhia).
INSERT INTO cobranca.indices_acresc_impont (iaci_id, iaci_amreferencia, iaci_pcmulta, iaci_pcjurosmora, iaci_nnfatoratlzcmonetaria,
                                            iaci_tmultimaalteracao, iaci_icjurosmensal, iaci_icmultamensal, iaci_pclimitejuros,
                                            iaci_pclimitemulta) VALUES
  (7101, 202605, 2.00, 0.0333, 1.000000, '2026-01-01 00:00:00', 2, 1, 1.00, 2.00),
  (7102, 202606, 2.00, 0.0333, 1.010000, '2026-01-01 00:00:00', 2, 1, 1.00, 2.00);
