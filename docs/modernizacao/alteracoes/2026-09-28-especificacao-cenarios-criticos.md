# [2026-09-28] Especificação dos cenários críticos

- **Motivo**: os mapas funcionais tinham um **inventário** de cenários; a Fase 0 exige **especificações** capazes de orientar massa, execução no legado, golden masters e testes de equivalência. A pergunta a responder: *se amanhã formos construir o harness, sabemos o que exercitar e como decidir se o OpenGSAN está correto?*
- **Método**: verificação de continuidade; correção da estratégia de testes **antes** de especificar; contagem do inventário por script; deduplicação por operação e observáveis; leitura dirigida de código **apenas** onde uma especificação crítica não fechava pela documentação; matriz, distribuições e rastreabilidade **geradas por script** a partir das especificações.
- **Testes**: nenhum executado — ⚠️ esta atividade **especifica**, não executa. **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## 0. Verificação de continuidade

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `821fda7` — compatibilidade conceitual; local = remoto; árvore limpa |
| Commits posteriores | Nenhum |
| Documento consolidado de cenários | **Não existia** — só `testes/estrategia-testes.md` |
| Atividade realmente pendente | **Especificação dos cenários críticos** — item 1 do backlog |

## 1. Primeiro: a contradição da estratégia de testes

🔴 A estratégia exigia, ao mesmo tempo: que os cenários fossem **especificados na Fase 0**; que `Resultado esperado` separasse cenário de especificação; que um resultado 🟡 "a capturar" significasse **cenário não especificado**; e que a captura ocorresse **na Fase 2**. Juntas, formavam um ciclo sem saída:

```text
Fase 0 exige resultado capturado → a captura é da Fase 2 → a Fase 2 depende da Fase 0
```

⚠️ A regra que fechava o ciclo — *"enquanto estiver 🟡, o cenário não está especificado"* — foi escrita na rodada de correções de 2026-09-14. **Causa**: confundia *saber o que observar e como decidir* com *saber o valor observado*.

**Correção**: dois campos distintos — **resultado semântico esperado** (regra comprovada, Fase 0) e **baseline concreta do legado** (valor observado, Fase 2). Um cenário está especificado quando operação, estado, entrada, observáveis, semântica, normalizações, divergência permitida e oráculo estão fechados. 🔴 `JÁ COMPROVADA` só vale quando **o próprio observável é um artefato estático**; para comportamento em execução, leitura de código **nunca** conta como baseline.

Correções residuais no mesmo documento: "GSAN NOVO" → OpenGSAN; "pré-requisito da Fase 5" → fundação de segurança (S1); "antes de migrar qualquer módulo" → antes de substituir qualquer comportamento; e a prioridade 7 da baseline (ver §3).

## 2. O inventário tinha 166 itens, não "~110"

A cifra circulava em **seis** documentos — inclusive no roteiro desta execução — e **nunca foi contada**. Contagem por script sobre as seções de cenários: micromedição 12 · faturamento 13 · cobrança 14 · arrecadação 20 · atendimento 22 · segurança 24 · batch 20 · relatórios 19 · integrações 22. ⚠️ **O mapa do Cadastro não tem seção de cenários** — os cinco cenários de Cadastro foram derivados das regras do mapa.

Corrigida nos documentos em que circulava e registrada em [`procedencia.md §4`](../procedencia.md).

## 3. Os resumos `sp*_gerar_res_*` não são baseline do núcleo

A estratégia os citava como prioridade 7 da baseline. O inventário do banco os classifica como **customização permanente da instalação de referência**. Substituídos pelos relatórios do **código público** — `RelatorioResumoFaturamento` e `RelatorioResumoArrecadacao`, localizados nesta execução.

## 4. O que foi produzido

- [`testes/cenarios-criticos.md`](../testes/cenarios-criticos.md) — índice, matriz mestre, distribuições, cobertura de arredondamento, gates, bloqueados, candidatos, perfis de massa, rastreabilidade.
- [`testes/cenarios/`](../testes/cenarios/) — **71 especificações** em sete arquivos, todas com os **17 campos obrigatórios** (verificado por script).

| Destino dos 166 itens | Itens |
| --------------------- | ----: |
| Absorvidos em 59 especificações | 135 |
| Bloqueados por decisão | 3 |
| Sem equivalência (C4) | 3 |
| A complementar — variante por companhia | 2 |
| P2 — mantidos no inventário | 23 |

Mais **12 especificações derivadas**, sem origem no inventário: fatia vertical (consulta de imóvel), regras do Cadastro, divergências sem cenário (D-07, D-08, D-15, D-16), identidade do pagamento, recepção do movimento, resumos financeiros — e o cálculo proporcional entre vigências (§5).

| Distribuição | |
| ------------ | - |
| Criticidade | **43 P0** · 28 P1 |
| Oráculo | **54** oráculo 1 · **8** por observável (1+2) · **6** oráculo 2 · **3** pendentes de caracterização |
| Baseline | **70** a capturar na Fase 2 · **1** já comprovada (artefato estático) |
| Etapa | 0: 7 · 1: 8 · 2: 9 · 3: 9 · **4: 12** · 5: 9 · 6: 9 · 7: 7 · 8: 1 |

🔵 A faixa sugerida de 35–60 foi calibrada para ~110 itens; com 166, a mesma proporção daria 53–91. O resultado fica dentro dela — e **não foi forçado**.

## 5. O que a leitura dirigida de código revelou

A estratégia exige cobrir **cada** uma das cinco políticas de arredondamento com um cenário que **realmente a execute**. A documentação só trazia contagens. A localização método a método em `ControladorFaturamentoFINAL.java` — ⚠️ **uma classe**, escopo declarado — mostrou:

| Achado | Consequência |
| ------ | ------------ |
| 🔴 **9 dos 27 HALF_UP** estão em `calculoProporcionalMaisDeUmaTarifa` — o cálculo quando **a tarifa muda dentro do período de leitura** | **Cenário P0 ausente de todo o inventário** → CEN-FAT-002 |
| **UP** está sobretudo na **emissão** (linhas tarifárias impressas, 2ª via, ficha de compensação) | O documento emitido é observável financeiro → CEN-FAT-009 |
| **Impostos usam três políticas num único cálculo** (DOWN, HALF_DOWN, HALF_UP) | CEN-FAT-005 |
| **FLOOR** só no rateio de micro-condomínio, precedido de acréscimo construído a partir de `double` — e **alcançável** por caminhos ativos do `gerarConta` | Nenhum efeito sobre os centavos é presumido → CEN-FAT-006 |
| A taxa de emissão de conta usa HALF_UP e **não aparecia em nenhum cenário** | Variação condicional em CEN-FAT-004 |
| Crédito de programa social nomeado e consumo médio diário só em controladores de companhia | `A COMPLEMENTAR` |

🟢 **As cinco políticas têm cenário.** Das 57 ocorrências, 54 estão em caminhos cobertos; 3 em caminhos de companhia. ⚠️ **Cobrança e Arrecadação não foram varridas** — pendência registrada, pré-requisito da captura das baselines de parcelamento e acréscimos.

## 6. Refinamento: nem todo C5 bloqueia cenário

A compatibilidade conceitual afirmava que *todo* conceito C5 "não tem cenário especificável". Ao especificar, isso se mostrou forte demais. **Só três dos sete bloqueiam** — os de **comportamento** (Fatura, mecanismo de negação, D-17). Os de **representação** são especificáveis quando o oráculo já está fixado por outra regra: as fórmulas de acréscimo, por exemplo, têm representação pendente, mas **resultado financeiro — oráculo 1** pela regra explícita do registro de divergências. Bloqueá-las impediria caracterizar um cálculo P0 sem motivo.

Corrigido em [`gsan-opengsan.md`](../compatibilidade/gsan-opengsan.md) §4.3, §5.1, §22, §23 e §26 — ⚠️ onde a §26 ainda dizia "**nove** conceitos C5", resíduo da correção para sete feita na execução anterior.

## 7. Dois candidatos a divergência novos — não aprovados

| # | Conceito | Situação |
| - | -------- | -------- |
| **CAND-03** | Contador de tentativas de login | 🟢 Vive na **sessão HTTP**. A visão conceitual o atribui a D-01, mas ⚠️ **o texto de D-01 cobre apenas o hash** — **lacuna de registro** |
| **CAND-04** | Exceção de autorização por substring `pesquisar`/`relatorio` | Qualquer Action cujo nome contenha os termos sai do bloco de autorização do filtro; para `pesquisar`, depende de cada Action — condicional à caracterização |

Registrados em [`gsan-opengsan.md §20.3`](../compatibilidade/gsan-opengsan.md). Nenhum vira oráculo 2 antes de aprovado.

## 8. Uma leitura de D-15 que precisa ser confirmada

D-15 torna configurável o consumo de reserva de 20 fixo em código. 🔴 Para ser compatível com a regra de que **nenhuma divergência atinge cálculo financeiro**, a única leitura possível é: divergência de **configurabilidade**, com **valor padrão 20 preservado**. Registrado em CEN-FAT-011 para confirmação na aprovação de D-15.

## 9. O que ficou deliberadamente de fora

🔴 Nenhum teste executado · nenhum golden master capturado · nenhuma massa criada · nenhum *harness* · nenhum JBoss · nenhum localizador físico do OpenGSAN · nenhuma baseline deduzida de código · nenhuma divergência aprovada · ADR-0007 não decidida · ordem de implementação não reaberta · nenhuma das 64 estruturas reclassificada.

## 10. Impacto

- **Criados**: `testes/cenarios-criticos.md`; `testes/cenarios/` (7 arquivos).
- **Corrigidos**: `testes/estrategia-testes.md` (dependência circular, prioridade 7, terminologia); `compatibilidade/gsan-opengsan.md` (regra do C5, candidatos, "~110", "nove"); `dominio/mapa-de-dominio.md` e `modulos/dependencias-e-ordem-implementacao.md` ("~110").
- **Atualizados**: `MODERNIZACAO_GSAN.md`, `docs/modernizacao/README.md`, `procedencia.md` (quatro correções de fato publicado), `alteracoes/README.md`.
- **Nenhuma alteração de código, banco ou infraestrutura.**

## 11. Próxima atividade

**Decisão da ADR-0007 — arquitetura de interface**, com o escopo do que ela afeta nos cenários já delimitado ([`cenarios-criticos.md §14`](../testes/cenarios-criticos.md)). Depois: **auditoria final e encerramento da Fase 0**.
