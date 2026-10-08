"""Roteiros: a operação do GSAN executada por um cenário, pelas telas do próprio legado.

Um roteiro recebe a sessão autenticada e a entrada da variação e devolve o que a operação mostrou,
já extraído do HTML (dinheiro como texto decimal exato). Não escreve no banco por conta própria: o
estado só muda pelo que a operação do GSAN fizer.
"""
import base64
import hashlib
import io
import json
import re
import secrets
import time
import zipfile

from gsan_http import Sessao, moeda, texto_visivel, valor_campo


def _linhas_resultado(html):
    """Linhas (categoria, água, esgoto, total) e a linha de totais da tabela de resultado da simulação."""
    fim = html.find('value="Desfazer"')
    trecho = html[:fim] if fim > 0 else html
    linhas = []
    for tr in re.findall(r'(?is)<tr bgcolor="#(?:FFFFFF|cbe5fe)" height="18">(.*?)</tr>', trecho):
        tds = [texto_visivel(td) for td in re.findall(r'(?is)<td\b[^>]*>(.*?)</td>', tr)]
        if len(tds) == 4 and not tds[0].startswith('Total'):
            linhas.append(tds)
    totais = None
    m = re.search(r'(?is)<strong>Total:(?:&nbsp;)?</strong>\s*</td>(.*?)</tr>', trecho)
    if m:
        totais = [texto_visivel(td) for td in re.findall(r'(?is)<td\b[^>]*>(.*?)</td>', m.group(1))]
    return linhas, totais


def simular_calculo_conta(sessao, entrada):
    """[UC0157] Simular Cálculo da Conta — chama obterConsumoMinimoLigacao (UC0105) e
    calcularValoresAguaEsgoto (UC0120), o mesmo cálculo que gerarConta usa por imóvel."""
    sessao.get('exibirSimularCalculoContaAction.do?menu=sim&limparForm=OK')
    for item in entrada['categorias']:
        sessao.get('exibirAdicionarCategoriaContaAction.do')
        html = sessao.post('adicionarCategoriaContaAction.do', {
            'categoriaID': str(item['categoria']), 'subcategoriaID': '', 'qtdEconomia': str(item['economias'])})
        # Sucesso: o popup devolve a página que recarrega a tela de origem e fecha a janela.
        if "chamarSubmitComUrl('exibirSimularCalculoContaAction.do')" not in html:
            raise RuntimeError('a categoria não foi aceita pelo popup: ' + texto_visivel(html)[:300])
    sessao.get('exibirSimularCalculoContaAction.do')

    dados = {
        'mesAnoReferencia': entrada['referencia'],
        'ligacaoAguaSituacaoID': str(entrada['ligacao_agua_situacao']),
        'consumoFaturadoAgua': '' if entrada.get('consumo_agua') is None else str(entrada['consumo_agua']),
        'ligacaoEsgotoSituacaoID': str(entrada['ligacao_esgoto_situacao']),
        'consumoFaturadoEsgoto': '' if entrada.get('consumo_esgoto') is None else str(entrada['consumo_esgoto']),
        'percentualEsgoto': entrada.get('percentual_esgoto') or '',
        'consumoFaturadoPoco': '', 'percentualColeta': '',
        'consumoTarifaID': str(entrada['tarifa']),
        'faturamentoGrupoID': str(entrada['grupo']),
        'area': '', 'numeroMoradores': '', 'pontosUtilizacao': '',
    }
    for item in entrada['categorias']:
        dados[f"categoria{item['categoria']}"] = str(item['economias'])
    html = sessao.post('simularCalculoContaAction.do', dados)

    linhas, totais = _linhas_resultado(html)
    if not totais:
        return {'resultado': 'recusado', 'mensagem': texto_visivel(html)[-600:]}
    # Calculado sem nenhuma linha (nada faturável): a tabela vem só com os totais zerados.
    return {
        'resultado': 'calculado',
        'por_categoria': [
            {'categoria': c, 'valor_agua': moeda(a), 'valor_esgoto': moeda(e), 'valor_total': moeda(t)}
            for c, a, e, t in linhas],
        'total_agua': moeda(totais[0]), 'total_esgoto': moeda(totais[1]), 'total_geral': moeda(totais[2]),
        'consumo_faturado_agua_exibido': valor_campo(html, 'consumoFaturadoAgua'),
        'consumo_faturado_esgoto_exibido': valor_campo(html, 'consumoFaturadoEsgoto'),
    }


def consultar_imovel_dados_cadastrais(sessao, entrada):
    """[UC0472] Consultar Imóvel — aba Dados Cadastrais, pela matrícula. A composição de economias vem
    de pesquisarCategoriasImovel (imovel_subcategoria); o total é somado pelo JSP a partir dela."""
    sessao.get('exibirConsultarImovelAction.do?menu=sim')
    html = sessao.post('consultarImovelWizardAction.do?action=exibirConsultarImovelDadosCadastraisAction&indicadorNovo=OK',
                       {'idImovelDadosCadastrais': str(entrada['matricula'])})
    inscricao = valor_campo(html, 'matriculaImovelDadosCadastrais')
    if inscricao in (None, '') or 'INEXISTENTE' in inscricao:
        return {'resultado': 'nao_encontrado', 'inscricao': inscricao}
    ini = html.find('Subcategorias e Economias')
    fim = html.find('Total de', ini)
    composicao = []
    for tr in re.findall(r'(?is)<tr bgcolor="#(?:FFFFFF|cbe5fe)">(.*?)</tr>', html[ini:fim]):
        tds = [texto_visivel(td) for td in re.findall(r'(?is)<td\b[^>]*>(.*?)</td>', tr)]
        if len(tds) == 3:
            composicao.append({'categoria': tds[0], 'subcategoria': tds[1], 'economias': int(tds[2])})
    total = re.search(r'(?is)Total de\s*Economias</strong>.*?<font[^>]*>\s*(\d+)\s*</font>', html[fim - 10:])
    return {
        'resultado': 'encontrado',
        'inscricao': inscricao,
        # o JSP acrescenta "(Excluído)" ao título quando imov_icexclusao = SIM (ExibirConsultarImovelDadosCadastraisAction:80)
        'excluido_exibido': bool(re.search(r'Dados do Im.vel\s*\(Exclu', texto_visivel(html))),
        'situacao_agua': valor_campo(html, 'situacaoAguaDadosCadastrais'),
        'situacao_esgoto': valor_campo(html, 'situacaoEsgotoDadosCadastrais'),
        'perfil': valor_campo(html, 'imovelPerfilDadosCadastrais'),
        'composicao': composicao,
        'total_economias_exibido': int(total.group(1)) if total else None,
    }


def consultar_imoveis_matricula(sessao, entrada):
    """[UC0472] Consultar Imóvel pela matrícula, uma consulta por matrícula da lista, na mesma sessão."""
    consultas = []
    for matricula in entrada['matriculas']:
        r = consultar_imovel_dados_cadastrais(sessao, {'matricula': matricula})
        consultas.append({'matricula': matricula, 'resultado': r['resultado'], 'inscricao': r.get('inscricao'),
                          'excluido_exibido': r.get('excluido_exibido')})
    return {'consultas': consultas}


def consultar_relacao_cliente_imovel(sessao, entrada):
    """Consultar Relação Cliente e Imóvel (ConsultarRelacaoClienteImovelAction → ExibirImovelRelacaoClienteImovelAction):
    TODOS os vínculos do imóvel — vigentes e encerrados —, ordenados pelo legado por tipo de relação e data de início."""
    sessao.get('ExibirConsultarRelacaoClienteImovelAction.do?menu=sim')
    filtros = entrada.get('filtros', {})
    html = sessao.post('ConsultarRelacaoClienteImovelAction.do', {
        'idImovel': str(entrada['matricula']), 'idCliente': '',
        'idClienteRelacaoTipo': str(filtros.get('tipo_relacao', '')),
        'idClienteImovelFimRelacaoMotivo': str(filtros.get('motivo_fim', '')),
        'periodoInicialDataInicioRelacao': filtros.get('inicio_de', ''), 'periodoFinalDataInicioRelacao': filtros.get('inicio_ate', ''),
        'periodoInicialDataFimRelacao': filtros.get('fim_de', ''), 'periodoFinalDataFimRelacao': filtros.get('fim_ate', ''),
        'situacaoRelacao': str(filtros.get('situacao', '3'))})
    ini = html.find('Clientes Relacionados')
    if ini < 0:
        return {'resultado': 'recusado', 'http': sessao.ultimo_estado, 'mensagem': texto_visivel(html)[-400:]}
    fim = html.find('Dados da(s)', ini)  # a seção seguinte (economias); o cabeçalho da lista é uma tabela própria
    fim = fim if fim > 0 else len(html)
    vinculos = []
    for tr in re.findall(r'(?is)<tr align="left" bgcolor="#(?:FFFFFF|cbe5fe)" height="18">(.*?)</tr>', html[ini:fim]):
        tds = [texto_visivel(td) or None for td in re.findall(r'(?is)<td\b[^>]*>(.*?)</td>', tr)]
        if len(tds) == 6:
            vinculos.append(dict(zip(('cliente', 'nome', 'tipo_relacao', 'inicio', 'fim', 'motivo_fim'), tds)))
    return {'resultado': 'consultado', 'vinculos': vinculos}


def consultar_consumo_minimo_ligacao_agua(sessao, entrada):
    """Atualizar Consumo Mínimo da Ligação de Água — só a EXIBIÇÃO, a partir de uma OS encerrada e executada
    (ExibirAtualizarConsumoMinimoLigacaoAguaAction): o "Valor Obtido" é obterConsumoMinimoLigacao(imovel, null)."""
    sessao.get('exibirAtualizarConsumoMinimoLigacaoAguaAction.do?menu=sim')
    html = sessao.post('exibirAtualizarConsumoMinimoLigacaoAguaAction.do',
                       {'idOrdemServico': str(entrada['ordem_servico']), 'veioEncerrarOS': 'false'})
    if sessao.ultimo_estado >= 400:
        return {'resultado': 'recusado', 'http': sessao.ultimo_estado, 'mensagem': _mensagem(html) or _atencao(html)}
    return {
        'resultado': 'exibido',
        'matricula': valor_campo(html, 'matriculaImovel'),
        'situacao_agua': valor_campo(html, 'situacaoLigacaoAgua'),
        'categoria_exibida': valor_campo(html, 'categoriaImovel'),
        'economias_exibidas': valor_campo(html, 'qtdeEconomia'),
        'consumo_minimo_fixado': valor_campo(html, 'consumoMinimoFixado'),
        'valor_obtido': valor_campo(html, 'valorObtido'),
    }


# --- Atendimento: efeitos da OS -------------------------------------------------------------------
# A OS chega à operação ENCERRADA e executada (massa); a operação "Efetuar Ligação de Água" é executada pela tela e
# o que ela grava é lido do banco — situação do imóvel, a ligação, os indicadores da OS e o débito a cobrar. Ids
# sequenciais não saem; datas que o legado preenche com o relógio saem como "preenchida" ou relativas ao mês corrente.

def _formulario(html, nome):
    """O que o NAVEGADOR enviaria do formulário `nome`: campos de texto e ocultos com o valor, rádio/caixa marcados, e de
    cada seletor a opção marcada (ou a primeira). Botões não vão."""
    m = re.search(r'(?is)<form\b[^>]*name="' + re.escape(nome) + r'"[^>]*>(.*?)</form>', html)
    corpo = m.group(1) if m else ''
    dados = {}
    for tag in re.findall(r'(?is)<input\b[^>]*>', corpo):
        n = re.search(r'(?i)\bname="([^"]*)"', tag)
        tipo = (re.search(r'(?i)\btype="([^"]*)"', tag) or [None, 'text'])[1].lower()
        if not n or tipo in ('button', 'submit', 'reset', 'image'):
            continue
        if tipo in ('radio', 'checkbox') and not re.search(r'(?i)\bchecked\b', tag):
            continue
        v = re.search(r'(?i)\bvalue="([^"]*)"', tag)
        dados[n.group(1)] = v.group(1) if v else ''
    for n, opcoes in re.findall(r'(?is)<select\b[^>]*\bname="([^"]*)"[^>]*>(.*?)</select>', corpo):
        valores = re.findall(r'(?is)<option\b([^>]*)>', opcoes)
        escolhida = next((o for o in valores if re.search(r'(?i)\bselected\b', o)), valores[0] if valores else '')
        v = re.search(r'(?i)\bvalue="([^"]*)"', escolhida)
        dados[n] = v.group(1) if v else ''
    return dados


def _estado_ligacao_agua(ctx, imovel, os_id):
    def um(q):
        v = json.loads(ctx.sql(f"select coalesce(json_agg(x), '[]') from ({q}) x") or '[]')
        return v[0] if v else None

    def todos(q):
        return json.loads(ctx.sql(f"select coalesce(json_agg(x), '[]') from ({q}) x") or '[]')
    return {
        'imovel': um("select la.last_dsligacaoaguasituacao as situacao_agua, le.lest_dsligacaoesgotosituacao as situacao_esgoto"
                     " from cadastro.imovel i join atendimentopublico.ligacao_agua_situacao la using (last_id)"
                     f" join atendimentopublico.ligacao_esgoto_situacao le using (lest_id) where i.imov_id = {int(imovel)}"),
        'ligacao_agua': um("select to_char(l.lagu_dtligacaoagua, 'DD/MM/YYYY') as data_ligacao, d.lagd_dsligacaoaguadiametro as diametro,"
                           " m.lagm_dsligacaoaguamaterial as material, p.lapf_dsligacaoaguaperfil as perfil,"
                           " l.rlin_id as ramal_local, l.lgor_id as origem, l.lagu_nnconsumominimoagua as consumo_minimo"
                           " from atendimentopublico.ligacao_agua l join atendimentopublico.ligacao_agua_diametro d using (lagd_id)"
                           " join atendimentopublico.ligacao_agua_material m using (lagm_id)"
                           f" left join atendimentopublico.ligacao_agua_perfil p using (lapf_id) where l.lagu_id = {int(imovel)}"),
        'ordem_servico': um("select o.orse_cdsituacao as situacao, o.orse_iccomercialatualizado as comercial_atualizado,"
                            " o.orse_icatualizaagua as atualiza_agua, o.orse_vlservicoatual::text as valor_atual,"
                            " o.orse_pcvalorcobranca::text as percentual_cobranca, m.sncm_dsservnaocobmotivo as motivo_nao_cobranca"
                            " from atendimentopublico.ordem_servico o left join atendimentopublico.servico_nao_cobr_motivo m"
                            f" using (sncm_id) where o.orse_id = {int(os_id)}"),
        'debitos': todos("select t.dbtp_dsdebitotipo as tipo, d.dbac_vldebito::text as valor, d.dbac_nnprestacaodebito as prestacoes,"
                         " d.dbac_nnprestacaocobradas as cobradas, d.dbac_amreferenciadebito as referencia,"
                         " d.dbac_amcobrancadebito as cobranca, (d.dbac_amreferenciacontabil = to_char(current_date, 'YYYYMM')::int)"
                         " as referencia_contabil_mes_corrente, s.dcst_dsdebitocreditosituacao as situacao,"
                         " f.cbfm_dscobrancaforma as forma, d.dbac_pctaxajurosfinanciamento::text as taxa_juros,"
                         " (d.orse_id is not null) as ligado_a_os, (d.rgat_id is not null) as ligado_ao_ra,"
                         " (select json_agg(json_build_object('categoria', c.catg_dscategoria, 'economias', k.dbcg_qteconomia,"
                         "   'valor', k.dbcg_vlcategoria::text) order by c.catg_id) from faturamento.deb_a_cobrar_catg k"
                         "   join cadastro.categoria c using (catg_id) where k.dbac_id = d.dbac_id) as por_categoria"
                         " from faturamento.debito_a_cobrar d join faturamento.debito_tipo t using (dbtp_id)"
                         " join faturamento.debito_credito_situacao s on s.dcst_id = d.dcst_idatual"
                         f" join cobranca.cobranca_forma f using (cbfm_id) where d.imov_id = {int(imovel)} order by d.dbac_id"),
        'registros_de_operacao': int(ctx.sql('select count(*) from seguranca.operacao_efetuada')),
    }


def efetuar_ligacao_agua(ctx, entrada):
    """Efetuar Ligação de Água a partir de uma OS (ExibirEfetuarLigacaoAguaAction → EfetuarLigacaoAguaAction →
    ControladorAtendimentoPublicoSEJB.efetuarLigacaoAgua → gerarDebitoOrdemServico)."""
    login = entrada['usuario']
    ctx.nova_sessao()
    ctx.atual.tentar_login(login, ctx.senha(login, 'correta'))
    os_id, imovel = entrada.get('ordem_servico'), entrada['imovel']
    antes = _estado_ligacao_agua(ctx, imovel, os_id or 0)
    html = ctx.atual.get('exibirEfetuarLigacaoAguaAction.do?menu=sim')
    sem_ra_na_tela = 'permissaoAlterarOSsemRA' in html and valor_campo(html, 'permissaoAlterarOSsemRA') == 'true'
    if os_id:
        html = ctx.atual.post('exibirEfetuarLigacaoAguaAction.do', {'idOrdemServico': str(os_id), 'veioEncerrarOS': 'false'})
    else:  # sem OS: o usuário digita a matrícula (a tela só a habilita com a permissão EFETUAR_LIGACAO_DE_AGUA_SEM_RA)
        html = ctx.atual.post('exibirEfetuarLigacaoAguaAction.do', {'idImovel': str(imovel), 'veioEncerrarOS': 'false'})
    tela = {'http': ctx.atual.ultimo_estado, 'mensagem': _mensagem(html) or (_atencao(html) if ctx.atual.ultimo_estado >= 400 else None)}
    for campo in ('nomeOrdemServico', 'matriculaImovel', 'situacaoLigacaoAgua', 'dataLigacao', 'idTipoDebito', 'valorDebito',
                  'quantidadeParcelas', 'valorParcelas'):
        tela[campo] = valor_campo(html, campo)
    tela['permite_motivo_nao_cobranca'] = bool(re.search(r'name="motivoNaoCobranca"', html))
    tela['matricula_habilitada_sem_ra'] = sem_ra_na_tela
    if ctx.atual.ultimo_estado >= 400:
        return {'tela': tela, 'resultado': 'recusado_na_exibicao', 'antes': antes, 'depois': antes}
    enviado = entrada.get('enviar', {})
    # O que a tela renderizou, como o navegador enviaria, mais as escolhas do usuário nos seletores e campos obrigatórios.
    dados = _formulario(html, 'EfetuarLigacaoAguaActionForm')
    dados.update({'diametroLigacao': '1', 'materialLigacao': '1', 'perfilLigacao': '1', 'ramalLocalInstalacao': '1',
                  'idLigacaoOrigem': '1', 'profundidadeRamal': '1,00', 'distanciaInstalacaoRamal': '2,00', 'aceitaLacre': '2'})
    if not os_id:
        dados.update({'matriculaImovel': str(imovel), 'dataLigacao': entrada['data_ligacao']})
    if 'percentualCobranca' in dados:
        dados['percentualCobranca'] = '100'
    if 'quantidadeParcelas' in dados and not dados['quantidadeParcelas']:
        dados['quantidadeParcelas'] = '1'
    # O que a variação digita — ou FORJA, quando a tela não deixaria (o POST é aceito ou não pelo servidor).
    for chave, campo in (('parcelas', 'quantidadeParcelas'), ('valor_debito', 'valorDebito'),
                         ('percentual_cobranca', 'percentualCobranca'), ('motivo_nao_cobranca', 'motivoNaoCobranca')):
        if chave in enviado:
            dados[campo] = str(enviado[chave])
    html = ctx.atual.post('efetuarLigacaoAguaAction.do', dados)
    sucesso = 'efetuada com Sucesso' in texto_visivel(html)
    return {'tela': tela, 'enviado': enviado, 'http': ctx.atual.ultimo_estado,
            'resultado': 'efetuada' if sucesso else 'recusada',
            'mensagem': None if sucesso else (_mensagem(html) or _atencao(html)),
            'antes': antes, 'depois': _estado_ligacao_agua(ctx, imovel, os_id or 0)}


# --- Processamento: faturamento em grupo (EAR em modo Batch) ---------------------------------------
# O comando de FATURAR GRUPO chega pela massa (cronograma, rotas e consumos); a operação é disparada pela tela "Inserir
# Processo Faturamento Comandado" e executada pelo agendador do EAR Batch (verificador do Quartz a cada minuto → uma
# unidade por rota). O roteiro espera o processo chegar a um estado terminal e lê do banco o que o framework e o
# faturamento gravaram. Ids sequenciais e carimbos de tempo não saem: processos pela ordem de criação, unidades pelo
# código da rota, contas pela matrícula, exceção pelas chaves de mensagem do legado. Única escrita fora do GSAN: o passo
# `aplicar` de uma variação que corrige a causa de uma falha (arquivo de massas/passos/, com o sha256 no resultado).

PROCESSO_TERMINAL = (2, 6, 7)  # ProcessoSituacao: CONCLUIDO, CONCLUIDO_COM_ERRO, EXECUCAO_CANCELADA
ESPERA_MAXIMA = 900  # segundos


def _linhas(ctx, q):
    return json.loads(ctx.sql(f"select coalesce(json_agg(x), '[]') from ({q}) x") or '[]')


def _contas_entregues(ctx):
    """Números que a sequência das contas já entregou — não voltam num rollback: medem as contas INICIADAS."""
    return int(ctx.sql('select case when is_called then last_value else last_value - 1 end from faturamento.seq_conta_geral'))


def _lancamentos(ctx):
    """Débitos cobrados e créditos realizados nas contas, e o que resta a cobrar/realizar (CEN-FAT-004)."""
    return {
        'debitos_cobrados': _linhas(ctx, "select c.imov_id as matricula, c.cnta_amreferenciaconta as referencia_conta,"
                                         " t.dbtp_dsdebitotipo as tipo, f.fntp_dsfinanciamentotipo as financiamento,"
                                         " d.dbcb_nnprestacaodebito as prestacao, d.dbcb_nnprestacao as prestacoes,"
                                         " d.dbcb_vlprestacao::text as valor, d.dbcb_amreferenciadebito as referencia_debito,"
                                         " d.dbcb_amcobrancadebito as cobranca,"
                                         " (select json_agg(json_build_object('categoria', g.catg_dscategoria, 'economias', k.dccg_qteconomia,"
                                         "   'valor', k.dccg_vlcategoria::text) order by k.catg_id) from faturamento.debito_cobrado_categoria k"
                                         "   join cadastro.categoria g using (catg_id) where k.dbcb_id = d.dbcb_id) as por_categoria"
                                         " from faturamento.debito_cobrado d join faturamento.conta c using (cnta_id)"
                                         " join faturamento.debito_tipo t using (dbtp_id) join financeiro.financiamento_tipo f on f.fntp_id = d.fntp_id"
                                         " order by c.imov_id, c.cnta_amreferenciaconta, d.dbtp_id, d.dbcb_nnprestacaodebito"),
        'creditos_realizados': _linhas(ctx, "select c.imov_id as matricula, c.cnta_amreferenciaconta as referencia_conta,"
                                            " t.crti_dscreditotipo as tipo, o.crog_dscreditoorigem as origem,"
                                            " r.crrz_nnprestacaocredito as prestacao, r.crrz_nnprestacao as prestacoes,"
                                            " r.crrz_vlcredito::text as valor"
                                            " from faturamento.credito_realizado r join faturamento.conta c using (cnta_id)"
                                            " left join faturamento.credito_tipo t using (crti_id)"
                                            " join faturamento.credito_origem o using (crog_id)"
                                            " order by c.imov_id, c.cnta_amreferenciaconta, r.crti_id, r.crrz_nnprestacaocredito"),
        'debitos_a_cobrar': _linhas(ctx, "select d.imov_id as matricula, t.dbtp_dsdebitotipo as tipo, d.dbac_vldebito::text as valor,"
                                         " d.dbac_nnprestacaodebito as prestacoes, d.dbac_nnprestacaocobradas as cobradas,"
                                         " d.dbac_amreferenciaprestacao as referencia_ultima_prestacao, (d.parc_id is not null) as de_parcelamento,"
                                         " s.dcst_dsdebitocreditosituacao as situacao"
                                         " from faturamento.debito_a_cobrar d join faturamento.debito_tipo t using (dbtp_id)"
                                         " join faturamento.debito_credito_situacao s on s.dcst_id = d.dcst_idatual"
                                         " order by d.imov_id, d.dbtp_id, d.dbac_vldebito"),
        'creditos_a_realizar': _linhas(ctx, "select r.imov_id as matricula, t.crti_dscreditotipo as tipo, r.crar_vlcredito::text as valor,"
                                            " r.crar_nnprestacaocredito as prestacoes, r.crar_nnprestacaorealizadas as realizadas,"
                                            " r.crar_vlresidualmesanterior::text as residual,"
                                            " r.crar_vlresidualconcedidomes::text as residual_concedido_mes,"
                                            " r.crar_amreferenciaprestacao as referencia_ultima_prestacao,"
                                            " s.dcst_dsdebitocreditosituacao as situacao"
                                            " from faturamento.credito_a_realizar r join faturamento.credito_tipo t using (crti_id)"
                                            " join faturamento.debito_credito_situacao s on s.dcst_id = r.dcst_idatual"
                                            " order by r.imov_id, r.crti_id, r.crar_vlcredito"),
    }


def _impostos(ctx):
    """Impostos deduzidos de cada conta: base, alíquota e valor por imposto (CEN-FAT-005)."""
    return {'impostos': _linhas(ctx, "select c.imov_id as matricula, c.cnta_amreferenciaconta as referencia_conta,"
                                     " t.imtp_dsimposto as imposto, i.cnid_pcaliquota::text as aliquota,"
                                     " i.cnid_vlbasecalculo::text as base, i.cnid_vlimposto::text as valor"
                                     " from faturamento.conta_impostos_deduzidos i join faturamento.conta c using (cnta_id)"
                                     " join faturamento.imposto_tipo t using (imtp_id)"
                                     " order by c.imov_id, c.cnta_amreferenciaconta, i.imtp_id")}


def _rateio(ctx):
    """Rateio de micro-condomínio: o que cada conta recebeu e o histórico de consumo do principal e dos vinculados
    (CEN-FAT-006)."""
    return {
        'rateio_contas': _linhas(ctx, "select c.imov_id as matricula, c.cnta_amreferenciaconta as referencia_conta,"
                                      " c.cnta_nnconsumoagua as consumo_agua, c.cnta_nnconsumorateioagua as consumo_rateio_agua,"
                                      " c.cnta_vlrateioagua::text as valor_rateio_agua, c.cnta_vlagua::text as valor_agua,"
                                      " c.cnta_vlrateioesgoto::text as valor_rateio_esgoto"
                                      " from faturamento.conta c join cadastro.imovel i using (imov_id)"
                                      " where i.imov_idimovelcondominio is not null or i.imov_icimovelcondominio = 1"
                                      " order by c.imov_id, c.cnta_amreferenciaconta"),
        'rateio_consumos': _linhas(ctx, "select h.imov_id as matricula, (i.imov_icimovelcondominio = 1) as principal,"
                                        " h.cshi_amfaturamento as referencia, h.cshi_nnconsumofaturadomes as consumo,"
                                        " h.cshi_nnconsumorateio as consumo_rateio, h.cshi_nnconsimoveisvinculados as consumo_vinculados,"
                                        " (h.cshi_idconsumoimovelcondominio is not null) as ligado_ao_principal"
                                        " from micromedicao.consumo_historico h join cadastro.imovel i using (imov_id)"
                                        " where i.imov_idimovelcondominio is not null or i.imov_icimovelcondominio = 1"
                                        " order by h.imov_id, h.cshi_amfaturamento, h.lgti_id"),
    }


def _micromedicao(ctx):
    """Medições e consumos como a consistência de leituras os deixou: leituras anterior/atual (informadas e de
    faturamento), consumo medido, média do hidrômetro, situação e anormalidades; consumo faturado, para média, médio, tipo
    e anormalidade de consumo (CEN-MIC-*)."""
    return {
        'medicoes': _linhas(ctx, "select m.lagu_id as matricula, m.mdhi_amleitura as referencia, t.medt_dsmedicaotipo as medicao,"
                                 " m.mdhi_nnleitantfatmt as leitura_anterior_faturamento,"
                                 " to_char(m.mdhi_dtleitantfatmt, 'DD/MM/YYYY') as data_leitura_anterior,"
                                 " m.mdhi_nnleitantinformada as leitura_anterior_informada,"
                                 " m.mdhi_nnleituraatualinformada as leitura_atual_informada,"
                                 " to_char(m.mdhi_dtleituraatualinformada, 'DD/MM/YYYY') as data_leitura_atual_informada,"
                                 " m.mdhi_nnleituraatualfaturamento as leitura_atual_faturamento,"
                                 " to_char(m.mdhi_dtleituraatualfaturamento, 'DD/MM/YYYY') as data_leitura_atual_faturamento,"
                                 " m.mdhi_nnconsumomedidomes as consumo_medido, m.mdhi_nnconsumoinformado as consumo_informado,"
                                 " m.mdhi_nnconsumomediohidrometro as consumo_medio_hidrometro,"
                                 " sa.ltst_dsleiturasituacao as situacao_atual, sp.ltst_dsleiturasituacao as situacao_anterior,"
                                 " ai.ltan_dsleituraanormalidade as anormalidade_informada,"
                                 " af.ltan_dsleituraanormalidade as anormalidade_faturamento, m.mdhi_icanalisado as analisado"
                                 " from micromedicao.medicao_historico m join micromedicao.medicao_tipo t using (medt_id)"
                                 " left join micromedicao.leitura_situacao sa on sa.ltst_id = m.ltst_idleiturasituacaoatual"
                                 " left join micromedicao.leitura_situacao sp on sp.ltst_id = m.ltst_idleiturasituacaoanterior"
                                 " left join micromedicao.leitura_anormalidade ai on ai.ltan_id = m.ltan_idleitanorminformada"
                                 " left join micromedicao.leitura_anormalidade af on af.ltan_id = m.ltan_idleitanormfatmt"
                                 " order by coalesce(m.lagu_id, m.imov_id), m.medt_id, m.mdhi_amleitura"),
        'instalacoes': _linhas(ctx, "select i.lagu_id as matricula, d.hidr_nnhidrometro as hidrometro,"
                                    " to_char(i.hidi_dtinstalacaohidrometro, 'DD/MM/YYYY') as data_instalacao,"
                                    " i.hidi_nnleitinstalacaohidmt as leitura_instalacao,"
                                    " to_char(i.hidi_dtretiradahidrometro, 'DD/MM/YYYY') as data_retirada,"
                                    " i.hidi_nnleitretiradahidmt as leitura_retirada,"
                                    " (l.hidi_id = i.hidi_id) as instalacao_atual_da_ligacao"
                                    " from micromedicao.hidrometro_inst_hist i join micromedicao.hidrometro d using (hidr_id)"
                                    " left join atendimentopublico.ligacao_agua l on l.lagu_id = i.lagu_id"
                                    " order by i.lagu_id, i.hidi_dtinstalacaohidrometro, d.hidr_nnhidrometro"),
        'consumos_detalhe': _linhas(ctx, "select h.imov_id as matricula, h.cshi_amfaturamento as referencia, l.lgti_dsligacaotipo as ligacao,"
                                         " h.cshi_nnconsumofaturadomes as consumo_faturado, h.cshi_nnconsumocalculomedia as consumo_para_media,"
                                         " h.cshi_nnconsumomedio as consumo_medio, h.cshi_nnconsumominimo as consumo_minimo,"
                                         " t.cstp_dsconsumotipo as tipo, a.csan_dsconsumoanormalidade as anormalidade,"
                                         " h.cshi_icfaturamento as indicador_faturamento, h.cshi_icajuste as ajuste"
                                         " from micromedicao.consumo_historico h left join micromedicao.ligacao_tipo l using (lgti_id)"
                                         " left join micromedicao.consumo_tipo t using (cstp_id)"
                                         " left join micromedicao.consumo_anormalidade a using (csan_id)"
                                         " order by h.imov_id, h.cshi_amfaturamento, h.lgti_id"),
    }


# Identidade documental da conta: matrícula, referência e ordem de criação na referência — nunca a chave técnica.
IDENT = ("with ident as (select cnta_id, imov_id, cnta_amreferenciaconta,"
         " row_number() over (partition by imov_id, cnta_amreferenciaconta order by cnta_id) as ordem from faturamento.conta) ")
IDENT_JSON = "json_build_object('matricula', {a}.imov_id, 'referencia', {a}.cnta_amreferenciaconta, 'ordem', {a}.ordem)"


def _data_relativa(coluna):
    """Data gravada pelo relógio do legado sai relativa à execução; as datas da massa saem como estão."""
    return (f"case when {coluna} is null then null when {coluna}::date = current_date then 'data da execução'"
            f" else to_char({coluna}, 'DD/MM/YYYY') end")


def _ciclo_conta(ctx):
    """Ciclo de vida das contas (CEN-FAT-007, CEN-FAT-008): cada conta pela identidade documental, com situação atual e
    anterior, valores, motivos, retificações e referência contábil; as contas gerais que ficaram SEM documento (exclusão
    física); pagamentos e RA pela conta a que apontam; o histórico de consumo; e a trilha de auditoria das operações
    (tabela, coluna, valor anterior e atual, como o legado os grava)."""
    contas = _linhas(ctx, IDENT +
                     "select c.imov_id as matricula, c.cnta_amreferenciaconta as referencia, i.ordem,"
                     " s.dcst_dsdebitocreditosituacao as situacao, sa.dcst_dsdebitocreditosituacao as situacao_anterior,"
                     " c.cnta_nnconsumoagua as consumo_agua, c.cnta_nnconsumoesgoto as consumo_esgoto,"
                     " (select sum(k.ctcg_qteconomia) from faturamento.conta_categoria k where k.cnta_id = c.cnta_id) as economias,"
                     " c.cnta_vlagua::text as valor_agua, c.cnta_vlesgoto::text as valor_esgoto,"
                     " c.cnta_vldebitos::text as valor_debitos, c.cnta_vlcreditos::text as valor_creditos,"
                     " (c.cnta_vlagua + c.cnta_vlesgoto + c.cnta_vldebitos - c.cnta_vlcreditos"
                     "  - coalesce(c.cnta_vlimpostos, 0))::text as valor_total,"
                     " mr.cmrt_dsmotivoretificacaoconta as motivo_retificacao, mc.cmcn_dsmotivocancelamentoconta as motivo_cancelamento,"
                     " c.cnta_nnretificacao as retificacoes,"
                     f" {_data_relativa('c.cnta_dtretificacao')} as data_retificacao,"
                     f" {_data_relativa('c.cnta_dtcancelamento')} as data_cancelamento,"
                     f" {_data_relativa('c.cnta_dtemissao')} as data_emissao,"
                     " to_char(c.cnta_dtvencimentoconta, 'DD/MM/YYYY') as vencimento,"
                     " c.cnta_icalteracaovencimento as indicador_alteracao_vencimento,"
                     " case when c.cnta_amreferenciacontabil = to_char(current_date, 'YYYYMM')::int then 'mês da execução'"
                     "  else c.cnta_amreferenciacontabil::text end as referencia_contabil,"
                     " case when c.cnta_idorigem is null then null else coalesce((select " + IDENT_JSON.format(a='o') +
                     "  from ident o where o.cnta_id = c.cnta_idorigem), json_build_object('conta_geral_sem_documento', true)) end"
                     " as origem,"
                     " (c.rgat_id is not null) as ligada_a_ra, u.usur_nmlogin as autor,"
                     " (select count(*) from cadastro.cliente_conta k where k.cnta_id = c.cnta_id) as clientes,"
                     " g.cntg_ichistorico as indicador_historico"
                     " from faturamento.conta c join ident i using (cnta_id) join faturamento.conta_geral g using (cnta_id)"
                     " join faturamento.debito_credito_situacao s on s.dcst_id = c.dcst_idatual"
                     " left join faturamento.debito_credito_situacao sa on sa.dcst_id = c.dcst_idanterior"
                     " left join faturamento.conta_motivo_retificacao mr using (cmrt_id)"
                     " left join faturamento.conta_mot_cancelamento mc using (cmcn_id) left join seguranca.usuario u using (usur_id)"
                     " order by c.imov_id, c.cnta_amreferenciaconta, i.ordem")
    return {
        'contas_ciclo': contas,
        'contas_gerais_sem_documento': _linhas(ctx, "select g.cntg_ichistorico as indicador_historico, count(*) as quantidade"
                                                    " from faturamento.conta_geral g"
                                                    " where not exists (select 1 from faturamento.conta c where c.cnta_id = g.cnta_id)"
                                                    " and not exists (select 1 from faturamento.conta_historico h"
                                                    "  where h.cnta_id = g.cnta_id) group by 1 order by 1"),
        'pagamentos': _linhas(ctx, IDENT +
                              "select p.imov_id as matricula, p.pgmt_amreferenciapagamento as referencia_pagamento,"
                              " p.pgmt_vlpagamento::text as valor, ps.pgst_dspagamentosituacao as situacao,"
                              " case when p.cnta_id is null then null else coalesce((select " + IDENT_JSON.format(a='i') +
                              "  from ident i where i.cnta_id = p.cnta_id), json_build_object('conta_geral_sem_documento', true)) end"
                              " as conta"
                              " from arrecadacao.pagamento p left join arrecadacao.pagamento_situacao ps on ps.pgst_id = p.pgst_idatual"
                              " order by p.imov_id, p.pgmt_amreferenciapagamento, p.pgmt_vlpagamento"),
        'registros_atendimento': _linhas(ctx, IDENT +
                                         "select r.imov_id as matricula, e.step_dssolcttipoespec as especificacao,"
                                         " r.rgat_cdsituacao as codigo_situacao, m.amen_dsmotivoencerramento as motivo_encerramento,"
                                         " r.rgat_dsparecerencerramento as parecer,"
                                         f" {_data_relativa('r.rgat_tmencerramento')} as data_encerramento,"
                                         " (select json_agg(json_build_object('tramite', t.attp_dsatendimentorelacaotipo,"
                                         "   'unidade', o.unid_dssiglaunidade, 'usuario', us.usur_nmlogin) order by ru.raun_id)"
                                         "   from atendimentopublico.ra_unidade ru"
                                         "   join atendimentopublico.atendimento_relacao_tipo t using (attp_id)"
                                         "   join cadastro.unidade_organizacional o using (unid_id) join seguranca.usuario us using (usur_id)"
                                         "   where ru.rgat_id = r.rgat_id) as tramites,"
                                         " (select json_agg(" + IDENT_JSON.format(a='i') + " order by i.imov_id, i.cnta_amreferenciaconta,"
                                         "   i.ordem) from ident i join faturamento.conta c using (cnta_id) where c.rgat_id = r.rgat_id)"
                                         " as contas_ligadas"
                                         " from atendimentopublico.registro_atendimento r"
                                         " join atendimentopublico.solicitacao_tipo_espec e using (step_id)"
                                         " left join atendimentopublico.atend_motivo_encmt m using (amen_id)"
                                         " order by r.imov_id, r.rgat_tmregistroatendimento"),
        'consumos_ciclo': _linhas(ctx, "select h.imov_id as matricula, h.cshi_amfaturamento as referencia, h.lgti_id as ligacao_tipo,"
                                       " h.cshi_nnconsumofaturadomes as consumo_faturado, h.cshi_nnconsumocalculomedia as consumo_para_media,"
                                       " h.cshi_nnconsumomedio as consumo_medio,"
                                       " (h.cshi_tmultimaalteracao::date = current_date) as alterado_na_data_da_execucao"
                                       " from micromedicao.consumo_historico h order by h.imov_id, h.cshi_amfaturamento, h.lgti_id"),
        'auditoria': _linhas(ctx, "select o.oper_dsoperacao as operacao, e.opef_cnargumento as argumento,"
                                  " e.opef_dsdadosadicionais as dados_adicionais,"
                                  " (select json_agg(json_build_object('tabela', t.tabe_nmtabela, 'alteracao', a.altp_dsalteracaotipo,"
                                  "   'colunas', (select json_agg(json_build_object('coluna', tc.tbco_nmcoluna,"
                                  "     'anterior', ca.tbca_cncolunaanterior, 'atual', ca.tbca_cncolunaatual) order by ca.tbca_id)"
                                  "     from seguranca.tab_linha_col_alteracao ca join seguranca.tabela_coluna tc using (tbco_id)"
                                  "     where ca.tbla_id = l.tbla_id)) order by l.tbla_id)"
                                  "   from seguranca.tabela_linha_alteracao l join seguranca.tabela t using (tabe_id)"
                                  "   join seguranca.alteracao_tipo a using (altp_id) where l.tref_id = e.opef_id) as linhas"
                                  " from seguranca.operacao_efetuada e join seguranca.operacao o using (oper_id) order by e.opef_id"),
    }


DETALHES = {'lancamentos': _lancamentos, 'impostos': _impostos, 'rateio': _rateio, 'micromedicao': _micromedicao,
            'ciclo_conta': _ciclo_conta}


def _estado_faturamento(ctx, contas_no_inicio, detalhes=(), comando=1):
    processos = _linhas(ctx, "select p.proi_id, pr.proc_dsprocesso as processo, s.prst_dsprocessosituacao as situacao,"
                             " u.usur_nmlogin as solicitante, p.proi_nngrupo as grupo,"
                             " (p.proi_tminicio is not null) as inicio_registrado, (p.proi_tmtermino is not null) as termino_registrado"
                             " from batch.processo_iniciado p join batch.processo pr using (proc_id)"
                             " join batch.processo_situacao s using (prst_id) left join seguranca.usuario u using (usur_id)"
                             " order by p.proi_id")
    ordem = {p.pop('proi_id'): i + 1 for i, p in enumerate(processos)}
    for i, p in enumerate(processos):
        p['ordem'] = i + 1
    funcionalidades = _linhas(ctx, "select f.proi_id, pf.prfn_nnsequencialexecucao as sequencia, pf.fncd_id as funcionalidade,"
                                   " sf.fncd_dsfuncionalidade as descricao, s.fnst_dsoperacaosituacao as situacao,"
                                   " (f.fuin_tminicio is not null) as inicio_registrado,"
                                   " (f.fuin_tmtermino is not null) as termino_registrado, coalesce(f.fuin_dserro, '') as erro"
                                   " from batch.funcionalidade_iniciada f join batch.processo_funcionalidade pf using (prfn_id)"
                                   " join batch.funcionalidade_situacao s using (fnst_id)"
                                   " left join seguranca.funcionalidade sf on sf.fncd_id = pf.fncd_id"
                                   " order by f.proi_id, pf.prfn_nnsequencialexecucao, f.fuin_id")
    for f in funcionalidades:
        f['processo'] = ordem.get(f.pop('proi_id'))
        erro = f.pop('erro')
        # O texto técnico (pilha) fica fora; ficam o registro e as chaves de mensagem do legado que ele carrega.
        f['erro_registrado'] = bool(erro)
        f['erro_chaves'] = sorted(set(re.findall(r'\b(?:atencao|erro)\.[a-z0-9_.]*[a-z0-9_]', erro)))
    unidades = _linhas(ctx, "select f.proi_id, pf.fncd_id as funcionalidade, u.unpr_id as tipo_unidade, r.rota_cdrota as rota,"
                            " s.unst_dsoperacaosituacao as situacao, (u.undi_tmtermino is not null) as termino_registrado"
                            " from batch.unidade_iniciada u join batch.funcionalidade_iniciada f using (fuin_id)"
                            " join batch.processo_funcionalidade pf using (prfn_id) join batch.unidade_situacao s using (unst_id)"
                            " left join micromedicao.rota r on r.rota_id = u.undi_cdidunidadeprocessamento"
                            " order by f.proi_id, pf.fncd_id, r.rota_cdrota, s.unst_dsoperacaosituacao")
    for u in unidades:
        u['processo'] = ordem.get(u.pop('proi_id'))
    contas = _linhas(ctx, "select c.cnta_id, c.imov_id as matricula, r.rota_cdrota as rota, c.cnta_amreferenciaconta as referencia,"
                          " s.dcst_dsdebitocreditosituacao as situacao, c.cnta_nnconsumoagua as consumo_agua,"
                          " c.cnta_nnconsumoesgoto as consumo_esgoto, c.cnta_vlagua::text as valor_agua,"
                          " c.cnta_vlesgoto::text as valor_esgoto, c.cnta_vldebitos::text as valor_debitos,"
                          " c.cnta_vlcreditos::text as valor_creditos, coalesce(c.cnta_vlimpostos, 0)::text as valor_impostos,"
                          " (c.cnta_vlagua + c.cnta_vlesgoto + c.cnta_vldebitos - c.cnta_vlcreditos"
                          "  - coalesce(c.cnta_vlimpostos, 0))::text as valor_total,"
                          " to_char(c.cnta_dtvencimentoconta, 'DD/MM/YYYY') as vencimento,"
                          " to_char(c.cnta_dtvalidadeconta, 'DD/MM/YYYY') as validade,"
                          " c.cnta_amreferenciacontabil as referencia_contabil, c.cnta_dgverificadorconta as digito_verificador,"
                          " (c.cnta_dtemissao = current_date) as emitida_na_data_da_execucao, u.usur_nmlogin as autor,"
                          " t.cttp_dstipoconta as tipo_impressao"
                          " from faturamento.conta c join faturamento.debito_credito_situacao s on s.dcst_id = c.dcst_idatual"
                          " left join micromedicao.rota r on r.rota_id = c.rota_id left join seguranca.usuario u using (usur_id)"
                          " left join faturamento.conta_impressao i using (cnta_id) left join faturamento.conta_tipo t using (cttp_id)"
                          " order by c.imov_id, c.cnta_amreferenciaconta, c.cnta_id")
    for c in contas:
        cnta = c.pop('cnta_id')
        c['por_categoria'] = _linhas(ctx, "select g.catg_dscategoria as categoria, sc.scat_dssubcategoria as subcategoria,"
                                          " k.ctcg_qteconomia as economias, k.ctcg_nnconsumoagua as consumo_agua,"
                                          " k.ctcg_vlagua::text as valor_agua, k.ctcg_nnconsumominimoagua as consumo_minimo_agua,"
                                          " k.ctcg_vltarifaminimaagua::text as tarifa_minima_agua,"
                                          " k.ctcg_nnconsumoesgoto as consumo_esgoto, k.ctcg_vlesgoto::text as valor_esgoto,"
                                          " (select coalesce(json_agg(json_build_object('inicio', x.cccf_nnconsumofaixainicio,"
                                          "   'fim', x.cccf_nnconsumofaixafim, 'consumo_agua', x.cccf_nnconsumoagua,"
                                          "   'tarifa', x.cccf_vltarifafaixa::text, 'valor_agua', x.cccf_vlagua::text)"
                                          "   order by x.cccf_nnconsumofaixainicio), '[]') from faturamento.conta_catg_cons_fx x"
                                          "   where x.cnta_id = k.cnta_id and x.catg_id = k.catg_id"
                                          "   and x.scat_id is not distinct from k.scat_id) as faixas"
                                          " from faturamento.conta_categoria k join cadastro.categoria g using (catg_id)"
                                          " left join cadastro.subcategoria sc on sc.scat_id = k.scat_id and sc.scat_id <> 0"
                                          f" where k.cnta_id = {int(cnta)} order by k.catg_id, k.scat_id")
    totais = _linhas(ctx, "select r.rota_cdrota as rota, count(*) as contas, sum(c.cnta_vlagua)::text as valor_agua,"
                          " sum(c.cnta_vlesgoto)::text as valor_esgoto,"
                          " sum(c.cnta_vlagua + c.cnta_vlesgoto + c.cnta_vldebitos - c.cnta_vlcreditos"
                          "     - coalesce(c.cnta_vlimpostos, 0))::text as valor_total"
                          " from faturamento.conta c left join micromedicao.rota r on r.rota_id = c.rota_id"
                          " group by r.rota_cdrota order by r.rota_cdrota")
    grupo = _linhas(ctx, "select count(*) as contas, coalesce(sum(cnta_vlagua + cnta_vlesgoto + cnta_vldebitos - cnta_vlcreditos"
                         " - coalesce(cnta_vlimpostos, 0)), 0)::text as valor_total from faturamento.conta")[0]
    consumos = _linhas(ctx, "select h.imov_id as matricula, h.cshi_amfaturamento as referencia, l.lgti_dsligacaotipo as ligacao,"
                            " h.cshi_nnconsumofaturadomes as consumo, t.cstp_dsconsumotipo as tipo"
                            " from micromedicao.consumo_historico h left join micromedicao.ligacao_tipo l using (lgti_id)"
                            " left join micromedicao.consumo_tipo t using (cstp_id)"
                            " order by h.imov_id, h.cshi_amfaturamento, h.lgti_id")
    return {
        'processos': processos, 'funcionalidades': funcionalidades, 'unidades': unidades, 'contas': contas,
        'totais': {'por_rota': totais, 'grupo': grupo}, 'consumos': consumos,
        'grupo_faturamento': _linhas(ctx, "select ftgr_amreferencia as referencia_atual from faturamento.faturamento_grupo"
                                          " where ftgr_id = 1")[0],
        'comando': _linhas(ctx, "select (ftac_tmrealizacao is not null) as realizado from faturamento.fatur_ativ_cronograma"
                                f" where ftac_id = {int(comando)}")[0],
        'contas_iniciadas': _contas_entregues(ctx) - contas_no_inicio,
        # Blocos de detalhe só quando a variação os pede: as baselines que não os declaram não mudam de forma.
        **{k: v for d in detalhes for k, v in DETALHES[d](ctx).items()},
    }


def _situacoes(ctx):
    return ctx.sql("select string_agg(proi_id::text || ':' || prst_id::text, ',' order by proi_id) from batch.processo_iniciado"
                   " union all select string_agg(fuin_id::text || ':' || fnst_id::text, ',' order by fuin_id) from batch.funcionalidade_iniciada"
                   " union all select string_agg(undi_id::text || ':' || unst_id::text, ',' order by undi_id) from batch.unidade_iniciada")


def _aguardar(ctx, ate):
    """`terminal`: todo processo iniciado num estado terminal e nada mudando por 15 s. `ciclo`: 75 s — ao menos uma
    passagem do verificador (a cada minuto) — para ver o que ele faz com um processo que não deve rodar."""
    inicio = time.monotonic()
    if ate == 'ciclo':
        time.sleep(75)
        return {'ate': ate}
    while time.monotonic() - inicio < ESPERA_MAXIMA:
        situacoes = [int(s) for s in (ctx.sql('select prst_id from batch.processo_iniciado') or '').split()]
        if situacoes and all(s in PROCESSO_TERMINAL for s in situacoes):
            antes = _situacoes(ctx)
            time.sleep(15)
            if _situacoes(ctx) == antes:
                return {'ate': ate}
        time.sleep(5)
    raise TimeoutError(f'o processo não chegou a um estado terminal em {ESPERA_MAXIMA} s')


def _ultimo_processo(ctx):
    return int(ctx.sql('select max(proi_id) from batch.processo_iniciado'))


# --- Manutenção de conta: retificar, cancelar (lote 5d) ---------------------------------------------
# Sobre as contas que o faturamento em grupo acabou de gerar (ou as que a massa traz): o usuário escolhe a conta da
# referência na lista de Manter Conta; o id só serve à navegação e nunca sai no resultado (nem a marca de tempo que a
# lista põe na caixa de seleção). Mensagens de erro saem pelas chaves de mensagem do legado, sem pilha.

def _conta_alvo(ctx, imovel, referencia, situacoes):
    """A conta da referência que a variação manipula: a mais recente entre as situações pedidas."""
    return ctx.sql(f"select max(cnta_id) from faturamento.conta where imov_id = {int(imovel)}"
                   f" and cnta_amreferenciaconta = {int(referencia)}"
                   f" and dcst_idatual in ({', '.join(str(int(s)) for s in situacoes)})") or None


def _confirmacao(html):
    """Página de confirmação do legado: o texto e as URLs dos botões Sim (confirmado=ok) e Não (confirmado=cancelar)."""
    botoes = {m.group(2): m.group(1) for m in
              re.finditer(r"botaoAvancarTelaEspera\('/gsan/([^']*?confirmado=(ok|cancelar)[^']*)'\)", html)}
    if not botoes:
        return None, {}
    m = re.search(r'Confirma..o\s+(.*?)\s+GSAN -', texto_visivel(html))
    return (m.group(1).strip() if m else ''), botoes


def _recusa(html, estado):
    """Mensagem de recusa ou de erro: o texto exibido (sem pilha) e as chaves de mensagem do legado que a página traz."""
    chaves = sorted({k for k in re.findall(r'\b(?:atencao|erro)\.[a-z0-9_.]*[a-z0-9_]', html)
                     if not re.search(r'\.(?:gif|png|jpe?g)$', k)})  # os ícones atencao.gif/erro.gif não são mensagens
    texto = _mensagem(html) or (_atencao(html) if estado >= 400 or chaves else None)
    if not texto and chaves:  # página de erro: o que ela exibe antes do link para o log (às vezes a chave sem texto)
        m = re.search(r'Erro\s+(.*?)\s+Visualizar Log', texto_visivel(html))
        texto = m.group(1) if m else None
    return {'mensagem': texto, 'chaves': chaves}


def _manter_conta(ctx, imovel, conta):
    """Manter Conta do imóvel: a lista de onde a conta é escolhida (e a coleção que o cancelamento usa na sessão)."""
    html = ctx.atual.get(f'exibirManterContaAction.do?idImovel={int(imovel)}')
    marca = re.search(r'(?i)NAME="conta"\s*value="(' + str(conta) + r'-\d*)"', html) if conta else None
    r = {'http': ctx.atual.ultimo_estado, 'conta_listada': bool(marca)}
    if not marca:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r, (marca.group(1) if marca else None)


def _retificar(ctx, passo):
    """Retificar Conta (ExibirRetificarContaAction → RetificarContaAction → ControladorRetificarConta.retificarConta):
    o que a tela mostrou, as confirmações que o legado pediu e a resposta da variação, e o resultado."""
    r = {}
    conta = _conta_alvo(ctx, passo['imovel'], passo['referencia'], passo.get('situacoes', (0, 1, 2)))
    r['manter_conta'], _ = _manter_conta(ctx, passo['imovel'], conta)
    if not conta:
        r['resultado'] = 'sem_conta'
        return r
    html = ctx.atual.get(f'exibirRetificarContaAction.do?contaID={conta}&idImovel={int(passo["imovel"])}')
    tela = {'http': ctx.atual.ultimo_estado}
    texto, botoes = _confirmacao(html)
    if texto is not None:  # conta paga: o legado pede confirmação antes de abrir a tela
        tela.update(confirmacao=texto, resposta=passo.get('conta_paga'))
        if passo.get('conta_paga') not in botoes:
            r.update(tela=tela, resultado='nao_confirmado')
            return r
        html = ctx.atual.get(botoes[passo['conta_paga']])
        tela['http_apos_confirmacao'] = ctx.atual.ultimo_estado
    dados = _formulario(html, 'RetificarContaActionForm')
    if not dados.get('idImovel'):
        tela.update(_recusa(html, ctx.atual.ultimo_estado))
        r.update(tela=tela, resultado='recusado_na_exibicao')
        return r
    tela.update(referencia=dados.get('mesAnoConta'), consumo_agua=dados.get('consumoAgua'),
                valor_agua=moeda(dados.get('valorAgua') or ''), valor_total=moeda(dados.get('valorTotal') or ''),
                vencimento=dados.get('vencimentoConta'),
                economias={c: v for c, v in re.findall(r'(?i)NAME="categoria(\d+)"[^>]*value="([^"]*)"', html)})
    r['tela'] = tela
    # O que a variação digita: o motivo, as economias por categoria e/ou o consumo de água.
    dados['motivoRetificacaoID'] = str(int(passo['motivo']))
    for categoria, quantidade in passo.get('economias', {}).items():
        dados[f'categoria{int(categoria)}'] = str(int(quantidade))
    if 'consumo_agua' in passo:
        dados['consumoAgua'] = str(int(passo['consumo_agua']))
    html = ctx.atual.post('retificarContaAction.do', dados)
    texto, botoes = _confirmacao(html)
    if texto is not None:  # consumo alterado: "substituir o consumo para o cálculo da média?"
        r.update(confirmacao=texto, resposta=passo.get('substituir_media'))
        if passo.get('substituir_media') not in botoes:
            r['resultado'] = 'nao_confirmado'
            return r
        html = ctx.atual.post(botoes[passo['substituir_media']], {})
    sucesso = 'retificada com sucesso' in texto_visivel(html)
    r.update(http=ctx.atual.ultimo_estado, resultado='retificada' if sucesso else 'recusada')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _cancelar(ctx, passo):
    """Cancelar Conta a partir de Manter Conta (ExibirCancelarContaAction → CancelarContaAction →
    ControladorFaturamentoFINAL.cancelarConta). A tela não diz "sucesso": volta ao formulário; o efeito é lido do banco.
    `forjar`: se a tela recusa, o POST de cancelamento é enviado mesmo assim (o servidor aceita ou não)."""
    r = {}
    conta = _conta_alvo(ctx, passo['imovel'], passo['referencia'], passo.get('situacoes', (0, 1, 2)))
    r['manter_conta'], marca = _manter_conta(ctx, passo['imovel'], conta)
    if not marca:
        r['resultado'] = 'conta_nao_listada'
        return r
    html = ctx.atual.get(f'exibirCancelarContaAction.do?conta={marca}&idImovel={int(passo["imovel"])}')
    dados = _formulario(html, 'CancelarContaActionForm')
    tela = {'http': ctx.atual.ultimo_estado,
            'motivos': re.findall(r'(?is)<option\b[^>]*value="(\d+)"', html)}
    if 'contaSelected' not in dados:
        tela.update(_recusa(html, ctx.atual.ultimo_estado))
        if not passo.get('forjar'):
            r.update(tela=tela, resultado='recusado_na_exibicao')
            return r
        r['forjado'] = True  # o que a tela não deixaria enviar
        dados = {'contaSelected': marca, 'contasEmExtratoDebito': ''}
    r['tela'] = tela
    dados.update(contaSelected=marca, motivoCancelamentoContaID=str(int(passo['motivo'])))
    html = ctx.atual.post('cancelarContaAction.do', dados)
    texto, botoes = _confirmacao(html)
    if texto is not None:  # conta paga
        r.update(confirmacao=texto, resposta=passo.get('conta_paga'))
        if passo.get('conta_paga') not in botoes:
            r['resultado'] = 'nao_confirmado'
            return r
        html = ctx.atual.post(botoes[passo['conta_paga']], {})
    recusa = _recusa(html, ctx.atual.ultimo_estado)
    aceito = ctx.atual.ultimo_estado < 400 and not recusa['chaves'] and 'CancelarContaActionForm' in html
    r.update(http=ctx.atual.ultimo_estado, resultado='aceito' if aceito else 'recusado')
    if not aceito:
        r.update(recusa)
    return r


def _iniciar_processo(ctx, passo):
    """Inserir Processo de tipo mensal/eventual (InserirProcessoAction → InserirProcessoMensalEventualAction →
    ControladorBatchSEJB.inserirProcessoIniciado): o verificador do Quartz o executa no minuto seguinte."""
    ctx.atual.get('exibirInserirProcessoAction.do?menu=sim')
    ctx.atual.post('inserirProcessoAction.do', {'idProcessoTipo': str(int(passo['tipo_processo']))})
    html = ctx.atual.post('exibirInserirProcessoMensalEventualAction.do', {'idProcesso': str(int(passo['processo']))})
    dados = _formulario(html, 'InserirProcessoMensalEventualActionForm')
    r = {'tela': {'http': ctx.atual.ultimo_estado, 'processo': dados.get('descricaoProcesso') or None}}
    dados['idProcesso'] = str(int(passo['processo']))
    html = ctx.atual.post('inserirProcessoMensalEventualAction.do', dados)
    sucesso = 'inserido com sucesso' in texto_visivel(html)
    r.update(http=ctx.atual.ultimo_estado, resultado='inserido' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def faturar_grupo(ctx, entrada):
    """Faturar grupo pelo processo comandado (ExibirInserirProcessoFaturamentoComandadoAction →
    InserirProcessoFaturamentoComandadoAction → ControladorBatchSEJB.inserirProcessoIniciadoFaturamentoComandado →
    verificador do Quartz → MDB por rota → ControladorFaturamentoFINAL.faturarGrupoFaturamento), com os passos da variação:
    disparar · aguardar (terminal | ciclo) · observar · autorizar · aplicar (arquivo de massas/passos: a correção de causa
    do lote 5, o pagamento do lote 5d) · reiniciar · retificar · cancelar (manutenção de conta pela tela) ·
    iniciar_processo (processo mensal/eventual, ex.: a prescrição).
    `detalhes` (opcional): blocos a mais no estado — `lancamentos` (débitos e créditos), `impostos`, `rateio`,
    `micromedicao` (medições e consumos detalhados) e `ciclo_conta` (contas pela identidade documental, pagamentos, RA,
    consumos e auditoria)."""
    login = entrada['usuario']
    comando = str(int(entrada['comando']))
    ctx.nova_sessao()
    ctx.atual.tentar_login(login, ctx.senha(login, 'correta'))
    contas_no_inicio = _contas_entregues(ctx)
    detalhes = entrada.get('detalhes', [])
    passos = []
    for passo in entrada['passos']:
        tipo, r = passo['tipo'], {'tipo': passo['tipo']}
        if tipo == 'disparar':
            html = ctx.atual.get('exibirInserirProcessoFaturamentoComandadoAction.do?menu=sim')
            listado = any(re.search(r'(?i)\bvalue="' + comando + r'"', t)
                          for t in re.findall(r'(?is)<input\b[^>]*name="idFaturamentoAtividadeCronograma"[^>]*>', html))
            r['tela'] = {'http': ctx.atual.ultimo_estado, 'comando_listado': listado,
                         'mensagem': None if listado else (_mensagem(html) or _atencao(html))}
            if listado or passo.get('forjar'):
                # Sem o comando na tela, o POST é o que a tela não deixaria enviar: o servidor aceita ou não.
                r['forjado'] = not listado
                html = ctx.atual.post('inserirProcessoFaturamentoComandadoAction.do', {'idFaturamentoAtividadeCronograma': comando})
                sucesso = 'inserido(s) com sucesso' in texto_visivel(html)
                r.update(http=ctx.atual.ultimo_estado, resultado='inserido' if sucesso else 'recusado',
                         mensagem=None if sucesso else (_mensagem(html) or _atencao(html)))
            else:
                r['resultado'] = 'nao_enviado'
        elif tipo == 'aguardar':
            r.update(_aguardar(ctx, passo.get('ate', 'terminal')))
        elif tipo == 'observar':
            r['estado'] = _estado_faturamento(ctx, contas_no_inicio, detalhes, comando)
        elif tipo == 'autorizar':
            proi = _ultimo_processo(ctx)
            html = ctx.atual.get('exibirAutorizarRelatoriosBatchAction.do?menu=sim')
            listado = any(re.search(r'(?i)\bvalue="' + str(proi) + r'"', t)
                          for t in re.findall(r'(?is)<input\b[^>]*name="idRegistrosAutorizar"[^>]*>', html))
            r['tela'] = {'http': ctx.atual.ultimo_estado, 'processo_listado': listado}
            html = ctx.atual.post('autorizarProcessoIniciadoAction.do', {'idRegistrosAutorizar': str(proi)})
            sucesso = 'autorizado(s) com sucesso' in texto_visivel(html)
            r.update(http=ctx.atual.ultimo_estado, resultado='autorizado' if sucesso else 'recusado',
                     mensagem=None if sucesso else (_mensagem(html) or _atencao(html)))
        elif tipo == 'aplicar':
            caminho = '/referencia/baselines/' + passo['arquivo']
            with open(caminho, 'rb') as f:
                conteudo = f.read()
            ctx.sql(conteudo.decode('utf-8'))
            r.update(arquivo=passo['arquivo'], sha256=hashlib.sha256(conteudo).hexdigest())
        elif tipo == 'retificar':
            r.update(_retificar(ctx, passo))
        elif tipo == 'cancelar':
            r.update(_cancelar(ctx, passo))
        elif tipo == 'iniciar_processo':
            r.update(_iniciar_processo(ctx, passo))
        elif tipo == 'reiniciar':
            proi = _ultimo_processo(ctx)
            # Etapas a reiniciar: as CONCLUIDA COM ERRO (4, padrão) ou as CONCLUIDA (2) — FuncionalidadeSituacao.
            situacao = {'com_erro': 4, 'concluidas': 2}[passo.get('etapas', 'com_erro')]
            r['etapas'] = passo.get('etapas', 'com_erro')
            com_erro = ctx.sql(f'select fuin_id from batch.funcionalidade_iniciada where proi_id = {proi}'
                               f' and fnst_id = {situacao} order by fuin_id').split()
            html = ctx.atual.get(f'exibirConsultarDadosProcessoIniciadoAction.do?idRegistroAtualizacao={proi}')
            r['tela'] = {'http': ctx.atual.ultimo_estado,
                         'etapas_listadas_para_reinicio': sum(1 for f in com_erro if re.search(
                             r'(?is)<input\b[^>]*name="idRegistrosRemocao"[^>]*value="' + f + r'"', html))}
            # A tela marca uma etapa por vez (caixa idRegistrosRemocao); a etapa de faturar é a única do processo.
            if len(com_erro) != 1:
                raise RuntimeError(f'esperada uma etapa para reiniciar ({r["etapas"]}), há {len(com_erro)}')
            html = ctx.atual.post('reiniciarFuncionalidadeIniciadaAction.do', {'idRegistrosRemocao': com_erro[0]})
            r.update(etapas_reiniciadas=len(com_erro), http=ctx.atual.ultimo_estado,
                     mensagem=_mensagem(html) or (_atencao(html) if ctx.atual.ultimo_estado >= 400 else None))
        else:
            raise ValueError(f'passo desconhecido: {tipo}')
        passos.append(r)
    final = _estado_faturamento(ctx, contas_no_inicio, detalhes, comando)
    # Só evidência (nenhum cenário projeta): as linhas de exceção e de código do legado nas exceções persistidas.
    texto = ctx.sql("select coalesce(string_agg(substr(fuin_dserro, 1, 6000), chr(10)), '')"
                    " from batch.funcionalidade_iniciada where fuin_dserro is not null")
    erros = [l.strip() for l in texto.splitlines() if 'Exception' in l or 'Caused' in l or 'at gcom.' in l][:60]
    return {'passos': passos, **final, 'erros_tecnicos': erros}


# --- Segurança: autenticação e autorização -------------------------------------------------------
# Roteiro por PASSOS, declarados na variação: a mesma fronteira (login + filtro de acesso) serve a vários
# cenários só mudando os passos e a massa. Nenhuma senha, hash ou identificador de sessão vai para o
# resultado — só o que o legado decidiu.

class Contexto:
    """O que um roteiro de Segurança recebe do executor. As senhas (efêmeras, por execução) ficam só aqui."""

    def __init__(self, base, senhas, sql):
        self.base = base
        self._senhas = dict(senhas)
        self._novas = {}
        self._marcas = {}  # credencial gravada antes da operação: só para comparar, nunca sai daqui
        self.sql = sql
        self.sessoes = []
        self.atual = None

    def nova_sessao(self, carregar=True):
        self.atual = Sessao(self.base)
        self.sessoes.append(self.atual)
        if carregar:
            self.atual.get('carregarParametrosAction.do')
        return self.atual

    def senha(self, login, tipo):
        if tipo == 'correta':
            return self._senhas[login]
        if tipo == 'errada':  # nunca igual à correta
            return 'x' + secrets.token_urlsafe(12)
        return self._novas.setdefault(tipo, secrets.token_urlsafe(18))  # rótulo de senha nova

    def trocou(self, login, tipo):
        self._senhas[login] = self._novas[tipo]

    def respostas(self):
        return [r for s in self.sessoes for r in s.respostas]


LOGIN_VALIDO = re.compile(r'[a-z0-9.]{1,11}')


def _mensagem(html):
    """Mensagem de erro/atenção exibida pelo legado, sem pilha de exceção nem rodapé."""
    m = re.search(r'(?is)<font color="red">(.*?)</font>', html)
    if m and texto_visivel(m.group(1)):
        return texto_visivel(m.group(1))
    t = texto_visivel(html)
    m = re.search(r'Mensagem\s*:\s*(?:C.digo Erro\s*:\s*\d+\s*)?(.*?)(?:\s+With the following stack trace|$)', t)
    if 'Erro de Sistema' in t and m:
        return 'Erro de Sistema: ' + m.group(1)[:200].strip()
    m = re.search(r'Aten..o\s+(.*?)\s+(?:Voltar|GSAN -|Banco:)', t)
    return m.group(1).strip() if m else None


def _atencao(html):
    """Mensagem da página de "Atenção" sem rodapé (quando _mensagem não a reconhece)."""
    m = re.search(r'Aten..o\s+(.{1,300}?)\s*$', texto_visivel(html))
    return m.group(1).strip() if m else None


def _decisao(sessao, html):
    t = texto_visivel(html)
    if sessao.ultimo_estado >= 400:
        return 'erro_http'
    if 'Acesso a funcionalidade negado' in t:
        return 'negado_funcionalidade'
    if 'negado devido a abrang' in t:
        return 'negado_abrangencia'
    if 'Acesso a opera' in t and 'negado' in t:
        return 'negado_operacao'
    if 'efetuarLogoffAction' in html:
        return 'permitido'
    if 'efetuarLoginAction' in html:
        return 'tela_login'
    return 'permitido'


def _texto_util(sessao, html):
    """Texto de onde procurar dado retornado — inclusive dentro de relatório entregue em ZIP."""
    tipo = (sessao.cabecalhos.get('Content-Type') or '').lower() if sessao.cabecalhos else ''
    if 'zip' in tipo:
        z = zipfile.ZipFile(io.BytesIO(html.encode('iso-8859-1')))
        partes = [z.read(n).decode('utf-8', errors='replace') for n in z.namelist() if n.endswith('.html')]
        return 'zip', ' '.join(texto_visivel(p) for p in partes)
    return 'html', texto_visivel(html)


def _menu(html):
    """Folhas do menu (árvore d.add(id, pai, 'nome', 'url')) como caminhos 'Grupo > ... > Item'."""
    nos = {}
    for id_, pai, nome, url in re.findall(r"add\((\d+),(-?\d+),'([^']*)'(?:,'([^']*)')?", html):
        nos[id_] = (pai, nome, url)
    folhas = []
    for id_, (pai, nome, url) in nos.items():
        if url and url != '#':
            caminho, p = [nome], pai
            while p in nos and nos[p][0] != '-1':
                caminho.insert(0, nos[p][1])
                p = nos[p][0]
            folhas.append(' > '.join(caminho))
    return sorted(folhas)


CARIMBO = re.compile(r'\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}')


def _auditoria(ctx):
    """Registro de operação e trilha por linha/coluna gravados pelo legado (Interceptador/RegistradorOperacao).

    Os identificadores sequenciais dos registros de auditoria não saem: a correlação vira a posição na ordem de
    gravação. Identificadores de usuário são da massa e saem com o login. O IP do cliente (rede do laboratório)
    sai só como "preenchido". Valor de senha nunca sai, mesmo que um dia apareça na trilha."""
    def consulta(q):
        return json.loads(ctx.sql(f"select coalesce(json_agg(x), '[]') from ({q}) x") or '[]')

    def login(id_):
        if id_ in (None, ''):
            return None
        v = ctx.sql(f"select usur_nmlogin from seguranca.usuario where usur_id::text = '{int(id_)}'")
        return v or None

    ops = consulta("select o.opef_id, p.oper_id, p.oper_dsoperacao, o.opef_cnargumento, o.opef_dsdadosadicionais,"
                   " o.opef_tmultimaalteracao is not null as momento, o.atgr_id from seguranca.operacao_efetuada o"
                   " join seguranca.operacao p using (oper_id) order by o.opef_id")
    pos_op = {o['opef_id']: i + 1 for i, o in enumerate(ops)}
    autores = consulta("select a.tref_id, a.usis_id, c.usac_dsusuarioacao, a.empr_id, a.usac_nnip is not null as ip,"
                       " a.usat_tmultimaalteracao is not null as momento from seguranca.usuario_alteracao a"
                       " join seguranca.usuario_acao c using (usac_id) order by a.usat_id")
    linhas = consulta("select l.tbla_id, l.tref_id, t.tabe_nmtabela, k.altp_dsalteracaotipo, l.tbla_id1, l.tbla_id2,"
                      " l.tbla_icprincipal, l.tbla_tmultimaalteracao is not null as momento"
                      " from seguranca.tabela_linha_alteracao l join seguranca.tabela t using (tabe_id)"
                      " join seguranca.alteracao_tipo k using (altp_id) order by l.tbla_id")
    pos_linha = {l['tbla_id']: i + 1 for i, l in enumerate(linhas)}
    colunas = consulta("select c.tbla_id, k.tbco_nmcoluna, c.tbca_cncolunaanterior, c.tbca_cncolunaatual,"
                       " c.tbca_icatualizada from seguranca.tab_linha_col_alteracao c"
                       " join seguranca.tabela_coluna k using (tbco_id) order by c.tbca_id")
    comuns, carimbos = [], []
    for c in colunas:
        item = {'linha': pos_linha.get(c['tbla_id']), 'coluna': c['tbco_nmcoluna'],
                'anterior': c['tbca_cncolunaanterior'], 'atual': c['tbca_cncolunaatual'],
                'atualizada': c['tbca_icatualizada']}
        if c['tbco_nmcoluna'] == 'usur_nmsenha':
            item['anterior'] = item['atual'] = '<valor de senha omitido>'
        (carimbos if CARIMBO.fullmatch(c['tbca_cncolunaatual'] or '') else comuns).append(item)
    return {
        'operacoes': [{'operacao': o['oper_id'], 'descricao': o['oper_dsoperacao'], 'argumento': o['opef_cnargumento'],
                       'argumento_login': login(o['opef_cnargumento']), 'dados_adicionais': o['opef_dsdadosadicionais'],
                       'atributo_grupo': o['atgr_id'], 'momento_preenchido': o['momento']} for o in ops],
        'autores': [{'operacao': pos_op.get(a['tref_id']), 'usuario': login(a['usis_id']),
                     'acao': a['usac_dsusuarioacao'], 'empresa': a['empr_id'], 'ip_preenchido': a['ip'],
                     'momento_preenchido': a['momento']} for a in autores],
        'linhas': [{'operacao': pos_op.get(l['tref_id']), 'tabela': l['tabe_nmtabela'], 'tipo': l['altp_dsalteracaotipo'],
                    'id1': l['tbla_id1'], 'id1_login': login(l['tbla_id1']) if l['tabe_nmtabela'] == 'seguranca.usuario'
                    else None, 'id2': l['tbla_id2'], 'principal': l['tbla_icprincipal'],
                    'momento_preenchido': l['momento']} for l in linhas],
        'colunas': comuns,
        'carimbos': carimbos,
        'coluna_senha_na_trilha': any(c['tbco_nmcoluna'] == 'usur_nmsenha' for c in colunas),
    }


def seguranca(ctx, entrada):
    resultados = []
    for passo in entrada['passos']:
        tipo = passo['passo']
        r = {'passo': tipo}
        login = passo.get('usuario')
        if login is not None and not LOGIN_VALIDO.fullmatch(login):
            raise ValueError(f'login inválido no cenário: {login!r}')
        if tipo == 'sessao':
            ctx.nova_sessao(passo.get('carregar', True))
            r['carregar'] = passo.get('carregar', True)
        elif tipo == 'login':
            html = ctx.atual.tentar_login(login, ctx.senha(login, passo['senha']))
            r.update(usuario=login, senha=passo['senha'], http=ctx.atual.ultimo_estado,
                     # a troca de senha imposta vem DENTRO do leiaute (com o link de logoff): testada antes
                     resultado=('erro_http' if ctx.atual.ultimo_estado >= 400 else
                                'alterar_senha' if 'novaSenha' in html else
                                'tela_principal' if 'efetuarLogoffAction' in html else
                                'tela_login' if 'efetuarLoginAction' in html else 'outra'),
                     mensagem=_mensagem(html) or (_atencao(html) if ctx.atual.ultimo_estado >= 400 else None))
        elif tipo == 'contexto':
            html = ctx.atual.get('telaPrincipal.do')
            t = texto_visivel(html)
            usuario = re.search(r'Usu.rio:\s*(\S+)', t)
            grupos = re.search(r'Grupo:\s*(.*?)\s*N.\s*Acesso', t)
            autenticado = 'efetuarLogoffAction' in html
            r.update(http=ctx.atual.ultimo_estado, autenticado=autenticado,
                     usuario_exibido=usuario.group(1) if autenticado and usuario else None,
                     grupos_exibidos=grupos.group(1) if autenticado and grupos else None,
                     menu=_menu(html) if autenticado else [])
        elif tipo == 'situacao':
            r.update(usuario=login, situacao=ctx.sql(
                "select s.usst_dsusuariosituacao from seguranca.usuario u join seguranca.usuario_situacao s "
                f"on s.usst_id = u.usst_id where u.usur_nmlogin = '{login}'"))
        elif tipo == 'contadores':
            linha = ctx.sql("select coalesce(usur_nnacessos::text, 'nulo') || '|' || (usur_tmultimoacesso is not null)::text"
                            f" || '|' || coalesce(usur_nnbloqueioacesso::text, 'nulo') from seguranca.usuario"
                            f" where usur_nmlogin = '{login}'").split('|')
            r.update(usuario=login, acessos=linha[0], ultimo_acesso_preenchido=linha[1] == 'true',
                     bloqueios=linha[2])
        elif tipo == 'acessar':
            if passo.get('dados') is not None:
                html = ctx.atual.post(passo['url'], passo['dados'])
            else:
                html = ctx.atual.get(passo['url'])
            origem, texto = _texto_util(ctx.atual, html)
            r.update(rotulo=passo['rotulo'], http=ctx.atual.ultimo_estado, decisao=_decisao(ctx.atual, html),
                     conteudo=origem)
            if 'marca' in passo:
                r['recurso_executado'] = passo['marca'] in (html if origem == 'html' else texto)
            if 'procurar' in passo:
                r['dados_encontrados'] = [d for d in passo['procurar'] if d in texto]
            if r['decisao'] == 'erro_http':
                # Exceção de negócio não tratada (ActionServletException): o legado devolve a página de "Atenção"
                # com HTTP 500 — a mensagem é o que ele decidiu.
                r['mensagem'] = _mensagem(html) or _atencao(html)
            r['set_cookie_sessao'] = any('JSESSIONID' in c for c in ctx.atual.respostas[-1].get('set_cookie', []))
        elif tipo == 'trocar_senha':
            ctx.atual.get('exibirEfetuarAlteracaoSenhaSimplificadaAction.do')
            if 'nova_literal' in passo:  # valor de teste declarado no cenário — nunca uma credencial real
                passo = dict(passo, nova='literal:' + passo['nova_literal'])
                ctx._novas[passo['nova']] = passo['nova_literal']
            nova = ctx.senha(login, passo['nova'])
            html = ctx.atual.post('efetuarAlteracaoSenhaSimplificadaAction.do', {
                'senha': ctx.senha(login, 'correta'), 'novaSenha': nova, 'confirmacaoNovaSenha': nova,
                'lembreteSenha': passo.get('lembrete', 'LEMBRETE SINTETICO')}, registrar_corpo=False)
            sucesso = 'Senha alterada com sucesso' in texto_visivel(html)
            if sucesso:
                ctx.trocou(login, passo['nova'])
            r.update(usuario=login, http=ctx.atual.ultimo_estado, sucesso=sucesso,
                     mensagem=None if sucesso else _mensagem(html) or _atencao(html))
        elif tipo == 'credenciais':
            valores = [ctx.sql(f"select coalesce(usur_nmsenha, '') from seguranca.usuario where usur_nmlogin = '{u}'")
                       for u in passo['usuarios']]
            formatos = []
            for v in valores:  # só a forma; o valor nunca sai daqui
                try:
                    formatos.append(f'base64 de {len(base64.b64decode(v, validate=True))} bytes')
                except Exception:
                    formatos.append('outro')
            r.update(usuarios=passo['usuarios'], valores_iguais=len(set(valores)) == 1, formatos=formatos)
            del valores
        elif tipo == 'redefinir_senha':
            # Operação 818 (EfetuarAlteracaoSenhaPorMatriculaAction): o usuário da sessão redefine a senha de
            # OUTRO login. O valor gravado é fixo no código do legado e não é observado aqui.
            alvo = passo['alvo']
            if not LOGIN_VALIDO.fullmatch(alvo):
                raise ValueError(f'login inválido no cenário: {alvo!r}')
            html = ctx.atual.get('exibirEfetuarAlteracaoSenhaPorMatriculaAction.do?limparForm=ok')
            decisao_entrada = _decisao(ctx.atual, html)
            html = ctx.atual.post('efetuarAlteracaoSenhaPorMatriculaAction.do', {'login': alvo})
            t = texto_visivel(html)
            sucesso = 'gerada com sucesso' in t
            r.update(alvo=alvo, entrada=decisao_entrada, http=ctx.atual.ultimo_estado, decisao=_decisao(ctx.atual, html),
                     sucesso=sucesso, mensagem=_mensagem(html) if not sucesso else
                     re.search(r'Senha padr.o para o login: \S+ gerada com sucesso\.', t).group(0))
        elif tipo == 'guardar_credencial':
            for u in passo['usuarios']:
                ctx._marcas[u] = ctx.sql(f"select coalesce(usur_nmsenha, '') from seguranca.usuario where usur_nmlogin = '{u}'")
            r.update(usuarios=passo['usuarios'])
        elif tipo == 'credencial_alterada':
            r.update(alterada={u: ctx.sql(f"select coalesce(usur_nmsenha, '') from seguranca.usuario"
                                          f" where usur_nmlogin = '{u}'") != ctx._marcas[u] for u in passo['usuarios']})
        elif tipo == 'datas':
            # Datas de acesso relativas ao dia da execução (dias a partir de hoje; nulo = não definida).
            linha = ctx.sql("select coalesce((usur_dtexpiracaoacesso - current_date)::text, 'nulo') || '|' ||"
                            " coalesce((usur_dtprazomsgexpiracao - current_date)::text, 'nulo') from seguranca.usuario"
                            f" where usur_nmlogin = '{login}'").split('|')
            r.update(usuario=login, expiracao_acesso_dias=None if linha[0] == 'nulo' else int(linha[0]),
                     prazo_aviso_dias=None if linha[1] == 'nulo' else int(linha[1]))
        elif tipo == 'historico':
            r.update(usuario=login, senhas_no_historico=int(ctx.sql(
                "select count(*) from seguranca.usuario_senha_historico h join seguranca.usuario u using (usur_id)"
                f" where u.usur_nmlogin = '{login}'")))
        elif tipo == 'auditoria':
            r.update(_auditoria(ctx))
        elif tipo == 'cookie':
            cookies = [c for c in (ctx.atual.respostas[0].get('set_cookie', []) if ctx.atual.respostas else [])
                       if c.startswith('JSESSIONID=')]
            atributos = [a.strip().split('=')[0].lower() for a in (cookies[0].split(';')[1:] if cookies else [])]
            r.update(emitido=bool(cookies), httponly='httponly' in atributos, secure='secure' in atributos,
                     samesite='samesite' in atributos, path=next((a.strip()[5:] for a in cookies[0].split(';')
                                                                  if a.strip().lower().startswith('path=')), None)
                     if cookies else None)
        else:
            raise ValueError(f'passo desconhecido: {tipo}')
        resultados.append(r)
    return {'passos': resultados}


ROTEIROS = {
    'simular_calculo_conta': simular_calculo_conta,
    'consultar_imovel_dados_cadastrais': consultar_imovel_dados_cadastrais,
    'consultar_imoveis_matricula': consultar_imoveis_matricula,
    'consultar_relacao_cliente_imovel': consultar_relacao_cliente_imovel,
    'seguranca': seguranca,
    'efetuar_ligacao_agua': efetuar_ligacao_agua,
    'consultar_consumo_minimo_ligacao_agua': consultar_consumo_minimo_ligacao_agua,
    'faturar_grupo': faturar_grupo,
}
