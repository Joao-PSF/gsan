# [2026-08-14] Glossário de domínio (item 1 do backlog da Fase 0)

- **Motivo**: executar a próxima atividade definida no backlog — estabelecer linguagem comum para as análises da Fase 0.
- **Impacto**: novo documento `docs/modernizacao/dominio/glossario.md` com os 20 conceitos estruturantes + 5 acrescentados por serem indispensáveis (Categoria/Subcategoria, Grupo de Faturamento, Referência AAAAMM, Guia de Pagamento, Parcelamento); mapa textual de relações do domínio; 9 pontos que exigem aprofundamento. Sumário e `MODERNIZACAO_GSAN.md` atualizados. Nenhuma alteração de código ou banco.
- **Método**: cada termo definido por evidência — classe Java + mapeamento `.hbm.xml` (tabela real) + FKs/constantes/comentários de coluna do banco. Nenhuma definição inventada a partir do nome. Termos GSAN preservados (ADR-0005).
- **Descobertas relevantes**: Economia não possui entidade própria (tripla representação); ligações de água/esgoto são extensões 1:1 do imóvel (FK `lagu_id`/`lesg_id` → `imov_id`) com situação armazenada no imóvel; mecanismo `*_geral`/`*_historico` como espinha de retificação/pagamento; pagamento com 5 alvos possíveis; constante ambígua `LIGADO_A_REVELIA`=`LIGADO_EM_ANALISE`=4; nomenclatura de companhia no núcleo (`numeroCelpe`).
- **Dependências**: nenhuma.
- **Testes**: n/a (documental).
- **Risco**: baixo.
- **Rollback**: `git revert` do commit.
