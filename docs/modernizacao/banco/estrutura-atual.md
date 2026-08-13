# Banco `gsan_comercial` — Estrutura Atual

Inventário a partir do DDL exportado (fornecido em 2026-08-13, ~4,1 MB, sem GRANTs/privilégios — completar com inventário no banco real).

## Números gerais

| Objeto | Quantidade |
| ------ | ---------- |
| Schemas | 18 |
| Tabelas | 1.838 |
| Sequences | 849 |
| Views | 46 |
| Materialized views | 3 (`cadastro.vw_dados_cadastrais_cliente_imovel`, `public.arrecadacao_roger_bi`, `public.faturamento_roger_bi`) |
| Funções | 116 (56 em C, 46 PL/pgSQL, 14 SQL) |
| Triggers | 4 |
| Índices | 2.371 |
| Foreign keys | 2.940 |

Encoding: LATIN1 (confirmado por `script_char_set=LATIN1` nas migrations e encoding ISO-8859-1 do build). Roles conhecidas: `gsan_admin` (owner), `gsan_batch`, `gsan_dba`, `gsan_olap`, `gsan_online`, `role_users`, `role_aplic`, `postgres`.

## Tabelas por schema

| Schema | Tabelas | Observação |
| ------ | ------- | ---------- |
| public | 833 | Núcleo GSAN + ~212 tabelas de backup/manutenção + views ad hoc de BI/geo |
| atendimentopublico | 202 | RA, OS, execução em campo |
| cadastro | 173 | Imóvel, cliente, localidade |
| cobranca | 157 | Inclui parcelamento, negativação |
| faturamento | 148 | Contas, tarifas, créditos/débitos |
| micromedicao | 70 | Hidrômetros, leituras, consumo |
| seguranca | 53 | RBAC próprio completo |
| arrecadacao | 49 | Pagamentos, avisos bancários, devoluções |
| atualizacaocadastral | 29 | Recadastramento (NIS, tarifa social) |
| financeiro | 27 | Contabilização |
| mobile | 22 | Integração com apps de campo |
| operacional | 15 | — |
| fiscal | 14 | Nota fiscal, tributação (customização) |
| quartz | 12 | Tabelas do Quartz 1.5 |
| batch | 12 | Controle do framework batch próprio |
| admindb | 11 | Rotinas de DBA (backup, vacuum, versão de base) |
| integracao | 10 | SPED, terceiros |
| auxiliarbatch | 1 | — |

## Sinais de versão de origem antiga (era PostgreSQL 8.x)

- `dblink` instalado como ~50 funções C soltas no schema `public` (estilo contrib pré-9.1, antes de `CREATE EXTENSION`); 114 referências no DDL.
- `pg_trgm` idem (`gtrgm_*`, `gin_*_trgm`, `similarity*`, `set_limit`...).
- `public.plpgsql_call_handler` declarado manualmente.
- Nenhum `CREATE EXTENSION` no DDL.

Consequência: um restore direto em PostgreSQL 18 falha nesses objetos; eles devem ser substituídos pelas extensões oficiais (ver [migracao-postgresql.md](migracao-postgresql.md)).

## Classificação preliminar dos objetos

1. **Núcleo oficial GSAN**: schemas de domínio (cadastro, faturamento, arrecadacao, cobranca, micromedicao, atendimentopublico, seguranca, batch, quartz e maior parte do `public`).
2. **Customizações permanentes**: `fiscal` (NF/tributação), `integracao` (SPED, `ti_*`), `mobile`, `atualizacaocadastral` (NIS/Bolsa Água), `admindb`, funções `sp*_gerar_res_*` (resumos de faturamento/arrecadação), `sp1_gerar_cred_pagto_viva_agua`, matviews de BI, views `vw_debito*`/geo, tabela `seguranca.token`.
3. **Históricos/temporários/backup**: ~212 tabelas em `public` com padrões `bkp_*`, `backup_*`, `*_rm<numero>`, `*_20xx`, `atu_fat_sit_especial_*`, `clientes_backup*` etc. — criadas manualmente em manutenções (nomes referenciam RMs e competências até 2026). **Nada será removido**; classificar com o DBA e excluir da modelagem do sistema novo.

## Drift identificado (crítico)

- `gsan-migracoes` (MyBatis Migrations): 301 scripts `comercial`, último de 2024-06; 5 `gerencial`.
- O DDL real contém objetos criados após isso (nomes com competências 2025/2026), logo **existe DDL aplicado em produção sem migration correspondente**.
- O schema `admindb` possui controle próprio de "versão de base" (`vw_db_versao_base`, `db_versao_sincronismo`) — reconciliar com o histórico do MyBatis.
- Ação: diff DDL produção × migrations, registrar drift e congelar nova **baseline** (Flyway) antes de qualquer mudança estrutural.

## Pontos de modelagem relevantes para o novo código

- PKs `int4` com sequences dedicadas (`seq_*`); colunas com prefixo de tabela (`usur_`, `imov_`...); auditoria via `*_tmultimaalteracao` + tabelas `seguranca.tabela_linha_alteracao`/`tab_linha_col_alteracao`.
- 70 colunas `bytea` (arquivos/documentos dentro do banco) e 7 usos de `oid` (large objects — validar `lo_*` na migração).
- Apenas 4 triggers (`cliente_endereco` insert/update, `quadra` última alteração, validação de data) — regra de negócio está na aplicação e nas funções `sp*`, não em triggers.
