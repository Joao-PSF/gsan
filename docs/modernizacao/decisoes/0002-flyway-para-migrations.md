# ADR-0002 — Flyway como ferramenta de migrations

- **Status: Aceita** · Data: 2026-08-13 · **Formalizada em 2026-09-14**

> **Histórico**: permaneceu em *Proposta* por engano — a decisão já governava o planejamento do banco desde 2026-08-13. Formalizada com a justificativa comparativa explicitada e uma premissa residual corrigida (menção a "equipe DBA", inexistente neste projeto).

## Contexto
O GSAN versiona banco com MyBatis Migrations (`gsan-migracoes`, 301 scripts, parado em 2024-06) e o `gsan_comercial` prova que instalações reais acumulam DDL manual sem migration (objetos até 2026, ex.: PIX). O SISAN precisa de disciplina única de versionamento desde o primeiro dia. *(Revisado em 2026-08-13: sem produção neste projeto, não existe "baseline do DDL real" a congelar.)*

## Decisão
Adotar **Flyway** (SQL puro, integração nativa com Spring Boot, versionamento linear simples). O schema do SISAN nasce versionado desde `V1`, construído pelas decisões de compatibilidade (ADR-0006) — **sem baseline copiada do `gsan_comercial`**. O histórico MyBatis permanece em `gsan-migracoes` como referência de evolução do legado. Toda alteração estrutural do SISAN passa por migration.

## Consequências
- (+) Migrations em **SQL puro** — legível por quem conhece o banco, sem camada de tradução XML/DSL entre a intenção e o que executa. Importa aqui porque o schema do SISAN nasce de decisões de compatibilidade caso a caso (ADR-0006), e cada migration precisa ser auditável contra a estrutura legada correspondente.
- (+) Validação de **checksum** detecta edição manual de script já aplicado — resposta direta ao problema comprovado no legado (drift: objetos no `gsan_comercial` até 2026 sem migration correspondente, migrations paradas em 2024-06).
- (+) Integração nativa com Spring Boot: versionamento verificado no boot, coerente com ADR-0001.
- (−) Sem rollback automático — cada migration relevante documenta rollback manual no registro de alterações (já era a prática exigida pelo projeto).

## Alternativas consideradas
| Alternativa | Avaliação |
| ----------- | --------- |
| **Liquibase** | Mais recursos: changelog em XML/YAML/JSON, *rollback* declarativo, abstração entre bancos. **Rejeitada** porque nenhuma dessas vantagens é necessária aqui — o SISAN tem um só banco alvo (PostgreSQL 18, ADR-0004), e a abstração multi-banco cobra complexidade permanente por um benefício que não será usado. O rollback declarativo cobre bem DDL simples e mal a migração de dados, que é onde estaria o valor |
| **MyBatis Migrations** (o que o legado usa) | **Rejeitada**: projeto pouco mantido, sem integração com Spring Boot, e comprovadamente insuficiente na prática — é a ferramenta sob a qual o drift do `gsan_comercial` aconteceu |
| **DDL versionado à mão / scripts numerados** | **Rejeitada**: é exatamente o que produziu o estado atual do banco legado. Sem checksum nem controle de aplicação, o drift é questão de tempo |
| **Hibernate `ddl-auto`** | **Rejeitada categoricamente**: schema derivado de entidade é incompatível com um projeto cujo schema resulta de decisões explícitas de compatibilidade (ADR-0006), e inaceitável em base financeira |

## Rollback
Flyway entra em vigor com a `V1` do SISAN; reverter a decisão antes disso não tem custo. Nenhuma migração destrutiva sem script de desfazer testado em ambiente de homologação.
