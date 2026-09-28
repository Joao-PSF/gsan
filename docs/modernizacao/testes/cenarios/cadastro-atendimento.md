# Cenários Críticos — Cadastro e Atendimento

> Parte de [`cenarios-criticos.md`](../cenarios-criticos.md). Modelo e regras em [`estrategia-testes.md`](../estrategia-testes.md).
>
> ⚠️ **Nenhum valor desta página foi capturado.** Baseline: `⬜ A CAPTURAR NA FASE 2` em todos os cenários.

🔵 **Leitura da área**: aqui vive a **primeira fatia vertical** (autenticar → consultar imóvel/cliente → abrir e tramitar RA) e o **contrato central** do OpenGSAN — *a OS solicita, o dono aplica*.

⚠️ **O mapa do Cadastro não tem inventário de cenários.** Os cinco cenários `CEN-CAD` foram **derivados** das regras estruturantes do mapa (§5) e dos estados (§6), não de uma lista pré-existente — registrado para a auditoria.

---

## CEN-CAD-001 — Matrícula e dígito verificador

- **Criticidade**: P1
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: Imóvel/matrícula (C1) · dígito verificador (C2 — regra configurável)
- **Objetivo**: caracterizar a identidade pública do imóvel e seu dígito verificador
- **Pré-condições**: imóveis com matrículas cobrindo casos de fronteira do DV (restos que geram dígito 0 e o maior dígito possível); um imóvel com exclusão lógica
- **Entrada**: V1 — matrícula com DV correto; V2 — matrícula com DV incorreto; V3 — matrícula de imóvel excluído logicamente
- **Operação GSAN**: consulta de imóvel pela matrícula
- **Operação conceitual OpenGSAN**: localizar imóvel pela identidade pública
- **Observações semânticas**: imóvel localizado (sim/não) · DV aceito/recusado · tratamento do excluído logicamente · matrícula nunca reaproveitada
- **Localizadores GSAN**: `imov_id` com dígito módulo 11; `imov_icexclusao`
- **Resultado semântico esperado**: 🟢 a identidade é estável e **nunca reaproveitada**; o DV é módulo 11; exclusão é **lógica**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma — a matrícula é identidade funcional
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 1 → 2
- **Evidência**: [`modulos/cadastro.md`](../../modulos/cadastro.md) §5 regra 1; CAD-01

⚠️ **Variantes de DV por companhia** ficam `A COMPLEMENTAR` (ver índice): o cenário caracteriza **a variante ativa na instância de referência**.

---

## CEN-CAD-002 — Cliente × Imóvel por papel e vigência

- **Criticidade**: P0
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: Cliente × Imóvel (C1)
- **Objetivo**: caracterizar **quem é o cliente em cada papel, numa data** — o que decide a quem se fatura e quem se negativa
- **Pré-condições**: IMV-01 com clientes em papéis distintos (usuário, responsável, proprietário); um vínculo encerrado com motivo; troca de cliente-usuário no meio de uma referência
- **Entrada**: consulta do cliente por papel em datas antes, durante e depois da troca
- **Operação GSAN**: consulta de clientes do imóvel
- **Operação conceitual OpenGSAN**: obter o cliente de um papel numa data
- **Observações semânticas**: cliente por papel e data · vínculos ativos (fim nulo) × encerrados · motivo do encerramento
- **Localizadores GSAN**: `ClienteImovel` (papel, data de início, data de fim, motivo)
- **Resultado semântico esperado**: 🟢 o vínculo tem **papel, vigência e motivo** — nunca se reduz a uma chave simples; em cada data há um cliente definido por papel
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 1 → 2
- **Evidência**: [`modulos/cadastro.md`](../../modulos/cadastro.md) §5 regra 5; CAD-04

🔵 **Por que P0**: um papel errado leva à **negativação da pessoa errada** — dano difícil de reverter.

---

## CEN-CAD-003 — Composição de economias por categoria e subcategoria

- **Criticidade**: P0
- **Etapa OpenGSAN**: 2 — Núcleo operacional
- **Conceitos relacionados**: Economia (C2) · Categoria/Subcategoria (C1)
- **Objetivo**: caracterizar a quantidade de economias por categoria que governa tarifa e mínimo
- **Pré-condições**: IMV-01 (1 economia), IMV-02 (várias economias, mesma categoria), IMV-03 (várias categorias e subcategorias)
- **Entrada**: consulta da composição de economias de cada imóvel
- **Operação GSAN**: leitura de `imovel_subcategoria`
- **Operação conceitual OpenGSAN**: obter a composição de economias
- **Observações semânticas**: economias por categoria · economias por subcategoria · total · categoria principal
- **Localizadores GSAN**: `imovel_subcategoria`; `imov_qteconomia`; `imov_idcategoriaprincipal`, `imov_idsubcategoriaprincipal`
- **Resultado semântico esperado**: 🟢 as economias **agregadas por subcategoria** governam a tarifa; a individualização é informativa. O total e a categoria principal do OpenGSAN são **derivados** da composição
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2 — ⚠️ inclusive **se os valores denormalizados no Imóvel coincidem com a composição**
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma aprovada. ⚠️ **CAND-01**: se o legado tiver total ou categoria principal **defasados**, o valor derivado divergirá — decisão registrada, nunca aceita em silêncio
- **Oráculo**: **1** — por mapeamento semântico (composição → total)
- **Gate que este cenário protege**: 2 → 3
- **Evidência**: [`modulos/cadastro.md`](../../modulos/cadastro.md) §5 regra 2; CAD-05, CAD-07

---

## CEN-CAD-004 — Situações da ligação: faturabilidade e situação derivada do imóvel

- **Criticidade**: P0
- **Etapa OpenGSAN**: 2 — Núcleo operacional
- **Conceitos relacionados**: situação da ligação (C2 — passa a ser da Ligação) · situação derivada (C1)
- **Objetivo**: caracterizar como as situações das ligações determinam **se e como se fatura** e **quais solicitações o atendimento habilita**
- **Pré-condições**: imóveis cobrindo as situações de água (potencial, factível, ligado, cortado, suprimido e ⚠️ o valor 4) × situações de esgoto; imóveis em cada situação especial de faturamento (NORMAL, PARALISAR_EMISSAO_CONTAS, PARALISAR_LEITURA_FATURAR_MEDIA, PARALISAR_LEITURA_FATURAR_TAXA_MINIMA, FATURAR_NORMAL)
- **Entrada**: consulta dos atributos derivados de cada combinação
- **Operação GSAN**: leitura das situações e da tabela paramétrica `imovel_situacao`
- **Operação conceitual OpenGSAN**: obter faturabilidade e situação derivada
- **Observações semânticas**: fatura (sim/não) · forma de faturamento (leitura, média, mínimo) · consumo mínimo aplicável · situação derivada (ATIVO/INATIVO/LIGADO_SO_ESGOTO) · tipos de solicitação habilitados
- **Localizadores GSAN**: `ligacao_agua_situacao` e seus indicadores; `LigacaoEsgotoSituacao`; `imov.ftst_id`; `imovel_situacao` → `imovel_situacao_tipo`
- **Resultado semântico esperado**: 🟢 os efeitos vêm de **atributos da situação** (dado), não de regra em código; 🟢 a situação do imóvel é **derivada** por tabela paramétrica
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2 — ⚠️ incluindo **a semântica do valor 4** (duas constantes, significado definido por dado da instalação) e **a completude** de `imovel_situacao`
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico (a situação muda de dono, não de significado)
- **Gate que este cenário protege**: 2 → 3
- **Evidência**: [`modulos/cadastro.md`](../../modulos/cadastro.md) §5 regras 3, 4 e 8; §6; CAD-08

---

## CEN-CAD-005 — Rotas por finalidade

- **Criticidade**: P1
- **Etapa OpenGSAN**: 2 — Núcleo operacional
- **Conceitos relacionados**: Rota (C2 — três colunas passam a vínculo por finalidade)
- **Objetivo**: caracterizar as três finalidades de rota e a precedência da rota alternativa
- **Pré-condições**: IMV-01 só com rota de leitura via quadra; IMV-17 com rota alternativa definida; imóvel com rota de entrega distinta
- **Entrada**: processos de leitura, análise e entrega sobre os imóveis
- **Operação GSAN**: seleção de imóveis por rota nos processos de leitura e entrega
- **Operação conceitual OpenGSAN**: resolver a rota de um imóvel por finalidade
- **Observações semânticas**: rota usada na leitura · rota usada na análise · rota usada na entrega
- **Localizadores GSAN**: quadra → rota; `rota_identrega`; `rota_idalternativa`
- **Resultado semântico esperado**: 🟢 as três finalidades são **distintas**; quando definida, a alternativa **prevalece** sobre a da quadra nos processos de leitura/análise
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 2 → 3
- **Evidência**: [`modulos/cadastro.md`](../../modulos/cadastro.md) §5 regra 9; CAD-10; [`modulos/micromedicao.md`](../../modulos/micromedicao.md) §13 item 9

---

## CEN-ATE-001 — Consulta de imóvel e cliente sob autorização

- **Criticidade**: P1
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: Imóvel, Cliente × Imóvel, ligações (C1)
- **Objetivo**: caracterizar o conjunto de dados que a consulta de imóvel entrega a um usuário autorizado — **segundo passo da fatia vertical**
- **Pré-condições**: USR-01 com a funcionalidade de consulta; IMV-01 e IMV-03
- **Entrada**: consulta dos dois imóveis
- **Operação GSAN**: telas de consultar imóvel
- **Operação conceitual OpenGSAN**: consultar imóvel
- **Observações semânticas**: identidade · endereço · clientes por papel · ligações e suas situações · situação derivada · composição de economias
- **Localizadores GSAN**: a identificar na Fase 1 (Actions de consulta de imóvel)
- **Resultado semântico esperado**: o usuário autorizado obtém os dados do imóvel coerentes com CEN-CAD-002, CEN-CAD-003 e CEN-CAD-004; ⚠️ a **forma de apresentação não é comparada**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: formatação e ordem de exibição sem semântica
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 1 → 2
- **Evidência**: [`modulos/dependencias-e-ordem-implementacao.md`](../../modulos/dependencias-e-ordem-implementacao.md) §21 — cenário **derivado** da fatia vertical

⚠️ **Neutro à ADR-0007**: nada aqui depende de tela ou recurso REST.

---

## CEN-ATE-002 — Abertura de RA governada pela especificação

- **Criticidade**: P1
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: RA (C1) · `SolicitacaoTipoEspecificacao` (C2 — política versionada)
- **Objetivo**: caracterizar como a **especificação**, que é dado, determina o comportamento da abertura — o padrão *regra como dado* exercitado na fatia vertical
- **Pré-condições**: ESP-01 (sem geração de OS), ESP-02 (gera OS automaticamente, com serviço, prioridade e valor), ESP-04 (admite RA sem imóvel); IMV-01; USR-01 autorizado
- **Entrada**:

  | Var. | Descrição |
  | ---- | --------- |
  | V1 | RA com ESP-01 para IMV-01 |
  | V2 | RA com ESP-02 para IMV-01 |
  | V3 | RA com ESP-04, **sem matrícula**, com localização por coordenadas |
  | V4 | V1 repetida após **alterar o dado** da especificação (ex.: prazo) |

- **Operação GSAN**: registrar atendimento
- **Operação conceitual OpenGSAN**: abrir demanda
- **Observações semânticas**: protocolo gerado · situação inicial · prazo previsto · unidade atual · obrigatoriedades exigidas · OS gerada (sim/não; tipo de serviço, prioridade, valor) · autoria
- **Localizadores GSAN**: `step_icgeracaoordemservico`; `unid_idatual`; datas previstas do RA
- **Resultado semântico esperado**: 🟢 prazo, obrigatoriedades e geração de OS **decorrem da especificação**. V4 — o comportamento muda **sem recompilar**. V3 — 🟢 a matrícula é **opcional** no RA
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: número do protocolo (identidade técnica diferente — comparar pelo **vínculo** RA↔OS); timestamps
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 1 → 2 — *comportamento do RA muda ao alterar dado de especificação*
- **Evidência**: [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 itens 3 e 9; ATE-03

---

## CEN-ATE-003 — Encerramento de RA sem OS e encerramento automático

- **Criticidade**: P1
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: RA ≠ OS (C1)
- **Objetivo**: caracterizar o fim do ciclo do RA quando não há execução
- **Pré-condições**: RA aberto com ESP-01; RA aberto com ESP-03 (encerramento automático)
- **Entrada**: V1 — encerramento manual com parecer e motivo; V2 — condição de encerramento automático atingida
- **Operação GSAN**: encerrar atendimento
- **Operação conceitual OpenGSAN**: encerrar demanda
- **Observações semânticas**: situação final · motivo · parecer · data · autoria · ausência de OS
- **Localizadores GSAN**: situação e motivo de encerramento do RA
- **Resultado semântico esperado**: 🟢 um RA pode ser encerrado **sem OS**; o encerramento automático é **parametrizado pela especificação**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: timestamps
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 1 → 2
- **Evidência**: [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 itens 1 e 2

---

## CEN-ATE-004 — Tramitação entre unidades

- **Criticidade**: P1
- **Etapa OpenGSAN**: 1 — Primeira fatia vertical
- **Conceitos relacionados**: tramitação (C1) · unidade organizacional (C1 — posicionamento, não autorização)
- **Objetivo**: caracterizar o histórico de trâmites e a unidade atual
- **Pré-condições**: UNI-01 e UNI-02; RA aberto em UNI-01; USR-01 em UNI-01; USR-10 em UNI-02
- **Entrada**: V1 — USR-01 tramita de UNI-01 para UNI-02; V2 — USR-10 tramita de volta; V3 — USR-10 tenta tramitar ou encerrar **enquanto o RA ainda está em UNI-01**
- **Operação GSAN**: tramitar atendimento
- **Operação conceitual OpenGSAN**: tramitar demanda
- **Observações semânticas**: histórico de trâmites (ordem, origem, destino, autor) · unidade atual · resultado de V3
- **Localizadores GSAN**: registros de trâmite; `unid_idatual`
- **Resultado semântico esperado**: 🟢 a tramitação é **histórico auditável** e a unidade atual é **estado corrente**. V3 — ❔ não se sabe se há bloqueio: **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: timestamps; identificadores dos registros de trâmite
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — ⚠️ a ordem dos trâmites **tem semântica** e não é normalizada
- **Gate que este cenário protege**: 1 → 2
- **Evidência**: [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 item 4; [`modulos/seguranca.md`](../../modulos/seguranca.md) §27 item 18

---

## CEN-ATE-005 — Prazo, espera e reiteração

- **Criticidade**: P1
- **Etapa OpenGSAN**: 2 — Núcleo operacional
- **Conceitos relacionados**: prazo original × atual (C1) · espera e reiteração (C2 — campos que sobrescrevem → histórico)
- **Objetivo**: caracterizar o efeito da espera sobre o prazo e o registro da reiteração
- **Pré-condições**: RA aberto com prazo conhecido
- **Entrada**: V1 — início e fim de espera; V2 — reiteração, duas vezes
- **Operação GSAN**: registrar espera; reiterar
- **Operação conceitual OpenGSAN**: suspender e retomar demanda; reiterar
- **Observações semânticas**: prazo original · prazo atual (`dataPrevistaAtual`) · contador de reiteração · data da última reiteração
- **Localizadores GSAN**: `dataPrevistaAtual`; contador e data de reiteração no RA
- **Resultado semântico esperado**: 🟢 o prazo original **não se perde**. ❔ **Se a espera altera `dataPrevistaAtual` não está comprovado** — é o que este cenário descobre. No OpenGSAN, os valores correntes devem **coincidir** com os do GSAN; o histórico adicional **não é comparado**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: timestamps de registro
- **Divergência permitida**: nenhuma — manter histórico é acréscimo, não mudança de valor
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 2 → 3
- **Evidência**: [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 itens 5 e 6; ATE-05

---

## CEN-ATE-006 — Ciclo de vida da OS: executada e não executada

- **Criticidade**: P1
- **Etapa OpenGSAN**: 2 — Núcleo operacional
- **Conceitos relacionados**: OS (C1)
- **Objetivo**: caracterizar os marcos e estados da OS até os dois desfechos possíveis
- **Pré-condições**: OS gerada por CEN-ATE-002 V2; tipo de serviço SRV-01 (cobrado)
- **Entrada**: V1 — pendente → aguardando liberação → em execução → **encerrada executada**; V2 — pendente → **encerrada não executada**, com motivo
- **Operação GSAN**: emitir, liberar, executar e encerrar OS
- **Operação conceitual OpenGSAN**: conduzir a execução
- **Observações semânticas**: sequência de situações · marcos (geração, emissão, execução, encerramento) · motivo em V2 · efeito sobre a cobrança do serviço em V2
- **Localizadores GSAN**: situação e datas da OS
- **Resultado semântico esperado**: 🟢 **encerrada não executada** é desfecho próprio, com motivo, distinto de cancelamento. ❔ O efeito de V2 sobre a cobrança do serviço **a capturar**
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: timestamps
- **Divergência permitida**: nenhuma
- **Oráculo**: **1**
- **Gate que este cenário protege**: 2 → 3
- **Evidência**: [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 itens 10 e 11

---

## CEN-ATE-007 — Efeito cadastral da OS aplicado pelo dono

- **Criticidade**: P0
- **Etapa OpenGSAN**: 2 — Núcleo operacional
- **Conceitos relacionados**: efeito da OS (C2 — o dono aplica) · situação da ligação (C2)
- **Objetivo**: caracterizar o efeito da execução sobre a ligação — **o contrato central do OpenGSAN**
- **Pré-condições**: IMV-01 com água **factível**; IMV-15 com água **cortada** e débito quitado
- **Entrada**: V1 — OS de ligação de água executada pela operação "Efetuar ligação"; V2 — OS de religação executada; V3 — OS de ligação de esgoto executada
- **Operação GSAN**: operações "Efetuar ligação/religação…", que atualizam a ligação e **marcam a OS**
- **Operação conceitual OpenGSAN**: a OS **solicita** o efeito; o Cadastro valida, aplica e responde
- **Observações semânticas**: situação da ligação antes/depois · datas registradas na ligação · indicadores na OS de que a atualização ocorreu · situação derivada do imóvel depois
- **Localizadores GSAN**: `orse_iccomercialatualizado`; `orse_icatualizaagua`, `orse_icatualizaesgoto`; situação da ligação
- **Resultado semântico esperado**: 🟢 o efeito **não é gatilho automático do encerramento** — vem da operação específica. O **estado final** da ligação e da situação derivada deve ser **idêntico** no OpenGSAN
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: nenhuma sobre situação e datas de negócio
- **Divergência permitida**: nenhuma — ⚠️ a mudança é de **quem aplica**, não do resultado
- **Oráculo**: **1** — por mapeamento semântico
- **Gate que este cenário protege**: 2 → 3 — *efeito aplicado pelo dono*
- **Evidência**: [`modulos/atendimento.md`](../../modulos/atendimento.md) §16 e §29 itens 13 e 15; [`modulos/cadastro.md`](../../modulos/cadastro.md) §5 regra 7

⚠️ **Complemento do gate, fora do oráculo 1**: no OpenGSAN, uma tentativa de escrita **direta** do Atendimento no estado da ligação deve ser **reprovada pela verificação de fronteira** — isso é teste do próprio OpenGSAN, sem equivalente a comparar.

---

## CEN-ATE-008 — Efeito financeiro do serviço executado

- **Criticidade**: P0
- **Etapa OpenGSAN**: 4 — Financeiro individual
- **Conceitos relacionados**: tipo de serviço (C1) · débito a cobrar (C1) · efeito da OS (C2)
- **Objetivo**: caracterizar o débito gerado pela execução de serviço cobrado
- **Pré-condições**: SRV-01 (cobrado, com parcelamento em N parcelas); SRV-02 (não cobrado, com motivo); SRV-03 (permite alterar valor)
- **Entrada**: V1 — execução de SRV-01; V2 — execução de SRV-02; V3 — execução de SRV-03 com valor alterado; V4 — SRV-01 com percentual de cobrança parcial
- **Operação GSAN**: `gerarDebitoOrdemServico`
- **Operação conceitual OpenGSAN**: a OS solicita o lançamento; o Faturamento cria o débito
- **Observações semânticas**: débito criado (sim/não) · tipo de débito · valor total · número de parcelas · valor de cada parcela · motivo de não cobrança · valor alterado
- **Localizadores GSAN**: `gerarDebitoOrdemServico`; `indicadorPermiteAlterarValor`; `calcularValorPrestacao` (🟢 **HALF_UP**, `ControladorFaturamentoFINAL:7027–7056`)
- **Resultado semântico esperado**: V1 — débito com N parcelas cuja soma é o valor do serviço. V2 — nenhum débito, motivo registrado. V3 — débito com o valor alterado. ⚠️ **A distribuição de centavos entre parcelas é regra de resultado** — capturar, não recalcular
- **Baseline concreta do legado**: ⬜ A CAPTURAR NA FASE 2
- **Normalizações**: identificadores técnicos dos lançamentos
- **Divergência permitida**: nenhuma
- **Oráculo**: **1** — igualdade **ao centavo**
- **Gate que este cenário protege**: 4 → 5
- **Evidência**: [`modulos/atendimento.md`](../../modulos/atendimento.md) §29 itens 16 e 17; cobertura da política **HALF_UP** (ver índice)
