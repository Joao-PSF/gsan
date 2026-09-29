# Mapa Funcional — Operacional

> **Fase 0 — revisão controlada de escopo (21ª execução, 2026-09-28).** Lacuna da Fase 0: o GSAN tem um módulo Operacional que **não recebeu mapa funcional**. Este documento o mapeia e responde à pergunta central: *o que o Operacional do GSAN realmente faz — e o que "Gestão Operacional" significa no OpenGSAN, separada de Atendimento/OS, de Redes/GIS e de Gestão de Ativos?*
>
> Nenhum banco, tabela, API ou implementação é definido aqui.

---

## 1. Evidência e método

### 1.1 Marcas de evidência

As mesmas do mapa do Financeiro ([`financeiro-contabilizacao.md §1.1`](financeiro-contabilizacao.md)): **[GSAN]** comprovado no GSAN (código público ou banco público versionado, com localizador) · **[REF]** comprovado em ferramenta de referência · **[INF]** inferência arquitetural · **[PROP]** proposta OpenGSAN · **[DEC]** decisão OpenGSAN · **[PEND]** pendente.

### 1.2 Fontes

| Nível | Fonte | O que forneceu |
| ----- | ----- | -------------- |
| 1 | **Código público** — `gcom.operacional` (**35 classes**, 7 delas em `abastecimento`), `gcom.gui.operacional` (**94**), `ControladorOperacionalSEJB` (**755 linhas**) e os consumidores em Cadastro, Atendimento e Faturamento | Base das afirmações [GSAN] sobre o núcleo |
| 2 | **Catálogo de funcionalidades versionado** (`gsan-migracoes/.../20160118183244_popula_tabela_de_funcionalidades.sql`) | Módulo 10: **49 funcionalidades, 25 pontos de entrada** — contagem por script |
| 2 | **Dump versionado** `gsan-migracoes/comercial/scripts/20160118183224_dump.sql` | Schema `operacional` (**15 tabelas**) e o schema **`operacao`** (**77 tabelas, 3 visões, função `geraindicador`**) — §6 |
| 3–4 | **Wiki do GSAN** | ⚠️ **Não consultada diretamente** — host bloqueado pela política de rede desta sessão. Um trecho indexado por mecanismo de busca descreve o módulo como apoio ao **controle dos elementos do processo operacional** e a um **maior controle das perdas** — [PEND] conteúdo integral |
| 5 | Inventário do `gsan_comercial` | Schema `operacional` com 15 tabelas; ⚠️ **não contém** o schema `operacao` |

⚠️ **Lição aplicada nesta execução**: uma busca negativa restrita ao código Java concluiu que "nada calcula perdas". A mesma busca **no banco versionado** encontrou uma função que calcula um índice de perda física (§6). As buscas negativas deste documento declaram **escopo e camada** (regra 3 de [`procedencia.md`](../procedencia.md)).

---

## 2. Responsabilidade

🔴 **O que o módulo é no GSAN** [GSAN] — **duas camadas distintas**, que o nome "Operacional" junta:

| Camada | Onde vive | O que faz |
| ------ | --------- | --------- |
| **Núcleo** | `gcom.operacional` · schema `operacional` | **Cadastro de referência da estrutura operacional** (sistemas, setores, zonas, distritos, zonas de pressão, fontes, sistemas de esgoto, bacias, divisões), **programação de abastecimento e manutenção** e registro mensal de **produção de água** |
| **Satélite** | Aplicação separada **`gsan-operacional`** (item de menu `12000`, 2013) · schema `operacao` no dump versionado | **Gestão operacional propriamente dita**: volumes por unidade, horas de conjunto motor-bomba, energia elétrica e contratos, produtos químicos, macromedidores e aferição, distritos de medição e controle, análises, **indicadores** — §6 |

🟢 [GSAN] **O núcleo não calcula nada.** O controlador tem 755 linhas: manutenção de cadastro, atualização da programação (`atualizarProgramacaoAbastecimentoManutencao`, `:266`), **a manutenção da marca de hidrômetro** (§7) e uma consulta de fontes por setor comercial (`:745`).

🔵 **Conclusão** [INF, sustentada pelas duas linhas acima]: no núcleo, o valor do Operacional **não está no módulo** — está nas **pontes** que outros módulos atravessam (§5). A gestão operacional com medições e indicadores existiu **fora do núcleo**, num satélite cujo código **não está** nos repositórios analisados.

---

## 3. A estrutura operacional do núcleo [GSAN]

```text
ÁGUA
  TipoCaptacao ◄── FonteCaptacao ◄── SistemaAbastecimento          (um sistema → uma fonte)
                                        ├── SetorAbastecimento
                                        └── ZonaAbastecimento
                    DistritoOperacional ──► ZonaAbastecimento  E  SetorAbastecimento   (dois pais)
                    ZonaPressao ──► DistritoOperacional
  SetorFonteCaptacao = SetorComercial × FonteCaptacao      ← ponte comercial ↔ operacional
  ProducaoAgua = competência × Localidade × volume         ← indexada pelo território COMERCIAL

ESGOTO
  DivisaoEsgoto ──► UnidadeOrganizacional
  SistemaEsgoto ──► DivisaoEsgoto, TipoTratamento
  Bacia ──► SistemaEsgoto

CALENDÁRIO
  AbastecimentoProgramacao · ManutencaoProgramacao
    competência · data/hora de início e fim · município · bairro · área de bairro ·
    sistema · setor · zona · distrito  (a manutenção tem ainda descrição e situação)

PONTES NO TERRITÓRIO COMERCIAL
  Quadra ──► DistritoOperacional, Bacia                    (Quadra.java:68, :71)
  QuadraFace ──► DistritoOperacional, Bacia, Dmc           (QuadraFace.java:46, :49)
```

🟢 [GSAN] Três sinais de que a estrutura **não é uniforme** entre companhias:

1. `DistritoOperacional` tem **dois pais** (zona **e** setor) e uma referência a `SistemaAbastecimento` **comentada** — a hierarquia mudou ao longo do tempo.
2. O uso de **quadra** ou de **face da quadra** como ponte é **parâmetro da companhia** (`SistemaParametro.indicadorQuadraFace`).
3. O **DMC** (distrito de medição e controle) foi acrescentado à **face da quadra** em **2023** (commit `a9b52f1`), com entidade `gcom.cadastro.Dmc` indexada por **localidade e setor comercial**; ⚠️ a tabela `cadastro.dmc` **não tem migration versionada** — deriva de schema.

🔵 [INF] **A estrutura operacional é um vocabulário da companhia, não uma árvore universal.** O OpenGSAN não deve fixá-la em código.

---

## 4. Conceitos — e a pergunta que separa domínio de CRUD

🔴 Para cada conceito: *que decisão ou processo de negócio ele suporta no GSAN?* A resposta vem dos **consumidores** fora do próprio cadastro — contados por script em `src/gcom`, excluídos o pacote, as telas e os relatórios do próprio Operacional.

| Conceito | O que é | Consumidores no GSAN | Decisão ou processo suportado | Evidência |
| -------- | ------- | -------------------- | ----------------------------- | --------- |
| **Sistema de abastecimento** | Conjunto que abastece uma área a partir de uma fonte | Faturamento (qualidade), programação | **Qual informação de qualidade** vai no documento; a que sistema se aplica a programação | [GSAN] cascata em `UC0745GerarArquivoTextoFaturamento:4706` |
| **Setor / Zona de abastecimento** | Subdivisões do sistema | Programação; cadeia distrito → setor → sistema | Localizar o sistema a partir do distrito | [GSAN] mantidos por telas genéricas de tabela auxiliar |
| **Distrito operacional** | Unidade operacional local | **OS** e Faturamento | 🔴 **Critério de programação de OS** (critério 6) a partir da quadra ou da face do local do RA | [GSAN] `ControladorOrdemServicoSEJB:1293`, `:1450–1483`; `IRepositorioOrdemServico:426, :439` |
| **Zona de pressão** | Zona hidráulica do distrito | 🔴 **Nenhum** | **Nenhuma** no GSAN — cadastro sem consumidor | [GSAN] busca: 0 arquivos fora do próprio CRUD |
| **Fonte de captação** (+ tipo) | Origem da água | Cadastro (setor comercial), Faturamento (qualidade) | **Que fontes** se oferecem ao informar a qualidade de um setor | [GSAN] `ExibirInserirQualidadeAguaDadosAction:549`; `SetorFonteCaptacao` |
| **Produção de água** | Volume produzido na competência, por **localidade** | 🔴 **Nenhum** além do próprio relatório | **Nenhuma** — registrada e não usada | [GSAN] busca: só `RelatorioManterProducaoAgua` |
| **Sistema de esgoto** (+ tipo de tratamento) | Conjunto de coleta e tratamento | Cadastro | Hidratar a **divisão de esgoto** do imóvel: quadra → bacia → sistema → divisão | [GSAN] `ControladorImovelSEJB:5115–5128` |
| **Bacia** | Área de contribuição de esgoto | Cadastro (quadra e face) | Idem — elo da cadeia | [GSAN] `Quadra.java:71`; `QuadraFace.java:49` |
| **Divisão de esgoto** | Responsabilidade por área, ligada a uma **unidade organizacional** | 🔴 **Atendimento** | **Unidade de destino do RA** quando o tipo de solicitação é relativo a esgoto; compatibilidade com localidade, setor e quadra | [GSAN] `ControladorRegistroAtendimentoSEJB:2018` (`definirUnidadeDestinoDivisaoEsgoto`), `:8911`, `:1899`; `RegistroAtendimento.java:608` |
| **Programação de abastecimento / manutenção** | Calendário operacional por área | 🔴 **Atendimento** | Ao registrar ou atualizar um **RA de falta de água**, avisar que **não há abastecimento programado** ou que **há manutenção prevista** naquele dia | [GSAN] `ControladorRegistroAtendimentoSEJB:4835`, `:5011`, `:5177` |

🔵 **Leitura**: dos onze conceitos mantidos pelo módulo, **dois não têm consumidor algum fora do próprio cadastro** (zona de pressão e produção de água) e os dois *tipos* (de captação e de tratamento) só classificam o conceito-pai — telas genéricas de tabela auxiliar. Zona de pressão e produção não são conceitos inválidos: são conceitos cuja decisão **mora em outro lugar** (hidráulica; balanço hídrico), que o núcleo do GSAN nunca implementou.

---

## 5. As pontes — onde está o valor

### 5.1 Território comercial → estrutura operacional

🟢 [GSAN] A quadra e a face carregam **distrito operacional** e **bacia** como atributos; a companhia escolhe qual das duas vale (`indicadorQuadraFace`). A OS usa o distrito para montar o roteiro de programação.

- **Necessidade — A**: localizar uma demanda na estrutura operacional.
- **Implementação — D (acoplamento indevido)**: o cadastro **comercial** guarda um atributo **operacional**; mudar o desenho de um distrito exige editar quadras. O mesmo vale para o DMC de 2023.

### 5.2 Divisão de esgoto → unidade que recebe a demanda

🟢 [GSAN] Para tipos de solicitação relativos a esgoto, o local de ocorrência do RA inclui a divisão de esgoto; a **unidade organizacional** da divisão define o **destino** do RA, depois de verificada a compatibilidade com localidade, setor e quadra.

- **A** — a **responsabilidade operacional por área** determina quem trata a demanda. É regra de roteamento legítima, a preservar.

### 5.3 Programação → RA de falta de água

🟢 [GSAN] `verificarProgramacaoAbastecimentoManutencao(data, idBairroArea, idBairro)` só roda quando o RA é de **falta de água**. Sem programação de abastecimento naquele dia e área → mensagem *"não há programação de abastecimento…"*; com manutenção prevista → *"há manutenção prevista…"*.

- **Necessidade — A**: confrontar a reclamação com o **calendário operacional** antes de despachar equipe.
- **Implementação — D e E**: a consulta é por **bairro e área de bairro** (território de endereço), não pela estrutura operacional; o resultado é **texto** para o atendente, não um fato consultável.
- 🔴 **Posição no menu ≠ ownership** [GSAN]: *Informar* e *Consultar* a programação estão no **módulo 6 — Atendimento** (`518`, `248`), embora entidades e controlador sejam do Operacional. O menu seguiu o **consumidor**.

### 5.4 Qualidade da água → documento emitido

🟢 [GSAN] `gcom.faturamento.QualidadeAgua` guarda, por **competência**, os resultados mensais (turbidez, cloro residual, pH, cor, flúor, *E. coli*, ferro, coliformes, nitrato, alcalinidade) e, por parâmetro, as amostras **exigidas, analisadas e conformes** — indexados por **localidade, setor comercial, fonte e sistema de abastecimento**. As telas estão no **Faturamento** (módulo 7, **7 funcionalidades**).

🟢 [GSAN] Na emissão (`UC0745GerarArquivoTextoFaturamento.gerarArquivoTextoQualidadeAgua`, `:4555`), o registro é escolhido por **cascata** (`:4706–4785`):

```text
1. face da quadra → distrito → setor de abastecimento → SISTEMA de abastecimento   + competência
2. localidade + setor comercial                                                   + competência
3. localidade (setor nulo)                                                        + competência
4. geral (localidade e setor nulos)                                               + competência
```

⚠️ [GSAN] O passo 2 **não limpa** os parâmetros do passo 1 — `limparListaParametros` só aparece nos passos 3 e 4 (`:4749`, `:4769`). Comportamento **a caracterizar**, não a presumir (CEN-OPE-003).

- **Necessidade — A**: informar ao consumidor a qualidade da água **no documento**. 🟡 [INF] A presença de *exigidas / analisadas / conformes* por parâmetro é coerente com exigência regulatória de divulgação mensal ao consumidor — a confirmar.
- **Ownership — D (responsabilidade mal posicionada)**: resultado de **monitoramento operacional** mora no **Faturamento** porque o Faturamento é quem o **imprime**.

### 5.5 Fonte ↔ setor comercial

🟢 [GSAN] `SetorFonteCaptacao` (chave setor comercial × fonte) é mantida na **tela do setor comercial** (Cadastro) e usada para oferecer as fontes ao informar a qualidade.

- **A** necessidade (saber que fonte abastece que área) · **D** posicionamento (a origem do abastecimento vira atributo do território comercial).

---

## 6. 🔴 O satélite: `gsan-operacional` e o schema `operacao`

### 6.1 O que se sabe

| Fato | Evidência | Nível |
| ---- | --------- | ----- |
| O item de menu **"Operacional"** (`12000`, 2013) chama `acessarOperacional` | Catálogo de 2016 | [GSAN] |
| `AcessarOperacionalServlet` redireciona para **outra aplicação**, `/gsan-operacional/`, com token **MD5** | `AcessarOperacionalServlet:34–48`; achado 1b de [`riscos-identificados.md`](../seguranca/riscos-identificados.md) | [GSAN] |
| O código dessa aplicação **não está** em `gsan`, `gsan-migracoes` nem `SISAN` | Busca nos três repositórios clonados | [GSAN] negativa |
| O dump versionado tem o schema **`operacao`**: **77 tabelas, 3 visões e a função `geraindicador`**; nenhum mapeamento Hibernate do GSAN o referencia | `20160118183224_dump.sql`; busca em `*.hbm.xml`: 0 | [GSAN] nível 2 |
| ⚠️ O inventário do `gsan_comercial` **não tem** o schema `operacao` | [`banco/estrutura-atual.md`](../banco/estrutura-atual.md) | nível 5 |
| O papel de banco **`gsan_operacional`** recebe `SELECT/INSERT/UPDATE/DELETE` sobre tabelas de **negociação da cobrança por empresa** | `20170504180427_...cobranca_emprsa.sql:35, :78` | [GSAN] |

🟡 [INF] **Que `operacao` seja o banco do `gsan-operacional` é inferência** — forte pelo nome, pela data e pelo conteúdo, não comprovada por grant ou por código.

### 6.2 O conteúdo do schema `operacao` [GSAN — nível 2]

| Família | Tabelas representativas | O que representa |
| ------- | ----------------------- | ---------------- |
| **Unidades operacionais** | `eta`, `eeab`, `eeat`, `rso`, `ete`, `residencia`, `escritorio`, `tipo_unidade_operacional`; visão `estacao_operacional` | Estações de tratamento, elevatórias, reservação, escritórios — com capacidade, altura e volume úteis |
| **Conjunto motor-bomba** | colunas `*_cmb`, `*_cmbpotencia`, `*_cmbvazao`, `*_cmbmca`, `*_cmbmodelo` **dentro da estação**; `*_horas_cmb`, `hora_cmb` | 🔴 A bomba **não tem identidade**: é quantidade e atributos da estação; as **horas de operação** são registradas por estação |
| **Volumes** | `*_volume`, `*_volume_entrada`, `*_volume_saida`, `volume`, `volume_fluxo` | Volumes medidos ou **estimados** por unidade e período |
| **Macromedição** | `macro_medidor` (fabricante, modelo, nº de série, **tombamento**, princípio, protocolo, faixa, sinal, sensor), `macro_medidor_afericao`, `eta_medidor`/`eeab_medidor`/`eeat_medidor` (**data de instalação, TAG**) | 🔴 **Instrumento com identidade patrimonial, instalado numa unidade, com histórico de aferição** — o padrão *equipamento × instalação* da Micromedição, repetido para ativos operacionais, com **uma tabela de instalação por tipo de unidade** e, na reservação (`rso`), **colunas da própria unidade** |
| **DMC** | `dmc` (estação que o alimenta, **macromedidor de entrada**), `dmc_volume` | Distrito de medição e controle com volume de entrada — ⚠️ **outro conceito** que não o `Dmc` de 2023 do núcleo (§3) |
| **Energia** | `unidade_consumidora`, `contrato_energia`, `energiaeletrica`, `energiaeletrica_dados` | Contratos, demanda, faturas de energia importadas por unidade |
| **Insumos** | `produto`, `consumo_produto`, `preco_produto`, `tabelapreco` | Produtos químicos consumidos e seu preço por vigência |
| **Qualidade e rede** | `analise_clinica`, `rede_instalada` | Amostras analisadas × conformes; extensão de rede cadastrada × existente |
| **Indicadores** | `indicador` (fórmula, responsável, grupo), `indicador_mensal`; função `geraindicador` | **17 indicadores** mensais — químicos, energia e demanda contratada, horas paradas, macromedição, rede cadastrada, prazos de OS, vazamentos, tratamento de esgoto, conformidade da qualidade, **perda física**, precariedade de abastecimento |

🔵 [INF] **Tudo é indexado pela hierarquia administrativo-comercial** (gerência regional, unidade de negócio, município, localidade) — não pela estrutura operacional do §3 nem por topologia de rede.

### 6.3 🔴 O que a função `geraindicador` revela

| Achado | Evidência (dump, `operacao.geraindicador`, linhas 501–951) | Classe |
| ------ | ---------------------------------------------------------- | ------ |
| Indicadores de OS e vazamento calculados **lendo diretamente** tabelas de Atendimento, Cadastro e Faturamento | `atendimentopublico.ordem_servico`, `registro_atendimento`, `faturamento.fatur_situacao_hist` | **D** — acoplamento indevido |
| **31 tipos de serviço** fixados por identificador; **uma localidade excluída** por identificador (7 ocorrências); data de corte fixa (5) | `svtp_id=…`, `ra.loca_id <>156`, `'20110101'` | **C** — customização institucional |
| "Precariedade de abastecimento" medida por uma **situação especial de faturamento** | `ftsm_id = 3` (indicador 211) | **D** — conceito comercial usado como proxy operacional |
| 🔴 **Índice de perda física** (210): numerador `A − (A − B) − B` e denominador `A − (A − B)`, com *A* = saída das ETAs e *B* = saída das elevatórias | Linha 888 | **E** — o numerador é **algebricamente zero**; o índice vale **0** sempre que calculado |
| 🔴 **Índice de macromedição total** (209): razão de uma grandeza **por ela mesma** × 100 | Linha 852 | **E** — vale **100%** sempre que calculado |
| Conexão a **outro banco** por `dblink` com **usuário e senha em texto claro** e endereço interno | Linha 948 — **valor não transcrito** | 🔴 **Achado de segurança nº 20** — segredo comprometido, rotação obrigatória |

🔴 **Consequência para o escopo**: *"existência na documentação ≠ boa arquitetura"* vale aqui ao pé da letra. A **necessidade** — controlar perdas, energia e insumos por unidade — é **válida (A)**; a **implementação** encontrada é degenerada nos dois índices centrais. **Nenhuma equivalência** com esses números é requisito do OpenGSAN.

---

## 7. Posição no menu ≠ ownership — a evidência

| Caso | Menu | Código | O que prova |
| ---- | ---- | ------ | ----------- |
| **Marca de hidrômetro** | Módulo **5 — Micromedição** (`738`, `746`, `758`, `759`) | `removerHidrometroMarca`/`atualizarHidrometroMarca` no **`ControladorOperacionalSEJB`** (`:653`, `:681`) | 🔴 O menu acertou e o código errou — **nem menu nem pacote decidem o dono** |
| **Programação de abastecimento/manutenção** | Módulo **6 — Atendimento** | Entidades e controlador do Operacional | O menu seguiu o **consumidor** |
| **Qualidade da água** | Módulo **7 — Faturamento** | Entidade em `gcom.faturamento` | O dado seguiu **quem o imprime** |
| **Módulo 10** | 49 funcionalidades | **45** mantêm os 11 conceitos; **4** são alheias: *Informar Melhorias GSAN*, *Cadastro de e-mail do cliente*, *Exibir log* e o acesso ao satélite | O módulo do menu é **agrupamento de navegação** |
| **Papel `gsan_operacional`** | — | Escreve em tabelas da **Cobrança** | O nome do papel **não descreve** o que ele faz |

---

## 8. O que não existe — buscas negativas com escopo

| Busca | Escopo | Resultado |
| ----- | ------ | --------- |
| Perdas, balanço hídrico, água não faturada (`indicePerda\|balancoHidrico\|perdaFisica\|volumePerdido\|aguaNaoFaturada\|IPDT`) | `src/gcom`, `*.java` | **0 arquivos** |
| Idem | Dump versionado | ⚠️ **Existe** — indicador 210, degenerado (§6.3) |
| Macromedição operacional | `src/gcom`, `*.java` | O único "macromedidor" é `Hidrometro.indicadorMacromedidor` — **medição comercial** de rateio de condomínio (Micromedição) |
| Bomba, válvula, elevatória, adutora, tubulação, patrimônio, imobilizado, depreciação | `src/gcom`, `*.java` | **0 arquivos** para cada termo |
| "Equipamento" | `src/gcom`, `*.java` | Só `EquipamentosEspeciais` — **recurso da equipe de execução** da OS, não ativo da rede |
| "Reservatório" | `src/gcom`, `*.java` | Só `ReservatorioVolumeFaixa` — **reservatório do imóvel** (cadastro comercial) |
| Geometria nas entidades operacionais | `gcom.operacional` | Nenhuma — só descrição, indicador de uso e referências |

🔵 **O núcleo público do GSAN tem objetos físicos** — o hidrômetro, com ciclo de vida completo na Micromedição, e os elementos da estrutura operacional —, **mas não um modelo corporativo unificado de gestão de ativos, nem geometria, nem topologia.** A gestão corporativa de ativos e Redes/GIS **não têm oráculo GSAN** — e nenhuma equivalência será fabricada.

---

## 9. Classificação das descobertas

| Descoberta | Classe | Tratamento no OpenGSAN |
| ---------- | ------ | ---------------------- |
| Estrutura operacional (sistema, setor, zona, distrito, bacia, divisão…) | **A** conceito · **C** hierarquia concreta | Vocabulário **configurável** da companhia; nenhuma árvore fixa em código |
| Distrito e bacia **como colunas** da quadra e da face | **D** | A correspondência território comercial ↔ unidade operacional passa a ser **relação com dono** (§11) |
| Quadra × face como ponte, por parâmetro | **C** | Configuração da companhia |
| DMC na face da quadra (2023), sem migration versionada | **B** conceito · **D** posicionamento · **E** deriva | DMC é zona de medição — pertencimento derivável da rede (ver [`gis-redes-ativos.md`](../arquitetura/gis-redes-ativos.md)) |
| Divisão de esgoto → unidade de destino do RA | **A** | Preservar como regra de roteamento que **consulta** a estrutura operacional |
| Programação × RA de falta de água | **A** necessidade · **D/E** chave e forma | Calendário operacional **consultável** pela estrutura operacional; o aviso ao atendente é consequência |
| Qualidade da água no Faturamento | **A** necessidade · **D** ownership | Dona: Gestão Operacional; a Emissão **consome uma projeção** e congela o que imprimiu |
| Fonte ↔ setor comercial | **A** necessidade · **D** posicionamento | Relação com dono explícito |
| Zona de pressão sem consumidor | **F** no GSAN | Conceito hidráulico — Redes/GIS |
| Produção de água por localidade, sem consumidor | **A** necessidade · **E** implementação | Medição operacional por unidade, não por território comercial |
| Marca de hidrômetro no controlador Operacional | **D** | Micromedição |
| Itens alheios no módulo 10 | **E** | Não transportar |
| Satélite `gsan-operacional` por redirecionamento com token MD5 | **E** | Não transportar o mecanismo (D-02) |
| Papel `gsan_operacional` escrevendo na Cobrança | **D** | Contas de banco por finalidade, menor privilégio |
| Schema `operacao`: unidades, volumes, energia, insumos, macromedição, DMC, indicadores | **A/B** necessidades | **Expansão estrutural** — reconhecer, não mapear agora (§11.3) |
| CMB como atributos da estação | **D** | O equipamento ganha identidade em **Gestão de Ativos** |
| Uma tabela de instalação de medidor por tipo de unidade | **D** — solução *ad hoc* | Um único vínculo ativo × localização funcional |
| Indicadores lendo tabelas de outros módulos, com identificadores fixos | **C** + **D** | Indicador consome **fatos publicados** pelo dono |
| Índices de perda física e de macromedição degenerados | **E** | Não transportar; nenhuma equivalência numérica exigida |
| Credencial em `dblink` dentro de função versionada | **E** + segurança | Achado nº 20 — rotação; `dblink` não entra no OpenGSAN |
| Conteúdo da wiki não lido | **F** | [PEND] |

---

## 10. 🔴 Atendimento / OS ≠ Gestão Operacional

A palavra "operacional" carrega quatro coisas diferentes no ecossistema GSAN. O OpenGSAN as separa:

| Domínio | Pergunta que responde | Dono de |
| ------- | --------------------- | ------- |
| **Atendimento e Execução** | *O que foi pedido, quem executa, quando, com que resultado?* | RA, **OS**, tramitação, prazo, execução, equipe e seus recursos |
| **Gestão Operacional** | *Como o sistema de saneamento está organizado e operando?* | Estrutura operacional lógica, responsabilidade por área, **calendário operacional**, **medições operacionais** agregadas (produção, qualidade distribuída), indicadores operacionais |
| **Redes / GIS** | *Onde está e como se conecta?* | Geometria, topologia, zonas derivadas da rede, simulação hidráulica |
| **Gestão de Ativos** | *Que coisa física é, em que estado está, que manutenção precisa?* | Identidade, classe, hierarquia, condição, criticidade, ciclo de vida, histórico técnico |

🔴 **E o cadastro comercial é um quinto eixo**, que não se confunde com nenhum deles:

```text
Cadastro territorial comercial   Localidade · Setor Comercial · Quadra · Face · Rota
        ≠                        → a quem se fatura, como se lê, como se roteiriza a leitura
Estrutura operacional            Sistema · Setor/Zona de abastecimento · Distrito · Zona de pressão · Bacia · DMC
        ≠                        → como a água chega e o esgoto sai; quem responde pela área
Geometria / topologia GIS        polígono · traçado · nó · arco · conectividade
                                 → onde está e como se liga
```

🔵 [INF] O GSAN **fundiu** os três eixos pela quadra: o território comercial carrega o operacional, e nenhum dos dois tem geometria no núcleo. Por isso o pedido de *"atualizar distrito"* no GSAN é uma edição de quadras.

---

## 11. Gestão Operacional no OpenGSAN [PROP]

### 11.1 O que é

**Gestão Operacional** é o domínio dono da **organização lógica da operação** — as unidades operacionais da companhia, suas relações e a responsabilidade por área —, do **calendário operacional** (abastecimento programado, manutenção programada, interrupções) e das **medições operacionais agregadas** que outros domínios consomem (produção, qualidade distribuída).

### 11.2 O que não é

| Não é dono de | Dono |
| ------------- | ---- |
| Ordem de serviço, execução, equipe | **Atendimento e Execução** |
| Geometria, topologia, zonas derivadas da rede, simulação | **Redes / GIS** |
| Bomba, válvula, macromedidor, estação como **coisa física** | **Gestão de Ativos** |
| Hidrômetro comercial, leitura, consumo | **Micromedição** |
| Localidade, setor comercial, quadra, rota | **Cadastro** |
| Emissão da conta | **Faturamento / Emissão** — consome a projeção da qualidade |

### 11.3 Núcleo inicial × expansão

| Parte | Onde entra | Por quê |
| ----- | ---------- | ------- |
| **Estrutura operacional mínima** (distrito, divisão de esgoto e bacia com a responsabilidade por área) + **correspondência com o território comercial** | **Etapa 2** | Roteamento de RA e programação de OS dependem dela — cenário CEN-OPE-001 |
| **Calendário operacional** consultável | **Etapa 2** | Falta de água × programação — CEN-OPE-002 |
| **Qualidade da água** como dado operacional projetado na emissão | **Etapa 4** | É observável do documento emitido — CEN-OPE-003 |
| Unidades operacionais, volumes, energia, insumos, indicadores, DMC com volume de entrada | **Expansão estrutural** | Necessidades válidas (§6), sem oráculo GSAN confiável — **não mapear agora** |
| Perdas, telemetria, SCADA, laboratório, energia em profundidade | **Fora do escopo desta revisão** | Regra de não abrir escopo infinito |

⚠️ [PEND] **Correspondência território comercial ↔ unidade operacional**: mantida como relação explícita pelo dono ou **derivada de geometria** (Redes/GIS)? Não decidido aqui — nenhuma decisão de PostGIS ou sincronização ([ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md)).

---

## 12. Fronteiras

| Com | O que atravessa | Dono |
| --- | --------------- | ---- |
| **Cadastro** | Correspondência quadra/face ↔ distrito, bacia, DMC | **Gestão Operacional** (relação) · Cadastro dono da quadra |
| **Atendimento e Execução** | Unidade responsável pela área; calendário operacional | **Gestão Operacional** publica · Atendimento **consulta** |
| **Atendimento e Execução** | Manutenção ou interrupção programada que exige **OS** | Operacional **solicita**; a OS é do Atendimento |
| **Faturamento / Emissão** | Qualidade da água da competência | **Gestão Operacional** · Emissão **congela** no documento |
| **Redes / GIS** | Geometria das zonas; pertencimento de uma ligação à zona | **Redes/GIS** (espacial) · Operacional (identidade e significado da unidade) |
| **Gestão de Ativos** | Estações, bombas, macromedidores | **Ativos** (coisa física) · Operacional referencia a **localização funcional** |
| **Micromedição** | Marca de hidrômetro | **Micromedição** |
| **Analytics** | Indicadores operacionais | Analytics consome **fatos publicados**, nunca tabelas alheias |

🔴 **Regra** [PROP, coerente com a visão conceitual]: nenhum indicador lê o estado interno de outro módulo; nenhuma estrutura operacional vira coluna do cadastro comercial.

---

## 13. Cenários de caracterização identificados

⚠️ **Inventário**, não especificação — as especificações estão em [`testes/cenarios/financeiro-operacional.md`](../testes/cenarios/financeiro-operacional.md).

1. Distrito operacional do RA obtido pela quadra ou pela face, conforme o parâmetro da companhia, como critério de programação de OS.
2. Divisão de esgoto do local de ocorrência define a unidade de destino do RA de tipo relativo a esgoto, com verificação de compatibilidade.
3. RA de falta de água confrontado com a programação de abastecimento e de manutenção.
4. Qualidade da água no arquivo de emissão da conta, pela cascata sistema → localidade e setor → localidade → geral.
5. Divisão de esgoto do imóvel derivada da quadra (quadra → bacia → sistema → divisão).
6. Inserção, atualização e remoção da programação com controle de concorrência.
7. Fontes de captação oferecidas por setor comercial ao informar a qualidade.

---

## 14. Pendências

| # | Pendência | Afeta |
| - | --------- | ----- |
| 1 | 🔴 **Correspondência território comercial ↔ unidade operacional**: relação mantida ou derivada de geometria? | Cadastro × Operacional × Redes/GIS |
| 2 | **Semântica da programação**: por área de bairro ou por unidade operacional no OpenGSAN | Atendimento × Operacional |
| 3 | **Código e comportamento do `gsan-operacional`** — não disponíveis | Satélite (§6) |
| 4 | **Conteúdo da wiki** sobre o módulo | Completude — host bloqueado |
| 5 | Motivação regulatória exata dos campos de qualidade | CEN-OPE-003 |
| 6 | Comportamento do passo 2 da cascata de qualidade (filtro não limpo) | CEN-OPE-003 |
| 7 | Os dois conceitos de DMC (núcleo, 2023 × satélite) — qual prevalece no vocabulário | Redes/GIS × Operacional |

---

## 15. Evidências principais

```text
Núcleo:       src/gcom/operacional/ (35 classes) · src/gcom/gui/operacional/ (94)
Controlador:  ControladorOperacionalSEJB.java (755 linhas) — :266 programação; :653/:681 marca de hidrômetro; :745 fontes por setor
Pontes:       Quadra.java:68,71 · QuadraFace.java:46,49 · SistemaParametro.indicadorQuadraFace
OS:           ControladorOrdemServicoSEJB:1293 (critério 6: :1450–1483) · IRepositorioOrdemServico:426,439
RA:           ControladorRegistroAtendimentoSEJB :1899 compatibilidade · :2018 destino por divisão · :4835/:5011/:5177 falta de água · :8911
Imóvel:       ControladorImovelSEJB:5115–5128
Qualidade:    gcom.faturamento.QualidadeAgua · UC0745GerarArquivoTextoFaturamento:4555 (cascata :4706–4785)
DMC (núcleo): gcom.cadastro.Dmc → cadastro.dmc (commit a9b52f1, 2023) — sem migration versionada
Satélite:     AcessarOperacionalServlet:34–48 · menu 12000 (2013)
Banco:        schema operacional (15 tabelas) · schema operacao no dump versionado (77 tabelas, 3 visões)
              função operacao.geraindicador — dump linhas 501–951 (209: 852 · 210: 888 · dblink: 948)
Menu (2016):  módulo 10 — 49 funcionalidades, 25 pontos de entrada (45 de estrutura · 4 alheias)
              programação: módulo 6 (518, 248) · qualidade: módulo 7 (7) · marca de hidrômetro: módulo 5 (4)
Grants:       20170504180427_...cobranca_emprsa.sql:35,78 (gsan_operacional)
```


---

## 🆕 Adendo da auditoria final da Fase 0 (2026-09-29)

| Tema | Posição |
| ---- | ------- |
| **Interrupção programada e emergencial · racionamento** (NR ANA 11/2024: interrupção programada comunicada previamente ao regulador e aos usuários) | 🔵 **Evento operacional** com **área afetada**, dono Gestão Operacional. O legado já tem a semente — programação de abastecimento e de manutenção cruzada com o RA de falta de água (CEN-OPE-002). O que falta, e fica registrado: o evento como conceito, a área afetada derivável do território, o **evento de negócio** que a comunicação consome (canal é da Notificação) e o reflexo na prestação de informações. Classificação **L1** |
| **Qualidade da água** (Portaria GM/MS 888/2021 · SISAGUA · Decreto 5.440/2005) | A informação na conta já está coberta (CEN-OPE-003). O **ciclo de controle** — plano de amostragem, coleta, parâmetro, resultado, limite, conformidade, ação — é **evolução** (L3) da Gestão Operacional; laboratório: **receber resultados de LIMS externo primeiro, ciclo laboratorial próprio como opção** (C); SISAGUA é **adapter** de prestação de informação, sem leiaute no domínio |
| **Perdas e telemetria** | Sem metodologia nesta fase. Os dados que um balanço hídrico exigirá **poderão existir**: consumo micromedido (Micromedição), volume faturado (Faturamento), volume macromedido e setor (Gestão Operacional/Ativos/Redes), séries de telemetria com unidade, origem e qualidade da medição ([completude §10](../auditoria/completude-funcional-regulatoria.md#10-operação-qualidade-metrologia-perdas-telemetria-e-energia)) |

---

## 🆕 Adendo pós-Fase 0 (2026-09-29)

Refinamento arquitetural antes da Fase 1 — a Fase 0 continua encerrada ([registro](../alteracoes/2026-09-29-adendo-pos-fase0.md)).

| Tema | Posição |
| ---- | ------- |
| **Parada / interrupção operacional** | O *evento operacional com área afetada* da auditoria final passa a **conceito nativo** da Gestão Operacional — tipos, estados, impacto calculado **ou** declarado, comunicação, mapa ([`paradas-interrupcoes.md`](../dominio/paradas-interrupcoes.md)). 🔴 **Parada ≠ polígono ≠ *mincut*.** A programação por área consultada pelo Atendimento continua **equivalente** ao legado (CEN-OPE-002, C1); projetá-la a partir da Parada é pendência |
| **Manutenção programada** do calendário | No OpenGSAN, a manutenção é **planejada e programada pelo PCM** (Gestão de Ativos); o que chega à Gestão Operacional é o **pedido de janela**, que vira Parada aprovada ([`pcm.md`](../dominio/pcm.md)) |
| **Produção de água** (§4) e volumes do satélite (§6.2) | Insumo do [Gerencial & Analytics](../analytics/gerencial-analytics.md) — a métrica declara o **ponto de medição**. 🔴 **Nunca** valor SINISA por semelhança de nome ([ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md)) |
| **Indicadores do satélite** (§6.3) | Semente do [catálogo de métricas](../analytics/catalogo-de-metricas.md); os defeitos encontrados viraram regras dele |
