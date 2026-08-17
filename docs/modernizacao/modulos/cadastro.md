# Módulo Cadastro — Mapa Funcional

Elaborado em 2026-08-14 (Fase 0). Fontes: código do GSAN (`src/gcom/cadastro`, `src/gcom/atendimentopublico` para ligações), mapeamentos Hibernate, FKs e comentários do banco; `gsan_comercial` usado apenas como evidência complementar. Termos conforme o [glossário](../dominio/glossario.md).

## 1. Responsabilidade

O Cadastro é a **base de referência comercial** da companhia: descreve *quem* (clientes), *o quê* (imóveis e suas economias, ligações e classificação tarifária) e *onde* (estrutura territorial e endereços). Ele não fatura, não cobra e não arrecada — fornece a todos os demais módulos a identidade, a classificação e o estado dos objetos sobre os quais esses processos operam. No banco, 123 FKs apontam para `cadastro.imovel` — praticamente todos os processos do sistema dependem do Cadastro.

## 2. Principais capacidades

- Gerenciar imóveis (inclusão em passos/wizard, atualização, exclusão lógica, condomínios principal/vinculados).
- Gerenciar clientes (PF/PJ, documentos, endereços, telefones, responsável hierárquico).
- Relacionar cliente e imóvel com papel (proprietário/usuário/responsável), vigência e motivo de encerramento.
- Classificar imóveis: categoria/subcategoria e quantidades de economias; perfil do imóvel.
- Manter a estrutura territorial/comercial: gerência regional, unidade de negócio, localidade, setor comercial, quadra (e face de quadra), vínculo com rotas.
- Manter a base de endereçamento (logradouro, bairro, CEP) usada por imóveis, clientes e RAs.
- Registrar situações que modulam outros processos: situação especial de faturamento (paralisações), situação de cobrança, situação derivada do imóvel (ativo/inativo/só esgoto).
- Extensões nesta instalação: tarifa social/programas especiais, recadastramento (`atualizacaocadastral`), campos sociais, fotos de imóvel (tabela sem classe — uso mobile).

As **ligações de água e esgoto** são conceitualmente parte do cadastro do imóvel, mas o código que as efetua vive no módulo `atendimentopublico` (Actions `EfetuarLigacaoAgua*`, `EfetuarLigacaoEsgoto*`, `EfetuarReligacaoAgua*`) — a fronteira real é processo de atendimento → efeito cadastral.

## 3. Entidades e conceitos centrais

### 3.1 Imóvel

**O que representa**: a unidade atendível ("matrícula") — um ponto de fornecimento potencial ou efetivo, com localização comercial, classificação tarifária e estado. É o agregador do sistema.

**Identidade**:
- `imov_id` gerado por `cadastro.seq_imovel`; **estável** (não muda ao longo da vida do imóvel; alterações de endereço/perfil geram registros auxiliares, não novo id).
- A **matrícula exibida** = `imov_id` formatado com dígito verificador módulo 11 (`Imovel.getMatriculaFormatada()` + `Util.obterDigitoVerificadorModulo11`). Existe variante de DV específica de companhia (`obterDigitoVerificadorModuloCAERN`) — customização no núcleo.
- Exclusão é **lógica** (`imov_icexclusao`); histórico auxiliar: `imovel_endereco_anterior` (endereços anteriores), `imovel_historico_perfil` (perfis), auditoria genérica via `seguranca.tabela_linha_alteracao`.

**Responsabilidades hoje concentradas no Imovel** (registro do estado atual, sem decidir separação):

| Aspecto | Conteúdo no imóvel |
| ------- | ------------------ |
| Identificação | id/matrícula, nome, IPTU, contrato de energia (`numeroCelpe` — nomenclatura de companhia) |
| Localização | localidade, setor, quadra + face, lote/sublote, logradouro/bairro/CEP, coordenadas |
| Estrutura comercial | rotas (entrega/alternativa; leitura via quadra), sequencial na rota, grupo via rota |
| Classificação | perfil, categoria/subcategoria principal (denormalização), quantidade de economias (denormalização) |
| Ligações | situação da ligação de água (`last_id`) e de esgoto (`lest_id`) |
| Faturamento | dia/mês de vencimento, débito automático, situação especial de faturamento (`ftst_id`), tarifa (`cstf_id`) |
| Cobrança | situação de cobrança (`cbst_id`/`cbsp_id`), contadores de parcelamento/reparcelamento |
| Físico | área construída, reservatórios, piscina, pontos de utilização, moradores, poço |
| Social (extensões) | classe social, quantidade de economias sociais, exclusão de tarifa social, programas especiais |

**Módulos que dependem diretamente do Imóvel** (FKs + código): micromedição (medição, consumo, hidrômetro instalado), faturamento (conta, débito, crédito, guia), cobrança (parcelamento, negativação, documentos), arrecadação (pagamento), atendimento (RA, OS, ligações), recadastramento e mobile.

### 3.2 Cliente

Pessoa física/jurídica (`cadastro.cliente`: CPF/CNPJ, tipo, profissão/ramo, responsável hierárquico). Endereços e telefones em tabelas próprias (`cliente_endereco` — com triggers de auditoria no banco desta instalação —, `cliente_fone`). O Cliente **pertence conceitualmente ao Cadastro** (pacote `gcom.cadastro.cliente`, schema `cadastro`); os demais módulos o referenciam (pagamento, guia, negativação, RA).

### 3.3 Cliente × Imóvel

Relação **N:N com papel e vigência**, materializada em `cadastro.cliente_imovel` (`ClienteImovel`):

- **Papel** (`ClienteRelacaoTipo`): Proprietário(1), Usuário(2), Responsável(3).
- **Vigência**: `clim_dtrelacaoinicio` / `clim_dtrelacaofim`; relação **ativa = data fim nula**. Histórico completo permanece na própria tabela.
- **Troca de cliente** = encerrar a vigência atual com motivo (`ClienteImovelFimRelacaoMotivo` — ex.: EXCLUSAO_IMOVEL=6, EXCLUSAO_PROGRAMA_ESPECIAL=8, POR_ATU_CADASTRAL=10) e criar nova relação. A conta emitida preserva os clientes daquele momento em `cadastro.cliente_conta`.
- `clim_icnomeconta` indica **qual cliente dá nome à conta** impressa.
- Um imóvel pode ter simultaneamente proprietário, usuário e responsável distintos; um cliente pode estar em muitos imóveis.

Não é um `imovel.cliente_id` — a relação intermediária com papel/vigência é estruturante e deve ser preservada conceitualmente.

### 3.4 Economia

**O que é**: unidade autônoma de consumo dentro do imóvel (moradia, loja...), classificada por subcategoria — a "unidade tarifária". O imóvel tem 1..N economias; tarifas mínimas e faixas aplicam por economia.

**Representações e seus papéis** (dúvida 1 do glossário — **resolvida**):

| Representação | Estrutura | Papel |
| ------------- | --------- | ----- |
| Agregada por subcategoria | `imovel_subcategoria` (PK imov+scat, `imsb_qteconomia`) | **Governa os processos.** É o que `ControladorImovel.obterQuantidadeEconomias*` consulta (HQL sobre `ImovelSubcategoria` em `RepositorioImovelHBM`), alimentando cálculo de tarifa por categoria |
| Total no imóvel | `imov_qteconomia` | Denormalização de conveniência (exibição/validações) |
| Individualizada | `imovel_economia` (por imov+scat) | Detalhamento informativo — usada apenas por relatórios cadastrais (`RelatorioDadosEconomiaImovel`, dados cadastrais/clientes relacionados); **não** participa do cálculo de faturamento |
| Fotografia na conta | `faturamento.conta_categoria` (`ctcg_qteconomia` + valores/consumos/mínimos por categoria) | Registro imutável do que foi considerado na emissão |
| Social (extensão) | `imov_qtd_economias_social` | Customização de tarifa social desta instalação |

**Obrigatoriedade de `imovel_economia`**: a evidência de uso (só relatórios) indica registro **complementar/opcional**; não foi possível provar com DDL apenas se toda instalação a popula — registrado como ressalva (verificável com dados reais: comparar contagens `imovel_economia` × `imsb_qteconomia`).

### 3.5 Categoria e Subcategoria

- `cadastro.categoria` e `cadastro.subcategoria`; **Subcategoria pertence a uma Categoria** (`catg_id` na subcategoria, many-to-one confirmado).
- **A classificação é das economias, não do imóvel inteiro**: um imóvel pode ter economias em múltiplas categorias simultaneamente (ex.: prédio com lojas e apartamentos) via `imovel_subcategoria`. O imóvel guarda apenas categoria/subcategoria **principal** como denormalização (`imov_idcategoriaprincipal`/`imov_idsubcategoriaprincipal`).
- A Categoria carrega **parâmetros de análise de consumo** usados pela micromedição e faturamento: `consumoMinimo`, `consumoEstouro`, `vezesMediaEstouro`, `mediaBaixoConsumo`, `consumoAlto`, `consumoMaximoEc` — categoria não é só rótulo, é parametrização de regra.
- **Fotografado em Conta**: `conta_categoria` grava, por categoria: quantidade de economias, valores e consumos de água/esgoto, tarifa mínima e consumo mínimo — insumo direto da futura análise do Faturamento.

### 3.6 Ligação de Água

- **Padrão estrutural**: extensão 1:1 do imóvel **por construção** — as Actions criam a ligação copiando o id (`ligacaoAgua.setId(imovel.getId())` em `EfetuarLigacaoAguaComInstalacaoHidrometroSemRAAction`, `EfetuarReligacaoAguaAction`); FK `lagu_id → cadastro.imovel(imov_id)`. Não é convenção acidental: é identidade compartilhada intencional ("dados de ligação do imóvel").
- **Estado atual**: no **imóvel** (`imov.last_id`). A tabela `ligacao_agua_situacao` é **paramétrica** — cada situação define comportamento: `last_icfaturamento` (fatura ou não), `last_nnconsumominimo` (consumo mínimo da situação), indicadores cadastrada/ativa/desligada/em análise, existência de rede/ligação/abastecimento, "só faturar consumo real", dias para corte. **As regras de faturamento por situação são dados, não código.**
- **Histórico**: parcial, na própria ligação (datas de ligação, corte, religação, supressão, corte administrativo, restabelecimento; selos e lacre); o detalhe dos eventos fica nas OSs que os executaram. Não há tabela de histórico de situações da ligação.
- **Quem altera a situação**: efetivação de ligação/religação (Actions de atendimento), encerramento de OS (indicadores `orse_icatualizaagua`/`orse_icatualizaesgoto` — corte, religação, supressão, fiscalização) e recadastramento.
- **Fotografia**: Conta grava `last_id`/`lest_id` **e** `cnta_pcesgoto` (percentual de esgoto) e `cnta_pccoleta` — dúvida 2 do glossário **resolvida**: a conta congela a condição vigente na emissão para auditoria/recálculo, pois o estado do imóvel muda depois (corte, religação, mudança de percentual). Parcelamento também fotografa (`parc` → `last_id`/`lest_id`), registrando a condição do imóvel no ato da negociação.

### 3.7 Ligação de Esgoto

Mesmo padrão (FK `lesg_id → imov_id`; situação no imóvel `lest_id`; características técnicas próprias). Situações (`LigacaoEsgotoSituacao`): POTENCIAL(1), FACTIVEL(2), LIGADO(3), EM_FISCALIZACAO(4), LIG_FORA_DE_USO(5), TAMPONADO(6). O valor de esgoto da conta deriva do consumo de água pelo **percentual de esgoto**, fotografado na conta — a regra de cálculo em si pertence ao Faturamento (aprofundar lá).

### 3.8 Estrutura territorial e comercial

Hierarquia **confirmada** por FKs/mapeamentos:

```text
Gerência Regional ─┐
Unidade de Negócio ┴─ Localidade (auto-relação "elo"/pólo; município principal)
                        └── Setor Comercial (código dentro da localidade; município)
                              ├── Quadra (código no setor; bairro; face de quadra; recortes operacionais)
                              │     └── Imóvel (lote/sublote + face de quadra + sequencial de rota)
                              └── Rota (pertence ao setor; e a um Grupo de Faturamento)
                                    ↑ Quadra referencia sua Rota (N quadras : 1 rota)
```

- Rota **não** contém quadras hierarquicamente: a quadra aponta para a rota (`qdra.rota_id`); a rota pertence ao setor e ao grupo de faturamento (cronograma AAAAMM, dia de vencimento).
- **Múltiplas rotas no imóvel** (dúvida 6 do glossário — **resolvida no essencial**):

| Rota | Onde | Uso comprovado |
| ---- | ---- | -------------- |
| Rota territorial/de leitura | via `quadra.rota_id` | processos territoriais e de campo: emissão de ordens de corte/fiscalização, atualização cadastral, relatórios do imóvel |
| Rota de entrega | `imov.rota_identrega` | entrega de contas/2ª via (`Relatorio2ViaConta*`), definida na conclusão do cadastro do imóvel |
| Rota alternativa | `imov.rota_idalternativa` | micromedição/faturamento com dispositivo móvel: análise de exceções de leitura, impressão simultânea de contas, movimento celular |

  A precedência exata entre elas dentro do processo de leitura/faturamento será confirmada no mapa da Micromedição.
- **Processos influenciados**: leitura (rota/quadra/sequencial), faturamento (grupo da rota → cronograma e vencimento), entrega (rota de entrega), cobrança (grupo/critério/empresa por rota), atendimento e operacional (recortes de quadra: bacia, distrito, ZEIS).

### 3.9 Endereço

Base própria de endereçamento em `gcom.cadastro.endereco`: `Logradouro` (+ tipo/título), `Bairro`, `Cep`, e as associações `LogradouroBairro` e `LogradouroCep`. O **imóvel** endereça-se por `lgbr_id` + `lgcp_id` + número + complemento (+ referência e perímetro em RA); o **cliente** possui N endereços tipificados (`cliente_endereco`); mudanças de endereço do imóvel preservam o anterior (`imovel_endereco_anterior`). RAs sem imóvel usam a mesma base (logradouro/bairro/local de ocorrência).

## 4. Relações principais (atualização do mapa do glossário)

```text
Cliente ══ ClienteImovel {papel, vigência, nome-na-conta, motivo de fim} ══ Imóvel
Imóvel ──1:1(id compartilhado por construção)── Ligação de Água ── situação PARAMÉTRICA (flags de faturamento)
Imóvel ──1:1── Ligação de Esgoto ── percentual de esgoto → fotografado na Conta
Imóvel ── economias agregadas por Subcategoria (GOVERNA tarifa) ── Categoria {parâmetros de consumo}
Imóvel ── Localidade/Setor/Quadra(+Face) ── Quadra→Rota(leitura) | Rota de entrega | Rota alternativa (móvel)
Rota ── Grupo de Faturamento {cronograma AAAAMM, vencimento}
Conta ── fotografa: clientes (cliente_conta), categorias/economias (conta_categoria),
         situações das ligações, percentual esgoto, tarifa
OS (encerramento) ── atualiza situação das ligações do imóvel
Situação derivada do imóvel (imovel_situacao_tipo: ATIVO/INATIVO/LIGADO_SO_ESGOTO)
         = combinação paramétrica (imovel_situacao: last × lest) — usada pelo atendimento
```

## 5. Regras estruturantes identificadas

1. **Matrícula estável com DV**: a identidade pública do imóvel é o `imov_id` com dígito módulo 11; nunca é reaproveitada; exclusão é lógica.
2. **Economias agregadas governam a tarifa**: o cálculo consulta `imovel_subcategoria` (por categoria); a individualização é informativa; a conta congela o que foi usado (`conta_categoria`).
3. **Situação da ligação é parametrizada por dados**: faturar ou não, consumo mínimo, corte etc. são atributos da situação (`ligacao_agua_situacao`), não `if`s por código — flexibilidade que **deve ser preservada** no SISAN.
4. **Estados que alteram faturamento** vêm de três eixos: situação das ligações (flags), situação especial de faturamento do imóvel (`FaturamentoSituacaoTipo`: NORMAL(0), PARALISAR_EMISSAO_CONTAS(1), PARALISAR_LEITURA_FATURAR_MEDIA(2), PARALISAR_LEITURA_FATURAR_TAXA_MINIMA(3), FATURAR_NORMAL(5)) e situação de cobrança.
5. **Relação cliente×imóvel tem papel, vigência e motivo** — nunca reduzir a um FK simples; a conta preserva os clientes da emissão.
6. **Fotografias na emissão**: conta e parcelamento congelam situações/percentuais/categorias vigentes — trilha de auditoria financeira.
7. **A execução de serviços retroalimenta o cadastro** (atualiza situação das ligações) — cadastro e atendimento são acoplados por regra de negócio, não apenas por referência. **Precisão (2026-08-14, mapa do Atendimento)**: o efeito **não é gatilho automático do encerramento da OS**, e sim resultado das operações de negócio específicas (Actions "Efetuar ligação/religação/instalação/substituição/retirada…"), que atualizam o domínio dono e **marcam a OS** com `orse_iccomercialatualizado` e `orse_icatualizaagua`/`icatualizaesgoto` como registro de que a atualização já ocorreu. Ver [atendimento.md §16](atendimento.md).
8. **A situação "do imóvel" é derivada** das situações das ligações via tabela paramétrica (`imovel_situacao` → `imovel_situacao_tipo` ATIVO/INATIVO/LIGADO_SO_ESGOTO); o atendimento usa essa derivação para habilitar tipos de solicitação.
9. **Estrutura territorial é encadeada e estrita** (localidade→setor→quadra→imóvel), com a rota atravessando (setor+grupo; quadra→rota; imóvel com rotas específicas de entrega/alternativa).

## 6. Estados relevantes

| Objeto | Estados estruturais | Fonte |
| ------ | ------------------- | ----- |
| Ligação de água (no imóvel) | Potencial(1), Factível(2), Ligado(3), [4 — ambíguo: "à revelia"/"em análise"], Cortado(5), Suprimido(6) + flags paramétricas por situação | `LigacaoAguaSituacao` + tabela paramétrica |
| Ligação de esgoto (no imóvel) | Potencial, Factível, Ligado, Em fiscalização, Fora de uso, Tamponado | `LigacaoEsgotoSituacao` |
| Situação derivada do imóvel | Ativo(1), Inativo(2), Ligado só esgoto(3) | `ImovelSituacaoTipo` via `imovel_situacao` |
| Faturamento do imóvel | Normal, Paralisar emissão, Paralisar leitura+faturar média, Paralisar leitura+faturar taxa mínima, Faturar normal | `FaturamentoSituacaoTipo` (`imov.ftst_id`) |
| Cadastro | ativo × excluído lógico (`imov_icexclusao`); pendências de recadastramento (extensão) | `Imovel` |
| Relação cliente×imóvel | ativa (fim nulo) × encerrada (com motivo) | `ClienteImovel` |

**Ponto de atenção**: o valor 4 da situação de água tem duas constantes (`LIGADO_A_REVELIA` e `LIGADO_EM_ANALISE`) — a semântica efetiva é **dado da instalação** (descrição na linha da tabela paramétrica), que o DDL exportado não contém. Resolver exige dados reais de uma instalação.

## 7. Dependências com outros módulos

| Módulo | Como depende do Cadastro |
| ------ | ------------------------ |
| Micromedição | Leitura/consumo por imóvel e ligação; hidrômetro instalado na ligação/imóvel; rota (via quadra + alternativa) e sequencial de rota organizam o trabalho de campo; parâmetros de análise de consumo vêm da Categoria |
| Faturamento | Conta por imóvel; economias/categorias (via `imovel_subcategoria`) definem tarifa; situações (ligação + `ftst`) decidem se/como faturar; grupo de faturamento via rota; vencimento do imóvel; fotografa tudo na emissão |
| Cobrança | Situação de cobrança gravada no imóvel; parcelamento por imóvel (fotografa situações); corte/religação viram OS que atualizam o cadastro; grupos/critérios de cobrança por rota |
| Arrecadação | Pagamento referencia imóvel e/ou cliente; devoluções ao cliente |
| Atendimento (RA/OS) | RA referencia imóvel ou endereço da base cadastral; tipos de solicitação habilitados pela situação derivada do imóvel; OS executa e retroalimenta situação das ligações |
| Recadastramento / Mobile (extensões) | `atualizacaocadastral` e schema `mobile` leem/atualizam imóvel, economias, características e fotos |
| Segurança | Abrangência de usuário por localidade/gerência (restringe o que cada usuário vê/faz) |

## 8. Pontos de compatibilidade GSAN → SISAN

Classificação preliminar (ADR-0006; sem decisão de modelo físico):

| Conceito/estrutura | Classificação preliminar | Motivo |
| ------------------ | ------------------------ | ------ |
| Matrícula do imóvel (id estável + DV) | PRESERVAR CONCEITO | Identidade pública e chave de migração; DV é conhecido dos usuários |
| Relação Cliente×Imóvel (papel+vigência+motivo) | PRESERVAR CONCEITO | Regra de negócio madura; histórico embutido |
| Economias agregadas por subcategoria | PRESERVAR CONCEITO | Governa tarifa; simples e migrável |
| Categoria/Subcategoria com parâmetros de consumo | PRESERVAR CONCEITO | Parametrização provada; central ao faturamento |
| Situações paramétricas de ligação (flags de faturamento) | PRESERVAR CONCEITO | "Regra como dado" é força do GSAN; modernizar apenas a forma |
| Fotografias na emissão (conta_categoria, situações, percentuais) | PRESERVAR CONCEITO | Auditoria financeira e reprodutibilidade |
| Estrutura territorial (localidade/setor/quadra/rota) | PRESERVAR CONCEITO | Consolidada, atravessa todos os processos |
| Ligação 1:1 com id compartilhado | EXIGE APROFUNDAMENTO | Decidir na modelagem: entidade própria × extensão; migração precisa mapear o padrão atual |
| Situação derivada do imóvel (`imovel_situacao`) | EXIGE APROFUNDAMENTO | Confirmar uso real e completude da parametrização |
| Denormalizações (`imov_qteconomia`, categoria principal, rota de entrega no imóvel) | POSSÍVEL MODERNIZAÇÃO | Conveniências que podem virar consultas/projeções no SISAN |
| Endereçamento próprio (logradouro/bairro/CEP) | POSSÍVEL MODERNIZAÇÃO | Conceito ok; avaliar higienização e integração com bases externas |
| Campos sociais e programas especiais no imóvel | EXIGE APROFUNDAMENTO | Separar núcleo × extensão de companhia antes de transportar |
| Nomenclaturas de companhia no núcleo (`numeroCelpe`, DV CAERN) | POSSÍVEL MODERNIZAÇÃO | Generalizar nomes preservando semântica e migração |

## 9. Hipóteses para avaliação futura (não são decisões)

1. **Economia como conceito explícito** no modelo do SISAN (entidade/valor com quantidade por subcategoria), mantendo equivalência direta com `imovel_subcategoria` para migração trivial.
2. **Decomposição do agregado Imóvel** em aspectos coesos (identificação/localização; classificação/economias; situação; parâmetros de faturamento/cobrança; extensão social) preservando a matrícula única — motivada pela concentração descrita em 3.1.
3. **Ligação como entidade com identidade própria** e FK ao imóvel (a migração mapearia `lagu_id=imov_id` → nova chave), OU manutenção do padrão extensão-1:1 — decidir com a análise de micromedição/faturamento.
4. **Situações como dados versionados** (manter o modelo paramétrico do GSAN com governança de mudanças/migrations), eliminando as constantes duplicadas no código.
5. **Extensões de companhia como módulo separado** (social/NIS/programas/recadastramento) plugado ao núcleo do cadastro, para que o núcleo SISAN permaneça genérico.

## 10. Dúvidas que permanecem

1. **Semântica do valor 4** da situação de água nesta instalação — requer dados reais (linha da tabela paramétrica).
2. **`imovel_economia` é populada em todas as instalações?** Uso comprovado apenas informativo; confirmar com dados (contagens × `imsb_qteconomia`).
3. ~~Precedência exata das três rotas~~ **Resolvida (2026-08-14, mapa da Micromedição)**: nos processos de leitura/análise, a rota alternativa do imóvel, quando definida, **sobrepõe** a rota da quadra (consultas com dois ramos em `RepositorioMicromedicaoHBM.pesquisarImovelExcecoesLeituras`); rota de entrega segue exclusiva da distribuição. Ver [micromedicao.md §3.10](micromedicao.md).
4. **Completude de `imovel_situacao`** (todas as combinações last×lest têm classificação?) — verificar com dados.
5. ~~Regra de cálculo do valor de esgoto~~ **Resolvida (2026-08-14, mapa do Faturamento)**: percentuais definidos na Ligação de Esgoto (`lesg_pcesgoto`, `lesg_pccoleta`, alternativo acima de limite de consumo), aplicados sobre o volume derivado da água (+poço) e **fotografados na conta** (`cnta_pcesgoto`/`cnta_pccoleta`). Ver [faturamento.md §10](faturamento.md).

## 11. Evidências principais

```text
Identidade:    Imovel.getMatriculaFormatada() (Imovel.java:1969); Util.obterDigitoVerificadorModulo11; cadastro.seq_imovel
Ligações 1:1:  EfetuarLigacaoAguaComInstalacaoHidrometroSemRAAction.java:89 (setId(imovel.getId())); FKs fk15_ligacao_agua/fk10_ligacao_esgoto → imov_id
Situação param.: DDL atendimentopublico.ligacao_agua_situacao (last_icfaturamento, last_nnconsumominimo, last_ic*)
Economias:     ControladorImovelSEJB.obterQuantidadeEconomias*(:315,1394+); RepositorioImovelHBM (HQL sobre ImovelSubcategoria:938,1320,1730);
               ImovelEconomia referenciada apenas em relatorio/cadastro/imovel/*
Fotografias:   Conta.hbm (last_id, lest_id, cnta_pcesgoto, cnta_pccoleta); ContaCategoria.hbm → faturamento.conta_categoria (ctcg_qteconomia, mínimos)
Cliente×Imóvel: ClienteImovel.hbm (clim_dtrelacaoinicio/fim, clim_icnomeconta); ClienteRelacaoTipo (1/2/3); ClienteImovelFimRelacaoMotivo
Território:    SetorComercial.hbm (loca_id); Quadra.hbm (stcm_id, rota_id); Rota.hbm (stcm_id, ftgr_id); Imovel.hbm (qdra_id, qdfa_id, rota_identrega/idalternativa)
Rotas em uso:  Relatorio2ViaConta* (rotaEntrega); ExibirDadosAnaliseExcecoesLeituraResumido/ProcessarRequisicaoDipositivoMovelImpressaoSimultanea (rotaAlternativa);
               EmitirOrdemCorteAction e ControladorAtualizacaoCadastral (quadra.getRota())
Estados:       LigacaoAguaSituacao/LigacaoEsgotoSituacao/ImovelSituacaoTipo/FaturamentoSituacaoTipo (constantes)
Dependências:  123 FKs REFERENCES cadastro.imovel no DDL
```
