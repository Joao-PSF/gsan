# Gestão de Ativos — Visão Alvo do OpenGSAN

> **Fase 0 — revisão controlada de escopo (21ª execução, 2026-09-28).** 🔴 **Decisão do responsável do projeto**: o OpenGSAN terá **Gestão de Ativos nativa** — registrada na [ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md). Este documento define a **visão conceitual alvo** do domínio: o que ele é, do que é dono, como se relaciona com Operacional, Redes/GIS, Atendimento e Execução, Micromedição e Contabilização.
>
> 🆕 **Adendo pós-Fase 0 (2026-09-29)**: o **PCM** — backlog, planejamento, programação, controle e indicadores — é capacidade deste domínio ([`pcm.md`](pcm.md)); a indisponibilidade que a manutenção exige é pedida à Gestão Operacional como **Parada** ([`paradas-interrupcoes.md`](paradas-interrupcoes.md)). Pontos tocados: §10, §11, §15, §17.
>
> ⚠️ **Não decide** schema, tabelas, chaves, PostGIS, sincronização, eventos ou REST. **Não modela** o domínio em profundidade — reconhece, delimita e fixa as regras que impedem decisões ruins mais tarde.

---

## 1. Evidência e método

Marcas: **[GSAN]** · **[REF]** · **[INF]** · **[PROP]** · **[DEC]** · **[PEND]** — definidas em [`modulos/financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

| Fonte | Papel | Limite |
| ----- | ----- | ------ |
| **Código público do GSAN** | 🔴 O GSAN tem **objetos físicos** — o **hidrômetro**, com ciclo de vida completo na Micromedição (aquisição, nota fiscal, garantia, armazenagem, movimentação, instalação, revisão, baixa com motivo), e os elementos da estrutura operacional —, mas **não possui um modelo corporativo unificado de gestão de ativos**: busca por bomba, válvula, elevatória, adutora, tubulação, patrimônio, imobilizado e depreciação em `src/gcom` (`*.java`) retorna **0 arquivos** para cada termo ([`operacional.md §8`](../modulos/operacional.md)) | **Não existe oráculo GSAN** para a gestão corporativa de ativos — nenhuma equivalência será fabricada. O hidrômetro é **referência de requisitos**, e continua da Micromedição (§9) |
| **Banco público versionado** — schema `operacao` do satélite `gsan-operacional` | **Fonte de requisitos**: o ecossistema GSAN já precisou de identidade patrimonial, instalação e aferição de instrumentos (§2.2) | Satélite sem código público; nada ali é oráculo |
| **openMAINT / CMDBuild** | [REF] benchmark de CMMS/EAM aberto | Fontes oficiais localizadas por busca; ⚠️ leitura direta **bloqueada** pela política de rede desta sessão |
| **Giswater** | [REF] gestão de ativos **orientada à rede** | Idem |

---

## 2. A decisão e o que a sustenta

### 2.1 [DEC] Gestão de Ativos é nativa do OpenGSAN

| Alternativa | Por que não é o dono dos ativos |
| ----------- | ------------------------------- |
| **Giswater** | [REF] Seu módulo de gestão de ativos é voltado à **rede** — pontuação de prioridade e análise de rupturas ([FOSS4G Europe 2025](https://talks.osgeo.org/foss4g-europe-2025/talk/ETPJKW/)). Eletromecânicos, instrumentação e instalações não são seu foco, e 🔴 o OpenGSAN **não pode depender obrigatoriamente** de uma ferramenta externa para ter identidade de ativo |
| **openMAINT / EAM externo** | [REF] É CMMS completo, com **suas próprias ordens de trabalho**, estoque e contratos ([openMAINT](https://www.openmaint.org/en/product/features)). Adotá-lo como dono **duplicaria a OS** e a identidade — as duas coisas que esta decisão proíbe |
| **Não ter o domínio** | Manutenção de bombas, válvulas e instrumentos ficaria sem dono e reapareceria como **solução ad hoc** — exatamente o que o satélite do GSAN fez (§2.2) |

### 2.2 [GSAN] A necessidade já existia — resolvida para uma classe no núcleo e, para as demais, fora dele

| Evidência (schema `operacao`, dump versionado) | O que mostra | Classe |
| ---------------------------------------------- | ------------ | ------ |
| `macro_medidor` com fabricante, modelo, **nº de série**, **tombamento**, princípio, faixa, sinal; `macro_medidor_afericao` | Instrumento com **identidade patrimonial** e **histórico de aferição** | **A** — necessidade geral |
| `eta_medidor`, `eeab_medidor`, `eeat_medidor` com **data de instalação e TAG** | **Equipamento × posição de instalação** — o mesmo padrão de *hidrômetro × instalação* da Micromedição | **A** conceito · **D** forma: **uma tabela por tipo de unidade** — e, na reservação, colunas da própria unidade |
| 🆕 `Hidrometro` com data de aquisição, nota fiscal, garantia, situação, **local de armazenagem**, **movimentação** com motivo, revisão e **baixa com motivo** (núcleo público, Micromedição) | 🟢 O GSAN **já gere o ciclo de vida de um ativo físico** — mas de **uma só classe**, dentro de um módulo comercial | **A** — o padrão a generalizar |
| Conjunto motor-bomba como **colunas da estação** (`*_cmb`, `*_cmbpotencia`, `*_cmbvazao`…) e **horas de operação** por estação | 🔴 A bomba **não tem identidade**: não é possível saber qual bomba parou, qual foi trocada, qual acumula horas | **D** — representação inadequada |

🔵 [INF] **O padrão estrutural "equipamento × instalação", que o GSAN aplica ao hidrômetro, é o mesmo que a gestão de ativos precisa** — generalizado para *ativo × localização funcional* (§6).

---

## 3. Responsabilidade

**Gestão de Ativos** é o domínio dono da **coisa física** que a companhia opera e mantém: sua **identidade**, **classe**, **composição**, **localização funcional**, **estado no ciclo de vida**, **condição**, **criticidade** e **histórico técnico** — inclusive de manutenção e custos técnicos.

| É dono de | Não é dono de |
| --------- | ------------- |
| Identidade corporativa do ativo e suas referências externas | **Geometria e topologia** → Redes/GIS |
| Classe, atributos técnicos, composição | **Ordem de serviço e execução** → Atendimento e Execução |
| Localização funcional e histórico de instalação | **Estrutura operacional lógica** → Gestão Operacional |
| Ciclo de vida, condição, criticidade | **Hidrômetro comercial** → Micromedição |
| Planos de manutenção e necessidades geradas | **Imobilizado, depreciação, razão** → ERP (§12) |
| Histórico técnico: falhas, causas, intervenções, custos técnicos | **Medições de telemetria em tempo real** → Telemetria (futuro) |

---

## 4. Identidade

🔴 [DEC] **Uma identidade corporativa única por ativo** — o mesmo `AT-123` reconhecido por Ativos, Redes/GIS, QGIS, Telemetria, OS e Analytics.

| A identidade **não é** | Por quê |
| ---------------------- | ------- |
| O identificador da **geometria** | Uma tubulação pode ser redesenhada sem deixar de ser o mesmo ativo; um ativo pode não ter geometria |
| A **TAG** operacional | A TAG identifica a **posição** (localização funcional), não a peça — a bomba reserva que assume a posição herda a TAG, não a identidade |
| O **número de série** | Atributo do fabricante; pode faltar ou repetir entre fabricantes |
| O **tombamento** | Identificador **patrimonial** do ERP — referência externa, não identidade técnica |

🔵 [PROP] Referências externas (geometria no Giswater, número patrimonial no ERP, ponto de telemetria) são **vínculos com dono explícito**, nunca cópias sincronizadas sem decisão — regra da [`gis-redes-ativos.md §7`](../arquitetura/gis-redes-ativos.md).

---

## 5. Classe

🔴 [DEC] **Não há uma classe física única.** A taxonomia é **dado** — cada classe declara seus atributos, os estados de ciclo de vida que usa e os tipos de manutenção aplicáveis.

| Família | Exemplos | Particularidade |
| ------- | -------- | --------------- |
| **Lineares** | Redes, adutoras, coletores, ramais, trechos | Extensão; geometria linear; manutenção por trecho |
| **Pontuais hidráulicos** | Válvulas/registros, hidrantes, ventosas, descargas, poços de visita | Posição na topologia; manobra |
| **Eletromecânicos** | Conjuntos motor-bomba, motores, painéis, inversores | Horas de operação; manutenção preventiva e preditiva |
| **Instrumentação** | Macromedidores, sensores de pressão e nível, analisadores | 🔴 **Calibração/aferição**; ponto de medição para Telemetria |
| **Instalações** | ETA, ETE, elevatórias, reservatórios, poços, captações | Composição: contêm outros ativos |

⚠️ O **hidrômetro comercial** não entra nessa taxonomia como ativo de posse de Ativos — §9.

---

## 6. Hierarquia e localização funcional

🔴 **Duas relações diferentes que o modelo não pode fundir:**

```text
É PARTE DE (composição física)            ESTÁ LOCALIZADO EM (posição funcional)
────────────────────────────────          ──────────────────────────────────────
rotor ── é parte de ──► bomba             bomba AT-123 ── instalada em ──► EEAT-03 / posição CMB-2
bomba ── é parte de ──► conjunto CMB      (de 10/03 a 22/08; depois, AT-777)
```

| Conceito | O que é | Evidência |
| -------- | ------- | --------- |
| **Composição** | Estrutura física: do que um ativo é feito | [INF] |
| **Localização funcional** | 🔴 **Posição onde uma função é exercida** na operação — existe **mesmo sem ativo instalado** e sobrevive às trocas | [INF] generalização do padrão *equipamento × instalação* (§2.2) |
| **Histórico de instalação** | Qual ativo ocupou qual posição, de quando a quando | [GSAN] padrão da Micromedição (`HidrometroInstalacaoHistorico`) e do satélite (`eta_medidor`) |

🔵 [PROP] A localização funcional é **o ponto de encontro** com a Gestão Operacional (uma posição pertence a uma unidade operacional) e com Redes/GIS (uma posição pode ter geometria). A peça que a ocupa é de Ativos.

---

## 7. Estado, condição e criticidade

| Conceito | Natureza | Pergunta |
| -------- | -------- | -------- |
| **Estado** | Posição no ciclo de vida (§8) — discreta | *Em que fase da vida o ativo está?* |
| **Condição** | Avaliação técnica com **data, método e evidência** — escala da companhia | *Quão bem está?* |
| **Criticidade** | Consequência da falha combinada com a probabilidade | *Quanto importa se falhar?* — base de priorização |

🔴 [PROP] Os três têm **histórico**: uma condição é uma **observação datada**, não um campo sobrescrito. É o mesmo antipadrão que o GSAN teve com espera e reiteração no Atendimento (campos que sobrescrevem).

---

## 8. Ciclo de vida

```text
planejado → adquirido → recebido → instalado → em operação ⇄ em manutenção
                                                    │
                                                    ▼
                                             fora de operação → substituído → baixado
```

| Regra | |
| ----- | - |
| 🔴 **Nem toda classe usa todos os estados** | Um trecho de rede não é "recebido em almoxarifado"; um instrumento é |
| Cada transição tem **data, autoria e evidência** | Auditoria de negócio, não só técnica |
| *instalado* e *substituído* **referenciam a localização funcional** | §6 |
| ⚠️ *baixado* é **baixa técnica** | ≠ **baixa patrimonial** do imobilizado, que é do ERP (§12) |

---

## 9. Hidrômetro comercial

🔴 [DEC] **O hidrômetro comercial é da Micromedição** — identidade, instalação no imóvel, leitura, substituição para fins de faturamento.

| Gestão de Ativos pode | Gestão de Ativos não pode |
| --------------------- | ------------------------- |
| **Referenciar** o hidrômetro | Manter **estado concorrente** do mesmo hidrômetro |
| **Consultar** instalação e histórico | Instalar, substituir ou retirar hidrômetro |
| **Inventariar** o parque (quantidade, idade, marca) | Ser dona da marca ou do modelo — [`operacional.md §7`](../modulos/operacional.md) mostra o que acontece quando o dono se confunde |

⚠️ [GSAN] **Macromedidor comercial ≠ macromedidor operacional.** `Hidrometro.indicadorMacromedidor` é medição **comercial** de rateio de condomínio — Micromedição. O macromedidor de entrada de setor ou DMC (satélite, `macro_medidor`) é **instrumentação** — Ativos.

---

## 10. Manutenção

| Elemento | O que registra |
| -------- | -------------- |
| **Tipos** | Preventiva · corretiva · preditiva · inspeção · calibração · substituição |
| **Plano** | Periodicidade (tempo, horas de operação ou condição) · checklist · classe ou ativo alvo |
| **Necessidade** | Gerada pelo plano, por condição ou por falha |
| **Resultado técnico** | Falha · causa · componente · material · mão de obra · tempo parado · custo |

🔵 [INF] As horas de operação que o satélite registrava **por estação** (§2.2) são o insumo natural de manutenção por horas — mas só funcionam se cada bomba tiver identidade.

🆕 **Adendo pós-Fase 0**: esta tabela era a base, não um PCM. O fluxo completo — *necessidade → backlog → planejamento → programação → OS → execução → controle → histórico* —, os estados do backlog e os indicadores estão em [`pcm.md`](pcm.md).

---

## 11. 🔴 Sem OS paralela

[DEC] **Gestão de Ativos não tem ordem de trabalho própria.** A execução é sempre **OS do Atendimento e Execução**.

```text
Ativos                           Atendimento e Execução                Ativos
──────                           ──────────────────────                ──────
plano / condição / falha
        │
        ▼
necessidade de manutenção
        │  solicita execução
        └──────────────────────► OS (tipo de serviço, ativo ou
                                 localização funcional de referência)
                                         │ programa · executa · encerra
                                         ▼
                                 resultado da execução ─────────────► atualiza histórico,
                                 (falha, causa, material,               condição, custos,
                                  horas, tempo parado)                  estado do ciclo de vida
```

🔵 É o **contrato central do OpenGSAN** — *solicita × aplica* ([visão conceitual §14.3](visao-conceitual-opengsan.md)) — aplicado nos dois sentidos: Ativos **solicita** execução; o Atendimento **executa**; o resultado volta e **Ativos aplica** ao seu próprio estado.

🆕 **Com o PCM** o contrato não muda: a necessidade passa por backlog, planejamento e programação **antes** da OS, e toda OS continua referenciando a necessidade ([`pcm.md §7`](pcm.md#7-sem-ordem-de-trabalho-paralela)). 🔴 **Programação do PCM ≠ programação da OS**: o PCM decide **janela e prioridade** da manutenção; o Atendimento **distribui e sequencia** as OS no roteiro das equipes — a programação de OS que o legado já tem ([`pcm.md §5`](pcm.md#5-programação)).

⚠️ [REF] O Giswater também organiza **visitas** e **campanhas de trabalho** ([FOSS4G Europe 2025](https://talks.osgeo.org/foss4g-europe-2025/talk/ETPJKW/); [integração com CRM/hidrômetro](https://github.com/giswater/api/releases/tag/v1.8.0)). [PEND] Se usados, são **registro técnico de inspeção** vinculado à OS — nunca uma segunda OS.

---

## 12. 🔴 Custos do ativo × contabilidade corporativa

| Plano | Dono | Conteúdo |
| ----- | ---- | -------- |
| **Custo técnico do ativo** | **Gestão de Ativos** | Custo de cada intervenção (material, mão de obra, serviço contratado), acumulado por ativo, classe e localização — **para decidir** reparar ou substituir |
| **Contabilização subsidiária** | **Contabilização** ([`financeiro-contabilizacao.md`](../modulos/financeiro-contabilizacao.md)) | Fatos contábeis **do saneamento comercial** — não inclui imobilizado |
| **Imobilizado, depreciação, baixa patrimonial, razão** | **ERP corporativo** | Fora do OpenGSAN |

🔴 [PROP] **Custo do ativo ≠ contabilidade corporativa.** O OpenGSAN **não deprecia** e **não mantém razão**. Se a companhia quiser, o custo técnico é **exportado** ao ERP por adaptador (Integrações), e o número patrimonial do ERP é **referência externa** do ativo (§4).

---

## 13. Estoque, peças, contratos e fornecedores

| Capacidade | Classificação | Razão |
| ---------- | ------------- | ----- |
| Material **consumido** numa OS | **Necessário** — registrado pela execução | O custo técnico (§12) depende dele |
| Garantia do ativo | **Necessário** — atributo do ativo [PROP] | Decide reparo × acionamento do fornecedor |
| Estoque de peças de reposição | **Pendente** — módulo futuro ou integração com ERP | Nenhuma evidência no GSAN; não construir sem necessidade demonstrada |
| Compras | **Integração com ERP** | Fora do domínio |
| Contratos de manutenção e fornecedores | **Pendente** — módulo futuro ou ERP | O catálogo já registra *gestão de contrato de empresa de campo* como módulo opcional ([`funcionalidades-futuras.md §8.4`](../modulos/funcionalidades-futuras.md)) |

---

## 14. Benchmark EAM — requisitos, não modelo

| Referência | O que ensina | O que **não** copiar |
| ---------- | ------------ | -------------------- |
| [REF] **openMAINT** ([funcionalidades](https://www.openmaint.org/en/product/features); [visão geral CMDBuild](https://docs.cmdbuild.org/docs/overview/vertical-solutions/openmaint)) | Inventário de ativos e componentes; manutenção preventiva e corretiva; almoxarifado; orçamento, custos, fornecedores e contratos; energia; GIS e BIM | O foco em **facilities**; **suas ordens de trabalho**; seu modelo de dados |
| [REF] **CMDBuild** ([produto](https://www.cmdbuild.org/en/products/cmdbuild)) | Classes e atributos **configuráveis** — a taxonomia como dado | Ser plataforma genérica de CMDB |
| [REF] **Giswater — Asset Management** ([FOSS4G Europe 2025](https://talks.osgeo.org/foss4g-europe-2025/talk/ETPJKW/)) | Priorização de renovação de rede por **pontuação** e **análise de rupturas** | Tornar-se o dono de todos os ativos |

🔵 [INF] O denominador comum: **identidade + classe configurável + localização + histórico de manutenção + custo**. É o que este documento fixa — nada além.

---

## 15. Fronteiras

| Com | O que atravessa | Dono |
| --- | --------------- | ---- |
| **Gestão Operacional** | Unidade operacional ↔ localização funcional | Operacional (unidade) · Ativos (posição e peça) |
| **Redes / GIS** | Geometria e topologia do ativo linear ou pontual | **Redes/GIS** (espacial) · Ativos (identidade) — matriz por atributo em [`gis-redes-ativos.md`](../arquitetura/gis-redes-ativos.md) |
| **Atendimento e Execução** | Necessidade → OS → resultado | Ativos solicita · **Atendimento executa** · Ativos aplica |
| **Micromedição** | Hidrômetro comercial | **Micromedição** — Ativos só referencia |
| **Contabilização / ERP** | Custo técnico; número patrimonial | Ativos (custo técnico) · **ERP** (imobilizado) |
| **Telemetria** (futuro) | Ponto de medição ↔ instrumento | Ativos (instrumento) · Telemetria (série de medições) |
| 🆕 **Gestão Operacional — Parada** | Necessidade que exige indisponibilidade → pedido de janela → Parada aprovada | **Gestão Operacional** (Parada) · Ativos/PCM (necessidade) — [`paradas-interrupcoes.md`](paradas-interrupcoes.md) |
| **Analytics** — 🆕 **Gerencial & Analytics** | Condição, falhas, custos · 🆕 indicadores do PCM | Analytics consome fatos publicados — [catálogo de métricas](../analytics/catalogo-de-metricas.md) |

---

## 16. O que esta visão não decide

Schema · tabelas · chaves · PostGIS · sincronização · eventos · REST · ferramenta de campo · se o Giswater será usado por uma instalação. 🔴 **Giswater não é dependência obrigatória** ([ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md)).

---

## 17. Pendências

| # | Pendência |
| - | --------- |
| 1 | Taxonomia inicial de classes e atributos mínimos por classe |
| 2 | Escala de condição e método de criticidade — padrão da companhia ou do produto |
| 3 | Estoque de peças: módulo futuro ou integração com ERP |
| 4 | Contratos de manutenção e fornecedores |
| 5 | Papel das visitas e campanhas do Giswater quando a instalação o usar |
| 6 | Posição de Gestão de Ativos na ordem de implementação — **trilha estrutural**, depois da Etapa 2 ([`dependencias-e-ordem-implementacao.md`](../modulos/dependencias-e-ordem-implementacao.md)) — 🆕 o PCM vem depois de Ativos + OS (§24.2) |
| 7 🆕 | Capacidade de equipe, calendário de trabalho e escala de prioridade do PCM ([`pcm.md §12`](pcm.md#12-pendências)) |
