FROM debian:buster

# Add bullseye as a secondary APT source
RUN echo 'deb http://deb.debian.org/debian bullseye main' >> /etc/apt/sources.list.d/bullseye.list
RUN echo 'APT::Default-Release "buster";' > /etc/apt/apt.conf.d/30default

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
      jq   \
 ;

# Install 'rpm' 4.16 with its dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      rpm=4.16.1.2+dfsg1-3 \
      librpm9=4.16.1.2+dfsg1-3 \
      librpmbuild9=4.16.1.2+dfsg1-3 \
      librpmio9=4.16.1.2+dfsg1-3 \
      librpmsign9=4.16.1.2+dfsg1-3 \
      debugedit=4.16.1.2+dfsg1-3 \
      rpm-common=4.16.1.2+dfsg1-3 \
      rpm2cpio=4.16.1.2+dfsg1-3 \
      libdw1=0.183-1 \
      libelf1=0.183-1 \
      libzstd1=1.4.8+dfsg-2.1 \
      libselinux1=3.1-3 \
      libelf-dev=0.183-1 \
 ;

COPY includes /etc/includes

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
