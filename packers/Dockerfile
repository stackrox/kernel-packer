FROM debian:buster

RUN apt-get update \
 && apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      binutils \
      make \
      gcc \
      gcc-7-plugin-dev \
      gcc-8-plugin-dev \
      gcc-8 \
      libelf-dev \
      libc6-dev \
      bc \
      coreutils \
      dpkg \
      lbzip2 \
      multipath-tools \
      pigz \
      rpm \
      tar \
      ca-certificates \
      golang \
      rsync \
      libssl-dev \
      git \
      libtool \
      build-essential \
      wget \
      python \
      python3 \
      unzip \
      bison \
      flex \
      zstd \
      curl \
 ;


COPY packers/includes /etc/includes

COPY packers/entrypoint /usr/bin/entrypoint

COPY . /go/src/github.com/stackrox/kernel-packer

RUN mkdir -p /go/src/github.com/stackrox/kernel-packer/

ENTRYPOINT ["/usr/bin/entrypoint"]
