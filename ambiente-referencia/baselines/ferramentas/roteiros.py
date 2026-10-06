"""Roteiros: a operação do GSAN executada por um cenário, pelas telas do próprio legado.

Um roteiro recebe a sessão autenticada e a entrada da variação e devolve o que a operação mostrou,
já extraído do HTML (dinheiro como texto decimal exato). Não escreve no banco por conta própria: o
estado só muda pelo que a operação do GSAN fizer.
"""
import base64
import io
import json
import re
import secrets
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
}
