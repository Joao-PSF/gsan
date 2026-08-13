# Migração PostgreSQL — Estratégia

Projeto próprio dentro da modernização (Fase 8), com preparação iniciando na Fase 0/1. Alvo: PostgreSQL 18.x (18.6+ em 2026-08; PG 14 sai de suporte em 2026-11).

## Pré-requisitos (Fase 0/1)

1. Confirmar no banco real: `SELECT version()`, encoding/collation efetivos (`\l+`), locale do SO, tamanho da base, tablespaces, roles e GRANTs (ausentes no DDL exportado), configurações não padrão (`postgresql.conf`), jobs externos (cron/pgAgent), replicação existente, uso de large objects.
2. Inventariar consumidores diretos do banco além do GSAN (BI "roger", `gsan_olap`, dblink de/para outras bases — o `admindb.db_versao_sincronismo` sugere sincronismo entre bases).
3. Congelar inventário de funções C antigas a substituir por extensões: `dblink`, `pg_trgm`, `plpgsql_call_handler`.

## Incompatibilidades já conhecidas com PG 18

| Item | Tratamento |
| ---- | ---------- |
| Funções C de contrib pré-extensão (`dblink`, `pg_trgm`) | Não restaurar; recriar com `CREATE EXTENSION dblink; CREATE EXTENSION pg_trgm;` e revalidar objetos dependentes (114 referências a dblink; índices trgm) |
| `public.plpgsql_call_handler` | Descartar (PL/pgSQL é nativo) |
| `oid`/large objects (7 usos) | Validar `pg_largeobject` no dump/restore (`--large-objects`) |
| Encoding LATIN1 | Manter LATIN1 na primeira migração (ADR-0004) para reduzir variáveis; conversão UTF-8 avaliada em etapa posterior |
| Collation (glibc/ICU mudam entre SOs) | Restore reconstrói índices, sem risco de corrupção; ordenações de relatórios podem mudar — validar nas consultas críticas |
| Sintaxe antiga em 46 views/62 funções SQL+PL/pgSQL | Testar recriação uma a uma em homolog; corrigir o que falhar |

## Estratégia recomendada: dump/restore com janela controlada

- `pg_upgrade` é inviável: salto de muitas versões, exige binários antigos e falharia nas contribs pré-extensão.
- Replicação lógica nativa exige origem ≥ 10 (a confirmar; sinais apontam origem 8.x/9.x) — se a origem confirmar ≥ 9.4, avaliar `pglogical`/híbrido para reduzir downtime.
- Padrão: `pg_dump -Fc` (schema + dados) da produção → restore em homolog PG 18 → correções scriptadas e idempotentes → ensaio completo cronometrado (define a janela real) → repetição do procedimento em produção com freeze de escrita.

## Bateria de validação (obrigatória antes do corte)

1. **Schema**: diff de objetos (tabelas, colunas, tipos, constraints, índices, sequences, views, matviews, funções, triggers, permissões) origem × destino.
2. **Dados**: contagem de registros por tabela (100%); checksums por amostragem em tabelas grandes; posição das sequences ≥ `max(id)`.
3. **Financeiro (tolerância zero)**: somatórios por competência de contas, pagamentos, devoluções, créditos, débitos, parcelamentos e saldos; contagens de hidrômetros, leituras e OS.
4. **Funcional**: execução em homolog de faturamento de um grupo, arrecadação (retorno bancário), cobrança, parcelamento, relatórios críticos e batch — comparando resultados com a produção da mesma competência.
5. **Performance**: `EXPLAIN ANALYZE` das consultas críticas catalogadas; tempos de batch; ajuste de `postgresql.conf` para hardware novo; `ANALYZE` completo pós-restore.

## Rollback

Servidor de origem permanece intocado e desligado para escrita durante a janela; rollback = religar a origem. Nenhuma escrita nova no destino antes do "go" final. Registrar o ponto de corte (última transação) para auditoria.

## Versionamento do banco (Fase 0 em diante)

- Ferramenta: **Flyway** (ADR-0002). Baseline `V1__baseline.sql` gerada do DDL real de produção após reconciliação do drift com `gsan-migracoes`.
- Histórico MyBatis Migrations arquivado como referência (somente leitura).
- Regra: nenhuma alteração estrutural sem migration; alterações emergenciais em produção devem gerar migration retroativa em até 1 dia útil.
- Contas de banco: manter/reativar a segregação já prevista (`gsan_online`, `gsan_batch`, `gsan_olap`, `gsan_dba`) com menor privilégio real por schema, após rotação de senhas (ver segurança).
