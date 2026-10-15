-- Delta — o catálogo de que o PARCELAMENTO de débitos precisa (lote 7b: CEN-COB-004). Depende de fat-lancamentos-catalogos.sql
-- (situação NORMAL e tipo POR IMÓVEL do parcelamento, forma de cobrança EM CONTA, financiamento PARCELAMENTO SERVIÇO),
-- de arr-arrecadador.sql (tipo de documento CONTA), de cob-acrescimos-indices.sql e de cob-acrescimos-encerramento.sql (os tipos
-- de débito MULTA, JUROS e ATUALIZAÇÃO: a conclusão gera um débito a cobrar de cada acréscimo parcelado —
-- ControladorCobranca.gerarDebitosACobrarAcrescimosImpontualidade:10980; sem eles, dbtp_id nulo; exploração).
--
-- EVIDÊNCIA (base reconstruída: tudo vazio):
-- · ProcessarEfetuarParcelamentoDebitosProcesso1Action:166-180 procura a situação do imóvel pela situação de água e esgoto
--   (cadastro.imovel_situacao) — sem ela, "atencao.nao.existe.situacao.imovel.correspondente.situacao.agua.esgoto"; :213-291
--   procura o PERFIL de parcelamento pela situação, perfil do imóvel, subcategoria, resolução de diretoria e categoria
--   (cobranca.parcelamento_perfil) — sem ele, "atencao.nao.existe.perfil.parcelamento.correspondente.situacao.imovel"; a RD
--   é escolhida na tela (cobranca.resolucao_diretoria).
-- · As opções de prestações vêm das faixas do perfil (cobranca.parcel_qtde_reparcel → parcel_qtde_prestacao: máximo de
--   prestações, taxa de juros, percentual mínimo de entrada).
--   A condição de reparcelamento vale "a partir de" N reparcelamentos consecutivos (o maior limite <= N:
--   RepositorioCobrancaHBM.obterQtdeReparcelamentoPerfil:7005-7019) — limite 0 para o primeiro parcelamento.
-- · ControladorCobranca.concluirParcelamentoDebitos:15792 e os geradores (gerarDebitosACobrarParcelamento:11465,
--   gerarCreditoARealizarParcelamento:11756, gerarEntradaParcelamento:12013) gravam débitos e créditos pelos tipos das
--   constantes (DebitoTipo, CreditoTipo, CreditoOrigem, DocumentoTipo, FinanciamentoTipo) — a base tem só 863, 864 de
--   crédito, as origens 14–16 e o documento CONTA.
-- Ids das constantes; descrições, percentuais e faixas SINTÉTICOS. A imovel_situacao cobre IMV-01/02/03 (água LIGADO = 3,
-- esgoto POTENCIAL = 1). O perfil 7001 (RD 7001) não tem desconto; o 7002 (RD 7002) tem desconto de acréscimos.
-- Os três percentuais de desconto de acréscimos (multa, juros, atualização) vão 0,00, não NULL, embora a coluna aceite
-- NULL: ControladorCobranca.obterOpcoesDeParcelamento:9870 os compara sem checar nulo — com NULL, o passo 3 do assistente
-- falha com NullPointerException ("Erro de Sistema"; exploração, achado). O mesmo com o indicador de desconto por faixa de
-- referência da conta da RD (rdir_icdescontofaixarefconta, anulável; :10000) — vai 2 (não).
-- Situações de débito/crédito PARCELADA (5) e ENTRADA DE PARCELAMENTO (7) (DebitoCreditoSituacao): a conclusão marca a conta
-- parcelada (ControladorCobranca.atualizarContaEfetuarParcelamentoDebito:9782) — sem a 5, a gravação falha por chave estrangeira
-- (fk16_conta; exploração); a 7 é a da conta tomada como entrada.
INSERT INTO faturamento.debito_credito_situacao (dcst_id, dcst_dsdebitocreditosituacao, dcst_dsabreviado, dcst_tmultimaalteracao) VALUES
  (5, 'PARCELADA', 'PAR', '2026-01-01 00:00:00'),
  (7, 'ENTRADA DE PARCELAMENTO', 'ENP', '2026-01-01 00:00:00');
-- Motivos de revisão que a conclusão aplica às contas marcadas no passo 2 (ContaMotivoRevisao): a conta tomada como ENTRADA
-- (EP — REVISAO_ENTRADA_DE_PARCELAMENTO = 101, gerarEntradaParcelamento:12041) e a de PAGAMENTO COMPROVADO (NB —
-- REVISAO_POR_PAGAMENTO_COMPROVADO = 98, concluirParcelamentoDebitos:15910); a tabela está VAZIA.
INSERT INTO faturamento.conta_motivo_revisao (cmrv_id, cmrv_dsmotivorevisaoconta, cmrv_icuso, cmrv_tmultimaalteracao, crmv_iccancnegatconta) VALUES
  (98, 'REVISAO POR PAGAMENTO COMPROVADO', 1, '2026-01-01 00:00:00', 2),
  (101, 'REVISAO ENTRADA DE PARCELAMENTO', 1, '2026-01-01 00:00:00', 2);
INSERT INTO cadastro.imovel_situacao_tipo (istp_id, istp_dsimovelsituacaotipo, istp_tmultimaalteracao) VALUES
  (1, 'ATIVO', '2026-01-01 00:00:00');
INSERT INTO cadastro.imovel_situacao (imst_id, istp_id, last_id, lest_id, imst_tmultimaalteracao) VALUES
  (7001, 1, 3, 1, '2026-01-01 00:00:00');
INSERT INTO cobranca.resolucao_diretoria (rdir_id, rdir_nnresolucaodiretoria, rdir_dsassunto, rdir_dtvigenciainicio, rdir_dtvigenciafim,
                                          rdir_tmultimaalteracao, rdir_icparcelamentounico, rdir_icutilizacaolivre, rdir_icdescontosancoes,
                                          rdir_icparcelasematraso, rdir_icparcelamentoemandamento, rdir_icnegociacaosoavista,
                                          rdir_icdescontosoemcontaavista, rdir_icparcelamentolojavirtual, rdir_icdescontofaixarefconta) VALUES
  (7001, 'RD 7001/2026', 'PARCELAMENTO SINTETICO', '2026-01-01', '2099-12-31', '2026-01-01 00:00:00', 2, 1, 2, 2, 2, 2, 2, 2, 2),
  (7002, 'RD 7002/2026', 'PARCELAMENTO COM DESCONTO SINTETICO', '2026-01-01', '2099-12-31', '2026-01-01 00:00:00', 2, 1, 2, 2, 2, 2, 2, 2, 2);
INSERT INTO cobranca.parcelamento_perfil (pcpf_id, iper_id, scat_id, rdir_id, pcpf_pcdescontoacrescimomulta, istp_id, pcpf_tmultimaalteracao,
                                          pcpf_pctarifaminimaprestacao, pcpf_icchequedevolvido, pcpf_icsancoesparcunica, catg_id,
                                          pcpf_icretroativotarsoc, pcpf_icalertaparcelaminima, pcpf_icentradaminima, pcpf_icpesquisacapchidmt,
                                          pcpf_pcdescontoacrescimojurosmora, pcpf_pcdescontoacrescimoatualizacaomonetaria) VALUES
  (7001, 5, NULL, 7001, 0.00, 1, '2026-01-01 00:00:00', 0.00, 2, 2, NULL, 2, 2, 2, 2, 0.00, 0.00),
  (7002, 5, NULL, 7002, 50.00, 1, '2026-01-01 00:00:00', 0.00, 2, 2, NULL, 2, 2, 2, 2, 50.00, 50.00);
INSERT INTO cobranca.parcel_qtde_reparcel (pqtr_id, pcpf_id, pqtr_qtmaximareparcelamento, pqtr_tmultimaalteracao) VALUES
  (7001, 7001, 0, '2026-01-01 00:00:00'),
  (7002, 7002, 0, '2026-01-01 00:00:00');
INSERT INTO cobranca.parcel_qtde_prestacao (pqtp_id, pqtp_qtmaximaprestacao, pqtp_txjuros, pqtp_pcminimoentrada, pqtr_id, pqtp_tmultimaalteracao,
                                            pqtp_icmediavalorcontas, pqtp_icentultcontaatraso) VALUES
  (7001, 3, 0.00, 10.00, 7001, '2026-01-01 00:00:00', 2, 2),
  (7002, 6, 1.00, 10.00, 7001, '2026-01-01 00:00:00', 2, 2),
  (7003, 12, 1.50, 20.00, 7001, '2026-01-01 00:00:00', 2, 2),
  (7004, 3, 0.00, 10.00, 7002, '2026-01-01 00:00:00', 2, 2),
  (7005, 6, 1.00, 10.00, 7002, '2026-01-01 00:00:00', 2, 2);
INSERT INTO financeiro.financiamento_tipo (fntp_id, fntp_dsfinanciamentotipo, fntp_dsabreviado, fntp_icuso, fntp_tmultimaalteracao, fntp_icinclusao) VALUES
  (2, 'PARCELAMENTO AGUA', 'PAG', 1, '2026-01-01 00:00:00', 2),
  (3, 'PARCELAMENTO ESGOTO', 'PES', 1, '2026-01-01 00:00:00', 2),
  (8, 'JUROS PARCELAMENTO', 'JPA', 1, '2026-01-01 00:00:00', 2),
  (9, 'ENTRADA PARCELAMENTO', 'EPA', 1, '2026-01-01 00:00:00', 2);
-- Grupos de parcelamento (gcom.cobranca.ParcelamentoGrupo, 1 a 6): cada débito a cobrar que a conclusão gera aponta o seu
-- (DOCUMENTOS EMITIDOS para os acréscimos e as contas parceladas — gerarDebitosACobrarParcelamento:11504); a tabela está VAZIA e
-- a gravação falha por chave estrangeira (fk9_debito_a_cobrar; exploração).
INSERT INTO cobranca.parcelamento_grupo (pcgr_id, pcgr_dsparcelamentogrupo, pcgr_dsabreviado, pcgr_tmultimaalteracao) VALUES
  (1, 'DOCUMENTOS EMITIDOS', 'DOCEMIT', '2026-01-01 00:00:00'),
  (2, 'FINANCIAMENTOS A COBRAR CURTO PRAZO', 'FINCP', '2026-01-01 00:00:00'),
  (3, 'FINANCIAMENTOS A COBRAR LONGO PRAZO', 'FINLP', '2026-01-01 00:00:00'),
  (4, 'PARCELAMENTOS A COBRAR CURTO PRAZO', 'PARCCP', '2026-01-01 00:00:00'),
  (5, 'PARCELAMENTOS A COBRAR LONGO PRAZO', 'PARCLP', '2026-01-01 00:00:00'),
  (6, 'JUROS COBRADOS', 'JUROS', '2026-01-01 00:00:00');
INSERT INTO faturamento.debito_tipo (dbtp_id, lict_id, dbtp_dsdebitotipo, dbtp_dsabreviado, dbtp_icuso, dbtp_tmultimaalteracao, fntp_id,
                                     dbtp_icgeracaoautomatica, dbtp_icgeracaoconta, dbtp_iccartaocredito, dbtp_icguiajurosctrparcel) VALUES
  (33, 6, 'ENTRADA DE PARCELAMENTO', 'ENTPARC', 1, '2026-01-01 00:00:00', 9, 1, 1, 2, 2),
  (40, 6, 'PARCELAMENTO DE CONTAS', 'PARCCONT', 1, '2026-01-01 00:00:00', 2, 1, 1, 2, 2),
  (41, 6, 'PARCELAMENTO GUIAS PAGAMENTO', 'PARCGUIA', 1, '2026-01-01 00:00:00', 4, 1, 1, 2, 2),
  (42, 6, 'REPARCELAMENTO CURTO PRAZO', 'REPCP', 1, '2026-01-01 00:00:00', 4, 1, 1, 2, 2),
  (43, 2, 'PARCELAMENTO ACRESCIMOS', 'PARCACR', 1, '2026-01-01 00:00:00', 4, 1, 1, 2, 2),
  (44, 2, 'JUROS SOBRE PARCELAMENTO', 'JURPARC', 1, '2026-01-01 00:00:00', 8, 1, 1, 2, 2),
  (45, 6, 'PARCELAMENTO DEB COBRAR CP', 'PDACP', 1, '2026-01-01 00:00:00', 4, 1, 1, 2, 2),
  (47, 6, 'PARCELAMENTO DEB COBRAR LP', 'PDALP', 1, '2026-01-01 00:00:00', 4, 1, 1, 2, 2),
  (50, 6, 'REPARCELAMENTO LONGO PRAZO', 'REPLP', 1, '2026-01-01 00:00:00', 4, 1, 1, 2, 2);
INSERT INTO faturamento.credito_origem (crog_id, crog_dscreditoorigem, crog_dsabreviado, crog_icuso, crog_tmultimaalteracao) VALUES
  (6, 'DESCONTOS CONCEDIDOS NO PARCELAMENTO', 'DCP', 1, '2026-01-01 00:00:00');
INSERT INTO faturamento.credito_tipo (crti_id, lict_id, crti_dscreditotipo, crti_dsabreviado, crti_icuso, crti_tmultimaalteracao, crti_icgeracaoautomatica) VALUES
  (1, 2, 'DESCONTO ACRESCIMOS IMPONT', 'DACR', 1, '2026-01-01 00:00:00', 1),
  (2, 6, 'DESCONTO ANTIGUIDADE DEBITO', 'DANT', 1, '2026-01-01 00:00:00', 1),
  (3, 6, 'DESCONTO INATIVIDADE LIGACAO', 'DINA', 1, '2026-01-01 00:00:00', 1),
  (4, 6, 'CREDITOS ANTERIORES CURTO PRAZ', 'CACP', 1, '2026-01-01 00:00:00', 1),
  (10, 6, 'DESCONTO SANCOES', 'DSAN', 1, '2026-01-01 00:00:00', 1),
  (11, 6, 'DESCONTO TARIFA SOCIAL', 'DTSO', 1, '2026-01-01 00:00:00', 1);
INSERT INTO cobranca.documento_tipo (dotp_id, dotp_dsdocumentotipo, dotp_dsabreviado, dotp_icpagavel, dotp_icuso, dotp_tmultimaalteracao) VALUES
  (2, 'ENTRADA DE PARCELAMENTO', 'ENTPARC', 1, 1, '2026-01-01 00:00:00'),
  (6, 'DEBITO A COBRAR', 'DEBCOB', 2, 1, '2026-01-01 00:00:00'),
  (7, 'GUIA DE PAGAMENTO', 'GUIA', 1, 1, '2026-01-01 00:00:00'),
  (10, 'CREDITO A REALIZAR', 'CREDREAL', 2, 1, '2026-01-01 00:00:00');
-- Concessões do operador: Efetuar Parcelamento de Débitos (funcionalidade 167) com as operações que as migrações concedem ao
-- grupo administrador nela (os passos 1–4, a conclusão, o pagamento à vista e as consultas do assistente).
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao)
SELECT 1001, oper_id, 167, '2026-01-01 00:00:00' FROM seguranca.grupo_func_operacao WHERE grup_id = 1 AND fncd_id = 167;
-- Cada passo do assistente é também uma funcionalidade (a URL de exibição do passo): sem ela, "Acesso a funcionalidade
-- negado: exibirEfetuarParcelamentoDebitosProcesso1Action.do" (exploração). As operações de cada uma, pelo catálogo.
INSERT INTO seguranca.grupo_func_operacao (grup_id, oper_id, fncd_id, gfop_tmultimaalteracao) VALUES
  (1001, 190, 157, '2026-01-01 00:00:00'),
  (1001, 223, 163, '2026-01-01 00:00:00'),
  (1001, 224, 165, '2026-01-01 00:00:00'),
  (1001, 225, 166, '2026-01-01 00:00:00');
