# syntax=docker/dockerfile:1.4

FROM ubuntu:jammy as core

RUN <<EOT
#!/usr/bin/env bash
set -exu
apt-get update
apt-get install --yes --no-install-recommends libc6
EOT
