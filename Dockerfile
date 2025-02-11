# syntax=docker/dockerfile:1.4

########## tini ##########################
# prepare tini binary (used as default entrypoint)
FROM ubuntu:jammy as tini
LABEL org.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images

ENV TINI_VERSION=v0.19.0
# Options added via tini README.md suggestion
# https://github.com/krallin/tini#building-tini
ENV CFLAGS="-DPR_SET_CHILD_SUBREAPER=36 -DPR_GET_CHILD_SUBREAPER=37"

RUN <<EOT
#!/usr/bin/env bash
set -exu
apt-get update
apt-get install --yes --no-install-recommends \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  golang \
  make \
  tar
update-ca-certificates
curl -L https://github.com/krallin/tini/archive/refs/tags/$TINI_VERSION.tar.gz -o tini-$TINI_VERSION.tar.gz
tar -xf tini-$TINI_VERSION.tar.gz
# Compile tini from source to ensure compatability with the m1 architectures
cd tini-$(echo $TINI_VERSION | cut -c2-)
cmake .
make
# Ensure tini runs
./tini-static --version
mv ./tini-static /tini
EOT


########## core image ##########################
FROM ubuntu:jammy as core
LABEL com.opencontainers.image.authors="djbender"
LABEL org.opencontainers.image.source=https://github.com/djbender/docker-base-images
ENV DEBIAN_FRONTEND=noninteractive

# Create a 'docker' user
RUN <<EOT
#!/usr/bin/env bash
set -exu
apt-get update
apt-get install --yes --no-install-recommends \
  ca-certificates \
  locales

# create docker user
addgroup --gid 9999 docker
adduser --uid 9999 --gid 9999 --disabled-password --gecos "Docker User" docker
usermod -L docker

update-ca-certificates
# See the Locals heading at https://hub.docker.com/_/ubuntu
# Alias created as some languages (such as ruby) require the extra local
localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/*
EOT

# Ensure UTF-8 locale
ENV LANG en_US.utf-8
ENV LANGUAGE en_US:en

# Install Tini for init use (reaps defunct processes and forwards signals)
COPY --from=tini /tini /tini

# Switch to the 'docker' user
USER docker

# always use tini
ENTRYPOINT ["/tini", "--"]

# keep backwards compatability with use cases that assume CMD is 'bash' since
# specifying an ENTRYPOINT always clears the CMD that was inheritted by the FROM image
# ref: https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
CMD ["bash"]
