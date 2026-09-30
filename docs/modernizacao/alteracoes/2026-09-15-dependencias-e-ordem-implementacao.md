# [2026-09-15] Dependências e ordem de implementação do OpenGSAN

- **Motivo**: a Fase 0 sabia *como o GSAN funciona*, *como o domínio se relaciona*, *o que preservar*, *como o OpenGSAN se organiza* e *quais funcionalidades futuras existem* — mas não *em que ordem construir*. Esta execução responde a uma pergunta única: **o que se programa primeiro quando a Fase 0 terminar?**
- **Método**: verificação de continuidade primeiro; depois **reuso** dos artefatos existentes (ownership, 14 fronteiras, 7 ciclos, 64 decisões, 26 capacidades, estratégia de testes). **Nenhum módulo foi reanalisado.** Nenhuma decisão foi copiada do plano antigo sem verificação.
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## 0. Verificação de continuidade (obrigatória)

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `6e1386a` — catálogo de funcionalidades futuras; local = remoto; árvore limpa |
| Commits posteriores ao estado assumido no roteiro | Nenhum |
| `dependencias-e-ordem-implementacao.md` já existente | **Não existia** |
| Documento posterior que já tivesse refinado a ordem | **Nenhum** — `modulos/README.md` ainda trazia a ordem preliminar |
| Atividade realmente pendente | **Refinamento das dependências e ordem de implementação** — confirmada |

## 1. Correção de nomenclatura

`modulos/README.md` intitulava-se **"Ordem de Migração e Status"**, e `docs/modernizacao/README.md` o descrevia como "ordem de migração dos módulos". ⚠️ Obsoleto desde 2026-09-15: a migração operacional é projeto separado. Corrigido para **Ordem de Implementação**. **Registros históricos em `alteracoes/` preservam a nomenclatura da época.**

## 2. O que foi produzido

`docs/modernizacao/modulos/dependencias-e-ordem-implementacao.md` — **31 seções**.

| Conteúdo | Resultado |
| -------- | --------- |
| Matriz de dependências | **26 relações** classificadas em DURA / PARCIAL / TRANSVERSAL / OPERACIONAL / CONSULTA / FUTURA |
| Ciclos | **8** — os 7 do mapa de domínio **mais um novo** (§4) |
| Fundação mínima | **13 itens no dia 1**, 7 que podem evoluir depois, cada um com o motivo |
| Primeira fatia vertical | **Opção D** recomendada, com o que ela deliberadamente **não** prova |
| Etapas | **9**, por capacidade implementável, com resultado observável e destravamento |
| Gates | Por **prova**, não por código pronto |
| Decisões bloqueantes | As 5 **delimitadas** — ver §6 |

## 3. 🔴 O achado principal: a ordem financeira anterior estava invertida

A ordem preliminar era `… 6 cobrança · 7 arrecadação · 8 faturamento`. A dependência real é a oposta:

```text
Faturamento cria a Conta
      ↓
Arrecadação recebe e aplica contra o documento
      ↓
Cobrança deriva a posição de dívida dos documentos NÃO pagos
```

🟢 **Duas evidências, ambas já documentadas antes desta execução**:

1. A posição de dívida é **derivada dos documentos** — não é entidade. Sem documento emitido não existe dívida a cobrar.
2. A fronteira Arrecadação → Cobrança diz que *"a posição de dívida reflete os recebimentos por derivação"* — no legado o pagamento não altera campo no documento: **a dívida cai por consulta**.

⚠️ **Consequência prática da ordem antiga**, e é o argumento decisivo: construir Cobrança antes de Faturamento exigiria **simular a Conta** — fabricar o objeto financeiro mais sensível do sistema e validar a Cobrança contra uma ficção.

🔵 **Diagnóstico da causa**: a ordem antiga ordenou o financeiro por **risco crescente** ("faturamento por último porque é o mais arriscado"). Risco crescente é bom critério de **desempate**; não substitui a dependência. O erro não foi de critério — foi de aplicá-lo onde a dependência já tinha resposta.

## 4. 🔴 Oitavo ciclo descoberto: Cadastro ↔ Segurança

O mapa de domínio registrou 7 ciclos. Esta execução encontrou um oitavo, **de implementação**:

```text
Cadastro ──estrutura territorial──► Segurança (eixo de escopo/abrangência)
Segurança ──autorização──────────► Cadastro (telas do módulo)
```

🟢 A abrangência é definida sobre gerência regional, unidade de negócio, elo/polo e localidade — e **a estrutura territorial pertence ao Cadastro**.

🔴 **Consequência que corrige o plano de trabalho**: o **escopo territorial não pode ser implementado antes de existir estrutura territorial**. A "Fase 5 — Segurança" do plano antigo promete um entregável **estruturalmente impossível** no ponto em que está agendada.

⚠️ Correção honesta registrada no documento: o plano antigo **não** põe segurança depois do domínio — ele já a coloca antes do piloto, e nisso está certo. O defeito é a *completude* prometida, não a posição.

Segurança passa a **três blocos**: **S1** identidade/concessão/auditoria (Etapa 0, sem dependência de domínio) · **S2** escopo territorial (Etapa 2, depende de Cadastro e de D-17) · **S3** administração completa (progressivo).

## 5. Outras correções de ordem

| # | Correção | Motivo |
| - | -------- | ------ |
| 1 | **Auditoria** sai da fase de observabilidade e vai para o **dia 1** | Retrofit obriga revisitar **toda escrita** já existente |
| 2 | **Motor de conta individual** vai para o meio da sequência (Etapa 4); o **lote** para a 7 | 🟢 `gerarConta` é a mesma lógica no individual e no lote — separar honra a estrutura que o legado já tem |
| 3 | **Cadastros auxiliares e consultas** deixam de ser etapas | Uma etapa precisa provar mais que CRUD |
| 4 | **Arrecadação** deixa de ser peça única | 🟢 A *recepção* (movimento do arrecadador, registro bruto, conferência) **não depende de nada financeiro** |
| 5 | **Micromedição** decomposta em 5 capacidades; 1–4 antes do Faturamento | Anormalidades não são pré-requisito do cálculo |
| 6 | **Batch** com justificativa mais forte que "é o mais acoplado" | 🔴 A dependência é **inversa**: orquestrador sem operação determinística não tem o que orquestrar |
| 7 | **Portal / canal digital** entra na ordem (Etapa 8) | Não existia na ordem antiga; descoberto pelo catálogo |
| 8 | **`fiscal`/SPED** saem do pacote do faturamento | Sem comportamento observável; ⚠️ **não podem bloquear o início** |
| 9 | Ordem por **capacidade**, não por módulo | Evita "terminar Cadastro inteiro para começar Atendimento" |

🔵 **O que a ordem anterior acertou** e permanece: começar por risco baixo, Micromedição antes de Faturamento, batch por último.

## 6. Decisões bloqueantes delimitadas

⚠️ A Visão Conceitual registrou 5 decisões como "bloqueiam a implementação inicial". Verificado: **não bloqueiam a mesma coisa, e duas não bloqueiam o início.**

| Decisão | Bloqueia | Prazo real |
| ------- | -------- | ---------- |
| 🔴 Negação na autorização (allow-only × deny) | O modelo de avaliação da concessão | **Único bloqueio de dia 1** |
| Nome/governança do repositório | A partida física do código | Antes da Etapa 0 — ⚠️ exige **decisão**, não investigação |
| ADR-0007 | **Superfície de entrega**, unidade de autorização, entrega de relatório, canal digital | Antes da superfície da Etapa 1 |
| D-17 | O bloco S2 | Antes da Etapa 2 |
| Variantes por companhia | Ponto de extensão tarifário | Antes da Etapa 4 |

🔵 **Resultado útil para a próxima decisão** (§47 do roteiro): a **Etapa 0 inteira e o motor financeiro da Etapa 4 são independentes da ADR-0007**, desde que a concessão seja expressa em **caso de uso**, nunca em rota. A ADR-0007 é bloqueio de **superfície**, não de sistema.

⚠️ **Reclassificação do nome do repositório** (§48): não é bloqueio de projeto, é **bloqueio de partida**. Diferente dos outros quatro em natureza — os demais exigem evidência, inventário ou aprovação técnica; este exige apenas que alguém decida. Não deve figurar com o mesmo peso.

## 7. A resposta concreta

| Pergunta | Resposta |
| -------- | -------- |
| O que se programa primeiro | A **fundação**: projeto modular com fronteira verificada, Flyway `V1`, Testcontainers, S1, auditoria mínima, convenção monetária |
| Primeira funcionalidade real | **Autenticar → consultar imóvel/cliente → abrir e tramitar um RA** |
| Quando começa Micromedição | Etapa 3 |
| Quando começa Faturamento | Etapa 4 — **no meio, não no fim** |
| Cobrança antes ou depois do Faturamento | 🔴 **Depois** |
| Quando entram os batches | Etapa 7, só após golden master do individual |
| Quando entra o Portal | Etapa 8 |

## 8. Atualizações de controle

| Documento | O que mudou |
| --------- | ----------- |
| `MODERNIZACAO_GSAN.md` | 18ª execução; artefato acrescentado aos concluídos; backlog renumerado (**próxima: compatibilidade conceitual**); seção de dependências bloqueadoras **reescrita** com a delimitação; "MÓDULOS MIGRADOS" → "MÓDULOS IMPLEMENTADOS", com a resposta do que se implementa primeiro |
| `docs/modernizacao/README.md` | Documento indexado; descrição de `modulos/README.md` corrigida; pasta `modulos/` marcada como completa |
| `docs/modernizacao/modulos/README.md` | **Reescrito**: título corrigido, resumo das 9 etapas, link ao detalhado, linguagem de migração operacional removida, ordem anterior declarada preliminar com as 8 mudanças e seus motivos, regra nova de que a ordem é revisável |
| `alteracoes/README.md` | Esta entrada |

## 9. Impacto

- **Criado**: `modulos/dependencias-e-ordem-implementacao.md`.
- **Reescrito**: `modulos/README.md`.
- **Atualizados**: `MODERNIZACAO_GSAN.md`, `docs/modernizacao/README.md`, `alteracoes/README.md`.
- **Não alterados**: os dez mapas funcionais, o mapa de domínio, a visão conceitual, a compatibilidade, o catálogo e as ADRs. ⚠️ **Nenhuma classificação, decisão ou divergência anterior foi revista.**
- ⚠️ **`plano-de-trabalho.md` não foi reescrito.** A §31.4 do novo documento mapeia Etapas × Fases e declara que a §5 do plano (ordem dos módulos) foi **substituída**, evitando duas numerações concorrentes sem tocar no histórico do plano. 🔵 Registrado como pendência de consolidação, não como contradição silenciosa.
- **Nenhuma alteração de código, banco ou infraestrutura.** Nenhum schema, migration, entidade, API ou tecnologia de comunicação entre módulos. **Nenhum cronograma, sprint ou data.** ADR-0007 continua pendente; D-17 continua proposta.

## 10. Próxima atividade

**Compatibilidade Conceitual GSAN → OpenGSAN** — correspondência entre conceitos, continuidades, diferenças deliberadas, conceitos reestruturados e semântica preservada. ⚠️ **Não trata da estratégia operacional de migração.**
