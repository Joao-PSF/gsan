# Completude Funcional e Regulatória — Auditoria Final da Fase 0

> **Procedência**: auditoria final da Fase 0, 2026-09-29, `HEAD` de entrada `9993ac1`. Relatório e veredito em [`auditoria-final-fase0.md`](auditoria-final-fase0.md).
>
> **Pergunta**: *se começássemos a implementação amanhã, existe alguma obrigação, capacidade ou domínio fundamental de uma companhia moderna de água e esgoto que descobriríamos tarde demais porque a Fase 0 não o enxergou?*
>
> 🆕 **Adendo pós-Fase 0 (2026-09-29)** — notas datadas nas linhas de SINISA, contingência operacional e NR 11 (§2, §3.1, §6, §10). O registro da auditoria **não foi reescrito**: as notas dizem o que mudou depois, e por quê ([ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md), [`paradas-interrupcoes.md`](../dominio/paradas-interrupcoes.md)).
>
> ⚠️ **Não implementa, não modela, não escolhe fornecedor, leiaute, PSP, plataforma ou biblioteca.** Onde uma interpretação jurídica ou fiscal não pôde ser confirmada, a linha diz `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` — nunca uma conclusão presumida.

---

## 1. Método e fontes

**Hierarquia de evidência** — para comportamento histórico do GSAN: código público → banco versionado → documentação oficial do GSAN → wiki/evoluções → instalação customizada. Para obrigação atual: lei/decreto → regulamento → ANA → Receita/Portal DF-e → Banco Central → Ministério da Saúde → Ministério das Cidades → regulador competente. Blogs, fornecedores e consultorias serviram **só para localizar termos**; onde há fonte oficial, é ela que sustenta a conclusão.

**Classes de lacuna**: **L0** já coberto · **L1** coberto parcialmente · **L2** capacidade nova necessária · **L3** evolução futura · **L4** integração/adapter · **L5** específica/local · **L6** não aplicável.

**Resultado por tema**: `JÁ COBERTO` · `CORRIGIDO` (a lacuna era de documento e foi corrigida) · `INCORPORADO` (capacidade nova entrou no desenho) · `DEFERIDO` (evolução registrada, sem bloquear) · `NÃO APLICÁVEL` · `PENDENTE POR FONTE` (depende de norma que não pôde ser lida ou confirmada).

⚠️ **Limitação desta execução**: a política de rede da sessão **bloqueou a leitura direta** de `www.gov.br`, `www.planalto.gov.br`, `dfe-portal.svrs.rs.gov.br` e de cópias da NR 11 em sites de agências. As fontes oficiais foram lidas por **resumos de busca sobre as próprias páginas oficiais**; onde só havia fonte secundária, a certeza está rebaixada e a linha diz qual confirmação falta. **Data de consulta de todas as fontes: 2026-09-29.**

---

## 2. Matriz de completude

| Tema | Obrigação/capacidade | Fonte | Cobertura atual | Classificação | Dono | Ação |
| ---- | -------------------- | ----- | --------------- | ------------- | ---- | ---- |
| Fiscal | **NFAg (modelo 75)** — emissão, assinatura, autorização/rejeição, chave/série/número, eventos, DANFAG | LC 214/2025; Portal NFAg; Ato Conjunto RFB/CGIBS nº 4/2026; ATC nº 2/2026 | ❌ Catálogo 08 `EXIGE APROFUNDAMENTO`, H2; schema sem código; fora da ordem | **L2** | Fiscal (+ adapter em Integrações) | **INCORPORADO** — módulo e [mapa Fiscal](../modulos/fiscal.md); catálogo 08 → capacidade regulatória necessária, H1; Etapas 4 e 7; CEN-FIS-001 a 003 |
| Fiscal | **Conta ≠ documento fiscal**; fato tributável publicado pelo Faturamento | Decisão de fronteira | ⚠️ Hipótese 🟡 "se decorrer da conta" | **L2** | Faturamento (fato) · Fiscal (documento) | **INCORPORADO** — `fiscal.md` §3–§4; visão §19 e §27.2; mapa de domínio §12 |
| Fiscal | Determinação tributária IBS/CBS como política com vigência | LC 214/2025 | ❌ Ausente | **L2** | Fiscal | **INCORPORADO** — `fiscal.md` §8; tarifa bruta × líquida: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |
| Fiscal | **Devolução personalizada (cashback)** de IBS/CBS na cobrança de água e esgoto | LC 214/2025 | ❌ Ausente — **omissão fora do roteiro** | **L2** | Fiscal (regra) · Faturamento (apresentação) | **INCORPORADO** conceitualmente; parâmetros e mecânica **PENDENTE POR FONTE** |
| Fiscal | Contingência offline, transmissão posterior, reconciliação | MOC NFAg — Visão Geral | ❌ Ausente | **L2** | Fiscal | **INCORPORADO** — CEN-FIS-002; emissão em campo × contingência **PENDENTE POR FONTE** |
| Fiscal | Guarda fiscal ≠ artefato de relatório | MOC NFAg; legislação | ⚠️ Só o padrão T4 genérico | **L1** | Fiscal | **CORRIGIDO** — `fiscal.md` §6.2; prazo **PENDENTE POR FONTE** |
| Fiscal | NFAg × retificação e cancelamento da conta | MOC NFAg (substituição, cancelamento) | ❌ Ausente | **L2** | Faturamento (fato) · Fiscal (ação) | **INCORPORADO** — invariantes fixados (CEN-FIS-003); regra **PENDENTE POR FONTE** |
| Fiscal | Vinculação pagamento–documento fiscal (*split payment*) | NT 2026.001 (Portal NF-e) | ❌ Ausente | **L4** | Arrecadação (fato) · Fiscal (evento) · Integrações | **INCORPORADO** como fronteira; aplicabilidade à NFAg **PENDENTE POR FONTE** |
| Fiscal | Faturamento conjunto / por terceiros (outros serviços de saneamento na conta) | NR ANA 13/2025; MOC NFAg | ⚠️ Item de terceiro como débito a cobrar; sem reflexo fiscal | **L1** | Faturamento (item) · Fiscal (evento) | **CORRIGIDO** — adendo do Faturamento; `fiscal.md` §5 |
| Obrigações acessórias | SPED do legado | Legado (customização em banco) | ⚠️ Catálogo 09 `EXIGE APROFUNDAMENTO` | **L4** | ERP — dados por Integrações | **CORRIGIDO** — catálogo 09 → integração |
| Obrigações acessórias | DeRE | Comunicado Conjunto RFB/CGIBS (dez/2025) | — | **L6** | — | **NÃO APLICÁVEL** — prevista para regimes específicos que não incluem saneamento |
| Apuração | Apuração de IBS/CBS | LC 214/2025 | — | **L6** | Contribuinte/ERP | **NÃO APLICÁVEL** ao OpenGSAN — ele entrega o documento fiscal |
| Contabilização | Fatos fiscais na contabilização, sem duplicar valores | — | ⚠️ Só fatos comerciais e financeiros | **L1** | Contabilização | **CORRIGIDO** — `fiscal.md` §9; adendo do mapa |
| Pagamentos | **Contrato de meio de pagamento** — sem uma arrecadação por meio | — | ✅ Quatro momentos genéricos (visão §13) | **L1** | Arrecadação | **CORRIGIDO** — explicitado (§5; adendo da Arrecadação) |
| Pagamentos | Boleto registrado | Regras do sistema bancário (não pesquisadas nesta execução) | ✅ Catálogo 02, H1 — mas na Etapa 8 | **L1** | Arrecadação + Integrações | **CORRIGIDO** — Etapa 5 |
| Pagamentos | **Pix Cobrança** — `txid`, valor, vencimento, QR dinâmico, confirmação idempotente, conciliação, expiração, cancelamento, devolução | Banco Central — Regulamento Pix; Manual de Padrões para Iniciação; API Pix | ⚠️ Catálogo 01, H1, na Etapa 8 | **L1** | Arrecadação (Pagamentos) + Integrações (PSP) | **CORRIGIDO** — Etapa 5; CEN-ARR-012 |
| Pagamentos | **Pix Automático** — autorização, recorrência, agendamento, retentativa, cancelamento | Res. BCB 402 e 403/2024, 506/2025; Guia de implementação | ❌ Ausente | **L1** — generaliza a autorização do débito automático | Arrecadação + Integrações | **INCORPORADO** — catálogo N1; Etapa 6; CEN-ARR-013 |
| Pagamentos | Débito automático | Legado (C1) | ✅ CEN-ARR-009 | **L0** | Arrecadação | **JÁ COBERTO** — abstração comum mínima com o Pix Automático |
| Pagamentos | Cartão | Legado | ✅ Catálogo 03, opcional | **L0** | Arrecadação | **JÁ COBERTO** |
| Tarifa Social | Regra nacional — CadÚnico ou BPC; desconto até limite de volume | Lei 14.898/2024; NR ANA 13/2025 | ⚠️ Catálogo 11 genérico; no legado é extensão de companhia | **L1** | Faturamento (aplicação) · Cadastro (elegibilidade) | **CORRIGIDO** — catálogo 11 → capacidade regulatória necessária; CEN-FAT-012 |
| Tarifa Social | **Concessão automática** a partir de bases oficiais | Lei 14.898/2024 | ❌ *"CadÚnico/NIS é integração externa, não parte da capacidade"* | **L2** | Integrações (fonte) + Cadastro | **INCORPORADO** — adapter operante antes do gate 7 → operação; prestadores até 11/12/2026 (NR 13) |
| Tarifa Social | Perda, revisão, transição, comunicação, histórico | Lei 14.898/2024; regulador local | ⚠️ Perda por anormalidade (extensão do legado) | **L1** / **L5** | Cadastro + Notificação | **CORRIGIDO** — ciclo do benefício (§4); permanência/transição **PENDENTE POR FONTE** (regulador) |
| Tarifa Social | Proteção de dados de CadÚnico/BPC | LGPD; Lei 14.898/2024 | ⚠️ Genérico (achado 8) | **L1** | Segurança + Cadastro | **CORRIGIDO** — §7 |
| Condições gerais | NR 11 — ligação, medição, faturamento, cobrança, suspensão, religação, interrupção, atendimento | NR ANA 11/2024 | ⚠️ Comportamentos existem como regra-como-dado, sem referência à norma | **L1** / **L5** | Cada dono | **CORRIGIDO** — matriz §3.1; parâmetro regulado |
| Estrutura tarifária | Categorias, faixas, transparência | NR ANA 13/2025 | ✅ Tarifa versionada, categorias, faixas | **L0** | Faturamento | **JÁ COBERTO** |
| Reajuste e revisão tarifária | Receber a estrutura aprovada × calcular a revisão | Normas de referência da ANA sobre reajuste e revisão (não consultadas nesta execução) | ✅ Estrutura com vigência | **L0** (receber) · **L6** (calcular) | Faturamento | **JÁ COBERTO** — o OpenGSAN **aplica**; não é sistema regulador |
| Contexto institucional | Prestador · titular · instrumento de delegação · área de prestação · regulador · vigência · origem normativa | NR ANA 11/2024 (aplicação por entidade reguladora infranacional) | ❌ Implícito — uma companhia | **L2** — fundacional | Cadastro (área) + configuração da instalação | **INCORPORADO** — visão §23.2 e §27.3; **sem** decidir multi-tenancy |
| Qualidade | Informação mensal na conta e relatório anual ao consumidor | Decreto 5.440/2005 | ✅ CEN-OPE-003 | **L0** | Gestão Operacional + emissão | **JÁ COBERTO** — o DANFAG também exibe qualidade |
| Qualidade | Ciclo de controle — plano, amostra, parâmetro, resultado, limite, conformidade, ação | Portaria GM/MS 888/2021 | ⚠️ Qualidade por fonte para a conta; controle no satélite | **L3** | Gestão Operacional | **DEFERIDO** — catálogo N3; laboratório: opção C (§10) |
| Qualidade | Prestação ao SISAGUA | Portaria GM/MS 888/2021; SISAGUA | ❌ Ausente | **L4** | Integrações + Gestão Operacional | **DEFERIDO** — adapter, sem leiaute no domínio |
| Prestação de informações | **SINISA** anual — condição de acesso a recursos federais | Ministério das Cidades — SINISA; Portaria MCID nº 1.069 | ⚠️ Catálogo 22 (RA ao regulador) | **L1** | ~~Donos + Analytics + Integrações~~ 🆕 **Prestação de Informações** — Workspace SINISA **manual** (adendo pós-Fase 0, ADR-0009) | **CORRIGIDO** — capacidade transversal (§10); implementação **DEFERIDA** · 🆕 adendo: premissa de preenchimento derivado **corrigida** — [`sinisa.md`](../regulatorio/sinisa.md) |
| Metrologia | Verificação metrológica, selo, certificado, validade do medidor | Portarias Inmetro 155/2022 e 78/2022 | ⚠️ Hidrômetro sem verificação metrológica | **L3** | Micromedição + Ativos | **PENDENTE POR FONTE** — obrigações do **prestador** não confirmadas |
| Privacidade | Finalidade, retenção, bloqueio, anonimização, correção, exportação — por fluxo | LGPD | ⚠️ Genérico | **L1** | Segurança + donos | **CORRIGIDO** — §7 |
| Atendimento digital | 2ª via, débito, certidão, parcelamento, RA, acompanhamento | Legado (portal) | ✅ Catálogo 04; ADR-0007 §12 | **L0** | Canal digital | **JÁ COBERTO** |
| Comunicação | **Evento de negócio ≠ canal**; comunicações obrigatórias | NR 11; Lei 14.898/2024; Decreto 5.440/2005 | ⚠️ Padrão T2 genérico; SMS com defeito (D-13) | **L1** | Donos (evento) + Notificação (canal) | **CORRIGIDO** — §8 |
| Documentos e evidências | Armazenamento, metadados, dono, acesso, retenção, integridade | — | ⚠️ T1 e T4 como padrões soltos | **L1** | Plataforma + donos | **CORRIGIDO** — §6, sem ECM |
| Acessibilidade | WCAG no canal web; documento acessível; atendimento assistido | ADR-0007 §7.3 (WCAG 2.2 AA); legado (conta em braile) | ✅ ADR-0007; catálogo 07 | **L0** | Canais + emissão | **JÁ COBERTO** |
| Contingência operacional | Interrupção programada e emergencial, racionamento, área afetada, comunicação | NR ANA 11/2024 | ⚠️ Programação de abastecimento/manutenção × RA de falta d'água (CEN-OPE-002) | **L1** | Gestão Operacional + Notificação | **CORRIGIDO** — evento operacional (catálogo N2; adendo do Operacional) · 🆕 adendo pós-Fase 0: **Parada / interrupção operacional** — [`paradas-interrupcoes.md`](../dominio/paradas-interrupcoes.md) |
| Perdas | Dados para balanço hídrico | — | ⚠️ Volumes não faturados; índices degenerados no satélite | **L3** | Gestão Operacional + Analytics | **DEFERIDO** — dados necessários identificados (§10) |
| Telemetria | Ponto, série, unidade, qualidade da medição, origem, vínculo | — | ⚠️ Origem de leitura (catálogo 17) | **L3** | Micromedição · Ativos | **DEFERIDO** — requisitos mínimos registrados (§10) |
| Energia | Consumo e custo energético | — | ❌ Ausente | **L3** | Ativos + Analytics | **DEFERIDO** — atributo/indicador, sem módulo |
| Geoespacial | Sistema, rede, segmento, nó, área, zona, ramal, ligação física, ativo, imóvel | ADR-0008 | ✅ [`gis-redes-ativos.md`](../arquitetura/gis-redes-ativos.md) | **L0** | Redes/GIS · Ativos · Cadastro | **JÁ COBERTO** — ligação comercial × ramal físico **não bloqueia** a implementação inicial |
| Esgoto | Ligação, coleta, tratamento, volume, percentual, solução alternativa, bacia, ativos | Legado | ✅ Percentuais, poço, alternativo, divisão de esgoto e bacia (CEN-FAT-003, CEN-OPE-001) | **L0** · efluente **L3** | Cadastro · Faturamento · Gestão Operacional | **JÁ COBERTO** — qualidade do efluente fora do escopo atual |
| Resíduos e drenagem | Gestão desses serviços | — | — | **L6** | — | **NÃO APLICÁVEL** — a **cobrança conjunta** deles na conta é coberta (linha do faturamento conjunto) |
| Evoluções do GSAN | Funcionalidades posteriores ao código público | Documentação oficial do GSAN | ⚠️ Catálogo baseado no `gsan_comercial` | — | — | **PENDENTE POR FONTE** — portal oficial inacessível; nenhuma evolução nova encontrada por busca |
| Segurança | Status de D-01…D-16 | Registro de divergências | ⚠️ *Proposta* na tabela das aprovadas | — | Segurança | **CORRIGIDO** — aprovação registrada com a origem |
| Segurança | Achado 6 (cookie e CSRF) sem `D-xx` | ADR-0007 §9.4 | ⚠️ Tratado como "sem antecedente" | **L1** | Segurança | **CORRIGIDO** — D-18 + CEN-SEG-012 |
| Segurança | Negação na autorização — o "único bloqueio de dia 1" | Código (`ControladorAcessoSEJB`) | ⚠️ "Uso não observado" | **L0** — existe; preservar | Segurança | **CORRIGIDO** — uso comprovado; CEN-SEG-004 V7; CAND-05 |
| Segurança | Segredos conhecidos não transcritos (chave de SMS, `dblink`) | Achados 11 e 20 | ✅ Sem valor transcrito | **L0** | — | **JÁ COBERTO** — varredura em [`auditoria-final-fase0.md §14`](auditoria-final-fase0.md) |
| Nomenclatura | Conta × Fatura × documento fiscal × documento de cobrança × comprovante | Código (`Fatura`, `FaturaItem`, `ControladorArrecadacao`) | ⚠️ "Fatura" C5 (BLQ-04) | **L1** | Faturamento · Fiscal · Cobrança · Arrecadação | **CORRIGIDO** — [glossário](../dominio/glossario.md); CEN-ARR-011 |

---

## 3. Matriz de regulações

⚠️ **Só as pertinentes ao OpenGSAN** — não é catálogo do direito sanitário. Consulta: **2026-09-29**.

| Norma/Fonte | Versão/data | Tema | Impacto OpenGSAN | Coberto? |
| ----------- | ----------- | ---- | ---------------- | -------- |
| [LC 214/2025](https://www.planalto.gov.br/ccivil_03/leis/lcp/lcp214.htm) | 16/01/2025 | IBS/CBS; documentos fiscais; devolução personalizada | Módulo Fiscal; determinação tributária; cashback | ✅ Conceitual — parâmetros `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |
| [Ato Conjunto RFB/CGIBS nº 4](https://www.gov.br/receitafederal/pt-br/assuntos/noticias/2026/julho/receita-federal-e-comite-gestor-do-ibs-publicam-o-cronograma-de-implementacao-dos-documentos-fiscais-eletronicos-da-reforma-tributaria-do-consumo) | 30/07/2026 | Cronograma dos documentos fiscais | Prioridade da NFAg | ✅ — data exata da NFAg `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |
| [Portal NFAg](https://dfe-portal.svrs.rs.gov.br/Nfag) — MOC Anexo I v1.00l, Anexo II v1.02; ATC nº 2/2026 | 24/08/2026 (ATC, por fonte secundária) | Leiaute, eventos, DANFAG, contingência | `fiscal.md` §5–§6 | ⚠️ Parcial — portal bloqueado; eventos a confirmar no MOC |
| [NT 2026.001 — Portal NF-e](https://www.nfe.fazenda.gov.br/portal/exibirArquivo.aspx?conteudo=k7zG06n5M6I%3D) | Produção 04/05/2026 (fonte secundária) | Vinculação pagamento–documento fiscal | Ponte Arrecadação ↔ Fiscal | ⚠️ Aplicabilidade à NFAg pendente |
| [Comunicado Conjunto RFB/CGIBS](https://www.gov.br/receitafederal/pt-br/assuntos/noticias/2025/dezembro/comunicado-conjunto) | Dez/2025 | DeRE | Nenhum — não se aplica a saneamento | ✅ Não aplicável |
| [Lei 14.898/2024](https://www2.camara.leg.br/legin/fed/lei/2024/lei-14898-13-junho-2024-795775-publicacaooriginal-172087-pl.html) | 13/06/2024 · vigência 11/12/2024 | Tarifa Social de Água e Esgoto | Benefício tarifário; concessão automática; CadÚnico/BPC | ✅ |
| [NR ANA 13/2025 — Resolução ANA nº 271](https://www.gov.br/ana/pt-br/legislacao/resolucoes/resolucoes-regulatorias/2025/271) | 21/11/2025 | Estrutura tarifária; Tarifa Social; cobrança conjunta | Parâmetro regulado; prazo dos prestadores 11/12/2026 | ✅ |
| [NR ANA 11/2024 — Resolução ANA nº 230](https://www.gov.br/ana/pt-br/legislacao/resolucoes/resolucoes-regulatorias/2024/230) | 18/12/2024 · entidades reguladoras até 20/05/2027 | Condições gerais da prestação | Matriz §3.1 | ⚠️ Por tema — texto integral não lido |
| [Pix Automático — Banco Central](https://www.bcb.gov.br/content/estabilidadefinanceira/pix/automatico/guia_pix_automatico.pdf) · Res. BCB 402 e 403/2024 · [Res. BCB 506/2025](https://www.legisweb.com.br/legislacao/?id=484161) | Lançamento 16/06/2025 | Recorrência | Autorização de pagamento recorrente | ✅ |
| [Manual de Padrões para Iniciação do Pix](https://www.bcb.gov.br/content/estabilidadefinanceira/pix/Regulamento_Pix/II_ManualdePadroesparaIniciacaodoPix.pdf) | v2.10.0 | Cobrança imediata e com vencimento | Pix Cobrança | ✅ |
| [Portaria GM/MS nº 888/2021](https://bvsms.saude.gov.br/bvs/saudelegis/gm/2021/prt0888_07_05_2021.html) (+ GM/MS 2.472/2021) | 04/05/2021 | Potabilidade; controle; SISAGUA | Ciclo de qualidade; adapter SISAGUA | ⚠️ Deferido |
| [Decreto 5.440/2005](https://www2.camara.leg.br/legin/fed/decret/2005/decreto-5440-4-maio-2005-536789-publicacaooriginal-27901-pe.html) | 04/05/2005 | Informação de qualidade ao consumidor | Qualidade na conta; relatório anual | ✅ |
| [SINISA — Ministério das Cidades](https://www.gov.br/cidades/pt-br/acesso-a-informacao/acoes-e-programas/saneamento/sinisa) · Portaria MCID nº 1.069 | Ciclo 2026: coleta 13/05–03/09/2026 | Prestação anual de informações | Capacidade transversal | ⚠️ Deferido |
| [Portaria Inmetro 155/2022](https://www.conaut.com.br/blog/nova-portaria-inmetro) · [Portaria Inmetro 78/2022](https://www.legisweb.com.br/legislacao/?id=429363) | 2022 | Medidores de água; verificação inicial e após reparo | Atributos metrológicos do equipamento | ⚠️ Pendente por fonte |
| LGPD — Lei 13.709/2018 | Vigente | Dados pessoais | Matriz por fluxo (§7) | ✅ |

### 3.1 Matriz de conformidade funcional — NR ANA 11/2024

🔴 **A NR 11 obriga as entidades reguladoras infranacionais** a editar atos com conteúdo mínimo; o prestador cumpre o ato do **seu** regulador. Por isso a maior parte das linhas é **parametrizável** ou **regra do regulador local** — e nunca `if estado == X`: é **parâmetro regulado** com vigência, contexto institucional e origem normativa ([visão §23.2](../dominio/visao-conceitual-opengsan.md)). ⚠️ Matriz **por tema** do conteúdo mínimo; a conferência artigo a artigo fica **pendente por fonte** (texto integral não lido nesta execução).

| Tema da NR 11 | Comportamento necessário | Módulo dono | Cobertura atual | Classificação |
| ------------- | ------------------------ | ----------- | --------------- | ------------- |
| Usuário e unidade usuária | Identificar usuário e unidade, titularidade e responsabilidade pelo pagamento | Cadastro | Cliente × imóvel por papel e vigência (CEN-CAD-002) | **COBERTO** |
| Ligação — pedido e execução | Solicitação, vistoria, execução com prazo | Atendimento + Cadastro | RA → OS → efeito aplicado pelo dono (CEN-ATE-007); prazos por especificação | **PARAMETRIZÁVEL** |
| Medição | Instalação, substituição, acesso ao medidor; recusa do usuário como motivo de suspensão | Micromedição + Atendimento | Instalação e troca (CEN-MIC-003); OS de hidrômetro | **COBERTO** |
| Leitura e periodicidade | Ciclo de leitura | Micromedição | Grupo e cronograma (C1) | **PARAMETRIZÁVEL** |
| Faturamento sem leitura | Média, mínimo, estimativa | Micromedição + Faturamento | Origem do consumo declarada (CEN-MIC-001/002) | **REGRA DO REGULADOR LOCAL** — parâmetros |
| Conteúdo da fatura | Informações mínimas ao usuário | Faturamento (emissão) + Fiscal (DANFAG) | Emissão com qualidade e tarifas; DANFAG impõe campos | **PARCIAL** — conteúdo a parametrizar por regulador |
| Vencimento | Datas e opções | Faturamento | Vencimento por grupo e preferência (CEN-FAT-009) | **PARAMETRIZÁVEL** |
| Cobrança e suspensão por inadimplência | Aviso prévio, prazos, vedações | Cobrança + Atendimento | Sequência aviso → corte parametrizada (CEN-COB-003) | **REGRA DO REGULADOR LOCAL** |
| Suspensão por irregularidade técnica | Ligação clandestina, religação à revelia, instalação deficiente | Atendimento + Cadastro | Situações da ligação e OS (CEN-CAD-004) | **COBERTO** |
| Religação normal e de urgência | Prazos e valores informados ao usuário | Atendimento + Cobrança | OS de religação; valor do serviço (CEN-ATE-008) | **REGRA DO REGULADOR LOCAL** |
| Interrupção programada | Comunicação prévia ao regulador e aos usuários | Gestão Operacional + Notificação | Programação × falta d'água (CEN-OPE-002); sem evento com área afetada | **PARCIAL** — evento operacional registrado (catálogo N2) · 🆕 adendo: Parada programada especificada (CEN-PAR-001) |
| Interrupção emergencial e racionamento | Registro, área afetada, comunicação | Gestão Operacional | ❌ Sem conceito explícito | **AUSENTE** → registrado como evolução (N2) · 🆕 adendo: Parada emergencial especificada (CEN-PAR-002); racionamento = **plano** que gera paradas |
| Atendimento | Canais, protocolo, prazos de resposta | Atendimento | RA com protocolo, especificação com prazo (CEN-ATE-005) | **COBERTO** · prazos **PARAMETRIZÁVEL** |
| Padrões de atendimento e informação ao regulador | Indicadores e dados ao regulador | Atendimento + prestação de informações | Dados complementares do RA ao regulador (catálogo 22) | **PARCIAL** |
| Obrigações do usuário | Violação de medidor, intervenção na ligação | Micromedição + Atendimento | Fiscalização de leitura e anormalidades | **COBERTO** |
| Faturamento de esgoto | Volume e percentual | Faturamento | Percentuais, alternativo, poço (CEN-FAT-003) | **COBERTO** |

---

## 4. Tarifa Social e benefício tarifário

🔴 **Não é só uma categoria.** A Lei 14.898/2024 fixou critério nacional (família no CadÚnico com renda per capita de até meio salário mínimo, ou com membro que recebe BPC), desconto na tarifa para a parcela de consumo até um limite de volume e **concessão automática** pelo prestador, sem requerimento, a partir das bases oficiais. A NR ANA 13/2025 incorporou as diretrizes e deu aos prestadores até **11/12/2026**.

```text
Benefício tarifário
├─ regra ..................... Faturamento — parâmetro regulado (vigência · contexto · origem normativa)
├─ fonte de elegibilidade .... Integrações — CadÚnico/BPC (adapter; leiaute fora do domínio)
├─ família beneficiária ...... Cadastro — vínculo pessoa/família ↔ unidade usuária
├─ unidade usuária ........... Cadastro
├─ concessão ................. Cadastro — automática, sem requerimento
├─ vigência · revisão ........ Cadastro — revisão periódica contra a base oficial
├─ perda ..................... Cadastro — evento de negócio
├─ período de transição ...... regra do regulador — PENDENTE POR FONTE
├─ comunicação ............... evento → Notificação (canal)
├─ histórico ................. Cadastro
└─ aplicação no cálculo ...... Faturamento — política de arredondamento nomeada
```

| Pergunta | Resposta |
| -------- | -------- |
| Precisa de módulo? | ❌ **Não**. Elegibilidade e vínculo no Cadastro, aplicação no Faturamento, fonte em Integrações, informação regulatória na capacidade transversal |
| E o legado? | Os programas nomeados e os campos sociais continuam **extensão de companhia** (catálogo §12); a regra nacional é **requisito nativo** (CEN-FAT-012) |
| E o cashback de IBS/CBS? | ⚠️ **Outro benefício, outro dono**: devolução de tributo (Fiscal), não benefício tarifário. Compartilham só a **fonte de elegibilidade** |
| Quando precisa estar pronto? | Regra e vínculo na Etapa 4; concessão automática operante **antes do gate 7 → operação** |

---

## 5. Pagamentos — meios como extensão

**Pergunta do roteiro**: *o modelo de Arrecadação suporta novos meios sem criar uma arrecadação por meio de pagamento?* — 🟢 **Sim.** Os quatro momentos (recepção → classificação → aplicação → conciliação) não mudam; o que varia é o **contrato de meio de pagamento**.

```text
Arrecadação
└─ Pagamentos — contrato de meio de pagamento
   ├─ Boleto registrado ... título registrado · retorno · baixa                          Etapa 5
   ├─ Pix Cobrança ........ cobrança vinculada ao documento · txid · QR dinâmico ·        Etapa 5
   │                        vencimento/expiração · confirmação idempotente · devolução
   ├─ Pix Automático ...... autorização de pagamento recorrente · agendamento ·          Etapa 6
   │                        tentativa/retentativa · liquidação · cancelamento
   ├─ Débito automático ... autorização de pagamento recorrente · movimento · retorno     Etapa 6 (C1)
   └─ Cartão .............. opcional                                                      posterior
```

| Ponto | Posição |
| ----- | ------- |
| **PIX pertence a quem?** | 🔴 **Arrecadação/Pagamentos.** Depende de conta + recebimento + PSP + conciliação — **não** do Portal, que só apresenta e aciona |
| **Pix Cobrança** | Cobrança vinculada ao documento; confirmação por notificação **ou** consulta, **idempotente**; o pagamento de cobrança expirada **não é descartado**; conciliação contra o PSP |
| **Pix Automático** | Autorização (jornadas do Regulamento), recorrência com status, vigência e limite; agendamento em janela antes da liquidação; retentativas; cancelamento com as regras do arranjo **lidas na fonte**, nunca codificadas no domínio |
| **Abstração comum** | *Autorização de pagamento recorrente* — quem autorizou, para qual unidade/conta, vigência, limite, estado. ⚠️ **Mínima**: débito automático e Pix Automático têm arranjos, participantes e regras diferentes e **não se fundem** |
| **PSP/banco** | Não escolhidos. Contrato de Integrações; chave Pix por ambiente, nunca constante |
| **Vinculação ao documento fiscal** | Fato de pagamento da Arrecadação; evento do Fiscal, se aplicável à NFAg — **PENDENTE POR FONTE** |

---

## 6. Documentos e evidências

🔵 **Capacidade transversal, sem ECM.** O mesmo problema aparece em muitos lugares — conta impressa, DANFAG, documento fiscal, relatório, foto de campo, documento do cliente, anexo de OS, artefato regulatório — e já estava registrado como padrões T1 e T4 do catálogo.

| Aspecto | Regra |
| ------- | ----- |
| **Dono** | O módulo do objeto de negócio a que o documento pertence — a capacidade guarda, não decide |
| **Metadados mínimos** | Tipo · objeto de negócio · autor · momento · localização quando aplicável · classe de retenção · integridade (resumo criptográfico) |
| **Acesso** | Por caso de uso autorizado — o padrão de D-03, nunca por identificador solto |
| **Armazenamento** | Fora do banco transacional (catálogo 25) — tecnologia não escolhida |

| Classe | Exemplo | Retenção | Mutabilidade |
| ------ | ------- | -------- | ------------ |
| **Legal/fiscal** | Documento fiscal autorizado, protocolo, eventos | Prazo legal — **PENDENTE POR FONTE** | Imutável |
| **Regenerável** | Conta impressa, DANFAG, relatório | Operacional | Regenerado a partir do dado |
| **Evidência** | Foto de campo, anexo de OS | Política da companhia | Imutável |
| **Pessoal** | Documento do cliente | Finalidade + LGPD (§7) | Correção pelo dono |
| **Regulatório** | O que foi prestado ao SINISA, SISAGUA, regulador — 🆕 declaração SINISA versionada, evidências e comprovantes ([`sinisa.md §13`](../regulatorio/sinisa.md#13-rastreabilidade-da-declaração)) | Rastreabilidade da informação prestada | Imutável |

---

## 7. Privacidade por fluxo sensível

⚠️ **Terminologia**: *dado pessoal* é o que identifica ou torna identificável uma pessoa natural; *dado pessoal sensível* é a categoria estrita do art. 5º, II, da LGPD. **Não se classifica tudo como sensível**. O que a tabela aponta, além da classe jurídica, é o **risco operacional**.

| Fluxo / dado | Classe | Risco operacional | Controle arquitetural necessário |
| ------------ | ------ | ----------------- | -------------------------------- |
| Cliente — nome, endereço | Pessoal | Médio | Escopo territorial por construção (D-17 proposta); auditoria de escrita |
| CPF | Pessoal | Alto | Mascaramento na interface; nunca em log; busca sem expor o valor completo |
| CNPJ | Não pessoal (salvo empresário individual) | Baixo | — |
| NIS · dados de CadÚnico · condição de BPC | Pessoal — ⚠️ BPC pode **revelar condição de saúde** (deficiência): tratar com o rigor de sensível; enquadramento jurídico `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` | **Muito alto** | **Finalidade específica** (benefício); **minimização** — guardar a elegibilidade e sua origem, não a ficha social; acesso restrito e **auditoria de leitura**; retenção atada ao benefício |
| Telefone · e-mail | Pessoal | Médio | Consentimento/finalidade de comunicação; exportação ao titular |
| Consumo e histórico | Pessoal (hábitos do domicílio) | Médio | Acesso por vínculo (cliente final) e por escopo (interno) |
| Pagamento — dados do pagador Pix, banco | Pessoal | Alto | Guardar só o necessário à conciliação; nunca em log |
| Documento fiscal (NFAg) | Pessoal — com base em **obrigação legal** | Alto | Guarda legal imutável; acesso restrito; o prazo legal prevalece sobre pedido de eliminação |
| Documentos e anexos do cliente | Pessoal — pode conter sensível | Alto | Classe *pessoal* (§6); correção e eliminação pelo dono |
| Fotos de campo | Pessoal **eventual** (pessoas, placas) | Médio | Evidência com acesso por caso de uso |
| Geolocalização — ocorrência, leiturista, dispositivo | Pessoal | Médio | Finalidade operacional declarada; retenção limitada |
| Usuários internos, sessões, trilhas | Pessoal | Médio | Auditoria sem conteúdo de negócio desnecessário |
| Logs | Não devem conter dado pessoal de cliente | — | Regra de fundação (Etapa 0) |
| Massas de teste | — | Alto se reais | Anonimização/pseudonimização obrigatória (regra permanente do projeto) |

🔵 **Necessidade arquitetural — sem sistema de LGPD**: registrar a **finalidade** por categoria de dado; **retenção por categoria**, com bloqueio ou anonimização ao expirar, **exceto** onde a guarda é legal (fiscal, financeira); **correção** pelo fluxo do dono (Cadastro); **exportação** dos dados do titular pelo canal digital ou pelo atendimento. ❌ **Não é módulo** — são regras da fundação e dos donos.

---

## 8. Comunicação ao usuário — evento de negócio × canal

🔴 **Evento de negócio pertence ao dono; canal pertence à Notificação; fornecedor pertence à Integração.** O defeito D-13 do legado — todo SMS com o texto errado — é o que acontece quando os três se misturam.

| Evento de negócio | Dono | Obrigatoriedade | Observação |
| ----------------- | ---- | --------------- | ---------- |
| Interrupção programada | Gestão Operacional | NR 11 — comunicação prévia ao regulador e aos usuários; antecedência definida pelo regulador | **Regra do regulador local** |
| Interrupção emergencial · racionamento | Gestão Operacional | NR 11 — conforme o regulador | Evento operacional com área afetada (N2) |
| Aviso de débito e de suspensão | Cobrança | NR 11 — aviso prévio conforme o regulador | Já é ação de cobrança parametrizada |
| Concessão e perda da Tarifa Social | Cadastro | Lei 14.898/2024; regulador | Prazos: **PENDENTE POR FONTE** |
| Reajuste tarifário | Faturamento | Publicidade conforme o regulador | Nova vigência do parâmetro regulado |
| Qualidade da água | Gestão Operacional | Decreto 5.440/2005 — na conta mensal, relatório anual, orientação em situação de risco | Já coberta na conta (CEN-OPE-003) |
| Vencimento próximo · confirmação de pagamento | Faturamento · Arrecadação | Prática de mercado | Opcional por companhia |
| Incidente de segurança com dados pessoais | Segurança | LGPD — comunicação de incidente | Processo da companhia; o sistema fornece a trilha |

**Canais**: SMS · e-mail · push · mensagem no portal · adapters futuros (inclusive aplicativos de mensagem) · conta impressa e DANFAG. ❌ Nenhum fornecedor entra no domínio.

---

## 9. Contexto institucional e vigência regulatória

Tratado na [visão conceitual §27.3](../dominio/visao-conceitual-opengsan.md): prestador, titular, instrumento de delegação, **área de prestação** (recorte territorial — Cadastro), entidade reguladora e **parâmetro regulado** (vigência, contexto e origem normativa) em tarifa, benefício, fiscal, atendimento e faturamento. 🔴 **Regras variam por contexto institucional sem fork** — e **sem** decidir multi-tenancy, que continua aberta.

**Reajuste e revisão tarifária** — o OpenGSAN **recebe e aplica** a estrutura aprovada, com vigência e origem normativa; **não calcula** revisão regulatória. O regulador define; o prestador aplica, registra fatos e presta informações.

---

## 10. Operação: qualidade, metrologia, perdas, telemetria e energia

| Tema | Conclusão |
| ---- | --------- |
| **Qualidade — conceitos** | Plano de amostragem · ponto de coleta · amostra · coleta · parâmetro · resultado · limite · conformidade · não conformidade · ação · histórico — **evolução** da Gestão Operacional (catálogo N3) |
| **Laboratório** | **Opção C**: receber resultados de LIMS/laboratório externo **primeiro** (B); ciclo laboratorial próprio (A) como opção futura. ❌ Nenhum módulo Laboratório |
| **SISAGUA** | Integração regulatória — **adapter**; o leiaute atual não entra no domínio |
| **SINISA** | 🔴 **Não é BI**: exige dado primário, consolidação por período, validação, responsável, submissão, **histórico do que foi prestado** e rastreabilidade. Capacidade transversal **Prestação de Informações Regulatórias**: dados primários nos donos; consolidação e indicadores em Analytics; validação e submissão por Integrações; o que foi prestado guardado como documento regulatório (§6). ❌ Nenhum módulo *Regulação*. 🆕 **Adendo pós-Fase 0 — premissa corrigida**: consolidar métricas internas e submetê-las presumia equivalência semântica com o glossário do ciclo. O SINISA passa a **manual por padrão** — e só manual na V1 —, num **Workspace dono da declaração** (módulo *Prestação de Informações*), com glossário versionado, fonte, evidência, aprovação e retificação; o Analytics só oferece referência ([`sinisa.md`](../regulatorio/sinisa.md), [ADR-0009](../decisoes/0009-sinisa-preenchimento-manual.md)). *Não é BI* continua valendo |
| **Metrologia** | O equipamento já tem classe metrológica, vazões, revisão e garantia. Verificação, selo/lacre, certificado e validade entram **como atributos**, se confirmado que a obrigação recai sobre o prestador — **PENDENTE POR FONTE** |
| **Perdas** | Sem metodologia. Os dados do balanço hídrico **poderão existir**: consumo micromedido (Micromedição), volume faturado (Faturamento), volume macromedido e setor (Gestão Operacional, Ativos, Redes), séries de telemetria. Os índices do satélite do GSAN são **degenerados** e não são requisito |
| **Telemetria** | Mínimo a não inviabilizar: identidade do **ponto** de medição (vinculada a ativo ou rede), **série temporal**, **unidade**, **qualidade da medição**, **origem** e vínculo **vigente** com o ativo. Nenhuma plataforma IoT escolhida |
| **Energia** | Atributo operacional e custo do ativo; indicador em Analytics. **Sem módulo, sem evidência que o justifique** |

---

## 11. Resultado por tema

⚠️ **Contagem por script** sobre a coluna *Ação* da matriz do §2 (regra permanente 6 de [`procedencia.md`](../procedencia.md)).

| Resultado | Temas |
| --------- | ----: |
| JÁ COBERTO | 10 |
| CORRIGIDO | 20 |
| INCORPORADO | 10 |
| DEFERIDO | 5 |
| NÃO APLICÁVEL | 3 |
| PENDENTE POR FONTE | 2 |
| **Total** | **50** |

| Classe (primária) | Temas |
| ----------------- | ----: |
| L0 — já coberto | 11 |
| L1 — parcial | 18 |
| L2 — capacidade nova | 8 |
| L3 — evolução | 5 |
| L4 — integração/adapter | 3 |
| L6 — não aplicável | 3 |
| — (achado de consistência, sem classe de lacuna) | 2 |
| **Total** | **50** |
