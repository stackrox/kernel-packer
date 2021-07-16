FROM ubuntu:xenial

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install --no-install-recommends -y \
      binutils \
      make \
      gcc \
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
      unzip \
      bison \
      flex \
      software-properties-common \
 ;

RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test \
&& apt update -qq \
&& apt install -yq gcc-7 gcc-8-plugin-dev \
;

COPY includes /etc/includes

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
