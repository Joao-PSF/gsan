# Revisão Final Consolidada — Arquitetura do OpenGSAN depois dos adendos

> **2026-09-30 — revisão, não descoberta.** A Fase 0 continua encerrada em 29/09/2026; o primeiro adendo (PCM, Paradas, SINISA, Gerencial) e o segundo (monólito modular e suíte modular, [ADR-0010](../decisoes/0010-monolito-modular-perfis-de-implantacao.md)) foram **incorporados**, não refeitos. Registro da execução em [`alteracoes/2026-09-30-revisao-final-consolidada.md`](../alteracoes/2026-09-30-revisao-final-consolidada.md).
>
> **Pergunta-guia**: *se as próximas fases começarem com esta arquitetura, existe contradição, dependência acidental, responsabilidade duplicada ou lacuna estrutural que provavelmente obrigue uma reestruturação grande depois?*

---

## 1. Estado de entrada

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `83a3195` — segundo adendo pós-Fase 0; local = remoto; árvore limpa; nenhum commit posterior |
| Fase 0 | Concluída em 2026-09-29 — [auditoria final](auditoria-final-fase0.md), veredito SIM |
| Adendos | Dois, no mesmo dia; nenhum reabriu a Fase 0 |
| ADRs aceitas | 10 |
| Especificações de cenário | 103 (55 P0 · 48 P1; 22 com oráculo N) — por script |
| Implementação | Nenhuma |

---

## 2. Arquitetura consolidada

```text
OpenGSAN — UM monólito modular · uma versão · um processo por instalação
│
├─ Platform ...... identidade · autorização · auditoria · contexto institucional · parâmetro regulado ·
│                  documentos · notificação · processamento · relatórios (motor) ·
│                  infraestrutura de integração · registro de módulos
├─ Commercial .... Cadastro Comercial · Faturamento (tarifas e benefícios) · Cobrança ·
│                  Arrecadação e Pagamentos (Pix, Pix Automático, boleto, débito automático) ·
│                  Financeiro/Contabilização · Fiscal/NFAg — coeso
├─ Metering ...... parque de hidrômetros · leitura · consumo · anormalidades (+ telemedição/AMI)
├─ Atendimento ... RA · OS · Campo (+ unidades de atendimento)
├─ Assets ........ ativos · condição · criticidade · PCM
├─ Operations .... Gestão Operacional · Produção · Paradas · Racionamento · Continuidade
├─ Networks ...... Redes · GIS · topologia · impacto — com Giswater e QGIS como ferramentas
├─ SINISA ........ Workspace SINISA — manual na V1
└─ Analytics ..... Gerencial — consumidor de fatos
```

Tarifas e benefícios continuam **capacidades** — aplicação no Faturamento, elegibilidade e vínculo no Cadastro —, não módulos ([visão §27.2](../dominio/visao-conceitual-opengsan.md#272--estrutura-conceitual-consolidada-auditoria-final-2026-09-29)). Os princípios valem inteiros: preservar o que o GSAN tem de bom; modernizar onde é preciso; OpenGSAN como evolução do GSAN; modularidade real; Commercial coeso; módulos isoláveis quando fazem sentido; Platform pequena; ferramenta ≠ módulo; métrica ≠ informação regulatória; PCM sem OS paralela; Parada sem polígono como identidade; implantação modular sem microserviço.

---

## 3. Correção do módulo Atendimento

| Antes | Depois | Por quê |
| ----- | ------ | ------- |
| Instalável ***Services*** | **Atendimento** — RA · OS · Campo | O nome escondia o RA, soava como camada técnica e deixava a demanda do cliente parecer assunto do Commercial |
| RA descrito como uma das origens da OS | RA com **ciclo próprio** — protocolo, solicitante, especificação, prioridade, prazo, situação, unidade responsável, tramitação, histórico, acompanhamento | O RA não é formulário para abrir OS (CEN-ATE-002 a 005) |
| Campo implícito | **Campo** explícito — aplicativo, QField em tarefa geoespacial, evidências, geolocalização; offline só onde o cliente especializado exige | ADR-0007 |
| Unidade organizacional na Platform | **Unidades de atendimento** no Atendimento | §5 abaixo |

Preservado, com evidência: **RA ≠ OS**; nunca 1:1; **RA sem OS** (CEN-ATE-003); **OS sem RA** — a ação de cobrança a gera a partir do documento (`ControladorCobranca:24135–24142` → `ControladorOrdemServicoSEJB:1032–1086`); origens da OS — RA, Commercial, Metering, Assets/PCM, Operations, sistema externo, integração autorizada. O Atendimento **opera sem o Commercial**, com referência externa e snapshot; no perfil completo, o Commercial dá cliente, imóvel, ligação e contexto, e o Atendimento é dono de RA, OS e execução. Relações: com o **Assets**, *necessidade → OS → resultado → Assets*, sem ordem paralela; com a **Operations**, a Parada é dela e a OS só executa; com o **Metering**, serviço de hidrômetro é OS e o estado do hidrômetro é do Metering; com o **Networks**, geometria e contexto de rede, e a OS continua do Atendimento. Detalhe em [`modulos-e-perfis-de-implantacao.md §7`](../arquitetura/modulos-e-perfis-de-implantacao.md#7-atendimento--ra-os-e-campo).

---

## 4. Ownership

| Conceito | Dono | Onde está fixado | Situação |
| -------- | ---- | ---------------- | -------- |
| Cliente · imóvel · ligação | Commercial — Cadastro | Mapa de domínio; [módulos §4](../arquitetura/modulos-e-perfis-de-implantacao.md#4-commercial--coeso-por-dependência) | ✅ |
| Documento comercial | Commercial — Faturamento | Visão §11 | ✅ |
| Pagamento | Commercial — Arrecadação | Completude §5 | ✅ |
| NFAg | Commercial — Fiscal | [`fiscal.md`](../modulos/fiscal.md) | ✅ |
| Hidrômetro e instalação · leitura | Metering | [`gestao-de-ativos.md §9`](../dominio/gestao-de-ativos.md#9-hidrômetro-comercial); módulos §5 | ✅ — o Assets só referencia |
| RA · OS · execução em campo | **Atendimento** | Módulos §7 | ✅ **corrigido** — o nome *Services* não dizia |
| Unidade de atendimento | **Atendimento** | Módulos §7.2 | ✅ **corrigido** — estava na Platform |
| Equipe | Atendimento — ou o sistema externo de execução | [`pcm.md §5`](../dominio/pcm.md#5-programação) | ✅ **explicitado** — o PCM lê capacidade |
| Ativo · necessidade de manutenção | Assets · PCM | ADR-0008; [`pcm.md`](../dominio/pcm.md) | ✅ |
| Parada · produção operacional | Operations | [`paradas-interrupcoes.md`](../dominio/paradas-interrupcoes.md); módulos §10 | ✅ |
| Geometria · topologia | Networks | [`gis-redes-ativos.md`](../arquitetura/gis-redes-ativos.md) | ✅ |
| Declaração SINISA | SINISA | ADR-0009 | ✅ |
| Métrica | Analytics — definição aprovada pelo *owner* de negócio do domínio | [catálogo](../analytics/catalogo-de-metricas.md) | ✅ |
| Contexto institucional | Platform | Módulos §14 | ✅ **justificado** — dimensão do parâmetro regulado |

Nenhuma responsabilidade duplicada. Três estruturas continuam separadas: **território comercial** (Commercial) ≠ **estrutura operacional** (Operations) ≠ **unidades de atendimento** (Atendimento) — e nenhuma é geometria, que é do Networks.

---

## 5. Dependências

**Re-auditoria**: cada 🔴 respondeu à pergunta *é necessária para o módulo existir?* ([módulos §15.2](../arquitetura/modulos-e-perfis-de-implantacao.md#152--re-auditoria-da-obrigatoriedade--revisão-consolidada-2026-09-30)).

| Resultado | Dependências |
| --------- | ------------ |
| **REQUIRED** | Só a **Platform** — em todos os módulos funcionais |
| 🔴 **Provedor obrigatório — exceção documentada** | Consumo faturável e qualidade da água para o documento, **ambos do Commercial**: sem o primeiro não há faturamento; sem o segundo, a conta descumpre o Decreto 5.440/2005 |
| **Rebaixadas** a condição de capacidade | Ponto de consumo → Metering (leitura e instalação); execução → Assets (programação e execução do PCM) |
| OPTIONAL · EXTERNALIZABLE | Só por **contrato do consumidor**; ponte só com os dois módulos ativos; nunca *import* direto nem HTTP |

Dependências-chave: *Commercial ← consumo faturável ← Metering ou externo* · *Commercial ← qualidade da água ← Operations ou externo* · *Assets/PCM → Atendimento ou OS externa* · *Operations → Networks, opcional* · *SINISA → manual, só a Platform* · *Analytics ← fatos e projeções*. Nenhuma dependência acidental encontrada: SINISA e Analytics são consumidores e não constam como dependência de ninguém; a Platform não depende de módulo funcional — o escopo territorial se resolve por inversão, e a unidade de atendimento **não** é dimensão de escopo.

---

## 6. Perfis de implantação

Treze perfis de referência reconferidos contra a matriz revista — **todos válidos**:

| Perfil | Módulos | Situação |
| ------ | ------- | -------- |
| FULL | Todos | ✅ |
| PEQUENO PRESTADOR | Platform · Commercial · Metering · Atendimento · Operations · SINISA | ✅ **Composição mínima**: consumo pelo Metering e qualidade pela Operations — os dois 🔴 atendidos internamente, sem sistema externo |
| COMMERCIAL · COMMERCIAL + METERING | — | ✅ com os 🔴 externos declarados |
| METERING | Platform · Metering | ✅ — leitura e instalação com o sistema comercial |
| **ATENDIMENTO** | Platform · Atendimento | ✅ **renomeado** — ERP ou sistema comercial + OpenGSAN Atendimento |
| ASSETS · **ASSETS + ATENDIMENTO** · ASSETS + OPERATIONS + NETWORKS | — | ✅ — ASSETS agora sobe também **sem** provedor de execução, com o PCM sem executar |
| OPERATIONS · NETWORKS · SINISA · ANALYTICS | — | ✅ — Analytics com ao menos uma fonte |

Nenhuma combinação impossível. Combinação fora da lista continua permitida se a validação passar, sem garantia de teste. Autenticação ≠ autorização ≠ módulo habilitado; SINISA, Assets e Atendimento isolados não dependem do Commercial para escopo — usam o contexto institucional e a dimensão do módulo presente.

---

## 7. Consistência entre ADRs

| ADR | Relação com o estado consolidado | Situação |
| --- | -------------------------------- | -------- |
| 0001 | Monólito modular; especializada pela 0010. A lista de módulos da 0001 — com `integracoes` e `shared` — é **histórica**: `integracoes` é infraestrutura, e os adapters ficam nos módulos | ✅ **nota na arquitetura alvo** — ADR não reescrita |
| 0002 | Flyway desde `V1`; migrations de módulo desabilitado na Etapa 0 | ✅ |
| 0003 · 0004 · 0006 | Sem relação com a revisão | ✅ |
| 0005 | Coexistência por contrato ≠ migração | ✅ |
| 0007 | Canais sobre casos de uso; autorização no caso de uso; campo com identidade de dispositivo; nenhum HTTP interno | ✅ |
| 0008 | OS não duplicada — reforçada: sem provedor de execução, **nada** no Assets registra execução | ✅ |
| 0009 | SINISA manual; nenhuma dependência de métrica | ✅ |
| 0010 | Três pontos corrigidos **dentro** dela — nome, estrutura organizacional, obrigatoriedade; nenhuma decisão revertida | ✅ **seção de revisão** |

**Nenhuma ADR nova**: renomear não é decisão estrutural, e as duas outras correções aplicam critérios que a ADR-0010 já tinha — itens 4 e 7.

---

## 8. Consistência de interfaces

ADR-0007 intacta: backoffice server-driven, portal como canal do Commercial e do Atendimento, campo e QField como clientes por contrato; **backoffice não é offline**. Módulo desligado não registra menu, tela, permissão, endpoint, job, adapter, relatório nem evento. API ≠ domínio; módulo interno ≠ HTTP. Nenhum *broker* presumido — Kafka ou RabbitMQ só se um dia houver necessidade demonstrada. Motor × semântica, conferidos: relatórios (motor na Platform, definição no módulo), documentos (guarda na Platform, semântica no módulo), notificação (canal na Platform, evento no módulo), processamento (motor na Platform, job no módulo — módulo desligado não registra job) e integrações (infraestrutura na Platform, adapter no módulo). 🔧 Formulações que punham adapters "em Integrações" — na [arquitetura alvo](../arquitetura/arquitetura-alvo.md) e em [`sinisa.md`](../regulatorio/sinisa.md) — foram corrigidas; [`fiscal.md`](../modulos/fiscal.md) e [`integracoes.md`](../modulos/integracoes.md) ganharam nota. Registros históricos, como a auditoria final, não foram reescritos.

---

## 9. Consistência regulatória

| Obrigação | Onde vive | Situação |
| --------- | --------- | -------- |
| NFAg | Commercial — Fiscal; adapter do Fiscal | ✅ |
| Pix · Pix Automático | Commercial — Arrecadação; **não** no portal | ✅ |
| Qualidade da água na conta (Decreto 5.440/2005) | 🔴 contrato do Commercial | ✅ |
| Tarifa Social | Regra: Cadastro + Faturamento — sem módulo | ✅ |
| SINISA | Workspace manual; métrica ≠ informação SINISA; automação desligada por padrão | ✅ |
| Parâmetro regulado por regulador e vigência | Mecanismo e contexto institucional na Platform; significado no módulo | ✅ **justificado** |

---

## 10. Consistência dos cenários

103 especificações, **contadas por script** — 55 P0 · 48 P1; 22 com oráculo N; 36 derivadas; 69 perfis de massa usados. Nenhum cenário novo foi necessário.

| O que precisa ser protegido | Cenário | Situação |
| --------------------------- | ------- | -------- |
| RA sem OS | CEN-ATE-003 | ✅ |
| OS sem RA — comportamento do GSAN | CEN-COB-003 | 🔧 **observável acrescentado**: a OS da ação nasce sem RA |
| OS aberta por sistema externo | CEN-MOD-002 V2 · CEN-MOD-004 | ✅ |
| Efeito aplicado pelo dono | CEN-ATE-007 · CEN-MOD-002 V5 | ✅ |
| Atendimento sem Commercial | CEN-MOD-002 | 🔧 renomeado |
| Assets sem provedor de execução | CEN-MOD-004 V4 | 🔧 **esperado revisto** — sobe com a capacidade ausente; nada registra execução |

MOD-001 a 007 continuam com os mesmos IDs, etapas e gates; só o texto de MOD-002 e MOD-004 mudou, e o comportamento, só em MOD-004 V4 — pela re-auditoria da §5.

---

## 11. Pendências reais

Nenhuma bloqueia o próximo estágio. Nenhuma decisão de comportamento, ownership, regra financeira, identidade, norma obrigatória ou modularidade ficou aberta — só detalhe, cada um no seu momento:

| Quando | Pendência |
| ------ | --------- |
| **Antes da Fase 1** | Nenhuma |
| **Fase 1** | Nenhuma nova — ambiente de referência do legado, como no plano |
| **Fase 2** | Capturar as baselines, inclusive o observável novo de CEN-COB-003 |
| **Etapa 0** | Mecanismo de ativação · estrutura Maven e de pacotes · estratégia de migrations de módulo desabilitado (A, B ou C) · identificadores técnicos — o do Atendimento pode ser `services` · ferramenta de verificação |
| **Implementação do módulo** | Rota de leitura × agrupamento do ciclo — Etapa 3 · conteúdo dos contratos, com o primeiro par que os usa — Etapa 1 · testemunha do termo de parcelamento sem o Atendimento — Etapa 6 · escopo territorial fino do perfil ATENDIMENTO sem o Commercial · unidade de capacidade do PCM e escopo nativo do Networks sem Giswater — trilha estrutural · portal sem o Commercial — Etapa 8 |
| **Futuro** | Automação SINISA por mapeamento · telemedição/AMI · novos perfis de referência · versão por módulo |

---

## 12. Riscos remanescentes

Só os que poderiam forçar reestruturação, perda de compatibilidade, erro financeiro ou regulatório, ou acoplamento forte:

| # | Risco | Mitigação já registrada |
| - | ----- | ----------------------- |
| 1 | A restrição de modularidade não nascer na Etapa 0 — retrofit caro | CEN-MOD-006 e 007 no gate 0 → 1 |
| 2 | A primeira fatia — Cadastro × RA — atravessar dois instaláveis por atalho de repositório | Contrato nasce com ela (módulos §22) |
| 3 | Estratégia de migrations de módulo desabilitado mal escolhida | Critérios fixados na módulos §20; decisão na Etapa 0 |
| 4 | Capacidade condicionada virar execução paralela no Assets | CEN-MOD-004 V4 verifica que nada registra execução |
| 5 | Adapter externo virar dono de regra; snapshot virar cadastro | ADR-0010 — o adapter traduz; snapshot pertence ao registro |
| 6 | Rota como conceito de junção | Decisão na Etapa 3, com a equivalência de CEN-CAD-005 |

---

## 13. Correções executadas

| # | Inconsistência | Correção |
| - | -------------- | -------- |
| 1 | Instalável *Services* escondia o RA | **Atendimento** — RA · OS · Campo — em todos os documentos vigentes; registros históricos com nota |
| 2 | Estrutura organizacional na Platform sem passar no critério | Movida para o **Atendimento** (§7.2 da módulos), com evidência do código |
| 3 | Contexto institucional na Platform sem justificativa escrita | Justificado — dimensão do parâmetro regulado; perfis sem Commercial o usam |
| 4 | Provedores obrigatórios além do necessário — Metering e Assets | Rebaixados a condição de capacidade; CEN-MOD-004 V4 revisto |
| 5 | Adapters "em Integrações" — arquitetura alvo, SINISA, Fiscal | Infraestrutura na Platform; adapter no módulo dono |
| 6 | PCM: *pacote de trabalho* podia ser lido como ordem; equipe sem dono explícito | Pacote = atributos da necessidade, não emitido nem executado; equipe do Atendimento ou do externo |
| 7 | Visão §27.2 punha o Atendimento sob *Gestão Comercial* | Nota de supersessão — o agrupamento não define dono |
| 8 | CEN-COB-003 não observava a ausência de RA | Observável e localizador acrescentados |
| 9 | Glossário: tabelas de terminologia no meio da lista de pontos em aberto | Lista reunida; terminologia depois dela; termos da revisão acrescentados |

---

## 14. Veredito

**SIM.**

Arquitetura consolidada e revisada. Fase 0 permanece concluída. Adendos incorporados. Próximo estágio permanece conforme o plano vigente.

Depois das correções acima — todas documentais, de terminologia, de ownership ou de obrigatoriedade, sem decisão estrutural nova —, a resposta à pergunta-guia é **não**: nenhuma contradição, dependência acidental, responsabilidade duplicada ou lacuna estrutural conhecida obriga reestruturação grande. O que resta está na §11, cada item no seu momento.
