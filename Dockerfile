# syntax=docker/dockerfile:1.4

########## tini ##########################
# prepare tini binary (used as default entrypoint)
FROM ubuntu:jammy as core
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
  libc6
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
