# Integrações Identificadas

Levantamento inicial (Fase 0) a partir do código e do banco. Cada integração deverá ter ficha própria (protocolo, formato, frequência, criticidade, contatos) antes de ser migrada.

| Integração | Evidências | Observações |
| ---------- | ---------- | ----------- |
| Bancos/arrecadadores (arquivos de débito automático, retorno de pagamento, registro de boletos) | Schema `arrecadacao` (aviso bancário, movimento), migrations de boleto BB/ficha de compensação (2024), MDBs de arrecadação por companhia | Crítica — dinheiro entra por aqui; formatos CNAB/FEBRABAN |
| Cobrança terceirizada / por resultado | `descriptors/cobrancaPorResultado`, `empr_cobr_conta_pagto`, arquivos TXT de OS de cobrança (`mobile.arq_txt_os_cobranca*`) | Envio/retorno de carteiras a empresas |
| Negativação SPC/Serasa | Pacote `gcom.spcserasa`, `backup_cobranca_negatd_movimento_reg` | Movimentos de inclusão/exclusão |
| Fiscal: NF/NFC-e + SPED | Schema `fiscal` (nota_fiscal_*, certificado_fiscal, bucket), `integracao.sped_documento`, `sp1_gerar_integracao_sped`, tabelas `ti_*` (contábil) | Customização relevante vs. GSAN público; obrigações regulatórias |
| Contabilidade | Schema `financeiro` (`sp*_gerar_conta_rec_ctb`) | Geração de lançamentos contábeis |
| Mobile / execução em campo | Schema `mobile` (exe_os_corte, exe_os_fiscalizacao, exe_os_cliente), fotos, recadastramento (`atualizacaocadastral`, parâmetro de versão do app) | Apps de OS, corte, fiscalização e recadastramento |
| Serviço externo de relatórios | `api/GsanApi.java`, `lib/gsan-relatorios` (Jersey+Gson), token | Projeto `gsan-relatorios` separado |
| Web services SOAP | Axis2 1.5.1, `gcom.integracao.webservice` | Mapear consumidores reais |
| UPA / GIS | `gcom.integracao.upa`, `GisRetornoMotivo`, views geo (`vw_debito_geo_*`, `vw_imoveis_geo_*`) | Confirmar se ativos |
| Consultas cadastrais externas | `seguranca.consulta_receita_federal`, `consulta_cdl` | Dados pessoais — atenção LGPD |
| Tarifa social / programas (Bolsa Água, Viva Água, NIS) | `sp1_gerar_cred_pagto_viva_agua`, migrations de NIS, `atualizacaocadastral` | Regras sociais com impacto financeiro |
| APIs HTTP próprias | `/api/pagamentoCredito/*`, `/api/ordem-servico/*`, `/autocomplete`, `seguranca.token` | Segurança frágil — ver riscos |
| BI / OLAP | Matviews `*_roger_bi`, role `gsan_olap`, base `gerencial` (gsan-migracoes), `admindb.db_versao_sincronismo` | Consumidores diretos do banco — restrição forte a mudanças de schema |
| E-mail | `mail.jar`, `usur_dsemail` | Notificações |
| Impressão térmica (2ª via etc.) | `aAppletImpressaoTermica.jar` (applet) | Applets não rodam em browsers modernos — descobrir como é usado hoje e planejar substituição |

## Regra

Nenhuma integração será desligada ou substituída sem: ficha completa, consumidores confirmados, teste de equivalência do arquivo/mensagem gerada e janela combinada com a contraparte.
