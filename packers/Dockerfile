FROM alpine:3.10

#RUN apt-get update \
# && apt-get upgrade -y \
# && apt-get install --no-install-recommends -y \
#      binutils \
#      make \
#      gcc \
#      gcc-8-plugin-dev \
#      libelf-dev \
#      libc6-dev \
#      bc \
#      coreutils \
#      dpkg \
#      lbzip2 \
#      multipath-tools \
#      pigz \
#      rpm \
#      tar \
#      ca-certificates \
#      golang \
#      rsync \
#      libssl-dev \
#      git \
#      libtool \
#      build-essential \
#      wget \
#      python \
#      unzip \
#      bison \
#      flex \
# ;

RUN apk add --no-cache --update wget ca-certificates \
    build-base gcc abuild binutils \
    bc \
    cmake \
    rpm \
    dpkg \
    git \
    bash \
    elfutils-dev \
    elfutils-libelf \
    linux-headers \
    openssl-dev \
    autoconf kmod pigz clang llvm8

RUN gcc -v
COPY includes /etc/includes

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
