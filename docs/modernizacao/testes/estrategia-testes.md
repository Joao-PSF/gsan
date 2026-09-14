# Estratégia de Testes

Situação atual: 19 classes de teste para ~2,39M linhas — na prática, **não há rede de segurança**. A Fase 2 cria a baseline; a regra central de toda a modernização é:

```text
MESMA ENTRADA → GSAN ANTIGO → RESULTADO A
MESMA ENTRADA → GSAN NOVO   → RESULTADO B
REGRA: RESULTADO A = RESULTADO B
```

> ⚠️ **Correção estrutural de 2026-09-14.** A regra acima, sozinha, **contradiz uma regra de segurança do próprio projeto** e precisa ser desdobrada. O legado contém comportamento que o SISAN **não deve** reproduzir: endpoint de escrita sem autenticação (achados 12 e 15), artefato de relatório acessível sem controle de acesso (achado 13), senha em SHA-1 sem *salt* (achado 1), segredo em código (achado 11). Exigir `RESULTADO A = RESULTADO B` literalmente obrigaria o SISAN a reproduzir essas falhas. As duas regras do projeto colidiam e a colisão não estava registrada.

## Dois oráculos, não um

A equivalência é avaliada por **dois critérios independentes**, e todo comportamento cai em um deles:

| Oráculo | Pergunta | Critério | O que uma diferença significa |
| ------- | -------- | -------- | ----------------------------- |
| **1. Funcional / financeiro** | O SISAN produz o mesmo resultado de negócio? | `RESULTADO A = RESULTADO B`. Valores financeiros: **exato ao centavo** | **Defeito.** Investigar e corrigir o SISAN |
| **2. Técnico / de segurança** | O SISAN se comporta melhor onde o legado está errado? | O SISAN **deve divergir** nos pontos registrados | **Conformidade.** Uma igualdade aqui é que seria o defeito |

**Nada fica fora dos dois.** Um comportamento não classificado é uma pendência de análise, não um caso "neutro".

### Registro de divergências aprovadas

Toda divergência intencional é registrada **antes** de a implementação começar, em [`compatibilidade/divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md), com: comportamento legado, comportamento SISAN, motivo, quem aprovou, e como o teste reconhece a divergência como esperada. Sem esse registro, uma correção de segurança aparece no relatório de testes como "falha de equivalência" e tende a ser revertida por engano.

> Revisão 2026-08-13: **não há produção neste projeto**. "GSAN antigo" = instância de referência do legado levantada a partir do repositório (Fase 1) com massa de dados controlada. Como os schemas GSAN e SISAN podem divergir (ADR-0006), a comparação de resultados é **semântica, via mapeamento GSAN→SISAN**, não byte a byte de tabelas.

## Especificação de cenário — entregável do fechamento da Fase 0

⚠️ **Correção de 2026-09-14.** Os ~110 cenários levantados nos mapas funcionais são **inventário**, não especificação. A sequência de trabalho do projeto é:

```text
ANALISAR → COMPREENDER → DOCUMENTAR → IDENTIFICAR FRONTEIRAS
        → IDENTIFICAR COMPATIBILIDADE → LEVANTAR HIPÓTESES → DEFINIR TESTES → PARAR
```

**DEFINIR TESTES está dentro da Fase 0**, antes do PARAR. Especificar o que observar não é programar — programar é construir massa, *harness* e automação, que são da Fase 2. A ausência dessas especificações é lacuna da Fase 0, não escopo adiado.

### Modelo obrigatório de especificação

```markdown
## CEN-<módulo>-<n> — <título>
- **Objetivo**: que regra este cenário caracteriza
- **Pré-condições**: estado exigido da massa (entidades, situações, referência)
- **Entrada**: dados e operação exatos
- **Operação**: o que é executado (método/endpoint/rotina batch)
- **Campos observados**: lista fechada do que é comparado (tabela.coluna, valor, arquivo)
- **Resultado esperado**: 🟢 comprovado no legado | 🟡 a capturar na Fase 2
- **Normalizações**: o que se ignora na comparação (timestamps, ids sequenciais, ordem)
- **Divergência permitida**: referência ao registro de divergências, se houver
- **Oráculo**: 1 (funcional/financeiro) ou 2 (técnico/segurança)
```

⚠️ **`Resultado esperado` é o campo que separa cenário de especificação.** Enquanto ele estiver 🟡, o cenário está identificado mas não especificado. Marcá-lo 🟢 sem captura no legado seria inventar o resultado — o erro que a regra mestra do projeto existe para impedir.

### Comparação de relatórios — não é byte a byte

🟢 O motor é JasperReports com exportação por tipo ([`modulos/relatorios.md`](../modulos/relatorios.md)). PDFs carregam *timestamp*, metadados do Jasper e ordem de objetos que variam entre execuções — comparação binária produziria falha em 100% dos casos, inclusive do legado contra ele mesmo.

A comparação de relatórios é **semântica**, em ordem de preferência:

1. **Sobre o `RelatorioDataSource`** — os dados que alimentam o template, antes da renderização. É o ponto que carrega a regra de negócio.
2. **Sobre o conteúdo extraído** (texto e tabelas do PDF), normalizando data de geração, numeração de página e espaçamento.
3. **Sobre a contagem e os totalizadores** — mínimo aceitável, nunca suficiente sozinho para relatório financeiro.

## Camadas de teste

1. **Caracterização do legado (golden master)** — capturar o comportamento atual sem alterá-lo:
   - Batch/cálculos: executar rotinas em homolog sobre massa congelada e gravar as saídas (tabelas resultantes, resumos, arquivos gerados) como "golden files" versionados.
   - Telas críticas: testes HTTP contra o legado (login → fluxo → resultado no banco), priorizando cadastro, faturamento, arrecadação, cobrança, parcelamento, micromedição, OS, autenticação e autorização.
   - Consultas/relatórios críticos: catalogar SQL, executar sobre massa congelada e versionar resultados.
2. **Equivalência legado × novo (por módulo)** — harness que aplica a mesma entrada nos dois sistemas e compara semanticamente, via mapeamento GSAN→SISAN: estado final dos dados mapeados, valores financeiros, arquivos/relatórios gerados e códigos de retorno.
3. **Testes do sistema novo** — JUnit 5 + Spring Boot Test + Testcontainers (PostgreSQL 18 com o schema do SISAN aplicado pelas migrations Flyway); testes de repositório contra o schema verdadeiro, não H2.
4. **Migração de banco (Fase 8)** — contagens por tabela, checksums por amostragem, somatórios financeiros por competência, sequences, e re-execução de batch de referência (ver `banco/migracao-postgresql.md`).
5. **Segurança (oráculo 2)** — testes de autorização por funcionalidade (matriz perfil × funcionalidade extraída de `seguranca.*`). ⚠️ **Correção 2026-09-14**: o objetivo **não** é "negar/permitir exatamente como o legado". É preservar as concessões legítimas (união de grupos, abrangência, permissões especiais) e **negar deliberadamente** onde o legado permite por defeito — cada caso constando do registro de divergências aprovadas. Casos conhecidos: acesso ao artefato de relatório (achado 13), `/api/ordem-servico/*` (12), entrada de dados de campo (15), filtros decorativos (14).

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
