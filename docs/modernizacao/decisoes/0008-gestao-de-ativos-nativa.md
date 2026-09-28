# ADR-0008 — Gestão de Ativos nativa no OpenGSAN; Giswater para redes, GIS e engenharia

- **Status: Aceita** (decisão do responsável do projeto) · Data: 2026-09-28 · Revisão controlada de escopo da Fase 0

## Contexto

A revisão controlada de escopo reconheceu que o OpenGSAN, como plataforma aberta de saneamento, precisa acomodar gestão de ativos, redes/GIS e engenharia — sem copiar o menu do GSAN, a estrutura física do Giswater ou o modelo do openMAINT, e sem abrir escopo infinito.

A evidência que motiva a decisão:

1. 🟢 **O núcleo público do GSAN não tem ativo físico**: nenhuma classe de bomba, válvula, elevatória, adutora, tubulação, patrimônio, imobilizado ou depreciação (busca com escopo em [`modulos/operacional.md §8`](../modulos/operacional.md)). Não existe oráculo GSAN para ativos.
2. 🟢 **A necessidade existia no ecossistema**: o satélite `gsan-operacional` (schema `operacao` do dump versionado) registra macromedidores com **número de série, tombamento e aferição**, e **instalação com data e TAG** por unidade operacional — mas guarda o conjunto motor-bomba como **colunas da estação**, sem identidade ([`gestao-de-ativos.md §2.2`](../dominio/gestao-de-ativos.md)).
3. 🟢 **O GIS de redes sempre foi outro sistema** no ecossistema GSAN (GeoSan), integrado por consumidor ↔ nó e consumo → demanda; o código do GSAN tem só o ponto de integração ([`arquitetura/gis-redes-ativos.md §1`](../arquitetura/gis-redes-ativos.md)).
4. Ferramentas de referência abertas cobrem partes do problema: **Giswater** (rede, topologia, zonas por grafo, mincut, visitas, planejamento, gestão de ativos **de rede**, EPANET/SWMM) e **openMAINT/CMDBuild** (CMMS de facilities com suas próprias ordens de trabalho, estoque e contratos).

## Decisão

1. **Gestão de Ativos é domínio nativo do OpenGSAN** — dono da identidade, classe, composição, localização funcional, ciclo de vida, condição, criticidade e histórico técnico (manutenção e custo técnico) da coisa física.
2. **Giswater é a ferramenta de referência para redes, GIS e engenharia** — não é o EAM do OpenGSAN.
3. **QGIS é ferramenta** de edição, análise e cartografia; QGIS Server e QField são **candidatos** a publicação e a cliente de campo, sem decisão.
4. **EAMs externos (openMAINT, CMDBuild) são benchmark de requisitos**, não dependência nem modelo.
5. **A OS não é duplicada**: Gestão de Ativos **solicita** execução; **Atendimento e Execução** executa; o resultado volta e Ativos o aplica ao seu estado. Não existe "ordem de trabalho do ativo".
6. **Identidade corporativa única do ativo**, reconhecida por Ativos, Redes/GIS, QGIS, Telemetria, OS e Analytics; emitida por Gestão de Ativos.
7. **Integrações por ownership explícito**: todo atributo que atravessa ferramentas tem **um dono** e **uma forma de consumo** declarada — referência, projeção, snapshot ou cache. **Proibido "copiar e sincronizar"** sem essa decisão ([matriz por atributo](../arquitetura/gis-redes-ativos.md)).
8. **O hidrômetro comercial é da Micromedição**; Ativos pode referenciá-lo, consultá-lo e inventariá-lo, sem estado concorrente.
9. **Giswater não é dependência obrigatória**: uma instalação sem ele continua com ativos, OS, estrutura operacional e localização pontual.

**Esta ADR não decide**: schema, tabelas, chaves, PostGIS, mecanismo de sincronização, eventos, REST, a posição exata de Ativos na ordem de implementação além de "trilha estrutural depois da Etapa 2", nem a adoção de QGIS Server ou QField.

## Consequências

- (+) Um único lugar responde *"que coisa física é, em que estado está, que manutenção precisa"*; manutenção de bombas e instrumentos deixa de ser solução ad hoc.
- (+) O padrão *equipamento × instalação*, já provado na Micromedição do GSAN, é generalizado — não inventado.
- (+) Reuso do Giswater sem aprisionamento: o OpenGSAN integra pela identidade e continua funcional sem ele.
- (−) Escopo novo que o GSAN não tinha — **sem oráculo de equivalência**; a correção será provada por especificação própria, não por comparação com o legado.
- (−) Exige disciplina de ownership por atributo entre ferramentas que, isoladamente, se consideram donas de tudo.
- ⚠️ Risco: o Giswater também organiza visitas e campanhas de trabalho — risco de OS paralela se a integração não respeitar o item 5 (pendência registrada).

## Alternativas consideradas

| Alternativa | Motivo da rejeição |
| ----------- | ------------------ |
| **Giswater como dono dos ativos** | Sua gestão de ativos é orientada à rede (priorização e rupturas); eletromecânicos, instrumentação e instalações ficariam sem dono; tornaria o Giswater dependência obrigatória |
| **openMAINT/CMDBuild como EAM integrado** | Duplicaria OS e identidade; foco em facilities; o OpenGSAN passaria a depender de um segundo sistema de registro para manter bombas |
| **Não ter o domínio** | A necessidade reapareceria fora do núcleo — exatamente o que o satélite do GSAN fez, com bomba sem identidade |
| **Ativos dentro da Gestão Operacional** | Mistura *como a operação se organiza* com *que coisa física existe*; a mesma estação seria unidade operacional e ativo sem distinção de responsabilidade |
| **Ativos dentro de Redes/GIS** | Nem todo ativo tem geometria; nem toda geometria é ativo; a identidade ficaria refém da representação espacial |

## Rollback

Decisão conceitual, sem código. Revertê-la exige nova ADR que indique outro dono para identidade, ciclo de vida e manutenção dos ativos — e reavalie as fronteiras com Atendimento e Execução e Micromedição.
