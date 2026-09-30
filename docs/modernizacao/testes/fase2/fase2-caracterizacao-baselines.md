# Fase 2 — Caracterização e captura de baselines

> Relatório da Fase 2 do [plano de trabalho](../../plano-de-trabalho.md): *"baseline funcional automatizada"*, com o
> critério de aceite *"rodadas repetidas produzem resultados idênticos; cobre os comportamentos priorizados"*.
> Mecanismo: [`ambiente-referencia/baselines/`](../../../../ambiente-referencia/baselines/README.md). Gerados por script:
> [matriz de caracterização](matriz-caracterizacao.md) · [cobertura de baselines](cobertura-baselines.md).
>
> ⚠️ **FASE 2 — EM ANDAMENTO.** Esta primeira execução classificou os 103 cenários, construiu o mecanismo e capturou o
> **lote piloto**. A fase não está concluída: a cobertura dos comportamentos priorizados é o trabalho dos próximos lotes (§12).
> 🔴 Nada do OpenGSAN foi implementado; nenhuma linha do legado foi alterada.

## 0. Estado de entrada

| Item | Valor |
| ---- | ----- |
| Linha principal | `master` = `origin/master` = `7425c23` (Fase 1) |
| Fase 1 | Concluída em 2026-09-30; ambiente em execução, 22/22 verificações |
| Trabalho local | Nenhum além do desta fase |
| Legado | `1a0edcf`, EAR **Online** (`Versão: referencia (Online)` no rodapé de cada tela capturada) |

## 1. Objetivo

Transformar as 103 especificações da Fase 0 em **baselines executáveis**: para cada variação de cenário que depende do
legado, executar o GSAN de referência sobre **massa sintética controlada**, a partir de um **estado limpo**, e gravar o
que ele **efetivamente produz** — de forma que a mesma captura, repetida, dê o mesmo resultado byte a byte.

```text
massa (base + delta)  →  estado limpo  →  operação do GSAN pelas telas  →  observáveis da lista fechada  →  baseline
```

## 2. Estratégia

1. **Classificar antes de capturar** (§3): nem todo cenário precisa do legado — requisitos nativos e artefatos estáticos
   não se executam; divergências aprovadas só se registram.
2. **Construir o mecanismo uma vez** (§4–§8): captura e verificação separadas, estado limpo por execução, massa conferida,
   normalização mínima e declarada, evidência fora da baseline.
3. **Provar num lote piloto pequeno** (§9–§10): poucos P0 numa cadeia vertical, cada variação executada duas vezes do
   zero na captura e uma terceira na verificação.
4. **Escalar por lotes** (§12), na ordem de captura da [estratégia de testes](../estrategia-testes.md#priorização-da-baseline-fase-2).

🔴 **Fronteira executável**: a baseline é o que uma tela ou processo do legado **exibe ou grava**. O que a fronteira
escolhida não expõe é registrado na própria baseline (`fora_desta_fronteira`) e fica para a fronteira que o expõe —
nunca é deduzido da leitura do código.

## 3. Classificação A/B/C/N

Derivada **por script** dos campos *Oráculo* e *Baseline concreta* de cada especificação
(`ferramentas/caracterizacao.py`), com ajustes manuais só por arquivo justificado (`caracterizacao-ajustes.tsv` — vazio
nesta execução: nenhuma regra precisou de exceção).

| Classe | Critério (em ordem) | Precisa executar o GSAN? |
| ------ | ------------------- | ------------------------ |
| **N** — requisito nativo | Oráculo **N** | Não — sem equivalente no GSAN público |
| **B** — evidência estática suficiente | Baseline **JÁ COMPROVADA**: o observável é artefato versionado | Não |
| **C** — divergência aprovada | Oráculo **2** puro (sem 1 nem PENDENTE) | Só para **registrar** o comportamento de que se diverge — não é oráculo |
| **A** — baseline GSAN necessária | Todo o resto: oráculo 1, 1+2 ou PENDENTE DE CARACTERIZAÇÃO | Sim |

| Classe | Cenários | P0 | P1 | Variações a capturar |
| ------ | -------- | -- | -- | -------------------- |
| **A** | 74 | 42 | 32 | 221 |
| **B** | 1 | 1 | 0 | 0 |
| **C** | 6 | 2 | 4 | 13 (registro) |
| **N** | 22 | 10 | 12 | 0 |
| **Total** | **103** | 55 | 48 | **234** |

- **80 cenários exigem executar o legado** (74 A + 6 C) — confere com os "81 com baseline a capturar ou já comprovada"
  do [índice](../cenarios-criticos.md#15-o-que-a-fase-2-recebe) (80 + a única B).
- **Variações**: 326 declaradas nas especificações; 234 a capturar. Ficam fora da contagem de A as variações sob
  oráculo 2 de cenários mistos (REL-001 V2–V3, INT-001 V4, INT-002 V3, INT-004 V2/V4/V5, INT-007 V4, FAT-011 V2) e as
  "não comparadas" (SEG-006 V3); cenário sem variações declaradas conta **uma** entrada (17 casos: 14 A, 2 C, 1 B).
- **Decididos pela própria baseline**: BAT-003, BAT-004 e SEG-005 (PENDENTE DE CARACTERIZAÇÃO), OPE-003 V5 e SEG-002 V3 (decisão
  pendente) — classificados A: a captura informa a decisão, não a antecipa.
- A única **B** é CEN-SEG-011 (segredo em artefato versionado: ler o arquivo *é* observá-lo), que também é oráculo 2.

"Massas iniciais" na matriz é o **limite superior**: uma massa por variação. O piloto mostra por que o número real é
menor — variações que só diferem na entrada compartilham a massa efetiva (§10).

## 4. Formato da baseline

Um arquivo JSON por variação, em `golden/<domínio>/<CEN>/<V>.json`, **canônico** (chaves ordenadas, indentação 2,
UTF-8, LF): duas capturas iguais geram arquivos iguais byte a byte. Conteúdo:

| Bloco | O que registra |
| ----- | -------------- |
| `cenario`, `titulo`, `variacao`, `descricao`, `especificacao`, `oraculo` | Identidade e o oráculo que decide |
| `legado` | Commit do código, commit das migrações, versão exibida pelo próprio GSAN (tipo Online/Batch), variante, sha256 do complemento P6 |
| `massa` | Lista ordenada dos arquivos de massa aplicados, cada um com sha256 |
| `operacao` | Fronteira executável (tela/caso de uso e localizadores), roteiro e **entrada** |
| `normalizacoes` | Regras aplicadas, com justificativa |
| `observaveis` | Só a lista fechada da especificação; dinheiro como texto decimal exato |
| `efeitos_no_banco` | Tabelas vigiadas: variação de linhas ou "inalterado/alterado" do conteúdo |
| `fora_desta_fronteira` | Observáveis da especificação que esta fronteira não expõe, e onde capturá-los |

🔵 **Sem data da captura** na baseline: ela mudaria a cada captura e quebraria a igualdade. Data, horários e tabelas
antes/depois ficam no manifesto da execução (evidência); a data da captura é a do commit.

## 5. Massa

**Base + deltas**, em SQL versionado, **100% sintética**:

| Arquivo | Conteúdo | Usado por |
| ------- | -------- | --------- |
| `massas/base/010-parametrizacao-faturamento.sql` | Tipos de cálculo de tarifa (1–4), situações de ligação POTENCIAL/LIGADO (água e esgoto), subcategoria zero, grupo G1, **TAR-01** com duas vigências (2025-01-01 e 2026-07-16) e faixas por categoria | Todas as execuções |
| `massas/base/020-operador-caracterizacao.sql` | Operador sintético `fase2.oper`, grupo próprio, três concessões explícitas; **sem senha** | Todas as execuções |
| `massas/deltas/tar04-calculo-direto-na-faixa.sql` | TAR-04: tipo de cálculo 4, mesmos mínimo e faixas residenciais da TAR-01 | CEN-FAT-001 V7 |
| `massas/deltas/tar01-vigencia-no-dia-da-leitura.sql` | 3ª vigência da TAR-01 em 2026-08-31 | CEN-FAT-002 V2 |
| `massas/deltas/tar01-duas-mudancas-no-periodo.sql` | Vigências em 2026-09-10 e 2026-09-20 | CEN-FAT-002 V3 |
| `massas/deltas/territorio-l1.sql` | Região → UF "ZZ" → município → bairro → logradouro/CEP; gerência, unidade de negócio, **L1**, setor 1, rota **R1** no G1, quadra 1 | CEN-CAD-003 |
| `massas/deltas/imoveis-imv-01-02-03.sql` | Imóveis **IMV-01/02/03** (100013, 100021, 100030) com a composição de economias | CEN-CAD-003 |

- **Identificadores por constante do legado** onde o código os fixa, com a evidência na linha (`TarifaTipoCalculo`,
  `LigacaoAguaSituacao`, `Subcategoria.SUBCATEGORIA_ZERO`, `ImovelPerfil.NORMAL`, `ImovelContaEnvio.ENVIAR_IMOVEL`,
  `LeituraTipo.CONVENCIONAL`, `SituacaoAtualizacaoCadastral.DISPONIVEL`); o resto é declarado SINTÉTICO.
- **Pressupostos do schema** revelados pela massa: `imovel.siac_id` tem `DEFAULT 0` com chave estrangeira — a linha
  0 (DISPONÍVEL) tem de existir, e nenhuma migração a cria.
- **Carimbos de tempo fixos** (`2026-01-01 00:00:00`): a massa é idêntica a cada aplicação.
- **Sequências** das tabelas povoadas passam do maior id da massa (mesma convenção do P2 da Fase 1): inserção posterior
  feita pelo GSAN não colide.
- A composição dos imóveis IMV-01/02/03 é a mesma das entradas de CEN-FAT-001 V1/V2/V3 — o elo da cadeia (§9).

## 6. Captura

`scripts/baseline.sh capturar <alvo>` — no host; para cada variação e cada repetição:

```text
parar JBoss → DROP/CREATE gsan_comercial e gsan_gerencial a partir dos modelos gsan_*_ref
→ aplicar a massa efetiva (base + deltas) e registrá-la em public.baseline_massa (arquivo + sha256)
→ subir o JBoss do zero (~30 s) → executor no contêiner `ferramentas`:
   conferir massa e pré-condições → medir tabelas vigiadas → senha efêmera do operador → login
   → roteiro (telas do legado) → medir tabelas vigiadas → projetar observáveis → normalizar → resultado.json
```

- **Modelos congelados**: o passo `banco` da Fase 1 termina congelando os dois bancos como `gsan_*_ref`
  (`IS_TEMPLATE`, sem conexões). O congelamento **recusa** banco em que alguém já entrou pela aplicação
  (`usur_tmultimoacesso`): o modelo é o estado pós-migração, não um banco usado.
- **Isolamento por execução**: nada passa de uma execução à outra — banco, sessão HTTP e cache estático do JBoss são
  refeitos. Custo medido: ~1 min por execução.
- **Operador**: `fase2.oper`, sintético, grupo próprio. O grupo ADMINISTRADOR **não** é alterado — ele não tem, numa base
  nova, nem a concessão de adicionar categoria na simulação (§11, achado F2-07). A senha é gerada a cada execução, só o
  hash vai ao banco, no formato do legado, e o login é registrado sem o corpo da requisição.
- **Captura explícita**: só `capturar` escreve em `golden/`, e só depois de ≥ 2 execuções **idênticas**; baseline
  existente e diferente é recusada (`--substituir` exige justificativa registrada).

## 7. Normalização

Mínima, declarada no cenário e gravada na baseline. Regras admitidas: `identificador_tecnico` (ordinal de primeira
aparição), `carimbo_tempo`, `data_execucao` (relativa à data do banco) e `ordem_sem_semantica` (só para lista que o
legado devolve sem `ORDER BY`). O executor **recusa** normalizar caminho de dinheiro, total, consumo, situação,
referência, matrícula, economia, categoria, tarifa, faixa ou mínimo.

No piloto, uma única normalização: a composição de economias de CEN-CAD-003 é ordenada por (categoria, subcategoria)
porque `pesquisarCategoriasImovel` não tem `ORDER BY` (`RepositorioImovelHBM:10961-10987`) — a ordem na tela é a física.
Nenhum identificador técnico nem data aparece nos observáveis do piloto.

## 8. Verificação

`scripts/baseline.sh verificar <alvo>`: mesma execução a partir do estado limpo, comparada com a baseline; **nunca
escreve** em `golden/`. Diferença de massa (sha256) aparece como diferença de massa, não de comportamento. Saída:
`CONFERE` / `DIVERGE` com o caminho de cada diferença.

## 9. Lote piloto

Escolha: **poucos P0 numa cadeia vertical** Cadastro → Faturamento individual, todos executáveis **online** e com a
mesma massa-base.

| Cenário | P | Fronteira | Por que no piloto |
| ------- | - | --------- | ----------------- |
| **CEN-CAD-003** — composição de economias | P0 | [UC0472] Consultar Imóvel, aba Dados Cadastrais | Cadastro: a composição que governa tarifa e mínimo |
| **CEN-FAT-001** — valor de água por economias e categorias | P0 | [UC0157] Simular Cálculo da Conta | O caso base do motor de faturamento, ao centavo |
| **CEN-FAT-002** — mudança de vigência no período | P0 | idem | A maior concentração de HALF_UP do controlador; cenário ausente do inventário original |

- **A simulação é o mesmo cálculo da conta**: `SimularCalculoContaAction` chama `obterConsumoMinimoLigacao` (UC0105) e
  `calcularValoresAguaEsgoto` (UC0120) — o método que `gerarConta` chama por imóvel (`ControladorFaturamentoFINAL:52919`).
  Sem cronograma de leitura, o período é o mês da referência inteiro. O que a simulação **não** mostra — valor por faixa,
  contexto congelado na conta, situação e referência da conta — fica registrado em cada baseline para o lote do
  faturamento em grupo.
- **Elo da cadeia**: IMV-01/02/03 no Cadastro têm exatamente as composições de FAT-001 V1/V2/V3.
- **Fora do piloto, com motivo**:
  - *Atendimento* — os P0 (ATE-007, ATE-008) exigem o ciclo de OS (RA → OS → encerramento).
  - *Micromedição* — CEN-MIC-002 (consumo mínimo) foi tentado: a simulação usa `obterConsumoMinimoLigacao`, mas **não
    exibe** o mínimo; a única tela online que o exibe (`ExibirAtualizarConsumoMinimoLigacaoAguaAction`, "Valor Obtido")
    exige uma OS com RA e imóvel — entra com o lote de Atendimento. Os demais P0 de Micromedição são batch
    (consistência de leituras), em modo Batch.
  - *CEN-CAD-002* (cliente por papel e data) — a consulta mostra só vínculos **ativos** (`dataFimRelacao is null`,
    `RepositorioImovelHBM:10872`); a dimensão temporal do cenário precisa de outra fronteira.
  - CEN-FAT-001 V4 (consumo por média) e V5 (taxa mínima por situação especial) — a origem do consumo vem da
    Micromedição sobre imóvel com histórico; fronteira `gerarConta`, lote do faturamento em grupo.

## 10. Resultados

Resultados em [`golden/`](../../../../ambiente-referencia/baselines/golden/); abaixo, o essencial de cada baseline.

### 10.1 Baselines do lote piloto

| Cenário · variação | Entrada | Massa efetiva | Observado (baseline) |
| ------------------ | ------- | ------------- | -------------------- |
| CAD-003 V1 — IMV-01 | matrícula 100013 | base + território + imóveis | RESIDENCIAL / RESIDENCIAL PADRAO: 1 · total **1** |
| CAD-003 V2 — IMV-02 | matrícula 100021 | idem | RESIDENCIAL / RESIDENCIAL PADRAO: 3 · total **3** |
| CAD-003 V3 — IMV-03 | matrícula 100030 | idem | RES PADRAO 1 · RES POPULAR 1 · COMERCIAL PADRAO 1 · total **3** |
| FAT-001 V1 | 05/2026, RES × 1, 27 m³ | base | RESIDENCIAL **R$ 110,40** · consumo exibido 27 |
| FAT-001 V2 | 05/2026, RES × 3, 47 m³ | base | RESIDENCIAL **R$ 168,09** · consumo exibido **48** |
| FAT-001 V3 | 05/2026, RES × 2 + COM × 1, 58 m³ | base | RES **R$ 128,66** · COM **R$ 123,94** · total **R$ 252,60** · consumo exibido **59** |
| FAT-001 V6 | 05/2026, RES × 1, 7 m³ | base | RESIDENCIAL **R$ 32,50** · consumo exibido 7 |
| FAT-001 V7 | 05/2026, TAR-04 (tipo 4), RES × 1, 27 m³ | base + TAR-04 | RESIDENCIAL **R$ 140,40** · consumo exibido 27 |
| FAT-002 V1 | 07/2026 (vigência em 16/07), RES × 1, 27 m³ | base | **R$ 114,96** |
| FAT-002 V2 | 08/2026 (vigência em 31/08, dia da leitura), RES × 1, 27 m³ | base + vigência no dia da leitura | **R$ 119,47** |
| FAT-002 V3 | 09/2026 (vigências em 10/09 e 20/09), RES × 1, 27 m³ | base + duas mudanças no período | **R$ 123,51** |

Em todas: `efeitos_no_banco` sem nenhuma escrita (contas, categorias da conta, histórico, débitos a cobrar e
histórico de consumo com 0 linhas a mais; imóvel e composição com conteúdo inalterado).

### 10.2 Cenário ≠ massa ≠ baseline ≠ execução, no piloto

| Medida | Piloto |
| ------ | ------ |
| Cenários | 3 |
| Variações (baselines) | 11 |
| Arquivos de massa | 7 (2 base + 5 deltas) |
| **Massas efetivas** distintas | **5** — base (FAT-001 V1–V3, V6; FAT-002 V1) · base + TAR-04 · base + vigência no dia · base + duas mudanças · base + território + imóveis (CAD-003 V1–V3) |
| Execuções a partir do estado limpo | 22 na captura + 2 do teste do mecanismo (CAD-003 V3) + 11 na verificação + 1 no teste negativo = **36** |

### 10.3 Determinismo

- **Captura**: 11 de 11 variações com as duas execuções **idênticas byte a byte** (`consolidacao.txt` da execução
  `20260930T184454Z-capturar`). CAD-003 V3 já havia sido capturada no teste do mecanismo: a nova captura reproduziu o
  arquivo existente — 4 execuções iguais.
- **Verificação**: 11 de 11 `CONFERE` numa 3ª execução independente, também do estado limpo
  (`20260930T190557Z-verificar`).
- **Teste negativo**: com o valor de FAT-001 V6 adulterado em **1 centavo** numa cópia da baseline, a verificação
  respondeu `DIVERGE`, apontou `observaveis.por_categoria[0].valor_agua` e `observaveis.total_agua` e saiu com erro; a
  baseline foi restaurada idêntica (`cmp`). A conferência não é vazia.
- **Ambiente** depois de tudo: `referencia.sh verificar` com **23 de 23** verificações OK (a nova confere os modelos).
- Controles que sustentam o determinismo: estado recriado do modelo a cada execução; JBoss reiniciado; massa com
  carimbos fixos e conferida por sha256; vigências só no passado (pré-condição de relógio conferida em toda execução
  de FAT); ordem sem semântica normalizada (CAD-003); nenhum identificador técnico ou data nos observáveis.

### 10.4 Conferência aritmética (consistência — não é a baseline)

Os valores acima são os que o GSAN produziu. Reproduzi-los à mão, a partir da massa, só mostra que são **consistentes**
com uma leitura da regra; a baseline não depende dessa leitura.

- **V1** 32,50 + 10 × 4,15 + 7 × 5,20 = **110,40**.
- **V2** excesso do imóvel 47 − 30 = 17; por economia 17 / 3 = 5,67 (HALF_UP, 2 casas); por economia
  32,50 + 5,67 × 4,15 = 56,03; × 3 = **168,09**. O consumo exibido 48 = ⌈3 × 15,67⌉.
- **V3** mínimo do imóvel 2 × 10 + 1 × 15 = 35; excesso 23 / 3 = 7,67 por economia **em qualquer categoria**; RES
  (32,50 + 7,67 × 4,15) × 2 = **128,66**; COM 71,40 + 7,67 × 6,85 = **123,94**. Consumo exibido 59 = ⌈35,34⌉ + ⌈22,67⌉.
- **V6** abaixo do mínimo: a tarifa mínima, **32,50**.
- **V7** tipo 4: todo o consumo à tarifa da faixa em que cai — 27 × 5,20 = **140,40**.
- **FAT-002**: proporção por **dias corridos** do período (inclusivo), aplicada a **cada componente** (mínimo e cada
  faixa) de cada vigência, com arredondamento por componente — V1 15/31 + 16/31 → **114,96**; V2 30/31 + 1/31 →
  **119,47** (a vigência que começa no dia da leitura conta 1 dia); V3 9/30 + 10/30 + 11/30 → **123,51** (arredondar por
  vigência, e não por componente, daria 123,52).

## 11. Achados

Classificação: 🔵 **caracterização** (resposta a uma dúvida da especificação) · 🟡 **comportamento a decidir**
(pode virar candidato a divergência) · 🔴 **defeito do legado** (registrado, não corrigido) · ⚙️ **ambiente/massa**.

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-01 | As faixas progressivas aplicam-se **por economia**: o excesso do imóvel sobre o mínimo é repartido **igualmente entre todas as economias, de todas as categorias** (2 casas, HALF_UP), e cada economia paga o mínimo **da sua categoria** mais esse excesso nas faixas **da sua categoria** | FAT-001 V2, V3 (§10.4) | 🔵 | Responde a dúvida ❔ de CEN-FAT-001 ("granularidade das faixas"): **por economia individual**. Em V3 a repartição é por economia, **não** proporcional ao mínimo da categoria |
| F2-02 | O **consumo faturado exibido supera o informado** quando o excesso não divide pelas economias: 47 → 48 m³ (V2), 58 → 59 m³ (V3) — soma dos consumos por categoria arredondados para cima | FAT-001 V2, V3 | 🟡 | Se o mesmo valor for gravado na conta por `gerarConta`, a conta mostra consumo maior que o medido. Confirmar na fronteira da conta (faturamento em grupo) antes de decidir entre reproduzir e registrar candidato a divergência |
| F2-03 | Abaixo do mínimo, cobra-se a tarifa mínima, e o consumo exibido continua o **informado** (7 m³), não o mínimo | FAT-001 V6 | 🔵 | — |
| F2-04 | Tipo de cálculo 4 ("direto na faixa") cobra **todo** o consumo à tarifa da faixa em que ele cai, sem tarifa mínima separada | FAT-001 V7 | 🔵 | O tipo existe no código e na massa; se existe em alguma instalação real continua `A COMPLEMENTAR` (variante) |
| F2-05 | Mudança de vigência no período: resultado consistente com proporção **por dias corridos**, por componente de cada vigência; a vigência iniciada no dia da leitura atual pesa **1 dia** | FAT-002 V1–V3 (§10.4) | 🔵 | Responde, **como consistência**, a dúvida ❔ de CEN-FAT-002 ("base da proporção"); a parcela por vigência não é exibida — confirmar na conta gerada |
| F2-06 | O **mínimo da ligação** (`obterConsumoMinimoLigacao`) usa a vigência em vigor na **data corrente do servidor**, não a da referência faturada | `RepositorioMicromedicaoHBM:1375-1395` (`new Date()`) | 🟡 | Refaturar uma referência antiga usa o mínimo de hoje. Na caracterização vira **pré-condição de relógio**: vigências só no passado, conferidas a cada execução. Não observável na simulação — leitura de código, não baseline |
| F2-07 | Numa base nova, o grupo ADMINISTRADOR **não consegue** usar a simulação de cálculo: falta a concessão da operação "Adicionar Categoria Conta" (394) | Execução exploratória ("Acesso a operação negado") | ⚙️ | Consequência do achado da Fase 1 (concessões só das migrações); a caracterização usa operador próprio |
| F2-08 | Na tela de simulação, o **consumo de esgoto exibido** é a soma dos consumos de **água** por categoria, mesmo com esgoto POTENCIAL (27 m³ exibidos) | `SimularCalculoContaAction` (`consumoEsgoto + getConsumoFaturadoAguaCategoria()`); evidência `bruto.json` | 🔴 | Defeito de exibição da tela, fora dos observáveis de FAT-001/002; registrado para CEN-FAT-003 (esgoto) |
| F2-09 | Consultar Imóvel: o **total de economias** é somado pelo JSP a partir da composição — não lê `imov_qteconomia`; a categoria principal não é exibida | `imovel_consultar_cadastro.jsp:383-502` | 🔵 | Metade da pergunta de CEN-CAD-003: na **leitura**, o total deriva da composição. A coerência do denormalizado depende do caminho de escrita |
| F2-10 | A composição de economias vem **sem ordem definida** (sem `ORDER BY`) | `RepositorioImovelHBM:10961-10987` | 🔵 | Normalização `ordem_sem_semantica` (§7); o OpenGSAN não precisa reproduzir a ordem física |
| F2-11 | O schema pressupõe a linha 0 (DISPONÍVEL) em `situacao_atlz_cadastral` (`imovel.siac_id DEFAULT 0` + chave estrangeira), e nenhuma migração a cria: inserir imóvel falha numa base nova | Erro de chave estrangeira na primeira aplicação da massa | ⚙️ | A massa cria a linha, com evidência (`SituacaoAtualizacaoCadastral.DISPONIVEL`). Mesma família dos pré-requisitos P3 da Fase 1 |
| F2-12 | A consulta com matrícula inexistente não dá erro: preenche a inscrição com "IMÓVEL INEXISTENTE" | Execução exploratória | 🔵 | O roteiro trata como `nao_encontrado`; entra como variação de CEN-CAD-001 |

## 12. Próximos lotes

Ordem proposta — a de captura da [estratégia](../estrategia-testes.md#priorização-da-baseline-fase-2), agrupada por
**fronteira** (o que muda de lote para lote é a massa e o modo do EAR, não o mecanismo):

| Lote | Cenários | Fronteira / modo | Massa nova |
| ---- | -------- | ---------------- | ---------- |
| **2 — Autenticação e autorização** | SEG-001, 002, 004, 006, 007, 008 (A) + registro de SEG-009, 010, 012 (C); SEG-005 decide o próprio oráculo | Login, filtro de acesso, telas protegidas — Online | Perfis USR-01…USR-11 em delta de concessões; parâmetros da política de senha e de tentativas, fixados antes de capturar ([índice §15](../cenarios-criticos.md#15-o-que-a-fase-2-recebe)) |
| 3 — Cadastro e faturamento online | CAD-001, CAD-004, CAD-005, FAT-003 (percentual padrão pela simulação), FAT-011 V1 | Consultar Imóvel, simulação — Online | Perfis IMV-04, 11a, 15, 17; situações de ligação restantes |
| 4 — Atendimento e consumo mínimo | ATE-001…008, MIC-002 (valor obtido na tela de consumo mínimo) | RA → OS → encerramento — Online | ESP-01…06, SRV-01…03, UNI-01/02, OS com imóvel |
| 5 — Faturamento em grupo e Micromedição | BAT-001…005, FAT-001 V4/V5 e observáveis e/f, FAT-002 na conta, MIC-001/003/004/005 | Processos batch — **EAR em modo Batch** (`GSAN_TIPO=Batch`, novo build) | Cronograma, rotas, leituras, históricos (IMV-05…10, 12a/b, 16, 18) |
| 6 — Arrecadação, cobrança, financeiro | ARR-*, COB-*, FIN-*, OPE-* | Recepção de movimento, ações, contabilização — Batch/Online | DOC-*, movimentos de arrecadação, CTB-*, OPR-* |

Em paralelo: a **baseline de performance** do plano (inicialização, login, telas, lote) — os manifestos de execução já
registram horários, mas nenhuma medição foi tratada como baseline.

## 13. Limitações e bloqueios

- **Fronteira da simulação**: a simulação não gera conta — valor por faixa, contexto congelado, situação e referência
  da conta ficam para o faturamento em grupo (registrado em cada baseline).
- **Massa gravada por SQL** não responde perguntas do **caminho de escrita** do legado (ex.: se o total de economias
  denormalizado fica coerente) — exigem executar Inserir/Manter Imóvel.
- **Configuração da instância**: `parm_ictarifacategoria = 1` (tarifa por categoria) e nenhuma variante de companhia;
  as baselines valem para essa configuração, gravada em cada uma.
- **Modo do EAR**: o piloto é todo Online. Lotes batch exigem rebuild em Batch — um EAR por modo.
- **Custo por execução** (~1 min) é dominado pela subida do JBoss; é o preço do isolamento total e foi mantido.
- **Bloqueios**: nenhum para o próximo lote. BLQ-01 e BLQ-03 (D-17) continuam bloqueando os cenários que dependem deles.

## 14. Volume projetado

| Medida | Valor | Base |
| ------ | ----- | ---- |
| Variações a capturar | **234** (221 A + 13 C) | Matriz |
| Execuções | ~**700** (2 na captura + 1 na verificação, por variação) | Regra do mecanismo |
| Tempo de máquina | ~**12 h** online, sequencial, a ~1 min por execução — batch será maior (processo + modo Batch) | Piloto |
| Massas efetivas | ~**100** — no piloto, 11 variações usaram 5 (≈ 45%); extrapolação, não medida | Piloto |
| Custo real | **Autoria de massa e roteiros** (achar a fronteira, os pré-requisitos do schema e as concessões), não a execução | Piloto |

## 15. Estado da Fase 2

🟡 **FASE 2 — EM ANDAMENTO.**

| Critério de aceite do plano | Situação |
| --------------------------- | -------- |
| Rodadas repetidas produzem resultados idênticos | ✅ **Comprovado no piloto** — 11 de 11 variações idênticas nas 2 execuções de captura e conferidas numa 3ª, de verificação; o teste negativo acusa 1 centavo |
| Cobre os comportamentos priorizados | ⬜ 3 de 42 P0 da classe A — [cobertura](cobertura-baselines.md) |
| Baseline de performance | ⬜ Não iniciada |

Não se marca a Fase 2 como concluída: o mecanismo está pronto e provado; a cobertura é o trabalho dos próximos lotes.
