# PostgreSQL — SISAN e Importação de Bases GSAN

> Revisão 2026-08-13 (2ª execução): a versão anterior deste documento planejava o corte de um banco de produção — premissa corrigida: **não há produção neste projeto**. O conteúdo técnico válido foi reorganizado em três partes: (1) o PostgreSQL do SISAN; (2) restauração de bases GSAN para análise/referência; (3) estratégia futura de migração GSAN→SISAN, que é requisito arquitetural, não atividade atual.

## 1. PostgreSQL do SISAN (desenvolvimento e VPS)

- Versão: PostgreSQL 18.x (18.6+ em 2026-08; reconfirmar a cada fase).
- Encoding **UTF-8** com collation explícita e documentada na criação do cluster/banco (ADR-0004) — sem depender do locale implícito do SO.
- Schema versionado por **Flyway desde `V1`** (ADR-0002): o modelo nasce das decisões de compatibilidade (`PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR`, ADR-0006), não de baseline copiada do `gsan_comercial`.
- Contas segregadas por finalidade desde o início (aplicação online, batch, consulta/BI, administração) com menor privilégio — reaproveitando o conceito já presente no GSAN (`gsan_online/batch/olap/dba`), **nunca** as credenciais (senha = login, comprometidas).
- Extensões: apenas as necessárias e via `CREATE EXTENSION` (ex.: `pg_trgm` se a busca aproximada for preservada); `dblink` não entra no SISAN — integrações entre bases serão explícitas na aplicação.
- Dev: docker-compose; testes de persistência com Testcontainers sobre o schema real do SISAN. VPS: instância PostgreSQL própria para testes/homologação/demonstração (sem requisitos de produção crítica nesta etapa).

## 2. Restauração de bases GSAN para análise e referência (Fases 0–2)

Necessária para estudar comportamento, montar o ambiente de referência do legado e futuramente rodar a caracterização. Um dump/DDL de instalação GSAN antiga (como o `gsan_comercial`) não restaura limpo em PostgreSQL moderno; correções scriptadas e idempotentes:

| Item | Tratamento |
| ---- | ---------- |
| Funções C de contrib pré-extensão (`dblink`, `pg_trgm` — estilo PG 8.x) | Não restaurar as definições antigas; `CREATE EXTENSION dblink; CREATE EXTENSION pg_trgm;` e revalidar dependentes (114 referências a dblink; índices trgm) |
| `public.plpgsql_call_handler` declarado manualmente | Descartar (PL/pgSQL é nativo) |
| `oid`/large objects (7 usos) | Restaurar com `--large-objects` e validar `pg_largeobject` |
| Encoding LATIN1 da origem | Restaurável sem conversão em PG moderno (banco de referência pode permanecer LATIN1); conversão para UTF-8 só no contexto de migração real (parte 3) |
| Views/funções com sintaxe antiga (46 views, 60 funções SQL/PLpgSQL) | Testar recriação uma a uma; corrigir o que falhar e registrar |
| Ordenação (collation glibc/ICU difere da origem) | Índices são reconstruídos no restore; diferenças de `ORDER BY` em relatórios são esperadas e devem ser documentadas |

## 3. Migração GSAN → SISAN (requisito arquitetural — **não implementar agora**)

Pipeline futuro, por companhia:

```text
Instalação GSAN → identificação da versão/schema → análise de compatibilidade
→ mapeamento GSAN→SISAN → transformações necessárias → validação → migração → SISAN
```

Princípios definidos desde já para não inviabilizar o migrador:

1. **Sem hipótese de schema único**: cada instalação pode ter versão, migrations, customizações, objetos extras e DDL manual próprios (comprovado no `gsan_comercial`). O migrador começa inspecionando o schema efetivo, não assumindo-o.
2. **Mapeamento registrado**: toda divergência estrutural do SISAN em relação ao GSAN é registrada com sua transformação correspondente no documento de compatibilidade — o migrador nasce desse registro, não de engenharia reversa futura.
3. **Encoding**: origem tipicamente LATIN1 → conversão para UTF-8 detectada e validada caso a caso (ADR-0004): tamanhos de campo, caracteres inválidos, ordenações.
4. **Validação com tolerância zero no financeiro** (herdada do plano original): diff de schema mapeado; contagem de 100% das tabelas transportadas; somatórios financeiros por competência (contas, pagamentos, devoluções, créditos, débitos, parcelamentos, saldos, hidrômetros, OS); amostragens com checksum; re-execução de rotinas de referência comparando resultados; performance das consultas críticas.
5. **Rollback e janela**: quando uma migração real existir, a origem permanece intocada até o aceite final; janela, freeze e ponto de corte registrados. (Detalhamento pertence ao projeto de migração da companhia, não a esta fase.)
6. **Objetos não transportados**: categorias `NÃO TRANSPORTAR` (backups/temporários/manutenção) são ignoradas pelo migrador, mas listadas no relatório de migração para decisão explícita da companhia.
