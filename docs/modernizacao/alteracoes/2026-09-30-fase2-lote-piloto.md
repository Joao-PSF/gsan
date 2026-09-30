# [2026-09-30] Fase 2 — classificação dos cenários, mecanismo de baselines e lote piloto

> Primeira execução da Fase 2. **Não implementa o OpenGSAN** e **não altera o legado**: classifica os 103 cenários,
> constrói o mecanismo de captura/verificação de baselines e captura o lote piloto. A Fase 2 **continua em andamento**.

- **Motivo**: plano de trabalho, Fase 2 — *"baseline funcional automatizada"*; critério de aceite *"rodadas repetidas
  produzem resultados idênticos; cobre os comportamentos priorizados"*.
- **Impacto**: novo `ambiente-referencia/baselines/` (ferramentas, massas, cenários executáveis, baselines);
  `scripts/baseline.sh` e `scripts/estado-base.sh`; o passo `banco` da Fase 1 passa a parar o JBoss no início e a
  congelar os modelos `gsan_*_ref` no fim; `verificar.sh` confere os modelos (23 verificações). Nenhuma linha do código,
  dos mapeamentos, dos JSPs ou das migrações do legado alterada.
- **Dependências**: ambiente da Fase 1; nenhum download novo.
- **Testes**: `baseline.sh capturar --lote piloto` (2 execuções idênticas por variação a partir do estado limpo) e
  `baseline.sh verificar --lote piloto` (3ª execução, comparada); `caracterizacao.py verificar` e `cobertura.py verificar`.
- **Risco**: baixo (laboratório isolado, massa 100% sintética, sem segredo). **Rollback**: `git revert`;
  `referencia.sh recriar-banco --sim` refaz banco e modelos. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

`master` = `origin/master` = `7425c23` (Fase 1). Ambiente em execução com 22/22 verificações. Nenhum trabalho local.

## 2. Entregas

| Entrega | Onde |
| ------- | ---- |
| Classificação A/B/C/N dos 103 cenários, por script | [`testes/fase2/matriz-caracterizacao.md`](../testes/fase2/matriz-caracterizacao.md) |
| Mecanismo de captura e verificação | [`ambiente-referencia/baselines/`](../../../ambiente-referencia/baselines/README.md) |
| Massa sintética base + 5 deltas | `ambiente-referencia/baselines/massas/` |
| Lote piloto: CEN-CAD-003, CEN-FAT-001, CEN-FAT-002 — 11 baselines | `ambiente-referencia/baselines/golden/` |
| Relatório, cobertura (gerada) e estratégia de testes atualizada | [`testes/fase2/`](../testes/fase2/fase2-caracterizacao-baselines.md), [`estrategia-testes.md`](../testes/estrategia-testes.md) |

## 3. Achados

Ver [relatório §11](../testes/fase2/fase2-caracterizacao-baselines.md#11-achados). Os que respondem dúvidas abertas das
especificações, como consistência ao centavo dos valores capturados: faixas aplicadas **por economia** (CEN-FAT-001) e
proporção entre vigências **por dias corridos** (CEN-FAT-002). Verificação: 11/11 `CONFERE` numa 3ª execução; teste
negativo (baseline adulterada em 1 centavo) acusado; ambiente com 23/23 verificações.

## 4. Documentos

**Criados**: [`testes/fase2/fase2-caracterizacao-baselines.md`](../testes/fase2/fase2-caracterizacao-baselines.md) ·
[`testes/fase2/matriz-caracterizacao.md`](../testes/fase2/matriz-caracterizacao.md) (gerado) ·
[`testes/fase2/cobertura-baselines.md`](../testes/fase2/cobertura-baselines.md) (gerado) ·
[`ambiente-referencia/baselines/README.md`](../../../ambiente-referencia/baselines/README.md) · este registro.
**Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) · `testes/estrategia-testes.md`
(cenário × massa × baseline × execução; testes parametrizados; massa) · `testes/cenarios-criticos.md` §15, §18 ·
especificações CEN-CAD-003, CEN-FAT-001 e CEN-FAT-002 (campo *Baseline concreta*) · `ambiente-referencia/README.md` ·
`alteracoes/README.md`.

## 5. Veredito

**FASE 2 — EM ANDAMENTO.** Classificação, mecanismo e piloto prontos, com determinismo comprovado; a cobertura dos
comportamentos priorizados e a baseline de performance são dos próximos lotes. Próximo lote: **autenticação e
autorização**.
