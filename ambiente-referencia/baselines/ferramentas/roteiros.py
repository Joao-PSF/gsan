"""Roteiros: a operação do GSAN executada por um cenário, pelas telas do próprio legado.

Um roteiro recebe a sessão autenticada e a entrada da variação e devolve o que a operação mostrou,
já extraído do HTML (dinheiro como texto decimal exato). Não escreve no banco por conta própria: o
estado só muda pelo que a operação do GSAN fizer.
"""
import base64
import io
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
    if not linhas or not totais:
        return {'resultado': 'recusado', 'mensagem': texto_visivel(html)[-600:]}
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
        'situacao_agua': valor_campo(html, 'situacaoAguaDadosCadastrais'),
        'situacao_esgoto': valor_campo(html, 'situacaoEsgotoDadosCadastrais'),
        'perfil': valor_campo(html, 'imovelPerfilDadosCadastrais'),
        'composicao': composicao,
        'total_economias_exibido': int(total.group(1)) if total else None,
    }


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
                     resultado=('erro_http' if ctx.atual.ultimo_estado >= 400 else
                                'tela_principal' if 'efetuarLogoffAction' in html else
                                'alterar_senha' if 'novaSenha' in html else
                                'tela_login' if 'efetuarLoginAction' in html else 'outra'),
                     mensagem=_mensagem(html))
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
                r['mensagem'] = _mensagem(html)
            r['set_cookie_sessao'] = any('JSESSIONID' in c for c in ctx.atual.respostas[-1].get('set_cookie', []))
        elif tipo == 'trocar_senha':
            ctx.atual.get('exibirEfetuarAlteracaoSenhaSimplificadaAction.do')
            nova = ctx.senha(login, passo['nova'])
            html = ctx.atual.post('efetuarAlteracaoSenhaSimplificadaAction.do', {
                'senha': ctx.senha(login, 'correta'), 'novaSenha': nova, 'confirmacaoNovaSenha': nova,
                'lembreteSenha': 'LEMBRETE SINTETICO'}, registrar_corpo=False)
            sucesso = 'Senha alterada com sucesso' in texto_visivel(html)
            if sucesso:
                ctx.trocou(login, passo['nova'])
            r.update(usuario=login, http=ctx.atual.ultimo_estado, sucesso=sucesso,
                     mensagem=None if sucesso else _mensagem(html))
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
    'seguranca': seguranca,
}
