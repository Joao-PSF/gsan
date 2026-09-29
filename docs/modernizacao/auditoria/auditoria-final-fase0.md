# Auditoria Final da Fase 0

> **Data**: 2026-09-29 · **Estado de entrada**: `9993ac1` · **Branch**: `claude/gsan-modernizacao-tecnica-rd5g60`.
>
> ⚠️ **Não é nova fase de descoberta.** Auditou a Fase 0 existente, procurou lacunas reais, corrigiu **só** as lacunas, verificou consistência e decidiu o encerramento. **Nenhum** código, migration, API, banco, execução do GSAN, captura de baseline, integração fiscal, chamada Pix, envio ao SINISA ou ao SISAGUA.
>
> Matrizes detalhadas em [`completude-funcional-regulatoria.md`](completude-funcional-regulatoria.md).

---

## 1. Escopo

**Pergunta**: *se começássemos a implementação amanhã, existe alguma obrigação, capacidade ou domínio fundamental de uma companhia moderna de água e esgoto que descobriríamos tarde demais porque a Fase 0 não o enxergou?*

| Incluído | Como |
| -------- | ---- |
| Vinte e duas varreduras — fiscal, pagamentos, Tarifa Social, NR ANA 11, qualidade, SINISA, metrologia, privacidade, atendimento digital, notificações, documentos, contingência, perdas, telemetria, energia, contratos e concessões, reajuste, Conta × Fatura × documento fiscal, comunicação, acessibilidade, geoespacial, esgoto, resíduos e drenagem | Fonte oficial primeiro; classes L0–L6; resultado por tema |
| Evoluções posteriores do GSAN | Busca pública — ⚠️ portal oficial inacessível nesta sessão |
| Varredura dos 79 cenários | Só os P0/P1 necessários acrescentados |
| Coerência, ownership, nomenclatura e segurança | Entre ADRs, visão, mapa, ordem, módulos e cenários |

⚠️ **Limitação declarada**: a política de rede da sessão bloqueou a leitura direta de `www.gov.br`, `www.planalto.gov.br`, `dfe-portal.svrs.rs.gov.br` e de cópias da NR 11 em sites de agências. As fontes oficiais foram lidas por resumos de busca sobre as próprias páginas; onde só havia fonte secundária, a certeza está rebaixada e a pendência registrada.

---

## 2. Estado de entrada

| Verificação | Resultado |
| ----------- | --------- |
| HEAD real | `9993ac1` — ADR-0007 aceita; **local = remoto**; árvore limpa |
| Commits posteriores | Nenhum |
| Auditoria já iniciada | Não — pasta `auditoria/` inexistente; backlog com *"Auditoria final e encerramento da Fase 0 ← próxima"* |
| ADRs | **8, todas aceitas** |
| Mapas funcionais | **12** |
| Especificações críticas | **79** (45 P0 · 34 P1), inventário de 184 itens |
| Pendências apontadas pela execução anterior | Achado 6 (cookie e CSRF) sem `D-xx`; D-01…D-16 com status *Proposta* na tabela das aprovadas |

---

## 3. Artefatos auditados

**76 documentos** em `docs/modernizacao/` no estado de entrada, mais [`MODERNIZACAO_GSAN.md`](../../../MODERNIZACAO_GSAN.md):

| Grupo | Documentos | O que se verificou |
| ----- | ---------- | ------------------ |
| Decisões | ADR-0001 a 0008 | Coerência com a estrutura final; afirmações factuais |
| Domínio | Glossário · mapa de domínio · visão conceitual · gestão de ativos | Conceitos estruturais faltantes; ownership; nomenclatura |
| Mapas | 12 mapas, catálogo, ordem de implementação | Lacunas regulatórias; posição de capacidades promovidas; evidências |
| Compatibilidade | Estruturas centrais · GSAN → OpenGSAN · divergências | Contagens por script; pendências resolvíveis; status de aprovação |
| Segurança | Riscos · modelo legado · mapa de segurança | Achados sem `D-xx`; segredos transcritos |
| Testes | Estratégia · índice · especificações | Requisitos P0/P1 sem cenário; oráculo de requisito nativo |

---

## 4. Coerência arquitetural

| Par verificado | Achado | Correção |
| -------------- | ------ | -------- |
| ADR-0001 × Fiscal | Novo módulo com **ciclo próprio**; adapter do ambiente autorizador em Integrações; sem HTTP entre módulos | Coerente — `fiscal` acrescentado à [arquitetura-alvo](../arquitetura/arquitetura-alvo.md) e ao [plano](../plano-de-trabalho.md) |
| ADR-0007 × achado 6 | ⚠️ A ADR dizia que sessão, cookie e CSRF **não tinham antecedente** no GSAN. O legado **tem** sessão e cookie, sem atributos e sem token — ausência de proteção é comportamento observável | ADR-0007 §9.4 e §15 corrigidas; **D-18** + CEN-SEG-012; decisão da ADR inalterada |
| ADR-0007 × ordem | ⚠️ PIX e boleto registrado na **Etapa 8** (canais) — mas o canal só **apresenta** o meio | Reposicionados para a **Etapa 5**; Pix Automático na **6** |
| ADR-0008 × varreduras | Telemetria, perdas e energia cabem na trilha estrutural e no Analytics | Coerente — nenhuma alteração |
| Visão × obrigação | ⚠️ Nenhum lugar para documento fiscal, contexto institucional ou parâmetro regulado | Visão §19, §23.2, §27.2, §27.3 |
| Mapa de domínio × fiscal | ⚠️ A cadeia financeira terminava na Contabilização | Ciclo fiscal acrescentado (§12) — **único** conceito estrutural novo |
| Mapa de Segurança × código | 🔴 Afirmava que `UsuarioGrupoRestricao` **não** era consultada no cálculo de autorização — a leitura parou antes do trecho que a consulta | Corrigido por leitura de código (`ControladorAcessoSEJB:3104`, `:3517`) — o **"único bloqueio de dia 1" deixou de existir** |
| Catálogo × obrigação | ⚠️ Fiscal e SPED `EXIGE APROFUNDAMENTO`, H2; Tarifa Social como capacidade genérica | Reclassificados; contagens refeitas por script |
| Compatibilidade × evidência | ⚠️ "Fatura" C5 bloqueando cenário; negação C5 | Resolvidas por código; contagens refeitas por script |

---

## 5. Completude funcional

🟢 **O núcleo comercial estava completo** — cadastro, medição, faturamento, cobrança, arrecadação, atendimento, contabilização, operação e ativos resistiram à varredura. As lacunas funcionais encontradas foram de **fronteira e de posição**, não de domínio:

- **Pagamentos**: o modelo de Arrecadação **já** suportava novos meios sem uma arrecadação por meio; faltava dizê-lo e posicionar PIX no lugar certo.
- **Contingência operacional**: interrupção e racionamento tinham semente no legado (programação × RA de falta d'água), mas não conceito — registrado como **evento operacional com área afetada**.
- **Documentos e evidências** e **comunicação**: padrões soltos viraram **capacidades transversais** com regras — sem ECM e sem fornecedor no domínio.
- **Qualidade, perdas, telemetria, energia**: **deferidos** com o mínimo de dados que não pode ser inviabilizado.

**Evoluções do GSAN**: a busca pública não encontrou funcionalidade nova além do que o catálogo já registrou; o portal oficial estava inacessível — **pendente por fonte**. ⚠️ **Gambiarras**: nenhuma posição de menu foi tomada como arquitetura; o schema `fiscal` e o SPED em função de banco foram classificados pela **necessidade real** (obrigação fiscal; dados ao ERP), não pela estrutura encontrada.

---

## 6. Completude regulatória

🔴 **A omissão estrutural era regulatória** — exatamente o risco que motivou a auditoria. Resultado por script sobre **50 temas**:

| Resultado | Temas |
| --------- | ----: |
| JÁ COBERTO | 10 |
| CORRIGIDO | 20 |
| INCORPORADO | 10 |
| DEFERIDO | 5 |
| NÃO APLICÁVEL | 3 |
| PENDENTE POR FONTE | 2 |

**Classes de lacuna** (primária): L0 11 · L1 18 · **L2 8** · L3 5 · L4 3 · L6 3 · 2 achados de consistência. As **8 L2** são todas do **Fiscal, da Tarifa Social e do contexto institucional**. A matriz de regulações tem **15 normas** (9 cobertas ou não aplicáveis, 6 parciais), e a de conformidade com a NR 11, **16 temas** (6 cobertos, 3 parametrizáveis, 3 regra do regulador local, 3 parciais, 1 ausente).

🔴 **Omissão que o roteiro não listava**: a **devolução personalizada (cashback) de IBS/CBS**, concedida no momento da cobrança de água e esgoto a famílias do CadÚnico — altera o valor cobrado e foi incorporada ao Fiscal.

---

## 7. NFAg / Fiscal

| Questão | Conclusão |
| ------- | --------- |
| É obrigatória? | 🟢 **Sim** — documento fiscal eletrônico dos prestadores de água e esgoto (modelo 75), na Reforma Tributária do Consumo; leiaute aprovado; cronograma no Ato Conjunto RFB/CGIBS nº 4/2026. ⚠️ Data exata: `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` |
| Classificação | ~~`EXIGE APROFUNDAMENTO`, H2~~ → **CAPACIDADE REGULATÓRIA NECESSÁRIA**, **H1**, módulo **Fiscal** |
| Conta × NFAg | 🔴 **Conta ≠ NFAg** — o Faturamento publica o fato tributável; o Fiscal emite; vínculo *versão da conta ↔ documento fiscal* |
| Ownership | Faturamento: cálculo, consumo, tarifa, documento comercial. Fiscal: documento, identidade fiscal, autorização, rejeição, eventos, contingência, DANFAG, guarda, determinação tributária. Integrações: adapter |
| Ciclo | Gerar → assinar → transmitir → autorizada/rejeitada → guardar → DANFAG → eventos. Eventos além de cancelamento, substituição, faturamento conjunto e vinculação de pagamento **não** foram assumidos |
| Contingência | Suportar normal, contingência, transmissão posterior e reconciliação. 🔴 Emissão **em campo** (impressão simultânea) × contingência: a pendência fiscal de **maior impacto arquitetural** |
| Guarda | Documento fiscal ≠ artefato de relatório |
| Retificação | Invariantes fixados (documento autorizado nunca alterado; identidades separadas); a regra fiscal: **pendente** |
| Arrecadação | Documento ≠ pagamento; ponte única: vinculação do *split payment*, se aplicável à NFAg |
| Contabilização | Consome fatos comerciais, fiscais e financeiros; cada valor com **uma** origem |
| SPED · DeRE · apuração | SPED → integração com o ERP; DeRE → não aplicável; apuração → fora do sistema |
| Ordem | Etapa **4** (individual, homologação) e **7** (lote, contingência, eventos) |
| Cenários | CEN-FIS-001 a 003 — oráculo **N** |

Mapa: [`modulos/fiscal.md`](../modulos/fiscal.md), com as **10 pendências** de validação fiscal e o prazo de cada uma.

---

## 8. Pagamentos / PIX

🟢 **O modelo suporta novos meios sem uma arrecadação por meio**: os quatro momentos não mudam; varia o **contrato de meio de pagamento**. PIX pertence à **Arrecadação/Pagamentos** — não depende do Portal. Posição: **Pix Cobrança e boleto registrado na Etapa 5**, **Pix Automático na Etapa 6** junto do débito automático. Abstração comum **mínima**: *autorização de pagamento recorrente*, sem fundir os arranjos. Cenários CEN-ARR-012 (confirmação idempotente, duplicidade, conciliação, expiração) e CEN-ARR-013 (autorização, retentativa, cancelamento). Nenhum PSP escolhido; nenhuma API Pix chamada.

---

## 9. Tarifa Social

🔴 Deixou de ser capacidade genérica para ser **obrigação nacional** (Lei 14.898/2024; NR ANA 13/2025, com prazo aos prestadores em **11/12/2026**): critério nacional, desconto até um limite de volume e **concessão automática** a partir de CadÚnico/BPC. **Sem módulo**: elegibilidade e vínculo no Cadastro, aplicação no Faturamento, fonte oficial em Integrações, informação regulatória na capacidade transversal. Dados de CadÚnico/BPC com finalidade específica e minimização. Cenário CEN-FAT-012. ⚠️ Permanência, transição e prazos de comunicação: regra do regulador — pendente.

---

## 10. NR ANA

| Norma | Conclusão |
| ----- | --------- |
| **NR 11/2024** (Resolução ANA 230) | Obriga as **entidades reguladoras** a regular condições gerais até 20/05/2027. O comportamento já existia no legado como regra-como-dado; o que faltava era o **parâmetro regulado** (vigência, contexto institucional, origem normativa) e o **evento operacional** de interrupção. Matriz de conformidade com 16 temas |
| **NR 13/2025** (Resolução ANA 271) | Estrutura tarifária (coberta), Tarifa Social (incorporada) e **cobrança conjunta** de outros serviços de saneamento na conta (item de terceiro no Faturamento + faturamento conjunto no Fiscal) |
| **Regra local** | 🔴 Nunca `if estado == X`: política, parametrização, vigência, jurisdição, regulador |
| **Reajuste e revisão** | O OpenGSAN **aplica** a estrutura aprovada; **não** calcula revisão regulatória — a fronteira prestador × regulador fica mantida |

---

## 11. Qualidade / SISAGUA

A informação de qualidade na conta (Decreto 5.440/2005) **já estava coberta** (CEN-OPE-003). O **ciclo de controle** (Portaria GM/MS 888/2021) é **evolução** da Gestão Operacional; laboratório: **opção C** — receber resultados de LIMS externo primeiro, ciclo próprio como opção; **SISAGUA é adapter**, sem leiaute no domínio. Sem cenário: o ciclo não entrou no escopo atual, e não se cria equivalência GSAN artificial.

---

## 12. SINISA

Prestação **anual e obrigatória** para acesso a recursos federais (ciclo 2026: coleta de 13/05 a 03/09/2026). 🔴 **Não é BI**: exige dado primário, consolidação, validação, responsável, submissão e **histórico do que foi prestado**. Tratado como capacidade transversal **Prestação de Informações Regulatórias** — dados nos donos, consolidação no Analytics, submissão por Integrações, guarda como documento regulatório. ❌ **Nenhum módulo *Regulação*** — a distribuição cobre matriz normativa, indicadores e submissão.

---

## 13. Privacidade

LGPD auditada **por fluxo**, com terminologia correta — *dado pessoal* × *dado pessoal sensível* (art. 5º, II) — e risco operacional à parte. Maior risco: **CadÚnico/BPC** (BPC pode revelar condição de saúde; enquadramento jurídico a validar), CPF, pagamento e documento fiscal. Necessidade arquitetural registrada **sem sistema de LGPD**: finalidade por categoria, retenção por categoria com bloqueio ou anonimização (exceto guarda legal), correção pelo dono, exportação ao titular, logs sem dado pessoal. Detalhe em [completude §7](completude-funcional-regulatoria.md#7-privacidade-por-fluxo-sensível).

---

## 14. Segurança

| Item | Resolução |
| ---- | --------- |
| **D-01…D-16 com status *Proposta*** | A aprovação **existia e não estava registrada**: regras permanentes do responsável técnico (hash, pseudo-autenticação, segredos, credenciais por ambiente), ADR-0001 (D-14), ADR-0007 (D-03) e a instrução explícita de testar D-13 pelo oráculo 2. Registrada com a origem de cada uma no [registro de divergências](../compatibilidade/divergencias-aprovadas.md) |
| **Achado 6 sem `D-xx`** | **D-18** — cookie sem `HttpOnly`/`Secure`/`SameSite` e nenhum token anti-CSRF no legado (sem `session-config`; zero `saveToken`/`isTokenValid` em `src/`) → cookie protegido e token em toda requisição que altera estado. Aprovada pela ADR-0007; cenário CEN-SEG-012 |
| **Negação na autorização** | 🔴 **Existe**: restrição por usuário que subtrai a concessão de um grupo — acesso se restrições < concessões. Preservada (C1); CEN-SEG-004 V7 |
| **CAND-05** (novo) | Composição do filtro de restrições com limite de laço trocado (`:3072`) — condicional à caracterização |
| **CAND-03 · CAND-04** | ⚠️ **Mantidos pendentes** — sem decisão explícita nem caracterização |
| **Segredos** | Verificação por script **sem exibir valores**: **zero** ocorrências do valor da chave de SMS e das senhas de `dblink` na documentação. ⚠️ Duas linhas listavam os **nomes das roles** ao lado da afirmação *senha = login* — o que equivalia a transcrever a credencial; a lista foi retirada ([`modelo-legado.md`](../seguranca/modelo-legado.md), [`migracao-postgresql.md`](../banco/migracao-postgresql.md)). Os nomes permanecem só como estrutura; as credenciais seguem **comprometidas e com rotação obrigatória** (D-08, D-16, achados 11 e 20) |

**Estado do registro**: 17 divergências aprovadas · 1 proposta (D-17) · 5 candidatas.

---

## 15. Ownership

🟢 **Nenhum conceito central com dois donos.**

| Conceito | Dono único | Consumidores |
| -------- | ---------- | ------------ |
| **Conta** | Faturamento | Fiscal, Cobrança, Arrecadação, Contabilização, canais |
| **NFAg / documento fiscal** | Fiscal | Faturamento (vínculo), Arrecadação (vinculação), Contabilização |
| **Pagamento / recebimento** | Arrecadação | Cobrança (posição derivada), Fiscal (vinculação), Contabilização |
| **Benefício tarifário** | Cadastro (elegibilidade e vínculo) · Faturamento (regra e aplicação) — **atributos distintos**, não o mesmo dado | Atendimento, prestação de informações |
| **OS** | Atendimento e Execução | Cobrança, Micromedição, Ativos (manutenção executa por OS — ADR-0008) |
| **Ativo** | Gestão de Ativos | Redes/GIS, Telemetria, Analytics |
| **Rede** | Redes/GIS | Ativos, Gestão Operacional |
| **Qualidade da água** | Gestão Operacional | Emissão (projeção congelada), SISAGUA |
| **Lançamento contábil** | Contabilização | ERP por adaptador |

**Nomenclatura fixada** ([glossário](../dominio/glossario.md)): *Conta* (documento comercial) · *Fatura do cliente responsável* (documento agregador — "Fatura" solta não é sinônimo de conta) · *documento fiscal/NFAg* · *documento de cobrança* · *comprovante* · *recebimento* · *posição de dívida* (derivada; não existe entidade "Dívida"). *Operacional* designa a Gestão Operacional; o antigo "núcleo operacional" do Atendimento já era *atendimento e execução*. *Ativo* é o da ADR-0008. Nada foi renomeado sem necessidade.

---

## 16. Cenários

| | Antes | Depois |
| - | ----: | -----: |
| Especificações | 79 | **87** |
| P0 · P1 | 45 · 34 | **49 · 38** |
| Oráculo 1 · 1+2 · 2 · **N** · pendente | 62 · 8 · 6 · — · 3 | **63 · 8 · 7 · 6 · 3** |
| Baseline a capturar · comprovada · não aplicável | 78 · 1 · — | **80 · 1 · 6** |
| Bloqueados por decisão | BLQ-01 a 04 | **BLQ-01 e 03** (D-17) |
| Divergências aprovadas com cenário | 16 | **17** |
| Inventário | 184 | 184 — um destino mudou (BLQ-02 → SEG-004 V7) |

**Acrescentados**: CEN-FIS-001, 002, 003 (NFAg) · CEN-ARR-012 (Pix Cobrança) · CEN-ARR-013 (Pix Automático) · CEN-FAT-012 (Tarifa Social) — **requisitos nativos, oráculo N** · CEN-ARR-011 (Fatura, antigo BLQ-04, oráculo 1) · CEN-SEG-012 (D-18, oráculo 2). **Alterado**: CEN-SEG-004 (V7). Matriz, distribuições, perfis e rastreabilidade **regenerados por script**. Qualidade/SISAGUA **sem cenário** — fora do escopo atual.

---

## 17. Pendências aceitas

Não impedem o encerramento: nenhuma altera arquitetura ou ownership **já definidos**; todas têm dono e prazo.

| # | Pendência | Natureza | Prazo |
| - | --------- | -------- | ----- |
| 1 | Validações fiscais da NFAg — data, retificação, cancelamento, **emissão em campo**, cardinalidade, tarifa bruta × líquida, cashback, guarda ([`fiscal.md §12`](../modulos/fiscal.md)) | `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` | Etapas 3–7, item a item |
| 2 | Aprovação de **D-17** (escopo territorial sistemático) — BLQ-01 e BLQ-03 | Decisão do responsável | Antes da Etapa 2 |
| 3 | **Nome e governança do repositório** (ADR-0003) | Decisão do responsável | Antes da Etapa 0 |
| 4 | Inventário das **variantes por companhia** | Investigação | Antes da Etapa 4 |
| 5 | Varredura das políticas de arredondamento na Cobrança e na Arrecadação | Investigação | Antes da captura dessas baselines (Fase 2) |
| 6 | CAND-01 a CAND-05 | Caracterização | Fase 2 |
| 7 | Permanência/transição da Tarifa Social; conteúdo mínimo da fatura; prazos de aviso — por regulador | Regra do regulador local | Antes da operação na jurisdição |
| 8 | Obrigações metrológicas do prestador (Inmetro) | Pendente por fonte | Antes da Etapa 3 |
| 9 | NR 11 artigo a artigo e documentação atual do GSAN | Pendente por fonte — hosts bloqueados | Quando o acesso existir |
| 10 | Conta alterada depois do agendamento do Pix Automático | Decisão de produto | Antes da Etapa 6 |
| 11 | Multi-tenancy | Decisão estrutural **não tomada**, deliberadamente | Quando houver caso concreto |

---

## 18. Correções realizadas

| Documento | Correção |
| --------- | -------- |
| 🆕 [`modulos/fiscal.md`](../modulos/fiscal.md) | Mapa do ciclo fiscal — NFAg, fronteiras, ordem, pendências |
| 🆕 [`completude-funcional-regulatoria.md`](completude-funcional-regulatoria.md) · este relatório | Matrizes e veredito |
| 🆕 [`testes/cenarios/fiscal.md`](../testes/cenarios/fiscal.md) + ARR-011/012/013, FAT-012, SEG-012 | 8 especificações; SEG-004 V7 |
| [`funcionalidades-futuras.md`](../modulos/funcionalidades-futuras.md) | Natureza *capacidade regulatória necessária*; 08, 09, 11 e 22 reclassificados; PIX em Pagamentos; §28 com N1–N3; recontagem por script |
| [`dependencias-e-ordem-implementacao.md`](../modulos/dependencias-e-ordem-implementacao.md) · [`modulos/README.md`](../modulos/README.md) | Relações 27–29; PIX → Etapa 5; Pix Automático → 6; NFAg → 4 e 7; Tarifa Social; gates; bloqueio de negação resolvido |
| [`visao-conceitual-opengsan.md`](../dominio/visao-conceitual-opengsan.md) | §27.2 estrutura consolidada; §27.3 contexto institucional; §23.2 parâmetro regulado; ownership; riscos 16–17 |
| [`mapa-de-dominio.md`](../dominio/mapa-de-dominio.md) · [`glossario.md`](../dominio/glossario.md) | Ciclo fiscal; Fatura; negação; terminologia fixada |
| Mapas de Faturamento, Arrecadação, Cadastro, Operacional, Integrações, Contabilização, Micromedição | Adendos de fronteira — sem reanálise |
| [`modulos/seguranca.md`](../modulos/seguranca.md) | Restrição por usuário **comprovada**; modelo real de autorização |
| [`divergencias-aprovadas.md`](../compatibilidade/divergencias-aprovadas.md) · [`riscos-identificados.md`](../seguranca/riscos-identificados.md) · [ADR-0007](../decisoes/0007-arquitetura-de-interface.md) | Aprovação registrada; D-18; "sem antecedente" corrigido |
| [`gsan-opengsan.md`](../compatibilidade/gsan-opengsan.md) · [`estruturas-centrais.md`](../compatibilidade/estruturas-centrais.md) | Negação → C1 e SEG-07 → PRESERVAR; Fatura resolvida; CAND-05; oráculo N fora da matriz; **recontagens por script** (145: 91 · 25 · 17 · 5 · 1 · 6; 64: 38 · 14 · 6 · 4 · 2) |
| [`estrategia-testes.md`](../testes/estrategia-testes.md) · [`cenarios-criticos.md`](../testes/cenarios-criticos.md) | Oráculo N; baseline não aplicável; gates; bloqueios; candidatos |
| [`arquitetura-alvo.md`](../arquitetura/arquitetura-alvo.md) · [`plano-de-trabalho.md`](../plano-de-trabalho.md) | Módulo `fiscal` |
| [`modelo-legado.md`](../seguranca/modelo-legado.md) · [`migracao-postgresql.md`](../banco/migracao-postgresql.md) | Lista de roles retirada da afirmação sobre a senha |

---

## 19. Riscos transferidos

| Risco | Para | Mitigação já registrada |
| ----- | ---- | ----------------------- |
| Regra fiscal confirmada tarde (retificação, campo, cashback) | Etapas 3–7 | Fronteira Fiscal isolada; invariantes em CEN-FIS-003; pendências com prazo |
| Norma mudar depois da implementação | Operação | **Parâmetro regulado** com vigência e origem normativa; leiaute só no adapter |
| Portais oficiais lidos por resumo nesta fase | Implementação do Fiscal e do Pix | Releitura do MOC e do Regulamento Pix vigentes antes de implementar |
| Baseline do legado indisponível ou customizada | Fases 1–2 | Especificações com observáveis fechados; origem da evidência declarada |
| Escopo inflado por capacidades deferidas | Evolução | Nenhum módulo novo além do Fiscal; N1–N3 contadas à parte |
| Credenciais comprometidas em circulação | Instalações que usem o legado | Rotação obrigatória (D-08, D-16; achados 11 e 20) |

---

## 20. Critérios de saída

| Critério | Situação |
| -------- | -------- |
| Varredura sistemática de omissões funcionais, regulatórias e arquiteturais | ✅ 22 varreduras, 50 temas, 15 normas, 16 temas da NR 11 |
| Toda lacuna **estrutural** P0/P1 tratada — incorporada ou corrigida | ✅ NFAg, determinação tributária, cashback, Tarifa Social, contexto institucional, PIX, negação, D-18 |
| Nenhum detalhe normativo inventado | ✅ `VALIDAÇÃO JURÍDICA/FISCAL NECESSÁRIA` onde a norma não foi confirmada |
| Coerência entre ADRs, visão, mapa, ordem, módulos e cenários | ✅ §4 |
| Nenhum conceito central com dois donos | ✅ §15 |
| Pendências de segurança da ADR-0007 resolvidas | ✅ §14 |
| CAND-03 e CAND-04 **não** aprovados em silêncio | ✅ Mantidos pendentes |
| Nenhum segredo transcrito | ✅ Verificado por script; duas linhas corrigidas |
| Contagens por script | ✅ Catálogo, compatibilidade, estruturas, cenários, completude |
| Links relativos válidos | ✅ Validados por script no encerramento |
| Nenhuma implementação | ✅ |

---

## 21. Veredito da Fase 0

# A FASE 0 PODE SER ENCERRADA? — **SIM**

**Não há lacuna estrutural P0/P1 não tratada.** A omissão que a auditoria existia para impedir — *descobrir a NFAg com o Faturamento construído* — foi encontrada **agora**, com fronteira definida, e veio acompanhada de uma segunda que o roteiro não listava (a devolução personalizada de IBS/CBS). O único "bloqueio de dia 1" registrado **deixou de existir** por evidência de código. O que permanece aberto é **decisão do responsável** (D-17, repositório), **regra de norma a confirmar** (fiscal, regulador local, metrologia) ou **caracterização da Fase 2** — nenhum item exige nova descoberta geral nem muda arquitetura ou ownership já definidos.

> *O OpenGSAN possui uma visão suficientemente completa do que uma companhia moderna de água e esgoto precisa operar, faturar, receber, atender, manter, prestar contas e cumprir suas obrigações — sem carregar as gambiarras estruturais do GSAN.*

**Próximo estágio, conforme o plano vigente**: [Fase 1 — ambiente de referência do legado](../plano-de-trabalho.md), seguida da Fase 2 — captura das baselines. A Etapa 0 do OpenGSAN corresponde à Fase 4 e depende das Fases 0–2. ⚠️ **Nenhuma implementação foi iniciada por esta auditoria.**
