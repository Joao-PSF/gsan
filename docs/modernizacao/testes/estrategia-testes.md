# Estratégia de Testes

Situação atual: 19 classes de teste para ~2,39M linhas — na prática, **não há rede de segurança**. A Fase 2 cria a baseline; a regra central de toda a modernização é:

```text
MESMA ENTRADA → GSAN ANTIGO → RESULTADO A
MESMA ENTRADA → GSAN NOVO   → RESULTADO B
REGRA: RESULTADO A = RESULTADO B
```

Diferenças só são aceitas quando deliberadas, documentadas e aprovadas. Valores financeiros: comparação exata ao centavo (tolerância apenas com justificativa explícita e aprovada).

## Camadas de teste

1. **Caracterização do legado (golden master)** — capturar o comportamento atual sem alterá-lo:
   - Batch/cálculos: executar rotinas em homolog sobre massa congelada e gravar as saídas (tabelas resultantes, resumos, arquivos gerados) como "golden files" versionados.
   - Telas críticas: testes HTTP contra o legado (login → fluxo → resultado no banco), priorizando cadastro, faturamento, arrecadação, cobrança, parcelamento, micromedição, OS, autenticação e autorização.
   - Consultas/relatórios críticos: catalogar SQL, executar sobre massa congelada e versionar resultados.
2. **Equivalência legado × novo (por módulo migrado)** — harness que aplica a mesma entrada nos dois sistemas (ou executa a mesma rotina sobre cópias idênticas do banco) e compara: estado final das tabelas afetadas, valores financeiros, arquivos/relatórios gerados e códigos de retorno.
3. **Testes do sistema novo** — JUnit 5 + Spring Boot Test + Testcontainers (PostgreSQL 18 com schema real via baseline Flyway); testes de repositório contra o schema verdadeiro, não H2.
4. **Migração de banco (Fase 8)** — contagens por tabela, checksums por amostragem, somatórios financeiros por competência, sequences, e re-execução de batch de referência (ver `banco/migracao-postgresql.md`).
5. **Segurança** — testes de autorização por funcionalidade (matriz perfil × funcionalidade extraída de `seguranca.*`), garantindo que o novo sistema nega/permite exatamente como o legado.

## Massa de dados

- Derivada de produção, **anonimizada** (nomes, CPF/CNPJ, NIS, endereços, e-mails, telefones, documentos em `bytea`), preservando distribuições e casos extremos.
- Deve conter obrigatoriamente: contas normais/retificadas/canceladas/parceladas/vencidas, pagamentos, devoluções, créditos, débitos, parcelamentos (ativos e desfeitos), hidrômetros e leituras (incluindo consumo por média), cortes/religações, OS abertas/encerradas, usuários com perfis variados e permissões especiais.
- Congelada e versionada (dump identificado por hash) para que golden files sejam reproduzíveis.

## Priorização da baseline (Fase 2)

| Ordem | Comportamento | Motivo |
| ----- | ------------- | ------ |
| 1 | Autenticação + autorização (matriz de acesso) | Porta de entrada de tudo; pré-requisito da Fase 5 |
| 2 | Cálculo de conta individual (faturar um imóvel) | Núcleo financeiro; base para faturamento em lote |
| 3 | Baixa de pagamento (retorno bancário) | Núcleo da arrecadação |
| 4 | Parcelamento (criar/desfazer) | Regras financeiras complexas |
| 5 | Consumo/média de micromedição | Alimenta o faturamento |
| 6 | Abertura/encerramento de OS | Alto volume operacional |
| 7 | Relatórios financeiros críticos (resumos `sp*_gerar_res_*`) | Conferência gerencial/regulatória |

## Performance (baseline antes de migrar qualquer módulo)

Registrar: tempo de inicialização, autenticação, telas principais, consultas críticas, faturamento/arrecadação de um grupo, geração de relatórios, batch, CPU/memória/conexões, queries lentas (`pg_stat_statements` em homolog). O novo sistema não pode degradar significativamente sem justificativa.
