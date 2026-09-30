# Matriz de caracterização — Fase 2

> ⚠️ **Gerado por script** — `ambiente-referencia/baselines/ferramentas/caracterizacao.py gerar`, a partir das
> especificações em [`../cenarios/`](../cenarios/) e dos ajustes justificados em
> [`caracterizacao-ajustes.tsv`](../../../../ambiente-referencia/baselines/caracterizacao-ajustes.tsv). Não editar à mão.
> Critérios e leitura: [`fase2-caracterizacao-baselines.md`](fase2-caracterizacao-baselines.md) §3.

## Totais

| Classe | Significado | Cenários | P0 | P1 | P2 | Massas iniciais |
| ------ | ----------- | -------- | -- | -- | -- | --------------- |
| **A** | baseline GSAN necessária | 74 | 42 | 32 | 0 | 221 |
| **B** | evidência estática suficiente | 1 | 1 | 0 | 0 | 0 |
| **C** | divergência aprovada | 6 | 2 | 4 | 0 | 13 |
| **N** | requisito nativo | 22 | 10 | 12 | 0 | 0 |
| **Total** | | **103** | 55 | 48 | 0 | **234** |

**Precisam de execução do GSAN**: 80 cenários — 74 como oráculo (A) e 6 só como registro da divergência (C). Variações declaradas nas especificações: 326.

## Por domínio

| Domínio | A | B | C | N | Massas iniciais (A) |
| ------- | - | - | - | - | ------------------- |
| Arrecadação | 11 | 0 | 0 | 2 | 33 |
| Batch, relatórios e integrações | 11 | 0 | 3 | 0 | 23 |
| Cadastro e atendimento | 13 | 0 | 0 | 0 | 28 |
| Cobrança | 7 | 0 | 0 | 0 | 24 |
| Faturamento | 11 | 0 | 0 | 1 | 37 |
| Financeiro e operacional | 8 | 0 | 0 | 0 | 32 |
| Fiscal | 0 | 0 | 0 | 3 | 0 |
| Micromedição | 5 | 0 | 0 | 0 | 22 |
| Modularidade | 0 | 0 | 0 | 7 | 0 |
| PCM e paradas | 0 | 0 | 0 | 4 | 0 |
| Regulatório | 0 | 0 | 0 | 5 | 0 |
| Segurança | 8 | 1 | 3 | 0 | 22 |

## Matriz

| Cenário | Domínio | Prioridade | Classe | Tipo de oráculo | Precisa execução GSAN? | Massas iniciais | Justificativa |
| ------- | ------- | ---------- | ------ | --------------- | ---------------------- | --------------- | ------------- |
| [CEN-ARR-001](../cenarios/arrecadacao.md#cen-arr-001--recepção-do-movimento-do-arrecadador) | Arrecadação | P1 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-002](../cenarios/arrecadacao.md#cen-arr-002--classificação-contra-conta-vigente-por-valor-e-prazo) | Arrecadação | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-003](../cenarios/arrecadacao.md#cen-arr-003--classificação-em-situação-especial-nada-é-descartado) | Arrecadação | P0 | **A** | 1 | Sim | 5 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-004](../cenarios/arrecadacao.md#cen-arr-004--pagamento-em-duplicidade-e-devolução) | Arrecadação | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-005](../cenarios/arrecadacao.md#cen-arr-005--pagamento-de-conta-retificada-ou-arquivada) | Arrecadação | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-006](../cenarios/arrecadacao.md#cen-arr-006--identidade-do-pagamento-no-arquivamento) | Arrecadação | P0 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-ARR-007](../cenarios/arrecadacao.md#cen-arr-007--conciliação-por-aviso-bancário) | Arrecadação | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-008](../cenarios/arrecadacao.md#cen-arr-008--pagamento-de-entrada-e-de-prestação-de-parcelamento) | Arrecadação | P0 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-009](../cenarios/arrecadacao.md#cen-arr-009--débito-automático) | Arrecadação | P1 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-010](../cenarios/arrecadacao.md#cen-arr-010--encerramento-mensal-da-arrecadação) | Arrecadação | P0 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-ARR-011](../cenarios/arrecadacao.md#cen-arr-011--pagamento-de-fatura-do-cliente-responsável) | Arrecadação | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ARR-012](../cenarios/arrecadacao.md#cen-arr-012--cobrança-pix-vinculada-ao-documento-confirmação-idempotente-e-conciliação) | Arrecadação | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-ARR-013](../cenarios/arrecadacao.md#cen-arr-013--pix-automático-autorização-cobrança-recorrente-retentativa-e-cancelamento) | Arrecadação | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-BAT-001](../cenarios/batch-relatorios-integracoes.md#cen-bat-001--execução-de-processo-em-três-níveis-com-autorização) | Batch, relatórios e integrações | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-BAT-002](../cenarios/batch-relatorios-integracoes.md#cen-bat-002--falha-de-unidade-retomada-e-reprocessamento) | Batch, relatórios e integrações | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-BAT-003](../cenarios/batch-relatorios-integracoes.md#cen-bat-003--atomicidade-dentro-da-unidade) | Batch, relatórios e integrações | P0 | **A** | PENDENTE | Sim | 1 | oráculo decidido pela própria baseline; entrada única (sem variações declaradas); a própria baseline decide entre oráculo 1 e divergência |
| [CEN-BAT-004](../cenarios/batch-relatorios-integracoes.md#cen-bat-004--execução-duplicada-com-os-mesmos-parâmetros) | Batch, relatórios e integrações | P0 | **A** | PENDENTE | Sim | 2 | oráculo decidido pela própria baseline; a própria baseline decide entre oráculo 1 e divergência |
| [CEN-BAT-005](../cenarios/batch-relatorios-integracoes.md#cen-bat-005--faturamento-em-lote-igual-à-soma-dos-individuais) | Batch, relatórios e integrações | P0 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-REL-001](../cenarios/batch-relatorios-integracoes.md#cen-rel-001--acesso-ao-artefato-de-relatório) | Batch, relatórios e integrações | P0 | **A** | 1+2 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; variações sob oráculo 2 (só registro): V2, V3 |
| [CEN-REL-002](../cenarios/batch-relatorios-integracoes.md#cen-rel-002--resumos-de-faturamento-e-de-arrecadação-por-competência) | Batch, relatórios e integrações | P1 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-INT-001](../cenarios/batch-relatorios-integracoes.md#cen-int-001--coleta-móvel-de-leitura) | Batch, relatórios e integrações | P0 | **A** | 1+2 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN; variações sob oráculo 2 (só registro): V4 |
| [CEN-INT-002](../cenarios/batch-relatorios-integracoes.md#cen-int-002--telemetria) | Batch, relatórios e integrações | P1 | **A** | 1+2 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN; variações sob oráculo 2 (só registro): V3 |
| [CEN-INT-003](../cenarios/batch-relatorios-integracoes.md#cen-int-003--api-de-ordem-de-serviço) | Batch, relatórios e integrações | P0 | **C** | 2 | Sim — só registro do comportamento de que se diverge (não é oráculo) | 3 | esperado vem da divergência aprovada; igualdade com o legado seria o defeito |
| [CEN-INT-004](../cenarios/batch-relatorios-integracoes.md#cen-int-004--integração-com-sistema-parceiro-por-banco-compartilhado-upasam) | Batch, relatórios e integrações | P1 | **A** | 1+2 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN; variações sob oráculo 2 (só registro): V2, V4, V5 |
| [CEN-INT-005](../cenarios/batch-relatorios-integracoes.md#cen-int-005--api-de-pagamento-autenticação-do-chamador) | Batch, relatórios e integrações | P0 | **C** | 2 | Sim — só registro do comportamento de que se diverge (não é oráculo) | 3 | esperado vem da divergência aprovada; igualdade com o legado seria o defeito |
| [CEN-INT-006](../cenarios/batch-relatorios-integracoes.md#cen-int-006--sms-por-tipo-de-mensagem) | Batch, relatórios e integrações | P1 | **C** | 2 | Sim — só registro do comportamento de que se diverge (não é oráculo) | 1 | esperado vem da divergência aprovada; igualdade com o legado seria o defeito |
| [CEN-INT-007](../cenarios/batch-relatorios-integracoes.md#cen-int-007--requisição-gis-assinada) | Batch, relatórios e integrações | P1 | **A** | 1+2 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN; variações sob oráculo 2 (só registro): V4 |
| [CEN-CAD-001](../cenarios/cadastro-atendimento.md#cen-cad-001--matrícula-e-dígito-verificador) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-CAD-002](../cenarios/cadastro-atendimento.md#cen-cad-002--cliente--imóvel-por-papel-e-vigência) | Cadastro e atendimento | P0 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-CAD-003](../cenarios/cadastro-atendimento.md#cen-cad-003--composição-de-economias-por-categoria-e-subcategoria) | Cadastro e atendimento | P0 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-CAD-004](../cenarios/cadastro-atendimento.md#cen-cad-004--situações-da-ligação-faturabilidade-e-situação-derivada-do-imóvel) | Cadastro e atendimento | P0 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-CAD-005](../cenarios/cadastro-atendimento.md#cen-cad-005--rotas-por-finalidade) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-ATE-001](../cenarios/cadastro-atendimento.md#cen-ate-001--consulta-de-imóvel-e-cliente-sob-autorização) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-ATE-002](../cenarios/cadastro-atendimento.md#cen-ate-002--abertura-de-ra-governada-pela-especificação) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ATE-003](../cenarios/cadastro-atendimento.md#cen-ate-003--encerramento-de-ra-sem-os-e-encerramento-automático) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ATE-004](../cenarios/cadastro-atendimento.md#cen-ate-004--tramitação-entre-unidades) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ATE-005](../cenarios/cadastro-atendimento.md#cen-ate-005--prazo-espera-e-reiteração) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ATE-006](../cenarios/cadastro-atendimento.md#cen-ate-006--ciclo-de-vida-da-os-executada-e-não-executada) | Cadastro e atendimento | P1 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ATE-007](../cenarios/cadastro-atendimento.md#cen-ate-007--efeito-cadastral-da-os-aplicado-pelo-dono) | Cadastro e atendimento | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-ATE-008](../cenarios/cadastro-atendimento.md#cen-ate-008--efeito-financeiro-do-serviço-executado) | Cadastro e atendimento | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-COB-001](../cenarios/cobranca.md#cen-cob-001--posição-de-dívida-derivada) | Cobrança | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-COB-002](../cenarios/cobranca.md#cen-cob-002--ação-de-cobrança-e-pagamento-antes-ou-depois-do-documento) | Cobrança | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-COB-003](../cenarios/cobranca.md#cen-cob-003--corte-e-religação) | Cobrança | P1 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-COB-004](../cenarios/cobranca.md#cen-cob-004--efetuar-parcelamento) | Cobrança | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-COB-005](../cenarios/cobranca.md#cen-cob-005--desfazimento-e-reparcelamento) | Cobrança | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-COB-006](../cenarios/cobranca.md#cen-cob-006--negativação-e-exclusão) | Cobrança | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-COB-007](../cenarios/cobranca.md#cen-cob-007--retificação-cancelamento-e-prescrição-de-conta-já-em-cobrança) | Cobrança | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-001](../cenarios/faturamento.md#cen-fat-001--valor-de-água-por-economias-categorias-e-origem-do-consumo) | Faturamento | P0 | **A** | 1 | Sim | 7 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-002](../cenarios/faturamento.md#cen-fat-002--mudança-de-vigência-tarifária-dentro-do-período-de-leitura) | Faturamento | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-003](../cenarios/faturamento.md#cen-fat-003--esgoto-percentual-padrão-alternativo-e-poço) | Faturamento | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-004](../cenarios/faturamento.md#cen-fat-004--débitos-cobrados-e-créditos-realizados-na-conta) | Faturamento | P0 | **A** | 1 | Sim | 5 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-005](../cenarios/faturamento.md#cen-fat-005--impostos-deduzidos) | Faturamento | P0 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-006](../cenarios/faturamento.md#cen-fat-006--rateio-de-micro-condomínio) | Faturamento | P0 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-007](../cenarios/faturamento.md#cen-fat-007--retificação-de-conta) | Faturamento | P0 | **A** | 1+2 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN; oráculo 2 só em observáveis, não em variações |
| [CEN-FAT-008](../cenarios/faturamento.md#cen-fat-008--cancelamento-e-prescrição) | Faturamento | P0 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-009](../cenarios/faturamento.md#cen-fat-009--emissão-pré-faturamento-linhas-tarifárias-e-vencimento) | Faturamento | P1 | **A** | 1 | Sim | 7 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FAT-010](../cenarios/faturamento.md#cen-fat-010--referência-de-faturamento--referência-contábil) | Faturamento | P1 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-FAT-011](../cenarios/faturamento.md#cen-fat-011--imóvel-sem-consumo-anterior-consumo-de-reserva) | Faturamento | P1 | **A** | 1+2 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; variações sob oráculo 2 (só registro): V2 |
| [CEN-FAT-012](../cenarios/faturamento.md#cen-fat-012--tarifa-social-concessão-automática-desconto-e-perda-de-elegibilidade) | Faturamento | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-FIN-001](../cenarios/financeiro-operacional.md#cen-fin-001--lançamentos-contábeis-da-competência-por-origem) | Financeiro e operacional | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FIN-002](../cenarios/financeiro-operacional.md#cen-fin-002--baixa-contábil-de-devedores-duvidosos-e-recuperação) | Financeiro e operacional | P0 | **A** | 1 | Sim | 4 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FIN-003](../cenarios/financeiro-operacional.md#cen-fin-003--regeração-da-contabilização-de-uma-competência) | Financeiro e operacional | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FIN-004](../cenarios/financeiro-operacional.md#cen-fin-004--volumes-consumidos-e-não-faturados-da-competência) | Financeiro e operacional | P1 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-FIN-005](../cenarios/financeiro-operacional.md#cen-fin-005--exportação-dos-lançamentos-para-o-sistema-contábil) | Financeiro e operacional | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-OPE-001](../cenarios/financeiro-operacional.md#cen-ope-001--localização-operacional-da-demanda) | Financeiro e operacional | P1 | **A** | 1 | Sim | 5 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-OPE-002](../cenarios/financeiro-operacional.md#cen-ope-002--ra-de-falta-de-água-confrontado-com-a-programação) | Financeiro e operacional | P1 | **A** | 1 | Sim | 5 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-OPE-003](../cenarios/financeiro-operacional.md#cen-ope-003--qualidade-da-água-no-documento-emitido) | Financeiro e operacional | P1 | **A** | 1 · PENDENTE | Sim | 6 | oráculo 1: o resultado concreto só existe executando o GSAN; em V5, a própria baseline decide entre oráculo 1 e divergência |
| [CEN-FIS-001](../cenarios/fiscal.md#cen-fis-001--emissão-da-nfag-a-partir-da-conta-autorização-e-rejeição) | Fiscal | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-FIS-002](../cenarios/fiscal.md#cen-fis-002--contingência-e-transmissão-posterior) | Fiscal | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-FIS-003](../cenarios/fiscal.md#cen-fis-003--retificação-e-cancelamento-de-conta-com-nfag-autorizada) | Fiscal | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-MIC-001](../cenarios/micromedicao.md#cen-mic-001--consumo-da-referência-por-situação-de-leitura) | Micromedição | P0 | **A** | 1 | Sim | 5 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-MIC-002](../cenarios/micromedicao.md#cen-mic-002--consumo-mínimo-e-precedência-de-overrides) | Micromedição | P0 | **A** | 1 | Sim | 6 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-MIC-003](../cenarios/micromedicao.md#cen-mic-003--troca-de-hidrômetro-na-referência) | Micromedição | P0 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-MIC-004](../cenarios/micromedicao.md#cen-mic-004--anormalidades-virada-de-hidrômetro-e-limiares-de-consumo) | Micromedição | P1 | **A** | 1 | Sim | 5 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-MIC-005](../cenarios/micromedicao.md#cen-mic-005--leitura-informada--leitura-de-faturamento) | Micromedição | P1 | **A** | 1 | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-MOD-001](../cenarios/modularidade.md#cen-mod-001--sinisa-inicia-somente-com-a-platform) | Modularidade | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-MOD-002](../cenarios/modularidade.md#cen-mod-002--atendimento-opera-sem-commercial-com-referência-externa-e-snapshot) | Modularidade | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-MOD-003](../cenarios/modularidade.md#cen-mod-003--commercial-fatura-com-medição-externa) | Modularidade | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-MOD-004](../cenarios/modularidade.md#cen-mod-004--assets-fecha-o-ciclo-de-manutenção-com-os-externa) | Modularidade | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-MOD-005](../cenarios/modularidade.md#cen-mod-005--operations-opera-sem-networks) | Modularidade | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-MOD-006](../cenarios/modularidade.md#cen-mod-006--ativação-módulo-desligado-não-registra-nada-atualização-não-ativa-módulo-perfil-inválido-falha-cedo) | Modularidade | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-MOD-007](../cenarios/modularidade.md#cen-mod-007--dependência-opcional-ausente-não-é-importada-nem-acessada) | Modularidade | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-PCM-001](../cenarios/pcm-paradas.md#cen-pcm-001--necessidade-programada-gera-os-sem-duplicar) | PCM e paradas | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-PAR-001](../cenarios/pcm-paradas.md#cen-par-001--parada-programada-impacto-registrado-e-comunicação-prévia) | PCM e paradas | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-PAR-002](../cenarios/pcm-paradas.md#cen-par-002--parada-emergencial-até-a-normalização) | PCM e paradas | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-PAR-003](../cenarios/pcm-paradas.md#cen-par-003--normalização-previsões-revisadas-e-realizado) | PCM e paradas | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-REG-001](../cenarios/regulatorio.md#cen-reg-001--declaração-manual-rastreável-e-retificação-sem-sobrescrever) | Regulatório | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-REG-002](../cenarios/regulatorio.md#cen-reg-002--mudança-de-glossário-preserva-a-declaração-anterior) | Regulatório | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-REG-003](../cenarios/regulatorio.md#cen-reg-003--métrica-interna-não-vira-valor-sinisa-implicitamente) | Regulatório | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-REG-004](../cenarios/regulatorio.md#cen-reg-004--mapeamento-futuro-nunca-ativado-automaticamente) | Regulatório | P0 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-REG-005](../cenarios/regulatorio.md#cen-reg-005--override-futuro-auditado) | Regulatório | P1 | **N** | N | Não — sem equivalente no GSAN público | 0 | esperado derivado da norma, do leiaute ou da decisão registrada — nunca do legado |
| [CEN-SEG-001](../cenarios/seguranca.md#cen-seg-001--autenticação-legítima-e-forma-da-credencial-armazenada) | Segurança | P0 | **A** | 1+2 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas); oráculo 2 só em observáveis, não em variações |
| [CEN-SEG-002](../cenarios/seguranca.md#cen-seg-002--credencial-inválida-e-bloqueio-por-tentativas) | Segurança | P0 | **A** | 1 · PENDENTE | Sim | 3 | oráculo 1: o resultado concreto só existe executando o GSAN; decisão pendente em V3 — capturar informa a decisão |
| [CEN-SEG-003](../cenarios/seguranca.md#cen-seg-003--ciclo-de-vida-da-credencial-situação-expiração-e-política-de-senha) | Segurança | P1 | **A** | 1 | Sim | 6 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-SEG-004](../cenarios/seguranca.md#cen-seg-004--matriz-de-autorização-concessão-por-união-de-grupos-e-negação) | Segurança | P0 | **A** | 1 | Sim | 7 | oráculo 1: o resultado concreto só existe executando o GSAN |
| [CEN-SEG-005](../cenarios/seguranca.md#cen-seg-005--rota-excepcionada-por-substring-no-filtro-de-autorização) | Segurança | P0 | **A** | PENDENTE | Sim | 1 | oráculo decidido pela própria baseline; entrada única (sem variações declaradas); a própria baseline decide entre oráculo 1 e divergência |
| [CEN-SEG-006](../cenarios/seguranca.md#cen-seg-006--auditoria-em-dois-níveis) | Segurança | P0 | **A** | 1 | Sim | 2 | oráculo 1: o resultado concreto só existe executando o GSAN; não comparadas: V3 |
| [CEN-SEG-007](../cenarios/seguranca.md#cen-seg-007--abrangência-territorial-onde-o-legado-a-verifica) | Segurança | P0 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-SEG-008](../cenarios/seguranca.md#cen-seg-008--permissão-especial-nomeada) | Segurança | P1 | **A** | 1 | Sim | 1 | oráculo 1: o resultado concreto só existe executando o GSAN; entrada única (sem variações declaradas) |
| [CEN-SEG-009](../cenarios/seguranca.md#cen-seg-009--token-de-acesso-dos-servlets-auxiliares) | Segurança | P1 | **C** | 2 | Sim — só registro do comportamento de que se diverge (não é oráculo) | 1 | esperado vem da divergência aprovada; igualdade com o legado seria o defeito |
| [CEN-SEG-010](../cenarios/seguranca.md#cen-seg-010--cadeia-de-filtros-sem-elo-decorativo) | Segurança | P1 | **C** | 2 | Sim — só registro do comportamento de que se diverge (não é oráculo) | 2 | esperado vem da divergência aprovada; igualdade com o legado seria o defeito |
| [CEN-SEG-011](../cenarios/seguranca.md#cen-seg-011--nenhuma-credencial-em-artefato-versionado) | Segurança | P0 | **B** | 2 | Não — o observável é artefato versionado, já lido | 0 | baseline JÁ COMPROVADA na Fase 0: ler o artefato é observá-lo; oráculo 2: o OpenGSAN deve divergir |
| [CEN-SEG-012](../cenarios/seguranca.md#cen-seg-012--sessão-e-requisição-forjada) | Segurança | P1 | **C** | 2 | Sim — só registro do comportamento de que se diverge (não é oráculo) | 3 | esperado vem da divergência aprovada; igualdade com o legado seria o defeito |
