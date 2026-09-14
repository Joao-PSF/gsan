# Compatibilidade das Estruturas Centrais GSAN → SISAN

> **Procedência**: consolidação decisória sobre o [mapa de domínio](../dominio/mapa-de-dominio.md), o [glossário](../dominio/glossario.md) e os dez mapas funcionais. Base documental: `HEAD = 4cb9fc7`. **Nenhuma reanálise ampla de código ou banco** — método e níveis de certeza em [`procedencia.md`](../procedencia.md).
>
> **Esta atividade responde: *o que fazemos com o que existe?*** Não responde *como o domínio do SISAN ficará* — isso é a Visão Conceitual Alvo, próxima atividade. Onde algo é `REESTRUTURAR`, o documento registra **o problema e a semântica a preservar**, e **para aí**.
>
> **Não contém**: nomes de tabelas ou schemas, tipos de coluna, chaves, índices, migrations, entidades JPA, APIs, modelo físico.

---

## 1. Objetivo

Classificar as **estruturas centrais do domínio** do GSAN segundo a ADR-0006, equilibrando cinco forças que puxam em direções diferentes:

```text
compatibilidade  +  qualidade da arquitetura  +  facilidade de migração
                 +  preservação das regras     +  manutenção futura
```

O objetivo **não** é deixar o SISAN igual ao GSAN. Também **não** é redesenhar tudo. A ADR-0005 fixa a regra: *preservar quando adequado, modernizar quando necessário, redesenhar somente com justificativa*.

⚠️ **Escopo**: **64 decisões estruturais** sobre conceitos centrais. As ~1.800 tabelas **não** foram classificadas — o que é `NÃO TRANSPORTAR` está agrupado por **famílias** (§18).

⚠️ **Nota honesta sobre o volume**: o roteiro sugeria *aproximadamente 25 a 50* decisões; o resultado ficou em 64. Não reduzi artificialmente por duas razões: (a) são **dez** áreas, e Cadastro e Faturamento sozinhos concentram 21 decisões por serem os módulos mais densos; (b) **agrupar estruturas com classificações diferentes esconderia a decisão** — `FAT-02` (identidade) e `FAT-03` (tabelas-espelho) são o mesmo mecanismo físico, mas a semântica de uma é inegociável e a da outra não. Onde o agrupamento **não** perdia informação, foi feito (`MIC-01` trata hidrômetro e instalação juntos; `ARR-06`, devolução e débito automático).

---

## 2. Critério de classificação

Conforme ADR-0006, sem reinterpretação:

| Classificação | Quando se aplica |
| ------------- | ---------------- |
| **PRESERVAR** | A estrutura atual é adequada; alterá-la não traria benefício suficiente. Ajustes mínimos permitidos |
| **MODERNIZAR** | Conceito e estrutura básica permanecem; detalhes melhoram (tipos, nomes, constraints, organização). **Transformação GSAN→SISAN direta** |
| **REESTRUTURAR** | Problema estrutural relevante justifica alteração. Exige registrar: problema, benefício, semântica a preservar, transformação, risco e validação (§19) |
| **NÃO TRANSPORTAR** | Não deve existir no SISAN. O migrador ignora e relata |
| **EXIGE APROFUNDAMENTO** | Não há evidência suficiente para decidir. **Não é classificação** — é recusa honesta a classificar |

### 2.1 Regra de decisão (peso da evidência)

Quanto maior **criticidade + número de consumidores + valor histórico + risco financeiro**, maior a evidência exigida para `REESTRUTURAR`.

⚠️ **Não se reestrutura porque ficaria mais bonito.** Onde a única justificativa encontrada foi estética, a classificação ficou em `PRESERVAR` ou `MODERNIZAR`.

### 2.2 Nível de confiança

| Nível | Significado |
| ----- | ----------- |
| **ALTA** | Comportamento e estrutura suficientemente compreendidos; a decisão pode orientar a modelagem |
| **MÉDIA** | Decisão provável; existe detalhe pendente que pode ajustar a forma, não o rumo |
| **BAIXA** | ⚠️ **Não deve orientar implementação sem aprofundamento** |

### 2.3 Precedência das divergências aprovadas

Para qualquer estrutura ligada a uma divergência de [`divergencias-aprovadas.md`](divergencias-aprovadas.md): **a divergência tem precedência sobre equivalência literal**. A classificação aqui registra o que fazer com a estrutura; o *comportamento* exigido está lá. Divergência nova encontrada nesta análise é marcada **`DIVERGÊNCIA PROPOSTA`** — nunca aprovada automaticamente.

---

## 3. Semântica × estrutura física

⚠️ **A distinção mais importante deste documento.** Toda linha separa três coisas:

```text
A. SEMÂNTICA        o que precisa continuar existindo funcionalmente
B. REPRESENTAÇÃO    como o GSAN implementa isso hoje
C. TRATAMENTO       a classificação da ESTRUTURA no SISAN
```

Elas não andam juntas. O exemplo canônico:

```text
Identidade estável de uma conta      → semântica: PRESERVAR OBRIGATORIAMENTE
ContaGeral + conta + conta_historico → representação atual
estrutura no SISAN                   → REESTRUTURAR
```

🔵 **Preservar a semântica e reestruturar a representação não é contradição — é o caso mais comum neste documento.** Onze das decisões abaixo têm exatamente esse formato, e confundi-las produziria ou uma cópia fossilizada do legado, ou a perda silenciosa de uma regra.

---

## 4. Resumo executivo

**64 decisões.** ⚠️ **12 delas têm classificação dupla** (tipicamente *semântica × estrutura*, ou *domínio × integração*) — por isso a tabela distingue a classificação **primária** de quantas decisões **tocam** cada categoria.

| Classificação | Primária | Tocam | Leitura |
| ------------- | -------: | ----: | ------- |
| **PRESERVAR** | **37** | 37 | 🔴 **O GSAN acertou mais do que errou.** Quase 6 em cada 10 decisões preservam a estrutura atual |
| **REESTRUTURAR** | **14** | 15 | Acoplamentos reais, representações concorrentes e estruturas cuja melhoria se justifica (§19) |
| **MODERNIZAR** | **6** | 11 | Estruturas conceitualmente corretas com problemas técnicos pequenos |
| **EXIGE APROFUNDAMENTO** | **5** | 6 | Sem evidência suficiente — registrados, não forçados (§20) |
| **NÃO TRANSPORTAR** | **2** | 7 | Infraestrutura morta, mecanismos inadequados, artefatos — mais **6 famílias** em §18 |

🔵 **A leitura mais importante da tabela**: `PRESERVAR` domina. Isso **não** é conservadorismo — é consequência da regra da ADR-0006 (quanto maior criticidade + consumidores + valor histórico + risco financeiro, maior a evidência exigida para reestruturar) aplicada a um sistema cujo modelo funcional, nos módulos financeiros, é bom.

### 4.1 As cinco decisões que mais importam

1. 🔴 **Identidade estável de documento financeiro** (`FAT-02`) — a semântica é **inegociável**; a implementação (`*Geral` + tabelas-espelho) é `REESTRUTURAR`. Errar aqui quebra pagamento, cobrança e parcelamento de contas retificadas ou arquivadas.
2. 🔴 **Precisão financeira** (`FAT-08`) — **`PRESERVAR`**. As cinco políticas de arredondamento **são comportamento de negócio**, não dívida técnica. Unificá-las altera valores cobrados do cliente.
3. 🔴 **Snapshots da Conta** (`FAT-04`) — **`PRESERVAR`**. Parecem desnormalização; são requisito de auditoria retroativa.
4. 🔴 **Abrangência territorial** (`SEG-03`) — conceito `PRESERVAR`, aplicação `REESTRUTURAR`. Hoje depende de chamada manual em cada consulta; herdar isso é herdar vazamento de dados por omissão (LGPD).
5. 🔴 **Regra como dado** (§15) — 16 famílias paramétricas, quase todas `PRESERVAR`. Transformá-las em `enum` converte configuração em deploy.

### 4.2 Distribuição por área

Classificação **primária**, por área:

| Área | Total | PRES | REEST | MOD | APROF | N/TRANSP |
| ---- | ----: | ---: | ----: | --: | ----: | -------: |
| Cadastro | 11 | 5 | 3 | 2 | 1 | — |
| Faturamento | 10 | 7 | 3 | — | — | — |
| Cobrança | 7 | 5 | — | 1 | 1 | — |
| Arrecadação | 7 | 5 | 2 | — | — | — |
| Segurança | 7 | 4 | 1 | — | 1 | 1 |
| Micromedição | 6 | 4 | — | 1 | — | 1 |
| Atendimento | 6 | 2 | 1 | 2 | 1 | — |
| Integrações | 4 | 2 | 2 | — | — | — |
| Batch | 3 | 2 | 1 | — | — | — |
| Relatórios | 3 | 1 | 1 | — | 1 | — |
| **Total** | **64** | **37** | **14** | **6** | **5** | **2** |

🔵 **Leituras**:

- **Faturamento é o mais preservado em proporção** (7 de 10) — apesar de ser o módulo de maior risco financeiro. É a evidência mais forte de que o modelo do núcleo financeiro é bom: **onde há dinheiro, o GSAN acertou**.
- **Cadastro concentra reestruturações** não por ser mal feito, mas porque o **Imóvel acumulou estado de outros domínios** (`CAD-02`) e a **Economia ficou sem forma explícita** (`CAD-05`).
- **Integrações tem metade das decisões reestruturando** — a maior proporção. Coerente: é a única área onde a camada **não existe**.
- **Atendimento tem o maior peso de `MODERNIZAR`** — o modelo é correto, os defeitos são de forma (flags sem versionamento, campos agregados sem histórico).

---

## 5. Cadastro

### CAD-01 · Imóvel — identidade (matrícula + DV)

| | |
|---|---|
| **Semântica** | Um identificador público, estável e único por unidade atendível, reconhecido por usuários e clientes, que nunca é reaproveitado |
| **Representação atual** | 🟢 `imov_id` de `cadastro.seq_imovel` + **matrícula formatada com DV módulo 11**; exclusão lógica (`imov_icexclusao`); variante de DV por companhia (`obterDigitoVerificadorModuloCAERN`) |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🟢 123 FKs dependem dela; é a chave pública impressa em contas e usada em atendimento. Valor de negócio máximo, qualidade adequada, benefício de mudança ≈ zero |
| **Impacto de migração** | 🔴 **Crítico**: o identificador deve permanecer **externamente igual** (§17) |
| **Transformação** | Nenhuma no valor. A **regra de DV** vira ponto de extensão (a variante CAERN não pode ficar no núcleo — ver `CAD-08`) |
| **Validação** | Contagem total de imóveis; amostragem de DV recalculado; verificação de ausência de colisão |

### CAD-02 · Imóvel — o agregado sobrecarregado

| | |
|---|---|
| **Semântica** | O imóvel precisa expor: identificação, localização, características físicas, classificação tarifária e **o estado corrente relevante** aos processos |
| **Representação atual** | ⚠️ 🟢 O registro concentra também: **situação das ligações de água e esgoto** (`last_id`/`lest_id` — estado de *outra* entidade), **situação de cobrança** + contadores de parcelamento/reparcelamento (estado de processo de *outro módulo*), parâmetros de faturamento (dia de vencimento, débito automático, situação especial), denormalizações (`imov_qteconomia`, categoria principal), três colunas de rota, campos sociais e nomenclaturas de companhia |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.1](#191-cad-02--estado-de-outros-domínios-dentro-do-imóvel) |
| **Motivo** | 🔵 É a causa estrutural das 123 FKs e do acoplamento entre módulos. Não é questão estética: **o estado de cobrança e de ligação escrito no Imóvel é o que obriga Cobrança e Atendimento a escreverem no agregado do Cadastro** |
| **Impacto de migração** | Médio — a transformação é redistribuição de colunas, sem perda de informação |
| **Validação** | Para cada imóvel: o estado reconstruído no SISAN reproduz exatamente o que as colunas legadas continham |

### CAD-03 · Cliente

| | |
|---|---|
| **Semântica** | Pessoa física/jurídica identificada por CPF/CNPJ, com tipo, endereços e contatos, que se relaciona com imóveis e responde por obrigações |
| **Representação atual** | 🟢 `cadastro.cliente` + `cliente_endereco` (N tipificados) + `cliente_fone`; auto-relação de cliente responsável |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | Modelo simples e correto; CPF/CNPJ é chave de negócio natural; alto acoplamento (pagamento, guia, negativação, RA, conta) |
| **Impacto de migração** | Baixo |
| **Transformação** | Ajustes de tipo/constraint apenas |
| **Validação** | Contagem; unicidade de CPF/CNPJ (⚠️ verificar se o legado a garante) |

### CAD-04 · Cliente × Imóvel (papel + vigência)

| | |
|---|---|
| **Semântica** | A relação entre pessoa e imóvel tem **papel** (proprietário/usuário/responsável), **vigência** (início/fim), **motivo de encerramento** e indicação de **qual cliente dá nome à conta** — e o histórico de relações passadas precisa permanecer |
| **Representação atual** | 🟢 `cadastro.cliente_imovel`: `ClienteRelacaoTipo` (1/2/3), `clim_dtrelacaoinicio/fim` (ativa = fim nulo), `ClienteImovelFimRelacaoMotivo`, `clim_icnomeconta` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Modelo maduro com histórico embutido. **Reduzir a um `imovel.cliente_id` destruiria a responsabilização por período** — que é o que sustenta cobrança e negativação de dívida antiga. Três módulos consomem (Faturamento fotografa, Cobrança consulta por papel, Atendimento identifica solicitante) |
| **Impacto de migração** | Baixo — transformação 1:1 |
| **Validação** | Contagem por papel; nenhuma relação ativa duplicada por (imóvel, papel); vigências sem sobreposição inválida |

### CAD-05 · Economia — três representações concorrentes

| | |
|---|---|
| **Semântica** | 🟢 A **economia é a unidade tarifária**: tarifas mínimas e faixas aplicam-se por economia dentro da categoria. É preciso saber **quantas economias** o imóvel tem **por subcategoria**, e essa composição é o que governa o cálculo |
| **Representação atual** | ⚠️ 🟢 **Três representações concorrentes, sem entidade própria**: (a) `imovel_subcategoria.imsb_qteconomia` — agregada, **governa os processos**; (b) `imov_qteconomia` — total denormalizado, conveniência; (c) `imovel_economia` — individualizada, **só relatórios**, não participa do cálculo |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.2](#192-cad-05--economia-com-três-representações) |
| **Motivo** | 🔴 Três fontes para o mesmo dado, com apenas uma correta. Usar a errada muda o valor da conta. É o conceito mais central do sistema **sem forma explícita** |
| **Impacto de migração** | Médio — a fonte de verdade já é conhecida (a agregada) |
| **Validação** | 🔴 **Recálculo de contas**: as economias por categoria do SISAN devem reproduzir `conta_categoria.ctcg_qteconomia` das contas emitidas |

### CAD-06 · Categoria e Subcategoria com parâmetros de consumo

| | |
|---|---|
| **Semântica** | A classificação tarifária das economias, e os **limiares de análise de consumo** associados (consumo mínimo, estouro, vezes-média-estouro, média-baixo-consumo, consumo alto, máximo por economia) |
| **Representação atual** | 🟢 `cadastro.categoria` + `subcategoria` (FK `catg_id`); parâmetros como colunas da Categoria; imóvel guarda categoria/subcategoria **principal** como denormalização |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Categoria **não é rótulo — é parametrização**: a Micromedição usa seus limiares para criticar consumo e o Faturamento para mínimos. Estrutura simples, provada, usada por dois módulos |
| **Impacto de migração** | Baixo |
| **Transformação** | A denormalização "categoria principal" no imóvel segue `CAD-07` |
| **Validação** | Catálogo íntegro por instalação; limiares preservados valor a valor |

### CAD-07 · Denormalizações de conveniência no Imóvel

| | |
|---|---|
| **Semântica** | Consultas e telas precisam de acesso rápido a totais e classificação principal |
| **Representação atual** | 🟢 `imov_qteconomia`, `imov_idcategoriaprincipal`/`idsubcategoriaprincipal`, `rota_identrega`, `rota_idalternativa` |
| **Classificação** | **MODERNIZAR** · confiança **MÉDIA** |
| **Motivo** | São conveniências legítimas, não erros. 🔵 Podem virar projeções/derivações no SISAN — mas isso é decisão de forma, e a semântica não muda. ⚠️ **As rotas não são denormalização**: as três têm finalidades distintas comprovadas (leitura via quadra, entrega, override) — o que muda é a forma (três colunas × vínculo por finalidade) |
| **Impacto de migração** | Baixo — valores recalculáveis da fonte |
| **Validação** | Total derivado = total legado, imóvel a imóvel |

### CAD-08 · Ligação de Água e Esgoto — identidade compartilhada

| | |
|---|---|
| **Semântica** | 🟢 Cada imóvel tem **no máximo uma** ligação de água e uma de esgoto; a ligação tem características técnicas próprias, eventos datados (corte, supressão, religação, restabelecimento) e percentuais (esgoto/coleta/alternativo) que o Faturamento usa |
| **Representação atual** | ⚠️ 🟢 **PK compartilhada por construção**: `ligacaoAgua.setId(imovel.getId())`, FK `lagu_id → imov_id`. **O estado corrente mora no Imóvel** (`last_id`/`lest_id`), não na ligação. Não há tabela de histórico de situações da ligação — o detalhe dos eventos fica nas OSs |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.3](#193-cad-08--ligação-com-pk-compartilhada-e-estado-fora-da-entidade) |
| **Motivo** | 🔵 **Preservar a semântica 1:1 não exige preservar a PK compartilhada** — são duas decisões diferentes, e a pergunta do roteiro tem resposta clara: não exige. A PK compartilhada impede a ligação de ter ciclo de vida próprio e ancora o estado no lugar errado |
| **Impacto de migração** | 🟡 Médio-alto — o migrador precisa mapear `lagu_id = imov_id` para a nova chave, e **todas as FKs que apontam a ligação** |
| **Validação** | Toda ligação migrada resolve para o mesmo imóvel; estado corrente reproduz `last_id`/`lest_id` |

### CAD-09 · Estrutura territorial (Localidade → Setor → Quadra)

| | |
|---|---|
| **Semântica** | Hierarquia territorial-comercial estrita que organiza leitura, faturamento, cobrança, operação **e a abrangência de segurança** |
| **Representação atual** | 🟢 Gerência regional / unidade de negócio → Localidade (auto-relação elo/polo) → Setor Comercial → Quadra (+ face) → Imóvel (lote/sublote), com recortes operacionais na quadra (bairro, bacia, distrito, setor censitário) |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | Consolidada, atravessa todos os processos, é a base da abrangência (`SEG-03`) e do cronograma. Mudar traria risco alto e benefício baixo |
| **Impacto de migração** | Baixo — transformação direta |
| **Validação** | Integridade da hierarquia; contagem por nível; nenhum imóvel órfão |

### CAD-10 · Rota e suas três finalidades

| | |
|---|---|
| **Semântica** | 🟢 A rota organiza trabalho de campo **por finalidade**: leitura (via quadra), entrega de contas, e **override** para processos de leitura/análise com dispositivo móvel. Pertence a setor + grupo de faturamento; tem leiturista/empresa e tipo de leitura |
| **Representação atual** | 🟢 `micromedicao.rota`; quadra aponta a rota (`qdra.rota_id`); imóvel tem `rota_identrega` e `rota_idalternativa` |
| **Classificação** | **MODERNIZAR** · confiança **ALTA** |
| **Motivo** | 🔵 A semântica das três finalidades é real e **deve ser preservada** (a alternativa sobrepõe a da quadra — comprovado). O que pode melhorar é a **forma**: três caminhos distintos (uma FK indireta + duas colunas) para o mesmo tipo de vínculo |
| **Impacto de migração** | Baixo — mapeamento direto por finalidade |
| **Validação** | 🔴 Para cada imóvel, a rota **efetiva** de leitura resolvida no SISAN = a resolvida pelo legado (incluindo o caso de override) |

### CAD-11 · Extensões de companhia no núcleo do Cadastro

| | |
|---|---|
| **Semântica** | Programas sociais (tarifa social, classe social, economias sociais), recadastramento e identificadores externos existem e são necessários **para as companhias que os usam** |
| **Representação atual** | ⚠️ 🟢 Colunas no núcleo: `imov_classe_social`, `imov_qtd_economias_social`, exclusão de tarifa social, `numeroCelpe` (contrato de energia — nomenclatura de uma companhia), DV CAERN |
| **Classificação** | **EXIGE APROFUNDAMENTO** · confiança **BAIXA** |
| **Motivo** | ⚠️ Não há inventário das diferenças reais entre companhias (dúvida aberta em quatro mapas). Classificar agora seria decidir sem base. O que se pode afirmar: **nome de companhia no núcleo compartilhado é dívida** — mas se a *capacidade* é núcleo ou extensão, não se sabe |
| **O que falta** | Inventário de diferenças por companhia; decisão sobre modelo de extensibilidade (que depende da Visão Alvo) |

---

## 6. Micromedição

### MIC-01 · Hidrômetro (equipamento) e Instalação — a separação

| | |
|---|---|
| **Semântica** | 🟢 **Duas coisas distintas**: o *equipamento* tem identidade, características metrológicas e ciclo próprio (estoque → instalado → manutenção → baixa); a *instalação* é o **elo datado** entre equipamento e ligação/imóvel, com **leituras de fronteira** (instalação e retirada) que permitem calcular consumo no mês de troca |
| **Representação atual** | 🟢 `micromedicao.hidrometro` + `hidrometro_inst_hist` (vigente = `dataRetirada` nula); `MedicaoTipo` distingue ligação de água (1) × poço (2) |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 O GSAN acertou. A separação equipamento × instalação é exatamente o modelo correto, e as leituras de fronteira são o que torna a troca de hidrômetro calculável. É a estrutura mais bem desenhada do sistema |
| **Impacto de migração** | Baixo — migração do parque depende dela |
| **Validação** | Uma única instalação vigente por ligação/imóvel; continuidade das leituras de fronteira |

### MIC-02 · Ponteiro de instalação vigente no Imóvel/Ligação

| | |
|---|---|
| **Semântica** | Saber rapidamente qual hidrômetro está instalado agora |
| **Representação atual** | 🟢 `imovel.hidi_id` (poço) e `ligacao_agua.hidi_id` (água) apontam a instalação vigente |
| **Classificação** | **MODERNIZAR** · confiança **ALTA** |
| **Motivo** | É denormalização derivável (`dataRetirada IS NULL`). Útil, mas duplica a verdade — 🔵 risco de divergir. Forma pode melhorar; semântica não muda |
| **Impacto de migração** | Baixo — recalculável |
| **Validação** | Ponteiro derivado = ponteiro legado, instalação a instalação |

### MIC-03 · Leitura com par informado × faturamento

| | |
|---|---|
| **Semântica** | 🔴 **O que veio do campo nunca é sobrescrito pelo que vale para faturar.** Leitura anterior/atual, datas, situação e anormalidade existem em duas versões: informada e de faturamento |
| **Representação atual** | 🟢 `micromedicao.medicao_historico`, uma linha por imóvel/instalação/referência; `LeituraSituacao` (realizada/não realizada/confirmada/alterada); usuário que alterou |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 É **auditoria embutida no modelo** e a base da caracterização (Fase 2). Colapsar os pares destruiria a capacidade de explicar por que uma conta saiu com determinado valor |
| **Impacto de migração** | Baixo |
| **Validação** | Ambas as versões preservadas campo a campo; `mdhi_icanalisado` e usuário mantidos |

### MIC-04 · Consumo Histórico

| | |
|---|---|
| **Semântica** | 🟢 O resultado mensal por **imóvel + referência + tipo de ligação** (água e esgoto em linhas próprias), com **origem tipificada** (`ConsumoTipo`: real/média/mínimo/fixado/rateio) e **três valores distintos**: faturado, para cálculo de média, medido |
| **Representação atual** | 🟢 `micromedicao.consumo_historico` + versões anteriores em `consumo_hist_anterior`; rateio de condomínio referenciando o consumo do principal |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔴 Os três valores **não são redundância**: o faturado é o que virou dinheiro, o de média expurga anormalidades para não contaminar meses futuros, o medido é o fato bruto. Colapsá-los corrompe médias e críticas em cascata. A série pertence ao **imóvel**, não ao equipamento — por isso troca de hidrômetro não rompe histórico |
| **Impacto de migração** | Médio (volume alto) |
| **Validação** | 🔴 Recálculo de médias a partir do histórico migrado = médias do legado |

### MIC-05 · Anormalidades paramétricas (leitura e consumo)

| | |
|---|---|
| **Semântica** | 🟢 O catálogo de anormalidades **define comportamento**: qual consumo cobrar e qual leitura faturar **com** e **sem** leitura; se emite OS; e, no consumo, **fator e carta escalonados por mês de reincidência** (1º/2º/3º) |
| **Representação atual** | 🟢 `leitura_anormalidade` (+ `leitura_anorm_consumo`, `leitura_anorm_leitura`), `consumo_anorm_acao` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔴 Caso exemplar de **regra como dado**. Transformar em `enum` converteria configuração operacional em deploy — e o catálogo **varia por companhia**. Ver §15 |
| **Impacto de migração** | Baixo, mas **por instalação** (catálogos divergem) |
| **Validação** | Catálogo migrado integralmente; comportamento reproduzido por cenário |

### MIC-06 · Subclasses de controlador por companhia

| | |
|---|---|
| **Semântica** | Companhias têm diferenças reais de cálculo e processo |
| **Representação atual** | ⚠️ 🟢 Herança de controlador inteiro: `ControladorMicromedicao{CAEMA,CAER,CAERN,COMPESA,COSAMA,COSANPA,JUAZEIRO}SEJB` (padrão repetido em Faturamento, Cobrança e Arrecadação) |
| **Classificação** | **NÃO TRANSPORTAR** (o mecanismo) · confiança **ALTA** |
| **Motivo** | 🔵 Herdar um controlador inteiro para mudar um método é anti-padrão reconhecido. ⚠️ **A capacidade de variar permanece obrigatória** — o que não se transporta é a técnica |
| **Impacto de migração** | ⚠️ **Bloqueado**: o inventário de diferenças reais entre as 7 variantes **nunca foi feito** (dúvida em quatro mapas). Sem ele, não há como desenhar o ponto de extensão |
| **Validação** | Por companhia, resultado idêntico ao da subclasse correspondente |

---

## 7. Faturamento

### FAT-01 · Conta como documento financeiro

| | |
|---|---|
| **Semântica** | 🟢 O documento mensal de cobrança de um imóvel numa referência: valores de água e esgoto, débitos cobrados, créditos realizados, impostos, vencimento, situação — **reproduzível para sempre** |
| **Representação atual** | 🟢 `faturamento.conta` + satélites (`conta_categoria`, `cliente_conta`, `conta_impostos_deduzidos`) |
| **Classificação** | **PRESERVAR** (o conceito) · confiança **ALTA** |
| **Motivo** | Coração financeiro do sistema. O documento, sua composição e seus estados são adequados |
| **Impacto de migração** | 🔴 Crítico (volume + valor) |
| **Validação** | 🔴 Soma de valores por competência, com **tolerância zero** |

### FAT-02 · Identidade estável do documento (o mecanismo `*Geral`)

| | |
|---|---|
| **Semântica** | 🔴 **INEGOCIÁVEL**: referências externas (pagamento, cobrança, parcelamento, débito automático) apontam um identificador que **permanece válido quando o documento é arquivado**. É isso que permite pagar uma conta que já foi para o histórico |
| **Representação atual** | 🟢 `conta_geral` é entidade **física** cuja sequence origina o `cnta_id`, com `indicadorHistorico` e one-to-one para `conta`, `conta_historico` e `conta_impressao` — todas com o mesmo id (generator `assigned`). Padrão replicado em `guia_pagamento_geral`, `debito_a_cobrar_geral`, `credito_a_realizar_geral` |
| **Classificação** | ⚠️ **Semântica: PRESERVAR OBRIGATORIAMENTE** · **Estrutura: REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.4](#194-fat-02fat-03--identidade-estável-e-tabelas-espelho) |
| **Motivo** | 🔵 O mecanismo resolve um problema real de forma engenhosa — mas resolve-o com **uma tabela extra por tipo de documento**, existindo apenas para ser fonte de sequence e ponteiro. O problema (identidade que sobrevive ao arquivamento) tem soluções mais simples; a semântica é obrigatória, a forma não |
| **Impacto de migração** | 🔴 **Máximo** — todo `cnta_id` do legado precisa continuar resolvendo para o mesmo documento (§17) |
| **Validação** | 🔴 Para cada pagamento legado, o documento resolvido no SISAN é o mesmo |

### FAT-03 · Conta corrente × conta histórica (tabelas-espelho)

| | |
|---|---|
| **Semântica** | 🟢 O encerramento mensal **arquiva** documentos, mantendo-os consultáveis e **participantes de regras** (a classificação de pagamento busca no histórico; 2ª via reconstrói) |
| **Representação atual** | ⚠️ 🟢 Par de tabelas espelho por tipo (`conta`/`conta_historico`, e satélites: `conta_categoria_historico`, `conta_impostos_deduzidos_historico`…), movidas por batches de encerramento |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.4](#194-fat-02fat-03--identidade-estável-e-tabelas-espelho) |
| **Motivo** | 🔵 Duplicação estrutural que obriga **toda consulta relevante a saber dos dois lugares** — evidência direta: `classificarPagamentosConta` busca em ambas. Cada satélite dobra junto. O arquivamento é semântica real; a tabela-espelho é uma das formas de implementá-lo, não a única |
| **Impacto de migração** | Médio — a união das duas fontes é mecânica |
| **Validação** | Contagem corrente + histórico = contagem no SISAN; nenhuma conta perdida no merge |

### FAT-04 · Snapshots da Conta (contexto de cálculo)

| | |
|---|---|
| **Semântica** | 🔴 A conta **congela o contexto do cálculo** porque o original vai mudar: situações das ligações, percentuais de esgoto/coleta, tarifa, clientes da emissão, e categorias/economias/mínimos por categoria |
| **Representação atual** | 🟢 Colunas na conta (`last_id`, `lest_id`, `cnta_pcesgoto`, `cnta_pccoleta`, `cstf_id`) + `conta_categoria` + `cliente_conta` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔴 ⚠️ **Não tratar como desnormalização ruim.** O motivo é explícito no código: *"o percentual do imóvel pode mudar depois; a conta precisa reproduzir o cálculo original"*. Uma conta de 2019 precisa ser recalculável em 2026 com o imóvel já tendo mudado de categoria, percentual, tarifa e dono. **Remover destrói auditabilidade retroativa, e o sintoma só aparece meses depois** |
| **Impacto de migração** | Baixo (é cópia) |
| **Validação** | 🔴 Recálculo de amostra de contas antigas a partir **apenas** do snapshot migrado |

### FAT-05 · Linhagem por retificação

| | |
|---|---|
| **Semântica** | 🔴 Retificar **não altera** o documento: cria um **novo**, com **nova identidade**, ligado ao anterior por origem; o original muda de situação (RETIFICADA / CANCELADA_POR_RETIFICACAO) com motivo. É preciso sempre saber `A → retificada → B` |
| **Representação atual** | 🟢 `cnta_idorigem` apontando a `ContaGeral` original + `ContaMotivoRetificacao` + situações do documento |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Mecanismo correto, e **distinto** da identidade estável (`FAT-02`) — confundir os dois foi um erro já cometido e corrigido neste projeto. A linhagem é o que dá continuidade financeira **entre** documentos. O mesmo padrão aparece em RA reativado, OS de referência e reparcelamento |
| **Impacto de migração** | Médio — cadeias precisam ser remontadas na ordem |
| **Validação** | 🔴 Toda cadeia de retificação legada reconstruída integralmente; nenhum elo órfão |

### FAT-06 · Estrutura tarifária (tarifa → vigência → categoria/faixa)

| | |
|---|---|
| **Semântica** | 🟢 Tarifa atribuída ao imóvel, **versionada por data de vigência** (vale a maior data ≤ referência), com mínimo e valor por categoria, e faixas progressivas (início/fim/valor por m³) |
| **Representação atual** | 🟢 `consumo_tarifa` → `consumo_tarifa_vigencia` → `consumo_tarifa_categoria` + `consumo_tarifa_faixa` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Modelo paramétrico e versionado **exemplar** — resolve corretamente o problema de "tarifa muda, contas antigas não mudam". ⚠️ **A fórmula de aplicação das faixas está em código, com variantes por companhia** — isso é `FAT-07`, não esta linha |
| **Impacto de migração** | Baixo, mas **por instalação** |
| **Validação** | 🔴 Recálculo de contas por vigência, ao centavo |

### FAT-07 · Variação de cálculo por companhia dentro do núcleo

| | |
|---|---|
| **Semântica** | Companhias aplicam faixas/franquias de forma diferente |
| **Representação atual** | ⚠️ 🟢 **Três camadas simultâneas**: parametrização (tabelas), subclasses de controlador, **e métodos com nome de companhia dentro do núcleo compartilhado** — `calcularValorFaturadoFaixaCAER*` em `ControladorFaturamentoFINAL` |
| **Classificação** | **REESTRUTURAR** · confiança **MÉDIA** · detalhamento em [§19.5](#195-fat-07--variação-por-companhia-dentro-do-núcleo) |
| **Motivo** | 🔵 Nome de companhia no núcleo é dívida objetiva. ⚠️ Confiança **MÉDIA** e não alta porque **as diferenças reais nunca foram inventariadas** — sabe-se que o mecanismo é ruim, não o que exatamente ele faz de diferente |
| **Impacto de migração** | Nenhum sobre dados; total sobre a arquitetura de extensibilidade |
| **Validação** | 🔴 Por companhia: conta calculada no SISAN = conta da variante legada, ao centavo |

### FAT-08 · Precisão financeira — as cinco políticas de arredondamento

| | |
|---|---|
| **Semântica** | 🔴 **O arredondamento é regra de negócio por ponto de cálculo**, não uma política única |
| **Representação atual** | 🟢 Em `ControladorFaturamentoFINAL`: `HALF_UP` (27), `UP` (21), `DOWN` (5), `HALF_DOWN` (2), `FLOOR` (2) — **cinco políticas semânticas**; truncamento da base de cálculo de imposto (`:29943`). O utilitário `Util.arredondar` é consistente; o uso no controlador não |
| **Classificação** | **PRESERVAR (o comportamento)** · confiança **ALTA** |
| **Motivo** | 🔴 ⚠️ **Explicitamente: não classificar como dívida técnica apenas por serem diferentes.** "Corrigir para HALF_UP em tudo" alteraria valores cobrados do cliente sem decisão de negócio — e produziria divergência de centavos em massa contra o GSAN de referência. 🔵 O que **pode** ser modernizado é a *organização* (tornar cada política explícita e nomeada no ponto de cálculo); o *resultado* é intocável |
| **Impacto de migração** | Nenhum sobre dados; 🔴 **máximo sobre a reimplementação** |
| **Validação** | 🔴 Golden masters ponto a ponto. Este é o item de maior risco de equivalência financeira do projeto |
| **Observação** | Se alguma política vier a ser alterada deliberadamente, torna-se **divergência registrada e aprovada** — nunca decisão técnica silenciosa |

### FAT-09 · Débito e Crédito em dois momentos; Guia de Pagamento

| | |
|---|---|
| **Semântica** | 🟢 **Débito a cobrar** (lançamento com prestações, pendente) × **débito cobrado** (a parcela efetivamente incluída numa conta); espelho para crédito. A **Guia** é o caminho avulso, fora do ciclo mensal (entrada de parcelamento, serviço, pagamento parcial) |
| **Representação atual** | 🟢 `debito_a_cobrar`/`debito_cobrado`, `credito_a_realizar`/`credito_realizado`, `guia_pagamento` — todos com identidade estável `*Geral` e histórico |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 A distinção "lançado × efetivado" é semântica real e necessária: o débito existe antes de ter conta que o carregue. `DebitoTipo`/`CreditoTipo` carregam **contabilização** — são parametrização, não enum |
| **Impacto de migração** | Alto (volume), mecânica direta |
| **Validação** | Somatórios por tipo e competência |

### FAT-10 · Referência AAAAMM e referência contábil

| | |
|---|---|
| **Semântica** | 🟢 A **competência do ciclo comercial** (mês do consumo faturado) é distinta da **competência contábil** (que fecha depois) e da data de emissão. AAAAMM indexa leitura, consumo, conta, pagamento e arrecadação |
| **Representação atual** | 🟢 Inteiro `AAAAMM` em todas as entidades do ciclo; funções utilitárias no banco |
| **Classificação** | **PRESERVAR** (semântica) · confiança **ALTA** |
| **Motivo** | 🔵 É o **eixo temporal do sistema inteiro**. Se o SISAN adotar tipo mais expressivo internamente, o mapeamento é trivial — mas **a semântica de competência, e a distinção entre as duas referências, é obrigatória** |
| **Impacto de migração** | Baixo |
| **Validação** | Comparações financeiras por competência batem |

---

## 8. Cobrança

### COB-01 · Estoque de dívida como consulta

| | |
|---|---|
| **Semântica** | 🟢 "Quanto este imóvel/cliente deve" é uma **pergunta respondida por consulta** sobre documentos não quitados, com recortes (situação, vencimento, revisão, papel do cliente) — não há tabela de dívida |
| **Representação atual** | 🟢 `obterDebitoImovelOuCliente(...)`; consultas filtram por `dcst_idatual` e vencimento, carregando o motivo de revisão junto |
| **Classificação** | **PRESERVAR** (semântica) · confiança **ALTA** |
| **Motivo** | 🔵 **Contraintuitivo, mas correto**: manter a dívida como estado calculado evita o clássico problema de saldo desatualizado. A redução por pagamento acontece porque a consulta passa a deduzi-lo — não porque alguém escreveu num campo. Materializações/projeções por desempenho são decisão de forma, não de semântica |
| **Impacto de migração** | Nenhum (não há dado a migrar) |
| **Validação** | 🔴 Estoque calculado no SISAN = estoque calculado no legado, imóvel a imóvel, na mesma data-base |

### COB-02 · Obrigação financeira — conceito implícito

| | |
|---|---|
| **Semântica** | 🟢 Existe funcionalmente algo como "documento cobrável": **cinco alvos** convivem como destino de pagamento e como item de cobrança/parcelamento (Conta, Guia, Débito a Cobrar, Documento de Cobrança, Fatura) |
| **Representação atual** | ⚠️ 🟢 Cinco FKs opcionais no mesmo registro de `Pagamento`; cinco colunas de item no documento de cobrança; combinação equivalente no `parcelamento_item` |
| **Classificação** | **EXIGE APROFUNDAMENTO** · confiança **BAIXA** |
| **Motivo** | 🔵 O **problema estrutural é real e foi apontado independentemente por três mapas**. ⚠️ Mas duas coisas impedem decidir agora: (a) a semântica de **"Fatura"** (`faturamento.fatura`) nunca foi esclarecida — pode ser agrupamento de contas por cliente responsável, ou resíduo; (b) o roteiro é explícito: *não criar entidade nova ainda*. Registra-se o problema, não a solução |
| **O que falta** | Esclarecer "Fatura"; verificar se os cinco alvos têm ciclo de vida realmente comum |

### COB-03 · Documento de Cobrança com itens rastreáveis

| | |
|---|---|
| **Semântica** | 🟢 A ação de cobrança **materializa-se num documento por imóvel**, cujos **itens registram dívida a dívida**: qual documento foi atingido, valor cobrado, acréscimos, situação e data |
| **Representação atual** | 🟢 `cobranca_documento` + `cobranca_documento_item` (referenciando as identidades `*Geral` + prestação de contrato) + históricos próprios |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Auditoria dívida a dívida é exatamente o que se espera de um instrumento de cobrança. O documento é ainda **alvo pagável** — é entidade de primeira classe, não relatório |
| **Impacto de migração** | Médio (volume) |
| **Validação** | Soma dos itens = valor do documento; todos os itens resolvem para documentos existentes |

### COB-04 · Ação de Cobrança — workflow parametrizado

| | |
|---|---|
| **Semântica** | 🟢 A sequência de cobrança é **dado**: cada ação declara **predecessora**, critério de elegibilidade, situações de ligação alvo e **o tipo de serviço da OS que gera** |
| **Representação atual** | 🟢 `cobranca_acao` + `cobranca_criterio(_linha)` + cronogramas/comandos com filtros |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔴 Um dos pontos mais fortes do GSAN: **o workflow de cobrança é configurável sem código**. Mudar a escada (aviso → corte → supressão), os limiares ou o serviço gerado é alterar linhas de tabela. Ver §15 |
| **Impacto de migração** | Baixo, **por instalação** |
| **Validação** | Sequência e critérios reproduzidos; simulação de elegibilidade com o mesmo resultado |

### COB-05 · Parcelamento — composição e memória financeira

| | |
|---|---|
| **Semântica** | 🔴 A negociação preserva **duas coisas**: a **composição** (quais documentos originais entraram, item a item, por identidade ou versão histórica) e a **memória financeira integral** (valor de conta, serviços, atualização monetária, juros de mora, multa, débito atualizado, cada desconto, entrada, juros do parcelamento, nº e valor de prestações) |
| **Representação atual** | 🟢 `parcelamento` (memória) + `parcelamento_item` (composição) + prestações como débitos tipificados + estornos tipificados no desfazimento |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔴 É **o que torna o desfazimento exato**: sem a composição, não há como reativar exatamente o que foi consolidado; sem a memória, não há como estornar exatamente o que foi concedido. E o desfazimento automático por entrada não paga é regra estrutural de proteção. Mexer aqui é mexer em dinheiro de cliente |
| **Impacto de migração** | Alto (valor), mecânica direta |
| **Validação** | 🔴 Simulação de desfazimento sobre parcelamentos migrados reproduz os estornos legados |

### COB-06 · Negativação — domínio × integração

| | |
|---|---|
| **Semântica** | 🟢 **Duas coisas separadas**: (a) o **domínio** — negativar é do **cliente** (CPF/CNPJ) sobre dívida do imóvel, por comando com critérios parametrizados, com estado registrado na situação de cobrança do imóvel e movimentos de inclusão/exclusão; (b) a **integração** com o bureau |
| **Representação atual** | 🟢 `NegativacaoComando`/`Criterio` + `CobrancaSituacao` (11–15) + movimentos; integração via `gcom.spcserasa` e SOAP/Axis2 |
| **Classificação** | **(a) PRESERVAR · (b) MODERNIZAR** · confiança **ALTA** |
| **Motivo** | 🔵 O domínio está correto e é obrigação legal. A integração é transporte obsoleto (Axis2 1.5.1) — a capacidade permanece, o mecanismo troca. Ver `INT-04` |
| **Impacto de migração** | Baixo no domínio |
| **Validação** | Estado de negativação preservado por cliente; movimentos reconstruídos |

### COB-07 · Contadores de reincidência no Imóvel; acréscimos em código

| | |
|---|---|
| **Semântica** | 🟢 Reparcelamento é **novo parcelamento encadeado** com controle de reincidência; acréscimos por impontualidade (juros, multa, atualização) compõem a dívida |
| **Representação atual** | ⚠️ 🟢 Contadores denormalizados **no Imóvel** (`imov_nnparcelamento`, `nnreparcelamento`, `nnreparcmtconsec`) + funções de verificação de cadeia no banco. ⚠️ **Fórmulas de acréscimo estão em código** |
| **Classificação** | Contadores: **MODERNIZAR** · Acréscimos: **EXIGE APROFUNDAMENTO** · confiança **MÉDIA / BAIXA** |
| **Motivo** | Contadores são deriváveis da cadeia (parte do problema `CAD-02`). ⚠️ Os **acréscimos** atravessam Faturamento, Cobrança e Arrecadação e **nunca foram caracterizados** — dúvida aberta em dois mapas. Classificar sem a fórmula seria decidir no escuro |
| **O que falta** | Caracterização numérica das fórmulas de juros/multa/atualização |

---

## 9. Arrecadação

### ARR-01 · Separação recepção × classificação

| | |
|---|---|
| **Semântica** | 🔴 **O dinheiro é reconhecido antes de ser apropriado.** O pagamento nasce no processamento do movimento; a descoberta de qual obrigação ele quita é etapa posterior, em lote |
| **Representação atual** | 🟢 `ArrecadadorMovimento(Item)` → `Pagamento` (criado) → `classificarPagamentosDevolucoes` (lote, por localidade → imóvel → tipo de documento) |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Propriedade arquitetural valiosa: garante que **nada se perde** por não casar. É o que sustenta o tratamento do não classificado |
| **Impacto de migração** | Baixo (conceito, não estrutura) |
| **Validação** | Totais de recebido × classificado reproduzidos por competência |

### ARR-02 · Registro bruto do arquivo preservado

| | |
|---|---|
| **Semântica** | 🟢 A **linha original do arquivo** recebido é guardada, com totais de conferência do trailer (registros e valor) e aceitação por item |
| **Representação atual** | 🟢 `amit_cnregistro` (conteúdo do registro), `armv_nnregistrosmovimento`, `armv_vltotalmovimento`, `amit_icaceitacao`, NSA, versão de layout |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Permite auditoria e reprocessamento **a partir da origem** — capacidade rara e valiosa em sistema financeiro. Custo de armazenamento é irrelevante frente ao benefício |
| **Impacto de migração** | Alto (volume), mecânica trivial |
| **Validação** | Amostragem de reprocessamento a partir do registro bruto migrado |

### ARR-03 · Catálogo de situações do pagamento

| | |
|---|---|
| **Semântica** | 🔴 **Nenhum pagamento é descartado**: a impossibilidade de apropriar vira **estado** (duplicidade, documento inexistente, valor em excesso/a baixar/não confere, prescrito, parcelada, cancelada, erro de processamento, a contabilizar), **com situação anterior preservada** |
| **Representação atual** | 🟢 14 situações em `PagamentoSituacao` (constantes de código) + `pgst_idatual`/`pgst_idanterior` |
| **Classificação** | **Semântica: PRESERVAR · Forma: MODERNIZAR** · confiança **ALTA** |
| **Motivo** | 🔵 O catálogo **é** a semântica do módulo — migrar significados, não só códigos. ⚠️ Estar em **constantes de código** (e não em tabela de domínio governada) é a parte modernizável: impede acrescentar situação sem deploy e não documenta o significado no banco |
| **Impacto de migração** | Baixo — mapeamento de código para código |
| **Validação** | 🔴 Todo pagamento migrado mantém situação atual **e anterior** |

### ARR-04 · Identidade do Pagamento perdida no arquivamento

| | |
|---|---|
| **Semântica** | Um recebimento é um fato financeiro que precisa ser rastreável ao longo do tempo |
| **Representação atual** | ⚠️ 🟢 `arrecadacao.pagamento` usa `seq_pagamento`; ao ser arquivado, `PagamentoHistorico` usa **`seq_pagamento_historico`** — **o pagamento recebe novo identificador**. É a **única** exceção ao padrão `*Geral` do sistema |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.6](#196-arr-04--identidade-do-pagamento) |
| **Motivo** | 🔵 A pergunta do roteiro — *necessidade funcional ou limitação estrutural histórica?* — tem resposta com a evidência disponível: **limitação estrutural**. Nenhum mapa encontrou razão funcional para o recebimento perder identidade enquanto todos os documentos de dívida a preservam. 🔵 O sistema **inteiro** demonstra o padrão correto; este é o ponto onde ele não foi aplicado |
| **Impacto de migração** | 🟡 Médio-alto — pagamentos correntes e históricos precisam de identidade unificada, e o histórico pode ter colisões de id entre as duas sequences |
| **Validação** | 🔴 Nenhum pagamento duplicado após o merge; rastreabilidade pagamento↔documento preservada antes e depois do arquivamento |

### ARR-05 · Conciliação por Aviso Bancário

| | |
|---|---|
| **Semântica** | 🟢 O mecanismo de conciliação **é o par calculado × informado**: o GSAN calcula a partir dos pagamentos/devoluções processados e confronta com o valor informado pelo banco, com **acertos** e **deduções** (tarifas/retenções) como instrumentos de ajuste |
| **Representação atual** | 🟢 `AvisoBancario` (valores calculado/informado/realizado/contabilizado, datas prevista/realizada) + `AvisoAcerto` + `AvisoDeducoes` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Modelo de controle bancário real e correto. ⚠️ Nota: a máquina de estados formal do aviso (abertura/fechamento) **não foi comprovada** — mas isso é dúvida de comportamento, não de estrutura |
| **Impacto de migração** | Baixo |
| **Validação** | Conciliação recalculada reproduz calculado × informado do legado |

### ARR-06 · Devolução e Guia de Devolução; Débito Automático em três níveis

| | |
|---|---|
| **Semântica** | 🟢 **Devolução**: a saída de dinheiro é rastreada com o mesmo rigor da entrada — entidade própria, guia como instrumento, situações próprias, **duas competências**, e vínculo opcional com crédito a realizar. 🟢 **Débito automático**: três níveis distintos — opção do cliente, envio de **uma conta** ao banco (com NSA e código de retorno), e o pagamento efetivo pelo fluxo normal |
| **Representação atual** | 🟢 `Devolucao` + `GuiaDevolucao` + históricos; `DebitoAutomatico` + `DebitoAutomaticoMovimento` + `RetornoCodigo` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Ambos são distinções corretas que sistemas mais novos frequentemente erram (tratar devolução como pagamento negativo; confundir adesão com envio). Estruturas adequadas |
| **Impacto de migração** | Baixo |
| **Validação** | Devoluções por competência; adesões ativas por imóvel |

### ARR-07 · Layouts bancários embutidos no controlador

| | |
|---|---|
| **Semântica** | 🟢 O sistema precisa ler **layouts posicionais versionados** de arrecadação, ficha de compensação e cartão, validando por tipo de registro e versão |
| **Representação atual** | ⚠️ 🟢 Rotinas de validação **dentro de `ControladorArrecadacao`** (`validarArquivoMovimentoArrecadador`, `...ArquivosBanco`, `...FichaCompensacao`, header/trailer de cartão) |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.7](#197-arr-07--layouts-bancários-no-controlador) |
| **Motivo** | 🔵 Layout bancário é **contrato externo versionado** que muda por convênio e por banco, independentemente da regra de negócio. Tê-lo dentro do controlador de domínio significa que acrescentar um convênio mexe no núcleo financeiro |
| **Impacto de migração** | Nenhum sobre dados |
| **Validação** | 🔴 Reprocessar arquivos reais preservados (`amit_cnregistro`) produzindo os mesmos pagamentos |

---

## 10. Atendimento

### ATE-01 · RA e OS como identidades distintas

| | |
|---|---|
| **Semântica** | 🔴 O **RA é o compromisso** (protocolo da demanda, com prazo e responsabilidade); a **OS é o trabalho** (unidade de execução, com custo, prioridade e resultado). São conceitos diferentes com ciclos de vida próprios |
| **Representação atual** | 🟢 `registro_atendimento` e `ordem_servico`, cada uma com identidade, estados e marcos próprios; OS distingue **encerrada executada × encerrada não executada**; três marcos (geração, emissão, encerramento) |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Distinção madura. O RA é comunicado ao cliente (protocolo) e a OS é o instrumento operacional — fundi-los perderia tanto o compromisso quanto a execução. "Encerrar ≠ executar" é informação essencial para indicadores e para decidir se cobra o serviço |
| **Impacto de migração** | Médio (volume) |
| **Validação** | Contagem por estado; marcos temporais preservados |

### ATE-02 · Cardinalidade RA ↔ OS

| | |
|---|---|
| **Semântica** | 🟢 RA sem OS existe (demanda informativa); RA com várias OS existe; e há **origens de OS independentes de demanda individual** (cobrança, fiscalização coletiva, ordem seletiva) |
| **Representação atual** | ⚠️ 🟢 **Divergência mapping × banco**: DDL tem `ordem_servico.rgat_id NULL` e `registro_atendimento.imov_id NULL`, mas os mappings Hibernate declaram ambos `not-null="true"` |
| **Classificação** | **Semântica: PRESERVAR · Estrutura: EXIGE APROFUNDAMENTO** · confiança **BAIXA** |
| **Motivo** | ⚠️ ⚠️ **Não transformar em 1:1** — a semântica opcional nos dois sentidos está comprovada. Mas **a forma de persistência não está**: não se sabe se existem registros nulos, nem por qual caminho foram gravados. Decidir a cardinalidade física agora seria assumir desenho sem evidência |
| **O que falta** | 🔴 Verificar em dados reais: existem `rgat_id IS NULL` e `imov_id IS NULL`? Por qual caminho? |

### ATE-03 · `SolicitacaoTipoEspecificacao` — o núcleo paramétrico

| | |
|---|---|
| **Semântica** | 🔴 ~20 indicadores definem **quase todo o comportamento** do atendimento por tipo de demanda: prazo, obrigatoriedades (matrícula, cliente, solicitante, documento, parecer), pré-condições (ligação, débito), efeitos financeiros (gerar débito/crédito, valor, permite alterar, cobrar juros), geração de OS, urgência, encerramento automático, canal (loja virtual) e integrações específicas |
| **Representação atual** | 🟢 Colunas `step_ic*`/`step_nn*` numa única tabela |
| **Classificação** | **MODERNIZAR** · confiança **ALTA** |
| **Motivo** | 🔵 **A configurabilidade é a força do módulo e deve ser preservada** — mudar prazo, obrigatoriedade ou geração de OS é configuração, não código. ⚠️ O que justifica modernizar: (a) ~20 flags booleanas numa linha é difícil de compreender e evoluir; (b) 🔴 **não há versionamento aparente** — mudar uma flag muda o comportamento retroativamente para todos os RAs daquele tipo, sem histórico de quando mudou. ⚠️ Preservar a semântica **não é copiar a tabela** |
| **Impacto de migração** | Baixo, **por instalação** (a parametrização é a variabilidade do módulo) |
| **Validação** | 🔴 Por especificação, o comportamento resultante no SISAN = o do legado, cenário a cenário |

### ATE-04 · Tipo de Serviço (segundo nível de regra); Tramitação

| | |
|---|---|
| **Semântica** | 🟢 **Dois níveis de regra**: a especificação diz o que o cliente pediu; o **tipo de serviço** diz o que a companhia executa — e já traz valor, tempo médio, se atualiza comercial, se é terceirizado, e **o tipo de débito/crédito a lançar**. 🟢 A **tramitação** é histórico auditável: origem, destino, responsável, **quem registrou**, parecer — com `unid_idatual` como estado corrente |
| **Representação atual** | 🟢 `servico_tipo` (+ prioridade, subgrupo, perfil, referência); `Tramite` por RA |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 A separação dos dois níveis é real e correta. A tramitação distingue **responsável × quem registrou** — distinção deliberada e valiosa para auditoria, que sistemas mais simples costumam perder |
| **Impacto de migração** | Baixo |
| **Validação** | Cadeia de trâmites reconstruída na ordem; estado corrente coerente com o último trâmite |

### ATE-05 · Espera e Reiteração como campos agregados

| | |
|---|---|
| **Semântica** | 🟢 Um atendimento pode ficar **em espera** (aguardando terceiro/informação) e pode ser **reiterado** pelo solicitante — e ambos são sinais operacionais relevantes |
| **Representação atual** | ⚠️ 🟢 **Espera** = um par único de datas no próprio RA (`tminicioespera`/`tmfimespera`) → **múltiplas esperas sobrescrevem a anterior**. **Reiteração** = contador + data da última → **perde o histórico individual** (quem, quando, por qual canal) |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.8](#198-ate-05--espera-e-reiteração-sem-histórico) |
| **Motivo** | 🔵 Perda de informação **por construção**, não por decisão: o modelo não consegue representar o que acontece na operação real. Sem motivo da espera nem histórico de reiterações, indicadores de atendimento ficam incompletos e reclamações regulatórias não são reconstituíveis |
| **Impacto de migração** | Baixo — o que existe cabe no modelo novo como primeira ocorrência |
| **Validação** | Todo RA migrado preserva a espera e a contagem atuais |

### ATE-06 · Indicadores de efeito na OS; códigos de exibição

| | |
|---|---|
| **Semântica** | 🟢 **Indicadores de efeito**: é preciso saber se a atualização no domínio dono **já foi aplicada** por aquela OS (controle de idempotência e rastreabilidade). 🟢 **Códigos de exibição** (`RA_REFERENCIA`/`RA_ATUAL`/`RA_ANTERIOR`): nenhuma — são rótulos de tela |
| **Representação atual** | 🟢 `orse_iccomercialatualizado`, `orse_icatualizaagua`, `orse_icatualizaesgoto`, setados pelas Actions "Efetuar…". 🟢 Constantes de rótulo em `RegistroAtendimento` |
| **Classificação** | Indicadores: **MODERNIZAR** · Códigos de exibição: **NÃO TRANSPORTAR** · confiança **ALTA** |
| **Motivo** | 🔵 A **necessidade** por trás dos indicadores é legítima (saber se o efeito foi aplicado); a forma (flags booleanas) pode evoluir. ⚠️ **Não mover a propriedade do dado para o Atendimento**: quem é dono da situação da ligação continua sendo o Cadastro; da instalação, a Micromedição. Os códigos de exibição são artefato de UI do legado |
| **Impacto de migração** | Baixo |
| **Validação** | Nenhuma OS perde a marcação de efeito aplicado |

---

## 11. Segurança

> ⚠️ **Precedência**: as divergências D-01, D-02, D-03, D-06, D-07 e D-16 de [`divergencias-aprovadas.md`](divergencias-aprovadas.md) governam o **comportamento** desta área. As linhas abaixo tratam da **estrutura**, e não exigem equivalência técnica onde há divergência registrada.

### SEG-01 · Modelo conceitual de autorização (usuário, grupo, concessão)

| | |
|---|---|
| **Semântica** | 🟢 Usuário pertence a **grupos** (N:N); a concessão é o **trio grupo × funcionalidade × operação**; concessões de múltiplos grupos **se somam** (união, basta um conceder); dependência entre funcionalidades participa do cálculo |
| **Representação atual** | 🟢 `usuario`, `grupo`, `usuario_grupo`, `grupo_func_operacao`, `funcionalidade`(+`dependencia`), `operacao` |
| **Classificação** | **PRESERVAR** (modelo conceitual) · confiança **ALTA** |
| **Motivo** | 🔵 RBAC maduro, na granularidade certa, migrável 1:1. O comportamento de união é o que os usuários esperam. ⚠️ **O identificador das funcionalidades é outra decisão** — ver `SEG-02` |
| **Impacto de migração** | 🔴 Alto: perfis de acesso precisam ser migráveis sem reconfiguração manual |
| **Validação** | 🔴 Matriz perfil × funcionalidade reproduzida (com as divergências aprovadas aplicadas) |

### SEG-02 · Funcionalidade/Operação ancoradas em URL de Action

| | |
|---|---|
| **Semântica** | 🟢 Uma funcionalidade e uma operação precisam ser **identificáveis de forma estável** para que concessões durem |
| **Representação atual** | ⚠️ 🟢 Resolvidas por **`CAMINHO_URL`** — o identificador efetivo da concessão é o caminho HTTP da Action Struts (`/exibirManterConta.do` etc.) |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.9](#199-seg-02--concessão-ancorada-na-url-da-action) |
| **Motivo** | 🔴 **Problema de migração antes de ser problema de arquitetura**: o SISAN não terá URLs `.do`. Se a concessão é a URL, **todas as concessões de todas as instalações precisariam ser reconfiguradas manualmente** — inviável e propenso a erro de segurança |
| **Impacto de migração** | 🔴 **Bloqueante** sem chave estável |
| **Validação** | 🔴 Cada concessão legada mapeia para exatamente uma concessão no SISAN, sem perda nem ganho de permissão |

### SEG-03 · Abrangência territorial

| | |
|---|---|
| **Semântica** | 🔴 **PRESERVAR OBRIGATORIAMENTE**: recorte territorial hierárquico (gerência regional → unidade de negócio → elo/polo → localidade) que limita sobre quais dados o usuário atua. Requisito real de companhias multirregionais |
| **Representação atual** | ⚠️ 🟢 Estrutura adequada (`UsuarioAbrangencia` + eixos), **mas a aplicação é manual**: além do filtro, `verificarAcessoAbrangencia` / `existeLocalidadeForaDaAbrangenciaUsuario` são chamados explicitamente em Fachada, controladores e Actions — e no filtro só ocorre no ramo "operação", quando há contexto de abrangência |
| **Classificação** | **Conceito: PRESERVAR · Aplicação: REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.10](#1910-seg-03--abrangência-aplicada-manualmente) |
| **Motivo** | 🔴 Uma consulta nova que esqueça a checagem **vaza dados de outro território em silêncio** — e o sistema tem milhares de consultas. 🔵 Não é defeito de modelo, é defeito de **garantia**: o modelo está certo, a aplicação depende de disciplina humana. Herdar isso é herdar vazamento por omissão (LGPD) |
| **Impacto de migração** | Baixo sobre dados |
| **Validação** | 🔴 Cenário dirigido: usuário com abrangência restrita consultando dados fora dela em **cada** superfície de consulta |

### SEG-04 · Permissões especiais; ciclo de vida do usuário; solicitação de acesso

| | |
|---|---|
| **Semântica** | 🟢 **Permissões especiais** são capacidades **nomeadas** verificadas dentro da funcionalidade já autorizada, para exceções ("fazer sem RA", "alterar valor", "encerrar comando") — ampliam, não substituem. 🟢 **Situação, bloqueio de senha e expiração** são **eixos independentes** (`PENDENTE_SENHA` permite entrar para trocar a senha). 🟢 Existe **workflow de solicitação de acesso** por grupos, com situação própria |
| **Representação atual** | 🟢 `PermissaoEspecial` + `usuario_permissao_espec` + `grupo_permissao_especial` + `ControleLiberacaoPermissaoEspecial`; `UsuarioSituacao` + `dataExpiracaoAcesso` + `usuario_senha_historico` + `senha_invalida` + `usuario_periodo_bloqueio`; `SolicitacaoAcesso(+Grupo, +Situacao)` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔵 Os três são padrões maduros. Os nomes das permissões especiais **têm significado de negócio** e são conhecidos pelos operadores. Os três eixos de estado do usuário são semanticamente distintos e nenhum controle pode ser reduzido (regra explícita do registro de divergências). A solicitação de acesso é **governança**, não cadastro paralelo |
| **Impacto de migração** | Médio — atribuições por usuário e por grupo |
| **Validação** | 🔴 Nenhum controle atual reduzido; permissões especiais preservadas por nome |

### SEG-05 · Auditoria em dois níveis

| | |
|---|---|
| **Semântica** | 🟢 **Dois níveis acoplados**: operação efetuada (quem fez qual operação sobre quais objetos) e alteração de dados **por linha e coluna** |
| **Representação atual** | ⚠️ 🟢 `OperacaoEfetuada` + `RegistradorOperacao` (declarado programaticamente); `@ControleAlteracao` + `Interceptador` + `tabela_linha_alteracao`/`tab_linha_col_alteracao` — 🟢 **restrita ao que está anotado** |
| **Classificação** | **Semântica: PRESERVAR · Mecanismo: MODERNIZAR** · confiança **ALTA** |
| **Motivo** | 🔵 A granularidade (operação + linha/coluna) é exatamente o que uma auditoria financeira precisa. ⚠️ O que modernizar: **depender de anotar cada campo** significa que o que se esquece de anotar não gera trilha — e não há como saber o que falta. A necessidade é manter a trilha reduzindo a chance de omissão |
| **Impacto de migração** | Alto (volume de trilha histórica) — ⚠️ decidir se a trilha legada migra ou fica em arquivo consultável é decisão da Visão Alvo |
| **Validação** | Operações sensíveis geram trilha equivalente |

### SEG-06 · Mecanismos de autenticação e de sessão a substituir

| | |
|---|---|
| **Semântica** | Validar credencial; impedir força bruta; identificar sistemas que chamam APIs |
| **Representação atual** | ⚠️ 🟢 **SHA-1 sem salt** com autenticação por consulta que casa login+hash; **contagem de tentativas na sessão HTTP**; **token MD5 efêmero** para servlets auxiliares; pseudo-autenticação de API por host do próprio servidor; `FiltroSSO`/`FiltroSessaoExpirada` decorativos |
| **Classificação** | **NÃO TRANSPORTAR** · confiança **ALTA** · governado por **D-01, D-02, D-06, D-07** |
| **Motivo** | 🔵 A **semântica** (validar credencial, histórico de senha, blacklist, bloqueio, expiração) é preservada em `SEG-04`; o que não se transporta é o mecanismo. ⚠️ Contagem em sessão é contornável trocando de sessão — o bloqueio precisa ser por identidade, persistente |
| **Impacto de migração** | 🟡 A base de usuários migra; o hash legado só serve para validar **o primeiro login**, com re-hash imediato (D-01) |
| **Validação** | Todo usuário legado autentica na primeira vez e tem hash substituído; nenhum controle existente reduzido |

### SEG-07 · `UsuarioGrupoRestricao` (mecanismo de *deny*)

| | |
|---|---|
| **Semântica** | ❔ Aparentemente: "este usuário, neste grupo, **não** recebe esta concessão" |
| **Representação atual** | 🟢 A tabela e o mapping existem (vinculando `GrupoFuncionalidadeOperacao` e `UsuarioGrupo`). ⚠️ 🟢 **O uso no cálculo de autorização não foi observado** — os métodos `verificarAcessoPermitido*` consultam concessões e grupos, sem consulta visível à restrição |
| **Classificação** | **EXIGE APROFUNDAMENTO** · confiança **BAIXA** |
| **Motivo** | 🔴 ⚠️ **Decisão de alta prioridade que não pode ser tomada agora.** Define se o modelo do SISAN tem *deny* ou é allow-only — e isso muda o desenho da autorização inteira. Duas leituras possíveis: aplicada em outro ponto, ou estrutura pouco utilizada. **A existência da tabela não prova o uso** |
| **O que falta** | 🔴 Rastreio dirigido do cálculo de autorização + verificação de dados reais (há restrições cadastradas?) |

---

## 12. Batch

### BAT-01 · Modelo definição × execução em três níveis

| | |
|---|---|
| **Semântica** | 🟢 Processo → Etapa → Unidade, cada nível com **definição** (catálogo) e **execução** (instância com estado, tempos, parâmetros e erro persistidos **no banco**). A ordem das etapas é **dado** (`sequencialExecucao`); a unidade tem **identificador real da partição** |
| **Representação atual** | 🟢 `batch.processo`/`processo_iniciado`, `processo_funcionalidade`/`funcionalidade_iniciada`, `unidade_processamento`/`unidade_iniciada` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔴 O modelo responde, **sem log técnico**: quem pediu, quando, com quais parâmetros, quais etapas rodaram, qual partição falhou, qual foi o erro e o que já está concluído. Isso é observabilidade funcional de primeira classe, e é **independente da tecnologia** que orquestra |
| **Impacto de migração** | Baixo — histórico de execuções é operacional, não financeiro |
| **Validação** | Modelo reproduzido; cenários de retomada com o mesmo comportamento |

### BAT-02 · Retomada por unidade e autorização de processo

| | |
|---|---|
| **Semântica** | 🔴 **Unidade já concluída não é reexecutada** (reprocessar um processo não refaz o que terminou); falha é **por unidade**, com exceção persistida, e as demais seguem; reprocessamento é **por etapa**. 🟢 Processos sensíveis exigem **autorização** própria, distinta da permissão de operar a tela |
| **Representação atual** | 🟢 Verificação de `codigoRealUnidadeProcessamento` já `CONCLUIDA`; `Processo.indicadorAutorizacao` + estado `AGUARDANDO_AUTORIZACAO` |
| **Classificação** | **PRESERVAR** · confiança **ALTA** |
| **Motivo** | 🔴 Propriedade essencial em processamento financeiro: evita duplicar efeito de dinheiro ao reprocessar. ⚠️ **Nota honesta**: o framework garante **estado por unidade**, não atomicidade do trabalho dentro dela — isso não foi comprovado e deve ser caracterizado por processo |
| **Impacto de migração** | Nenhum sobre dados |
| **Validação** | 🔴 Reexecução de unidade concluída não refaz trabalho; reprocessamento por etapa retoma do ponto certo |

### BAT-03 · Contexto de execução serializado em bytes; infraestrutura de transporte

| | |
|---|---|
| **Semântica** | 🟢 **Contexto**: os parâmetros da execução precisam ser persistidos para sustentar reinício e auditoria. 🟢 **Transporte**: o trabalho precisa ser agendado, distribuído e paralelizado |
| **Representação atual** | ⚠️ 🟢 **Contexto**: a **tarefa inteira serializada em bytes** (`IoUtil.transformarObjetoParaBytes`) dentro de `FuncionalidadeIniciada`. ⚠️ **Transporte**: Quartz 1.5.2 + JMS + MDB (EJB 2.x), com `NotSupported` no MDB |
| **Classificação** | Contexto: **REESTRUTURAR** ([§19.11](#1911-bat-03--contexto-de-execução-serializado-em-bytes)) · Transporte: **NÃO TRANSPORTAR** · confiança **ALTA** |
| **Motivo** | 🔵 **Serialização Java de classes do legado amarra a migração**: o contexto só é legível por um processo que tenha exatamente aquelas classes no classpath. 🔵 O transporte **não é conceito de domínio** — EJB/MDB/JMS/Quartz antigo é infraestrutura; a capacidade (agendar, distribuir, paralelizar) permanece |
| **Impacto de migração** | 🟡 Execuções em andamento não migram (aceitável — são transitórias) |
| **Validação** | Contexto legível e reconstruível fora do runtime original |

---

## 13. Relatórios

### REL-01 · Três conceitos distintos; decisão automática online × batch

| | |
|---|---|
| **Semântica** | 🟢 **Definição** (tipo catalogado) × **tarefa** (solicitação executável parametrizada) × **artefato** (resultado materializado) são coisas diferentes. 🟢 A decisão online × assíncrono é **automática e prévia**: conta os registros que o relatório produziria e compara com um **limite por tipo**; sem limite configurado → sempre assíncrono |
| **Representação atual** | 🟢 `batch.relatorio`, `TarefaRelatorio`, `batch.relatorio_gerado`; limites em `constantes_execucao_relatorios.properties` (chave = nome simples da classe); autorização governada por parâmetro global |
| **Classificação** | Conceitos: **PRESERVAR** · Limites: **MODERNIZAR** · confiança **ALTA** |
| **Motivo** | 🔵 A separação em três conceitos é correta, e a decisão automática por volume é **um bom desenho** — protege o sistema sem exigir escolha do operador. ⚠️ O que modernizar: o limite está em **properties versionado, chaveado por nome de classe Java** — acoplamento ao código e fora de governança. A regra é parametrização e deveria viver como tal (§15) |
| **Impacto de migração** | Baixo |
| **Validação** | Mesma decisão online/batch para os mesmos volumes |

### REL-02 · Artefato persistido e seu acesso

| | |
|---|---|
| **Semântica** | 🟢 O relatório batch **produz artefato persistido** (binário + páginas) vinculado à execução e, por ela, ao solicitante — e o solicitante precisa poder recuperá-lo depois. 🔴 **E somente ele** |
| **Representação atual** | ⚠️ 🟢 `relatorio_gerado.rege_pdf` — **binário no banco**; recuperado por Action que localiza **apenas pelo `idFuncionalidadeIniciada` do request**, sem verificação de propriedade; alcançável sem usuário autenticado |
| **Classificação** | Artefato: **EXIGE APROFUNDAMENTO** · Controle de acesso: **NÃO TRANSPORTAR** (D-03) · confiança **MÉDIA / ALTA** |
| **Motivo** | 🔵 O **controle de acesso atual é achado de segurança confirmado** e tem divergência aprovada — não se discute. ⚠️ O **armazenamento** (binário no banco × storage externo) depende de retenção, volume e política de expiração, **nenhum dos três levantado**. Classificar agora seria opinião |
| **O que falta** | Volume e política de retenção/expiração dos artefatos |

### REL-03 · Serialização Java da tarefa de relatório; motor Jasper

| | |
|---|---|
| **Semântica** | 🟢 Os parâmetros da solicitação precisam ser preservados e a solicitação reconstruível; e é preciso um motor que preencha um template e exporte em formatos |
| **Representação atual** | ⚠️ 🟢 **Mesmo mecanismo do Batch**: tarefa serializada em bytes. 🟢 Motor: template `.jasper` compilado + `RelatorioDataSource` montado pela aplicação + exportador por tipo |
| **Classificação** | Serialização: **REESTRUTURAR** (mesmo caso de `BAT-03`) · Motor: **MODERNIZAR** · confiança **ALTA** |
| **Motivo** | 🔵 A serialização tem o mesmo problema estrutural do batch. 🔵 O **motor** é o caso mais claro de "conceito ≠ tecnologia": JasperReports **atual** está na arquitetura alvo e os `.jrxml` são reaproveitáveis — 🔵 o que é obsoleto é a **versão** (1.2.2), não o conceito. ⚠️ **A comparação de relatórios na validação é semântica, nunca byte a byte de PDF** |
| **Impacto de migração** | Baixo (templates são reaproveitáveis) |
| **Validação** | Comparação sobre o datasource ou o conteúdo extraído |

---

## 14. Integrações

> ⚠️ **Regra do roteiro aplicada**: para cada integração, **capacidade funcional**, **contrato** e **implementação técnica** são classificados separadamente. Nada é preservado só porque a integração existe.

### INT-01 · Camada de integração — a estrutura ausente

| | |
|---|---|
| **Semântica** | 🟢 O sistema precisa falar com o mundo externo com **política comum**: autenticação da origem, identidade rastreável atravessando a fronteira, erro durável e observável, segredo fora do código, transporte cifrado |
| **Representação atual** | ⚠️ 🟢 **Não existe camada**: sete padrões técnicos independentes, criados em momentos diferentes. O pacote `gcom.integracao` cobre **uma** integração; as demais vivem em Actions, servlets, utilitários e controladores de negócio |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · detalhamento em [§19.12](#1912-int-01--camada-de-integração-inexistente) |
| **Motivo** | 🔵 Não é "melhorar uma camada" — é **criar a que nunca existiu**. O espectro atual vai de OAuth2 com credencial em banco (`INT-03`) a chave de API em constante Java (`INT-04`), e essa desigualdade é consequência direta da ausência de política |
| **Impacto de migração** | Nenhum sobre dados |
| **Validação** | Toda integração do SISAN autentica a origem e registra erro de forma durável |

### INT-02 · Capacidades funcionais de campo e móvel

| | |
|---|---|
| **Semântica** | 🔴 **Capacidades legítimas que devem sobreviver**: baixar rota para coletor, enviar movimento de leitura, finalizar leitura; listar OS programadas, encerrar OS, enviar fotos; receber telemetria; consultar GIS |
| **Representação atual** | ⚠️ 🟢 **Implementações a descartar**: protocolo binário por opcode sem autenticação; servlet com estado de instância e despacho por `contains()`; endpoints de escrita sem credencial; assinatura DSA cobrindo apenas o login (portador estático) |
| **Classificação** | **Capacidade: PRESERVAR · Implementação: NÃO TRANSPORTAR** · confiança **ALTA** · governado por **D-04, D-05, D-10, D-11** |
| **Motivo** | 🔵 ⚠️ **A distinção é o ponto**: descartar a implementação junto com a capacidade seria perda de escopo — coleta em campo e OS móvel são requisitos operacionais reais. 🔴 A leitura de hidrômetro alimenta consumo → faturamento: entrada sem autenticação é superfície de **fraude de faturamento**, não incidente de TI |
| **Impacto de migração** | Nenhum sobre dados; contratos precisam ser renegociados com os dispositivos |
| **Validação** | Cada capacidade preservada com autenticação de dispositivo comprovada |

### INT-03 · Integração por banco compartilhado (UPA/SAM)

| | |
|---|---|
| **Semântica** | 🟢 Trocar ordens de serviço com um executante terceirizado: exportar OS a executar, receber de volta as executadas, encerrar no GSAN, notificar a empresa |
| **Representação atual** | ⚠️ 🟢 **Segunda `SessionFactory`**: o GSAN **insere diretamente no banco do sistema parceiro**; idempotência por `ConstraintViolationException` engolida; identidade atravessa como **string de login**; falha de resolução → `continue` + `System.out`, **sem registro durável** |
| **Classificação** | **REESTRUTURAR** · confiança **ALTA** · governado por **D-12** · detalhamento em [§19.13](#1913-int-03--integração-por-banco-compartilhado) |
| **Motivo** | 🔴 **Acoplamento máximo com observabilidade mínima**: o contrato é o schema alheio (muda sem aviso) e a OS fica presa no limbo sem que ninguém saiba. A capacidade é legítima; a forma é a pior possível |
| **Impacto de migração** | Nenhum sobre dados do GSAN; exige renegociar o contrato com o parceiro |
| **Validação** | Nenhuma OS perdida em silêncio; toda rejeição em fila consultável |

### INT-04 · `GsanApi` (OAuth2) × `ServicoSMS` (chave em código)

| | |
|---|---|
| **Semântica** | Consumir serviços externos autenticando-se corretamente; notificar clientes por SMS |
| **Representação atual** | 🟢 **`GsanApi`**: OAuth2 *client credentials*, URL e credenciais vindas do **banco** (`SegurancaParametro` / `obterCredenciaisOauth`), Bearer token. ⚠️ 🟢 **`ServicoSMS`**: chave de API em **constante Java** e em properties versionado; URL `http://` fixa; `inicializarPropriedades()` retorna `null`; `tipoMensagem` **ignorado** (todo SMS envia o texto de cadastro no Portal) |
| **Classificação** | `GsanApi`: **PRESERVAR** (como padrão de referência) · `ServicoSMS`: **NÃO TRANSPORTAR** · confiança **ALTA** · governado por **D-08, D-09, D-13** |
| **Motivo** | 🔵 O contraste é o achado: **a competência existia dentro do próprio código**. O `GsanApi` é o padrão mais próximo do alvo em todo o repositório e serve de referência interna ao desenhar `INT-01`. O `ServicoSMS` acumula segredo comprometido, transporte em claro, configuração inerte e **defeito funcional que alcança o cliente final** |
| **Impacto de migração** | Nenhum sobre dados; ⚠️ **a chave de SMS está em rotação obrigatória** |
| **Validação** | Nenhum segredo em código; cada tipo de SMS envia sua mensagem |

---

## 15. Parametrizações — análise transversal

🔴 **O princípio**: *não transformar regra configurável em código fixo.* Esta é a característica mais forte da identidade do GSAN e a que mais corre risco numa reescrita — a tentação natural de um desenvolvedor é converter tabela paramétrica em `enum`.

| Família paramétrica | O que a linha decide | Classificação | Confiança |
| ------------------- | -------------------- | ------------- | --------- |
| **Situação de ligação** | Fatura ou não · consumo mínimo · "só consumo real" · dias para corte | **PRESERVAR** | ALTA |
| **Categoria** (limiares de consumo) | Estouro, alto, baixo, vezes-média, máximo por economia | **PRESERVAR** | ALTA |
| **Anormalidade de leitura** | Consumo a cobrar e leitura a faturar, com/sem leitura · emite OS | **PRESERVAR** | ALTA |
| **Anormalidade de consumo** | Fator e carta por mês de reincidência (1º/2º/3º) | **PRESERVAR** | ALTA |
| **Tarifa** (vigência/categoria/faixa) | Mínimos e valores por m³, por vigência datada | **PRESERVAR** | ALTA |
| **Situação especial de faturamento** | Paralisar emissão · faturar média · faturar taxa mínima | **PRESERVAR** | ALTA |
| **Cronograma do ciclo** | Datas das 8 atividades mensais por rota | **PRESERVAR** | ALTA |
| **Ação de cobrança** | Predecessora · critério · situações-alvo · tipo de OS gerada | **PRESERVAR** | ALTA |
| **Critério de elegibilidade** | Valores/quantidades mínimos e máximos | **PRESERVAR** | ALTA |
| **Parcelamento** (faixas/descontos) | Máximo de prestações · juros · entrada mínima · descontos | **PRESERVAR** | ALTA |
| **Tipos de débito/crédito** | Semântica do lançamento **+ contabilização** | **PRESERVAR** | ALTA |
| **Especificação da solicitação** | ~20 indicadores de comportamento do atendimento | **MODERNIZAR** (forma + versionamento) | ALTA |
| **Tipo de serviço** | Valor, efeitos, débito/crédito a lançar | **PRESERVAR** | ALTA |
| **Processo/Etapa/Unidade** (batch) | Quais etapas, em que ordem, com que partição | **PRESERVAR** | ALTA |
| **Funcionalidade/Operação/Grupo** | Quem pode fazer o quê | **PRESERVAR** (modelo) / **REESTRUTURAR** (chave — `SEG-02`) | ALTA |
| **Limite online de relatório** | Quantos registros cabem em execução interativa | **MODERNIZAR** (sair de properties) | ALTA |

### 15.1 Duas observações que valem para toda a tabela

⚠️ **1 — Nenhuma família paramétrica é `NÃO TRANSPORTAR`.** Isso não é coincidência: é a evidência de que o padrão "regra como dado" está entre as decisões mais acertadas do GSAN.

⚠️ **2 — Falta versionamento em quase todas.** 🔵 Mudar uma linha paramétrica altera o comportamento **retroativamente**, sem histórico de quando mudou nem de qual valor vigia antes. Para a maioria isso é tolerável; para **tarifa** o GSAN resolveu (vigência datada) — e é justamente a prova de que o problema é conhecido. 🟡 **Hipótese, não decisão**: parametrização versionada e governada como capacidade transversal (§21).

### 15.2 O que **não** é parametrizado — e não deve ser confundido

🟢 Ficou deliberadamente em código: fórmula de faixas e distribuição por economia, **modos de arredondamento**, fluxo de retificação/cancelamento, fórmulas de acréscimos, fluxo de desfazimento, layouts bancários, retenções tributárias, situações de pagamento, cálculo de dias úteis, atualização cadastral pela execução.

🔵 **Leitura**: o GSAN parametriza **o quê** e **quando**; deixa em código **como se calcula**. É divisão coerente, e o SISAN herda exatamente essa, não outra. ⚠️ Transformar cálculo em parametrização seria erro simétrico ao de transformar parâmetro em código.

---

## 16. Histórico, versão, linhagem e snapshot — análise transversal

🔴 ⚠️ **Os quatro mecanismos parecem a mesma coisa e resolvem problemas diferentes.** O roteiro é explícito: **não unificá-los num mecanismo genérico apenas por arquitetura**.

| Mecanismo | Problema que resolve | Exemplos | Classificação | Confiança |
| --------- | -------------------- | -------- | ------------- | --------- |
| **① Histórico temporal** (série) | "Como estava em cada período" — o dado **nasce** por período | Consumo e medição por imóvel+referência; instalações sucessivas; trâmites | **PRESERVAR** | ALTA |
| **② Versionamento** (corrente/arquivado) | "O documento saiu do fluxo corrente, mas continua existindo e sendo referenciado" | Conta → conta_historico (idem guia, débito, crédito); pagamento → histórico | **Semântica: PRESERVAR · Forma: REESTRUTURAR** (`FAT-03`, `ARR-04`) | ALTA |
| **③ Linhagem** (substituição) | "Este documento substituiu aquele" — identidades **diferentes**, encadeadas | Retificação (`cnta_idorigem`); RA reativado/duplicado; OS de referência; reparcelamento | **PRESERVAR** | ALTA |
| **④ Snapshot** (fotografia) | "O contexto do cálculo mudou depois, e preciso reproduzir o original" | Conta (situações, percentuais, tarifa, clientes, categorias/economias); parcelamento (memória financeira) | **PRESERVAR** | ALTA |

### 16.1 Por que não unificar

🔵 Cada um tem **regra de escrita, de leitura e de retenção diferente**:

- ① é escrito **uma vez por período** e lido em série;
- ② é escrito **por evento de arquivamento** e precisa ser lido **junto** com o corrente (a classificação de pagamento busca nos dois);
- ③ é escrito **por decisão de negócio** (retificar, reativar) e lido como cadeia;
- ④ é escrito **no ato da operação** e é **imutável para sempre** — nunca é atualizado.

🔵 Um "mecanismo genérico de histórico" precisaria satisfazer os quatro contratos ao mesmo tempo, e o resultado provável seria satisfazer mal os quatro. ⚠️ Essa é a razão técnica de manter a distinção — não conservadorismo.

### 16.2 A confusão a evitar

🔴 **② versionamento ≠ ③ linhagem.** Este projeto já cometeu esse erro uma vez e o corrigiu:

```text
② A conta ARQUIVADA mantém o MESMO id            → identidade estável
③ A conta RETIFICADORA tem id NOVO + origem      → linhagem
```

Tratá-los como um só mecanismo quebra pagamento, cobrança e parcelamento de contas retificadas.

---

## 17. Identificadores e compatibilidade

🔴 Seção decisiva para o futuro migrador. Quatro tratamentos possíveis:

| Tratamento | Significado |
| ---------- | ----------- |
| **EXTERNO IGUAL** | O valor deve continuar o mesmo e visível ao usuário |
| **PRESERVADO NA MIGRAÇÃO** | O valor precisa resolver para o mesmo objeto; não é necessariamente exibido |
| **NOVO COM ORIGEM** | Pode receber novo identificador desde que a chave legada fique registrada |
| **A DECIDIR** | Sem evidência suficiente |

| Identificador | Tratamento | Justificativa | Confiança |
| ------------- | ---------- | ------------- | --------- |
| **Matrícula do imóvel** (`imov_id` + DV) | 🔴 **EXTERNO IGUAL** | Impressa em contas, usada em atendimento, conhecida por clientes. Mudar exigiria recomunicar toda a base | ALTA |
| **Cliente** (`clie_id`; CPF/CNPJ) | **PRESERVADO NA MIGRAÇÃO** | CPF/CNPJ é a chave de negócio natural; o id interno pode ser novo com origem | ALTA |
| **Hidrômetro** (nº de série) | 🔴 **EXTERNO IGUAL** (o nº de série) / **NOVO COM ORIGEM** (o id) | O número de série é patrimônio físico, gravado no equipamento | ALTA |
| **Conta / ContaGeral** (`cnta_id`) | 🔴 **PRESERVADO NA MIGRAÇÃO** (obrigatório) | Referenciado por pagamento, cobrança, parcelamento, débito automático e itens de documento. É o identificador mais referenciado do sistema financeiro | ALTA |
| **Guia de Pagamento** | **PRESERVADO NA MIGRAÇÃO** | Mesmo padrão; e a guia é impressa e paga | ALTA |
| **Débito a Cobrar** | **PRESERVADO NA MIGRAÇÃO** | Alvo de pagamento e item de parcelamento | ALTA |
| **Parcelamento** (`parc_id`) | **PRESERVADO NA MIGRAÇÃO** | Cadeia de reparcelamento e contadores dependem; e é referenciado pelas contas INCLUIDA | ALTA |
| **Pagamento** (`pgmt_id`) | ⚠️ **A DECIDIR** | 🔴 Complicado por `ARR-04`: correntes e históricos vêm de **sequences distintas** e podem colidir. A decisão depende de resolver a identidade primeiro | MÉDIA |
| **RA** (`rgat_id`) | 🔴 **EXTERNO IGUAL** | É **protocolo comunicado ao cliente** — o cliente liga citando o número | ALTA |
| **OS** (`orse_id`) | **PRESERVADO NA MIGRAÇÃO** | Referenciada por débito de serviço, documento de cobrança e execução em campo | ALTA |
| **Usuário** (login) | 🔴 **EXTERNO IGUAL** (o login) | O usuário digita o login; mudá-lo é retreinar a base inteira | ALTA |
| **Referência AAAAMM** | 🔴 **EXTERNO IGUAL** (a semântica) | Eixo temporal de todas as comparações financeiras | ALTA |

### 17.1 Estratégia de *legacy id* — hipótese, não padrão

⚠️ O roteiro é explícito: **não decidir automaticamente que toda PK do GSAN vira PK do SISAN**.

🟡 **Hipótese registrada** (não decisão, não implementação): para identificadores classificados **NOVO COM ORIGEM**, um trio conceitual

```text
identificador do SISAN  +  origem (qual instalação GSAN)  +  identificador legado
```

resolveria dois problemas simultâneos: (a) o SISAN não fica preso às sequences do legado; (b) o migrador consegue reconciliar e validar. 🔵 A **origem** importa porque a ADR-0005 é explícita: *o SISAN não assume schema único entre companhias* — dois GSANs distintos podem ter `imov_id = 1000` referindo imóveis diferentes.

⚠️ **Não tornar padrão automático**: para os identificadores **EXTERNO IGUAL**, o trio é desnecessário e acrescenta indireção. A decisão de onde aplicá-lo é da Visão Conceitual Alvo.

---

## 18. Estruturas não transportadas

⚠️ Classificadas **por família**, não tabela a tabela. Em todos os casos: **nada precisa ser removido do `gsan_comercial`** (que não é o banco alvo) — o migrador **ignora e relata**.

| Família | Padrões observados | Origem | Ação do migrador |
| ------- | ------------------ | ------ | ---------------- |
| **Backups manuais** | `bkp_*`, `backup_*`, `clientes_backup*` | 🟢 ~212 tabelas em `public`, criadas em manutenções | **Ignorar e relatar** (contagem + nomes) |
| **Cópias por RM / competência** | `*_rm<numero>`, `*_20xx`, `atu_fat_sit_especial_*` | Manutenções referenciando RMs e competências até 2026 | **Ignorar e relatar** |
| **Objetos de DBA** | schema `admindb` (rotinas de backup, vacuum, versão de base) | Operação do banco legado | **Ignorar** — não é domínio |
| **Infraestrutura de runtime legado** | Tabelas/filas do Quartz 1.5.2, artefatos JBoss, deployments EJB por companhia | Tecnologia | **Ignorar** — substituída |
| **Mecanismos de segurança inadequados** | Hash SHA-1 no login, token MD5, pseudo-autenticação por host, filtros decorativos | ⚠️ D-01, D-02, D-06, D-07 | **Migrar apenas o hash** (uso único no primeiro login, com re-hash); descartar o resto |
| **Artefatos de UI do legado** | Códigos de exibição RA referência/atual/anterior; applet de impressão térmica | Rótulos e tecnologia de tela | **Ignorar** |

⚠️ **Nota de tolerância**: o migrador deve **tolerar objetos extras** em instalações reais — o `gsan_comercial` prova que instalações acumulam DDL manual fora das migrations. Encontrar tabela desconhecida é situação **esperada**, e deve gerar relatório, não falha.

---

## 19. Decisões REESTRUTURAR

> Cada subseção responde obrigatoriamente as seis perguntas do critério: **problema · benefício · semântica a preservar · transformação · risco · validação**.
>
> 13 subseções cobrem as 15 decisões que tocam `REESTRUTURAR`: **§19.4 trata `FAT-02` e `FAT-03` juntas** (mesmo mecanismo físico) e **`REL-03` é a mesma reestruturação de `BAT-03`**, tratada em §19.11 com dois consumidores.

### 19.1 · CAD-02 — Estado de outros domínios dentro do Imóvel

| | |
|---|---|
| **Problema** | 🟢 O registro do imóvel guarda **estado que pertence a outros domínios**: situação das ligações (Cadastro/Atendimento), situação de cobrança e contadores de parcelamento (Cobrança), parâmetros de faturamento. 🔵 Isso força Cobrança e Atendimento a escreverem no agregado do Cadastro, e é causa estrutural do acoplamento |
| **Benefício** | Fronteiras de módulo reais (ADR-0001); cada domínio dono do seu estado; fim da escrita cruzada no agregado alheio |
| **Semântica a preservar** | 🔴 **Toda**: cada estado continua existindo e consultável pelos mesmos processos. Em particular, a situação da ligação continua comandando faturabilidade e cobrança |
| **Transformação** | Redistribuição de colunas para os domínios donos, preservando o vínculo com o imóvel. Sem perda de informação — é remapeamento, não conversão |
| **Risco** | 🟡 **Médio**: se algum consumidor não for encontrado, passa a ler estado desatualizado. O risco é de **cobertura**, não de dado |
| **Validação** | Para cada imóvel: estado reconstruído = estado legado, coluna a coluna. E: inventário de todos os leitores das colunas migradas |

### 19.2 · CAD-05 — Economia com três representações

| | |
|---|---|
| **Problema** | 🟢 Três representações concorrentes do mesmo conceito, com apenas uma governando o cálculo (a agregada por subcategoria). 🔴 Usar a errada muda o valor da conta, e nada no modelo indica qual é a certa |
| **Benefício** | Uma fonte de verdade para a unidade tarifária; fim da ambiguidade; cálculo auditável |
| **Semântica a preservar** | 🔴 **Quantidade e composição tarifária**: quantas economias o imóvel tem, **por subcategoria** — é isso que alimenta mínimos e faixas. ⚠️ A individualizada e o total denormalizado precisam ser **avaliados separadamente**: a primeira pode ter valor informativo real; o segundo é derivável |
| **Transformação** | A agregada é a fonte; o total é derivado; a individualizada **exige decisão própria** (⚠️ não se sabe se é populada em todas as instalações — dúvida aberta) |
| **Risco** | 🔴 **Alto se mal feito**: erro sistemático de valor em todas as contas. Baixo se a fonte correta for respeitada |
| **Validação** | 🔴 Economias por categoria no SISAN = `conta_categoria.ctcg_qteconomia` das contas emitidas, imóvel a imóvel |
| **⚠️ Parar aqui** | A **representação alvo** é decisão da Visão Conceitual Alvo |

### 19.3 · CAD-08 — Ligação com PK compartilhada e estado fora da entidade

| | |
|---|---|
| **Problema** | 🟢 A ligação usa o id do imóvel como PK e **não guarda o próprio estado** (que mora no imóvel). 🔵 Consequência: a ligação não tem ciclo de vida próprio, e o estado está no lugar errado para quem precisa dele |
| **Benefício** | Ligação com identidade e ciclo próprios; estado junto da entidade a que pertence; possibilidade de histórico de situações (hoje inexistente) |
| **Semântica a preservar** | 🔴 **Cardinalidade 1:1 com o imóvel** (no máximo uma ligação de cada tipo); características técnicas; eventos datados; percentuais usados pelo Faturamento; e a **situação continuar comandando faturabilidade** |
| **Transformação** | Mapear `lagu_id = imov_id` para a nova chave e **reapontar todas as FKs** que hoje referenciam a ligação; mover o estado corrente para a ligação |
| **Risco** | 🟡 **Médio-alto**: a PK compartilhada é assumida implicitamente em consultas e joins do legado — o inventário de dependências precisa ser completo |
| **Validação** | Toda ligação migrada resolve para o mesmo imóvel; estado corrente reproduz `last_id`/`lest_id`; faturabilidade recalculada idêntica |
| **⚠️ Nota** | 🔵 **Preservar a semântica 1:1 não exige preservar a PK compartilhada** — resposta direta à pergunta do roteiro |

### 19.4 · FAT-02/FAT-03 — Identidade estável e tabelas-espelho

| | |
|---|---|
| **Problema** | 🟢 **Duas estruturas ligadas**: (a) uma tabela extra por tipo de documento (`*_geral`) existe apenas para ser fonte de sequence e ponteiro; (b) o arquivamento cria **tabelas-espelho** que obrigam toda consulta relevante a saber dos dois lugares — evidência direta: `classificarPagamentosConta` busca em `Conta` **e** `ContaHistorico`. Cada satélite dobra junto |
| **Benefício** | Uma consulta em vez de duas por documento; menos estruturas para manter sincronizadas; menos chance de esquecer o histórico numa consulta nova |
| **Semântica a preservar** | 🔴 **INEGOCIÁVEL — duas coisas distintas**: (1) **identidade que sobrevive ao arquivamento** — todo `cnta_id` legado continua resolvendo para o mesmo documento; (2) **o documento arquivado continua participando de regras**, não é depósito morto |
| **Transformação** | União das duas fontes por tipo de documento, preservando o identificador e a marcação de arquivado |
| **Risco** | 🔴 **Alto**: é o núcleo financeiro. Uma conta perdida no merge é uma dívida ou um pagamento órfão |
| **Validação** | 🔴 Contagem corrente + histórico = contagem no SISAN, por tipo e competência; **para cada pagamento legado, o documento resolvido é o mesmo**; nenhum id duplicado |
| **⚠️ Parar aqui** | Como representar "arquivado" (coluna, partição, outra estrutura) é decisão da Visão Alvo |

### 19.5 · FAT-07 — Variação por companhia dentro do núcleo

| | |
|---|---|
| **Problema** | 🟢 Três camadas simultâneas de variação, sendo a pior **métodos com nome de companhia dentro do controlador compartilhado**. 🔵 Efeito: o núcleo financeiro carrega código de clientes específicos, e mudar a regra de uma companhia arrisca todas |
| **Benefício** | Núcleo genérico; variação explícita e testável por companhia; possibilidade de acrescentar companhia sem tocar no núcleo |
| **Semântica a preservar** | 🔴 **O resultado de cada companhia, ao centavo.** Cada variante calcula o que calcula hoje |
| **Transformação** | Nenhuma sobre dados — é reorganização de código. ⚠️ **Mas depende de um inventário que não existe** |
| **Risco** | 🔴 **Alto e mal dimensionado**: não se sabe o que as 7 variantes fazem de diferente. Generalizar sem inventário produziria um ponto de extensão que não cobre os casos reais |
| **Validação** | 🔴 Por companhia: conta calculada = conta da variante legada, ao centavo, em toda a bateria de golden masters |
| **⚠️ Pré-requisito** | 🔴 **Inventário das diferenças reais entre as variantes** (dúvida aberta em quatro mapas). Sem ele, esta reestruturação não deve começar |

### 19.6 · ARR-04 — Identidade do Pagamento

| | |
|---|---|
| **Problema** | 🟢 O pagamento recebe **novo identificador** ao ser arquivado (sequences distintas) — única exceção ao padrão de identidade do sistema. 🔵 Consequência: a rastreabilidade do recebimento depois do arquivamento passa a depender das chaves do documento e da competência, não de um id perene |
| **Benefício** | Recebimento rastreável ao longo de toda a vida, como já acontece com os documentos de dívida; auditoria e migração simplificadas |
| **Semântica a preservar** | 🔴 **Todo o resto**: valor, competências (documento × arrecadação), situação atual e anterior, vínculos com movimento/aviso/documento, e o princípio de que **nenhum pagamento é descartado** |
| **Transformação** | Unificar correntes e históricos sob identidade única. ⚠️ **Atenção**: as duas sequences podem ter **colisão de valores** — o migrador precisa detectá-la, não assumir ausência |
| **Risco** | 🟡 **Médio-alto**: colisão silenciosa produziria pagamentos trocados. É risco de **migração**, não de modelo |
| **Validação** | 🔴 Nenhum pagamento duplicado ou perdido no merge; soma de recebimentos por competência preservada; rastreabilidade pagamento↔documento verificada antes e depois do arquivamento |
| **⚠️ Resposta à pergunta do roteiro** | *Necessidade funcional ou limitação estrutural histórica?* → 🔵 **Limitação estrutural.** Nenhum mapa encontrou razão funcional; o sistema inteiro demonstra o padrão correto e este é o ponto onde não foi aplicado |

### 19.7 · ARR-07 — Layouts bancários no controlador

| | |
|---|---|
| **Problema** | 🟢 Rotinas de validação de layout posicional (arrecadação, ficha de compensação, cartão) vivem **dentro do controlador de domínio**. 🔵 Acrescentar convênio ou versão de layout significa mexer no núcleo financeiro |
| **Benefício** | Layouts como contratos externos versionados, isolados do domínio; acrescentar banco/convênio sem tocar na regra de negócio |
| **Semântica a preservar** | 🔴 **O comportamento de cada layout, byte a byte**: validação por tipo de registro e versão, aceitação por item, totais de conferência do trailer |
| **Transformação** | Nenhuma sobre dados — o registro bruto já está preservado (`ARR-02`), o que **viabiliza a validação** |
| **Risco** | 🟡 **Médio**: um layout mal portado rejeita arquivo válido ou aceita inválido — ambos com consequência financeira |
| **Validação** | 🔴 **Reprocessar arquivos reais preservados em `amit_cnregistro`** produzindo exatamente os mesmos pagamentos e as mesmas rejeições |

### 19.8 · ATE-05 — Espera e reiteração sem histórico

| | |
|---|---|
| **Problema** | 🟢 **Espera** cabe num único par de datas (múltiplas esperas sobrescrevem); **reiteração** é contador agregado (perde quem, quando, por qual canal). 🔵 Perda de informação por construção |
| **Benefício** | Indicadores de atendimento completos; reclamações regulatórias reconstituíveis; motivo da espera registrado |
| **Semântica a preservar** | 🟢 Que o RA pode ficar em espera e ser reiterado, e que ambos afetam a leitura do atendimento |
| **Transformação** | O que existe hoje entra como **primeira ocorrência** do novo histórico — migração trivial, sem perda |
| **Risco** | 🟢 **Baixo**: não há dado a converter, apenas a acomodar |
| **Validação** | Todo RA preserva a espera atual e a contagem de reiterações |
| **⚠️ Pendência** | ❔ Se a espera **suspende formalmente o prazo** não foi comprovado — afeta o desenho, não a classificação |

### 19.9 · SEG-02 — Concessão ancorada na URL da Action

| | |
|---|---|
| **Problema** | 🔴 O identificador efetivo de funcionalidade e operação é o **caminho HTTP da Action Struts**. O SISAN não terá URLs `.do` |
| **Benefício** | Concessões migráveis; funcionalidade identificada por chave estável, independente da tecnologia de apresentação; e desacoplamento da ADR-0007 (a decisão de interface deixa de afetar a segurança) |
| **Semântica a preservar** | 🔴 **O modelo inteiro**: funcionalidade, operação, o trio de concessão, a união de grupos, a dependência entre funcionalidades e as permissões especiais nomeadas |
| **Transformação** | Cada funcionalidade/operação legada recebe **chave estável**; cada concessão é remapeada para o novo par |
| **Risco** | 🔴 **Alto e assimétrico**: errar **para mais** concede acesso indevido (falha de segurança silenciosa); errar **para menos** trava a operação (visível e corrigível). ⚠️ Toda validação deve ser desenhada para detectar o primeiro |
| **Validação** | 🔴 Matriz completa perfil × funcionalidade × operação reproduzida; **nenhuma concessão nova** aparece; diferenças apenas as das divergências aprovadas |
| **⚠️ Observação** | Sem isso, **migrar perfis de acesso seria reconfiguração manual por instalação** — inviável e perigoso |

### 19.10 · SEG-03 — Abrangência aplicada manualmente

| | |
|---|---|
| **Problema** | 🟢 O modelo de abrangência está correto, mas sua aplicação **depende de cada Action/controlador chamar a verificação**. Uma consulta nova que esqueça vaza dados de outro território |
| **Benefício** | Escopo territorial garantido por construção, não por disciplina; eliminação de uma classe inteira de vazamento por omissão |
| **Semântica a preservar** | 🔴 **O modelo hierárquico e seu comportamento**: gerência regional → unidade de negócio → elo/polo → localidade, com a mesma resposta a "o que você pediu está dentro do que sua abrangência permite?" |
| **Transformação** | Nenhuma sobre dados — a estrutura de abrangência do usuário migra 1:1. A mudança é de **aplicação** |
| **Risco** | 🟡 **Médio, invertido**: aplicar escopo onde o legado **não** aplicava pode **restringir** consultas que hoje funcionam. ⚠️ Isso seria **correção**, não regressão — mas precisa ser previsto, comunicado e registrado como divergência |
| **Validação** | 🔴 Usuário com abrangência restrita testado em **cada** superfície de consulta; comparação explícita com o legado, com as diferenças classificadas como correção esperada |
| **⚠️ DIVERGÊNCIA PROPOSTA** | 🔴 **D-17 (proposta, não aprovada)**: onde o legado hoje **não** aplica abrangência por omissão, o SISAN aplicará. É divergência de comportamento visível e precisa de aprovação — não pode ser tratada como equivalência |

### 19.11 · BAT-03 — Contexto de execução serializado em bytes

| | |
|---|---|
| **Problema** | 🟢 A tarefa inteira é serializada em bytes Java dentro do registro de execução. 🔵 O contexto só é legível por um processo com exatamente aquelas classes no classpath — **amarra a migração e impede inspeção** |
| **Benefício** | Contexto legível, inspecionável e independente da versão das classes; possibilidade de auditar o que foi pedido sem executar |
| **Semântica a preservar** | 🟢 **Os parâmetros da execução persistidos**, sustentando reinício e auditoria do que foi solicitado |
| **Transformação** | Execuções **em andamento não migram** — são transitórias por natureza, e a migração acontece com o sistema parado |
| **Risco** | 🟢 **Baixo**: não há dado financeiro em jogo |
| **Validação** | Contexto reconstruível fora do runtime original; reinício funciona a partir do contexto persistido |
| **⚠️ Alcance** | O mesmo problema existe em **Relatórios** (`REL-03`) — mesma reestruturação, dois consumidores |

### 19.12 · INT-01 — Camada de integração inexistente

| | |
|---|---|
| **Problema** | 🟢 **Não existe camada.** Sete padrões independentes, sem política comum de autenticação, erro ou observabilidade — de OAuth2 com credencial em banco a chave de API em constante Java |
| **Benefício** | Uma política em vez de sete; autenticação da origem garantida; erro durável e observável; segredo fora do código; transporte cifrado |
| **Semântica a preservar** | 🔴 **Todas as capacidades funcionais**: coleta em campo, OS móvel, troca com executante terceirizado, consulta a birô, arquivos bancários, notificação por e-mail e SMS, GIS |
| **Transformação** | Nenhuma sobre dados. ⚠️ **Mas os contratos externos precisam ser renegociados** com dispositivos e parceiros — é trabalho de coordenação, não só de código |
| **Risco** | 🟡 **Médio**: ❔ **os consumidores reais de cada entry point não foram levantados** (dúvida aberta). Desligar um protocolo sem saber quem o usa quebra operação de campo |
| **Validação** | Cada capacidade preservada com autenticação comprovada; nenhum consumidor conhecido sem caminho |
| **⚠️ Referência interna** | 🔵 O `GsanApi` demonstra o padrão correto **dentro do próprio repositório** — a camada é a generalização dele, não invenção |

### 19.13 · INT-03 — Integração por banco compartilhado

| | |
|---|---|
| **Problema** | 🟢 O GSAN **escreve diretamente no banco do parceiro** por uma segunda `SessionFactory`; idempotência por exceção de constraint engolida; identidade atravessa como string de login; falha → `continue` + `System.out`, **sem registro durável**. A OS fica presa no limbo sem que ninguém seja notificado |
| **Benefício** | Contrato explícito em vez do schema alheio; idempotência por chave de negócio; erro em fila consultável; identidade rastreável |
| **Semântica a preservar** | 🟢 O **ciclo funcional**: exportar OS a executar → receber executadas → encerrar no GSAN → notificar a empresa; e o estado do protocolo (`indicadorMovimento` 1→2), que é máquina de estados simples e adequada |
| **Transformação** | Nenhuma sobre dados do GSAN. ⚠️ **Exige acordo com o parceiro** — é a reestruturação com maior dependência externa |
| **Risco** | 🟡 **Médio**: se o parceiro não puder mudar, é preciso um adaptador que isole a escrita direta sem eliminá-la de imediato |
| **Validação** | Nenhuma OS perdida em silêncio; toda rejeição consultável; idempotência comprovada por reenvio |

---

## 20. Itens que exigem aprofundamento

🔴 Seis bloqueios de evidência. ⚠️ Nenhum deve orientar implementação antes de ser resolvido.

⚠️ **Nem todos são linhas `EXIGE APROFUNDAMENTO` na matriz**: cinco são (`CAD-11`, `COB-02`, `ATE-02`, `SEG-07`, `REL-02`); os outros dois são **pré-requisitos bloqueantes de decisões já classificadas** — o inventário das variantes por companhia bloqueia `FAT-07`/`MIC-06`, e as fórmulas de acréscimos bloqueiam a parte não decidida de `COB-07`.

| # | Item | Por que não dá para decidir | O que falta | Impacto se decidido errado |
| - | ---- | --------------------------- | ----------- | -------------------------- |
| 1 | **`UsuarioGrupoRestricao`** (`SEG-07`) | A tabela existe; **o uso no cálculo não foi observado** | 🔴 Rastreio dirigido + verificação de dados reais | Define se o modelo tem *deny*. Errar remove um controle de segurança sem perceber |
| 2 | **"Fatura"** e a **obrigação financeira** (`COB-02`) | Semântica de `faturamento.fatura` nunca esclarecida; sem ela não se sabe se os 5 alvos têm ciclo comum | Análise dirigida da entidade Fatura e de seus consumidores | Desenhar a abstração errada contamina Cobrança, Arrecadação e Parcelamento |
| 3 | **Cardinalidade física RA↔OS e RA↔Imóvel** (`ATE-02`) | 🟢 DDL permite nulo, mapping não. Não se sabe se há registros nulos nem por qual caminho | 🔴 Verificação em dados reais | Tornar obrigatório o que é opcional quebra ocorrências de rede e OS de cobrança |
| 4 | **Diferenças entre variantes por companhia** (`MIC-06`, `FAT-07`) | 7 companhias × 4 módulos, **nunca inventariadas** | Inventário das diferenças reais | Ponto de extensão que não cobre os casos reais; regressão financeira por companhia |
| 5 | **Fórmulas de acréscimos** (`COB-07`) | Atravessam três módulos, em código, **nunca caracterizadas** | Caracterização numérica de juros/multa/atualização | Divergência financeira em toda dívida vencida |
| 6 | **Retenção e volume dos artefatos de relatório** (`REL-02`) | Nem volume nem política de expiração levantados | Levantamento de volume e retenção | Escolha de armazenamento inadequada; custo ou perda de artefatos |

⚠️ Adicionalmente, **extensões de companhia no Cadastro** (`CAD-11`) permanece sem classificação pela mesma razão do item 4.

---

## 21. Hipóteses para o modelo alvo

> ⚠️ **Registro, não decisão.** Emergiram da classificação e serão avaliadas na Visão Conceitual Alvo. **Nenhuma vira ADR aqui.**

1. **Identidade estável + linhagem como capacidade de plataforma**, não reimplementada documento a documento — o padrão aparece em conta, guia, débito, crédito, RA, OS e parcelamento.
2. **Obrigação financeira como abstração explícita**, se e quando "Fatura" for esclarecida — com mapeamento 1:1 às identidades legadas.
3. **Economia como conceito de primeira classe**, com equivalência direta à representação agregada.
4. **Contexto de cálculo como documento versionado**, preservando a imutabilidade do snapshot.
5. **Estado de domínio junto do domínio dono**, com o Imóvel expondo apenas o que é seu.
6. **Ligação com identidade própria**, preservando a cardinalidade 1:1 como restrição, não como chave.
7. **Escopo territorial sistemático**, aplicado por construção.
8. **Chave estável de funcionalidade/operação**, desacoplada da tecnologia de apresentação.
9. **Parametrização versionada e governada** — o padrão "regra como dado" com histórico de mudanças, como a tarifa já faz.
10. **Ledger de recebimentos com identidade perene**, corrigindo a anomalia do pagamento.
11. **Camada de integração única**, generalizando o padrão que o `GsanApi` já demonstra.
12. **Adaptadores de layout bancário versionados**, fora do domínio.
13. **Contexto de execução tipado e legível**, substituindo a serialização Java (batch e relatórios).
14. **Estratégia de *legacy id*** (identificador SISAN + origem + id legado) **onde necessária**, nunca como padrão automático (§17.1).

---

## 22. Matriz consolidada

| # | Área | Conceito/estrutura | Classificação | Confiança | Divergência |
| - | ---- | ------------------ | ------------- | --------- | ----------- |
| CAD-01 | Cadastro | Imóvel — identidade (matrícula + DV) | **PRESERVAR** | ALTA | — |
| CAD-02 | Cadastro | Imóvel — estado de outros domínios | **REESTRUTURAR** | ALTA | — |
| CAD-03 | Cadastro | Cliente | **PRESERVAR** | ALTA | — |
| CAD-04 | Cadastro | Cliente × Imóvel (papel + vigência) | **PRESERVAR** | ALTA | — |
| CAD-05 | Cadastro | Economia — três representações | **REESTRUTURAR** | ALTA | — |
| CAD-06 | Cadastro | Categoria/Subcategoria com parâmetros | **PRESERVAR** | ALTA | — |
| CAD-07 | Cadastro | Denormalizações de conveniência | **MODERNIZAR** | MÉDIA | — |
| CAD-08 | Cadastro | Ligação — PK compartilhada + estado fora | **REESTRUTURAR** | ALTA | — |
| CAD-09 | Cadastro | Estrutura territorial | **PRESERVAR** | ALTA | — |
| CAD-10 | Cadastro | Rota e suas três finalidades | **MODERNIZAR** | ALTA | — |
| CAD-11 | Cadastro | Extensões de companhia no núcleo | **APROFUNDAMENTO** | BAIXA | — |
| MIC-01 | Micromedição | Hidrômetro × Instalação (a separação) | **PRESERVAR** | ALTA | — |
| MIC-02 | Micromedição | Ponteiro de instalação vigente | **MODERNIZAR** | ALTA | — |
| MIC-03 | Micromedição | Leitura — par informado × faturamento | **PRESERVAR** | ALTA | — |
| MIC-04 | Micromedição | Consumo histórico (3 valores + origem) | **PRESERVAR** | ALTA | — |
| MIC-05 | Micromedição | Anormalidades paramétricas | **PRESERVAR** | ALTA | — |
| MIC-06 | Micromedição | Subclasses por companhia | **NÃO TRANSPORTAR** | ALTA | — |
| FAT-01 | Faturamento | Conta como documento financeiro | **PRESERVAR** | ALTA | — |
| FAT-02 | Faturamento | Identidade estável (`*Geral`) | **REESTRUTURAR** (semântica: PRESERVAR) | ALTA | — |
| FAT-03 | Faturamento | Tabelas-espelho corrente/histórico | **REESTRUTURAR** | ALTA | — |
| FAT-04 | Faturamento | Snapshots da Conta | **PRESERVAR** | ALTA | — |
| FAT-05 | Faturamento | Linhagem por retificação | **PRESERVAR** | ALTA | — |
| FAT-06 | Faturamento | Estrutura tarifária versionada | **PRESERVAR** | ALTA | — |
| FAT-07 | Faturamento | Variação por companhia no núcleo | **REESTRUTURAR** | MÉDIA | — |
| FAT-08 | Faturamento | Precisão financeira (5 políticas) | **PRESERVAR** | ALTA | — |
| FAT-09 | Faturamento | Débito/Crédito em dois momentos; Guia | **PRESERVAR** | ALTA | — |
| FAT-10 | Faturamento | Referência AAAAMM + contábil | **PRESERVAR** | ALTA | — |
| COB-01 | Cobrança | Estoque como consulta | **PRESERVAR** | ALTA | — |
| COB-02 | Cobrança | Obrigação financeira implícita | **APROFUNDAMENTO** | BAIXA | — |
| COB-03 | Cobrança | Documento de cobrança com itens | **PRESERVAR** | ALTA | — |
| COB-04 | Cobrança | Ação de cobrança parametrizada | **PRESERVAR** | ALTA | — |
| COB-05 | Cobrança | Parcelamento — composição + memória | **PRESERVAR** | ALTA | — |
| COB-06 | Cobrança | Negativação: domínio / integração | **PRESERVAR / MODERNIZAR** | ALTA | — |
| COB-07 | Cobrança | Contadores no imóvel / acréscimos | **MODERNIZAR / APROFUNDAMENTO** | MÉDIA / BAIXA | — |
| ARR-01 | Arrecadação | Recepção × classificação | **PRESERVAR** | ALTA | — |
| ARR-02 | Arrecadação | Registro bruto do arquivo | **PRESERVAR** | ALTA | — |
| ARR-03 | Arrecadação | Catálogo de situações do pagamento | **PRESERVAR / MODERNIZAR** | ALTA | — |
| ARR-04 | Arrecadação | Identidade do pagamento | **REESTRUTURAR** | ALTA | — |
| ARR-05 | Arrecadação | Conciliação por aviso bancário | **PRESERVAR** | ALTA | — |
| ARR-06 | Arrecadação | Devolução; débito automático (3 níveis) | **PRESERVAR** | ALTA | — |
| ARR-07 | Arrecadação | Layouts bancários no controlador | **REESTRUTURAR** | ALTA | — |
| ATE-01 | Atendimento | RA e OS como identidades distintas | **PRESERVAR** | ALTA | — |
| ATE-02 | Atendimento | Cardinalidade RA ↔ OS | **APROFUNDAMENTO** | BAIXA | — |
| ATE-03 | Atendimento | Especificação da solicitação | **MODERNIZAR** | ALTA | — |
| ATE-04 | Atendimento | Tipo de serviço; tramitação | **PRESERVAR** | ALTA | — |
| ATE-05 | Atendimento | Espera e reiteração agregadas | **REESTRUTURAR** | ALTA | — |
| ATE-06 | Atendimento | Indicadores de efeito / códigos de tela | **MODERNIZAR / NÃO TRANSPORTAR** | ALTA | — |
| SEG-01 | Segurança | Modelo de autorização (grupo/func/oper) | **PRESERVAR** | ALTA | — |
| SEG-02 | Segurança | Concessão ancorada na URL | **REESTRUTURAR** | ALTA | — |
| SEG-03 | Segurança | Abrangência (conceito / aplicação) | **PRESERVAR / REESTRUTURAR** | ALTA | **D-17 proposta** |
| SEG-04 | Segurança | Permissões especiais; ciclo do usuário | **PRESERVAR** | ALTA | — |
| SEG-05 | Segurança | Auditoria em dois níveis | **PRESERVAR / MODERNIZAR** | ALTA | — |
| SEG-06 | Segurança | Mecanismos de autenticação e sessão | **NÃO TRANSPORTAR** | ALTA | D-01, D-02, D-06, D-07 |
| SEG-07 | Segurança | `UsuarioGrupoRestricao` (deny) | **APROFUNDAMENTO** | BAIXA | — |
| BAT-01 | Batch | Definição × execução em três níveis | **PRESERVAR** | ALTA | — |
| BAT-02 | Batch | Retomada por unidade; autorização | **PRESERVAR** | ALTA | — |
| BAT-03 | Batch | Serialização Java / Quartz-JMS-MDB | **REESTRUTURAR / NÃO TRANSPORTAR** | ALTA | — |
| REL-01 | Relatórios | Três conceitos; decisão automática | **PRESERVAR / MODERNIZAR** | ALTA | — |
| REL-02 | Relatórios | Artefato persistido e seu acesso | **APROFUNDAMENTO / NÃO TRANSPORTAR** | MÉDIA / ALTA | D-03 |
| REL-03 | Relatórios | Serialização da tarefa; motor Jasper | **REESTRUTURAR / MODERNIZAR** | ALTA | — |
| INT-01 | Integrações | Camada de integração inexistente | **REESTRUTURAR** | ALTA | — |
| INT-02 | Integrações | Capacidades de campo e móvel | **PRESERVAR / NÃO TRANSPORTAR** | ALTA | D-04, D-05, D-10, D-11 |
| INT-03 | Integrações | Banco compartilhado (UPA/SAM) | **REESTRUTURAR** | ALTA | D-12 |
| INT-04 | Integrações | `GsanApi` / `ServicoSMS` | **PRESERVAR / NÃO TRANSPORTAR** | ALTA | D-08, D-09, D-13 |

**Totais — 64 decisões.** Por classificação **primária** (a primeira listada em cada linha): **37 PRESERVAR · 14 REESTRUTURAR · 6 MODERNIZAR · 5 EXIGE APROFUNDAMENTO · 2 NÃO TRANSPORTAR**.

⚠️ **12 linhas têm classificação dupla** — `COB-06`, `COB-07`, `ARR-03`, `ATE-06`, `SEG-03`, `SEG-05`, `BAT-03`, `REL-01`, `REL-02`, `REL-03`, `INT-02`, `INT-04`. Contando também a secundária, as decisões que **tocam** cada categoria: PRESERVAR 37 · REESTRUTURAR 15 · MODERNIZAR 11 · NÃO TRANSPORTAR 7 · EXIGE APROFUNDAMENTO 6.

Além da matriz: **6 famílias** não transportadas (§18) e **16 famílias paramétricas** (§15).

---

## 23. Evidências

Esta análise **não gerou evidência nova de código**. Toda afirmação 🟢 remete ao mapa de origem, onde consta arquivo:linha.

| Fonte | Uso nesta análise |
| ----- | ----------------- |
| [`dominio/mapa-de-dominio.md`](../dominio/mapa-de-dominio.md) | Base principal: conceitos centrais e natureza, identidades estáveis, mecanismos de tempo, ownership, fronteiras, ciclos, regras como dados, conceitos sobrecarregados e implícitos, riscos |
| [`dominio/glossario.md`](../dominio/glossario.md) | Definições e evidências por conceito |
| [`decisoes/0005-*.md`](../decisoes/0005-sisan-modernizacao-evolutiva-do-gsan.md) | Regra "preservar quando adequado, modernizar quando necessário, redesenhar somente com justificativa"; migração como requisito arquitetural; schema não único entre companhias |
| [`decisoes/0006-*.md`](../decisoes/0006-modelo-de-dados-evolutivo.md) | Definição exata das quatro classificações e das regras de registro |
| [`arquitetura/arquitetura-alvo.md`](../arquitetura/arquitetura-alvo.md) | Stack alvo; organização modular; o que não se faz (redesenho por estética; preservação de estrutura ruim por apego) |
| [`divergencias-aprovadas.md`](divergencias-aprovadas.md) | Precedência sobre equivalência literal em Segurança e Integrações (D-01…D-16) |
| [`procedencia.md`](../procedencia.md) | Método, níveis de certeza, correções de fato já aplicadas |
| Dez mapas em [`modulos/`](../modulos/) | Evidência de detalhe por estrutura, consultada pontualmente |

### 23.1 Divergência nova proposta nesta análise

| # | Área | Comportamento do GSAN | Comportamento proposto para o SISAN | Status |
| - | ---- | --------------------- | ----------------------------------- | ------ |
| **D-17** | Abrangência territorial | Em superfícies onde a verificação não é chamada, o usuário acessa dados fora de sua abrangência | Escopo territorial aplicado sistematicamente em toda consulta | ⚠️ **PROPOSTA — não aprovada** |

⚠️ Registrada como proposta porque **altera comportamento visível**: consultas que hoje funcionam passariam a ser restringidas. É correção, não regressão — mas exige aprovação explícita, e por isso não foi adicionada ao registro de divergências aprovadas.

---

## 24. Próxima atividade

**Visão Conceitual Alvo do SISAN** — ainda **sem modelo físico**. Consome:

- as **37 decisões `PRESERVAR`** como **restrições de desenho** (o que não pode mudar);
- as **15 decisões que tocam `REESTRUTURAR`** como **problemas a resolver** (com a semântica a preservar já explicitada em §19);
- as 14 hipóteses de §21 como **material a avaliar**;
- os **6 bloqueios de evidência** de §20 como itens **a endereçar ou aceitar como risco declarado**.
