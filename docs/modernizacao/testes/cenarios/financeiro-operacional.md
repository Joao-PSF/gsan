# Cenários Críticos — Contabilização e Gestão Operacional

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ **Nenhum valor desta página foi capturado.** Baseline: `⬜ A CAPTURAR NA FASE 2` em todos os cenários.

🔵 **Leitura da área** (revisão controlada de escopo, 2026-09-28): os dois módulos do GSAN que não tinham mapa funcional — [Financeiro/Contabilização](../../modulos/financeiro-contabilizacao.md) e [Operacional](../../modulos/operacional.md). A Contabilização fecha a **escala** (Etapa 7); a Gestão Operacional entra **mínima** no núcleo de atendimento e execução (Etapa 2) e na emissão (Etapa 4).

⚠️ **Os conceitos destas especificações estão fora dos 145** da compatibilidade conceitual. A classe `C1`–`C5` declarada em *Conceitos relacionados* foi atribuída nesta revisão — ver [`gsan-opengsan.md §5.2`](../../compatibilidade/gsan-opengsan.md).

⚠️ **Gestão de Ativos e Redes/GIS não têm cenário de equivalência**: o núcleo do GSAN não tem ativo físico, geometria nem topologia — não há oráculo a comparar ([ADR-0008](../../decisoes/0008-gestao-de-ativos-nativa.md)).

---

## CEN-FIN-001 — Lançamentos contábeis da competência por origem

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: lançamento contábil (C1) · parametrização contábil (C2 — política versionada) · resumos de faturamento e de receita (C1)
- **Objetivo**: caracterizar a transformação dos fatos financeiros da competência em lançamentos de partida dobrada, **pela parametrização**
- **Pré-condições**: CTB-01; competência de faturamento com resumo gerado (massa dos cenários `CEN-FAT`); competência de arrecadação com pagamentos classificados e aviso bancário (massa dos cenários `CEN-ARR`); localidades L1 e L2
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Lançamentos do **faturamento** da competência |
  | V2 | Lançamentos da **arrecadação**, com pagamentos de **dois tipos de recebimento** |
  | V3 | Lançamentos dos **avisos bancários** |
  | V4 | V1 repetida em outra competência após **alterar o dado** da conta de crédito de um item |

- **Operação GSAN**: `gerarLancamentosContabeisFaturamento` (funcionalidade `681`), `gerarLancamentoContabeisArrecadacao` (`700`), `gerarLancamentosContabeisAvisosBancarios` — unidade de processamento = **localidade**
- **Operação conceitual OpenGSAN**: contabilizar a competência por origem
- **Observações semânticas**: cabeçalhos por competência × localidade × origem × tipo · itens D/C com conta, valor e histórico · débitos = créditos em cada lançamento · total contabilizado × total do resumo da origem · V4 — a conta usada muda **sem recompilar**
- **Localizadores GSAN**: `LancamentoContabil`, `LancamentoContabilItem`; `obterParametrosContabilFaturamento` (`RepositorioFinanceiroHBM:1008`), `obterParametrosContabilArrecadacao` (`:1116`); `ControladorFinanceiro:335`, `:515`
- **Resultado semântico esperado**: 🟢 contas de débito e crédito e históricos **decorrem da parametrização**, que é dado; o lançamento é por competência × localidade × origem. ❔ Se a partida dobrada fecha em todos os caminhos e se o total contabilizado confere com o resumo: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos; data de processamento
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 7 → operação — *lançamentos contábeis da competência conferem com os resumos financeiros*
- **Evidência**: [`modulos/financeiro-contabilizacao.md`](../../modulos/financeiro-contabilizacao.md) §5, §6 e §13 itens 1–3

---

## CEN-FIN-002 — Baixa contábil de devedores duvidosos e recuperação

- **Criticidade**: P0
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: baixa contábil (C2 — a marca escrita na Conta passa a registro da Contabilização) · critérios de devedores duvidosos (C2 — política versionada) · recuperação de perdas (C1)
- **Objetivo**: caracterizar seleção por critério, marcação, resumo, lançamentos e **recuperação** quando a conta baixada é paga
- **Pré-condições**: CTB-02; DOC-02 com idades e valores **dos dois lados** de cada limite de critério; competência contábil aberta
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Geração do resumo e da baixa da competência |
  | V2 | Lançamentos contábeis dos devedores duvidosos |
  | V3 | Pagamento **posterior** de uma conta já baixada |
  | V4 | V1 em outra competência após **alterar o dado** de um critério |

- **Operação GSAN**: gerar resumo dos devedores duvidosos (`714`); gerar lançamentos contábeis dos devedores duvidosos (`755`); classificação do pagamento com acumulação da recuperação
- **Operação conceitual OpenGSAN**: baixar contabilmente créditos por política; reconhecer recuperação
- **Observações semânticas**: contas selecionadas — e as de fronteira **não** selecionadas · competência da baixa registrada · resumo por gerência, localidade, categoria, tipo e item · lançamentos da origem · a conta baixada **continua devida** · o pagamento posterior entra no acumulado de recuperação
- **Localizadores GSAN**: `ParametrosDevedoresDuvidosos`, `ParametrosDevedoresDuvidososItem`; `cnta_amreferenciabaixacontabil` escrita em `RepositorioFinanceiroHBM:415–445`; `ResumoDevedoresDuvidosos`; `RepositorioArrecadacaoHBM:7173+`
- **Resultado semântico esperado**: 🟢 **baixa contábil ≠ extinção da dívida**: a conta baixada permanece e pode ser paga; o pagamento é recuperação. ❔ Semântica exata de valor-limite × número de meses por situação de cobrança: **a capturar**. ⚠️ O uso da marca como "dívida ativa" pela Cobrança (`RepositorioCobrancaHBM:341–343`) **não é observável deste cenário** — pendência 1 do mapa
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos; representação da marca (campo da Conta × registro da Contabilização) — por mapeamento semântico
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico, **ao centavo**
- **Gate que este cenário protege**: 7 → operação — *lançamentos contábeis da competência conferem com os resumos financeiros*
- **Evidência**: [`modulos/financeiro-contabilizacao.md`](../../modulos/financeiro-contabilizacao.md) §7 e §13 itens 4–6

---

## CEN-FIN-003 — Regeração da contabilização de uma competência

- **Criticidade**: P1
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: lançamento contábil (C1)
- **Objetivo**: caracterizar que **regerar substitui, nunca duplica**
- **Pré-condições**: CEN-FIN-001 V1 executado para L1 e L2
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Regerar L1 × faturamento sem mudança nos fatos |
  | V2 | Regerar L1 × faturamento depois de retificar uma conta de L1 na mesma competência |
  | V3 | Regerar L1 × arrecadação — os lançamentos de faturamento de L1 e os de L2 ficam intactos |

- **Operação GSAN**: `removerLancamentoContabil(anoMesReferenciaContabil, idLocalidade, idLancamentoOrigem)` seguida de nova geração
- **Operação conceitual OpenGSAN**: regerar a contabilização de competência × localidade × origem
- **Observações semânticas**: quantidade e totais de lançamentos antes e depois · lançamentos de outras localidades e origens intocados · ausência de duplicidade
- **Localizadores GSAN**: `removerLancamentoContabil`; `LancamentoContabil`
- **Resultado semântico esperado**: 🟢 a remoção é por competência × localidade × origem. ❔ Comportamento quando a competência **já foi exportada**: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos; timestamps
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 7 → operação — *regerar não duplica lançamento*
- **Evidência**: [`modulos/financeiro-contabilizacao.md`](../../modulos/financeiro-contabilizacao.md) §6 e §13 item 7

---

## CEN-FIN-004 — Volumes consumidos e não faturados da competência

- **Criticidade**: P1
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: volumes consumidos não faturados (C1) · lançamento contábil (C1)
- **Objetivo**: caracterizar o valor do consumo **já ocorrido e ainda não faturado** e seu lançamento
- **Pré-condições**: CTB-01; grupos de faturamento cujo período de leitura atravessa o fim da competência, com IMV-01 e IMV-03
- **Entrada**: V1 — geração do valor (`898`); V2 — lançamentos contábeis do valor (`1561`)
- **Operação GSAN**: gerar valor de volumes consumidos não faturados; gerar lançamentos contábeis de volumes consumidos não faturados
- **Operação conceitual OpenGSAN**: reconhecer receita de consumo ocorrido e não faturado
- **Observações semânticas**: valor por localidade e categoria · base usada no cálculo · lançamentos gerados
- **Localizadores GSAN**: `ValorVolumesConsumidosNaoFaturado`; funcionalidades `898` e `1561`
- **Resultado semântico esperado**: 🟢 existe acréscimo de receita por competência para o consumo não faturado. ❔ Como a estimativa é calculada e **quem a produz**: **a capturar** — pendência 3 do mapa
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — **ao centavo**
- **Gate que este cenário protege**: 7 → operação — *lançamentos contábeis da competência conferem com os resumos financeiros*
- **Evidência**: [`modulos/financeiro-contabilizacao.md`](../../modulos/financeiro-contabilizacao.md) §4, §13 item 9 e §14 item 3

---

## CEN-FIN-005 — Exportação dos lançamentos para o sistema contábil

- **Criticidade**: P1
- **Etapa OpenGSAN**: 7 — Escala
- **Conceitos relacionados**: exportação contábil (C2 — capacidade genérica; formato no adaptador) · lançamento contábil (C1)
- **Objetivo**: caracterizar o **conteúdo** exportado, separado do layout
- **Pré-condições**: CEN-FIN-001 executado
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Exportação no **formato base**, por origem e competência |
  | V2 | Reexportação da mesma competência |
  | V3 | Variante de companhia — ⚠️ **A COMPLEMENTAR** |

- **Operação GSAN**: `gerarIntegracaoContabilidade(idLancamentoOrigem, anoMes, data)` (`ControladorFinanceiro:5645`); variantes `ControladorFinanceiro{CAEMA,CAERN,COSAMA,COSANPA}SEJB`
- **Operação conceitual OpenGSAN**: exportar os lançamentos da competência ao sistema contábil, por adaptador
- **Observações semânticas**: lançamentos exportados (conta, centro de custo, débito/crédito, valor) · totais por origem · efeito da reexportação
- **Localizadores GSAN**: `ControladorFinanceiro:5645`; funcionalidades `684` (tela genérica) e `752` (tela da CAERN)
- **Resultado semântico esperado**: 🟢 a geração é comum a todas as companhias; só o formato de saída varia. ❔ Idempotência da reexportação: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: layout, delimitador, compactação e nome do arquivo — pertencem ao **adaptador**; compara-se o **conteúdo**
- **Divergência permitida**: nenhuma no conteúdo
- **Oráculo**: **1** — por mapeamento semântico do conteúdo
- **Gate que este cenário protege**: 7 → operação — *exportação reproduz os lançamentos da competência*
- **Evidência**: [`modulos/financeiro-contabilizacao.md`](../../modulos/financeiro-contabilizacao.md) §8 e §13 item 10; [`modulos/integracoes.md`](../../modulos/integracoes.md) inventário item 22

---

## CEN-OPE-001 — Localização operacional da demanda

- **Criticidade**: P1
- **Etapa OpenGSAN**: 2 — Núcleo de atendimento e execução
- **Conceitos relacionados**: distrito operacional, bacia e divisão de esgoto como pontes do território comercial (C2 — coluna da quadra → relação com dono) · unidade de destino do RA (C1)
- **Objetivo**: caracterizar como a estrutura operacional determina **onde** a demanda é programada e **quem** a recebe
- **Pré-condições**: OPR-01; ESP-02; ESP-05; os dois valores do parâmetro quadra × face da companhia
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Companhia usa **quadra**: RA em quadra do distrito D1 → distritos oferecidos à programação |
  | V2 | Companhia usa **face**: RA em face do distrito D2 da mesma quadra |
  | V3 | RA com ESP-05 (relativo a esgoto) em quadra da divisão DV1 → unidade de destino |
  | V4 | Divisão de esgoto informada **incompatível** com localidade, setor ou quadra |
  | V5 | Divisão de esgoto obtida da quadra do imóvel (quadra → bacia → sistema de esgoto → divisão) |

- **Operação GSAN**: `pesquisarTipoServicoDisponivelPorCriterio` (critério 6); `definirUnidadeDestinoDivisaoEsgoto`; `verificarCompatibilidadeDivisaoEsgotoLocalidadeSetorQuadra`; `obterDivisaoEsgoto`
- **Operação conceitual OpenGSAN**: localizar a demanda na estrutura operacional
- **Observações semânticas**: distritos oferecidos para a programação de OS · unidade de destino do RA · resultado da verificação de compatibilidade · divisão obtida para o imóvel
- **Localizadores GSAN**: `ControladorOrdemServicoSEJB:1293`, `:1450–1483`; `ControladorRegistroAtendimentoSEJB:1848`, `:1899`, `:2018`, `:8911`; `ControladorImovelSEJB:5115–5128`; `Quadra.java:68, :71`; `QuadraFace.java:46, :49`; `SistemaParametro.indicadorQuadraFace`
- **Resultado semântico esperado**: 🟢 o distrito vem da quadra **ou** da face, conforme o parâmetro da companhia; para tipo relativo a esgoto, a divisão define a unidade de destino. ❔ Precedência quando quadra e face apontam distritos diferentes: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos; representação da correspondência (coluna × relação) — por mapeamento semântico
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 2 → 3 — *roteamento e programação pela estrutura operacional reproduzidos*
- **Evidência**: [`modulos/operacional.md`](../../modulos/operacional.md) §4, §5.1, §5.2 e §13 itens 1, 2 e 5

---

## CEN-OPE-002 — RA de falta de água confrontado com a programação

- **Criticidade**: P1
- **Etapa OpenGSAN**: 2 — Núcleo de atendimento e execução
- **Conceitos relacionados**: programação de abastecimento e de manutenção (C1) · RA (C1)
- **Objetivo**: caracterizar o aviso ao atendente quando a reclamação de falta de água coincide com o **calendário operacional**
- **Pré-condições**: OPR-02; ESP-06
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | Falta de água em área **sem abastecimento programado** no dia |
  | V2 | Área com abastecimento programado **e manutenção prevista** no dia |
  | V3 | Abastecimento programado, **sem** manutenção |
  | V4 | RA que **não** é de falta de água, na mesma área e dia |
  | V5 | Segunda passagem da mesma operação, com a verificação já feita |

- **Operação GSAN**: registrar e atualizar atendimento — `verificarRegistroAtendimentoFaltaAgua`, `verificarRegistroAtendimentoFaltaAguaInserir` → `verificarProgramacaoAbastecimentoManutencao`
- **Operação conceitual OpenGSAN**: abrir demanda de falta de água consultando o calendário operacional
- **Observações semânticas**: presença e **tipo** do aviso · RA registrado ou não · área e data consideradas
- **Localizadores GSAN**: `ControladorRegistroAtendimentoSEJB:4835`, `:5011`, `:5177`; `AbastecimentoProgramacao`, `ManutencaoProgramacao`
- **Resultado semântico esperado**: 🟢 a consulta é por data × área de bairro × bairro; ausência de abastecimento programado e manutenção prevista produzem **avisos distintos**; RA que não é de falta de água não consulta. ❔ Se o aviso **impede** o registro ou só informa: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: texto exato da mensagem — compara-se o **tipo** de aviso
- **Divergência permitida**: nenhuma — ⚠️ trocar a chave de área (bairro → unidade operacional) exigirá divergência registrada (pendência 2 do mapa)
- **Oráculo**: **1**
- **Gate que este cenário protege**: 2 → 3 — *roteamento e programação pela estrutura operacional reproduzidos*
- **Evidência**: [`modulos/operacional.md`](../../modulos/operacional.md) §4, §5.3 e §13 item 3

---

## CEN-OPE-003 — Qualidade da água no documento emitido

- **Criticidade**: P1
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: qualidade da água (C2 — o dono passa do Faturamento à Gestão Operacional; a emissão consome projeção e congela o que imprimiu) · documento emitido (C1)
- **Objetivo**: caracterizar **qual registro de qualidade** é impresso para cada imóvel
- **Pré-condições**: QLD-01; OPR-01 (face → distrito → setor de abastecimento → sistema); IMV-01
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | A face do imóvel leva a um sistema de abastecimento **com** registro na competência |
  | V2 | Sem registro por sistema; **com** registro de localidade + setor comercial |
  | V3 | Só registro da localidade |
  | V4 | Só registro geral |
  | V5 | Sistema sem registro **e** registro de localidade + setor existente — efeito do passo 2, que não limpa o filtro do passo 1 |
  | V6 | Competência sem nenhum registro |

- **Operação GSAN**: gerar o arquivo texto de faturamento — `gerarArquivoTextoQualidadeAgua`
- **Operação conceitual OpenGSAN**: emitir o documento com a qualidade da água vigente para a área
- **Observações semânticas**: registro selecionado · parâmetros impressos (resultados; amostras exigidas, analisadas e conformes) · competência
- **Localizadores GSAN**: `UC0745GerarArquivoTextoFaturamento:4555`, cascata `:4706–4785` (`limparListaParametros` em `:4749`, `:4769`); `QualidadeAgua`
- **Resultado semântico esperado**: 🟢 a cascata tem quatro níveis — sistema de abastecimento, localidade e setor, localidade, geral. ❔ V5: se o passo 2 encontra o registro depois de o passo 1 ter sido tentado: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: layout do arquivo — compara-se o **conteúdo** impresso
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico; ⚠️ V5 PENDENTE DE CARACTERIZAÇÃO — se o legado não encontrar o registro por efeito do filtro, não reproduzir exigirá divergência registrada
- **Gate que este cenário protege**: 4 → 5 — *conteúdo do documento emitido preservado*
- **Evidência**: [`modulos/operacional.md`](../../modulos/operacional.md) §5.4 e §13 item 4
