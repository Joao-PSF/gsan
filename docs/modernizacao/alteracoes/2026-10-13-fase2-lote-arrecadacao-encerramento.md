# [2026-10-13] Fase 2 — lote 6c: Arrecadação — encerramento e arquivamento

> Décimo terceiro lote de baselines da Fase 2, continuação dos lotes 6 e 6b, no EAR em modo Batch. **Não implementa o
> OpenGSAN** e **não altera o legado**. A Fase 2 **continua em andamento**.

- **Motivo**: o fechamento da competência de arrecadação — o resumo que o encerramento grava, o que o arquivamento leva ao
  histórico e o avanço da competência — e o que o arquivamento faz com a identidade do pagamento e com o pagamento de uma
  conta arquivada.
- **Impacto**: 9 baselines novas — CEN-ARR-010 e CEN-ARR-006 (cenários novos) e CEN-ARR-005 V4; 4 deltas de massa; o roteiro
  `faturar_grupo` ganhou o passo `consultar_pagamentos`, o registro de conta arquivada no `movimento`, o texto da recusa de
  `iniciar_processo` lançado no lugar da chave e o bloco `encerramento`; as variações do lote 6 em CEN-ARR-005 ficam com a
  definição idêntica. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo. ⚠️ Durante a exploração, um `docker run` baixou sem querer a imagem oficial
  `alpine:latest` (Docker Hub, ~4 MB) para uma busca de texto no volume das migrações; foi removida em seguida e não é usada
  por nada do lote (as buscas seguintes usaram a imagem local `gsan-referencia/ferramentas`).
- **Testes**: duas rodadas de exploração dirigida (7 variações em 10 execuções, sem gravar); captura com 2 execuções idênticas; verificação
  independente; regressão dos lotes 6 e 6b; `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `5c84ab0` (lote 6b). Cobertura: 30 de 42 P0 da classe A; 178 baselines; 40 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 9 baselines — ARR-010 V1/V1b/V2/V3/V4/V5, ARR-006 V1/V2, ARR-005 V4 | `ambiente-referencia/baselines/golden/arrecadacao/` |
| Cenários CEN-ARR-010 e CEN-ARR-006; CEN-ARR-005 V4 | `ambiente-referencia/baselines/cenarios/` |
| Catálogos do resumo (das constantes do legado); os processos de encerramento e arquivamento; a concessão de Consultar Pagamento; a conta arquivada | `ambiente-referencia/baselines/massas/deltas/arr-encerramento-catalogos.sql`, `arr-processo-encerrar.sql`, `arr-consulta-pagamentos.sql`, `arr-conta-arquivada.sql` |
| Achados F2-138 a F2-146; candidatos CAND-38 e CAND-39 | [relatório §27](../testes/fase2/fase2-caracterizacao-baselines.md#27-lote-6c--arrecadação-encerramento-e-arquivamento-2026-10-13), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada; a matriz de caracterização não muda) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-38** | O arquivamento das contas pagas (Gerar Histórico Conta) falha sempre; nenhuma conta vai ao histórico e, no mesmo processo, as etapas seguintes ficam em espera | O arquivamento das contas pagas funciona; a falha de uma etapa não deixa as outras em espera silenciosa |
| **CAND-39** | Depois do arquivamento do pagamento, um segundo pagamento da mesma conta sai CLASSIFICADO, sem excedente | A duplicidade é verificada contra os pagamentos atuais e os arquivados do documento |

CAND-39 toca **valor** (quitação e devolução): continua no **oráculo 1** até decisão registrada. Nada foi aprovado.
Continuam pendentes, sem decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-39, a leitura final de D-15 e o alcance de
D-14.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§27, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) · `testes/cenarios/arrecadacao.md` (CEN-ARR-005, 006, 010) ·
`testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` (estado) ·
`modulos/arrecadacao.md` (§2, §14) · `alteracoes/README.md` · `ambiente-referencia/baselines/README.md`. **Código das
ferramentas**: `baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 6c capturado: **9/9** variações com as duas execuções idênticas, **9/9** conferidas numa
verificação independente e os lotes 6 e 6b de novo **33/33**. **187** baselines em 42 cenários; P0 da classe A **32 de 42**
(+2: CEN-ARR-006 e CEN-ARR-010). CAND-38 e CAND-39 aguardam decisão — CAND-39 toca valor. Próximo lote: **7 — Cobrança:
posição de dívida, acréscimos e parcelamento** (CEN-COB-001, 004, 005, CEN-ARR-008 e os acréscimos por impontualidade);
MIC-005 (análise de leitura, pela tela) e a baseline de performance seguem pendentes.
