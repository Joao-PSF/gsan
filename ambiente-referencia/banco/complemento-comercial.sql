-- P6 — complemento estrutural de gsan_comercial derivado do mapeamento Hibernate do código.
-- GERADO por ambiente-referencia/scripts/mapeamento.py — não editar à mão; a política e a
-- classificação de cada divergência estão em banco/README.md.
-- Objetos que o código (commit legado fixado em versoes.env) mapeia, que a SessionFactory
-- comercial carrega e que nenhuma migração do gsan-migracoes cria: em produção vieram de DDL
-- manual. Tipos derivados do mapeamento; colunas anuláveis; PK pelo <id>. Não é o DDL de
-- produção: é o mínimo para que essas entidades carreguem.
-- Itens: 14. Divergências não complementadas: 6 excluido, 78 transferido (ver verificação).

-- gcom.arrecadacao.DadosPagamentosNaoClassificados (gcom/arrecadacao/DadosPagamentosNaoClassificados.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE arrecadacao.dados_pag_nao_class ADD COLUMN pgst_idatual integer;

-- gcom.arrecadacao.debitoautomatico.DebitoAutomatico (gcom/arrecadacao/debitoautomatico/DebitoAutomatico.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE arrecadacao.debito_automatico ADD COLUMN deba_idusuarioexclusao integer;

-- gcom.atendimentopublico.ordemservico.FiscalizacaoColetiva (gcom/atendimentopublico/ordemservico/FiscalizacaoColetiva.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE atendimentopublico.fiscalizacao_coletiva ADD COLUMN unid_idencerramento integer;

-- gcom.atendimentopublico.ordemservico.FiscalizacaoColetiva (gcom/atendimentopublico/ordemservico/FiscalizacaoColetiva.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE atendimentopublico.fiscalizacao_coletiva ADD COLUMN usur_idencerramento integer;

-- gcom.cadastro.cliente.CadastroUnico (gcom/cadastro/cliente/CadastroUnico.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE cadastro.cadastro_unico ADD COLUMN cadu_icseaster smallint;

-- gcom.cadastro.cliente.Cliente (gcom/cadastro/cliente/Cliente.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE cadastro.cliente ADD COLUMN clie_icrecusasubsidio smallint;

-- gcom.cadastro.localidade.QuadraFace (gcom/cadastro/localidade/QuadraFace.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE cadastro.quadra_face ADD COLUMN dmc_id integer;

-- gcom.faturamento.HistogramaAguaEconomiaSemQuadra (gcom/faturamento/HistogramaAguaEconomiaSemQuadra.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE faturamento.histo_agua_econ_sqdra ADD COLUMN scat_id integer;

-- gcom.faturamento.HistogramaAguaLigacaoSemQuadra (gcom/faturamento/HistogramaAguaLigacaoSemQuadra.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE faturamento.histo_agua_ligacao_sqdra ADD COLUMN scat_id integer;

-- gcom.faturamento.HistogramaEsgotoLigacaoSemQuadra (gcom/faturamento/HistogramaEsgotoLigacaoSemQuadra.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE faturamento.histo_esgt_ligacao_sqdra ADD COLUMN hals_id integer;

-- gcom.faturamento.HistogramaEsgotoLigacaoSemQuadra (gcom/faturamento/HistogramaEsgotoLigacaoSemQuadra.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE faturamento.histo_esgt_ligacao_sqdra ADD COLUMN hels_icvolfixadoagua smallint;

-- gcom.faturamento.HistogramaEsgotoLigacaoSemQuadra (gcom/faturamento/HistogramaEsgotoLigacaoSemQuadra.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE faturamento.histo_esgt_ligacao_sqdra ADD COLUMN last_id integer;

-- gcom.faturamento.HistogramaEsgotoLigacaoSemQuadra (gcom/faturamento/HistogramaEsgotoLigacaoSemQuadra.hbm.xml): coluna de entidade carregada: sem ela, toda leitura da entidade falha
ALTER TABLE faturamento.histo_esgt_ligacao_sqdra ADD COLUMN scat_id integer;

-- gcom.cadastro.Dmc (gcom/cadastro/Dmc.hbm.xml)
-- QuadraFace (território, núcleo do Cadastro) referencia Dmc por dmc_id; a entidade foi acrescentada em 2023 (commit a9b52f1) sem migração — a Fase 0 já registrou que a tabela deriva de schema (modulos/operacional.md §3)
CREATE TABLE cadastro.dmc (
  dmc_id integer,
  dmc_descr varchar(6),
  loca_id integer,
  stcm_id integer,
  dmc_icuso smallint,
  PRIMARY KEY (dmc_id)
);
CREATE SEQUENCE cadastro.seq_dmc;
