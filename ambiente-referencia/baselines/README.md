# Baselines do GSAN de referência (Fase 2)

Caracterização do legado: executar operações do GSAN sobre **massa sintética controlada**, a partir de um
**estado limpo**, e gravar o que ele **efetivamente produz** como baseline (*golden master*) versionada.
Relatório, critérios e resultados: [`docs/modernizacao/testes/fase2/`](../../docs/modernizacao/testes/fase2/fase2-caracterizacao-baselines.md).

> 🔴 Aqui não se implementa o OpenGSAN e não se corrige o legado. Um comportamento estranho do GSAN é
> **registrado** como achado, nunca "consertado" na massa ou no ambiente.

## Quatro coisas diferentes

| Termo | O que é | Onde |
| ----- | ------- | ---- |
| **Cenário** | A especificação: o que executar, o que observar, qual oráculo decide (Fase 0) | `docs/modernizacao/testes/cenarios/*.md` |
| **Variação** | Uma entrada concreta do cenário (V1, V2…), com a massa que ela exige | `cenarios/<CEN>.json` |
| **Massa** | O estado de dados: **base** (comum a todas as execuções) + **deltas** (por variação) | `massas/base/`, `massas/deltas/` |
| **Baseline** | O que o GSAN produziu para uma variação, normalizado — só existe depois de executar | `golden/<domínio>/<CEN>/<V>.json` |
| **Execução** | Uma rodada: estado limpo → massa → operação → observação. Evidência, não baseline | `.saida/baselines/<id>/` (não versionado) |

Variações que só diferem na entrada compartilham a **mesma massa efetiva** (ex.: CEN-FAT-001 V1, V2, V3 e V6);
uma massa serve a vários cenários (a base serve a todos). Uma baseline é função de *(massa, operação,
entrada, versão do legado)* — e cada baseline grava os quatro.

## Estrutura

```text
baselines/
├── caracterizacao-ajustes.tsv   ajustes manuais à classificação A/B/C/N, sempre justificados
├── caracterizacao.tsv           classificação derivada (gerada por ferramentas/caracterizacao.py)
├── cenarios/<CEN>.json          definição executável: fronteira, roteiro, variações, observáveis, normalizações
├── massas/base/*.sql            massa comum, aplicada em ordem a toda execução
├── massas/deltas/*.sql          massa por variação (perfis IMV-*, TAR-*, …)
├── golden/<domínio>/<CEN>/<V>.json   baselines (só `baseline.sh capturar` escreve aqui)
└── ferramentas/
    ├── cenarios.py              leitura das especificações (docs)
    ├── caracterizacao.py        classificação A/B/C/N → matriz (docs) e TSV
    ├── cobertura.py             relatório de cobertura (docs)
    ├── executor.py              massa efetiva, execução, consolidação (roda no contêiner `ferramentas`)
    ├── roteiros.py              operações do GSAN pelas telas do legado (HTTP)
    └── gsan_http.py             cliente HTTP mínimo (Struts, ISO-8859-1)
```

## Uso

Pré-requisito: ambiente da Fase 1 construído (`scripts/referencia.sh tudo`). O passo `banco` termina
**congelando** `gsan_comercial`/`gsan_gerencial` como modelos `gsan_*_ref` — o estado de partida de toda
execução. O modelo só nasce de um banco em que ninguém entrou pela aplicação.

```bash
scripts/baseline.sh lista                          # variações executáveis
scripts/baseline.sh capturar --lote piloto         # captura: 2 execuções por variação, grava golden/
scripts/baseline.sh capturar CEN-FAT-001:V1 --repeticoes 3
scripts/baseline.sh verificar --lote piloto        # nova execução, compara com golden/, não escreve
python3 baselines/ferramentas/caracterizacao.py gerar   # matriz A/B/C/N
python3 baselines/ferramentas/cobertura.py gerar        # cobertura de baselines
```

Cada execução de cada variação: **para o JBoss → recria os bancos dos modelos → aplica a massa efetiva →
sobe o JBoss do zero → autentica o operador sintético → executa a operação pelas telas → observa**. Nada
passa de uma execução à outra: nem banco, nem sessão HTTP, nem cache estático do JBoss (~1 min por execução).

## Regras

1. **Captura e verificação separadas.** `capturar` exige ≥ 2 execuções **byte a byte idênticas** (depois da
   normalização) antes de gravar; se já houver baseline diferente, recusa — `--substituir` só com a
   justificativa registrada no relatório. `verificar` nunca escreve em `golden/`.
2. **Massa conferida.** A massa aplicada fica em `public.baseline_massa` (arquivo + sha256); o executor
   recusa executar se ela não for a massa efetiva declarada na variação. A baseline grava a mesma lista:
   mudar um arquivo de massa invalida as baselines que o usam (a verificação acusa).
3. **Só dados sintéticos.** Nenhum dado real de cliente ou produção. Identificadores por constante do
   legado quando o código os fixa (evidência no comentário); o resto é declarado SINTÉTICO.
4. **Sem segredo.** O operador `fase2.oper` nasce sem senha; cada execução gera uma senha aleatória, grava
   só o hash no formato do legado e a descarta. Evidências registram o login **sem** o corpo da requisição.
5. **Normalização mínima e declarada** (`normalizacoes` no JSON): `identificador_tecnico`,
   `carimbo_tempo`, `data_execucao` e `ordem_sem_semantica` (só para lista que o legado devolve sem
   `ORDER BY`). O executor **recusa** normalizar caminho de dinheiro, estado, referência, consumo,
   categoria, tarifa ou identidade. Dinheiro é texto decimal exato, nunca ponto flutuante.
6. **Efeitos no banco observados.** Cada cenário declara tabelas vigiadas: contagem de linhas ou resumo
   do conteúdo antes × depois — uma consulta que escrevesse no banco apareceria na baseline.
7. **Pré-condições conferidas.** Ex.: o mínimo da ligação usa a vigência de tarifa em vigor na data
   **corrente** do servidor; a massa só tem vigências passadas e o executor confere isso (relógio).
8. **Evidência ≠ baseline.** HTML de cada resposta, requisições, saída bruta e manifesto (horários,
   tabelas antes/depois) ficam em `.saida/baselines/<id>/`, fora do versionamento.

## Acrescentar um cenário

1. Confirmar a classificação na [matriz](../../docs/modernizacao/testes/fase2/matriz-caracterizacao.md).
2. Achar a **fronteira** executável: a tela ou processo do legado que exercita a operação da especificação e
   **exibe** os observáveis — o que ela não exibe vai em `fora_desta_fronteira`, nunca é inventado.
3. Escrever a massa mínima como **delta** — inclusive as concessões novas do operador
   (`massas/deltas/concessoes-<lote>.sql`). A base só muda com recaptura consciente: mudar um arquivo da
   base invalida **todas** as baselines existentes (a verificação acusa a massa diferente).
4. Escrever o roteiro em `ferramentas/roteiros.py` e `cenarios/<CEN>.json`.
5. `baseline.sh capturar <CEN>` e, depois, `baseline.sh verificar <CEN>`; `cobertura.py gerar`.
