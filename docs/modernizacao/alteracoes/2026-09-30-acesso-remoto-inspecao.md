# [2026-09-30] Acesso remoto temporário à instância de inspeção do GSAN legado

> Conveniência de inspeção humana — **não faz parte do comportamento do legado** e não participa de nenhuma baseline.

- **Motivo**: o responsável quer ver o GSAN de referência de outro computador, sem abrir porta no roteador e sem
  expor o JBoss sem proteção.
- **Impacto**: `referencia.sh` ganha a seleção de instância (`GSAN_INSTANCIA=referencia|inspecao`) e os comandos
  `compartilhar`, `status-compartilhamento` e `parar-compartilhamento`; serviço `tunel` (perfil `compartilhamento`) no
  compose; `scripts/tunel.sh`; `cloudflared` 2026.9.3 fixado em `versoes.env` (SHA-256 da release oficial); o proxy
  devolve redirecionamentos relativos; `baseline.sh` fixa a instância das baselines e recusa capturar com túnel nela.
  **Nenhuma linha do legado alterada.**
- **Dependências**: binário oficial `cloudflared-linux-amd64` da release do GitHub da Cloudflare (download autorizado
  pelo responsável), guardado em `.ferramentas/` (ignorado) e executado na imagem `ferramentas` já existente.
- **Testes**: sem autenticação, toda rota da URL pública (inclusive `/jmx-console` e `/web-console`) responde 302 para
  o login da Cloudflare Access, sem conteúdo do GSAN; o log do `cloudflared` confirma *protected quick Tunnel —
  One-Time PIN*. Pelo mesmo caminho do túnel (rede externa → `proxy:80`, `Host` público): `/gsan` 200, login do GSAN,
  CSS/JS/imagens 200, navegação até o imóvel da massa; consoles e demais aplicações 404. `parar-compartilhamento`
  remove só o contêiner do projeto. `referencia.sh verificar` na instância das baselines: 23/23.
- **Risco**: baixo com a proteção por e-mail; o legado tem falhas conhecidas — compartilhar só durante o uso.
  **Rollback**: `parar-compartilhamento`; `git revert`.

## Decisões

| Decisão | Motivo |
| ------- | ------ |
| Instância de **inspeção** separada | Navegação humana não pode tocar o banco que a caracterização controla. Reaproveita imagens, compose e receita; muda só projeto, volumes, rede e porta |
| Quick Tunnel com `--allowed-mail` | Temporário, sem domínio nem DNS, com autenticação da Cloudflare Access antes de qualquer requisição chegar à origem |
| Origem = proxy existente | Já roteava só `/gsan` (Fase 1); nenhum proxy novo |
| `Location` relativo no proxy | O Tomcat 5 monta `http://<host>/…` absoluto; atrás do HTTPS da borda, isso trocaria o esquema. O executor e a verificação falam direto com `gsan:8080` — as baselines não passam pelo proxy |
| E-mail autorizado só no `.env` | Dado pessoal: nunca versionado, impresso mascarado |

Procedimento: [`ambiente-referencia/README.md` §6b](../../../ambiente-referencia/README.md#6b-acesso-remoto-temporário).
