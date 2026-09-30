# Estratégia de Testes

Situação atual: 19 classes de teste para ~2,39M linhas — na prática, **não há rede de segurança**. A Fase 2 cria a baseline; a regra central de toda a modernização é:

```text
MESMA ENTRADA → GSAN (referência) → RESULTADO A
MESMA ENTRADA → OpenGSAN          → RESULTADO B
REGRA: RESULTADO A = RESULTADO B
```

> ⚠️ **Correção estrutural de 2026-09-14.** A regra acima, sozinha, **contradiz uma regra de segurança do próprio projeto** e precisa ser desdobrada. O legado contém comportamento que o OpenGSAN **não deve** reproduzir: endpoint de escrita sem autenticação (achados 12 e 15), artefato de relatório acessível sem controle de acesso (achado 13), senha em SHA-1 sem *salt* (achado 1), segredo em código (achado 11). Exigir `RESULTADO A = RESULTADO B` literalmente obrigaria o OpenGSAN a reproduzir essas falhas. As duas regras do projeto colidiam e a colisão não estava registrada.

## Dois oráculos, não um

A equivalência é avaliada por **dois critérios independentes**, e todo comportamento cai em um deles:

| Oráculo | Pergunta | Critério | O que uma diferença significa |
| ------- | -------- | -------- | ----------------------------- |
| **1. Funcional / financeiro** | O OpenGSAN produz o mesmo resultado de negócio? | `RESULTADO A = RESULTADO B`. Valores financeiros: **exato ao centavo** | **Defeito.** Investigar e corrigir o OpenGSAN |
| **2. Técnico / de segurança** | O OpenGSAN se comporta melhor onde o legado está errado? | O OpenGSAN **deve divergir** nos pontos registrados | **Conformidade.** Uma igualdade aqui é que seria o defeito |

**Nada fica fora dos dois** — para comportamento que **existe no GSAN**. Um comportamento não classificado é uma pendência de análise, não um caso "neutro".

### 🆕 Requisito nativo — oráculo N (auditoria final, 2026-09-29)

Há requisitos que o OpenGSAN **deve** cumprir e que o GSAN público **não tem**: documento fiscal eletrônico (NFAg), Tarifa Social nacional com concessão automática, Pix Cobrança e Pix Automático — 🆕 e, desde o adendo pós-Fase 0, PCM, Parada e a declaração ao SINISA (CEN-PCM, CEN-PAR, CEN-REG). Para eles **não existe resultado A** — usar o oráculo 1 fabricaria uma equivalência; usar o 2 inventaria uma divergência.

| Oráculo | Pergunta | Critério | O que uma diferença significa |
| ------- | -------- | -------- | ----------------------------- |
| **N. Requisito nativo** | O OpenGSAN cumpre a obrigação ou a decisão registrada? | Resultado esperado derivado da **norma, do leiaute oficial ou da decisão registrada** — **nunca** do legado | **Defeito** do OpenGSAN |

⚠️ **Regras**: baseline do legado `➖ NÃO APLICÁVEL`; onde a norma ainda não foi confirmada, o cenário registra `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` e **não fecha** até a resposta; e o requisito nativo **não entra** na matriz de compatibilidade GSAN → OpenGSAN, para não distorcê-la ([`gsan-opengsan.md §5.2`](../compatibilidade/gsan-opengsan.md)). Quando o requisito nativo passa por um comportamento que o GSAN tem — a classificação de um recebimento Pix, por exemplo —, **essa parte** continua sob o oráculo 1 no cenário que já a cobre.

### Registro de divergências aprovadas

Toda divergência intencional é registrada **antes** de a implementação começar, em [`compatibilidade/divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md), com: comportamento legado, comportamento OpenGSAN, motivo, quem aprovou, e como o teste reconhece a divergência como esperada. Sem esse registro, uma correção de segurança aparece no relatório de testes como "falha de equivalência" e tende a ser revertida por engano.

> Revisão 2026-08-13: **não há produção neste projeto**. "GSAN antigo" = instância de referência do legado levantada a partir do repositório (Fase 1) com massa de dados controlada. Como os schemas GSAN e OpenGSAN podem divergir (ADR-0006), a comparação de resultados é **semântica, via mapeamento GSAN→OpenGSAN**, não byte a byte de tabelas.

## Especificação de cenário × baseline — duas entregas, duas fases

⚠️ **Correção de 2026-09-28 — dependência circular eliminada.** A versão anterior desta seção exigia, ao mesmo tempo, que (a) os cenários críticos estivessem **especificados na Fase 0**; (b) o campo `Resultado esperado` separasse cenário de especificação; (c) enquanto esse campo estivesse 🟡 "a capturar", o cenário **não** estivesse especificado; e (d) os resultados reais fossem **capturados na Fase 2**. Juntas, as quatro regras formavam um ciclo sem saída:

```text
Fase 0 exige resultado capturado  →  a captura é da Fase 2  →  a Fase 2 depende da Fase 0
```

🔵 **Causa**: a regra (c) confundia duas coisas diferentes — *saber o que observar e como decidir* com *saber o valor que será observado*. A primeira é trabalho de análise; a segunda só existe depois de executar o legado.

### A distinção que resolve

| | **Especificação do cenário** | **Baseline / golden master** |
| - | ---------------------------- | ---------------------------- |
| **Fase** | **0** | **2** |
| **Responde** | O que executar, em que estado, o que observar, qual semântica esperar, qual diferença é permitida, qual oráculo decide | Qual valor, registro, arquivo, total ou saída o GSAN de referência **efetivamente produz** |
| **Fonte** | Mapas funcionais, compatibilidade, divergências, código lido | Execução do GSAN de referência sobre massa congelada |
| **Pode conter** | Regras e invariantes **comprovados** | Valores concretos **observados** |
| 🔴 **Não pode conter** | Valor inventado | Valor deduzido de leitura de código |

### Quando um cenário está especificado

Um cenário está **ESPECIFICADO NA FASE 0** quando estão fechados: **o que executar** · **em qual estado** · **o que observar** · **qual comportamento caracteriza sucesso** · **qual oráculo decide** · **quais diferenças são permitidas** — mesmo que os valores concretos ainda devam ser capturados na Fase 2.

🔴 **Regra absoluta**: *não observado ≠ resultado esperado conhecido*. Quando a documentação comprova só que uma operação existe, não se inventa valor. Quando comprova uma regra, registra-se a regra. Quando o valor real é necessário, a baseline fica `A CAPTURAR NA FASE 2`.

### Modelo obrigatório de especificação

```markdown
## CEN-<ÁREA>-<NNN> — <título>

- **Criticidade**: P0 / P1 / P2
- **Etapa OpenGSAN**: etapa da ordem de implementação — 🆕 ou **T** (trilha estrutural) e **R** (trilha regulatória), fora das etapas numeradas (adendo pós-Fase 0)
- **Conceitos relacionados**: conceitos e classe de compatibilidade (C1…C5)
- **Objetivo**: regra caracterizada
- **Pré-condições**: estado exigido da massa (perfis, situações, referência)
- **Entrada**: dados e variações exercitadas
- **Operação GSAN**: o que é executado no legado
- **Operação conceitual OpenGSAN**: a operação equivalente, sem localizador físico
- **Observações semânticas**: lista FECHADA do que é comparado
- **Localizadores GSAN**: tabela.coluna / saída / arquivo, quando conhecidos
- **Resultado semântico esperado**: regra ou invariante comprovado — testável
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2 | 🟢 JÁ COMPROVADA | ➖ NÃO APLICÁVEL (requisito nativo)
                                   🆕 (Fase 2) | 🟢 CAPTURADA — variações e caminho em golden/
                                   | 🟡 CAPTURADA EM PARTE — o que falta e por quê
- **Normalizações**: o que se ignora — nunca dinheiro, referência, situação,
                     identidade funcional, ordem com semântica ou arredondamento
- **Divergência permitida**: D-xx | nenhuma
- **Oráculo**: 1 | 2 | 1+2 (por observável) | N (requisito nativo) | PENDENTE DE CARACTERIZAÇÃO
- **Gate que este cenário protege**: transição de etapa
- **Evidência**: documentos e código que sustentam a especificação
```

⚠️ **`JÁ COMPROVADA` só vale quando o próprio observável é um artefato estático** — por exemplo, um segredo presente em arquivo versionado: ler o arquivo *é* observar. Para comportamento em execução, leitura de código **nunca** conta como baseline capturada.

🔴 **Localizador físico só do lado do GSAN.** O OpenGSAN ainda não tem modelo físico; suas observações são semânticas.

### Onde estão os cenários

[`cenarios-criticos.md`](cenarios-criticos.md) — índice, matriz mestre de cobertura, gates por etapa, requisitos de massa, cenários bloqueados e rastreabilidade do inventário. As especificações estão em [`cenarios/`](cenarios/), por área.

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
2. **Equivalência legado × novo (por módulo)** — harness que aplica a mesma entrada nos dois sistemas e compara semanticamente, via mapeamento GSAN→OpenGSAN: estado final dos dados mapeados, valores financeiros, arquivos/relatórios gerados e códigos de retorno.
3. **Testes do sistema novo** — JUnit 5 + Spring Boot Test + Testcontainers (PostgreSQL 18 com o schema do OpenGSAN aplicado pelas migrations Flyway); testes de repositório contra o schema verdadeiro, não H2.
4. ~~**Migração de banco**~~ — ⚠️ **fora do escopo deste projeto** desde 2026-09-15 (ADR-0005): a Fase 8 foi removida e a migração de instalações GSAN tem projeto próprio. A bateria que tal projeto precisaria (contagens por tabela, checksums por amostragem, somatórios financeiros por competência, sequences, re-execução de batch de referência) fica registrada como **insumo** em [`banco/migracao-postgresql.md`](../banco/migracao-postgresql.md).
5. **Segurança (oráculo 2)** — testes de autorização por funcionalidade (matriz perfil × funcionalidade extraída de `seguranca.*`). ⚠️ **Correção 2026-09-14**: o objetivo **não** é "negar/permitir exatamente como o legado". É preservar as concessões legítimas (união de grupos, abrangência, permissões especiais) e **negar deliberadamente** onde o legado permite por defeito — cada caso constando do registro de divergências aprovadas. Casos conhecidos: acesso ao artefato de relatório (achado 13), `/api/ordem-servico/*` (12), entrada de dados de campo (15), filtros decorativos (14).
6. 🆕 **Arquitetura e perfis de implantação** (segundo adendo pós-Fase 0 — [ADR-0010](../decisoes/0010-monolito-modular-perfis-de-implantacao.md)) — **testes arquiteturais**: nenhum núcleo importa dependência opcional, nenhum módulo acessa internos de outro, nenhuma comunicação interna usa HTTP; **testes de perfil**: FULL, SINISA, ATENDIMENTO, ASSETS + ATENDIMENTO, ASSETS sem provedor de execução, COMMERCIAL com medição externa e OPERATIONS sem Networks **iniciam**, e perfil inválido **não inicia**. Na fundação, o mecanismo é provado com **módulos-fixture**; cada módulo real acrescenta seu perfil quando nasce (CEN-MOD-001 a 007, [`modulos-e-perfis-de-implantacao.md §21`](../arquitetura/modulos-e-perfis-de-implantacao.md#21-verificação-da-modularidade)).

## 🆕 Cenário, massa, baseline e execução — quatro coisas (Fase 2, 2026-09-30)

A Fase 2 separou o que a Fase 0 tratava junto. Confundir os quatro termos leva a contar errado (103 cenários **não** são 103 baselines) e a comparar errado (uma baseline sem a massa que a produziu não prova nada).

| Termo | Definição | Cardinalidade | Onde |
| ----- | --------- | ------------- | ---- |
| **Cenário** | Especificação: o que executar, o que observar (lista fechada), qual oráculo decide | 103 | [`cenarios/`](cenarios/) |
| **Variação** | Uma entrada concreta do cenário (V1…Vn), com a massa que exige | 326 declaradas; 234 a capturar (matriz) | `ambiente-referencia/baselines/cenarios/*.json` |
| **Massa** | Estado de dados sintético: **base** comum + **deltas** por variação; cada arquivo identificado por sha256 | < variações — variações que só diferem na entrada compartilham a massa efetiva | `ambiente-referencia/baselines/massas/` |
| **Baseline** | O que o GSAN produziu para **uma** variação, normalizado — função de *(massa, operação, entrada, versão do legado)*, e grava os quatro | uma por variação | `ambiente-referencia/baselines/golden/` |
| **Execução** | Uma rodada estado limpo → massa → operação → observação. **Evidência**, nunca baseline | ≥ 2 por baseline na captura, 1 por verificação | `.saida/` (não versionado) |

🔴 Regras que decorrem: (1) só se grava baseline depois de **duas execuções idênticas** a partir do estado limpo; (2) a verificação nunca escreve baseline; (3) mudar a massa de uma baseline a invalida — a verificação acusa a massa, não o comportamento; (4) o que a fronteira executável **não exibe** fica registrado em `fora_desta_fronteira` da baseline, nunca é deduzido do código. Mecanismo e resultados: [relatório da Fase 2](fase2/fase2-caracterizacao-baselines.md); classificação A/B/C/N dos 103 cenários: [matriz](fase2/matriz-caracterizacao.md); cobertura: [gerada por script](fase2/cobertura-baselines.md).

### Testes parametrizados a partir das baselines (Fase 4 em diante)

Cada cenário vira **um** teste de equivalência do OpenGSAN, **parametrizado pelas variações**: o teste enumera `golden/<domínio>/<CEN>/*.json`, reconstrói no OpenGSAN a mesma massa (pelo mapeamento GSAN → OpenGSAN), aplica a mesma entrada da baseline e compara **só os observáveis da lista fechada**, pelo oráculo do cenário — igualdade ao centavo no oráculo 1, divergência esperada no 2. Acrescentar uma variação é acrescentar um arquivo de baseline, não um teste. Explosão combinatória (`categoria × situação × tipo × …`) continua proibida ([`cenarios-criticos.md §13.7`](cenarios-criticos.md)): parametrização é sobre casos base e de fronteira, não sobre o produto cartesiano.

## Massa de dados

- Origem: **sintética representativa**, construída para o projeto (situação padrão — não há produção aqui), ou derivada de uma base GSAN de referência que venha a ser obtida. Qualquer dado real recebido será **anonimizado** (nomes, CPF/CNPJ, NIS, endereços, e-mails, telefones, documentos em `bytea`), preservando distribuições e casos extremos.
- Deve conter obrigatoriamente: contas normais/retificadas/canceladas/parceladas/vencidas, pagamentos, devoluções, créditos, débitos, parcelamentos (ativos e desfeitos), hidrômetros e leituras (incluindo consumo por média), cortes/religações, OS abertas/encerradas, usuários com perfis variados e permissões especiais.
- ~~Congelada e versionada (dump identificado por hash)~~ 🆕 **Como ficou na Fase 2**: não um *dump* único, mas **arquivos SQL versionados** (base + deltas), cada um identificado por sha256 gravado em toda baseline que o usa; o estado de partida é o banco pós-migração **congelado como modelo** (`gsan_*_ref`) ao fim do passo `banco` da Fase 1, recriado a cada execução. Identificadores fixados por constante do legado vêm dessa constante; o resto é declarado SINTÉTICO.

## Priorização da baseline (Fase 2)

| Ordem | Comportamento | Motivo |
| ----- | ------------- | ------ |
| 1 | Autenticação + autorização (matriz de acesso) | Porta de entrada de tudo; pré-requisito da **fundação de segurança (S1)** — ⚠️ a antiga "Fase 5 — Segurança" foi desdobrada em S1/S2/S3 em 2026-09-15 |
| 2 | Cálculo de conta individual (faturar um imóvel) | Núcleo financeiro; base para faturamento em lote |
| 3 | Baixa de pagamento (retorno bancário) | Núcleo da arrecadação |
| 4 | Parcelamento (criar/desfazer) | Regras financeiras complexas |
| 5 | Consumo/média de micromedição | Alimenta o faturamento |
| 6 | Abertura/encerramento de OS | Alto volume operacional |
| 7 | Resumos financeiros de conferência — `RelatorioResumoFaturamento` e `RelatorioResumoArrecadacao` | Conferência gerencial/regulatória. ⚠️ **Corrigido em 2026-09-28**: a versão anterior citava os resumos `sp*_gerar_res_*`, que o inventário do banco classifica como **customizações permanentes da instalação de referência** ([`banco/estrutura-atual.md`](../banco/estrutura-atual.md)) — não GSAN público. Baseline de caracterização se faz sobre o núcleo |

🔵 A ordem acima é da **captura** na Fase 2. A relação de cada cenário com as etapas de implementação e seus gates está em [`cenarios-criticos.md`](cenarios-criticos.md).

🆕 **Lote piloto (2026-09-30)** — por decisão do responsável, o piloto seguiu uma **cadeia vertical** Cadastro → Faturamento individual (itens 2 e 5 acima) em vez de começar pelo item 1: provar o mecanismo sobre cálculo financeiro ao centavo, o caso mais exigente de determinismo. Autenticação e autorização (item 1) são o **próximo lote** ([relatório da Fase 2 §12](fase2/fase2-caracterizacao-baselines.md#12-próximos-lotes)).

## Performance (baseline antes de substituir qualquer comportamento)

Registrar: tempo de inicialização, autenticação, telas principais, consultas críticas, faturamento/arrecadação de um grupo, geração de relatórios, batch, CPU/memória/conexões, queries lentas (`pg_stat_statements` em homolog). O novo sistema não pode degradar significativamente sem justificativa.
