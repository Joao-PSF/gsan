# Módulos Instaláveis e Perfis de Implantação

> **Segundo adendo pós-Fase 0 (2026-09-29)** — refinamento arquitetural antes da Fase 1; a Fase 0 continua encerrada em 29/09/2026. Decisão registrada na [ADR-0010](../decisoes/0010-monolito-modular-perfis-de-implantacao.md), que **especializa a [ADR-0001](../decisoes/0001-monolito-modular-spring-boot.md) sem contradizê-la**. Registro em [`alteracoes/2026-09-29-adendo-2-perfis-de-implantacao.md`](../alteracoes/2026-09-29-adendo-2-perfis-de-implantacao.md).
>
> 🆕 **Revisão final consolidada (2026-09-30)** — [revisão](../auditoria/revisao-final-consolidada-pos-adendos.md): o instalável *Services* passa a chamar-se **Atendimento** — RA · OS · Campo (§3, §7); a **estrutura organizacional** sai da Platform para o Atendimento (§7.2, §14); a execução do Assets e o ponto de consumo do Metering deixam de ser provedores **obrigatórios** e passam a condicionar só a capacidade que os usa (§15). Nenhuma outra decisão mudou.
>
> ⚠️ **Não decide** mecanismo de ativação, formato de configuração, estrutura Maven ou de pacotes, interface Java, tabela, estratégia de migrations, ferramenta de verificação nem mensageria (§23). Marcas **[GSAN]** · **[REF]** · **[INF]** · **[PROP]** · **[DEC]** · **[PEND]** como em [`financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

---

## 1. Três coisas que não se confundem

```text
módulo de domínio   ≠   módulo instalável   ≠   microserviço
```

| | Módulo de domínio | Módulo instalável | Microserviço |
| - | ----------------- | ----------------- | ------------ |
| **O que é** | Fronteira conceitual e de código com dono do estado — Cadastro, Faturamento, Atendimento e Execução… | **Grupo de módulos de domínio** que se habilita ou desabilita junto numa instalação — Commercial, Metering, Atendimento… | Processo implantado à parte, com banco e ciclo de deploy próprios |
| **Fronteira** | Contrato de aplicação; nenhum acesso a entidade alheia (ADR-0001) | Contrato explícito para todo acesso a outro módulo instalável **opcional** (§16) | Rede |
| **Existe no OpenGSAN?** | ✅ Sim | ✅ Sim — 🆕 este adendo | ❌ **Não** |

**[DEC] Perfil de implantação** — o conjunto de módulos instaláveis **habilitados** numa instalação, com os **provedores externos** declarados para os contratos que nenhum módulo ativo atende.

🔴 Um módulo pode ter fronteira conceitual forte **sem** ser instalável isoladamente — os módulos de domínio do Commercial são o exemplo (§4). E um módulo Maven é unidade de **build**, não de implantação: `opengsan-commercial` num POM **não é** um serviço.

---

## 2. Princípio — monólito modular no código, suíte modular na implantação

**[DEC]** Um único código, **uma única versão da suíte**, **um único processo por instalação** — a ADR-0001 continua inteira. O que varia por instalação é **quais módulos estão ativos**.

```text
                    OpenGSAN — UM monólito modular
                                 │
   ┌────────────┬────────────┬───┴────────┬────────────┬────────────┐
Commercial   Metering    Atendimento    Assets     Operations   Networks
   └────────────┴────────────┴───┬────────┴────────────┴────────────┘
                    SINISA   ·   Analytics   ·   Platform
```

| O que **não** existe | Por quê |
| -------------------- | ------- |
| Microserviços · *service mesh* · banco por serviço · deploy por processo | ADR-0001: transações financeiras atravessam módulos; equivalência ao centavo |
| HTTP entre módulos internos | ADR-0007: contratos internos em Java; HTTP só para canais externos |
| Fila interna obrigatória | A modularidade não pode depender de Kafka ou RabbitMQ (§19) |
| Fork, *branch* ou produto por perfil | Todos os perfis saem do mesmo código (§17) |
| `if edition == "SINISA"` espalhado | A presença de uma função decorre do **módulo registrado**, não de uma edição (§19) |

A suíte permite **adoção total**, **adoção incremental** e **coexistência** com sistemas existentes — por contrato, nunca por migração (§18).

---

## 3. Os módulos instaláveis

**[DEC] Nomenclatura**: o nome do módulo instalável tem de **revelar o conteúdo** a quem implanta (Platform, Commercial, Metering, Atendimento…); módulo de domínio mantém o **nome do domínio** em português (Cadastro, Faturamento…). Dois níveis, dois vocabulários — o que impede confundir *Micromedição* (domínio) com *Metering* (o instalável que a contém, com a telemedição futura). ❌ Nenhum módulo se chama "QGIS" ou "Giswater": ferramenta não é módulo. Identificadores técnicos — pacote, artefato — ficam para a Etapa 0.

🆕 **Revisão consolidada (2026-09-30)**: o instalável do RA, da OS e do campo chama-se **Atendimento**. *Services* escondia o RA, soava como camada técnica de serviços e deixava a demanda do cliente parecer assunto do Commercial. O identificador técnico continua decisão da Etapa 0 — pode até ser `services` —, mas o nome funcional e documental é **Atendimento**.

| Módulo instalável | Função | Módulos de domínio que reúne |
| ----------------- | ------ | ---------------------------- |
| **Platform** | Plataforma | Segurança · Processamento · Relatórios (motor) · Integrações (infraestrutura) · Notificação · Documentos e evidências · contexto institucional · registro de módulos (§14) |
| **Commercial** | Comercial | Cadastro · Faturamento (tarifa, benefício tarifário) · Cobrança · Arrecadação (Pagamentos: Pix, Pix Automático, boleto, débito automático) · Contabilização · Fiscal (NFAg) |
| **Metering** | Micromedição e telemedição | Micromedição (+ telemedição/AMI futura) |
| **Atendimento** | Atendimento, OS e campo | Atendimento e Execução — **RA** (solicitação e demanda), **OS**, catálogo de serviços, programação e distribuição, **execução em campo**, unidades de atendimento (§7) |
| **Assets** | Ativos e PCM | Gestão de Ativos (+ PCM) |
| **Operations** | Operação e Paradas | Gestão Operacional (+ Paradas, racionamento, qualidade distribuída, produção) |
| **Networks** | Redes e GIS | Redes/GIS (+ capacidade GIS, engenharia e simulação via Giswater) |
| **SINISA** | Prestação de informações ao SINISA | Prestação de Informações — Workspace SINISA |
| **Analytics** | Gerencial & Analytics | Gerencial & Analytics (+ catálogo de métricas) |

**Canais não são módulos instaláveis** (ADR-0007): o *backoffice* compõe as telas dos módulos ativos; o **portal** é canal sobre os casos de uso do Commercial e do Atendimento; o **campo** e o **QField** são clientes do Atendimento, do Metering e do Networks. ⚠️ Não existe perfil *Field*: o campo é **parte do Atendimento**; o aplicativo móvel é cliente, não perfil de servidor.

🔴 **[DEC] A capacidade GIS sai da Platform e vai para o Networks.** A visão conceitual listava "GIS como capacidade" na plataforma; mas um perfil SINISA não precisa de infraestrutura espacial, e a Platform só recebe o que **todo** perfil usa (§14). GIS continua **capacidade**, não domínio de negócio — agora empacotada no módulo que a usa. Coordenada como **atributo** (a do RA, por exemplo) continua com o dono; **mapa** exige o Networks.

---

## 4. Commercial — coeso por dependência

**[DEC] Um módulo instalável.** Não existem perfis *OpenGSAN Faturamento*, *Cobrança*, *Arrecadação*, *PIX* ou *Fiscal*.

| Evidência da coesão | Fonte |
| ------------------- | ----- |
| Não existe dívida sem documento emitido; posição de dívida só se valida com recebimentos | Dependências **#6** e **#7** |
| A aplicação do recebimento exige a identidade do documento | **#8** |
| Ciclos internos Faturamento ↔ Cobrança e Cobrança ↔ Arrecadação | [Ciclos 5 e 6](../modulos/dependencias-e-ordem-implementacao.md#8-ciclos) |
| O documento fiscal **decorre** da conta; a contabilização, dos fatos de faturamento, arrecadação e baixa | [`fiscal.md`](../modulos/fiscal.md) · [`financeiro-contabilizacao.md`](../modulos/financeiro-contabilizacao.md) |
| Pix, boleto e débito automático são **meios** sob o mesmo ciclo de recebimento | [Completude §5](../auditoria/completude-funcional-regulatoria.md#5-pagamentos--meios-como-extensão) |
| Faturar uma conta lê cadastro e consumo, grava documento, consome débitos e créditos e calcula imposto numa operação | ADR-0001, contexto 1 |

Os módulos de domínio continuam com fronteira própria **dentro** do Commercial — só não se instalam separadamente. ⚠️ Separar o Fiscal tecnicamente é possível no futuro, mas não entra nos perfis iniciais.

**O que o Commercial precisa de fora** (§15): consumo faturável — do **Metering** ou de medição externa (§6); informação de **qualidade da água para o documento** — da **Operations** ou de fonte externa, porque o Decreto 5.440/2005 a exige na conta ([`operacional.md §5.4`](../modulos/operacional.md#54-qualidade-da-água--documento-emitido)); **execução em campo** — corte, religação, ligação — do **Atendimento** ou de sistema de campo externo.

🔴 **O RA não é do Commercial.** A demanda do cliente — ainda que trate de conta, débito ou ligação — é **atendimento**; o Commercial é **origem** de OS (a ação de cobrança, §7.1) e **dono dos efeitos** comerciais que a execução solicita (§7).

---

## 5. Metering

**[DEC] Módulo instalável**: parque de hidrômetros — identidade, aquisição, instalação, retirada, movimentação, revisão, baixa, garantia, lacre quando aplicável, histórico metrológico —, leitura, anormalidades, consumo medido e, no futuro, telemedição/AMI. A coleta móvel de leitura é canal dele.

🔴 **Não depende obrigatoriamente do Commercial.** [GSAN] A Micromedição recebe do Cadastro o imóvel, a ligação e sua situação, a quadra e a rota com o sequencial, a categoria com os parâmetros de crítica, as economias e o grupo de faturamento ([`micromedicao.md`](../modulos/micromedicao.md), fronteiras; dependência **#1**). Sem o Commercial, isso chega **por contrato**, não por cópia do cadastro:

```text
Sistema comercial externo
        ↓  ponto de consumo — unidade usuária e ligação, com o snapshot mínimo:
        ↓  endereço, situação relevante para a leitura, categoria e economias para a crítica
        ↓  roteiro de leitura — rota, sequência, cronograma
OpenGSAN Metering
        ↓  consumo medido, com origem · anormalidades · leituras
Sistema comercial externo
```

| O Metering isolado **precisa** | O Metering isolado **não precisa** |
| ------------------------------ | ---------------------------------- |
| Referência ao ponto de consumo, com snapshot | O cadastro comercial inteiro |
| Roteiro de leitura | Tarifa, conta, cobrança |
| Parâmetros de crítica por classe de consumo | — |

⚠️ **[PEND] Rota é conceito de junção.** No GSAN, `Rota` fica no pacote `micromedicao`, a quadra aponta para ela e ela reúne setor comercial, grupo de faturamento, leiturista e tipo de leitura; a compatibilidade a classificou como conceito do **Cadastro**, com três finalidades (CAD-10, C2). Para o Metering isolado e para o Commercial com medição externa, é preciso separar a **rota de leitura** (trabalho de campo do Metering) do **agrupamento do ciclo de faturamento** (Commercial). No perfil completo, a **mesma rota** serve aos dois papéis, como no GSAN — a equivalência de CEN-CAD-005 não muda. Decisão de modelagem na **Etapa 3**.

**Consumo mínimo tarifário**: quando o Commercial está presente, o Metering o lê pelo contrato (dependência **#5**) e determina o consumo faturável com origem — comportamento preservado. Isolado, o Metering entrega **consumo medido ou estimado, com origem**, e **não aplica** mínimo tarifário: quem fatura aplica.

🆕 **Sem nenhum provedor do ponto de consumo** — revisão consolidada (§15) —, o Metering opera o **parque de hidrômetros**: identidade, aquisição, movimentação, garantia, baixa, lacre quando aplicável, histórico metrológico. **Leitura e instalação** ficam **ausentes** — capacidade condicionada, visível no inventário do perfil; não é perfil inválido.

**Serviço de hidrômetro em campo** — instalação, retirada, substituição, inspeção, revisão — é **OS** do Atendimento (ou de sistema externo de campo); o **estado do hidrômetro**, a instalação vigente e o histórico metrológico são do **Metering**, que aplica o resultado da execução — o mesmo *solicita × aplica* do §7.

---

## 6. Commercial com medição externa

```text
Commercial ──precisa de──► consumo faturável ◄──fornecido por── OpenGSAN Metering
                                             ◄──fornecido por── sistema externo de leitura
                                             ◄──fornecido por── AMI externo
```

O contrato carrega o que a fronteira Micromedição → Faturamento já definia ([visão §20.2](../dominio/visao-conceitual-opengsan.md#202-fronteiras-principais)): **consumo por unidade e referência, com origem tipificada** — real, média, mínimo, estimado —, leituras quando houver, anormalidade, identidade do ponto e do medidor.

| Regra | Consequência com medição externa |
| ----- | -------------------------------- |
| 🔴 **Consumo com origem declarada** — gate 3 → 4 | O provedor externo **tem de** informar a origem; consumo sem origem é recusado |
| 🔴 **O Faturamento não grava consumo** — D-14 | A correção de consumo numa retificação continua **pedido ao dono da medição**; o adapter traduz o pedido; a conta só é retificada com o consumo corrigido devolvido |
| O ciclo de faturamento — grupo e cronograma — é do Commercial | O provedor entrega por referência; a atividade "leitura" do cronograma é cumprida por ele |
| Equivalência com o GSAN | Vale para o **cálculo sobre o consumo** (oráculo 1). A determinação do consumo passa a ser responsabilidade **declarada** do provedor externo |

Não se define interface Java.

---

## 7. Atendimento — RA, OS e Campo

**[DEC] Módulo instalável *Atendimento* = o domínio Atendimento e Execução** (instalável chamado *Services* até a revisão consolidada de 30/09 — só o nome mudou):

```text
OpenGSAN Atendimento
├─ RA ...... solicitação e demanda — protocolo comunicado, solicitante, tipo e especificação, prioridade,
│            prazo, situação, unidade responsável, encaminhamento e tramitação, histórico, acompanhamento
├─ OS ...... execução — tipo de serviço, origem, prioridade, local, programação e distribuição, equipe,
│            roteiro, materiais, checklist, evidências, execução, encerramento, resultado
└─ Campo ... execução em campo — aplicativo de campo; QField nas tarefas geoespaciais; fotos, checklist,
             geolocalização; offline só onde o cliente especializado exige; sincronização por contrato
```

**Ciclo**: *demanda → atendimento → RA → análise e encaminhamento → OS, quando houver → programação e distribuição → execução → encerramento → histórico*.

| Regra | Evidência ou motivo |
| ----- | ------------------- |
| 🔴 O RA **não** é formulário para abrir OS: tem ciclo próprio — prazo, tramitação, encerramento com ou sem execução | [GSAN] ATE-01 · ATE-02; CEN-ATE-002 a 005 |
| 🔴 **RA ≠ OS** e **não** é 1:1 — RA sem OS, RA com várias OS e OS sem RA existem (§7.1) | [GSAN] ATE-02; CEN-ATE-003; CEN-COB-003; CEN-MOD-002 |
| 🔴 O RA **não pertence ao Commercial** | A demanda é do atendimento; o Commercial é origem de OS e dono de efeitos (§4) |
| O **backoffice não é offline**; o campo sincroniza por contrato, com identidade de dispositivo + usuário | ADR-0007 |
| A execução em campo **não aplica** efeito no dado alheio: solicita ao dono | CEN-ATE-007 — *efeito aplicado pelo dono* |

### 7.1 A fronteira RA × OS — reavaliada, não destruída

| Fato | Evidência |
| ---- | --------- |
| RA é **demanda** (protocolo comunicado ao cliente); OS é **execução** — conceitos distintos, com identidades próprias | [GSAN] ATE-01 (C1); [`atendimento.md §12`](../modulos/atendimento.md#12-ra--os-cardinalidade-real) |
| RA sem OS existe; RA com várias OS existe | [GSAN] ATE-02 |
| 🆕 **OS sem RA existe**: a ação de cobrança gera a OS a partir do **documento de cobrança** — monta a OS com documento, tipo de serviço, imóvel e data e chama `gerarOrdemServicoSemValidacao`, que a insere **sem associar RA**; a versão com RA técnico de identificador 0 está **comentada**; o DDL aceita `rgat_id` nulo | [GSAN] `ControladorCobranca:24135–24142` → `ControladorOrdemServicoSEJB:1032–1086`; `20160118183224_dump.sql:15708` |
| A unidade de destino dessa OS é a responsável pela **localidade** do imóvel | [GSAN] `ControladorOrdemServicoSEJB:1074` |

🔵 A leitura integral do caminho de inserção **fecha quase toda** a dúvida registrada no mapa do Atendimento (§30, item 1b): a OS de cobrança não recebe RA técnico nem reutilizado. Resta só a divergência *mapping* × banco já conhecida (`not-null` no `hbm.xml`), que não muda a semântica.

**[DEC] Decisão** — preserva a semântica mapeada e permite o Atendimento sem o Commercial:

1. **O RA continua no Atendimento** — atendimento e execução são o mesmo domínio desde a visão conceitual (§7): o RA com especificação que gera OS, a tramitação e o encerramento por execução não se separam sem perder regra.
2. **A OS não exige RA.** Ela tem **origem**: um RA interno · um módulo OpenGSAN (Commercial — Cobrança, por exemplo —, Metering, Assets/PCM, Operations) · um **sistema externo** ou uma **integração autorizada**.
3. **Solicitação de execução** é o contrato mínimo pelo qual um módulo ou sistema pede uma OS — o lado *solicita* do contrato central ([visão §14.3](../dominio/visao-conceitual-opengsan.md#143--efeito-operacional--o-contrato-central)): tipo de serviço, origem, referências (§8), prazo, prioridade.
4. **Sistema externo pode abrir OS diretamente**, quando o contrato o permite, com **identidade de sistema** e autorização no caso de uso (ADR-0007).
5. **Efeito**: o resultado da OS é **solicitado ao dono**, que aplica — módulo OpenGSAN ou sistema externo, pelo mesmo contrato. Tipo de serviço que declara efeito sem provedor configurado é recusado **na configuração**.
6. **Roteamento**: a unidade de destino vem de regra do próprio Atendimento — por especificação ou por chave territorial recebida — e, quando a Operations existe, também da estrutura operacional ([`operacional.md §5.2`](../modulos/operacional.md#52-divisão-de-esgoto--unidade-que-recebe-a-demanda)). O vínculo *área operacional → unidade de destino* é **configuração do Atendimento**: a Operations fornece a área, nunca a unidade.

### 7.2 Unidades de atendimento — a estrutura organizacional do fluxo

🆕 **[DEC] Revisão consolidada (2026-09-30)**: a **estrutura organizacional** sai da Platform e fica **no Atendimento**.

| Fato | Evidência |
| ---- | --------- |
| A unidade organizacional do GSAN é **posicionamento de fluxo** — de onde o usuário opera, para onde tramita, qual caixa é dele —, não autorização nem recorte de dados | [GSAN] [`seguranca.md §14`](../modulos/seguranca.md#14-unidade-organizacional--abrangência) |
| Os atributos são de atendimento: abertura de RA, tramitação, central de atendimento, meio de solicitação, esgoto, unidade centralizadora, repavimentadora | [GSAN] `UnidadeOrganizacional.java:26–76` |
| Os usos fora do pacote de atendimento ainda são posicionamento de RA ou OS — a unidade da OS de cobrança pelo imóvel, a unidade que encerra o RA na retificação de conta | [GSAN] `UC0870GerarMovimentoContasEmCobrancaPorEmpresa:212`; `ControladorRetificarConta:479–483` |
| Nenhum outro módulo tem regra que dependa dela: o *responsável* do SINISA é atribuído ao formulário ou ao bloco da declaração; o PCM lê **equipe e capacidade** de quem executa | [`sinisa.md §8`](../regulatorio/sinisa.md#8-declaração--o-valor-informado) · [`pcm.md §5`](../dominio/pcm.md#5-programação) |

Consequências: a **lotação** do usuário numa unidade é relação do Atendimento sobre o usuário da Platform — o mesmo padrão de inversão do escopo territorial (§14); a Platform continua dona da **identidade**. Configuração do Commercial que cita unidade — testemunha do termo de parcelamento, por exemplo — referencia a unidade **por identidade**, opcional; detalhe da etapa que a implementa. ⚠️ Três estruturas que não se confundem: **território comercial** (Commercial) ≠ **estrutura operacional** (Operations) ≠ **unidades de atendimento** (Atendimento) — e nenhuma delas é geometria, que é do Networks.

---

## 8. Referência externa e snapshot

```text
Referência externa
├─ sistema de origem ....... o adapter registrado no perfil
├─ tipo .................... cliente · unidade usuária · ligação · ativo · origem da solicitação…
├─ identificador ........... o do sistema de origem — opaco para o OpenGSAN
└─ snapshot mínimo ......... o necessário para interpretar o registro depois:
                             endereço exibido, nome relevante, descrição do equipamento,
                             contexto no momento — com a data em que foi tomado
```

| Regra | Porque |
| ----- | ------ |
| O snapshot **pertence ao registro** que o tomou — OS, leitura, parada | Interpretar historicamente o serviço, como os snapshots da conta fazem no Faturamento |
| 🔴 **Snapshot não é cadastro mestre** | Nunca é atualizado como fonte; mudança no sistema de origem gera **novo** snapshot num **novo** evento |
| A mesma forma vale quando o provedor é um módulo OpenGSAN | O consumidor **não sabe** quem forneceu (§16) |
| Dado pessoal no snapshot segue a **finalidade do registro** | Mínimo necessário; retenção do próprio registro ([completude §7](../auditoria/completude-funcional-regulatoria.md#7-privacidade-por-fluxo-sensível)) |
| Não se define tabela | — |

⚠️ Reconciliar referências externas com identidades internas quando um módulo é acrescentado depois — por exemplo, o Commercial numa instalação que só tinha o Atendimento — é **migração de dados**, fora deste projeto (§18).

---

## 9. Assets / PCM

**[DEC] Módulo instalável *Assets***: ativos, hierarquia, localização funcional, condição, criticidade, ciclo de vida, planos, necessidades, backlog, planejamento, **programação do PCM**, histórico e indicadores de manutenção. ❌ Nenhum módulo instalável PCM separado.

🔴 **Assets não obriga o Atendimento.** A execução é **contrato**:

```text
Assets / PCM ──solicitação de execução──► WorkExecution ◄── OpenGSAN Atendimento (caminho preferencial)
     ▲                                                  ◄── OS / CMMS externo
     └────────── estado e resultado da execução ────────┘
```

| No perfil completo | Com OS externa | 🆕 Sem provedor de execução |
| ------------------ | -------------- | --------------------------- |
| *necessidade → OS → execução → Assets* — sem ordem paralela ([`pcm.md §7`](../dominio/pcm.md#7-sem-ordem-de-trabalho-paralela)) | A solicitação vai ao sistema externo; o estado da necessidade deriva do **estado externo por mapeamento declarado no adapter**; o resultado técnico volta e o **Assets aplica** ao histórico | Inventário, hierarquia, condição, criticidade, planos, backlog e planejamento **operam**; programação e execução do PCM ficam **ausentes** — nada é enviado à execução e **nada no Assets registra execução** |
| A OS encerrada sem execução devolve a necessidade ao backlog | Idem, a partir do estado externo equivalente | — |

🆕 **Revisão consolidada (2026-09-30)**: a execução **condiciona a capacidade**, não o módulo — o cadastro de ativos tem valor sem ela e, sem provedor, nada sai errado em silêncio (§15). O que **não** se admite em nenhum caso é o atalho: registrar execução no próprio Assets seria a ordem de trabalho paralela que a ADR-0008 proíbe.

Sem **Operations**, a localização funcional não se liga a uma unidade operacional — ou se liga por referência externa. Sem **Networks**, não há geometria nem topologia. ERP (custo, patrimônio), estoque, compras, fornecedores e telemetria são **externos** por natureza.

---

## 10. Operations / Paradas

**[DEC] Módulo instalável *Operations***: sistemas e subsistemas operacionais, estrutura operacional, programação operacional, qualidade distribuída, produção quando aplicável, **interrupções e paradas**, racionamento, continuidade e normalização. ❌ Nenhum produto *OpenGSAN Paradas*.

| Sem o módulo | O que acontece |
| ------------ | -------------- |
| **Networks** | Impacto **declarado** — recortes territoriais e operacionais escolhidos em lista; **sem mapa**: o mapa de paradas e o desenho de área exigem a capacidade GIS ([`paradas-interrupcoes.md §5`](../dominio/paradas-interrupcoes.md#5-impacto)) |
| **Atendimento** | Manobra e reparo por **sistema externo de OS** — ou execução registrada como externa. A **Parada** continua da Operations em qualquer perfil: a OS só executa |
| **Commercial** | Unidades usuárias afetadas e contatos vêm de sistema comercial externo; sem provedor, o aviso **individual** aos usuários não existe — o aviso público e ao regulador, sim |
| **Assets** | Parada sem ativo relacionado nem necessidade do PCM |

**O que a Operations fornece quando existe**: qualidade da água ao **documento** do Commercial; programação por área ao RA de falta de água e estrutura operacional ao **roteamento** do Atendimento (CEN-OPE-001 a 003). 🔴 Por isso o perfil **Pequeno prestador** inclui a Operations (§17). Com **Networks**, impacto calculado ou misto — Giswater continua opcional (ADR-0008).

---

## 11. Networks / GIS

**[DEC] Módulo instalável *Networks***: rede, geometria, topologia, **geometria e pertencimento** de setores e zonas derivados da rede, ramais, elementos de rede, análise espacial, **análise de impacto**, e a **capacidade GIS** — guardar, exibir e publicar geometria. Integra **Giswater**, **QGIS**, **QGIS Server** e, quando aplicável, **QField**.

```text
Networks / GIS  = capacidade OpenGSAN
QGIS            = ferramenta
Giswater        = ferramenta especializada
```

| Ponto | Regra |
| ----- | ----- |
| Identidade da unidade operacional (setor de abastecimento) | Continua da **Operations**; o Networks é dono do polígono e do pertencimento derivados da rede ([`gis-redes-ativos.md §8`](gis-redes-ativos.md#8-fronteira-operacional--redesgis--ativos--exemplos)) |
| Identidade corporativa do ativo | Emitida pelo **Assets** quando presente (ADR-0008); sem Assets, o elemento de rede tem identidade de rede, e a corporativa pode vir de **EAM externo** por referência |
| Ligação comercial ↔ ramal físico | Pendência existente; com Commercial ausente, por referência externa |
| RA e OS no mapa | O Networks fornece geometria, localização e contexto de rede; **RA e OS continuam do Atendimento** — a coordenada é atributo deles |

**Complementaridade forte com a Operations**: juntos dão impacto calculado, mapa de paradas e zonas; separados, cada um funciona.

---

## 12. SINISA

**[DEC] Módulo instalável independente — REQUIRED só a Platform.** A V1 continua **100% manual** (ADR-0009, integral).

```text
OpenGSAN SINISA — perfil mínimo
├─ Platform ........ usuários · autorização · contexto institucional (prestador, municípios) ·
│                    documentos e evidências · auditoria · notificação
└─ SINISA .......... ciclo · glossário · formulários · valores manuais · fontes e evidências ·
                     validação · aprovação · histórico · exportação e registro de submissão
```

| Com | O que muda |
| --- | ---------- |
| Outros módulos OpenGSAN | Oferecem **dados auxiliares** — `REFERÊNCIA — NÃO É VALOR SINISA`; nunca valor oficial por padrão |
| Sistemas externos — SAP, TOTVS, GSAN, ERP próprio, SCADA, planilhas, sistemas operacionais | **Fontes auxiliares** por adapter, no futuro; nenhum é exigido |

⚠️ O módulo de domínio chama-se *Prestação de Informações*; o instalável é o **SINISA**. SISAGUA e regulador local **não** entram nele por padrão: têm outras dependências — o SISAGUA depende da qualidade distribuída da Operations.

---

## 13. Analytics

**[DEC] Módulo instalável consumidor.** Consome **fatos publicados, projeções e contratos analíticos** — dos módulos OpenGSAN ativos ou de **fontes corporativas externas** (ERP, SCADA, sistema comercial ou de manutenção próprio). ❌ Não importa serviços internos de nenhum módulo e não consulta banco alheio ([`gerencial-analytics.md §2`](../analytics/gerencial-analytics.md#2-arquitetura-conceitual)). Precisa de **ao menos uma fonte** para ter o que mostrar. Mapa gerencial exige o **Networks**.

---

## 14. Platform — pequena e transversal

**[DEC] Critério de pertinência** — uma capacidade entra na Platform **só** se (a) **todo** perfil a usa, (b) não tem conceito de negócio próprio além do seu instrumento e (c) não depende de nenhum módulo funcional. É o critério da visão conceitual (§8), agora aplicado à implantação. 🆕 **Revisão consolidada**: na dúvida, vale a forma curta — *só entra se todos os perfis realmente precisam e não existe dono de negócio melhor*. Foi esse teste que tirou a estrutura organizacional (§7.2).

| Na Platform | Observação |
| ----------- | ---------- |
| Identidade e autenticação | Usuário interno; infraestrutura de identidade do cliente final — **contas distintas** (ADR-0007) |
| Autorização | Concessão por caso de uso, política, grupos, permissões especiais; **mecanismo** de escopo (abaixo) |
| Usuários | Cadastro do usuário interno. 🆕 A **estrutura organizacional** — unidades, lotação, caixa de trabalho — é do **Atendimento** (§7.2): nem todo perfil a usa, e ela tem dono de negócio melhor |
| **Contexto institucional** | Prestador, titulares e municípios, instrumentos de delegação, reguladores, vigências ([visão §27.3](../dominio/visao-conceitual-opengsan.md#273--contexto-institucional--sem-decidir-multi-tenancy)); a **área de prestação**, recorte do território, continua do Commercial. 🆕 **Por que fica**: é a dimensão do **parâmetro regulado**, mecanismo da própria Platform — que não pode depender de módulo funcional para saber quem regula e desde quando —, e perfis sem o Commercial o usam: o SINISA isolado declara por prestador e município. Não há dono de negócio melhor: é configuração da instalação |
| **Registro de módulos e perfil** | Ativação, validação na inicialização, inventário (§19) |
| Auditoria · configuração · observabilidade | — |
| Parametrização | O **mecanismo** de parâmetro versionado e regulado; o significado de cada parâmetro é do módulo |
| Integrações | **Infraestrutura** — convenções, identidade de sistema e de dispositivo, idempotência, erro durável, segredo fora do código; **os adapters são dos módulos donos** e só existem com eles (§19) — nenhuma camada central de integração dona de regra |
| Documentos e anexos | Guarda, metadados, integridade, acesso por caso de uso; a **semântica** é do módulo |
| Notificação | Canais; o **evento** é do módulo — *Operations → parada programada → Notificação* |
| Processamento | Orquestração; a regra é do módulo |
| Relatórios | Motor, artefato e controle de acesso (D-03); o **relatório** é do módulo |
| *Shell* do backoffice | Navegação composta **só** pelos módulos ativos (ADR-0007) |

❌ **Não pertencem à Platform**: cliente · imóvel · unidade usuária · ligação · território comercial · rota · hidrômetro · tarifa · conta · RA · OS · 🆕 unidade de atendimento · ativo · unidade operacional · parada · geometria · métrica · glossário SINISA. ⚠️ **Platform ≠ `shared`**: o `shared` da ADR-0001 é biblioteca de tipos comuns — dinheiro, identificadores, competência —, não capacidade em execução, e continua pequeno (visão §25.3).

🔴 **[DEC] O oitavo ciclo se resolve por inversão.** O escopo territorial é definido sobre o território do Cadastro (dependência **#15**, [§4.4](../modulos/dependencias-e-ordem-implementacao.md#44--segurança-depende-de-cadastro--uma-dependência-que-faltava)). A Platform não pode depender do Commercial: ela oferece o **mecanismo** de escopo e **cada módulo registra sua dimensão** — o Commercial, o território comercial (S2, D-17 ainda pendente); a Operations, a estrutura operacional; a Platform, o contexto institucional. A dependência #15 continua verdadeira — é do **escopo territorial comercial**, não da Platform. ⚠️ A unidade de atendimento **não** é dimensão de escopo: posiciona o fluxo, não recorta dados ([`seguranca.md §14`](../modulos/seguranca.md#14-unidade-organizacional--abrangência)).

---

## 15. Matriz de dependências

**REQUIRED** — não funciona sem. **OPTIONAL** — ganha capacidade quando o módulo existe. **EXTERNALIZABLE** — contrato atendido por um módulo OpenGSAN **ou** por sistema externo; 🔴 marca **provedor obrigatório**: sem ele, o perfil é inválido. 🆕 **Revisão consolidada**: 🔴 só onde, sem provedor, o módulo produziria resultado **errado em silêncio** ou **violaria norma** — hoje, só o consumo e a qualidade da água do Commercial (§15.2). Os demais contratos **condicionam uma capacidade**: sem provedor, ela fica ausente e o inventário mostra.

| Módulo | Required | Optional | Externalizable | Pode operar isolado? |
| ------ | -------- | -------- | -------------- | -------------------- |
| **Platform** | — | — | — | ❌ É a base de todo perfil; sozinha não entrega negócio |
| **Commercial** | Platform | Metering · Atendimento · Operations · Networks | 🔴 consumo faturável (Metering ou medição externa) · 🔴 qualidade da água para o documento (Operations ou fonte externa) · execução em campo (Atendimento ou sistema de campo) · protocolo de atendimento (Atendimento ou CRM) | ⚠️ Com provedores de consumo e de qualidade — **exceção documentada** (§15.2) |
| **Metering** | Platform | Commercial · Atendimento | ponto de consumo e roteiro de leitura (Commercial ou sistema comercial externo) — **condiciona leitura e instalação** · execução de serviço de hidrômetro (Atendimento ou externo) · telemetria/AMI | ✅ Sim — parque de hidrômetros; leitura e instalação com provedor do ponto de consumo |
| **Atendimento** | Platform | Commercial · Metering · Assets · Operations · Networks | contexto de cliente e unidade · aplicação de efeito · origem da solicitação · ativo · estrutura operacional para roteamento | ✅ Sim |
| **Assets** | Platform | Atendimento · Operations · Networks · Metering | execução (Atendimento ou OS/CMMS externo) — **condiciona programação e execução do PCM** · ERP · estoque · compras · fornecedores · telemetria · unidade operacional | ✅ Sim — ativos, planos e backlog; o PCM executa com provedor de execução |
| **Operations** | Platform | Assets · Atendimento · Networks · Commercial | execução de manobra e reparo · unidades afetadas e contatos · impacto calculado · SCADA · telemetria | ✅ Sim — impacto declarado |
| **Networks** | Platform | Operations · Assets · Commercial · Metering · Atendimento | Giswater · QGIS · outro motor GIS · identidade corporativa do ativo (Assets ou EAM) · ligação e unidade · consumo por nó | ✅ Sim |
| **SINISA** | Platform | Analytics · Commercial · Metering · Operations · Assets — **só referência** | qualquer fonte externa de evidência ou referência | ✅ Sim |
| **Analytics** | Platform | Todos — como **fontes** | qualquer fonte corporativa autorizada | ✅ Sim — com ao menos uma fonte |

🔵 **Correções aos exemplos do roteiro** (validados contra ownership, fronteiras e cenários):

| Exemplo | Correção | Motivo |
| ------- | -------- | ------ |
| Commercial OPTIONAL SINISA e Analytics; Metering, Atendimento e Assets OPTIONAL Analytics | **Removidos** | São **consumidores**: o Commercial não ganha capacidade quando o SINISA existe — o SINISA é que ganha referência |
| Commercial REQUIRED só Platform, sem mais nada | **Provedores obrigatórios** de consumo e de qualidade | Não se fatura consumo medido sem medição; a conta sem informação de qualidade descumpre o Decreto 5.440/2005 (CEN-OPE-003) |
| Metering EXTERNALIZABLE "unidade usuária" | Também o **roteiro de leitura** e os **parâmetros de crítica** | Rota, categoria e economias vêm do Cadastro (#1; CAD-10) |
| Assets EXTERNALIZABLE "OS" | ~~Provedor **obrigatório**~~ → provedor da **capacidade** de execução (§15.2) | A manutenção se executa por OS — interna ou externa; sem provedor, o ciclo do PCM não fecha — mas o cadastro de ativos tem valor sozinho |
| Networks OPTIONAL Assets | Mantido, com a identidade corporativa **externalizável** | ADR-0008: quando o Assets existe, ele emite a identidade; sem ele, EAM externo ou identidade de rede |
| Perfil Pequeno prestador sem Operations | **Operations acrescentada** | Qualidade na conta, roteamento por divisão de esgoto e falta de água × programação (CEN-OPE-001 a 003) — o pequeno prestador não tem sistema externo que os forneça |

### 15.1 Classificação para operar isolado

| Classificação | Módulos | Condição |
| ------------- | ------- | -------- |
| **SUPORTADO ISOLADAMENTE** | SINISA · Atendimento · Metering · Assets · Operations · Networks · Analytics | Só a Platform como outro módulo OpenGSAN; adapters externos **ampliam**. Capacidades condicionadas: leitura e instalação no Metering; programação e execução do PCM no Assets. Analytics precisa de ao menos uma fonte; Networks sem Giswater tem escopo nativo mínimo **pendente** |
| **SUPORTADO COM DEPENDÊNCIA** | Commercial | Só a Platform como outro módulo OpenGSAN — **desde que** consumo e qualidade da água tenham provedor: interno **ou externo** |
| **NÃO FAZ SENTIDO ISOLADO** | Platform | Base de todo perfil |

### 15.2 🆕 Re-auditoria da obrigatoriedade — revisão consolidada (2026-09-30)

Pergunta aplicada a cada 🔴: *a dependência é necessária para o módulo **existir**?* Se não, é rebaixada a condição de capacidade.

| Contrato | Antes | Agora | Motivo |
| -------- | ----- | ----- | ------ |
| Consumo faturável → Commercial | 🔴 | 🔴 **mantido** | Sem consumo não há faturamento — e sem documento não há dívida, cobrança, arrecadação nem fiscal (§4). É a exceção que define o Commercial |
| Qualidade da água para o documento → Commercial | 🔴 | 🔴 **mantido** | A conta sem a informação descumpre o Decreto 5.440/2005 — seria violação regulatória, não capacidade ausente |
| Ponto de consumo e roteiro → Metering | 🔴 | **Condiciona** leitura e instalação | O parque de hidrômetros tem valor sozinho; sem provedor, leitura e instalação não se registram — nada sai errado em silêncio |
| Execução → Assets | 🔴 | **Condiciona** programação e execução do PCM | Ativos, condição, criticidade, planos e backlog têm valor sozinhos; sem provedor nada é executado — e nada no Assets registra execução (§9) |

Efeito: o único REQUIRED continua sendo a Platform; os únicos provedores obrigatórios ficam no Commercial, onde a ausência produziria cobrança errada ou irregular. CEN-MOD-004 V4 passa a esperar *sobe com a capacidade ausente* — não mais *inicialização recusada*.

---

## 16. Contratos externalizáveis

```text
módulo consumidor ──► contrato explícito (definido pelo consumidor) ◄── adapter interno   (módulo OpenGSAN fornecedor)
                                                                    ◄── adapter externo   (ERP · GIS · AMI · terceiro)
```

| Contrato — conceito | Consumidor | Provedor OpenGSAN | Provedor externo | Obrigatório? |
| ------------------- | ---------- | ----------------- | ---------------- | ------------ |
| **Consumo faturável** — com origem; pedido de correção | Commercial | Metering | Leitura externa · AMI | 🔴 Para faturar água e esgoto — real, média, mínimo ou estimado, o consumo vem do provedor |
| **Ponto de consumo e roteiro de leitura** | Metering | Commercial | Sistema comercial | Condiciona leitura e instalação (§15.2) |
| **Solicitação de execução e resultado** | Commercial · Metering · Assets · Operations | Atendimento | OS · CMMS · sistema de campo | Por capacidade — campo do Commercial e do Metering, execução do PCM, manobra e reparo (§15.2) |
| **Aplicação de efeito** — *solicita × aplica* | Atendimento | Commercial · Metering · Assets | Sistema dono do dado | Por tipo de serviço |
| **Contexto de cliente e unidade** | Atendimento · Operations | Commercial | ERP · CRM · sistema comercial | Não |
| **Qualidade da água para o documento** | Commercial | Operations | LIMS · sistema operacional | 🔴 Para emitir |
| **Estrutura operacional para roteamento e programação** | Atendimento | Operations | — regra própria do Atendimento | Não |
| **Unidades afetadas e contatos** | Operations | Commercial (+ Networks) | Sistema comercial | Não — aviso individual |
| **Impacto calculado** | Operations | Networks | — (Giswater opera **dentro** do Networks) | Não |
| **Identidade corporativa do ativo** | Networks · Atendimento | Assets | EAM | Não |
| **Fatos publicados e contrato analítico** | Analytics | Todos | ERP · SCADA · sistemas | Ao menos uma fonte |
| **Referência auxiliar** | SINISA | Analytics · módulos | SAP · TOTVS · GSAN · ERP · SCADA · planilhas | Não — e **nunca valor** (ADR-0009) |
| **Dimensão de escopo** | Platform | Commercial · Operations | — | — |

Exemplos conceituais — **os nomes não são obrigatórios**:

```text
Atendimento ──precisa do contexto da unidade──► CustomerContextPort ◄── CommercialAdapter
                                                                    ◄── ExternalERPAdapter
Commercial ──precisa do consumo faturável──► ConsumptionProvider    ◄── OpenGSAN Metering
                                                                    ◄── ExternalMeteringAdapter
Assets/PCM ──precisa executar manutenção──► WorkExecution           ◄── OpenGSAN Atendimento
                                                                    ◄── ExternalCMMSAdapter
```

🔴 **[DEC] Regras dos contratos**:

1. **Dependência opcional nunca vira *import* direto.** O núcleo do Atendimento não importa `CommercialService`, `ImovelRepository` nem `ClienteRepository`; importa o **contrato**.
2. O contrato é **do consumidor** — porque o provedor pode ser externo e o domínio consumidor não sabe quem forneceu.
3. A **ponte** entre dois módulos OpenGSAN só existe quando **os dois** estão ativos; nenhum dos núcleos importa o outro.
4. Dentro do monólito, **contrato interno em Java** — nunca HTTP, nem entre módulos instaláveis.
5. **Adapter externo** usa a **infraestrutura** de integração da Platform — convenções de idempotência, erro durável e identidade de sistema — e é **do módulo que o usa**: registrado com ele, ausente sem ele (§19).
6. REQUIRED — só a Platform — pode ser usado **diretamente**, porque está sempre presente.

---

## 17. Perfis de implantação

### 17.1 Perfis de referência

**[DEC] "Suportado" significa testado** (§21): o perfil tem teste de inicialização e dos contratos. Todos saem do **mesmo código**.

| Perfil | Módulos | Provedores externos esperados | Para quem |
| ------ | ------- | ----------------------------- | --------- |
| **FULL** | Todos | — | Suíte completa |
| **PEQUENO PRESTADOR** | Platform · Commercial · Metering · Atendimento · Operations · SINISA | — | Pequenas autarquias: núcleo equivalente ao GSAN, sem GIS, sem Ativos, sem Analytics |
| **COMMERCIAL** | Platform · Commercial | 🔴 Medição · 🔴 qualidade da água · campo | Companhia com medição, campo e operação em outros sistemas |
| **COMMERCIAL + METERING** | Platform · Commercial · Metering | 🔴 Qualidade da água · campo | — |
| **METERING** | Platform · Metering | Sistema comercial — para leitura e instalação | Sistema comercial próprio + OpenGSAN Metering |
| **ATENDIMENTO** | Platform · Atendimento | Opcional: ERP · CRM · sistema comercial | ERP ou sistema comercial próprio + OpenGSAN Atendimento |
| **ASSETS** | Platform · Assets | OS/CMMS — para executar o PCM · opcional: ERP | Gestão de ativos sobre OS existente |
| **ASSETS + ATENDIMENTO** | Platform · Assets · Atendimento | Opcional: ERP | ERP + Ativos + execução |
| **ASSETS + OPERATIONS + NETWORKS** | Platform · Assets · Operations · Networks | OS/CMMS — para executar o PCM | Operação e engenharia |
| **OPERATIONS** | Platform · Operations | Opcional: unidades afetadas | Paradas sem GIS |
| **NETWORKS** | Platform · Networks | Opcional: Giswater | Cadastro técnico de redes |
| **SINISA** | Platform · SINISA | — | Só a prestação ao SINISA |
| **ANALYTICS** | Platform · Analytics | Fontes corporativas | Gerencial sobre sistemas existentes |

### 17.2 Matriz de perfis

✅ no perfil · 🔌 contrato atendido por sistema externo · — ausente

| Perfil | Platform | Commercial | Metering | Atendimento | Assets | Operations | Networks | SINISA | Analytics |
| ------ | -------- | ---------- | -------- | ----------- | ------ | ---------- | -------- | ------ | --------- |
| FULL | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PEQUENO PRESTADOR | ✅ | ✅ | ✅ | ✅ | — | ✅ | — | ✅ | — |
| COMMERCIAL | ✅ | ✅ | 🔌 | 🔌 | — | 🔌 | — | — | — |
| COMMERCIAL + METERING | ✅ | ✅ | ✅ | 🔌 | — | 🔌 | — | — | — |
| METERING | ✅ | 🔌 | ✅ | 🔌 | — | — | — | — | — |
| ATENDIMENTO | ✅ | 🔌 | — | ✅ | — | — | — | — | — |
| ASSETS | ✅ | — | — | 🔌 | ✅ | — | — | — | — |
| ASSETS + ATENDIMENTO | ✅ | 🔌 | — | ✅ | ✅ | — | — | — | — |
| ASSETS + OPERATIONS + NETWORKS | ✅ | — | — | 🔌 | ✅ | ✅ | ✅ | — | — |
| OPERATIONS | ✅ | 🔌 | — | 🔌 | — | ✅ | — | — | — |
| NETWORKS | ✅ | — | — | — | — | — | ✅ | — | — |
| SINISA | ✅ | — | — | — | — | — | — | ✅ | — |
| ANALYTICS | ✅ | 🔌 | 🔌 | 🔌 | 🔌 | 🔌 | 🔌 | — | ✅ |

### 17.3 Combinações não listadas

**[DEC] Não se promete toda combinação** — com oito módulos funcionais, seriam 2⁸. Uma combinação fora da lista é **permitida se a validação do perfil passar** (§19), mas não é garantida por teste. Promover uma combinação a perfil de referência exige acrescentá-la aos testes de perfil. Exemplo válido e não listado: *COMMERCIAL + METERING + SINISA* — o SINISA não acrescenta dependência.

---

## 18. Coexistência — não é migração

**[DEC] Coexistência**, aqui, é **integração operacional entre sistemas vivos**:

```text
OpenGSAN módulo X  ↕  contrato  ↕  sistema existente
```

❌ Não é sincronização massiva de bancos, migração nem *cutover* — isso continua no projeto de migração, fora deste ([ADR-0005](../decisoes/0005-sisan-modernizacao-evolutiva-do-gsan.md)). ⚠️ A [arquitetura alvo](arquitetura-alvo.md) diz que "coexistência não pertence a este projeto" — no sentido de **dois sistemas com o mesmo dado durante uma transição**; o sentido deste adendo é outro, e a distinção fica registrada lá.

| Cliente | Perfil | Coexiste com |
| ------- | ------ | ------------ |
| **A** | FULL | — |
| **B** | SINISA | Tudo o mais em outros sistemas; eles podem virar fontes auxiliares |
| **C** | ATENDIMENTO | ERP próprio — cliente, unidade e efeitos por contrato |
| **D** | METERING | Sistema comercial próprio — ponto de consumo e roteiro entram, consumo sai |
| **E** | ASSETS + ATENDIMENTO | ERP — custo, patrimônio, estoque, compras |
| **F** | COMMERCIAL + METERING + SINISA | Sistema de campo e fonte de qualidade da água externos |

---

## 19. Regras de um perfil em execução

| Tema | Regra |
| ---- | ----- |
| **Configuração** | Conceitualmente, `modules: { commercial: true, metering: false, … }` mais os provedores externos por contrato. **Formato não escolhido** |
| 🔴 **Validação** | O sistema **falha na inicialização** — com diagnóstico — quando um módulo REQUIRED falta ou um contrato 🔴 não tem provedor, interno ou externo. Nunca sobe pela metade **em silêncio**: contrato que só condiciona capacidade, sem provedor, deixa a capacidade **sem registro** e *ausente* no inventário (§15.2; CEN-MOD-007 V3) |
| **Perfil ≠ fork ≠ edição** | Nenhum *branch* por perfil; nenhum `if edition == …`: o que existe é o que foi **registrado** pelos módulos ativos |
| **Interface** | Só os módulos ativos registram menus, telas, funcionalidades e permissões — nenhum menu vazio |
| **Autorização** | Duas perguntas distintas: *o módulo existe?* e *o usuário pode executar?* — a segunda continua do **caso de uso** (ADR-0007). Ativar módulo **não** concede nada; a concessão de um módulo desligado fica **dormente**, não é apagada |
| **Processamento** | Jobs de módulo desligado **não iniciam**; job que atravessa módulos usa os contratos |
| **Integrações** | Adapter só é registrado com o módulo que o usa — nada de adapter de NFAg numa instalação só SINISA |
| **Relatórios** | Dependem só do próprio módulo e dos contratos aceitos — nenhum relatório SINISA exige o Commercial |
| **Notificação** | Infraestrutura da Platform; o evento é do módulo dono |
| **Documentos** | Infraestrutura da Platform; a semântica é do módulo — NFAg no Commercial, evidência de OS no Atendimento, evidência SINISA no SINISA |
| **Analytics** | Só fatos publicados, projeções e contratos analíticos — nunca o banco interno alheio |
| **Eventos** | Mensageria **não decidida**: evento de domínio interno pode ser chamada, *listener* ou outro mecanismo interno. Modularidade **não depende** de Kafka ou RabbitMQ |
| **Observabilidade** | Inventário na inicialização e consultável: versão, módulos ativos e, por contrato, o provedor — *interno*, *externo (sistema X)* ou *ausente* |
| 🔴 **Atualização de versão** | **Nunca ativa módulo.** Módulo novo nasce **desabilitado** quando não fazia parte do perfil existente — o mesmo princípio do `autoPreenchimento = false` da ADR-0009 |
| **Desativação** | Não apaga dados; exige que o perfil resultante seja válido — os dependentes precisam de outro provedor |

```text
OpenGSAN 1.x
Módulos ativos: Commercial · Atendimento · SINISA
Contratos:     consumo faturável = externo (Sistema X) · qualidade da água = externo (LIMS Y)
               execução em campo = Atendimento · unidade operacional = ausente
```

---

## 20. Dados e migrations

**[DEC] Regras de dados** — monólito modular **não** significa schema separado por módulo, e o modelo físico **não** é decidido aqui:

1. Um módulo **só escreve** no que possui.
2. Leitura transversal só por **contrato ou projeção** apropriada.
3. A **ausência** de um módulo não pode quebrar tabela alheia. [INF] Consequência a confirmar na Etapa 0: **nenhuma chave estrangeira** de um módulo para tabela de módulo **opcional** — referência por identidade; chave estrangeira só na direção de dependência REQUIRED, isto é, para a Platform.

**[PEND] Questão para a Etapa 0 — migrations de módulos desabilitados são aplicadas?**

| Alternativa | Consequências |
| ----------- | ------------- |
| **A — Todas, sempre** | Schema idêntico em toda instalação; habilitar depois não exige migration; upgrade simples. ⚠️ Tabelas sem uso nos perfis parciais; a migration de um módulo desligado ainda roda — e pode falhar por ele |
| **B — Só as dos módulos ativos, num histórico único** | Schema mínimo. ⚠️ Habilitar depois executa migrations **mais antigas** que a versão corrente — exige execução fora de ordem; ordem global de versões entre módulos fica frágil |
| **C — Histórico próprio por módulo instalável** | Isolamento limpo; habilitar depois roda o histórico do módulo do começo; combina com a regra 3. ⚠️ Mais de um histórico para operar; objetos que cruzam módulos — visões, chaves — ficam proibidos ou movidos para contratos |

Critérios que qualquer escolha precisa cumprir: atualização de versão não ativa módulo; habilitar depois não exige SQL manual; desabilitar não apaga dado; nenhuma migration de um módulo altera tabela de outro; ADR-0002 — Flyway desde `V1` — continua valendo.

---

## 21. Verificação da modularidade

A modularidade precisa ser **verificável em build e em teste** — sem isso, degrada (ADR-0001).

| Verificação | Exemplo de regra |
| ----------- | ---------------- |
| **Teste arquitetural** | *Commercial não acessa internos de Assets* · *Atendimento não acessa repositório do Commercial* · *SINISA não acessa Faturamento* · *nenhum núcleo importa dependência opcional* |
| **Teste de perfil** | *FULL inicia* · *SINISA só inicia* · *ATENDIMENTO só inicia* · *ASSETS + ATENDIMENTO inicia* · *ASSETS sem provedor de execução inicia, sem o PCM executar* · *COMMERCIAL sem Metering interno, com adapter externo, inicia* · *OPERATIONS sem Networks inicia* · *perfil inválido não inicia* |

**Ferramentas — só como meio, avaliadas na Etapa 0**, pesando benefício × complexidade, **nunca por moda**: ArchUnit ou equivalente (já previsto no dia 1 da ordem); Spring Modulith — verificação de fronteira, dependências, eventos e documentação modular, contra o custo de adotar suas convenções; módulos Maven por módulo instalável. ⚠️ Nenhuma troca de stack para cumprir este adendo. ⚠️ **Módulo Maven ≠ microserviço.**

---

## 22. Impacto na ordem e na Etapa 0

**[DEC] Restrição transversal**: *cada módulo nasce respeitando sua fronteira de implantação.* As etapas não mudam.

| Onde | O que entra |
| ---- | ----------- |
| **Etapa 0 — antes da primeira funcionalidade** | Decidir o **mecanismo de ativação**, a **estrutura Maven e de pacotes**, os **testes de fronteira**, a **estratégia de migrations** (§20), o **registro condicional** de interface, permissões, jobs, endpoints e adapters, a **validação** e o **inventário** do perfil |
| **Gate 0 → 1** | Módulos-fixture provam a ativação e a fronteira — CEN-MOD-006 e 007 |
| **Etapa 1** | 🔴 A primeira fatia vertical **atravessa dois módulos instaláveis** — Cadastro (Commercial) e RA (Atendimento): o contrato entre eles **nasce com ela**, nunca um repositório compartilhado |
| **Gate 2 → 3** | Atendimento sobe sem Commercial — CEN-MOD-002 |
| **Etapa 3** | Separar rota de leitura × agrupamento do ciclo (§5) |
| **Gate 4 → 5** | Commercial fatura com medição externa — CEN-MOD-003 |
| **Trilha estrutural** | Assets com OS externa · Operations sem Networks — CEN-MOD-004 e 005 |
| **Trilha regulatória** | SINISA isolado — CEN-MOD-001 |

---

## 23. O que este documento não decide

`pom.xml` · Spring · *profiles* · *feature flags* · migrations · adapters · classes · API · Spring Modulith · formato de configuração · tabelas · mensageria · política de versão por módulo — a ADR-0001 adiou JARs versionados independentes, e a suíte continua com **versão única**.

## 24. Pendências

| # | Pendência | Quando |
| - | --------- | ------ |
| 1 | Mecanismo de ativação, estrutura Maven e de pacotes, estratégia de migrations | Etapa 0 |
| 2 | Identificadores técnicos dos módulos instaláveis — o do Atendimento pode ser `services`; o nome funcional não muda | Etapa 0 |
| 3 | Rota de leitura × agrupamento do ciclo de faturamento (CAD-10) | Etapa 3 |
| 4 | Conteúdo dos contratos de consumo, execução e efeito | Com o primeiro par de módulos que os usa |
| 5 | Escopo nativo mínimo do Networks sem Giswater | Trilha estrutural |
| 6 | Portal numa instalação sem Commercial — vínculo do cliente final por provedor externo | Etapa 8 |
| 7 | Quais combinações além dos perfis de referência entram nos testes | Revisão a cada etapa |
| 8 🆕 | Configuração do Commercial que cita unidade de atendimento — testemunha do termo de parcelamento — num perfil sem o Atendimento: referência por identidade ou por usuário | Etapa 6 — Cobrança |
