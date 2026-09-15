# ADR-0005 — OpenGSAN é a evolução aberta e moderna do GSAN

- **Status: Aceita** (diretriz do responsável do projeto) · Data: 2026-08-13 · **Revisada em 2026-09-15**

> **Nota de nomenclatura**: o arquivo mantém o nome original (`0005-sisan-...`) para preservar links e histórico. O sistema chamava-se **SISAN** entre 2026-08-13 e 2026-09-14; a partir de 2026-09-15 chama-se **OpenGSAN**. Registros de alteração anteriores mantêm o nome da época — isso é histórico decisório, não inconsistência.

> **Histórico da revisão (2026-09-15)** — duas mudanças de diretriz, ambas do responsável do projeto:
>
> 1. **Nome e posicionamento**: SISAN → **OpenGSAN**. Não é projeto novo: é a continuação direta de tudo que já foi analisado e decidido.
> 2. **Escopo**: o item 3 da versão anterior afirmava que *"facilidade de migração GSAN→SISAN é requisito arquitetural"* e que este projeto produziria o migrador. **Isso foi corrigido**: a migração de instalações GSAN existentes passa a ser **projeto separado**. Este projeto constrói o sistema; o outro construirá as ferramentas de transporte.

## Contexto

O GSAN concentra décadas de conhecimento de gestão comercial de saneamento — conceitos, módulos, regras, fluxos, relatórios, processos e integrações validados por operação real em múltiplas companhias. Esse conhecimento é o ativo mais valioso do legado, e é independente da tecnologia em que foi escrito.

A base tecnológica, por outro lado, está esgotada: Java 1.5/1.6, JBoss 4.0.1sp1, Struts 1.1, EJB 2.x, Hibernate 3 — tudo EOL, sem caminho de upgrade. Os dez mapas funcionais e a análise de compatibilidade mostraram, com evidência, que **o modelo funcional é majoritariamente bom** (37 das 64 decisões estruturais foram `PRESERVAR`) e que os problemas concentram-se na implementação, não no domínio.

## Decisão

1. **OpenGSAN é a evolução aberta e moderna do GSAN**: preserva o conhecimento funcional consolidado e **reconstrói a base tecnológica**. Não é sistema criado do zero, nem atualização tecnológica do código antigo.

   ```text
   GSAN ──► conhecimento de domínio, regras, conceitos, experiência acumulada ──► OpenGSAN
                                                                                   ├── arquitetura moderna
                                                                                   ├── código sustentável
                                                                                   ├── segurança moderna
                                                                                   ├── extensibilidade
                                                                                   └── evolução funcional
   ```

2. **Regra geral mantida**: *preservar quando adequado, modernizar quando necessário, redesenhar somente com justificativa*. Não recriar a roda — e não fossilizar problemas.

3. **A migração de instalações GSAN existentes está FORA do escopo deste projeto.** Estratégia gradual, coexistência, sincronização, ETL operacional, cutover, replicação e compatibilidade entre bancos em execução serão tratados em **projeto próprio**, posterior.

4. ⚠️ **A facilidade de migração não é critério de desenho do OpenGSAN.** Ela **não** pode ser usada para justificar a manutenção de tabelas ruins, acoplamentos, chaves artificiais, estruturas duplicadas, segurança inadequada ou decisões técnicas herdadas. Quando a análise indicar `REESTRUTURAR`, reestrutura-se — e o projeto de migração fará a transformação `estrutura GSAN → estrutura OpenGSAN` quando existir.

5. **A continuidade conceitual permanece requisito.** Isso é diferente do item 4 e não o contradiz: conceitos, nomenclaturas úteis, regras de negócio, identidades relevantes, comportamento financeiro, histórico, parametrizações e relações de domínio são preservados **porque valem por si**, não porque facilitam um transporte de dados. O documento de compatibilidade desta fase trata de **correspondência conceitual**, não de transformação operacional.

6. **OpenGSAN é software livre e aberto** para gestão de saneamento — o que orienta a arquitetura para neutralidade institucional, configuração sobre fork, documentação clara, instalação reproduzível e ausência de dependência desnecessária de fornecedores.

7. O repositório `gsan` permanece como **referência de comportamento**; o `gsan_comercial` como fonte complementar de compatibilidade e descoberta funcional.

## Consequências

- (+) O desenho do OpenGSAN deixa de ser limitado pela forma do legado — reestruturações justificadas podem ser feitas sem negociar com um migrador que não existe.
- (+) Reduz risco de perda de regras de negócio; encurta a curva de entendimento; evita reinvenção.
- (+) O caráter aberto amplia o alcance além das companhias que hoje usam GSAN.
- (−) Companhias GSAN não têm, **neste projeto**, caminho de adoção pronto — ele dependerá do projeto de migração.
- (−) Disciplina de registrar correspondência conceitual permanece, mesmo sem a obrigação de migrar.

## Alternativas consideradas

| Alternativa | Avaliação |
| ----------- | --------- |
| **Greenfield sem compromisso com o GSAN** | **Rejeitada**: descarta décadas de conhecimento funcional validado em operação real. Os mapas funcionais provam que o domínio é bom |
| **Port 1:1 do GSAN** | **Rejeitada**: perpetuaria dívidas estruturais e de segurança já documentadas (SHA-1 sem salt, endpoints sem autenticação, abrangência por omissão) |
| **Manter migração como requisito deste projeto** (versão anterior) | **Substituída**: acoplava o desenho do sistema novo à forma do legado. Separar os projetos libera ambos — o OpenGSAN para ser bem desenhado, o migrador para ser bem especificado |
| **Manter o nome SISAN** | **Substituída** por diretriz do responsável: OpenGSAN expressa a continuidade com o GSAN e o caráter aberto, que SISAN não comunicava |

## Rollback

Diretriz de projeto — mudá-la exige nova ADR e revisão do plano.

## Pendência ligada

O **nome físico do repositório** (renomear, criar novo, organização no GitHub) é decisão separada e **permanece pendente** — ver ADR-0003. A nomenclatura OpenGSAN é decisão de produto, não de infraestrutura.
