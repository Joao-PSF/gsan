# Dependências e Ordem de Implementação do OpenGSAN

> **Fase 0 — 18ª execução (2026-09-15).** Define **sequência e gates**, não cronograma. Nenhuma tabela, migration, entidade ou API é criada aqui.
>
> Fontes: [mapa de domínio](../dominio/mapa-de-dominio.md) (ownership, 14 fronteiras, 7 ciclos) · [visão conceitual](../dominio/visao-conceitual-opengsan.md) (core × plataforma, fronteiras, decisões pendentes) · [compatibilidade](../compatibilidade/estruturas-centrais.md) (64 decisões) · [funcionalidades futuras](funcionalidades-futuras.md) (26 capacidades) · [estratégia de testes](../testes/estrategia-testes.md) · [arquitetura alvo](../arquitetura/arquitetura-alvo.md) · ADRs [0001](../decisoes/0001-monolito-modular-spring-boot.md), [0002](../decisoes/0002-flyway-para-migrations.md), [0007](../decisoes/0007-arquitetura-de-interface.md). **Nenhum módulo foi reanalisado.**

---

## 1. Objetivo

Responder a uma pergunta única:

> **Qual sequência permite construir o OpenGSAN de forma incremental, validável e segura, colocando cada dependência antes da capacidade que precisa dela?**

⚠️ A pergunta **não** é "qual módulo é mais fácil" nem "qual era a ordem antiga".

### 1.1 🔴 Três coisas que este documento não confunde

A distinção governa todo o resto:

| Conceito | Exemplo | Consequência |
| -------- | ------- | ------------ |
| **Dependência de domínio** | Faturamento depende de Consumo | Permanente; é do negócio |
| **Dependência de implementação** | Para implementar Faturamento é preciso um **contrato** de Micromedição | Satisfeita por contrato, não por módulo completo |
| **Ordem de entrega** | Micromedição **não** precisa estar 100% pronta antes da primeira linha de Faturamento | O que precisa estar pronto é a capacidade consumida |

🔵 **Quase todo erro de ordenação nasce de tratar as três como uma só.** A ordem antiga (§29) errou exatamente assim.

---

## 2. Critérios

Cada capacidade foi pontuada em `BAIXO / MÉDIO / ALTO`. ⚠️ Sem aritmética artificial: os critérios explicam a posição, não a calculam.

| Critério | O que mede |
| -------- | ---------- |
| **Dependências** | Quantas capacidades precisam existir antes |
| **Risco financeiro** | Consequência de erro em dinheiro |
| **Risco operacional** | Consequência de erro na operação |
| **Valor de validação arquitetural** | Quanto a capacidade prova sobre a arquitetura |
| **Valor funcional** | Utilidade percebida por quem usa |
| **Complexidade** | Esforço e sutileza da regra |
| **Consumidores** | Quantos módulos dependem dela depois |
| **Testabilidade** | Facilidade de caracterizar e comparar |
| **Necessidade para os próximos** | Se destrava ou não o passo seguinte |

### 2.1 Regra de desempate

Quando dois candidatos empatam, vence o que **destrava mais capacidades seguintes** — não o de maior valor funcional imediato. 🔵 Razão: valor entregue cedo em capacidade sem consumidores não reduz retrabalho; dependência satisfeita cedo reduz.

---

## 3. Core × plataforma

⚠️ 🔴 **As dez áreas não são dez itens de uma fila.** Ordená-las como iguais é o primeiro erro a evitar ([visão conceitual §7–8](../dominio/visao-conceitual-opengsan.md)).

| Natureza | Áreas | Como entra na ordem |
| -------- | ----- | ------------------- |
| **Core de negócio** | Cadastro · Micromedição · Faturamento · Cobrança · Arrecadação · Atendimento | Sequência por dependência; cada um tem conceitos próprios |
| **Plataforma** | Segurança · Processamento · Relatórios · Integrações | ⚠️ **Não são etapas** — são capacidades que nascem parcialmente na fundação e crescem junto dos módulos |

### 3.1 🔴 O princípio que evita a dependência artificial

> **Nunca**: "precisa terminar Segurança inteira para começar Cadastro".
> **Sempre**: "precisa existir autenticação e concessão mínima antes do primeiro fluxo protegido".

Aplicado às quatro capacidades de plataforma:

| Plataforma | Parte que nasce na fundação | Parte que cresce depois |
| ---------- | --------------------------- | ----------------------- |
| **Segurança** | Identidade, autenticação, concessão por caso de uso, auditoria mínima | Escopo territorial, administração completa, delegação, fluxo de solicitação |
| **Processamento** | ⚠️ **Nada** — ver §16 | Assíncrono genérico; batch de domínio |
| **Relatórios** | Convenção de artefato e controle de acesso a ele | Motor e relatórios por módulo dono |
| **Integrações** | **Convenções** de contrato (idempotência, erro durável, identidade de dispositivo) | Camada implementada + adapters por módulo dono |

🔵 **Processamento é o único que não tem parte fundacional**, e a razão é estrutural: um orquestrador sem operação para orquestrar não tem o que fazer. A dependência é inversa — ver §16.

---

## 4. Fundação mínima

### 4.1 NECESSÁRIO NO DIA 1

⚠️ Critério para entrar nesta lista: **retrofit obrigaria revisitar código já escrito**. Não é "importante" — é "caro depois".

| # | Item | Por que no dia 1 |
| - | ---- | ---------------- |
| 1 | **Projeto Maven multi-módulo com fronteiras declaradas** | ADR-0001 |
| 2 | 🔴 **Verificação automatizada de fronteira** (ArchUnit ou equivalente) | A própria ADR-0001 registra: *"sem isso, o modular degrada para não modular"*. Introduzir depois significa descobrir violações já espalhadas |
| 3 | **Conexão PostgreSQL 18 + Flyway desde `V1`** | ADR-0002; schema versionado desde a primeira tabela, sem baseline do legado |
| 4 | **Testes com Testcontainers sobre o schema real** | [Estratégia de testes](../testes/estrategia-testes.md): repositório testado contra o schema verdadeiro, **nunca H2**. Infraestrutura de teste criada depois não é criada |
| 5 | 🔴 **Convenção de valor monetário e políticas de arredondamento nomeadas** | O legado tem **5 políticas semânticas distintas** e a compatibilidade classificou isso como **`PRESERVAR` — comportamento, não dívida**. Decidir o tipo e a política depois obriga revisitar toda linha financeira |
| 6 | 🔴 **Auditoria mínima** (quem, quando, o quê, valor anterior) | Retrofit de auditoria obriga revisitar **toda escrita** já existente. No plano antigo isso estava na Fase 10 — defeito corrigido (§29) |
| 7 | **Identidade + autenticação** | O primeiro fluxo já é protegido |
| 8 | **Concessão por caso de uso / operação** | Estrutura, não administração completa. ⚠️ Expressa em **caso de uso**, nunca em rota — ver §4.3 |
| 9 | **Convenções de domínio**: identidade ≠ versão ≠ linhagem | [Visão conceitual §21](../dominio/visao-conceitual-opengsan.md). É o padrão estrutural nº 2 do GSAN; aplicá-lo depois muda chaves já criadas |
| 10 | **Tratamento de erro + log estruturado com identificador de correlação** | Barato agora; reescrita transversal depois |
| 11 | **Configuração externalizada, sem hard-code institucional** | 🟢 O GSAN falha em três pontos (nome de empresa, URL fixa, campo institucional). Requisito de software livre — §26 |
| 12 | **CI: build + testes + `V1` em banco limpo + *secret scan*** | 🔴 O *secret scan* é dia 1 por evidência própria: o legado versionou chave de API em código-fonte (achado 11 / D-08) |
| 13 | **Ambiente reproduzível (compose) + massa sintética** | Requisito de software livre e de teste; massa real exigiria anonimização (LGPD) |

### 4.2 PODE EVOLUIR DEPOIS

| Item | Quando | Por que não no dia 1 |
| ---- | ------ | -------------------- |
| **Escopo territorial (abrangência)** | Etapa 2 | 🔴 **Depende de Cadastro** — ver §4.4 |
| Administração de grupos, permissões especiais, delegação, fluxo de solicitação | Etapa 2+ | Nenhum fluxo inicial precisa; são telas de administração |
| Observabilidade completa (métricas, alertas, painéis) | Etapa 2+ | *Health check* e log estruturado bastam para o primeiro fluxo |
| Motor de relatório | Etapa 2 | Nasce no primeiro caso real, conforme §17 |
| Camada de integração implementada | Etapa 3 | Nasce no primeiro adapter real, conforme §18 |
| Processamento assíncrono | Etapa 5 | Ver §16 |
| Parametrização multiempresa (`shared`) | Etapa 4 | O primeiro ponto de variação real é tarifário |

### 4.3 🔴 A concessão precisa ser expressa em caso de uso, não em rota

🟢 No GSAN a unidade de autorização **é a URL** (`FiltroSegurancaAcesso` sobre `*.do`), e a ADR-0007 registra que a unidade de autorização depende da decisão de interface.

🔵 **Consequência para a fundação**: se a concessão nascer amarrada a rota, ela terá de ser refeita caso a ADR-0007 decida por API. Expressa em **caso de uso/operação**, sobrevive a qualquer das três opções. Isso torna a fundação **independente da ADR-0007** (§27).

### 4.4 🔴 Segurança depende de Cadastro — uma dependência que faltava

⚠️ **Achado desta execução.** A abrangência territorial é definida sobre gerência regional, unidade de negócio, elo/polo e localidade — e 🟢 **a estrutura territorial pertence ao Cadastro** ([mapa de domínio §7](../dominio/mapa-de-dominio.md)).

```text
Cadastro ──estrutura territorial──► Segurança (eixo de escopo)
Segurança ──autorização──► Cadastro (telas do módulo)
```

🔵 É um **oitavo ciclo**, não listado entre os sete do mapa de domínio — porque lá a leitura era de domínio, e este é de **implementação**.

🔴 **Consequência direta**: o escopo territorial **não pode** ser implementado antes de existir estrutura territorial. Isso torna impossível uma "Segurança completa" antes do Cadastro — e é a razão pela qual a Segurança se divide em três (§9), não em duas.

---

## 5. Matriz de dependências

Tipos: **DURA** (B não funciona sem A) · **PARCIAL** (só parte de B depende) · **TRANSVERSAL** (usada por vários) · **OPERACIONAL** (B solicita ação, não depende da estrutura interna) · **CONSULTA** (B lê dados de A) · **FUTURA** (capacidade fora do core inicial).

| # | Origem | Depende de | Tipo | Motivo | Pronto antes? |
| - | ------ | ---------- | ---- | ------ | ------------- |
| 1 | Micromedição | Cadastro | **DURA** | Imóvel, ligação e situação, rota/sequencial, limiares por categoria | **Sim** — Cadastro mínimo |
| 2 | Faturamento | Cadastro | **DURA** | Economias e categoria definem o mínimo (Σ tarifa × economias por categoria) | **Sim** — Cadastro mínimo |
| 3 | Faturamento | Micromedição | **DURA** | Consumo é insumo obrigatório do cálculo | **Sim, o contrato**; não o módulo inteiro |
| 4 | Faturamento | Tarifa por vigência | **DURA** | Interna ao próprio Faturamento | Sim (mesma etapa) |
| 5 | Micromedição | Faturamento (consumo mínimo) | **CONSULTA** | 🟢 Micromedição lê tarifa mínima para a crítica | Não — é leitura, resolvível por contrato |
| 6 | Cobrança | Faturamento | **DURA** | 🔴 **Não existe dívida sem documento emitido.** A posição de dívida é derivada de documentos | **Sim** |
| 7 | Cobrança | Arrecadação | **PARCIAL / validação** | 🔴 A posição de dívida reflete recebimentos **por derivação** — sem pagamentos ela compila, mas **não pode ser validada** | **Sim, para validar** |
| 8 | Arrecadação (aplicação) | Faturamento / Cobrança | **DURA** | Precisa da identidade do documento pagável | **Sim** |
| 9 | Arrecadação (recepção) | — | **nenhuma** | 🟢 Movimento do arrecadador é registro bruto com totais de conferência | **Não** — pode ser a primeira capacidade financeira de todas |
| 10 | Atendimento | Cadastro | **PARCIAL** | Precisa de imóvel/cliente para o caso típico, mas 🟢 **a matrícula é opcional** no RA | **Sim, o mínimo** |
| 11 | Atendimento | Segurança | **TRANSVERSAL** | Identidade na tramitação, autoria, auditoria | **Sim** — fundação de segurança |
| 12 | OS | Atendimento | **DURA** | OS é a unidade de execução da demanda | **Sim** |
| 13 | OS | Cadastro · Micromedição · Cobrança · Faturamento | **OPERACIONAL** | 🔴 A OS **solicita** o efeito; o dono aplica | **Não** — cada efeito entra quando seu dono existe |
| 14 | Todos | Segurança | **TRANSVERSAL** | Autenticação, concessão, auditoria | **Sim**, na parte fundacional |
| 15 | Segurança (escopo) | Cadastro (território) | **DURA** | §4.4 | **Sim** — inverte a ordem antiga |
| 16 | Processamento | Operação individual determinística | **DURA** | 🔴 Dependência **inversa**: orquestrador sem operação não tem o que orquestrar | **Sim** — a operação vem primeiro |
| 17 | Processamento | Segurança (catálogo) | **TRANSVERSAL** | 🟢 No legado as etapas **são** funcionalidades do catálogo | Sim (já existe) |
| 18 | Relatórios | Módulo dono da consulta | **CONSULTA** | 🟢 A regra pertence ao dono do dado | Progressivo |
| 19 | Integrações (camada) | Módulo dono do efeito | **OPERACIONAL** | 🔴 Integração traduz e entrega; **não é dona do domínio** | Convenção antes; adapter com o dono |
| 20 | Canal digital | Cadastro · Faturamento · Cobrança · Atendimento | **DURA** | 🔵 É **camada consumidora**, não dona de domínio | **Sim, os quatro** |
| 21 | Canal digital | Identidade do cliente final | **DURA** | 🔴 Modelo **distinto** do usuário interno | **Sim** |
| 22 | PIX | Documento · Recebimento · Conciliação · Contrato com PSP | **FUTURA/DURA** | Urgência não altera dependência | **Sim** |
| 23 | Boleto registrado | Documento · Recebimento · Contrato bancário | **FUTURA/DURA** | Idem | **Sim** |
| 24 | Notificação | Evento de negócio + contrato de canal | **TRANSVERSAL/FUTURA** | Nasce no primeiro evento real a notificar | Não |
| 25 | SPED | Documento fiscal | **FUTURA/DURA** | 🟢 Cadeia confirmada: SPED → fiscal → documento comercial | **Sim** |
| 26 | Analytics | Todos | **CONSULTA** | 🔵 Consome, não produz | **Não bloqueia** — ver §20 |

### 5.1 Onde a matriz contraria a intuição

| Intuição | O que a matriz mostra |
| -------- | --------------------- |
| "Cobrança é mais simples que Faturamento, vem antes" | **#6** — sem documento emitido não existe dívida a cobrar |
| "Arrecadação depende de tudo, vem no fim" | **#9** — a *recepção* não depende de nada financeiro |
| "Batch é infraestrutura, vem no começo" | **#16** — a dependência é inversa |
| "Segurança é transversal, resolve-se antes do domínio" | **#15** — o escopo territorial depende do Cadastro |
| "PIX é urgente, então é cedo" | **#22** — urgência não é dependência |

---

## 6. Dependências duras

As que **determinam** a sequência. Nenhuma pode ser contornada por contrato temporário sem risco de retrabalho:

```text
Cadastro mínimo
    ├──► Micromedição ──────────┐
    ├──► Atendimento            │
    ├──► Segurança (escopo)     │
    └──► Faturamento ◄──────────┘
             │
             ├──► Arrecadação (classificação/aplicação)
             │              │
             └──► Cobrança ◄┘ (validação)
                      │
                      └──► Canal digital ──► PIX / boleto registrado
```

🔴 **A cadeia financeira é a espinha da ordem** e tem direção única: **documento → recebimento → dívida**. Ela não admite inversão, porque cada elo cria o objeto que o próximo consome.

---

## 7. Dependências parciais

🔵 São as que permitem **incrementalidade real** — cada uma é um ponto onde a ordem pode avançar sem completar o módulo anterior.

| Dependência | Parte que bloqueia | Parte que não bloqueia |
| ----------- | ------------------ | ---------------------- |
| Faturamento → Micromedição | Consumo faturado com origem declarada | Anormalidades, rota alternativa, telemetria, correção por idade |
| Atendimento → Cadastro | Imóvel e cliente legíveis | Economia, categorias avançadas, histórico |
| Cobrança → Arrecadação | Noção de documento quitado | Conciliação, devolução, débito automático, encerramento contábil |
| Arrecadação → Faturamento | Identidade do documento pagável | Retificação, cancelamento, prescrição |
| OS → donos | Nenhuma no início — a OS pode encerrar sem efeito | Cada "Efetuar…" entra quando o dono existe |
| Segurança → Cadastro | Estrutura territorial (para escopo) | Todo o resto da autorização |
| Relatórios → módulos | Nada; o relatório segue o dono | Todos os relatórios |

### 7.1 🔴 O que **não** pode ser simulado por stub

⚠️ Distinção crítica, porque "pode ser stub" é a desculpa mais comum para inverter uma ordem:

| Pode ser contrato temporário | 🔴 NÃO pode |
| ---------------------------- | ----------- |
| Consumo, como entrada fixa nos primeiros testes do motor de cálculo | **A Conta.** Simulá-la significa fabricar o objeto financeiro mais sensível do sistema — e validar Cobrança contra uma ficção |
| Efeito operacional da OS, antes de o dono existir | **O recebimento.** Baixa sem recebimento real não prova a única coisa que a Arrecadação precisa provar |
| Notificação, como registro de intenção | **A identidade do documento.** É o que torna a dívida rastreável; é decisão estrutural, não detalhe |
| Contrato externo, por *fake* de PSP/banco | **A política de arredondamento.** Não é detalhe de implementação: é comportamento `PRESERVAR` |

---

## 8. Ciclos

Os sete ciclos do [mapa de domínio §10](../dominio/mapa-de-dominio.md) **não desaparecem** — são de negócio. A visão conceitual já definiu a forma: **solicitação/resposta entre responsáveis**, nunca escrita cruzada.

🔵 A pergunta aqui é outra e é de implementação: **algum ciclo impede construir em sequência?** Resposta: **nenhum** — e a razão é sempre a mesma, o que é um bom sinal de que o modelo de ownership está certo.

| # | Ciclo | Estado autoritativo | Quem só solicita | Impede sequência? | Contrato temporário? | Entra primeiro |
| - | ----- | ------------------- | ---------------- | ----------------- | -------------------- | -------------- |
| 1 | Cadastro ↔ Atendimento | **Cadastro** (ligação e situação) | Atendimento | **Não** | Sim — RA sem efeito cadastral | **Cadastro** |
| 2 | Micromedição ↔ Atendimento | **Micromedição** (hidrômetro, instalação) | Atendimento | **Não** | Sim — OS automática por anormalidade é capacidade posterior | **Micromedição** |
| 3 | Cobrança ↔ Atendimento | Cada um do seu lado | Cobrança solicita OS | **Não** | Não precisa: Atendimento já existirá | **Atendimento** (por ordem geral) |
| 4 | Faturamento ↔ Micromedição | **Micromedição** (consumo, sempre) | Faturamento | **Não** | Sim — consumo como entrada fixa | **Micromedição** |
| 5 | Faturamento ↔ Cobrança | **Faturamento** (conta, débito, crédito) | Cobrança solicita derivados | **Não** | 🔴 **Não** — a Conta não se simula | **Faturamento** |
| 6 | Cobrança ↔ Arrecadação | **Arrecadação** (recebimento) | Cobrança deriva | **Não** | Parcial — posição de dívida sem pagamento é incompleta | **Arrecadação** |
| 7 | Segurança ↔ Processamento | **Segurança** (catálogo) | Processamento | **Não** | Sim | **Segurança** |
| 8 | Cadastro ↔ Segurança (escopo) — **novo, §4.4** | **Cadastro** (território) | Segurança | **Não** | 🔴 **Não** — escopo sobre território inexistente não é testável | **Cadastro** |

### 8.1 🔵 Por que nenhum ciclo bloqueia

Todos os oito têm a mesma anatomia:

```text
lado A  detém o estado
lado B  solicita a mudança
        ↓
o ciclo só se fecha quando a CAPACIDADE DE EFEITO é implementada —
e essa capacidade é sempre posterior ao núcleo de cada lado
```

🔵 **Conclusão**: o ciclo é de **negócio**, mas o *acoplamento de implementação* está concentrado na capacidade de efeito, não no núcleo. Construir o núcleo de A, depois o núcleo de B, e só então o efeito A↔B rompe o ciclo **sem stub e sem acoplamento direto**.

⚠️ **Risco a vigiar**: nada disso funciona se a capacidade de efeito for implementada como chamada direta ao estado alheio. É exatamente o que o legado fez em `ControladorRetificarConta:273` (divergência **D-14**), e é por isso que a verificação automatizada de fronteira é item de **dia 1** (§4.1-2).

---

## 9. Capacidades transversais

### 9.1 🔴 Segurança não é uma fase

O plano antigo tem **Fase 5 — Segurança**, entre a fundação e o piloto. ⚠️ Correção honesta: **o plano antigo não põe segurança depois do domínio** — ele já a coloca antes do piloto, e nisso está correto. O defeito é outro, e é mais sutio:

🔴 **"Segurança completa antes do domínio" é estruturalmente impossível**, porque a abrangência territorial depende da estrutura territorial do Cadastro (§4.4). A Fase 5 do plano antigo promete um entregável que não pode existir no ponto em que está agendada.

Divisão derivada — **três**, não duas:

| Bloco | Conteúdo | Posição | Depende de |
| ----- | -------- | ------- | ---------- |
| **S1 — Identidade e concessão** | Autenticação (BCrypt/Argon2), identidade, concessão por caso de uso, auditoria mínima, sessão/CSRF/headers | 🔴 **Etapa 0** | Nada de domínio |
| **S2 — Escopo territorial** | Abrangência garantida por construção (divergência **D-17**), não lembrada em cada consulta | **Etapa 2** | Cadastro (território) · D-17 aprovada |
| **S3 — Administração completa** | Grupos, permissões especiais nomeadas, delegação, fluxo de solicitação de acesso, expiração/bloqueio | **Etapa 2+**, progressivo | S1 |

🟢 **Por que S2 é bloco próprio e não detalhe de S1**: no legado a abrangência **depende de chamada explícita em cada consulta** — é a falha estrutural nº 1 da segurança mapeada. Corrigi-la "por construção" é decisão de desenho que atravessa toda consulta de domínio; misturá-la em S1 esconderia que ela tem pré-requisito de domínio.

### 9.2 Auditoria

🔴 **Dia 1**, não Fase 10. O legado tem auditoria em dois níveis (operação efetuada + alteração por linha/coluna). Auditoria adicionada depois obriga revisitar **toda escrita existente** — retrabalho de custo proporcional ao código já escrito.

⚠️ E deve nascer com a distinção que a visão conceitual estabeleceu: **auditoria ≠ histórico de negócio**. Um é plataforma, o outro é domínio. Confundi-los cria "histórico" que não serve para auditar e auditoria que não serve para o negócio.

### 9.3 Testes

Sem fase própria. O que a ordem usa dos ~110 cenários inventariados é **risco**, para posicionar gates (§25). ⚠️ A especificação formal dos cenários é **atividade pendente da Fase 0** e não é feita aqui.

---

## 10. Cadastro mínimo

🔴 **Cadastro mínimo ≠ Cadastro.** Separar é o que permite tudo começar.

### 10.1 Cadastro estrutural mínimo (Etapa 1)

| Capacidade | Por que no mínimo | Consumidores imediatos |
| ---------- | ----------------- | ---------------------- |
| **Imóvel / matrícula** | 🟢 123 FKs apontam para ele — é a identidade central do sistema | Todos |
| **Cliente e Cliente × Imóvel com papel e vigência** | Sem papel não há a quem cobrar nem quem atende | Atendimento, Faturamento, Cobrança |
| **Estrutura territorial** (localidade → setor → quadra → rota) | 🔴 Pré-requisito de **S2** (§4.4) e da unidade de processamento do faturamento | Segurança, Micromedição, Processamento |
| **Categoria / subcategoria** | Determina tarifa e limiares de crítica | Faturamento, Micromedição |
| **Economias** | 🔴 Entra no mínimo porque o valor mínimo é Σ tarifa × economias **por categoria** | Faturamento |
| **Ligação (água/esgoto) e sua situação** | 🔴 A visão conceitual moveu a situação para a **Ligação** — a correção precisa nascer aqui, não ser retrofit | Faturamento (faturabilidade), Cobrança |

⚠️ **Economias entram no mínimo mesmo sem individualização decidida** (pendência 6 da visão conceitual): o conceito e a composição são necessários; a individualização não.

### 10.2 Fora do mínimo

Recadastramento em massa · histórico de situação de primeira classe (pendência 7) · benefício social · atributos avançados de imóvel · condomínio/macromedição · integração GIS · unidades auxiliares extensas.

🔵 O **DV da matrícula** é variação por companhia ([catálogo §21](funcionalidades-futuras.md)): entra no mínimo como **ponto de extensão configurável**, não como regra no núcleo — e isso não exige o inventário completo de variantes (pendência 2).

---

## 11. Atendimento e OS

### 11.1 Por que o Atendimento é candidato forte — com a evidência

🔵 Não por ser fácil. Por seis propriedades verificadas:

| Propriedade | Evidência |
| ----------- | --------- |
| Risco financeiro **BAIXO** | Efeitos financeiros existem, mas são *solicitados*; o dono é outro módulo |
| Valor funcional **ALTO** | É a porta de entrada da operação real |
| 🔴 Exercita **regra como dado** | `SolicitacaoTipoEspecificacao` é o **núcleo paramétrico** do módulo: prazo, obrigatoriedades, geração de OS, efeitos, encerramento automático. É o padrão estrutural nº 1 do GSAN |
| Exercita **workflow com estado e histórico** | Tramitação auditável + `unid_idatual` como estado corrente; prazo original × atual |
| Exercita **autorização e auditoria** | Autoria da tramitação, unidade organizacional |
| 🔴 É onde vive o **contrato central** do OpenGSAN | "Atendimento solicita, o dono aplica" — [visão conceitual §14.3](../dominio/visao-conceitual-opengsan.md) |

⚠️ **Contra-argumento registrado**: o Atendimento participa de **três dos sete ciclos** — é o nó mais conectado depois do Imóvel. Começar por ele significa exercitar o contrato de solicitação **antes de os donos financeiros existirem**, com risco de moldá-lo só por casos operacionais.

🔵 **Mitigação, não descarte**: o contrato de efeito é desenhado na Etapa 2 e **revisado contra a lista de efeitos financeiros** (débito de serviço, crédito, guia, retificação, alteração de vencimento) antes de ser considerado estável. Revisar um contrato documentado é barato; descobri-lo errado depois de quatro módulos o usarem, não.

### 11.2 Ordens de serviço

OS vem **depois** de uma base de Atendimento (dependência DURA #12), e seus efeitos entram **progressivamente**:

| Efeito da OS | Entra quando | Etapa |
| ------------ | ------------ | ----- |
| Encerrar sem efeito em outro domínio | Imediato | 2 |
| Efeito na **ligação** (ligar, religar, suprimir) | Ligação existe no Cadastro | 2 |
| Efeito no **hidrômetro** (instalar, substituir, retirar) | Micromedição existe | 3 |
| **Fiscalização de leitura** | Micromedição existe | 3 |
| Efeito **financeiro** (débito de serviço, crédito, guia) | Faturamento existe | 4 |
| OS originada em **ação de cobrança** | Cobrança existe | 6 |
| **Evidência de campo** (fotos) e execução móvel | Camada de integração existe | 3+ |

🟢 Isso confirma que OS **não é uma entrega única**: é um núcleo (Etapa 2) mais uma série de efeitos que acompanham seus donos. ⚠️ A cardinalidade física RA ↔ OS permanece pendência (10) resolvível na Etapa 2.

---

## 12. Micromedição

Decomposição pedida, com a conclusão: **duas etapas de capacidade, não uma**.

| Ordem | Capacidade | Depende de | Risco | Observação |
| ----- | ---------- | ---------- | ----- | ---------- |
| 1 | **Hidrômetro** (equipamento) | Cadastro mínimo | BAIXO | 🔴 Separação equipamento × instalação é `PRESERVAR` |
| 2 | **Instalação** (vínculo com ligação, vigência) | Hidrômetro, Ligação | MÉDIO | Leituras de fronteira na troca |
| 3 | **Leitura** (informada, com origem) | Instalação, rota, cronograma | MÉDIO | Par **informado × faturamento** é `PRESERVAR` |
| 4 | 🔴 **Consumo** (real · média · mínimo, com origem tipificada) | Leitura + tarifa mínima (consulta) | **ALTO** | É a saída que o Faturamento consome. **Gate de golden master** |
| 5 | **Anormalidades** paramétricas com ações escalonadas | Consumo | MÉDIO | Emite OS — fecha o ciclo 2 |

🔵 **Onde cortar**: capacidades 1–4 são **pré-requisito do Faturamento**; a 5 não é. Anormalidades podem entrar depois do primeiro faturamento individual, junto do ciclo com o Atendimento.

⚠️ O consumo mínimo vem da tarifa, que é do Faturamento (dependência de **consulta** #5) — resolvida por contrato de leitura, sem inverter a ordem.

---

## 13. Faturamento

### 13.1 🔴 A decisão mais importante da ordem: individual antes do lote

🟢 **Evidência que sustenta**: `gerarConta(Imovel, anoMesFaturamento, SistemaParametro, ...)` é o **método central reutilizável** — o lote o invoca imóvel a imóvel, e existe fluxo de faturamento individual fora do lote (`FaturamentoImediatoAjuste`). O mapa do Faturamento registra: *"mesmo cálculo no individual e no lote"*.

🔵 **Três consequências**:

1. O **motor de cálculo individual** é uma unidade determinística com entrada pequena e saída comparável **ao centavo** — o candidato ideal a primeiro golden master financeiro.
2. O **lote é orquestração** (unidade = rota do cronograma) sobre o mesmo cálculo. Separar é honrar a estrutura que o legado já tem.
3. 🔴 Construir o lote antes do cálculo comprovado seria **desenvolver batch para regra não estabilizada** — o antipadrão que §16 evita.

### 13.2 Por que o Faturamento não é "o último de tudo"

⚠️ Há diferença real entre duas coisas que a ordem antiga tratou como uma:

| | |
| - | - |
| **implementar tarde o bastante para haver maturidade** | ✅ correto |
| **adiar até o fim e descobrir tarde que a arquitetura não suporta o núcleo** | 🔴 é o risco que a ordem antiga corria |

🔵 O Faturamento é onde o OpenGSAN prova que **preservou o que o GSAN acertou** — e a compatibilidade mostrou que o Faturamento é o módulo **mais preservado em proporção (7 de 10 decisões)**, apesar de ser o de maior risco financeiro. As decisões que ele carrega (precisão, snapshots, tarifa versionada, identidade estável) são as que **mais restringem o desenho**. Descobrir na Etapa 8 que a fundação não as suporta é exatamente o retrabalho que esta ordem existe para evitar.

🔴 **Portanto**: o motor individual entra **no meio da sequência (Etapa 4)**, não no fim — cedo o bastante para validar a arquitetura financeira, tarde o bastante para ter cadastro e medição reais.

### 13.3 Decomposição

| Ordem | Capacidade | Risco | Observação |
| ----- | ---------- | ----- | ---------- |
| 1 | **Estrutura tarifária versionada** (categorias, faixas, mínimos) | ALTO | `PRESERVAR`; é regra como dado |
| 2 | **Faturabilidade** por situação | MÉDIO | Paramétrica |
| 3 | 🔴 **Motor de conta individual** | **ALTO** | Gate de golden master |
| 4 | **Conta + contexto congelado (snapshots)** | ALTO | 🔴 `PRESERVAR`: parecem desnormalização, **são auditoria retroativa** |
| 5 | **Identidade estável do documento** (`ContaGeral` 1:1 corrente/histórico) | ALTO | Semântica inegociável; estrutura a reestruturar |
| 6 | **Débito · Crédito · Guia** | MÉDIO | Faturamento é dono; outros criam **através dele** |
| 7 | Retificação (conta encadeada) · cancelamento como estado | ALTO | 🔴 A retificação exige a **operação exposta pela Micromedição** (D-14) — não escrita direta |
| 8 | Impostos deduzidos | MÉDIO | ⚠️ Truncamento em base de imposto é uma das 5 políticas |
| 9 | Faturamento em lote | ALTO | **Etapa 7**, não aqui |

### 13.4 🔴 Golden master financeiro influencia o desenho cedo

Mesmo com o Faturamento na Etapa 4, os 13 golden masters financeiros já identificados atuam **antes**: a convenção de valor monetário e as 5 políticas de arredondamento são item de **dia 1** (§4.1-5). ⚠️ **Proibido unificar em HALF_UP sem decisão registrada** — o legado tem 27 HALF_UP, 21 UP, 5 DOWN, 2 HALF_DOWN e 2 FLOOR, e `setScale(2, ROUND_DOWN)` em base de imposto.

---

## 14. Cobrança

### 14.1 Dependência real

🔴 **Cobrança depende de Faturamento de forma dura** (#6): a posição de dívida é **derivada dos documentos**; sem documento emitido não há dívida. E depende de Arrecadação **para ser validada** (#7): a posição reflete recebimentos por derivação — sem pagamentos ela compila e mente.

🔵 Distinção que importa: dependência de **compilação** (Faturamento) × dependência de **correção** (Arrecadação). Ambas colocam a Cobrança **depois das duas**.

### 14.2 Decomposição

| Ordem | Capacidade | Depende de | Risco |
| ----- | ---------- | ---------- | ----- |
| 1 | **Posição de dívida** (consulta derivada, conceito nomeado) | Faturamento + Arrecadação | ALTO |
| 2 | **Situação de cobrança do imóvel** | 🔴 Muda de dono: vai para a Cobrança | MÉDIO |
| 3 | **Política e ação** (predecessora, critério, situações-alvo, OS) | Posição de dívida, Atendimento | MÉDIO |
| 4 | **Documento de cobrança com itens rastreáveis** | Ação | MÉDIO |
| 5 | 🔴 **Parcelamento** (composição + memória financeira integral) | Documento, Faturamento (prestações) | **ALTO** |
| 6 | Desfazimento automático por entrada não paga, com estornos | Parcelamento, Arrecadação | ALTO |
| 7 | Reparcelamento encadeado | Parcelamento | ALTO |
| 8 | Negativação por cliente · terceirização por carteira | Integrações | MÉDIO |

⚠️ **Parcelamento é a regra financeira mais complexa do sistema** e fica tarde por dependência, não por escolha. 🔵 Mitigação do risco de descoberta tardia: a posição de dívida (capacidade 1) é exercitada **já na Etapa 5**, como consulta de leitura sobre contas e pagamentos — antes de existir qualquer política. Assim o conceito mais estrutural da Cobrança é validado uma etapa antes do módulo.

### 14.3 Pendências que não bloqueiam

Fórmulas de acréscimo por impontualidade (pendência 8) e formalização de "obrigação financeira" (pendência 9, **`PROPOSTO`**) são decidíveis ao implementar. ⚠️ 🔴 Não criar a superentidade antes: o risco de abstração errada aqui contamina Faturamento, Cobrança e Arrecadação **de uma vez**.

---

## 15. Arrecadação

### 15.1 🔴 Não é uma peça única — e um pedaço dela não depende de nada

🟢 A visão conceitual preservou **quatro momentos distintos**. A ordem os usa:

| Ordem | Capacidade | Depende de | Risco | Quando |
| ----- | ---------- | ---------- | ----- | ------ |
| 1 | **Recepção** — movimento do arrecadador, registro bruto, totais de conferência | 🟢 **Nada financeiro** | BAIXO | Pode ser a **primeira** capacidade financeira construída |
| 2 | **Classificação** — catálogo de situações do pagamento | Recepção + identidade do documento | ALTO | Etapa 5 |
| 3 | **Aplicação** — baixa contra o documento | Classificação + Faturamento | ALTO | Etapa 5 |
| 4 | **Conciliação** — aviso bancário (calculado × informado, acertos, deduções) | Aplicação | MÉDIO | Etapa 5, final |
| 5 | Excedente/devolução com guia própria · débito automático | Aplicação | MÉDIO | Etapa 6 |
| 6 | Encerramento mensal (fechamento contábil, retenções) | Todo o mês processado | ALTO | **Etapa 7** — é batch |

### 15.2 🔴 O princípio inegociável a nascer com a capacidade 2

🟢 **Nenhum pagamento é descartado; a situação anterior é preservada.** É o que torna a Arrecadação auditável. ⚠️ E a assimetria conhecida — 🟢 **o pagamento perde identidade ao ser arquivado**, única anomalia do padrão de identidade do sistema — deve ser **corrigida na construção**, não reproduzida: a identidade do recebimento já é decisão da visão conceitual.

---

## 16. Processamento / Batch

### 16.1 🔴 A dependência é inversa

> Um orquestrador sem operação determinística para orquestrar **não tem o que fazer**.

🟢 Evidência do próprio legado: o Faturamento **não tem orquestração própria** — usa o framework padrão (processo → etapas → tarefa → mensagem por rota → MDB → controlador), e *"o lote repete o cálculo individual por imóvel dentro de cada rota"*. O batch é embalagem; a regra é do módulo dono.

### 16.2 Três coisas distintas

| Tipo | Quando | Justificativa |
| ---- | ------ | ------------- |
| **Processamento síncrono** | Etapa 1 | Não é batch: é a operação individual sob requisição |
| **Processamento assíncrono genérico** | **Etapa 5** | Nasce no primeiro caso real que o justifique — geração de documento em volume ou relatório pesado |
| **Batch crítico de domínio** | **Etapa 7** | Faturar grupo, arrecadação mensal, encerramentos, resumos |

### 16.3 Princípio de entrada

```text
operação individual correta
        ↓
caracterização (golden master aprovado)
        ↓
processamento em lote
```

🔴 **Nunca o inverso.** Desenvolver batch para regra não estabilizada produz duas fontes de erro simultâneas — a regra e a orquestração — e nenhuma delas isolável.

⚠️ **Propriedades que o modelo do legado já tem e devem ser preservadas na Etapa 7**: definição × execução em três níveis (processo/etapa/unidade), retomada por unidade, reprocessamento por etapa, ordem definida por dado. E 🟢 uma propriedade que **não** foi comprovada no legado e não deve ser assumida: a **atomicidade do trabalho de negócio dentro de uma unidade** (pendência 12).

---

## 17. Relatórios

**Princípio**: relatórios entram **progressivamente, junto do módulo dono dos dados**. 🟢 A consulta e a regra pertencem ao dono; o motor é plataforma.

| O que | Quando |
| ----- | ------ |
| Convenção de artefato + 🔴 **controle de acesso ao artefato** | **Etapa 0** (convenção) |
| Motor comum (template, *datasource*, exportação) | **Etapa 2** — primeiro caso real |
| Decisão automática online × assíncrono por volume | Etapa 5, com o assíncrono genérico |
| Relatórios de cada módulo | Junto do módulo |
| Relatórios financeiros de conferência | Etapa 7, com os resumos |

🔴 **Por que o controle de acesso é convenção de dia 1**: o achado 13 (confirmado) mostra o artefato do legado recuperável **por identificador, sem verificação de propriedade e sem usuário autenticado**. A divergência **D-03** obriga o OpenGSAN a divergir. Se o motor nascer sem essa verificação, ela é retrofit sobre todo relatório já existente.

⚠️ A **forma de entrega** (bytes na resposta × artefato por URL assinada) depende da **ADR-0007** — registrado, não decidido.

---

## 18. Integrações

Separação pedida, resolvida por dependência:

| Camada | Quando | Conteúdo |
| ------ | ------ | -------- |
| **Convenções de contrato** | **Etapa 0** | Idempotência por chave de negócio · erro **durável e observável** · identidade de dispositivo/sistema distinta de usuário · TLS obrigatório |
| **Camada implementada** | **Etapa 3** | Nasce com o primeiro adapter real |
| **Adapters concretos** | Com o módulo dono | — |

| Adapter | Entra com | Etapa |
| ------- | --------- | ----- |
| Coleta móvel de leitura | Micromedição | **3** |
| Execução móvel de OS · evidência de campo | Atendimento/OS + camada | 3 |
| Arquivo bancário / arrecadador | Arrecadação | 5 |
| Bureau de crédito · cobrança terceirizada | Cobrança | 6 |
| PSP / PIX · boleto registrado | Arrecadação + Faturamento maduros | 8 |
| Notificação (e-mail/SMS) | Primeiro evento real a notificar | 6 |
| GIS · telemetria · analytics | Posterior | 8+ |

🔴 **Por que a camada nasce na Etapa 3 e não depois**: o primeiro adapter é a **coleta de leitura**, cujo dado **alimenta cálculo financeiro**. A divergência **D-05** exige autenticação de dispositivo **antes de qualquer escrita** — no legado a leitura é gravada sem identificar a origem. Um dado financeiro de origem não identificada é problema de integridade, não de conveniência.

⚠️ 🔴 **E a regra que a camada existe para garantir**: *uma integração não é dona do domínio* — ela traduz e entrega; **o dono aplica**. O legado violou isso ao escrever direto no banco do sistema parceiro (D-12).

---

## 19. Canal digital

### 19.1 Confirmação conceitual pedida

🔵 **Confirmado: o canal digital é camada consumidora, não dona de domínio.** Três evidências:

1. 🟢 As 47 classes do portal legado fazem 2ª via (Faturamento), extrato e parcelamento (Cobrança), certidão (Cobrança), solicitação de serviço (Atendimento) e consulta de imóvel (Cadastro) — **todas as operações pertencem a domínios existentes**.
2. 🟢 Nenhum conceito de negócio é criado pelo portal — exceto um: o **login do cliente**, que é identidade, não domínio comercial.
3. 🔵 Por isso ele não tinha dono: não é um módulo que faltou mapear, é uma **camada que atravessa quatro**.

⚠️ **Contra-argumento preservado** ([catálogo §20](funcionalidades-futuras.md)): pode ser apresentação sobre capacidades existentes, e não domínio. Isso não muda a **posição** na ordem — em qualquer das leituras, ele vem **depois** dos quatro domínios.

### 19.2 Posição e respostas

| Pergunta | Resposta |
| -------- | -------- |
| Entra no primeiro core? | 🔴 **Não.** Depende de Cadastro, Faturamento, Cobrança e Atendimento (#20) |
| Depois dos serviços internos? | **Sim** — consome o que eles expõem |
| Depende da ADR-0007? | 🔴 **Sim, diretamente.** É a superfície pública do sistema |
| Exige identidade distinta? | 🔴 **Sim** — ver §19.3 |

**Posição: Etapa 8**, como primeira capacidade de canal.

### 19.3 🔴 Identidade do cliente final ≠ usuário interno

Dois modelos que **não devem ser misturados**:

| | Usuário interno | Cliente final |
| - | --------------- | ------------- |
| Quem é | Funcionário da companhia | Pessoa atendida pelo serviço |
| Concessão | RBAC por funcionalidade/operação, com escopo territorial | Acesso aos **próprios** dados |
| Cadastro | Administrado pela companhia | 🟢 Autocadastro com validação de e-mail (existe no legado) |
| Escopo | Territorial | **Vínculo com imóvel/cliente** |

🔴 **Impacto estrutural na Segurança, registrado**: a autorização do cliente final não é RBAC — é **verificação de vínculo**. Se o modelo de autorização nascer assumindo "todo ator é usuário interno com papéis", a chegada do canal digital exige alteração estrutural.

⚠️ **Consequência para a fundação, e é acionável**: S1 (Etapa 0) deve tratar **ator** e **tipo de ator** como conceito, sem assumir que todo ator tem papel funcional. Isso não antecipa o canal digital nem o implementa — apenas evita fechar a porta. 🔵 Registrado como **restrição de desenho da fundação**, não como capacidade a construir.

---

## 20. Funcionalidades futuras H1

As nove capacidades H1 do catálogo. 🔴 **H1 não significa "no primeiro release"** — significa "próxima do núcleo".

| Capacidade | Fundacional? | Depende de módulo inexistente? | Posição | Motivo |
| ---------- | ------------ | ------------------------------ | ------- | ------ |
| **APIs para terceiros e dispositivos** | 🔵 **Parcialmente** | Não — as convenções, sim | **Etapa 0** (convenção) / 3 (camada) | As capacidades já têm consumidores não navegador |
| **Coleta móvel de leitura** | Não | Micromedição | **Etapa 3** | É a operação real de campo |
| **Execução móvel de OS** | Não | Atendimento/OS | **Etapa 3** | Idem |
| **Benefício social tarifário** | 🔴 **Quase** | Cadastro + Faturamento | **Etapa 4** | 🔴 **Afeta o cálculo da conta** — acoplar depois é mais caro |
| **Notificação ao cliente** | Não | Evento a notificar | **Etapa 6** | Nasce no primeiro evento real |
| **Cobrança bancária registrada** | Não | Faturamento + Arrecadação | **Etapa 8** | Exige documento e baixa maduros |
| **Pagamento instantâneo (PIX)** | Não | Faturamento + Arrecadação + PSP | **Etapa 8** | Ver §20.1 |
| **Portal de autoatendimento** | Não | Quatro domínios + identidade | **Etapa 8** | §19 |
| **Identidade do cliente final** | 🔵 **Restringe** a fundação | Não | **Etapa 8** (capacidade) / 0 (restrição) | §19.3 |

### 20.1 🔴 PIX: urgente não é primeiro

PIX é a capacidade mais urgente do catálogo e a menos pronta. Mas depende de documento, recebimento, conciliação e contrato com PSP (#22). 🔵 Posicioná-lo cedo **não o entregaria mais cedo** — apenas o construiria sobre peças inexistentes.

⚠️ O que a ordem faz por ele desde já: a **recepção** (Etapa 5) e a **conciliação** nascem genéricas, sem assumir arquivo bancário como único canal de entrada. Isso é desenho, não implementação.

### 20.2 Benefício social — a exceção que merece atenção

🔴 É a única H1 que entra junto do núcleo financeiro, e a razão é dura: **afeta o cálculo da conta**. Tarifa social é praticamente universal no saneamento brasileiro. Acoplar um critério de elegibilidade e uma condição de perda a um motor de cálculo já construído é mais caro do que prever o ponto de extensão na estrutura tarifária.

⚠️ **Sem antecipar implementação**: o que entra na Etapa 4 é o **ponto de extensão na estrutura tarifária**; os critérios reais por companhia continuam lacuna registrada (lacuna 4 do catálogo).

### 20.3 Fiscal, SPED, analytics, GIS

| Área | Posição | Regra |
| ---- | ------- | ----- |
| **Fiscal / SPED** | 🔴 **Fora da ordem** | Permanecem `EXIGE APROFUNDAMENTO`. ⚠️ **Não podem bloquear o início** sem evidência de que são necessários ao primeiro núcleo. Devem ser esclarecidos **antes da Etapa 4** — se o documento fiscal decorrer da conta emitida (hipótese 🟡), o evento que o origina nasce lá |
| **Analytics** | Etapa 8+ | 🔴 **Não bloqueia o núcleo**, mas impõe **uma restrição desde a Etapa 0**: o desenho não pode tornar impossível a análise futura. Concretamente — evento de negócio legível, competência explícita, e nenhuma destruição de identidade no arquivamento (o legado destrói a do pagamento) |
| **GIS** | Etapa 8+ | 🔴 **Não é dependência do core comercial.** 🟢 O que existe no legado é só integração; não há domínio GIS a preservar. Coordenada no RA é atributo, não capacidade |

---

## 21. Primeira fatia vertical

### 21.1 Avaliação dos candidatos

| | **A** Cadastro auxiliar | **B** Consulta Imóvel/Cliente | **C** RA simples | 🟢 **D** Autenticação + consulta + RA |
| - | - | - | - | - |
| Dependências | Mínimas | Cadastro mínimo | Cadastro mínimo | Cadastro mínimo + S1 |
| Risco | BAIXO | BAIXO | BAIXO | BAIXO |
| Valor funcional | BAIXO | MÉDIO | ALTO | **ALTO** |
| Prova persistência | Sim | Só leitura | Sim | **Sim** |
| Prova autorização | Trivial | Leitura | Sim | **Sim, com negação** |
| Prova auditoria | Pouco | **Não** (não escreve) | Sim | **Sim** |
| Prova **regra como dado** | 🔴 **Não** | Não | **Sim** (especificação) | **Sim** |
| Prova estado/workflow | Não | Não | **Sim** (tramitação) | **Sim** |
| Atravessa ≥ 2 módulos | Não | Não | Parcial | **Sim** (Cadastro + Atendimento) |
| Golden master | Fraco | Bom | Bom | **Bom** — priorizado na baseline |

### 21.2 🟢 Recomendação: opção D, com escopo declarado

```text
usuário autentica
      ↓
consulta imóvel / cliente   (Cadastro — leitura, com autorização)
      ↓
abre RA                     (Atendimento — escrita, com especificação paramétrica)
      ↓
tramita e consulta o RA     (estado + histórico + auditoria)
```

**Por que D e não C**: C isolado não prova autenticação nem autorização sobre leitura. **Por que D e não A/B**: nenhum dos dois prova escrita com estado, auditoria e regra como dado — e §16 do roteiro é explícito: o piloto deve demonstrar *o OpenGSAN funcionando como sistema*, não *Spring salva tabela no PostgreSQL*.

**O que D prova**: modularidade com fronteira verificada · Flyway sobre banco limpo · autenticação e concessão por caso de uso · auditoria na escrita · regra como dado · estado com histórico · dois módulos com fronteira real · teste com Testcontainers sobre o schema verdadeiro.

### 21.3 ⚠️ O que D deliberadamente **não** prova

Registrado para que ninguém conclua da fatia mais do que ela sustenta:

| Não prova | Onde é provado |
| --------- | -------------- |
| Precisão financeira | Etapa 4 |
| Snapshot / contexto congelado | Etapa 4 |
| Versionamento e linhagem de documento | Etapa 4 |
| Escopo territorial | Etapa 2 (depende de D-17) |
| 🔴 **O contrato "solicita × aplica"** | **Etapa 2** — o RA da fatia 1 não produz efeito em domínio alheio |
| Processamento em volume | Etapa 7 |

🔵 A ausência do contrato de efeito na fatia 1 é **escolha**, não esquecimento: é o que a mantém pequena. E é por isso que a Etapa 2 tem esse contrato como objetivo declarado, não como consequência.

---

## 22. Primeiro núcleo funcional

**Etapas 0 → 2.** Jornada demonstrável de ponta a ponta:

```text
usuário autentica (com escopo territorial aplicado)
      ↓
consulta imóvel, cliente e ligação
      ↓
abre RA de um tipo parametrizado
      ↓
o RA gera OS conforme a especificação
      ↓
a OS é executada e encerrada
      ↓
🔴 o DONO aplica o efeito (situação da ligação)
      ↓
tudo auditado, dentro do escopo do usuário
```

🔵 **Por que este é o corte certo**: é o menor conjunto em que o OpenGSAN exibe **as duas coisas que o distinguem de um CRUD** — regra vinda de dado e efeito aplicado pelo dono. Sem dinheiro envolvido.

⚠️ **O que ainda não é**: não fatura, não cobra, não recebe. **Não é um sistema comercial.**

---

## 23. Primeiro núcleo comercial

🔴 Separação necessária, que o plano antigo não fazia — e a distinção é entre **comportamento** e **operabilidade**:

| | Alcance | Etapas | O que permite |
| - | ------- | ------ | ------------- |
| **Núcleo comercial — comportamento** | Cadastro + medição + faturamento individual + conta + recepção/classificação/aplicação de pagamento | **0 → 5** | 🔵 A cadeia comercial completa **funciona e é comparável ao legado ao centavo** |
| **Núcleo comercial — operável** | + cobrança + processamento em escala | **0 → 7** | 🔴 Uma companhia **pode efetivamente operar** |

```text
imóvel cadastrado
      ↓
hidrômetro instalado, leitura coletada, consumo determinado
      ↓
conta individual gerada  ◄── golden master ao centavo
      ↓
pagamento recebido, classificado e aplicado
      ↓
posição de dívida correta (derivada)
```

⚠️ 🔴 **Por que a Etapa 5 não basta para operar**: nenhuma companhia fatura cem mil imóveis um a um. **A operabilidade exige o lote (Etapa 7)** — e o lote exige o individual comprovado (§16.3). Chamar a Etapa 5 de "release comercial" seria honesto quanto ao comportamento e enganoso quanto ao uso.

🔵 **MVP não é produto permanentemente incompleto**: a ordem existe para construir com segurança; a visão do OpenGSAN continua ampla, com as 26 capacidades do catálogo à frente.

---

## 24. Fases de implementação

⚠️ Etapas de **capacidade**, não de módulo (§53). Derivadas da matriz (§5), dos ciclos (§8) e dos critérios (§2).

```text
ETAPA 0 — FUNDAÇÃO
├── projeto modular + verificação automatizada de fronteira
├── PostgreSQL 18 + Flyway V1 + Testcontainers
├── convenções: valor monetário e arredondamento nomeado · identidade/versão/linhagem
├── S1 — identidade, autenticação, concessão por caso de uso
├── auditoria mínima · erro · log com correlação
├── configuração externa sem hard-code institucional · CI com secret scan
└── convenções de integração e de artefato de relatório
        ↓
ETAPA 1 — PRIMEIRA FATIA VERTICAL
├── Cadastro: imóvel, cliente, cliente×imóvel (leitura) + auxiliares necessários
├── Atendimento: RA com especificação paramétrica, tramitação, estado
└── plataforma: autorização aplicada, auditoria na escrita, teste de negação
        ↓
ETAPA 2 — NÚCLEO OPERACIONAL
├── Cadastro: estrutura territorial · ligação e situação (dono correto) · economias · categorias
├── Atendimento: OS, prazos, espera/reiteração, encerramento
├── 🔴 CONTRATO "solicita × aplica" — primeiro efeito real (situação da ligação)
├── S2 — escopo territorial por construção (requer D-17)
└── Relatórios: motor comum + controle de acesso ao artefato
        ↓
ETAPA 3 — MEDIÇÃO
├── hidrômetro → instalação → leitura → consumo (real/média/mínimo, com origem)
├── anormalidades paramétricas → OS automática (fecha o ciclo com Atendimento)
├── efeitos de OS sobre hidrômetro e fiscalização de leitura
└── camada de integração implementada + coleta móvel (com identidade de dispositivo)
        ↓
ETAPA 4 — FINANCEIRO INDIVIDUAL
├── estrutura tarifária versionada (+ ponto de extensão para benefício social)
├── faturabilidade paramétrica
├── 🔴 MOTOR DE CONTA INDIVIDUAL
├── Conta + contexto congelado + identidade estável do documento
├── débito · crédito · guia · retificação (via operação da Micromedição) · cancelamento
└── efeitos financeiros da OS
        ↓
ETAPA 5 — RECEBIMENTO
├── recepção (movimento, registro bruto, conferência)
├── classificação por situação do pagamento (nenhum descartado)
├── aplicação contra o documento · conciliação por aviso bancário
├── posição de dívida como consulta derivada  ◄── valida o conceito antes da Cobrança
└── processamento assíncrono genérico (primeiro caso real)
        ↓
ETAPA 6 — COBRANÇA
├── situação de cobrança (dono correto) · política · ação · documento com itens
├── parcelamento · desfazimento com estornos · reparcelamento
├── negativação · terceirização por carteira
├── excedente/devolução · débito automático
└── notificação ao cliente (primeiro evento real)
        ↓
ETAPA 7 — ESCALA
├── faturamento em lote (unidade = rota do cronograma)
├── arrecadação mensal · encerramento contábil · encerramento do faturamento
├── três níveis (processo/etapa/unidade), retomada por unidade, reprocessamento por etapa
└── relatórios financeiros de conferência
        ↓
ETAPA 8 — CANAIS E EVOLUÇÕES
├── identidade do cliente final (verificação de vínculo, não RBAC)
├── canal digital: 2ª via, extrato, parcelamento, certidão, solicitação
├── PIX · boleto registrado
└── bureau, telemetria, analytics, GIS, acessibilidade — por prioridade posterior
```

### 24.1 Resultado observável por etapa

| Etapa | O que estará funcionando | Conceitos disponíveis | Destrava |
| ----- | ------------------------ | --------------------- | -------- |
| **0** | Aplicação sobe, migra banco limpo, autentica, audita, testes rodam | Ator, identidade, concessão, auditoria | Todo o resto |
| **1** | Consultar imóvel e abrir RA, com autorização e auditoria | Imóvel, cliente, RA, especificação | Etapa 2 |
| **2** | Ciclo operacional completo, com efeito aplicado pelo dono e escopo territorial | Ligação, situação, OS, território, escopo | Etapas 3 e 4 |
| **3** | Medir: hidrômetro instalado, leitura coletada, consumo determinado | Instalação, leitura, consumo com origem | Etapa 4 |
| **4** | 🔴 **Gerar uma conta correta ao centavo** | Tarifa, Conta, snapshot, identidade do documento, débito/crédito | Etapas 5 e 7 |
| **5** | Receber, classificar e baixar pagamento; posição de dívida correta | Recebimento, situação do pagamento, conciliação, posição de dívida | Etapas 6 e 7 |
| **6** | Cobrar, negociar e parcelar | Política, ação, documento de cobrança, parcelamento | Etapa 8 |
| **7** | Faturar e arrecadar **em volume**, com retomada | Execução em três níveis, competência encerrada | Operação real |
| **8** | Cliente se atende sozinho e paga por meio moderno | Identidade do cliente, canal, PSP | Evoluções |

---

## 25. Gates de avanço

🔴 Nenhum gate é "código pronto". Todos são **prova**.

### 0 → 1

- `V1` aplicada em banco limpo produz o schema esperado; *health check* OK.
- Testcontainers executando contra o schema real.
- 🔴 **A verificação de fronteira reprova uma violação deliberada** — provar que o mecanismo funciona, não que existe.
- Autenticação contra hash moderno (BCrypt/Argon2 — D-01).
- Uma escrita qualquer produz registro de auditoria legível.
- CI reprova segredo commitado (lição do achado 11).
- Nenhum nome de empresa, URL fixa ou campo institucional no núcleo.

### 1 → 2

- Matriz de autorização testada **com negação provada**, não só concessão.
- Comportamento do RA muda ao alterar **dado** de especificação, sem recompilar.
- Golden master de abertura de RA comparado semanticamente.
- Auditoria da criação e da tramitação.

### 2 → 3

- 🔴 **Efeito aplicado pelo dono**, com a tentativa de escrita cruzada **reprovada pela verificação de fronteira**.
- Escopo territorial aplicado **por construção**: uma consulta nova sem tratamento explícito **não** vaza dados fora do escopo (é o que D-17 propõe e o que o legado falha).
- Artefato de relatório inacessível a quem não é dono (D-03).

### 3 → 4

- Consumo com **origem declarada** em todos os casos; os três valores (real, média, mínimo) distinguíveis.
- Golden master de consumo/média aprovado (prioridade 5 da baseline).
- Leitura de campo **rejeitada** sem identidade de dispositivo (D-05).

### 4 → 5 — 🔴 o gate mais rigoroso

- **13 golden masters financeiros** aprovados, **exatos ao centavo**.
- 🔴 As **5 políticas de arredondamento** caracterizadas **individualmente** — nenhuma unificação sem decisão registrada.
- Snapshot reproduz uma conta passada **com a parametrização da época**, não com a atual.
- Identidade estável do documento verificada entre versão corrente e histórico.
- Retificação altera consumo **pela operação da Micromedição** (D-14), nunca por escrita direta.
- Desempenho por imóvel medido contra a baseline.

### 5 → 6

- Golden master de baixa de pagamento aprovado (prioridade 3).
- **Nenhum pagamento descartado**; situação anterior preservada em todos os caminhos.
- Conciliação fecha calculado × informado.
- Posição de dívida reflete pagamentos **por derivação**, comprovada por caso pago/parcial/não pago.

### 6 → 7

- Golden master de parcelamento **criar e desfazer** aprovado (prioridade 4), com estornos tipificados.
- Memória financeira do parcelamento **integral** e auditável.

### 7 → operação

- Lote produz resultado **idêntico** à soma dos individuais — mesma regra, só orquestrada.
- Retomada por unidade comprovada: unidade concluída **não** reexecuta.
- Reprocessamento por etapa comprovado.
- Encerramento de competência confere com os resumos financeiros.

### Gate de golden master — forma geral

```text
implementação
      ↓
caracterização do legado (golden master sobre massa congelada)
      ↓
comparação semântica via mapeamento GSAN → OpenGSAN
      ↓
aceitação sob os DOIS oráculos
```

🔴 **Obrigatório** em consumo, faturamento, parcelamento e arrecadação. ⚠️ Sob o **oráculo 2**, divergência de segurança registrada é **aprovação**, não falha — e igualdade é defeito.

---

## 26. Atividades transversais contínuas

🔴 Nenhuma é fase final. Cada uma tem obrigação **em toda etapa**:

| Atividade | O que significa em cada etapa |
| --------- | ----------------------------- |
| **Testes** | Nenhuma capacidade fecha sem teste; golden master onde há equivalente no GSAN |
| **Documentação** | Mapa funcional → especificação → decisão registrada, antes do código |
| **Segurança** | S1 na fundação; S2/S3 progressivos; divergências aprovadas **aplicadas e testadas** |
| **Auditoria** | Toda escrita nova nasce auditada |
| **Observabilidade** | Log com correlação desde a Etapa 0; métricas e alertas crescem com o volume |
| **Performance** | Baseline conhecida antes de substituir comportamento; medição por capacidade |
| **Revisão de dependências** | Esta matriz é revisada ao fim de cada etapa — dependência descoberta **muda a ordem** |
| **ADRs** | Decisão estrutural vira ADR **antes** da implementação |
| 🔴 **Software livre** | Configuração externa, zero hard-code institucional, ambiente reproduzível, massa **sintética**, documentação de instalação — em **toda** etapa |

### 26.1 Por que software livre entra aqui e não "depois de funcionar"

🟢 Evidência do legado: nome de empresa, URL fixa e campo institucional **no núcleo** — falha nos três pontos que a neutralidade exige. Remover hard-code institucional depois de construído é refatoração transversal; não colocá-lo custa nada.

⚠️ E a massa de teste é **sintética por decisão**: dado real exigiria anonimização (nomes, CPF/CNPJ, NIS, endereços, telefones, documentos binários) — e um projeto aberto não pode depender de base de companhia para rodar seus testes.

---

## 27. Decisões bloqueantes

🔴 A visão conceitual registrou cinco decisões como "bloqueiam a implementação inicial". ⚠️ **Verificado nesta execução: não bloqueiam a mesma coisa, e duas não bloqueiam o início.** Dizer que todas bloqueiam todo código seria impreciso e paralisante.

| # | Decisão | Bloqueia de fato | **Não** bloqueia | Prazo real |
| - | ------- | ---------------- | ---------------- | ---------- |
| 3 | 🔴 **Existe negação na autorização?** | **S1 — o modelo de avaliação da concessão** | Nada além | 🔴 **Antes da Etapa 0.** É o único bloqueio de dia 1 |
| 4 | **Nome do repositório e governança** | A **partida física** do código | Todo o trabalho conceitual | Antes da Etapa 0 — ver §27.2 |
| 1 | **ADR-0007 — interface** | **Superfície de entrega** da Etapa 1; entrega de relatório; canal digital | 🔵 Fundação, domínio, persistência, testes, motor financeiro | Antes da **superfície** da Etapa 1 |
| 5 | **Divergência D-17** (escopo sistemático) | **S2** | Etapas 0 e 1 | Antes da Etapa 2 |
| 2 | **Variantes por companhia** | Desenho do **ponto de extensão** tarifário | Etapas 0–3 | Antes da Etapa 4 |

### 27.1 🔴 ADR-0007 — exatamente o que ela bloqueia

Pedido explícito do roteiro (§47). Resposta:

| **Bloqueado** | **Não bloqueado** |
| ------------- | ----------------- |
| Superfície de entrega da fatia 1 (tela × recurso REST) | Modelo de domínio e regras |
| 🔴 **Unidade de autorização** (rota × caso de uso) | Persistência e Flyway |
| Forma de entrega do relatório (bytes × URL assinada) | Fronteiras de módulo e sua verificação |
| Canal digital (Etapa 8) | Testes e Testcontainers |
| Sessão × token | Auditoria |
| — | 🔵 **Motor de faturamento individual** — não tem superfície |

🔵 **Conclusão acionável**: a **Etapa 0 inteira pode ser construída sem a ADR-0007**, desde que a concessão seja expressa em **caso de uso** (§4.3). E o motor financeiro da Etapa 4 também é independente dela. A ADR-0007 é bloqueio de **superfície**, não de sistema — mais estreito do que "bloqueia o piloto" sugeria, e isso ajuda a próxima decisão.

### 27.2 🔴 Nome do repositório — reclassificado

⚠️ O roteiro pede a classificação (§48). **Não é bloqueio de projeto: é bloqueio de partida, e de natureza diferente dos outros quatro.**

| Os outros quatro | O nome/governança |
| ---------------- | ----------------- |
| Exigem **investigação** (evidência, inventário, aprovação técnica) | Exige apenas **decisão** |
| Podem levar rodadas | Resolvível em uma conversa |
| Erram se decididos sem dados | Não depende de dado nenhum |

🔵 **Consequência**: não deve figurar ao lado dos outros como se tivesse o mesmo peso. Nada de conceitual ou técnico depende dele — **e nada dele depende de nós**. ⚠️ O que ele realmente governa é **publicação**: licença, organização mantenedora e caminho de contribuição. E a ADR-0003 é clara em que o código novo **não** vive no repositório do legado — então ele precisa existir antes da primeira linha, não antes da primeira decisão.

### 27.3 Pendências que **não** bloqueiam nada agora

As sete "decidíveis ao implementar o módulo" da visão conceitual, posicionadas: individualização de economia (Etapa 1) · histórico de situação da ligação (2) · cardinalidade RA↔OS (2) · retenção de artefato (2) · fórmulas de acréscimo (6) · obrigação financeira (6, ⚠️ `PROPOSTO` — não criar antes) · granularidade de commit em unidade de processamento (7).

---

## 28. Ordem final recomendada

```text
ETAPA 0   Fundação                      ── sem dependência de domínio
ETAPA 1   Primeira fatia vertical       ── auth + consulta + RA
ETAPA 2   Núcleo operacional            ── ligação, OS, contrato de efeito, escopo territorial
ETAPA 3   Medição                       ── hidrômetro → consumo + integração de campo
ETAPA 4   Financeiro individual         ── tarifa + motor de conta + identidade do documento
ETAPA 5   Recebimento                   ── recepção → classificação → aplicação → conciliação
ETAPA 6   Cobrança                      ── posição de dívida → política → parcelamento
ETAPA 7   Escala                        ── lote de faturamento e arrecadação
ETAPA 8   Canais e evoluções            ── identidade do cliente, canal digital, PIX, boleto
```

### 28.1 A resposta direta

| Pergunta | Resposta |
| -------- | -------- |
| **O que programamos primeiro?** | A **fundação** (Etapa 0) — projeto modular com fronteira verificada, Flyway `V1`, testes com Testcontainers, S1, auditoria mínima, convenção monetária |
| **Qual é a primeira funcionalidade real?** | **Autenticar → consultar imóvel/cliente → abrir e tramitar um RA** (Etapa 1) |
| **O que precisa existir antes dela?** | Etapa 0 + Cadastro mínimo em leitura. E a resposta sobre **negação na autorização** |
| **O que vem depois?** | Ligação com situação, OS e o **contrato "solicita × aplica"** (Etapa 2) |
| **Quando começa Micromedição?** | **Etapa 3**, depois de o Cadastro ter território, ligação e categoria |
| **Quando começa Faturamento?** | **Etapa 4** — no meio, não no fim |
| **Por que o Faturamento está nessa posição?** | Precisa de cadastro e consumo reais (antes), e é **pré-requisito de Cobrança, Arrecadação e de todo o batch** (depois). É também onde a arquitetura financeira se prova — adiar é descobrir tarde |
| **Cobrança antes ou depois de Faturamento?** | 🔴 **Depois.** Não existe dívida sem documento emitido |
| **Quando entra Arrecadação?** | **Etapa 5**, logo após a conta. A *recepção* poderia vir antes (não depende de nada financeiro), mas classificação e aplicação exigem o documento |
| **Quando entram os batches?** | **Etapa 7**, só depois de a operação individual estar comprovada por golden master |
| **Quando entra o Portal?** | **Etapa 8** — é camada consumidora de quatro domínios e exige identidade do cliente final |
| **O que é transversal desde o início?** | Testes, auditoria, S1, log com correlação, configuração externa, neutralidade institucional, convenção monetária, verificação de fronteira |

---

## 29. Diferenças em relação à ordem anterior

A tabela de [`modulos/README.md`](README.md) é tratada como **hipótese preliminar histórica** (§40 do roteiro), não preservada por inércia.

| # | Ordem anterior | Ordem agora | Motivo |
| - | -------------- | ----------- | ------ |
| 1 | 🔴 6 Cobrança · 7 Arrecadação · 8 Faturamento | 🔴 **4 Faturamento · 5 Recebimento · 6 Cobrança** | **Estava invertida.** O Faturamento cria a Conta; não há dívida sem documento, nem posição de dívida correta sem pagamentos. A ordem antiga exigiria **simular a Conta** para construir Cobrança — fabricar o objeto financeiro mais sensível do sistema |
| 2 | 1 Cadastros auxiliares como etapa | Parte das Etapas 0–1 | Uma etapa deve provar mais que CRUD (§14/§16 do roteiro) |
| 3 | 2 Consultas como etapa isolada | Dentro da fatia 1 | Leitura sozinha não prova escrita, auditoria nem regra como dado |
| 4 | `seguranca` na Fase 5 | **S1/S2/S3 em três posições** | 🔴 "Segurança completa" antes do domínio é **impossível**: o escopo territorial depende do Cadastro (§4.4) |
| 5 | Auditoria na Fase 10 (observabilidade) | **Etapa 0** | Retrofit obriga revisitar toda escrita existente |
| 6 | 8 Faturamento por último (com o batch) | **Motor individual na 4; lote na 7** | 🟢 `gerarConta` é a mesma lógica no individual e no lote — separar é honrar a estrutura existente |
| 7 | Arrecadação como peça única | **Quatro capacidades ordenáveis** | A *recepção* não depende de nada financeiro |
| 8 | Micromedição como bloco (item 5) | **Cinco capacidades; 1–4 antes do Faturamento** | Anormalidades não são pré-requisito do cálculo |
| 9 | Ordem por **módulo** | Ordem por **capacidade** | Evita "terminar Cadastro inteiro para começar Atendimento" |
| 10 | `integracoes` "junto ao módulo dono" | **Convenção na 0 · camada na 3 · adapters com o dono** | O primeiro adapter alimenta cálculo financeiro; D-05 exige identidade antes da escrita |
| 11 | `fiscal`/SPED junto de faturamento | 🔴 **Fora da ordem** | `EXIGE APROFUNDAMENTO` — schema sem comportamento observável não gera etapa |
| 12 | Portal ausente | **Etapa 8** | Não existia na ordem antiga; o catálogo o descobriu |
| 13 | Identidade do cliente final ausente | **Restrição na 0; capacidade na 8** | Modelo distinto do usuário interno |

### 29.1 🔵 O que a ordem anterior acertou

Registrado por honestidade, e porque três acertos permanecem:

1. **Começar por risco baixo e dependências simples** — o critério estava certo; a aplicação é que confundiu "risco baixo" com "CRUD".
2. **Micromedição antes de Faturamento** — correto, e confirmado pela dependência dura #3.
3. **Batch por último** — correto, e agora com justificativa mais forte (§16.1, dependência inversa) do que "é o mais acoplado ao legado".

⚠️ **O erro não foi de critério, foi de sequenciamento dentro do financeiro** — e nasceu de ordenar por *risco crescente* em vez de por *dependência*. Risco crescente é bom critério de desempate; não substitui a dependência.

---

## 30. Riscos

| # | Risco | Como esta ordem o trata |
| - | ----- | ----------------------- |
| 1 | 🔴 **Convenção monetária ou de arredondamento errada na fundação** contamina tudo depois da Etapa 4 | Item de **dia 1** (§4.1-5); as 5 políticas caracterizadas **antes** do motor, não durante |
| 2 | **Parcelamento tarde** — a regra financeira mais complexa fica na Etapa 6 | A **posição de dívida** é validada na Etapa 5, uma etapa antes do módulo; memória integral já é `PRESERVAR` |
| 3 | **Contrato de efeito moldado só por casos operacionais** (Atendimento antes do financeiro) | O contrato da Etapa 2 é **revisado contra a lista de efeitos financeiros** antes de ser considerado estável (§11.1) |
| 4 | **ADR-0007 decidida depois da fatia 1** obriga reescrever a superfície | Domínio e aplicação livres de conceito de entrega; concessão em caso de uso (§4.3); decidir antes da **superfície** da Etapa 1 |
| 5 | **Problema de escala descoberto na Etapa 7**, com o núcleo inteiro construído | Baseline de performance conhecida antes de substituir comportamento; medição **por imóvel** desde a Etapa 4 |
| 6 | **Ordem por capacidade** produz módulos permanentemente incompletos | Gates por etapa (§25) + critério de pronto por capacidade (§31.1) |
| 7 | **Fiscal obrigatório** descoberto tarde, já com a conta construída | Esclarecimento exigido **antes da Etapa 4**: se o documento fiscal decorre da conta, o evento nasce lá (§20.3) |
| 8 | **Fronteira degradada** para acoplamento direto, como no legado | Verificação automatizada de fronteira é **gate**, e precisa reprovar violação deliberada (§25) |
| 9 | 🔴 **Nada disto vale sem a rede de testes** (19 testes / 2,39M LOC no legado) | Os gates são de **prova**, não de código; a caracterização do legado precede a comparação |
| 10 | **A ordem ser tratada como imutável** | §26: a matriz é revisada ao fim de cada etapa; dependência descoberta **muda a ordem**, com motivo registrado |

---

## 31. Próximos passos

### 31.1 Critério de pronto conceitual

Modelo mínimo por capacidade — ⚠️ não é especificação exaustiva:

```text
Capacidade pronta quando:
- comportamento documentado ANTES do código;
- domínio implementado com o dono correto do estado;
- autorização aplicada (e negação testada);
- auditoria registrando a escrita;
- teste automatizado existente;
- golden master comparado, onde há equivalente no GSAN;
- observabilidade mínima (log com correlação);
- nenhuma violação de fronteira;
- nenhum hard-code institucional nem segredo em código.
```

### 31.2 O que esta execução **não** decidiu

⚠️ ADR-0007 · mecanismo de comunicação entre módulos · aprovação de D-17 · nome do repositório · qualquer modelagem de banco · qualquer cronograma, sprint ou data.

### 31.3 Pendências da Fase 0, na ordem

1. **Compatibilidade conceitual GSAN → OpenGSAN** — próxima atividade.
2. **Especificação dos cenários críticos** — os ~110 cenários inventariados viram especificação com resultado esperado.
3. **Decisão da ADR-0007** — agora com o escopo do bloqueio delimitado (§27.1).
4. **Auditoria final e encerramento da Fase 0.**

🔴 **Três respostas que devem existir antes da Etapa 0 começar**: negação na autorização (bloqueio de dia 1), nome/governança do repositório (bloqueio de partida) e a decisão da ADR-0007 antes da superfície da Etapa 1.

### 31.4 Relação com as fases do plano de trabalho

⚠️ Para não haver duas numerações competindo — as **Etapas** deste documento detalham as **Fases** do [plano de trabalho](../plano-de-trabalho.md):

| Etapa | Fase correspondente | Observação |
| ----- | ------------------- | ---------- |
| 0 | **4 — Fundação** + parte da **5 — Segurança** (S1) | S2/S3 saem da Fase 5 e passam às Etapas 2+ |
| 1 | **6 — Piloto** | O piloto passa a ser a fatia vertical, não "cadastros + consulta + 1 relatório" |
| 2 – 8 | **7 — Módulos** | A §5 do plano (ordem dos módulos) é **substituída** por esta ordem |
| contínuas | 10 — Observabilidade · 11 — CI/CD | 🔴 Deixam de ser fases finais: entram nas transversais (§26) |
| pré-requisito | 1 — Ambiente de referência · 2 — Rede de segurança · 3 — Build | Os gates de golden master dependem delas |

🔵 As Fases 1–3 continuam sendo **pré-requisito dos gates**, não da Etapa 0: a fundação pode ser construída em paralelo à montagem do ambiente de referência, mas **nenhum gate de golden master fecha sem ela**.
