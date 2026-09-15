# Módulos — Ordem de Migração e Status

**Mapas funcionais concluídos (Fase 0 — todos)**: [cadastro](cadastro.md) · [micromedicao](micromedicao.md) · [faturamento](faturamento.md) · [cobranca](cobranca.md) · [arrecadacao](arrecadacao.md) · [atendimento](atendimento.md) · [seguranca](seguranca.md) · [batch](batch.md) · [relatorios](relatorios.md) · [integracoes](integracoes.md).

⚠️ Mapa concluído **não é** especificação pronta para implementar: cada um lista dúvidas abertas, e a especificação dos cenários críticos é item do fechamento da Fase 0 (ver [`estrategia-testes.md`](../testes/estrategia-testes.md)).

**Além dos dez mapas**, esta pasta contém o [catálogo de funcionalidades futuras](funcionalidades-futuras.md) (2026-09-15) — 26 capacidades descobertas no legado que **não são módulos** e não estão na tabela abaixo. ⚠️ Ele levanta uma pergunta que a ordem atual não responde: o **portal de autoatendimento** (47 classes, sem dono em nenhum módulo) é candidato a capacidade própria e depende da ADR-0007.

Ordem recomendada (refinamento é a **próxima atividade** do backlog da Fase 0, com base nos mapas funcionais, no mapa de domínio e no catálogo de funcionalidades futuras; mudanças de ordem devem registrar o motivo aqui). Critério: começar por risco moderado e dependências simples; faturamento e arrecadação por último entre os críticos (risco financeiro); batch crítico ao final.

| # | Módulo | Justificativa | Status |
| - | ------ | ------------- | ------ |
| 1 | Cadastros auxiliares (tabelas de apoio de `cadastro`/`seguranca`) | CRUD simples, valida stack ponta a ponta com risco baixo | Pendente |
| 2 | Consultas (imóvel, cliente, débitos — somente leitura) | Sem escrita; exercita mapeamento do schema real e desempenho | Pendente |
| 3 | Atendimento (registro de atendimento/RA) | Risco moderado, alto valor para usuários; candidato a **piloto (Fase 6)** junto com o item 1 | Pendente |
| 4 | Ordens de serviço | Encadeia com atendimento; integra mobile | Pendente |
| 5 | Micromedição (leituras, consumo, média) | Alimenta faturamento; regras bem delimitadas | Pendente |
| 6 | Cobrança (ações, parcelamento, negativação) | Financeiro, mas com janelas de correção maiores que faturamento | Pendente |
| 7 | Arrecadação (retornos bancários, baixas, devoluções) | Crítico financeiro — só após maturidade da plataforma | Pendente |
| 8 | Faturamento (cálculo de contas, tarifas, créditos/débitos) | Núcleo financeiro de maior risco | Pendente |
| 9 | Batch críticos (faturamento/arrecadação em lote, resumos) | Último estágio; Spring Batch substituindo EJB/MDB/Quartz 1.5 | Pendente |
| — | Transversais: seguranca (Fase 5), relatorios (contínuo, por módulo), integracoes (junto ao módulo dono — mas a **camada** de integração é fundação, pois o GSAN não tem uma: ver [integracoes.md §1](integracoes.md)), fiscal/SPED (junto a faturamento/financeiro) | — | Pendente |

## Regras

1. Nenhum módulo entra em implementação sem documento próprio em `docs/modernizacao/modulos/<modulo>.md` descrevendo comportamento atual, dependências, tabelas, regras de negócio e resultado esperado (sequência de trabalho: analisar → documentar → dependências → resultado esperado → testes → implementar → comparar → validar segurança → validar performance → documentar).
2. Módulo só é considerado concluído no OpenGSAN após: equivalência comprovada com o GSAN de referência (testes de caracterização, comparação semântica via mapeamento) e validação em ambiente de homologação (VPS). Critérios adicionais de produção (validação por usuários reais, logs estáveis, rollback operacional) aplicam-se quando existir companhia operando o OpenGSAN.
3. Este arquivo é atualizado a cada mudança de status.
