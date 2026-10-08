# [2026-10-08] Fase 2 — lote 5d: ciclo de vida da conta — retificação, cancelamento e prescrição

> Nono lote de baselines da Fase 2, no EAR em modo Batch. **Não implementa o OpenGSAN** e **não altera o legado**. A
> Fase 2 **continua em andamento**.

- **Motivo**: os dois P0 de Faturamento do lado do documento — retificação (CEN-FAT-007) e cancelamento e prescrição
  (CEN-FAT-008) — operam sobre contas já geradas; o faturamento em grupo do lote 5 as gera no início de cada execução.
- **Impacto**: 2 definições executáveis; 7 deltas de massa e 1 passo (`massas/passos/`); 12 baselines em
  `golden/faturamento/`; o roteiro `faturar_grupo` ganhou os passos `retificar`, `cancelar` e `iniciar_processo` e o bloco
  opcional `ciclo_conta` (contas pela identidade documental, contas gerais sem documento, pagamentos, RA, consumos,
  auditoria) — mudanças **aditivas**. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: exploração (11 variações, sem gravar); captura com 2 execuções idênticas por variação; verificação independente
  do lote; regressão dos lotes Batch 5, 5b, 5c e do piloto; `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `8695628` (lote 5c). Cobertura: 24 de 42 P0 da classe A; 110 baselines.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| CEN-FAT-007 (V1, V1b, V2, V2b, V3, V4, V4b), FAT-008 (V1, V1b, V1c, V2, V2b) — 12 baselines | `ambiente-referencia/baselines/golden/faturamento/` |
| Catálogos da manutenção de conta, permissões sem RA, histórico de consumo, Arrecadação mínima e o pagamento (passo), RA de alteração de conta, contas antigas e o processo de prescrição | `ambiente-referencia/baselines/massas/deltas/conta-ciclo-*.sql`, `massas/passos/pagamento-conta-imv01-202605.sql` |
| Achados F2-87 a F2-100; candidatos CAND-17 a CAND-24; nota de evidência sobre o alcance de D-14 | [relatório §23](../testes/fase2/fase2-caracterizacao-baselines.md#23-lote-5d--ciclo-de-vida-da-conta-retificação-cancelamento-e-prescrição-2026-10-08), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada): **26 de 42** P0 da classe A | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-17** | A segunda retificação no mesmo mês contábil **sobrescreve** a conta retificada (o documento anterior deixa de existir) | Toda retificação gera nova versão, com linhagem |
| **CAND-18** | Cancelar a conta retificada no mesmo mês a **exclui fisicamente** e devolve a original como CANCELADA | Cancelamento é sempre estado |
| **CAND-19** | Retificar conta paga **move o pagamento** para a conta nova (R$ 110,40 pagos numa conta de R$ 94,05) | O pagamento continua na conta que pagou |
| **CAND-20** | A prescrição manual (cancelar com motivo de prescrição) **nunca** é aceita — consulta HQL quebrada | A mesma regra da prescrição em lote |
| **CAND-21** | A conta retificadora não referencia a retificada; o RA fica na conta antiga | Linhagem explícita |
| **CAND-22** | O parecer do encerramento automático do RA é gravado com bytes corrompidos (literal do fonte) | Texto correto |
| **CAND-23** | Falha na montagem de uma tarefa batch deixa o processo EM PROCESSAMENTO para sempre, sem erro | Falha registrada, etapa encerrada com erro |
| **CAND-24** | Sem a permissão e sem RA, a tela de cancelamento recusa, mas o POST de cancelamento é **aceito** (achado de segurança 36; família de D-19) | A exigência de RA avaliada no servidor |

CAND-19 toca **valor e quitação**: continua no **oráculo 1** até decisão registrada. Nada foi aprovado. Continuam
pendentes, sem decisão automática: D-19, CAND-02, CAND-11 a CAND-16, a leitura final de D-15 e, agora, o alcance de D-14
(a retificação que muda o consumo corrige o consumo faturado do histórico?).

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§23, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/faturamento.md` (FAT-007, FAT-008) · `testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` ·
`compatibilidade/divergencias-aprovadas.md` (nota de D-14, estado) · `seguranca/riscos-identificados.md` (achado 36) · `modulos/faturamento.md` · `modulos/batch.md` ·
`alteracoes/README.md` · `ambiente-referencia/baselines/README.md`. **Código das ferramentas**: `baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 5d capturado com determinismo (11/11 idênticas e a V1c, acrescentada depois, também); verificação independente com o roteiro final **12/12**; regressão dos lotes 5, 5b, 5c e do piloto **43/43** — as 122 baselines conferem. P0 da classe A: 24 → **26 de 42**. Próximo lote recomendado: **5e — consumo pela origem, na conta** (consistir e faturar em sequência, inclusive a retificação por alteração da leitura faturada).
