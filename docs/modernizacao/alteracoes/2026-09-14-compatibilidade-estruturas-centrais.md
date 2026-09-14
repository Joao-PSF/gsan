# [2026-09-14] Análise de compatibilidade das estruturas centrais GSAN → SISAN

- **Motivo**: classificar as estruturas centrais do domínio conforme a ADR-0006, respondendo *o que fazemos com o que existe?* — insumo direto da Visão Conceitual Alvo.
- **Método**: consolidação decisória sobre o mapa de domínio, o glossário, as ADRs 0005/0006, a arquitetura alvo e o registro de divergências. **Nenhuma reanálise de código ou banco.**
- **Testes**: n/a (documental) · **Risco**: baixo · **Rollback**: `git revert` do commit · **Migration**: nenhuma.

## Documento criado

`docs/modernizacao/compatibilidade/estruturas-centrais.md` — 24 seções, **64 decisões estruturais** + 6 famílias não transportadas + 16 famílias paramétricas.

⚠️ O roteiro sugeria 25–50 decisões; ficou em 64. Não reduzi artificialmente: são dez áreas, e agrupar estruturas com classificações diferentes esconderia a decisão (`FAT-02` e `FAT-03` são o mesmo mecanismo físico, mas a semântica de uma é inegociável e a da outra não).

## Distribuição das classificações

⚠️ **12 decisões têm classificação dupla** (semântica × estrutura, ou domínio × integração) — por isso a distinção entre primária e "tocam".

| Classificação | Primária | Tocam | Leitura |
| ------------- | -------: | ----: | ------- |
| **PRESERVAR** | 37 | 37 | O GSAN acertou mais do que errou |
| **REESTRUTURAR** | 14 | 15 | Acoplamento real, com justificativa completa |
| **MODERNIZAR** | 6 | 11 | Conceito correto, problema técnico pequeno |
| **EXIGE APROFUNDAMENTO** | 5 | 6 | Recusa honesta a classificar sem evidência |
| **NÃO TRANSPORTAR** | 2 | 7 | Infraestrutura morta, mecanismos inadequados, artefatos (+6 famílias) |

Por área: **Faturamento é o mais preservado em proporção** (7 de 10), apesar de ser o de maior risco financeiro — onde há dinheiro, o modelo do legado é bom. **Cadastro** concentra reestruturações porque o Imóvel acumulou estado de outros domínios e a Economia ficou sem forma explícita. **Integrações** tem metade das decisões reestruturando — é a única área onde a camada não existe.

## As decisões que mais importam

| # | Decisão | Por quê |
| - | ------- | ------- |
| 1 | **Identidade estável de documento** — semântica `PRESERVAR` **inegociável**, estrutura (`*Geral` + tabelas-espelho) `REESTRUTURAR` | Errar quebra pagamento, cobrança e parcelamento de contas retificadas ou arquivadas |
| 2 | **Precisão financeira — `PRESERVAR`** | As cinco políticas de arredondamento **são comportamento de negócio**, não dívida técnica. Unificá-las altera valores cobrados do cliente |
| 3 | **Snapshots da Conta — `PRESERVAR`** | Parecem desnormalização; são requisito de auditoria retroativa. Remover destrói a reprodutibilidade de contas antigas, e o sintoma aparece meses depois |
| 4 | **Abrangência territorial** — conceito `PRESERVAR`, aplicação `REESTRUTURAR` | Hoje depende de chamada manual em cada consulta; herdar isso é herdar vazamento por omissão (LGPD) |
| 5 | **Regra como dado** — 16 famílias paramétricas, **nenhuma descartada** | Transformá-las em `enum` converte configuração operacional em deploy |

## Decisões que exigiram separar semântica de estrutura

Onze decisões têm o formato "preservar a semântica, reestruturar a representação" — o caso mais comum do documento e a fonte mais provável de erro se confundido:

- Identidade estável (`FAT-02`) · arquivamento (`FAT-03`) · identidade do pagamento (`ARR-04`) · situações do pagamento (`ARR-03`) · abrangência (`SEG-03`) · concessão por URL (`SEG-02`) · auditoria (`SEG-05`) · contexto de execução (`BAT-03`) · limites de relatório (`REL-01`) · capacidades de integração (`INT-02`) · negativação (`COB-06`).

## Respostas às perguntas do roteiro

| Pergunta | Resposta |
| -------- | -------- |
| *Preservar a semântica 1:1 da ligação exige preservar a PK compartilhada?* | 🔵 **Não** — são decisões diferentes. Cardinalidade vira restrição; a chave é própria (`CAD-08`) |
| *Preservar a tabela `ContaGeral` ou o conceito de identidade estável?* | 🔴 **O conceito, obrigatoriamente.** A tabela existe só para ser fonte de sequence e ponteiro (`FAT-02`) |
| *Duas tabelas físicas continuam sendo a melhor forma de representar versões?* | 🔵 Não — obrigam toda consulta a saber dos dois lugares (`FAT-03`) |
| *A identidade perdida do pagamento é necessidade funcional ou limitação estrutural?* | 🔵 **Limitação estrutural.** Nenhum mapa encontrou razão funcional (`ARR-04`) |
| *Quais estruturas do batch são infraestrutura e quais são semântica?* | 🔵 Modelo de 3 níveis e retomada = semântica (`PRESERVAR`); Quartz/JMS/MDB = transporte (`NÃO TRANSPORTAR`) |

## Análises transversais

- **§15 Parametrização** — 16 famílias classificadas. ⚠️ **Nenhuma é `NÃO TRANSPORTAR`**, o que confirma que "regra como dado" está entre as decisões mais acertadas do GSAN. Falta versionamento em quase todas (a tarifa é a exceção, e a prova de que o problema é conhecido).
- **§16 Histórico/versão/linhagem/snapshot** — os quatro mecanismos classificados **separadamente**, com a razão técnica de não unificá-los: cada um tem regra de escrita, leitura e retenção diferente. Registrada a confusão a evitar (versionamento ≠ linhagem), que este projeto já cometeu e corrigiu.
- **§17 Identificadores** — 12 identificadores com tratamento de migração. **Externo igual**: matrícula do imóvel, nº de série do hidrômetro, RA (é protocolo comunicado ao cliente), login do usuário, semântica AAAAMM. *Legacy id* registrado como **hipótese**, não padrão automático.
- **§18 Não transportar** — 6 famílias, com a nota de que o migrador deve **tolerar objetos extras** (o `gsan_comercial` prova que instalações acumulam DDL fora das migrations).

## Divergência nova

**D-17 (⚠️ PROPOSTA, não aprovada)** — abrangência aplicada sistematicamente. Registrada em seção própria de [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md), separada das aprovadas, porque **altera comportamento visível**: consultas que hoje retornam dados passariam a ser restringidas. É correção, não regressão — mas exige aprovação explícita.

## Itens recusados por falta de evidência

Seis decisões **não foram forçadas**: `UsuarioGrupoRestricao` (define se o modelo tem *deny*), semântica de "Fatura" e da obrigação financeira, cardinalidade física RA↔OS, diferenças entre as variantes por companhia, fórmulas de acréscimos, retenção dos artefatos de relatório. ⚠️ Todas marcadas **BAIXA confiança** e explicitamente fora de uso para orientar implementação.

## Impacto

- **Criado**: `compatibilidade/estruturas-centrais.md`.
- **Atualizados**: `MODERNIZACAO_GSAN.md` (15ª execução; backlog renumerado, Visão Conceitual Alvo como próxima), `docs/modernizacao/README.md`, `compatibilidade/divergencias-aprovadas.md` (seção de propostas).
- **Nenhuma alteração de código, banco ou infraestrutura.** Nenhum nome de tabela, schema, tipo, chave, índice, migration, entidade JPA ou API. Nenhuma hipótese virou ADR. Nenhuma das ~1.800 tabelas classificada individualmente.

## Próxima atividade

**Visão Conceitual Alvo do SISAN** — ainda sem modelo físico.
