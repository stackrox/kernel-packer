FROM alpine:3.9

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
 && apk add --no-cache --update \
    bash \
    coreutils \
    dpkg \
    lbzip2 \
    multipath-tools \
    pigz \
    rpm \
    tar

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
