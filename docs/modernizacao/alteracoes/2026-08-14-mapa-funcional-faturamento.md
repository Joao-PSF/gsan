# [2026-08-14] Mapa funcional do Faturamento (item 2 do backlog da Fase 0)

- **Atividade**: análise funcional do Faturamento (ciclo FATURAR_GRUPO, faturabilidade, consumo utilizado, mínimos, tarifa, água/esgoto, débitos/créditos, Conta/ContaGeral/histórico, retificação, cancelamento, vencimento, precisão financeira, variações por companhia) com evidências de código, mapeamentos, constantes e DDL. Nenhuma implementação realizada.
- **Documentos criados**: `docs/modernizacao/modulos/faturamento.md`.
- **Documentos alterados**: `modulos/micromedicao.md` (dúvidas 2 e 3 resolvidas), `modulos/cadastro.md` (dúvida 5 resolvida), `dominio/glossario.md` (pontos 4 e 9 resolvidos; termo Conta atualizado), `modulos/README.md` (mapas concluídos), `docs/modernizacao/README.md` (sumário), `MODERNIZACAO_GSAN.md` (status/backlog — próxima atividade: cobrança).
- **Principais descobertas**: `gerarConta` é o cálculo único usado no lote (unidade = rota do cronograma) e no individual — base ideal de golden master; o Faturamento decide faturabilidade (flags paramétricos) mas **não regrava consumo** (fronteira limpa com a Micromedição); consumo mínimo = Σ por categoria (mínimo da tarifa vigente × economias), calculado pela Micromedição; tarifa versionada por vigência (mudança não afeta o passado — conta fotografa); esgoto por percentuais definidos na ligação (inclusive percentual alternativo acima de limite) fotografados na conta; **ContaGeral é a entidade física da identidade estável** (sequence + indicadorHistorico, 1:1 com conta corrente/histórica/impressão) — pagamentos apontam para ela; retificação cria nova conta encadeada por origem; cancelamento é transição de estado com motivo (inclusive prescrição); arquivamento em batches de encerramento mensal; arredondamento HALF_UP centralizado em `Util` (consumo em m³ inteiro, moeda escala 2); variação por companhia em três camadas (parâmetro, subclasses SEJB, métodos `*CAER` no núcleo).
- **Golden masters**: 13 cenários financeiros críticos registrados.
- **Dependências**: nenhuma.
- **Testes**: n/a (documental).
- **Risco**: baixo.
- **Rollback**: `git revert` do commit.
