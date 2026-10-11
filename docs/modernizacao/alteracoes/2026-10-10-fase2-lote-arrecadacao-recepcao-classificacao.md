# [2026-10-10] Fase 2 — lote 6: Arrecadação — recepção do movimento e classificação dos pagamentos

> Décimo primeiro lote de baselines da Fase 2 e o primeiro da Arrecadação, no EAR em modo Batch. **Não implementa o
> OpenGSAN** e **não altera o legado**. A Fase 2 **continua em andamento**.

- **Motivo**: os P0 da Arrecadação ligados à recepção do movimento, à identificação e classificação do pagamento e aos seus
  efeitos financeiros — inclusive o que a Cobrança passa a considerar quitado.
- **Impacto**: 21 baselines (CEN-ARR-001 a 005); 6 deltas de massa e 1 passo; o roteiro `faturar_grupo` ganhou os passos
  `movimento` (arquivo do arrecadador com o código de barras que o GSAN imprime, enviado pela tela), `aguardar_movimento`
  e `consultar_debitos` (posição de dívida pela tela) e o bloco `arrecadacao`; `gsan_http` envia multipart. Nenhuma linha do
  legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: três rodadas de exploração dirigida (14 variações, sem gravar); captura com 2 execuções idênticas; verificação
  independente; regressão dos lotes Batch 5, 5b, 5c, 5d, 5e e do piloto; `caracterizacao.py verificar`,
  `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `dd84849` (lote 5e). Cobertura: 26 de 42 P0 da classe A; 145 baselines; 35 cenários com baseline.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 21 baselines — ARR-001 V1/V2/V2b/V3/V4/V5, ARR-002 V1/V1b/V1c/V2/V3/V4, ARR-003 V1/V2/V5, ARR-004 V1/V1b/V1c, ARR-005 V1/V2/V3 | `ambiente-referencia/baselines/golden/arrecadacao/` |
| Arrecadador, contrato, tarifa, catálogos da Arrecadação, parâmetros FEBRABAN, processo de classificação, clientes das contas, conferência do trailer; o passo que avança a referência de faturamento | `ambiente-referencia/baselines/massas/deltas/arr-*.sql`, `massas/passos/arr-faturamento-encerrado-202605.sql` |
| Achados F2-115 a F2-128; candidatos CAND-29 a CAND-33; evidência nova para CAND-19 | [relatório §25](../testes/fase2/fase2-caracterizacao-baselines.md#25-lote-6--arrecadação-recepção-do-movimento-e-classificação-dos-pagamentos-2026-10-10), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada; a matriz de caracterização não muda) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-29** | Uma conta com qualquer pagamento vinculado sai da posição de dívida — inclusive o pagamento a menor (VALOR NÃO CONFERE): a falta deixa de ser cobrada | A conta só sai da dívida pelo que os pagamentos apropriados quitam |
| **CAND-30** | Diferença de até R$ 2,00 é reclassificada como CLASSIFICADO, sem registro da falta | Tolerância parametrizada e diferença registrada |
| **CAND-31** | Um pagamento exato desclassifica o anterior (classificado pela tolerância), que perde o vínculo com a conta | O apropriado continua apropriado; o que chega depois é o excedente |
| **CAND-32** | Com a referência contábil aberta, o pagamento CLASSIFICADO fica com excedente = valor pago | Excedente = pago − devido, sempre |
| **CAND-33** | A falha do processamento do arquivo volta tudo depois de a tela dizer "enviado", sem aviso | Resultado do processamento registrado e visível |

CAND-29 e CAND-30 tocam **quitação e valor**: continuam no **oráculo 1** até decisão registrada. Nada foi aprovado.
Continuam pendentes, sem decisão automática: D-17, D-19, CAND-02, CAND-11 a CAND-33, a leitura final de D-15 e o alcance de
D-14.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§25, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) · `testes/cenarios/arrecadacao.md` (CEN-ARR-001 a 005) · `testes/cenarios-criticos.md`
§11 · `testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` (estado) · `modulos/arrecadacao.md` ·
`modulos/cobranca.md` · `alteracoes/README.md` · `ambiente-referencia/baselines/README.md`. **Código das ferramentas**:
`baselines/ferramentas/roteiros.py`, `baselines/ferramentas/gsan_http.py`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 6 capturado: **21/21** variações com as duas execuções idênticas, **21/21** conferidas
numa verificação independente e os lotes 5, 5b, 5c, 5d, 5e e o piloto de novo **78/78**. **166** baselines em 40 cenários;
P0 da classe A **30 de 42** (+4: CEN-ARR-002 a 005). CAND-29 a CAND-33 aguardam decisão. Próximo lote: **6b — Arrecadação:
devolução, reclassificação e arquivamento**; MIC-005 (análise de leitura, pela tela) e a baseline de performance seguem
pendentes.
