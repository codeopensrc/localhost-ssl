FROM nginx:stable-alpine

RUN apk add --no-cache openssl \
 && printf "%s\n" "." "." "." "." "." "." "a@b.c" | openssl req \
        -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
        -out /etc/ssl/localhost.crt \
        -keyout /etc/ssl/localhost.key

ARG PROXY_TO_ADDRESS=172.17.0.1
ARG PROXY_TO_PORT=80
ARG PROXY_TO_FULL_ADDRESS=${PROXY_TO_ADDRESS}:${PROXY_TO_PORT}

ADD nginx.conf.template /etc/nginx/templates/nginx.conf.template

RUN sed -i "s/PROXY_TO_ADDRESS/$PROXY_TO_FULL_ADDRESS/" /etc/nginx/templates/nginx.conf.template \
 && echo $PROXY_TO_FULL_ADDRESS
