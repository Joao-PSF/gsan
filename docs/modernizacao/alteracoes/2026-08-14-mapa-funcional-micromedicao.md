# [2026-08-14] Mapa funcional da Micromedição (item 2 do backlog da Fase 0)

- **Atividade**: análise funcional da Micromedição (hidrômetro/instalação, ciclo de leitura, anormalidades, consumo, média, casos especiais, fronteiras com Cadastro/Faturamento/OS) com evidências de código, mapeamentos, constantes e DDL. Nenhuma implementação realizada.
- **Documentos criados**: `docs/modernizacao/modulos/micromedicao.md`.
- **Documentos alterados**: `docs/modernizacao/modulos/cadastro.md` (dúvida 3 — precedência de rotas — resolvida), `docs/modernizacao/dominio/glossario.md` (ponto 6 concluído), `docs/modernizacao/README.md` (sumário), `MODERNIZACAO_GSAN.md` (status/backlog — próxima atividade: faturamento).
- **Principais descobertas**: equipamento × instalação separados, com leituras de fronteira na instalação (base do mês de troca); histórico mensal pertence ao imóvel+referência (troca não rompe série); par informado × faturamento em leituras/anormalidades; anormalidades de leitura e de consumo são **paramétricas** (ações com/sem leitura, OS automática, fatores e cartas por mês de reincidência); consumo com origem tipificada (real/média/mínimo/rateio) e três valores mensais (faturado, p/ média, medido); virada tratada por nº de dígitos; média multiuso (faturar, criticar, faixa esperada/antifraude); ciclo dirigido por cronograma do grupo (8 atividades com datas por rota); **rota alternativa sobrepõe a da quadra** na leitura; variantes de controlador por companhia (CAEMA/CAERN/COMPESA/COSANPA/...); evoluções no `gsan_comercial`: telemetria, releitura mobile, fotos de leitura, histórico de versões anteriores.
- **Cenários de caracterização**: 12 casos registrados (troca, virada, média, sem hidrômetro, reincidência de anormalidade, rateio de condomínio etc.).
- **Dependências**: nenhuma.
- **Testes**: n/a (documental).
- **Risco**: baixo.
- **Rollback**: `git revert` do commit.
