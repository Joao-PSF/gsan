# [2026-09-30] Fase 1 — ambiente de referência do GSAN legado

> Primeira fase de execução depois da Fase 0. **Não implementa o OpenGSAN** e **não captura baseline** (Fase 2): torna o
> GSAN legado deste repositório executável, reproduzível e observável, para servir de oráculo.

- **Motivo**: plano de trabalho, Fase 1 — *"legado executável de forma controlada"*; critério de aceite *"build + deploy
  do EAR reproduzidos do zero seguindo apenas a documentação"*.
- **Impacto**: novo diretório [`ambiente-referencia/`](../../../ambiente-referencia/README.md) (Docker Compose, imagens,
  scripts, camada de banco P1–P6); nenhuma linha do código, dos mapeamentos, dos JSPs ou do `build.xml` do legado alterada.
- **Dependências**: Docker com Compose v2; downloads fixados em `ambiente-referencia/versoes.env` (autorizados pelo
  responsável); `gsan-migracoes` no commit `2d6acdb`.
- **Testes**: `referencia.sh verificar` — banco, mapeamento Hibernate × schema, isolamento, implantação, login, consulta de
  domínio e negação de autorização; reprodução limpa a partir de clone novo e imagens sem cache.
- **Risco**: baixo para o projeto (laboratório isolado, sem segredo real). **Rollback**: `referencia.sh destruir --sim` e
  `git revert` do commit. **Migration do OpenGSAN**: nenhuma.

## 1. Estado de entrada

| Verificação | Resultado |
| ----------- | --------- |
| `master` local e remoto | `ac9b623` — merge do PR #1 (legado `1a0edcf` + documentação `c5be172`), árvore idêntica a `c5be172` |
| Commits posteriores | Nenhum |
| Trabalho local | `ambiente-referencia/` não rastreado, de sessão anterior (build, banco, P1–P5) — lido, preservado e concluído |

## 2. Achados

| Achado | Evidência | Efeito |
| ------ | --------- | ------ |
| O histórico de migrações **não reconstrói uma base**: 52 de 301 falham numa base nova | Execução diagnóstica (`GSAN_MIGRAR_DIAGNOSTICO=1`) | Camada explícita P1–P5 do ambiente; histórico intacto |
| O código mapeia colunas e tabelas que nenhuma migração cria | `scripts/mapeamento.py` sobre as SessionFactory de `HibernateUtil` | Complemento P6 mínimo (13 colunas + `cadastro.dmc`); o resto classificado e transferido |
| A JVM do OpenJDK 6 do Debian wheezy morre em kernel sem vsyscall | SIGSEGV em `0xffffffffff600400` | Zulu 6 sobre Debian bookworm |
| Os EJBs só implantam com o `mondrian.war` da receita | `ClassNotFoundException: ...FileItem` no verificador de EJB | `mondrian.war` instalado como na receita, credenciais neutralizadas |
| Toda requisição depende de um serviço SSO externo | `FiltroSSO` → `GerenciadorSSO` | Stub interno "sem sessão" + `URL_SEGURANCA` |
| Pesquisa de cliente em popup quebrada no código versionado | `Invalid property name 'nis'` — commit `452c445` | Defeito do legado, reproduzido e registrado |
| Segredos versionados: senha do `admin`, credenciais OAuth da GSAN-API, credenciais no `mondrian.war`; consoles do JBoss abertos | Achados 21–25 | Nenhum usado; tratamento no relatório |

## 3. Documentos

**Criados**: [`ambiente/fase1-ambiente-referencia.md`](../ambiente/fase1-ambiente-referencia.md) ·
[`ambiente-referencia/README.md`](../../../ambiente-referencia/README.md) ·
[`ambiente-referencia/banco/README.md`](../../../ambiente-referencia/banco/README.md) · este registro.
**Atualizados**: `MODERNIZACAO_GSAN.md` · `plano-de-trabalho.md` §9 · `README.md` (índice) · `procedencia.md` (fontes e
correções) · `seguranca/riscos-identificados.md` (achados 21–25) · `arquitetura/arquitetura-legada.md` ·
`testes/cenarios-criticos.md` §15 · `alteracoes/README.md`.

## 4. Veredito

**FASE 1 — CONCLUÍDA.** Reprodução limpa a partir de clone novo e imagens sem cache: 12 min 33 s, **22 de 22 verificações
OK** ([relatório §14–§16](../ambiente/fase1-ambiente-referencia.md#14-reprodução-limpa)). Próximo estágio, conforme o plano:
**Fase 2 — rede de segurança** (captura das baselines) — não iniciada.
