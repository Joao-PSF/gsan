# [2026-08-14] Mapa funcional do módulo Cadastro (item 2 do backlog da Fase 0)

- **Atividade**: análise funcional do Cadastro (imóvel, cliente, cliente×imóvel, economia, categorias, ligações, território, endereço, estados) com evidências de código, mapeamentos, FKs, constantes e comentários do banco. Nenhuma implementação realizada.
- **Documentos criados**: `docs/modernizacao/modulos/cadastro.md`.
- **Documentos alterados**: `docs/modernizacao/dominio/glossario.md` (dúvidas 1, 2 e 6 resolvidas com evidência; 8 parcialmente; observação do termo Economia), `docs/modernizacao/README.md` (sumário), `MODERNIZACAO_GSAN.md` (status, concluído, backlog — próxima atividade: micromedição).
- **Principais descobertas**: matrícula = `imov_id` estável + DV módulo 11 (com variante CAERN); economia governada pela agregação `imovel_subcategoria` (individualização `imovel_economia` é informativa; `conta_categoria` fotografa); situação de ligação **paramétrica** (`ligacao_agua_situacao` com flags de faturamento/consumo mínimo — "regra como dado"); ligação criada copiando o id do imóvel (extensão 1:1 intencional); conta fotografa situações + percentual de esgoto; três rotas com usos distintos (quadra=campo/território, entrega=contas, alternativa=leitura móvel); situação derivada do imóvel (ativo/inativo/só esgoto) por tabela paramétrica, usada pelo atendimento; OS encerrada retroalimenta a situação das ligações; 123 FKs → `cadastro.imovel`.
- **Dependências**: nenhuma.
- **Testes**: n/a (documental).
- **Risco**: baixo.
- **Rollback**: `git revert` do commit.
