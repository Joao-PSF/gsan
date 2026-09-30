# Ferramentas do ambiente de referência: obtenção das migrações, aplicação no
# banco, rotação de credenciais e verificação. Não faz parte do GSAN.
ARG IMG_ALPINE
FROM ${IMG_ALPINE}
RUN apk add --no-cache bash coreutils curl findutils git grep openssl postgresql-client python3 sed
WORKDIR /referencia
