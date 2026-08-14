# [2026-08-14] Ajustes pontuais pós-revisão do mapa de Faturamento

- **Motivo**: revisão do [mapa funcional do Faturamento](../modulos/faturamento.md) confirmou a análise como majoritariamente correta, mas identificou **três formulações mais fortes do que as evidências sustentam**. Correção pontual — **nenhuma reanálise foi realizada** e nenhum documento foi recriado.

## O que foi corrigido

| # | Formulação anterior | Correção aplicada | Onde |
| - | ------------------- | ----------------- | ---- |
| 1 | "identidade estável que **sobrevive ao arquivamento e à retificação**" | `ContaGeral` preserva a identidade **de uma determinada Conta na passagem entre representação corrente e histórica** (mesmo `cnta_id`). A **retificação cria nova Conta com nova identidade**, ligada à anterior por `origem`. O conceito a preservar no SISAN é o trio **identidade estável do documento + versionamento corrente/histórico + linhagem entre retificações** | `faturamento.md` §13, §24, §29; propagação corrigida em `cobranca.md` §4, §29, §30 e `arrecadacao.md` §4; `glossario.md` (Conta e ponto 4) |
| 2 | "mudanças tarifárias **nunca** reprocessam o passado" | A estrutura tarifária é versionada por vigência e a Conta **preserva os principais parâmetros do cálculo**, mantendo o contexto histórico das contas emitidas mesmo após alterações tarifárias; reprocessamentos deliberados (retificação/revisão) seguem seus próprios fluxos | `faturamento.md` §8, §28 |
| 3 | "o eixo cadastro → medição → conta está **compreendido de ponta a ponta**" | O fluxo principal Cadastro → Micromedição → Faturamento → Conta → Cobrança → Arrecadação está **funcionalmente mapeado**, permanecendo regras de exceção, precedências específicas e variações por companhia para aprofundamento | `MODERNIZACAO_GSAN.md` (status geral) |
| 3b | "consumo **nunca** é regravado pelo Faturamento" | **No fluxo principal analisado** não foi identificado reprocessamento/gravação de `ConsumoHistorico` no Faturamento; a determinação e manutenção pertencem à Micromedição (mesma conclusão, no nível de certeza que a evidência permite) | `faturamento.md` §5, §28 |

## Conclusões que permanecem válidas (não reabertas)

`gerarConta(...)` como núcleo do faturamento e candidato a golden master; fronteira Micromedição → Faturamento (consumo como insumo); consumo mínimo = Σ mínimo tarifário da categoria × economias, com overrides cuja **ordem fina permanece dúvida aberta**; estrutura tarifa → vigência → categoria → mínimo → faixas; percentuais de esgoto/coleta/alternativo com limite; retificação (conta original → nova conta → vínculo de origem → motivo → trilha financeira); cancelamento como mudança de estado, não exclusão física; precisão financeira (`BigDecimal`, HALF_UP, escala e **momento do arredondamento**) como comportamento a reproduzir nos testes; variações por companhia existentes em três camadas, com a proposta de pontos de extensão no SISAN mantida explicitamente como **hipótese**, não decisão.

## Escopo

- **Impacto**: apenas documental (formulação/nível de certeza). Nenhuma conclusão técnica invalidada, nenhum número alterado.
- **Não realizado**: reanálise do Faturamento; nenhum `faturamento-v2.md`; nenhuma duplicação de documentação.
- **Nota de sequência**: os mapas de **Cobrança** (commit `4279671`) e **Arrecadação** (commit `5f935c6`) já haviam sido concluídos após o commit `5ec3733` — por isso não foram refeitos; receberam apenas a propagação da correção nº 1.
- **Testes**: n/a · **Risco**: baixo · **Rollback**: `git revert` do commit.
