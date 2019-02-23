FROM alpine:3.8

RUN apk add --no-cache \
    bash \
    pigz \
    rpm

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
