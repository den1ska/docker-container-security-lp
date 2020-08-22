FROM alpine:3.11

ENV HUGO_VERSION=0.74.3
ENV HUGO_HOME=/opt/hugo

ARG HUGO_SHA256=269482fff497051a7919da213efa29c7f59c000e51cf14c1d207ecf98d87bf33
ARG HUGO_URL=https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz


RUN apk add --no-cache \
  curl \
  git \
  openssh-client \
  rsync

RUN set -o errexit -o nounset \
  && addgroup -Sg 1000 hugo \
  && adduser -SG hugo -u 1000 -h /src hugo
  

SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN set -o errexit -o nounset \
  && echo "Downloading Hugo" \
  && curl --fail --location --silent --show-error --output hugo.tar.gz "$HUGO_URL" \
  && echo "Verifying checksum" \
  && echo "$HUGO_SHA256 *hugo.tar.gz" | sha256sum -c - \
  && echo "Installing Hugo" \
  && mkdir -p "$HUGO_HOME" \
  && tar -xf hugo.tar.gz -C "$HUGO_HOME" \
  && rm hugo.tar.gz \
  && ln -s "$HUGO_HOME/hugo" /usr/bin/hugo \
  && echo "Verifying installation" \
  && hugo version

USER hugo

WORKDIR /src

EXPOSE 1313

LABEL MAINTAINER=psellars@gmail.com

HEALTHCHECK CMD curl --fail http://localhost:1313 || exit 1

