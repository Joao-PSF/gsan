# Estratégia de Testes

Situação atual: 19 classes de teste para ~2,39M linhas — na prática, **não há rede de segurança**. A Fase 2 cria a baseline; a regra central de toda a modernização é:

```text
MESMA ENTRADA → GSAN ANTIGO → RESULTADO A
MESMA ENTRADA → GSAN NOVO   → RESULTADO B
REGRA: RESULTADO A = RESULTADO B
```

Diferenças só são aceitas quando deliberadas, documentadas e aprovadas. Valores financeiros: comparação exata ao centavo (tolerância apenas com justificativa explícita e aprovada).

> Revisão 2026-08-13: **não há produção neste projeto**. "GSAN antigo" = instância de referência do legado levantada a partir do repositório (Fase 1) com massa de dados controlada. Como os schemas GSAN e SISAN podem divergir (ADR-0006), a comparação de resultados é **semântica, via mapeamento GSAN→SISAN**, não byte a byte de tabelas.

## Camadas de teste

1. **Caracterização do legado (golden master)** — capturar o comportamento atual sem alterá-lo:
   - Batch/cálculos: executar rotinas em homolog sobre massa congelada e gravar as saídas (tabelas resultantes, resumos, arquivos gerados) como "golden files" versionados.
   - Telas críticas: testes HTTP contra o legado (login → fluxo → resultado no banco), priorizando cadastro, faturamento, arrecadação, cobrança, parcelamento, micromedição, OS, autenticação e autorização.
   - Consultas/relatórios críticos: catalogar SQL, executar sobre massa congelada e versionar resultados.
2. **Equivalência legado × novo (por módulo)** — harness que aplica a mesma entrada nos dois sistemas e compara semanticamente, via mapeamento GSAN→SISAN: estado final dos dados mapeados, valores financeiros, arquivos/relatórios gerados e códigos de retorno.
3. **Testes do sistema novo** — JUnit 5 + Spring Boot Test + Testcontainers (PostgreSQL 18 com o schema do SISAN aplicado pelas migrations Flyway); testes de repositório contra o schema verdadeiro, não H2.
4. **Migração de banco (Fase 8)** — contagens por tabela, checksums por amostragem, somatórios financeiros por competência, sequences, e re-execução de batch de referência (ver `banco/migracao-postgresql.md`).
5. **Segurança** — testes de autorização por funcionalidade (matriz perfil × funcionalidade extraída de `seguranca.*`), garantindo que o novo sistema nega/permite exatamente como o legado.

## Massa de dados

- Origem: **sintética representativa**, construída para o projeto (situação padrão — não há produção aqui), ou derivada de uma base GSAN de referência que venha a ser obtida. Qualquer dado real recebido será **anonimizado** (nomes, CPF/CNPJ, NIS, endereços, e-mails, telefones, documentos em `bytea`), preservando distribuições e casos extremos.
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
