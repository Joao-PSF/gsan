"""Roteiros: a operação do GSAN executada por um cenário, pelas telas do próprio legado.

Um roteiro recebe a sessão autenticada e a entrada da variação e devolve o que a operação mostrou,
já extraído do HTML (dinheiro como texto decimal exato). Não escreve no banco por conta própria: o
estado só muda pelo que a operação do GSAN fizer.
"""
import base64
import datetime
import hashlib
import io
import json
import re
import secrets
import time
import zipfile
from decimal import Decimal

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
                                         " order by c.imov_id, c.cnta_amreferenciaconta, d.dbtp_id, d.dbcb_nnprestacaodebito, d.dbcb_nnprestacao, d.dbcb_vlprestacao"),
        'creditos_realizados': _linhas(ctx, "select c.imov_id as matricula, c.cnta_amreferenciaconta as referencia_conta,"
                                            " t.crti_dscreditotipo as tipo, o.crog_dscreditoorigem as origem,"
                                            " r.crrz_nnprestacaocredito as prestacao, r.crrz_nnprestacao as prestacoes,"
                                            " r.crrz_vlcredito::text as valor"
                                            " from faturamento.credito_realizado r join faturamento.conta c using (cnta_id)"
                                            " left join faturamento.credito_tipo t using (crti_id)"
                                            " join faturamento.credito_origem o using (crog_id)"
                                            " order by c.imov_id, c.cnta_amreferenciaconta, r.crti_id, r.crrz_nnprestacaocredito, r.crrz_nnprestacao, r.crrz_vlcredito"),
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
        'medicoes': _linhas(ctx, "select coalesce(m.lagu_id, m.imov_id) as matricula, m.mdhi_amleitura as referencia, t.medt_dsmedicaotipo as medicao,"
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


def _data_do_dia(coluna):
    """Como `_data_relativa`, e também as datas POSTERIORES à execução, que só o relógio do legado produz (o vencimento
    "hoje + 3 dias" da conta tomada como entrada do parcelamento, lote 7b): 'data da execução + N dias'. As da massa são
    todas anteriores e saem como estão."""
    return (f"case when {coluna} is null then null when {coluna}::date = current_date then 'data da execução'"
            f" when {coluna}::date > current_date then 'data da execução + ' || ({coluna}::date - current_date)::text || ' dias'"
            f" else to_char({coluna}, 'DD/MM/YYYY') end")


def _hoje(ctx):
    return datetime.date.fromisoformat(ctx.sql("select current_date::text").strip())  # o dia do relógio do legado


def _mes_do_dia(valor, hoje):
    """Uma referência (AAAAMM) que o legado tira do relógio — a do mês corrente ou posterior (a referência contábil da
    conta parcelada ou refaturada, a do parcelamento: lotes 6b e 7b) — sai relativa ao mês da execução; as da massa são
    todas anteriores e saem como estão (inteiras)."""
    if not isinstance(valor, int) or not hoje:
        return valor
    n = (valor // 100 - hoje.year) * 12 + (valor % 100 - hoje.month)
    return valor if n < 0 else 'mês da execução' + (f' + {n} meses' if n > 1 else ' + 1 mês' if n == 1 else '')


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


def _conta_origem(ctx):
    """Consumo pela origem, na conta (lote 5e): o que a conta fotografou do consumo — leituras, volumes, percentuais de
    esgoto e coleta, volume de poço, situações das ligações, rota — e o consumo da referência processada, por ligação, com
    tipo, anormalidade, indicador de faturamento, rota e situação especial de faturamento — só o que a execução gravou (o
    histórico da massa fica de fora)."""
    return {
        'contas_origem': _linhas(ctx, "select c.imov_id as matricula, c.cnta_amreferenciaconta as referencia,"
                                      " s.dcst_dsdebitocreditosituacao as situacao,"
                                      " c.cnta_nnleituraanterior as leitura_anterior, c.cnta_nnleituraatual as leitura_atual,"
                                      " c.cnta_nnconsumoagua as consumo_agua, c.cnta_nnconsumoesgoto as consumo_esgoto,"
                                      " c.cnta_pcesgoto::text as percentual_esgoto, c.cnta_pccoleta::text as percentual_coleta,"
                                      " c.cnta_nnvolumepoco as volume_poco, c.cnta_vlagua::text as valor_agua,"
                                      " c.cnta_vlesgoto::text as valor_esgoto,"
                                      " (c.cnta_vlagua + c.cnta_vlesgoto + c.cnta_vldebitos - c.cnta_vlcreditos"
                                      "  - coalesce(c.cnta_vlimpostos, 0))::text as valor_total,"
                                      " la.last_dsligacaoaguasituacao as situacao_agua, le.lest_dsligacaoesgotosituacao as situacao_esgoto,"
                                      " r.rota_cdrota as rota"
                                      " from faturamento.conta c join faturamento.debito_credito_situacao s on s.dcst_id = c.dcst_idatual"
                                      " left join atendimentopublico.ligacao_agua_situacao la on la.last_id = c.last_id"
                                      " left join atendimentopublico.ligacao_esgoto_situacao le on le.lest_id = c.lest_id"
                                      " left join micromedicao.rota r on r.rota_id = c.rota_id"
                                      " order by c.imov_id, c.cnta_amreferenciaconta, c.cnta_id"),
        'consumos_origem': _linhas(ctx, "select h.imov_id as matricula, h.cshi_amfaturamento as referencia, l.lgti_dsligacaotipo as ligacao,"
                                        " h.cshi_nnconsumofaturadomes as consumo_faturado, h.cshi_nnconsumocalculomedia as consumo_para_media,"
                                        " h.cshi_nnconsumomedio as consumo_medio, t.cstp_dsconsumotipo as tipo,"
                                        " a.csan_dsconsumoanormalidade as anormalidade, h.cshi_icfaturamento as indicador_faturamento,"
                                        " r.rota_cdrota as rota, f.ftst_dsfaturamentosituacaotipo as situacao_especial"
                                        " from micromedicao.consumo_historico h left join micromedicao.ligacao_tipo l using (lgti_id)"
                                        " left join micromedicao.consumo_tipo t using (cstp_id)"
                                        " left join micromedicao.consumo_anormalidade a using (csan_id)"
                                        " left join micromedicao.rota r on r.rota_id = h.rota_id"
                                        " left join faturamento.fatur_situacao_tipo f on f.ftst_id = h.ftst_id"
                                        " where h.cshi_tmultimaalteracao::date = current_date"
                                        " order by h.imov_id, h.cshi_amfaturamento, h.lgti_id"),
    }


def _arrecadacao(ctx):
    """Recepção e classificação (lote 6): cada movimento pelo NSA, com o cabeçalho e os totais do trailer; os itens na
    ordem do arquivo (registro original, ocorrência, aceitação, imóvel e documento); os pagamentos pela matrícula e
    referência, com valor, excedente, datas, referências, situações atual e anterior, a conta pela identidade documental e
    o item do movimento de origem; os avisos bancários (calculado × informado); as devoluções; o NSA do contrato. Ids
    técnicos nunca saem."""
    item = ("(select json_build_object('nsa', m.armv_nnnsa, 'ordem', (select count(*) from arrecadacao.arrecadador_mov_item k"
            " where k.armv_id = i.armv_id and k.amit_id <= i.amit_id)) from arrecadacao.arrecadador_mov_item i"
            " join arrecadacao.arrecadador_movimento m using (armv_id) where i.amit_id = {c})")
    aviso = "(select count(*) from arrecadacao.aviso_bancario k where k.avbc_id <= {c})"
    conta = ("case when {c} is null then null else coalesce((select " + IDENT_JSON.format(a='x') +
             " from ident x where x.cnta_id = {c}), json_build_object('conta_geral_sem_documento', true)) end")
    return {
        'movimentos': _linhas(ctx, "select m.armv_nnnsa as nsa, m.armv_cdremessa as remessa, m.armv_cdconvenio as convenio,"
                                   " m.armv_nmempresa as empresa, m.armv_cdbanco as banco, m.armv_nmbanco as nome_banco,"
                                   " to_char(m.armv_dtgeracao, 'DD/MM/YYYY') as data_geracao, m.armv_nnversaolayout as versao_layout,"
                                   " m.armv_dsidentificacaoservico as servico, m.armv_nnregistrosmovimento as registros,"
                                   " m.armv_vltotalmovimento::text as valor_total"
                                   " from arrecadacao.arrecadador_movimento m order by m.armv_id"),
        'itens': _linhas(ctx, IDENT +
                         "select m.armv_nnnsa as nsa, row_number() over (partition by i.armv_id order by i.amit_id) as ordem,"
                         " r.rgcd_cdregistrocodigo as codigo, i.amit_cnregistro as registro, i.amit_dsocorrencia as ocorrencia,"
                         " i.amit_icaceitacao as aceitacao, i.imov_id as matricula, i.amit_vldocumento::text as valor_documento,"
                         f" {conta.format(c='i.cnta_id')} as conta"
                         " from arrecadacao.arrecadador_mov_item i join arrecadacao.arrecadador_movimento m using (armv_id)"
                         " left join arrecadacao.registro_codigo r using (rgcd_id) order by i.armv_id, i.amit_id"),
        'pagamentos_arrecadacao': _linhas(ctx, IDENT +
                                          "select p.imov_id as matricula, p.pgmt_amreferenciapagamento as referencia_pagamento,"
                                          " p.pgmt_vlpagamento::text as valor, p.pgmt_vlexcedente::text as excedente,"
                                          " to_char(p.pgmt_dtpagamento, 'DD/MM/YYYY') as data_pagamento,"
                                          " p.pgmt_amreferenciaarrecadacao as referencia_arrecadacao,"
                                          " sa.pgst_dspagamentosituacao as situacao, sp.pgst_dspagamentosituacao as situacao_anterior,"
                                          " d.dotp_dsdocumentotipo as documento_tipo, da.dotp_dsdocumentotipo as documento_agregador,"
                                          f" {conta.format(c='p.cnta_id')} as conta, p.loca_id as localidade,"
                                          " f.arfm_dsarrecadacaoforma as forma,"
                                          f" {item.format(c='p.amit_id')} as item, {aviso.format(c='p.avbc_id')} as aviso,"
                                          " p.pgmt_icclassrecupcredito as indicador_recuperacao_credito,"
                                          " p.pgmt_icexpurgado as expurgado, (p.pgmt_tmprocessamento is not null) as processamento_registrado"
                                          " from arrecadacao.pagamento p"
                                          " left join arrecadacao.pagamento_situacao sa on sa.pgst_id = p.pgst_idatual"
                                          " left join arrecadacao.pagamento_situacao sp on sp.pgst_id = p.pgst_idanterior"
                                          " left join cobranca.documento_tipo d on d.dotp_id = p.dotp_id"
                                          " left join cobranca.documento_tipo da on da.dotp_id = p.dotp_idagregador"
                                          " left join arrecadacao.arrecadacao_forma f on f.arfm_id = p.arfm_id"
                                          " order by p.imov_id, p.pgmt_amreferenciapagamento, p.pgmt_dtpagamento, p.pgmt_id"),
        'avisos': _linhas(ctx, "select row_number() over (order by a.avbc_id) as ordem, m.armv_nnnsa as nsa,"
                               " to_char(a.avbc_dtlancamento, 'DD/MM/YYYY') as data_lancamento,"
                               " to_char(a.avbc_dtprevista, 'DD/MM/YYYY') as data_prevista,"
                               " to_char(a.avbc_dtrealizada, 'DD/MM/YYYY') as data_realizada, a.avbc_nnsequencial as sequencial,"
                               " a.avbc_amreferenciaarrecadacao as referencia_arrecadacao,"
                               " a.avbc_vlarrecadacaocalculado::text as arrecadacao_calculado,"
                               " a.avbc_vlarrecadacaoinformado::text as arrecadacao_informado,"
                               " a.avbc_vldevolucaocalculado::text as devolucao_calculado,"
                               " a.avbc_vldevolucaoinformado::text as devolucao_informado, a.avbc_vlrealizado::text as realizado,"
                               " a.avbc_vlcontabilizado::text as contabilizado, a.avbc_iccreditodebito as credito_debito,"
                               " a.avbc_nndocumento as documento, f.arfm_dsarrecadacaoforma as forma,"
                               " (a.ctbc_id is not null) as com_conta_bancaria"
                               " from arrecadacao.aviso_bancario a left join arrecadacao.arrecadador_movimento m using (armv_id)"
                               " left join arrecadacao.arrecadacao_forma f on f.arfm_id = a.arfm_id order by a.avbc_id"),
        'devolucoes': _linhas(ctx, "select d.imov_id as matricula, d.devl_vldevolucao::text as valor,"
                                   " to_char(d.devl_dtdevolucao, 'DD/MM/YYYY') as data_devolucao,"
                                   " d.devl_amreferenciaarrecadacao as referencia_arrecadacao, s.dvst_dsdevolucaosituacao as situacao"
                                   " from arrecadacao.devolucao d left join arrecadacao.devolucao_situacao s on s.dvst_id = d.dvst_idatual"
                                   " order by d.devl_id"),
        'contratos': _linhas(ctx, "select c.arct_nncontrato as contrato, c.arct_nnnsaretornocdbarras as nsa_retorno_codigo_barras"
                                  " from arrecadacao.arrecadador_contrato c order by c.arct_id"),
    }


def _devolucao(ctx):
    """Tratamento do pagamento não classificado (lote 6b): as guias de devolução (imóvel, documento, referência, valor,
    tipo de crédito, situação, RA de origem), as devoluções com a guia, o aviso e a referência, e os créditos a realizar
    com tipo, origem, valor, referências e situação — num bloco à parte, para o bloco `arrecadacao` (lote 6) não mudar."""
    return {
        'guias_devolucao': _linhas(ctx, IDENT +
                                   "select g.imov_id as matricula, d.dotp_dsdocumentotipo as documento,"
                                   " g.gdev_amreferenciaguiadevolucao as referencia, g.gdev_vldevolucao::text as valor,"
                                   " t.crti_dscreditotipo as credito_tipo, s.dcst_dsdebitocreditosituacao as situacao,"
                                   " g.gdev_amreferenciacontabil as referencia_contabil, (g.rgat_id is not null) as com_ra,"
                                   f" {_data_relativa('g.gdev_dtemissao')} as data_emissao,"
                                   " (g.gdev_dtvalidade - g.gdev_dtemissao) as dias_validade,"
                                   " case when g.cnta_id is null then null else (select " + IDENT_JSON.format(a='x') +
                                   "  from ident x where x.cnta_id = g.cnta_id) end as conta"
                                   " from arrecadacao.guia_devolucao g left join cobranca.documento_tipo d using (dotp_id)"
                                   " left join faturamento.credito_tipo t using (crti_id)"
                                   " left join faturamento.debito_credito_situacao s on s.dcst_id = g.dcst_idatual order by g.gdev_id"),
        'devolucoes_detalhe': _linhas(ctx, "select d.imov_id as matricula, d.devl_vldevolucao::text as valor,"
                                           " to_char(d.devl_dtdevolucao, 'DD/MM/YYYY') as data_devolucao,"
                                           " d.devl_amreferenciadevolucao as referencia_devolucao,"
                                           " d.devl_amreferenciaarrecadacao as referencia_arrecadacao,"
                                           " sa.dvst_dsdevolucaosituacao as situacao, sp.dvst_dsdevolucaosituacao as situacao_anterior,"
                                           " (d.gdev_id is not null) as com_guia,"
                                           " (select count(*) from arrecadacao.aviso_bancario k where k.avbc_id <= d.avbc_id) as aviso"
                                           " from arrecadacao.devolucao d"
                                           " left join arrecadacao.devolucao_situacao sa on sa.dvst_id = d.dvst_idatual"
                                           " left join arrecadacao.devolucao_situacao sp on sp.dvst_id = d.dvst_idanterior order by d.devl_id"),
        'creditos_a_realizar_devolucao': _linhas(ctx, "select r.imov_id as matricula, t.crti_dscreditotipo as tipo,"
                                                      " o.crog_dscreditoorigem as origem, r.crar_vlcredito::text as valor,"
                                                      " r.crar_amreferenciacredito as referencia_credito,"
                                                      " r.crar_amcobrancacredito as referencia_cobranca,"
                                                      " r.crar_amreferenciacontabil as referencia_contabil,"
                                                      " r.crar_nnprestacaocredito as prestacoes, r.crar_nnprestacaorealizadas as realizadas,"
                                                      " s.dcst_dsdebitocreditosituacao as situacao, (r.rgat_id is not null) as com_ra,"
                                                      " u.usur_nmlogin as autor"
                                                      " from faturamento.credito_a_realizar r join faturamento.credito_tipo t using (crti_id)"
                                                      " join faturamento.credito_origem o using (crog_id)"
                                                      " join faturamento.debito_credito_situacao s on s.dcst_id = r.dcst_idatual"
                                                      " left join seguranca.usuario u using (usur_id)"
                                                      " order by r.imov_id, r.crar_id"),
    }


# Identidade documental que alcança também a conta arquivada (faturamento.conta_historico guarda o mesmo cnta_id).
IDENT_H = ("with identh as (select cnta_id, imov_id, referencia, historico, row_number() over (partition by imov_id,"
           " referencia, historico order by cnta_id) as ordem from (select cnta_id, imov_id, cnta_amreferenciaconta as referencia,"
           " false as historico from faturamento.conta union all select cnta_id, imov_id, cnhi_amreferenciaconta, true"
           " from faturamento.conta_historico) u) ")
IDENTH_JSON = ("json_build_object('matricula', {a}.imov_id, 'referencia', {a}.referencia, 'ordem', {a}.ordem,"
               " 'historico', {a}.historico)")


def _encerramento(ctx):
    """Encerramento da arrecadação e arquivamento (lote 6c): as referências do sistema; o resumo da arrecadação linha a
    linha (tipo de recebimento, tipo e item de lançamento pelas constantes do legado, sequências, categoria e valor); os
    pagamentos atuais com a conta pela identidade documental que alcança também a conta arquivada; e o que foi para o
    histórico — pagamentos (com a conta e o item do movimento de origem), contas, devoluções e créditos a realizar. Num
    bloco à parte: os blocos dos lotes 6 e 6b não mudam. Ids técnicos nunca saem."""
    item = ("(select json_build_object('nsa', m.armv_nnnsa, 'ordem', (select count(*) from arrecadacao.arrecadador_mov_item k"
            " where k.armv_id = i.armv_id and k.amit_id <= i.amit_id)) from arrecadacao.arrecadador_mov_item i"
            " join arrecadacao.arrecadador_movimento m using (armv_id) where i.amit_id = {c})")
    conta = ("case when {c} is null then null else coalesce((select " + IDENTH_JSON.format(a='x') +
             " from identh x where x.cnta_id = {c}), json_build_object('conta_geral_sem_documento', true)) end")
    return {
        'parametros': _linhas(ctx, "select parm_amreferenciaarrecadacao as referencia_arrecadacao,"
                                   " parm_amreferenciafaturamento as referencia_faturamento from cadastro.sistema_parametros"),
        'resumo_arrecadacao': _linhas(ctx, "select r.rarr_amreferencia as referencia, r.loca_id as localidade,"
                                           " r.greg_id as gerencia, r.uneg_id as unidade_negocio, c.catg_dscategoria as categoria,"
                                           " r.rctp_id as recebimento_tipo, t.rctp_dsrecebimentotipo as recebimento,"
                                           " r.lctp_id as lancamento_tipo, r.lcit_id as lancamento_item,"
                                           " ic.lict_dsitemlancamentocontabil as item_contabil,"
                                           " r.rarr_nnsequenciatipolancamento as sequencia_tipo,"
                                           " r.rarr_nnseqitemtplanc as sequencia_item, r.rarr_vlitemarrecadacao::text as valor"
                                           " from arrecadacao.resumo_arrecadacao r"
                                           " left join cadastro.categoria c using (catg_id)"
                                           " left join arrecadacao.recebimento_tipo t using (rctp_id)"
                                           " left join financeiro.lancamento_item_contabil ic using (lict_id)"
                                           " order by r.rarr_amreferencia, r.loca_id, r.rarr_nnsequenciatipolancamento,"
                                           " r.rarr_nnseqitemtplanc, r.catg_id, r.lcit_id, r.lict_id, r.rctp_id, r.rarr_vlitemarrecadacao"),
        'pagamentos_documento': _linhas(ctx, IDENT_H +
                                        "select p.imov_id as matricula, p.pgmt_amreferenciapagamento as referencia_pagamento,"
                                        " p.pgmt_vlpagamento::text as valor, p.pgmt_vlexcedente::text as excedente,"
                                        " to_char(p.pgmt_dtpagamento, 'DD/MM/YYYY') as data_pagamento,"
                                        " p.pgmt_amreferenciaarrecadacao as referencia_arrecadacao,"
                                        " sa.pgst_dspagamentosituacao as situacao, sp.pgst_dspagamentosituacao as situacao_anterior,"
                                        f" {conta.format(c='p.cnta_id')} as conta"
                                        " from arrecadacao.pagamento p"
                                        " left join arrecadacao.pagamento_situacao sa on sa.pgst_id = p.pgst_idatual"
                                        " left join arrecadacao.pagamento_situacao sp on sp.pgst_id = p.pgst_idanterior"
                                        " order by p.imov_id, p.pgmt_amreferenciapagamento, p.pgmt_dtpagamento, p.pgmt_vlpagamento, p.pgmt_id"),
        'pagamentos_historico': _linhas(ctx, IDENT_H +
                                        "select p.imov_id as matricula, p.pghi_amreferenciapagamento as referencia_pagamento,"
                                        " p.pghi_vlpagamento::text as valor, p.pghi_vlexcedente::text as excedente,"
                                        " to_char(p.pghi_dtpagamento, 'DD/MM/YYYY') as data_pagamento,"
                                        " p.pghi_amreferenciaarrecadacao as referencia_arrecadacao,"
                                        " sa.pgst_dspagamentosituacao as situacao, sp.pgst_dspagamentosituacao as situacao_anterior,"
                                        " d.dotp_dsdocumentotipo as documento_tipo, da.dotp_dsdocumentotipo as documento_agregador,"
                                        f" {conta.format(c='p.cnta_id')} as conta, p.loca_id as localidade,"
                                        " f.arfm_dsarrecadacaoforma as forma, p.pghi_cdagente as agente,"
                                        f" {item.format(c='p.amit_id')} as item,"
                                        " (select count(*) from arrecadacao.aviso_bancario k where k.avbc_id <= p.avbc_id) as aviso,"
                                        " p.pghi_icexpurgado as expurgado, (p.pghi_tmprocessamento is not null) as processamento_registrado"
                                        " from arrecadacao.pagamento_historico p"
                                        " left join arrecadacao.pagamento_situacao sa on sa.pgst_id = p.pgst_idatual"
                                        " left join arrecadacao.pagamento_situacao sp on sp.pgst_id = p.pgst_idanterior"
                                        " left join cobranca.documento_tipo d on d.dotp_id = p.dotp_id"
                                        " left join cobranca.documento_tipo da on da.dotp_id = p.dotp_idagregador"
                                        " left join arrecadacao.arrecadacao_forma f on f.arfm_id = p.arfm_id"
                                        " order by p.imov_id, p.pghi_amreferenciapagamento, p.pghi_dtpagamento, p.pghi_vlpagamento, p.pghi_id"),
        'contas_historico': _linhas(ctx, IDENT_H +
                                    "select " + IDENTH_JSON.format(a='x') + " as conta,"
                                    " sa.dcst_dsdebitocreditosituacao as situacao, sp.dcst_dsdebitocreditosituacao as situacao_anterior,"
                                    " (h.cnhi_vlagua + h.cnhi_vlesgoto + h.cnhi_vldebitos - h.cnhi_vlcreditos)::text as valor_total,"
                                    " h.cnhi_amreferenciacontabil as referencia_contabil,"
                                    " h.cnhi_amreferenciabaixacontabil as referencia_baixa_contabil,"
                                    " to_char(h.cnhi_dtvencimentoconta, 'DD/MM/YYYY') as vencimento,"
                                    " g.cntg_ichistorico as indicador_historico,"
                                    " exists (select 1 from faturamento.conta k where k.cnta_id = h.cnta_id) as ainda_na_tabela_de_contas"
                                    " from faturamento.conta_historico h join identh x on x.cnta_id = h.cnta_id and x.historico"
                                    " join faturamento.conta_geral g on g.cnta_id = h.cnta_id"
                                    " left join faturamento.debito_credito_situacao sa on sa.dcst_id = h.dcst_idatual"
                                    " left join faturamento.debito_credito_situacao sp on sp.dcst_id = h.dcst_idanterior"
                                    " order by h.imov_id, h.cnhi_amreferenciaconta, h.cnta_id"),
        'devolucoes_historico': _linhas(ctx, "select d.imov_id as matricula, d.dehi_vldevolucao::text as valor,"
                                             " to_char(d.dehi_dtdevolucao, 'DD/MM/YYYY') as data_devolucao,"
                                             " d.dehi_amreferenciadevolucao as referencia_devolucao,"
                                             " d.dehi_amreferenciaarrecadacao as referencia_arrecadacao,"
                                             " sa.dvst_dsdevolucaosituacao as situacao, sp.dvst_dsdevolucaosituacao as situacao_anterior,"
                                             " (d.gdev_id is not null) as com_guia, (d.crar_id is not null) as com_credito,"
                                             " (select count(*) from arrecadacao.aviso_bancario k where k.avbc_id <= d.avbc_id) as aviso"
                                             " from arrecadacao.devolucao_historico d"
                                             " left join arrecadacao.devolucao_situacao sa on sa.dvst_id = d.dvst_idatual"
                                             " left join arrecadacao.devolucao_situacao sp on sp.dvst_id = d.dvst_idanterior"
                                             " order by d.imov_id, d.dehi_dtdevolucao, d.dehi_vldevolucao, d.dehi_id"),
        'creditos_a_realizar_historico': _linhas(ctx, "select r.imov_id as matricula, t.crti_dscreditotipo as tipo,"
                                                      " o.crog_dscreditoorigem as origem, r.carh_vlcredito::text as valor,"
                                                      " r.carh_amreferenciacredito as referencia_credito,"
                                                      " r.carh_amcobrancacredito as referencia_cobranca,"
                                                      " s.dcst_dsdebitocreditosituacao as situacao"
                                                      " from faturamento.cred_a_realiz_hist r"
                                                      " left join faturamento.credito_tipo t using (crti_id)"
                                                      " left join faturamento.credito_origem o using (crog_id)"
                                                      " left join faturamento.debito_credito_situacao s on s.dcst_id = r.dcst_idatual"
                                                      " order by r.imov_id, r.crar_id"),
    }


def _cobranca(ctx):
    """Posição de dívida e acréscimos (lote 7): cada conta pela identidade documental com situação, valor, vencimento, o
    motivo e a data da revisão e o indicador de multa já cobrada; e os débitos a cobrar de ACRÉSCIMO (multa, juros,
    atualização — os tipos das constantes) com as referências de débito e de cobrança. Num bloco à parte: os anteriores
    não mudam."""
    return {
        'contas_cobranca': _linhas(ctx, IDENT +
                                   "select " + IDENT_JSON.format(a='x') + " as conta, s.dcst_dsdebitocreditosituacao as situacao,"
                                   " (c.cnta_vlagua + c.cnta_vlesgoto + c.cnta_vldebitos - c.cnta_vlcreditos"
                                   " - coalesce(c.cnta_vlimpostos, 0))::text as valor_total,"
                                   f" {_data_do_dia('c.cnta_dtvencimentoconta')} as vencimento,"
                                   " m.cmrv_dsmotivorevisaoconta as motivo_revisao,"
                                   f" {_data_relativa('c.cnta_dtrevisao')} as data_revisao,"
                                   " c.cnta_iccobrancamulta as indicador_cobranca_multa"
                                   " from faturamento.conta c join ident x using (cnta_id)"
                                   " left join faturamento.debito_credito_situacao s on s.dcst_id = c.dcst_idatual"
                                   " left join faturamento.conta_motivo_revisao m using (cmrv_id)"
                                   " order by c.imov_id, c.cnta_amreferenciaconta, c.cnta_id"),
        'debitos_acrescimos': _linhas(ctx, "select d.imov_id as matricula, t.dbtp_dsdebitotipo as tipo, d.dbac_vldebito::text as valor,"
                                           " d.dbac_amreferenciadebito as referencia_debito, d.dbac_amcobrancadebito as referencia_cobranca,"
                                           " d.dbac_nnprestacaodebito as prestacoes, d.dbac_nnprestacaocobradas as cobradas,"
                                           " s.dcst_dsdebitocreditosituacao as situacao, f.cbfm_dscobrancaforma as forma_cobranca"
                                           " from faturamento.debito_a_cobrar d join faturamento.debito_tipo t using (dbtp_id)"
                                           " join faturamento.debito_credito_situacao s on s.dcst_id = d.dcst_idatual"
                                           " left join cobranca.cobranca_forma f using (cbfm_id)"
                                           " where d.dbtp_id in (80, 91, 94, 100)"
                                           " order by d.imov_id, d.dbac_amreferenciadebito, d.dbtp_id"),
    }


def _parcelamento(ctx):
    """Parcelamento de débitos (lote 7b): cada parcelamento com a memória financeira que o cabeçalho guarda (valores de
    contas, serviços, acréscimos, descontos, entrada, juros, prestações), situação, tipo, RD, perfil e indicadores; os
    itens, cada um pelo documento original (conta pela identidade documental, débito, guia ou crédito pelo tipo e valor);
    as guias de pagamento (a da entrada) com o vencimento em dias da emissão; e os contadores de parcelamento do imóvel.
    Num bloco à parte: os anteriores não mudam."""
    v = ("conta vlconta vlservicosacobrar vlatualizacaomonetaria vljurosmora vlmulta vldebitoatualizado vldescontoacrescimos"
         " vlentrada vljurosparcelamento vlprestacao vldescontoantiguidade vldescontoinatividade pcdescontoacrescimos"
         " pcdescontoantiguidade pcdescontoinatividade vlguiapapagamento vlcreditoarealizar vlparcelamentosacobrar txjuros"
         " vldescontosancao vldescontotarsoc vldescontodebtotal vldescontofaixa").split()[1:]
    valores = ', '.join(f'p.parc_{c}::text as {c}' for c in v)
    hoje = _hoje(ctx)
    parcelamentos = _linhas(ctx, "select p.imov_id as matricula, s.pcst_dsparcelamentosituacao as situacao,"
                                      " t.pctp_dsparcelamentotipo as tipo, r.rdir_nnresolucaodiretoria as rd, p.pcpf_id as perfil,"
                                      f" {_data_relativa('p.parc_tmparcelamento')} as data_parcelamento,"
                                      " p.parc_amreferenciafaturamento as referencia_faturamento, p.parc_nnprestacoes as prestacoes,"
                                      f" {valores}, p.parc_icdebitoacobrar as ic_debito_a_cobrar,"
                                      " p.parc_icacrescimosimpontualdade as ic_acrescimos, p.parc_iccontasrevisao as ic_contas_revisao,"
                                      " p.parc_icguiaspagamento as ic_guias, p.parc_iccreditoarealizar as ic_credito,"
                                      " p.parc_icrestabelecimento as ic_restabelecimento, p.parc_icconfirmacao as ic_confirmacao,"
                                      " f.cbfm_dscobrancaforma as forma_cobranca, u.usur_nmlogin as usuario,"
                                      " m.pmdz_dsparcmtmotivodesfazer as motivo_desfazer, ud.usur_nmlogin as usuario_desfazimento"
                                      " from cobranca.parcelamento p"
                                      " left join cobranca.parcelamento_situacao s using (pcst_id)"
                                      " left join cobranca.parcelamento_tipo t using (pctp_id)"
                                      " left join cobranca.resolucao_diretoria r using (rdir_id)"
                                      " left join cobranca.cobranca_forma f using (cbfm_id)"
                                      " left join seguranca.usuario u on u.usur_id = p.usur_id"
                                      " left join seguranca.usuario ud on ud.usur_id = p.usur_iddesfaz"
                                      " left join cobranca.parcel_motivo_desfazer m on m.pmdz_id = p.pmdz_id"
                                      " order by p.imov_id, p.parc_id")
    for p in parcelamentos:
        p['referencia_faturamento'] = _mes_do_dia(p['referencia_faturamento'], hoje)
    return {
        'parcelamentos': parcelamentos,
        'itens_parcelamento': _linhas(ctx, IDENT_H +
                                      "select p.imov_id as parcelamento_imovel, d.dotp_dsdocumentotipo as documento,"
                                      " case when i.cnta_id is null then null else (select " + IDENTH_JSON.format(a='x') +
                                      "  from identh x where x.cnta_id = i.cnta_id) end as conta,"
                                      " (select json_build_object('tipo', t.dbtp_dsdebitotipo, 'valor', a.dbac_vldebito::text)"
                                      "  from faturamento.debito_a_cobrar a join faturamento.debito_tipo t using (dbtp_id)"
                                      "  where a.dbac_id = i.dbac_id) as debito_a_cobrar,"
                                      " (select json_build_object('tipo', t.dbtp_dsdebitotipo, 'valor', g.gpag_vldebito::text)"
                                      "  from faturamento.guia_pagamento g join faturamento.debito_tipo t using (dbtp_id)"
                                      "  where g.gpag_id = i.gpag_id) as guia,"
                                      " (select json_build_object('tipo', t.crti_dscreditotipo, 'valor', c.crar_vlcredito::text)"
                                      "  from faturamento.credito_a_realizar c join faturamento.credito_tipo t using (crti_id)"
                                      "  where c.crar_id = i.crar_id) as credito_a_realizar"
                                      " from cobranca.parcelamento_item i join cobranca.parcelamento p using (parc_id)"
                                      " left join cobranca.documento_tipo d using (dotp_id)"
                                      " order by p.parc_id, i.dotp_id, i.cnta_id, i.dbac_id, i.gpag_id, i.crar_id"),
        'guias_pagamento': _linhas(ctx, "select g.imov_id as matricula, t.dbtp_dsdebitotipo as tipo, d.dotp_dsdocumentotipo as documento,"
                                        " g.gpag_vldebito::text as valor, s.dcst_dsdebitocreditosituacao as situacao,"
                                        f" {_data_relativa('g.gpag_dtemissao')} as emissao,"
                                        " (g.gpag_dtvencimento - g.gpag_dtemissao) as dias_para_vencimento,"
                                        " g.gpag_nnprestacaodebito as prestacao, g.gpag_nnprestacaototal as prestacoes,"
                                        " (g.parc_id is not null) as do_parcelamento, g.gpag_iccobrancamulta as ic_cobranca_multa"
                                        " from faturamento.guia_pagamento g join faturamento.debito_tipo t using (dbtp_id)"
                                        " left join cobranca.documento_tipo d using (dotp_id)"
                                        " left join faturamento.debito_credito_situacao s on s.dcst_id = g.dcst_idatual"
                                        " order by g.imov_id, g.gpag_id"),
        'imoveis_parcelamento': _linhas(ctx, "select imov_id as matricula, imov_nnparcelamento as parcelamentos,"
                                             " imov_nnreparcelamento as reparcelamentos, imov_nnreparcmtconsec as reparcelamentos_consecutivos"
                                             " from cadastro.imovel where imov_id in (100013, 100021, 100030) order by imov_id"),
    }


def _acao_cobranca(ctx):
    """Ação de cobrança (lote 8): os comandos eventuais (ação, atividade, critério, períodos, se realizado, quantidade de
    documentos e de itens, valor); os documentos de cobrança por imóvel (ação, tipo, forma de emissão, situação da ação e do
    débito, valores de documento, acréscimos, desconto e taxa, emissão relativa à execução); os itens de cada documento pelo
    documento original (conta pela identidade documental), com valor, acréscimos e situação do débito; os imóveis que a
    geração recusou, com o motivo; os pagamentos associados a um documento (o documento pago pelo código de barras dele).
    Num bloco à parte: os anteriores não mudam."""
    return {
        'comandos_cobranca': _linhas(ctx, "select a.cbac_dscobrancaacao as acao, t.cbat_dscobrancaatividade as atividade,"
                                          " c.cacm_iccriterio as indicador_criterio, c.cbct_id is not null as com_criterio,"
                                          " c.cacm_amreferenciacontainicial as referencia_inicial, c.cacm_amreferenciacontafinal as referencia_final,"
                                          " to_char(c.cacm_dtvencimentocontainicial, 'DD/MM/YYYY') as vencimento_inicial,"
                                          " to_char(c.cacm_dtvencimentocontafinal, 'DD/MM/YYYY') as vencimento_final,"
                                          " (c.cacm_tmrealizacao is not null) as realizado, c.cacm_qtdocumentos as documentos,"
                                          " c.cacm_qtitenscobrados as itens, c.cacm_vldocumentos::text as valor_documentos, c.cacm_dstitulo as titulo"
                                          " from cobranca.cobranca_acao_ativ_cmd c join cobranca.cobranca_acao a on a.cbac_id = c.cbac_id"
                                          " join cobranca.cobranca_atividade t on t.cbat_id = c.cbat_id order by c.cacm_id"),
        'documentos_cobranca': _linhas(ctx, "select d.imov_id as matricula, a.cbac_dscobrancaacao as acao, t.dotp_dsdocumentotipo as documento,"
                                            " f.demf_dsdocumentoemissaoforma as emissao_forma, s.cast_dssituacaoacao as situacao_acao,"
                                            " ds.cdst_dssituacaodebito as situacao_debito, d.cbdo_vldocumento::text as valor_documento,"
                                            " d.cbdo_vlacrescimos::text as acrescimos, d.cbdo_vldesconto::text as desconto, d.cbdo_vltaxa::text as taxa,"
                                            f" {_data_relativa('d.cbdo_tmemissao')} as emissao, (d.cacm_id is not null) as do_comando,"
                                            " (select count(*) from cobranca.cobranca_documento_item i where i.cbdo_id = d.cbdo_id) as itens"
                                            " from cobranca.cobranca_documento d left join cobranca.cobranca_acao a on a.cbac_id = d.cbac_id"
                                            " left join cobranca.documento_tipo t on t.dotp_id = d.dotp_id"
                                            " left join cobranca.documento_emissao_forma f on f.demf_id = d.demf_id"
                                            " left join cobranca.cobranca_acao_situacao s on s.cast_id = d.cast_id"
                                            " left join cobranca.cobranca_debito_situacao ds on ds.cdst_id = d.cdst_id"
                                            " order by d.imov_id, d.cbdo_id"),
        'itens_cobranca': _linhas(ctx, IDENT_H +
                                       "select d.imov_id as documento_imovel, t.dotp_dsdocumentotipo as item_documento,"
                                       " case when i.cnta_id is null then null else (select " + IDENTH_JSON.format(a='x') +
                                       "  from identh x where x.cnta_id = i.cnta_id) end as conta,"
                                       " i.cdit_vlitemcobrado::text as valor, i.cdit_vlacrescimos::text as acrescimos,"
                                       " s.cdst_dssituacaodebito as situacao_debito, (i.dbac_id is not null) as debito_a_cobrar,"
                                       " (i.gpag_id is not null) as guia"
                                       " from cobranca.cobranca_documento_item i join cobranca.cobranca_documento d using (cbdo_id)"
                                       " left join cobranca.documento_tipo t on t.dotp_id = i.dotp_id"
                                       " left join cobranca.cobranca_debito_situacao s on s.cdst_id = i.cdst_id"
                                       " order by d.imov_id, d.cbdo_id, i.cnta_id, i.cdit_id"),
        'imoveis_nao_gerados': _linhas(ctx, "select n.imov_id as matricula, m.mngd_dsmotivo as motivo, (n.cacm_id is not null) as do_comando"
                                            " from cobranca.imovel_nao_gerado n"
                                            " left join cobranca.motivo_nao_ger_doc_cobr m on m.mngd_id = n.mngd_id"
                                            " order by n.imov_id, n.mngd_id"),
        'pagamentos_documento': _linhas(ctx, IDENT +
                                        "select p.imov_id as matricula, p.pgmt_amreferenciapagamento as referencia_pagamento,"
                                        " p.pgmt_vlpagamento::text as valor, d.imov_id as documento_imovel,"
                                        " t.dotp_dsdocumentotipo as documento,"
                                        " case when p.cnta_id is null then null else (select " + IDENT_JSON.format(a='x') +
                                        "  from ident x where x.cnta_id = p.cnta_id) end as conta"
                                        " from arrecadacao.pagamento p join cobranca.cobranca_documento d on d.cbdo_id = p.cbdo_id"
                                        " left join cobranca.documento_tipo t on t.dotp_id = d.dotp_id"
                                        " order by p.imov_id, p.pgmt_amreferenciapagamento, p.pgmt_id"),
    }


def _financeiro(ctx):
    """Contabilização (lote 9): as referências do sistema; o resumo do faturamento linha a linha (tipo, item e item contábil de
    lançamento pelas constantes do legado, categoria, sequências e valor); os lançamentos contábeis (referência, origem, tipo,
    localidade, tipo de recebimento) com cada item — o indicador de débito/crédito como o legado o grava (e a natureza pelas
    constantes ConstantesSistema.INDICADOR_DEBITO = 2, INDICADOR_CREDITO = 1), a conta contábil pelo
    número, o valor e o histórico; os parâmetros e o resumo dos devedores duvidosos; as contas baixadas contabilmente, pela
    identidade documental. Ids técnicos nunca saem."""
    return {
        'parametros_financeiro': _linhas(ctx, "select parm_amreferenciafaturamento as referencia_faturamento,"
                                              " parm_amreferenciaarrecadacao as referencia_arrecadacao from cadastro.sistema_parametros"),
        'resumo_faturamento': _linhas(ctx, "select r.rfat_amreferencia as referencia, r.loca_id as localidade, c.catg_dscategoria as categoria,"
                                           " r.lctp_id as lancamento_tipo, t.lctp_dstipolancamento as tipo, r.lcit_id as lancamento_item,"
                                           " i.lcit_dsitemlancamento as item, ic.lict_dsitemlancamentocontabil as item_contabil,"
                                           " r.rfat_nnsequenciatipolancamento as sequencia_tipo, r.rfat_nnseqitemtplanc as sequencia_item,"
                                           " r.rfat_vlitemfaturamento::text as valor"
                                           " from financeiro.resumo_faturamento r"
                                           " left join cadastro.categoria c on c.catg_id = r.catg_id"
                                           " left join financeiro.lancamento_tipo t on t.lctp_id = r.lctp_id"
                                           " left join financeiro.lancamento_item i on i.lcit_id = r.lcit_id"
                                           " left join financeiro.lancamento_item_contabil ic on ic.lict_id = r.lict_id"
                                           " order by r.rfat_amreferencia, r.loca_id, r.rfat_nnsequenciatipolancamento, r.rfat_nnseqitemtplanc,"
                                           " r.catg_id, r.lctp_id, r.lcit_id, r.lict_id, r.rfat_vlitemfaturamento"),
        'lancamentos_contabeis': _linhas(ctx, "select l.lcnb_amlancamento as referencia, o.lcor_dslancamentoorigem as origem,"
                                              " l.lctp_id as lancamento_tipo, t.lctp_dstipolancamento as tipo, l.loca_id as localidade,"
                                              " l.rctp_id as recebimento_tipo, i.lcti_icdebitocredito as indicador_debito_credito,"
                                              " case i.lcti_icdebitocredito when 2 then 'DEBITO' when 1 then 'CREDITO' end as natureza,"
                                              " rtrim(k.cnct_nnconta) as conta_contabil, i.lcti_vllancamento::text as valor, i.lcti_dshistorico as historico"
                                              " from financeiro.lancamento_contabil l"
                                              " left join financeiro.lancamento_origem o on o.lcor_id = l.lcor_id"
                                              " left join financeiro.lancamento_tipo t on t.lctp_id = l.lctp_id"
                                              " left join financeiro.lancamento_contabil_item i on i.lcnb_id = l.lcnb_id"
                                              " left join financeiro.conta_contabil k on k.cnct_id = i.cnct_id"
                                              " order by l.lcnb_amlancamento, l.lcor_id, l.loca_id, l.lctp_id, l.rctp_id, k.cnct_nnconta,"
                                              " i.lcti_icdebitocredito, i.lcti_vllancamento, i.lcti_dshistorico"),
        'devedores_parametros': _linhas(ctx, "select p.pded_amreferenciacontabil as referencia_contabil, p.pded_vlvalorabaixar::text as valor_a_baixar,"
                                             " p.pded_vlbaixado::text as valor_baixado, p.pded_amreferenciaarrecadacao as referencia_arrecadacao,"
                                             f" {_data_relativa('p.pded_tmprocessamento')} as processamento"
                                             " from financeiro.param_deved_duvid p order by p.pded_amreferenciacontabil"),
        'resumo_devedores': _linhas(ctx, "select r.rded_amreferenciacontabil as referencia_contabil, r.rded_amreferenciaarrecadacao as referencia_arrecadacao,"
                                         " r.loca_id as localidade, c.catg_dscategoria as categoria, r.lctp_id as lancamento_tipo,"
                                         " r.lcit_id as lancamento_item, i.lcit_dsitemlancamento as item,"
                                         " ic.lict_dsitemlancamentocontabil as item_contabil, r.rded_nnsequenciatipolancamento as sequencia_tipo,"
                                         " r.rded_nnseqlitentplanc as sequencia_item, r.rded_vlvalorbaixado::text as valor_baixado"
                                         " from financeiro.resumo_deved_duvid r"
                                         " left join cadastro.categoria c on c.catg_id = r.catg_id"
                                         " left join financeiro.lancamento_item i on i.lcit_id = r.lcit_id"
                                         " left join financeiro.lancamento_item_contabil ic on ic.lict_id = r.lict_id"
                                         " order by r.rded_amreferenciacontabil, r.loca_id, r.rded_nnsequenciatipolancamento,"
                                         " r.rded_nnseqlitentplanc, r.catg_id, r.lctp_id, r.lcit_id, r.lict_id, r.rded_vlvalorbaixado"),
        'contas_baixadas': _linhas(ctx, IDENT +
                                   "select " + IDENT_JSON.format(a='x') + " as conta, c.cnta_amreferenciabaixacontabil as referencia_baixa,"
                                   " (c.cnta_vlagua + c.cnta_vlesgoto + c.cnta_vldebitos - c.cnta_vlcreditos"
                                   " - coalesce(c.cnta_vlimpostos, 0))::text as valor_total"
                                   " from faturamento.conta c join ident x on x.cnta_id = c.cnta_id"
                                   " where c.cnta_amreferenciabaixacontabil is not null"
                                   " order by c.imov_id, c.cnta_amreferenciaconta, x.ordem"),
    }


DETALHES = {'lancamentos': _lancamentos, 'impostos': _impostos, 'rateio': _rateio, 'micromedicao': _micromedicao,
            'ciclo_conta': _ciclo_conta, 'conta_origem': _conta_origem, 'arrecadacao': _arrecadacao,
            'devolucao': _devolucao, 'encerramento': _encerramento, 'cobranca': _cobranca,
            'parcelamento': _parcelamento, 'acao_cobranca': _acao_cobranca, 'financeiro': _financeiro}


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
    hoje = _hoje(ctx)
    for c in contas:
        cnta = c.pop('cnta_id')
        c['vencimento'] = _datas_do_dia([c['vencimento']], hoje)[0] if c['vencimento'] else None
        c['referencia_contabil'] = _mes_do_dia(c['referencia_contabil'], hoje)
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
    if 'leitura_atual' in passo:
        tela.update(leitura_anterior=dados.get('leituraAnteriorAgua'), leitura_atual=dados.get('leituraAtualAgua'))
    r['tela'] = tela
    # O que a variação digita: o motivo, as economias por categoria e/ou o consumo de água.
    dados['motivoRetificacaoID'] = str(int(passo['motivo']))
    for categoria, quantidade in passo.get('economias', {}).items():
        dados[f'categoria{int(categoria)}'] = str(int(quantidade))
    if 'consumo_agua' in passo:
        dados['consumoAgua'] = str(int(passo['consumo_agua']))
    if 'leitura_atual' in passo:  # alteração da leitura faturada: a nova leitura atual de água
        dados['leituraAtualAgua'] = str(int(passo['leitura_atual']))
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
        # A recusa cujo texto o legado lança no lugar da chave aparece como "???pt_BR.<texto>???" (lote 6c).
        m = re.search(r'\?\?\?[a-z]{2}_[A-Z]{2}\.(.*?)\?\?\?', texto_visivel(html))
        if not r.get('mensagem') and m:
            r['mensagem'] = m.group(1).strip()
    return r


# --- Arrecadação: recepção do movimento do arrecadador (lote 6) --------------------------------------------------------
# O arquivo é o retorno de um arrecadador no layout de 150 posições que a recepção valida — registros A, G e Z
# (ControladorArrecadacao.registrarMovimentoArrecadadores:1679, distribuirdadosRegistroMovimentoArrecadador:10949) — e o
# código de barras de cada registro G é o que o GSAN imprime na conta (obterRepresentacaoNumericaCodigoBarra:38166,
# obterIdentificacaoPagamento:38350): localidade, matrícula, referência e dígito da conta lidos do banco, como a emissão os
# leria. Dinheiro em centavos exatos (Decimal), nunca float. O arquivo inteiro sai no resultado: é a entrada da variação.

def _dv_modulo10(numero):
    """Util.obterDigitoVerificadorModulo10: pesos 2 e 1 a partir da direita, somando os algarismos dos produtos."""
    soma, peso = 0, 2
    for d in reversed(str(numero)):
        soma += sum(int(x) for x in str(int(d) * peso))
        peso = 3 - peso
    return (10 - soma % 10) % 10


def _centavos(valor):
    c = Decimal(str(valor)) * 100
    if c != c.to_integral_value() or c < 0:
        raise ValueError(f'valor fora de centavos: {valor!r}')
    return int(c)


def _registro_g(ctx, reg, sequencia):
    """Um registro G: o código de barras da conta (ou de um documento que não existe) e o valor recebido pelo banco."""
    if reg.get('guia_entrada'):
        return _registro_g_guia_entrada(ctx, reg, sequencia)
    if reg.get('documento_cobranca'):
        return _registro_g_documento(ctx, reg, sequencia)
    imovel, ref = int(reg['imovel']), int(reg['referencia'])
    situacoes = ', '.join(str(int(s)) for s in reg.get('situacoes', (0, 1, 2)))
    if reg.get('arquivada'):  # a conta já no histórico (lote 6c): o código de barras que ela tinha impresso
        conta = _linhas(ctx, "select loca_id, cnhi_dgverificadorconta as dv, (cnhi_vlagua + cnhi_vlesgoto + cnhi_vldebitos"
                             " - cnhi_vlcreditos - coalesce(cnhi_vlimpostos, 0))::text as valor from faturamento.conta_historico"
                             f" where imov_id = {imovel} and cnhi_amreferenciaconta = {ref} and dcst_idatual in ({situacoes})"
                             " order by cnta_id desc limit 1")
    else:
        conta = _linhas(ctx, "select loca_id, cnta_dgverificadorconta as dv, (cnta_vlagua + cnta_vlesgoto + cnta_vldebitos"
                             " - cnta_vlcreditos - coalesce(cnta_vlimpostos, 0))::text as valor from faturamento.conta"
                             f" where imov_id = {imovel} and cnta_amreferenciaconta = {ref} and dcst_idatual in ({situacoes})"
                             " order by cnta_id desc limit 1")
    if conta:
        loca, dv, valor_conta = conta[0]['loca_id'], conta[0]['dv'], conta[0]['valor']
    else:  # documento que não existe: o dígito como a emissão o calcularia (a recepção não o confere)
        loca, dv, valor_conta = int(ctx.sql(f'select loca_id from cadastro.imovel where imov_id = {imovel}')), _dv_modulo10(ref), None
    documento = reg.get('valor_documento', 'conta')
    valor_doc = valor_conta if documento == 'conta' else documento
    if valor_doc is None:
        raise ValueError(f'sem conta de {imovel} em {ref} para o valor do documento')
    recebido = reg.get('valor_recebido', 'documento')
    if recebido == 'documento':
        valor_rec = _centavos(valor_doc)
    elif recebido[0] in '+-':
        valor_rec = _centavos(valor_doc) + (1 if recebido[0] == '+' else -1) * _centavos(recebido[1:])
    else:
        valor_rec = _centavos(recebido)
    empresa = reg.get('empresa') or ctx.sql("select lpad(parm_cdempresafebraban::text, 4, '0') from cadastro.sistema_parametros")
    ident = f'{int(loca):03d}{imovel:09d}01{ref % 100:02d}{ref // 100:04d}{int(dv)}000'
    sem_dv = '826' + f'{_centavos(valor_doc):011d}' + empresa + ident + '3'
    barras = sem_dv[:3] + str(_dv_modulo10(sem_dv)) + sem_dv[3:]
    linha = ('G' + '0001' + '0' * 16 + reg.get('data_pagamento', '20260610') + reg.get('data_credito', '20260611') + barras
             + f'{valor_rec:012d}' + '0' * 7 + f'{sequencia:08d}' + '00000001' + reg.get('forma', '1')
             + ' ' * 23 + '1' + ' ' * 9)
    assert len(linha) == 150, len(linha)
    return linha, valor_rec, {'imovel': imovel, 'referencia': ref, 'conta_no_envio': bool(conta),
                              'valor_documento': f'{Decimal(_centavos(valor_doc)) / 100:.2f}',
                              'valor_recebido': f'{Decimal(valor_rec) / 100:.2f}'}


def _registro_g_guia_entrada(ctx, reg, sequencia):
    """Um registro G da guia de ENTRADA do parcelamento do imóvel (lote 7c): o código de barras que a emissão da guia
    imprime — tipo de pagamento 1, guia com identificação da matrícula (ControladorArrecadacao.obterIdentificacaoPagamento
    :38350, a emissão em :30444 escolhe o tipo 1 para guia de imóvel): localidade, matrícula e o número da guia — e o
    valor da guia."""
    imovel = int(reg['imovel'])
    guia = _linhas(ctx, "select gpag_id, loca_id, gpag_vldebito::text as valor from faturamento.guia_pagamento"
                        f" where imov_id = {imovel} and dotp_id = 2 and parc_id is not null order by gpag_id desc limit 1")
    if not guia:
        raise ValueError(f'sem guia de entrada de parcelamento para {imovel}')
    gpag, loca, valor_doc = int(guia[0]['gpag_id']), int(guia[0]['loca_id']), guia[0]['valor']
    recebido = reg.get('valor_recebido', 'documento')
    valor_rec = _centavos(valor_doc) if recebido == 'documento' else _centavos(recebido)
    empresa = reg.get('empresa') or ctx.sql("select lpad(parm_cdempresafebraban::text, 4, '0') from cadastro.sistema_parametros")
    ident = f'{loca:03d}{imovel:09d}{gpag:09d}001'
    sem_dv = '826' + f'{_centavos(valor_doc):011d}' + empresa + ident + '1'
    barras = sem_dv[:3] + str(_dv_modulo10(sem_dv)) + sem_dv[3:]
    linha = ('G' + '0001' + '0' * 16 + reg.get('data_pagamento', '20260610') + reg.get('data_credito', '20260611') + barras
             + f'{valor_rec:012d}' + '0' * 7 + f'{sequencia:08d}' + '00000001' + reg.get('forma', '1')
             + ' ' * 23 + '1' + ' ' * 9)
    assert len(linha) == 150, len(linha)
    return linha, valor_rec, {'imovel': imovel, 'guia_entrada': True,
                              'valor_documento': f'{Decimal(_centavos(valor_doc)) / 100:.2f}',
                              'valor_recebido': f'{Decimal(valor_rec) / 100:.2f}'}


def _registro_g_documento(ctx, reg, sequencia):
    """Um registro G do DOCUMENTO DE COBRANÇA do imóvel (lote 8): o código de barras que a emissão do documento imprime —
    tipo de pagamento 5 (ControladorCobranca.emitirDocumentoCobranca:22431 → ControladorArrecadacao.obterIdentificacaoPagamento
    :38398): localidade e matrícula do documento, o sequencial do documento e o tipo de documento — e o valor do documento,
    que a recepção confere (processarPagamentosCodigoBarrasDocumentoCobrancaTipo5:5838)."""
    imovel = int(reg['imovel'])
    doc = _linhas(ctx, "select cbdo_nnsequenciadocumento as sequencial, loca_id, dotp_id, cbdo_vldocumento::text as valor"
                       f" from cobranca.cobranca_documento where imov_id = {imovel} order by cbdo_id desc limit 1")
    if not doc:
        raise ValueError(f'sem documento de cobrança para {imovel}')
    seq, loca, dotp, valor_doc = int(doc[0]['sequencial']), int(doc[0]['loca_id']), int(doc[0]['dotp_id']), doc[0]['valor']
    recebido = reg.get('valor_recebido', 'documento')
    valor_rec = _centavos(valor_doc) if recebido == 'documento' else _centavos(recebido)
    empresa = reg.get('empresa') or ctx.sql("select lpad(parm_cdempresafebraban::text, 4, '0') from cadastro.sistema_parametros")
    ident = f'{loca:03d}{imovel:09d}{seq:09d}{dotp:02d}1'
    sem_dv = '826' + f'{_centavos(valor_doc):011d}' + empresa + ident + '5'
    barras = sem_dv[:3] + str(_dv_modulo10(sem_dv)) + sem_dv[3:]
    linha = ('G' + '0001' + '0' * 16 + reg.get('data_pagamento', '20260610') + reg.get('data_credito', '20260611') + barras
             + f'{valor_rec:012d}' + '0' * 7 + f'{sequencia:08d}' + '00000001' + reg.get('forma', '1')
             + ' ' * 23 + '1' + ' ' * 9)
    assert len(linha) == 150, len(linha)
    return linha, valor_rec, {'imovel': imovel, 'documento_cobranca': True,
                              'valor_documento': f'{Decimal(_centavos(valor_doc)) / 100:.2f}',
                              'valor_recebido': f'{Decimal(valor_rec) / 100:.2f}'}


def _arquivo_movimento(ctx, passo):
    """Cabeçalho A (remessa 2, convênio, banco, NSA, layout, CODIGO DE BARRAS), registros G e trailer Z (total de
    registros, inclusive A e Z, e valor total recebido) — `total` e `registros` só quando a variação os força."""
    nsa, geracao = int(passo.get('nsa', 1)), passo.get('data_geracao', '20260611')
    a = ('A2' + f'{"901":<20}' + f'{"EMPRESA SINTETICA":<20}' + '901' + f'{"BANCO SINTETICO":<20}' + geracao + f'{nsa:06d}'
         + passo.get('versao_layout', '04') + f'{"CODIGO DE BARRAS":<17}' + ' ' * 52)
    linhas, total, registros = [a], 0, []
    for i, reg in enumerate(passo['registros']):
        g, valor, desc = _registro_g(ctx, reg, i + 2)
        linhas.append(g)
        total += valor
        registros.append(desc)
    if 'total' in passo:
        total = total + _centavos(passo['total'][1:]) * (1 if passo['total'][0] == '+' else -1)
    z = 'Z' + f'{int(passo.get("registros_trailer", len(linhas) + 1)):06d}' + f'{total:017d}' + ' ' * 126
    linhas.append(z)
    assert all(len(l) == 150 for l in linhas)
    return linhas, registros, f'{Decimal(total) / 100:.2f}'


def _enviar_movimento(ctx, passo):
    """Registrar Movimento dos Arrecadadores (RegistrarMovimentoArrecadadoresAction): agente e tipo de movimento, o
    convênio que a tela lista para eles e o arquivo .ARR; o processamento segue por mensagem (fila do controlador de
    Arrecadação) — a resposta da tela é só o envio."""
    linhas, registros, total = _arquivo_movimento(ctx, passo)
    conteudo = ('\n'.join(linhas) + '\n').encode('ascii')
    nome = f'MOVIMENTO{int(passo.get("nsa", 1)):06d}.ARR'
    r = {'arquivo': {'nome': nome, 'linhas': linhas, 'registros': registros, 'total_trailer': total,
                     'sha256': hashlib.sha256(conteudo).hexdigest()}}
    ctx.atual.get('exibirRegistrarMovimentoArredadadoresAction.do')
    campos = [('codigoAgente', '901'), ('idTipoMovimento', 'CODIGO DE BARRAS')]
    html = ctx.atual.post_multipart('exibirRegistrarMovimentoArredadadoresAction.do?objetoConsulta=1', campos)
    r['tela'] = {'http': ctx.atual.ultimo_estado,
                 'convenio_listado': bool(re.search(r'(?is)<option value="901">\s*901\s*</option>', html))}
    html = ctx.atual.post_multipart('registrarMovimentoArredadadoresAction.do',
                                    campos[:1] + [('idTipoMovimento', 'CODIGO DE BARRAS'), ('codigoConvenio', '901')],
                                    ('uploadPicture', nome, conteudo))
    sucesso = 'Enviado para Processamento' in texto_visivel(html)
    r.update(http=ctx.atual.ultimo_estado, resultado='enviado' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _aguardar_movimento(ctx, passo):
    """O processamento do arquivo é uma transação só (registrarMovimentoArrecadadores, Required): o movimento do NSA
    aparece com tudo o que gravou, ou nada aparece (a transação voltou). Espera até `segundos` e mais 5 s de quietude."""
    nsa, limite = int(passo.get('nsa', 1)), int(passo.get('segundos', 120))
    inicio = time.monotonic()
    while time.monotonic() - inicio < limite:
        if ctx.sql(f'select count(*) from arrecadacao.arrecadador_movimento where armv_nnnsa = {nsa}') != '0':
            time.sleep(5)
            return {'nsa': nsa, 'movimento_gravado': True}
        time.sleep(3)
    return {'nsa': nsa, 'movimento_gravado': False, 'segundos': limite}


SECOES_DEBITO = (('contas', r'<strong>\s*Contas\s*</strong>'), ('contas_inconformes', r'<strong>\s*Contas Inconformes\s*</strong>'),
                 ('debitos_a_cobrar', r'D&eacute;bitos\s+A Cobrar'), ('creditos_a_realizar', r'Cr&eacute;ditos\s+A Realizar'),
                 ('guias', r'Guias de Pagamento'), ('totais', r'Valor Total dos D'))
# A página do débito do CLIENTE (lote 7) quebra os títulos dos quadros em linhas: os mesmos quadros, espaços flexíveis.
SECOES_DEBITO_CLIENTE = (('contas', r'<strong>\s*Contas\s*</strong>'), ('contas_inconformes', r'Contas\s+Inconformes'),
                         ('debitos_a_cobrar', r'D&eacute;bitos\s+A\s+Cobrar'),
                         ('creditos_a_realizar', r'Cr&eacute;ditos\s+A\s+Realizar'),
                         ('guias', r'Guias\s+de\s+Pagamento'), ('totais', r'Valor\s+Total\s+dos'))


def _secoes_debito(html, secoes=SECOES_DEBITO):
    """As linhas de dados de cada quadro da tela, na ordem da tela: o texto de cada célula."""
    marcas = []
    for nome, padrao in secoes:
        m = re.search(padrao, html)
        if m:
            marcas.append((m.start(), nome))
    marcas.sort()
    fim_tela = html.find('class="footer"')
    secoes = {}
    for i, (ini, nome) in enumerate(marcas):
        fim = marcas[i + 1][0] if i + 1 < len(marcas) else (fim_tela if fim_tela > ini else len(html))
        trecho = html[ini:fim]
        secoes[nome] = [[texto_visivel(td) for td in re.findall(r'(?is)<td\b[^>]*>(.*?)</td>', tr)]
                        for tr in re.findall(r'(?is)<tr bgcolor="#(?:FFFFFF|cbe5fe)">(.*?)</tr>', trecho)]
    return secoes


def _contas_da_posicao(s, acrescimos, hoje=None):
    """As linhas do quadro Contas: mês/ano, vencimento, água, esgoto, débitos, créditos, impostos, valor da conta,
    acréscimos, situação — na posição do cliente, com a matrícula antes. Os acréscimos (e a coluna que os soma na linha
    de total) só entram quando a variação os pede."""
    contas, total_contas = [], None
    for c in s.get('contas', []):
        cel = [x for x in c if x != '']
        k = next((n for n, x in enumerate(cel) if re.fullmatch(r'\d{2}/\d{4}', x)), None)
        if k is not None and len(cel) - k == 10:
            linha = {'referencia': cel[k], 'vencimento': _datas_do_dia([cel[k + 1]], hoje)[0], 'valor_agua': moeda(cel[k + 2]),
                     'valor_esgoto': moeda(cel[k + 3]), 'valor_debitos': moeda(cel[k + 4]), 'valor_creditos': moeda(cel[k + 5]),
                     'valor_impostos': moeda(cel[k + 6]), 'valor_conta': moeda(cel[k + 7]), 'situacao': cel[k + 9]}
            if k:
                linha = dict(matricula=cel[k - 1], **linha)
            if acrescimos:
                linha['acrescimos'] = moeda(cel[k + 8])
            contas.append(linha)
        elif cel and cel[0] == 'Total' and len(cel) >= 8:
            # Na posição do imóvel a linha de total traz a quantidade de documentos; na do cliente, não.
            j = 2 if 'doc' in cel[1] else 1
            total_contas = {'documentos': cel[1] if j == 2 else None, 'valor_contas': moeda(cel[j + 5])}
            if acrescimos:
                total_contas['acrescimos'] = moeda(cel[j + 6]) if len(cel) > j + 6 else None
        else:
            raise ValueError(f'linha de conta fora do formato esperado: {cel!r}')
    return contas, total_contas


def _datas_do_dia(celulas, hoje):
    """As datas que o relógio do legado gera na execução — a do dia e as posteriores (emissão e vencimento da guia de
    entrada do parcelamento, lote 7b) — saem relativas a ela; as anteriores (as da massa) saem como estão."""
    saida = []
    for x in celulas:
        m = re.fullmatch(r'(\d{2})/(\d{2})/(\d{4})', x)
        if m and hoje:
            n = (datetime.date(int(m[3]), int(m[2]), int(m[1])) - hoje).days
            if n >= 0:
                x = 'data da execução' + (f' + {n} dias' if n else '')
        saida.append(x)
    return saida


def _posicao(html, s, acrescimos, hoje=None):
    contas, total_contas = _contas_da_posicao(s, acrescimos, hoje)
    totais = s.get('totais', [[]])
    r = {
        'contas': contas, 'total_contas': total_contas,
        'contas_inconformes': [{'referencia': c[0], 'valor_conta': moeda(c[1]), 'valor_pagamento': moeda(c[2]),
                                'data_pagamento': c[3], 'situacao_anterior': c[4] or None, 'situacao_atual': c[5] or None}
                               for c in s.get('contas_inconformes', []) if len(c) == 6],
        'debitos_a_cobrar': [[x for x in c if x] for c in s.get('debitos_a_cobrar', [])],
        'creditos_a_realizar': [[x for x in c if x] for c in s.get('creditos_a_realizar', [])],
        'guias': [_datas_do_dia([x for x in c if x], hoje) for c in s.get('guias', [])],
        'valor_total_debitos': moeda(totais[0][0]) if totais and totais[0] else None,
    }
    if acrescimos:  # o total atualizado (com os acréscimos) e o pagamento à vista, como a tela os mostra
        t = (totais[0] + ['', '', '', ''])[:4] if totais and totais[0] else ['', '', '', '']
        r['totais'] = {'debitos': moeda(t[0]), 'debitos_atualizado': moeda(t[1]), 'desconto_a_vista': moeda(t[2]),
                       'pagamento_a_vista': moeda(t[3])}
    return r


def _consultar_debitos(ctx, passo):
    """Consultar Débitos do imóvel (ConsultarDebitoAction → ExibirConsultarDebitoImovelAction →
    Fachada.obterDebitoImovelOuCliente): a posição de dívida que a Cobrança calcula — as contas em débito, as contas
    "inconformes" (com pagamento que não confere), débitos a cobrar, créditos a realizar, guias e o total dos débitos.
    Fora do resultado, por dependerem do dia em que roda: os acréscimos por impontualidade e os totais atualizado e à
    vista (ficam na evidência) — salvo quando a variação os pede (`acrescimos`, lote 7: os índices da massa tornam o
    resultado independente do dia). `clientes` (lote 7): a mesma consulta pelo cliente (ExibirConsultarDebitoClienteAction),
    com a relação (USUÁRIO, RESPONSÁVEL…) da variação."""
    r = {}
    acrescimos = bool(passo.get('acrescimos'))
    hoje = _hoje(ctx)
    for imovel in passo.get('imoveis', []):
        html = ctx.atual.post('consultarDebitoAction.do', {'codigoImovel': str(int(imovel))})
        r[str(int(imovel))] = dict(http=ctx.atual.ultimo_estado, **_posicao(html, _secoes_debito(html), acrescimos, hoje))
    saida = {'debitos': r}
    if passo.get('clientes'):
        rc = {}
        for cli in passo['clientes']:
            relacao = cli.get('relacao')
            # O formulário da tela fica na sessão: a matrícula da consulta anterior vai vazia, como o navegador a enviaria.
            html = ctx.atual.post('consultarDebitoAction.do', {'codigoImovel': '', 'codigoClienteSuperior': '',
                                                              'codigoCliente': str(int(cli['codigo'])),
                                                              'tipoRelacao': str(int(relacao)) if relacao else '-1'})
            chave = f"{int(cli['codigo'])}" + (f"/{int(relacao)}" if relacao else '')
            rc[chave] = dict(http=ctx.atual.ultimo_estado,
                             **_posicao(html, _secoes_debito(html, SECOES_DEBITO_CLIENTE), acrescimos, hoje))
        saida['debitos_cliente'] = rc
    return saida


def _colocar_revisao(ctx, passo):
    """Colocar Conta em Revisão a partir de Manter Conta (ExibirColocarRevisaoContaAction → ColocarRevisaoContaAction →
    Fachada.colocarRevisaoConta), com o motivo da variação. O efeito é lido do banco (bloco `cobranca`). `forjar`: se a
    tela recusa, o POST é enviado mesmo assim (o servidor aceita ou não) — sem ele, a recusa encerra o passo."""
    r = {}
    conta = _conta_alvo(ctx, passo['imovel'], passo['referencia'], passo.get('situacoes', (0, 1, 2)))
    r['manter_conta'], marca = _manter_conta(ctx, passo['imovel'], conta)
    if not marca:
        r['resultado'] = 'conta_nao_listada'
        return r
    html = ctx.atual.get(f'exibirColocarRevisaoContaAction.do?conta={marca}&idImovel={int(passo["imovel"])}')
    tela = {'http': ctx.atual.ultimo_estado, 'motivos': re.findall(r'(?is)<option\b[^>]*value="(\d+)"', html)}
    dados = _formulario(html, 'ColocarRevisaoContaActionForm')
    if ctx.atual.ultimo_estado >= 400 or not tela['motivos']:
        tela.update(_recusa(html, ctx.atual.ultimo_estado))
        if not passo.get('forjar'):
            r.update(tela=tela, resultado='recusado_na_exibicao')
            return r
        r['forjado'] = True  # o que a tela não deixaria enviar
        dados = {}
    r['tela'] = tela
    dados.update(contaSelected=marca, motivoRevisaoContaID=str(int(passo['motivo'])))
    html = ctx.atual.post('colocarRevisaoContaAction.do', dados)
    recusa = _recusa(html, ctx.atual.ultimo_estado)
    aceito = ctx.atual.ultimo_estado < 400 and not recusa['chaves']
    r.update(http=ctx.atual.ultimo_estado, resultado='aceito' if aceito else 'recusado', mensagem=_sucesso(html))
    if not aceito:
        r.update(recusa)
    return r


# --- Cobrança: parcelamento de débitos (lote 7b) -----------------------------------------------------------------------
# O assistente Efetuar Parcelamento de Débitos (EfetuarParcelamentoDebitosWizardAction) tem quatro passos; cada botão
# Avançar/Concluir só aponta o formulário da página para a URL do passo seguinte e o envia (util.js botaoAvancar). O roteiro
# faz o mesmo: lê o formulário e a URL do botão de cada página, aplica as escolhas da variação e envia.

PARC_FORM = 'EfetuarParcelamentoDebitosActionForm'


def _url_wizard(html, destino=None, concluir=False):
    """A URL que o botão Avançar (para `destino`) ou Concluir da página enviaria."""
    for m in re.finditer(r"botaoAvancar(?:TelaEspera)?\('/gsan/([^']+)'\)", html):
        u = m.group(1).replace('&amp;', '&')
        if concluir and 'concluir=true' in u:
            return u
        if destino is not None and re.search(r'[?&]destino=' + str(destino) + r'&', u):
            return u
    return None


def _valores_wizard(dados):
    """Os valores que a página mostra no formulário do assistente (memória da negociação), como a tela os escreve."""
    return {k: v for k, v in sorted(dados.items())
            if v not in ('', None) and re.match(r'(valor|desconto|percentual|taxa|numero|indicadorQuantidade|parcela)', k)}


def _linhas_com(html, marca):
    """O texto das linhas de tabela (tr) que contêm `marca` (um rádio da página), sem a marcação."""
    return [texto_visivel(tr) for tr in re.findall(r'(?is)<tr\b[^>]*>((?:(?!<tr\b).)*?' + marca + r'.*?)</tr>', html)]


def _passo_wizard(ctx, html, estado):
    r = {'http': estado}
    recusa = _recusa(html, estado)
    if estado >= 400 or recusa['chaves'] or recusa['mensagem']:
        r.update(recusa)
    return r


def _efetuar_parcelamento(ctx, passo):
    """Efetuar Parcelamento de Débitos pela tela: 1 — o imóvel (matrícula), a data do parcelamento (a do dia, que a tela
    propõe, se a variação não der outra), o intervalo de referências, a resolução de diretoria e as perguntas
    "considerar contas em revisão, guias, acréscimos, débitos a cobrar, créditos" (as respostas da variação; 1 = sim,
    2 = não); 2 — os débitos que a tela lista (como ela os marca, ou EP/NB por referência, como a variação pede); 3 — a
    opção de prestações da variação (com a entrada que a tela propõe, ou a informada pela variação e o Calcular);
    4 — a confirmação; Concluir. De cada passo saem os valores que a tela mostra e a recusa, se houver; o efeito é lido
    do banco (bloco `parcelamento`)."""
    imovel = str(int(passo['imovel']))
    r = {'passos_assistente': []}
    ctx.atual.get('exibirEfetuarParcelamentoDebitosAction.do?menu=sim')
    html = ctx.atual.post('efetuarParcelamentoDebitosWizardAction.do?action=exibirEfetuarParcelamentoDebitosProcesso1Action',
                          {'matriculaImovel': imovel})
    dados = _formulario(html, PARC_FORM)
    p1 = _passo_wizard(ctx, html, ctx.atual.ultimo_estado)
    p1.update(passo=1, valores=_valores_wizard(dados),
              resolucoes=re.findall(r'(?is)<option\b[^>]*value="(\d+)"[^>]*>\s*RD', html),
              situacao_agua=dados.get('situacaoAgua'), situacao_esgoto=dados.get('situacaoEsgoto'))
    r['passos_assistente'].append(p1)
    dados.update(matriculaImovel=imovel, resolucaoDiretoria=str(int(passo['rd'])),
                 inicioIntervaloParcelamento=passo.get('inicio', '01/2000'), fimIntervaloParcelamento=passo.get('fim', '05/2026'))
    if passo.get('data'):  # sem ela, a data que a tela propõe (a do dia)
        dados['dataParcelamento'] = passo['data']
    for k, v in {'indicadorContasRevisao': '2', 'indicadorGuiasPagamento': '1', 'indicadorAcrescimosImpotualidade': '1',
                 'indicadorDebitosACobrar': '1', 'indicadorCreditoARealizar': '1', 'indicadorDividaAtiva': '2'}.items():
        dados[k] = str(passo.get(k, v))
    for numero in (2, 3, 4):
        url = _url_wizard(html, destino=numero)
        if not url:
            r['resultado'] = f'sem_avancar_no_passo_{numero - 1}'
            return r
        html = ctx.atual.post(url, dados)
        estado = ctx.atual.ultimo_estado
        pn = _passo_wizard(ctx, html, estado)
        if 'chaves' in pn or estado >= 400:
            pn['passo'] = numero
            r['passos_assistente'].append(pn)
            r['resultado'] = f'recusado_ao_avancar_para_{numero}'
            return r
        dados = _formulario(html, PARC_FORM)
        pn.update(passo=numero, valores=_valores_wizard(dados))
        if numero == 2:
            pn['contas'] = _linhas_com(html, r'name="indicadorContasDebito\d+"')
            for k, v in (passo.get('contas') or {}).items():  # referência → 1 (EP: a conta é a entrada) ou 2 (NB: pagamento comprovado)
                ids = ctx.sql(f"select cnta_id from faturamento.conta where imov_id = {int(imovel)} and cnta_amreferenciaconta = {int(k)}").split()
                for i in ids:
                    dados[f'indicadorContasDebito{i}'] = str(v)
        elif numero == 3:
            pn['opcoes'] = _linhas_com(html, r'name="indicadorQuantidadeParcelas"')
            if passo.get('entrada') is not None:  # a entrada informada só vale depois do Calcular (a tela recalcula as opções)
                dados['valorEntradaInformado'] = passo['entrada'].replace('.', ',')
                html = ctx.atual.post('efetuarParcelamentoDebitosWizardAction.do?action='
                                      'exibirEfetuarParcelamentoDebitosProcesso3Action&calculaOpcaoParcelamento=1', dados)
                calculo = _passo_wizard(ctx, html, ctx.atual.ultimo_estado)
                dados = _formulario(html, PARC_FORM)
                calculo.update(valores=_valores_wizard(dados), opcoes=_linhas_com(html, r'name="indicadorQuantidadeParcelas"'))
                pn['calculo_entrada'] = calculo
            dados['indicadorQuantidadeParcelas'] = str(int(passo['prestacoes']))
        elif numero == 4:
            dados['indicadorConfirmacaoParcelamento'] = '1'
        r['passos_assistente'].append(pn)
    url = _url_wizard(html, concluir=True)
    if not url:
        r['resultado'] = 'sem_concluir'
        return r
    if passo.get('forjar_conclusao'):  # lote 7c (CAND-44): campos do formulário trocados no POST de conclusão
        r['forjado'] = {k: {'tela': dados.get(k), 'enviado': str(v)} for k, v in sorted(passo['forjar_conclusao'].items())}
        dados.update({k: str(v) for k, v in passo['forjar_conclusao'].items()})
    html = ctx.atual.post(url, dados)
    sucesso = _sucesso(html)
    r.update(http=ctx.atual.ultimo_estado, mensagem=sucesso, resultado='efetuado' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _comandar_acao_cobranca(ctx, passo):
    """Inserir Comando de Ação de Cobrança eventual, por critério da rota (exibirInserirComandoAcaoCobrancaAction →
    exibirInserirComandoAcaoCobrancaEventualCriterioRotaAction → inserirComandoAcaoCobrancaEventualConcluirAction →
    Fachada.concluirComandoAcaoCobranca): a ação, a atividade, o grupo de cobrança, o período de referência e de vencimento
    das contas e o título da variação. Só grava o comando — o processo é outro passo (`processo_cobranca`)."""
    ctx.atual.get('exibirInserirComandoAcaoCobrancaAction.do?menu=sim')
    html = ctx.atual.post('exibirInserirComandoAcaoCobrancaEventualCriterioRotaAction.do?limparForm=OK&menu=sim',
                          {'tipoComando': 'Eventual'})
    form = 'InserirComandoAcaoCobrancaEventualCriterioRotaActionForm'
    dados = _formulario(html, form)
    tela = {'http': ctx.atual.ultimo_estado,
            'acoes': re.findall(r'(?is)<option\b[^>]*value="(\d+)"[^>]*>\s*AVISO', html)}
    if ctx.atual.ultimo_estado >= 400:
        tela.update(_recusa(html, ctx.atual.ultimo_estado))
    dados.update(cobrancaAtividade=str(int(passo.get('atividade', 2))), cobrancaGrupo=str(int(passo.get('grupo', 1))),
                 indicador=str(passo.get('indicador', 'Rota')), periodoInicialConta=passo.get('referencia_inicial', '05/2026'),
                 periodoFinalConta=passo.get('referencia_final', '05/2026'),
                 periodoVencimentoContaInicial=passo.get('vencimento_inicial', '01/01/2026'),
                 periodoVencimentoContaFinal=passo.get('vencimento_final', '10/06/2026'),
                 titulo=passo.get('titulo', 'AVISO SINTETICO'), descricaoSolicitacao=passo.get('descricao', 'COMANDO SINTETICO'))
    for campo in ('cobrancaAcao', 'subcategoria', 'situacaoFiscalizacao'):  # select multiple: sem seleção, o navegador não envia
        dados.pop(campo, None)
    pares = (list(dados.items()) + [('cobrancaAcao', str(int(a))) for a in passo.get('acoes', [1])]
             + [('subcategoria', str(int(s))) for s in passo.get('subcategorias', [])])
    html = ctx.atual.post('inserirComandoAcaoCobrancaEventualConcluirAction.do', pares)
    sucesso = _sucesso(html)
    r = {'tela': tela, 'http': ctx.atual.ultimo_estado, 'mensagem': sucesso, 'resultado': 'comandado' if sucesso else 'recusado'}
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _gerar_resumo_devedores(ctx, passo):
    """Gerar Resumo dos Devedores Duvidosos (exibirGerarResumoDevedoresDuvidososAction → GerarResumoDevedoresDuvidososAction →
    ControladorFinanceiro.gerarResumoDevedoresDuvidosos): a referência contábil da variação (MM/AAAA); a tela insere o processo
    79 com essa referência, e o verificador do Quartz o executa."""
    ctx.atual.get('exibirGerarResumoDevedoresDuvidososAction.do?menu=sim')
    r = {'tela': {'http': ctx.atual.ultimo_estado}}
    html = ctx.atual.post('gerarResumoDevedoresDuvidososAction.do',
                          {'anoMesReferenciaContabil': passo.get('referencia_contabil', '06/2026')})
    sucesso = 'Gerando Resumo dos Devedores Duvidosos' in texto_visivel(html)
    r.update(http=ctx.atual.ultimo_estado, resultado='inserido' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _processo_cobranca(ctx, passo):
    """Inserir Processo de Cobrança Comandado (exibirInserirProcessoCobrancaComandadoAction → InserirProcessoCobrancaComandadoAction
    → ControladorBatchSEJB.inserirProcessoIniciadoCobrancaComandado): os comandos eventuais que a tela lista, pelo último
    comando gravado (o id só navega); o verificador do Quartz executa o processo da atividade."""
    cmd = ctx.sql('select max(cacm_id) from cobranca.cobranca_acao_ativ_cmd') or None
    html = ctx.atual.get('exibirInserirProcessoCobrancaComandadoAction.do?menu=sim')
    listado = bool(cmd) and any(re.search(r'(?i)\bvalue="' + str(int(cmd)) + r'"', t)
                                for t in re.findall(r'(?is)<input\b[^>]*name="idsEventuais"[^>]*>', html))
    r = {'tela': {'http': ctx.atual.ultimo_estado, 'comando_listado': listado}}
    if not listado:
        r['tela'].update(_recusa(html, ctx.atual.ultimo_estado))
        r['resultado'] = 'nao_listado'
        return r
    html = ctx.atual.post('inserirProcessoCobrancaComandadoAction.do', [('idsEventuais', str(int(cmd)))])
    sucesso = _sucesso(html)
    r.update(http=ctx.atual.ultimo_estado, mensagem=sucesso, resultado='inserido' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _desfazer_parcelamento(ctx, passo):
    """Desfazer Parcelamento pela tela: Consultar Parcelamento de Débitos do imóvel (ExibirConsultarParcelamentoDebitoAction
    — a tela só oferece o Desfazer ao parcelamento NORMAL, sem prestação cobrada e com a entrada não paga) e o botão
    Desfazer com o motivo da variação (ExibirDesfazerParcelamentoDebitoAction → Fachada.desfazerParcelamentosDebito).
    O parcelamento é o último NORMAL do imóvel (o id só navega). `forjar`: se a tela não oferece o Desfazer, a URL do botão
    é enviada assim mesmo (o servidor aceita ou não)."""
    imovel = int(passo['imovel'])
    parc = ctx.sql(f"select max(parc_id) from cobranca.parcelamento where imov_id = {imovel} and pcst_id = 1") or None
    if not parc:
        return {'resultado': 'sem_parcelamento_normal'}
    ctx.atual.get('exibirConsultarListaParcelamentoDebitoAction.do?menu=sim')
    html = ctx.atual.get(f'exibirConsultarParcelamentoDebitoAction.do?codigoImovel={imovel}&codigoParcelamento={int(parc)}')
    oferece = 'Desfazer Parcelamento' in html and 'parcelamentoMotivoDesfazer' in html
    tela = {'http': ctx.atual.ultimo_estado, 'oferece_desfazer': oferece,
            'motivos': re.findall(r'(?is)<option[^>]*value="(\d+)"', re.search(r'(?is)<select[^>]*name="parcelamentoMotivoDesfazer".*?</select>', html).group(0)) if re.search(r'(?is)<select[^>]*name="parcelamentoMotivoDesfazer".*?</select>', html) else []}
    if ctx.atual.ultimo_estado >= 400:
        tela.update(_recusa(html, ctx.atual.ultimo_estado))
    r = {'tela': tela}
    if not oferece:
        if not passo.get('forjar'):
            r['resultado'] = 'nao_oferecido'
            return r
        r['forjado'] = True  # o que a tela não deixaria enviar
    html = ctx.atual.get(f'exibirDesfazerParcelamentoDebitoAction.do?codigoParcelamento={int(parc)}&motivo={int(passo["motivo"])}')
    sucesso = _sucesso(html)
    r.update(http=ctx.atual.ultimo_estado, mensagem=sucesso, resultado='desfeito' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


# --- Arrecadação: o pagamento não classificado (lote 6b) ---------------------------------------------------------------
# O pagamento é escolhido pela matrícula, data e valor (o id só serve à navegação e nunca sai no resultado).

def _pagamento_alvo(ctx, passo):
    return ctx.sql(f"select max(pgmt_id) from arrecadacao.pagamento where imov_id = {int(passo['imovel'])}"
                   f" and pgmt_dtpagamento = to_date('{passo.get('data_pagamento', '20260610')}', 'YYYYMMDD')"
                   f" and pgmt_vlpagamento = {Decimal(passo['valor'])}") or None


def _sucesso(html):
    """A mensagem da página de sucesso do legado (o que vem depois do título "Sucesso"), com os números (ids) mascarados."""
    t = texto_visivel(html)
    if not re.search(r'com sucesso|j\S* classificados', t):
        return None
    m = re.search(r'Sucesso\s+(.*?)\s+(?:Menu Principal|Voltar|Inserir outr|Fazer outr|Atualizar |Imprimir )', t)
    return re.sub(r'\d+', '<n>', m.group(1).strip()) if m else 'sucesso'


def _recuperar_credito(ctx, passo):
    """Recuperar Crédito / Pagamentos a Classificar (ExibirFiltrarPagamentosAClassificarAction →
    FiltrarPagamentosAClassificarAction → ClassificarPagamentosAction "Devolver" ou RefaturarPagamentosNaoClassificadosAction
    → ControladorArrecadacao.recuperarCredito): a situação filtrada, o que a lista mostrou e o resultado."""
    alvo = _pagamento_alvo(ctx, passo)
    ctx.atual.get('exibirFiltrarPagamentosAClassificarAction.do?menu=sim')
    html = ctx.atual.post('filtrarPagamentosRecuperacaoDeCreditoAction.do',
                          {'idSituacaoPagamento': str(int(passo['situacao'])), 'referenciaArrecadacao': passo.get('referencia_arrecadacao', '06/2026'),
                           'dataPagamento': '', 'matriculaImovel': ''})
    listados = re.findall(r'(?i)name="idRegistrosClassificacao"\s+value="(\d+)"', html)
    r = {'tela': {'http': ctx.atual.ultimo_estado, 'listados': len(listados), 'alvo_listado': bool(alvo) and str(alvo) in listados,
                  'refaturar_oferecido': 'refaturar(document.forms[0])' in html and 'value="Refaturar"' in html}}
    if not listados:
        r['tela'].update(_recusa(html, ctx.atual.ultimo_estado))
    if not alvo or str(alvo) not in listados:
        r['resultado'] = 'nao_listado'
        return r
    caminho = {'devolver': 'classificarPagamentosAction.do?devolver=1',
               'refaturar': 'refaturarPagamentosNaoClassificadosAction.do?devolver=0'}[passo['acao']]
    html = ctx.atual.post(caminho, {'idRegistrosClassificacao': str(alvo), 'idSituacaoPagamento': str(int(passo['situacao']))})
    sucesso = _sucesso(html)
    r.update(acao=passo['acao'], http=ctx.atual.ultimo_estado, mensagem=sucesso, resultado='concluido' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _manter_pagamento(ctx, passo):
    """Manter Pagamento (ExibirAtualizarPagamentosAction → AtualizarPagamentosAction): a referência (e, se a variação
    pedir, a situação) que o operador corrige; a confirmação que o legado pede é respondida pela variação."""
    alvo = _pagamento_alvo(ctx, passo)
    if not alvo:
        return {'resultado': 'sem_pagamento'}
    html = ctx.atual.get(f'exibirAtualizarPagamentosAction.do?idRegistroAtualizacao={alvo}')
    dados = _formulario(html, 'ManterPagamentoActionForm')
    tela = {'http': ctx.atual.ultimo_estado, 'referencia': dados.get('referenciaConta'), 'valor': dados.get('valorPagamento'),
            'documento': dados.get('idTipoDocumento')}
    r = {'tela': tela}
    if 'referenciaConta' not in dados:
        tela.update(_recusa(html, ctx.atual.ultimo_estado))
        r['resultado'] = 'recusado_na_exibicao'
        return r
    dados['referenciaConta'] = passo['referencia_nova']
    if 'situacao' in passo:
        dados['idSituacaoAtualPagamento'] = str(int(passo['situacao']))
    html = ctx.atual.post('atualizarPagamentosAction.do', dados)
    texto, botoes = _confirmacao(html)
    if texto is not None:
        r.update(confirmacao=texto, resposta=passo.get('confirmar'))
        if passo.get('confirmar') not in botoes:
            r['resultado'] = 'nao_confirmado'
            return r
        html = ctx.atual.post(botoes[passo['confirmar']], dados)
    sucesso = _sucesso(html)
    r.update(http=ctx.atual.ultimo_estado, mensagem=sucesso, resultado='atualizado' if sucesso else 'recusado')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _inserir_guia_devolucao(ctx, passo):
    """Inserir Guia de Devolução (InserirGuiaDevolucaoAction → ControladorArrecadacao.inserirGuiaDevolucao) a partir do RA
    pendente do imóvel, para uma conta (documento CONTA) da referência e no valor da variação."""
    ra = ctx.sql(f"select max(rgat_id) from atendimentopublico.registro_atendimento where imov_id = {int(passo['imovel'])}"
                 " and rgat_cdsituacao = 1")
    ctx.atual.get('exibirInserirGuiaDevolucaoAction.do?menu=sim')
    dados = {'idRegistroAtendimento': ra or '', 'idOrdemServico': '', 'documentoTipo': '1', 'documentoTipoHidden': '1',
             'idLocalidade': '1', 'idLocalidadeHidden': '1', 'idImovel': str(int(passo['imovel'])),
             'referenciaConta': passo['referencia'], 'idGuiaPagamento': '', 'idDebitoACobrar': '', 'idTipoDebito': '',
             'idTipoDebitoHidden': '', 'valorDevolucao': passo['valor'].replace('.', ','), 'idFuncionarioAnalista': '',
             'idFuncionarioAutorizador': ''}
    html = ctx.atual.post('inserirGuiaDevolucaoAction.do', dados)
    texto, botoes = _confirmacao(html)
    r = {'ra_pendente': bool(ra)}
    if texto is not None:
        r.update(confirmacao=texto, resposta=passo.get('confirmar'))
        if passo.get('confirmar') not in botoes:
            r['resultado'] = 'nao_confirmado'
            return r
        html = ctx.atual.post(botoes[passo['confirmar']], dados)
    sucesso = _sucesso(html)
    r.update(http=ctx.atual.ultimo_estado, mensagem=sucesso,
             resultado='inserida' if sucesso else 'recusada')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


def _inserir_devolucao(ctx, passo):
    """Inserir Devoluções (InserirDevolucoesAction): a devolução no aviso bancário do movimento (NSA), com a guia de
    devolução do imóvel, a data, a referência e o valor da variação; a confirmação (valor acima da guia) é respondida pela
    variação."""
    aviso = ctx.sql("select max(a.avbc_id) from arrecadacao.aviso_bancario a join arrecadacao.arrecadador_movimento m using (armv_id)"
                    f" where m.armv_nnnsa = {int(passo.get('nsa', 1))}")
    guia = ctx.sql(f"select max(gdev_id) from arrecadacao.guia_devolucao where imov_id = {int(passo['imovel'])}") or ''
    valor_guia = ctx.sql(f"select gdev_vldevolucao from arrecadacao.guia_devolucao where gdev_id = {int(guia)}") if guia else ''
    ctx.atual.get('exibirInserirDevolucoesAction.do?menu=sim')
    dados = {'avisoBancario': aviso, 'dataDevolucao': passo.get('data', '20/06/2026'), 'valorDevolucao': passo['valor'].replace('.', ','),
             'guiaDevolucao': guia if passo.get('com_guia', True) else '', 'localidade': '1', 'localidadeClone': '1',
             'codigoImovel': str(int(passo['imovel'])), 'codigoImovelClone': str(int(passo['imovel'])),
             'referenciaDevolucao': passo['referencia'], 'referenciaDevolucaoClone': passo['referencia'],
             'valorGuiaDevolucao': (valor_guia or '').replace('.', ',') if passo.get('com_guia', True) else '',
             'tipoDebito': '', 'tipoDebitoClone': ''}
    html = ctx.atual.post('inserirDevolucoesAction.do', dados)
    texto, botoes = _confirmacao(html)
    r = {'com_guia': bool(dados['guiaDevolucao'])}
    if texto is not None:
        r.update(confirmacao=texto, resposta=passo.get('confirmar'))
        if passo.get('confirmar') not in botoes:
            r['resultado'] = 'nao_confirmado'
            return r
        html = ctx.atual.post(botoes[passo['confirmar']], dados)
    sucesso = _sucesso(html)
    r.update(http=ctx.atual.ultimo_estado, mensagem=sucesso,
             resultado='inserida' if sucesso else 'recusada')
    if not sucesso:
        r.update(_recusa(html, ctx.atual.ultimo_estado))
    return r


# --- Arrecadação: encerramento e arquivamento (lote 6c) ----------------------------------------------------------------

def _pagamentos_das_contas(html):
    """O quadro "Pagamentos das Contas" da consulta: cada linha (mês/ano, valor da conta, valor e data do pagamento,
    situações anterior e atual) e se a tela a mostra como HISTÓRICO (a tela pinta de vermelho o pagamento arquivado);
    e os totais atual e histórico que a tela soma."""
    i = html.find('Pagamentos das Contas')
    j = html.find('Pagamentos das Guias de Pagamento', i)
    secao = html[i:j] if i >= 0 else ''
    linhas = []
    for tr in re.findall(r'(?is)<tr\b[^>]*>(.*?)</tr>', secao):
        if '<strong>' in tr.lower():
            continue  # cabeçalhos e totais
        cel = [texto_visivel(c) for c in re.findall(r'(?is)<td\b[^>]*>(.*?)</td>', tr)]
        if len(cel) != 6 or not re.fullmatch(r'\d{2}/\d{4}', cel[0]):
            continue
        linhas.append({'historico': 'ff0000' in tr.lower(), 'referencia': cel[0], 'valor_conta': moeda(cel[1]),
                       'valor_pagamento': moeda(cel[2]), 'data_pagamento': cel[3],
                       'situacao_anterior': cel[4] or None, 'situacao_atual': cel[5] or None})
    totais = {k.lower().replace('ó', 'o'): {'quantidade': int(q.replace('.', '')), 'valor': moeda(v)}
              for k, q, v in re.findall(r'Total (Atual|Hist\S*rico)\s+Qtd -\s+([\d.]+)\s+Valor do Pagamento -\s+(-?[\d.]*\d,\d{2})',
                                        texto_visivel(secao))}
    return linhas, totais


def _consultar_pagamentos(ctx, passo):
    """Consultar Pagamentos do imóvel (exibirFiltrarPagamentoConsultaAction → FiltrarPagamentoAction → ExibirConsultarPagamentoAction,
    UC0255) com a opção "Ambos": os pagamentos atuais e os arquivados, como a tela os mostra a partir do imóvel e da conta.
    O id do pagamento (que muda no arquivamento) só existe no link da tela e nunca sai no resultado."""
    r = {}
    for imovel in passo['imoveis']:
        ctx.atual.get('exibirFiltrarPagamentoConsultaAction.do?menu=sim')
        html = ctx.atual.post('consultarPagamentoAction.do', {'idImovel': str(int(imovel)),
                                                             'opcaoPagamento': passo.get('opcao', 'ambos')})
        linhas, totais = _pagamentos_das_contas(html)
        r[str(int(imovel))] = {'http': ctx.atual.ultimo_estado, 'pagamentos_das_contas': linhas, 'totais': totais,
                               'mensagem': None if linhas or totais else (_mensagem(html) or _atencao(html))}
    return {'consulta': r}


def faturar_grupo(ctx, entrada):
    """Faturar grupo pelo processo comandado (ExibirInserirProcessoFaturamentoComandadoAction →
    InserirProcessoFaturamentoComandadoAction → ControladorBatchSEJB.inserirProcessoIniciadoFaturamentoComandado →
    verificador do Quartz → MDB por rota → ControladorFaturamentoFINAL.faturarGrupoFaturamento), com os passos da variação:
    disparar · aguardar (terminal | ciclo) · observar · autorizar · aplicar (arquivo de massas/passos: a correção de causa
    do lote 5, o pagamento do lote 5d) · reiniciar · retificar · cancelar (manutenção de conta pela tela) ·
    iniciar_processo (processo mensal/eventual, ex.: a prescrição, a classificação de pagamentos) · movimento (envio do
    arquivo do arrecadador pela tela) · aguardar_movimento · consultar_debitos (a posição de dívida pela tela) ·
    recuperar_credito · manter_pagamento · inserir_guia_devolucao · inserir_devolucao (lote 6b) · consultar_pagamentos
    (os pagamentos atuais e arquivados do imóvel pela tela, lote 6c) · colocar_revisao (lote 7) · efetuar_parcelamento
    (o assistente Efetuar Parcelamento de Débitos, lote 7b).
    `detalhes` (opcional): blocos a mais no estado — `lancamentos` (débitos e créditos), `impostos`, `rateio`,
    `micromedicao` (medições e consumos detalhados), `ciclo_conta` (contas pela identidade documental, pagamentos, RA,
    consumos e auditoria), `conta_origem`, `arrecadacao` (movimentos, itens, pagamentos, avisos, devoluções, contrato),
    `devolucao` (guias, devoluções, créditos a realizar), `encerramento` (referências, resumo da arrecadação,
    histórico), `cobranca` (lote 7) e `parcelamento` (lote 7b: parcelamentos, itens, guias, contadores do imóvel)."""
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
            # O comando do passo (consistir, depois faturar, na mesma referência) ou o da entrada.
            alvo = str(int(passo.get('comando', comando)))
            if 'comando' in passo:
                r['comando'] = int(alvo)
            html = ctx.atual.get('exibirInserirProcessoFaturamentoComandadoAction.do?menu=sim')
            listado = any(re.search(r'(?i)\bvalue="' + alvo + r'"', t)
                          for t in re.findall(r'(?is)<input\b[^>]*name="idFaturamentoAtividadeCronograma"[^>]*>', html))
            r['tela'] = {'http': ctx.atual.ultimo_estado, 'comando_listado': listado,
                         'mensagem': None if listado else (_mensagem(html) or _atencao(html))}
            if listado or passo.get('forjar'):
                # Sem o comando na tela, o POST é o que a tela não deixaria enviar: o servidor aceita ou não.
                r['forjado'] = not listado
                html = ctx.atual.post('inserirProcessoFaturamentoComandadoAction.do', {'idFaturamentoAtividadeCronograma': alvo})
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
        elif tipo == 'movimento':
            r.update(_enviar_movimento(ctx, passo))
        elif tipo == 'aguardar_movimento':
            r.update(_aguardar_movimento(ctx, passo))
        elif tipo == 'consultar_debitos':
            r.update(_consultar_debitos(ctx, passo))
        elif tipo == 'recuperar_credito':
            r.update(_recuperar_credito(ctx, passo))
        elif tipo == 'manter_pagamento':
            r.update(_manter_pagamento(ctx, passo))
        elif tipo == 'inserir_guia_devolucao':
            r.update(_inserir_guia_devolucao(ctx, passo))
        elif tipo == 'inserir_devolucao':
            r.update(_inserir_devolucao(ctx, passo))
        elif tipo == 'consultar_pagamentos':
            r.update(_consultar_pagamentos(ctx, passo))
        elif tipo == 'colocar_revisao':
            r.update(_colocar_revisao(ctx, passo))
        elif tipo == 'efetuar_parcelamento':
            r.update(_efetuar_parcelamento(ctx, passo))
        elif tipo == 'desfazer_parcelamento':
            r.update(_desfazer_parcelamento(ctx, passo))
        elif tipo == 'comandar_acao_cobranca':
            r.update(_comandar_acao_cobranca(ctx, passo))
        elif tipo == 'processo_cobranca':
            r.update(_processo_cobranca(ctx, passo))
        elif tipo == 'gerar_resumo_devedores':
            r.update(_gerar_resumo_devedores(ctx, passo))
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
