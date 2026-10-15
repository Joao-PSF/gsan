# [2026-10-15] Fase 2 — lote 7c: Cobrança — depois do parcelamento

> Décimo sexto lote de baselines da Fase 2, no EAR em modo Batch. **Não implementa o OpenGSAN** e **não altera o
> legado**. A Fase 2 **continua em andamento**.

- **Motivo**: o que acontece a um parcelamento depois de efetuado — o pagamento da guia de entrada e da conta com a prestação, o
  desfazimento automático por entrada não paga e o manual, e o reparcelamento do saldo — ao centavo, com as situações e os saldos
  antes e depois; e a caracterização controlada da hipótese do CAND-44.
- **Impacto**: 10 baselines novas — CEN-ARR-008 V1, V2 e CEN-COB-005 V1, V1b, V1c, V2, V2b, V2c, V3 (cenários novos) e
  CEN-COB-004 V7; **9 baselines recapturadas com `--substituir`** (CEN-COB-004 V1, V1b, V1c, V1d, V2, V3, V4, V6 do lote 7b e
  CEN-ARR-005 V1 do lote 6b), porque dependiam do relógio (F2-170) — a comparação campo a campo com as versões anteriores mostra
  que só mudaram os campos do relógio, a troca dos indicadores de desfazimento pelo motivo e o usuário e, na V3, a ordem de dois
  débitos cobrados empatados; 1 delta de massa e 1 passo de relógio; o roteiro `faturar_grupo` ganhou o passo
  `desfazer_parcelamento`, o registro da guia de entrada no movimento, `forjar_conclusao` no parcelamento e a forma relativa das
  referências e datas que o legado tira do relógio. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Integração externa**: nenhuma chamada. A tela Consultar Parcelamento tenta registrar o boleto da entrada pela API do banco
  mesmo com a integração desligada (CAND-45); o cliente sintético fica **sem CPF/CNPJ de propósito** — a tentativa falha na
  gravação da ficha, antes de qualquer chamada de rede (e a rede do GSAN de referência é interna).
- **Usuário sintético novo**: o de rotina batch que o desfazimento automático exige — sem senha (não autentica), sem grupo,
  distinto do operador do executor.
- **Testes**: 4 rodadas de exploração dirigida (14 execuções, sem gravar); captura com 2 execuções idênticas (as 10 novas e as 9 substituídas);
  verificação independente; regressão do lote 7 e dos lotes 6, 6b e 6c (49/49); `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `83950e7` (lote 7b). Cobertura: 34 de 42 P0 da classe A; 203 baselines; 44 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 10 baselines — ARR-008 V1/V2, COB-005 V1/V1b/V1c/V2/V2b/V2c/V3, COB-004 V7 | `ambiente-referencia/baselines/golden/arrecadacao/CEN-ARR-008/`, `golden/cobranca/CEN-COB-005/`, `golden/cobranca/CEN-COB-004/V7.json` |
| 9 baselines recapturadas (relógio) | `golden/cobranca/CEN-COB-004/` (V1, V1b, V1c, V1d, V2, V3, V4, V6), `golden/arrecadacao/CEN-ARR-005/V1.json` |
| Cenários CEN-ARR-008 e CEN-COB-005; CEN-COB-004 V7 | `ambiente-referencia/baselines/cenarios/` |
| O que o desfazimento exige (situações, motivos, usuário de rotina batch, processo, concessões); o passo de relógio da guia de entrada | `ambiente-referencia/baselines/massas/deltas/cob-parcelamento-desfazer.sql`, `massas/passos/cob-relogio-entrada-vencida.sql` |
| Achados F2-170 a F2-182; candidatos CAND-45 a CAND-49; CAND-44 com evidência executável; achado de segurança 39 (e o 38 atualizado) | [relatório §30](../testes/fase2/fase2-caracterizacao-baselines.md#30-lote-7c--cobrança-depois-do-parcelamento-2026-10-15), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`riscos-identificados.md`](../seguranca/riscos-identificados.md), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-44** (executado) | O POST de conclusão com valores coerentes entre si e diferentes da dívida calculada é aceito: multa zerada, dívida R$ 2,27 menor, sem o débito de multa (CEN-COB-004 V7) | O servidor recalcula dívida e opções na conclusão |
| **CAND-45** | A consulta do parcelamento com entrada não paga registra o boleto pela API do banco, sem olhar a configuração; sem CPF/CNPJ, a tela falha (500) e o Desfazer fica inalcançável | Consultar não emite nada; a emissão é ação explícita e configurável |
| **CAND-46** | O desfazimento não confere no servidor o que a tela confere — com a entrada paga, tenta excluir a guia paga (só a chave estrangeira impede); o EP é desfeito pela URL | As condições no caso de uso, no servidor, com recusa explícita |
| **CAND-47** | O parcelamento com a conta como entrada, não paga, nunca é desfeito (o processo só olha guias; a tela trata como paga) | A entrada por conta acompanhada como a guia |
| **CAND-48** | O primeiro reparcelamento não é contado (contador nulo → 0) | Contar a partir de zero |
| **CAND-49** | O desfazimento exclui os documentos gerados e nada grava auditoria | Cancelar com vínculo; trilha de auditoria da negociação |

CAND-41 continua no **oráculo 1** (toca valor) — o lote trouxe evidência nova (o Calcular recusa a entrada abaixo do mínimo da
última faixa). Nada foi aprovado. Continuam pendentes, sem decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-49, a leitura
final de D-15, o alcance de D-14 e F2-157.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§30, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/arrecadacao.md` (CEN-ARR-008) · `testes/cenarios/cobranca.md` (CEN-COB-004, CEN-COB-005) ·
`testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` · `seguranca/riscos-identificados.md` ·
`compatibilidade/divergencias-aprovadas.md` (estado) · `modulos/cobranca.md` (§15) · `alteracoes/README.md` ·
`alteracoes/2026-10-15-fase2-lote-cobranca-parcelamento.md` (nota da recaptura) · `ambiente-referencia/baselines/README.md`.
**Código das ferramentas**: `baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 7c capturado: **10/10** variações novas e **9/9** substituídas com as duas execuções idênticas,
**20/20** conferidas numa verificação independente e o lote 7 e os lotes 6, 6b e 6c de novo **49/49**. **213** baselines em 46
cenários; P0 da classe A **36 de 42** (+2: CEN-ARR-008, CEN-COB-005). CAND-41 continua no oráculo 1 (toca valor); CAND-44 com
evidência executável, pendente. Próximo lote: **8 — Cobrança: ação de cobrança e conta em cobrança** (CEN-COB-002, CEN-COB-007);
depois o Financeiro (CEN-FIN-001, 002). MIC-005 e a baseline de performance seguem pendentes.
