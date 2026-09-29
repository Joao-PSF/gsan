# Arquitetura — Redes, GIS e Ativos

> **Fase 0 — revisão controlada de escopo (21ª execução, 2026-09-28).** Define **papéis e ownership** entre Gestão de Ativos, Redes/GIS, Gestão Operacional e Atendimento e Execução, e o papel de Giswater, QGIS, QGIS Server, QField e EPANET/SWMM. Responde às perguntas do critério de saída da revisão (§11).
>
> 🆕 **Adendo pós-Fase 0 (2026-09-29)**: *mincut* × **Parada** — o cálculo de isolamento é de Redes/GIS; a Parada é da Gestão Operacional ([`paradas-interrupcoes.md`](../dominio/paradas-interrupcoes.md)). Pontos tocados: §6, §8, §12, §13.
>
> ⚠️ **Não decide** schema, tabelas, chaves, PostGIS, sincronização, eventos nem REST. Decisão estrutural: [ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md).

---

## 1. Evidência

Marcas: **[GSAN]** · **[REF]** · **[INF]** · **[PROP]** · **[DEC]** · **[PEND]** — definidas em [`modulos/financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

| Fonte | O que forneceu | Limite |
| ----- | -------------- | ------ |
| [GSAN] `ProcessarRequisicaoGisAction` (`gcom.gui.integracao`) | Um **GIS externo** abre a tela de **registro de RA** já preenchida — coordenadas norte/leste, logradouro, imóvel, localidade, setor, **diâmetro** — e recebe listas de RA para exibir; autenticação por assinatura DSA (`:101`, `:113`, `:162`) | É **integração**, não domínio — [`integracoes.md`](../modulos/integracoes.md), achado 16 de [`riscos-identificados.md`](../seguranca/riscos-identificados.md) |
| [GSAN] `RegistroAtendimento` | Coordenadas, indicador de coordenada sem logradouro e **diâmetro** no próprio RA | — |
| [GSAN] Núcleo público | 🔴 **Nenhuma geometria nem topologia**; objetos físicos existem (hidrômetro com ciclo de vida, estrutura operacional), mas **nenhum modelo corporativo unificado de gestão de ativos** ([`operacional.md §8`](../modulos/operacional.md)) | Sem oráculo GSAN para Redes/GIS e para a gestão corporativa de ativos |
| [REF] GeoSan | GIS histórico do ecossistema GSAN: integra o cadastro de **redes e consumidores** ao cadastro comercial e leva o **consumo do GSAN como demanda dos nós** para simulação no EPANET ([Nexus — GeoSan](https://www.nexusbr.com/es/geosan); [Portal do Software Público](https://softwarepublico.gov.br/social/gsan)) | Resumo de mecanismo de busca |
| [REF] Giswater, QGIS Server, QField | Fontes oficiais (§4) | ⚠️ Hosts de documentação **bloqueados** pela política de rede desta sessão — conteúdo obtido por resumo de mecanismo de busca sobre as páginas oficiais |

🔵 [INF] **Precedente**: no ecossistema GSAN, o **GIS de redes sempre foi outro sistema**, integrado por **consumidor ↔ nó** e **consumo → demanda**. O OpenGSAN não inventa essa separação — a formaliza.

---

## 2. Quatro coisas que não se confundem

| Conceito | O que é | Exemplo | Dono |
| -------- | ------- | ------- | ---- |
| **Ativo** | A **coisa física**, com identidade, estado, condição e manutenção | A válvula `AT-123`, de ferro fundido, instalada em 2019 | **Gestão de Ativos** |
| **Geometria** | A **representação espacial** | O ponto (x, y) da válvula; o traçado de uma adutora | **Redes/GIS** |
| **Topologia** | A **conectividade** | A válvula separa os arcos A e B; fechá-la isola 312 ligações | **Redes/GIS** |
| **Simulação** | O **modelo calculado** num cenário | Pressão prevista no nó N às 7 h do cenário "pico de verão" | **Engenharia/Simulação** — EPANET/SWMM |

🔴 Um ativo pode **não ter geometria** (um inversor dentro de um painel); uma geometria pode **não ser ativo** (um polígono de DMA); a topologia pode **mudar sem que o ativo mude** (uma nova derivação); uma simulação **não é estado** de nada — é cenário.

---

## 3. Três eixos territoriais

```text
Cadastro territorial comercial   Localidade · Setor Comercial · Quadra · Face · Rota      → Cadastro
Estrutura operacional            Sistema · Setor/Zona · Distrito · Zona de pressão · Bacia → Gestão Operacional
Geometria / topologia            polígonos, traçados, nós, arcos, zonas derivadas da rede   → Redes/GIS
```

🟢 [GSAN] O GSAN **fundiu** os dois primeiros pela quadra (distrito e bacia como colunas; DMC na face desde 2023) e não tem o terceiro no núcleo — [`operacional.md §3, §10`](../modulos/operacional.md).

[REF] No Giswater, zonas como **DMA, SECTOR, DQA e PRESSZONE** são calculadas por **análise de grafo** da rede, e o algoritmo pode gravar `dma_id`, `presszone_id` e `sector_id` em nós, arcos e ligações ([Mapzones algorithm](https://github.com/Giswater/giswater_dbmodel/wiki/Mapzones-algorithm)).

🔵 [INF] **O pertencimento de uma ligação a uma zona é fato derivável da rede** — não um atributo a digitar na quadra. Mas a **identidade e o significado da unidade** (nome, unidade responsável, calendário) continuam sendo da Gestão Operacional. Ver matriz (§6).

---

## 4. Papel de cada ferramenta

| Ferramenta | O que é | Papel no OpenGSAN | Marca |
| ---------- | ------- | ----------------- | ----- |
| **Giswater** | Plugin QGIS + PostgreSQL/PostGIS + pgRouting; inventário e topologia de redes de água e esgoto; zonas por grafo; **mincut** (válvulas a fechar e área afetada); visitas de O&M; planejamento por setores de obra; gestão de ativos **de rede**; exportação para **EPANET** e **SWMM**; vínculo de ligação ao cliente por código ([software](https://www.giswater.org/software/?lang=en); [docs](https://github.com/Giswater/docs); [mincut](https://docs.giswater.org/master/en/docs/giswater/for-users/dialogs/mincut.html); [API v1.8.0](https://github.com/giswater/api/releases/tag/v1.8.0)) | 🔴 **Ferramenta de referência preferencial para Redes/GIS e Engenharia**: **reutilizar** o que ela faz, **integrar** por contrato, **referenciar** pela identidade corporativa, **não duplicar**. ⚠️ **Não é** o EAM do OpenGSAN e **não é dependência obrigatória** | [REF] + [DEC] |
| **QGIS** | SIG desktop | **Ferramenta** de edição, análise e cartografia — cliente, não sistema de registro | [DEC] |
| **QGIS Server** | Publica projetos QGIS por OGC — WMS, WMTS, WFS, WFS-T, WCS, OGC API Features ([serviços](https://docs.qgis.org/3.44/en/docs/server_manual/services.html)) | **Candidata** a camada de publicação cartográfica | [REF] + [PEND] — **nada decidido** |
| **QField** (+ QFieldCloud) | Cliente de campo do QGIS: formulários, edição offline, fotos, GNSS, sincronização ([QField](https://qfield.org/); [QFieldCloud](https://qfield.cloud/)) | **Cliente de campo** para cadastro técnico e inspeção. 🔴 **A OS continua sendo do Atendimento e Execução** — QField pode ser o instrumento que a executa, nunca o dono | [REF] + [PROP] |
| **EPANET / SWMM** | Motores de simulação hidráulica (água / drenagem e esgoto) | **Via Giswater**. 🔴 O OpenGSAN **não constrói simulador próprio** | [REF] + [DEC] |

🔵 [INF] **Sem Giswater**, uma instalação OpenGSAN continua tendo ativos, OS, estrutura operacional e **localização pontual** de demandas e ativos; perde topologia, zonas derivadas, mincut e simulação. É o que "não é dependência obrigatória" significa na prática.

---

## 5. Identidade corporativa única

🔴 [DEC] O mesmo ativo — `AT-123` — é reconhecido por **Ativos, Redes/GIS (Giswater), QGIS, Telemetria, OS e Analytics**.

[PROP] **Gestão de Ativos emite a identidade**; cada ferramenta pode manter seu identificador interno, mas guarda a **referência** à identidade corporativa. A identidade **não é** o identificador da geometria, a TAG, o número de série nem o tombamento ([`gestao-de-ativos.md §4`](../dominio/gestao-de-ativos.md)).

---

## 6. 🔴 Matriz de ownership por atributo

Formas de consumo (§7): **R** referência · **P** projeção · **S** snapshot · **C** cache.

| Atributo | Dono (único escritor) | Consumidores (forma) | Marca |
| -------- | --------------------- | -------------------- | ----- |
| Identidade corporativa do ativo | **Gestão de Ativos** | Todos (R) | [DEC] |
| Classe e atributos técnicos (material, diâmetro nominal, fabricante, potência) | **Gestão de Ativos** | Redes/GIS, Engenharia (P) | [PROP] |
| Estado no ciclo de vida | **Gestão de Ativos** | Redes/GIS — um ativo *fora de operação* muda a topologia operante (P) | [PROP] |
| Condição, criticidade | **Gestão de Ativos** | Engenharia — priorização de renovação; Analytics (P) | [PROP] |
| Plano, necessidade e histórico de manutenção; custo técnico | **Gestão de Ativos** | Analytics (P) · ERP — custo (exportação) | [PROP] |
| Geometria (ponto da válvula, traçado da tubulação) | **Redes/GIS** | Ativos, QGIS, QField, Analytics (R/P) | [PROP] |
| Topologia (conectividade) | **Redes/GIS** | Engenharia, mincut (—) | [PROP] |
| 🆕 Análise de isolamento (*mincut*) — válvulas, elementos afetados, extensão, estado da análise | **Redes/GIS** (Giswater, quando usado) | Gestão Operacional — Parada (S: **snapshot versionado** do impacto, com data do cálculo e versão da topologia) | [REF] + [DEC] |
| 🆕 **Parada** — identidade, tipo, estado, previsão, realizado | **Gestão Operacional** | Redes/GIS (R — comanda a análise), Notificação (R), Atendimento (R), Gerencial (P) | [DEC] |
| Zona a que pertence uma ligação (DMA, setor, zona de pressão) | **Redes/GIS** — derivada da rede | Gestão Operacional (P) | [PROP] |
| Identidade, nome e responsável de uma unidade operacional | **Gestão Operacional** | Atendimento (R), Analytics (R) | [PROP] |
| Correspondência território comercial ↔ unidade operacional | **Gestão Operacional** — mantida **ou** derivada de geometria | Atendimento, Faturamento (P) | [PEND] |
| Calendário operacional | **Gestão Operacional** | Atendimento (P) | [PROP] |
| Qualidade da água distribuída | **Gestão Operacional** | Emissão da conta (S) | [PROP] |
| OS — programação, execução, resultado | **Atendimento e Execução** | Ativos — resultado (R); QField — cliente | [DEC] |
| Localização da demanda (coordenada do RA) | **Atendimento e Execução** | Redes/GIS — exibição (R) | [GSAN] + [PROP] |
| Diâmetro informado no RA | **Atendimento** — como **contexto da demanda** | — (S) — ⚠️ o diâmetro **autoritativo** é o do ativo | [GSAN] + [INF] |
| Hidrômetro comercial | **Micromedição** | Ativos — inventário; Giswater — vínculo por cliente (R) | [DEC] |
| Ligação comercial — situação, faturabilidade | **Cadastro** | Redes/GIS (R) | [GSAN] |
| Ramal físico — geometria e conectividade | **Redes/GIS** | Cadastro (R) | [PROP] · [PEND] correspondência com a ligação comercial |
| Consumo por ligação | **Micromedição** | Engenharia — demanda dos nós (P) — precedente GeoSan | [REF] + [PROP] |
| Resultado de simulação | **Engenharia/Simulação** | Operacional, Analytics (S por cenário) | [PROP] |
| Medições de telemetria | **Telemetria** (futuro) | Operacional, Ativos (P) | [PROP] |

---

## 7. 🔴 Nunca "copiar e sincronizar" sem decisão

Todo atributo que atravessa ferramentas tem **um** dono e **uma** forma de consumo declarada:

| Forma | Definição | Pode ser editada pelo consumidor? |
| ----- | --------- | --------------------------------- |
| **Referência** | Guarda só a identidade; lê do dono quando precisa | Não |
| **Projeção** | Visão derivada, **reconstruível** a partir do dono | Não |
| **Snapshot** | Cópia **congelada**, com data e finalidade — como o contexto da conta | Não — é histórico |
| **Cache** | Cópia **descartável**, com validade | Não |

🔴 [DEC] **Proibido**: duas bases escrevendo o mesmo atributo e "sincronizando". Uma edição feita no QGIS ou no QField sobre atributo de que o GIS **não é dono** é **solicitação** ao dono — nunca escrita direta. É a regra *solicita × aplica* da [visão conceitual §20](../dominio/visao-conceitual-opengsan.md).

---

## 8. Fronteira Operacional × Redes/GIS × Ativos — exemplos

| Objeto | Gestão Operacional | Redes/GIS | Gestão de Ativos | Atendimento e Execução |
| ------ | ------------------ | --------- | ---------------- | ---------------------- |
| **Distrito operacional** | Identidade, nome, unidade responsável, calendário | Polígono — possivelmente derivado da topologia | — | Consulta para rotear e programar |
| **Estação elevatória** | Unidade operacional: o que ela abastece, volumes | Ponto no mapa; nó na rede | A instalação e seus componentes (bombas, painéis, macromedidor) | Executa a manutenção |
| **Válvula** | — | Ponto; papel na topologia; efeito no mincut | A peça: identidade, estado, condição, manutenção | Executa a **manobra** e registra o resultado |
| 🆕 **Parada** | **Dona**: o fato operacional — tipo, estado, previsão, realizado | Calcula o impacto (*mincut*) — sem posse; a projeção espacial é geometria sua | Necessidade de manutenção (PCM) que pede a janela | Executa manobra, reparo e normalização por **OS** |

🆕 [DEC] **O estado do *mincut* é estado da análise; o da Parada, do fato operacional.** Segundo a API oficial do Giswater, o *mincut* tem estados próprios (planejado, em curso, encerrado, cancelado, em planejamento, **em conflito**) e operações de iniciar, encerrar e cancelar — ciclo que **não** pode ser o da Parada. Se a instalação usar esse ciclo, o adaptador o **comanda a partir da Parada**, nunca o inverso ([`paradas-interrupcoes.md §7`](../dominio/paradas-interrupcoes.md#7-giswater--o-que-o-mincut-faz)).

---

## 9. GIS é capacidade; Redes é domínio

🔵 [PROP] **"GIS" não precisa ser módulo de negócio.** Guardar, exibir e publicar geometria é **capacidade transversal** — como Relatórios é para extração. **Redes** — modelo da rede, topologia, zonas derivadas, engenharia — é **domínio**, e pode ser **realizado pelo Giswater** quando a instalação o usar.

---

## 10. O que não se decide aqui

PostGIS no banco do OpenGSAN · mecanismo de sincronização · eventos · REST · publicação por QGIS Server · QField como cliente oficial · profundidade do Redes/GIS nativo sem Giswater — [PEND] (§12).

---

## 11. Respostas do critério de saída

🔴 Nenhuma resposta depende de *"porque no menu está assim"*.

| Pergunta | Resposta | Base |
| -------- | -------- | ---- |
| **O que é Financeiro/Contabilização?** | Domínio de **contabilização subsidiária**: dono dos fatos contábeis originados no saneamento, da política de contabilização (parâmetros como dado) e dos lançamentos derivados; exporta ao ERP por adaptador. **Não é ERP** | [`financeiro-contabilizacao.md §2, §11`](../modulos/financeiro-contabilizacao.md) — código |
| **O que é Operacional?** | **Gestão Operacional**: organização lógica da operação, responsabilidade por área, calendário operacional, medições operacionais agregadas. Não é OS, nem geometria, nem ativo | [`operacional.md §10, §11`](../modulos/operacional.md) |
| **Cadastro territorial × estrutura operacional?** | O primeiro diz **a quem se fatura e como se lê**; o segundo, **como a água chega e quem responde pela área**. A correspondência é **relação com dono**, não coluna da quadra | §3; `Quadra.java:68, :71` |
| **Operacional × GIS?** | Operacional: **identidade e significado** da unidade. Redes/GIS: **polígono, topologia e pertencimento** derivados da rede | §3, §8 |
| **GIS × Gestão de Ativos?** | GIS: **onde está e como se liga**. Ativos: **que coisa física é**, estado, condição, manutenção. Uma identidade, duas responsabilidades | §2, §6 |
| **Dono de uma bomba?** | **Gestão de Ativos** (identidade, estado, manutenção); a posição que ela ocupa pertence a uma unidade da **Gestão Operacional**; o ponto no mapa, a **Redes/GIS** | §8; [`gestao-de-ativos.md §6`](../dominio/gestao-de-ativos.md) |
| **Dono de uma válvula?** | **Gestão de Ativos** (a peça); **Redes/GIS** (ponto, topologia, mincut); a manobra é **OS** | §8 |
| **Dono da geometria de uma tubulação?** | **Redes/GIS** | §6 |
| **Dono da manutenção?** | **Gestão de Ativos** — plano, necessidade, histórico, custo técnico. A **execução** é do Atendimento e Execução | [`gestao-de-ativos.md §11`](../dominio/gestao-de-ativos.md) |
| **Quem executa a OS?** | **Atendimento e Execução** — sempre. QField ou aplicativo são **clientes** | §4; ADR-0008 |
| **Dono do hidrômetro comercial?** | **Micromedição** — Ativos referencia, consulta e inventaria, sem estado concorrente | [`gestao-de-ativos.md §9`](../dominio/gestao-de-ativos.md) |
| **O que o Giswater fará?** | Modelo da rede, topologia, zonas derivadas, mincut, planejamento, simulação via EPANET/SWMM — **integrado pela identidade corporativa**; não é dono de ativos nem de OS; **opcional** | §4 |
| **O que o QGIS fará?** | Ferramenta de edição, análise e cartografia; QGIS Server é **candidato** a publicação; QField, **cliente de campo** | §4 |
| **O que será nativo?** | Cadastro comercial · Micromedição · Faturamento · Cobrança · Arrecadação · **Atendimento e Execução** · **Contabilização subsidiária** · **Gestão Operacional** · **Gestão de Ativos** · identidade corporativa do ativo · plataforma. **Não nativos**: simulador, SIG desktop, ERP, razão contábil | ADR-0008; §4 |
| **Que partes da wiki/legado foram preservadas, generalizadas, reposicionadas, descartadas?** | Tabela abaixo. ⚠️ A wiki **não pôde ser lida** (host bloqueado); o menu foi reconstruído pelo **catálogo versionado** | — |

### 11.1 Destino do que o legado mostrou

| Destino | Itens |
| ------- | ----- |
| **Preservado** | Parametrização contábil como dado · geração e **regeração** de lançamentos por competência × localidade × origem · resumos contábeis · baixa de devedores duvidosos com **recuperação** · roteamento do RA pela divisão de esgoto · confronto de falta de água com a programação · qualidade da água no documento emitido |
| **Generalizado** | Formatos contábeis por companhia → **adaptadores** · *equipamento × instalação* → **ativo × localização funcional** · hierarquia operacional fixa → **vocabulário configurável** · DMC da face → **zona derivada da rede** |
| **Reposicionado** | Qualidade da água: Faturamento → **Gestão Operacional** · marca de hidrômetro: controlador Operacional → **Micromedição** · programação: menu do Atendimento → **Gestão Operacional** (consumida pelo Atendimento) · marca de baixa contábil na Conta → **registro da Contabilização** · distrito e bacia na quadra → **relação com dono** |
| **Descartado** | Herança de controlador por companhia · método, tela e menu com nome de companhia · variantes vazias · redirecionamento com token MD5 ao satélite · **índices de perda e macromedição degenerados** · credencial em `dblink` · indicadores lendo tabelas alheias com identificadores fixos · itens alheios no módulo 10 · papel de banco escrevendo em domínio alheio |

---

## 12. Pendências

| # | Pendência |
| - | --------- |
| 1 | Mínimo nativo de Redes/GIS numa instalação **sem** Giswater (só localização pontual? geometria simples?) |
| 2 | Correspondência território comercial ↔ unidade operacional: mantida ou derivada |
| 3 | Correspondência ligação comercial ↔ ramal físico ↔ ativo |
| 4 | QGIS Server como publicação; QField como cliente oficial de campo |
| 5 | Visitas e campanhas do Giswater × OS |
| 6 | Os dois conceitos de DMC do legado (núcleo 2023 × satélite) |
| 7 🆕 | Protocolo do adaptador Parada ↔ *mincut* — nada decidido ([`paradas-interrupcoes.md §16`](../dominio/paradas-interrupcoes.md#16-pendências)) |

---

## 13. Fontes externas

Giswater — [software](https://www.giswater.org/software/?lang=en) · [documentação (GitHub)](https://github.com/Giswater/docs) · [mincut](https://docs.giswater.org/master/en/docs/giswater/for-users/dialogs/mincut.html) · [algoritmo de mapzones](https://github.com/Giswater/giswater_dbmodel/wiki/Mapzones-algorithm) · [API v1.8.0](https://github.com/giswater/api/releases/tag/v1.8.0) · 🆕 [API — repositório, lido em 2026-09-29](https://github.com/Giswater/api) · 🆕 protocolo *P16 — mincut basics* no [repositório de documentação](https://github.com/Giswater/docs) · [Giswater 4 — FOSS4G Europe 2025](https://talks.osgeo.org/foss4g-europe-2025/talk/ETPJKW/) — QGIS Server — [serviços](https://docs.qgis.org/3.44/en/docs/server_manual/services.html) — QField — [QField](https://qfield.org/) · [QFieldCloud](https://qfield.cloud/) — openMAINT/CMDBuild — [funcionalidades](https://www.openmaint.org/en/product/features) · [CMDBuild](https://www.cmdbuild.org/en/products/cmdbuild) — GeoSan — [Nexus](https://www.nexusbr.com/es/geosan) · [Portal do Software Público](https://softwarepublico.gov.br/social/gsan).

⚠️ Conteúdo obtido por **resumo de mecanismo de busca** sobre essas páginas: os hosts de documentação estão bloqueados para leitura direta nesta sessão. 🆕 No adendo pós-Fase 0, a API e o protocolo P16 foram lidos **diretamente nos repositórios públicos** do projeto Giswater — o site de documentação seguia bloqueado. **Pesquisa externa informa requisitos; não substitui decisão arquitetural.**
