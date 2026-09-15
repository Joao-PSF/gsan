# Catálogo de Funcionalidades Futuras do OpenGSAN

> **Procedência**: consolida o que já foi documentado nos [dez mapas funcionais](README.md), no [inventário do banco](../banco/estrutura-atual.md) e no [inventário de integrações](../integracoes/integracoes-identificadas.md), com **verificação dirigida no código** apenas onde era preciso distinguir *capacidade com fluxo* de *tabela sem fluxo*. Base: `HEAD = 73577c4`. Níveis de certeza em [`procedencia.md`](../procedencia.md).
>
> ⚠️ **Não implementa, não modela e não prioriza por data.** Nenhuma tabela, schema, migration ou escolha de ferramenta. Nenhuma funcionalidade entra no núcleo por este documento.

---

## 1. Objetivo

Responder, para cada capacidade que **instalações reais do GSAN desenvolveram** além da base pública:

> Que problema de negócio resolve? · É genérica para saneamento ou específica de uma companhia? · Pertence ao núcleo futuro do OpenGSAN ou deve ser extensão? · De que módulos depende? · Qual sua importância relativa?

🔴 **A pergunta que este catálogo NÃO responde**: *"o que vamos implementar agora?"*. Ele responde: *"que capacidades o ecossistema GSAN já demonstrou precisar, e quais fazem sentido para o OpenGSAN?"*

---

## 2. Critérios

### 2.1 🔴 A regra fundamental

```text
EXISTE NO gsan_comercial   ≠   DEVE EXISTIR NO OpenGSAN
```

Toda funcionalidade encontrada passa por análise. Pode ser universal, comum-mas-opcional, específica de companhia, integração externa, solução temporária ou dívida técnica.

### 2.2 Natureza

| Classificação | Significado |
| ------------- | ----------- |
| **CORE FUTURO** | Suficientemente geral para saneamento; provavelmente deve fazer parte do OpenGSAN |
| **MÓDULO OPCIONAL** | Útil para várias companhias, mas não necessário ao núcleo |
| **INTEGRAÇÃO** | Depende principalmente de sistema ou serviço externo |
| **EXTENSÃO DE COMPANHIA** | Necessidade específica que **não deve contaminar o núcleo** |
| **EXIGE APROFUNDAMENTO** | Evidência insuficiente |

⚠️ **`CORE FUTURO` não se atribui porque algo existe numa instalação.**

### 2.3 Maturidade da evidência

| Nível | Critério |
| ----- | -------- |
| **COMPROVADA** | Fluxo e finalidade identificados (código + estrutura + relação) |
| **PARCIALMENTE COMPREENDIDA** | Função geral identificada; detalhes incompletos |
| **APENAS EVIDÊNCIA** | ⚠️ Existem objetos relacionados, **mas não há segurança sobre o comportamento** |

🔴 **"Tem tabela" não é prova suficiente.** Onde só havia nome de estrutura, a maturidade é `APENAS EVIDÊNCIA` — e isso mudou a classificação de duas famílias (fiscal e SPED).

### 2.4 Horizonte preliminar

| Horizonte | Significado |
| --------- | ----------- |
| **H1** | Complementa diretamente o sistema comercial moderno |
| **H2** | Evolução relevante após o núcleo estável |
| **H3** | Expansão estratégica de médio/longo prazo |
| **ESPECÍFICA** | Não entra no roadmap geral |

⚠️ Horizonte **não é ordem de implementação** — isso é a próxima atividade.

### 2.5 🔴 Funcionalidade ≠ implementação encontrada

Para cada item relevante, o documento separa:

```text
FUNCIONALIDADE           "receber pagamento instantâneo de uma conta"
IMPLEMENTAÇÃO ENCONTRADA "classe que monta string de QR Code estático + duas tabelas"
```

⚠️ **A implementação encontrada não é o desenho do OpenGSAN.**

### 2.6 O que ficou de fora

🔴 **Mecanismo técnico não é funcionalidade de negócio.** OAuth2, REST, containers, banco, observabilidade, cache e mensageria **não entram neste catálogo** — são decisões de arquitetura, tratadas em outro lugar.

Também não entram: tabelas isoladas, campos isolados, customizações sem fluxo funcional, e nomes de estrutura sem evidência suficiente.

---

## 3. Visão geral

**26 capacidades** catalogadas. Distribuição:

| Natureza | Qtd | Leitura |
| -------- | --: | ------- |
| **CORE FUTURO** | 11 | Genéricas para saneamento; complementam o núcleo comercial |
| **MÓDULO OPCIONAL** | 7 | Úteis a várias companhias, dispensáveis ao núcleo |
| **INTEGRAÇÃO** | 5 | Dependem de sistema ou serviço externo |
| **EXIGE APROFUNDAMENTO** | 2 | ⚠️ Fiscal e SPED — a natureza **não pode ser atribuída** sem conhecer o comportamento |
| **EXTENSÃO DE COMPANHIA** | 1 | ⚠️ **Não deve contaminar o núcleo** |

| Maturidade | Qtd |
| ---------- | --: |
| **COMPROVADA** | 11 |
| **PARCIALMENTE COMPREENDIDA** | 10 |
| **APENAS EVIDÊNCIA** | 5 |

| Horizonte | Qtd |
| --------- | --: |
| **H1** — próximo do núcleo | 9 |
| **H2** — evolução importante | 11 |
| **H3** — plataforma ampliada | 5 |
| **ESPECÍFICA** | 1 |

⚠️ **Os totais acima foram conferidos por script contra a tabela do §4** — não são estimativas de leitura. Cada eixo soma 26. As oito especificidades de companhia do §21 **não entram nesta contagem**: são *instâncias* de capacidades genéricas já catalogadas, não capacidades adicionais.

🔵 **Três leituras do conjunto:**

1. **O canal digital com o cliente é a maior lacuna do GSAN público.** O portal de autoatendimento (47 classes) é a capacidade mais substancial encontrada e a menos documentada até agora — nenhum mapa funcional a cobriu, porque nenhum módulo é seu dono.
2. **O fiscal é o maior desconhecido.** Existe um schema inteiro e uma integração de obrigação acessória, mas **sem nenhuma classe Java correspondente nesta branch** — é a maior área com evidência estrutural e comportamento desconhecido.
3. **Pagamento digital é o item mais urgente e o menos pronto.** PIX é hoje meio de pagamento dominante no Brasil, e o que existe no legado é uma classe utilitária com chave de teste em código.

---

## 4. Catálogo consolidado

| # | Funcionalidade | Problema resolvido | Área dona | Natureza | Maturidade | Horiz. |
| - | -------------- | ------------------ | --------- | -------- | ---------- | ------ |
| 01 | **Pagamento instantâneo (PIX)** | Receber conta por meio dominante no país, com confirmação imediata | Arrecadação + Integrações | **CORE FUTURO** | Parcial | **H1** |
| 02 | **Cobrança bancária registrada (boleto)** | Emitir cobrança registrada no banco, com baixa automática e rastreio | Faturamento + Arrecadação | **CORE FUTURO** | Comprovada | **H1** |
| 03 | **Pagamento por cartão** | Aceitar débito/crédito, inclusive parcelando negociação | Arrecadação + Cobrança | MÓDULO OPCIONAL | Parcial | H2 |
| 04 | **Portal de autoatendimento** | Cliente resolve sozinho: 2ª via, extrato, parcelamento, certidão, solicitação | ⚠️ **Sem dono hoje** — candidato a capacidade própria | **CORE FUTURO** | Comprovada | **H1** |
| 05 | **Identidade do cliente (login externo)** | Autenticar o cliente final, distinto do usuário interno | Segurança (identidade externa) | **CORE FUTURO** | Parcial | **H1** |
| 06 | **Notificação ao cliente** | Avisar vencimento, corte, confirmação — por e-mail e SMS | Plataforma | **CORE FUTURO** | Comprovada | **H1** |
| 07 | **Acessibilidade da conta (braile)** | Atender cliente com deficiência visual | Faturamento (emissão) | MÓDULO OPCIONAL | Comprovada | H2 |
| 08 | **Documento fiscal eletrônico** | Emitir nota fiscal do serviço prestado | ⚠️ **Candidato a módulo Fiscal** | ⚠️ **EXIGE APROFUNDAMENTO** | ⚠️ **Apenas evidência** | H2 |
| 09 | **Obrigação acessória fiscal (SPED)** | Entregar escrituração digital ao fisco | Fiscal | ⚠️ **EXIGE APROFUNDAMENTO** | ⚠️ **Apenas evidência** | H2 |
| 10 | **Integração contábil** | Gerar lançamentos contábeis a partir do movimento comercial | Financeiro/Integrações | MÓDULO OPCIONAL | ⚠️ **Apenas evidência** | H2 |
| 11 | **Benefício social tarifário** | Conceder tarifa reduzida por critério socioeconômico | Cadastro + Faturamento | **CORE FUTURO** | Parcial | **H1** |
| 12 | **Programas de subsídio nomeados** | Programa institucional específico de uma companhia/governo | Extensão sobre (11) | **EXTENSÃO DE COMPANHIA** | Parcial | ESPECÍFICA |
| 13 | **Campanha de recadastramento** | Atualizar cadastro em massa, com coleta em campo e validação | Cadastro + Campo | **CORE FUTURO** | Comprovada | H2 |
| 14 | **Coleta móvel de leitura** | Ler, criticar e transmitir do campo; releitura | Micromedição + Integrações | **CORE FUTURO** | Comprovada | **H1** |
| 15 | **Execução móvel de OS** | Receber, executar e encerrar ordem de serviço em campo | Atendimento + Integrações | **CORE FUTURO** | Comprovada | **H1** |
| 16 | **Evidência de campo (fotos/anexos)** | Comprovar o que foi encontrado e executado | ⚠️ **Capacidade transversal** | **CORE FUTURO** | Parcial | H2 |
| 17 | **Telemetria / leitura remota** | Medir sem visita, em frequência maior | Micromedição + Integrações | MÓDULO OPCIONAL | Parcial | H2 |
| 18 | **Correção de medição por idade do medidor** | Compensar submedição de hidrômetro envelhecido | Micromedição | MÓDULO OPCIONAL | ⚠️ Apenas evidência | H3 |
| 19 | **Gestão de contrato de empresa de campo** | Medir e pagar serviço de terceiro por produção | Atendimento/Operacional | MÓDULO OPCIONAL | Parcial | H3 |
| 20 | **Bureau de crédito** | Negativar e reabilitar devedor | Cobrança + Integrações | **INTEGRAÇÃO** | Comprovada | H2 |
| 21 | **Cobrança terceirizada por resultado** | Entregar carteira a empresa e remunerar por recuperação | Cobrança | MÓDULO OPCIONAL | Comprovada | H2 |
| 22 | **Prestação de contas regulatória** | Responder à agência reguladora sobre atendimento | Atendimento | **INTEGRAÇÃO** | Parcial | H2 |
| 23 | **Análise gerencial (BI)** | Acompanhar indicadores sem onerar o transacional | ⚠️ **Candidato a capacidade Analytics** | **INTEGRAÇÃO** | Parcial | H3 |
| 24 | **Georreferenciamento (GIS)** | Localizar imóveis e ocorrências no território | Integrações — ⚠️ **hoje só integração** | **INTEGRAÇÃO** | Comprovada | H3 |
| 25 | **Armazenamento de documentos** | Guardar arquivos fora do banco transacional | Plataforma | **INTEGRAÇÃO** | ⚠️ Apenas evidência | H3 |
| 26 | **APIs para terceiros e dispositivos** | Permitir que outros sistemas consultem e operem | Integrações | **CORE FUTURO** | Comprovada | **H1** |

---

## 5. Pagamentos digitais / PIX

### 5.1 Separação obrigatória

```text
FUNCIONALIDADE            receber o pagamento de uma conta por PIX, com confirmação e conciliação
IMPLEMENTAÇÃO ENCONTRADA  uma classe utilitária que monta a string de um QR Code ESTÁTICO,
                          com chave de teste hard-coded, + duas tabelas na instalação de referência
```

⚠️ 🔴 **A implementação encontrada não é sequer uma integração** — é um gerador de texto.

### 5.2 Respondendo às perguntas do roteiro

| Pergunta | Resposta |
| -------- | -------- |
| **Qual problema resolve?** | PIX é hoje meio de pagamento dominante no Brasil. Sem ele, a companhia perde canal de recebimento e o cliente perde conveniência |
| **Gera QR Code por conta?** | 🟢 A tabela de referência `conta_qrcode_pix` sugere **por conta**; a classe existente gera **estático**, sem valor vinculado a documento |
| **Existe vínculo com a identidade da conta?** | ❔ **Não comprovado.** A tabela sugere o vínculo; o código não o implementa |
| **Como o pagamento é identificado?** | ❔ **Desconhecido no legado.** 🔵 No GSAN base, o recebimento PIX (se usado) chega pelo movimento bancário tradicional — sem tratamento próprio |
| **Existe confirmação externa?** | 🟢 **Não.** Nenhuma integração com PSP, webhook ou notificação |
| **Existe conciliação?** | 🟢 Não específica. Usaria a conciliação por aviso bancário |
| **Pertence à Arrecadação ou a Integrações?** | 🔵 **Ambos, em fronteiras diferentes** (§5.3) |

### 5.3 🔵 Ownership conceitual

```text
ARRECADAÇÃO   dona do RECEBIMENTO: reconhecer, classificar, aplicar, conciliar
              (o PIX é mais um meio — o ciclo de quatro momentos não muda)

INTEGRAÇÕES   dona do CONTRATO com o PSP: autenticação, cobrança dinâmica,
              confirmação assíncrona, idempotência do aviso, erro observável

FATURAMENTO   dono do DOCUMENTO ao qual o QR Code se refere
```

⚠️ **§34 do roteiro respeitado**: registro os requisitos funcionais, **não redesenho a Arrecadação**. O modelo de quatro momentos da Visão Conceitual já acomoda PIX sem alteração — o que falta é o contrato externo.

### 5.4 Requisitos funcionais a suportar no futuro

Cobrança dinâmica vinculada a documento · confirmação assíncrona do PSP com idempotência · conciliação do recebido contra o esperado · tratamento de pagamento sem documento identificável (o catálogo de resultados da classificação já cobre) · **chave PIX como configuração por ambiente/companhia, nunca constante** (D-08 já registra o problema no legado).

---

## 6. Fiscal e documentos fiscais

### 6.1 ⚠️ O maior desconhecido do catálogo

🟢 **Evidência estrutural**: schema `fiscal` com 14 tabelas (nota fiscal, certificado, armazenamento), `conta_impostos_deduzidos` no faturamento.

⚠️ 🟢 **Evidência de código nesta branch: nenhuma.** A busca por classes relacionadas a nota fiscal retorna apenas **falsos positivos** — são telas de *nota fiscal de aquisição de hidrômetro* (compra do equipamento), não emissão de documento fiscal de serviço.

🔵 **Conclusão honesta**: existe um schema fiscal inteiro cujo comportamento **não é observável neste repositório**. Classificação de maturidade: **APENAS EVIDÊNCIA**.

### 6.2 Respondendo ao roteiro — com o que se pode

| Pergunta | Resposta possível |
| -------- | ----------------- |
| **Que evento gera o documento fiscal?** | 🟡 Provavelmente a **conta emitida** (o serviço prestado no período). ❔ Não comprovado |
| **Que dados são necessários?** | 🔵 Cliente, serviço, valor, competência, tributos — todos já existentes na conta e em `conta_impostos_deduzidos` |
| **Existe numeração própria?** | 🟡 O schema sugere que sim (documento fiscal tem numeração legal própria, distinta do documento comercial) |
| **Existe integração externa?** | 🟡 Certificado digital e armazenamento no schema sugerem emissão eletrônica com autoridade externa |
| **É universal ou depende de legislação?** | 🔴 **Depende de legislação** — municipal e estadual, com variação real entre companhias |

### 6.3 🔴 O risco a evitar

⚠️ **Não criar estrutura universal falsa.** Legislação fiscal varia por município, estado e tipo de serviço.

```text
CAPACIDADE COMUM      emitir documento fiscal a partir do faturamento, com numeração
                      própria, tributos calculados e guarda do documento

PONTO VARIÁVEL        modelo do documento, regras de tributação, autoridade emissora,
                      formato de transmissão, prazos

INTEGRAÇÃO/REGULAÇÃO  autoridade fiscal, certificado digital, contingência
```

🔵 A capacidade comum é modelável; o ponto variável **precisa ser ponto de extensão, não código no núcleo**.

**Classificação**: ⚠️ `EXIGE APROFUNDAMENTO`, H2 — 🔴 **não** `MÓDULO OPCIONAL`. Dizer "opcional" já seria afirmar que o núcleo passa sem ela, e isso **depende do comportamento que não se observou**. Enquanto houver schema sem código, a natureza fica indeterminada por decisão, não por descuido.

---

## 7. SPED

🟢 **Evidência**: `integracao.sped_documento`, função `sp1_gerar_integracao_sped`, tabelas `ti_*` (contábil). ⚠️ 🟢 **Nenhuma classe Java** nesta branch — é funcionalidade **implementada no banco**.

🔵 **Posicionamento**: ⚠️ **não é core de faturamento.** É obrigação acessória que consome dados de outros módulos:

```text
Faturamento · Arrecadação · Financeiro
         ↓ (dados do período)
  Camada fiscal (documentos, tributos, apuração)
         ↓
  Obrigação acessória (SPED)
```

🔵 **Consequência**: SPED depende da existência da capacidade fiscal (§6). Implementar SPED antes de ter documento fiscal seria construir o telhado antes da parede.

⚠️ **Layout não analisado** — e não deve ser. Formato de obrigação acessória muda por legislação e ano-calendário; é implementação, não domínio.

**Classificação**: ⚠️ `EXIGE APROFUNDAMENTO`, H2 — pela mesma razão do §6.3, agravada: o comportamento está em função de banco, fora do alcance dos mapas funcionais.

---

## 8. Campo / Mobile

### 8.1 🔴 Separar capacidade de tecnologia

```text
CAPACIDADE                 IMPLEMENTAÇÃO ENCONTRADA (não transportável)
registrar leitura em campo → protocolo binário por opcode, sem autenticação
encerrar OS em campo       → servlet com estado compartilhado, endpoints sem credencial
enviar fotos               → mesmo servlet
```

🟢 As implementações já estão classificadas `NÃO TRANSPORTAR` na análise de compatibilidade, com as capacidades `PRESERVAR`. Este catálogo trata das **evoluções** além disso.

### 8.2 Capacidades

| Capacidade | Evidência | Natureza |
| ---------- | --------- | -------- |
| **Coleta móvel de leitura** | Tipo de leitura por rota (convencional, microcoletor, celular, leitura-e-impressão simultânea); movimento de roteiro; faixa esperada para detecção de leitura falsa | **CORE FUTURO** |
| **Releitura em campo** | `releitura_mobile`, `situacao_transm_leitura` | **CORE FUTURO** (parte de coleta) |
| **Impressão simultânea** | Action dedicada; conta pré-faturada | **CORE FUTURO** (parte de coleta) |
| **Execução móvel de OS** | Schema `mobile` (execução de corte, fiscalização, cliente); arquivos de OS para terceiros | **CORE FUTURO** |
| **Boletim de medição de serviços** | `micro_boletim_*`, indicador de boletim na OS, `contrato_empresa_*`, `item_servico*` | MÓDULO OPCIONAL (§8.4) |

### 8.3 Requisitos que o OpenGSAN deve suportar

🔴 Autenticação de **dispositivo**, não só de usuário (divergências D-04, D-05) · trabalho **offline** com sincronização posterior · **idempotência** no reenvio · rastreabilidade de quem executou, quando e onde · e a **faixa esperada de leitura** como controle antifraude (capacidade madura do legado, a preservar).

### 8.4 Gestão de contrato de empresa de campo

🔵 Capacidade distinta das anteriores: **medir e pagar serviço de terceiro por produção**. Empresa executa leitura, entrega ou OS; o sistema mede o que foi feito e apura o pagamento, com créditos e descontos.

🟡 É genérica (terceirização é comum no setor), mas **não pertence ao núcleo comercial** — é gestão de fornecedor. `MÓDULO OPCIONAL`, H3.

---

## 9. Evidências de campo e fotos

🔵 **Capacidade transversal identificada**, não um recurso de um módulo. Fotos aparecem ligadas a **quatro objetos diferentes**:

```text
leitura     (movimento_rot_empr_foto, foto_registro_tipo)
OS          (exibição de foto de OS; tipo de imagem)
ocorrência  (foto de ocorrência de cadastro, consultada pelo imóvel)
imóvel      (tabela de fotos sem classe correspondente)
```

🟢 Há fluxo comprovado: telas dedicadas de exibição e uma abstração de imagem.

🔵 **Leitura**: o que existe é o mesmo problema resolvido quatro vezes — **comprovar o que foi encontrado ou executado em campo**. Isso sugere uma capacidade de plataforma: *evidência anexada a um objeto de negócio, com tipo, autor, momento e — quando aplicável — localização*.

⚠️ **Não criar mecanismo genérico automaticamente** (§17 e §43 do roteiro). Registrado como **padrão transversal descoberto** (§19), a avaliar quando dois ou mais módulos do OpenGSAN precisarem dele de fato.

---

## 10. Recadastramento

🟢 **Capacidade substancial e comprovada**: 267 classes relacionadas, schema próprio (`atualizacaocadastral`, 29 tabelas), Action de requisição de dispositivo móvel dedicada, geração de arquivo texto para campo, e validadores próprios.

**Problema que resolve**: o cadastro comercial envelhece — imóveis mudam de uso, economias mudam de quantidade, moradores mudam. Sem recadastramento periódico, a base tarifária diverge da realidade e a companhia fatura errado.

🔵 **Componentes da capacidade**:

| Componente | Descrição |
| ---------- | --------- |
| **Campanha** | Recorte territorial a recadastrar, com período e responsável |
| **Coleta em campo** | Envio dos dados atuais ao dispositivo, coleta do que mudou |
| **Validação** | Crítica do que voltou antes de alterar o cadastro |
| **Aplicação em massa** | Atualização controlada, com trilha do que mudou e por quê |
| **Dados socioeconômicos** | ⚠️ Coletados junto — ver §11 |

🔵 **Ownership**: **Cadastro** é dono do efeito; a coleta é capacidade de campo (§8). ⚠️ **Não incorporar o formulário específico de uma companhia ao núcleo** — o conjunto de campos coletados é configuração, não modelo.

**Classificação**: `CORE FUTURO`, H2 — genérica para saneamento, mas depende do núcleo cadastral estável.

---

## 11. Tarifa social e programas sociais

### 11.1 🔴 A distinção que define este item

```text
CAPACIDADE GENÉRICA         conceder tarifa reduzida ou subsídio por critério socioeconômico
                            → pertence ao OpenGSAN

PROGRAMA INSTITUCIONAL      "Bolsa Água", "Viva Água", "Água Para", programa estadual X
                            → é INSTÂNCIA da capacidade, não módulo do OpenGSAN
```

⚠️ 🔴 **Não transformar nome de programa em módulo.** É o erro que o GSAN cometeu: os nomes dos programas estão no núcleo (tipo de consumo específico de programa, função de banco nomeada por programa, coluna de crédito por programa).

### 11.2 Evidência

🟢 Capacidade real e disseminada — 291 classes relacionadas a tarifa social, incluindo manutenção por tabela auxiliar, relatórios de acompanhamento e de imóveis excluídos, e **integração com o ciclo de faturamento**:

| Ponto de contato | Evidência |
| ---------------- | --------- |
| **Cadastro** | Classe social do imóvel, quantidade de economias sociais, indicador de exclusão de tarifa social |
| **Micromedição** | 🟢 Anormalidade de leitura pode **derrubar a tarifa social** (`ltan_icperdatarifasocial`) — o benefício tem condição de manutenção |
| **Faturamento** | Estruturas tarifárias próprias; tipo de consumo específico de programa; créditos de programa |
| **Recadastramento** | Coleta de dados socioeconômicos (NIS) |

🔵 O ponto da Micromedição é o mais revelador: **o benefício não é permanente — pode ser perdido por comportamento**. Isso confirma que a capacidade tem ciclo de vida próprio.

### 11.3 Componentes da capacidade genérica

Critério de elegibilidade (parametrizado) · cadastro do beneficiário com origem do dado · concessão com vigência · condição de manutenção e **perda** · efeito no cálculo (tarifa própria, desconto ou crédito) · acompanhamento e prestação de contas.

⚠️ **Registro de Cadastro Único / NIS é integração externa**, não parte da capacidade.

**Classificação**: `CORE FUTURO`, **H1** — tarifa social é praticamente universal no saneamento brasileiro e **afeta o cálculo da conta**, portanto precisa ser considerada cedo, não acoplada depois.

---

## 12. Bureau de crédito

🟢 **Capacidade comprovada e já mapeada**: comando de negativação com critérios parametrizados, movimentos de inclusão e exclusão, estado registrado na situação de cobrança do imóvel, retorno do negativador.

🔵 **Posicionamento conceitual (§6 do roteiro)**: tratar como **integração com bureau de crédito**, não como dependência de um fornecedor específico. O domínio é *negativar e reabilitar um devedor*; qual bureau recebe o movimento é contrato externo.

| Aspecto | Tratamento |
| ------- | ---------- |
| **Domínio** (quem pode ser negativado, por qual critério, quando sai) | Cobrança — já `PRESERVAR` na análise |
| **Integração** (envio, retorno, consulta, retirada, acompanhamento) | Camada de integração — transporte obsoleto a substituir |

**Classificação**: `INTEGRAÇÃO`, H2. ⚠️ Opcional: nem toda companhia negativa.

---

## 13. APIs e canais digitais

### 13.1 🔴 Portal de autoatendimento — a maior descoberta deste catálogo

🟢 **47 classes** em pacote próprio, cobrindo capacidades reais e distintas:

| Capacidade | Evidência |
| ---------- | --------- |
| Segunda via de conta | Emissão pelo cliente, com acesso geral ou autenticado |
| Extrato de débitos | Consulta da posição de dívida pelo próprio cliente |
| **Parcelamento online** | 🔴 Negociação de dívida **sem atendimento presencial** |
| Certidão negativa | Por imóvel e por cliente |
| Solicitação de serviços | Abertura de demanda pelo cliente |
| Consulta de estrutura tarifária | Transparência tarifária |
| Canais e lojas de atendimento | Informação institucional |
| Cadastro de e-mail do cliente | Canal de notificação |

⚠️ 🔵 **Nenhum dos dez mapas funcionais cobriu o portal** — porque **nenhum módulo é seu dono**. Ele atravessa Faturamento (2ª via), Cobrança (extrato, parcelamento), Atendimento (solicitação) e Cadastro (certidão).

🔵 **Isso é significativo para o OpenGSAN**: o canal digital com o cliente é hoje expectativa mínima, e o GSAN o resolveu como conjunto de telas sem dono. Merece **posicionamento conceitual próprio** — não necessariamente módulo, mas dono claro.

### 13.2 Identidade do cliente final

🟢 Evidência: cadastro de login do cliente, validação de e-mail, acesso ao portal com e sem autenticação.

🔴 **Capacidade distinta da Segurança interna**: o cliente não é usuário do sistema — não tem grupo, funcionalidade nem abrangência. Tem **acesso aos próprios dados**. Confundir os dois modelos é erro comum e caro.

**Classificação**: `CORE FUTURO`, H1.

### 13.3 APIs para terceiros e dispositivos

⚠️ **Não catalogar endpoints** (§25 do roteiro). Capacidades agrupadas:

| Capacidade | Consumidor típico |
| ---------- | ----------------- |
| **Consulta de débitos e emissão de 2ª via** | Aplicativo, correspondente bancário, canal parceiro |
| **Recebimento de leitura de campo** | Coletor, aplicativo de leiturista |
| **Operação de OS em campo** | Aplicativo de equipe |
| **Registro de pagamento/crédito** | Parceiro de arrecadação |
| **Consulta territorial** | Sistema de GIS |
| **Abertura e acompanhamento de atendimento** | Canal institucional, ouvidoria |

**Classificação**: `CORE FUTURO`, **H1** — 🔵 não porque "ter API" seja funcionalidade, mas porque **as capacidades acima já têm consumidores reais** no ecossistema GSAN, e sem elas o sistema fica ilhado.

### 13.4 Acessibilidade

🟢 Conta em braile: cadastro dedicado, disponível também pelo portal. 🔵 Capacidade pequena, obrigação de acessibilidade real, custo baixo. `MÓDULO OPCIONAL`, H2.

---

## 14. BI / Analytics

🟢 **Evidência**: matviews analíticas no `public`, papel de banco dedicado a OLAP, base gerencial separada (em `gsan-migracoes`), sincronismo de versão de base, e funcionalidade de relatório OLAP por ano no legado.

### 14.1 🔴 Respondendo à pergunta do roteiro

> *Isso deve ser responsabilidade do núcleo transacional, ou capacidade analítica separada?*

🔵 **Separada.** Três razões, todas com evidência:

1. 🟢 O GSAN **já separou de fato** — criou base gerencial própria e papel de banco dedicado, em vez de consultar o transacional.
2. A pergunta analítica é **diferente da transacional**: "quanto arrecadei por localidade nos últimos 24 meses" não tem a mesma forma que "qual a dívida deste imóvel hoje".
3. 🔴 Consumidores diretos do banco são **restrição forte a mudanças de schema** — o inventário já registrou isso como risco.

### 14.2 Distinção necessária

```text
RELATÓRIO OPERACIONAL/TRANSACIONAL    "listar as contas vencidas desta rota"
                                      → módulo Relatórios, dado corrente, dono é o módulo

ANÁLISE HISTÓRICA/GERENCIAL           "evolução da inadimplência por localidade em 24 meses"
                                      → capacidade analítica, dado consolidado, outro ciclo
```

⚠️ **Não duplicar o módulo Relatórios.** São coisas diferentes com públicos diferentes.

🔵 **Indicadores prováveis** (sem decidir): arrecadação e inadimplência, perdas, produtividade de campo, atendimento e prazos, evolução da base cadastral.

**Classificação**: `INTEGRAÇÃO` (consome, não é dona dos dados), **candidato a capacidade própria** (§20), H3. ⚠️ **Nenhuma ferramenta escolhida.**

---

## 15. Cobrança bancária / boleto registrado

🟢 **Comprovada**: pacote dedicado de registro de boletos, com serviços distintos para **conta** e **entrada de parcelamento**; layout de ficha de compensação validado; migrations de 2024 na instalação de referência ampliando o registro bancário.

🔵 **Problema que resolve**: no boleto **não registrado**, o banco não conhece o título — não há garantia de baixa correta, nem protesto, nem controle de pagamento fora do prazo. O registrado corrige isso, e **é exigência bancária** no Brasil desde a implantação da nova plataforma de cobrança.

### 15.1 Relação com o domínio

```text
Conta / entrada de parcelamento          documento a cobrar (Faturamento/Cobrança)
        ↓ registro
Título registrado no banco               identificador bancário, valor, vencimento, instruções
        ↓ retorno
Confirmação, baixa, alteração, protesto  (Arrecadação — já é o ciclo existente)
```

🔵 **Capacidade genérica** (gestão de cobrança bancária registrada) **separada da implementação específica** (layout de cada banco, que é contrato de integração).

**Classificação**: `CORE FUTURO`, **H1** — 🔵 sem registro, a cobrança bancária moderna não funciona.

---

## 16. GIS

⚠️ 🔴 **Distinção obrigatória (§36 do roteiro):**

```text
INTEGRAÇÃO GIS ATUAL          o que existe no legado: um sistema externo consulta o GSAN
                              (requisição autenticada por assinatura, coordenadas,
                               views geográficas de débito e imóveis)
                              → ISTO é o que este catálogo trata

DOMÍNIO GIS NATIVO FUTURO     visão estratégica do OpenGSAN (rede, ativos, traçado)
                              → NÃO é tratado aqui; não projetar
```

🟢 **O que existe**: três classes de integração, views geográficas, coordenadas no registro de atendimento (com indicador de ocorrência sem logradouro), recortes territoriais operacionais na quadra.

🔵 **Leitura**: o legado **já demonstra a necessidade de localizar o que não é imóvel** — uma ocorrência de rede em via pública tem coordenada, não matrícula. Isso é insumo para a expansão futura, mas **a integração atual é só integração**.

**Classificação**: `INTEGRAÇÃO`, H3, **candidato a domínio próprio no futuro** (§20).

---

## 17. Telemetria

🟢 **Evidência**: 28 classes relacionadas, tabelas de movimento, registro, log, log de erro e motivo de retorno; e um ponto de entrada dedicado para requisição de telemetria.

🔵 **O que representa**: **entrada automática de medição** — leitura sem visita, potencialmente em frequência maior que mensal.

⚠️ **Não projetar IoT** (§19 do roteiro). O que importa registrar:

| Aspecto | Observação |
| ------- | ---------- |
| **Natureza** | É uma **origem de leitura** adicional, não um domínio novo |
| **Fronteira** | Micromedição é dona do consumo; a telemetria é canal de entrada |
| **Frequência** | 🔵 Pode romper a premissa mensal do ciclo — o que a Visão Conceitual já registrou como decisão a não inviabilizar |
| **Segurança** | 🔴 A implementação atual grava leitura **sem autenticar a origem** (achado 15, divergência D-05) |

**Classificação**: `MÓDULO OPCIONAL`, H2.

---

## 18. Outras capacidades encontradas

| Capacidade | Evidência | Natureza | Nota |
| ---------- | --------- | -------- | ---- |
| **Notificação ao cliente** | Serviço de e-mail com sete variantes de envio; serviço de SMS com mensagens de vencimento, corte e confirmação | **CORE FUTURO** | 🔵 Capacidade de plataforma. ⚠️ A implementação de SMS tem segredo em código e ignora o tipo da mensagem (D-08, D-13) |
| **Cobrança terceirizada por resultado** | Comando de carteira por empresa, situação do imóvel, acompanhamento de pagamento repassado e comissão | MÓDULO OPCIONAL | Já mapeada na Cobrança; a **remuneração por recuperação** é a parte que extrapola o núcleo |
| **Prestação de contas regulatória** | Dados complementares do RA para a agência reguladora, com telas de consulta e relatório | **INTEGRAÇÃO** | 🔵 Obrigação regulatória real; ⚠️ prazos e formato variam por agência |
| **Pagamento por cartão** | Rotinas de movimento de cartão com validação de cabeçalho/rodapé; parcelamento por cartão de crédito na Cobrança | MÓDULO OPCIONAL | 🔵 Entra como mais um meio de recebimento; o parcelamento por cartão é da Cobrança |
| **Correção por idade do medidor** | Tabelas de fator de correção e faixa de idade do hidrômetro | MÓDULO OPCIONAL | ⚠️ **Apenas evidência.** 🔵 Compensa submedição de medidor envelhecido — tem impacto **financeiro direto**, portanto exige caracterização antes de qualquer implementação |
| **Armazenamento de documentos** | Estruturas de armazenamento em bucket e mapeamento de tabelas que o usam | **INTEGRAÇÃO** | ⚠️ Apenas evidência. 🔵 Indica movimento para tirar binário do banco transacional — coerente com a dúvida aberta sobre artefatos de relatório |
| **Contabilização** | Funções de geração de conta a receber contábil; schema financeiro | MÓDULO OPCIONAL | ⚠️ Apenas evidência. 🔵 Ponte entre o comercial e o sistema contábil da companhia |

---

## 19. Capacidades transversais

🔵 **Padrões descobertos**: necessidades que **várias capacidades compartilham**. Registrados por informarem a arquitetura posterior. ⚠️ **Nenhum vira módulo genérico automaticamente.**

| # | Padrão | Onde aparece | Observação |
| - | ------ | ------------ | ---------- |
| T1 | **Evidência anexada a objeto de negócio** | Leitura, OS, ocorrência, imóvel, recadastramento | 🔵 O mesmo problema resolvido 4+ vezes (§9) |
| T2 | **Notificação ao cliente** | Vencimento, corte, confirmação de cadastro, aviso a empresa terceirizada | Canal, modelo de mensagem, destinatário, evidência de envio |
| T3 | **Identidade de dispositivo e de sistema** | Coletor, app de OS, telemetria, GIS, API de parceiro | 🔴 Distinta da identidade de usuário interno **e** da identidade do cliente final |
| T4 | **Documento eletrônico com guarda** | Conta impressa, relatório gerado, documento fiscal, foto de campo | Guarda, recuperação, retenção e **controle de acesso** (achado 13) |
| T5 | **Contrato com parceiro externo** | Banco, PSP, bureau, empresa de campo, empresa de cobrança, agência reguladora | Contrato, credencial, idempotência, erro observável |
| T6 | **Campanha / comando em massa** | Recadastramento, cobrança, negativação, ordem seletiva | 🔵 Recorte + critério + execução + acompanhamento — padrão já maduro no legado |

🔵 **T6 é o mais interessante**: o GSAN **já resolveu bem** esse padrão na Cobrança (comando com filtros, resultado rastreável). Recadastramento e negativação usam a mesma forma. Sugere capacidade de plataforma real, não coincidência.

---

## 20. Candidatos a novos módulos

⚠️ **Marcação, não criação.** Exigem justificativa e nenhum é decidido aqui.

| Candidato | Justificativa | Contra-argumento | Situação |
| --------- | ------------- | ---------------- | -------- |
| **Fiscal** | 🟢 Schema próprio de 14 tabelas; ciclo próprio (documento fiscal tem numeração, cancelamento e prazo legais distintos do documento comercial); depende de legislação que varia; e o SPED depende dele | ⚠️ Comportamento **não observável** nesta branch — pode ser menor do que o schema sugere | **CANDIDATO** — decisão depende de esclarecer o comportamento |
| **Analytics** | 🟢 O GSAN já separou de fato (base gerencial, papel dedicado); pergunta analítica difere da transacional; consumidores diretos do banco restringem mudanças | ⚠️ Pode ser capacidade de plataforma em vez de módulo de domínio | **CANDIDATO** |
| **GIS** | Visão estratégica já estabelecida; o legado demonstra necessidade de localizar o que não é imóvel | 🔴 O que existe hoje é **só integração** — não há domínio GIS no legado a preservar | **CANDIDATO FUTURO** — não por evidência atual, mas por visão |
| **Canal digital do cliente** | 🟢 47 classes sem dono; atravessa quatro módulos; identidade do cliente é modelo distinto do usuário interno | 🔵 Pode ser camada de apresentação sobre capacidades existentes, não domínio | **CANDIDATO** — ⚠️ depende da ADR-0007 |

---

## 21. Funcionalidades específicas de companhia

⚠️ **Não devem contaminar o núcleo.** Catalogadas como **instância de capacidade genérica** sempre que possível (§21 do roteiro).

| Específico encontrado | Capacidade genérica correspondente | Tratamento |
| --------------------- | ---------------------------------- | ---------- |
| Programas de subsídio nomeados (Bolsa Água, Viva Água, Água Para) | **Benefício social tarifário** (§11) | Instância configurada; ⚠️ o nome **não** entra no núcleo |
| Tipo de consumo específico de programa social | Origem do consumo (já genérica) | Parametrização |
| Crédito nomeado por programa | Tipo de crédito (já parametrizado) | Parametrização |
| Contrato de energia do imóvel (identificador de concessionária parceira) | Identificador externo do imóvel | ⚠️ Campo genérico com origem, não campo nomeado por empresa |
| Dígito verificador específico de companhia | Regra de formatação da matrícula | Ponto de extensão |
| Variantes de cálculo de faixa nomeadas por companhia | Política tarifária | 🔴 Ponto de extensão — **não método no núcleo** |
| Campanhas de cobrança nomeadas | Campanha de cobrança (padrão T6) | Parametrização |
| Tipos de débito locais (ex.: tarifa de cortado) | Tipo de débito (já parametrizado) | Parametrização |

🔵 **O padrão é consistente**: quase toda "customização" encontrada é **instância de algo genérico** que o GSAN já tinha — o erro não foi criar a necessidade, foi **codificá-la com nome próprio no núcleo**.

---

## 22. Não candidatos ao OpenGSAN

Recursos encontrados que **não** devem ir adiante. ⚠️ Não altera a classificação estrutural anterior — apenas registra.

| Item | Motivo |
| ---- | ------ |
| **Applet de impressão térmica** | Tecnologia morta; navegadores não executam applets. A **capacidade** (imprimir em impressora térmica no atendimento) pode ser reavaliada, mas o mecanismo não |
| **Atendimento "manual" com numeração própria** | 🟡 Aparenta contingência tecnológica do legado (operar sem sistema), não regra de negócio. Já marcado `EXIGE APROFUNDAMENTO` na compatibilidade |
| **Códigos de exibição de RA** (referência/atual/anterior) | São rótulos de tela, não conceito de domínio |
| **Gerador de QR Code PIX estático com chave em código** | 🔴 Não é integração; é utilitário com segredo versionado (D-08). A **capacidade** PIX é candidata; esta implementação não |
| **Nota fiscal de aquisição de hidrômetro tratada como "fiscal"** | ⚠️ Não é documento fiscal de serviço — é dado de compra do equipamento. Registrado para evitar confusão em análise futura |
| **Tabelas de backup, cópias por competência e artefatos de manutenção** | Já classificados `NÃO TRANSPORTAR` por famílias |

---

## 23. Dependências

⚠️ **Dependências conceituais apenas** — nenhuma dependência técnica.

```text
PAGAMENTO INSTANTÂNEO (PIX)          COBRANÇA BANCÁRIA REGISTRADA
├── Documento a cobrar               ├── Documento a cobrar
├── Identidade do documento          ├── Identidade do documento
├── Recebimento                      ├── Recebimento
├── Conciliação                      ├── Conciliação
└── Contrato com PSP                 └── Contrato bancário

BENEFÍCIO SOCIAL TARIFÁRIO           DOCUMENTO FISCAL
├── Cadastro (imóvel, economias)     ├── Documento comercial emitido
├── Categoria/classificação          ├── Tributos apurados
├── Estrutura tarifária              ├── Numeração própria
├── Critério de elegibilidade        ├── Certificado digital
├── Condição de perda                └── Autoridade fiscal externa
└── Origem do dado social (externa)        ↓
                                     OBRIGAÇÃO ACESSÓRIA (SPED)
COLETA MÓVEL DE LEITURA              └── depende de Documento Fiscal
├── Estrutura territorial (rota)
├── Ciclo de leitura                 CANAL DIGITAL DO CLIENTE
├── Identidade de dispositivo        ├── Identidade do cliente final
├── Sincronização offline            ├── Posição de dívida
└── Evidência de campo               ├── Documento emitido (2ª via)
                                     ├── Negociação (parcelamento)
RECADASTRAMENTO                      └── Abertura de demanda
├── Cadastro completo
├── Campanha (padrão T6)             ANÁLISE GERENCIAL
├── Coleta em campo                  └── depende de TODOS os módulos
└── Validação antes de aplicar           (consome, não produz)
```

🔵 **Duas cadeias de dependência importantes**: (a) **SPED depende de Fiscal**, que depende do documento comercial — construir na ordem inversa é inviável; (b) **Analytics depende de todos** — por isso é H3, não por ser menos valiosa.

---

## 24. Horizonte preliminar

⚠️ **Não é ordem de implementação** — é indicação de proximidade ao núcleo. A ordem sai da próxima atividade.

### H1 — próximo do núcleo (9)

| Capacidade | Por que H1 |
| ---------- | ---------- |
| **Pagamento instantâneo (PIX)** | Meio dominante no país; sem ele a companhia perde canal de recebimento |
| **Cobrança bancária registrada** | Exigência bancária; sem registro a cobrança moderna não funciona |
| **Benefício social tarifário** | 🔴 **Afeta o cálculo da conta** — acoplar depois é mais caro que considerar cedo |
| **Portal de autoatendimento** | Expectativa mínima do cliente hoje |
| **Identidade do cliente final** | Pré-requisito do portal |
| **Notificação ao cliente** | Sustenta cobrança, atendimento e portal |
| **Coleta móvel de leitura** | Já é a operação real de campo |
| **Execução móvel de OS** | Idem |
| **APIs para terceiros e dispositivos** | Sem elas o sistema fica ilhado |

### H2 — evolução importante (11)

Recadastramento · Documento fiscal · SPED · Integração contábil · Cartão · Telemetria · Bureau de crédito · Cobrança terceirizada · Prestação de contas regulatória · Evidência de campo · Acessibilidade.

### H3 — plataforma ampliada (5)

Análise gerencial · GIS · Armazenamento de documentos · Gestão de contrato de empresa de campo · Correção por idade do medidor.

### ESPECÍFICA (1)

Programas de subsídio nomeados (§12 do catálogo).

⚠️ As demais especificidades encontradas — variantes de cálculo por companhia, campos institucionais, DV próprio, campanhas nomeadas — **não são capacidades**: são instâncias ou pontos de extensão de capacidades genéricas, tratadas no §21.

### 24.1 Relação com a visão de longo prazo

| Eixo | Capacidades |
| ---- | ----------- |
| **Comercial** | PIX · boleto registrado · cartão · portal · identidade do cliente · benefício social · recadastramento · bureau · cobrança terceirizada · acessibilidade |
| **Operacional** | Coleta móvel · execução móvel de OS · evidência de campo · contrato de empresa de campo · prestação de contas regulatória |
| **Técnico** | Telemetria · correção por idade do medidor |
| **GIS** | Georreferenciamento (hoje integração) |
| **Analytics** | Análise gerencial |
| **Plataforma** | Notificação · APIs · armazenamento de documentos · documento fiscal · SPED · contabilização |

### 24.2 Necessidade para o núcleo moderno

| Classificação | Capacidades |
| ------------- | ----------- |
| **NECESSÁRIA PARA O CORE MODERNO** | PIX · boleto registrado · benefício social · notificação · APIs |
| **IMPORTANTE APÓS O CORE** | Portal · identidade do cliente · coleta móvel · execução móvel de OS · recadastramento |
| **EVOLUÇÃO FUTURA** | Fiscal · SPED · contabilização · telemetria · analytics · GIS · armazenamento · contrato de campo |
| **ESPECÍFICA/OPCIONAL** | Cartão · acessibilidade · bureau · cobrança terceirizada · regulatória · correção por idade · programas nomeados |

---

## 25. Lacunas e dúvidas

| # | Lacuna | Impacto | O que falta |
| - | ------ | ------- | ----------- |
| 1 | 🔴 **Comportamento da capacidade fiscal** | Bloqueia decidir se Fiscal é módulo e o que exatamente faz | Acesso ao código fiscal da instalação, ou entrevista funcional |
| 2 | 🔴 **Comportamento do SPED** | Depende de (1) | Idem |
| 3 | **Fluxo real de PIX na instalação de referência** | Define o que já existe × o que é novo | Estrutura e uso das tabelas PIX |
| 4 | **Critérios reais de elegibilidade social** | A capacidade é H1 e afeta cálculo | Regras de concessão, manutenção e perda por companhia |
| 5 | **Uso efetivo de telemetria e cartão** | Define se é opcional ou raro | Volume e companhias que usam |
| 6 | **Escopo da contabilização** | Define se é integração ou módulo | Funções de geração contábil |
| 7 | **Consumidores reais das APIs** | Já registrado como dúvida nas Integrações | Inventário de consumidores |
| 8 | **Correção por idade do medidor** | 🔴 Tem impacto financeiro direto | Fórmula e uso real |
| 9 | ❔ **Simulação hidráulica** | — | 🟢 **Nenhuma evidência encontrada** no legado. Permanece **visão futura já estabelecida**, fora deste catálogo baseado em evidência (§37 do roteiro) |

---

## 26. Evidências

⚠️ Evidência **suficiente**, não exaustiva.

| Capacidade | Evidência principal |
| ---------- | ------------------- |
| PIX | `gcom.arrecadacao.GeradorQrCodePIX`; tabelas `arrecadacao_pix` e `conta_qrcode_pix` (só na instalação de referência); sem migration oficial |
| Boleto registrado | Pacote `gcom.faturamento.registroBoletos` (serviços para conta e para entrada de parcelamento); `FichaCompensacao`, `BoletoInfo`; migrations de registro bancário (2024) |
| Cartão | Rotinas de movimento de cartão com validação de cabeçalho/rodapé; `PagamentoCartaoDebito`; `ParcelamentoPagamentoCartaoCredito` |
| Portal | Pacote `gcom.gui.portal` (47 classes): 2ª via, extrato, parcelamento, certidões, solicitação, canais, estrutura tarifária |
| Identidade do cliente | `CadastroLoginClienteAction`, validação de e-mail, acesso geral × autenticado |
| Notificação | `gcom.util.email.ServicosEmail`; `gcom.util.sms.ServicoSMS` |
| Acessibilidade | `InserirCadastroContaBraileAction` e variante do portal |
| Fiscal | Schema `fiscal` (14 tabelas) — ⚠️ **sem classe Java correspondente nesta branch** |
| SPED | `integracao.sped_documento`, `sp1_gerar_integracao_sped`, tabelas `ti_*` — ⚠️ **implementado no banco** |
| Contabilização | Schema `financeiro`; funções de geração de conta a receber contábil |
| Benefício social | 291 classes relacionadas a tarifa social; `imov_classe_social`, `imov_qtd_economias_social`; `ltan_icperdatarifasocial`; schema `atualizacaocadastral` |
| Recadastramento | 267 classes; schema `atualizacaocadastral` (29 tabelas); Action de dispositivo móvel; geração de arquivo para campo |
| Coleta móvel | Tipo de leitura por rota; `movimento_roteiro_empr`; `releitura_mobile`; `situacao_transm_leitura`; faixa esperada |
| Execução móvel de OS | Schema `mobile` (22 tabelas): execução de corte, fiscalização, cliente; arquivos de OS para terceiros |
| Evidência de campo | `movimento_rot_empr_foto`, `foto_registro_tipo`; `ExibirOrdemServicoFotoAction`; `ExibirFotoOcorrenciaCadastroConsultarImovelAction` |
| Telemetria | 28 classes; `telemetria_mov`, `telemetria_mov_reg`, `telemetria_log`, `telemetria_ret_mot`; entry point dedicado |
| Correção por idade | `hidrometro_fat_correcao`, `hidrometro_faixa_idade` |
| Contrato de campo | `contrato_empresa_*`, `item_servico*`, `micro_boletim_*` |
| Bureau de crédito | Pacote `gcom.spcserasa`; comando e critérios de negativação; movimentos do negativador |
| Cobrança terceirizada | `ComandoEmpresaCobrancaConta`; `empr_cobr_conta_pagto`; acompanhamento de pagamento repassado |
| Regulatória | `RaDadosAgenciaReguladora` + telas de filtro/consulta |
| Analytics | Matviews analíticas; papel de banco OLAP; base gerencial (`gsan-migracoes`); `SelecaoRelatorioOLAPAno` |
| GIS | `ProcessarRequisicaoGisAction`, `ProcessarCoordenadasGisAction`, `GisHelper`; views geográficas; coordenadas no RA |
| Armazenamento | `informacoes_armazenamento_bucket`, `inform_armaz_bucket_tabelas` |
| APIs | Servlets `/api/*`; entry points de dispositivo; cliente de serviço externo com OAuth2 |

---

## 27. Próxima atividade

**Refinamento das Dependências e Ordem de Implementação** — combinando mapa de domínio + Visão Conceitual + compatibilidade das estruturas + este catálogo, para definir a sequência mais segura de construção do OpenGSAN. ⚠️ **Não executada aqui.**
