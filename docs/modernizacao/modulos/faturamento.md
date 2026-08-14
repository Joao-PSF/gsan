# Módulo Faturamento — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Fontes: código GSAN (`gcom.faturamento`, fronteiras em `gcom.micromedicao`), mapeamentos, constantes, DDL; `gsan_comercial` como evidência complementar. Pré-requisitos: [cadastro](cadastro.md), [micromedicao](micromedicao.md), [glossário](../dominio/glossario.md).

## 1. Responsabilidade

O Faturamento transforma o estado do cadastro (imóvel, economias, categorias, situações das ligações) e o consumo apurado pela Micromedição em **documentos de cobrança mensais (Contas)**: decide quem é faturável, valora água e esgoto pela estrutura tarifária vigente, agrega débitos, créditos e impostos, emite a conta com vencimento e mantém o ciclo de vida do documento (retificação, cancelamento, histórico) preservando a trilha de auditoria financeira.

## 2. Principais capacidades

Faturar grupo (lote por rota do cronograma) e imóvel individual; pré-faturar; determinar faturabilidade por situação; valorar água/esgoto por tarifa vigente (categorias, economias, faixas, mínimos); incorporar débitos a cobrar e créditos a realizar; calcular impostos deduzidos; emitir/imprimir contas (inclusive 2ª via) com vencimento por cronograma; reter/revisar contas; retificar; cancelar (inclusive prescrição); manter histórico mensal encerrado; emitir guias; manter a estrutura tarifária e parâmetros.

## 3. Ciclo mensal de faturamento

O trem mensal do grupo (micromedicao.md §3.10) culmina no **FATURAR_GRUPO(5)**:

- **Disparo**: cronograma do grupo na referência — `FaturamentoAtividadeCronograma` + **`FaturamentoAtivCronRota`** (datas por rota). O batch (deployment próprio `descriptors/batchFaturarGrupoFaturamento`) chama `ControladorFaturamentoFINAL.faturarGrupoFaturamento(colecaoFaturamentoAtividadeCronogramaRota, ...)` — **a unidade de processamento é a rota**.
- **Grupo de Faturamento**: agrupa rotas → imóveis; carrega a referência corrente (`ftgr_amreferencia`) e o vencimento base. Grupo × referência × rota × cronograma formam o eixo do lote.
- **Pré-faturamento**: `preFaturarGrupoFaturamento(Rota, anoMes, idGrupo...)` gera contas em situação `PRE_FATURADA(9)` (impressão simultânea/antecipação), consolidadas no faturamento definitivo.
- **Nem todo imóvel do grupo é faturado**: exclusões por faturabilidade (§4), paralisações, retenção/revisão (`ContaMotivoRevisao`), inclusão em parcelamento, e regras por situação especial.
- **Individual × lote**: o lote itera imóveis da rota e invoca a mesma lógica central de **`gerarConta(Imovel, anoMesFaturamento, SistemaParametro, ...)`** (linha 53545) usada ponto a ponto — com apoio de `gerarContaCategoria*` e helpers. Existe também fluxo GUI de faturamento imediato/ajuste (`FaturamentoImediatoAjuste*`). **Mesmo cálculo no individual e no lote — candidato ideal a golden master (§31)**.

## 4. Determinação de faturabilidade

A decisão final é do Faturamento, em cima de dados paramétricos do Cadastro:

- **`permiteFaturamentoParaAgua(LigacaoAguaSituacao, consumoAgua, ...)`** e **`permiteFaturamentoParaEsgoto(...)`** (`ControladorFaturamentoFINAL:1957/2019`): combinam os flags da situação (`last_icfaturamento`, `last_icconsumoreal` — "só fatura com consumo real") com a existência/origem do consumo.
- **Situação especial de faturamento do imóvel** (`FaturamentoSituacaoTipo`): PARALISAR_EMISSAO_CONTAS(1), PARALISAR_LEITURA_FATURAR_MEDIA(2), PARALISAR_LEITURA_FATURAR_TAXA_MINIMA(3) — paralisações e modos alternativos.
- Cortado/suprimido: faturável ou não conforme os flags da própria situação (parametrizado, não hard-coded); sem hidrômetro: fatura por mínimo/estimado (§6).
- Distinção de conceitos: situação da **ligação** (estado físico-comercial), situação **de faturamento** do imóvel (modo do ciclo), situação **da Conta** (`DebitoCreditoSituacao` — estado do documento) — três eixos independentes que não devem ser confundidos.

## 5. Consumo utilizado (resolve dúvida da Micromedição)

**O Faturamento não regrava consumo — ele consome o consumo determinado pela Micromedição.** Evidências: `faturarGrupoFaturamento` obtém `ConsumoHistorico` de água e esgoto via `getControladorMicromedicao().obterConsumoHistoricoMedicaoIndividualizada(imovel, ligacaoTipo, anoMesFaturamento)` (linhas 1441–1453); não há `inserirConsumoHistorico`/`atualizarConsumoHistorico` em `ControladorFaturamentoFINAL` (grep vazio). O valor monetizado é o **`cshi_nnconsumofaturadomes`** com sua **origem** (`ConsumoTipo`: real/média/mínimo/fixado) e anormalidade. Alterações posteriores de consumo (retificação/revisão) passam de novo pela Micromedição (ajuste com versões preservadas em `consumo_hist_anterior`).

## 6. Consumo mínimo (precedência — núcleo resolvido)

- **Quem calcula**: a Micromedição, a serviço do Faturamento — `ControladorMicromedicao.obterConsumoMinimoLigacao(imovel, colecaoCategorias)` (linha 6353), chamado pelo Faturamento (`ControladorFaturamentoFINAL:7290, 52840, 60699`).
- **Fórmula base** (evidência no próprio método, ref. UC0108): obter a **vigência tarifária mais recente da tarifa do imóvel** → para cada categoria do imóvel, **mínimo da tarifa da categoria × quantidade de economias da categoria**, acumulando → consumo mínimo da ligação.
- **Sobreposições existentes** (ordem fina ainda a confirmar em caracterização): mínimo informado na própria ligação (`lagu_nnconsumominimoagua`), mínimo da situação da ligação (`last_nnconsumominimo`), parametrizações por área (`consumo_minimo_parametro`, `consumo_minimo_area` — manutenção via `informarConsumoMinimoParametro`).

```text
consumo apurado (real/média)
   ↓ comparado com
mínimo = Σ por categoria (mínimo da tarifa vigente × economias)   [com overrides ligação/situação/área]
   ↓
consumo considerado = maior/aplicável conforme situação e flags (ex.: "só consumo real" ignora mínimo)
```

## 7. Categoria, Subcategoria e Economias

- A classificação tarifária é **das economias** (cadastro.md §3.5): o cálculo consulta `obterQuantidadeEconomiasCategoria(imovel)` (agregação de `imovel_subcategoria`).
- **Imóvel com múltiplas categorias é faturado por categoria**: `gerarContaCategoria`, `gerarContaCategoriaPorCategoria`, `gerarContaCategoriaPorSubcategoria` e `gerarContaCategoriaValoresZerados` (linhas 53835–54175) produzem `conta_categoria` — consumo e valores **distribuídos por categoria** proporcionalmente às economias, com mínimos por categoria (mínimo × qtd economias, como em §6).
- Faixas progressivas aplicam-se dentro da categoria sobre o consumo atribuído a ela; a granularidade exata da divisão por economia (franquia individual × agregada por categoria) tem variação por companhia (ex.: `calcularValorFaturadoFaixaCAER(consumoFaturado, valorTarifaMinimaCategoria, ...)`) — **ponto marcado para caracterização numérica** (§31), não para suposição.
- A Conta fotografa tudo em `conta_categoria`: economias, consumo/valor de água e esgoto, tarifa e consumo mínimos por categoria (`ctcg_*`).

## 8. Estrutura tarifária

```text
ConsumoTarifa (tabela tarifária; atribuída ao imóvel — imov.cstf_id; default por localidade)
  └── ConsumoTarifaVigencia (cstv_dtvigencia — versões datadas da tarifa)
        ├── ConsumoTarifaCategoria (por categoria: consumo mínimo + valor da tarifa mínima)
        └── ConsumoTarifaFaixa (faixas: consumo início/fim + valor por m³)
```

- **Vigência**: a válida para a referência é a de **maior data de vigência ≤ data de referência** (`pesquisarMaiorDataVigenciaConsumoTarifaImovel`, `obterConsumoTarifaVigencia:5894`). Alteração tarifária cria nova vigência; **referências anteriores não são afetadas** porque a Conta fotografa a tarifa usada (`cnta.cstf_id` + valores em `conta_categoria`).
- Estruturas tarifárias diferentes coexistem (várias `ConsumoTarifa` — por localidade/perfil; extensões sociais como tarifa social/Bolsa Água usam tarifas/créditos próprios — customização).

## 9. Cálculo de água (confirmado, em etapas)

```text
consumo faturado (Micromedição, com origem)
  → distribuição por categoria (proporção de economias)          [gerarContaCategoria*]
  → por categoria: mínimo (tarifa mínima × economias)            [ConsumoTarifaCategoria]
     + faixas progressivas sobre o consumo excedente             [ConsumoTarifaFaixa: início/fim, R$/m³]
  → soma das categorias = valor de água da conta                 [cnta_vlagua]
```

Elementos confirmados: tarifa mínima (valor fixo por economia/categoria), faixas progressivas com valor por m³, rateio de consumo em condomínio (micromedição), variantes de cálculo por companhia. Casos especiais tratados por situação/paralisação (média, taxa mínima) e por perfil (grandes consumidores monitorados por `identificarGrandesConsumidores` com limites × economias por localidade).

## 10. Cálculo de esgoto (resolve dúvida do Cadastro)

- **Volume**: derivado do consumo de água (e de poço/fonte própria — medição tipo POÇO compõe o volume de esgoto; `calculoConsumoLigacaoEsgoto` na Micromedição). A linha de consumo de esgoto existe separadamente no histórico (`LigacaoTipo.LIGACAO_ESGOTO`).
- **Percentuais definidos na Ligação de Esgoto** (por imóvel): `lesg_pcesgoto` (**percentual de esgoto** — fração do volume tarifada), `lesg_pccoleta` (**percentual de água consumida coletada**), e **percentual alternativo acima de um limite de consumo** (`lesg_pcalternativo` + `lesg_nnconsumopcalternativo`) — degrau por faixa de consumo.
- **Valor**: tarifação do volume de esgoto (mesma mecânica de categorias/faixas/mínimos — `conta_categoria` tem colunas próprias de esgoto) ajustada pelo percentual.
- **Fotografia na Conta**: `cnta_pcesgoto` e `cnta_pccoleta` são copiados na emissão (`contaInserir.setPercentualEsgoto(...)`, linha 7785) — motivo: o percentual do imóvel pode mudar depois; a conta precisa reproduzir o cálculo original (auditoria/recálculo/2ª via).

## 11. Débitos e créditos na Conta

- **Débito a Cobrar** (prestações pendentes) vira **`DebitoCobrado`** dentro da conta; **Crédito a Realizar** vira **`CreditoRealizado`** (abate o total). Ambos guardam a prestação cobrada/realizada e mantêm vínculo com a origem (serviço/OS/parcelamento/lançamento).
- **Impostos deduzidos**: `conta_impostos_deduzidos` (com histórico próprio) — retenções por tipo de cliente (ex.: público federal).
- Composição do valor final: `cnta_vlagua + cnta_vlesgoto + cnta_vldebitos − cnta_vlcreditos − impostos` (débitos/créditos são **itens associados** à conta, não campos soltos — as somas ficam na conta).
- Guia de Pagamento continua sendo o caminho avulso (fora da conta mensal).

## 12. Conta (anatomia)

| Grupo | Conteúdo |
| ----- | -------- |
| Identidade | `cnta_id` (herdado da ContaGeral), imóvel, **referência AAAAMM** (`cnta_amreferenciaconta`), referência contábil (`cnta_amreferenciacontabil`) |
| Dados de cálculo | consumo(s) da referência, tarifa (`cstf_id`), grupo de faturamento, dia/regra de vencimento |
| Fotografias | situações das ligações (`last_id`/`lest_id`), percentuais de esgoto/coleta, clientes (`cliente_conta`), categorias/economias/mínimos (`conta_categoria`), quadra/perfil/tarifa |
| Resultados financeiros | `cnta_vlagua`, `cnta_vlesgoto`, `cnta_vldebitos`, `cnta_vlcreditos`, impostos, itens (débitos cobrados, créditos realizados) |
| Estado do documento | `DebitoCreditoSituacao` atual/anterior (NORMAL=0, RETIFICADA=1, INCLUIDA=2, CANCELADA=3, CANCELADA_POR_RETIFICACAO=4, DEBITO_PRESCRITO=8, PRE_FATURADA=9), motivos (retificação/cancelamento/revisão/inclusão), vencimento, débito automático |

## 13. ContaGeral e histórico (resolve dúvida do glossário)

- **`ContaGeral` é entidade física** (`faturamento.conta_geral`): **fonte da identidade** (`cnta_id` de `seq_conta_geral`) + `indicadorHistorico` + one-to-one com `Conta` (corrente), `ContaHistorico` (arquivada) e `ContaImpressao` — todas compartilham o mesmo id (Conta usa generator `assigned`).
- **Problema de negócio que resolve**: referências externas (pagamento, cobrança, parcelamento, relatórios) precisam de um **id estável que sobreviva ao arquivamento e à retificação** — `Pagamento.cnta_id → ContaGeral` funciona igual antes e depois de a conta ir a histórico.
- **Quando vai a histórico**: no **encerramento mensal** — batches `batchGerarHistoricoConta` e `batchGerarHistoricoParaEncerrarFaturamentoMes` (e o par de arrecadação) movem `conta` → `conta_historico` (com satélites: `conta_categoria_historico`, impostos etc.) e marcam `indicadorHistorico`. O mesmo padrão vale para guia, débito e crédito (`*_geral`).
- O histórico **participa de consultas e regras** (helpers de relatório específicos, 2ª via, reconstrução do faturamento original) — não é só armazenamento morto.

## 14. Retificação

- **Cria uma nova Conta** (novo id de `seq_conta_geral`): o serviço dedicado `ControladorRetificarConta.retificarConta(...)` **retorna o id da nova conta** (chamadas em `RetificarContaAction:630` e `ControladorRegistroAtendimentoSEJB:15294`).
- A nova conta aponta a origem (`cnta_idorigem → ContaGeral` da original), formando **cadeia de versões**; a original muda de situação (RETIFICADA=1 / CANCELADA_POR_RETIFICACAO=4, com `ContaMotivoRetificacao`) e segue para histórico no encerramento.
- O cálculo é refeito com os dados retificados (consumo, categorias/economias, vencimento, itens) — retificáveis conforme a tela/serviço; débitos/créditos adicionais podem surgir da diferença; **pagamentos permanecem ligados à conta original** via ContaGeral (diferenças viram crédito/débito — há inclusive retificação automática por diferença de pagamento, `retificarContaPagamentosDiferenca2Reais`).
- Existem variações em massa (retificar conjunto de contas) e retificação disparada pelo atendimento (RA).

## 15. Cancelamento

- **Transição de estado, nunca exclusão**: `cancelarConta(colecaoContas, motivo, ...)` (linha 8447) grava `ContaMotivoCancelamento`, move situação atual→anterior e define **CANCELADA(3)** — ou **DEBITO_PRESCRITO(8)** quando o motivo é prescrição.
- A conta permanece consultável e vai a histórico no encerramento; não há "restauração" formal (nova conta seria emitida se necessário).
- Interfaces registradas (aprofundar nos módulos donos): cobrança deixa de considerar o débito; conta cancelada **paga** gera tratamento na arrecadação (crédito/devolução/transferência); parcelamento que incluiu a conta tem regras próprias.

## 16. Referência e vencimento

- **Referência AAAAMM = competência do ciclo comercial** (mês do consumo faturado), distinta da data de emissão; a **referência contábil** (`cnta_amreferenciacontabil`) pode diferir (fechamento contábil após encerramento do mês). Leitura/consumo/conta compartilham a referência do grupo; pagamento tem referências próprias (pagamento/arrecadação).
- **Vencimento**: `determinarVencimentoConta(Imovel, FaturamentoAtivCronRota, ...)` (linha 3484) — parte do cronograma da rota/grupo (dia de vencimento do grupo, `ftgr_icvencimentomesfatura`) ajustado pelas preferências do imóvel (`imov_ddvencimento` — dia escolhido pelo cliente; `imov_icvencimentomesseguinte`). Pode ser **alterado sem refaturar** (`alterarVencimentoConta`, linha 9239).

## 17. Situações de faturamento

Quatro planos independentes (não confundir): situação da **ligação** (água/esgoto — paramétrica, no imóvel); situação **derivada do imóvel** (ativo/inativo/só esgoto); **situação especial de faturamento** do imóvel (`FaturamentoSituacaoTipo` — normal/paralisações/média/taxa mínima); situação **da Conta** (`DebitoCreditoSituacao` — ciclo de vida do documento). O faturamento lê os três primeiros e escreve o quarto.

## 18. Faturamento individual

`gerarConta(Imovel, anoMesFaturamento, SistemaParametro, ...)` é o **método central reutilizável** — o lote o invoca imóvel a imóvel. Com um imóvel montado (cadastro + consumo da referência + tarifa vigente), produz uma Conta determinística. **Forte candidato ao primeiro golden master financeiro** (entrada pequena → conta comparável ao centavo). O fluxo GUI `FaturamentoImediatoAjuste` confirma a viabilidade de faturar individualmente fora do lote.

## 19. Faturamento em lote (fronteira com Batch)

Deployment EJB dedicado (`descriptors/batchFaturarGrupoFaturamento`); orquestração em `ControladorBatchFaturamento`/framework batch próprio; **unidade de processamento = rota** do cronograma (`faturarGrupoFaturamento(colecaoFaturamentoAtividadeCronogramaRota, ...)`); o registro de execução/falha usa as tabelas do schema `batch` (funcionalidade iniciada/unidades). Commits parciais, paralelismo e reprocesso serão detalhados no mapa do Batch — aqui fica a fronteira: o lote repete o cálculo individual por imóvel dentro de cada rota.

## 20. Variações por companhia

Mesmo padrão da Micromedição, mais intenso:

| Tipo | Evidência | Classificação |
| ---- | --------- | ------------- |
| Subclasses de controlador | `ControladorFaturamentoCAEMA/CAERN/CAER/COMPESA/COSAMA/COSANPA/JUAZEIRO SEJB` sobre `ControladorFaturamentoFINAL` | CUSTOMIZAÇÃO DE COMPANHIA |
| Métodos específicos no núcleo | `calcularValorFaturadoFaixaCAER*` dentro do FINAL | CUSTOMIZAÇÃO no núcleo (dívida) |
| Validadores | `validator-compesa.xml` | CUSTOMIZAÇÃO |
| Tarifas, vigências, faixas, mínimos, situações, anormalidades, cronogramas | tabelas | EXTENSÃO PARAMÉTRICA |
| Ciclo por grupo/rota, mecanismo de conta/versões, fotografias | núcleo estável | REGRA GERAL DO GSAN |

Para o SISAN: a variação de cálculo por companhia precisa virar **ponto de extensão explícito** (a herança de EJB inteiro é o anti-padrão a evitar) — hipótese em §30.

## 21. Parametrização das regras

| Regra | Onde está |
| ----- | --------- |
| Tarifa (mínimos, faixas, vigências) | Parametrizada (`consumo_tarifa*`) |
| Faturabilidade por situação de ligação | Parametrizada (`ligacao_agua_situacao` flags) |
| Modo de faturamento do imóvel (média/taxa mínima/paralisar) | Parametrizada (`faturamento_situacao_tipo`) |
| Anormalidades e suas ações | Parametrizadas (leitura/consumo + ações) |
| Consumo mínimo (área/parâmetro) | Parametrizada (`consumo_minimo_*`) |
| Calendário do ciclo | Parametrizado (cronogramas por grupo/rota) |
| Percentuais de esgoto | Dado por imóvel (ligação de esgoto) |
| Fórmula de faixas/distribuição por economia | **Código** (com variantes por companhia) |
| Retificação/cancelamento (fluxo) | **Código** |
| Impostos/retenções | Misto (tabelas + código) |

## 22. Relação com Cadastro

Recebe: imóvel (matrícula, perfil, vencimento preferido, débito automático), economias por categoria/subcategoria, situações das ligações (+flags), situação especial de faturamento, tarifa atribuída, clientes da relação vigente, grupo (via rota), percentuais de esgoto (ligação). Devolve: fotografias na conta e situação de cobrança/pendências indiretas. Não altera cadastro (exceto marcações de faturamento).

## 23. Relação com Micromedição (fronteira definida)

```text
Micromedição                                         Faturamento
── determina e GRAVA consumo (origem tipificada) ──▶ lê consumo faturado + origem + anormalidade
── calcula consumo mínimo da ligação (tarifa×econ.)─▶ solicita via obterConsumoMinimoLigacao
── mantém médias e histórico ──────────────────────▶ usa média quando o modo exige
                                                     decide FATURABILIDADE (permiteFaturamento*)
                                                     valora (tarifa) e emite a Conta
retificação/ajuste de consumo volta para a Micromedição (versões preservadas)
```

## 24. Relação com Cobrança (fronteira)

Conta vencida e não paga em situação normal é o insumo da cobrança; cobrança referencia a identidade **ContaGeral** (sobrevive a arquivamento); situação da conta comanda elegibilidade (cancelada/retificada/incluída saem do estoque de débito); parcelamento muda a situação das contas para INCLUIDA(2) e gera novos itens de faturamento (débitos/créditos). Detalhes no mapa da Cobrança.

## 25. Relação com Arrecadação (fronteira)

`Pagamento.cnta_id → ContaGeral` — o pagamento aponta a **identidade estável**, não a versão; por isso permanece válido após retificação/arquivamento. Pagamento de conta retificada/cancelada gera tratamento (diferença→crédito/devolução; inclusive retificação automática por diferença pequena). Detalhes no mapa da Arrecadação.

## 26. Relação com Fiscal (evolução — `gsan_comercial`)

A instalação analisada acopla o faturamento a NF/tributação: schema `fiscal` (nota_fiscal_*, certificado), `conta_impostos_deduzidos`, integração SPED (`integracao.sped_documento`, `ti_*`) e funções `sp*_gerar_conta_rec_ctb` (contabilização). Para o SISAN: registrar no catálogo de funcionalidades futuras; a conta emitida é a fonte dos documentos fiscais — não copiar o schema.

## 27. Precisão financeira

- **`BigDecimal` com arredondamento HALF_UP centralizado em `gcom.util.Util`**: `arredondar(BigDecimal)` = `setScale(0, ROUND_HALF_UP)` (consumo em m³ inteiro, linha 653–654); divisões monetárias com escala 2 (linhas 3110/3141) e intermediárias com escalas 4 e 7 (682, 1668); conversões via `formatarMoedaRealparaBigDecimal`.
- Valores monetários nas tabelas com `numeric(13,2)`-equivalente (length 13 nos mapeamentos, escala 2).
- **O momento do arredondamento (por faixa, por categoria, no total) é regra de resultado** — deve ser capturado pelos golden masters, não reimplementado "matematicamente melhor" no SISAN.

## 28. Regras estruturantes do Faturamento

1. **Identidade estável de documento**: toda referência externa aponta ContaGeral; versões (corrente/histórica) compartilham o id; retificação cria nova identidade encadeada pela origem.
2. **Fotografia completa na emissão** (tarifa, categorias/economias/mínimos, situações, percentuais, clientes) — a conta é reproduzível para sempre, independente do estado atual do cadastro.
3. **Mesmo cálculo no individual e no lote** (`gerarConta` único) — propriedade que viabiliza caracterização e migração por comparação.
4. **Faturabilidade é decisão do Faturamento sobre flags paramétricos** do Cadastro/Micromedição.
5. **Consumo é insumo, nunca é regravado pelo Faturamento** — a fronteira com a Micromedição é limpa.
6. **Tarifa é versionada por vigência** e selecionada por referência; mudanças tarifárias nunca reprocessam o passado.
7. **Mínimos são função de tarifa × economias por categoria** (com overrides paramétricos).
8. **Cancelar/retificar nunca apaga** — transições de estado com motivo + arquivamento no encerramento mensal.
9. **Encerramento mensal** é um marco duro: move documentos a histórico e fecha a competência (referência contábil).
10. **Variação por companhia existe em três camadas** (parâmetro, subclasse, método no núcleo) — o SISAN precisa reduzi-la a parâmetro + ponto de extensão.

## 29. Compatibilidade GSAN → SISAN

| Conceito | Classificação | Motivo |
| -------- | ------------- | ------ |
| Conta por imóvel+referência com fotografia completa | PRESERVAR CONCEITO | Coração financeiro; auditoria e migração |
| Identidade estável (semântica da ContaGeral) + versões corrente/histórica | PRESERVAR CONCEITO | Pagamentos/cobrança dependem; **a semântica é obrigatória mesmo que a implementação futura mude** |
| Cadeia de retificação (nova conta + origem + motivo) | PRESERVAR CONCEITO | Trilha financeira |
| Cancelamento como estado com motivo | PRESERVAR CONCEITO | Nada se apaga |
| Estrutura tarifária vigência→categoria→faixas/mínimos | PRESERVAR CONCEITO | Modelo paramétrico provado |
| Consumo com origem como insumo (fronteira com Micromedição) | PRESERVAR CONCEITO | Separação de responsabilidades correta |
| Referência AAAAMM + referência contábil distinta | PRESERVAR CONCEITO | Competência financeira |
| Precisão/arredondamento HALF_UP nos momentos atuais | PRESERVAR CONCEITO | Resultados ao centavo |
| Encerramento mensal como marco | PRESERVAR CONCEITO | Fecha competência; migração respeita |
| Implementação física conta/conta_historico duplicada | POSSÍVEL MODERNIZAÇÃO | Semântica mantida; forma (duas tabelas espelho) pode evoluir |
| Fórmula de faixas por economia/companhia | EXIGE APROFUNDAMENTO | Capturar por caracterização antes de qualquer generalização |
| Ordem fina dos overrides de mínimo | EXIGE APROFUNDAMENTO | Confirmar em caracterização |
| Variação por companhia (subclasses/métodos no núcleo) | EXIGE APROFUNDAMENTO | Inventariar diferenças reais antes de modelar extensão |

## 30. Hipóteses para avaliação futura (não são decisões)

1. **Entidade lógica "Conta" com versionamento explícito** (identidade + versões + estado), preservando a semântica ContaGeral sem as tabelas-espelho.
2. **Motor tarifário isolado e testável** (entrada: consumo+categorias/economias+vigência; saída: memória de cálculo), com golden masters do legado como contrato.
3. **Política por companhia como estratégia configurável** (substituindo herança de controladores e métodos `*CAER` no núcleo).
4. **Snapshot estruturado do contexto de cálculo** (fotografia atual espalhada em colunas → documento de contexto versionado), mantendo equivalência campo a campo para migração.
5. **Separação explícita cálculo → emissão → distribuição** (hoje entrelaçados no fluxo do grupo).

## 31. Cenários críticos para golden masters (financeiros)

1. Residencial simples, 1 economia, leitura normal (caso base ao centavo).
2. Múltiplas economias na mesma categoria.
3. Múltiplas categorias no mesmo imóvel (distribuição + mínimos por categoria).
4. Conta por média (paralisação/situação) e por taxa mínima.
5. Consumo mínimo com override (ligação e situação) × mínimo tarifário.
6. Esgoto: percentual padrão, percentual alternativo acima do limite, e poço compondo volume.
7. Conta com débitos cobrados (parcela de serviço/parcelamento) e créditos realizados.
8. Impostos deduzidos (cliente público).
9. Retificação: mesma referência antes/depois (cadeia origem, situações, valores).
10. Cancelamento (inclusive prescrição) e efeito sobre estoque de débito.
11. Pré-faturada → consolidada (impressão simultânea).
12. Vencimento: dia escolhido pelo imóvel × cronograma do grupo × mês seguinte.
13. Virada de referência: conta emitida após encerramento (referência contábil ≠ referência).

## 32. Dúvidas que permanecem

1. Ordem fina de precedência entre overrides de consumo mínimo (ligação × situação × área × tarifa) — caracterizar.
2. Granularidade exata da aplicação de faixas (por economia individual × agregada por categoria) e suas variantes por companhia — caracterizar numericamente.
3. Fluxo interno completo do `ControladorRetificarConta` (localizado; corpo não lido integralmente) — leitura dirigida quando a caracterização de retificação for montada.
4. Regras de retenção/revisão de contas (`ContaMotivoRevisao`) e contas "retidas" (vistas no `gsan_comercial`) — mapear com Cobrança/operacional.
5. Débito automático (fluxo com arrecadação) — mapa da Arrecadação.
6. Diferenças reais entre as 7 subclasses de companhia do faturamento — inventário próprio.

## 33. Evidências principais

```text
Ciclo/lote:    faturarGrupoFaturamento (ControladorFaturamentoFINAL:1146, unidade=rota); preFaturarGrupoFaturamento:52323; descriptors/batchFaturarGrupoFaturamento; FaturamentoAtivCronRota
Individual:    gerarConta:53545; gerarContaCategoria*:53835–54175; FaturamentoImediatoAjuste* (GUI)
Faturabilidade: permiteFaturamentoParaAgua:1957 / ParaEsgoto:2019; FaturamentoSituacaoTipo (constantes)
Consumo:       obterConsumoHistoricoMedicaoIndividualizada chamado em 1441–1453; ausência de inserir/atualizarConsumoHistorico no FINAL
Mínimo:        ControladorMicromedicao.obterConsumoMinimoLigacao:6353 (Σ mínimo tarifa categoria × economias na vigência); chamadas 7290/52840/60699; consumo_minimo_parametro/area
Tarifa:        consumo_tarifa / consumo_tarifa_vigencia (cstv_dtvigencia) / consumo_tarifa_categoria (cstc_nnconsumominimo, cstc_vltarifaminima) / consumo_tarifa_faixa (ctfx_nncosumofaixainicio/fim, ctfx_vlconsumotarifa); obterConsumoTarifaVigencia:5894
Esgoto:        LigacaoEsgoto.hbm (lesg_pcesgoto, lesg_pccoleta, lesg_pcalternativo + lesg_nnconsumopcalternativo); setPercentualEsgoto:7785; Conta.hbm (cnta_pcesgoto, cnta_pccoleta)
Conta/versões: ContaGeral.hbm → conta_geral (cnta_id de seq_conta_geral, cntg_ichistorico, one-to-one Conta/ContaHistorico/ContaImpressao); Conta id assigned; Conta.origem [cnta_idorigem]
Retificação:   getControladorRetificarConta().retificarConta(...) retorna id da nova conta (RetificarContaAction:630; ControladorRegistroAtendimentoSEJB:15294); DebitoCreditoSituacao RETIFICADA/CANCELADA_POR_RETIFICACAO; retificarContaPagamentosDiferenca2Reais:14267
Cancelamento:  cancelarConta:8447 (motivo + situação CANCELADA/DEBITO_PRESCRITO; sem exclusão)
Histórico:     descriptors/batchGerarHistoricoConta, batchGerarHistoricoParaEncerrarFaturamentoMes/ArrecadacaoMes; ContaHistorico/ContaCategoriaHistorico/ContaImpostosDeduzidosHistorico
Vencimento:    determinarVencimentoConta:3484; alterarVencimentoConta:9239; imov_ddvencimento + imov_icvencimentomesseguinte + ftgr_nndiavencimento/icvencimentomesfatura
Precisão:      Util.arredondar:653 (setScale(0,HALF_UP)); divisões HALF_UP escalas 2/4/7 (629/682/1668/3110/3141)
Companhia:     ControladorFaturamento{CAEMA,CAERN,CAER,COMPESA,COSAMA,COSANPA,JUAZEIRO}SEJB; calcularValorFaturadoFaixaCAER:5723; validator-compesa.xml
Débitos/impostos: DebitoCobrado/CreditoRealizado.hbm; conta_impostos_deduzidos(+historico); grandes consumidores: identificarGrandesConsumidores:59186
```
