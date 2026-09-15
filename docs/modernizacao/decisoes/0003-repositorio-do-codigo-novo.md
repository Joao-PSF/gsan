# ADR-0003 — Repositório do código novo (separado do legado)

- **Status: Aceita** (confirmada pelo responsável do projeto) · Data: 2026-08-13 · **Revisada em 2026-09-15**

> **Histórico da revisão (2026-09-15)**: a versão original decidia que o código nasceria no repositório **`SISAN`**. Com a mudança de identidade do produto para **OpenGSAN** (ADR-0005), o **nome físico do repositório voltou a ser pendência aberta**. O que permanece decidido é o princípio: **código novo fora do repositório legado**.

## Contexto

Existem hoje: `gsan` (legado, ~2,39M LOC, encoding ISO-8859-1, build Ant), `gsan-migracoes` (migrations MyBatis) e `SISAN` (vazio, criado quando o produto tinha esse nome). O legado tem layout incompatível com um projeto Maven/Spring moderno.

## Decisão

1. **O código do OpenGSAN nasce em repositório próprio**, fora do `gsan` — Maven multi-módulo, UTF-8, CI/CD independente.
2. O repositório `gsan` permanece como **legado em manutenção** e abriga a documentação da modernização (`docs/modernizacao/`), que segue sendo a **fonte de verdade documental** enquanto o projeto estiver em Fase 0.
3. `gsan-migracoes` é substituído pelas migrations Flyway do OpenGSAN (ADR-0002), no próprio repositório do código.

## ⚠️ Pendência aberta — nome físico do repositório

**Não decidido**, e deliberadamente não resolvido por inércia:

| Opção | Consideração |
| ----- | ------------ |
| Renomear `SISAN` → `opengsan` | Aproveita o repositório existente; exige acertar referências |
| Criar repositório novo `opengsan` | Limpo; deixa o `SISAN` órfão |
| Organização GitHub própria para o projeto aberto | Coerente com o caráter open source (ADR-0005, item 6); decisão de governança, não técnica |

🔵 A decisão depende de definição de **governança do projeto aberto** (quem mantém, sob qual organização, com qual licença) — que ainda não foi tomada. Registrada aqui para não se perder; **nada será renomeado automaticamente**.

## Consequências

- (+) Projeto novo limpo, sem herdar histórico de 2,39M LOC; pipelines independentes; sem risco de build cruzado com Ant.
- (−) Documentação em um repositório e código novo em outro — mitigado por links e pela replicação do sumário no README do repositório novo quando ele nascer.
- (−) Enquanto o nome físico não for decidido, o código não pode começar — ⚠️ mas isso **não bloqueia a Fase 0**, que é documental.

## Alternativas consideradas

Pasta `modern/` dentro do repo `gsan` (rejeitada: acopla pipelines e permissões, repositório gigante); manter o código no legado (rejeitada pelos mesmos motivos).

## Rollback

Enquanto não houver código publicado, mover o projeto de repositório é barato.
