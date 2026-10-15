# [2026-10-15] Fase 2 — lote 7b: Cobrança — efetuar parcelamento

> Décimo quinto lote de baselines da Fase 2, no EAR em modo Batch. **Não implementa o OpenGSAN** e **não altera o
> legado**. A Fase 2 **continua em andamento**.

- **Motivo**: a negociação da dívida — o assistente Efetuar Parcelamento de Débitos pela tela, com as opções de prestações,
  a memória financeira, os itens, os débitos e créditos gerados, a guia de entrada e a situação dos documentos originais, ao
  centavo.
- **Impacto**: 9 baselines novas em CEN-COB-004 (cenário novo); 4 deltas de massa; o roteiro `faturar_grupo` ganhou o passo
  `efetuar_parcelamento` e o bloco `parcelamento`, e as datas do relógio do legado posteriores à execução (vencimento da guia
  de entrada, da conta tomada como entrada) saem relativas — as datas da massa são todas anteriores e as baselines existentes
  não mudam (regressão). Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Integração externa**: a emissão do boleto da entrada pela API do Banco do Brasil (ligada na base) fica **fora da
  fronteira** — desligada por um delta de configuração em todas as variações menos V6, que mostra a base como está e falha
  antes de qualquer chamada de rede; a rede do GSAN de referência é interna, sem saída. Os parâmetros de URL de integração da
  base (`seguranca.parametro`) foram conferidos só por nome e natureza: nenhum traz credencial embutida; nenhum valor foi
  transcrito.
- **Testes**: 14 rodadas de exploração dirigida (9 variações em 27 execuções, sem gravar); captura com 2 execuções idênticas; verificação independente;
  regressão do lote 7 e dos lotes 6, 6b e 6c (49/49); `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `d6eb5f2` (lote 7). Cobertura: 33 de 42 P0 da classe A; 194 baselines; 43 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 9 baselines — COB-004 V1/V1b/V1c/V1d/V2/V3/V4/V5/V6 | `ambiente-referencia/baselines/golden/cobranca/CEN-COB-004/` |
| Cenário CEN-COB-004 | `ambiente-referencia/baselines/cenarios/` |
| O catálogo do parcelamento (RD, perfis, faixas, grupos, situações, tipos de débito e crédito, concessões dos passos); a guia de serviço; o débito de 24 prestações; o delta de configuração que desliga o boleto pela API do banco | `ambiente-referencia/baselines/massas/deltas/cob-parcelamento-catalogos.sql`, `cob-guia-servico.sql`, `cob-debito-servico-24x.sql`, `cob-parcelamento-sem-boleto-bb.sql` |
| Achados F2-158 a F2-169; candidatos CAND-41 a CAND-44; achado de segurança 38 | [relatório §29](../testes/fase2/fase2-caracterizacao-baselines.md#29-lote-7b--cobrança-efetuar-parcelamento-2026-10-15), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`riscos-identificados.md`](../seguranca/riscos-identificados.md), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-41** | A tela propõe a entrada mínima da última faixa (R$ 46,99) e mostra as opções com a de 10% (R$ 23,49); sem o Calcular, a conclusão usa a entrada proposta com a prestação da opção — sem juros, a prestação do cabeçalho (70,49) não é a dos débitos (62,65); com juros, **R$ 36,50 de juros em vez de 11,54** (o cliente paga R$ 24,96 a mais) | Opções, prestação e juros sempre calculados com a entrada efetiva |
| **CAND-42** | A conta NB (pagamento comprovado) impede o parcelamento: os acréscimos dela saem do total, não dos componentes, e a conferência recusa sem mensagem (HTTP 500) | A conta NB sai com os seus acréscimos, por componente; toda recusa com mensagem |
| **CAND-43** | Com o boleto pela API do banco ligado, a conclusão grava o parcelamento e a falha da emissão chega à tela como "Erro de Sistema" | A negociação confirmada é informada como efetuada; emissão e registro bancário em passo próprio, reprocessável |
| **CAND-44** | A memória financeira (débito atualizado, acréscimos, descontos, entrada) vem do formulário; a conferência só compara campos entre si (por leitura de código; achado de segurança 38) | O servidor recalcula dívida e opções na conclusão |

CAND-41 toca **valor**: continua no **oráculo 1** até decisão registrada. Nada foi aprovado. Continuam pendentes, sem
decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-44, a leitura final de D-15 e o alcance de D-14. Segue pendente
também **F2-157** (ferramenta; F2-169 traz evidência nova: o literal escrito em Python sai correto).

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§29, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/cobranca.md` (CEN-COB-004) · `testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` ·
`seguranca/riscos-identificados.md` · `compatibilidade/divergencias-aprovadas.md` (estado) · `modulos/cobranca.md` (§15) ·
`alteracoes/README.md` · `ambiente-referencia/baselines/README.md`. **Código das ferramentas**: `baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 7b capturado: **9/9** variações com as duas execuções idênticas, **9/9** conferidas numa
verificação independente e o lote 7 e os lotes 6, 6b e 6c de novo **49/49**. **203** baselines em 44 cenários; P0 da classe A
**34 de 42** (+1: CEN-COB-004). CAND-41 aguarda decisão — toca valor. Próximo lote:
**7c — Cobrança: depois do parcelamento** (CEN-ARR-008: pagamento da entrada e da prestação; CEN-COB-005: desfazimento e
reparcelamento); MIC-005 (análise de leitura, pela tela) e a baseline de performance seguem pendentes.
