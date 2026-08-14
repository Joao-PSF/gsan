# Glossário de Domínio — GSAN/SISAN

Elaborado em 2026-08-14 (Fase 0). Objetivo: linguagem comum para as próximas análises. Cada termo foi definido a partir de **evidências** (classe Java, mapeamento Hibernate → tabela, FKs, constantes e comentários de coluna do banco) — nenhuma definição foi inventada a partir do nome. Conforme a ADR-0005, os termos consolidados do GSAN são preservados; observações apontam problemas sem decidir mudanças (decisões ficam para a etapa de modelagem).

**Conceito ≠ implementação**: várias entidades têm tabela-espelho (`*_geral`, `*_historico`), classes auxiliares e múltiplas telas. O glossário registra o conceito de negócio; a implementação é citada apenas como evidência.

Aos 20 termos estruturantes foram acrescentados 5 conceitos indispensáveis para compreendê-los: **Categoria/Subcategoria**, **Grupo de Faturamento**, **Referência (AAAAMM)**, **Guia de Pagamento** e **Parcelamento**.

---

## 1. Cliente

- **Definição**: pessoa física ou jurídica que se relaciona com a companhia — identificada por nome e CPF/CNPJ, tipificada (`ClienteTipo`), com endereço, contatos e, quando PJ, ramo de atividade.
- **Papel no sistema**: cadastro central de pessoas; vincula-se a imóveis com papéis distintos, responde por contas emitidas, recebe guias e é alvo de ações de cobrança/negativação.
- **Relações principais**:
  ```text
  Cliente
   ├── relaciona-se a Imóveis via ClienteImovel — papel: Proprietário(1), Usuário(2), Responsável(3),
   │     com início/fim de relação e motivo de encerramento
   ├── pode ter Cliente responsável (auto-relação, ex.: órgãos/grupos)
   ├── vincula-se às Contas emitidas (cliente_conta)
   └── pode ser o pagador em Pagamentos e o titular de Guias
  ```
- **Módulo principal**: `cadastro`
- **Evidências**:
  ```text
  Código:       gcom.cadastro.cliente.Cliente, ClienteImovel, ClienteRelacaoTipo (PROPRIETARIO=1, USUARIO=2, RESPONSAVEL=3)
  Mapeamento:   Cliente.hbm.xml → cadastro.cliente; ClienteImovel.hbm.xml → cadastro.cliente_imovel; ClienteConta.hbm.xml → cadastro.cliente_conta
  Banco:        clie_nncpf 'Numero do CPF do cliente', clie_nncnpj, cltp_id (tipo), clie_cdclienteresponsavel (auto-relação)
  ```
- **Observações de modernização**: conceito e nomenclatura consolidados — preservar. O papel na relação com o imóvel (proprietário/usuário/responsável) é regra estruturante e deve permanecer explícito.

## 2. Imóvel

- **Definição**: unidade predial (ou terreno) atendível no território da companhia — a "matrícula". É o centro do modelo comercial: endereço estruturado (localidade/setor/quadra/lote/sublote), características físicas e estado comercial.
- **Papel no sistema**: quase tudo referencia o imóvel: ligações, hidrômetro, leituras, consumo, contas, débitos, créditos, parcelamentos, RAs e OSs. As **situações das ligações de água e esgoto ficam armazenadas no imóvel** (`last_id`, `lest_id`) e comandam faturamento e cobrança.
- **Relações principais**:
  ```text
  Imóvel
   ├── pertence a Localidade → Setor Comercial → Quadra (+ lote/sublote)
   ├── possui Economias por Subcategoria (imovel_subcategoria) e quantidade total (imov_qteconomia)
   ├── guarda a situação da Ligação de Água (last_id) e de Esgoto (lest_id)
   ├── pode ter instalação de Hidrômetro própria (hidi_id — caso poço); a da ligação fica na Ligação de Água
   ├── rotas: leitura via Quadra→Rota; entrega (rota_identrega) e alternativa (rota_idalternativa)
   ├── condomínio: auto-relações imovelCondominio / imovelPrincipal
   ├── tarifa aplicável (ConsumoTarifa) e perfil (ImovelPerfil)
   └── recebe Contas, Débitos, Créditos, RAs, OSs, Parcelamentos
  ```
- **Módulo principal**: `cadastro`
- **Evidências**:
  ```text
  Código:       gcom.cadastro.imovel.Imovel
  Mapeamento:   Imovel.hbm.xml → cadastro.imovel (loca_id, stcm_id, qdra_id, last_id, lest_id, hidi_id, cstf_id, iper_id, rota_identrega...)
  Banco:        FKs de ligacao_agua/ligacao_esgoto apontam para imov_id (ver termos 9 e 10)
  ```
- **Observações de modernização**: entidade **sobrecarregada** (endereço, situações de ligação, características físicas, flags de faturamento/cobrança e campos sociais customizados como `imov_classe_social` e `imov_qtd_economias_social`). Forte candidata a análise de decomposição na modelagem — preservando a matrícula como identidade estável para migração.

## 3. Economia

- **Definição**: unidade autônoma de consumo dentro de um imóvel (moradia, apartamento, loja, sala...), classificada por Categoria/Subcategoria. Um imóvel tem 1..N economias.
- **Papel no sistema**: base do cálculo tarifário — tarifas mínimas e faixas são aplicadas por economia/categoria; a conta registra valores e economias por categoria.
- **Relações principais**:
  ```text
  Imóvel ── possui N Economias
   ├── agregadas por Subcategoria (imovel_subcategoria.imsb_qteconomia)
   ├── total no próprio imóvel (imov_qteconomia)
   └── individualizadas opcionalmente (imovel_economia)
  Conta ── distribui valores por Categoria/economias (conta_categoria)
  ```
- **Módulo principal**: `cadastro` (uso intenso em `faturamento`)
- **Evidências**:
  ```text
  Código:       NÃO existe classe "Economia" — o conceito materializa-se em gcom.cadastro.imovel.ImovelSubcategoria (PK composta imov_id+scat_id, imsb_qteconomia) e ImovelEconomia
  Mapeamento:   ImovelSubcategoria.hbm.xml → cadastro.imovel_subcategoria; ImovelEconomia.hbm.xml → cadastro.imovel_economia
  Banco:        faturamento.conta_categoria; customização: imov_qtd_economias_social
  ```
- **Observações de modernização**: **representação tripla** (total no imóvel, agregada por subcategoria, individualizada) sem entidade explícita. Resolvido em 2026-08-14: a agregada por subcategoria governa os processos; a individualizada é informativa — detalhes em [modulos/cadastro.md §3.4](../modulos/cadastro.md).

## 4. Categoria e Subcategoria *(acrescentado)*

- **Definição**: classificação tarifária das economias — Categoria (residencial, comercial, industrial, pública) subdividida em Subcategorias.
- **Papel no sistema**: eixo do cálculo tarifário (tarifas, consumo mínimo, faixas) e das análises comerciais; a conta consolida valores por categoria.
- **Relações principais**: Categoria 1—N Subcategoria; Economia classificada por Subcategoria; Conta → `conta_categoria`.
- **Módulo principal**: `cadastro` (regras de tarifa em `faturamento`)
- **Evidências**:
  ```text
  Código:      gcom.cadastro.imovel.Categoria / Subcategoria
  Mapeamento:  Categoria.hbm.xml → cadastro.categoria; Subcategoria.hbm.xml → cadastro.subcategoria
  ```

## 5. Localidade

- **Definição**: divisão territorial-comercial primária da companhia (tipicamente cidade/distrito operado), classificada por porte/classe, podendo apontar para uma localidade **pólo/elo** (agrupamento).
- **Papel no sistema**: raiz da hierarquia territorial para gestão, metas e relatórios; todo imóvel pertence a uma localidade.
- **Relações principais**:
  ```text
  Gerência Regional / Unidade de Negócio
     └── Localidade (auto-relação de elo: loca_cdelo)
            └── Setores Comerciais
  ```
- **Módulo principal**: `cadastro`
- **Evidências**:
  ```text
  Código:      gcom.cadastro.localidade.Localidade
  Mapeamento:  Localidade.hbm.xml → cadastro.localidade (greg_id, uneg_id, loca_cdelo, muni_idprincipal)
  ```

## 6. Setor Comercial

- **Definição**: subdivisão da localidade que agrupa quadras, com código próprio dentro da localidade.
- **Papel no sistema**: unidade intermediária de organização comercial e de leitura; as rotas pertencem ao setor.
- **Relações principais**: pertence a Localidade; referencia Município; contém Quadras; Rotas são do setor.
- **Módulo principal**: `cadastro`
- **Evidências**:
  ```text
  Mapeamento:  SetorComercial.hbm.xml → cadastro.setor_comercial (loca_id, muni_id); Rota.stcm_id; Quadra.stcm_id
  ```

## 7. Quadra

- **Definição**: menor agrupamento territorial de imóveis (conjunto de lotes) dentro do setor comercial.
- **Papel no sistema**: vincula os imóveis à **rota de leitura**; carrega recortes geográficos/operacionais (bairro, bacia, distrito operacional, setor censitário).
- **Relações principais**: pertence a Setor Comercial; vinculada a 1 Rota; contém Imóveis (lote/sublote); bairro e recortes operacionais.
- **Módulo principal**: `cadastro`
- **Evidências**:
  ```text
  Mapeamento:  Quadra.hbm.xml → cadastro.quadra (stcm_id, rota_id, bair_id, diop_id, baci_id, istc_id)
  ```

## 8. Rota

- **Definição**: percurso de trabalho de campo que agrupa quadras/imóveis para **leitura de hidrômetros, entrega de contas e ações de cobrança**, com responsável (leiturista/empresa) e tipo de leitura.
- **Papel no sistema**: unidade operacional da micromedição e elo com o cronograma mensal — toda rota pertence a um Grupo de Faturamento e pode ter grupo/critério de cobrança.
- **Relações principais**:
  ```text
  Rota
   ├── pertence a Setor Comercial e a Grupo de Faturamento (cronograma)
   ├── Leiturista / Empresa de leitura / Empresa de entrega / Empresa de cobrança
   ├── grupo e critério de Cobrança
   └── contém Quadras (imóvel tem sequencial na rota; e rotas de entrega/alternativa próprias)
  ```
- **Módulo principal**: `micromedicao`
- **Evidências**:
  ```text
  Código:      gcom.micromedicao.Rota
  Mapeamento:  Rota.hbm.xml → micromedicao.rota (stcm_id, ftgr_id, leit_id, lttp_id, empr_id/identregacontas/idcobranca, cbgr_id, cbct_id)
  ```
- **Observações de modernização**: o imóvel referencia rota por três caminhos (via quadra, rota de entrega, rota alternativa) — confirmar no mapa da micromedição qual comanda cada processo.

## 9. Ligação de Água

- **Definição**: ponto físico de conexão do imóvel à rede de abastecimento (ramal), com características técnicas (diâmetro, material, perfil, local do ramal) e eventos de corte/supressão/religação. No GSAN é **extensão 1:1 do imóvel — mesma chave** (`lagu_id = imov_id`).
- **Papel no sistema**: habilita abastecimento e medição. A **situação** (armazenada no imóvel) comanda faturamento/cobrança: Potencial(1), Factível(2), Ligado(3), Ligado à revelia(4), Cortado(5), Suprimido(6).
- **Relações principais**:
  ```text
  Imóvel ──1:1── Ligação de Água (mesmo id)
   ├── Instalação de Hidrômetro (hidrometro_inst_hist.lagu_id)
   ├── eventos: corte (tipo/motivo), supressão (tipo/motivo), religação — executados por OS
   └── características técnicas (diâmetro, material, pavimentos afetados)
  ```
- **Módulo principal**: `atendimentopublico` (a ligação nasce de processo de atendimento)
- **Evidências**:
  ```text
  Código:      gcom.atendimentopublico.ligacaoagua.LigacaoAgua; LigacaoAguaSituacao (constantes acima)
  Mapeamento:  LigacaoAgua.hbm.xml → atendimentopublico.ligacao_agua (id assigned)
  Banco:       fk15_ligacao_agua: FOREIGN KEY (lagu_id) REFERENCES cadastro.imovel(imov_id); Imovel.last_id
  ```
- **Observações de modernização**: identidade compartilhada com o imóvel e situação armazenada fora da ligação; além disso `LIGADO_A_REVELIA = 4` e `LIGADO_EM_ANALISE = 4` (mesmo código com dois nomes). Avaliar na modelagem se a ligação vira entidade com ciclo de vida próprio; módulo "dono" no código (`atendimentopublico`) difere da intuição de cadastro.

## 10. Ligação de Esgoto

- **Definição**: ponto de conexão do imóvel à rede coletora de esgoto — mesmo padrão da ligação de água (`lesg_id = imov_id`), com características próprias (diâmetro, material, esgotamento, destino de dejetos/águas pluviais, caixa de inspeção).
- **Papel no sistema**: habilita a cobrança de esgoto — o valor de esgoto da conta deriva do consumo de água conforme a situação/percentual de esgoto (regra a caracterizar em faturamento).
- **Relações principais**: Imóvel ──1:1── Ligação de Esgoto; situação no imóvel (`lest_id`); fotografada em Conta e Parcelamento.
- **Módulo principal**: `atendimentopublico`
- **Evidências**:
  ```text
  Mapeamento:  LigacaoEsgoto.hbm.xml → atendimentopublico.ligacao_esgoto
  Banco:       fk10_ligacao_esgoto: FOREIGN KEY (lesg_id) REFERENCES cadastro.imovel(imov_id)
  ```

## 11. Hidrômetro

- **Definição**: equipamento medidor de volume, com identidade própria (número, tipo, marca, capacidade, diâmetro, classe metrológica) e ciclo de vida (armazenagem → instalação → retirada/baixa).
- **Papel no sistema**: viabiliza o consumo REAL. A **instalação** é um histórico que vincula o hidrômetro a uma Ligação de Água **ou** diretamente a um imóvel (poço) — `MedicaoTipo`: LIGACAO_AGUA(1), POCO(2).
- **Relações principais**:
  ```text
  Hidrômetro ── HidrometroInstalacaoHistorico (instalação vigente/histórica)
                 ├── em Ligação de Água (lagu_id) — medição tipo 1
                 ├── ou em Imóvel (imov_id) — poço, tipo 2
                 ├── local da instalação, proteção, rateio (condomínio)
                 └── Leituras referenciam a instalação (hidi_id)
  ```
- **Módulo principal**: `micromedicao`
- **Evidências**:
  ```text
  Código:      gcom.micromedicao.hidrometro.Hidrometro, HidrometroInstalacaoHistorico; MedicaoTipo
  Mapeamento:  Hidrometro.hbm.xml → micromedicao.hidrometro; HidrometroInstalacaoHistorico.hbm.xml → micromedicao.hidrometro_inst_hist (hidr_id, lagu_id, imov_id, medt_id)
  ```
- **Observações de modernização**: conceito claro e preservável; manter explícita a dupla ancoragem (ligação × imóvel/poço).

## 12. Leitura

- **Definição**: registro periódico do valor apontado no hidrômetro em uma referência (AAAAMM), com leitura anterior/atual, datas, situação, anormalidade e leiturista. O GSAN distingue leitura **informada** (campo) da leitura **de faturamento** (validada, usada no cálculo).
- **Papel no sistema**: insumo do consumo; anormalidades de leitura disparam críticas e podem interferir no faturamento.
- **Relações principais**:
  ```text
  Leitura (MedicaoHistorico, por imóvel + referência)
   ├── da Instalação de Hidrômetro (hidi_id) / Ligação de Água (lagu_id) / Imóvel (imov_id)
   ├── Leiturista; situação de leitura anterior/atual; anormalidade informada × de faturamento
   └── produz o consumo medido do mês (mdhi_nnconsumomedidomes)
  ```
- **Módulo principal**: `micromedicao`
- **Evidências**:
  ```text
  Código:      gcom.micromedicao.medicao.MedicaoHistorico
  Mapeamento:  MedicaoHistorico.hbm.xml → micromedicao.medicao_historico (mdhi_nnleitantfatmt, mdhi_nnleituraatualinformada, mdhi_nnleituraatualfaturamento)
  Banco:       comentários 'Leitura de Campo', 'Data da leitura anterior de faturamento', leit_id 'Id do Leiturista'
  ```
- **Observações de modernização**: a separação informada × faturamento é regra de ouro para os testes de caracterização.

## 13. Consumo

- **Definição**: volume (m³) atribuído ao imóvel em uma referência para faturamento. Pode ser REAL (medido), por MÉDIA (do hidrômetro ou do imóvel), MÍNIMO/FIXADO ou rateado (condomínio) — `ConsumoTipo`: REAL(1), MEDIA_HIDROMETRO(3), CONSUMO_MINIMO_FIXADO(7), MEDIA_IMOVEL(9); customização social: CONSUMO_MINIMO_BOLSA_AGUA(11).
- **Papel no sistema**: base quantitativa da conta; mantém o consumo usado no cálculo de média (`cshi_nnconsumocalculomedia`).
- **Relações principais**: deriva da Leitura (quando real); pertence a Imóvel + referência; tipo de ligação (água/poço); anormalidade de consumo; rateio referenciando o consumo do imóvel-condomínio.
- **Módulo principal**: `micromedicao` (consumido por `faturamento`)
- **Evidências**:
  ```text
  Código:      gcom.micromedicao.consumo.ConsumoHistorico; ConsumoTipo
  Mapeamento:  ConsumoHistorico.hbm.xml → micromedicao.consumo_historico (cshi_amfaturamento, cshi_nnconsumofaturadomes, cstp_id, rttp_id, cshi_idconsumoimovelcondominio)
  ```
- **Observações de modernização**: tipos incluem customizações sociais (Bolsa Água) — separar núcleo × customização na análise de compatibilidade.

## 14. Conta

- **Definição**: documento mensal de cobrança dos serviços de um imóvel numa referência (AAAAMM): valores de água e esgoto + débitos cobrados − créditos realizados + impostos, com vencimento e situação. É "a fatura mensal" do imóvel.
- **Papel no sistema**: núcleo financeiro do faturamento; alvo de pagamento; quando vencida alimenta a cobrança; sofre retificação, revisão, cancelamento e inclusão em parcelamento — tudo controlado por situação.
- **Relações principais**:
  ```text
  Conta (Imóvel + referência AAAAMM)
   ├── composição: valorAgua + valorEsgoto + débitos (DebitoCobrado) − créditos (CreditoRealizado) + impostos
   ├── por categoria/economias (conta_categoria)
   ├── situação (DebitoCreditoSituacao atual/anterior): NORMAL(0), RETIFICADA(1), INCLUIDA(2=parcelamento),
   │     CANCELADA(3), CANCELADA_POR_RETIFICACAO(4), ..., DEBITO_PRESCRITO(8), PRE_FATURADA(9)
   ├── clientes vinculados na emissão (cliente_conta); Grupo de Faturamento; fotografias (situação das ligações, quadra, tarifa)
   ├── paga via Pagamento (apontando para ContaGeral)
   └── versões: conta_geral (id estável) / conta_historico / origem (cnta_idorigem)
  ```
- **Módulo principal**: `faturamento`
- **Evidências**:
  ```text
  Código:      gcom.faturamento.conta.Conta, ContaGeral, DebitoCreditoSituacao
  Mapeamento:  Conta.hbm.xml → faturamento.conta (cnta_amreferenciaconta, cnta_dtvencimentoconta, cnta_vlagua, cnta_vlesgoto, cnta_vldebitos, cnta_vlcreditos, parc_id, ftgr_id, dcst_idatual/anterior, cnta_idorigem)
  Banco:       comentários 'Ano/Mes Referencia Conta', 'Valor Agua', 'Valor Esgoto', 'Data Vencimento Conta'
  ```
- **Observações de modernização**: o mecanismo Conta/ContaGeral/ContaHistorico (id "geral" estável entre versões) é central para retificações e para o vínculo do pagamento — compreendê-lo por completo antes de modelar; impacto direto na migração.

## 15. Débito

- **Definição**: obrigação a cobrar do imóvel/cliente, tipificada (`DebitoTipo`). Dois momentos: **Débito a Cobrar** (lançamento com valor total e prestações, aguardando inclusão em contas futuras ou pagamento avulso) e **Débito Cobrado** (a parcela efetivamente incluída em uma conta emitida).
- **Papel no sistema**: veículo de cobrança de serviços (OS), prestações de parcelamento e lançamentos diversos, com integração contábil.
- **Relações principais**:
  ```text
  DébitoACobrar (Imóvel, DebitoTipo, prestações, situação)
   ├── origem: OS / RA / Parcelamento / lançamentos
   ├── incluído em Contas como DébitoCobrado, ou pago direto (Pagamento.dbac_id)
   └── contabilização: LancamentoItemContabil
  ```
- **Módulo principal**: `faturamento` (uso intenso em `cobranca`)
- **Evidências**:
  ```text
  Mapeamento:  DebitoACobrar.hbm.xml → faturamento.debito_a_cobrar (dbtp_id, parc_id, orse_id, rgat_id, lict_id, dcst_id*); DebitoCobrado.hbm.xml → faturamento.debito_cobrado
  ```
- **Observações de modernização**: no uso corrente "débito" também significa "dívida do imóvel" (contas em aberto). Manter os dois planos distintos no SISAN: débito-lançamento (este conceito) × débito-em-aberto (estado da dívida).

## 16. Crédito

- **Definição**: valor a favor do imóvel/cliente, tipificado e com origem (`CreditoTipo`, `CreditoOrigem`). Dois momentos: **Crédito a Realizar** (lançado, aguardando abatimento) e **Crédito Realizado** (efetivado em conta).
- **Papel no sistema**: devoluções, descontos (inclusive de parcelamento), compensações e programas sociais (customização: crédito Viva Água/Bolsa Água).
- **Relações principais**: espelho do débito — CreditoARealizar (origem em RA/OS/Parcelamento) → CreditoRealizado em Conta; contabilização.
- **Módulo principal**: `faturamento`
- **Evidências**:
  ```text
  Mapeamento:  CreditoARealizar.hbm.xml → faturamento.credito_a_realizar (crti_id, crog_id, parc_id, rgat_id, orse_id); CreditoRealizado.hbm.xml → faturamento.credito_realizado
  Banco:       função customizada faturamento.sp1_gerar_cred_pagto_viva_agua (gsan_comercial)
  ```

## 17. Guia de Pagamento *(acrescentado)*

- **Definição**: documento avulso de cobrança de débitos fora da conta mensal (ex.: serviço de OS, entrada de parcelamento), emitido para imóvel ou cliente, com prestações e situação.
- **Papel no sistema**: permite cobrar sem esperar o ciclo mensal; alvo direto de pagamento.
- **Relações principais**: origem em RA/OS/Parcelamento; `DebitoTipo`; paga via Pagamento (`gpag_id` → GuiaPagamentoGeral); versões `guia_pagamento_geral`/histórico.
- **Módulo principal**: `faturamento` (emissão) / `arrecadacao` (recebimento)
- **Evidências**:
  ```text
  Mapeamento:  GuiaPagamento.hbm.xml → faturamento.guia_pagamento (parc_id, rgat_id, orse_id, dbtp_id, gpag_idorigem)
  ```

## 18. Parcelamento *(acrescentado)*

- **Definição**: negociação da dívida do imóvel: consolida contas vencidas/débitos, define entrada + prestações, com tipo, perfil e situação; pode conceder descontos; pode ser **desfeito** ou cancelado (com motivo e usuário).
- **Papel no sistema**: principal instrumento de regularização na cobrança. Gera Débitos a Cobrar (prestações), Créditos a Realizar (descontos) e Guia (entrada); as contas incluídas mudam de situação (INCLUIDA=2). O imóvel guarda contadores de parcelamentos/reparcelamentos.
- **Relações principais**:
  ```text
  Parcelamento (Imóvel, situação, tipo, perfil, RA de origem)
   ├── consolida Contas vencidas / débitos / acréscimos
   ├── gera DébitoACobrar (prestações), CréditoARealizar (descontos), Guia (entrada)
   ├── desfazer/cancelar: motivo + usuário; reparcelamento controlado (funções verificaseoparcelamentofoireparcelado*)
   └── autorização especial via Resolução de Diretoria
  ```
- **Módulo principal**: `cobranca`
- **Evidências**:
  ```text
  Mapeamento:  Parcelamento.hbm.xml → cobranca.parcelamento (pcst_id, pctp_id, pcpf_id, pmdz_id, rdir_id, usur_iddesfaz)
  Banco:       Conta.parc_id; DebitoACobrar.parc_id; CreditoARealizar.parc_id; funções cobranca.verificaseoparcelamentofoireparcelado*
  ```

## 19. Cobrança

- **Definição**: **processo** (não um documento único) de recuperação de débitos vencidos por ações escalonadas: aviso/carta, ordem de corte, corte, supressão, negativação (SPC/Serasa), cobrança administrativa/terceirizada e parcelamento.
- **Papel no sistema**: comanda cronogramas/comandos de ações por grupo e critério, gera documentos de cobrança e OSs de corte/religação/fiscalização; marca a situação de cobrança no imóvel.
- **Relações principais**:
  ```text
  Cobrança
   ├── insumo: contas/débitos vencidos por imóvel
   ├── ações (CobrancaAcao) em cronogramas/comandos, por grupo de cobrança (Rota.cbgr_id) e critério
   ├── gera CobrancaDocumento (pagável) e OS (corte/religação/fiscalização)
   ├── situação de cobrança no imóvel (cbst_id/cbsp_id)
   └── desdobramentos: Parcelamento | negativação (spcserasa) | cobrança por resultado (empresas)
  ```
- **Módulo principal**: `cobranca`
- **Evidências**:
  ```text
  Código:      pacote gcom.cobranca (CobrancaAcao*, CobrancaDocumento, CobrancaGrupo/Criterio); gcom.spcserasa
  Mapeamento:  Imovel.hbm.xml (cbst_id, cbsp_id); Pagamento.hbm.xml (cbdo_id); Rota.hbm.xml (cbgr_id, cbct_id)
  ```

## 20. Arrecadação

- **Definição**: **processo** de recebimento dos valores pagos: captura dos movimentos dos arrecadadores (bancos, lotéricas, cartão, débito automático — e PIX, customização posterior), conciliação por aviso bancário e classificação dos pagamentos (baixa nos documentos).
- **Papel no sistema**: fecha o ciclo financeiro; trata excedentes, pagamentos não classificados e devoluções; possui referência própria (AAAAMM de arrecadação).
- **Relações principais**:
  ```text
  Arrecadador (convênio) → ArrecadadorMovimento/Item (retornos CNAB)
     └── origina Pagamentos (classificação → baixa em Conta/Guia/Débito/Documento de cobrança)
  AvisoBancario ── concilia lotes/valores por data
  Devolucao ── valores a devolver/creditar
  PIX: arrecadacao_pix / conta_qrcode_pix / GeradorQrCodePIX (posterior, fora das migrations)
  ```
- **Módulo principal**: `arrecadacao`
- **Evidências**:
  ```text
  Código:      pacote gcom.arrecadacao (Pagamento, ArrecadadorMovimentoItem, AvisoBancario, Devolucao); gcom.arrecadacao.GeradorQrCodePIX
  Mapeamento:  Pagamento.hbm.xml (arfm_id ArrecadacaoForma, amit_id, avbc_id)
  ```

## 21. Pagamento

- **Definição**: registro individual de valor recebido (data, valor, forma, arrecadador, referência de arrecadação) vinculado ao documento pago — conta (via ContaGeral), guia, débito a cobrar, fatura ou documento de cobrança — com situação de classificação atual/anterior.
- **Papel no sistema**: efetiva a baixa dos documentos; excedentes e não-classificados seguem fluxos próprios.
- **Relações principais**:
  ```text
  Pagamento
   ├── alvo: ContaGeral (cnta_id) | GuiaPagamentoGeral (gpag_id) | DébitoACobrarGeral (dbac_id) | Fatura (fatu_id) | CobrancaDocumento (cbdo_id)
   ├── de Imóvel ou Cliente; forma de arrecadação; cartão de débito
   └── origem: ArrecadadorMovimentoItem; conciliação: AvisoBancario
  ```
- **Módulo principal**: `arrecadacao`
- **Evidências**:
  ```text
  Mapeamento:  Pagamento.hbm.xml → arrecadacao.pagamento (pgmt_vlpagamento, pgmt_dtpagamento, pgmt_amreferenciaarrecadacao, pgst_idatual/anterior + FKs acima)
  ```
- **Observações de modernização**: cinco alvos possíveis de baixa sugerem formalizar no SISAN a abstração "documento cobrável"; "Fatura" (`faturamento.fatura` — agrupamento de contas, ex.: cliente responsável) precisa de aprofundamento próprio.

## 22. Registro de Atendimento (RA)

- **Definição**: registro formal de uma solicitação ou reclamação (presencial, telefone, internet...), tipificada por `SolicitacaoTipo/Especificacao`, com situação, prazos e **tramitação entre unidades organizacionais**. Pode referir um imóvel **ou** apenas um endereço/local de ocorrência (atendimento a não-clientes).
- **Papel no sistema**: porta de entrada do atendimento; origina OSs e documentos (guia, débito, crédito, parcelamento); encerrado com motivo; pode ser reativado ou marcado como duplicidade.
- **Relações principais**:
  ```text
  RA
   ├── solicitante (cliente/usuário) + Imóvel OU endereço/local de ocorrência
   ├── tipo: SolicitacaoTipoEspecificacao; meio de solicitação
   ├── tramita por Unidades Organizacionais (unid_idatual)
   ├── origina OS(s), Guia, Débito, Crédito, Parcelamento (rgat_id nessas entidades)
   └── encerramento (motivo); reativação/duplicidade (auto-relações)
  ```
- **Módulo principal**: `atendimentopublico`
- **Evidências**:
  ```text
  Mapeamento:  RegistroAtendimento.hbm.xml → atendimentopublico.registro_atendimento (step_id, meso_id, unid_idatual, amen_id, rgat_idreativacao, rgat_idduplicidade, imov_id opcional, campos de endereço/perímetro)
  ```

## 23. Ordem de Serviço (OS)

- **Definição**: instrumento de execução de um serviço tipificado (`ServicoTipo`) em campo ou escritório, geralmente originada de um RA ou de comandos (cobrança, fiscalização, ordens seletivas), com prioridade (original/atual), tramitação e encerramento.
- **Papel no sistema**: braço operacional. Ao encerrar, pode **atualizar a situação das ligações do imóvel** (indicadores `orse_icatualizaagua`/`orse_icatualizaesgoto`) e gerar débito do serviço quando cobrável; executada em campo via mobile.
- **Relações principais**:
  ```text
  OS
   ├── origem: RA (rgat_id) | comando de cobrança (cbdo_id) | fiscalização | OS de referência
   ├── ServicoTipo + prioridade; unidade atual; projeto
   ├── execução: equipes/campo (mobile.exe_os_*), boletim de medição
   ├── encerramento (motivo) → pode atualizar situação água/esgoto do imóvel
   └── pode gerar DébitoACobrar/Guia (serviço cobrável) e OS de retorno
  ```
- **Módulo principal**: `atendimentopublico`
- **Evidências**:
  ```text
  Mapeamento:  OrdemServico.hbm.xml → atendimentopublico.ordem_servico (rgat_id, svtp_id, stpr_idoriginal/atual, unid_idatual, cbdo_id)
  Banco:       comentários 'Ind. Sit. Agua Imovel Alterada', 'Ind. Sit. Esg. Imovel Alterada'; DebitoACobrar.orse_id; mobile.exe_os_* (gsan_comercial)
  ```

## 24. Grupo de Faturamento *(acrescentado)*

- **Definição**: agrupamento operacional que define o **cronograma do ciclo mensal**: as rotas do grupo são lidas, faturadas e vencem juntas (dia de vencimento, vencimento no mês da fatura ou seguinte); guarda a referência corrente do grupo (`ftgr_amreferencia`).
- **Papel no sistema**: pulso do ciclo comercial (leitura → cálculo → emissão → vencimento) em lotes; o batch de faturamento processa por grupo.
- **Relações principais**: Grupo 1—N Rotas (`rota.ftgr_id`); Conta pertence a um grupo (`cnta`→`ftgr_id`); cronogramas de faturamento e cobrança por grupo.
- **Módulo principal**: `faturamento`
- **Evidências**:
  ```text
  Mapeamento:  FaturamentoGrupo.hbm.xml → faturamento.faturamento_grupo (ftgr_amreferencia, ftgr_nndiavencimento, ftgr_icvencimentomesfatura)
  ```

## 25. Referência (Ano/Mês — AAAAMM) *(acrescentado)*

- **Definição**: competência no formato inteiro `AAAAMM` que indexa todo o ciclo comercial: leitura/medição, consumo (`cshi_amfaturamento`), conta (`cnta_amreferenciaconta`), contabilidade (`cnta_amreferenciacontabil`), pagamento (`pgmt_amreferenciapagamento`) e arrecadação (`pgmt_amreferenciaarrecadacao`).
- **Papel no sistema**: chave temporal dos processos, comparações financeiras e resumos; o banco possui funções utilitárias próprias (`anomesref`, `admindb.fc_calcula_ano_mes`).
- **Observações de modernização**: preservar a semântica AAAAMM na migração e nos comparativos; se o SISAN adotar tipos mais expressivos internamente, o mapeamento é trivial, mas deve ser explícito.

---

## Relações principais do domínio

Mapa textual construído a partir das evidências acima (não é o mapa de domínio definitivo — item 3 do backlog):

```text
Gerência Regional / Unidade de Negócio
        └── Localidade ── Setor Comercial ─┬── Quadra (bairro, recortes operacionais)
                                           │      └── Imóveis (lote/sublote, sequencial na rota)
                                           └── Rota ── Grupo de Faturamento (cronograma AAAAMM)
                                                 └── Leiturista / empresas (leitura, entrega, cobrança)

Cliente ══ ClienteImovel (Proprietário/Usuário/Responsável, com período) ══ Imóvel
Imóvel ──1:1── Ligação de Água ── Instalação de Hidrômetro ── Hidrômetro
Imóvel ──1:1── Ligação de Esgoto          (situações de ambas armazenadas no Imóvel)
Imóvel ── Economias por Categoria/Subcategoria

Leitura (por referência) → Consumo (real | média | mínimo | rateio condomínio)
Consumo + Tarifa (por categoria/economias) → CONTA (água + esgoto + débitos − créditos + impostos)
DébitoACobrar ──┐ (prestações incluídas como DébitoCobrado)
CréditoARealizar ┴─→ incluídos na Conta (CreditoRealizado)
Conta ── clientes da emissão (cliente_conta) ── versões (conta_geral / conta_historico)

Conta vencida → COBRANÇA (ações por grupo/critério → documento, OS de corte, negativação SPC/Serasa)
COBRANÇA → PARCELAMENTO (consolida dívida → gera prestações, descontos, guia de entrada;
                          pode ser desfeito; contas ficam INCLUÍDAS)

Conta | Guia | DébitoACobrar | Fatura | DocumentoCobrança → PAGAMENTO
PAGAMENTO ← ArrecadadorMovimento (bancos, lotéricas, débito automático, PIX)
PAGAMENTO ── AvisoBancario (conciliação) ── Devolução / excedente

Cliente ou cidadão → RA (tipificada, tramita entre unidades) → OS (ServicoTipo, prioridade)
OS → execução em campo (mobile) → encerramento → pode atualizar situação das Ligações
OS/RA → podem gerar Débito, Crédito, Guia, Parcelamento
```

## Pontos que exigem aprofundamento

1. ~~Economia: qual representação comanda o cálculo tarifário?~~ **Resolvida (2026-08-14)**: a agregação por subcategoria (`imovel_subcategoria`) governa — `ControladorImovel.obterQuantidadeEconomias*` consulta `ImovelSubcategoria`; `imovel_economia` é informativa (só relatórios); `conta_categoria` fotografa na emissão. Ver [modulos/cadastro.md §3.4](../modulos/cadastro.md). Permanece aberta apenas a obrigatoriedade de `imovel_economia` por instalação (requer dados).
2. ~~Ligações: regra fotografia × estado corrente~~ **Resolvida (2026-08-14)**: identidade compartilhada é intencional, por construção (`ligacaoAgua.setId(imovel.getId())`); o estado corrente vive no imóvel e a Conta congela situação + `cnta_pcesgoto`/`cnta_pccoleta` na emissão para auditoria/recálculo (Parcelamento idem, no ato da negociação). A situação é **paramétrica** (`ligacao_agua_situacao`: flags de faturamento, consumo mínimo etc.). Ver [modulos/cadastro.md §3.6](../modulos/cadastro.md).
3. **Constante ambígua em situação de ligação de água** — `LIGADO_A_REVELIA = 4` e `LIGADO_EM_ANALISE = 4` no mesmo arquivo; verificar qual semântica vale por companhia/configuração.
4. **Mecanismo `*_geral`/`*_historico`** (conta, guia, débito a cobrar, crédito) — id "geral" estável entre versões do documento; é a espinha de retificações e do vínculo de pagamento; precisa de caracterização dedicada (impacto direto na migração).
5. **"Fatura" (`faturamento.fatura`)** como quinto alvo de pagamento — aparenta ser agrupamento de contas (ex.: cliente responsável); semântica exata a confirmar.
6. ~~Multiplicidade de rotas no imóvel~~ **Resolvida no essencial (2026-08-14)**: rota via quadra = processos territoriais/de campo (ordens de corte/fiscalização, atualização cadastral); rota de entrega = entrega de contas/2ª via; rota alternativa = leitura/faturamento com dispositivo móvel (exceções de leitura, impressão simultânea). Ver [modulos/cadastro.md §3.8](../modulos/cadastro.md). Precedência fina no processo de leitura fica para o mapa da Micromedição.
7. **RA sem imóvel** (por endereço/local de ocorrência) — dimensionar o quanto do fluxo de atendimento independe de matrícula (afeta o modelo do SISAN).
8. **Nomenclaturas de companhia no núcleo** — parcialmente mapeada no cadastro (2026-08-14): `numeroCelpe`, DV específico CAERN (`Util.obterDigitoVerificadorModuloCAERN`), campos sociais (`imov_classe_social`, `imov_qtd_economias_social`), programas especiais e recadastramento. Consolidar a separação núcleo × extensão na análise de compatibilidade ([modulos/cadastro.md §8](../modulos/cadastro.md)).
9. **Regra do valor de esgoto** (percentual sobre consumo de água conforme situação/tipo) — localizar e caracterizar no módulo faturamento.
