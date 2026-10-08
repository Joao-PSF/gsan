# Fase 2 — Caracterização e captura de baselines

> Relatório da Fase 2 do [plano de trabalho](../../plano-de-trabalho.md): *"baseline funcional automatizada"*, com o
> critério de aceite *"rodadas repetidas produzem resultados idênticos; cobre os comportamentos priorizados"*.
> Mecanismo: [`ambiente-referencia/baselines/`](../../../../ambiente-referencia/baselines/README.md). Gerados por script:
> [matriz de caracterização](matriz-caracterizacao.md) · [cobertura de baselines](cobertura-baselines.md).
>
> ⚠️ **FASE 2 — EM ANDAMENTO.** A 1ª execução classificou os 103 cenários, construiu o mecanismo e capturou o **lote
> piloto** (§9–§11); a 2ª capturou o **lote de Segurança** (§16); a 3ª, a **Segurança restante** (§17); a 4ª, o **lote 3
> — cadastro e faturamento online** (§18); a 5ª, o **lote 4 — Atendimento** (§19). A fase não está concluída: a cobertura dos
> comportamentos priorizados é o trabalho dos próximos lotes (§12).
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

Achados do lote de Segurança: **F2-13 a F2-25**, em [§16.8](#168-achados).

## 12. Próximos lotes

Ordem proposta — a de captura da [estratégia](../estrategia-testes.md#priorização-da-baseline-fase-2), agrupada por
**fronteira** (o que muda de lote para lote é a massa e o modo do EAR, não o mecanismo):

| Lote | Cenários | Fronteira / modo | Massa nova |
| ---- | -------- | ---------------- | ---------- |
| ~~2 — Autenticação e autorização~~ ✅ **capturado em 2026-10-05** (§16) | SEG-001, 002, 004, 005 (A) + registro de SEG-010, 012 (C) | Login e filtro de acesso — Online | Usuários e grupos sintéticos; limite de tentativas sintético; catálogos de situação e de auditoria |
| ~~2b — Segurança restante~~ ✅ **capturado em 2026-10-06** (§17) | SEG-006 (P0), SEG-007 (P0), SEG-003 (P1). **Ficam**: SEG-008 (P1) → lote 4, porque as ações condicionadas exigem OS/RA/comando de cobrança; SEG-009 (C) → lote 5 (Batch) | Login, filtro, troca de senha; Manter Conta (abrangência) — Online | USR-04…USR-08; território em degraus; níveis de abrangência |
| ~~3 — Cadastro e faturamento online~~ ✅ **capturado em 2026-10-06** (§18) | CAD-001, CAD-002 (entrou), CAD-004 (parte online), FAT-003 V1. **Saíram** para o lote 5, com evidência: CAD-005 (rotas só nos processos), FAT-011 V1 (`faturarImovel` só no faturamento em grupo), FAT-003 V2/V3 | Consultar Imóvel; Consultar Relação Cliente e Imóvel; simulação — Online | Fronteiras do DV; papéis e vigências do IMV-01; situações sintéticas |
| ~~4 — Atendimento e consumo mínimo~~ ✅ **capturado em parte em 2026-10-06** (§19) | ATE-007 V1, ATE-008, MIC-002 (nesta superfície), SEG-008 (ligação sem RA). **Ficam**: ATE-001…006 (fluxos de RA: abertura, encerramento, tramitação, espera, ciclo da OS), ATE-007 V2/V3 (religação, ligação de esgoto), as demais permissões de SEG-008, CAD-004 na abertura de RA | Efetuar Ligação de Água a partir de OS encerrada; Atualizar Consumo Mínimo (exibição) — Online | Catálogos de Atendimento; RA e OS encerradas; overrides de consumo mínimo |
| ~~5 — Faturamento em grupo~~ ✅ **capturado em 2026-10-07** (§20) — o modo Batch foi preparado e validado | BAT-001 V1/V2, BAT-002 V1–V3, BAT-003, BAT-004 V1/V1b, BAT-005, FAT-011 V1. **Ficam**: BAT-001 V3 (relatório), BAT-004 V2 (simultâneos) | Faturar grupo comandado — **EAR em modo Batch** | Catálogos do framework; cronograma, comando, rotas R1–R3 e consumos; falha controlada; IMV-16 |
| ~~5b — Faturamento na conta~~ ✅ **capturado em 2026-10-07** (§21) — reordenado: os P0 que já cabiam na fronteira do lote 5 | FAT-004 (V1–V4, com V1b, V2b, V3b, V3c), FAT-005 (V1–V3), FAT-006 (V1, V2); ATE-008 (valor de cada prestação na conta) respondido por FAT-004 V1/V1b. **Ficam**: FAT-004 V5 (taxa de emissão — processo de emissão) | Faturar grupo — Batch | Lançamentos, cliente responsável federal e impostos, micro-condomínio |
| ~~5c — Micromedição~~ ✅ **capturado em 2026-10-07** (§22) — os dois P0 | MIC-001 (V1–V4, V3b, V3c), MIC-003 (V1–V3). **Ficam**: MIC-001 V5 (situação especial), as operações de hidrômetro pela OS (MIC-003 a–d, h) | Consistir leituras e calcular consumos — Batch | Catálogos da Micromedição; hidrômetros, instalações, medições registradas, históricos |
| ~~5d — Ciclo de vida da conta~~ ✅ **capturado em 2026-10-08** (§23) | FAT-007 (V1, V1b, V2, V2b, V3, V4, V4b), FAT-008 (V1, V1b, V1c, V2, V2b). **Ficam**: a retificação por alteração da leitura faturada (motivo 104, imóvel hidrometrado) → 5e; a posição de dívida → 6 | Retificar e cancelar conta pela tela, sobre as contas que o faturamento em grupo gera na própria execução; prescrição em lote e manual — **Batch** | Catálogos da manutenção de conta; histórico de consumo; Arrecadação mínima e pagamento (passo); RA de alteração de conta; contas antigas; processo de prescrição |
| **5e — Consumo pela origem, na conta** (recomendado a seguir) | MIC-004/005, FAT-001 V4/V5 e observáveis e/f, FAT-002 na conta, CAD-005, FAT-003 V2/V3 e percentuais na conta, CAD-004 (situação especial), MIC-002 (precedência ao faturar), MIC-001 V5; 🆕 a retificação por alteração da leitura faturada (FAT-007, motivo 104) | Consistir e faturar em sequência — Batch | Situações especiais, vigências tarifárias, poço, rota alternativa (IMV-11a/b, 12a/b, 17, 18) |
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
- **Modo do EAR**: um EAR por modo, cada um no seu volume; o cenário declara o modo e o executor confere o rodapé
  (§20.3). O lote 5 é o primeiro em Batch.
- **Custo por execução** (~1 min) é dominado pela subida do JBoss; é o preço do isolamento total e foi mantido.
- **Catálogos que a base reconstruída não tem** (situações do usuário, ações e tipos de alteração da auditoria, tipos
  de relação cliente × imóvel, níveis de abrangência) entram pela massa, com os ids das constantes do código: a caracterização mostra o
  legado com o dado de referência que uma instalação teria. Sem eles, o legado **falha** (F2-15, F2-17, F2-29, F2-31) — o
  que também é registrado.
- **Limite de tentativas sintético** (3): o valor de uma instalação real é desconhecido; a baseline caracteriza o
  **mecanismo**, não o número. O mesmo vale para o histórico de senhas ligado em CEN-SEG-003 V5b.
- **Abrangência numa superfície**: CEN-SEG-007 cobre a consulta da GUI que chama a verificação (Manter Conta); as
  escritas que a chamam nos controladores (imóvel, micromedição, arrecadação, faturamento, cobrança) ficam com os lotes
  dos seus domínios. Os imóveis não têm conta: o "dentro" aparece pela resposta seguinte à verificação.
- **Bloqueios**: nenhum para o próximo lote. BLQ-01 e BLQ-03 (D-17) continuam bloqueando os cenários que dependem deles.
  🆕 **F2-42**: a semântica do valor 4 da situação de água e a completude de `imovel_situacao` exigem **dado de
  instalação** — a base reconstruída não tem nenhum dos dois, e a Fase 2 não usa dado real (CEN-CAD-004 fica em parte).
- **OS pela massa**: no lote 4, o RA e a OS nascem por SQL no estado em que o encerramento os deixaria — o objeto é o
  efeito da operação sobre a OS, não a abertura nem o encerramento (CEN-ATE-002…006, a capturar).
- **Lançamentos pela massa**: no lote 5b, débitos a cobrar, parcelamento, créditos a realizar e alíquotas nascem por
  SQL, no estado em que as operações que os criam os deixariam; o objeto é a **incorporação na conta**. O resultado do
  parcelamento depende da referência de faturamento do sistema, que na base está em 201410 (F2-70).
- **Leitura e hidrômetro pela massa**: no lote 5c, a medição do mês chega **registrada** e a troca de hidrômetro chega
  **aplicada**, no estado que "Efetuar Leitura" e a operação da OS deixariam; o objeto é a consistência. A referência de
  faturamento do sistema é alinhada ao mês do comando (05/2026), como numa instalação em operação — a base parou em
  201410 (F2-80).
- **Contas da própria execução**: no lote 5d, as contas manipuladas são as que o faturamento em grupo gera no início de cada
  execução (não vêm da massa); pagamento, RA e as contas antigas da prescrição chegam pela massa — o pagamento, por um passo
  aplicado depois do faturamento. A referência contábil e as datas de retificação/cancelamento saem relativas ao relógio; a
  prescrição compara o vencimento com hoje − 10 anos (as contas da massa estão longe dessa fronteira).
- **Processo pela massa**: no lote 5, cronograma, comando e consumos nascem por SQL; o objeto é o processo de faturar.
  A correção de causa de BAT-002 V2/V3 é aplicada por SQL **no meio** da execução (`massas/passos/`), porque a
  manutenção do imóvel é outra fronteira. O disparo **agendado** e o paralelismo das unidades são C4.

## 14. Volume projetado

| Medida | Valor | Base |
| ------ | ----- | ---- |
| Variações a capturar | **234** (221 A + 13 C) | Matriz |
| Execuções | ~**700** (2 na captura + 1 na verificação, por variação) | Regra do mecanismo |
| Tempo de máquina | ~**12 h** online, sequencial, a ~1 min por execução. 🆕 Batch: **~3–6 min por execução** (o verificador inicia o processo no minuto seguinte; reinícios e autorização somam ciclos) | Piloto; lotes de Segurança; lote 5 |
| Já capturado | **122 variações** de 33 cenários (piloto 11 + Segurança 19 + Segurança restante 15 + lote 3 16 + lote 4 17 + lote 5 10 + lote 5b 13 + lote 5c 9 + lote 5d 12) — 52% das 234 | Cobertura |
| Massas efetivas | ~**100** — no piloto, 11 variações usaram 5 (≈ 45%); extrapolação, não medida | Piloto |
| Custo real | **Autoria de massa e roteiros** (achar a fronteira, os pré-requisitos do schema e as concessões), não a execução | Piloto |

## 15. Estado da Fase 2

🟡 **FASE 2 — EM ANDAMENTO.**

| Critério de aceite do plano | Situação |
| --------------------------- | -------- |
| Rodadas repetidas produzem resultados idênticos | ✅ **Comprovado** — piloto 11/11, Segurança 19/19 e Segurança restante 15/15 idênticas nas 2 execuções de captura; verificação independente (3ª execução, com o roteiro final) **Segurança 34/34** e **piloto 11/11**; 🆕 lote 3 **16/16** idênticas na captura e conferidas numa 3ª execução, com o piloto de novo 11/11 — as 61 baselines conferem; 🆕 lote 4 **17/17** idênticas na captura e conferidas numa 3ª execução, com o piloto de novo 11/11; 🆕 lote 5 (EAR Batch) **10/10** idênticas na captura — inclusive a ordem dos imóveis na rota e os processos duplicados — e conferidas numa 3ª execução, com a regressão das **78 baselines Online, 78/78** — as 88 conferem; 🆕 lote 5b **13/13** idênticas na captura e conferidas numa 3ª execução, com o lote 5 e o piloto de novo **21/21**; 🆕 lote 5c **9/9** idênticas e conferidas numa 3ª execução, com os lotes 5, 5b e o piloto de novo **34/34** (duas delas depois da correção do relógio da observação, F2-86); 🆕 lote 5d **12/12** idênticas na captura e conferidas numa 3ª execução com o roteiro final, com os lotes 5, 5b, 5c e o piloto de novo **43/43**; o teste negativo do piloto acusa 1 centavo |
| Cobre os comportamentos priorizados | 🟡 **26 de 42** P0 da classe A — Segurança (6), cadastro (3), faturamento individual (3), na conta (3: lançamentos, impostos, rateio) e 🆕 do documento (2: retificação; cancelamento e prescrição), atendimento (2: efeito cadastral e financeiro da OS), micromedição (3: consumo mínimo e 🆕 consumo por situação de leitura e troca de hidrômetro) e processamento em lote (4: falha e reinício, atomicidade, duplicidade, lote × individual); [cobertura](cobertura-baselines.md) |
| Baseline de performance | ⬜ Não iniciada |

Não se marca a Fase 2 como concluída: o mecanismo está pronto e provado; a cobertura é o trabalho dos próximos lotes.

## 16. Lote 2 — Autenticação e autorização (2026-10-05)

Segundo lote, o primeiro item da [ordem de captura](../estrategia-testes.md#priorização-da-baseline-fase-2). Agrupado
pela **mesma fronteira** — login (`efetuarLoginAction`) e filtro de acesso (`FiltroSegurancaAcesso` →
`ControladorAcessoSEJB`) — e pela **mesma massa** de usuários sintéticos.

### 16.1 Cenários selecionados

| Cenário | Classe | P | Variações | Por que agora |
| ------- | ------ | - | --------- | ------------- |
| CEN-SEG-001 — autenticação e forma da credencial | A (1 + 2) | P0 | V1 | Porta de entrada; D-01 |
| CEN-SEG-002 — credencial inválida e bloqueio | A (1 · PENDENTE) | P0 | V1, V2, V3 | Bloqueio; CAND-03 |
| CEN-SEG-004 — matriz de autorização | A (1) | P0 | V1–V6, V5b, V7a, V7b, V7c, V7c2 | Negação provada; CAND-05; contorno CAND-06 (V5b) |
| CEN-SEG-005 — exceção por substring | A (PENDENTE) | P0 | V1 | CAND-04 |
| CEN-SEG-010 — cadeia de filtros | C (2) | P1 | V1, V2 | D-07 — só registro |
| CEN-SEG-012 — sessão e requisição forjada | C (2) | P1 | V1 | D-18 — só registro |

**Fora do lote, com motivo** (mesmo domínio, outra fronteira ou outra massa):
CEN-SEG-003 (ciclo de vida da credencial: USR-04…07, histórico, senhas proibidas — massa própria) ·
CEN-SEG-006 (auditoria: exige operação de negócio que **escreve** e campos anotados — e o catálogo de auditoria, ver F2-17) ·
CEN-SEG-007 (abrangência: hierarquia territorial completa e lista de superfícies que chamam a verificação; BLQ-01 nas demais) ·
CEN-SEG-008 (permissão especial: operações que dependem de OS) ·
CEN-SEG-009 (tokens dos servlets auxiliares — modo Batch) ·
CEN-SEG-011 (classe B, já comprovada).

### 16.2 Política de segurança — parâmetros da instância

| Parâmetro (`cadastro.sistema_parametros`) | Valor na base reconstruída | Uso no código (EVIDÊNCIA) | Na caracterização |
| ----------------------------------------- | -------------------------- | ------------------------- | ----------------- |
| `parm_nnmaximologinfalho` — tentativas de login | **NULO** | `EfetuarLoginAction:108,141` compara tentativas da **sessão** com o valor | **Fixado em 3 (SINTÉTICO)** por delta, para o bloqueio ser caracterizável; nulo derruba o login (F2-13) |
| `parm_icsenhaforte` | 2 | `ControladorAcessoSEJB:2411` — só valida senha forte se = 1 | Inalterado (troca de senha sem regra de força) |
| `parm_icbloqueiosenhasantes` | 2 | `:2213`, `:2422` — histórico de senhas só se = 1 | Inalterado |
| `parm_icdiasexpiracaosenhagrupo` | 2 | `:2103`, `:2139` — expiração por grupo só se = 1 | Inalterado |
| `parm_nndiasexpiracaoacesso`, `parm_nndiasmsgexpiracao` | NULOS | `:2056-2058` — tratados como 0 na troca de senha | Inalterados — a troca grava expiração **no próprio dia** (INFERÊNCIA do código; 🆕 ✅ **confirmada** por execução em CEN-SEG-003 V5 — §17.8) |
| `parm_icloginunico` | 0 | `SessaoHttpListener:55` | Inalterado |

Os valores vêm do banco (evidência); o significado vem do trecho de código citado (evidência). A única decisão
nossa é o limite **3**, declarado sintético: nenhum valor de instalação real é conhecido.

### 16.3 Massa

| Delta | Conteúdo | Evidência dos ids |
| ----- | -------- | ----------------- |
| `seguranca-usuarios.sql` | Situações PENDENTE SENHA/BLOQUEADA/INATIVO; grupos A, B, sem concessão; USR-01, USR-01B, USR-02, USR-03; concessões F1/O1 e F2; dependência F4 → F1 | `UsuarioSituacao`; catálogo de funcionalidades/operações das migrações |
| `seguranca-limite-tentativas.sql` | `parm_nnmaximologinfalho = 3` | — (sintético, declarado) |
| `seguranca-auditoria.sql` | Catálogo da trilha de auditoria: ações do usuário (EFETUOU OPERACAO, RESPONSAVEL INFORMACAO) e tipos de alteração (ALTERACAO, INCLUSAO, EXCLUSAO) — a troca de senha os exige | `UsuarioAcao`, `AlteracaoTipo` |
| `seguranca-restricao-usr01.sql`, `-usr02.sql` | Restrições por usuário (V7) | — |
| `seguranca-grupo-a-duas-operacoes.sql` | Segunda operação de F1 no grupo A (V7c) | catálogo |
| `clientes-imovel-imv03.sql` | Tipos de relação cliente × imóvel e um vínculo (CEN-SEG-005) | `ClienteRelacaoTipo` |

Usuários **separados** do operador da caracterização: bloquear ou restringir um usuário de cenário nunca afeta o
executor. Senhas **efêmeras** por execução, uma por rótulo (USR-01 e USR-01B recebem a mesma, como o perfil exige);
nenhuma senha, hash ou identificador de sessão vai à baseline — só o que o legado decidiu e a **forma** da credencial.

### 16.4 Mecanismo — o que mudou

- Roteiro `seguranca` **por passos** declarados na variação (sessão, login, contexto, situação, contadores, acesso,
  troca de senha, credenciais, cookie): uma fronteira, muitos cenários, parametrizados pela massa e pelos passos.
- O executor ganhou `autenticacao: roteiro` (o próprio roteiro autentica os usuários do cenário) e senhas por rótulo;
  o caminho do piloto não mudou — as 11 baselines do piloto seguem conferindo (§16.7).
- O cliente HTTP registra respostas de erro (4xx/5xx) como **resultado observável**, não como falha.

### 16.5 Baselines do lote

Em [`golden/seguranca/`](../../../../ambiente-referencia/baselines/golden/seguranca/) — **6 cenários, 19 baselines** (16 A + 3 C).

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| SEG-001 V1 | Autenticado; contexto: usuário `seg.usr01`, grupo A, menu "Consultar Imovel"; situação ATIVO; `usur_nnacessos` = 1; troca de senha **pelo GSAN** para USR-01 e USR-01B → valores gravados **iguais**, Base64 de 20 bytes (D-01) |
| SEG-002 V1 | Errada → "Por favor, verifique seu usuário e senha." (ATIVO); correta → tela principal |
| SEG-002 V2 | 3 erradas recusadas; a 4ª → "Números de tentativas de acesso excedeu o permitido. Senha bloqueada." (SENHA BLOQUEADA); correta → "situação correspondente a BLOQUE"… **e** `contexto` autenticado, F1 **permitida** |
| SEG-002 V3 | 2 + 2 erradas em sessões distintas → continua ATIVO; correta → tela principal |
| SEG-004 V1, V2 | F1 (e F2 para USR-02) **permitidas** |
| SEG-004 V3, V4 | F2 para USR-01 e F1 para USR-03 **negadas** ("Acesso a funcionalidade negado") |
| SEG-004 V5 | F1 permitida → O1 permitida e **executada** → O2 **negada** ("Acesso a operação negado") |
| SEG-004 V5b | O2 direta, com matrícula → negada; F1 com `idImovelDebitos` → **permitida, com cliente e endereço** |
| SEG-004 V6 | F4 (dependente de F1) **negada** — a dependência não concede |
| SEG-004 V7a / V7b | Negado (única concessão restrita) / permitido (outro grupo concede) |
| SEG-004 V7c / V7c2 | Permitido / permitido — duas concessões num grupo, sem e com uma restrição |
| SEG-005 V1 | Usuário sem concessão: F1 negada; `exibirPesquisarImovel` permitido; `pesquisarImovelAction` → **matrícula, cliente, endereço**; relatório de dados cadastrais gerado (ZIP/HTML, só a matrícula) |
| SEG-010 V1 / V2 | Sem sessão → HTTP 500 na página de negação / sessão sem usuário → "Acesso a funcionalidade negado" |
| SEG-012 V1 | Cookie sem `HttpOnly`/`Secure`/`SameSite`; troca de senha sem token aceita, com efeito |

`efeitos_no_banco`: `seguranca.usuario` **alterado** sempre que houve login com sucesso (o legado grava o último acesso
e o contador) ou troca de senha; **inalterado** no SEG-010 (nenhum login).

### 16.6 Determinismo

- **Captura**: 19 de 19 variações com as duas execuções **idênticas byte a byte**.
- **Verificação independente** (3ª execução, do estado limpo): 19 de 19 com **comportamento idêntico** ao da captura. 9 conferem byte a byte; 10 divergiram **só** no metadado `ressalvas` — acrescentado ao cenário depois de capturadas (V5b e a ressalva CAND-07) —, com **zero** linhas de diferença de comportamento (`20261005T174608Z-verificar`). Essas 10 foram regravadas com `--substituir` (§16.7).
- **Regressão do piloto** — o executor, o cliente HTTP e os roteiros mudaram neste lote: **11 de 11 `CONFERE`** (`20261005T180928Z-verificar`) — as mudanças do mecanismo não alteraram nenhuma baseline do piloto.
- Sem normalização: os passos foram desenhados para não expor carimbo de tempo, identificador de sessão nem valor
  de senha/hash — só decisões do legado, mensagens e formas.

### 16.7 Baselines substituídas — justificativa (`--substituir`)

Nenhuma substituição esconde comportamento do legado; todas corrigem **o roteiro ou a massa**, e as anteriores ficam
nas evidências da 1ª captura (`.saida/baselines/20260930T235854Z-capturar/`).

| Baseline | Primeira captura | Por que mudou |
| -------- | ---------------- | ------------- |
| SEG-001 V1 | (f) comparava hashes **gravados pelo executor** | Observável errado: passou a comparar os valores **gravados pelo GSAN** na troca de senha — o que D-01 descreve |
| SEG-002 V2 | Media a mensagem depois do bloqueio, não a sessão | Observável incompleto: acrescentados `contexto` e acesso a F1 depois do bloqueio (revelou F2-14) |
| SEG-004 V5 | O1 por URL que não é rota Struts (HTTP 400) e, depois, sem a entrada do caso de uso (HTTP 500) | Roteiro: O1 e O2 pela URL real do wizard, depois da entrada F1 |
| SEG-005 V1 | Procurava só a matrícula | Observável incompleto: "quais dados" — cliente e endereço |
| SEG-012 V1 | Troca de senha falhava (catálogo de auditoria ausente) | Massa: catálogo de auditoria (F2-17) |
| SEG-002 V1, V3 · SEG-004 V1–V4, V6, V7a, V7b, V7c | Sem as ressalvas acrescentadas depois (CAND-07, V5b) | **Só metadado**: a verificação mostrou comportamento idêntico; regravadas para que a baseline carregue as ressalvas vigentes do cenário |

### 16.8 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-13 | Base reconstruída **sem limite de tentativas**: com `parm_nnmaximologinfalho` nulo, a 1ª senha errada dá HTTP 500 (NPE) e nunca há bloqueio | `EfetuarLoginAction:141`; execução exploratória | ⚙️ 🔴 | Achado de segurança 29; massa fixa 3 (sintético) |
| F2-14 | **O bloqueio não bloqueia a sessão**: a senha correta depois do bloqueio mostra a recusa, mas autentica | SEG-002 V2; `EfetuarLoginAction:154-200` | 🔴 | Achado 26; **CAND-07** |
| F2-15 | Catálogo `usuario_situacao` só com ATIVO: o bloqueio falha por chave estrangeira (HTTP 500) e não acontece | Erro `fk3_usuario` | ⚙️ | Massa cria PENDENTE/BLOQUEADA/INATIVO pelas constantes |
| F2-16 | Tentativas **distribuídas em sessões** não bloqueiam (contador na sessão) | SEG-002 V3 | 🟡 | Sustenta **CAND-03** |
| F2-17 | Catálogo de auditoria vazio (`usuario_acao`, `alteracao_tipo`): toda operação que registra auditoria — a troca de senha incluída — falha com "Erro de acesso ao banco de dados" | Erros `fk1_usuario_alteracao`, `fk2_tabela_linha_alteracao` | ⚙️ | Massa cria pelas constantes; pré-requisito de CEN-SEG-006 |
| F2-18 | A troca de senha grava **o mesmo valor** para a mesma senha (Base64 de SHA-1, sem salt) | SEG-001 V1 (gravado pelo GSAN) | 🔵 | Registro de D-01 |
| F2-19 | Exceção por substring **devolve dado**: matrícula, cliente e endereço a usuário sem concessão | SEG-005 V1 | 🔴 | Achado 28; sustenta **CAND-04**; decide o oráculo pendente |
| F2-20 | Negação por operação **contornada** pela entrada da funcionalidade (encaminhamento interno não refiltrado); a entrada de F1 já abre na aba Débitos | SEG-004 V5b | 🔴 | Achado 27; **CAND-06** |
| F2-21 | A dependência entre funcionalidades **não participa** da decisão de acesso | SEG-004 V6 | 🔵 | Responde o pendente de V6 |
| F2-22 | A anomalia de composição do filtro de restrições **não muda a decisão** nas composições testadas | SEG-004 V7c, V7c2 | 🔵 | CAND-05 não confirmado (outras composições não testadas) |
| F2-23 | Quem nega é o **último elo** da cadeia; sem sessão prévia, a página de negação quebra (HTTP 500) | SEG-010 V1/V2; `FiltroSegurancaAcesso:287`, `FiltroSSO:20-28` | 🔵 | Registro de D-07 |
| F2-24 | Cookie de sessão sem atributos; requisição que altera estado aceita sem token | SEG-012 V1 | 🔵 | Registro de D-18 |
| F2-25 | Operação de wizard chamada sem a entrada do caso de uso na sessão → HTTP 500 | Exploração (1ª captura de V5) | 🔵 | Roteiros abrem a entrada antes da operação |

### 16.9 Mecanismo — lições operacionais

- **Comandos longos**: o limite de tempo dos comandos em segundo plano desta sessão interrompeu uma recaptura no meio
  (nenhuma baseline parcial: a gravação só ocorre depois das duas execuções). Capturas longas passaram a rodar como
  processo independente, acompanhadas pelo log.
- **Conexões depois de parar o JBoss**: com a máquina carregada, o PostgreSQL levou segundos para encerrar os backends
  e a guarda recusou recriar o banco. A guarda passou a **esperar** até 60 s — e continua recusando conexão que não sai.
- **Duas instâncias**: com a de inspeção no ar, a subida do JBoss das baselines foi de ~30 s para ~2 min; nenhum efeito
  sobre os resultados.
- **Verificação do ambiente — senha do `admin`.** No fim do lote a verificação deu 21 de 23: o `.env` havia sido alterado
  depois do congelamento dos modelos, e a `GSAN_ADMIN_SENHA` não correspondia mais ao hash do modelo (comparação feita
  dentro do contêiner, sem ler o valor); nenhuma baseline usa o `admin`. **Resolvido em 2026-10-05**: banco recriado
  (`referencia.sh recriar-banco --sim`), modelos recongelados com a senha atual, ambiente **23 de 23**, e as **30
  baselines conferidas contra o novo modelo** — piloto 11/11 (`20261005T224553Z-verificar`) e Segurança 19/19
  (`20261005T230208Z-verificar`). A reconstrução do banco pelas migrações é reprodutível: nenhuma baseline mudou.

## 17. Lote 2b — Segurança restante (2026-10-06)

Terceiro lote, o restante do domínio de Segurança que cabe na fronteira Online. Agrupado pela **mesma fronteira** do
lote 2 — login, filtro de acesso, troca de senha — mais **uma** superfície nova (Manter Conta, para a abrangência), e
pela **mesma massa** de usuários sintéticos, ampliada.

### 17.1 Cenários selecionados

| Cenário | Classe | P | Variações | Por que agora |
| ------- | ------ | - | --------- | ------------- |
| CEN-SEG-006 — auditoria em dois níveis | A (1; V3 não comparado) | P0 | V1, V2, V3 | Gate 0 → 1; o catálogo de auditoria já estava na massa (F2-17) |
| CEN-SEG-007 — abrangência onde o legado a verifica | A (1) | P0 | V1–V5 (um nível por variação) | Gate 2 → 3; ramo do filtro a esclarecer |
| CEN-SEG-003 — ciclo de vida da credencial | A (1) | P1 | V1–V6, V5b | Mesma fronteira e massa do lote 2: custo marginal baixo; regra 4 do registro |

**Fora do lote, com motivo**: CEN-SEG-008 (permissões especiais — as ações condicionadas são instalação de hidrômetro e
ligação de esgoto **sem RA**, replicar cobrança de serviço e encerrar comando de cobrança: exigem OS, RA e comando —
massa do lote de Atendimento) · CEN-SEG-009 (tokens dos servlets auxiliares — EAR em modo Batch) · CEN-SEG-011
(classe B, já comprovada).

### 17.2 Massa

| Delta | Conteúdo | Evidência dos ids / por quê |
| ----- | -------- | --------------------------- |
| `seguranca-redefinir-senha.sql` | Grupo B concede a funcionalidade 607 com a operação 818 | Catálogo das migrações; `oper_icregistratransacao = 1` |
| `seguranca-lembrete-usr01.sql` | USR-01 já tem o lembrete que a troca submete (V3) | Isola o campo **não anotado** |
| `territorio-abrangencia.sql` | Território em degraus: L3 (mesmo elo de L1), L4 (outro elo, mesma unidade), L5 (outra unidade, mesma gerência), L2 (outra gerência); um imóvel em cada (100048, 100056, 100064, 100072) | `verificarAcessoAbrangencia` (`ControladorAcessoSEJB:4153`); matrículas pelo dígito módulo 11 |
| `clientes-imoveis-abrangencia.sql` | Cliente usuário de cada imóvel | Sem ele, Manter Conta para em "nenhum cliente do tipo usuário" |
| `seguranca-abrangencia.sql` | Níveis de abrangência GERÊNCIA, ELO, LOCALIDADE, UNIDADE; grupo com Manter Conta (44/57); USR-08 — **um usuário por nível**, todos lotados em G1/U1/elo L1/L1 | Constantes de `UsuarioAbrangencia`; só o nível muda entre eles |
| `seguranca-ciclo-credencial.sql` | USR-04 INATIVO, USR-05 PENDENTE, USR-06A expirado ontem, USR-06B a expirar em 5 dias (aviso aberto), USR-07 | Datas **relativas** a `current_date` — o arquivo não muda de um dia para o outro |
| `seguranca-historico-senha.sql` | `parm_icbloqueiosenhasantes = 1` (V5b) | Sintético: o mecanismo com o controle ligado |
| `seguranca-senha-proibida.sql` | Um termo de teste na lista de senhas proibidas | Sintético; a coluna tem 6 caracteres |

Pré-requisitos que a base reconstruída não tem e que **falham** sem a massa (registrados): níveis de abrangência (só
ESTADO — F2-31) e `loca_nnconsumograndeusuario` da localidade (nulo derruba a carga da entidade — F2-29).

### 17.3 Mecanismo — o que mudou

- **Passos novos** no roteiro `seguranca`: `redefinir_senha` (818), `guardar_credencial`/`credencial_alterada` (a
  credencial mudou? — só igualdade, o valor não sai do executor), `auditoria`, `datas` (dias a partir de hoje),
  `historico` (contagem); `trocar_senha` aceita `lembrete` e, só para termo de teste sintético, `nova_literal`.
- **Auditoria sem identificador técnico**: os ids sequenciais dos registros não saem — a correlação é a **posição** na
  ordem de gravação; ids de usuário saem com o login (são da massa); o IP do cliente sai como "preenchido"; um valor de
  senha nunca sai, mesmo se aparecesse na trilha. Única normalização do lote, declarada: `carimbo_tempo` em
  `passos[*].carimbos[*].atual` (o carimbo de última alteração gravado pela operação).
- **Mensagem de "Atenção" com HTTP 500**: exceção de negócio não tratada (ex.: negação por abrangência, usuário
  inativo, senha anterior recusada) — a mensagem passa a ser lida também nessas páginas.
- **Correção de classificação no login**: a troca de senha imposta vem **dentro do leiaute** (com o link de logoff) e
  era classificada como tela principal — o teste de `novaSenha` passou a vir antes (§17.6).

### 17.4 Baselines do lote

Em [`golden/seguranca/`](../../../../ambiente-referencia/baselines/golden/seguranca/) — **3 cenários, 15 baselines**.

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| SEG-006 V1 | USR-02 redefine a senha de USR-01 (818): credencial de USR-01 alterada; `operacao_efetuada` com a operação 818, argumento = USR-01, dados adicionais com o nome; autor **USR-02** (EFETUOU OPERACAO), momento e IP preenchidos; trilha: carimbo de última alteração e descrição do objeto |
| SEG-006 V2 | Troca da própria senha (52) preenchendo o lembrete: trilha com `usur_dslembretesenha` vazio → `LEMBRETE SINTETICO` |
| SEG-006 V3 | Troca mantendo o lembrete: o lembrete **não** aparece; a senha mudou e `usur_nmsenha` **não** aparece na trilha |
| SEG-007 V1 (gerência) | L1, L3, L4, L5 dentro · L2 negado |
| SEG-007 V2 (unidade) | L1, L3, L4 dentro · L5, L2 negados |
| SEG-007 V3 (elo) | L1, L3 dentro · L4, L5, L2 negados |
| SEG-007 V4 (localidade) | L1 dentro · L3, L4, L5, L2 negados |
| SEG-007 V5 (estado, controle) | Todos dentro |
| SEG-003 V1 | INATIVO: HTTP 500 "O usuário seg.usr04 está inativo."; sem sessão; F1 negada |
| SEG-003 V2 | PENDENTE: login cai na **troca imposta**, mas a sessão existe — contexto autenticado e **F1 permitida** |
| SEG-003 V3 | Expirado ontem: idem V2 — troca imposta, F1 **permitida** |
| SEG-003 V4 | A expirar: tela principal com "Sua senha expira dentro de 5 dia(s)." |
| SEG-003 V5 | Parâmetro da instância (2): A → B → A **aceitas**; histórico vazio; depois da troca, expiração = **hoje**, e o login seguinte cai na troca imposta |
| SEG-003 V5b | Controle ligado (1): A → B aceitas; a volta para A é **recusada** com HTTP 500: "Senha já informada anteriormente para o usuário. Informe uma nova senha diferente das 3 anteriores."; 2 senhas no histórico |
| SEG-003 V6 | Termo da lista proibida: troca **aceita** — a lista nunca é consultada |

Dentro da abrangência, o legado segue para as contas do imóvel ("O imóvel de matrícula … não possui nenhuma conta.");
fora, "Acesso a operação negado devido a abrangência do usuário." — **ambas com HTTP 500** (F2-30). Unidade e gerência
do imóvel são as do **elo** da sua localidade.

`efeitos_no_banco`: SEG-006 — 1 registro de operação, 1 autor, 2 linhas e 2 ou 3 colunas de trilha por variação;
SEG-007 — imóveis e contas **inalterados** (a consulta não escreve); SEG-003 — histórico só cresce com o controle
ligado; cada troca aceita registra uma operação.

### 17.5 Determinismo

- **Captura**: **15 de 15** variações com as duas execuções **idênticas byte a byte** — SEG-006 (`20261006T133115Z-capturar`), SEG-007 (`20261006T134346Z-capturar`), SEG-003 (`20261006T141654Z-capturar`); SEG-012 V1 recapturada (`20261006T143116Z-capturar`, §17.6). Antes de cada captura, uma execução exploratória por variação conferiu os observáveis — evidência, nunca baseline.
- **Verificação independente** (3ª execução) e **regressão** — o roteiro mudou depois da captura de SEG-006 e SEG-007: **Segurança 34/34** conferem (`20261006T143318Z-verificar` — as 15 novas e as 19 do lote 2) e **piloto 11/11** (`20261006T150701Z-verificar`).
- Uma única regressão: a primeira cadeia de verificação foi **interrompida de propósito** logo depois da captura de SEG-007, para incluir o SEG-003 (que mudaria o roteiro de novo) antes de verificar tudo. Interromper uma verificação não deixa resíduo: ela nunca escreve em `golden/`.

### 17.6 Baseline substituída — justificativa (`--substituir`)

| Baseline | Captura anterior | Por que mudou |
| -------- | ---------------- | ------------- |
| SEG-012 V1 | O login com a senha nova registrado como `tela_principal` | **Classificação errada do roteiro**: a página era a **troca de senha imposta** (a troca grava expiração para o mesmo dia — F2-36), servida dentro do leiaute com o link de logoff, que o classificador testava primeiro. Comportamento do legado inalterado; o observável passou a dizê-lo (`alterar_senha`) |

### 17.7 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-26 | A linha de ALTERACAO da trilha grava **`id1 = 0`**: a linha alterada não é identificada nela. Causa: `Usuario` declara o **nome** como chave primária para a trilha (`retornaCamposChavePrimaria` → `nomeUsuario`); sem id inteiro, `getIds` devolve 0 | SEG-006 V1–V3; `Usuario.java:521-523`; `Interceptador:158-162`, `:1122-1124` | 🔵 | Objeto recuperável só pela operação e pela linha principal |
| F2-27 | A linha **principal** da trilha é sempre tipada **INCLUSAO**, mesmo numa alteração; a "chave" declarada (o nome) é gravada como coluna mesmo inalterada | SEG-006; `Interceptador:1745`, `:226-249` | 🔵 | Leiaute do legado, não requisito (oráculo semântico) |
| F2-28 | A operação 818 **redefine a senha de qualquer login para um valor fixo no código**, sem impor troca | SEG-006 V1; `EfetuarAlteracaoSenhaPorMatriculaAction:78-79` | 🔴 | Achado de segurança 30; **CAND-08**. Valor não transcrito |
| F2-29 | `loca_nnconsumograndeusuario` nulo (permitido pelo schema) derruba a carga da entidade `Localidade` (int primitivo): usuário lotado na localidade não entra | Execução exploratória; `Localidade.hbm.xml:21` | ⚙️ | Massa fixa 0 ("não informado") |
| F2-30 | Negação por abrangência entregue como **exceção não tratada (HTTP 500)** — a mesma forma da ausência de conta | SEG-007 | 🔵 | Não requisito: no OpenGSAN, resposta de negação |
| F2-31 | Catálogo `usuario_abrangencia` só com ESTADO: nenhum usuário pode ter abrangência restrita | Base reconstruída | ⚙️ | Massa cria os níveis pelas constantes |
| F2-32 | O ramo de abrangência do **filtro** é **inalcançável**: lê um atributo de requisição que nenhum código grava | `FiltroSegurancaAcesso:102, 253-258`; busca em `src/` | 🔵 | A abrangência só existe onde a Action/controlador a chama — reforça D-17/BLQ-01 |
| F2-33 | A lista de senhas proibidas **nunca é consultada** | SEG-003 V6; `pesquisarSenhasInvalidas` sem chamador | 🔴 | Achado de segurança 31 |
| F2-34 | Histórico de senhas **desligado** na base (parâmetro 2); ligado, recusa a volta a uma das 3 últimas | SEG-003 V5, V5b | 🟡 | Achado 31; parâmetro registrado como evidência |
| F2-35 | **Troca de senha imposta não restringe a sessão**: PENDENTE e expirado entram em funcionalidade concedida | SEG-003 V2, V3; `EfetuarLoginAction:187-190` | 🔴 | Achado de segurança 32; **CAND-09** |
| F2-36 | Com a validade nula da base, a troca grava a **expiração para o próprio dia**: o login seguinte já cai na troca imposta | SEG-003 V5; `ControladorAcessoSEJB:2071-2076` | 🟡 | Confirma por execução a inferência de §16.2 |

### 17.8 Política de senha — o que mudou de estado

| Item (§16.2) | Antes | Agora |
| ------------ | ----- | ----- |
| Expiração gravada pela troca com validade nula | INFERÊNCIA do código | ✅ **EVIDÊNCIA** — SEG-003 V5: expiração = hoje (F2-36) |
| Histórico de senhas (`parm_icbloqueiosenhasantes`) | Valor 2, inalterado | ✅ Efeito medido: com 2, sem histórico; com 1, 3 últimas recusadas |
| Aviso de dias para expirar | Não observado | ✅ Existe — "Sua senha expira dentro de N dia(s)." na tela principal (`ControladorAcessoSEJB:5471`) |
| Lista de senhas proibidas | Não observada | 🔴 Nunca consultada (F2-33) |

## 18. Lote 3 — Cadastro e faturamento online (2026-10-06)

Quarto lote, o item 2 da [ordem de captura](../estrategia-testes.md#priorização-da-baseline-fase-2) que roda **online**:
as fronteiras do piloto (Consultar Imóvel e Simular Cálculo da Conta) e uma tela nova (Consultar Relação Cliente e
Imóvel), sobre a mesma massa de território e imóveis.

### 18.1 Cenários selecionados

| Cenário | Classe | P | Variações | Fronteira |
| ------- | ------ | - | --------- | --------- |
| CEN-CAD-001 — matrícula e dígito verificador | A (1) | P1 | V1, V2, V3 | Consultar Imóvel, pela matrícula |
| CEN-CAD-002 — cliente × imóvel por papel e vigência | A (1) | P0 | V1–V4 | 🆕 Consultar Relação Cliente e Imóvel |
| CEN-CAD-004 — faturabilidade pela situação da ligação | A (1) | P0 | V1–V7 (parte online) | Simular Cálculo da Conta |
| CEN-FAT-003 — esgoto | A (1, ao centavo) | P0 | V1, V1b (percentual da ligação) | Simular Cálculo da Conta |

**Mudança de plano registrada (§12)**: o lote previa também CAD-005 e FAT-011 V1. **Saem**, com evidência:
CAD-005 (rotas por finalidade) só se observa nos **processos** de leitura e entrega; FAT-011 V1 (consumo de reserva
20) está em `faturarImovel`, chamado **só** pelo faturamento em grupo (`ControladorFaturamentoFINAL:1201`, `:52741`;
`ControladorFaturamento:14226`). Ambos vão para o lote 5 (EAR em modo Batch), com FAT-003 V2 (percentual alternativo,
decidido na geração da conta) e V3 (poço — a simulação recebe o campo e **não o usa**). Entra **CAD-002** (P0), que o
piloto deixara de fora por falta de fronteira temporal: a tela de Relação Cliente e Imóvel mostra os vínculos
**encerrados**, com início, término e motivo.

### 18.2 Massa

| Delta | Conteúdo | Evidência / por quê |
| ----- | -------- | ------------------- |
| `imoveis-matricula-dv.sql` | Imóveis nas fronteiras do módulo 11 (restos 0, 1, 10 e 2 → dígitos 0, 0, 1, 9), um **excluído** logicamente e um com **DV inválido** gravado pela massa (100019) | `Util.obterDigitoVerificadorModulo11`; o 100019 responde se a consulta confere o DV |
| `clientes-papeis-imv01.sql` | Motivo de fim de relação; clientes 2–5; IMV-01 com usuário anterior (encerrado em 15/05/2026, com motivo), usuário atual (desde 16/05/2026), proprietário e responsável | `clim_fim_relacao_motivo` **vazia** na base; troca no meio da referência 05/2026 |
| `localidade-l1-entidade.sql` | `loca_nnconsumograndeusuario = 0` em L1 | F2-29: sem ele, a tela de Relação carrega `Localidade` e quebra |
| `ligacao-agua-sit5-*.sql`, `ligacao-esgoto-sit5-*.sql` | A **mesma** situação 5 com dados diferentes: fatura / não fatura / mínimo de 30 m³ | Provar que o **dado** decide, não o id |
| `concessoes-cadastro-faturamento.sql` | Operador: Consultar Relação Cliente e Imóvel (121/158) | Catálogo das migrações |

### 18.3 Mecanismo — o que mudou

- Roteiros novos: `consultar_imoveis_matricula` (várias matrículas numa sessão, com a marca "(Excluído)") e
  `consultar_relacao_cliente_imovel` (vínculos com papel, início, término e motivo; filtros de situação e papel).
- `simular_calculo_conta` passa a distinguir **"calculado sem nada faturável"** (só os totais zerados) de **recusa** —
  antes, a falta de linhas era tratada como recusa e a tela inteira virava "mensagem". As 11 baselines do piloto não
  têm esse caso (regressão em §18.5).
- `baseline.sh` passa a dizer **qual variação** teve a massa recusada pelo banco: antes, um delta inválido (descrição
  acima de 20 caracteres) encerrou a cadeia sem mensagem do script.

### 18.4 Baselines do lote

Em [`golden/cadastro/`](../../../../ambiente-referencia/baselines/golden/cadastro/) e
[`golden/faturamento/`](../../../../ambiente-referencia/baselines/golden/faturamento/) — **4 cenários, 16 baselines**.

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| CAD-001 V1 | As 5 matrículas com DV correto encontradas — IMV-01 e as quatro fronteiras (dígitos 0, 0, 1, 9) —, com a inscrição |
| CAD-001 V2 | DV errado em ids inexistentes → "IMÓVEL INEXISTENTE" (o mesmo de qualquer id ausente); **100019, DV inválido, é encontrado** — a consulta **não confere o DV** |
| CAD-001 V3 | O excluído logicamente é **encontrado**, com "Dados do Imóvel **(Excluído)**" |
| CAD-002 V1 | 4 vínculos, na ordem do legado (papel, depois início): proprietário (01/03/2024, vigente) · usuário anterior (01/01/2025 → 15/05/2026, "MUDANCA DE USUARIO") · usuário atual (16/05/2026, vigente) · responsável (01/01/2026, vigente) |
| CAD-002 V2 / V3 | Vigentes: proprietário, usuário atual, responsável · Encerrados: só o usuário anterior, com término e motivo |
| CAD-002 V4 | Papel USUÁRIO: a sucessão anterior → atual, sem lacuna nem sobreposição — em cada data há um usuário definido (15/05 o anterior, 16/05 o atual) |
| CAD-004 V1 / V2 | Situação 5 com indicador ativo → água **110,40** (o mesmo valor do LIGADO em CEN-FAT-001 V1 — o id não pesa); a **mesma** situação com indicador inativo → **nada** faturado (totais 0,00) |
| CAD-004 V3 / V4 / V5 | Mínimo da situação 30 m³: 27 → **recusa** ("Consumo informado menor que consumo mínimo para situação da ligação de água, valor tem que ser maior que 30."); **30 → a mesma recusa**; 31 → água **133,35** |
| CAD-004 V6 / V7 | Esgoto na situação 5: indicador ativo → esgoto **110,40** a 100%; inativo → esgoto **0,00** (água 110,40 nos dois) |
| FAT-003 V1 | Esgoto LIGADO, 27 m³, percentual **100,00%** → esgoto **110,40** (igual à água); total **220,80** |
| FAT-003 V1b | Percentual **80,00%** → esgoto **88,32** (110,40 × 0,8, exato); total **198,72**; consumo de esgoto exibido 27 |

`efeitos_no_banco`: nenhuma tabela vigiada muda — as consultas e a simulação não escrevem (conta, histórico de consumo,
imóvel e vínculos inalterados).

### 18.5 Determinismo

- **Captura**: **16 de 16** variações com as duas execuções **idênticas byte a byte** (`20261006T182440Z-capturar`). Antes, duas rodadas exploratórias por variação (evidência, nunca baseline) revelaram o 500 da Relação Cliente e Imóvel (F2-29/F2-39), o limite de 20 caracteres da descrição da situação e um defeito do próprio roteiro (um caractere de controle na expressão que lê a lista de vínculos) — corrigidos antes da captura.
- **Verificação independente** (3ª execução): lote 3 **16/16** conferem (`20261006T185729Z-verificar`). **Regressão do
  piloto** — a simulação mudou: **11/11** (`20261006T191420Z-verificar`). Os roteiros de Segurança não mudaram desde a
  verificação 34/34 de §17.5.

### 18.6 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-37 | A consulta de imóvel **não confere o dígito verificador**: procura o id como digitado; DV errado só "não encontra" | CAD-001 V2 (100019 encontrado) | 🔵 | A identidade é o id inteiro; o DV não protege a digitação nesta tela |
| F2-38 | Exclusão **lógica**, tratada de forma diferente por tela: a consulta encontra e marca "(Excluído)"; a Relação Cliente e Imóvel **filtra** excluídos (por código — não executado para o excluído) | CAD-001 V3; `ExibirImovelRelacaoClienteImovelAction.criarFiltroConsultarImovelInformadoUsuario` (`indicadorExclusao ≠ SIM`) | 🔵 | Mapeamento semântico por superfície |
| F2-39 | **Erro mascarado**: falha de consulta do Hibernate aparece como "setRollbackOnly() not allowed without a transaction" (HTTP 500) — `ControladorUtilSEJB.pesquisar` marca rollback fora de transação e esconde a causa | Exploração de CAD-002; log do servidor (`ControladorUtilSEJB:159`) | ⚙️ | Diagnóstico; a causa real era F2-29 |
| F2-29 (2ª superfície) | O consumo de grande usuário nulo da localidade também derruba a Relação Cliente e Imóvel | idem | ⚙️ | Delta `localidade-l1-entidade.sql` |
| F2-40 | A faturabilidade vem do **dado** da situação (indicador, mínimo), não do id — a mesma situação 5 fatura ou não conforme a linha | CAD-004 V1/V2, V6/V7; `permiteFaturamentoParaAgua/Esgoto` | 🟢 | Confirma a especificação |
| F2-41 | **Borda do mínimo**: consumo **igual** ao mínimo da situação é recusado pela validação da simulação com a mensagem "menor que" — a regra é "menor ou igual"; o cálculo (`permiteFaturamentoParaAgua`) aceitaria a igualdade | CAD-004 V4; `verificarConsumoFaturadoAgua:36725` (`<=`) × `:1957` (`<=` no sentido oposto) | 🔵 | Registrar; a validação decide antes do cálculo |
| F2-42 | A base reconstruída **não tem** situações de ligação nem `imovel_situacao`: a semântica do **valor 4** (LIGADO_A_REVELIA × LIGADO_EM_ANALISE) e a completude da tabela paramétrica são **dado de instalação** | Base; catálogo da massa é todo sintético | ⚙️ | **Bloqueado** sem dado real — que a Fase 2 não usa |
| F2-43 | Na simulação, o esgoto é a tarifa de água aplicada ao volume de esgoto vezes o percentual (100% → igual à água) | FAT-003 V1/V1b | 🔵 | Registro do cálculo; o volume de esgoto exibido segue F2-08 |

## 19. Lote 4 — Atendimento: efeitos da OS e consumo mínimo (2026-10-06)

Quinto lote: os P0 do Atendimento e da Micromedição que rodam online — o **efeito** da execução de uma OS (cadastral e
financeiro) e o consumo mínimo que a tela da OS exibe — mais a permissão especial que a mesma tela consulta.

### 19.1 Cenários selecionados

| Cenário | Classe | P | Variações | Fronteira |
| ------- | ------ | - | --------- | --------- |
| CEN-ATE-007 — efeito cadastral da OS | A (1, mapeamento) | P0 | V1 (ligação de água) | Efetuar Ligação de Água, a partir de OS encerrada |
| CEN-ATE-008 — efeito financeiro do serviço | A (1, ao centavo) | P0 | V1, V1b, V2, V3, V3b, V4, V5 | idem — `gerarDebitoOrdemServico` |
| CEN-MIC-002 — consumo mínimo e overrides | A (1) | P0 | V1–V7 | Atualizar Consumo Mínimo da Ligação de Água (exibição) |
| CEN-SEG-008 — permissão especial nomeada | A (1) | P1 | V1, V2 (ligação de água sem RA) | Efetuar Ligação de Água, pela matrícula |

**Fora do lote, com motivo**: ATE-007 V2 (religação) e V3 (ligação de esgoto) — operações próprias, outras telas, a
mesma massa de OS serve; ATE-001…006 (consulta sob autorização, abertura e encerramento de RA, tramitação, espera, ciclo
de vida da OS) — fluxos de RA que este lote não exercita: a OS chega **encerrada pela massa**; as demais permissões
especiais de SEG-008 (hidrômetro e esgoto sem RA, replicar cobrança, encerrar comando).

### 19.2 Massa

A base reconstruída **não tem nenhum catálogo de Atendimento** (F2-44). A massa os cria pelas constantes do código,
SINTÉTICOS no resto:

| Delta | Conteúdo |
| ----- | -------- |
| `atendimento-catalogos.sql` | Tipo de categoria (as categorias das sementes não têm); UNI-01; meio de solicitação; situação de água FACTÍVEL; diâmetro, material, perfil e local do ramal; origem da ligação; motivo de não cobrança; motivo de encerramento com execução; situação de débito NORMAL (0) e forma de cobrança EM CONTA (1); tipo de débito; tipo de serviço 619 (`TIPO_LIGACAO_AGUA`), ligado à operação 257; tipo e especificação de solicitação; concessões do operador |
| `atendimento-os-ligacao-agua.sql` | IMV-A01 100200 com água FACTÍVEL, numa quadra **com rede**; cliente usuário; RA e OS de ligação **encerrada e executada**, comercial ainda não atualizado |
| `atendimento-srv-*.sql` | O **mesmo** tipo de serviço com outro dado: sem tipo de débito / permite alterar valor / cobra juros |
| `atendimento-permissao-*.sql` | Permissões especiais 30 (informar motivo de não cobrança) e 65 (ligação de água sem RA) — **inexistentes** no catálogo da base |
| `atendimento-os-consumo-minimo.sql` | Tipo de serviço 690 (`TIPO_CALCULAR_CONSUMO_MINIMO_AGUA`) com a operação 393; ligação de água do IMV-01 e do IMV-03; OS encerradas para cada um |
| `mic-*.sql` | Overrides de consumo mínimo: na ligação (30), na situação LIGADO (15), por área (25), e fator de economias da categoria (3) |

⚠️ **Ressalva de massa**: a quadra 1 de `territorio-l1.sql` grava `qdra_icredeagua = 1`, que pela constante é **SEM
REDE** (`Quadra.SEM_REDE = 1`) — o autor da massa leu "1" como "sim". As baselines anteriores não dependem desse
indicador; o imóvel do Atendimento fica numa quadra nova, com rede. `territorio-l1.sql` não muda.

### 19.3 Mecanismo — o que mudou

- Roteiro `efetuar_ligacao_agua`, autenticado pelo próprio roteiro (operador com senha efêmera): abre a OS (ou a
  matrícula, sem OS), **envia o formulário como o navegador** — exatamente os campos que a tela renderizou, mais as
  escolhas do usuário — e lê do banco o que a operação gravou: situação do imóvel, a ligação, os indicadores da OS e o
  débito a cobrar com a divisão por categoria. Ids sequenciais não saem; a referência contábil sai como "é o mês
  corrente". O que a variação **forja** (um valor que a tela não deixaria) fica explícito em `enviado`.
- Roteiro `consultar_consumo_minimo_ligacao_agua`: a exibição da tela de consumo mínimo, com o valor obtido e o fixado.
- `baseline.sh` sobe o banco da instância se ele estiver parado (antes, uma cadeia com a instância parada falhava na
  restauração).

### 19.4 Baselines do lote

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| ATE-007 V1 | Água FACTÍVEL → **LIGADO**; ligação criada (data da ligação = encerramento da OS, 05/09/2026; diâmetro, material, perfil); esgoto inalterado; serviço sem tipo de débito → **nenhum débito** e a OS **não** fica "comercial atualizado" |
| ATE-008 V1 | Débito de **R$ 100,00 em 3 prestações** (operador com a permissão): tipo do serviço, referência 201410, cobrança 201411, situação NORMAL, em conta, ligado à OS e ao RA; por categoria: residencial, 1 economia, 100,00; OS "comercial atualizado" |
| ATE-008 V1b | Sem a permissão a tela **fixa 1 parcela** — o POST com 3 é **aceito**: o mesmo débito em 3 prestações |
| ATE-008 V2 | Motivo de não cobrança informado → **nenhum débito**; a OS guarda o motivo |
| ATE-008 V3 | Serviço que permite alterar valor, R$ 80,00 → débito **80,00** |
| ATE-008 V3b | Serviço que **não** permite — a tela não deixa editar; R$ 80,00 enviado é **aceito** → débito 80,00 |
| ATE-008 V4 | Percentual 50% → débito **50,00** |
| ATE-008 V5 | Serviço que cobra juros, 3 parcelas, taxa de financiamento **nula** na base → débito de **R$ 0,00** em 3 prestações |
| MIC-002 V1 / V2 | Valor obtido **10** (IMV-01: 10 × 1) / **40** (IMV-03: residencial 10 × 2 + comercial 20 × 1) |
| MIC-002 V3–V6 | Overrides na ligação (30), na situação (15), por área (25) e os três juntos: valor obtido **10** em todos — nenhum entra no cálculo desta tela; o fixado na ligação aparece em campo **separado** |
| MIC-002 V7 | Fator de economias 3 na categoria residencial → **50** (10 × 3 + 20): o fator **substitui** o número de economias |
| SEG-008 V1 / V2 | Com a permissão, a tela habilita a matrícula e a ligação sem OS é efetuada; **sem a permissão, a tela não habilita — e o mesmo POST é efetuado** |

### 19.5 Determinismo

- **Captura**: **17 de 17** variações com as duas execuções **idênticas byte a byte** (`20261006T203748Z-capturar`). Antes, rodadas exploratórias por variação revelaram, uma a uma, os catálogos ausentes da base (F2-44), a quadra sem rede da massa do território, o defeito da validação do tipo de serviço (F2-46) e as exceções engolidas (F2-45) — e um defeito do próprio roteiro (enviava "valor do débito" vazio que a tela não renderiza), corrigido ao passar a enviar o formulário como o navegador.
- **Verificação independente** (3ª execução): lote 4 **17/17** conferem (`20261006T211339Z-verificar`). **Regressão do piloto** — o `baseline.sh` mudou: **11/11** (`20261006T213134Z-verificar`). Os roteiros existentes não mudaram (o lote só acrescentou funções).

### 19.6 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-44 | Base sem **nenhum** catálogo de Atendimento; categorias **sem tipo** — e a falta de tipo aparece como "imóvel sem subcategoria" | Exploração; `RepositorioImovelHBM.pesquisarObterQuantidadeEconomiasCategoria` (inner join com o tipo) | ⚙️ | Massa cria pelas constantes |
| F2-45 | **Exceções engolidas**: quatro métodos de `ControladorImovelSEJB` criam a exceção do repositório e não a lançam — a falha vira "não cadastrado" | `ControladorImovelSEJB:1424, 1488, 1552, 8750` | ⚙️ | Diagnóstico enganoso (como F2-39) |
| F2-46 | Validação do tipo de serviço na ligação **inoperante**: a ordem dos operandos chama `idOperacao.intValue()` antes de testar nulo — com operação, nunca confere o serviço; sem operação, NPE | `ControladorAtendimentoPublicoSEJB:380` | 🔵 | Registro |
| F2-47 | Fora do encerramento, a operação só aceita OS **encerrada, executada e sem atualização comercial**; o efeito cadastral vem da **operação**, não do encerramento | `validaOrdemServicoDiasAditivoPrazo:13840`; ATE-007 V1 | 🟢 | Confirma a especificação |
| F2-48 | A Action aplica a ligação **duas vezes** por requisição: o bloco da matrícula (sem OS) e o bloco da OS — a tela sempre envia a matrícula | `EfetuarLigacaoAguaAction:106-173` e `:177-304` | 🔵 | O estado final é o de uma ligação; registro |
| F2-49 | Permissão especial **só na tela**: sem EFETUAR_LIGACAO_DE_AGUA_SEM_RA a matrícula vem desabilitada, mas o POST com ela efetua a ligação **sem OS** | SEG-008 V2; a Action não consulta a permissão | 🔴 | Achado de segurança 33 |
| F2-50 | Parcelas, valor e motivo de não cobrança **aceitos do cliente**: a tela fixa 1 parcela e não deixa editar o valor; o servidor não confere | ATE-008 V1b, V3b; `ExibirEfetuarLigacaoAguaAction:428-437`, `EfetuarLigacaoAguaAction:282-292` | 🔴 | Achado de segurança 34 |
| F2-51 | Serviço que cobra juros, com a taxa de financiamento **nula** (como na base reconstruída), gera débito de **R$ 0,00** — receita perdida em silêncio | ATE-008 V5; `calcularValorPrestacaoAtendimentoPublico:13106-13121` | 🔴 | Parametrização obrigatória numa instalação |
| F2-52 | `valorPrestacao.setScale(2, HALF_UP)` tem o resultado **descartado** (BigDecimal é imutável): a prestação segue sem arredondar e o total volta exato (100,00 em 3) | `ControladorRegistroAtendimentoSEJB:13121`; ATE-008 V1 | 🔵 | A distribuição dos centavos fica para a conta (lote 5) |
| F2-53 | Serviço **sem tipo de débito**: a OS não é marcada "comercial atualizado" — continua apta a outra operação comercial | ATE-007 V1; `ControladorAtendimentoPublicoSEJB:303-308` | 🟡 | Registro |
| F2-54 | A operação 257 é marcada para registro de transação, mas a ligação **não deixa trilha** de auditoria | ATE-007/008 (registros de operação: 0) | 🟡 | Contraste com CEN-SEG-006 |
| F2-55 | O "Valor Obtido" do consumo mínimo ignora os overrides de ligação, situação e área; o fator de economias da categoria **substitui** as economias | MIC-002 V3–V7; `ControladorMicromedicao.obterConsumoMinimoLigacaoPorCategoria` | 🟢 | Responde, para esta superfície, a "ordem fina" pendente; a precedência ao faturar fica para o lote 5 |

## 20. Lote 5 — Faturamento em grupo em modo Batch (2026-10-07)

Sexto lote, o primeiro de **processos**: o faturamento de um grupo pelo processo comandado, executado pelo agendador do
EAR em modo Batch. Exigiu preparar e validar o modo Batch (§20.3) e caracteriza o **framework** de processamento — os três
níveis, a autorização, a falha por unidade, o reinício, a duplicidade — e o **resultado** do faturamento em lote.

### 20.1 Cenários selecionados

| Cenário | Classe | P | Variações | Fronteira |
| ------- | ------ | - | --------- | --------- |
| CEN-BAT-005 — lote igual à soma dos individuais | A (1, ao centavo) | P0 | V1 | Faturar grupo comandado — R1 com IMV-01, IMV-02, IMV-03 |
| CEN-BAT-001 — processo em três níveis, com autorização | A (1) | P1 | V1, V2 | idem; V2 com o processo exigindo autorização |
| CEN-BAT-002 — falha de unidade, retomada e reprocessamento | A (1) | P0 | V1, V2, V3 | idem — três rotas, falha controlada em R2; reinício pela tela |
| CEN-BAT-003 — atomicidade dentro da unidade | A (pendente) | P0 | V1 | idem — o imóvel do meio da R2 falha |
| CEN-BAT-004 — execução duplicada | A (pendente) | P0 | V1, V1b | idem — dois disparos; novo disparo depois de concluído |
| CEN-FAT-011 — imóvel sem consumo anterior | A (1) | P1 | V1 | idem — IMV-16 na R1 |

**Fora do lote, com motivo**: BAT-001 V3 (processo de relatório) — nenhum relatório batch exercido; BAT-004 V2
(disparos **simultâneos**) — concorrência real entre requisições; FAT-011 V2 — oráculo 2, só existe no OpenGSAN;
FAT-001 V4/V5, FAT-002 na conta, MIC-001/003/004/005, CAD-005, FAT-003 V2/V3 — exigem leituras, hidrômetros,
históricos e situações especiais que a massa deste lote ainda não tem (lote 5b, §12).

### 20.2 Massa

A base reconstruída **não tem** o que o framework e o faturamento em grupo pressupõem (F2-56). A massa cria pelas
constantes do código, SINTÉTICO no resto:

| Delta | Conteúdo |
| ----- | -------- |
| `categorias-com-tipo.sql` | Tipos de categoria (PARTICULAR, PÚBLICO) e o tipo de cada categoria — sem ele o imóvel "não tem subcategoria" (F2-44) |
| `batch-catalogos.sql` | Situações de processo (1–8), de etapa (1–7) e de unidade (1–4); atividade FATURAR GRUPO (5) ligada ao processo 2; o processo 2 com **tipo** (FATURAMENTO COMANDADO) e com a etapa de faturar (63) — a base só tem as etapas acessórias, postas fora de uso; tipos de ligação e de consumo; situação de débito NORMAL (0); tipos de conta (1–6); concessão do disparo |
| `batch-parametros-faturamento.sql` | Meses de validade da conta (`parm_nnmesesvalidadeconta = 3`) — nulo na base, quebra a geração da conta (F2-57) |
| `batch-faturamento-g1-202605.sql` | Cronograma de G1 para 05/2026, o **comando** de FATURAR GRUPO com a rota R1 (vencimento 10/06/2026) e o consumo REAL de 05/2026 de IMV-01 (27 m³), IMV-02 (47) e IMV-03 (58) — os mesmos das simulações CEN-FAT-001 V1–V3 |
| `batch-rotas-r2-r3.sql` | R2 e R3 no comando; R2 com IMV-R2a (15 m³), **IMV-R2x** (18 m³, **sem subcategoria** — a falha controlada) e IMV-R2b (22 m³), nesta ordem; R3 com IMV-R3a (33 m³) |
| `batch-imovel-sem-consumo.sql` | IMV-16 na R1, sem **nenhum** consumo registrado |
| `batch-permissoes-processo.sql` | Concessões de consultar, reiniciar e autorizar processo iniciado |
| `batch-processo-com-autorizacao.sql` | O processo 2 exigindo autorização (`proc_icautorizacao = 1`) |
| `massas/passos/batch-correcao-imovel-r2x.sql` | **Não é massa inicial**: a correção que o roteiro aplica entre a falha e o reinício (BAT-002 V2/V3), com o sha256 no resultado |

O que vem por SQL é o que as **etapas anteriores** do ciclo gravariam (Inserir Comando de Atividade, Consistir Leituras):
o objeto do lote é o processo, não a leitura nem o comando.

### 20.3 Modo Batch — preparação e validação

O piloto e os lotes 2–4 rodaram no EAR **Online**. O agendador (Quartz) só inicia no EAR **Batch** — `GSAN_TIPO=Batch`
no build, que grava o tipo no `version.properties` e o rodapé. Para não perder o EAR das 78 baselines existentes:

- **Um EAR por modo, cada um no seu volume** (`ear` e `ear-batch`); `referencia.sh` escolhe pelo `GSAN_TIPO` (build,
  subir) e a saída do build Batch vai para `.saida/build-batch/`.
- **O mesmo código**: do mesmo commit, os 247 jars do EAR Batch têm as **mesmas 22.614 entradas**, byte a byte, que os do
  Online — a única diferença é o `version.properties`; fora dos jars, só o `version.properties` e o rodapé. Os 504
  `.jasper` diferem por serem recompilados a cada build (artefato de compilação, não código).
- **Funcionando**: `referencia.sh verificar` **23/23** no EAR Batch; o log mostra o agendador iniciado e o verificador
  disparando a cada minuto; o rodapé mostra `referencia (Batch)`.
- 🔵 **NPE na iniciação do Batch** (F2-58): `AgendadorTarefas.agendarTarefaIntegracaoUPA` (:143-152) lê dois
  parâmetros nulos na base (hora de início e intervalo da integração UPA) como `int`. A exceção não impede o verificador
  — agendado na linha anterior (:47-48) —, e nada deste lote depende da integração. **Não corrigido** (o legado não muda
  nesta fase).
- O rótulo do rodapé vem do `version.properties` gravado no build; o atributo de contexto que distinguiria o modo em
  tempo de execução (`versaoTipo`) depende de um datasource `java:/BatchDS` que a receita não cria
  (`CarregarParametrosAction:66`) — por isso a guarda confere o rodapé.
- **O modo é exigido por cenário**: `"modo": "Batch"` na definição; `baseline.sh` sobe o JBoss com o EAR do modo e o
  executor **recusa** a execução se o rodapé mostrar outro modo (teste negativo: um cenário Online com o EAR Batch no ar
  é recusado). Cenários sem `modo` são Online — as 78 baselines anteriores não mudam de forma.

### 20.4 Mecanismo — o que mudou

- Roteiro `faturar_grupo` (autenticado pelo próprio roteiro, operador com senha efêmera): **dispara** pela tela "Inserir
  Processo Faturamento Comandado", registrando se o comando estava listado (e, com `forjar`, envia o POST que a tela não
  deixaria); **aguarda** o processo chegar a um estado final, sem mudar por 15 s (ou um ciclo de 75 s do verificador,
  para ver o que ele faz com um processo que não deve rodar); **autoriza** e **reinicia** pelas telas; **aplica** a
  correção de causa declarada; e lê do banco o estado final.
- O estado sai **sem ids nem carimbos**: processos pela ordem, unidades pelo código da rota, contas pela matrícula (com
  categorias e faixas), totais por rota e do grupo, consumos, referência do grupo, comando realizado e
  **`contas_iniciadas`** — quantos números a sequência das contas entregou durante a operação. Sequências não voltam num
  rollback: a diferença entre contas iniciadas e contas gravadas mede o trabalho **desfeito**.
- A exceção persistida sai pelo **registro** e pelas **chaves de mensagem** do legado que ela carrega; a pilha fica nas
  evidências (normalização "texto técnico da exceção" da especificação).

### 20.5 Baselines do lote

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| BAT-005 V1 | Três contas NORMAL de 05/2026 (vencimento 10/06/2026, validade 30/09/2026, referência contábil 202605): IMV-01 **110,40** (27 m³ — mínimo 32,50 + faixa 11–20: 10 m³ × 4,15 = 41,50 + faixa 21–30: 7 m³ × 5,20 = 36,40), IMV-02 **168,09**, IMV-03 **252,60** (residencial 128,66 + comercial 123,94); rota e grupo **531,09**. 🟢 **Igual, ao centavo, a CEN-FAT-001 V1–V3** em cada categoria (conferência abaixo) |
| BAT-001 V1 | Processo FATURAR GRUPO FATURAMENTO do grupo 1, solicitante `fase2.oper` → **CONCLUIDO**; etapa 63 (sequência 1) CONCLUIDA; **uma unidade por rota** (tipo 1 = ROTA, rota 1) CONCLUIDA; início e término registrados nos três níveis; comando realizado; grupo 05/2026 → **06/2026**. As contas **não têm autor** (`usur_id` nulo) e a operação não deixa registro de operação |
| BAT-001 V2 | Com o indicador de autorização, o processo nasce **AGUARD AUTORIZACAO** e a etapa EM ESPERA; depois de um ciclo do verificador **nada rodou** (nenhuma unidade, nenhuma conta, comando não realizado, grupo em 05/2026). O processo aparece na tela de autorização; **o próprio solicitante** o autoriza (operação própria, 1527) → CONCLUIDO, com as mesmas contas de V1 |
| BAT-002 V1 | R1 e R3 **CONCLUIDA**; R2 **CONCLUIDA COM ERRO**; a etapa CONCLUIDA COM ERRO com a exceção **persistida** (chave `atencao.nao_cadastrado.imovel_subcategoria`); processo **CONCLUIDO COM ERRO**; comando **não** realizado; grupo continua em 05/2026. Cinco contas: R1 (3), R3 (1) e a do **IMV-R2a** — o imóvel da R2 processado antes da falha |
| BAT-002 V2 | Correção da causa e reinício pela tela (a etapa com erro aparece para reinício): as **três** unidades são reexecutadas e terminam CONCLUIDA; contas novas só de IMV-R2x (65,70) e IMV-R2b (84,40) — R1, R3 e IMV-R2a **não duplicam** (7 números de conta entregues = 7 contas); processo CONCLUIDO; comando realizado; grupo → 06/2026; total **882,49** |
| BAT-002 V3 | V2 e, com o processo concluído, novo reinício da etapa **CONCLUIDA**: aceito pela tela; as três unidades rodam de novo e **nada** muda — 7 contas, grupo em 06/2026 |
| BAT-003 V1 | R2 com três imóveis, o do meio sem subcategoria: a conta do **primeiro** (IMV-R2a, 53,25) **fica gravada**; o terceiro não é processado; números de conta entregues **5 = contas gravadas** — nada foi desfeito; consumos intactos |
| BAT-004 V1 | Dois disparos pela tela, o comando listado nas duas vezes → **dois processos**, ambos CONCLUIDO, cada um com a sua unidade R1; **três contas** (uma por imóvel) e três números entregues — o segundo processo não gerou nada; grupo em 06/2026 |
| BAT-004 V1b | Depois de concluído, a tela **não lista** o comando (HTTP 500, "A pesquisa não retornou nenhum resultado."). O POST do mesmo comando é **aceito**: o segundo processo, CONCLUIDO, fatura **06/2026** — referência **sem comando e sem consumo** — pela tarifa mínima (IMV-01 32,50; IMV-02 97,50; IMV-03 136,40) e avança o grupo para **07/2026** |
| FAT-011 V1 | IMV-16, sem nenhum consumo registrado: conta de **0 m³** e **R$ 32,50** — a tarifa mínima residencial de 1 economia, sem faixa; **nenhum consumo gravado**; os outros três imóveis como em BAT-005 |

**Conferência BAT-005 × CEN-FAT-001** (lendo só `golden/`): V1 × IMV-01 RESIDENCIAL 110,40 = 110,40; V2 × IMV-02
RESIDENCIAL 168,09 = 168,09; V3 × IMV-03 RESIDENCIAL 128,66 = 128,66 e COMERCIAL 123,94 = 123,94 — **o lote é a soma dos
individuais**. O consumo difere na forma, não no valor: a conta grava o consumo **medido** (47 e 58 m³), e as categorias
somam o consumo distribuído por economia e arredondado (48 e 59 m³) — o que a simulação exibe como "consumo faturado"
(F2-59).

### 20.6 Determinismo

- **Captura**: **10 de 10** variações com as duas execuções **idênticas byte a byte** (`20261007T120644Z-capturar`),
  inclusive a ordem de processamento dos imóveis dentro da R2 (a consulta não tem `ORDER BY`; o plano é o mesmo para a
  mesma massa) e os dois processos de BAT-004. Antes, duas rodadas exploratórias acertaram o roteiro (dois erros de tipo
  em SQL — o PostgreSQL 9.5 não concatena inteiro com texto sem conversão).
- **Verificação independente** (3ª execução): lote 5 **10/10** conferem (`20261007T133127Z-verificar`).
- **Regressão Online** — a guarda de modo, o `baseline.sh` e o `referencia.sh` mudaram para todos os cenários: as
  **78 baselines** dos lotes piloto, 2, 2b, 3 e 4 **conferem** (`20261007T141238Z-verificar`), cada uma subindo o EAR
  Online pelo mecanismo novo. Com as 10 do lote 5, as **88** baselines conferem.

### 20.7 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-56 | A base não tem o que o processamento pressupõe: situações de processo, etapa e unidade **vazias**; nenhuma atividade de faturamento; o processo FATURAR GRUPO **sem tipo** e **sem a etapa de faturar** (só as acessórias); tipos de ligação, de consumo e de conta vazios; sem a situação NORMAL; `unidade_processamento` vazia. Sem tipo, o início do processo quebra (NPE em `verificarAutorizacaoBatch:6272`) | Exploração; `ControladorBatchSEJB:6260-6283` | ⚙️ | Massa cria pelas constantes; checklist de instalação |
| F2-57 | Meses de validade da conta **nulos** na base: a geração da conta quebra (NPE) | `ControladorFaturamentoFINAL:53629`, `:9440` | ⚙️ | Massa sintética (3); parâmetro obrigatório numa instalação |
| F2-58 | A iniciação do Batch lança NPE ao agendar a integração UPA (hora e intervalo nulos lidos como `int`) — depois de agendar o verificador, que segue funcionando | `AgendadorTarefas:47-48`, `:143-152` | 🔵 | Não bloqueia; registro |
| F2-59 | **Lote = soma dos individuais**, ao centavo, por categoria. A conta grava o consumo medido; as categorias guardam o consumo distribuído por economia e arredondado — a soma por categoria (48, 59) **não fecha** com o da conta (47, 58) | BAT-005 V1 × FAT-001 V1–V3 | 🟢 | Confirma a especificação; o consumo por categoria é observável próprio |
| F2-60 | Três níveis persistidos, cada um com situação, início e término; a ordem das etapas é **dado** (sequência); a unidade é a rota; o solicitante fica no processo. As escritas do processo **não têm autor** (`usur_id` nulo na conta) nem registro de operação — não há "usuário de batch" | BAT-001 V1 | 🟢 / 🟡 | Confirma o modelo; a autoria das escritas em lote é lacuna (USR-11) |
| F2-61 | Autorização: processo com indicador fica parado em AGUARD AUTORIZACAO (o verificador não o inicia) até a autorização pela tela, com **operação própria** — mas **o próprio solicitante autoriza**: não há segregação | BAT-001 V2; `AutorizarProcessoIniciadoAction` | 🟢 / 🟡 | Confirma a autorização distinta da permissão de tela; segregação é decisão de projeto |
| F2-62 | Falha **por unidade**: a exceção fica persistida na etapa, as outras rotas seguem, o processo termina CONCLUIDO COM ERRO, o comando não é realizado e o grupo não avança | BAT-002 V1 | 🟢 | Confirma a especificação |
| F2-63 | **A unidade não é atômica**: a conta do imóvel processado antes da falha fica gravada; nada é desfeito (números de conta entregues = contas gravadas). Na variante ativa (COSANPA), `faturarGrupoFaturamento` e `faturarImovel` são **`NotSupported`** — cada gravação confirma sozinha; o `setRollbackOnly` da falha não tem transação a marcar. A especificação e `modulos/batch.md §11` supunham `Required` | BAT-003 V1, BAT-002 V1; `descriptors/faturamentoCOSANPA/META-INF/ejb-jar.xml:118-128` | 🔴 | **CAND-02 caracterizado**: efeitos parciais — atomicidade no OpenGSAN exige divergência aprovada |
| F2-64 | O reinício é **por etapa e reexecuta todas as unidades** (apaga as unidades iniciadas e esquece as já executadas); não duplica porque `faturarImovel` **pula** o imóvel que já tem conta da referência (salvo PRÉ-FATURADA) — a salvaguarda é do **módulo**, não do framework. Reiniciar etapa concluída é aceito e não muda nada | BAT-002 V2, V3; `ControladorBatchSEJB:4565`, `:4588`; `ControladorFaturamentoFINAL:1297` | 🔵 | A especificação esperava "unidade concluída não é reexecutada": ela é — a idempotência vem do faturamento |
| F2-65 | Disparo **duplicado** com o comando ainda pendente: o framework aceita os dois e roda os dois processos; **não há faturamento em dobro** — a mesma salvaguarda do módulo | BAT-004 V1 | 🟢 | Oráculo 1 para o resultado (uma conta por imóvel) |
| F2-66 | **Novo disparo de comando já realizado fatura a referência seguinte**: a tela não lista o comando, mas o servidor não confere se ele foi realizado; a tarefa leva o grupo **como está** (já em 06/2026), não a referência do cronograma — fatura uma referência **sem comando e sem consumo**, pela tarifa mínima, e avança o grupo | BAT-004 V1b; `ControladorBatchSEJB:2678`, `:2892-2893` | 🔴 | Achado de segurança 35; **CAND-11** |
| F2-67 | Imóvel **sem nenhum consumo** é faturado com **0 m³ pela tarifa mínima**, e nenhum consumo é gravado. O "consumo de reserva 20" que a Fase 1 apontou (`ControladorFaturamentoFINAL:1875/1893`) fica em `obterValoresCreditosBolsaAgua` — o **crédito Bolsa Água** —, não no faturamento do imóvel | FAT-011 V1 | 🔴 (especificação) | Corrige a premissa de CEN-FAT-011 e a leitura de **D-15** (nota no registro) |

## 21. Lote 5b — Faturamento na conta: lançamentos, impostos e rateio (2026-10-07)

Sétimo lote, na mesma fronteira do lote 5 (faturar grupo comandado, EAR em modo Batch): o que a conta **incorpora** além
da água e do esgoto — débitos a cobrar, créditos a realizar, impostos retidos e o rateio de micro-condomínio. Três P0 de
Faturamento que só existem na conta gerada.

### 21.1 Cenários selecionados

| Cenário | Classe | P | Variações | Fronteira |
| ------- | ------ | - | --------- | --------- |
| CEN-FAT-004 — débitos cobrados e créditos realizados | A (1, ao centavo) | P0 | V1, V1b, V2, V2b, V3, V3b, V3c, V4 | Faturar grupo — IMV-01 com débito de serviço, parcelamento e crédito |
| CEN-FAT-005 — impostos deduzidos | A (1, ao centavo) | P0 | V1, V2, V3 | idem — IMV-01, 02 e 03 com cliente responsável de esfera federal |
| CEN-FAT-006 — rateio de micro-condomínio | A (1, ao centavo) | P0 | V1, V2 | idem — condomínio principal com dois micros na R1 |

**Fora do lote, com motivo**: FAT-004 V5 (taxa de emissão) — o débito nasce na **emissão** das contas
(`ControladorFaturamentoFINAL:29469`, `:39318`), outro processo; FAT-005 "base com centavos que exercitam o truncamento"
— a base soma valores de duas casas e o truncamento (`:29943`) não tem o que cortar nesta fronteira; MIC-001/003/004/005,
FAT-001 V4/V5, FAT-002 na conta e CAD-005 — exigem leituras, hidrômetros e históricos (consistir leituras) — lote 5c.

🆕 Variações que a especificação não tinha, acrescentadas porque o código mostrou uma regra a caracterizar: **V1b** (a
última prestação do débito), **V2b** (parcelamento recente), **V3b** (crédito maior que a conta), **V3c** (última
prestação do crédito) em FAT-004; **V3** (duas vigências de alíquota) em FAT-005.

### 21.2 Massa

| Delta | Conteúdo |
| ----- | -------- |
| `fat-lancamentos-catalogos.sql` | Forma de cobrança EM CONTA, financiamento PARCELAMENTO SERVIÇO (4), situação e tipo de parcelamento, origem de crédito (7), tipos de débito e de crédito SINTÉTICOS — a base não tem nenhum deles para uso geral (F2-68) |
| `fat-debito-servico-3x.sql` · `fat-debito-servico-ultima-prestacao.sql` | Débito de serviço do IMV-01 de **R$ 100,00 em 3** — o mesmo de CEN-ATE-008 V1 —, nenhuma cobrada / 2 cobradas |
| `fat-parcelamento-6x.sql` · `fat-parcelamento-recente.sql` | Parcelamento de 6 × R$ 50,00 feito em 09/2014 / em 04/2026 |
| `fat-credito-30.sql` · `fat-credito-maior-que-conta.sql` · `fat-credito-3x-ultima.sql` | Crédito de R$ 30,00 em 1 / de R$ 150,00 / de R$ 100,00 em 3 com 2 realizadas |
| `fat-impostos-orgao-federal.sql` | Esfera FEDERAL, cliente SINTÉTICO de órgão público como **responsável** de IMV-01, 02 e 03, tipos de relação cliente × imóvel, os quatro impostos e alíquotas SINTÉTICAS desde 01/2026 (IR 1,20 · CSLL 1,00 · COFINS 3,00 · PIS 0,65) |
| `fat-impostos-ir-meio-centavo.sql` · `fat-impostos-ir-duas-vigencias.sql` | IR a 2,50% (meio centavo exato sobre 252,60) / IR com uma alíquota anterior, de 01/2010 a 1,50% |
| `fat-condominio-micros.sql` · `fat-condominio-consumo-76.sql` | IMV-C (principal, 2 economias, com ligação de água), IMV-M1 (20 m³) e IMV-M2 (25 m³); o principal consome 75 / 76 m³ |

### 21.3 Mecanismo — o que mudou

- O roteiro `faturar_grupo` ganhou **blocos de detalhe opcionais** (`"detalhes"` na entrada): `lancamentos` (débitos
  cobrados, créditos realizados e o que resta a cobrar e a realizar), `impostos` (base, alíquota e valor por imposto) e
  `rateio` (consumo e valor rateados por conta e o histórico do principal e dos vinculados). Só entram quando a variação
  os pede — as 10 baselines do lote 5 não mudam de forma (regressão abaixo).

### 21.4 Baselines do lote

Em todas, IMV-01 tem água de **110,40** (27 m³ — a conta de CEN-BAT-005); IMV-02 e IMV-03 são faturados junto.

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| FAT-004 V1 | Débito de serviço de 100,00 em 3 → a conta cobra a **1ª prestação, 33,33** (valor ÷ 3 truncado), por categoria residencial; o débito a cobrar fica com 1 de 3 cobradas e a referência da prestação 202605. Conta **143,73** |
| FAT-004 V1b | O mesmo débito com 2 cobradas → a **3ª prestação leva o resto: 33,34**; 3 de 3 cobradas. Conta **143,74**. Fecha a pergunta deixada pelo lote 4 (F2-52): a distribuição dos centavos acontece **na conta** |
| FAT-004 V2 | Parcelamento de 6 × 50,00 feito em 09/2014 → a **1ª prestação, 50,00**, entra; o débito do parcelamento fica com 1 de 6. Conta **160,40** |
| FAT-004 V2b | O mesmo parcelamento feito em **04/2026** → **nenhuma** prestação entra (0 de 6 cobradas). Conta 110,40 |
| FAT-004 V3 | Crédito de 30,00 → realizado **30,00**; conta **80,40**; crédito 1 de 1, sem resíduo |
| FAT-004 V3b | Crédito de 150,00 → realizado **110,40** (o valor da conta); conta **0,00**; **resíduo de 39,60** guardado no crédito |
| FAT-004 V3c | Crédito de 100,00 em 3, 2 realizadas → a 3ª realiza **33,33** e o crédito se **encerra** (3 de 3, resíduo 0,00). Conta 77,07 |
| FAT-004 V4 | Débito (1ª de 3, 33,33) + parcelamento (1ª de 6, 50,00) + crédito (30,00) → débitos **83,33**, créditos 30,00, conta **163,73** |
| FAT-005 V1 | IR 1,20 · CSLL 1,00 · COFINS 3,00 · PIS 0,65 sobre 110,40 / 168,09 / 252,60 → impostos **6,46 / 9,83 / 14,78**; no IMV-01 o PIS sai **0,73** (0,65% isolado daria 0,72): o último imposto absorve o resíduo |
| FAT-005 V2 | IR a 2,50%: sobre 252,60 dá **6,315 exato → 6,31** (HALF_DOWN) |
| FAT-005 V3 | IR com duas alíquotas — 1,50% desde 01/2010 e 1,20% desde 01/2026 → a conta de 05/2026 usa **1,50%** (IMV-01 IR 1,66) |
| FAT-006 V1 | Principal 75 m³, micros 20 + 25 → **30 m³** a ratear → cada micro recebe **53,25**; contas 127,25 e 153,25 |
| FAT-006 V2 | Principal 76 m³ → **31 m³** → cada micro recebe **55,33** (15,5 m³ por economia valem 55,325); contas 129,33 e 155,33. O histórico do principal não recebe o rateio de consumo |

### 21.5 Determinismo

- **Captura**: **13 de 13** variações com as duas execuções **idênticas byte a byte** (`20261007T172854Z-capturar`). Antes,
  quatro rodadas exploratórias: três faltas de catálogo da base (forma de cobrança, tipos de relação cliente × imóvel —
  F2-68) e um erro do roteiro (coluna ambígua num join).
- **Verificação independente** (3ª execução): lote 5b **13/13** conferem (`20261007T184727Z-verificar`).
- **Regressão** — o roteiro `faturar_grupo` mudou (blocos de detalhe): lote 5 **10/10** e piloto **11/11** conferem
  (`20261007T192732Z-verificar`) — as 10 baselines do lote 5 não mudaram de forma. As **101** baselines conferem.

### 21.6 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-68 | A base não tem o que lançamentos e impostos pressupõem: forma de cobrança, financiamento de parcelamento, situação e tipo de parcelamento, tipos de relação cliente × imóvel, esfera de poder pública, **nenhum** tipo de imposto nem alíquota | Exploração | ⚙️ | Massa cria pelas constantes; checklist de instalação |
| F2-69 | Prestação do **débito**: valor ÷ N **truncado**; a **última** leva o resto (33,33 · 33,34) | FAT-004 V1, V1b; `ControladorFaturamentoFINAL:53141`, `:53170` | 🟢 | Fecha F2-52: a soma das prestações é o débito |
| F2-70 | A 1ª prestação de um **parcelamento** só entra se a referência do parcelamento for anterior à referência de faturamento **do sistema** (`parm_amreferenciafaturamento` — 201410 na base), não à do grupo: um parcelamento de 04/2026 não entra na conta de 05/2026 | FAT-004 V2, V2b; `:18195` ([FS0005]) | 🔵 | O resultado depende de um parâmetro que o encerramento mensal avança — registro; a referência do sistema é dado de instalação |
| F2-71 | **Crédito** limitado ao valor da conta: o excedente fica como **resíduo** no crédito, para as contas seguintes; a conta chega a 0,00 | FAT-004 V3b; `FaturamentoUtil.atualizarCreditosARealizar` | 🟢 | Confirma a especificação |
| F2-72 | A **última** prestação do **crédito não leva o resto**: 100,00 em 3 realiza 33,33 na 3ª e encerra o crédito — **1 centavo nunca creditado** ao cliente. O ajuste existe, mas só no pré-faturamento (`CreditoARealizar.calculaValorParcelaIntermediaria`) — assimetria com o débito (F2-69) | FAT-004 V3c | 🔴 | **CAND-12**: reproduzir é a regra (oráculo 1) até decisão — toca valor cobrado |
| F2-73 | Impostos: base = água + esgoto + débitos − créditos; cada imposto em **HALF_DOWN**, menos o **último**, que é total − anteriores, **truncado** — absorve o resíduo; meio centavo exato vai **para baixo** | FAT-005 V1, V2; `:29943-30021` | 🟢 | Responde a especificação: três políticas num só cálculo, agora com valores |
| F2-74 | **Alíquota de imposto: vale a mais ANTIGA**. A consulta filtra referência ≤ a da conta, ordena **da mais antiga para a mais nova** e fica com a primeira — com uma alíquota de 2010 e outra de 2026, a conta de 2026 usa a de 2010; uma nova alíquota **nunca** entra em vigor enquanto existir a anterior | FAT-005 V3; `RepositorioFaturamentoHBM.pesquisarAliquotaImposto` | 🔴 | **CAND-13**: retenção calculada com alíquota revogada |
| F2-75 | **Rateio** de micro-condomínio: consumo do principal − vinculados, valorado pela tarifa do principal, ÷ economias dos vinculados; o `+ new BigDecimal(0.005)` (de `double`), a divisão em FLOOR na escala longa e o arredondamento do PostgreSQL ao gravar `numeric(13,2)` levam **55,325 → 55,33** | FAT-006 V1, V2; `:60601`, `:60608`, `:60767-60785` | 🟢 | Responde a especificação: o efeito nos centavos, medido — não presumido |
| F2-76 | O rateio de **consumo** no histórico do principal só é **corrigido** ao fim da rota (`atualizarConsumosCondominios`) se a consistência de leituras o tiver gravado; sem isso, fica nulo — o rateio de valor da conta não depende dele | FAT-006; `ControladorMicromedicao:39543-39560` | 🔵 | Registro; o rateio de consumo é do lote de Micromedição |

## 22. Lote 5c — Micromedição: consistência de leituras e cálculo de consumos (2026-10-07)

Oitavo lote, no EAR em modo Batch: o processo **Consistir Leituras e Calcular Consumos** — o que a Micromedição grava como
consumo da referência a partir da leitura registrada, conforme a situação da leitura e a troca de hidrômetro. Os dois P0
da Micromedição que faltavam.

### 22.1 Cenários selecionados

| Cenário | Classe | P | Variações | Fronteira |
| ------- | ------ | - | --------- | --------- |
| CEN-MIC-001 — consumo por situação de leitura | A (1) | P0 | V1, V2, V3, V3b, V3c, V4 | Consistir leituras comandado — R4, um imóvel por perfil de leitura |
| CEN-MIC-003 — troca de hidrômetro na referência | A (1) | P0 | V1, V2, V3 | idem — substituição, instalação e retirada no meio do período |

**Fora do lote, com motivo**: MIC-001 V5 (situação especial PARALISAR_LEITURA_FATURAR_MEDIA — exige o histórico de
situação especial de faturamento); as **operações** de hidrômetro pela OS (MIC-003 observáveis a–d, g, h: a troca
chega pela massa); MIC-004/005, FAT-001 V4/V5, FAT-002 na conta, FAT-003 V2/V3, CAD-004 e CAD-005 — próximos lotes,
agora que o processo de consistência roda.

🆕 Variações acrescentadas: **V3b** e **V3c** em MIC-001 — o 2º e o 3º mês sem leitura, pelo que as consistências
anteriores teriam gravado (a especificação pedia a reincidência).

### 22.2 Massa

A base reconstruída não tem **nada** da Micromedição (F2-77). A massa cria pelas constantes do código:

| Delta | Conteúdo |
| ----- | -------- |
| `mic-catalogos.sql` | Processo SINTÉTICO com a etapa 52 (Consistir Leituras e Calcular Consumos) e as atividades EFETUAR LEITURA (2) e CONSISTIR LEITURAS (9); tipos de medição, situações de leitura, anormalidades de consumo, ações paramétricas da anormalidade de leitura (consumo e leitura a faturar), uma anormalidade de leitura SINTÉTICA "imóvel fechado", tipos de rateio, hidrômetro (marca, capacidade, tipo, diâmetro, situação, classe, local, proteção); o parâmetro CONSUMO_MINIMO_BOLSA_AGUA; os meses da média (6); limites de consumo das categorias |
| `mic-rota-r4-consistir-202605.sql` | Rota R4 (quadra 4); cronogramas de 04 e 05/2026 com EFETUAR LEITURA realizada e o **comando** de CONSISTIR LEITURAS de 05/2026 só para a R4 |
| `mic-imv-*.sql` | Um imóvel por perfil, cada um com ligação de água, hidrômetro(s), histórico de instalação, consumos anteriores e as medições de 04 e 05/2026 já **registradas** (o que "Efetuar Leitura" gravaria) |
| `mic-sem-leitura-2o-mes.sql` · `-3o-mes.sql` | O mesmo imóvel sem leitura também em 04/2026 (e 03/2026), com o que a consistência daqueles meses teria gravado |

### 22.3 Mecanismo — o que mudou

- 🆕 **Relógio da observação = relógio do legado** (achado de mecanismo, F2-86): a regressão noturna acusou
  CEN-BAT-005 V1 e CEN-FAT-011 V1 em `emitida_na_data_da_execucao` (`true ≠ false`). O JBoss grava datas no fuso da imagem
  (`imagens/jboss/Dockerfile:60`, America/Belem) e o banco roda em UTC: entre 21h e 24h locais, o `current_date` da sessão
  de observação já é o dia seguinte. **Não é comportamento do legado** — é o observador comparando dois relógios. A sessão
  `psql` das ferramentas passou a usar o fuso do legado (`PGTZ` no serviço `ferramentas`); o legado e o banco não mudam, e
  as baselines (capturadas de dia, quando os dois relógios dão a mesma data) continuam válidas — as duas foram verificadas
  de novo, à noite, com a correção (abaixo).
- O roteiro `faturar_grupo` serve à consistência sem mudança de fluxo: o comando é outro (atividade 9). O estado lê a
  realização **do comando da entrada** (antes, sempre o comando 1 — todas as baselines anteriores usam 1, nada muda) e
  ganhou o bloco opcional `micromedicao`: instalações de hidrômetro, medições (leituras informadas e de faturamento,
  consumo medido, média do hidrômetro, situação e anormalidades) e consumos (faturado, para média, médio, tipo,
  anormalidade).

### 22.4 Baselines do lote

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| MIC-001 V1 | Leituras 1000 → 1027 realizadas → consumo **REAL 27**; a medição grava o consumo medido (27) e a **média do hidrômetro, 26** (159 / 6, divisão inteira dos 6 meses REAIS); o consumo do mês: faturado 27, para média 27, médio 26 |
| MIC-001 V2 | Primeira leitura de hidrômetro instalado em 04/2026 (leitura de instalação 5) → consumo **27** (32 − 5), mas do tipo **ESTIMADO** — a situação ANTERIOR da medição é "não realizada" — e com anormalidade **FORA DE FAIXA**: sem consumo REAL no histórico, a média é o **mínimo (10)** |
| MIC-001 V3 | Sem leitura, anormalidade "imóvel fechado" (sem leitura: média; leitura anterior + média) → consumo **21** (média), tipo **MÉDIA HIDRÔMETRO**; leitura de faturamento **521** (500 + 21) |
| MIC-001 V3b | 2º mês sem leitura (04/2026 estimado) → o mês estimado **sai** da média: média **20** (os 5 REAIS restantes) → consumo 20; leitura de faturamento 511 (491 + 20) |
| MIC-001 V3c | 3º mês (03/2026 também estimado) → média **21** (os 4 REAIS restantes: 18, 22, 20, 24) → consumo 21; leitura 512 |
| MIC-001 V4 | Sem leitura, **sem** anormalidade, um só mês de histórico (8) → consumo **8** (a média de um mês), tipo MÉDIA HIDRÔMETRO, leitura de faturamento 16 (8 + 8) — e **nenhuma** anormalidade de consumo |
| MIC-003 V1 | Troca no meio do período: H5 (800 em 30/04) retirado com 812, H6 instalado com 3, leitura de 31/05 no H6: 15 → consumo **12 = 15 − 3** (só o trecho do H6), REAL, anormalidade **HIDRÔMETRO SUBSTITUÍDO INFORMADO**; a medição passa a ter anterior de faturamento **3** (a de instalação). Os **12 m³ do H5** (800 → 812) **não entram** |
| MIC-003 V2 | Instalação numa ligação sem hidrômetro (leitura 0), leitura de 31/05: 9 → consumo **9**, tipo **ESTIMADO** (situação anterior "não realizada"), sem anormalidade |
| MIC-003 V3 | Retirada sem reposição (400 em 30/04, retirada com 410) → consumo **NÃO MEDIDO 12** — o mínimo por **área** (80 m² → 12 m³), não o da tarifa (10); os **10 m³** registrados até a retirada **não entram** |

### 22.5 Determinismo

- **Captura**: **9 de 9** variações com as duas execuções **idênticas byte a byte** (`20261007T220053Z-capturar`). Antes,
  seis rodadas exploratórias revelaram, uma a uma, o que a base não tem (F2-77: descrições longas demais, o tipo de
  rateio, a situação anterior de uma medição sem mês anterior, o mínimo por área e a referência do sistema — F2-80,
  F2-81) e levaram o roteiro a guardar o texto técnico das exceções nas evidências.
- **Verificação independente** (3ª execução): lote 5c **9/9** conferem (`20261007T225625Z-verificar`).
- **Regressão** — o roteiro mudou (comando da entrada, bloco `micromedicao`, exceções nas evidências): lotes 5, 5b e
  piloto **32/34** (`20261007T232334Z-verificar`); as duas divergências — CEN-BAT-005 V1 e CEN-FAT-011 V1 — eram do
  relógio da observação (F2-86) e **conferem** depois da correção, verificadas às 22h locais, dentro da janela
  (`20261008T010002Z-verificar`). Regressão dos lotes
  Online com a correção, à noite (22h–23h40 locais): **67/67** (`20261008T010734Z-verificar`). As **110** baselines conferem.

### 22.6 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-77 | A base não tem **nada** da Micromedição: tipos de medição, situações e anormalidades de leitura e de consumo, ações paramétricas, tipo de rateio, hidrômetros e catálogos, consumo mínimo por área; nenhum processo com a etapa de consistência; o parâmetro CONSUMO_MINIMO_BOLSA_AGUA não existe (`Integer.valueOf` de nulo em todo imóvel com água); os **meses da média** (`parm_nnmesescalcmediacons`) e os limites de consumo das categorias são **nulos** | Exploração; `ControladorMicromedicao.determinarDadosFaturamentoAgua`, `obterVolumeMedioAguaEsgoto` | ⚙️ | Massa cria pelas constantes; checklist de instalação |
| F2-78 | **Consumo REAL** = leitura atual − anterior de faturamento; a **média** é a divisão **inteira** dos consumos dos últimos N meses cujo tipo entra na média (REAL), retroagindo até 24 meses; sem nenhum, vale o mínimo | MIC-001 V1, V2; `:2803`, `:3263`, `obterVolumeMedioAguaEsgoto` | 🟢 | Responde V1 da especificação |
| F2-79 | **Sem leitura**: com anormalidade, consumo e leitura vêm das **ações paramétricas** (média; anterior + média); a **reincidência** não tem regra própria — os meses estimados saem da média, que passa a ser a dos meses REAIS que restam na janela (21 → 20 → 21) | MIC-001 V3, V3b, V3c | 🟢 | Responde V3: o efeito da reincidência é o da janela da média |
| F2-80 | Parte da consistência **relê** a referência de faturamento do **sistema** em vez da do cronograma — o consumo não medido por área usa `parm_amreferenciafaturamento` (201410 na base): sem faixa de 2014, **NPE** e a unidade termina com erro | Exploração de MIC-003 V3; `:37743-37747`, `:25869` | 🔵 | Mesmo padrão de F2-70; **CAND-16** |
| F2-81 | **Primeira leitura** de hidrômetro novo (instalado no mês ou no anterior): a medição nasce com situação anterior "não realizada" e o consumo, medido, é tipificado **ESTIMADO** — que não entra na média seguinte; sem situação anterior, **NPE** | MIC-001 V2, MIC-003 V2; `determinarConsumoTipo:38163`, `gerarHistoricoMedicao:19533` | 🔵 | **CAND-15** |
| F2-82 | Leitura **não informada sem anormalidade**: a anormalidade LEITURA NÃO INFORMADA só é atribuída se o consumo **já tinha** outra — condição invertida; o consumo sai pela média sem anormalidade | MIC-001 V4; `:3145-3161` (atribuição em `:3155`) | 🟡 | Registro (monitoramento) |
| F2-83 | **Troca e retirada de hidrômetro**: a consistência usa só o trecho do hidrômetro **atual** (leitura atual − leitura de instalação) e ignora a **leitura de retirada** — o consumo entre a última leitura e a retirada (12 m³ na troca, 10 m³ na retirada) **não é faturado**. Responde a pergunta da especificação: nem soma dos trechos, nem regra alternativa | MIC-003 V1, V3; `determinarDadosFaturamentoAgua:2007-2014` | 🔴 | **CAND-14** — toca consumo faturado (oráculo 1 até decisão) |
| F2-84 | Sem hidrômetro, o consumo **não medido** vem do mínimo por **área** construída (12), não do mínimo da tarifa (10), quando `parm_icnaomedidotarifa` ≠ 1 | MIC-003 V3; `obterConsumoNaoMedido:37737-37747` | 🟢 | Registro da fonte |
| F2-85 | A consistência também é **`NotSupported`** na variante ativa: uma falha no meio deixa a medição atualizada sem o consumo do mês (observado na exploração, com a falta do tipo de rateio) | `descriptors/micromedicaoCOSANPA/META-INF/ejb-jar.xml:33-35` | 🔵 | Mesma natureza de F2-63 (CAND-02) |
| F2-86 | **Mecanismo**: o JBoss da referência grava datas em America/Belem e o banco roda em UTC — observações que comparam uma data gravada pelo legado com o `current_date` do banco viram entre 21h e 24h locais. Corrigido na sessão de observação (`PGTZ`), sem tocar no legado | Regressão de 2026-10-08 00:04 UTC; `imagens/jboss/Dockerfile:60` | ⚙️ | Ferramenta corrigida; baselines inalteradas |

## 23. Lote 5d — Ciclo de vida da conta: retificação, cancelamento e prescrição (2026-10-08)

Nono lote, no EAR em modo Batch: a **manutenção de conta** pelas telas do legado sobre as contas que o faturamento em
grupo gera no início da execução — retificar, cancelar — e a **prescrição**, em lote e manual. Os dois P0 de Faturamento
que faltavam na Etapa 4 (financeiro individual) do lado do documento.

### 23.1 Cenários selecionados

| Cenário | Classe | P | Variações | Fronteira |
| ------- | ------ | - | --------- | --------- |
| CEN-FAT-007 — retificação de conta | A (1 · 2 em g) | P0 | V1, V1b, V2, V2b, V3, V4, V4b | Faturar G1 → Manter Conta → Retificar Conta, sobre a conta de 05/2026 de IMV-01 |
| CEN-FAT-008 — cancelamento e prescrição | A (1) | P0 | V1, V1b, V1c, V2, V2b | Faturar G1 → Manter Conta → Cancelar Conta; Inserir Processo (eventual) → prescrição em lote |

**Fora do lote, com motivo**: a retificação por **alteração da leitura faturada** (motivo 104 — exige imóvel hidrometrado,
com medição e leitura na conta; é o caminho que corrige leitura e consumo **faturado** do histórico, `ControladorRetificarConta:263–273`)
fica para o lote 5e, que consiste e fatura em sequência; retificar **conjunto** de contas (outra operação, mesma regra por
conta); a presença na **posição de dívida** (CEN-COB-001, lote 6); a prescrição de imóveis **públicos** (outro processo);
desfazer cancelamento ou retificação.

🆕 Variações acrescentadas à especificação: **V1b** em FAT-007 (segunda retificação no mesmo mês), **V2b** (a resposta "Não"
à substituição da média) e **V4b** (sem permissão e sem RA); **V1b** em FAT-008 (cancelar a conta já retificada), **V1c**
(cancelamento sem permissão e sem RA, pelo POST que a tela recusa) e **V2b** (prescrição manual, pelo motivo de
cancelamento). A especificação pedia "retificação originada por RA" (V4) e "prescrição" (V2); o código mostrou dois caminhos
de cada.

### 23.2 Massa

As contas da referência 05/2026 **não** vêm da massa: são as do faturamento em grupo do lote 5 (IMV-01 27 m³ R$ 110,40;
IMV-02 R$ 168,09; IMV-03 R$ 252,60), geradas no início de cada execução. A massa traz o que a manutenção exige e a base não
tem (F2-87):

| Delta | Conteúdo |
| ----- | -------- |
| `conta-ciclo-catalogos.sql` | Situações de conta RETIFICADA, INCLUÍDA, CANCELADA, CANCELADA POR RETIFICAÇÃO, DÉBITO PRESCRITO e DÉBITO PRESCRITO INCLUÍDAS (constantes de `DebitoCreditoSituacao`); dois motivos de retificação e um de cancelamento SINTÉTICOS e o motivo DÉBITO PRESCRITO pelo id do código (64); as permissões especiais 48 e 51 (catálogo); as concessões de Manter, Retificar e Cancelar Conta; o cliente USUÁRIO de IMV-01; o parâmetro CONSUMO_MINIMO_BOLSA_AGUA; a referência de faturamento do sistema = 05/2026 e os meses da média = 6 |
| `conta-ciclo-permissao-sem-ra.sql` | O operador com RETIFICAR e CANCELAR CONTA SEM RA — todas as variações, menos V4/V4b de FAT-007 e V1c de FAT-008 |
| `conta-ciclo-consumos-imv01.sql` | O histórico de consumo de IMV-01 como a consistência o deixaria: para média de 05/2026 = 27, média 25 (três meses REAIS anteriores) |
| `conta-ciclo-arrecadacao.sql` · `passos/pagamento-conta-imv01-202605.sql` | O mínimo da Arrecadação (banco, agência, conta bancária, arrecadador, aviso, forma, tipo de documento, situação do pagamento) e, **depois do faturamento**, o pagamento classificado da conta de IMV-01 (R$ 110,40) |
| `conta-ciclo-ra-alteracao-conta.sql` | Um RA pendente de IMV-01 com especificação que valida ALTERAÇÃO DE CONTA (`'C'`), o motivo de encerramento CONCLUSÃO DE SERVIÇO (2) e o trâmite ENCERRAR (3) pelas constantes; o operador lotado na unidade de atendimento |
| `conta-ciclo-contas-antigas.sql` | Sete contas antigas de IMV-01..03, uma por condição da regra de prescrição (tabela em §23.4) |
| `conta-ciclo-processo-prescricao.sql` | Processo SINTÉTICO eventual com a etapa 1350 (Gerar Prescrever Débitos de Imóveis); uma situação de cobrança (sem ela, o processo trava — F2-98); as concessões de Inserir Processo |

### 23.3 Mecanismo — o que mudou

- O roteiro `faturar_grupo` ganhou três passos de tela: **`retificar`** (Manter Conta → Exibir Retificar → Retificar, com as
  confirmações que o legado pede — "conta já paga", "substituir o consumo para o cálculo da média" — respondidas pela
  variação), **`cancelar`** (Manter Conta → Exibir Cancelar → Cancelar, com `forjar` para o POST que a tela recusa) e
  **`iniciar_processo`** (Inserir Processo mensal/eventual). O passo **`aplicar`** passa a servir também ao pagamento, que só
  pode nascer depois da conta.
- Bloco opcional **`ciclo_conta`**: cada conta pela **identidade documental** — matrícula, referência e **ordem de criação na
  referência** —, nunca pela chave; situação atual e anterior, valores, economias, motivos, número de retificações, datas
  (relativas à execução quando gravadas pelo relógio do legado), referência contábil ("mês da execução" quando é o mês do
  relógio), origem, RA, autor; as **contas gerais sem documento** (exclusão física); pagamentos e RA pela identidade da conta
  a que apontam; o histórico de consumo; e a **trilha de auditoria** de cada operação (tabela, coluna, valor anterior e atual,
  como o legado os grava).
- Recusas e erros saem pelo texto exibido e pelas **chaves de mensagem** do legado; nunca pela pilha. A marca de tempo que
  Manter Conta põe na caixa de seleção (necessária ao cancelamento) e os ids só servem à navegação.

### 23.4 Baselines do lote

| Cenário · variação | Observado (baseline) |
| ------------------ | -------------------- |
| FAT-007 V1 | Retificar só as economias (1 → 2): nasce a conta **B** (ordem 2) RETIFICADA, 27 m³, **R$ 94,05**, motivo, 1 retificação, data de retificação = a da execução; a original **A** (ordem 1) fica **CANCELADA POR RETIFICAÇÃO** com os valores **preservados** (R$ 110,40) e situação anterior NORMAL. As duas com referência contábil = **mês do relógio** (outubro/2026, não 05/2026). **Nenhum vínculo explícito** B → A: `cnta_idorigem` nulo nas duas. Auditoria: economias 1 → 2, valor 110,40 → 94,05, motivo |
| FAT-007 V1b | Retificar de novo a conta B no mesmo mês (2 → 3 economias): **nenhuma conta nova** — B é alterada **em lugar** para R$ 97,50, 2 retificações. O documento de R$ 94,05 **deixa de existir**; só a auditoria guarda "94,05 → 97,50", como texto |
| FAT-007 V2 | Retificar o consumo 27 → 20 m³: o legado pergunta se "o novo consumo substituirá o consumo anterior para o cálculo da média"; **Sim** → B 20 m³ **R$ 74,00**; no histórico de 05/2026 o consumo **para média** é sobrescrito **27 → 20** e a média recalculada **25 → 23** (95 ÷ 4, divisão inteira) — **sem registro na auditoria**; o consumo **faturado** do histórico continua **27** |
| FAT-007 V2b | A mesma retificação respondendo **Não**: B igual a V2 (20 m³, R$ 74,00); histórico intacto (para média 27, média 25) |
| FAT-007 V3 | Conta paga (pagamento de R$ 110,40): o legado avisa "A conta do mês 05/2026 já está paga." e, confirmado, retifica (B R$ 94,05) — e **move o pagamento para B**: A, que recebeu o pagamento, fica sem ele; B fica com pagamento de R$ 110,40 para um valor de R$ 94,05 |
| FAT-007 V4 | Sem a permissão RETIFICAR CONTA SEM RA, com RA pendente de ALTERAÇÃO DE CONTA: retifica; o RA é ligado à conta **A** (a cancelada) — B não referencia RA — e **encerrado automaticamente**: motivo CONCLUSÃO DE SERVIÇO, parecer fixo, trâmite ENCERRAR na unidade do operador |
| FAT-007 V4b | Sem a permissão e sem RA: **recusa na exibição** (HTTP 500) — "Não existe RA que permita manutenção de conta para o imóvel 100013"; a conta segue NORMAL |
| FAT-008 V1 | Cancelar a conta NORMAL com motivo: **CANCELADA**, motivo, data de cancelamento = a da execução, situação anterior NORMAL (a referência da conta é a do sistema), referência contábil = mês do relógio; **o documento permanece**. A tela não diz "sucesso": volta ao formulário |
| FAT-008 V1b | Retificar e cancelar a conta **retificada** no mesmo mês: a conta B é **excluída fisicamente** (resta só a conta geral, com indicador 3, sem documento nem histórico); a original A volta como **CANCELADA**, com o motivo de cancelamento |
| FAT-008 V1c | Sem a permissão de cancelar sem RA e sem RA: a tela de cancelamento **recusa** (HTTP 500, "Não existe RA que permita manutenção de conta para o imóvel 100013"); o POST enviado **mesmo assim** é **aceito** — a conta fica CANCELADA, sem RA ligado. ⚠️ Registro do que o GSAN faz, **não** comportamento a reproduzir |
| FAT-008 V2 | Prescrição em lote: prescreve a NORMAL e a RETIFICADA vencidas em 2014 (→ **DÉBITO PRESCRITO**) e a INCLUÍDA (→ **DÉBITO PRESCRITO INCLUÍDAS**), com motivo DÉBITO PRESCRITO, data de cancelamento = a da execução, referência contábil = **05/2026 (do sistema)**, autor = usuário do batch e situação anterior **apagada**; **não** prescreve a paga, a vencida em 2020, a cancelada nem a retificada no mês corrente (contábil não anterior) |
| FAT-008 V2b | Prescrição manual — cancelar com o motivo DÉBITO PRESCRITO a conta de 06/2014 (NORMAL, vencida em 2014, sem pagamento, cliente particular): **recusada** (HTTP 500), com a chave de mensagem **sem texto** `???pt_BR.erro.conta_nao_satisfaz_criterios_para_prescricao???`; a conta segue NORMAL |

Contas da prescrição (V2, V2b):

| Conta (identidade) | Situação | Vencimento | Contábil | Regra | V2 |
| ------------------ | -------- | ---------- | -------- | ----- | -- |
| IMV-01 · 06/2014 | NORMAL | 10/07/2014 | 06/2014 | prescreve | DÉBITO PRESCRITO |
| IMV-01 · 07/2014 | RETIFICADA | 10/08/2014 | 08/2014 | prescreve | DÉBITO PRESCRITO |
| IMV-02 · 06/2014 | INCLUÍDA | 10/07/2014 | 09/2014 | prescreve (incluídas) | DÉBITO PRESCRITO INCLUÍDAS |
| IMV-02 · 08/2014 | NORMAL, **paga** | 10/09/2014 | 08/2014 | não — há pagamento | NORMAL |
| IMV-03 · 01/2020 | NORMAL | 10/02/2020 | 01/2020 | não — menos de 10 anos | NORMAL |
| IMV-03 · 06/2014 | CANCELADA | 10/07/2014 | 10/2014 | não — situação | CANCELADA |
| IMV-01 · 09/2014 | RETIFICADA no mês corrente | 10/10/2014 | 05/2026 | não — contábil não é anterior | RETIFICADA |

### 23.5 Determinismo

- **Captura**: **11 de 11** variações com as duas execuções **idênticas byte a byte** (`20261008T123955Z-capturar`); a V1c, acrescentada depois com o ramo `forjar` do cancelamento, também (`20261008T143915Z-capturar`). Antes, três rodadas de exploração dirigida e uma passada exploratória das 11 variações sem gravar (`20261008T120756Z-verificar`) revelaram o que a base não tem (F2-87), o processo que trava (F2-98) e a prescrição manual inoperante (F2-97).
- **Verificação independente** (3ª execução): lote 5d **12/12** conferem, com o roteiro final (`20261008T144657Z-verificar`). Uma verificação anterior, com o roteiro ainda sem o ramo `forjar`, já dera 11/11 (`20261008T135740Z-verificar`).
- **Regressão** — o roteiro ganhou passos e um bloco de detalhe (aditivos): lotes 5, 5b, 5c e piloto **43/43** conferem, com o roteiro final (`20261008T152942Z-verificar`). As 67 baselines Online dos lotes de Segurança, 3 e 4 usam roteiros que não mudaram; a última verificação delas é a do lote 5c (67/67). As **122** baselines conferem.

### 23.6 Achados

| # | Achado | Evidência | Classe | Efeito |
| - | ------ | --------- | ------ | ------ |
| F2-87 | A base não tem o que a manutenção de conta exige: as situações de conta além de NORMAL e PAGA, nenhum motivo de retificação ou de cancelamento, as permissões especiais 48 e 51, nenhum processo com a prescrição. Dois parâmetros derrubam operações inteiras: sem **CONSUMO_MINIMO_BOLSA_AGUA**, **toda** retificação termina em HTTP 500 — `RetificarContaAction:81` o lê antes de olhar o perfil do imóvel; com os **meses da média** nulos, confirmar a substituição do consumo dá NPE (`RepositorioMicromedicaoHBM:5292`) e "erro de acesso ao banco" | Exploração; código citado | ⚙️ | Massa cria pelas constantes; checklist de instalação |
| F2-88 | **Retificar** conta NORMAL cria **documento novo**: a original fica CANCELADA POR RETIFICAÇÃO com os valores preservados e situação anterior NORMAL; a nova, RETIFICADA, com motivo, número e data de retificação. A **referência contábil** das duas é o **mês do relógio** do servidor (`obterReferenciaContabilConta`: maior entre a referência do sistema, o mês corrente e a da conta) — outubro/2026 para uma conta de maio, com o sistema em maio | FAT-007 V1; `ControladorRetificarConta.retificarContasReferenciaContabilMenor`; `ControladorFaturamentoFINAL:56677` | 🟢 | Responde a–d da especificação; contábil pelo relógio registrado |
| F2-89 | **Linhagem só implícita**: a conta retificadora não referencia a retificada (`cnta_idorigem` nulo — o campo só é gravado na transferência de débitos entre imóveis, `ControladorCobranca:34815`); o que as liga é a mesma matrícula e referência e a situação CANCELADA POR RETIFICAÇÃO. O RA que autorizou a retificação fica ligado à conta **antiga** | FAT-007 V1, V4 | 🔵 | Corrige o localizador da especificação (`cnta_idorigem`); **CAND-21** |
| F2-90 | **Segunda retificação no mesmo mês altera em lugar**: conta RETIFICADA com referência contábil ≥ a do sistema é **sobrescrita** (`retificarContasReferenciaContabilMaiorOuIgual`); o documento anterior deixa de existir e o valor anterior só sobrevive na **auditoria**, como texto formatado | FAT-007 V1b | 🔴 | Contradiz "retificar cria documento novo, não edita" — **CAND-17** |
| F2-91 | **Cancelar a conta retificada no mesmo mês a EXCLUI**: o documento RETIFICADO é removido fisicamente (resta a conta geral com indicador 3, sem conta nem histórico) e a original volta como CANCELADA, com o motivo | FAT-008 V1b; `ControladorFaturamentoFINAL.cancelarConta` (ramo `isContaIncluidaOuRetificadaEReferenciaContabilMaiorOuIgual`) | 🔴 | Contradiz "cancelamento é estado, não exclusão" — **CAND-18** |
| F2-92 | **Retificar conta paga move o pagamento** para a conta nova (`atualizarPagamentoContaRetificada`): a conta que recebeu o pagamento fica sem ele, e a nova fica "paga" com valor diferente (R$ 110,40 para R$ 94,05) | FAT-007 V3 | 🔴 | Contradiz o resultado esperado (f) da especificação — **CAND-19** (toca valor: oráculo 1 até decisão) |
| F2-93 | **Consumo na retificação**: o legado pergunta se substitui o consumo "para o cálculo da média"; **Sim** sobrescreve o consumo para média do histórico (27 → 20) e recalcula a média (25 → 23, divisão inteira), **sem** registro na auditoria; **Não** deixa o histórico intacto. Em ambos, o consumo **faturado** do histórico continua o anterior (27) e a conta diz 20 | FAT-007 V2, V2b; `atualizarMediaConsumoHistoricoAoRetificarConta` | 🔵 | Responde (g): o valor anterior **não** é recuperável. Nota de evidência em **D-14** |
| F2-94 | **RA na retificação**: sem a permissão, a tela recusa sem RA de ALTERAÇÃO DE CONTA e o controlador também exige; com RA, o legado o liga à conta antiga e o **encerra** sozinho (motivo de conclusão, parecer fixo, trâmite ENCERRAR na unidade do usuário). O parecer é gravado com **bytes corrompidos** — o literal no fonte do legado tem caracteres de substituição (`ControladorRetificarConta:472`) | FAT-007 V4, V4b | 🟢 · 🟡 | Responde V4; o texto corrompido é **CAND-22** |
| F2-95 | **Cancelar** conta NORMAL é **estado**: CANCELADA, motivo, data, situação anterior NORMAL (porque a referência da conta é a do sistema; senão, nula), contábil pelo relógio; o documento permanece | FAT-008 V1 | 🟢 | Responde V1 |
| F2-96 | **Prescrição em lote**: vencimento anterior a **hoje − 10 anos**, contábil anterior à referência do sistema, sem pagamento; NORMAL/RETIFICADA → DÉBITO PRESCRITO, INCLUÍDA → DÉBITO PRESCRITO INCLUÍDAS; motivo pelo id 64 (sem a linha no catálogo, chave estrangeira); contábil = referência do **sistema** (não o relógio, ao contrário do cancelamento); situação anterior **apagada** | FAT-008 V2; `RepositorioCobrancaHBM.prescreverDebitosDeImoveis` | 🟢 | Responde V2 |
| F2-97 | **Prescrição manual nunca é aceita**: cancelar com o motivo de prescrição consulta a elegibilidade por uma HQL com a propriedade inexistente `conta.clienteConta` (o mapeamento é `clienteContas`); a exceção é engolida e a conta "não satisfaz os critérios" — qualquer conta, elegível ou não; a resposta é HTTP 500 com a chave de mensagem sem texto | FAT-008 V2b; `RepositorioFaturamentoHBM.pesquisarContaParaPrescricao:53932`, `ControladorFaturamentoFINAL:61105` | 🔴 | Defeito do legado — **CAND-20** |
| F2-98 | **Processo batch preso sem erro**: uma exceção na montagem da tarefa (`TarefaBatch.executar`, antes do envio ao MDB) não encerra nem registra a etapa. Com a situação de cobrança vazia, a prescrição lança `StringIndexOutOfBoundsException` (`Util.removerUltimosCaracteres` de lista vazia) no job do Quartz e o processo fica **EM PROCESSAMENTO** para sempre — indistinguível de um em andamento | Exploração (log do JBoss); `TarefaBatchGerarPrescreverDebitosDeImoveis:51` | 🔵 | **CAND-23**; massa traz a situação de cobrança |
| F2-99 | **Erro de banco engolido**: em `cancelarConta` e em `atualizarFaturaItemContaRetificada`, a falha do repositório marca a transação para rollback e cria uma `ControladorException` **sem lançá-la** — a operação é desfeita, mas a tela segue como se tivesse dado certo | Código: `ControladorFaturamentoFINAL:8637`, `:8808` (`cancelarConta`), `ControladorRetificarConta:836`; o mesmo padrão se repete em outros pontos do controlador | 🟡 | Registro (não exercido) |
| F2-100 | **RA exigido só na tela, no cancelamento**: sem a permissão e sem RA, a exibição recusa; o POST enviado mesmo assim cancela a conta — o controlador só procura o RA para ligá-lo (`verificarExistenciaRegistroAtendimentoSemLevantarExcecao`) e não recusa. Na retificação, o controlador recusa (`ControladorRetificarConta:426`, `:521`) | FAT-008 V1c; `ExibirCancelarContaAction`, `ControladorFaturamentoFINAL.cancelarConta` | 🔴 | Achado de segurança 36; **CAND-24** (mesma família de D-19, proposta) |
