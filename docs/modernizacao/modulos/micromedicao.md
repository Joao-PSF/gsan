# Módulo Micromedição — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Fontes: código GSAN (`gcom.micromedicao`, pontos de contato em `gcom.faturamento`), mapeamentos Hibernate, constantes, DDL e comentários do banco; `gsan_comercial` como evidência complementar (evoluções). Termos conforme o [glossário](../dominio/glossario.md); pré-requisito: [cadastro](cadastro.md).

## 1. Responsabilidade

A Micromedição responde pela **medição do consumo de água**: administra o parque de hidrômetros (equipamento e instalação), planeja e executa o ciclo mensal de leitura por rota, critica leituras e consumos (anormalidades), calcula o consumo de cada imóvel na referência (medido, por média ou mínimo) e mantém o histórico mensal que alimenta o Faturamento, as análises e as médias futuras.

## 2. Principais capacidades

- Gerenciar hidrômetros como **equipamentos** (estoque, movimentação, manutenção, baixa) e como **instalações** em imóveis/ligações (histórico com leituras de instalação/retirada).
- Planejar a leitura por rota dentro do cronograma do grupo de faturamento (gerar arquivo/movimento de leitura com leitura anterior e faixa esperada).
- Registrar leituras e anormalidades (convencional, microcoletor, celular/mobile, leitura-e-impressão simultânea).
- Criticar leitura e consumo com **regras parametrizadas em dados** (anormalidades de leitura com ações com/sem leitura; anormalidades de consumo com ações escalonadas por mês de reincidência).
- Calcular consumo por referência (real, média, mínimo, rateio de condomínio; tratamento de virada e troca de hidrômetro).
- Manter os históricos mensais de medição e consumo (por imóvel + referência, água e esgoto), inclusive versões anteriores de valores retificados.
- Apoiar fiscalização de leitura e análise de exceções.

## 3. Conceitos centrais

### 3.1 Hidrômetro (equipamento)

Equipamento físico com identidade própria e ciclo de vida independente do imóvel: `micromedicao.hidrometro` — número de série (`hidr_nnhidrometro`), ano de fabricação, aquisição, marca, tipo, capacidade, diâmetro, classe metrológica, relojoaria, vazões, **número de dígitos da leitura** (`hidr_nndigitosleitura` — essencial para a virada), leitura acumulada, última revisão, baixa (com motivo). Situações (`HidrometroSituacao`): INSTALADO(1), EM_MANUTENCAO(2), DISPONIVEL(3), ROUBADO(4). Estoque e logística: locais de armazenagem, `hidrometro_movimentacao`/`hidrometro_movimentado` (movimentação entre locais).

**Um hidrômetro pode passar por vários imóveis** (cada passagem é uma instalação nova); **um imóvel pode ter vários hidrômetros ao longo do tempo** (instalações sucessivas). Em um dado momento, a medição de uma ligação usa **uma** instalação vigente; um imóvel pode ter, além da instalação na ligação de água, instalação **no próprio imóvel** para poço (`MedicaoTipo`: LIGACAO_AGUA=1, POCO=2) — dois medidores simultâneos são possíveis nesse arranjo (água + poço).

### 3.2 Instalação (vínculo hidrômetro × imóvel/ligação)

`micromedicao.hidrometro_inst_hist` (`HidrometroInstalacaoHistorico`) é o **elo**: hidrômetro (`hidr_id`) + ligação de água (`lagu_id`) **ou** imóvel (`imov_id`, caso poço) + tipo de medição (`medt_id`) + local de instalação/proteção + usuários de instalação/retirada. Datas e leituras de fronteira: `dataInstalacao` + `numeroLeituraInstalacao`, `dataRetirada` + `numeroLeituraRetirada`, leituras de corte/supressão, selo/lacre, `indicadorInstalcaoSubstituicao` (instalação originada de substituição).

### 3.3 Histórico de instalação

O próprio registro é histórico: a **instalação vigente é a de `dataRetirada` nula**, e Cadastro guarda o ponteiro para ela (`imovel.hidi_id` para poço; `ligacao_agua.hidi_id` para água — ver cadastro.md §3.6/§3.11 do glossário). As instalações anteriores permanecem na tabela. As leituras de instalação/retirada preservadas em cada registro são o que permite calcular consumo no mês de troca sem perder continuidade. **O histórico de medição/consumo pertence ao imóvel+referência** (ver 3.8), então a troca de equipamento não rompe a série histórica do imóvel.

### 3.4 Leitura

`micromedicao.medicao_historico` (`MedicaoHistorico`) — uma linha por imóvel/instalação por referência, distinguindo sistematicamente **informado × faturamento**:

- `leituraAnteriorInformada` / `leituraAnteriorFaturamento` (+ datas);
- `leituraAtualInformada` (o que veio do campo; há também `mdhi_nnleituracampo`) / `leituraAtualFaturamento` (a validada, usada no cálculo);
- situação de leitura **anterior e atual** (`LeituraSituacao`: REALIZADA=1, NAO_REALIZADA=2, CONFIRMADA=3, LEITURA_ALTERADA=4) — leitura pode ser alterada/confirmada em análise, e o sistema marca isso na situação (`mdhi_icanalisado`, usuário que alterou/informou);
- anormalidade **informada** (do leiturista) × anormalidade **de faturamento** (a considerada);
- leiturista, tipo de medição, consumo medido no mês (`mdhi_nnconsumomedidomes`).

Versões anteriores de registros retificados vão para `medicao_hist_anterior` (o par de `consumo_hist_anterior`) — evolução presente no `gsan_comercial`.

### 3.5 Anormalidade de leitura

Situações de campo/da leitura (hidrômetro parado, imóvel fechado, leitura não realizada etc. — o catálogo é dado, não código). O ponto estrutural é que a tabela `leitura_anormalidade` é **paramétrica** e define, por anormalidade:

- o **consumo a cobrar** quando há leitura e quando não há (`lacs_idconsacobrarsemleit` / `lacs_idconsacobrarcomleit` → `leitura_anorm_consumo`);
- a **leitura a faturar** com/sem leitura (`lalt_idleitafaturarsemleit` / `lalt_idleitafaturarcomleit` → `leitura_anorm_leitura`);
- se **emite ordem de serviço** (`ltan_icemissaoordemservico`), se é relativa a hidrômetro, se vale para imóvel sem hidrômetro;
- extensão social nesta instalação: `ltan_icperdatarifasocial` (anormalidade que derruba tarifa social).

Informada pelo leiturista (via arquivo/dispositivo) e/ou atribuída pelo sistema na crítica; a de faturamento pode divergir da informada (campos separados na medição).

### 3.6 Consumo

`micromedicao.consumo_historico` (`ConsumoHistorico`) — o **resultado mensal por imóvel + referência (`cshi_amfaturamento`, AAAAMM) e por tipo de ligação** (`LigacaoTipo`: LIGACAO_AGUA=1, LIGACAO_ESGOTO=2 — água e esgoto têm linhas próprias). Campos estruturais: `numeroConsumoFaturadoMes` (o que foi faturado), `numeroConsumoCalculoMedia` (o que entra em médias futuras), `consumoMedio`, `consumoMinimo`, tipo de consumo (`ConsumoTipo`), anormalidade de consumo, rateio (`consumoRateio`, condomínio), poço, situação especial de faturamento, rota, indicadores de ajuste/alteração e `percentualColeta`.

**Fórmula básica**: leitura atual de faturamento − leitura anterior de faturamento; corrigida por: virada de hidrômetro (usa `numeroDigitosLeitura` — código explícito em `ControladorMicromedicao`, com anormalidade `VIRADA_HIDROMETRO`), troca de hidrômetro (leituras de retirada/instalação na fronteira), ausência de leitura/anormalidades (ações paramétricas de 3.5) e média/mínimo (3.9 e casos especiais). Não há coluna própria de "dias de consumo" — o período deriva das datas de leitura anterior/atual.

**Tipos** (`ConsumoTipo`): REAL(1), MEDIA_HIDROMETRO(3), CONSUMO_MINIMO_FIXADO(7), MEDIA_IMOVEL(9) — e, como extensão social nesta instalação, CONSUMO_MINIMO_BOLSA_AGUA(11). O tipo registra **a origem do consumo** — distinção central para caracterização e para o Faturamento.

**Consumo medido × faturado**: o medido do mês fica na medição (`mdhi_nnconsumomedidomes`); o faturado fica no consumo histórico (`cshi_nnconsumofaturadomes`); o "para média" (`cshi_nnconsumocalculomedia`) pode diferir de ambos (expurgo de anormalidades). Valores divergem quando há anormalidade, média, mínimo, rateio ou ajuste.

### 3.7 Anormalidade de consumo

Detectada pelo **sistema** na crítica do consumo calculado (diferente da anormalidade de leitura, que vem majoritariamente do campo). Constantes (`ConsumoAnormalidade`): CONSUMO_INFORMADO(2), BAIXO_CONSUMO(4), ESTOURO_CONSUMO(5), ALTO_CONSUMO(6), LEITURA_ATUAL_MENOR_PROJETADA(7), LEITURA_ATUAL_MENOR_ANTERIOR(8), HIDROMETRO_SUBSTITUIDO_INFORMADO(9), LEITURA_NAO_INFORMADA(10), VIRADA_HIDROMETRO. Os limiares vêm dos **parâmetros da Categoria** (consumoEstouro, vezesMediaEstouro, consumoAlto, vezesMediaAltoConsumo, mediaBaixoConsumo — cadastro.md §3.5) aplicados sobre a média do imóvel.

A reação é **paramétrica e escalonada por reincidência**: `consumo_anorm_acao` (`ConsumoAnormalidadeAcao`) define fator de consumo e emissão de carta para o 1º, 2º e 3º mês consecutivo da anormalidade (`csaa_nnfatorconsumomes1..3`, `csaa_icgeracaocartames1..3`). Ou seja: anormalidade pode **alterar o consumo faturado** (fator), **gerar comunicação** (carta) e **exigir revisão** (análise de exceções), conforme configuração.

### 3.8 Histórico de consumo

Unidade temporal confirmada: **referência AAAAMM** (`cshi_amfaturamento`). O histórico pertence ao **imóvel** (não ao equipamento): troca de hidrômetro não interrompe a série — o vínculo com o equipamento fica na medição (via instalação `hidi_id`). Usos: média (meses anteriores válidos), críticas (limiares sobre média), faturamento (consumo da referência), relatórios, e rateio de condomínio (consumo do imóvel-condomínio referenciado pelos vinculados). Retificações preservam versões (`consumo_hist_anterior`).

### 3.9 Média

- **Parâmetros de sistema**: `SistemaParametro.mesesMediaConsumo` e `numeroMesesMaximoCalculoMedia` (quantidade de meses considerada/limite).
- **Insumo**: `cshi_nnconsumocalculomedia` dos meses anteriores — meses com anormalidade entram expurgados/ajustados conforme as ações paramétricas (por isso o campo é separado do faturado).
- **Dois tipos**: média do **hidrômetro** (MEDIA_HIDROMETRO, série do medidor) e média do **imóvel** (MEDIA_IMOVEL — usada quando a série do medidor não serve: troca, imóvel novo religado etc.). `consumoMedio` fica gravado no consumo do mês.
- **Usos**: faturar por média (sem leitura, paralisação `PARALISAR_LEITURA_FATURAR_MEDIA`, situação da ligação sem leitura), crítica de consumo (limiares × média) e **faixa de leitura esperada** enviada ao leiturista (`calcularFaixaLeituraEsperada(int media, ...)`; `movimento_roteiro_empr.mrem_nnfaixaleitespinicial/...` e `leitura_faixa_falsa` para detecção de leitura inventada).
- **Fronteira**: a Micromedição calcula e guarda média/faixas; o Faturamento decide faturar por média (situação/paralisação) e aplica tarifa. Histórico insuficiente → média do imóvel/mínimo (regra fina a caracterizar).

### 3.10 Rota e ciclo de leitura

- A rota (setor comercial + grupo de faturamento + leiturista/empresa + **tipo de leitura**) organiza o trabalho: `LeituraTipo` da rota = CONVENCIONAL(1), MICROCOLETOR(2), **LEITURA_E_ENTRADA_SIMULTANEA(3)**, CELULAR_MOBILE(4) — o tipo define o canal de coleta (arquivo/dispositivo) e habilita a leitura com faturamento/impressão simultânea.
- **Precedência (resolve a pendência do Cadastro)**: nos processos de leitura/análise, **a rota alternativa do imóvel, quando definida, sobrepõe a rota da quadra** — as consultas de exceções de leitura têm dois ramos: `imovel.rota_idalternativa = rota.rota_id` e, para os demais, `rota_idalternativa IS NULL` + rota via quadra (`RepositorioMicromedicaoHBM.pesquisarImovelExcecoesLeituras`, linhas 2817/3183/3339). A rota de entrega (`rota_identrega`) segue exclusiva da distribuição de contas (cadastro.md §3.8).
- **Calendário**: o ciclo mensal é dirigido pelo cronograma do grupo — `FaturamentoAtividade` com `FaturamentoAtividadeCronograma` e **`FaturamentoAtivCronRota` (datas por rota)**: PRE_FATURAR_GRUPO(0) → GERAR_ARQUIVO_LEITURA(1) → EFETUAR_LEITURA(2) → REGISTRAR_LEITURA_ANORMALIDADE(3) → GERAR_FISCALIZACAO(4) → FATURAR_GRUPO(5) → DISTRIBUIR_CONTAS(6) → TRANSMITIR_ARQUIVO(7).

## 4. Ciclo funcional da leitura (confirmado)

```text
Grupo de Faturamento (cronograma AAAAMM, atividades 0–7, datas por rota)
   └── Rota (tipo de leitura; leiturista/empresa)  [alternativa sobrepõe a da quadra]
         └── GERAR_ARQUIVO_LEITURA → movimento_roteiro_empr
               (imóvel, endereço, hidrômetro, leitura anterior, FAIXA ESPERADA — da média)
                     └── EFETUAR_LEITURA (arquivo / microcoletor / celular / simultânea)
                           └── REGISTRAR_LEITURA_ANORMALIDADE → medicao_historico
                                 (leitura informada + anormalidade informada)
                                       └── crítica/análise de exceções
                                             (situações REALIZADA/ALTERADA/CONFIRMADA;
                                              anormalidade de faturamento; fiscalização)
                                                   └── determinação do consumo → consumo_historico
                                                         (REAL | MÉDIA | MÍNIMO | rateio; anormalidade de consumo;
                                                          virada/troca tratadas)
                                                               └── FATURAR_GRUPO (Faturamento consome)
```

## 5. Cálculo e determinação do consumo

1. Base: `leituraAtualFaturamento − leituraAnteriorFaturamento` (campos "de faturamento", não os informados).
2. Sem leitura ou com anormalidade de leitura: aplicam-se as **ações paramétricas** da anormalidade (qual leitura faturar, qual consumo cobrar — com/sem leitura).
3. Virada: se leitura atual < anterior dentro da faixa esperada da virada, consumo = (10^dígitos − anterior) + atual; anormalidade `VIRADA_HIDROMETRO` registrada (código em `ControladorMicromedicao`, região das linhas 2986–3035).
4. Troca de hidrômetro na referência: leituras de fronteira da instalação (retirada do antigo, instalação do novo) delimitam os trechos; anormalidade `HIDROMETRO_SUBSTITUIDO_INFORMADO` cobre divergências. (A composição exata do consumo do mês de troca é caso crítico de caracterização — ver §13.)
5. Crítica de consumo: limiares da Categoria sobre a média → BAIXO/ALTO/ESTOURO etc.; ação escalonada por mês de reincidência pode ajustar o consumo (fator) e gerar carta.
6. Situação da ligação e paralisações modulam o resultado: `last_icconsumoreal` ("só faturar consumo real"), `last_icfaturamento`, `FaturamentoSituacaoTipo` (faturar média/taxa mínima; paralisar) — a decisão final de faturabilidade é do Faturamento (`permiteFaturamentoParaAgua/Esgoto` em `ControladorFaturamentoFINAL`).
7. Escrita: `consumo_historico` por imóvel+referência+tipo de ligação (água/esgoto), com tipo de consumo, médio, mínimo e campo separado para médias futuras. Retificações preservam versão anterior. Tanto `ControladorMicromedicao` quanto `ControladorFaturamentoFINAL` gravam consumo — a orquestração exata dentro do FATURAR_GRUPO será detalhada no mapa do Faturamento.

## 6. Casos especiais

| Caso | Tratamento identificado |
| ---- | ----------------------- |
| Imóvel sem hidrômetro | Não há leitura; consumo **não medido** determinado por mínimo/estimativa: consumo mínimo com múltiplas fontes — da ligação (`lagu_nnconsumominimoagua`), da situação da ligação (`last_nnconsumominimo`), da categoria (`catg_nnconsumominimo` × economias) e parametrizações `consumo_minimo_parametro`/`consumo_minimo_area`; anormalidades específicas (`ltan_icimovelsemhidrometro`). Precedência exata → Faturamento |
| Poço | Instalação de hidrômetro no imóvel (`medt_id`=POCO); consumo de poço compõe esgoto |
| Condomínio | Consumo do imóvel-condomínio rateado aos vinculados (`RateioTipo`: SEM_RATEIO, RATEIO_NAO_MEDIDO_AGUA, RATEIO_AREA_COMUM; `cshi_idconsumoimovelcondominio`, `consumoRateio`) |
| Leitura não realizada | Anormalidade paramétrica define leitura/consumo a considerar; reincidência escalona ações |
| Primeira leitura (instalação nova) | Base = leitura de instalação do hidrômetro |
| Fiscalização | `leitura_fiscalizacao` + atividade GERAR_FISCALIZACAO + `InformarLeituraFiscalizacaoAction` |
| Leitura suspeita | Faixa esperada (média) + `leitura_faixa_falsa` (detecção de leitura "inventada") |

## 7. Relação com Cadastro

**Recebe**: imóvel (matrícula, quadra→rota, rota alternativa, sequencial), ligação de água e situação (paramétrica), categoria (parâmetros de crítica) e economias, grupo de faturamento (via rota), situação especial de faturamento, condomínio. **Devolve/atualiza**: instalação vigente do hidrômetro (ponteiros `hidi_id` no imóvel e na ligação), leituras de corte/supressão registradas na instalação, e o consumo/medição que outros módulos leem. A efetivação de ligações com instalação de hidrômetro nasce no atendimento (cadastro.md §2).

## 8. Relação com Faturamento

**Entrega**: consumo por imóvel+referência+tipo de ligação (faturado, tipo/origem, anormalidade, médio, mínimo, rateio), leitura anterior/atual de faturamento e datas (período), situações de leitura. **Faturamento decide**: faturabilidade por situação (`permiteFaturamentoParaAgua/Esgoto`), aplicação de mínimos/tarifa por categoria/economias e composição da conta (fotografando tudo — cadastro.md §3.6). **Recalcular/alterar**: sim — retificação de conta e revisões alteram consumo (`cshi_icajuste`, `consumo_hist_anterior`, `cmrv_id` na tabela de consumo); a fronteira fina da orquestração (quem chama o quê no FATURAR_GRUPO) fica para o mapa do Faturamento. Temporalmente, a leitura/consumo do grupo precede o FATURAR_GRUPO no cronograma.

## 9. Relação com Atendimento/OS

OSs executam instalação/substituição/retirada/aferição de hidrômetro e fiscalização de leitura; **anormalidade de leitura pode emitir OS automaticamente** (`ltan_icemissaoordemservico`). O encerramento dessas OSs altera o estado da micromedição (nova instalação vigente, leituras de fronteira) — mesmo padrão de retroalimentação já visto no Cadastro. Correção de leitura via análise/fiscalização gera `LEITURA_ALTERADA`/`CONFIRMADA` com usuário registrado.

## 10. Regras estruturantes identificadas

1. **Equipamento ≠ instalação**: hidrômetro tem vida própria (estoque→instalado→manutenção/baixa); a instalação é o elo histórico com imóvel/ligação e guarda as leituras de fronteira.
2. **A série histórica pertence ao imóvel+referência (AAAAMM)**, não ao equipamento — troca de hidrômetro não rompe histórico.
3. **Informado × faturamento em tudo**: leitura, data e anormalidade têm sempre o par "o que veio do campo" × "o que vale para faturar".
4. **Regra como dado, de novo**: anormalidades de leitura (ações com/sem leitura, OS automática) e de consumo (fatores e cartas por mês de reincidência) são tabelas paramétricas — mesmo padrão das situações de ligação.
5. **Consumo tem origem tipificada** (real/média/mínimo/fixado/rateio) e três valores distintos por mês: faturado, para média e medido.
6. **A média é insumo multiuso**: faturar sem leitura, criticar consumo e gerar faixa esperada de leitura (antifraude).
7. **Rota alternativa sobrepõe a rota da quadra** nos processos de leitura; rota de entrega é só distribuição.
8. **O ciclo é dirigido pelo cronograma do grupo** (8 atividades com datas por rota) — leitura e faturamento são fases do mesmo trem mensal.
9. **Customização por companhia via herança de controladores** (`ControladorMicromedicaoCAEMA/CAERN/CAER/COMPESA/COSAMA/COSANPA/JUAZEIRO SEJB`) e métodos específicos no núcleo (ex.: `calcularValorFaturadoFaixaCAER`) — o mecanismo de variação por companhia é estrutural no GSAN.

## 11. Compatibilidade GSAN → SISAN

| Conceito/estrutura | Classificação preliminar | Motivo |
| ------------------ | ------------------------ | ------ |
| Separação equipamento × instalação (com leituras de fronteira) | PRESERVAR CONCEITO | Modelo correto e essencial à migração do parque |
| Histórico mensal por imóvel+referência AAAAMM (água/esgoto) | PRESERVAR CONCEITO | Base de médias, críticas e comparações financeiras |
| Par informado × faturamento (leituras/anormalidades) | PRESERVAR CONCEITO | Auditoria e caracterização dependem dele |
| Origem do consumo tipificada (`ConsumoTipo`) | PRESERVAR CONCEITO | Semântica central p/ faturamento e testes |
| Anormalidades paramétricas (leitura e consumo, com ações) | PRESERVAR CONCEITO | "Regra como dado"; migrar catálogos por companhia |
| Faixa esperada / leitura falsa | PRESERVAR CONCEITO | Controle antifraude consolidado |
| Cronograma grupo→atividades→datas por rota | PRESERVAR CONCEITO | Espinha do ciclo mensal |
| Identidade do hidrômetro (nº série + características metrológicas) | PRESERVAR CONCEITO | Patrimônio e histórico |
| Rota alternativa como override | POSSÍVEL MODERNIZAÇÃO | Semântica útil; forma (3 colunas de rota no imóvel) pode melhorar |
| Denormalizações no movimento de leitura (endereço/categoria copiados) | POSSÍVEL MODERNIZAÇÃO | Movimento é interface, pode ser projeção |
| Variação por companhia via subclasses de EJB | EXIGE APROFUNDAMENTO | Precisa de mecanismo de extensão explícito no SISAN; inventariar diferenças reais entre as variantes |
| Composição do consumo no mês de troca de hidrômetro | EXIGE APROFUNDAMENTO | Caso crítico sem fórmula única evidenciada; caracterizar |
| Precedência entre fontes de consumo mínimo (ligação/situação/categoria/área) | EXIGE APROFUNDAMENTO | Resolver no mapa do Faturamento |

## 12. Hipóteses para avaliação futura (não são decisões)

1. Modelar explicitamente **Equipamento** (hidrômetro) e **Instalação** como conceitos distintos no SISAN — o GSAN já os separa; formalizar.
2. Tratar **Consumo como resultado mensal do imóvel** com **origem explícita** (medido/média/mínimo/rateado/ajustado) — já é a semântica do GSAN via `ConsumoTipo`; torná-la de primeira classe.
3. Unificar o padrão "regra como dado" (situações, anormalidades, ações) em um mecanismo paramétrico consistente e versionado.
4. Substituir as três colunas de rota do imóvel por um vínculo rota-por-finalidade (leitura/entrega/override), preservando a semântica e o mapeamento de migração.
5. Transformar a variação por companhia (subclasses de controlador) em pontos de extensão configuráveis, com inventário prévio das diferenças reais.

## 13. Cenários importantes para futura caracterização

1. Leitura normal (consumo REAL = atual − anterior).
2. Leitura não realizada → ações paramétricas sem leitura (consumo/leitura a faturar) + reincidência 1º/2º/3º mês.
3. Faturamento por média (paralisação `FATURAR_MEDIA`; situação sem leitura) — inclusive com histórico insuficiente.
4. **Troca de hidrômetro na referência** (leituras de retirada/instalação; consumo composto; anormalidade 9).
5. **Virada de hidrômetro** (nº de dígitos; consumo complementar; anormalidade VIRADA).
6. Estouro/alto/baixo consumo pelos limiares da Categoria × média (com fator e carta por mês).
7. Imóvel sem hidrômetro (mínimo por categoria/situação/ligação/área — precedência).
8. Primeira leitura após instalação (base = leitura de instalação).
9. Rota alternativa definida × não definida (mesmo imóvel, processos de leitura/análise).
10. Condomínio com rateio (área comum/não medido) referenciando o consumo do principal.
11. Leitura alterada/confirmada em análise (situações 3/4; anormalidade de faturamento ≠ informada).
12. Poço (medição tipo 2) compondo esgoto.

## 14. Funcionalidades futuras identificadas (`gsan_comercial`)

Registrar no catálogo (item 5 do backlog), sem projetar agora: **telemetria/leitura remota** (`telemetria_log`, `telemetria_log_erro`, `telemetria_mov`, `telemetria_mov_reg`, `telemetria_ret_mot`); **releitura mobile** (`releitura_mobile`) e situação de transmissão de leitura (`situacao_transm_leitura`); **fotos de leitura/registro** (`movimento_rot_empr_foto`, `foto_registro_tipo`); boletins de medição/execução com créditos/descontos (`micro_boletim_*`); versionamento de valores anteriores (`medicao_hist_anterior`, `consumo_hist_anterior`); gestão contratual de empresas de leitura (`contrato_empresa_*`, `item_servico*`); fator de correção por idade do hidrômetro (`hidrometro_fat_correcao`, `hidrometro_faixa_idade`).

## 15. Dúvidas que permanecem

1. **Composição exata do consumo no mês de troca de hidrômetro** (soma dos trechos × regra alternativa) — exige leitura dirigida do fluxo ou caracterização com massa de teste.
2. **Orquestração precisa da escrita de consumo** entre `ControladorMicromedicao` e `ControladorFaturamentoFINAL` no FATURAR_GRUPO — mapa do Faturamento.
3. **Precedência entre as fontes de consumo mínimo** (ligação × situação × categoria × área/parâmetro) — mapa do Faturamento.
4. **Diferenças reais entre as variantes por companhia** dos controladores (CAEMA/CAERN/.../COSANPA) — inventário próprio antes da modelagem SISAN.
5. Regra fina de média com histórico insuficiente/imóvel novo (meses mínimos, fallback imóvel × hidrômetro).

## 16. Evidências principais

```text
Equipamento:   Hidrometro.hbm (hidr_nnhidrometro, hidr_nndigitosleitura, vazões, dataBaixa); HidrometroSituacao (INSTALADO/EM_MANUTENCAO/DISPONIVEL/ROUBADO)
Instalação:    HidrometroInstalacaoHistorico.hbm → micromedicao.hidrometro_inst_hist (dataInstalacao/nnleitinstalacao, dataRetirada/nnleitretirada, icinstalacaosubstituicao); ponteiros hidi_id em Imovel.hbm e LigacaoAgua.hbm
Leitura:       MedicaoHistorico.hbm (leituraAnterior/AtualInformada×Faturamento, mdhi_nnleituracampo, mdhi_icanalisado); LeituraSituacao (1–4)
Anorm. leitura: DDL micromedicao.leitura_anormalidade (lacs_idconsacobrar*/lalt_idleitafaturar*, ltan_icemissaoordemservico, ltan_icperdatarifasocial) + leitura_anorm_consumo/leitura_anorm_leitura
Consumo:       ConsumoHistorico.hbm (cshi_amfaturamento, nnconsumofaturadomes, nnconsumocalculomedia, consumoMedio, consumoMinimo, LigacaoTipo, ConsumoTipo, rateio)
Anorm. consumo: ConsumoAnormalidade (constantes 2–10, VIRADA); ConsumoAnormalidadeAcao.hbm (fatores/cartas mês 1–3); parâmetros em Categoria.hbm
Virada:        ControladorMicromedicao.java ~2986–3035 (verificarViradaDeHidrometro; ConsumoAnormalidade.VIRADA_HIDROMETRO; faixa esperada)
Média:         SistemaParametro (mesesMediaConsumo, numeroMesesMaximoCalculoMedia); calcularFaixaLeituraEsperada; leitura_faixa_falsa; movimento_roteiro_empr (faixa esperada)
Ciclo:         FaturamentoAtividade (constantes 0–7); FaturamentoAtividadeCronograma; FaturamentoAtivCronRota; MovimentoRoteiroEmpresa.hbm → micromedicao.movimento_roteiro_empr
Rotas:         RepositorioMicromedicaoHBM.pesquisarImovelExcecoesLeituras (2817/3183/3339: join por rota_idalternativa OU rota_idalternativa IS NULL); Rota.hbm (lttp_id LeituraTipo 1–4)
Fronteira fat.: ControladorFaturamentoFINAL (permiteFaturamentoParaAgua/Esgoto:1957/2019, informarConsumoMinimoParametro:398, calcularValorFaturadoFaixaCAER:5723)
Por companhia: ControladorMicromedicaoCAEMA/CAER/CAERN/COMPESA/COSAMA/COSANPA/JUAZEIRO SEJB (src/gcom/micromedicao/)
Evoluções:     DDL gsan_comercial: telemetria_*, releitura_mobile, situacao_transm_leitura, movimento_rot_empr_foto, micro_boletim_*, consumo/medicao_hist_anterior, hidrometro_fat_correcao
```
