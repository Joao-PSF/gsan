# ADR-0002 — Flyway como ferramenta de migrations

- Status: Proposta · Data: 2026-08-13

## Contexto
O banco é versionado hoje por MyBatis Migrations (`gsan-migracoes`, 301 scripts, parado em 2024-06) e há drift: objetos criados em produção até 2026 sem migration. É preciso uma baseline nova e disciplina única de versionamento durante a coexistência legado+novo.

## Decisão
Adotar **Flyway** (SQL puro, integração nativa com Spring Boot, modelo simples de versionamento linear + `baseline`). Baseline `V1__baseline.sql` gerada do DDL real de produção após reconciliação do drift. Histórico MyBatis arquivado como referência. Toda alteração estrutural futura — inclusive as feitas para o legado — passa pelo repositório de migrations Flyway.

## Consequências
- (+) Migrations em SQL puro (equipe DBA participa sem aprender XML/DSL); validação de checksum detecta edição manual; integra ao pipeline e ao boot da aplicação.
- (−) Sem rollback automático — cada migration relevante documenta rollback manual no registro de alterações (já era a prática exigida pelo projeto).

## Alternativas consideradas
Liquibase (mais recursos — changelogs XML/YAML, rollback declarativo — porém mais complexo; o time já trabalha em SQL puro no MyBatis Migrations, e a simplicidade pesa mais aqui); manter MyBatis Migrations (rejeitada: projeto pouco mantido, sem integração Spring Boot, e já falhou em capturar o drift).

## Rollback
Flyway só entra em vigor a partir da baseline; reverter = voltar a aplicar SQL manualmente (situação atual). Nenhuma migração destrutiva sem script de desfazer testado em homolog.
