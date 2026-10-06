# Fase 2 — Caracterização e captura de baselines

> Relatório da Fase 2 do [plano de trabalho](../../plano-de-trabalho.md): *"baseline funcional automatizada"*, com o
> critério de aceite *"rodadas repetidas produzem resultados idênticos; cobre os comportamentos priorizados"*.
> Mecanismo: [`ambiente-referencia/baselines/`](../../../../ambiente-referencia/baselines/README.md). Gerados por script:
> [matriz de caracterização](matriz-caracterizacao.md) · [cobertura de baselines](cobertura-baselines.md).
>
> ⚠️ **FASE 2 — EM ANDAMENTO.** A 1ª execução classificou os 103 cenários, construiu o mecanismo e capturou o **lote
> piloto** (§9–§11); a 2ª capturou o **lote de Segurança** (§16); a 3ª, a **Segurança restante** (§17); a 4ª, o **lote 3
> — cadastro e faturamento online** (§18). A fase não está concluída: a cobertura dos
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
| **4 — Atendimento e consumo mínimo** (recomendado a seguir: P0 ATE-007, ATE-008 e MIC-002; o ciclo RA → OS é a dependência comum) | ATE-001…008, MIC-002 (valor obtido na tela de consumo mínimo), SEG-008 (permissões especiais sobre OS/RA), 🆕 CAD-004 (situação derivada e tipos de solicitação habilitados, na abertura de RA) | RA → OS → encerramento — Online | ESP-01…06, SRV-01…03, UNI-01/02, OS com imóvel |
| 5 — Faturamento em grupo e Micromedição | BAT-001…005, FAT-001 V4/V5 e observáveis e/f, FAT-002 na conta, MIC-001/003/004/005, 🆕 CAD-005, FAT-011 V1, FAT-003 V2/V3 e percentuais na conta, CAD-004 (forma de faturamento por situação especial) | Processos batch — **EAR em modo Batch** (`GSAN_TIPO=Batch`, novo build) | Cronograma, rotas, leituras, históricos (IMV-05…10, 11a/b, 12a/b, 16, 17, 18) |
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

## 14. Volume projetado

| Medida | Valor | Base |
| ------ | ----- | ---- |
| Variações a capturar | **234** (221 A + 13 C) | Matriz |
| Execuções | ~**700** (2 na captura + 1 na verificação, por variação) | Regra do mecanismo |
| Tempo de máquina | ~**12 h** online, sequencial, a ~1 min por execução — batch será maior (processo + modo Batch). Com a instância de inspeção no ar ou a máquina ocupada por outros contêineres, ~2–3 min por execução | Piloto; lotes de Segurança |
| Já capturado | **61 variações** de 16 cenários (piloto 11 + Segurança 19 + Segurança restante 15 + lote 3 16) — 26% das 234 | Cobertura |
| Massas efetivas | ~**100** — no piloto, 11 variações usaram 5 (≈ 45%); extrapolação, não medida | Piloto |
| Custo real | **Autoria de massa e roteiros** (achar a fronteira, os pré-requisitos do schema e as concessões), não a execução | Piloto |

## 15. Estado da Fase 2

🟡 **FASE 2 — EM ANDAMENTO.**

| Critério de aceite do plano | Situação |
| --------------------------- | -------- |
| Rodadas repetidas produzem resultados idênticos | ✅ **Comprovado** — piloto 11/11, Segurança 19/19 e Segurança restante 15/15 idênticas nas 2 execuções de captura; verificação independente (3ª execução, com o roteiro final) **Segurança 34/34** e **piloto 11/11**; 🆕 lote 3 **16/16** idênticas na captura e conferidas numa 3ª execução, com o piloto de novo 11/11 — as 61 baselines conferem; o teste negativo do piloto acusa 1 centavo |
| Cobre os comportamentos priorizados | 🟡 **12 de 42** P0 da classe A — Segurança (6), cadastro (3: composição, vínculos por papel, faturabilidade pela situação) e faturamento individual (3: água, vigência, esgoto); [cobertura](cobertura-baselines.md) |
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
