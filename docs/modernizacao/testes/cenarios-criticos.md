# Cenários Críticos do OpenGSAN — Índice e Matriz de Cobertura

> **Fase 0 — 20ª execução (2026-09-28); ampliado na 21ª (revisão controlada de escopo)** com os mapas de Financeiro/Contabilização e Operacional: **+8 especificações** e **+18 itens** de inventário. 🆕 **Ampliado na auditoria final (2026-09-29)**: **+8 especificações** — seis **requisitos nativos** (NFAg, Pix, Tarifa Social — oráculo **N**), o antigo **BLQ-04** e a divergência **D-18** —, inventário inalterado. Especifica **o que testar, em que estado, com qual entrada, o que observar, qual semântica esperar, qual diferença é permitida, qual oráculo decide e qual gate o teste protege**.
>
> 🔴 **Nada aqui foi executado.** Nenhum teste rodou, nenhum golden master foi capturado, nenhuma massa foi criada, nenhum *harness* foi escrito. Os **valores concretos** do GSAN são preenchidos na **Fase 2**.

---

## 1. Objetivo

Responder, antes de existir *harness*:

> **Se amanhã formos construir o *harness*, sabemos exatamente quais comportamentos críticos precisam ser exercitados e como decidir se o OpenGSAN está correto?**

As especificações estão em [`cenarios/`](cenarios/), por área. Este índice reúne a matriz de cobertura, os gates por etapa, os requisitos de massa, o que está bloqueado e a rastreabilidade do inventário.

| Área | Arquivo | Especificações |
| ---- | ------- | -------------: |
| Segurança | [`cenarios/seguranca.md`](cenarios/seguranca.md) | 12 |
| Cadastro e Atendimento | [`cenarios/cadastro-atendimento.md`](cenarios/cadastro-atendimento.md) | 13 |
| Micromedição | [`cenarios/micromedicao.md`](cenarios/micromedicao.md) | 5 |
| Faturamento | [`cenarios/faturamento.md`](cenarios/faturamento.md) | 12 |
| Arrecadação | [`cenarios/arrecadacao.md`](cenarios/arrecadacao.md) | 13 |
| Cobrança | [`cenarios/cobranca.md`](cenarios/cobranca.md) | 7 |
| Processamento, Relatórios e Integrações | [`cenarios/batch-relatorios-integracoes.md`](cenarios/batch-relatorios-integracoes.md) | 14 |
| Contabilização e Gestão Operacional | [`cenarios/financeiro-operacional.md`](cenarios/financeiro-operacional.md) | 8 |
| Fiscal 🆕 | [`cenarios/fiscal.md`](cenarios/fiscal.md) | 3 |
| **Total** | | **87** |

---

## 2. Especificação na Fase 0 × baseline na Fase 2

A regra normativa está em [`estrategia-testes.md`](estrategia-testes.md) — ⚠️ **corrigida nesta execução**, porque exigia um resultado capturado para considerar o cenário especificado, e a captura é da Fase 2, que depende da Fase 0.

| | Especificação — **Fase 0** | Baseline — **Fase 2** |
| - | -------------------------- | --------------------- |
| Fecha | operação, estado, entrada, observáveis, semântica comprovada, normalizações, divergência permitida, oráculo, gate | valores, registros, arquivos, totais, saídas efetivamente produzidos pelo GSAN de referência |
| 🔴 Não pode | inventar valor | deduzir valor de leitura de código |

🟢 **Estado desta entrega**: todas as especificações estão **fechadas**; **uma** baseline é `JÁ COMPROVADA` — a de um artefato estático (§6); 🆕 **seis** são `➖ NÃO APLICÁVEL` — requisitos nativos, sem legado a observar (§4.5); as demais estão `⬜ A CAPTURAR NA FASE 2`.

---

## 3. Como os cenários foram escolhidos

### 3.1 Critérios de criticidade

| | Falha pode… | Leitura |
| - | ----------- | ------- |
| **P0** | cobrar valor errado · baixar dívida errada · perder identidade · comprometer segurança · corromper em silêncio · permitir acesso indevido | ⚠️ Prioridade de **caracterização**, não de desenvolvimento |
| **P1** | quebrar regra importante do fluxo normal | — |
| **P2** | afetar variação relevante que não bloqueia o primeiro núcleo | Mantidos no inventário, **não especificados** nesta rodada (§10.5) |

Critérios de seleção: resultado financeiro · identidade · histórico/versão/linhagem · parametrização · mudança de estado · fronteira entre módulos · segurança · abrangência · lote · integração que escreve no domínio · operação difícil de corrigir · regra que alimenta outro módulo crítico.

### 3.2 Regra dos oráculos — aplicada, não reescolhida

Da [compatibilidade conceitual](../compatibilidade/gsan-opengsan.md) §22:

```text
C1 → oráculo 1                       C3 → oráculo 2 (igualdade é defeito)
C2 → oráculo 1, por mapeamento       C4 → sem equivalência a comparar
     semântico                       C5 → ver §12 — refinado nesta execução
🆕 requisito nativo (fora da matriz de compatibilidade) → oráculo N — auditoria final
```

Um mesmo cenário pode ter **observáveis de classes diferentes** — por exemplo, a autenticação (C1) e a forma da credencial armazenada (C3). Nesses casos o oráculo é declarado **por observável** (`1+2`), nunca escolhido para o cenário inteiro.

### 3.3 Deduplicação

Agrupou-se quando **a mesma operação** é exercitada com **os mesmos observáveis**, variando só a entrada — exatamente o que depois vira teste parametrizado. As variações ficam numa tabela **V1…Vn** dentro da especificação. ⚠️ Não se agrupou por tema: *efetuar* e *desfazer* parcelamento são operações distintas e ficaram em cenários distintos.

---

## 4. Do inventário à especificação

### 4.1 🔴 Correção: o inventário tinha 166 itens, não "~110" — hoje 184

A cifra "~110" circulava em seis documentos — inclusive no roteiro desta execução — e **nunca foi contada**. Contagem por script sobre as seções de cenários dos mapas funcionais:

| Mapa | Itens |
| ---- | ----: |
| Cadastro | 0 |
| Micromedição | 12 |
| Faturamento | 13 |
| Cobrança | 14 |
| Arrecadação | 20 |
| Atendimento | 22 |
| Segurança | 24 |
| Batch | 20 |
| Relatórios | 19 |
| Integrações | 22 |
| Financeiro/Contabilização 🆕 | 11 |
| Operacional 🆕 | 7 |
| **Total** | **184** |

⚠️ **O mapa do Cadastro não tem seção de cenários.** Os cinco cenários `CEN-CAD` foram derivados das regras e estados do próprio mapa.

🆕 **Auditoria final (2026-09-29)**: o inventário **não muda** (184). Muda um destino: o item 19 da Segurança (*restrição de grupo*) sai de **BLQ-02** para **CEN-SEG-004 V7**, porque o uso da restrição no cálculo de autorização foi **comprovado** no código ([`seguranca.md §10`](../modulos/seguranca.md)). O novo mapa [Fiscal](../modulos/fiscal.md) não tem inventário: descreve obrigação, não comportamento do GSAN.

🆕 **Revisão controlada de escopo (21ª execução)**: os dois módulos do GSAN que não tinham mapa — [Financeiro/Contabilização](../modulos/financeiro-contabilizacao.md) e [Operacional](../modulos/operacional.md) — acrescentaram **18 itens** ao inventário (166 → **184**). O item 22 de Integrações (*integração contábil padrão × variante*), antes `A COMPLEMENTAR`, passou a ser absorvido por **CEN-FIN-005** — só a variante de companhia continua a complementar.

### 4.2 Destino de cada item

| Destino | Itens |
| ------- | ----: |
| Absorvido em especificação | 151 |
| Bloqueado por decisão | 2 |
| Sem equivalência (C4) | 3 |
| A complementar — variante por companhia | 1 |
| P2 — mantido no inventário | 27 |
| **Total** | **184** |

🔵 **151 itens** foram absorvidos em **67 especificações**; outras **20** foram **derivadas** (§4.3). Total: **87 especificações**.

### 4.3 Especificações derivadas — sem origem no inventário

| Especificação | Origem |
| ------------- | ------ |
| [CEN-ARR-001](cenarios/arrecadacao.md) — Recepção do movimento do arrecadador | O inventário partia da classificação; faltava a **recepção** (ARR-01/02) |
| [CEN-ARR-006](cenarios/arrecadacao.md) — Identidade do pagamento no arquivamento | Cenário obrigatório de compatibilidade `C2` — identidade do pagamento (ARR-04) |
| [CEN-ARR-011](cenarios/arrecadacao.md) — Pagamento de Fatura do cliente responsável | 🆕 Auditoria final — antigo **BLQ-04**, desbloqueado pela semântica de "Fatura" (documento agregador) |
| [CEN-ARR-012](cenarios/arrecadacao.md) — Cobrança Pix vinculada ao documento: confirmação idempotente e conciliação | 🆕 Auditoria final — **requisito nativo**: Pix Cobrança na Arrecadação/Pagamentos |
| [CEN-ARR-013](cenarios/arrecadacao.md) — Pix Automático: autorização, cobrança recorrente, retentativa e cancelamento | 🆕 Auditoria final — **requisito nativo**: Pix Automático (autorização de pagamento recorrente) |
| [CEN-ATE-001](cenarios/cadastro-atendimento.md) — Consulta de imóvel e cliente sob autorização | Segundo passo da **fatia vertical** — consulta de imóvel |
| [CEN-CAD-001](cenarios/cadastro-atendimento.md) — Matrícula e dígito verificador | Regra 1 do mapa do Cadastro — o mapa não tem inventário |
| [CEN-CAD-002](cenarios/cadastro-atendimento.md) — Cliente × Imóvel por papel e vigência | Regra 5 do mapa do Cadastro |
| [CEN-CAD-003](cenarios/cadastro-atendimento.md) — Composição de economias por categoria e subcategoria | Regra 2 do mapa do Cadastro; CAND-01 |
| [CEN-CAD-004](cenarios/cadastro-atendimento.md) — Situações da ligação: faturabilidade e situação derivada do imóvel | Regras 3, 4 e 8 do mapa do Cadastro |
| [CEN-FAT-002](cenarios/faturamento.md) — Mudança de vigência tarifária dentro do período de leitura | 🟢 **Leitura dirigida de código** — cálculo proporcional entre vigências, 9 usos de HALF_UP |
| [CEN-FAT-011](cenarios/faturamento.md) — Imóvel sem consumo anterior: consumo de reserva | Divergência **D-15** sem cenário |
| [CEN-FAT-012](cenarios/faturamento.md) — Tarifa Social: concessão automática, desconto e perda de elegibilidade | 🆕 Auditoria final — **requisito nativo**: Tarifa Social nacional (Lei 14.898/2024) |
| [CEN-FIS-001](cenarios/fiscal.md) — Emissão da NFAg a partir da conta: autorização e rejeição | 🆕 Auditoria final — **requisito nativo**: NFAg, emissão, autorização e rejeição |
| [CEN-FIS-002](cenarios/fiscal.md) — Contingência e transmissão posterior | 🆕 Auditoria final — **requisito nativo**: NFAg, contingência |
| [CEN-FIS-003](cenarios/fiscal.md) — Retificação e cancelamento de conta com NFAg autorizada | 🆕 Auditoria final — **requisito nativo**: NFAg × retificação e cancelamento |
| [CEN-REL-002](cenarios/batch-relatorios-integracoes.md) — Resumos de faturamento e de arrecadação por competência | Prioridade 7 da baseline, corrigida para o núcleo (`RelatorioResumo*`) |
| [CEN-SEG-010](cenarios/seguranca.md) — Cadeia de filtros sem elo decorativo | Divergência **D-07** sem cenário |
| [CEN-SEG-011](cenarios/seguranca.md) — Nenhuma credencial em artefato versionado | Divergências **D-08** e **D-16** sem cenário |
| [CEN-SEG-012](cenarios/seguranca.md) — Sessão e requisição forjada | 🆕 Auditoria final — divergência **D-18** (achado 6) sem cenário |

🔵 **Por que existem**: o inventário listava o que cada mapa **observou**; ele não tinha como listar o que nenhum mapa cobria. As derivadas vêm de três fontes: a **fatia vertical** (consulta de imóvel), o **registro de divergências** (D-07, D-08, D-15, D-16 sem cenário próprio), e a **leitura dirigida de código** feita nesta execução para localizar as políticas de arredondamento — que revelou o cálculo proporcional entre vigências, **ausente de todo o inventário** e dono da maior concentração de HALF_UP do controlador. 🆕 **Na auditoria final**, mais três: a **varredura regulatória** (seis requisitos nativos), a **resolução do BLQ-04** (semântica de "Fatura") e a **D-18** sem cenário.

### 4.4 Sobre a quantidade

O roteiro sugeriu **35–60** especificações "somente se a evidência justificar". 🔵 A faixa foi calibrada para um inventário de ~110; com **166** itens reais, a mesma proporção (32 %–55 %) daria **53–91**. O resultado fica dentro dela — ⚠️ e não foi forçado: a contagem saiu da deduplicação, não o contrário. Com **184** itens (21ª execução), a mesma proporção daria **59–101**; eram **79** especificações. 🆕 A auditoria final levou a **87** — oito acréscimos, cada um justificado no §4.3, **seis deles fora do inventário por natureza** (requisitos nativos não têm item de mapa do GSAN).

### 4.5 🆕 Requisitos nativos — oráculo N

NFAg (CEN-FIS-001 a 003), Pix Cobrança (CEN-ARR-012), Pix Automático (CEN-ARR-013) e Tarifa Social nacional (CEN-FAT-012) **não existem no GSAN público**. O resultado esperado vem da **norma ou da decisão registrada**; a baseline do legado é `➖ NÃO APLICÁVEL`; e onde a regra ainda depende de confirmação, o cenário registra `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` e **não fecha** antes da resposta ([`estrategia-testes.md`](estrategia-testes.md)). ⚠️ Nenhum deles entra na matriz de compatibilidade GSAN → OpenGSAN.

---

## 5. Matriz mestre de cobertura

⚠️ **Gerada por script** a partir das próprias especificações — não digitada (regra permanente 6 de [`procedencia.md`](../procedencia.md)).

| ID | Área | Cenário | Crit. | Etapa | Compat. | Oráculo | Baseline | Gate |
| -- | ---- | ------- | ----- | ----- | ------- | ------- | -------- | ---- |
| [CEN-SEG-001](cenarios/seguranca.md) | Segurança | Autenticação legítima e forma da credencial armazenada | P0 | 0 | C1/C3 | 1+2 | ⬜ a capturar | 0 → 1 |
| [CEN-SEG-002](cenarios/seguranca.md) | Segurança | Credencial inválida e bloqueio por tentativas | P0 | 0 | C1 | 1 | ⬜ a capturar | 0 → 1 |
| [CEN-SEG-003](cenarios/seguranca.md) | Segurança | Ciclo de vida da credencial: situação, expiração e política de senha | P1 | 0 | C1 | 1 | ⬜ a capturar | 0 → 1 |
| [CEN-SEG-004](cenarios/seguranca.md) | Segurança | Matriz de autorização: concessão por união de grupos e negação | P0 | 1 | C1/C2 | 1 | ⬜ a capturar | 1 → 2 |
| [CEN-SEG-005](cenarios/seguranca.md) | Segurança | Rota excepcionada por substring no filtro de autorização | P0 | 1 | C1 | PEND | ⬜ a capturar | 1 → 2 |
| [CEN-SEG-006](cenarios/seguranca.md) | Segurança | Auditoria em dois níveis | P0 | 0 | C1 | 1 | ⬜ a capturar | 0 → 1 |
| [CEN-SEG-007](cenarios/seguranca.md) | Segurança | Abrangência territorial onde o legado a verifica | P0 | 2 | C1 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-SEG-008](cenarios/seguranca.md) | Segurança | Permissão especial nomeada | P1 | 2 | C1 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-SEG-009](cenarios/seguranca.md) | Segurança | Token de acesso dos servlets auxiliares | P1 | 0 | C3 | 2 | ⬜ a capturar | 0 → 1 |
| [CEN-SEG-010](cenarios/seguranca.md) | Segurança | Cadeia de filtros sem elo decorativo | P1 | 0 | C3 | 2 | ⬜ a capturar | 0 → 1 |
| [CEN-SEG-011](cenarios/seguranca.md) | Segurança | Nenhuma credencial em artefato versionado | P0 | 0 | C3 | 2 | 🟢 comprovada | 0 → 1 |
| [CEN-SEG-012](cenarios/seguranca.md) | Segurança | Sessão e requisição forjada | P1 | 1 | C3 | 2 | ⬜ a capturar | 1 → 2 |
| [CEN-CAD-001](cenarios/cadastro-atendimento.md) | Cadastro | Matrícula e dígito verificador | P1 | 1 | C1/C2 | 1 | ⬜ a capturar | 1 → 2 |
| [CEN-CAD-002](cenarios/cadastro-atendimento.md) | Cadastro | Cliente × Imóvel por papel e vigência | P0 | 1 | C1 | 1 | ⬜ a capturar | 1 → 2 |
| [CEN-CAD-003](cenarios/cadastro-atendimento.md) | Cadastro | Composição de economias por categoria e subcategoria | P0 | 2 | C1/C2 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-CAD-004](cenarios/cadastro-atendimento.md) | Cadastro | Situações da ligação: faturabilidade e situação derivada do imóvel | P0 | 2 | C1/C2 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-CAD-005](cenarios/cadastro-atendimento.md) | Cadastro | Rotas por finalidade | P1 | 2 | C2 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-ATE-001](cenarios/cadastro-atendimento.md) | Atendimento | Consulta de imóvel e cliente sob autorização | P1 | 1 | C1 | 1 | ⬜ a capturar | 1 → 2 |
| [CEN-ATE-002](cenarios/cadastro-atendimento.md) | Atendimento | Abertura de RA governada pela especificação | P1 | 1 | C1/C2 | 1 | ⬜ a capturar | 1 → 2 |
| [CEN-ATE-003](cenarios/cadastro-atendimento.md) | Atendimento | Encerramento de RA sem OS e encerramento automático | P1 | 1 | C1 | 1 | ⬜ a capturar | 1 → 2 |
| [CEN-ATE-004](cenarios/cadastro-atendimento.md) | Atendimento | Tramitação entre unidades | P1 | 1 | C1 | 1 | ⬜ a capturar | 1 → 2 |
| [CEN-ATE-005](cenarios/cadastro-atendimento.md) | Atendimento | Prazo, espera e reiteração | P1 | 2 | C1/C2 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-ATE-006](cenarios/cadastro-atendimento.md) | Atendimento | Ciclo de vida da OS: executada e não executada | P1 | 2 | C1 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-ATE-007](cenarios/cadastro-atendimento.md) | Atendimento | Efeito cadastral da OS aplicado pelo dono | P0 | 2 | C2 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-ATE-008](cenarios/cadastro-atendimento.md) | Atendimento | Efeito financeiro do serviço executado | P0 | 4 | C1/C2 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-MIC-001](cenarios/micromedicao.md) | Micromedição | Consumo da referência por situação de leitura | P0 | 3 | C1 | 1 | ⬜ a capturar | 3 → 4 |
| [CEN-MIC-002](cenarios/micromedicao.md) | Micromedição | Consumo mínimo e precedência de overrides | P0 | 3 | C1/C2 | 1 | ⬜ a capturar | 3 → 4 |
| [CEN-MIC-003](cenarios/micromedicao.md) | Micromedição | Troca de hidrômetro na referência | P0 | 3 | C1/C2 | 1 | ⬜ a capturar | 3 → 4 |
| [CEN-MIC-004](cenarios/micromedicao.md) | Micromedição | Anormalidades: virada de hidrômetro e limiares de consumo | P1 | 3 | C1 | 1 | ⬜ a capturar | 3 → 4 |
| [CEN-MIC-005](cenarios/micromedicao.md) | Micromedição | Leitura informada × leitura de faturamento | P1 | 3 | C1 | 1 | ⬜ a capturar | 3 → 4 |
| [CEN-FAT-001](cenarios/faturamento.md) | Faturamento | Valor de água por economias, categorias e origem do consumo | P0 | 4 | C1 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-002](cenarios/faturamento.md) | Faturamento | Mudança de vigência tarifária dentro do período de leitura | P0 | 4 | C1 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-003](cenarios/faturamento.md) | Faturamento | Esgoto: percentual padrão, alternativo e poço | P0 | 4 | C1/C2 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-004](cenarios/faturamento.md) | Faturamento | Débitos cobrados e créditos realizados na conta | P0 | 4 | C1 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-005](cenarios/faturamento.md) | Faturamento | Impostos deduzidos | P0 | 4 | C1 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-006](cenarios/faturamento.md) | Faturamento | Rateio de micro-condomínio | P0 | 4 | C1 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-007](cenarios/faturamento.md) | Faturamento | Retificação de conta | P0 | 4 | C1/C2/C3 | 1+2 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-008](cenarios/faturamento.md) | Faturamento | Cancelamento e prescrição | P0 | 4 | C1/C2 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-009](cenarios/faturamento.md) | Faturamento | Emissão: pré-faturamento, linhas tarifárias e vencimento | P1 | 4 | C1 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-010](cenarios/faturamento.md) | Faturamento | Referência de faturamento × referência contábil | P1 | 4 | C1 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-011](cenarios/faturamento.md) | Faturamento | Imóvel sem consumo anterior: consumo de reserva | P1 | 4 | C3 | 1+2 | ⬜ a capturar | 4 → 5 |
| [CEN-FAT-012](cenarios/faturamento.md) | Faturamento | Tarifa Social: concessão automática, desconto e perda de elegibilidade | P0 | 4 | nativo/C1 | N | ➖ não aplicável | 4 → 5 |
| [CEN-ARR-001](cenarios/arrecadacao.md) | Arrecadação | Recepção do movimento do arrecadador | P1 | 5 | C1 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-002](cenarios/arrecadacao.md) | Arrecadação | Classificação contra conta vigente, por valor e prazo | P0 | 5 | C1 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-003](cenarios/arrecadacao.md) | Arrecadação | Classificação em situação especial: nada é descartado | P0 | 5 | C1 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-004](cenarios/arrecadacao.md) | Arrecadação | Pagamento em duplicidade e devolução | P0 | 5 | C1 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-005](cenarios/arrecadacao.md) | Arrecadação | Pagamento de conta retificada ou arquivada | P0 | 5 | C2 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-006](cenarios/arrecadacao.md) | Arrecadação | Identidade do pagamento no arquivamento | P0 | 5 | C2 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-007](cenarios/arrecadacao.md) | Arrecadação | Conciliação por aviso bancário | P1 | 5 | C1 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-008](cenarios/arrecadacao.md) | Arrecadação | Pagamento de entrada e de prestação de parcelamento | P0 | 6 | C1 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-ARR-009](cenarios/arrecadacao.md) | Arrecadação | Débito automático | P1 | 6 | C1 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-ARR-010](cenarios/arrecadacao.md) | Arrecadação | Encerramento mensal da arrecadação | P0 | 7 | C1 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-ARR-011](cenarios/arrecadacao.md) | Arrecadação | Pagamento de Fatura do cliente responsável | P1 | 5 | C1/C2 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-ARR-012](cenarios/arrecadacao.md) | Arrecadação | Cobrança Pix vinculada ao documento: confirmação idempotente e conciliação | P1 | 5 | nativo/C1 | N | ➖ não aplicável | 5 → 6 |
| [CEN-ARR-013](cenarios/arrecadacao.md) | Arrecadação | Pix Automático: autorização, cobrança recorrente, retentativa e cancelamento | P1 | 6 | nativo/C1 | N | ➖ não aplicável | 6 → 7 |
| [CEN-COB-001](cenarios/cobranca.md) | Cobrança | Posição de dívida derivada | P0 | 5 | C2 | 1 | ⬜ a capturar | 5 → 6 |
| [CEN-COB-002](cenarios/cobranca.md) | Cobrança | Ação de cobrança e pagamento antes ou depois do documento | P0 | 6 | C1 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-COB-003](cenarios/cobranca.md) | Cobrança | Corte e religação | P1 | 6 | C1/C2 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-COB-004](cenarios/cobranca.md) | Cobrança | Efetuar parcelamento | P0 | 6 | C1 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-COB-005](cenarios/cobranca.md) | Cobrança | Desfazimento e reparcelamento | P0 | 6 | C1 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-COB-006](cenarios/cobranca.md) | Cobrança | Negativação e exclusão | P1 | 6 | C1/C2 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-COB-007](cenarios/cobranca.md) | Cobrança | Retificação, cancelamento e prescrição de conta já em cobrança | P0 | 6 | C2 | 1 | ⬜ a capturar | 6 → 7 |
| [CEN-BAT-001](cenarios/batch-relatorios-integracoes.md) | Processamento | Execução de processo em três níveis, com autorização | P1 | 7 | C1 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-BAT-002](cenarios/batch-relatorios-integracoes.md) | Processamento | Falha de unidade, retomada e reprocessamento | P0 | 7 | C1 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-BAT-003](cenarios/batch-relatorios-integracoes.md) | Processamento | Atomicidade dentro da unidade | P0 | 7 | C5 | PEND | ⬜ a capturar | 7 → operação |
| [CEN-BAT-004](cenarios/batch-relatorios-integracoes.md) | Processamento | Execução duplicada com os mesmos parâmetros | P0 | 7 | C1 | PEND | ⬜ a capturar | 7 → operação |
| [CEN-BAT-005](cenarios/batch-relatorios-integracoes.md) | Processamento | Faturamento em lote igual à soma dos individuais | P0 | 7 | C1 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-REL-001](cenarios/batch-relatorios-integracoes.md) | Relatórios | Acesso ao artefato de relatório | P0 | 2 | C1/C3 | 1+2 | ⬜ a capturar | 2 → 3 |
| [CEN-REL-002](cenarios/batch-relatorios-integracoes.md) | Relatórios | Resumos de faturamento e de arrecadação por competência | P1 | 7 | C1 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-INT-001](cenarios/batch-relatorios-integracoes.md) | Integrações | Coleta móvel de leitura | P0 | 3 | C1/C3 | 1+2 | ⬜ a capturar | 3 → 4 |
| [CEN-INT-002](cenarios/batch-relatorios-integracoes.md) | Integrações | Telemetria | P1 | 3 | C1/C3 | 1+2 | ⬜ a capturar | 3 → 4 |
| [CEN-INT-003](cenarios/batch-relatorios-integracoes.md) | Integrações | API de ordem de serviço | P0 | 3 | C3 | 2 | ⬜ a capturar | 3 → 4 |
| [CEN-INT-004](cenarios/batch-relatorios-integracoes.md) | Integrações | Integração com sistema parceiro por banco compartilhado (UPA/SAM) | P1 | 3 | C1/C3 | 1+2 | ⬜ a capturar | 3 → 4 |
| [CEN-INT-005](cenarios/batch-relatorios-integracoes.md) | Integrações | API de pagamento: autenticação do chamador | P0 | 5 | C3 | 2 | ⬜ a capturar | 5 → 6 |
| [CEN-INT-006](cenarios/batch-relatorios-integracoes.md) | Integrações | SMS por tipo de mensagem | P1 | 6 | C1/C3 | 2 | ⬜ a capturar | 6 → 7 |
| [CEN-INT-007](cenarios/batch-relatorios-integracoes.md) | Integrações | Requisição GIS assinada | P1 | 8 | C3 | 1+2 | ⬜ a capturar | etapa 8 |
| [CEN-FIN-001](cenarios/financeiro-operacional.md) | Contabilização | Lançamentos contábeis da competência por origem | P0 | 7 | C1/C2 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-FIN-002](cenarios/financeiro-operacional.md) | Contabilização | Baixa contábil de devedores duvidosos e recuperação | P0 | 7 | C1/C2 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-FIN-003](cenarios/financeiro-operacional.md) | Contabilização | Regeração da contabilização de uma competência | P1 | 7 | C1 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-FIN-004](cenarios/financeiro-operacional.md) | Contabilização | Volumes consumidos e não faturados da competência | P1 | 7 | C1 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-FIN-005](cenarios/financeiro-operacional.md) | Contabilização | Exportação dos lançamentos para o sistema contábil | P1 | 7 | C1/C2 | 1 | ⬜ a capturar | 7 → operação |
| [CEN-OPE-001](cenarios/financeiro-operacional.md) | Gestão Operacional | Localização operacional da demanda | P1 | 2 | C1/C2 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-OPE-002](cenarios/financeiro-operacional.md) | Gestão Operacional | RA de falta de água confrontado com a programação | P1 | 2 | C1 | 1 | ⬜ a capturar | 2 → 3 |
| [CEN-OPE-003](cenarios/financeiro-operacional.md) | Gestão Operacional | Qualidade da água no documento emitido | P1 | 4 | C1/C2 | 1 | ⬜ a capturar | 4 → 5 |
| [CEN-FIS-001](cenarios/fiscal.md) | Fiscal | Emissão da NFAg a partir da conta: autorização e rejeição | P0 | 4 | nativo/C2 | N | ➖ não aplicável | 4 → 5 |
| [CEN-FIS-002](cenarios/fiscal.md) | Fiscal | Contingência e transmissão posterior | P0 | 7 | nativo/C1 | N | ➖ não aplicável | 7 → operação |
| [CEN-FIS-003](cenarios/fiscal.md) | Fiscal | Retificação e cancelamento de conta com NFAg autorizada | P0 | 7 | nativo/C1/C2 | N | ➖ não aplicável | 7 → operação |

---

## 6. Distribuições

| Área | Qtd |
| --- | --: |
| Segurança | 12 |
| Cadastro | 5 |
| Atendimento | 8 |
| Micromedição | 5 |
| Faturamento | 12 |
| Arrecadação | 13 |
| Cobrança | 7 |
| Processamento | 5 |
| Relatórios | 2 |
| Integrações | 7 |
| Contabilização | 5 |
| Gestão Operacional | 3 |
| Fiscal | 3 |
| **Total** | **87** |

| Criticidade | Qtd |
| --- | --: |
| P0 | 49 |
| P1 | 38 |
| **Total** | **87** |

| Oráculo | Qtd |
| --- | --: |
| 1 — igualdade | 63 |
| 1+2 — por observável | 8 |
| 2 — divergência exigida | 7 |
| N — requisito nativo 🆕 | 6 |
| Pendente de caracterização | 3 |
| **Total** | **87** |

| Etapa | Qtd |
| --- | --: |
| 0 — Fundação | 7 |
| 1 — Fatia vertical | 9 |
| 2 — Atendimento e execução | 11 |
| 3 — Medição | 9 |
| 4 — Financeiro individual | 15 |
| 5 — Recebimento | 11 |
| 6 — Cobrança | 10 |
| 7 — Escala | 14 |
| 8 — Canais | 1 |
| **Total** | **87** |

| Baseline | Qtd |
| --- | --: |
| ⬜ A capturar na Fase 2 | 80 |
| 🟢 Já comprovada | 1 |
| ➖ Não aplicável — requisito nativo 🆕 | 6 |
| **Total** | **87** |

🔵 **Leituras**:

- **P0 é maioria** porque o núcleo financeiro é P0 por natureza — cada centavo errado é cobrança errada.
- **A Etapa 4 concentra o maior número de cenários**: é onde o GSAN mais acertou e onde a equivalência é mais estrita.
- **A única baseline já comprovada** é a de CEN-SEG-011: ali o observável é o **próprio artefato versionado** — ler o arquivo *é* observá-lo. Para qualquer comportamento em execução, leitura de código **não** vale como baseline.
- **Todos os `D-xx` aprovados têm cenário** — 🆕 **17** desde a auditoria final, que registrou a aprovação de D-01…D-16 e criou a D-18: D-01 SEG-001 · D-02 SEG-009 · D-03 REL-001 · D-04 INT-003 · D-05 INT-001, INT-002 · D-06 INT-005 · D-07 SEG-010 · D-08 SEG-011 · D-09 INT-005, INT-006 · D-10 INT-003 · D-11 INT-007 · D-12 INT-004 · D-13 INT-006 · D-14 FAT-007 · D-15 FAT-011 · D-16 SEG-011 · 🆕 D-18 SEG-012.
- 🆕 **Seis cenários não têm baseline do legado** — são requisitos nativos (§4.5). Não é lacuna: não há comportamento GSAN a observar.

---

## 7. Cobertura das cinco políticas de arredondamento

🔴 **Não existe um cenário "arredondamento".** Cada política é exercitada **onde ela produz resultado**. A localização foi feita por leitura dirigida de código nesta execução — escopo declarado: **`ControladorFaturamentoFINAL.java`, uma classe**.

| Política | Ocorr. | Métodos (ocorrências) | Cenário que a executa |
| -------- | -----: | --------------------- | --------------------- |
| **HALF_UP** | 27 | `calculoProporcionalMaisDeUmaTarifa` (9) · `calcularValorPrestacao` (5) · `getCalcularValoresAguaEsgotoHelper` (3) · `getCalcularValoresAguaEsgotoBigDecimalHelper` (3) · `calcularValorCreditoBolsaAguaAtualizado` (2) · `gerarDadosAliquotasImpostos` (2) · `calculoSimplesUmaTarifa` (1) · `gerarDebitoACobrarTaxaEmissaoConta` (1) · `calcularConsumoMinimo` (1) | FAT-002 · ATE-008 · FAT-001 · FAT-005 · FAT-004 V5 · MIC-002 — ⚠️ Bolsa Água: `A COMPLEMENTAR` |
| **UP** | 21 | `gerarLinhasTarifaAgua*` — quatro variantes (12) · `emitir2ViaContas` (2) · `emitir2ViaContasHistorico` (2) · `getCalcularValoresAguaEsgotoBigDecimalHelper` (1) · `getCalcularValoresAguaEsgotoFaixaBigDecimalHelper` (1) · `emitirContas` (1) · `emitirFichaCompensacao` (1) · `obterConsumoFaturadoConsumoMedioDiario` (1) | FAT-001 (cálculo) · FAT-009 (emissão) — ⚠️ consumo médio diário: chamado **só** por controladores de companhia, `A COMPLEMENTAR` |
| **DOWN** | 5 | `gerarImpostosDeduzidosConta` (3, inclusive o truncamento da base) · `obterValorCurtoELongoPrazo` (1) · `gerarDebitoCobrado` (1) | FAT-005 · COB-004 · FAT-004 |
| **HALF_DOWN** | 2 | `gerarImpostosDeduzidosConta` (2) | FAT-005 |
| **FLOOR** | 2 | `calcularValorRateioPorEconomia` (2) — **alcançável** pelo `gerarConta` do micro-condomínio | FAT-006 |

🟢 **As cinco políticas têm ao menos um cenário que as executa.** Das **57** ocorrências, **54** estão em caminhos cobertos; **3** estão em caminhos de companhia (Bolsa Água, consumo médio diário) e ficam `A COMPLEMENTAR`.

⚠️ **O que a localização revelou e o inventário não via**:

1. A **maior concentração** de HALF_UP (9 de 27) está no **cálculo proporcional entre vigências** — um cenário que **nenhum mapa listou** (CEN-FAT-002).
2. **UP afasta do zero sempre** e está sobretudo na **emissão** — nas linhas tarifárias impressas —, não só no cálculo. O documento emitido é observável financeiro (CEN-FAT-009).
3. **Três políticas convivem num único cálculo** — impostos (CEN-FAT-005).
4. FLOOR só aparece no rateio de micro-condomínio, **precedido de um acréscimo construído a partir de `double`**. Nenhum efeito sobre os centavos é presumido (CEN-FAT-006).

🔴 **Limite desta cobertura**: Cobrança e Arrecadação **não foram varridas**. Parcelamento e acréscimos por impontualidade podem ter políticas próprias em seus controladores. **Essa varredura é pré-requisito da captura dessas baselines** (§17).

---

## 8. Cenários P0 mais importantes

Dos P0, os que mais protegem — escolhidos pelo dano que a falha causaria e pelo número de cenários que dependem deles:

| Cenário | Por quê |
| ------- | ------- |
| **CEN-FAT-001** — valor de água | Caso base do motor; todo o resto do financeiro o supõe |
| **CEN-FAT-002** — vigência proporcional | Maior concentração de uma política de arredondamento; **ausente do inventário** |
| **CEN-ARR-005** — pagamento de conta retificada ou arquivada | Teste central da **identidade documental** |
| **CEN-ARR-006** — identidade do pagamento | Compara **sem chave** — a armadilha mais provável do *harness* |
| **CEN-COB-001** — posição de dívida derivada | Valida o conceito **uma etapa antes** da Cobrança existir |
| **CEN-COB-004/005** — parcelamento | A regra financeira mais complexa; memória integral ao centavo |
| **CEN-FAT-007** — retificação | Linhagem + identidade + a única divergência de fronteira (D-14) |
| **CEN-ATE-007** — efeito cadastral da OS | O **contrato central** do OpenGSAN: *a OS solicita, o dono aplica* |
| **CEN-SEG-004** — matriz de autorização | Prova **negação**, não só concessão |
| **CEN-REL-001** — acesso ao artefato | Acesso indevido **confirmado** no legado (D-03) |
| **CEN-BAT-002** — retomada sem refazer | Reprocessar não pode duplicar efeito de dinheiro |
| 🆕 **CEN-FIS-001** — emissão da NFAg | Obrigação que acompanha **toda** conta; *Conta ≠ NFAg* verificado desde a Etapa 4 |
| 🆕 **CEN-FAT-012** — Tarifa Social | Obrigação legal que **altera o valor** da conta; concessão automática |

---

## 9. Gates mínimos por etapa

⚠️ **Só os essenciais** — não a lista completa da etapa. Cada gate reproduz a transição definida em [`dependencias-e-ordem-implementacao.md`](../modulos/dependencias-e-ordem-implementacao.md) §25.

| Transição | Cenários obrigatórios | O que precisam provar |
| --------- | --------------------- | --------------------- |
| **0 → 1** | SEG-001 · SEG-002 · SEG-006 · SEG-010 · SEG-011 | Autenticação contra hash moderno · bloqueio por tentativas · escrita auditada · cada filtro barra · CI reprova segredo |
| **1 → 2** | SEG-004 · ATE-001 · ATE-002 · ATE-003 · ATE-004 · CAD-002 · 🆕 SEG-012 | **Negação provada** (🆕 inclusive a restrição por usuário) · consulta autorizada · RA governado por dado · encerramento · tramitação · cliente por papel · 🆕 requisição forjada recusada |
| **2 → 3** | ATE-007 · SEG-007 · CAD-003 · CAD-004 · REL-001 | **Efeito aplicado pelo dono** · escopo territorial · economias · faturabilidade · artefato protegido |
| **3 → 4** | MIC-001 · MIC-002 · MIC-003 · INT-001 | Consumo com **origem declarada** · mínimo · troca · leitura rejeitada sem dispositivo identificado |
| **4 → 5** | FAT-001 · FAT-002 · FAT-003 · FAT-005 · FAT-006 · FAT-007 · 🆕 FIS-001 · FAT-012 | **Ao centavo** · as cinco políticas caracterizadas · retificação pela operação da Micromedição · 🆕 documento fiscal autorizado ou rejeição rastreável · Tarifa Social pela regra vigente |
| **5 → 6** | ARR-002 · ARR-003 · ARR-005 · ARR-006 · COB-001 · 🆕 ARR-012 | Baixa · **nada descartado** · identidade documental · identidade do pagamento · posição derivada · 🆕 confirmação Pix idempotente |
| **6 → 7** | COB-002 · COB-004 · COB-005 | Ação e documento · parcelamento **criar e desfazer** |
| **7 → operação** | BAT-002 · BAT-005 · ARR-010 · FIN-001 · 🆕 FIS-002 · FIS-003 | Retomada sem refazer · **lote = soma dos individuais** · encerramento · **lançamentos contábeis conferem com os resumos** · 🆕 nenhuma conta sem documento fiscal · retificação e cancelamento com o tratamento fiscal vigente |
| **Etapa 8** | INT-007 | ⚠️ GIS é evolução — não gate do núcleo |

⚠️ **Três cenários de gate têm oráculo pendente** e só fecham depois da caracterização: SEG-005 (1 → 2), BAT-003 e BAT-004 (7 → operação). Eles **não** estão na coluna de obrigatórios acima, mas bloqueiam a transição se a baseline revelar comportamento que exija divergência. 🆕 E **CEN-FIS-003** só fecha quando a regra fiscal da retificação e do cancelamento for confirmada (`VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` — [`fiscal.md §12`](../modulos/fiscal.md)).

---

## 10. Bloqueados, pendentes e a complementar

🔴 **Nenhum buraco escondido.** Tudo o que **não** foi especificado como cenário fechado está aqui, com o motivo.

### 10.1 BLOQUEADO POR DECISÃO

| ID | O que seria testado | Origem | Decisão que falta |
| -- | ------------------- | ------ | ----------------- |
| **BLQ-01** | Consulta em superfície que **não** chama a verificação de abrangência | SEG#16 | 🔴 **Aprovação de D-17** — a divergência continua **proposta** |
| ~~**BLQ-02**~~ | Efeito de restrição de grupo (*deny*) sobre a autorização | SEG#19 | ✅ **Desbloqueado na auditoria final (2026-09-29)**: o uso **foi observado** — acesso se restrições < concessões (`ControladorAcessoSEJB:3104`, `:3517`). Absorvido em **CEN-SEG-004 V7** |
| **BLQ-03** | Disparo de processamento sobre território fora da abrangência | BAT#15 | **D-17** — e abrangência no lote **não localizada** |
| ~~**BLQ-04**~~ | Pagamento contra documento do tipo **Fatura** | derivado | ✅ **Desbloqueado na auditoria final (2026-09-29)**: "Fatura" é o documento **agregador** do cliente responsável; o pagamento se desdobra por conta. Especificado em **CEN-ARR-011** |

### 10.2 PENDENTE DE CARACTERIZAÇÃO

Especificados e prontos para a Fase 2 — o que falta é **decidir o oráculo depois de ver a baseline**:

| Cenário | Por que o oráculo não é decidível agora |
| ------- | --------------------------------------- |
| **CEN-SEG-005** | Se a Action excepcionada protege por controle interno, oráculo 1; se retorna dado, proteger exige divergência — **CAND-04** |
| **CEN-SEG-002 V3** | Bloqueio por tentativas em sessões diferentes — **CAND-03** |
| **CEN-BAT-003** | Atomicidade dentro da unidade — **CAND-02**. 🔴 Não se constrói oráculo 2 como se a divergência existisse |
| **CEN-BAT-004** | Execução duplicada — se houver faturamento em dobro, protegê-lo exige divergência |
| **CEN-OPE-003 V5** 🆕 | O passo 2 da cascata de qualidade da água não limpa o filtro do passo 1 — se o legado deixar de encontrar o registro por isso, não reproduzir exige divergência |
| **CEN-SEG-004 V7(c)** 🆕 | Composição do filtro de restrições com limite de laço trocado (`ControladorAcessoSEJB:3072`) — se o resultado desviar de "restrições < concessões", não reproduzir exige divergência — **CAND-05** |

### 10.3 A COMPLEMENTAR — variantes por companhia

🔴 O inventário das diferenças reais entre variantes **continua pendente**. Os cenários caracterizam **a variante ativa na instância de referência**; as demais esperam o inventário:

| Item | Onde |
| ---- | ---- |
| Dígito verificador da matrícula por companhia | CEN-CAD-001 |
| Variantes de cálculo de faixa (ex.: `calcularValorFaturadoFaixaCAER`) | CEN-FAT-001 |
| Crédito de programa social nomeado (`calcularValorCreditoBolsaAguaAtualizado`) | cobertura HALF_UP |
| Consumo médio diário em controladores de companhia (`obterConsumoFaturadoConsumoMedioDiario`) | cobertura UP |
| Confirmação de recebimento com variação por código de empresa | INT#4 |
| Formatos de exportação contábil por companhia (CAEMA, CAERN, COSAMA, COSANPA) | CEN-FIN-005 V3 — o formato base de INT#22 foi absorvido |

### 10.4 Sem equivalência — `C4`

Não há teste legado × OpenGSAN para: **disparo agendado por Quartz** (BAT#3), **paralelismo pelo pool de MDB** (BAT#13), **template e subrelatório Jasper** (REL#18). ⚠️ O OpenGSAN pode ter testes próprios dessas capacidades — nunca de equivalência.

### 10.5 P2 — mantidos no inventário, não especificados

Registrados para a auditoria, com o motivo:

| Itens | Motivo |
| ----- | ------ |
| REL#1–9, #11, #15–17, #19 | Mecânica do motor de relatório (online × lote, formatos, erros, agendamento, parâmetros). Não produzem resultado de negócio; entram quando o motor for construído (Etapa 2) |
| ATE#7, #8, #21, #22 | Duplicidade por área, reativação, OS referenciada, encerramento em massa — variações operacionais fora dos gates iniciais |
| COB#14, ARR#20 | Cobrança terceirizada — módulo opcional |
| SEG#24 | Solicitação de acesso — administração progressiva (S3) |
| INT#5, #19 | Teste de conexão; e-mail com falha de SMTP |
| FIN#8, #11 🆕 | Resumos contábeis derivados — contas a receber, documentos por faixa de vencimento, receita por banco. Regeráveis e sem efeito sobre documento; o envelhecimento volta a importar se a PECLD entrar no escopo |
| OPE#6, #7 🆕 | Mecânica de cadastro — manutenção da programação e filtro de fontes na tela de qualidade |

---

## 11. Candidatos a divergência

⚠️ **Nenhum aprovado.** São comportamentos que talvez devam mudar e **não estão registrados**. Os dois primeiros vêm da execução anterior; CAND-03 e CAND-04, da especificação dos cenários; 🆕 CAND-05, da auditoria final. ⚠️ A auditoria **não** aprovou CAND-03 nem CAND-04: não há decisão explícita nem caracterização que as sustente.

| # | Conceito | Origem | Situação |
| - | -------- | ------ | -------- |
| CAND-01 | Valores denormalizados no Imóvel | 19ª execução | Condicional à caracterização — CEN-CAD-003 |
| CAND-02 | Atomicidade dentro da unidade | 19ª execução | Condicional à caracterização — CEN-BAT-003 |
| **CAND-03** | **Contador de tentativas de login na sessão** | 🆕 | 🟢 O contador vive na `HttpSession`; o mapa de segurança o classifica `REESTRUTURAR` e a visão conceitual o descreve como "persistente" **atribuindo-o a D-01** — mas ⚠️ **o texto de D-01 cobre apenas o hash**. É **lacuna de registro**: ampliar D-01 ou criar divergência própria — CEN-SEG-002 V3 |
| **CAND-04** | **Exceção de autorização por substring `pesquisar`/`relatorio`** | 🆕 | 🟢 Qualquer Action cujo nome contenha os termos **sai do bloco de autorização funcional do filtro**; para `relatorio` no download, o acesso indevido já é achado confirmado. Para `pesquisar`, **depende de cada Action** — CEN-SEG-005 |
| 🆕 **CAND-05** | **Composição do filtro de restrições por funcionalidade** | Auditoria final | 🟢 No laço sobre as concessões, o marcador do último termo do `OR` usa o total de **grupos**, não de concessões (`ControladorAcessoSEJB:3072`) — condicional à caracterização — CEN-SEG-004 V7(c) |

---

## 12. Refinamento: nem todo `C5` bloqueia cenário

⚠️ **Correção de uma afirmação da execução anterior.** A compatibilidade conceitual registrou que *"conceito em C5 não tem cenário de teste especificável"*. Ao especificar, isso se mostrou **forte demais** — e a diferença importa, porque bloquearia caracterizações financeiras sem motivo.

| C5 | Bloqueia cenário? | Por quê |
| -- | ----------------- | ------- |
| Semântica de "Fatura" | ~~🔴 Sim — BLQ-04~~ ✅ **Resolvida** (auditoria final) | Documento agregador — CEN-ARR-011 |
| Mecanismo de negação | ~~🔴 Sim — BLQ-02~~ ✅ **Resolvido** (auditoria final) | Restrição por usuário comprovada no código — CEN-SEG-004 V7 |
| Aplicação da abrangência (D-17) | 🔴 **Sim** — BLQ-01, BLQ-03 | Depende de aprovação que ainda não existe |
| Fórmulas de acréscimo | 🟢 **Não** | A pendência é de **representação** (parametrizar ou não). O **resultado** é financeiro e, pela regra explícita do registro de divergências, **oráculo 1** — CEN-ARR-002 V2 |
| Cardinalidade física RA ↔ OS | 🟢 **Não** | A pendência é **física**; os casos semânticos (RA sem OS, OS de origem não individual) são observáveis. A caracterização **produz a evidência** que a decisão precisa |
| Atomicidade dentro da unidade | ⚠️ **Especificável, oráculo pendente** | CEN-BAT-003 |
| Retenção de artefatos | 🟢 **Não** | Política, não comportamento a comparar; nenhum cenário crítico depende dela |

🔵 **A regra refinada**: um `C5` bloqueia cenário **quando o comportamento esperado do OpenGSAN depende da decisão pendente**. Quando a pendência é de representação — e o oráculo já está fixado por outra regra explícita —, o cenário é especificável, e muitas vezes é **ele** que produz a evidência para decidir. A correção foi aplicada em [`gsan-opengsan.md`](../compatibilidade/gsan-opengsan.md).

---

## 13. Requisitos de massa — perfis

🔴 **Perfis, não registros.** Nenhum dado pessoal real: nomes, documentos, telefones e endereços são **sintéticos**. ⚠️ O telefone real que aparece no `main()` de `ServicoSMS` **não** é reutilizado.

### 13.1 Imóveis

| Perfil | Características |
| ------ | --------------- |
| **IMV-01** | Residencial · 1 economia · 1 categoria · água ligada · esgoto ligado com percentual padrão · hidrômetro com histórico ≥ 6 referências · leitura normal · clientes em três papéis, com troca de cliente-usuário no meio de uma referência · autorização de débito automático |
| **IMV-02** | Várias economias (≥ 3) na mesma categoria |
| **IMV-03** | Várias categorias e subcategorias, com economias em cada |
| **IMV-04** | Ligado, **sem hidrômetro** |
| **IMV-05** | Hidrômetro instalado na referência anterior — **primeira leitura** |
| **IMV-06** | Leitura **não realizada** em três referências consecutivas |
| **IMV-07** | Leitura não realizada com **histórico insuficiente** para média |
| **IMV-08** | Hidrômetro a ser **substituído** no meio do período |
| **IMV-09** | Leitura próxima do máximo de dígitos — **virada** |
| **IMV-10** | Média conhecida, para limiares de alto, estouro e baixo consumo |
| **IMV-11a** | Esgoto com percentual **alternativo acima do limite** |
| **IMV-11b** | **Poço** compondo o volume de esgoto |
| **IMV-12a** | Situação especial PARALISAR_LEITURA_FATURAR_MEDIA |
| **IMV-12b** | Situação especial PARALISAR_LEITURA_FATURAR_TAXA_MINIMA |
| **IMV-13** | Unidade de **micro-condomínio**, com condomínio principal medido |
| **IMV-14** | Cliente sujeito a **retenção de impostos** |
| **IMV-15** | Água **cortada**, débito quitado |
| **IMV-16** | **Sem nenhum** registro de consumo anterior |
| **IMV-17** | **Rota alternativa** definida |
| **IMV-18** | Período de leitura atravessando **mudança de vigência** tarifária |
| **IMV-19** 🆕 | Residencial com família **elegível à Tarifa Social nacional** (CadÚnico com renda per capita até ½ salário mínimo, ou BPC) — consumos abaixo e acima do limite de volume; identificadores externos **pseudonimizados** |

Complementos por combinação, sem perfil próprio: as situações de água e esgoto em todas as combinações parametrizadas (CEN-CAD-004), inclusive o **valor 4**; imóveis com override de mínimo na ligação, na situação e por área (CEN-MIC-002).

### 13.2 Documentos financeiros

| Perfil | Características |
| ------ | --------------- |
| **DOC-01** | Conta vigente, não vencida |
| **DOC-01P** | Conta emitida e **paga** |
| **DOC-02** | Conta **vencida**, elegível a ação |
| **DOC-03** | Conta A **retificada** por B |
| **DOC-04** / **DOC-05** | Conta **cancelada** / **prescrita** |
| **DOC-06** | Conta **arquivada** |
| **DOC-10** | Parcelamento com entrada paga e prestações em contas futuras, parte delas paga |
| **DOC-11** | Parcelamento com **entrada vencida e não paga** |
| **DOC-12** 🆕 | **Fatura do cliente responsável** agregando contas de pelo menos dois imóveis numa referência |

Além deles, por cenário: conta em revisão, guia não quitada, débito a cobrar de serviço em N parcelas, crédito a realizar, documento de cobrança com itens.

### 13.3 Movimentos de arrecadação

Arquivo coerente e variantes: total de trailer divergente, registro malformado, reenvio com o mesmo NSA. Pagamentos: integral no prazo · em atraso · a menor · a maior · duplicado · sem documento · contra conta cancelada, prescrita, parcelada, retificada e arquivada · de guia de entrada · de conta com prestação · associado a documento de cobrança. Aviso bancário com calculado ≠ informado. Retorno de débito automático aceito e rejeitado.

### 13.4 Usuários e organização

| Perfil | Características |
| ------ | --------------- |
| **USR-01** / **USR-01B** | Ativo, grupo A — os dois com **a mesma senha** (D-01) |
| **USR-02** | Grupos A **e** B |
| **USR-03** | Sem as concessões do cenário |
| **USR-04** / **USR-05** | Inativo / pendente de senha |
| **USR-06A** / **USR-06B** | Acesso expirado / a expirar |
| **USR-07** | Com histórico de senhas |
| **USR-08** | Abrangência restrita — uma variação por nível |
| **USR-09** | Com permissão especial |
| **USR-10** | Em outra unidade organizacional |
| **USR-11** | Usuário técnico de processamento |
| **UNI-01** / **UNI-02** | Unidades organizacionais para tramitação |

Território: duas gerências regionais, unidades de negócio, elos/polos, localidades L1 e L2, setores, quadras e rotas R1–R3 no grupo G1.

### 13.5 Parametrização

| Perfil | Características |
| ------ | --------------- |
| **TAR-01** | Tarifa com **duas vigências** e faixas por categoria |
| **ESP-01** | Especificação **sem** geração de OS, encerramento manual |
| **ESP-02** | Especificação que **gera OS** automaticamente |
| **ESP-03** | Especificação com **encerramento automático** |
| **ESP-04** | Especificação que admite RA **sem imóvel** |
| **SRV-01** / **SRV-02** / **SRV-03** | Serviço cobrado em N parcelas / não cobrado / com valor alterável |
| **ESP-05** 🆕 | Especificação de tipo de solicitação **relativo a esgoto** (exige divisão de esgoto no local de ocorrência) |
| **ESP-06** 🆕 | Especificação de **falta de água** |
| **CTB-01** 🆕 | Parametrização contábil das origens faturamento, arrecadação (dois tipos de recebimento) e avisos bancários, sobre plano de contas **sintético** |
| **CTB-02** 🆕 | Critérios de devedores duvidosos por situação de cobrança — valor-limite × número de meses |
| **OPR-01** 🆕 | Estrutura operacional mínima em L1: distritos D1 e D2, bacia, divisões DV1 e DV2 com **unidades distintas**, cadeia distrito → setor → sistema de abastecimento; uma quadra com **faces em distritos diferentes** |
| **OPR-02** 🆕 | Programação de abastecimento e de manutenção para uma área de bairro, em dias distintos |
| **QLD-01** 🆕 | Registros de qualidade da água na mesma competência em **quatro níveis**: sistema de abastecimento, localidade + setor, localidade, geral |

Mais: sequência de ações de cobrança (aviso → corte) com critérios; perfil de parcelamento com faixas, juros, entrada mínima e descontos; comando de negativação; processo com indicador de autorização.

### 13.6 Uso dos perfis pelos cenários

⚠️ **Gerado por script** a partir das especificações.

| Perfil | Cenários |
| ------ | -------- |
| IMV-01 | CEN-ARR-009 · CEN-ARR-013 · CEN-ATE-001 · CEN-ATE-002 · CEN-ATE-007 · CEN-CAD-002 · CEN-CAD-003 · CEN-CAD-005 · CEN-COB-001 · CEN-COB-002 · CEN-COB-003 · CEN-COB-004 · CEN-COB-006 · CEN-COB-007 · CEN-FAT-001 · CEN-FAT-003 · CEN-FAT-004 · CEN-FAT-007 · CEN-FAT-009 · CEN-FAT-010 · CEN-FIN-004 · CEN-MIC-001 · CEN-MIC-005 · CEN-OPE-003 |
| IMV-02 | CEN-CAD-003 · CEN-FAT-001 · CEN-FAT-009 |
| IMV-03 | CEN-ATE-001 · CEN-CAD-003 · CEN-FAT-001 · CEN-FIN-004 · CEN-MIC-002 |
| IMV-04 | CEN-MIC-002 |
| IMV-05 | CEN-MIC-001 |
| IMV-06 | CEN-MIC-001 |
| IMV-07 | CEN-MIC-001 |
| IMV-08 | CEN-MIC-003 |
| IMV-09 | CEN-MIC-004 |
| IMV-10 | CEN-MIC-004 |
| IMV-11a | CEN-FAT-003 |
| IMV-11b | CEN-FAT-003 |
| IMV-12a | CEN-FAT-001 · CEN-MIC-001 |
| IMV-12b | CEN-FAT-001 |
| IMV-13 | CEN-FAT-006 |
| IMV-14 | CEN-FAT-005 |
| IMV-15 | CEN-ATE-007 |
| IMV-16 | CEN-FAT-011 |
| IMV-17 | CEN-CAD-005 |
| IMV-18 | CEN-FAT-002 |
| IMV-19 | CEN-FAT-012 |
| DOC-01 | CEN-ARR-002 · CEN-ARR-004 · CEN-ARR-006 · CEN-ARR-012 · CEN-FAT-007 · CEN-FIS-001 |
| DOC-01P | CEN-FAT-007 |
| DOC-02 | CEN-FAT-008 · CEN-FIN-002 |
| DOC-03 | CEN-ARR-005 · CEN-FIS-003 |
| DOC-04 | CEN-ARR-003 · CEN-FIS-003 |
| DOC-05 | CEN-ARR-003 |
| DOC-06 | CEN-ARR-005 |
| DOC-10 | CEN-ARR-008 · CEN-COB-005 |
| DOC-11 | CEN-COB-005 |
| DOC-12 | CEN-ARR-011 |
| USR-01 | CEN-ATE-001 · CEN-ATE-002 · CEN-ATE-004 · CEN-BAT-001 · CEN-REL-001 · CEN-SEG-001 · CEN-SEG-002 · CEN-SEG-004 · CEN-SEG-006 · CEN-SEG-008 · CEN-SEG-009 · CEN-SEG-012 |
| USR-01B | CEN-SEG-001 |
| USR-02 | CEN-SEG-004 |
| USR-03 | CEN-REL-001 · CEN-SEG-004 · CEN-SEG-005 |
| USR-04 | CEN-SEG-003 |
| USR-05 | CEN-SEG-003 |
| USR-06A | CEN-SEG-003 |
| USR-06B | CEN-SEG-003 |
| USR-07 | CEN-SEG-003 |
| USR-08 | CEN-SEG-007 |
| USR-09 | CEN-SEG-008 |
| USR-10 | CEN-ATE-004 |
| USR-11 | CEN-BAT-001 |
| UNI-01 | CEN-ATE-004 |
| UNI-02 | CEN-ATE-004 |
| TAR-01 | CEN-FAT-001 · CEN-FAT-002 |
| ESP-01 | CEN-ATE-002 · CEN-ATE-003 |
| ESP-02 | CEN-ATE-002 · CEN-OPE-001 |
| ESP-03 | CEN-ATE-003 |
| ESP-04 | CEN-ATE-002 |
| ESP-05 | CEN-OPE-001 |
| ESP-06 | CEN-OPE-002 |
| SRV-01 | CEN-ATE-006 · CEN-ATE-008 |
| SRV-02 | CEN-ATE-008 |
| SRV-03 | CEN-ATE-008 |
| CTB-01 | CEN-FIN-001 · CEN-FIN-004 |
| CTB-02 | CEN-FIN-002 |
| OPR-01 | CEN-OPE-001 · CEN-OPE-003 |
| OPR-02 | CEN-OPE-002 |
| QLD-01 | CEN-OPE-003 |

### 13.7 Contra a explosão combinatória

🔴 Não se testa `categoria × situação × tipo × estado × companhia`. Escolheram-se **casos base e casos de fronteira**; o que for parametrização pura vira **teste parametrizado** na Fase 2, sobre os mesmos perfis.

---

## 14. ADR-0007 — decidida em 2026-09-29

As especificações são **neutras à interface**: nenhuma descreve tela, rota ou recurso REST. ✅ **Verificado depois da decisão** ([ADR-0007 §15](../decisoes/0007-arquitetura-de-interface.md)): ela **não acrescenta observável de equivalência** — nenhuma especificação foi reescrita.

| O que dependia da ADR-0007 | Como ficou |
| -------------------------- | ---------- |
| A **superfície** pela qual a fatia vertical (CEN-SEG-004, CAD-001/002, ATE-001 a 004) será exercida | **Backoffice server-driven com aprimoramento progressivo**; os observáveis não mudam |
| A **unidade de autorização** em CEN-SEG-004 | **Caso de uso**, para todo canal — já era comparada pela funcionalidade, não pelo caminho |
| A **forma de entrega** do artefato em CEN-REL-001 | **Caso de uso de obtenção do artefato** com verificação de usuário, propriedade e escopo — V2 e V3 continuam negadas (D-03) |
| O canal digital (Etapa 8) | **Canal próprio**; nenhum cenário especificado — continua sem baseline a comparar |

🆕 **Sessão, cookie e CSRF — corrigido na auditoria final (2026-09-29)**. Esta seção dizia que eram controles *sem antecedente no GSAN*, só testes da fundação. ⚠️ **Não é assim**: o legado **tem** sessão e cookie — sem `HttpOnly`/`Secure`/`SameSite` e sem token de formulário —, e aceitar requisição forjada é comportamento observável. A diferença virou a divergência **[D-18](../compatibilidade/divergencias-aprovadas.md)** e o cenário **CEN-SEG-012** (oráculo 2). Fixação de sessão, expiração e invalidação no logout continuam **testes próprios da fundação (S1)**.

---

## 15. O que a Fase 2 recebe

1. **87 especificações fechadas** (🆕 79 até a auditoria final), cada uma com a lista de observáveis, o oráculo e o gate — ⚠️ **81 com baseline a capturar ou já comprovada**; as **6** de requisito nativo não têm baseline do legado e são testadas contra a norma.
2. Os **perfis de massa** e o mapa perfil → cenário.
3. A lista do que **não** comparar (C4) e do que está **bloqueado** — 🆕 **BLQ-01 e BLQ-03**, ambos pela D-17; BLQ-02 e BLQ-04 foram desbloqueados na auditoria final.
4. Seis casos — três cenários e três variações (🆕 CEN-SEG-004 V7(c)) — cuja decisão de oráculo **depende da própria baseline** (§10.2).
5. 🔴 A **ordem de captura** continua a de [`estrategia-testes.md`](estrategia-testes.md) — autenticação, conta individual, baixa, parcelamento, consumo, OS, resumos.

⚠️ **O que a Fase 2 precisa fixar antes de capturar**, porque a baseline depende disso: a **variante de companhia** ativa na instância de referência; o **limite de tentativas** e os parâmetros da política de senha; os **parâmetros de faixa** das tarifas; se a **taxa de emissão** está ativa.

---

## 16. Rastreabilidade do inventário

⚠️ **Gerada por script.** Cada item de cada mapa, com seu destino.

**Micromedição** (12)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Leitura normal | CEN-MIC-001 |
| 2 | Leitura não realizada e reincidência | CEN-MIC-001 |
| 3 | Faturamento por média, inclusive histórico insuficiente | CEN-MIC-001 |
| 4 | Troca de hidrômetro na referência | CEN-MIC-003 |
| 5 | Virada de hidrômetro | CEN-MIC-004 |
| 6 | Alto/baixo consumo e estouro por limiares | CEN-MIC-004 |
| 7 | Imóvel sem hidrômetro — mínimo e precedência | CEN-MIC-002 |
| 8 | Primeira leitura após instalação | CEN-MIC-001 |
| 9 | Rota alternativa definida × não definida | CEN-CAD-005 |
| 10 | Condomínio com rateio | CEN-FAT-006 |
| 11 | Leitura alterada/confirmada em análise | CEN-MIC-005 |
| 12 | Poço compondo esgoto | CEN-FAT-003 |

**Faturamento** (13)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Residencial simples, 1 economia | CEN-FAT-001 |
| 2 | Múltiplas economias | CEN-FAT-001 |
| 3 | Múltiplas categorias | CEN-FAT-001 |
| 4 | Conta por média e por taxa mínima | CEN-FAT-001 |
| 5 | Mínimo com override × mínimo tarifário | CEN-MIC-002 |
| 6 | Esgoto: padrão, alternativo, poço | CEN-FAT-003 |
| 7 | Débitos cobrados e créditos realizados | CEN-FAT-004 |
| 8 | Impostos deduzidos | CEN-FAT-005 |
| 9 | Retificação | CEN-FAT-007 |
| 10 | Cancelamento e prescrição | CEN-FAT-008 |
| 11 | Pré-faturada → consolidada | CEN-FAT-009 |
| 12 | Vencimento | CEN-FAT-009 |
| 13 | Virada de referência contábil | CEN-FAT-010 |

**Cobrança** (14)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Cobrança simples até aviso de corte | CEN-COB-002 |
| 2 | Pagamento antes da ação | CEN-COB-002 |
| 3 | Pagamento após emissão do documento | CEN-COB-002 |
| 4 | Sequência aviso → corte | CEN-COB-003 |
| 5 | Parcelamento com entrada e descontos | CEN-COB-004 |
| 6 | Entrada não paga → desfazimento automático | CEN-COB-005 |
| 7 | Desfazimento manual | CEN-COB-005 |
| 8 | Reparcelamento | CEN-COB-005 |
| 9 | Corte → pagamento → religação | CEN-COB-003 |
| 10 | Negativação e exclusão | CEN-COB-006 |
| 11 | Retificação de conta em cobrança | CEN-COB-007 |
| 12 | Cancelamento/prescrição de conta em cobrança | CEN-COB-007 |
| 13 | Conta em revisão | CEN-COB-001 |
| 14 | Cobrança terceirizada | P2 — inventário |

**Arrecadação** (20)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Conta paga integralmente | CEN-ARR-002 |
| 2 | Pagamento em atraso com acréscimos | CEN-ARR-002 |
| 3 | Valor divergente | CEN-ARR-002 |
| 4 | Pagamento maior que o devido | CEN-ARR-002 |
| 5 | Duplicidade → devolução | CEN-ARR-004 |
| 6 | Sem documento → reclassificação | CEN-ARR-003 |
| 7 | Conta retificada antes/depois do pagamento | CEN-ARR-005 |
| 8 | Conta arquivada | CEN-ARR-005 |
| 9 | Conta cancelada/prescrita | CEN-ARR-003 |
| 10 | Conta em parcelamento | CEN-ARR-003 |
| 11 | Entrada de parcelamento paga / não paga | CEN-ARR-008 · CEN-COB-005 |
| 12 | Prestação paga na conta | CEN-ARR-008 |
| 13 | Pagamento de documento de cobrança | CEN-COB-002 |
| 14 | Pagamento após aviso/corte | CEN-COB-003 |
| 15 | Devolução com guia | CEN-ARR-004 |
| 16 | Débito automático | CEN-ARR-009 |
| 17 | Arquivo × aviso bancário | CEN-ARR-007 |
| 18 | Referência contábil aberta | CEN-ARR-003 |
| 19 | Encerramento mensal | CEN-ARR-010 |
| 20 | Carteira terceirizada | P2 — inventário |

**Atendimento** (22)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | RA encerrado sem OS | CEN-ATE-003 |
| 2 | Encerramento automático | CEN-ATE-003 |
| 3 | RA que gera OS | CEN-ATE-002 |
| 4 | Tramitação entre unidades | CEN-ATE-004 |
| 5 | Espera e prazo | CEN-ATE-005 |
| 6 | Reiteração | CEN-ATE-005 |
| 7 | Duplicidade por bairro-área | P2 — inventário |
| 8 | Reativação | P2 — inventário |
| 9 | Ocorrência em via pública | CEN-ATE-002 |
| 10 | Ciclo da OS até executada | CEN-ATE-006 |
| 11 | OS encerrada não executada | CEN-ATE-006 |
| 12 | OS de corte da Cobrança | CEN-COB-003 |
| 13 | OS de religação | CEN-ATE-007 |
| 14 | OS de hidrômetro | CEN-MIC-003 |
| 15 | OS de ligação | CEN-ATE-007 |
| 16 | Serviço cobrado × não cobrado | CEN-ATE-008 |
| 17 | Alteração do valor do serviço | CEN-ATE-008 |
| 18 | RA de pagamento em duplicidade | CEN-ARR-004 |
| 19 | RA que dispara retificação | CEN-FAT-007 |
| 20 | RA que altera vencimento | CEN-FAT-009 |
| 21 | OS referenciada | P2 — inventário |
| 22 | Encerramento em massa de OS | P2 — inventário |

**Segurança** (24)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Login válido | CEN-SEG-001 |
| 2 | Senha inválida | CEN-SEG-002 |
| 3 | Tentativas excedidas | CEN-SEG-002 |
| 4 | Usuário inativo | CEN-SEG-003 |
| 5 | Pendente de senha | CEN-SEG-003 |
| 6 | Acesso expirado | CEN-SEG-003 |
| 7 | Troca e histórico de senha | CEN-SEG-003 |
| 8 | Senha proibida | CEN-SEG-003 |
| 9 | Funcionalidade concedida | CEN-SEG-004 |
| 10 | União de grupos | CEN-SEG-004 |
| 11 | Funcionalidade dependente | CEN-SEG-004 |
| 12 | URL direta: protegida × excepcionada | CEN-SEG-004 · CEN-SEG-005 |
| 13 | Operação sem concessão | CEN-SEG-004 |
| 14 | Fora da abrangência | CEN-SEG-007 |
| 15 | Cada nível de abrangência | CEN-SEG-007 |
| 16 | Consulta sem verificação de abrangência | BLQ-01 |
| 17 | Permissão especial | CEN-SEG-008 |
| 18 | Outra unidade tramitando RA | CEN-ATE-004 |
| 19 | Restrição de grupo (deny) | CEN-SEG-004 |
| 20 | Operação efetuada | CEN-SEG-006 |
| 21 | Trilha por linha/coluna | CEN-SEG-006 |
| 22 | Autor USUARIO_BATCH | CEN-BAT-001 |
| 23 | API/servlet fora de *.do | CEN-SEG-009 · CEN-INT-003 · CEN-INT-005 |
| 24 | Solicitação de acesso | P2 — inventário |

**Batch** (20)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Disparo manual | CEN-BAT-001 |
| 2 | Autorização de processo | CEN-BAT-001 |
| 3 | Disparo agendado (Quartz) | C4 |
| 4 | Ordem das etapas | CEN-BAT-001 |
| 5 | Resolução de unidades | CEN-BAT-001 |
| 6 | Consolidação | CEN-BAT-001 |
| 7 | Uma unidade falha | CEN-BAT-002 |
| 8 | Processo concluído com erro | CEN-BAT-002 |
| 9 | Reprocessamento | CEN-BAT-002 |
| 10 | Reexecução de unidade concluída | CEN-BAT-002 |
| 11 | Falha no meio da unidade | CEN-BAT-003 |
| 12 | Duas execuções iguais | CEN-BAT-004 |
| 13 | Paralelismo pelo pool de MDB | C4 |
| 14 | Processo por referência e grupo | CEN-BAT-001 |
| 15 | Disparo fora da abrangência | BLQ-03 |
| 16 | Rastreabilidade | CEN-BAT-001 |
| 17 | FATURAR_GRUPO completo | CEN-BAT-005 |
| 18 | FATURAR_GRUPO com falha em rota | CEN-BAT-002 |
| 19 | ENCERRAR_ARRECADACAO_MES | CEN-ARR-010 |
| 20 | Relatório pelo framework | CEN-BAT-001 |

**Relatórios** (19)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Abaixo do limite → online | P2 — inventário |
| 2 | Acima do limite → lote | P2 — inventário |
| 3 | Sem chave → lote | P2 — inventário |
| 4 | Lote sem aprovação | P2 — inventário |
| 5 | Lote com aprovação | P2 — inventário |
| 6 | PDF online | P2 — inventário |
| 7 | XLS online | P2 — inventário |
| 8 | Relatório vazio | P2 — inventário |
| 9 | Erro online | P2 — inventário |
| 10 | Lote com artefato persistido | CEN-REL-001 |
| 11 | Erro em lote | P2 — inventário |
| 12 | Status por usuário | CEN-REL-001 |
| 13 | Download pelo solicitante | CEN-REL-001 |
| 14 | Download por outro usuário | CEN-REL-001 |
| 15 | Parâmetros preservados | P2 — inventário |
| 16 | Contagem × volume | P2 — inventário |
| 17 | Relatório agendado | P2 — inventário |
| 18 | Template e subrelatório | C4 |
| 19 | Serviço externo | P2 — inventário |

**Integrações** (22)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Baixar arquivo de rota | CEN-INT-001 |
| 2 | Enviar movimento | CEN-INT-001 |
| 3 | Finalizar leitura | CEN-INT-001 |
| 4 | Confirmação com variante de empresa | A COMPLEMENTAR |
| 5 | Teste de conexão | P2 — inventário |
| 6 | Telemetria bem formada | CEN-INT-002 |
| 7 | Telemetria malformada | CEN-INT-002 |
| 8 | GIS assinatura válida | CEN-INT-007 |
| 9 | GIS assinatura inválida | CEN-INT-007 |
| 10 | GIS usuário inexistente | CEN-INT-007 |
| 11 | UPA exportação | CEN-INT-004 |
| 12 | UPA registro já existente | CEN-INT-004 |
| 13 | UPA login válido | CEN-INT-004 |
| 14 | UPA login inválido | CEN-INT-004 |
| 15 | UPA empresa sem e-mail | CEN-INT-004 |
| 16 | API de pagamento por host | CEN-INT-005 |
| 17 | API de OS sem credencial | CEN-INT-003 |
| 18 | API de OS concorrente | CEN-INT-003 |
| 19 | E-mail com anexo e falha SMTP | P2 — inventário |
| 20 | SMS por tipo | CEN-INT-006 |
| 21 | Consulta SPC | CEN-COB-006 |
| 22 | Integração contábil padrão × variante | CEN-FIN-005 |

**Financeiro/Contabilização 🆕** (11)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Lançamentos do faturamento a partir do resumo | CEN-FIN-001 |
| 2 | Lançamentos da arrecadação com tipo de recebimento | CEN-FIN-001 |
| 3 | Lançamentos dos avisos bancários | CEN-FIN-001 |
| 4 | Lançamentos dos devedores duvidosos | CEN-FIN-002 |
| 5 | Seleção e marcação por critério, com resumo | CEN-FIN-002 |
| 6 | Pagamento de conta baixada — recuperação | CEN-FIN-002 |
| 7 | Remoção e regeração por competência, localidade e origem | CEN-FIN-003 |
| 8 | Contas a receber contábil e documentos a receber por faixa | P2 — inventário |
| 9 | Volumes consumidos e não faturados | CEN-FIN-004 |
| 10 | Exportação — formato base e variante | CEN-FIN-005 |
| 11 | Resumo de receita por banco e arrecadador | P2 — inventário |

**Operacional 🆕** (7)

| # | Item inventariado | Destino |
| - | ----------------- | ------- |
| 1 | Distrito pela quadra ou pela face na programação de OS | CEN-OPE-001 |
| 2 | Divisão de esgoto define o destino do RA | CEN-OPE-001 |
| 3 | Falta de água × programação | CEN-OPE-002 |
| 4 | Qualidade da água na emissão — cascata | CEN-OPE-003 |
| 5 | Divisão de esgoto do imóvel pela quadra | CEN-OPE-001 |
| 6 | Manutenção da programação com concorrência | P2 — inventário |
| 7 | Fontes por setor comercial ao informar a qualidade | P2 — inventário |

---

## 17. Pendências que esta especificação expõe

| # | Pendência | Afeta |
| - | --------- | ----- |
| 1 | 🔴 **Varredura das políticas de arredondamento nos controladores da Cobrança e da Arrecadação** | Baselines de parcelamento e acréscimos |
| 2 | 🔴 **Ajustar o registro para o contador de tentativas** (CAND-03) — ampliar D-01 ou criar divergência | CEN-SEG-002 V3 |
| 3 | **Confirmar a leitura de D-15**: divergência de configurabilidade, **valor padrão 20 preservado** | CEN-FAT-011 |
| 4 | **Inventário das variantes por companhia** | §10.3 |
| 5 | Decisão de BLQ-01 e BLQ-03 (aprovação de D-17) — 🆕 BLQ-02 e BLQ-04 resolvidos na auditoria final | §10.1 |
| 6 | Origem dos dados dos resumos financeiros (pré-calculado × consulta) | CEN-REL-002 |
| 7 🆕 | "Dívida ativa" e "baixa contábil" são o mesmo conceito? — hoje, o mesmo campo | CEN-FIN-002 · Cobrança |
| 8 🆕 | Quem produz a estimativa de consumo não faturado | CEN-FIN-004 |
| 9 🆕 | Chave de área da programação (bairro × unidade operacional) no OpenGSAN | CEN-OPE-002 |
| 10 🆕 | Regra fiscal da retificação, do cancelamento e da contingência em campo — `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` | CEN-FIS-002 · CEN-FIS-003 |
| 11 🆕 | Permanência/transição na perda da Tarifa Social e prazos de comunicação — regra do regulador | CEN-FAT-012 V4 |
| 12 🆕 | Tratamento de conta alterada depois do agendamento do Pix Automático — decisão de produto | CEN-ARR-013 V4 |

---

## 18. Próxima atividade

Restam para fechar a Fase 0:

1. ~~**ADR-0007 — arquitetura de interface.**~~ ✅ **Aceita em 2026-09-29** — sem efeito sobre os observáveis (§14).
2. ~~**Auditoria final e encerramento da Fase 0.**~~ ✅ **Concluída em 2026-09-29** — [`auditoria-final-fase0.md`](../auditoria/auditoria-final-fase0.md): oito especificações acrescentadas (§4.3), dois bloqueios resolvidos (§10.1), a D-18 com cenário e o oráculo N para requisitos nativos.
