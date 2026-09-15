# Documentação da Modernização do GSAN

> ⚠️ **Nomenclatura (2026-09-15)**: o sistema alvo chama-se **OpenGSAN** — evolução aberta e moderna do GSAN (ADR-0005). Chamava-se **SISAN** até 2026-09-14; registros históricos em `alteracoes/` e seções de histórico das ADRs preservam o nome da época.
>
> ⚠️ **Escopo (2026-09-15)**: a **migração de instalações GSAN existentes está fora deste projeto** e terá projeto próprio. Esta documentação trata de **continuidade conceitual**, não de transformação de dados.

Sumário da documentação técnica. A visão executiva do projeto está em [`MODERNIZACAO_GSAN.md`](../../MODERNIZACAO_GSAN.md) na raiz do repositório.

## Documentos

| Documento | Conteúdo |
| --------- | -------- |
| [procedencia.md](procedencia.md) | **Procedência das fontes e método de verificação**: commits analisados, níveis de certeza, método de contagem, correções de fato já aplicadas |
| [plano-de-trabalho.md](plano-de-trabalho.md) | Plano de trabalho da modernização: estado atual, arquitetura alvo, riscos, fases, ordem dos módulos, estratégias |
| [dominio/visao-conceitual-opengsan.md](dominio/visao-conceitual-opengsan.md) | **Visão Conceitual Alvo do OpenGSAN**: visão e escopo, princípios estruturais, core × plataforma, os dez domínios em nível conceitual, matriz de ownership, fronteiras por responsabilidade, identidade/versão/linhagem, seis mecanismos de histórico, parametrização, extensibilidade, tabela GSAN × OpenGSAN, expansão futura, decisões pendentes e riscos |
| [dominio/mapa-de-dominio.md](dominio/mapa-de-dominio.md) | **Mapa de domínio consolidado**: visão integrada dos dez mapas funcionais — conceitos centrais e sua natureza, identidades estáveis, estado/histórico/snapshot, ownership, fronteiras, dependências circulares, núcleo comercial, domínios financeiro e operacional, regras como dados, variação por companhia, conceitos sobrecarregados e implícitos, riscos de modernização |
| [dominio/glossario.md](dominio/glossario.md) | Glossário de domínio: 25 conceitos estruturantes com definição, relações, evidências (código/banco) e pontos de aprofundamento |
| [modulos/cadastro.md](modulos/cadastro.md) | Mapa funcional do módulo Cadastro: imóvel/matrícula, economia, cliente×imóvel, ligações, categorias, território, estados, dependências e compatibilidade |
| [modulos/micromedicao.md](modulos/micromedicao.md) | Mapa funcional da Micromedição: hidrômetro/instalação, ciclo de leitura, anormalidades paramétricas, consumo (real/média/mínimo), fronteira com faturamento, cenários de caracterização |
| [modulos/faturamento.md](modulos/faturamento.md) | Mapa funcional do Faturamento: FATURAR_GRUPO/gerarConta, faturabilidade, tarifa por vigência/faixas/mínimos, esgoto, Conta e ContaGeral (identidade/versões), retificação, cancelamento, precisão financeira, golden masters |
| [modulos/cobranca.md](modulos/cobranca.md) | Mapa funcional da Cobrança: estoque por identidades `*Geral`, ações com predecessora/critérios paramétricos, documento com itens, parcelamento/desfazer/reparcelamento, corte/religação, negativação, terceirizada, estados |
| [modulos/arrecadacao.md](modulos/arrecadacao.md) | Mapa funcional da Arrecadação: movimento do arrecadador, recepção separada da classificação, situações do pagamento, excedente/devolução, conciliação por aviso bancário, débito automático, encerramento contábil, PIX como evolução |
| [modulos/atendimento.md](modulos/atendimento.md) | Mapa funcional do Atendimento: RA como protocolo × OS como execução, especificação como núcleo paramétrico, prazo/espera/reiteração, tramitação, estados, efeito cadastral pela execução, fronteiras financeiras, matrícula opcional |
| [modulos/seguranca.md](modulos/seguranca.md) | Mapa funcional da Segurança (comportamento): gate transversal de autorização por URL (com exceções), união de grupos, permissões especiais nomeadas, abrangência territorial e sua aplicação manual, ciclo do usuário, auditoria em dois níveis |
| [modulos/batch.md](modulos/batch.md) | Mapa funcional do Batch: definição × execução em três níveis (processo/etapa/unidade), disparo manual/agendado/mensageria, retomada por unidade, reprocessamento por etapa, estados, identidade do solicitante, casos FATURAR_GRUPO e ENCERRAR_ARRECADACAO_MES |
| [modulos/integracoes.md](modulos/integracoes.md) | Mapa funcional das Integrações: os sete padrões técnicos, entry points fora do gate, APIs `/api/*`, cliente OAuth2, integração por banco compartilhado (UPA/SAM), SOAP/SPC, e-mail e SMS; autenticação comparada, identidade na fronteira, achados de segurança |
| [modulos/relatorios.md](modulos/relatorios.md) | Mapa funcional dos Relatórios: relatório × tarefa × resultado, decisão automática online/batch por contagem versus limite, motor Jasper com template compilado e datasource, artefato persistido e download, autorização operacional, segurança do acesso ao artefato |
| [modulos/funcionalidades-futuras.md](modulos/funcionalidades-futuras.md) | **Catálogo de funcionalidades futuras do OpenGSAN**: 26 capacidades descobertas no legado, classificadas por natureza (core futuro / módulo opcional / integração / extensão de companhia), **maturidade da evidência** e horizonte preliminar; pagamentos digitais, fiscal e SPED, campo/mobile, recadastramento, benefício social, bureau de crédito, canal digital do cliente, analytics, GIS e telemetria; padrões transversais, candidatos a novos módulos, especificidades de companhia e **não candidatos**. ⚠️ Sem modelagem e sem roadmap datado |
| [arquitetura/arquitetura-legada.md](arquitetura/arquitetura-legada.md) | Mapa técnico do GSAN legado: runtime, build, frameworks, camadas, batch, relatórios |
| [arquitetura/arquitetura-alvo.md](arquitetura/arquitetura-alvo.md) | Stack alvo, organização modular e princípios de compatibilidade GSAN→OpenGSAN (banco próprio UTF-8; coexistência **não** é premissa deste projeto — é cenário do playbook de migração futura) |
| [banco/estrutura-atual.md](banco/estrutura-atual.md) | Inventário do banco `gsan_comercial`: schemas, objetos, classificação, drift |
| [banco/migracao-postgresql.md](banco/migracao-postgresql.md) | Estratégia de atualização do PostgreSQL e versionamento do banco |
| [seguranca/modelo-legado.md](seguranca/modelo-legado.md) | Modelo de autenticação/autorização atual (RBAC próprio) |
| [seguranca/riscos-identificados.md](seguranca/riscos-identificados.md) | Achados de segurança e ações requeridas |
| [testes/estrategia-testes.md](testes/estrategia-testes.md) | Estratégia de testes: **dois oráculos** (funcional/financeiro × técnico/segurança), modelo de especificação de cenário, comparação semântica de relatórios |
| [compatibilidade/estruturas-centrais.md](compatibilidade/estruturas-centrais.md) | **Análise de compatibilidade das estruturas centrais**: 64 decisões `PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR` sobre os conceitos do domínio, com semântica × estrutura separadas, justificativa completa de cada reestruturação, análise transversal de parametrização e de histórico/versão/linhagem/snapshot, tratamento de identificadores e famílias não transportadas |
| [compatibilidade/divergencias-aprovadas.md](compatibilidade/divergencias-aprovadas.md) | **Registro de divergências aprovadas**: onde o OpenGSAN deve divergir do GSAN de propósito, para que o teste não trate correção de segurança como falha |
| [integracoes/integracoes-identificadas.md](integracoes/integracoes-identificadas.md) | Integrações externas identificadas no código e no banco |
| [modulos/README.md](modulos/README.md) | Ordem de migração dos módulos e status |
| [decisoes/README.md](decisoes/README.md) | Registro de decisões arquiteturais (ADRs) |
| [alteracoes/README.md](alteracoes/README.md) | Registro de alterações realizadas pela modernização |

## Convenções

- Cada alteração relevante gera/atualiza um registro em `alteracoes/` com motivo, impacto, dependências, testes, risco e rollback.
- Decisões estruturais viram ADR em `decisoes/` antes da implementação.
- Documentos por módulo serão criados em `modulos/` conforme cada módulo entrar em análise (nunca programar antes de documentar o comportamento atual).

## Pastas planejadas (backlog da Fase 0)

- `dominio/` — contém o glossário, o mapa de domínio consolidado e a **visão conceitual alvo do OpenGSAN** (2026-09-15).
- `compatibilidade/` — contém o registro de divergências e **a análise de compatibilidade das estruturas centrais** (2026-09-14). Receberá o documento de compatibilidade/migração GSAN→OpenGSAN (classificação `PRESERVAR/MODERNIZAR/REESTRUTURAR/NÃO TRANSPORTAR`, ADR-0006) e princípios de migração GSAN→OpenGSAN (ADR-0005).
- `modulos/` — **os dez mapas funcionais estão concluídos** (cadastro → integrações) e o **catálogo de funcionalidades futuras** foi entregue em 2026-09-15 (`funcionalidades-futuras.md`). Receberá ainda o refinamento da ordem de implementação em `modulos/README.md`.
