# [2026-10-08] Fase 2 — lote 5e: consumo pela origem, na conta — consistir e faturar em sequência

> Décimo lote de baselines da Fase 2, no EAR em modo Batch. **Não implementa o OpenGSAN** e **não altera o legado**. A
> Fase 2 **continua em andamento**.

- **Motivo**: as variações que dependiam da conta (`gerarConta`) e da consistência na mesma execução — situação especial,
  precedência do mínimo, vigência no meio do período, esgoto e poço, a retificação por alteração da leitura faturada que ficou
  do lote 5d — e os cenários de anormalidade (MIC-004) e de rota por finalidade (CAD-005).
- **Impacto**: 23 baselines (variações novas em FAT-001, FAT-002, FAT-003, FAT-007, MIC-001, MIC-002, CAD-004 e os cenários
  novos MIC-004 e CAD-005); 21 deltas de massa; 🆕 o **executor** aceita campos por variação (lote, modo, fronteira,
  pré-condições, efeitos, observáveis, oráculo, ressalvas), com os do cenário como padrão — provado sem efeito nas 122
  variações existentes; `baseline.sh` pede o modo por variação; o roteiro `faturar_grupo` dispara o comando do passo,
  retifica pela leitura e ganhou o bloco `conta_origem`. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: duas rodadas de exploração dirigida e uma passada exploratória das 22 primeiras variações (sem gravar); captura
  com 2 execuções idênticas; verificação independente; regressão dos lotes Batch 5, 5b, 5c, 5d e do piloto;
  `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `65df489` (lote 5d). Cobertura: 26 de 42 P0 da classe A; 122 baselines.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| 23 baselines — FAT-001 V4/V5, MIC-001 V5, CAD-004 V8/V9, FAT-002 V1c, FAT-003 V2/V2b/V3, MIC-002 V3c/V4c/V4d/V5c/V6c/V8, FAT-007 V2c, MIC-004 V1–V5, CAD-005 V1/V2 | `ambiente-referencia/baselines/golden/` |
| Comando de faturar da R4, catálogos de situação especial, um imóvel por perfil, vigência no meio do período, rota alternativa, catálogos da retificação | `ambiente-referencia/baselines/massas/deltas/cons-*.sql`, `tar01-vigencia-2026-05-16.sql` |
| Achados F2-101 a F2-114; candidatos CAND-25 a CAND-28; complemento da nota de evidência sobre D-14 | [relatório §24](../testes/fase2/fase2-caracterizacao-baselines.md#24-lote-5e--consumo-pela-origem-na-conta-consistir-e-faturar-em-sequência-2026-10-08), [`cenarios-criticos.md §11`](../testes/cenarios-criticos.md#11-candidatos-a-divergência), [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) |
| Cobertura (gerada) | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. Achados que pedem decisão

| Candidato | Comportamento do GSAN (baseline) | Proposta para o OpenGSAN |
| --------- | --------------------------------- | ------------------------ |
| **CAND-25** | A virada de hidrômetro não é reconhecida (comparação de Integer por referência): o mês vira média | A virada é reconhecida pelos dígitos do hidrômetro |
| **CAND-26** | Um imóvel com poço medido derruba a consistência da rota inteira | A falha de um imóvel fica nele; o poço compõe o esgoto |
| **CAND-27** | O faturamento, já comandado, fatura a rota pelo mínimo mesmo com a consistência falha | O faturamento exige a consistência da referência concluída |
| **CAND-28** | Imóveis com rota alternativa podem não ser lidos por nenhuma rota | A rota de leitura é a alternativa, quando houver, senão a da quadra |

CAND-25 e CAND-27 tocam **consumo e valor**: continuam no **oráculo 1** até decisão registrada. Nada foi aprovado. Continuam
pendentes, sem decisão automática: D-17, D-19, CAND-02 e CAND-11 a CAND-24, a leitura final de D-15 e o alcance de D-14 (que
recebeu complemento de evidência: só a retificação por alteração da leitura faturada corrige o consumo faturado).

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§24, §12–§14) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/faturamento.md` (FAT-001, FAT-002, FAT-003, FAT-007) · `testes/cenarios/micromedicao.md` (MIC-001, MIC-002,
MIC-004) · `testes/cenarios/cadastro-atendimento.md` (CAD-004, CAD-005) · `testes/cenarios-criticos.md` §11 ·
`testes/estrategia-testes.md` · `compatibilidade/divergencias-aprovadas.md` (D-14, estado) · `modulos/micromedicao.md` ·
`modulos/faturamento.md` · `modulos/cadastro.md` · `modulos/batch.md` · `alteracoes/README.md` ·
`ambiente-referencia/baselines/README.md`. **Código das ferramentas**: `baselines/ferramentas/executor.py`,
`baselines/ferramentas/roteiros.py`, `scripts/baseline.sh`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 5e capturado: **23/23** variações com as duas execuções idênticas, **23/23** conferidas
numa verificação independente e os lotes 5, 5b, 5c, 5d e o piloto de novo **55/55** (uma variação reverificada por ter
atravessado a meia-noite local — limite da ferramenta, F2-114). **145** baselines; P0 da classe A **26 de 42** (o lote
aprofunda cenários já cobertos e cobre MIC-004 e CAD-005, que não são P0 da classe A). CAND-25 a CAND-28 aguardam decisão.
Próximo lote: **6 — Arrecadação**; MIC-005 (análise de leitura, pela tela) e a baseline de performance seguem pendentes.
