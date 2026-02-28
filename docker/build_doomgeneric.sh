#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

doom_src_dir="${DOOM_SRC_DIR:-${repo_root}/vendor/doomgeneric/doomgeneric}"
bridge_src="${BRIDGE_SRC:-${repo_root}/src/native/doomcr_bridge.c}"
build_dir="${DOOM_BUILD_DIR:-${repo_root}/build/native}"
output_lib="${DOOM_OUTPUT_LIB:-${repo_root}/libdoomgeneric.a}"

if [[ ! -f "${doom_src_dir}/Makefile" ]]; then
  echo "Missing vendored doomgeneric source at ${doom_src_dir}" >&2
  exit 1
fi

mkdir -p "${build_dir}/obj" "$(dirname "${output_lib}")"

src_obj_line="$(sed -n 's/^SRC_DOOM = //p' "${doom_src_dir}/Makefile" | head -n1)"
if [[ -z "${src_obj_line}" ]]; then
  echo "Failed to parse SRC_DOOM" >&2
  exit 1
fi

objs=()
for obj in ${src_obj_line}; do
  src="${obj%.o}.c"
  if [[ "${src}" == "doomgeneric_xlib.c" ]]; then
    continue
  fi

  out="${build_dir}/obj/$(basename "${src%.c}.o")"
  cc -std=c99 -O2 -DNORMALUNIX -DLINUX -DSNDSERV -D_DEFAULT_SOURCE \
    -I"${doom_src_dir}" \
    -c "${doom_src_dir}/${src}" \
    -o "${out}"
  objs+=("${out}")
done

cc -std=c99 -O2 -I"${doom_src_dir}" \
  -c "${bridge_src}" \
  -o "${build_dir}/obj/doomcr_bridge.o"
objs+=("${build_dir}/obj/doomcr_bridge.o")

ar rcs "${output_lib}" "${objs[@]}"

echo "Built ${output_lib}"
