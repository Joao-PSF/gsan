# Módulos — Ordem de Implementação e Status

> **Nota de nomenclatura (2026-09-15)**: este arquivo chamava-se *"Ordem de Migração e Status"*. ⚠️ A expressão ficou obsoleta: a **migração operacional GSAN → OpenGSAN é projeto separado** (ADR-0005, revisão de 2026-09-15). O que se define aqui é a **ordem de implementação do OpenGSAN**.
>
> ⚠️ **A tabela de ordem que ocupava este arquivo era hipótese preliminar** e **foi substituída** em 2026-09-15 pela análise de dependências. Ver §"Mudanças" abaixo e o [registro da execução](../alteracoes/2026-09-15-dependencias-e-ordem-implementacao.md).

**Mapas funcionais concluídos (Fase 0 — todos)**: [cadastro](cadastro.md) · [micromedicao](micromedicao.md) · [faturamento](faturamento.md) · [cobranca](cobranca.md) · [arrecadacao](arrecadacao.md) · [atendimento](atendimento.md) · [seguranca](seguranca.md) · [batch](batch.md) · [relatorios](relatorios.md) · [integracoes](integracoes.md) · 🆕 [financeiro-contabilizacao](financeiro-contabilizacao.md) · 🆕 [operacional](operacional.md) · 🆕 [**fiscal**](fiscal.md) (auditoria final, 2026-09-29 — requisito nativo, sem comportamento GSAN a mapear).

🆕 **Revisão controlada de escopo (2026-09-28)**: os módulos Financeiro e Operacional do GSAN **não tinham mapa** — lacuna da Fase 0 corrigida. Conclusões: o Financeiro é **contabilização subsidiária**, não ERP; o Operacional do núcleo é **cadastro de referência + calendário**, e a gestão operacional com medições viveu num satélite fora do núcleo. A visão de [Gestão de Ativos](../dominio/gestao-de-ativos.md) e a [arquitetura Redes/GIS/Ativos](../arquitetura/gis-redes-ativos.md) seguem a [ADR-0008](../decisoes/0008-gestao-de-ativos-nativa.md).

⚠️ Mapa concluído **não é** especificação pronta para implementar: cada um lista dúvidas abertas, e a especificação dos cenários críticos é item do fechamento da Fase 0 (ver [`estrategia-testes.md`](../testes/estrategia-testes.md)).

🆕 **Auditoria final (2026-09-29)**: o **Fiscal** entrou como módulo — a **NFAg (modelo 75)** é obrigação dos prestadores de água e esgoto, com ciclo próprio (autorização, eventos, contingência, guarda); **Conta ≠ NFAg**. PIX e boleto registrado passaram à **Arrecadação/Pagamentos** (Etapa 5), Pix Automático à Etapa 6, e a Tarifa Social nacional à Etapa 4 com concessão automática antes da operação. Veredito e matrizes em [`../auditoria/`](../auditoria/auditoria-final-fase0.md).

🆕 **Adendo pós-Fase 0 (2026-09-29)** — sem reabrir a Fase 0: [PCM](../dominio/pcm.md) (capacidade da Gestão de Ativos), [Paradas](../dominio/paradas-interrupcoes.md) (Gestão Operacional), [Workspace SINISA manual](../regulatorio/sinisa.md) (módulo *Prestação de Informações*, [ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md)) e [Gerencial & Analytics](../analytics/gerencial-analytics.md). Não são mapas funcionais: não há comportamento GSAN a mapear.

🆕 **Segundo adendo pós-Fase 0 (2026-09-29)** — os módulos de domínio destes mapas agrupam-se em **módulos instaláveis** (Commercial, Metering, Atendimento…) habilitados por **perfil de implantação**, sobre o mesmo monólito modular ([ADR-0010](../decisoes/0010-monolito-modular-perfis-de-implantacao.md); [`modulos-e-perfis-de-implantacao.md`](../arquitetura/modulos-e-perfis-de-implantacao.md)). A ordem abaixo **não muda**: cada módulo nasce respeitando sua fronteira de implantação, e a Etapa 0 decide ativação, estrutura Maven e de pacotes, testes de fronteira e migrations de módulo desabilitado.

**Além dos treze mapas** (doze do GSAN e o Fiscal), esta pasta contém:

- [Catálogo de funcionalidades futuras](funcionalidades-futuras.md) — 26 capacidades do legado que **não são módulos**.
- 🔴 [**Dependências e ordem de implementação**](dependencias-e-ordem-implementacao.md) — **o documento detalhado**: matriz de dependências, os 8 ciclos, fundação mínima, primeira fatia vertical, 9 etapas, gates de avanço e decisões bloqueantes.

---

## Ordem de implementação — resumo

🔴 A ordem é por **capacidade implementável**, não por módulo inteiro. Detalhamento, justificativa e critérios em [`dependencias-e-ordem-implementacao.md`](dependencias-e-ordem-implementacao.md).

| Etapa | Foco | Capacidades principais | Status |
| ----- | ---- | ---------------------- | ------ |
| **0** | **Fundação** | Projeto modular com **fronteira verificada** · Flyway `V1` · Testcontainers · **S1** (identidade, autenticação, concessão por caso de uso) · **auditoria mínima** · convenção monetária e de arredondamento · configuração externa sem hard-code institucional · CI com *secret scan* | Pendente |
| **1** | **Primeira fatia vertical** | Autenticar → consultar imóvel/cliente → **abrir e tramitar RA** (especificação paramétrica) | Pendente |
| **2** | **Núcleo de atendimento e execução** | Estrutura territorial · **ligação e sua situação** · OS · 🔴 **contrato "solicita × aplica"** · **S2** (escopo territorial) · motor de relatório · 🆕 **Gestão Operacional mínima** (distrito, bacia, divisão de esgoto, calendário) | Pendente |
| **3** | **Medição** | Hidrômetro → instalação → leitura → **consumo com origem** · anormalidades · camada de integração + coleta móvel | Pendente |
| **4** | **Financeiro individual** | Estrutura tarifária versionada · **motor de conta individual** · Conta e snapshots · identidade estável do documento · débito/crédito/guia · 🆕 qualidade da água no documento emitido · 🆕 **Tarifa Social** (regra nacional) · 🆕 **NFAg individual** (homologação) | Pendente |
| **5** | **Recebimento** | Recepção → classificação → aplicação → conciliação · **posição de dívida como consulta derivada** · assíncrono genérico · 🆕 **Pix Cobrança · boleto registrado** | Pendente |
| **6** | **Cobrança** | Política · ação · documento · **parcelamento** · negativação · terceirização · notificação · 🆕 **Pix Automático** | Pendente |
| **7** | **Escala** | **Faturamento em lote** (unidade = rota) · arrecadação mensal · encerramentos · resumos financeiros · 🆕 **Contabilização** (lançamentos, devedores duvidosos, exportação por adaptador) · 🆕 **NFAg em lote, contingência e eventos** · 🆕 concessão automática da Tarifa Social | Pendente |
| **8** | **Canais e evoluções** | **Identidade do cliente final** · canal digital (🆕 apresenta Pix e boleto) · bureau, telemetria, GIS · ~~analytics~~ · ~~prestação de informações regulatórias~~ — 🆕 ver trilhas abaixo | Pendente |

🆕 **Trilha estrutural** — Gestão de Ativos, Redes/GIS (Giswater opcional), Engenharia/Simulação: **pode começar depois da Etapa 2**, em paralelo ou depois das Etapas 3–7; **não é décima etapa** e **não bloqueia** nenhum gate do núcleo comercial ([§24.2](dependencias-e-ordem-implementacao.md)). 🆕 Adendo: **PCM** depois de Ativos + OS; **Parada** depois da Gestão Operacional mínima — o GIS **agrega** o cálculo de impacto.

🆕 **Trilha regulatória** — **Workspace SINISA manual**, quando os glossários do ciclo estiverem definidos, **sem depender do Analytics**; automação **fora** da ordem inicial ([§24.3](dependencias-e-ordem-implementacao.md)).

🆕 **Gerencial & Analytics** — **incremental**: cada métrica entra quando o seu fato existe; nenhum gate depende dele ([§24.4](dependencias-e-ordem-implementacao.md)).

**Transversais desde a Etapa 0** (⚠️ não são fases finais): testes · auditoria · S1 · log com correlação · configuração externa · neutralidade institucional · convenção monetária · verificação de fronteira · revisão desta matriz ao fim de cada etapa.

**Plataforma, posicionada por parte**: `seguranca` em **três blocos** (S1 na Etapa 0, S2 na 2, S3 progressivo) · `relatorios` com o módulo dono, motor na Etapa 2 · `integracoes` como convenção na Etapa 0, camada na 3, adapters com o dono · `batch` na Etapa 7 (a dependência é **inversa**: orquestrador exige operação individual comprovada).

🆕 ~~**Fora da ordem**: `fiscal`/SPED permanecem `EXIGE APROFUNDAMENTO`~~ — **esclarecido na auditoria final (2026-09-29)**: o **Fiscal** entra nas Etapas **4** (NFAg individual) e **7** (lote, contingência, eventos); o **SPED** do legado sai do OpenGSAN (dados ao ERP por adaptador). Nenhum dos dois bloqueia a Etapa 0.

---

## Mudanças em relação à ordem anterior

A tabela antiga era `1 cadastros auxiliares · 2 consultas · 3 atendimento · 4 OS · 5 micromedição · 6 cobrança · 7 arrecadação · 8 faturamento · 9 batch`, com `seguranca` na Fase 5. As mudanças relevantes, com o motivo:

| # | Mudança | Motivo |
| - | ------- | ------ |
| 1 | 🔴 **A ordem financeira foi invertida**: `cobrança → arrecadação → faturamento` virou **`faturamento → recebimento → cobrança`** | O Faturamento **cria a Conta**; não existe dívida sem documento emitido, nem posição de dívida correta sem conhecer pagamentos. A ordem antiga exigiria **simular a Conta** — fabricar o objeto financeiro mais sensível do sistema para validar Cobrança contra uma ficção |
| 2 | **Cadastros auxiliares e consultas deixam de ser etapas** | Uma etapa precisa provar mais que CRUD: arquitetura, persistência, autorização, auditoria, domínio e teste |
| 3 | **Segurança deixa de ser "Fase 5"** e passa a três blocos | 🔴 "Segurança completa antes do domínio" é **estruturalmente impossível**: a abrangência territorial é definida sobre a estrutura territorial, que pertence ao **Cadastro** |
| 4 | **Auditoria sai da fase de observabilidade para a Etapa 0** | Retrofit obriga revisitar **toda escrita** já existente |
| 5 | **Faturamento deixa de ser o último**: motor individual na Etapa 4, lote na 7 | 🟢 `gerarConta` é a mesma lógica no individual e no lote; separar honra a estrutura que o legado já tem, e evita descobrir tarde que a arquitetura não suporta o núcleo financeiro |
| 6 | **Arrecadação e Micromedição deixam de ser blocos únicos** | A *recepção* de pagamento não depende de nada financeiro; as anormalidades de leitura não são pré-requisito do cálculo |
| 7 | **Portal / canal digital entra na ordem** (Etapa 8) | Não existia na ordem antiga — descoberto pelo catálogo de funcionalidades futuras (47 classes sem dono) |
| 8 | **`fiscal`/SPED saem do pacote do faturamento** | Permanecem sem comportamento observável nesta branch. 🆕 (2026-09-29) O **Fiscal** volta à ordem como módulo **próprio** — por obrigação (NFAg), não por evidência do legado |
| 9 🆕 | **PIX e boleto registrado saem da Etapa 8** para a Arrecadação/Pagamentos (Etapa 5) | PIX não depende do Portal; depende de conta, recebimento, PSP e conciliação (auditoria final) |

🔵 **O que a ordem anterior acertou** e permanece: começar por risco baixo, Micromedição antes de Faturamento, e batch por último. ⚠️ O erro não foi de critério — foi ordenar o financeiro por **risco crescente** em vez de por **dependência**.

---

## Regras

1. Nenhuma capacidade entra em implementação sem documento próprio descrevendo comportamento atual, dependências, tabelas, regras de negócio e resultado esperado (sequência: analisar → documentar → dependências → resultado esperado → testes → implementar → comparar → validar segurança → validar performance → documentar).
2. Capacidade só é considerada concluída no OpenGSAN após cumprir o **critério de pronto conceitual** e o **gate da sua etapa** ([§25 e §31.1](dependencias-e-ordem-implementacao.md)): equivalência comprovada sob os **dois oráculos** e validação em homologação (VPS). Critérios adicionais de produção aplicam-se quando existir companhia operando o OpenGSAN.
3. 🔴 **Ordem não é imutável**: a matriz de dependências é revisada ao fim de cada etapa. Dependência descoberta **muda a ordem** — e o motivo é registrado aqui.
4. Este arquivo é atualizado a cada mudança de status.
