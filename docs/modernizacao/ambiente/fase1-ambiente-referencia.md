# Fase 1 — Ambiente de referência do GSAN legado

> Relatório da Fase 1 do [plano de trabalho](../plano-de-trabalho.md): *"legado executável de forma controlada"*, com o
> critério de aceite *"build + deploy do EAR reproduzidos do zero seguindo apenas a documentação"*. O procedimento está em
> [`ambiente-referencia/README.md`](../../../ambiente-referencia/README.md); o banco, item a item, em
> [`ambiente-referencia/banco/README.md`](../../../ambiente-referencia/banco/README.md).
>
> ⚠️ **A Fase 1 prepara o oráculo; não captura baseline.** Nenhum cenário crítico foi executado e nenhum golden master
> existe — isso é a Fase 2.

## 0. Estado de entrada

| Item | Valor |
| ---- | ----- |
| Linha principal | `master` = `ac9b623` — merge do PR #1: legado `1a0edcf` (2023-10-10) + documentação da Fase 0 `c5be172` |
| Fase 0 | Concluída em 2026-09-29, com dois adendos e a revisão final consolidada (2026-09-30) |
| Fase 1 | "Não iniciada" no repositório; havia trabalho local não commitado de uma sessão anterior (`ambiente-referencia/`: build, banco, pré-requisitos P1–P5), retomado e concluído aqui |

## 1. Objetivo

Um GSAN legado **executável, reproduzível, observável e seguro para laboratório**, construído a partir do código deste
repositório, capaz de receber entradas conhecidas e expor o comportamento que a Fase 2 vai capturar:

```text
entrada conhecida  →  GSAN de referência  →  comportamento observado  →  baseline (Fase 2)
```

Fonte de verdade da instalação: a **receita oficial** da Prodiga Sistemas, citada pela wiki do GSAN
(`prodigasistemas/ti` — scripts `install/jboss` e `install/gsan`, receita `recipes/gsan`; `prodigasistemas/jboss-libs`).
O ambiente reproduz essa receita e só diverge onde é necessário (§6).

## 2. Stack

| Camada | Versão | Origem e conferência |
| ------ | ------ | -------------------- |
| JDK | Azul Zulu 6 — OpenJDK 6u119 | cdn.azul.com, SHA-256 publicado pela Azul |
| Servidor de aplicação | JBoss 4.0.1SP1 | SourceForge (projeto JBoss), SHA-1 publicado |
| Build | Apache Ant 1.9.16 | archive.apache.org, SHA-512 publicado |
| Receita | `prodigasistemas/ti` `75b1a2f`, `prodigasistemas/jboss-libs` `3002fa1` | commit fixado |
| Driver JDBC | PostgreSQL 42.2.23.jre6 | versionado no próprio fork (`lib/driver-postgres`) |
| Banco | PostgreSQL 9.5.25, LATIN1, `pt_BR.ISO-8859-1` | imagem oficial, digest fixado |
| Migrações | `Joao-PSF/gsan-migracoes` `2d6acdb` | commit fixado |
| Base das imagens | Debian bookworm (servidor), Alpine 3.20 (ferramentas), nginx 1.27 (proxy e stub de SSO) | digests fixados |

Tudo em [`ambiente-referencia/versoes.env`](../../../ambiente-referencia/versoes.env).

## 3. Build

`build.xml` original, sem alteração, num contêiner sem rede, a partir de `git archive` do commit legado fixado (o script
recusa o build se o código legado no `HEAD` divergir dele). Resultado: EAR explodido com **13.764 arquivos, 247 jars,
8.482 classes no WAR e 504 relatórios Jasper compilados**, em cerca de 3 minutos; inventário `caminho + sha256` gravado para
a comparação Ant × Maven da Fase 3.

Observações do build, sem intervenção:

- O `ejbjar` não carrega o analisador de dependências (BCEL fora do classpath do Ant): cada jar de EJB leva só as classes do
  bean; o restante vem do repositório unificado de classes do JBoss. Nada indica que a receita tivesse BCEL.
- O `build.xml` altera arquivos da árvore de fontes (`rodape.jsp`, `version.properties`); por isso o build roda sobre uma
  cópia exportada, nunca sobre o checkout.
- O locale importa: o JasperReports gera classes Java com acento no nome (ex.: variável `cabeçalho`, relatório
  `...Sintético`). Em locale ASCII, 6 relatórios não compilam. O servidor da receita usa `pt_BR.ISO-8859-1`, reproduzido na imagem.

## 4. Banco

`gsan_comercial` e `gsan_gerencial` criados como na receita e migrados do zero. Resultado, conferido por script:
**comercial — 296 migrações no `CHANGELOG` + 5 não aplicáveis = 301; gerencial — 5 de 5**; tablespace `indices` criado pela
própria migração. Pós-migração: senhas dos papéis versionados rotacionadas; senha do `admin` gerada localmente; parâmetros
da instância (`URL_SEGURANCA`, logomarca); massa mínima de verificação (um cliente **sintético**).

## 5. Migrações — o histórico não reconstrói uma base

🔴 **Numa base nova, 52 das 301 migrações comerciais falham** — inclusive pela receita oficial (o `gsan-migracoes` da
Prodiga está no mesmo commit). O histórico pressupõe o estado de uma instalação em uso. Causas, todas com evidência:

| Causa | Exemplos |
| ----- | -------- |
| Sequences atrás dos IDs carregados | O dump é só schema; os `popula_*` inserem IDs explícitos; o `nextval()` seguinte colide |
| Dados de referência de produção | Grupos, processos, tipos de processo, categorias, negativadores, itens contábeis citados por ID |
| Papéis de banco nunca criados | `gsan_operacional`, `pg_users`, `pg_aplic` |
| Objetos criados fora do histórico | `cadastro.cliente_login` (o `CREATE` está **dentro de um comentário**), coluna `cadastro.imovel.cntt_copasa`, `public.oauth_applications` |
| Migração vazia | `20210623185452` tem a seção "do" vazia — só o UNDO sobreviveu |
| Erro de sintaxe | `20170622185345`: falta um `;` |
| Migrações duplicadas | Mesma coluna, mesmas operações, mesmos itens contábeis criados duas vezes |

Tratamento: uma **camada explícita do ambiente**, sem editar o histórico — sementes, sequences e uma correção sintática
aplicadas na transação da migração que os pressupõe (P1–P4), cinco migrações não aplicáveis registradas com motivo (P5) e
o complemento estrutural (P6). Classes e itens: [banco/README.md §3](../../../ambiente-referencia/banco/README.md#3-pré-requisitos--classes-p1-a-p6).
Prova de que a camada não inventou identidade: os IDs que migrações de 2023 citam (funcionalidades 16108–16113,
operações 15123–15129) saem **idênticos aos de produção**.

## 6. Instalação histórica × instalação reproduzida

| Receita oficial | Ambiente de referência | Motivo |
| --------------- | ---------------------- | ------ |
| Oracle JDK 6 | Azul Zulu 6 (OpenJDK 6u119) | Oracle JDK 6 não é redistribuível. O OpenJDK 6 do Debian wheezy (`openjdk:6b38-jdk`) foi usado primeiro e **abandonado**: a glibc 2.13 chama `time()` pela página *vsyscall* e a JVM morre com SIGSEGV em `0xffffffffff600400` em kernels sem emulação de vsyscall (Docker Desktop/WSL2) |
| Ubuntu/Debian com `LANG=pt_BR` | Debian bookworm com `LANG=pt_BR.ISO-8859-1` | Mesmo locale do servidor da receita |
| Driver 8.1 (`jboss-libs`) | Driver 42.2.23.jre6 do fork | O 8.1 é anterior a `standard_conforming_strings=on` (padrão desde o PostgreSQL 9.1); o fork versiona o 42.2.23 |
| `mondrian.war` como vem | Mesmo arquivo, credenciais neutralizadas | Segredo versionado (achado 23). O arquivo é **mantido** porque é dependência implícita (§8) |
| MyBatis Migrations 3.2.1 | Executor próprio + P1–P6 | §5 |
| Credenciais padrão | Geradas localmente | Achados 2 e 21 |
| SSO da companhia | Stub que responde "sem sessão" | §8 |
| Porta HTTP do JBoss exposta | Proxy publica só `/gsan` em 127.0.0.1; rede interna sem saída | Achado 25; o legado chama SMS, SPC, bancos e APIs de produção |

Nenhuma dessas diferenças altera código, mapeamento ou regra do legado.

## 7. Hibernate × schema

O código de 2023 mapeia objetos que as migrações nunca criam (DDL manual de produção). O Hibernate não valida schema ao
subir; o objeto ausente só falha ao usar a entidade — e **coluna ausente em tabela existente quebra toda leitura da
entidade** (ex.: `cadastro.cliente.clie_icrecusasubsidio` quebraria qualquer consulta de Cliente).
[`mapeamento.py`](../../../ambiente-referencia/scripts/mapeamento.py) segue a árvore de decisão: a classe é carregada? por
qual SessionFactory (lida em `HibernateUtil.java`)? em que banco? tabela ou view? integração externa? defeito de
mapeamento? Resultado:

| SessionFactory | Classes | Complementado (P6) | Transferido | Excluído |
| -------------- | ------: | ------------------ | ----------: | -------: |
| Comercial (`java:/PostgresDS`) | 702 | 13 colunas + `cadastro.dmc` e sua sequence | 22 | 3 |
| Gerencial (`java:/PostgresGerencialDS`) | 83 | — | 56 | 3 |

Transferidas: tabelas de funcionalidades específicas (resumos contábeis por conta, controle de hidrômetro retornado,
dicionário SGBD, testes de medição) e todo o gerencial — BLOQUEIA SOMENTE CENÁRIO FUTURO ou NÃO RELEVANTE PARA A FASE.
Excluídas: uma view de definição desconhecida, mapeamentos cujo nome de tabela tem dois qualificadores (inutilizáveis já
no legado) e uma sequence cujo nome aponta para schema inexistente (`atedimentopublico.*`). A entidade da integração
UPA/SAM (banco externo) nem é registrada numa SessionFactory. O complemento é **gerado**, confere com a versão
commitada e é reverificado a cada `banco` e `verificar`.

## 8. Runtime

JBoss sobe em ~50 s; **245 módulos EJB** e o WAR `/gsan` implantados, **sem implantação incompleta**; as duas
SessionFactory construídas. Falhas encontradas e classificadas:

| Falha | Classe | Tratamento |
| ----- | ------ | ---------- |
| JVM do wheezy morre (vsyscall) | BLOQUEIA RUNTIME | Troca de JDK/base (§6) |
| `run.sh` sem permissão de execução | BLOQUEIA RUNTIME | `chmod +x bin/*.sh`, passo da própria receita que faltava no ambiente |
| Verificador de EJB rejeita os controladores: `ClassNotFoundException: org.apache.commons.fileupload.FileItem`; o EAR inteiro falha | BLOQUEIA RUNTIME | **Dependência implícita da receita**: o `mondrian.war` do `jboss-libs` (implantado antes, `.war` antes de `.ear`, com `UseJBossWebLoader=true`) põe o commons-fileupload no repositório unificado. O ambiente instala o `mondrian.war` como a receita |
| Toda requisição `*.do` devolve 500: `GerenciadorSSO` exige `URL_SEGURANCA` e um serviço HTTP que responda | BLOQUEIA RUNTIME | Parâmetro da instância + stub interno de SSO (achado 24) |
| Tela de login devolve 500: `logoMarca` nula | BLOQUEIA RUNTIME | Logomarca vazia — o caso "sem logomarca" que o JSP trata |
| `application.xml` declara 2 módulos EJB sem descritor nem classe | NÃO RELEVANTE | O JBoss 4.0.1 os ignora sem erro |
| 163 avisos "destination not found" | NÃO RELEVANTE | O JBoss cria sob demanda as filas JMS dos MDBs (não há configuração de filas no repositório) |
| 31 avisos de `composite-id` do Hibernate | NÃO RELEVANTE | Mapeamentos do legado |
| `/telaPrincipal.do` sem sessão devolve 500 (NPE no JSP) | NÃO RELEVANTE (comportamento do legado) | A URL é exceção do filtro de segurança (`urls_sem_usuario_na_sessao`); o erro não expõe conteúdo |
| Pesquisa de cliente em popup sempre falha: `Invalid property name 'nis'` | BLOQUEIA SOMENTE CENÁRIO FUTURO (**defeito do legado**) | Commit `452c445` (2023-10-09) mudou `PesquisarClienteAction` sem atualizar o form-bean. O oráculo reproduz o defeito |

## 9. Online × Batch

Modo gravado no build (`gsan.tipo`); os dois foram implantados e verificados.

| Modo | Comportamento observado |
| ---- | ----------------------- |
| **Online** (padrão da receita) | Agendador Quartz não é iniciado. 🔵 Pela leitura de `AgendadorTarefas`, `getAgendador()` devolve nulo e processos batch e relatórios assíncronos não podem ser disparados nesse modo |
| **Batch** | Quartz inicia e o **verificador de processos dispara a cada minuto**. O agendamento da integração UPA falha (NPE: horário e intervalo nulos em `sistema_parametros`) e o servlet `InicializadorSistema` fica indisponível depois de já ter construído as SessionFactory e fixado o fuso — NÃO RELEVANTE: é a integração com banco externo, cuja SessionFactory nunca é construída. Toda a verificação passa |

Qual modo cada captura da Fase 2 usa é decisão da Fase 2; processos batch exigem **Batch**.

## 10. Testes de fumaça

`referencia.sh verificar`: banco (codificação, migrações, tablespace, P6 aplicado e sem divergência aberta, senha do admin
não versionada), isolamento de rede, stub de SSO, JBoss e implantação, as duas SessionFactory, tela de login, tela
principal negada sem sessão, login do `admin` com menu, **consulta de domínio** e **negação de autorização**:

- **Domínio**: *Manter Cliente* filtra pelo nome e encontra o cliente de verificação — Struts → `FiltroSegurancaAcesso` →
  Fachada → EJB → HQL → PostgreSQL. Carga completa de entidade central ocorre no login (`Usuario`) e na inicialização
  (`SistemaParametro`); a presença de toda coluna mapeada pelas classes carregadas é provada pela verificação do P6.
- **Autorização**: *Consultar Cliente* existe no catálogo sem concessão ao grupo ADMINISTRADOR e é negada pelo gate do
  legado ("Acesso a funcionalidade negado") — um observável de segurança já disponível para a Fase 2.

## 11. Segurança

Nenhum segredo histórico é usado: senhas de banco e do `admin` são geradas no `.env` (ignorado pelo Git); os papéis com
senha versionada são rotacionados; a migração com credenciais OAuth não é aplicada; as credenciais do `mondrian.war` são
neutralizadas na instalação; o proxy expõe só `/gsan` em 127.0.0.1; a rede interna não tem saída. Achados novos, sem
valores: **21 a 25** em [`riscos-identificados.md`](../seguranca/riscos-identificados.md) — senha padrão do `admin`,
credenciais OAuth versionadas, credenciais no `mondrian.war`, desenho do SSO, consoles do JBoss 4 abertos.

## 12. Limitações

- **Dados de referência de negócio quase vazios** e **catálogo batch** (`batch.processo`/`processo_funcionalidade`)
  praticamente inexistente — nenhum processo batch executa sem ele.
- **27 grupos de produção sintéticos**, sem usuários, só para as concessões das migrações aplicarem.
- **Concessões do grupo ADMINISTRADOR** são as das migrações: funcionalidades posteriores podem não estar concedidas
  (ex.: Consultar Cliente, Atualizar Cliente); há concessões órfãs (operação `consultarClienteAction.do` sem mapeamento Struts).
- **URLs de produção** semeadas em parâmetros (APIs da companhia de origem): inalcançáveis; a funcionalidade falha ao ser acionada.
- **Tabelas e sequences transferidas** (§7) não existem.
- **Zulu 6 ≠ Oracle JDK 6**: fontes e rasterização diferem — relatórios são comparados semanticamente (estratégia de testes).
- **Collation** do glibc atual pode ordenar diferente de uma instalação antiga.

## 13. Riscos

| Risco | Mitigação |
| ----- | --------- |
| O oráculo ser uma instalação "possível", não a de produção (DDL manual desconhecido) | Toda reconstrução é explícita, classificada e com evidência; o que não tem evidência é SINTÉTICO por nome; a Fase 2 compara semântica, não estrutura |
| Baseline capturada sobre dado de referência sintético | A massa de caracterização é da Fase 2 (perfis de `cenarios-criticos.md` §13); a massa de verificação desta fase serve só ao teste de fumaça |
| Dependência de imagens e downloads externos | Tudo fixado por checksum, commit ou digest |
| Ambiente de laboratório com software EOL e defeitos de segurança conhecidos | Rede interna sem saída, só `/gsan` publicado em 127.0.0.1, nenhum segredo real |

## 14. Reprodução limpa

Executada em 2026-09-30, depois de todo o trabalho incremental, para provar que nada dependia de estado residual:

1. ambiente anterior **destruído** — contêineres, volumes (banco, EAR, logs, migrações) e imagens;
2. **clone novo** do `master` (`ac9b623`) numa pasta vazia, mais apenas os arquivos de `ambiente-referencia/` que este
   commit versiona — sem `.env` e sem `.saida/`;
3. `bash scripts/referencia.sh tudo --sem-cache`, exatamente como no [README](../../../ambiente-referencia/README.md) §9:
   `.env` e senhas **geradas de novo**; imagens construídas **sem cache do Docker** — JDK, JBoss e Ant baixados e conferidos
   por checksum outra vez; build do EAR; banco do zero; JBoss; verificação.

| Resultado | Valor |
| --------- | ----- |
| Duração total | 12 min 33 s (build do EAR: 2 min 17 s; JBoss: `Started in 37s`) |
| Migrações | comercial 296 + 5 não aplicáveis = 301; gerencial 5 de 5 |
| Complemento P6 | regenerado no clone com o **mesmo SHA-256** da versão commitada (`55ea0f2c…`) e aplicado |
| Verificação | **22 de 22 OK, 0 falhas, 0 alertas** |
| EAR | os mesmos 13.764 caminhos do build incremental; todos os `.class`, JSPs e recursos idênticos byte a byte. Diferem só os artefatos com carimbo de tempo — 504 `.jasper` e 247 `.jar` — e os 3 arquivos em que o `build.xml` grava tipo e data do build. **Insumo da Fase 3**: a comparação Ant × Maven precisa normalizar jars e relatórios compilados |

## 15. Critério de aceite

| Critério | Resultado | Evidência |
| -------- | --------- | --------- |
| GSAN legado construído | ✅ | `BUILD SUCCESSFUL`; `build.metadados` (§3, §14) |
| Banco comercial criado | ✅ | 296 + 5 = 301 (§4) |
| Banco gerencial criado | ✅ | 5 de 5 (§4) |
| Complementos necessários aplicados | ✅ | P1–P5 no executor; P6 aplicado e sem divergência a complementar aberta (§5, §7) |
| JBoss inicia | ✅ | `Started in` (§8, §14) |
| EAR implanta | ✅ | contexto `/gsan`, 245 módulos EJB, sem implantação incompleta |
| Datasource funciona | ✅ | `PostgresDS` e `PostgresGerencialDS` ligados no JNDI; consultas pela aplicação |
| Hibernate inicializa | ✅ | as duas SessionFactory construídas |
| Consulta mínima funciona | ✅ | Manter Cliente pela pilha inteira; login carrega `Usuario` (§10) |
| Nenhum segredo histórico necessário | ✅ | senhas geradas; credenciais versionadas rotacionadas, não aplicadas ou neutralizadas (§11) |
| Destruído e reconstruído | ✅ | §14 |
| Reproduzível só pela documentação | ✅ | a execução limpa seguiu o README, a partir de um clone novo |

## 16. Veredito

**FASE 1 — CONCLUÍDA.** O GSAN legado deste repositório é construído, implantado e verificado do zero por um único
procedimento documentado, num laboratório isolado e sem segredo histórico. Toda diferença em relação à instalação
histórica tem motivo e evidência, e nenhuma altera código ou regra do legado. Ele serve de oráculo para a Fase 2, com as
limitações do §12 e as pendências do §17 — nenhuma delas bloqueia o ambiente; bloqueiam capturas específicas até a massa
da Fase 2 existir.

## 17. Pendências transferidas à Fase 2

| # | Pendência | Impacto | Fase | Bloqueia? |
| - | --------- | ------- | ---- | --------- |
| 1 | Catálogo de processos batch (`batch.processo`, `processo_funcionalidade`) e dados de referência de negócio | Sem eles nenhum processo batch nem cálculo de conta executa | 2 (massa) | Bloqueia as capturas batch e financeiras, não a Fase 1 |
| 2 | Modo da instância por captura (`GSAN_TIPO`) e variante de companhia (`GSAN_VARIANTE`) | A baseline depende deles (`cenarios-criticos.md` §15) | 2 | Decisão antes de capturar |
| 3 | Concessões do grupo usado nas capturas | Funcionalidades sem concessão são negadas | 2 (massa: perfis USR-*) | Não |
| 4 | Tabelas transferidas pelo P6 exigidas por algum cenário | A funcionalidade falha até o objeto existir | 2 | Só o cenário afetado |
| 5 | Defeito do legado na pesquisa de cliente em popup (`nis`) | Cenários que dependam dessa tela precisam de outro caminho | 2 | Não |
| 6 | Integrações externas (SMS, SPC, bancos, UPA/SAM, APIs da companhia) | Inalcançáveis por desenho; capturas que as envolvam exigem stub por contrato | 2 | Só o cenário afetado |
