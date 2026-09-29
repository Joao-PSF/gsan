# Mapa Funcional — Financeiro / Contabilização

> **Fase 0 — revisão controlada de escopo (21ª execução, 2026-09-28).** Lacuna da Fase 0: o GSAN tem um módulo Financeiro que **não recebeu mapa funcional**. Este documento o mapeia — e responde à pergunta central: *o OpenGSAN precisa ter Contabilidade, ou precisa gerar fatos contábeis e entregá-los a quem tem?*
>
> Nenhum banco, tabela, API ou implementação é definido aqui.

---

## 1. Evidência e método

### 1.1 Marcas de evidência usadas neste documento

| Marca | Categoria |
| ----- | --------- |
| **[GSAN]** | COMPROVADO NO GSAN — código público (nível 1) ou banco público versionado (nível 2); o localizador é citado |
| **[REF]** | COMPROVADO EM FERRAMENTA DE REFERÊNCIA — fonte oficial externa |
| **[INF]** | INFERÊNCIA ARQUITETURAL |
| **[PROP]** | PROPOSTA OpenGSAN |
| **[DEC]** | DECISÃO OpenGSAN, tomada pelo responsável do projeto |
| **[PEND]** | PENDENTE |

### 1.2 Fontes

| Nível | Fonte | Uso |
| ----- | ----- | --- |
| 1 | **Código público** — `gcom.financeiro` (60 classes), `gcom.gui.financeiro` (13), controlador de ~17,5 mil linhas, 7 variantes por companhia | Base de todas as afirmações [GSAN] |
| 2 | **Catálogo de funcionalidades versionado** — `gsan-migracoes/comercial/scripts/20160118183244_popula_tabela_de_funcionalidades.sql` (o menu do GSAN é esse catálogo) | Menu de 2016 — módulo 12: **14 funcionalidades, 2 pontos de entrada** (`fncd_icpontoentrada = 1`), contados por script |
| 3–4 | **Wiki do GSAN** (`gsan.com.br`) | ⚠️ **Não consultada diretamente**: o host está **bloqueado pela política de rede desta sessão**. Duas páginas foram identificadas por mecanismo de busca (R0487 e integração contábil), sem acesso ao conteúdo integral — [PEND] |
| 2 | 🆕 **Dump versionado** `gsan-migracoes/comercial/scripts/20160118183224_dump.sql` | Tabela `financeiro.param_perdas_societarias` — parâmetros de "geração das **perdas societárias**" (§7.3); **nenhuma classe Java** do código público a usa |
| 3–4 | 🆕 **Documentação GSAN posterior** — informada pelo responsável do projeto (2026-09-29) | Registra **PECLD**, "Provisão de Perdas Societárias", contas em aberto marcadas com perdas estimadas e casos de uso posteriores de PECLD, parte deles associada a **bases específicas**. Por busca, localizada também a página *"Manter Parâmetros de Perdas Fiscais"*. ⚠️ Conteúdo **não lido diretamente** — host bloqueado |
| 5 | Inventário do `gsan_comercial` — schema `financeiro`, 27 tabelas | Consistência |

⚠️ **Contagem, não impressão**: todas as buscas negativas declaram escopo e comando (regra 3 de [`procedencia.md`](../procedencia.md)).

---

## 2. Responsabilidade

🔴 **O que o módulo faz no GSAN** [GSAN]: transforma os **fatos financeiros do saneamento** — faturamento, arrecadação, baixa de devedores duvidosos, avisos bancários — em **lançamentos contábeis de partida dobrada**, por **competência** e **localidade**, segundo uma **parametrização contábil mantida como dado**; produz **resumos** de contas a receber, receita e volumes não faturados; e **exporta** os lançamentos para o sistema contábil da companhia.

🔴 **O que o módulo não faz no GSAN** [GSAN — busca negativa em `gcom/financeiro` e `gcom/gui/financeiro`, `*.java`, padrões `balancete|livroRazao|razaoContabil|encerrar(Exercicio|Ano)Contabil|lancamentoManual`: **0 arquivos**]: não mantém **razão**, **balancete**, **encerramento de exercício** nem **lançamento manual**. Suas 13 classes de interface (9 ações, 4 formulários) só **disparam** a geração de lançamentos, resumos, um relatório e a exportação.

🔵 **Conclusão** [INF, sustentada pelas duas afirmações acima]: o GSAN é um **gerador subsidiário de fatos contábeis** — a contabilidade corporativa sempre esteve **fora** dele, no sistema que recebe a exportação.

---

## 3. A cadeia

```text
FATOS FINANCEIROS — donos: os módulos que os produzem
  Faturamento   → resumo de faturamento da competência       [GSAN: GERAR_RESUMO_FATURAMENTO, batch 1103]
  Arrecadação   → resumo de receita · avisos bancários
  (Contabiliz.) → baixa de devedores duvidosos
  (Contabiliz.) → volumes consumidos e não faturados
                         │
                         ▼
POLÍTICA CONTÁBIL — parametrização como dado
  (origem × tipo × item × item contábil × categoria [× tipo de recebimento])
          → conta débito · conta crédito · histórico débito · histórico crédito
                         │
                         ▼
LANÇAMENTOS CONTÁBEIS — por competência × localidade × origem
  cabeçalho (competência, origem, tipo, localidade) + linhas D/C por conta
                         │
                         ▼
EXPORTAÇÃO — arquivo para o sistema contábil da companhia
  formato base + formatos por companhia
```

🔴 **A fronteira que a cadeia revela** [GSAN]: o **resumo de faturamento** é produzido pelo **Faturamento** (tarefa `TarefaBatchGerarResumoFaturamentoAguaEsgoto`, funcionalidade `GERAR_RESUMO_FATURAMENTO = 1103`), embora a classe `ResumoFaturamento` esteja no pacote `financeiro`. O Financeiro **consome** o resumo em `gerarLancamentosContabeisFaturamento` (`ControladorFinanceiro:335`, funcionalidade `681`). 🔵 **O fato é do Faturamento; a contabilização é do Financeiro** — o pacote em que a classe mora não decide o dono.

---

## 4. Conceitos

| Conceito | O que é | Evidência |
| -------- | ------- | --------- |
| **Origem do lançamento** | 🟢 Quatro: **FATURAMENTO(1)**, **ARRECADACAO(2)**, **DEVEDORES_DUVIDOSOS(3)**, **AVISO_BANCARIO(4)** | [GSAN] `LancamentoOrigem` |
| **Tipo de lançamento** | ≥ 31 tipos hierárquicos (água, esgoto, financiamentos incluídos/cancelados CP/LP, receita bruta/líquida, refaturamento, parcelamentos, impostos deduzidos, guias…), com indicadores de **impressão**, **total** e **resumido** | [GSAN] `LancamentoTipo` |
| **Item de lançamento** | ≥ 30 itens (água, esgoto, juros, receita, IR, COFINS, CSLL, PIS/PASEP, duplicidade, valor que não confere…) | [GSAN] `LancamentoItem` |
| **Item contábil** | Classificação fina ligada ao item (ligações, acréscimos por impontualidade, religações e sanções, aferição de hidrômetros, extensões de rede, tarifas…) | [GSAN] `LancamentoItemContabil` |
| **Conta contábil** | Plano de contas **da companhia** refletido no GSAN: número, dígito, prefixo, nome, **terceiros**, **centro de custo** | [GSAN] `ContaContabil`, `GrupoContabil` |
| **Parâmetros contábeis** | 🔴 **Regra como dado**: para cada combinação de categoria, item contábil, item e tipo — e, na arrecadação, tipo de recebimento —, a **conta de débito**, a **de crédito** e os **históricos** | [GSAN] `FaturamentoContabilParametros` via `obterParametrosContabilFaturamento` (`RepositorioFinanceiroHBM:1008`); `obterParametrosContabilArrecadacao` (`:1116`); `DevedoresDuvidososContabilParametro` via `:2059` |
| **Lançamento contábil** | Cabeçalho: competência (`anoMes`), origem, tipo, localidade, tipo de recebimento | [GSAN] `LancamentoContabil` |
| **Item do lançamento** | Linha **D/C** (`indicadorDebitoCredito`), valor, conta, histórico, código de terceiro, data | [GSAN] `LancamentoContabilItem` |
| **Resumo de faturamento** | Valor por competência × localidade × gerência × unidade de negócio × categoria × tipo × item | [GSAN] `ResumoFaturamento` |
| **Resumo de receita** | Receita realizada por data × banco × arrecadador × conta bancária × conta contábil × localidade × categoria | [GSAN] `ResumoReceita` |
| **Contas a receber contábil** | Posição contábil a receber por competência, com a mesma dimensionalidade | [GSAN] `ContaAReceberContabil` |
| **Documentos a receber por faixa** | 🔴 **Envelhecimento** da carteira: quantidade e valor por **dias vencidos**, tipo de documento, perfil do imóvel, **esfera de poder**, categoria | [GSAN] `DocumentosAReceberResumo`, `FaixaDocumentosAReceber` |
| **Volumes consumidos não faturados** | Valor do consumo **já ocorrido e ainda não faturado** na competência — acréscimo de receita por competência | [GSAN] `ValorVolumesConsumidosNaoFaturado` |

---

## 5. Parametrização contábil — o ponto em que o GSAN acertou

🟢 [GSAN] O vínculo entre o fato comercial e a conta contábil **não está em código**: é **consulta a tabela de parâmetros** por origem, que devolve contas de débito e crédito e os históricos (`inserirLancamentoContabilItemFaturamento`, `ControladorFinanceiro:515`).

🔵 [INF] É o padrão **"regra como dado"** — o nº 1 do GSAN — aplicado à contabilidade: quando a companhia muda seu plano de contas, **muda dado, não código**. Classificação: **A — capacidade de domínio geral**, a **preservar**.

⚠️ [INF] Uma ressalva de representação: `LancamentoTipo` carrega indicadores de **impressão, total e resumo** — atributos do **relatório** do resumo — e as constantes de tipo e item estão **fixadas em código** (≥ 31 e ≥ 30). O conceito é geral (A); a forma mistura classificação contábil com apresentação e fixa a taxonomia em código (D).

---

## 6. Geração de lançamentos

| Operação | O que faz | Evidência |
| -------- | --------- | --------- |
| Lançamentos do **faturamento** | Lê o resumo de faturamento da competência e, para cada linha, aplica os parâmetros e grava cabeçalho e itens D/C | [GSAN] `gerarLancamentosContabeisFaturamento` (`:335`); batch `681` |
| Lançamentos da **arrecadação** | Idem, a partir dos resumos da arrecadação; os parâmetros consideram também o **tipo de recebimento** | [GSAN] `gerarLancamentoContabeisArrecadacao`; batch `700` |
| Lançamentos dos **avisos bancários** | Contabilização dos avisos da competência de arrecadação | [GSAN] `gerarLancamentosContabeisAvisosBancarios` |
| Lançamentos dos **devedores duvidosos** | Contabilização da baixa (§7) | [GSAN] `gerarLancamentosContabeisDevedoresDuvidosos`; batch `755` |
| **Regeração** | Remove os lançamentos de uma **competência × localidade × origem** para gerar de novo | [GSAN] `removerLancamentoContabil(anoMesReferenciaContabil, idLocalidade, idLancamentoOrigem)` |

🟢 [GSAN] **Toda geração é processamento em lote**, particionada por **localidade** (`pesquisarIdsLocalidadesParaGerarLancamentosContabeis*`) — o mesmo padrão de unidade de processamento do framework de batch.

🔵 [INF] A **regeração por remoção** — apagar e gerar de novo por competência, localidade e origem — é a forma que o GSAN encontrou para corrigir contabilização sem duplicar. É operação **difícil de corrigir se errar**: vira cenário crítico (§13).

---

## 7. Devedores duvidosos — o que o GSAN realmente faz

⚠️ **Não é o que o nome sugere à primeira leitura.** No **código público**, o mecanismo de devedores duvidosos **não estima uma provisão**: ele **baixa contabilmente** créditos que atendem a critérios, e depois reconhece a **recuperação** quando algum deles é pago. A provisão (PECLD) aparece em **evoluções posteriores** — §7.3.

### 7.1 O mecanismo [GSAN]

| Passo | Evidência |
| ----- | --------- |
| **Parâmetros por competência contábil**: valor a baixar, valor baixado, competência de arrecadação, data de processamento, **data de integração contábil** | `ParametrosDevedoresDuvidosos` |
| **Critérios**: por **situação de cobrança**, um **valor-limite** e um **número de meses** | `ParametrosDevedoresDuvidososItem` (`valorLimite`, `numeroMeses`, `CobrancaSituacao`) |
| **Marcação da conta**: a conta recebe a **competência da baixa contábil** | `Conta.referenciaBaixaContabil` / coluna `cnta_amreferenciabaixacontabil`; escrita por `atualizaContaAnoMesReferenciaContabil` (`RepositorioFinanceiroHBM:415–445`) |
| **Resumo** da baixa por gerência, localidade, categoria, tipo e item | `ResumoDevedoresDuvidosos`; `gerarResumoDevedoresDuvidosos`, `apagar…`, `atualizar…` |
| **Lançamentos** pela parametrização própria da origem | `DevedoresDuvidososContabilParametro` |
| **Recuperação**: a arrecadação acumula à parte os **pagamentos de contas já contabilizadas como perdas** | `RepositorioArrecadacaoHBM:7173+` — `acumularValorAgua_EsgotoPagamentosClassificadosNoMes_EfetuadosEmMesesAnterioresContaContabilizadasComoPerdas` |
| **Relatórios**: resumo de devedores duvidosos (wiki: *R0487*), contas baixadas contabilmente (TXT e somatório por faixa) | `consultarResumoDevedoresDuvidososRelatorio`; `gerarTXTContasBaixadasContabilmente` |

🔵 **Semântica** [INF, sustentada pelos passos acima]: **baixa contábil ≠ extinção da dívida**. A conta baixada **continua existindo** como documento comercial e **pode ser paga**; quando é, o pagamento entra num acumulador de **recuperação de perdas**.

### 7.2 🔴 Dois acoplamentos encontrados

| # | Acoplamento | Evidência | Classificação |
| - | ----------- | --------- | ------------- |
| 1 | **O Financeiro escreve na Conta**, entidade do Faturamento | [GSAN] `atualizaContaAnoMesReferenciaContabil` atualiza `faturamento.conta` | **D** — responsabilidade mal posicionada; mesmo padrão de fronteira que D-14 corrigiu na retificação |
| 2 | **A marca contábil serve de "dívida ativa" na Cobrança** | [GSAN] `RepositorioCobrancaHBM:341–343` — o parâmetro `indicadorDividaAtiva` da consulta de contas do imóvel filtra por `cnta_amreferenciabaixacontabil` | **D** — conceito sobrecarregado: **baixa contábil** e **dívida ativa** passam a ser o mesmo campo |

⚠️ [PEND] **Se "dívida ativa" e "baixa contábil" são o mesmo conceito na prática das companhias não está comprovado.** Dívida ativa é também categoria jurídica de cobrança; baixa contábil é decisão de política contábil. O GSAN as une num campo — o OpenGSAN **não deve unir sem decisão**.

### 7.3 PECLD — calibrado em 2026-09-29

| Plano de evidência | O que se sabe |
| ------------------ | ------------- |
| **Baseline público analisado** — código Java | 🟢 [GSAN — busca negativa em `src/gcom`, `*.java`, padrões `pecld\|provisao.*perda\|perdaEstimada\|perdas estimadas\|creditoLiquidacaoDuvidosa`: **0 arquivos**; `societari`: 1 arquivo, sem relação — `InsumoQuadroSocietario` no *stub* do webservice SPC] **Não foi encontrada implementação de cálculo de PECLD.** O que o código comprova é **baixa contábil + recuperação** (§7.1) |
| **Banco versionado** (nível 2) | 🟢 [GSAN] `financeiro.param_perdas_societarias`: competência contábil, faixa de referências das contas para baixa, meses para seleção de imóveis com contas anteriores **com baixa fiscal**, geração **real ou simulada**, filtros por categoria e esfera de poder — **estrutura sem código público correspondente** (`APENAS EVIDÊNCIA`) |
| **Documentação posterior / instalações** (nível 3–4) | [GSAN — documentação, informada pelo responsável; não lida diretamente] PECLD, "Provisão de Perdas Societárias", contas em aberto marcadas com perdas estimadas em créditos de liquidação duvidosa e casos de uso posteriores de PECLD — **parte associada a bases específicas** |

🔵 **Conclusão**: **PECLD é capacidade posterior comprovada documentalmente**, mas **não pode ser tratada como comportamento universal do GSAN público**.

🔴 **Três coisas que o OpenGSAN não funde**, mesmo que apareçam juntas sob "devedores duvidosos":

```text
BAIXA CONTÁBIL               ≠   PROVISÃO / PERDA ESPERADA (PECLD)   ≠   EXTINÇÃO COMERCIAL DA DÍVIDA
crédito sai do ativo pela        estimativa de perda sobre créditos       a obrigação deixa de existir
política; a conta continua       que continuam no ativo                   (pagamento, cancelamento,
devida e pode ser recuperada                                              prescrição — donos comerciais)
código público: 🟢               código público: não encontrado           Faturamento / Cobrança / Arrecadação
```

🟡 [INF — não comprovada] Os critérios **valor-limite × número de meses** da baixa são compatíveis com regras **fiscais** de dedutibilidade de perdas no recebimento de créditos; a existência de parâmetros de perdas **societárias** (com "baixa fiscal" no comentário da tabela) e de uma página de *"parâmetros de perdas fiscais"* sugere que o ecossistema GSAN distinguia **perda fiscal** de **perda societária**. A confirmar — e, em qualquer caso, **política da companhia**, não regra do sistema.

🔵 [PROP] **Classificação no OpenGSAN**: capacidade de **reconhecimento e estimativa de perdas esperadas em créditos**, pertencente à **Contabilização**. A política precisa poder variar por **companhia, norma, período, classificação da carteira e critérios contábeis ou regulatórios**. ⚠️ **Nenhuma fórmula é definida aqui** — ponto de aprofundamento posterior. O insumo que o GSAN já tem é o **envelhecimento da carteira** por dias vencidos (`DocumentosAReceberResumo`).

---

## 8. Integração contábil

### 8.1 O que existe [GSAN]

| Evidência | O que mostra |
| --------- | ------------ |
| `gerarIntegracaoContabilidade(idLancamentoOrigem, anoMes, data)` (`ControladorFinanceiro:5645`) | Formato **base**: arquivo texto delimitado por `;` (ano, conta, centro de custo, moeda, valor débito, valor crédito…) |
| Variantes `ControladorFinanceiro{CAEMA,CAERN,COSAMA,COSANPA}SEJB` | 🔴 **Sobrescrevem só a integração** — cada uma com **seu próprio layout** e compactação |
| Variantes `{CAER,COMPESA,JUAZEIRO}` | 17 a 19 linhas — **cascas vazias** |
| `gerarIntegracaoContabilidadeCaern` **na interface do núcleo** e tela `GerarIntegracaoContabilidadeCaernAction` | 🔴 **Nome de companhia no contrato do núcleo e na interface de usuário** |
| Catálogo de 2016: **duas** funcionalidades com o **mesmo nome genérico** *"Gerar Integração para a Contabilidade"*, ambas pontos de entrada — a `684` abre a tela genérica; a `752` abre `exibirGerarIntegracaoContabilidadeCaernAction.do` | 🔴 **A tela de uma companhia aparece no menu com nome genérico** — o usuário não distingue as duas pelo nome |
| Campos de layout em entidades de domínio: `numeroCartao`, `numeroFolha`, `codigoReferencia`, `numeroVersao`, `numeroHistoricoCredito/Debito` (`LancamentoOrigem`); `numeroTerceiros`, `indicadorCentroCusto`, `prefixoContabil` (`ContaContabil`) | Consumidos pelas variantes **CAEMA** e **CAERN** (`getNumeroCartao`, `getNumeroHistoricoCredito`, `getIndicadorCentroCusto`) |

🔵 [INF] **A geração é comum a todas as companhias; só o formato de saída varia.** O GSAN já tinha, na prática, a separação *capacidade genérica × adaptador* — implementada por **herança de controlador** e com **atributos de layout dentro das entidades de domínio**.

### 8.2 Como fica no OpenGSAN [PROP]

```text
Financeiro / Contabilização          ← dono dos lançamentos (contrato genérico)
          │
          ▼
Integrações                          ← contrato de exportação, idempotência, erro observável
          │
          ├─► adaptador ERP "A"      ← formato, compactação, campos próprios do destino
          ├─► adaptador ERP "B"
          └─► …
```

🔴 **O núcleo não conhece o nome de nenhum sistema contábil nem de nenhuma companhia.** Um "adaptador ALPHA", se vier a existir, é **extensão**; os campos de layout (cartão, folha, histórico numerado) pertencem ao **adaptador**, não ao lançamento.

---

## 9. Relatórios [GSAN]

Evolução e saldo de contas a receber contábil · volumes consumidos não faturados · contas baixadas contabilmente · parâmetros contábeis de contas a receber · resumo de devedores duvidosos · resumo de receita (analítico e por banco). 🔵 **Pertencem ao dono do dado** — Contabilização —, conforme a regra da plataforma de Relatórios.

---

## 10. Classificação das descobertas

| Descoberta | Classe | Tratamento no OpenGSAN |
| ---------- | ------ | ---------------------- |
| Geração de lançamentos por competência × localidade × origem | **A** | Preservar |
| Parametrização contábil como dado | **A** | 🔴 Preservar — o acerto central do módulo |
| Taxonomia origem/tipo/item/item contábil | **A** conceito · **D** forma | Preservar a taxonomia como **dado versionado**; separar dela os atributos de apresentação do relatório |
| Resumos (faturamento, receita, contas a receber, envelhecimento) | **A** | Preservar; cada resumo com **dono do fato** explícito |
| Volumes consumidos não faturados | **A** | Preservar — acréscimo de receita por competência |
| Baixa de devedores duvidosos com recuperação | **A** necessidade · **D** implementação | Preservar a semântica; a baixa passa a ser **registro da Contabilização** que referencia a identidade do documento, **não campo escrito na Conta** |
| Marca contábil usada como "dívida ativa" na Cobrança | **D** | Separar os dois conceitos — [PEND] sobre dívida ativa |
| Regeração por remoção | **A** | Preservar a semântica: regerar **substitui**, nunca duplica |
| Exportação para o sistema contábil | **A** capacidade | Capacidade genérica em Integrações |
| Formatos por companhia (CAEMA, CAERN, COSAMA, COSANPA) | **C** | Adaptadores; **fora do núcleo** |
| Herança de controlador, método e tela com nome de companhia | **D** | Não transportar o mecanismo |
| Campos de layout dentro de `LancamentoOrigem` e `ContaContabil` | **C** embutida → **D** | Mover para o adaptador |
| Variantes vazias (CAER, COMPESA, JUAZEIRO) | **E** | Não transportar |
| Tela de companhia publicada no menu com nome genérico | **D** | Não transportar |
| Estimativa de perdas esperadas (PECLD) | **B** no ecossistema · **F** no baseline público | Capacidade **posterior**, documentada, parte por base específica; no código público, nenhum cálculo — no banco, só a estrutura `param_perdas_societarias`. Capacidade da Contabilização com **política variável** — aprofundamento posterior (§7.3) |
| Páginas da wiki não lidas (R0487 e integração contábil) | **F** | [PEND] — host bloqueado nesta sessão |

---

## 11. 🔴 O OpenGSAN precisa ter Contabilidade?

### 11.1 Separar os dois planos

```text
FATO FINANCEIRO DO SANEAMENTO          RAZÃO CONTÁBIL / ERP CORPORATIVO
───────────────────────────────        ─────────────────────────────────
conta faturada, pagamento, baixa,      plano de contas corporativo completo,
aviso bancário, consumo não faturado   razão, balancete, exercício, lançamento
          │                            manual, imobilizado, depreciação,
          ▼                            demonstrações contábeis
lançamento derivado por política  ───► recebe e integra
```

### 11.2 Resposta, pela evidência

| O OpenGSAN… | Resposta | Base |
| ----------- | -------- | ---- |
| **gera fatos contábeis** do saneamento? | ✅ **Sim** | [GSAN] é o que o módulo faz |
| **mantém a política de contabilização** (parâmetros)? | ✅ **Sim** | [GSAN] parâmetros como dado |
| **produz resumos e lançamentos derivados** por competência? | ✅ **Sim** | [GSAN] |
| **regenera** a contabilização de uma competência? | ✅ **Sim** | [GSAN] |
| **exporta** para o sistema contábil? | ✅ **Sim, por adaptador** | [GSAN] + [PROP] |
| **mantém razão, balancete, exercício, lançamento manual**? | ❌ **Não** | [GSAN] busca negativa — nunca manteve |
| **cuida de imobilizado e depreciação** de ativos? | ❌ **Não** | [PROP] — ERP; ver [`gestao-de-ativos.md`](../dominio/gestao-de-ativos.md) §12 |
| **reconhece perdas esperadas (PECLD)**? | ⚠️ **Capacidade prevista, política pendente** — sem fórmula, variável por companhia, norma, período e carteira | [PEND] §7.3 — não é comportamento universal do GSAN público |

🔵 **Conclusão** [PROP, sustentada pela evidência]: **Financeiro/Contabilização no OpenGSAN é um domínio de contabilização subsidiária** — dono dos **fatos contábeis originados no saneamento**, da **política de contabilização** e dos **lançamentos derivados**. **Não é um ERP contábil.** O razão corporativo fica no sistema que recebe a exportação.

⚠️ O nome **"Contabilização"** descreve melhor o que o domínio faz do que "Contabilidade".

---

## 12. Fronteiras

| Com | O que atravessa | Dono |
| --- | --------------- | ---- |
| **Faturamento** | Resumo de faturamento da competência | **Faturamento** (fato) → Contabilização consome |
| **Arrecadação** | Resumo de receita; avisos bancários; pagamentos de documentos já baixados | **Arrecadação** (fato) → Contabilização reconhece a **recuperação** |
| **Cobrança** | Posição de dívida com **idade**, valor e situação de cobrança | **Cobrança** (posição) → Contabilização aplica **critérios de baixa** |
| **Cobrança** | Marca de "dívida ativa" | ⚠️ [PEND] — hoje é o campo da baixa contábil |
| **Micromedição / Faturamento** | Consumo ocorrido e não faturado | [PEND] quem produz a estimativa; a Contabilização a contabiliza |
| **Integrações** | Exportação; adaptadores por ERP | **Integrações** (contrato) · adaptador por destino |
| **ERP corporativo** | Razão, balancete, exercício, imobilizado | **ERP** — fora do OpenGSAN |
| **Analytics** | Resumos para análise gerencial | Analytics **consome** |

🔴 **Regra** [PROP, coerente com a visão conceitual §20]: a Contabilização **não escreve no estado de outro módulo**. A baixa contábil é **registro dela**, referenciando a identidade do documento; quem precisa saber — Cobrança, Arrecadação — **consulta**.

---

## 13. Cenários de caracterização identificados

⚠️ **Inventário**, não especificação — as especificações estão em [`testes/cenarios/financeiro-operacional.md`](../testes/cenarios/financeiro-operacional.md).

1. Lançamentos contábeis do faturamento a partir do resumo da competência.
2. Lançamentos contábeis da arrecadação, com tipo de recebimento.
3. Lançamentos contábeis dos avisos bancários.
4. Lançamentos contábeis dos devedores duvidosos.
5. Seleção e marcação de contas por critério de devedores duvidosos, com resumo.
6. Pagamento de conta já baixada contabilmente — recuperação.
7. Remoção e regeração dos lançamentos de uma competência, localidade e origem.
8. Resumo de contas a receber contábil e de documentos a receber por faixa de vencimento.
9. Volumes consumidos e não faturados na competência.
10. Exportação dos lançamentos para o sistema contábil — formato base e variante de companhia.
11. Resumo de receita por banco e arrecadador.

---

## 14. Pendências

| # | Pendência | Afeta |
| - | --------- | ----- |
| 1 | 🔴 **"Dívida ativa" e "baixa contábil" são o mesmo conceito?** | Cobrança × Contabilização |
| 2 | **Reconhecimento de perdas esperadas (PECLD)**: que políticas suportar, com que insumos — sem fórmula nesta fase | Contabilização — aprofundamento posterior |
| 3 | **Quem produz a estimativa de consumo não faturado** — Micromedição ou Contabilização | Fronteira |
| 4 | **Conteúdo das páginas da wiki** sobre o módulo | Completude — host bloqueado |
| 5 | Semântica exata dos critérios de baixa (`valorLimite × numeroMeses` por situação de cobrança) | Caracterização |
| 6 | Formatos de exportação das companhias além da variante de referência | `A COMPLEMENTAR` |

---

## 15. Evidências principais

```text
Pacote:        src/gcom/financeiro/ (60 classes) · src/gcom/gui/financeiro/ (13)
Controlador:   ControladorFinanceiro.java — :335 faturamento; :515 itens; :5645 integração base
Variantes:     ControladorFinanceiro{CAEMA,CAERN,COSAMA,COSANPA}SEJB — só gerarIntegracaoContabilidade
               ControladorFinanceiro{CAER,COMPESA,JUAZEIRO}SEJB — cascas (17–19 linhas)
Parâmetros:    RepositorioFinanceiroHBM :1008 (faturamento) · :1116 (arrecadação) · :2059 (devedores)
Baixa:         Conta.referenciaBaixaContabil · RepositorioFinanceiroHBM :415–445
Recuperação:   RepositorioArrecadacaoHBM :7173+
Dívida ativa:  RepositorioCobrancaHBM :341–343 (indicadorDividaAtiva)
Batch:         Funcionalidade 681 (faturamento) · 700 (arrecadação) · 755 (devedores) · 1103 (resumo)
Perdas soc.:   financeiro.param_perdas_societarias (dump versionado 2016) — sem classe Java
Menu (2016):   gsan-migracoes/.../20160118183244_popula_tabela_de_funcionalidades.sql — módulo 12:
               14 funcionalidades, 2 pontos de entrada (684 genérica · 752 CAERN) — contagem por script
Banco:         schema financeiro, 27 tabelas
```


---

## 🆕 Adendo da auditoria final da Fase 0 (2026-09-29)

🔴 **Fiscal ≠ Contabilização ≠ Arrecadação** — três ciclos. A Contabilização passa a consumir também **fatos fiscais** (tributos destacados, devolução personalizada) além dos comerciais e financeiros, com a regra de que **cada valor tem uma única origem** e nenhum é somado duas vezes ([`fiscal.md §9`](fiscal.md)). A parametrização contábil ganha **origens fiscais** sem mudar o princípio de lançamento por competência × localidade × origem. Obrigações acessórias (o SPED do legado) e apuração de IBS/CBS ficam **fora** do OpenGSAN — dados por adaptador ao ERP ([`fiscal.md §10`](fiscal.md)).
