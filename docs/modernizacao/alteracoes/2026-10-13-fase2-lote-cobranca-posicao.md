# [2026-10-13] Fase 2 — lote 7: Cobrança — posição de dívida e acréscimos por impontualidade

> Décimo quarto lote de baselines da Fase 2 e o primeiro da Cobrança, no EAR em modo Batch. **Não implementa o OpenGSAN**
> e **não altera o legado**. A Fase 2 **continua em andamento**.

- **Motivo**: a posição de dívida que a Cobrança calcula — por imóvel e por cliente, com os acréscimos por impontualidade,
  os débitos a cobrar e os créditos —, a conta em revisão e os acréscimos que o encerramento gera para a conta paga em
  atraso.
- **Impacto**: 7 baselines novas — CEN-COB-001 (cenário novo, o primeiro do domínio) e CEN-ARR-002 V2b, V2c; 3 deltas de
  massa; o roteiro `faturar_grupo` ganhou, no `consultar_debitos`, os acréscimos e os totais (opção `acrescimos`) e a posição
  pelo cliente (`clientes`), o passo `colocar_revisao` e o bloco `cobranca`; sem as opções, o `consultar_debitos` sai como
  antes (regressão). As variações do lote 6 em CEN-ARR-002 ficam com a definição idêntica. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: quatro rodadas de exploração dirigida (6 variações em 9 execuções, sem gravar); captura com 2 execuções
  idênticas; verificação independente; regressão dos lotes 6, 6b e 6c; `caracterizacao.py verificar`, `cobertura.py
  verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `1b67a5f` (lote 6c). Cobertura: 32 de 42 P0 da classe A; 187 baselines; 42 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 7 baselines — COB-001 V1/V1b/V1c/V2/V3, ARR-002 V2b/V2c | `ambiente-referencia/baselines/golden/cobranca/`, `golden/arrecadacao/CEN-ARR-002/` |
| Cenário CEN-COB-001; CEN-ARR-002 V2b, V2c | `ambiente-referencia/baselines/cenarios/` |
| Índices de acréscimo (desenhados para não depender do dia); tipos de débito de acréscimo e o processo da etapa 188; o que a revisão de conta exige | `ambiente-referencia/baselines/massas/deltas/cob-acrescimos-indices.sql`, `cob-acrescimos-encerramento.sql`, `cob-revisao.sql` |
| Achados F2-147 a F2-157; candidato CAND-40; evidência nova para CAND-24 e CAND-29; achado de segurança 37 | [relatório §28](../testes/fase2/fase2-caracterizacao-baselines.md#28-lote-7--cobrança-posição-de-dívida-e-acréscimos-por-impontualidade-2026-10-13), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`riscos-identificados.md`](../seguranca/riscos-identificados.md), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-40** | Gerar os acréscimos de novo cria outro débito de juros para a mesma conta (a multa tem trava, os juros não) | A geração de acréscimos é idempotente por conta e componente |
| CAND-24 (evidência nova) | A exigência de RA da revisão de conta é verificada só na tela; o POST é aceito sem RA | A exigência no caso de uso, no servidor |
| CAND-29 (evidência nova) | O pagamento a menor tira a conta da posição com os acréscimos | O saldo e os acréscimos continuam em cobrança |

Também para decisão do responsável — **F2-157** (ferramenta): o literal das datas relativas sai como "data da execuÃ§Ã£o" em 43 goldens desde o lote 5d (estável; as verificações conferem); corrigir a ferramenta exige regravar ou normalizar essas baselines.

CAND-40 toca **valor**: continua no **oráculo 1** até decisão registrada. Nada foi aprovado. Continuam pendentes, sem
decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-40, a leitura final de D-15 e o alcance de D-14.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§28, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/cobranca.md` (CEN-COB-001) · `testes/cenarios/arrecadacao.md` (CEN-ARR-002) ·
`testes/cenarios-criticos.md` §11 · `testes/estrategia-testes.md` · `seguranca/riscos-identificados.md` ·
`compatibilidade/divergencias-aprovadas.md` (estado) · `modulos/cobranca.md` (§20, §22) · `alteracoes/README.md` ·
`ambiente-referencia/baselines/README.md`. **Código das ferramentas**: `baselines/ferramentas/roteiros.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 7 capturado: **7/7** variações com as duas execuções idênticas, **7/7** conferidas numa
verificação independente e os lotes 6, 6b e 6c de novo **42/42**. **194** baselines em 43 cenários; P0 da classe A
**33 de 42** (+1: CEN-COB-001). CAND-40 aguarda decisão — toca valor. Próximo lote: **7b — Cobrança: parcelamento**
(CEN-COB-004, CEN-ARR-008, CEN-COB-005); MIC-005 (análise de leitura, pela tela) e a baseline de performance seguem
pendentes.
