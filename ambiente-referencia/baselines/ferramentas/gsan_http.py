"""Cliente HTTP mínimo do GSAN de referência (Struts 1, páginas em ISO-8859-1).

Só biblioteca padrão: roda no contêiner `ferramentas` (rede interna), sem dependência extra.
Cada chamada guarda a resposta crua na lista `respostas` — é evidência da execução, não baseline.
A senha nunca é registrada: o login é gravado sem o corpo da requisição.
"""
import http.cookiejar
import re
import urllib.error
import urllib.parse
import urllib.request

CODIFICACAO = 'iso-8859-1'


class Sessao:
    def __init__(self, base):
        self.base = base.rstrip('/')
        self.jar = http.cookiejar.CookieJar()
        self.abridor = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.jar))
        self.respostas = []

    def _pedir(self, caminho, dados=None, registrar_corpo=True, cabecalhos=None):
        url = f'{self.base}/{caminho.lstrip("/")}'
        corpo = None
        if dados is not None:
            corpo = urllib.parse.urlencode(dados, encoding=CODIFICACAO).encode('ascii')
        pedido = urllib.request.Request(url, data=corpo, headers=cabecalhos or {})
        # Erro HTTP (ex.: 500 do legado) é resultado observável, não falha do roteiro.
        try:
            with self.abridor.open(pedido, timeout=300) as r:
                texto = r.read().decode(CODIFICACAO)
                estado = r.status
                self.cabecalhos = r.headers
        except urllib.error.HTTPError as e:
            texto = e.read().decode(CODIFICACAO, errors='replace')
            estado = e.code
            self.cabecalhos = e.headers
        self.ultimo_estado = estado
        self.respostas.append({
            'metodo': 'POST' if dados is not None else 'GET', 'caminho': caminho,
            'parametros': (dados if registrar_corpo else '(omitido)') if dados is not None else None,
            'estado': estado, 'html': texto,
            'set_cookie': self.cabecalhos.get_all('Set-Cookie') or [] if self.cabecalhos else [],
        })
        return texto

    def get(self, caminho):
        return self._pedir(caminho)

    def post(self, caminho, dados, registrar_corpo=True, cabecalhos=None):
        return self._pedir(caminho, dados, registrar_corpo=registrar_corpo, cabecalhos=cabecalhos)

    def tentar_login(self, login, senha):
        """Uma tentativa de login, sem registrar o corpo (a senha). Devolve o HTML da resposta."""
        return self._pedir('efetuarLoginAction.do', {'login': login, 'senha': senha}, registrar_corpo=False)

    def entrar(self, login, senha):
        self.get('carregarParametrosAction.do')
        pagina = self._pedir('efetuarLoginAction.do', {'login': login, 'senha': senha}, registrar_corpo=False)
        if 'efetuarLogoffAction' not in pagina:
            raise RuntimeError('login recusado pelo GSAN de referência')
        return pagina


def texto_visivel(html):
    """Texto sem marcação, espaços colapsados — para mensagens de erro e comparação estável."""
    html = re.sub(r'(?is)<(script|style)\b.*?</\1>', ' ', html)
    html = re.sub(r'(?s)<!--.*?-->', ' ', html)
    t = re.sub(r'<[^>]+>', ' ', html)
    t = (t.replace('&nbsp;', ' ').replace('&aacute;', 'á').replace('&Aacute;', 'Á').replace('&atilde;', 'ã')
         .replace('&ccedil;', 'ç').replace('&eacute;', 'é').replace('&ecirc;', 'ê').replace('&iacute;', 'í')
         .replace('&oacute;', 'ó').replace('&otilde;', 'õ').replace('&uacute;', 'ú').replace('&amp;', '&'))
    return re.sub(r'\s+', ' ', t).strip()


def valor_campo(html, nome):
    """Valor de <input name="nome" value="..."> (atributos em qualquer ordem)."""
    for m in re.finditer(r'<input\b[^>]*>', html, re.I):
        tag = m.group(0)
        if re.search(r'\bname\s*=\s*"' + re.escape(nome) + r'"', tag, re.I):
            v = re.search(r'\bvalue\s*=\s*"([^"]*)"', tag, re.I)
            return v.group(1) if v else ''
    return None


def moeda(texto):
    """'1.234,56' → '1234.56' (texto decimal exato; nunca float). Vazio → None."""
    texto = texto.strip()
    if not texto:
        return None
    if not re.fullmatch(r'-?[\d.]*\d,\d{2}', texto):
        raise ValueError(f'valor monetário fora do formato do legado: {texto!r}')
    return texto.replace('.', '').replace(',', '.')
