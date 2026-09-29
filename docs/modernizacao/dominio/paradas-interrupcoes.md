# Paradas e Interrupções Operacionais

> **Adendo pós-Fase 0 (2026-09-29)** — refinamento arquitetural antes da Fase 1; a Fase 0 continua encerrada em 29/09/2026. Registro em [`alteracoes/2026-09-29-adendo-pos-fase0.md`](../alteracoes/2026-09-29-adendo-pos-fase0.md).
>
> Promove a conceito nativo o que a auditoria final registrou como *evento operacional com área afetada* (catálogo N2; [adendo do Operacional](../modulos/operacional.md)).
>
> ⚠️ **Não decide** schema, geometria física, protocolo com o Giswater, mecanismo de notificação ou ferramenta de mapa. Marcas como em [`financeiro-contabilizacao.md §1.1`](../modulos/financeiro-contabilizacao.md).

---

## 1. O conceito

**[DEC] PARADA / INTERRUPÇÃO OPERACIONAL** — o fato de o serviço deixar de ser prestado, ou ser prestado com restrição, numa área e num período, por um motivo. **Dono: Gestão Operacional.**

```text
PARADA  ≠  POLÍGONO  ≠  MINCUT
  │           │           │
  fato        projeção     cálculo de isolamento
  operacional espacial     (válvulas, elementos afetados)
  (dono:      do impacto   feito por ferramenta
  Gestão      (dono da     especializada
  Operacional) geometria:
               Redes/GIS)
```

🔴 **O Giswater não é dono da parada.** Ele calcula; a parada existe mesmo numa instalação sem Giswater (ADR-0008: Giswater não é dependência obrigatória).

**[GSAN]** A semente existe: a **programação de abastecimento e de manutenção** por área, consultada pelo Atendimento ao registrar falta d'água (CEN-OPE-002, C1). A Parada é o conceito nativo que a generaliza; ⚠️ a programação consultada pelo atendimento continua **equivalente** ao legado — a forma de projetá-la a partir da Parada é pendência (§16).

---

## 2. Tipos — eixos que não se confundem

| Eixo | Valores | Observação |
| ---- | ------- | ---------- |
| **Planejamento** | **Programada** — decidida com antecedência e comunicável previamente · **Não programada** — sem planejamento prévio | A NR ANA 11/2024 exige comunicação **prévia** da interrupção programada ao regulador e aos usuários |
| **Urgência** | **Emergencial** — não programada, por falha ou incidente que exige ação imediata | Emergencial é um **tipo de não programada**, não um sinônimo |
| **Efeito** | **Interrupção** — o serviço cessa · **Redução/restrição** — pressão, vazão ou horário reduzidos | Restrição **não é** interrupção |
| **Abrangência** | **Total** · **parcial** | Em relação à unidade operacional ou área de referência |
| **Serviço** | Abastecimento de água · coleta ou tratamento de esgoto | ⚠️ Não só água: a parada de uma elevatória de esgoto tem impacto próprio |
| **Regime** | **Racionamento** — regime de restrição por escassez, feito de **várias** interrupções ou restrições programadas por área (rodízio) | É um **plano** que gera paradas, não uma parada |

---

## 3. Modelo conceitual

```text
Parada
├─ identidade ........................ estável; nunca a do mincut
├─ tipo .............................. eixos do §2
├─ motivo ............................ catálogo parametrizado
├─ origem ............................ manutenção (PCM) · falha · incidente · terceiros ·
│                                      energia externa · racionamento · manobra operacional
├─ ativo relacionado ................. referência a Gestão de Ativos
├─ unidade operacional ............... referência a Gestão Operacional
├─ manutenção ........................ referência à necessidade do PCM, quando houver
├─ OS ................................ 0..n — manobra, reparo, normalização
├─ início previsto · normalização prevista
├─ início real · normalização real
├─ estado ............................ §4
├─ impacto ........................... §5 — calculado, declarado ou ambos, versionado
├─ comunicação ....................... eventos de negócio → Notificação (§12)
└─ histórico ......................... toda mudança, inclusive previsão revisada
```

🔴 **Previsão revisada não sobrescreve a previsão anterior** — o histórico de previsões é o que permite medir *previsto × realizado*.

---

## 4. Estados

| Estado | Programada | Emergencial |
| ------ | ---------- | ----------- |
| **Proposta** | Pedido de janela (do PCM ou da operação) | — |
| **Em análise** | Impacto calculado ou declarado; conflitos verificados | — |
| **Planejada** | Aprovada, com janela e comunicação prévia | — |
| **Ativa** | Serviço interrompido ou restrito | Nasce aqui, sem planejamento prévio |
| **Em normalização** | Serviço sendo restabelecido — recuperação de pressão, esvaziamento de redes, descarga | Idem |
| **Encerrada** | Normalização confirmada; realizado registrado | Idem |
| **Cancelada** | Não ocorreu, com motivo | — |

Reprogramar é **evento** registrado no histórico, não estado.

---

## 5. Impacto

A parada pode relacionar, conforme o dado disponível: **rede · sistema · subsistema · setores · bairros · localidades · ativos · imóveis/unidades usuárias · clientes críticos** (hospitais, unidades de diálise, escolas) **· serviços críticos**.

| Forma de obter | Quando | Registro |
| -------------- | ------ | -------- |
| **Calculado** | Redes/GIS com topologia consistente — Giswater *mincut* (§7) | Elementos afetados, **data do cálculo e versão da topologia** |
| **Declarado** | Sem topologia, ou emergência sem tempo para calcular | Recortes territoriais e operacionais escolhidos pelo operador, com responsável |
| **Misto** | Cálculo ajustado pela operação | Os dois, com a justificativa do ajuste |

🔴 **Não se assume que todo impacto pode ser calculado automaticamente.** O cálculo depende de topologia íntegra, válvulas classificadas, entradas de água configuradas e estado operativo dos elementos — requisitos que o próprio Giswater documenta (§7). O impacto guardado é um **snapshot versionado**: recalcular depois não altera o que foi comunicado.

**Unidades usuárias afetadas**: o elo entre o elemento de rede (ligação/ramal, hidrômetro) e a unidade usuária é o da [matriz por atributo](../arquitetura/gis-redes-ativos.md) — identidade corporativa, nunca cópia. ⚠️ Ligação comercial × ramal físico continua pendência que **não bloqueia** o início.

---

## 6. Projeção espacial

A parada **pode** ter uma **projeção espacial do impacto** — área derivada dos elementos afetados ou desenhada pelo operador. A geometria é de **Redes/GIS**; a Parada a **referencia**, versionada, como parte do snapshot de impacto.

---

## 7. Giswater — o que o *mincut* faz

Fontes oficiais do projeto Giswater, lidas no repositório público ([API](https://github.com/Giswater/api), commit de 28/09/2026; [protocolo P16 — mincut basics](https://github.com/Giswater/docs)); a documentação renderizada estava **bloqueada** pela política de rede desta sessão.

| Aspecto | O que a fonte oficial mostra |
| ------- | ---------------------------- |
| **O que calcula** | A partir de um arco ou de um ponto, as **válvulas a fechar** e os **elementos afetados**: arcos, nós, ligações (*connecs*), hidrômetros e a extensão geográfica |
| **Classificação de válvulas** | Propostas · **inacessíveis** · com mudança de estado · **não propostas / não operar** |
| **Estados do *mincut*** | `0 Planified` · `1 In Progress` · `2 Finished` · `3 Canceled` · `4 On Planning` · `5 Conflict` |
| **Causa · tipo** | Causa `Accidental` × `Planified`; tipo `Demo` · `Test` · `Real` |
| **Tempos** | Previsão (`forecast_start`, `forecast_end`) × execução (`exec_start`, `exec_end`, usuário e descrição da execução) |
| **Operações** | Criar (por arco **ou** coordenada), atualizar, iniciar, encerrar, cancelar, excluir; marcar válvula inacessível; alternar estado de válvula; hidrômetros afetados consultáveis por *mincut* |
| **Pré-requisitos** | Extensão pgRouting; entradas de água por exploração; tipos de válvula configurados; válvulas de retenção opcionais; topologia íntegra (nó inicial e final em todo trecho); válvulas sem valores nulos de "fechada" e "quebrada"; só elementos operativos; exploração macro para redes interligadas |

**[DEC] Conclusão**: o *mincut* tem **ciclo de vida próprio** — e é exatamente por isso que ele **não** pode ser o ciclo da parada:

1. O estado do *mincut* é **estado da análise**; o estado da Parada é **estado do fato operacional**.
2. A Parada referencia **uma ou mais** análises (recálculos, alternativas), cada uma com snapshot e versão.
3. Se a instalação usar o ciclo do *mincut* (iniciar, encerrar, cancelar), o adaptador o **comanda a partir da Parada** — nunca o inverso. Sem decisão explícita, **nada é copiado nem sincronizado** ([`gis-redes-ativos.md §7`](../arquitetura/gis-redes-ativos.md)).
4. O estado *Conflict* é **insumo** para a detecção de paradas sobrepostas (§4, *em análise*), não decisão.
5. Sem Giswater, o impacto é **declarado** (§5) — a Parada continua completa.

---

## 8. Manobras e válvulas

A manobra — fechar e reabrir válvulas — é **execução**: **OS** do Atendimento e Execução, sobre ativos com identidade (Gestão de Ativos) e papel na topologia (Redes/GIS). [INF] Uma válvula **inacessível** ou **quebrada** revelada pela análise ou pela manobra gera **necessidade de manutenção** no [PCM](pcm.md).

---

## 9. Ownership

| Responsabilidade | Dono |
| ---------------- | ---- |
| **Parada** — identidade, tipo, estado, previsão, realizado, histórico | **Gestão Operacional** |
| Necessidade de manutenção e sua programação | **Gestão de Ativos / PCM** |
| Execução — manobra, reparo, normalização | **Atendimento e Execução** (OS) |
| Topologia e geometria | **Redes/GIS** |
| Cálculo do impacto | **Giswater**, quando usado — ferramenta especializada, sem posse |
| Canais de comunicação | **Notificação** |
| Métricas e painéis | **Gerencial & Analytics** — consome |

---

## 10. Fluxo — parada programada

```text
PCM: manutenção exige indisponibilidade
        ↓ solicita janela
Gestão Operacional: cria a Parada (Proposta)
        ↓
Redes/GIS: calcula o impacto (ou a operação o declara)      → Em análise
        ↓
Operação analisa: conflitos, clientes críticos, alternativas
        ↓
Aprovação                                                   → Planejada
        ↓
PCM programa a OS na janela aprovada
        ↓
Comunicação prévia — regulador e usuários (antecedência = parâmetro regulado)
        ↓
Execução: manobra e serviço (OS)                            → Ativa
        ↓
Normalização                                                → Em normalização
        ↓
Encerramento: realizado registrado                          → Encerrada
```

## 11. Fluxo — parada emergencial

```text
falha ou incidente ──► Parada emergencial (Ativa) ──► impacto (calculado ou declarado)
        ──► OS ──► comunicação ──► reparo ──► normalização ──► Encerrada
```

Sem planejamento prévio. A necessidade corretiva do PCM **pode** nascer depois, a partir do resultado da OS.

---

## 12. Comunicação

**Eventos de negócio da Parada**: planejada (aviso prévio) · iniciada · previsão revisada · normalizada · cancelada. Destinatários: usuários afetados, clientes críticos, **regulador** (NR ANA 11/2024: interrupção programada comunicada previamente ao regulador e aos usuários; antecedência definida pelo regulador — **parâmetro regulado**). O canal — SMS, e-mail, portal, aplicativo — é da **Notificação**; nenhum fornecedor entra no domínio ([completude §8](../auditoria/completude-funcional-regulatoria.md#8-comunicação-ao-usuário--evento-de-negócio--canal)).

---

## 13. Mapa de paradas — interface conceitual

```text
MAPA DE PARADAS
● planejadas   ● ativas   ● em normalização   ● encerradas

Filtros: período · sistema · motivo · status · tipo · região
```

[DEC] Segue a [ADR-0007](../decisoes/0007-arquitetura-de-interface.md): página server-driven com o mapa como **ilha** interativa; geometria servida pela capacidade GIS; **nada de SPA**. O mapa respeita o escopo territorial do usuário.

## 14. Detalhe da parada

Mapa · linha do tempo (proposta → planejada → ativa → em normalização → encerrada, com cada previsão revisada) · **previsão × realizado** · ativos envolvidos · OS · manobras · área afetada · unidades usuárias afetadas · comunicações enviadas · responsável · restabelecimento.

---

## 15. Cenários

**CEN-PAR-001** — parada programada com impacto registrado, comunicação prévia e normalização · **CEN-PAR-002** — parada emergencial até a normalização ([`testes/cenarios/pcm-paradas.md`](../testes/cenarios/pcm-paradas.md)). Requisitos nativos, oráculo N.

## 16. Pendências

| # | Pendência |
| - | --------- |
| 1 | Projeção da Parada sobre a **programação** por área que o Atendimento consulta — preservando a equivalência de CEN-OPE-002 (C1) |
| 2 | Catálogo de motivos e sua relação com as anormalidades e ocorrências do legado |
| 3 | Antecedência e conteúdo da comunicação por regulador — parâmetro regulado |
| 4 | Critérios de "cliente crítico" — por companhia |
| 5 | Protocolo de integração com o Giswater — adaptador de Redes/GIS; nada decidido |
| 6 | Relação entre plano de racionamento e paradas que ele gera |
