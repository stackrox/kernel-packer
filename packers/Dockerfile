FROM debian:unstable

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install --no-install-recommends -y \
      binutils \
      make \
      gcc \
      libelf-dev \
      bc \
      coreutils \
      dpkg \
      lbzip2 \
      multipath-tools \
      pigz \
      rpm \
      tar \
 ;


COPY includes /etc/includes

COPY entrypoint /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
