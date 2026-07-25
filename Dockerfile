FROM crystallang/crystal:v1.21.0

SHELL ["/bin/bash", "-lc"]

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY shard.yml shard.lock ./
RUN shards install

COPY src ./src
COPY libdoomgeneric.a ./

RUN crystal build src/main.cr -o /app/bin/doomcr --release

COPY docker/entrypoint.sh /usr/local/bin/doomcr-entrypoint
RUN chmod +x /usr/local/bin/doomcr-entrypoint

ENV TERM=xterm-256color
ENV DOOM_WAD_DIR=/data/wads
ENV DOOM_WAD_SOURCE=shareware
ENV DOOM_SHAREWARE_URL=https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad

VOLUME ["/data"]

ENTRYPOINT ["doomcr-entrypoint"]
