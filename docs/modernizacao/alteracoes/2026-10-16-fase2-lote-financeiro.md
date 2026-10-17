# [2026-10-16] Fase 2 — lote 9: Financeiro — lançamentos contábeis e devedores duvidosos

> Décimo oitavo lote de baselines da Fase 2, no EAR em modo Batch, o primeiro da Contabilização. **Não implementa o
> OpenGSAN** e **não altera o legado**. A Fase 2 **continua em andamento**.

- **Motivo**: os lançamentos contábeis da competência por origem — faturamento (a partir do encerramento do mês), arrecadação e
  avisos bancários — pela parametrização como dado, com débitos e créditos conferidos contra o resumo de que vieram; e a baixa
  contábil de devedores duvidosos — seleção por critério, marcação, resumo, lançamentos — e a recuperação quando a conta baixada é
  paga, ao centavo.
- **Impacto**: 7 baselines novas — CEN-FIN-001 V1, V1b, V2, V3 e CEN-FIN-002 V1, V1b, V3 (cenários novos); 7 deltas de massa; o
  roteiro `faturar_grupo` ganhou o passo `gerar_resumo_devedores` e o bloco de detalhes `financeiro` — nenhuma linha existente mudou
  de comportamento. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Integração externa**: nenhuma chamada. A exportação para o sistema contábil fica fora da fronteira.
- **Testes**: 3 rodadas de exploração dirigida (9 execuções e uma tentativa que parou na massa, sem gravar); captura com 2
  execuções idênticas; verificação independente; regressão do lote 8, do 6c e de CEN-FAT-008 (25/25); `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `8106555` (lote 8). Cobertura: 38 de 42 P0 da classe A; 224 baselines; 48 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 7 baselines — FIN-001 V1/V1b/V2/V3, FIN-002 V1/V1b/V3 | `ambiente-referencia/baselines/golden/financeiro/CEN-FIN-001/`, `golden/financeiro/CEN-FIN-002/` |
| Cenários CEN-FIN-001 e CEN-FIN-002 | `ambiente-referencia/baselines/cenarios/` |
| Catálogos de lançamento (as constantes do código) e origens; os processos de encerramento e de contabilização; o plano de contas e a parametrização SINTÉTICOS; o parâmetro, a situação de cobrança e as contas de fronteira dos devedores duvidosos | `ambiente-referencia/baselines/massas/deltas/fin-*.sql` |
| Achados F2-195 a F2-203; candidatos CAND-53 a CAND-56 | [relatório §32](../testes/fase2/fase2-caracterizacao-baselines.md#32-lote-9--financeiro-lançamentos-contábeis-e-devedores-duvidosos-2026-10-16), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-53** | A linha de resumo sem parâmetro some da contabilização e a etapa termina CONCLUÍDA — contabilizado R$ 407,15 × resumo R$ 531,09, sem registro (FIN-001 V1b) | A combinação sem parâmetro é erro ou pendência explícita da competência |
| **CAND-54** | No PostgreSQL, o número de meses da baixa de devedores não exclui nada: a conta a 11 meses de um critério de 12 e a vencida há 0 meses são baixadas (FIN-002 V1) — **toca valor** | A idade da dívida pela data de vencimento |
| **CAND-55** | No PostgreSQL, o teto da baixa não limita e o valor baixado fica R$ 0,00: R$ 260,40 baixados com teto de R$ 100,00 (FIN-002 V1, V1b) — **toca valor** | O teto confere a soma a baixar; o valor baixado acumula |
| **CAND-56** | Os avisos bancários são contabilizados por contas procuradas pelo nome ("BANCO", "ARRECADACAO A DISCRIMINAR"), fora da parametrização (FIN-001 V3) | A origem dos avisos parametrizada como as demais |

Nenhum aprovado. Continuam pendentes, sem decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-56 (CAND-41, CAND-52, CAND-54 e
CAND-55 no oráculo 1, porque tocam valor; CAND-44 com a evidência executável do lote 7c), a leitura final de D-15, o alcance de
D-14 e F2-157.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§32, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/financeiro-operacional.md` (CEN-FIN-001, CEN-FIN-002) · `testes/cenarios-criticos.md` §11 ·
`testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` (estado) · `modulos/financeiro-contabilizacao.md` (§6,
§7, §14) · `alteracoes/README.md` · `ambiente-referencia/baselines/README.md`. **Código das ferramentas**:
`baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 9 capturado: **7/7** variações com as duas execuções idênticas, **7/7** conferidas numa
verificação independente e a regressão **25/25**; 35 conferências dos documentos contra os goldens, sem divergência. **231**
baselines em 50 cenários; P0 da classe A **40 de 42** (+2: CEN-FIN-001, CEN-FIN-002). CAND-53 a CAND-56 pendentes (CAND-54 e
CAND-55 tocam valor — oráculo 1). Próximo lote: **10 — Relatórios e integração de campo** (CEN-REL-001, CEN-INT-001), com o
acesso indevido e a entrada sem identificação registrados como achado de segurança. MIC-005 e a baseline de performance seguem
pendentes.
