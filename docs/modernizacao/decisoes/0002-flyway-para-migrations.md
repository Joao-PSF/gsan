# ADR-0002 — Flyway como ferramenta de migrations

- Status: Proposta · Data: 2026-08-13

## Contexto
O GSAN versiona banco com MyBatis Migrations (`gsan-migracoes`, 301 scripts, parado em 2024-06) e o `gsan_comercial` prova que instalações reais acumulam DDL manual sem migration (objetos até 2026, ex.: PIX). O SISAN precisa de disciplina única de versionamento desde o primeiro dia. *(Revisado em 2026-08-13: sem produção neste projeto, não existe "baseline do DDL real" a congelar.)*

## Decisão
Adotar **Flyway** (SQL puro, integração nativa com Spring Boot, versionamento linear simples). O schema do SISAN nasce versionado desde `V1`, construído pelas decisões de compatibilidade (ADR-0006) — **sem baseline copiada do `gsan_comercial`**. O histórico MyBatis permanece em `gsan-migracoes` como referência de evolução do legado. Toda alteração estrutural do SISAN passa por migration.

## Consequências
- (+) Migrations em SQL puro (equipe DBA participa sem aprender XML/DSL); validação de checksum detecta edição manual; integra ao pipeline e ao boot da aplicação.
- (−) Sem rollback automático — cada migration relevante documenta rollback manual no registro de alterações (já era a prática exigida pelo projeto).

## Alternativas consideradas
Liquibase (mais recursos — changelogs XML/YAML, rollback declarativo — porém mais complexo; o time já trabalha em SQL puro no MyBatis Migrations, e a simplicidade pesa mais aqui); manter MyBatis Migrations (rejeitada: projeto pouco mantido, sem integração Spring Boot, e já falhou em capturar o drift).

## Rollback
Flyway entra em vigor com a `V1` do SISAN; reverter a decisão antes disso não tem custo. Nenhuma migração destrutiva sem script de desfazer testado em ambiente de homologação.
