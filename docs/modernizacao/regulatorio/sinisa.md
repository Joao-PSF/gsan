# SINISA — Prestação de Informações como processo regulatório versionado

> **Adendo pós-Fase 0 (2026-09-29)** — refinamento arquitetural antes da Fase 1; a Fase 0 continua encerrada em 29/09/2026. Decisão registrada na [ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md); registro da execução em [`alteracoes/2026-09-29-adendo-pos-fase0.md`](../alteracoes/2026-09-29-adendo-pos-fase0.md).
>
> 🔴 **Corrige uma premissa.** A auditoria final tratou o SINISA como capacidade transversal cujos valores seriam **consolidados no Analytics** e **submetidos por Integrações** ([`auditoria-final-fase0.md §12`](../auditoria/auditoria-final-fase0.md#12-sinisa); [completude §10](../auditoria/completude-funcional-regulatoria.md#10-operação-qualidade-metrologia-perdas-telemetria-e-energia)). A conclusão *"SINISA não é BI"* continua válida; o caminho *fonte → métrica → SINISA* deixa de ser o padrão (§2). O texto da auditoria é **registro histórico** e não foi reescrito.
>
> ⚠️ **Não decide** schema, tabelas, motor de validação, leiaute, formato de exportação, lista de campos ou códigos. Marcas **[GSAN]** · **[REF]** · **[INF]** · **[PROP]** · **[DEC]** · **[PEND]** como em [`financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

---

## 1. O que o SINISA é — pelas fontes oficiais

⚠️ Leitura direta de `www.gov.br` **bloqueada** pela política de rede desta sessão: as páginas oficiais foram lidas **por resumo de busca**, e a certeza foi rebaixada onde só havia fonte secundária (regra 7 de [`procedencia.md`](../procedencia.md)). Fontes ao fim do documento.

| Aspecto | O que as fontes mostram | Certeza |
| ------- | ----------------------- | ------- |
| **Instituição** | Sistema Nacional de Informações em Saneamento Básico — Lei 11.445/2007, atualizada pela Lei 14.026/2020; sucede o SNIS a partir de 2024 | [REF] |
| **Obrigação** | Prestação **anual**; condição de acesso a recursos federais do setor | [REF] |
| **Ciclo** | Anual, pela Portaria MCID nº 1.069. **Ciclo 2026 = ano-base 2025**: coleta de 13/05 a 03/09/2026 · versão preliminar até 03/11 · manifestação e validação até 17/11 · publicação e **certidão de regularidade** até 31/12/2026 | [REF] |
| **Prazos móveis** | Prorrogação e prazo adicional da coleta em setembro de 2026 | ⚠️ Fontes secundárias |
| **Componentes** | Abastecimento de água · esgotamento sanitário · resíduos sólidos · drenagem e águas pluviais · gestão municipal. Água e esgoto: responsabilidade do **prestador**, quando o serviço é delegado; os demais, do município | [REF] |
| **Tipo de prestador** | Nos componentes de água e esgoto, ambientes distintos para prestador **regional** (mais de um município) e **local** (um município) | [REF] |
| **Formulários** | Um por componente, em blocos — no esgoto: gestão administrativa e financeira · informações técnicas · prestação e delegação | [REF] |
| **Glossários** | Glossário **de informações** e glossário **de termos técnicos**, publicados **por ciclo e por componente**; manual de preenchimento por ciclo e por tipo de prestador | [REF] |
| **Preenchimento** | Sistema de coleta **online**, com acesso por credencial do prestador; **comprovante de preenchimento** ao enviar | [REF] |
| **Comprovante ≠ regularidade** | O comprovante confirma o envio; a regularidade depende de **análise e validação** | [REF] |
| **Regulador** | Desde a coleta de 2025, as agências reguladoras **acompanham** o preenchimento dos regulados e podem pedir **correção** | [REF] |
| **Publicação retificável** | Planilhas oficiais de indicadores publicadas com versão de **retificação** | [REF] — nome do arquivo publicado |
| **Importação por arquivo** | **Não encontrada** nas fontes consultadas | [PEND] §14 |

**[INF] O que isso impõe à arquitetura**: o **glossário muda por ciclo** — logo, versionado; os **prazos mudam dentro do ciclo** — logo, dado, nunca constante; o formulário depende de **componente e tipo de prestador** — logo, eixos do ciclo; o regulador **pede correção** — logo, a retificação é fluxo de primeira classe; e a regularidade é **decidida fora** do OpenGSAN — logo, o sistema registra o que foi declarado, não certifica nada.

---

## 2. 🔴 Correção de premissa

```text
Premissa anterior — ❌ deixa de ser o padrão:

  fonte OpenGSAN ──► métrica (Analytics) ──► informação SINISA ──► submissão (Integrações)
                      preenchimento derivado
```

**Por quê.** Cada informação do SINISA tem **definição própria**, com ressalvas, inclusões, exclusões, critérios de medição, período, unidade, recorte e condições específicas. Um dado interno **com nome semelhante não é equivalente**:

```text
OpenGSAN: "volume produzido"          SINISA: "volume produzido"
                    ✗  não implica  valor OpenGSAN = valor SINISA
```

| Fonte de divergência | Exemplo |
| -------------------- | ------- |
| Estado da água | Bruta × tratada |
| Conceito | Produzido × disponibilizado |
| Ponto físico da medição | Saída da captação × saída da ETA × entrada do reservatório |
| Perdas e usos internos | Perdas na ETA; volumes de processo (lavagem de filtros) |
| Fronteira do sistema | Água importada e exportada entre sistemas ou prestadores |
| Tempo | Competência × período de leitura; posição em 31/12 × média do ano |
| Qualidade do dado | Medido × estimado |
| Glossário | Exclusões previstas no ciclo — que podem mudar no ciclo seguinte |

[GSAN] O próprio GSAN registra **produção de água por localidade** e competência — recorte **comercial**, não ponto de medição —, sem consumidor além de um relatório ([`operacional.md §4`](../modulos/operacional.md#4-conceitos--e-a-pergunta-que-separa-domínio-de-crud)). É exatamente o tipo de dado com nome igual e semântica a verificar.

🔴 **[DEC] Nenhum mapeamento semântico automático por nome.** A semântica prevalece sobre o nome.

---

## 3. Regra da versão inicial

> 🔴 **[DEC] TODO PREENCHIMENTO SINISA É MANUAL** — mesmo quando o OpenGSAN tem um dado parecido.

| Na V1 o sistema **não** | Exemplo do que fica proibido |
| ----------------------- | ---------------------------- |
| Calcula | Somar o volume macromedido do ano para um campo |
| Preenche | Gravar qualquer valor que o usuário não digitou |
| Pré-seleciona | Opção marcada de antemão num campo de escolha |
| Infere | Copiar o valor do ciclo anterior; converter unidade por conta própria |
| Sugere número | Botão *"aplicar valor"* — é do modo SUGERIDO, futuro (§16.3) |

O sistema **pode** mostrar **dados auxiliares**, sempre rotulados `REFERÊNCIA — NÃO É VALOR SINISA` (§10).

---

## 4. Workspace SINISA — dono da declaração

**[DEC] O Workspace SINISA é dono da declaração regulatória**: ciclo carregado, valores declarados, responsáveis, aprovação, submissão e retificação.

| Responsabilidade | O que faz | O que **não** faz |
| ---------------- | --------- | ----------------- |
| Carregar o catálogo oficial | Ciclo, glossários e campos como **dado** (§5, §6) | Inferir campo ou definição |
| Organizar formulários | Por componente, bloco e tipo de prestador | Reorganizar pelo modelo interno |
| Apresentar definições | Definição oficial, ressalvas, unidade (§7) | Reescrever o significado |
| Receber valores | Digitados pelo usuário, com fonte (§8) | Calcular o valor oficial |
| Validar o preenchimento | Obrigatoriedade, tipo, unidade, regras publicadas para o ciclo (§9) | Corrigir valor |
| Guardar evidências | Em [Documentos e evidências](../auditoria/completude-funcional-regulatoria.md#6-documentos-e-evidências), classe **Regulatório**, imutável | — |
| Controlar responsáveis | Informante · revisor · aprovador, por formulário ou bloco | — |
| Acompanhar completude | Progresso do fluxo (§12) | Acompanhar valor operacional — é do Gerencial |
| Versionar | Toda mudança cria versão (§8, §15) | Sobrescrever |
| Registrar aprovação e submissão | Quem, quando, o quê, comprovante (§13, §14) | Submeter sozinho |

**[DEC] Onde vive.** Com a declaração guardada — e não mais derivada —, a *Prestação de Informações Regulatórias* passa no critério que a auditoria fixou para uma obrigação virar módulo: **ciclo próprio e obrigatório** ([visão §27.2](../dominio/visao-conceitual-opengsan.md#272--estrutura-conceitual-consolidada-auditoria-final-2026-09-29)). Passa a **módulo** *Prestação de Informações*, no grupo Financeiro / Regulatório, com o **Workspace SINISA** como primeiro conteúdo. ❌ Continua **não** existindo módulo *Regulação*: matriz normativa, parâmetro regulado e obrigações de norma seguem nos donos. ⚠️ SISAGUA e regulador local seguem como estavam; estender a eles o princípio da ADR-0009 é pendência (§21).

🆕 **Módulo instalável *SINISA*** (ADR-0010): REQUIRED **só a Platform** — usuários, contexto institucional, documentos e evidências. Opera **sem nenhum outro módulo OpenGSAN**; os demais, quando existem, só oferecem **referência** ([`modulos-e-perfis-de-implantacao.md §12`](../arquitetura/modulos-e-perfis-de-implantacao.md#12-sinisa); CEN-MOD-001).

**Contexto institucional**: a declaração é **do prestador** ([visão §27.3](../dominio/visao-conceitual-opengsan.md#273--contexto-institucional--sem-decidir-multi-tenancy)); um prestador regional declara por vários municípios.

---

## 5. Ciclo SINISA — glossário versionado

```text
Ciclo SINISA
├─ ciclo de coleta ......... ex.: SINISA 2026
├─ ano-base ................ ex.: 2025
├─ calendário .............. coleta · preliminar · manifestação/validação · publicação — datas revisáveis, com histórico
├─ tipo de prestador ....... regional · local — o que o ciclo definir
├─ componente .............. água · esgoto · … — o que o ciclo definir
├─ versão do glossário ..... por componente
├─ publicação .............. documentos oficiais do ciclo: glossário, manual, formulário —
│                            título, data, URL e resumo criptográfico do arquivo obtido
└─ campos oficiais ......... Informação SINISA (§6)
```

**[DEC]** O catálogo é **dado carregado por ciclo — nunca código** — e nada o infere. **[PROP]** V1: cadastro **conferido** por responsável a partir da publicação oficial; se o Ministério publicar arquivo estruturado do catálogo, a carga passa por **adapter** (§14).

---

## 6. Informação SINISA — o campo oficial

```text
Informação SINISA
├─ código
├─ nome
├─ definição oficial ....... texto ou referência controlada (§7)
├─ ressalvas ............... inclusões · exclusões · critério de medição · observações do glossário
├─ unidade
├─ bloco ................... do formulário
├─ período ................. total do ano · posição em data · média — como o glossário definir
├─ versão .................. versão do glossário a que pertence
└─ referência .............. normativa e documental — publicação, página, seção
```

🔴 **[DEC] Identidade = código + versão do glossário.** O mesmo código em duas versões são **duas definições**; compará-las é ato explícito, nunca presunção. [INF] Nada garante que um código mantenha o significado entre ciclos.

---

## 7. Texto oficial

| Situação | Exibição |
| -------- | -------- |
| Reprodução permitida | **Definição oficial integral**, com a referência |
| Reprodução não confirmada | **Referência** (publicação, página, seção, URL) **+ resumo controlado** — marcado *"resumo; não substitui a definição oficial"*, com autor e aprovação |

🔴 Nenhum resumo pode **mudar a semântica**. ⚠️ Se o glossário publicado pode ser reproduzido integralmente: `VALIDAÇÃO JURÍDICA NECESSÁRIA` (§21) — até lá, vale a segunda linha.

**[DEC] Código SINISA não é métrica interna.** Não existe, como decisão do produto:

```text
GTA1001 = VOL_AGUA_PRODUZIDA          ❌
```

A relação só pode existir se a **companhia** a criar explicitamente (§16). ⚠️ Códigos e números deste documento são **ilustrativos**: não se afirma aqui o que o código significa no glossário oficial.

---

## 8. Declaração — o valor informado

```text
Valor declarado (por campo × ciclo × prestador)
├─ valor ................... digitado pelo usuário
├─ unidade ................. a do glossário — conversão é memória de cálculo do usuário, nunca automática
├─ usuário · data e hora
├─ responsável ............. do formulário ou do bloco
├─ fonte ................... §10 — obrigatória para aprovar
├─ memória de cálculo ...... texto livre
├─ justificativa · observação · ressalva
├─ evidência ............... documento — classe Regulatório
├─ ciclo · versão do glossário
└─ estado e histórico ...... §9 — toda mudança é versão
```

---

## 9. Fluxo manual e estados

```text
Campo SINISA
    ↓ usuário lê a definição e as ressalvas
informa o valor manualmente
    ↓ anexa ou indica a fonte
valida
    ↓
aprova
    ↓
submete — no sistema oficial, fora do OpenGSAN (§14)
```

| Estado do valor | Significa |
| --------------- | --------- |
| **Pendente** | Sem valor |
| **Informado** | Valor e fonte registrados pelo informante |
| **Devolvido** | Revisor ou aprovador devolveu, **com motivo** |
| **Validado** | Passou pela validação formal e pela revisão |
| **Aprovado** | Aprovado pelo responsável |
| **Submetido** | Incluído no envio, com comprovante como evidência |

*Com ressalva* é **marca**, não estado. Depois de **Submetido**, qualquer mudança é **retificação** (§15).

**Validação formal** — bloqueia ou alerta; **nunca altera** o valor:

1. obrigatoriedade, tipo e unidade conforme o glossário;
2. regras de consistência **publicadas para o ciclo**, quando houver — carregadas como dado; o produto não inventa regra oficial;
3. **[PROP]** alerta de variação em relação à declaração do ciclo anterior — **só** quando a definição do campo não mudou entre as versões do glossário; se mudou, a comparação aparece como *não aplicável*.

**[PROP] Segregação de funções por padrão** — quem informa não aprova o mesmo valor. Acúmulo de papéis só por configuração explícita da companhia, registrado.

---

## 10. Fontes de apoio e dados auxiliares

**Fonte** — o que o usuário usou, registrado como referência tipada: relatório · consulta · sistema · planilha · medição · cálculo externo · **métrica do Gerencial** (código, versão, período, recorte e o valor **exibido**). A fonte dá rastreabilidade; **não produz valor**.

**Dado auxiliar** — informação exibida **ao lado** do campo, nunca dentro dele:

```text
REFERÊNCIA — NÃO É VALOR SINISA
Produção operacional 2026 · VOL_PRODUCAO_OPERACIONAL v3 · jan–dez · sistema S1
118.234.721 m³
⚠ referência interna; não representa automaticamente GTA1001
```

🔴 **[DEC] Pôr uma métrica ao lado de um campo já é afirmar alguma relação.** Por isso a associação campo ↔ referência é **configurada pela companhia** — sem regra, sem transferência de valor, com responsável, histórico e versão do glossário — ou **escolhida pelo usuário** na hora, consultando o [catálogo de métricas](../analytics/catalogo-de-metricas.md). ❌ O produto não distribui associações. ❌ Na V1, nenhuma ação transfere o número para o campo. A declaração do ciclo anterior também é dado auxiliar — rotulado e com a versão do glossário dela.

---

## 11. Tela do campo — interface conceitual

```text
GTA1001 — [nome oficial]                                     Ciclo SINISA 2027 · glossário água v2027
─────────────────────────────────────────────────────────────────────────────────────────────
Definição oficial   [texto ou referência controlada]
Ressalvas           [inclusões · exclusões · critério de medição]
Unidade             [unidade do glossário]

Valor informado                 [____________]
Fonte / memória de cálculo      [____________________________]
Evidência                       [anexar]
Responsável                     [...]

Dados auxiliares — REFERÊNCIA — NÃO É VALOR SINISA
• produção operacional acumulada: ...
• relatório X: ...
⚠ Dados auxiliares não representam automaticamente o valor oficial da informação SINISA.
```

❌ **Não permitido**, em nenhuma versão sem mapeamento ativo configurado pela companhia:

```text
GTA1001 = 118.234.721   [preenchido automaticamente]
```

[DEC] Formulário **server-driven**, sem SPA ([ADR-0007](../decisoes/0007-arquitetura-de-interface.md)); telas: painel do ciclo · formulário por bloco · campo · fila de revisão e aprovação · histórico e retificações · comprovantes.

---

## 12. Acompanhamento da coleta

```text
SINISA 2027 · ano-base 2026
Água          72% preenchido
Esgoto        61% preenchido
Validado      45%
Aprovado      20%
Pendências    18        Com ressalva   8        Prazo da coleta   [data do calendário do ciclo]
```

Por componente, formulário, bloco e responsável: preenchidos · pendentes · devolvidos · validados · aprovados · inconsistências · prazos.

🔴 **Nenhuma atualização diária automática de campo oficial.** O acompanhamento diário é do **fluxo** — quem falta, o que venceu —, não do valor. Produção, perdas, faturamento, arrecadação, OS, manutenção e paradas acompanhados diariamente pertencem ao [Gerencial & Analytics](../analytics/gerencial-analytics.md), **não** ao SINISA.

---

## 13. Rastreabilidade da declaração

| Pergunta | Registro |
| -------- | -------- |
| Quem informou · revisou · aprovou | Usuário e papel, em cada versão do valor |
| O que foi enviado | O conjunto submetido, **congelado** |
| Quando | Momento de cada passo |
| Para qual ciclo | Ciclo, componente, tipo de prestador |
| Com qual glossário | Versão, publicação e resumo criptográfico do documento |
| Com qual evidência | Documentos anexados e fonte declarada |

🔴 **[DEC]** Depois de submetido, o conjunto é **imutável**; muda só por retificação (§15).

---

## 14. Submissão, importação e exportação

```text
preenchimento ──► validação ──► aprovação ──► exportação / submissão
```

🔴 **[DEC] Submissão não automatizada por padrão.** O usuário transcreve ou envia no sistema oficial e registra o **comprovante** como evidência. **[DEC]** A credencial do prestador no sistema oficial **não é guardada** pelo OpenGSAN na V1 — nada a guardar sem envio automático; se um dia houver adapter, credencial **por ambiente e fora do código**.

**[PEND] PENDENTE POR FONTE** — o mecanismo oficial encontrado é o **formulário online** do sistema de coleta. Nenhum leiaute oficial de importação ou exportação por arquivo apareceu nas fontes consultadas. **Se existir**: adapter **do módulo SINISA**, sobre a infraestrutura de integração da Platform, acionado por pessoa; **o leiaute nunca entra no domínio**. O que a V1 exporta é a **declaração aprovada em formato próprio** — para transcrição e guarda —, não um leiaute oficial.

---

## 15. Retificação

Uma informação enviada e depois corrigida — por iniciativa própria, por manifestação na validação da versão preliminar ou por pedido do regulador — preserva:

| Preservado | Registro |
| ---------- | -------- |
| Declaração anterior | Intacta, com seu comprovante |
| Valor novo | Nova versão, com fonte e evidência |
| Motivo | Obrigatório — inclusive a origem do pedido |
| Responsável · data | De quem retificou e de quem aprovou |

🔴 **Não sobrescrever histórico.** A retificação usa **o glossário do ciclo retificado**, não o vigente.

---

## 16. Automação futura — mapeamento configurado pela companhia

⚠️ **Não entra na versão inicial nem na ordem inicial.** A arquitetura precisa apenas **não impedir**.

### 16.1 Mapeamento SINISA

```text
Mapeamento SINISA
├─ campo SINISA ................... código + versão do glossário
├─ versão do glossário
├─ fonte interna .................. métrica do catálogo, com versão
├─ regra .......................... ex.: MAP-SINISA-032
├─ filtros ........................ recorte — sistema, município, período
├─ agregação
├─ responsável pela configuração
├─ data de aprovação
├─ vigência
├─ status ......................... §16.2
└─ histórico
```

🔴 **[DEC] Automação é decisão da companhia.** Só a instituição pode declarar *"para o nosso contexto, este cálculo interno corresponde a este campo SINISA"* — **nunca o OpenGSAN universal**. O produto **não** distribui mapeamentos; um modelo trazido de outra instalação entra como **Rascunho**.

### 16.2 Estados

```text
RASCUNHO ──► EM VALIDAÇÃO ──► ATIVO ◄──► SUSPENSO
                  ▲             │            │
                  │             ▼            ▼
                  │   REVALIDAÇÃO NECESSÁRIA  INATIVO
                  └─────────────┘
```

🔴 **A única transição automática é para REVALIDAÇÃO NECESSÁRIA** — no sentido da segurança. **Nenhuma transição para ATIVO é automática.**

### 16.3 Modos

| Modo | Comportamento | Quando |
| ---- | ------------- | ------ |
| **MANUAL** | §3 | **V1 — único modo** |
| **SUGERIDO** | Exibe o valor calculado, a fonte e a regra — `[Aplicar valor]`; o usuário decide; aplicar registra a origem, e o usuário continua **informante** | Futuro — mapeamento ATIVO |
| **AUTOMÁTICO** | Preenche o valor como *Informado*, com a origem | Futuro — só com mapeamento **configurado, validado pela instituição, ativo, versionado e compatível com o ciclo e o glossário vigentes** |

**[DEC]** `autoPreenchimento = false` por padrão, **nunca** habilitado por atualização de versão — nenhuma migration altera essa configuração. **[PROP]** Mesmo no AUTOMÁTICO, revisão, aprovação e submissão continuam **humanas**.

**Override auditado**: alterar um valor vindo de SUGERIDO ou AUTOMÁTICO registra valor calculado, regra e versão, valor final, **justificativa obrigatória**, usuário e momento. O override **não altera** o mapeamento; [INF] overrides repetidos indicam mapeamento a revisar.

### 16.4 Mudança de glossário

Nova versão do glossário, novo ciclo ou mudança da definição oficial:

1. o mapeamento **não continua ativo** — vai para **REVALIDAÇÃO NECESSÁRIA** e não produz valor;
2. as referências de apoio do campo (§10) ficam **a revisar**;
3. as declarações anteriores ficam **intactas**, presas à versão delas.

### 16.5 Proibições permanentes

- ❌ Inferir `"volume produzido" ≈ "volume produzido SINISA"` por **texto semelhante**, heurística ou modelo.
- ❌ Mapeamento ativo por padrão, por atualização ou por importação.
- ❌ Valor automático sem mapeamento compatível com o glossário vigente.

---

## 17. SINISA × Gerencial & Analytics

```text
DADOS INTERNOS ──► GERENCIAL / ANALYTICS ──► servem como referência
                                                    ↓
                    USUÁRIO interpreta o glossário ──► preenche ──► valida ──► aprova ──► submete
```

| Regra | Consequência |
| ----- | ------------ |
| 🔴 **O SINISA não depende do Analytics** | O Workspace funciona com **zero** métricas; o Analytics só oferece referências |
| 🔴 **Métrica OpenGSAN ≠ campo SINISA** | Mesmo quando parecem equivalentes ([catálogo de métricas](../analytics/catalogo-de-metricas.md)) |
| O Gerencial não existe para preencher o SINISA | Existe para operar, medir, comparar, investigar e decidir |
| O Gerencial mostra o SINISA só como **progresso** | Nunca um valor calculado apresentado como "valor SINISA" |

---

## 18. Ownership

| Responsabilidade | Dono |
| ---------------- | ---- |
| Ciclo, catálogo carregado, declaração, aprovação, submissão, retificação | **Prestação de Informações** — Workspace SINISA |
| Guarda das evidências | Documentos e evidências — a capacidade guarda; o Workspace decide |
| Métricas de referência | **Gerencial & Analytics** — consultadas, nunca donas do valor declarado |
| Dados primários | Os módulos donos — inalterado |
| Arquivo oficial, se existir | Adapter **do módulo SINISA**, sobre a infraestrutura de integração da Platform |
| Mapeamento futuro | **A companhia** — configuração com responsável e aprovação |
| Canal | Backoffice server-driven (ADR-0007) |

---

## 19. Ordem

[DEC] **Trilha regulatória, fora das etapas numeradas.** O Workspace pode ser construído quando os **glossários necessários estiverem definidos** — sem depender do Analytics nem dos módulos de negócio. Depende de: identidade, concessão e auditoria (Etapa 0) · guarda de evidências · contexto institucional (convenção da Etapa 0). Precisa estar operante **antes do primeiro ciclo em que a instalação declare pelo OpenGSAN**. A automação **não** está na ordem inicial ([`dependencias-e-ordem-implementacao.md §24.3`](../modulos/dependencias-e-ordem-implementacao.md)).

---

## 20. Cenários

Requisitos nativos, oráculo N — [`testes/cenarios/regulatorio.md`](../testes/cenarios/regulatorio.md):

| Cenário | Protege |
| ------- | ------- |
| **CEN-REG-001** | Declaração manual rastreável; retificação sem sobrescrever |
| **CEN-REG-002** | Mudança de glossário preserva a declaração anterior |
| **CEN-REG-003** | Métrica interna não vira valor SINISA implicitamente |
| **CEN-REG-004** | Mapeamento futuro nunca ativado automaticamente — ⚠️ condicionado à automação |
| **CEN-REG-005** | Override futuro auditado — ⚠️ condicionado à automação |

---

## 21. Pendências

| # | Pendência | Natureza |
| - | --------- | -------- |
| 1 | Mecanismo oficial de importação ou exportação por arquivo | **PENDENTE POR FONTE** |
| 2 | Reprodução integral do texto do glossário | `VALIDAÇÃO JURÍDICA NECESSÁRIA` |
| 3 | Granularidade da declaração do prestador regional — por município ou consolidada | **PENDENTE POR FONTE** — manual do ciclo |
| 4 | Segregação de funções — padrão proposto a confirmar com as companhias | Decisão de produto |
| 5 | Estender o princípio da ADR-0009 ao SISAGUA e ao regulador local | Não decidido |
| 6 | Retenção da declaração e das evidências | **PENDENTE POR FONTE** |

---

## Fontes

Oficiais — lidas por resumo de busca, host bloqueado:

- [SINISA — Ministério das Cidades](https://www.gov.br/cidades/pt-br/acesso-a-informacao/acoes-e-programas/saneamento/sinisa)
- [Área do Prestador](https://www.gov.br/cidades/pt-br/acesso-a-informacao/acoes-e-programas/saneamento/sinisa/area-do-prestador)
- [Cidades abre período de coleta de dados para o Sinisa 2026](https://www.gov.br/cidades/pt-br/assuntos/noticias-1/noticia-mcid-n-2166)
- [Glossário de informações — esgotamento sanitário](https://www.gov.br/cidades/pt-br/acesso-a-informacao/acoes-e-programas/saneamento/sinisa/area-do-prestador/arquivos/glossario_informacoes_sinisa_2025_esgotamento_sanitario.pdf)
- [Glossário de termos técnicos — abastecimento de água](https://www.gov.br/cidades/pt-br/acesso-a-informacao/acoes-e-programas/saneamento/sinisa/area-do-prestador/arquivos/glossario_termos_tecnicos_sinisa_2024_agua.pdf)
- [Manual de preenchimento — prestadores regionais de água e esgoto](https://www.gov.br/cidades/pt-br/acesso-a-informacao/acoes-e-programas/saneamento/sinisa/area-do-prestador/arquivos/MANUAL_SINISA_2024_ANO2_REGIONAIS_AGUA_ESGOTO.pdf)
- [Planilha de indicadores de esgotamento sanitário — retificação](https://www.gov.br/cidades/pt-br/acesso-a-informacao/acoes-e-programas/saneamento/sinisa/arquivos/SINISA_ESGOTO_Indicadores_Prestadoreslocaiseregionais_2023_Retificacao1.xlsx)

Secundárias:

- [Instituto Água e Saneamento — início da coleta de 2026](https://www.aguaesaneamento.org.br/en/news/sinisa-inicia-coleta-de-dados-de-saneamento-para-2026/)
- [TCE-SP — comunicado sobre o SINISA](https://www.tce.sp.gov.br/legislacao/comunicado/sistema-nacional-informacoes-sobre-saneamento-basico-sinisa)
- [TCE-PI — prorrogação da coleta](https://www.tcepi.tc.br/prazo-para-preenchimento-de-dados-no-sinisa-e-prorrogado-ate-13-de-setembro/)
- [AAM — prazo adicional da coleta](https://aam.org.br/sinisa-prazo-adicional-para-conclusao-do-envio-de-dados-termina-em-23-de-setembro/)
