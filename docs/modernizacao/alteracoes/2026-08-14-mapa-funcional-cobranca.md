# [2026-08-14] Mapa funcional da Cobrança (item 2 do backlog da Fase 0)

- **Atividade**: análise funcional da Cobrança (estoque e elegibilidade, documento de cobrança, ações, comandos, parcelamento/desfazer/reparcelamento, descontos, corte/religação, negativação, prescrição, terceirização, responsabilidade do cliente, estados) com evidências de código, mapeamentos, constantes e DDL. Nenhuma implementação realizada.
- **Documentos criados**: `docs/modernizacao/modulos/cobranca.md`.
- **Documentos alterados**: `modulos/faturamento.md` (dúvida 4 — retidas/revisão — parcialmente resolvida), `dominio/glossario.md` (termo Cobrança precisado), `modulos/README.md`, `docs/modernizacao/README.md` (sumário), `MODERNIZACAO_GSAN.md` (status/backlog — próxima atividade: arrecadação).
- **Principais descobertas**: a cobrança não cria dívida — o estoque nasce por consulta (`obterDebitoImovelOuCliente`, por imóvel **ou** cliente+papel) sobre as **identidades estáveis `*Geral`**; o Documento de Cobrança materializa a ação com **itens rastreáveis por dívida** (ContaGeral/débito/guia/crédito/prestação de contrato, valor e situação); as ações formam **workflow parametrizado** (predecessora, critério, situações-alvo, tipo de OS); elegibilidade paramétrica (`cobranca_criterio_linha`); parcelamento preserva a composição original por item + memória financeira integral (valores, acréscimos e 4 famílias de desconto), com **desfazimento automático por entrada não paga** e estornos de desconto tipificados (2441/2442); reparcelamento encadeado com contadores e funções de verificação no banco; negativação por cliente com comandos e critérios (situações 11–15 no imóvel); religação executada pelo próprio controlador de cobrança; terceirização por carteira de contas; conta em revisão tratada à parte nas consultas; "contas retidas" segue sem funcionalidade nomeada (dúvida).
- **Cenários de caracterização**: 14 casos registrados.
- **Dependências**: nenhuma.
- **Testes**: n/a (documental).
- **Risco**: baixo.
- **Rollback**: `git revert` do commit.
