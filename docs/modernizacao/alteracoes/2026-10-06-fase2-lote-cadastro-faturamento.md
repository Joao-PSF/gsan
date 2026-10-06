# [2026-10-06] Fase 2 — lote 3: cadastro e faturamento online

> Quarto lote de baselines da Fase 2. **Não implementa o OpenGSAN** e **não altera o legado**. A Fase 2 **continua em
> andamento**.

- **Motivo**: o item 2 da [ordem de captura](../testes/estrategia-testes.md#priorização-da-baseline-fase-2) que roda
  online — identidade e vínculos do imóvel, faturabilidade pela situação da ligação, esgoto —, reaproveitando a massa e
  as fronteiras do piloto.
- **Impacto**: 4 definições executáveis (`CEN-CAD-001`, `CEN-CAD-002`, `CEN-CAD-004`, `CEN-FAT-003`), 9 deltas de massa,
  16 baselines em `golden/cadastro/` e `golden/faturamento/`; dois roteiros novos (consulta de várias matrículas;
  Consultar Relação Cliente e Imóvel); a simulação distingue "nada faturável" de recusa; `baseline.sh` nomeia a
  variação cuja massa o banco recusou. Nenhuma linha do legado alterada.
- **Dependências**: nenhum download novo.
- **Testes**: captura com 2 execuções idênticas por variação; verificação independente do lote e regressão do piloto;
  `caracterizacao.py verificar`, `cobertura.py verificar`.
- **Risco**: baixo (laboratório, dados sintéticos). **Rollback**: `git revert`. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `11ddb97` (Segurança restante). Cobertura: 9 de 42 P0 da classe A; 45 baselines.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| CEN-CAD-001 (V1–V3), CEN-CAD-002 (V1–V4), CEN-CAD-004 (V1–V7), CEN-FAT-003 (V1, V1b) — 16 baselines | `ambiente-referencia/baselines/golden/` |
| Achados F2-37 a F2-43; F2-29 numa 2ª superfície | [relatório §18](../testes/fase2/fase2-caracterizacao-baselines.md#18-lote-3--cadastro-e-faturamento-online-2026-10-06) |
| Replanejamento: CAD-005, FAT-011 e FAT-003 V2/V3 para o lote batch, com evidência; CAD-002 entra | [relatório §18.1](../testes/fase2/fase2-caracterizacao-baselines.md#181-cenários-selecionados) |
| Cobertura (gerada): **12 de 42** P0 da classe A | [`cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) |

## 3. O que pede atenção

- **Bloqueio novo — F2-42**: a semântica do valor 4 da situação de água e a completude de `imovel_situacao` só existem
  em **dado de instalação**; a base reconstruída não tem nenhum dos dois e a Fase 2 não usa dado real. O cenário fica
  🟡 em parte até que um dado de instalação **autorizado e anonimizado** exista — decisão do responsável.
- **F2-41 — borda do mínimo**: a validação da simulação recusa consumo **igual** ao mínimo da situação ("menor que…"),
  enquanto o cálculo o aceitaria. Comportamento registrado na baseline; o OpenGSAN precisa escolher conscientemente.
- Nenhum candidato a divergência novo.

## 4. Documentos

**Criados**: este registro. **Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) ·
`testes/fase2/fase2-caracterizacao-baselines.md` (§18, §12–§15) · `testes/fase2/cobertura-baselines.md` (gerado) ·
`testes/cenarios/cadastro-atendimento.md` (CAD-001, 002, 004, 005) · `testes/cenarios/faturamento.md` (FAT-003, 011) ·
`testes/estrategia-testes.md` · `alteracoes/README.md`. **Código das ferramentas**: `baselines/ferramentas/roteiros.py`, `scripts/baseline.sh`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Lote 3 capturado com determinismo (16/16 idênticas); verificação independente **16/16** e regressão do piloto **11/11**. P0 da classe A: 9 → **12 de 42**.
Próximo lote recomendado: **4 — Atendimento** (ATE-007/008 P0, MIC-002, SEG-008, e a parte de CAD-004 que depende de
RA) — o ciclo RA → OS é a dependência comum de quatro cenários.
