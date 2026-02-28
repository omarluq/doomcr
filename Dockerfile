FROM crystallang/crystal:1.19.1

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
COPY vendor/doomgeneric ./vendor/doomgeneric

RUN set -euo pipefail \
  && doom_src_dir="/app/vendor/doomgeneric/doomgeneric" \
  && if [[ ! -f "${doom_src_dir}/Makefile" ]]; then echo "Missing vendored doomgeneric source at ${doom_src_dir}"; exit 1; fi \
  && mkdir -p /app/build/native/obj \
  && src_obj_line="$(sed -n 's/^SRC_DOOM = //p' "${doom_src_dir}/Makefile" | head -n1)" \
  && if [[ -z "${src_obj_line}" ]]; then echo "Failed to parse SRC_DOOM"; exit 1; fi \
  && objs=() \
  && for obj in ${src_obj_line}; do \
      src="${obj%.o}.c"; \
      if [[ "${src}" == "doomgeneric_xlib.c" ]]; then continue; fi; \
      out="/app/build/native/obj/$(basename "${src%.c}.o")"; \
      cc -std=c99 -O2 -DNORMALUNIX -DLINUX -DSNDSERV -D_DEFAULT_SOURCE \
        -I"${doom_src_dir}" \
        -c "${doom_src_dir}/${src}" \
        -o "${out}"; \
      objs+=("${out}"); \
    done \
  && cc -std=c99 -O2 -I"${doom_src_dir}" \
      -c /app/src/native/doomcr_bridge.c \
      -o /app/build/native/obj/doomcr_bridge.o \
  && objs+=("/app/build/native/obj/doomcr_bridge.o") \
  && ar rcs /app/build/native/libdoomgeneric.a "${objs[@]}"

RUN crystal build src/main.cr -o /app/bin/doomcr --release

COPY docker/entrypoint.sh /usr/local/bin/doomcr-entrypoint
RUN chmod +x /usr/local/bin/doomcr-entrypoint

ENV TERM=xterm-256color
ENV DOOM_WAD_DIR=/data/wads
ENV DOOM_WAD_SOURCE=shareware
ENV DOOM_SHAREWARE_URL=https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad

VOLUME ["/data"]

ENTRYPOINT ["doomcr-entrypoint"]
