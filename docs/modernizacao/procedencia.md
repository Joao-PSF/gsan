# Procedência das Fontes e Método de Verificação

Criado em 2026-09-14 em resposta à crítica de rastreabilidade da revisão externa. **Nenhuma afirmação da documentação da Fase 0 é verificável se a fonte não estiver identificada.** Este documento fixa as fontes e o método.

---

## 1. Fontes

| Fonte | Identificação | Uso |
| ----- | ------------- | --- |
| Código GSAN | repositório `Joao-PSF/gsan`, branch `claude/gsan-modernizacao-tecnica-rd5g60` | Fonte primária de comportamento |
| — commit dos mapas de módulo (cadastro → relatórios) | `2031c4ca762c3ec2597ea8c057db97aa388e5589` | Base das análises de 2026-08-13 a 2026-08-14 |
| — commit do mapa de Integrações e das correções | este commit | Base das análises de 2026-09-14 |
| DDL `gsan_comercial` | arquivo fornecido pelo usuário (`03056c39-gsan_comercial.txt`) | **Fonte complementar** — compatibilidade e descoberta funcional. Nunca é o schema alvo do OpenGSAN (ADR-0006) |
| Migrations | repositório `Joao-PSF/gsan-migracoes` | Versionamento histórico do banco |
| 🆕 Normas e portais oficiais | Lei, regulamento, ANA, Receita/Portal DF-e, Banco Central, Ministério da Saúde, Ministério das Cidades — consultados em **2026-09-29** ([matriz de regulações](auditoria/completude-funcional-regulatoria.md#3-matriz-de-regulações)) | Obrigações **atuais** — requisito nativo. ⚠️ Lidos por **resumo de busca** sobre as páginas oficiais: a leitura direta de `www.gov.br`, `www.planalto.gov.br` e `dfe-portal.svrs.rs.gov.br` estava bloqueada pela política de rede da sessão |
| 🆕 Giswater — repositórios oficiais | [`Giswater/api`](https://github.com/Giswater/api) (lido em 2026-09-29) e protocolo *P16 — mincut basics* em [`Giswater/docs`](https://github.com/Giswater/docs) | Semântica do *mincut* — estados, operações, válvulas, elementos afetados, pré-requisitos ([`paradas-interrupcoes.md §7`](dominio/paradas-interrupcoes.md#7-giswater--o-que-o-mincut-faz)). ⚠️ Lido **diretamente nos repositórios**; o site `docs.giswater.org` estava bloqueado |
| 🆕 SINISA — Ministério das Cidades | Página do SINISA, Área do Prestador, glossários e manuais por ciclo — consultados em **2026-09-29** ([`sinisa.md`](regulatorio/sinisa.md#fontes)) | Ciclo, glossários, formulários, comprovante × regularidade. ⚠️ Lidos por **resumo de busca** — `www.gov.br` bloqueado; prorrogações só por fonte secundária |

| 🆕 Receita oficial de instalação (Fase 1) | Wiki `prodigasistemas/gsan.wiki` (`d5d75c8`, 2023-03-29); scripts e receitas `prodigasistemas/ti` (`75b1a2f`, 2018-12-28); bibliotecas `prodigasistemas/jboss-libs` (`3002fa1`, 2016-08-31) — lidos em **2026-09-30**, diretamente nos repositórios | Como uma instalação real era montada: JDK 6, JBoss 4.0.1SP1 e suas alterações, locale LATIN1, datasources, MyBatis 3.2.1. Base do [ambiente de referência](../../ambiente-referencia/README.md) |
| 🆕 Migrações executadas (Fase 1) | `Joao-PSF/gsan-migracoes` `2d6acdb` — idêntico ao `prodigasistemas/gsan-migracoes` na data | A execução numa base nova é **evidência de comportamento do histórico**, não só leitura: [`banco/README.md`](../../ambiente-referencia/banco/README.md) |

⚠️ **Limitação declarada**: o hash do arquivo DDL não foi registrado na época em que a análise do banco foi feita. Toda afirmação derivada do DDL está marcada como tal e deve ser reconferida contra o arquivo vigente antes de virar decisão. Este é um débito reconhecido, não uma omissão silenciosa.

---

## 2. Níveis de certeza

Convenção adotada a partir do mapa da Arrecadação e aplicada retroativamente nos mapas seguintes:

| Marca | Significado | Critério para usar |
| ----- | ----------- | ------------------ |
| 🟢 | **Fato** | Lido diretamente no código/DDL, com arquivo e linha citados. Reproduzível por terceiro |
| 🔵 | **Interpretação** | Conclusão sustentada por evidência 🟢, mas que envolve juízo sobre intenção ou consequência |
| 🟡 | **Hipótese** | Plausível, com indício parcial; não comprovada |
| ❔ | **Não compreendido** | Dúvida aberta e registrada. Nunca preenchida por suposição |

**Regra derivada dos erros cometidos**: ausência de evidência **não** é evidência de ausência. Uma busca que não encontra um nome não autoriza afirmar que o comportamento não existe — autoriza apenas afirmar que aquele nome não aparece naquele escopo. Afirmações de inexistência exigem busca **exaustiva e declarada** (escopo + comando + resultado).

---

## 3. Método de contagem

Todo número publicado deve declarar **o que conta** e **em que escopo**. Métricas diferentes sobre o mesmo objeto divergem legitimamente; o defeito não é divergir, é não dizer qual métrica é.

### 3.1 Classes EJB

| Métrica | Valor | Como obter |
| ------- | ----: | ---------- |
| Classes com `MessageDrivenBean` em `src/` | **166** | `grep -rl "MessageDrivenBean" src --include=*.java \| wc -l` |
| Classes com `SessionBean` em `src/` | 69 | `grep -rl "SessionBean" src --include=*.java \| wc -l` |
| — das quais abstratas | 1 | `ControladorComum.java:79` — `public abstract class ControladorComum implements SessionBean` |
| **Session Beans concretos** | **68** | 69 − 1 |
| **Total de classes EJB concretas** | **234** | 166 + 68 |

⚠️ **Não confundir com** as ~247 declarações de EJB nos descritores `META-INF/ejb-jar.xml`. Aquilo conta **deployments declarados**, não classes concretas distintas: há controlador sem descritor e descritor apontando para classe compartilhada. As duas métricas são válidas e medem coisas diferentes.

### 3.2 Modos de arredondamento (Faturamento)

Escopo declarado: **`ControladorFaturamentoFINAL.java` apenas** (o pacote inteiro não foi contado). Ver [`modulos/faturamento.md §27`](modulos/faturamento.md).

⚠️ Contar **modos semânticos**, não constantes: `BigDecimal.ROUND_HALF_UP` (int, depreciado) e `RoundingMode.HALF_UP` (enum) são **o mesmo modo** em duas APIs.

---

## 4. Correções de fato já aplicadas

Registro das afirmações que foram publicadas erradas e depois corrigidas, para que ninguém reuse a versão antiga.

| Data | Afirmação incorreta | Onde estava | Correção |
| ---- | ------------------- | ----------- | -------- |
| 2026-08-14 | `ContaGeral` preserva identidade "através da retificação" | `faturamento.md` | Identidade é estável **corrente↔histórico**; retificação cria documento novo com linhagem por origem |
| 2026-09-14 | "Faturamento não regrava consumo" | `faturamento.md §5`, `micromedicao.md` | Três casos distintos; a **retificação escreve diretamente** (`ControladorRetificarConta:273`) |
| 2026-09-14 | "Arredondamento HALF_UP centralizado" | `faturamento.md §27` | **Cinco políticas semânticas** distintas; 21 usos de `RoundingMode.UP`; truncamento na base de imposto |
| 2026-09-14 | `calcularValorFaturadoFaixaCAER` como exemplo do núcleo da Micromedição | `micromedicao.md` | Método pertence a `ControladorFaturamentoFINAL` (Faturamento) |
| 2026-09-14 | "Senhas com MD5/SHA-1" | `riscos-identificados.md`, `plano-de-trabalho.md` | Login usa **SHA-1**; MD5 é token efêmero de servlets auxiliares |
| 2026-09-14 | Acesso ao artefato de relatório como "dúvida prioritária" | `relatorios.md`, `seguranca.md` | **Achado confirmado** — cadeia completa de filtros verificada |
| 2026-09-14 | `api/GsanApi.java` (raiz) citado como evidência | `integracoes-identificadas.md` | Cópia obsoleta; a viva é `src/gcom/api/GsanApi.java` |
| 2026-09-14 | Codificação do banco "LATIN1 confirmado" | `banco/estrutura-atual.md` | Rebaixado a **indício forte** (🔵), não fato |
| 2026-09-28 | "~110 cenários" inventariados nos mapas funcionais | `MODERNIZACAO_GSAN.md`, `mapa-de-dominio.md`, `estrategia-testes.md`, `dependencias-e-ordem-implementacao.md` (2×), `gsan-opengsan.md` | **166**, contados por script sobre as seções de cenários dos nove mapas que as têm. A cifra **nunca tinha sido contada** — viola a regra 2 deste documento |
| 2026-09-28 | *"Enquanto o resultado esperado estiver 🟡, o cenário não está especificado"* | `testes/estrategia-testes.md` | Criava **dependência circular** Fase 0 ↔ Fase 2. Especificação (Fase 0) e baseline (Fase 2) passaram a ser **campos distintos** |
| 2026-09-28 | Resumos `sp*_gerar_res_*` como baseline financeira prioritária | `testes/estrategia-testes.md` | São **customização da instalação de referência** (`banco/estrutura-atual.md`); substituídos pelos relatórios do código público `RelatorioResumoFaturamento` e `RelatorioResumoArrecadacao` |
| 2026-09-28 | *"Conceito em C5 não tem cenário especificável"* | `compatibilidade/gsan-opengsan.md` §4.3, §5.1, §22, §23, §26 | **Forte demais**: só 3 dos 7 C5 bloqueiam cenário — os de comportamento. Os de representação são especificáveis quando o oráculo já está fixado por outra regra. A §26 ainda dizia "nove" depois da correção para sete |
| 2026-09-28 | Integração contábil como **`MÓDULO OPCIONAL`**, maturidade **`APENAS EVIDÊNCIA`** | `modulos/funcionalidades-futuras.md` capacidade 10 e §18 | O código público prova o fluxo completo — `gcom.financeiro` (60 classes): lançamentos por origem, parametrização contábil como dado, devedores duvidosos com recuperação, exportação com variantes por companhia. Passa a **`CORE FUTURO` / comprovada**; a exportação é adaptador. ⚠️ **Causa**: o catálogo leu o schema e nomes de função, **não o pacote Java** — o módulo não tinha mapa funcional ([`financeiro-contabilizacao.md`](modulos/financeiro-contabilizacao.md)) |
| 2026-09-28 | "Domínio operacional" / "Núcleo operacional" para **Atendimento e OS** | `dominio/mapa-de-dominio.md` (Eixo 2, §13); Etapa 2 em `modulos/dependencias-e-ordem-implementacao.md`, `modulos/README.md`, `plano-de-trabalho.md` e em 9 especificações de cenário | Colidia com o **módulo Operacional** do GSAN — estrutura operacional, calendário, medições —, que é outra coisa ([`operacional.md §10`](modulos/operacional.md)). Passa a **"atendimento e execução"** |
| 2026-09-28 | Credenciais versionadas do legado em **três** artefatos | `testes/cenarios/seguranca.md` (CEN-SEG-011) | Incompleto: há também usuário e senha em strings `dblink` de funções armazenadas nos **dumps versionados** — achado 20 de [`riscos-identificados.md`](seguranca/riscos-identificados.md). Valores **não transcritos** |
| 2026-09-29 | PECLD tratada como **ausente** do GSAN, sem qualificar a fonte ("inexistente no código público", "não é PECLD") | `modulos/financeiro-contabilizacao.md` §7, §7.3, §10, §11.2, §14; `dominio/visao-conceitual-opengsan.md` §28.2; `MODERNIZACAO_GSAN.md` | Correta **só para o código Java público**. O banco versionado tem `financeiro.param_perdas_societarias` (estrutura sem código) e a documentação GSAN posterior registra PECLD e "Provisão de Perdas Societárias", parte por base específica. PECLD passa a **capacidade posterior comprovada documentalmente, não comportamento universal do GSAN público**; baixa contábil ≠ provisão ≠ extinção comercial |
| 2026-09-29 | "O núcleo do GSAN **não tem ativo físico**" | `dominio/gestao-de-ativos.md`, `modulos/operacional.md` §8, `arquitetura/gis-redes-ativos.md` §1, `decisoes/0008-gestao-de-ativos-nativa.md` (contexto), `compatibilidade/gsan-opengsan.md` §5.2, `testes/cenarios/financeiro-operacional.md` | **Excessiva.** O GSAN tem objetos físicos — o **hidrômetro**, com ciclo de vida completo na Micromedição (aquisição, nota fiscal, garantia, armazenagem, movimentação, revisão, baixa com motivo), e a estrutura operacional. A lacuna correta: **não possui um modelo corporativo unificado de gestão de ativos**. A decisão da ADR-0008 não muda |
| 2026-09-29 | `UsuarioGrupoRestricao` **não observada** no cálculo de autorização — "o modelo é allow-list"; "único bloqueio de dia 1" | `modulos/seguranca.md` §10, §12, §24, §27, §28; `compatibilidade/gsan-opengsan.md` §12.3, §23; `compatibilidade/estruturas-centrais.md` SEG-07, §20; `dominio/visao-conceitual-opengsan.md` §28.1; `dominio/mapa-de-dominio.md` §21; `modulos/dependencias-e-ordem-implementacao.md` §27, §28.1, §31.3; `testes/cenarios-criticos.md` BLQ-02; `MODERNIZACAO_GSAN.md` | 🟢 **Participa**: `FiltroSegurancaAcesso:219/241` → `ControladorAcessoSEJB.verificarAcessoPermitidoFuncionalidade` (`:2664`, decisão `:3104`) e `verificarAcessoPermitidoOperacao` (`:3137`, decisão `:3517`) — acesso se restrições < concessões. A leitura original parou antes do trecho da consulta. Negação → **C1**; SEG-07 → **PRESERVAR**; contagens refeitas por script; anomalia `:3072` → CAND-05 |
| 2026-09-29 | "Fatura" com **semântica nunca esclarecida** (C5, BLQ-04) | `dominio/glossario.md` §5; `dominio/mapa-de-dominio.md` §21; `compatibilidade/gsan-opengsan.md` §9.2, §23; `testes/cenarios-criticos.md` BLQ-04 | 🟢 Documento **agregador** do cliente responsável: o pagamento se desdobra em um pagamento por conta, tipo CONTA, com a Fatura como agregador (`ControladorArrecadacao:7217`, `:7289`, `:7400`, `:7430`) — CEN-ARR-011 |
| 2026-09-29 | Sessão, cookie e CSRF **"sem antecedente no GSAN"** | ADR-0007 §9.4, §15; `testes/cenarios-criticos.md` §14 | O legado tem sessão e cookie **sem** atributos e **sem** token — ausência de proteção é observável → **D-18**, CEN-SEG-012 |
| 2026-09-29 | D-01…D-16 com status **"Proposta"** na tabela das aprovadas | `compatibilidade/divergencias-aprovadas.md` | Aprovação **existente e não registrada** — registrada com a origem de cada uma |
| 2026-09-29 | Documento fiscal `EXIGE APROFUNDAMENTO`, **H2**, "fora da ordem"; SPED idem | `modulos/funcionalidades-futuras.md` §3, §4, §6, §7, §20, §24, §25; `modulos/dependencias-e-ordem-implementacao.md` §20.3; `modulos/README.md` | 🔴 **NFAg obrigatória** (LC 214/2025; Ato Conjunto RFB/CGIBS nº 4/2026) → **capacidade regulatória necessária**, H1, módulo Fiscal; SPED → integração. ⚠️ **Lição**: obrigação regulatória **não se descobre no legado** — ver regra 7 |
| 2026-09-29 | PIX e boleto registrado na **Etapa 8** (canais) | `modulos/dependencias-e-ordem-implementacao.md`; `modulos/README.md` | Meios de recebimento — **Etapa 5**; o canal só apresenta; Pix Automático na **6** |
| 2026-09-29 | Lista de roles **ao lado** da afirmação "senha igual ao login" | `seguranca/modelo-legado.md`; `banco/migracao-postgresql.md` | Equivalia a transcrever a credencial — lista retirada; nomes só como estrutura |
| 2026-09-29 🆕 adendo | SINISA com valores **consolidados de métricas internas** no Analytics e **submetidos por adapter** — preenchimento derivado | `auditoria/completude-funcional-regulatoria.md` §2 e §10; `modulos/funcionalidades-futuras.md` (22); `modulos/dependencias-e-ordem-implementacao.md` (#29, §18, §24); `modulos/integracoes.md` (adapters); `auditoria/auditoria-final-fase0.md` §12 — **registro histórico, mantido** | 🔴 **Premissa, não fato — e perigosa**: cada informação do SINISA tem definição própria por ciclo; *métrica interna ≠ informação SINISA*. V1 **manual**, Workspace dono da declaração, automação só por mapeamento da companhia, desligada por padrão ([ADR-0009](decisoes/0009-sinisa-preenchimento-manual.md)). ⚠️ **Lição**: nome igual não é semântica igual — regra 9 |
| 2026-09-30 🆕 revisão | Módulo instalável **Services** para RA, OS e campo | `arquitetura/modulos-e-perfis-de-implantacao.md`, ADR-0010, cenários MOD-002 e MOD-004, visão §27.5 e demais referências do segundo adendo | **Atendimento** — RA · OS · Campo: *Services* escondia o RA e o fazia parecer assunto do Commercial. Registros históricos com nota de supersessão |
| 2026-09-30 🆕 revisão | **Estrutura organizacional** na Platform | `arquitetura/modulos-e-perfis-de-implantacao.md` §3, §12, §14; visão §8, §27.5 | Posicionamento de fluxo do RA e da OS — `UnidadeOrganizacional.java:26–76`; usos fora do atendimento também posicionam RA ou OS. Vai para o **Atendimento** (§7.2) |
| 2026-09-30 🆕 revisão | Ponto de consumo (Metering) e execução (Assets) como provedores **obrigatórios** — perfil inválido sem eles | `arquitetura/modulos-e-perfis-de-implantacao.md` §15–§17; CEN-MOD-004 V4 | **Forte demais**: os dois módulos existem sem eles — parque de hidrômetros; ativos, planos e backlog. Condicionam **capacidade**; 🔴 só consumo e qualidade da água do Commercial (§15.2) |

| 2026-09-30 🆕 Fase 1 | "Datasource JNDI `java:/PostgresDS`" como único datasource | `arquitetura/arquitetura-legada.md` | São **dois**: `PostgresDS` (gsan_comercial) e `PostgresGerencialDS` (gsan_gerencial), cada um com sua SessionFactory em `HibernateUtil` |
| 2026-09-30 🆕 Fase 1 | O código do repositório pode não refletir produção — *"confirmar antes de qualquer implementação"* | `arquitetura/arquitetura-legada.md` | **Confirmado no sentido inverso**: o código de 2023 mapeia colunas e tabelas que nenhuma migração cria (DDL manual de produção) — ex.: `cadastro.cliente.clie_icrecusasubsidio`, `cadastro.dmc` ([relatório da Fase 1 §7](ambiente/fase1-ambiente-referencia.md#7-hibernate--schema)) |

---

## 5. Regra permanente

1. Toda afirmação 🟢 cita **arquivo:linha**.
2. Todo número cita **métrica e escopo**.
3. Toda afirmação de **inexistência** declara o comando de busca e o escopo varrido. 🆕 (2026-09-28) O escopo inclui a **camada**: busca só em `*.java` não prova inexistência no banco versionado — o índice de perda física do ecossistema GSAN existe como **função SQL** ([`operacional.md §6.3`](modulos/operacional.md)); e busca por nome de propriedade Java deve incluir o **nome da coluna**.
4. Nenhum documento técnico justifica decisão por autoridade do pedido ("o prompt exige"). Justifica-se por evidência e argumento — o pedido é contexto do projeto, não razão técnica.
5. Correção de fato publicado entra na tabela §4, **não** é apagada silenciosamente.
6. 🔴 **Total de tabela classificatória é derivado da tabela, nunca escrito à mão** — conferido por script antes do commit, com a conferência declarada no próprio documento. Regra criada em 2026-09-14, após os números errados de `estruturas-centrais.md`, e **exercida com sucesso em 2026-09-15**: o resumo do catálogo de funcionalidades futuras divergia da própria tabela nos três eixos e foi corrigido **antes** de publicar ([registro](alteracoes/2026-09-15-catalogo-funcionalidades-futuras.md)). ⚠️ A conferência não é só aritmética: ao recontar, duas capacidades (fiscal e SPED) revelaram-se **classificadas de forma incoerente com o restante do documento**.
7. 🆕 (2026-09-29) **Obrigação vigente não se descobre no legado.** Evidência do GSAN prova comportamento **histórico**; obrigação atual (fiscal, regulatória, de pagamento) exige varredura por **fonte oficial**, na hierarquia lei/decreto → regulamento → ANA → Receita/Portal DF-e → Banco Central → Ministério da Saúde → Ministério das Cidades → regulador. Requisito que nasce dela é **requisito nativo** (oráculo N), nunca classificado na matriz de compatibilidade. Fonte lida por resumo de busca, por bloqueio de rede, é declarada como tal e rebaixa a certeza.
8. 🆕 (2026-09-29) **Ausência de uso também exige prova completa.** *"Não observado"* só vale depois de ler **o método inteiro** que decide — a restrição por usuário estava no mesmo método cuja leitura parou antes do trecho relevante.
9. 🆕 (2026-09-29, adendo pós-Fase 0) **Equivalência semântica não se presume pelo nome.** Um dado interno e uma informação externa — regulatória, fiscal, de parceiro — só se relacionam por **definição comparada e decisão registrada**, refeitas a cada versão da definição externa. A matriz de compatibilidade já praticava isso entre GSAN e OpenGSAN; o adendo estende a regra à fronteira regulatória ([ADR-0009](decisoes/0009-sinisa-preenchimento-manual.md)).
