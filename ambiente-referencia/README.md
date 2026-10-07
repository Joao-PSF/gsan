# GSAN de referência — ambiente reproduzível do legado

Ambiente da **Fase 1** da modernização ([plano](../docs/modernizacao/plano-de-trabalho.md)): o GSAN legado deste repositório
construído e executado de forma controlada, para servir de **oráculo** na captura das baselines (Fase 2). Não é um GSAN
corrigido: o código, os mapeamentos e as regras do legado ficam intactos; só a infraestrutura, a configuração da instância e
a reconstrução do banco são do ambiente — cada intervenção com motivo e evidência. Relatório da fase:
[`docs/modernizacao/ambiente/fase1-ambiente-referencia.md`](../docs/modernizacao/ambiente/fase1-ambiente-referencia.md).

```text
                      127.0.0.1:8080
                            │  (só /gsan)
   rede "externa"      ┌────┴────┐
 ─────────────────────│  proxy  │ nginx
                       └────┬────┘
   rede "interna"           │  (internal: sem saída para a internet)
 ┌──────────────────────────┼───────────────────────────────┐
 │  ┌──────┐   ┌────────────┴──────────┐   ┌─────────────┐   │
 │  │ sso  │◄──│ gsan                  │──►│ db          │   │
 │  │ stub │   │ JDK 6 + JBoss 4.0.1SP1│   │ PostgreSQL  │   │
 │  └──────┘   │ + gcom.ear            │   │ 9.5 LATIN1  │   │
 │             └───────────────────────┘   └─────────────┘   │
 └───────────────────────────────────────────────────────────┘
```

## 1. Pré-requisitos

| Item | Observação |
| ---- | ---------- |
| Docker com Compose v2 (≥ 2.17) e BuildKit | Docker Desktop (Windows/macOS) ou Docker Engine (Linux). Reserve ≥ 4 GB de RAM e ≥ 8 GB de disco para o Docker |
| `git` e `bash` | Linux/macOS, ou Git Bash no Windows |
| Clone **completo** deste repositório | O build parte do commit legado fixado; clone raso não o contém |
| Internet na primeira preparação | Downloads listados em [`versoes.env`](versoes.env), todos conferidos por checksum, commit ou digest; depois disso o GSAN roda isolado |
| Porta `8080` livre em 127.0.0.1 | Configurável (`GSAN_PORTA_HTTP`) |

Os comandos abaixo rodam **dentro de `ambiente-referencia/`**.

## 2. Configuração local

```bash
bash scripts/referencia.sh preparar
```

Cria `.env` a partir de [`.env.exemplo`](.env.exemplo), **gera as senhas locais** que estiverem vazias e constrói as imagens.
O `.env` é ignorado pelo Git; nenhuma credencial histórica é usada.

| Variável | Uso |
| -------- | --- |
| `GSAN_DB_SENHA` | Superusuário do PostgreSQL de referência e credencial do datasource do JBoss (como na receita oficial). Só letras, dígitos, `.`, `-`, `_` |
| `GSAN_ADMIN_SENHA` | Senha do usuário `admin` do GSAN — substitui a publicada pelas migrações e pela wiki |
| `GSAN_TIPO` | `Online` (padrão da receita) ou `Batch`. **Batch** inicia o agendador Quartz (verificador de processos a cada minuto), sem o qual processos batch e relatórios assíncronos não rodam. Cada modo tem o **seu** EAR, num volume próprio (`ear` e `ear-batch`): `GSAN_TIPO=Batch bash scripts/referencia.sh build` constrói o Batch sem tocar no Online, e `subir` sobe o do modo pedido. O rodapé das telas mostra o modo (`referencia (Online)` / `referencia (Batch)`) |
| `GSAN_VERSAO` | Texto do rodapé das telas |
| `GSAN_PORTA_HTTP`, `GSAN_JVM_*` | Porta publicada e memória da JVM (valores da receita) |
| `GSAN_MIGRACOES_CODIFICACAO` | `detectar` (padrão) lê cada script de migração na sua codificação; `latin1` reproduz a receita, que corrompe o texto dos scripts em UTF-8 |
| `GSAN_VARIANTE` | Variante de companhia (`parm_nmcontrolador`); vazio mantém a semeada (COSANPA). A escolha da baseline é da Fase 2 |

## 3. Build

```bash
bash scripts/referencia.sh build
```

Confere que o código legado no `HEAD` é o do commit fixado (`GSAN_COMMIT_LEGADO`), exporta esse commit com `git archive` e
roda o `build.xml` original (Ant 1.9.16, JDK 6) num contêiner **sem rede**, gravando o EAR explodido no volume `ear`.
Saídas em `.saida/`: `build.log`, `build.metadados` (versões, contagens) e `inventario-ear.sha256` (caminho + hash de cada
arquivo do EAR — base de comparação da Fase 3). Cerca de 3 minutos.

O modo vem de `GSAN_TIPO` (padrão `Online`). `GSAN_TIPO=Batch bash scripts/referencia.sh build` grava o EAR **Batch** no
volume `ear-batch` e as saídas em `.saida/build-batch/`; os dois EARs coexistem. Do mesmo commit, diferem só no
`version.properties` (tipo) e no rodapé — conferido entrada a entrada no lote 5 da Fase 2.

## 4. Banco

```bash
bash scripts/referencia.sh banco
```

1. sobe o PostgreSQL 9.5 (cluster `pt_BR.ISO-8859-1`, LATIN1);
2. obtém o `gsan-migracoes` no commit fixado;
3. cria `gsan_comercial` e `gsan_gerencial` como a receita;
4. aplica as migrações com semântica do MyBatis e a **camada de pré-requisitos P1–P5** — o histórico oficial não reconstrói
   uma base do zero;
5. aplica o **complemento estrutural P6** (objetos mapeados pelo código e criados fora do histórico);
6. pós-migração: rotação das senhas dos papéis versionados, senha do `admin`, parâmetros da instância e a massa mínima de
   verificação;
7. 🆕 (Fase 2) **congela** os dois bancos, exatamente como saem daqui, nos modelos `gsan_comercial_ref` e
   `gsan_gerencial_ref` (`scripts/estado-base.sh`) — o estado de partida de toda execução de baseline. O JBoss é parado
   no início do passo: nenhuma conexão sobrevive de uma subida anterior.

Tudo explicado, item a item, em [`banco/README.md`](banco/README.md). Logs em `.saida/migracoes-*.log`, `.saida/pos-migracao.log`,
`.saida/mapeamento.tsv`. Cerca de 2 minutos. Qualquer falha não prevista interrompe o processo.

## 5. Runtime

```bash
bash scripts/referencia.sh subir
```

Sobe o stub de SSO, o JBoss com o EAR e o proxy; espera o `Started in`. Aplicação: **http://127.0.0.1:8080/gsan**, login
`admin` com a senha de `GSAN_ADMIN_SENHA` do `.env`. Log do servidor: `docker compose logs gsan` ou o volume `jboss-log`.

## 6. Verificação

```bash
bash scripts/referencia.sh verificar
```

Resultado também em `.saida/verificacao.txt`. Verifica: codificação e collation dos bancos; migrações aplicadas + não
aplicáveis = scripts do repositório; tablespace; complemento P6 aplicado e **nenhuma divergência Hibernate × schema a
complementar aberta**; senha do `admin` diferente da versionada; rede interna sem saída; stub de SSO; JBoss iniciado, EAR
implantado sem implantação incompleta, as duas SessionFactory construídas; tela de login; tela principal negada sem sessão;
login do `admin` com menu; **consulta de domínio** (Manter Cliente encontra o cliente de verificação pela pilha inteira);
**negação** de funcionalidade não concedida pelo gate de autorização do legado.

## 6a. Baselines (Fase 2)

```bash
bash scripts/baseline.sh capturar --lote piloto     # 2 execuções idênticas por variação → baselines/golden/
bash scripts/baseline.sh verificar --lote piloto    # nova execução comparada com a baseline; não escreve
```

Cada execução recria os bancos dos modelos, aplica a massa sintética da variação, sobe o JBoss do zero **com o EAR do
modo que o cenário declara** (`"modo": "Batch"`; padrão Online) e executa a operação pelas telas do legado; o executor
recusa a execução se o rodapé mostrar outro modo. Os cenários Batch exigem o EAR Batch construído uma vez
(`GSAN_TIPO=Batch bash scripts/referencia.sh build`). Depois de uma captura, o banco de trabalho fica com a massa da
**última** execução.
Tudo em [`baselines/README.md`](baselines/README.md).

## 6b. Acesso remoto temporário

Para abrir o GSAN legado no navegador de **outro computador**, sem abrir porta no roteador: *Quick Tunnel* da Cloudflare
(`cloudflared`) **com autenticação por e-mail** — a Cloudflare pede o e-mail, envia um código de uso único e só então
repassa a requisição. Nunca há túnel sem essa proteção: sem e-mail configurado, o túnel não abre.

```text
navegador → Cloudflare (e-mail + código) → cloudflared (contêiner) → proxy da instância (só /gsan) → JBoss
```

🔴 **Só a instância de inspeção é compartilhada.** A instância padrão (`gsan-referencia`, porta 8080) é a das baselines
da Fase 2: navegação humana mudaria o estado que a caracterização controla. A de inspeção (`gsan-inspecao`, porta
8090) usa as mesmas imagens e a mesma receita, com projeto Docker, banco, EAR, rede e porta próprios.
`referencia.sh compartilhar` recusa a instância das baselines, e `baseline.sh` recusa capturar se houver túnel nela.

**Pré-requisitos**: o ambiente da Fase 1 preparado (`preparar`). No `.env` (local, nunca versionado):

```bash
CLOUDFLARED_ALLOWED_EMAILS=nome@exemplo.com      # vários: separados por vírgula; domínio inteiro: *@exemplo.com
GSAN_INSPECAO_PORTA_HTTP=8090
```

**Primeira vez** — a instância de inspeção, com os comandos de sempre (~10 min):

```bash
GSAN_INSTANCIA=inspecao bash scripts/referencia.sh build
GSAN_INSTANCIA=inspecao bash scripts/referencia.sh banco
GSAN_INSTANCIA=inspecao bash scripts/referencia.sh subir
```

**Iniciar, consultar, encerrar**:

```bash
GSAN_INSTANCIA=inspecao bash scripts/referencia.sh compartilhar             # imprime https://<aleatório>.trycloudflare.com/gsan
GSAN_INSTANCIA=inspecao bash scripts/referencia.sh status-compartilhamento
GSAN_INSTANCIA=inspecao bash scripts/referencia.sh parar-compartilhamento   # só o túnel deste projeto
```

No outro computador: abrir a URL impressa, informar o e-mail autorizado, digitar o código recebido e, na tela do GSAN,
entrar com `admin` e a senha de `GSAN_ADMIN_SENHA`. `compartilhar` baixa, na primeira vez, o `cloudflared` oficial fixado
em `versoes.env` (release do GitHub da Cloudflare, SHA-256 conferido) para `.ferramentas/` (ignorado pelo Git) e o executa
no contêiner `tunel` da imagem `ferramentas`. URL e estado ficam em `.saida/` (ignorado).

**Limitações**: o Quick Tunnel é para desenvolvimento e testes — URL aleatória, **muda a cada abertura**, sem garantia de
disponibilidade. ⚠️ **É um sistema legado com falhas de segurança conhecidas** (senha em SHA-1 sem salt, sessão sem
proteção contra requisição forjada, achados 1–25): compartilhe só enquanto for usar, só com e-mails seus, e encerre ao
terminar. O proxy só roteia `/gsan` — `jmx-console`, `web-console`, `mondrian` e demais aplicações do JBoss respondem 404
mesmo para quem passou pela autenticação. O proxy devolve redirecionamentos relativos (o Tomcat 5 montaria `http://`
absoluto atrás do HTTPS da Cloudflare); nada no GSAN foi alterado. Para ver dados, a instância de inspeção pode receber a
massa sintética da Fase 2 com `scripts/estado-base.sh restaurar` (ver [`baselines/README.md`](baselines/README.md)).

## 7. Parar

```bash
bash scripts/referencia.sh parar
```

Para os contêineres e preserva banco, EAR e logs (volumes).

## 8. Limpeza

```bash
bash scripts/referencia.sh destruir --sim
```

Remove contêineres e **volumes** (banco, EAR, logs, migrações baixadas). Para remover também as imagens locais:
`docker image rm gsan-referencia/jboss:4.0.1sp1-jdk6 gsan-referencia/postgres:9.5-latin1 gsan-referencia/ferramentas`.

## 9. Reconstrução do zero

```bash
bash scripts/referencia.sh destruir --sim
bash scripts/referencia.sh tudo --sem-cache
```

`tudo` = `preparar` → `build` → `banco` → `subir` → `verificar`. `--sem-cache` reconstrói as imagens sem o cache do Docker,
refazendo todos os downloads e conferências de checksum. Só o banco: `bash scripts/referencia.sh recriar-banco --sim`.

## Diferenças em relação à instalação histórica

A referência é a **receita oficial** da Prodiga Sistemas (`prodigasistemas/ti`, `prodigasistemas/jboss-libs`), citada pela
wiki do GSAN. Cada desvio é necessário e não altera comportamento funcional:

| Receita oficial | Aqui | Por quê |
| --------------- | ---- | ------- |
| Oracle JDK 6 | Azul Zulu 6 (OpenJDK 6u119) sobre Debian bookworm | Oracle JDK 6 não é redistribuível; o OpenJDK 6 do Debian wheezy morre com SIGSEGV em kernels sem emulação de *vsyscall* (Docker Desktop/WSL2) |
| Servidor com `LANG=pt_BR` (ISO-8859-1) | Mesmo locale na imagem | Os relatórios Jasper geram classes Java com acento no nome; outro locale quebra o build |
| Driver JDBC 8.1 do `jboss-libs` | Driver 42.2.23.jre6 versionado no próprio fork (`lib/driver-postgres`) | O 8.1 é anterior a `standard_conforming_strings=on`, padrão do PostgreSQL 9.1+ |
| `mondrian.war` com credenciais de banco | Instalado com as credenciais **neutralizadas** | Ele fornece o commons-fileupload que os EJBs exigem na implantação; a credencial é segredo versionado |
| MyBatis Migrations 3.2.1 | Executor próprio com a mesma semântica + pré-requisitos P1–P6 | O histórico não reconstrói uma base do zero; com `auto_commit=false` o próprio MyBatis falha no `CREATE TABLESPACE` |
| Senhas padrão (papéis de banco, `admin`) | Geradas localmente | Credenciais versionadas são consideradas comprometidas |
| SSO da companhia | Stub interno que responde "sem sessão" | O filtro de SSO consulta o serviço em toda requisição e falha sem resposta |
| JBoss com todos os contextos expostos | Proxy publica só `/gsan`, em 127.0.0.1 | jmx-console, web-console e mondrian não interessam ao oráculo |
| Rede da companhia | Rede interna sem saída | O legado chama SMS, SPC, bancos e APIs de produção; nada sai do laboratório |

## Solução de problemas

- **Windows**: os scripts exportam `MSYS_NO_PATHCONV=1` (o Git Bash converteria caminhos de contêiner) e o
  [`.gitattributes`](.gitattributes) força LF, inclusive com `core.autocrlf=true`.
- **`o código legado no HEAD difere`**: alguém alterou arquivos do legado; a referência é o commit de `versoes.env`.
- **JBoss não sobe**: `docker compose --env-file versoes.env --env-file .env logs gsan`.
- **Falha de migração**: `.saida/migracoes-comercial.log` diz a última aplicada; a transação da que falhou é desfeita, e
  `banco` pode ser repetido.
