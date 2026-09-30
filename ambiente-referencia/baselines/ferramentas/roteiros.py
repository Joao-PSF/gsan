"""Roteiros: a operação do GSAN executada por um cenário, pelas telas do próprio legado.

Um roteiro recebe a sessão autenticada e a entrada da variação e devolve o que a operação mostrou,
já extraído do HTML (dinheiro como texto decimal exato). Não escreve no banco por conta própria: o
estado só muda pelo que a operação do GSAN fizer.
"""
import re

from gsan_http import moeda, texto_visivel, valor_campo


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


ROTEIROS = {
    'simular_calculo_conta': simular_calculo_conta,
    'consultar_imovel_dados_cadastrais': consultar_imovel_dados_cadastrais,
}
