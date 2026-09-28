# [2026-09-28] Revisão controlada de escopo do OpenGSAN

- **Motivo**: a visão estratégica do OpenGSAN como plataforma aberta de saneamento reconhece, além da gestão comercial, contabilização, gestão operacional, gestão de ativos, redes/GIS, engenharia, campo, telemetria e analytics. A Fase 0 precisava saber **o que disso tem evidência no GSAN**, **quem é dono de quê** e **o que não abrir agora** — sem copiar o menu do GSAN, a estrutura física do Giswater nem o modelo do openMAINT.
- **Método**: delta sobre a Fase 0 existente, sem reinício; hierarquia de evidência (código público → banco versionado → documentação oficial → wiki → `gsan_comercial`); marcas **[GSAN] [REF] [INF] [PROP] [DEC] [PEND]**; classificação A–F das descobertas; contagens **por script**.
- **Testes**: nenhum executado — ⚠️ especifica, não executa. **Risco**: baixo (documental) · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## 0. Verificação de continuidade

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `30fd8c8` — especificação dos cenários críticos; local = remoto |
| Commits posteriores | Nenhum |
| Atividade realmente pendente | A do backlog era a ADR-0007; esta revisão foi **inserida antes dela** por decisão do responsável |

## 1. A lacuna que a revisão encontrou

🔴 O GSAN tem dois módulos que **nenhum mapa funcional cobriu**: **Financeiro** (`gcom.financeiro`, 60 classes; módulo 12 do menu) e **Operacional** (`gcom.operacional`, 35 classes; módulo 10). Os dez mapas da Fase 0 seguiram o fluxo comercial e não passaram por eles.

## 2. Financeiro → Contabilização subsidiária

[`modulos/financeiro-contabilizacao.md`](../modulos/financeiro-contabilizacao.md).

| Achado | Classe |
| ------ | ------ |
| Lançamentos de partida dobrada por competência × localidade × origem (faturamento, arrecadação, avisos bancários, devedores duvidosos) | **A** |
| 🟢 **Parametrização contábil como dado** — o acerto central do módulo | **A** |
| Devedores duvidosos = **baixa contábil com recuperação**, não estimativa (PECLD inexistente no código público) | **A** necessidade · **D** implementação |
| O Financeiro **escreve na Conta**; a marca da baixa serve de "dívida ativa" na Cobrança | **D** — pendência sobre dívida ativa |
| Formatos de exportação por companhia por herança de controlador; nome de companhia na interface do núcleo e no menu | **C** / **D** |
| Nenhum razão, balancete, exercício ou lançamento manual (busca com escopo: 0 arquivos) | — |

🔵 **Conclusão**: o OpenGSAN terá **Contabilização subsidiária, não ERP**; a exportação é **adaptador**.

## 3. Operacional → Gestão Operacional

[`modulos/operacional.md`](../modulos/operacional.md).

| Achado | Classe |
| ------ | ------ |
| O núcleo é **cadastro de referência + calendário**; 755 linhas de controlador, nenhum cálculo | — |
| O valor está nas **pontes**: distrito na quadra → programação de OS; divisão de esgoto → destino do RA; programação × falta de água; qualidade da água na conta | **A** necessidades · **D** posicionamento |
| Zona de pressão e produção de água **sem consumidor** | **F** / **E** |
| Marca de hidrômetro mantida pelo controlador **Operacional**, embora o menu a ponha na Micromedição | **D** — nem menu nem pacote decidem o dono |
| 🔴 **Satélite `gsan-operacional`** — schema `operacao` no dump versionado (77 tabelas, 3 visões, função `geraindicador`): unidades, volumes, horas de motor-bomba, energia, insumos, macromedidores com aferição, DMC, 17 indicadores | **A/B** necessidades — expansão estrutural |
| 🔴 Índices de **perda física** e de **macromedição** do satélite **algebricamente degenerados** (0 e 100% sempre que calculados) | **E** — nenhuma equivalência exigida |

🔵 **Atendimento/OS ≠ Gestão Operacional ≠ Redes/GIS ≠ Gestão de Ativos** — e o cadastro territorial comercial é um quinto eixo.

## 4. Gestão de Ativos e Redes/GIS

- [ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md) — **Aceita** (decisão do responsável): Ativos nativa; Giswater para redes/GIS/engenharia, não EAM, **não obrigatório**; OS não duplicada; identidade corporativa única; ownership por atributo; **nenhuma** decisão de schema, PostGIS, sincronização, eventos ou REST.
- [`dominio/gestao-de-ativos.md`](../dominio/gestao-de-ativos.md) — visão alvo; **sem oráculo GSAN** (o núcleo não tem ativo físico), com o satélite como **fonte de requisitos**.
- [`arquitetura/gis-redes-ativos.md`](../arquitetura/gis-redes-ativos.md) — papéis das ferramentas, matriz de ownership **por atributo**, fronteiras e as **respostas do critério de saída** — nenhuma dependente da posição no menu.

## 5. Cenários — delta por script

| | Antes | Depois |
| - | ----: | -----: |
| Itens de inventário | 166 | **184** (+11 Financeiro, +7 Operacional) |
| Especificações | 71 | **79** (+5 `CEN-FIN`, +3 `CEN-OPE`) |
| P0 · P1 | 43 · 28 | **45 · 34** |
| Oráculo 1 · 1+2 · 2 · pendente | 54 · 8 · 6 · 3 | **62 · 8 · 6 · 3** |
| Etapa 2 · 4 · 7 | 9 · 12 · 7 | **11 · 13 · 12** |
| Destinos: absorvido · bloqueado · C4 · a complementar · P2 | 135 · 3 · 3 · 2 · 23 | **150 · 3 · 3 · 1 · 27** |
| Perfis de massa (definidos = usados) | 52 | **59** |

⚠️ O item 22 de Integrações (*integração contábil padrão × variante*) deixou de ser `A COMPLEMENTAR` e passou a CEN-FIN-005; só a variante por companhia continua a complementar. **CEN-SEG-011** ganhou os dumps com credencial (achado 20) — sem mudar contagem. Gate **7 → operação** passou a exigir CEN-FIN-001.

🔵 Matriz, distribuições, rastreabilidade e mapa de perfis **regenerados por script** a partir das especificações (os marcadores originais já tinham sido consumidos; o gerador passou a localizar os blocos por âncora).

## 6. Correções de fato publicado

Registradas em [`procedencia.md §4`](../procedencia.md):

| Afirmação | Correção |
| --------- | -------- |
| Integração contábil `MÓDULO OPCIONAL` / `APENAS EVIDÊNCIA` (catálogo, cap. 10 e §18) | `CORE FUTURO` / comprovada — o código prova o fluxo; o catálogo tinha lido schema, não o pacote Java. Totais do catálogo recontados por script: 12 · 6 · 5 · 2 · 1 e 12 · 10 · 4 |
| "Domínio/núcleo operacional" para Atendimento e OS | **Atendimento e execução** — colidia com o módulo Operacional |
| Credenciais versionadas em "três artefatos" (CEN-SEG-011) | Incompleto — dumps com `dblink` |

E uma regra de método: busca negativa declara também a **camada** (Java × SQL) e inclui **nome de coluna**.

## 7. Segurança — achado 20

🔴 Usuário e senha em strings `dblink` dentro de funções armazenadas de **dumps versionados** (5 no dump comercial, repetidas em `comercial/dump.sql`; 81 no gerencial; uma com endereço de rede interno). **Comprometidas, rotação obrigatória; nenhum valor transcrito.** [`riscos-identificados.md`](../seguranca/riscos-identificados.md).

## 8. Fontes externas e bloqueios

⚠️ **Bloqueados pela política de rede desta sessão** (não contornados): `gsan.com.br` (wiki), `docs.giswater.org`, `giswater.gitbook.io`, `docs.qfield.org`, `www.openmaint.org`, `docs.qgis.org`. Substitutos: o **catálogo de funcionalidades versionado** reconstruiu o menu do GSAN (nível 2); resumos de mecanismo de busca sobre as páginas oficiais informaram **requisitos** das ferramentas — nunca decisão.

## 9. O que ficou deliberadamente de fora

Nenhum código, banco, migration, API ou JPA · nenhum schema, tabela, chave, PostGIS, sincronização, evento ou REST · nenhuma fase nova (Ativos e Redes/GIS seguem **trilha estrutural** depois da Etapa 2) · primeira fatia vertical **não movida** · os 71 cenários e os mapas existentes **não refeitos** · telemetria, SCADA, perdas, laboratório, energia, simulação avançada, compras, estoque corporativo, ERP e BIM **não mapeados**.

## 10. Impacto

- **Criados**: `modulos/financeiro-contabilizacao.md`, `modulos/operacional.md`, `dominio/gestao-de-ativos.md`, `arquitetura/gis-redes-ativos.md`, `decisoes/0008-gestao-de-ativos-nativa.md`, `testes/cenarios/financeiro-operacional.md`, este registro.
- **Atualizados pontualmente**: `dominio/visao-conceitual-opengsan.md` (escopo, §19, §27 refinada, §28.2, §29, §30, §31) · `dominio/mapa-de-dominio.md` · `modulos/README.md` · `modulos/funcionalidades-futuras.md` · `modulos/dependencias-e-ordem-implementacao.md` (Etapas 2, 4 e 7; §24.2 trilha estrutural; gate 7 → operação) · `plano-de-trabalho.md` (nomenclatura) · `compatibilidade/gsan-opengsan.md` (§5.2) · `testes/cenarios-criticos.md` e três arquivos de especificação (nomenclatura; CEN-SEG-011) · `seguranca/riscos-identificados.md` · `procedencia.md` · `decisoes/README.md` · `MODERNIZACAO_GSAN.md` · `docs/modernizacao/README.md`.

## 11. Próxima atividade

**Decisão da ADR-0007 — arquitetura de interface**; depois, **auditoria final e encerramento da Fase 0**.
