# Mapa do Fiscal — Documento Fiscal de Água e Saneamento (NFAg)

> **Procedência**: criado na [auditoria final da Fase 0](../auditoria/auditoria-final-fase0.md) (2026-09-29), `HEAD = 9993ac1`. Diferente dos outros mapas, **não descreve comportamento do GSAN**: descreve uma **obrigação vigente** e a fronteira que o OpenGSAN precisa ter para cumpri-la. Fontes consultadas em **2026-09-29**, na ordem de hierarquia do projeto; ⚠️ os portais oficiais (Portal NFAg/SVRS, Planalto, gov.br) estavam **bloqueados pela política de rede da sessão** e foram lidos por resumos de busca sobre as páginas oficiais — ver §12.
>
> ⚠️ **Não implementa, não modela e não escolhe biblioteca, certificado, fornecedor ou leiaute.** Onde a regra depende de norma que não foi possível confirmar, está marcado `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` — nunca preenchido por suposição.

---

## 1. Por que este mapa existe

🔴 **A NFAg não é futuro hipotético.** O catálogo tratava o fiscal como `EXIGE APROFUNDAMENTO`, H2, porque a única evidência era um schema sem código. A pergunta estava errada: **obrigação regulatória não se descobre no legado**.

| Fato | Fonte | Certeza |
| ---- | ----- | ------- |
| A **NFAg — Nota Fiscal de Água e Saneamento Eletrônica, modelo 75** — é documento fiscal eletrônico nacional dos prestadores de água e esgoto, com validade dada pela **assinatura digital do emitente** e autorização em ambiente do Fisco | Portal NFAg (SVRS); LC 214/2025 | 🟢 Alta |
| Substitui a sistemática atual de emissão das notas/contas de água e saneamento, com campos de **IBS/CBS** e classificação tributária | Portal NFAg; manuais (MOC) | 🟢 Alta |
| Documentação técnica aprovada: **MOC Anexo I v1.00l** (leiaute e regras de validação) e **Anexo II v1.02** (DANFAG), pelo **Ato Técnico Conjunto nº 2/2026** (24/08/2026) | Resumo de fonte especializada | 🟡 Média — confirmar no Portal NFAg |
| Cronograma dos documentos fiscais da reforma: **Ato Conjunto RFB/CGIBS nº 4, de 30/07/2026** | Receita Federal; CGIBS | 🟢 Alta |
| **Data de obrigatoriedade da NFAg** | O resumo da notícia oficial indica data a fixar em documento técnico ou ato conjunto; fontes especializadas registram **01/12/2026** (janela de 03/08 a 01/12/2026); imprensa registrou adiamento em relação a agosto | ⚠️ **VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA** |

🔵 **A conclusão arquitetural não depende do dia exato**: a obrigação existe, tem leiaute aprovado e começa **antes** de qualquer instalação do OpenGSAN operar. É **capacidade regulatória necessária** — não é H2, não é opcional e não pode ser acoplada depois ao Faturamento.

---

## 2. O que o GSAN tem — e por que não serve de oráculo

| Evidência | O que é | Consequência |
| --------- | ------- | ------------ |
| Schema `fiscal` (14 tabelas: nota fiscal, certificado, armazenamento) | 🟢 **Customização** da instalação de referência `gsan_comercial`; **nenhuma classe Java** nesta branch; **nenhuma migration** no `gsan-migracoes` (busca por `create table fiscal.`/`create schema fiscal`, sem distinção de caixa) | Comportamento **não observável**. Não é oráculo |
| `conta_impostos_deduzidos` | 🟢 Retenção de tributos federais na conta (CEN-FAT-005) | **Continua no Faturamento**, oráculo 1. ⚠️ A convivência com IBS/CBS na transição é `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |
| Telas de "nota fiscal" de hidrômetro | Nota fiscal de **aquisição** do equipamento | ⚠️ Não é documento fiscal de serviço (catálogo §22) |

🔴 **Resultado**: o Fiscal é **requisito nativo do OpenGSAN** — testado por especificação própria (oráculo **N**, [`estrategia-testes.md`](../testes/estrategia-testes.md)), nunca por equivalência com o legado.

---

## 3. Conta ≠ NFAg

```text
Faturamento
   ↓  calcula e emite
Conta (documento comercial: consumo, tarifa, valores, vencimento, linhagem)
   ↓  publica
fato tributável  ("documento comercial X, versão V, itens e valores, emitido em T")
   ↓  consome
Fiscal
   ↓  determina tributação vigente, numera, assina, transmite
NFAg (documento fiscal: chave, série, número, protocolo, eventos)
```

| | **Conta** | **NFAg** |
| - | --------- | -------- |
| Pergunta | *Quanto o usuário deve, por quê e até quando?* | *Qual operação tributável ocorreu, com que tributos, reconhecida pelo Fisco?* |
| Identidade | Identidade documental estável + versões + linhagem (C2) | **Chave de acesso** + série + número + protocolo de autorização |
| Quem define as regras | Estrutura tarifária, regulador, política comercial | Legislação tributária e leiaute oficial |
| Ciclo | Emitida → retificada/cancelada/paga/prescrita | Gerada → autorizada/rejeitada → eventos (cancelamento, substituição…) |
| Dono | **Faturamento** | **Fiscal** |

🔴 **Regra**: *Conta ≠ NFAg*. Uma não é atributo da outra; a relação entre elas é um **vínculo rastreável** (qual versão da conta originou qual documento fiscal), não uma fusão de identidades. ⚠️ O **documento entregue** ao usuário tende a ser o **DANFAG**, que carrega dados comerciais (medição, qualidade da água, meios de pagamento — MOC Anexo II): isso é composição da **emissão**, não fusão dos conceitos. Se o DANFAG substitui integralmente a conta impressa: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA`.

---

## 4. Ownership

| Dono | Responde por | ⚠️ Não é dono de |
| ---- | ------------ | ---------------- |
| **Faturamento** | Cálculo · consumo faturado · tarifa · documento comercial · valores · linhagem da conta · retenções federais legadas (CEN-FAT-005) | Regra tributária, numeração fiscal, autorização |
| **Fiscal** | Documento fiscal · identidade fiscal (chave, série, número) · **determinação tributária vigente** (classificação, base, alíquotas, reduções — como política com vigência) · autorização e rejeição · **eventos** · cancelamento fiscal · contingência · DANFAG · guarda fiscal · devolução personalizada (§8) | Valor tarifário, consumo, recebimento |
| **Arrecadação** | Pagamento, recebimento, conciliação — e os **fatos de pagamento** que a vinculação pagamento–documento fiscal possa exigir (§7) | O documento fiscal |
| **Contabilização** | Lançamentos a partir de fatos comerciais **e** fiscais, sem duplicar valores (§9) | Documento fiscal; apuração |
| **Integrações** | **Adapter técnico** com o ambiente autorizador (SVRS): transporte, assinatura de mensagem, uso do certificado, retentativa, idempotência, erro durável | 🔴 **A regra fiscal** — o adapter traduz e entrega; quem decide é o Fiscal |

🔴 **Não acoplar a regra fiscal ao Faturamento.** O Faturamento **pergunta** ao Fiscal a tributação vigente para compor o documento (§8) e **publica** o fato tributável; o Fiscal traduz para a obrigação vigente. Assim, mudança de leiaute, de alíquota, de classificação, de validação ou de evento **não toca o motor tarifário**.

---

## 5. Ciclo mínimo

```text
Conta emitida (versão V)
      ↓
Gerar NFAg ─── determinação tributária vigente + dados do documento comercial
      ↓
Assinar (certificado digital do emitente)
      ↓
Transmitir ao ambiente autorizador
      ↓
Autorizada? ──── não ──→ REJEIÇÃO: motivo registrado · conta não fica "sem fiscal" em silêncio
   │                        ↓
   sim                   correção (dado comercial → Faturamento; dado fiscal → Fiscal) → nova transmissão
   ↓
armazenar documento autorizado + protocolo
   ↓
DANFAG (representação para entrega)
   ↓
eventos posteriores ── cancelamento · substituição · faturamento conjunto · vinculação de pagamento
```

| Elemento | Situação | Fonte |
| -------- | -------- | ----- |
| Emissão, assinatura, autorização, rejeição | 🟢 Confirmado | Portal NFAg |
| Recepção **síncrona** (transmissão e autorização na mesma conexão) | 🟡 Fonte secundária | Confirmar no MOC |
| **Cancelamento** | 🟢 Confirmado como evento; ⚠️ **prazo e condições**: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` | MOC Visão Geral v1.00l (resumo) |
| **Substituição** — evento "NFAg Substituição Autorizada" registrado na NFAg original, que passa a "substituída" | 🟡 Fonte secundária | Confirmar no MOC |
| **Faturamento conjunto / por terceiros** (`tpFat = 3`) com eventos automáticos de marcação registrados pelo próprio Fisco | 🟡 Fonte secundária | Confirmar no MOC |
| **Vinculação de pagamento ao DF-e** (NT 2026.001, evento 110300, produção em 04/05/2026) | ⚠️ **Aplicabilidade à NFAg**: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` | Portal NF-e (NT 2026.001) |

⚠️ **Nenhum evento além dos listados foi assumido.** A lista completa é a do MOC vigente, lida na implementação.

---

## 6. Contingência e guarda

### 6.1 Contingência

🟢 A documentação prevê **emissão em contingência offline** quando há falha técnica, com transmissão posterior e o destaque *"EMITIDA EM CONTINGÊNCIA"* no documento auxiliar.

🔵 **O OpenGSAN precisa suportar conceitualmente**: emissão normal · emissão em contingência · **transmissão posterior** · **reconciliação** (todo documento emitido em contingência termina autorizado ou tratado — nenhum fica em estado indefinido).

🔴 **Ponto crítico para o saneamento**: o GSAN tem **leitura com impressão simultânea** em campo (catálogo §8.2) — a conta é impressa no imóvel, frequentemente sem conectividade. Onde o documento fiscal é gerado e assinado nesse caso, e se a contingência offline é o caminho previsto para ele: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA`. É a pendência fiscal de **maior impacto arquitetural** (toca Campo, Integrações e identidade de dispositivo).

### 6.2 Guarda fiscal

| Guardar | Observação |
| ------- | ---------- |
| Documento autorizado (XML) + protocolo | Imutável; integridade verificável |
| Eventos e seus protocolos | Com o documento a que se referem |
| DANFAG | 🔵 Representação **regenerável** do documento autorizado — ⚠️ confirmar se há obrigação de guardar a representação |
| Prazo de retenção | `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |

🔴 **Documento fiscal ≠ artefato de relatório.** O artefato de relatório (D-03) é regenerável, pertence ao solicitante e tem retenção operacional; o documento fiscal é **prova legal**, imutável, com prazo legal de guarda e acesso controlado. Ambos são instâncias do padrão T4 (*documento eletrônico com guarda*) — ver [Gestão de documentos e evidências](../auditoria/completude-funcional-regulatoria.md#6-documentos-e-evidências) —, mas **não compartilham política**.

---

## 7. Fronteiras com o que já existe

### 7.1 NFAg × retificação e cancelamento da conta

🟢 **O que o OpenGSAN já tem** (C2): a retificação cria **nova versão** do documento comercial com linhagem; o cancelamento e a prescrição são situações do documento; o pagamento já vinculado **não migra** para a retificadora (CEN-ARR-005).

| Pergunta | Resposta |
| -------- | -------- |
| Identidades comercial e fiscal permanecem separadas? | 🟢 **Sim, por decisão** (§3) — o vínculo é *versão da conta ↔ documento fiscal* |
| Retificar a conta gera novo documento fiscal? | ⚠️ `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` — o leiaute prevê **substituição**; se a retificação de valor ou de consumo exige substituição, cancelamento seguido de nova emissão ou outro instrumento, e em que prazo, depende da norma |
| Cancelar a conta exige evento fiscal? | ⚠️ `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` — e o caso de cancelamento **fora do prazo** fiscal é pendência própria |
| Prescrição tem efeito fiscal? | ⚠️ `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |

🔵 **O desenho que independe da resposta**: o Faturamento publica o fato *"versão V substituída por V′, motivo M"* ou *"documento cancelado, motivo M"*; o Fiscal decide, **pela regra vigente**, a ação fiscal. A regra muda sem tocar a retificação — e a retificação continua passando pela Micromedição (D-14).

### 7.2 NFAg × Arrecadação

🔴 **Documento emitido ≠ pagamento.** A NFAg representa o fato fiscal; receber, classificar, aplicar e conciliar continuam na Arrecadação. A **única** ponte nova é a **vinculação pagamento–documento fiscal** do *split payment*: a Arrecadação fornece o fato de pagamento; o evento de vinculação, se aplicável à NFAg, pertence ao Fiscal; o PSP e o banco são integrações. Quem informa a chave ao meio de pagamento: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA`.

### 7.3 Fatura do cliente responsável

🟢 A "Fatura" do GSAN é **documento agregador de cobrança** de várias contas de um cliente responsável (ver [glossário](../dominio/glossario.md) e CEN-ARR-011). Se o documento fiscal é por conta, por unidade usuária ou pode acompanhar o agregador: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA`.

---

## 8. Determinação tributária e devolução personalizada

| Capacidade | Dono | Situação |
| ---------- | ---- | -------- |
| **Determinação tributária** — classificação, base, alíquotas, reduções, **com vigência** | **Fiscal** (política versionada) | 🔴 Afeta o **valor** do documento que o Faturamento compõe. Se a tarifa homologada é líquida ou bruta de IBS/CBS e como o regulador trata a neutralidade na transição: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` + regulador |
| **Devolução personalizada (cashback) de IBS/CBS** — para água e esgoto, concedida **no momento da cobrança** a família de baixa renda inscrita no CadÚnico (LC 214/2025) | **Fiscal** decide; o Faturamento **apresenta** a linha no documento | 🔴 **Omissão nova da Fase 0** — altera o valor cobrado. Início (CBS a partir de 2027; IBS depois), percentuais (fontes secundárias divergem), origem da elegibilidade e mecânica: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |

⚠️ **Não confundir** com a Tarifa Social: ambas usam o CadÚnico, mas a **tarifa social é benefício tarifário** (regulação do saneamento, dono Faturamento) e o **cashback é devolução de tributo** (legislação tributária, dono Fiscal). Compartilham **fonte de elegibilidade**, não regra nem dono. Ver [completude §4](../auditoria/completude-funcional-regulatoria.md#4-tarifa-social-e-benefício-tarifário).

---

## 9. Fiscal × Contabilização

```text
Faturamento ── fato comercial (receita, contas a receber) ──┐
Fiscal ─────── fato fiscal (tributos destacados, devolução) ─┼──► Contabilização ──► ERP (adaptador)
Arrecadação ── fato financeiro (recebimento) ───────────────┘
```

🔴 **Cada valor tem uma única origem.** O documento fiscal **não cria receita nova**: a receita vem do fato comercial; o tributo destacado, do fato fiscal; o recebimento, da Arrecadação. A Contabilização consome **os três** e nunca soma o mesmo valor duas vezes. A parametrização contábil (C2) ganha **origens fiscais** — sem mudar o princípio de lançamento por competência × localidade × origem ([`financeiro-contabilizacao.md`](financeiro-contabilizacao.md)).

---

## 10. Documento fiscal · obrigações acessórias · contabilização · apuração

| Classe | O que é | Para o OpenGSAN | Classificação |
| ------ | ------- | --------------- | ------------- |
| **Documento fiscal** | NFAg | Núcleo — módulo **Fiscal** | **L2 — capacidade nova necessária** |
| **Obrigações acessórias** | SPED do legado (`integracao.sped_documento`, `sp1_gerar_integracao_sped` — customização implementada no banco) | Obrigações da **pessoa jurídica**, cumpridas pela contabilidade/ERP; o OpenGSAN **fornece dados** por adaptador. ⚠️ Não assumir que o "SPED" do banco é a arquitetura futura | **L4 — integração** |
| | **DeRE** (Declaração de Regimes Específicos) | Prevista para instituições financeiras, planos de saúde, concursos de prognósticos, consórcios, seguros e previdência — **não para saneamento** | **L6 — não aplicável** |
| **Contabilização** | Lançamentos a partir de fatos | Já no escopo (Etapa 7); ganha fatos fiscais | **L1 — corrigido** (§9) |
| **Apuração** de IBS/CBS | Apuração pelo contribuinte, assistida pelo Fisco a partir dos documentos fiscais | Fora do OpenGSAN — o que ele entrega é o **documento fiscal** | **L6 — fora do sistema** |

---

## 11. Posição na ordem e cenários

| Etapa | O que entra | Gate |
| ----- | ----------- | ---- |
| **4 — Financeiro individual** | Fato tributável · determinação tributária como política · **NFAg individual** (gerar, assinar, transmitir, autorizar/rejeitar, DANFAG) contra ambiente de **homologação** | **4 → 5**: conta emitida produz documento fiscal autorizado **ou** rejeição rastreável — CEN-FIS-001 |
| **7 — Escala** | NFAg **em lote** · contingência · eventos · guarda · reconciliação fiscal | **7 → operação**: nenhuma conta sem documento fiscal autorizado ou em contingência registrada; retificação e cancelamento com o tratamento fiscal vigente — CEN-FIS-002, CEN-FIS-003 |

🔵 Mesma regra do motor de conta: **individual na Etapa 4, lote na 7** — a operação vem antes do orquestrador. Detalhe em [`dependencias-e-ordem-implementacao.md §20.3`](dependencias-e-ordem-implementacao.md).

**Cenários** (requisito nativo, oráculo N): [CEN-FIS-001 a 003](../testes/cenarios/fiscal.md).

---

## 12. Pendências — `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA`

| # | Pendência | Bloqueia | Até quando |
| - | --------- | -------- | ---------- |
| 1 | Data de obrigatoriedade e alcance (inclusive prestador público/autarquia) | Nada no desenho | Antes do plano de implantação |
| 2 | Regra fiscal da **retificação**, do **cancelamento** (prazos) e da **prescrição** | CEN-FIS-003 (resultado esperado) | Antes do gate 7 → operação |
| 3 | **Emissão em campo** (impressão simultânea) × contingência | Desenho do Campo e da identidade de dispositivo | Antes da Etapa 3 fechar o contrato de coleta com impressão |
| 4 | Cardinalidade: documento fiscal por conta, por unidade usuária, por agregador | Vínculo conta ↔ NFAg | Antes da Etapa 4 |
| 5 | Tarifa bruta × líquida de IBS/CBS; neutralidade na transição | Composição do valor | Antes da Etapa 4 |
| 6 | Devolução personalizada: início, percentuais, origem da elegibilidade, mecânica | Linha de devolução no documento | Antes de 2027 |
| 7 | Vinculação pagamento–documento fiscal aplicável à NFAg | Ponte Arrecadação ↔ Fiscal | Antes da Etapa 5 |
| 8 | Prazo e forma de guarda | Política de retenção | Antes do gate 7 → operação |
| 9 | Convivência das retenções federais legadas com IBS/CBS | CEN-FAT-005 na transição | Antes da Etapa 4 |
| 10 | Lista completa de eventos e rejeições no MOC vigente | Catálogo de eventos | Na implementação |

**Fontes** (consultadas em 2026-09-29):

- [Portal da NFAg — SVRS](https://dfe-portal.svrs.rs.gov.br/Nfag) (⚠️ bloqueado nesta sessão; lido por resumo de busca)
- [Receita Federal — cronograma dos documentos fiscais eletrônicos (Ato Conjunto RFB/CGIBS nº 4/2026)](https://www.gov.br/receitafederal/pt-br/assuntos/noticias/2026/julho/receita-federal-e-comite-gestor-do-ibs-publicam-o-cronograma-de-implementacao-dos-documentos-fiscais-eletronicos-da-reforma-tributaria-do-consumo) · [CGIBS — mesma publicação](https://cgibs.gov.br/receita-federal-e-comite-gestor-do-ibs-publicam-o-cronograma-de-implementacao-dos-documentos-fiscais-eletronicos)
- [Portal NF-e — NT 2026.001, vinculação com o pagamento](https://www.nfe.fazenda.gov.br/portal/exibirArquivo.aspx?conteudo=k7zG06n5M6I%3D)
- [Receita Federal — Comunicado Conjunto (DeRE)](https://www.gov.br/receitafederal/pt-br/assuntos/noticias/2025/dezembro/comunicado-conjunto)
- [LC 214/2025 — Planalto](https://www.planalto.gov.br/ccivil_03/leis/lcp/lcp214.htm) (⚠️ bloqueado; devolução personalizada lida em [transcrição da LC](https://modeloinicial.com.br/lei/LCP-214-2025/devolucao-personalizada-ibs-da-cbs-cashback-@__I_III_I))
- Fontes secundárias, **só para localizar termos**: [reformatributaria.com — manuais da NFAg](https://www.reformatributaria.com/documentos-fiscais/nfag-manuais-detalham-regras-do-ibs-cbs-cancelamento-em-faturamento-conjunto-e-documento-auxiliar) · [Agência iNFRA — adiamento](https://agenciainfra.com/blog/saneamento-emissao-obrigatoria-de-nota-fiscal-sera-adiada-diz-receita/) · [Felsberg — cronograma](https://www.felsberg.com.br/cronograma-documentos-fiscais-ibs-cbs-2026)
