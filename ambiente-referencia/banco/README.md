# Banco de referência do GSAN legado

Como `gsan_comercial` e `gsan_gerencial` são reconstruídos, e **por que** cada intervenção existe. Regra: o histórico de
migrações do GSAN não é corrigido; o que ele não consegue fazer sozinho numa base nova fica numa camada explícita deste
ambiente, com evidência. Nada aqui é "GSAN corrigido".

## 1. Fonte

| Item | Valor |
| ---- | ----- |
| Migrações | `Joao-PSF/gsan-migracoes`, commit fixado em [`../versoes.env`](../versoes.env) (o mesmo do `prodigasistemas/gsan-migracoes` na data) |
| Comercial | 301 scripts: o dump só de schema de 2016 (`20160118183224_dump.sql`, PostgreSQL 9.4.4) + a evolução até 2024-06 |
| Gerencial | 5 scripts (dump de schema + casts + grants) |
| Servidor | PostgreSQL 9.5.25 (versão da receita), cluster e bancos em LATIN1, locale `pt_BR.ISO-8859-1` |
| Tablespace | `indices` em `/opt/pgsql/indices`, criado pela própria migração `20160118183216` (a receita e o README do `gsan-migracoes` o pré-criam, o que faria a migração falhar) |

⚠️ O `comercial/dump.sql` da raiz do `gsan-migracoes` (PostgreSQL 9.5.2) **não** é usado pelas migrações e também é só schema.
Não existe carga oficial de dados de referência: a wiki do GSAN não prevê nenhuma.

## 2. Executor de migrações

[`../scripts/migrar.sh`](../scripts/migrar.sh) reproduz o MyBatis Migrations configurado pelos `environments/*.exemplo.properties`
do próprio repositório (`send_full_script=true`, `auto_commit=false`, `changelog=CHANGELOG`): ordem pelo ID, só a seção
"do" (antes de `-- //@UNDO`), `${changelog}` → `CHANGELOG`, uma sessão nova e uma transação por script, registro em
`CHANGELOG` na mesma transação, parada no primeiro erro. Desvios:

| Desvio | Motivo |
| ------ | ------ |
| Codificação por arquivo (`GSAN_MIGRACOES_CODIFICACAO=detectar`) | 273 scripts são ASCII, 26 são UTF-8 e 2 são LATIN1 (inclusive o dump, com trechos mistos). `script_char_set=LATIN1` da receita leria os 26 em UTF-8 como LATIN1 e gravaria texto corrompido (ex.: o menu). `latin1` reproduz a receita |
| `CREATE TABLESPACE` fora de transação | O PostgreSQL não aceita o comando em bloco transacional; com `auto_commit=false` o MyBatis falharia |
| `INSERT INTO public.CHANGELOG` | O dump deixa o `search_path` em outro schema; no MyBatis o registro usa outra conexão |
| Camada de pré-requisitos P1–P5 | §3 |

Diagnóstico: `GSAN_MIGRAR_DIAGNOSTICO=1` segue depois de erro e lista todas as falhas em `.saida/diagnostico-<banco>.tsv`
— foi assim que a camada abaixo foi levantada. **Numa base nova, sem ela, 52 das 301 migrações comerciais falham**
(contando falhas em cascata).

## 3. Pré-requisitos — classes P1 a P6

| Classe | O quê | Onde |
| ------ | ----- | ---- |
| **P1** | Papel de banco referenciado por migração e criado por nenhuma — criado `NOLOGIN` | `sementes/comercial/<ID>.sql` |
| **P2** | Sequence: sincronização única ao fim da carga em massa + avanço mínimo antes de cada `nextval()` | `sementes/comercial/20160118183249.sql`, [`sequencias-comercial.tsv`](sequencias-comercial.tsv) |
| **P2b** | Valor de sequence evidenciado por migração posterior que cita o ID gerado | `sementes/comercial/<ID>.sql` |
| **P3** | Linha de referência que a migração pressupõe (FK ou busca por nome) | `sementes/comercial/<ID>.sql` |
| **P3-DDL** | Objeto que a migração altera e que nenhuma migração cria | `sementes/comercial/<ID>.sql` |
| **P4** | Correção sintática mínima, com o diff declarado | `correcoes/comercial/<ID>.sql` (substitui a seção "do") |
| **P5** | Migração não aplicável numa base nova — não executada, registrada em `public.referencia_nao_aplicada` | [`nao-aplicaveis-comercial.tsv`](nao-aplicaveis-comercial.tsv) |
| **P6** | Complemento estrutural derivado do mapeamento Hibernate | [`complemento-comercial.sql`](complemento-comercial.sql) (gerado), [`complemento-tabelas.tsv`](complemento-tabelas.tsv) |

Sementes e correções rodam **antes da migração do mesmo ID, na mesma transação**. Cada arquivo traz no cabeçalho a
evidência. Identificadores e nomes vêm de **constantes do código** sempre que existem; o que não tem evidência é criado
como **SINTÉTICO**, com essa palavra no nome.

### 3.1 Sementes (P1, P2, P2b, P3, P3-DDL)

| Antes de | Classe | Conteúdo | Evidência |
| -------- | ------ | -------- | --------- |
| 20160118183249 | P2 | Sequences da segurança levadas ao maior ID da carga `popula_*` (funcionalidade 16025, operação 15047…) | IDs de 2023 citados por migrações (16108, 15123) mostram a sequence de produção seguindo a partir daí |
| 20160902145028 | P3 | `lancamento_item` 3, `lancamento_item_contabil` 2 | `LancamentoItem.GRUPO_CONTABIL`, `LancamentoItemContabil.ACRESCIMOS_POR_IMPONTUALIDADE`; vínculo com o item 3 em 20170925195225 |
| 20161117200212 | P3 | `processo_tipo` 1–7 | `ProcessoTipo` |
| 20170317194824 | P3 | `lancamento_item_contabil` 6 | `LancamentoItemContabil.OUTROS_SERVICOS_AGUA` |
| 20170504180427 | P1 | papel `gsan_operacional` | `GRANT` na própria migração |
| 20170512142138 | P3 | `unidade_processamento` 1–21 (menos 13); processo 151 **sintético** | `UnidadeProcessamento`; o 151 não tem constante |
| 20180201192322 | P3 | processo 49 **sintético** | citado pela migração, sem constante |
| 20180216205135 | P3 | 27 grupos de produção (46 = ATENDENTE LOJA; os demais **sintéticos**, sem usuários) | concessões por ID nas migrações; `Grupo.ATENDENTE_LOJA` |
| 20181107145817 | P3 | negativadores 1 e 2 | `Negativador.NEGATIVADOR_SPC/SERASA` |
| 20190211144931 | P3 | processo 507 | `Processo.ATUALIZACAO_CADASTRAL` |
| 20210203135248 | P3 | categorias 1–4 | `Categoria.RESIDENCIAL/COMERCIAL/INDUSTRIAL/PUBLICO` |
| 20210519175719 | P3 | grupo "CADASTRO PERFORMANCE" (ID sintético) | busca por nome na migração |
| 20210806133855 | P3 | processo "ENVIAR NOTIFICAÇÃO DE VENCIMENTO" (ID sintético) | a migração 20210623185452, que deveria criá-lo, tem a seção "do" **vazia**; a descrição vem do UNDO |
| 20210825174243 | P3-DDL | tabela e sequence `cadastro.cliente_login` | o `CREATE` de 20210708140147 está **inteiro dentro de um comentário `/* */`**; a semente é esse DDL (linhas 6-61), sem alteração; o código a mapeia (`ClienteLogin.hbm.xml`) |
| 20210920163300 | P3 | processo 2 | `Processo.FATURAR_GRUPO_FATURAMENTO` |
| 20220829132752 | P3-DDL | coluna `cadastro.imovel.cntt_copasa` | a migração a renomeia para `imov_idparametrosconvenio`, que `Imovel.hbm.xml` mapeia — sem ela toda leitura de Imóvel falharia |
| 20220831201946 | P3 | `financiamento_tipo` 1 | `FinanciamentoTipo.SERVICO_NORMAL` |
| 20230510162223 | P2b | `seq_funcionalidade` em 16107 | 20230510162447 cita 16108 e 16109 |
| 20230510162447 | P2b | `seq_operacao` em 15122 | 20230510162504 cita 15123 |
| 20230602183243 | P1 | papéis `pg_users` e `pg_aplic` | `GRANT` na própria migração |

Grupos por ID e a primeira migração que cita cada um: 3, 69, 73 (20180726192503); 11 (20180216205135); 46, 47, 48, 67
(20200430174643); 16, 20, 21, 34, 39, 42, 43, 49, 50, 52–56, 58, 61–63, 108 (20210203140041).

**Correção registrada (P2)** — a primeira versão sincronizava a sequence com o maior ID antes de **cada** migração. Isso a
empurrava para IDs explícitos altos (ex.: operação 16044, inserida à mão por uma migração) e produzia colisões mais
adiante. Em produção, a sequence de operação estava na faixa de 15 mil (15123 em 2023) com IDs explícitos 16 mil acima.
Regra correta: sincronizar **uma vez**, ao fim da carga em massa, e depois só **pular IDs ocupados** — com isso os IDs
citados pelas migrações de 2023 saem idênticos aos de produção.

### 3.2 Correção sintática (P4)

`20170622185345_Criar_tabela_de_parametros_de_cobranca.sql`: falta o `;` depois do `)` do `CREATE TABLE cobranca.parametro`;
o PostgreSQL rejeita o script inteiro com qualquer ferramenta. A correção difere do original em **uma linha**. Migrações
seguintes inserem parâmetros nessa tabela.

### 3.3 Não aplicáveis (P5)

| Migração | Classe | Motivo |
| -------- | ------ | ------ |
| 20161027190135 | histórico inconsistente | `DROP SEQUENCE` num schema para onde a sequence nunca foi movida |
| 20180807124455 | já satisfeita | coluna já criada por 20180725133250 |
| 20180831012134 | já satisfeita | reinsere operações criadas por 20180827195154 e 20180828151607 |
| 20220524164400 | **segurança** | insere **credenciais OAuth (uid e secret)** de aplicações clientes da GSAN-API numa tabela que nenhuma migração cria — nunca aplicada |
| 20230323191825 | já satisfeita | reinsere `lancamento_item` 135 e 136, já inseridos por 20220913142020 |

Resultado: `gsan_comercial` com **296 migrações no `CHANGELOG` + 5 não aplicáveis = 301**; `gsan_gerencial` com **5 de 5**.

## 4. Complemento estrutural (P6)

O código (commit legado fixado) mapeia objetos que **nenhuma** migração cria — em produção vieram de DDL manual. Hibernate
não valida o schema ao subir: o objeto ausente só falha quando a entidade é usada, e **coluna ausente em tabela existente
quebra toda leitura da entidade**. [`../scripts/mapeamento.py`](../scripts/mapeamento.py) lê as classes que cada
SessionFactory registra em `HibernateUtil.java` (comercial: 702; gerencial: 83), compara cada uma com o banco dela e
classifica toda divergência:

| Política | Tratamento |
| -------- | ---------- |
| Coluna ausente em tabela existente de classe da SessionFactory **comercial** | **complementa** (coluna anulável, tipo do mapeamento) — BLOQUEIA MÓDULO NECESSÁRIO AO ORÁCULO |
| Tabela ausente listada em [`complemento-tabelas.tsv`](complemento-tabelas.tsv), com justificativa | **complementa**, com a sequence do gerador |
| Outras tabelas ausentes do comercial | **transferida** — BLOQUEIA SOMENTE CENÁRIO FUTURO |
| Sequence ausente fora de tabela complementada | **transferida** (só afeta inclusão) ou **excluída** se o nome aponta para schema inexistente (defeito do legado, ex.: `atedimentopublico.*`) |
| SessionFactory **gerencial** (resumos e indicadores) | **transferida** — NÃO RELEVANTE PARA A FASE |
| View, nome com mais de um qualificador, banco externo (UPA/SAM) | **excluída** — defeito de mapeamento, definição desconhecida ou integração externa |

O complemento aplicado tem **14 itens**: 13 colunas (`Cliente`, `QuadraFace`, `DebitoAutomatico`, `CadastroUnico`,
`FiscalizacaoColetiva`, `DadosPagamentosNaoClassificados` e três histogramas) e a tabela `cadastro.dmc` com sua sequence (a
Fase 0 já registrara que ela "deriva de schema", sem migração). O arquivo é **gerado** e o procedimento exige que a
regeneração seja idêntica à versão commitada; é aplicado uma vez (`public.referencia_complemento`) e reverificado.
Divergências que continuam abertas, todas classificadas: comercial 25 (22 transferidas, 3 excluídas), gerencial 59
(56 transferidas, 3 excluídas) — lista em `.saida/mapeamento.tsv`.

## 5. Pós-migração — configuração da instância

[`../scripts/pos-migracao.sh`](../scripts/pos-migracao.sh):

1. rotação das senhas dos papéis `gsan_*` criados com senha igual ao login (valores aleatórios, não guardados);
2. senha do `admin` pela de `GSAN_ADMIN_SENHA`, no formato do legado (Base64 de SHA-1);
3. `seguranca.parametro URL_SEGURANCA` → stub interno de SSO (nenhuma migração o cria; sem ele toda requisição falha);
4. logomarca vazia em `sistema_parametros` (o seed não a define e `login.jsp` não aceita nulo; `""` é o caso "sem logomarca");
5. variante de companhia, se `GSAN_VARIANTE` estiver definida;
6. [`massa-verificacao.sql`](massa-verificacao.sql): esfera de poder 4 (`EsferaPoder.PARTICULAR`), um tipo de cliente e um
   cliente **sintéticos** — só para a consulta de domínio da verificação. Não é massa de caracterização (Fase 2).

## 6. Limitações conhecidas

- **Dados de referência de negócio praticamente vazios**: categorias, tipos e situações existem só onde as migrações ou a
  camada acima os criaram. O catálogo de processos batch (`batch.processo` / `processo_funcionalidade`) fica quase vazio —
  sem ele, nenhum processo batch executa. Montar a massa é da Fase 2.
- **Grupos de produção sintéticos**: 27 grupos existem só para as concessões das migrações aplicarem; não têm usuários.
- **Parâmetros de produção**: `seguranca.parametro` e `sistema_parametros` trazem URLs de APIs da companhia de origem
  (semeadas pelas migrações). Inalcançáveis na rede isolada; a funcionalidade que as usa falha ao ser acionada.
- **Tabelas e sequences transferidas** (§4) não existem: as funcionalidades que as usam (resumos contábeis por conta,
  controle de hidrômetro retornado, tabelas de dicionário SGBD, testes de medição) falham se acionadas.
- **Collation**: `pt_BR.ISO-8859-1` do glibc atual; a ordenação pode diferir da de uma instalação antiga.
