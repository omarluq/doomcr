#!/usr/bin/env bash
set -euo pipefail

contains_iwad_arg() {
  local prev=""
  for arg in "$@"; do
    if [[ "${prev}" == "-iwad" ]]; then
      return 0
    fi
    prev="${arg}"
  done
  return 1
}

download_freedoom() {
  local wad_dir="$1"
  local out1="${wad_dir}/freedoom1.wad"
  local out2="${wad_dir}/freedoom2.wad"

  if [[ -f "${out1}" && -f "${out2}" ]]; then
    echo "Using existing Freedoom WAD files in ${wad_dir}" >&2
    echo "${out1}"
    return
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' RETURN

  local api_json zip_url
  api_json="$(curl -fsSL https://api.github.com/repos/freedoom/freedoom/releases/latest)"
  zip_url="$(printf '%s\n' "${api_json}" | sed -n 's/.*"browser_download_url": "\(.*freedoom-[^"]*\.zip\)".*/\1/p' | head -n1)"

  if [[ -z "${zip_url}" ]]; then
    echo "Failed to resolve Freedoom release URL" >&2
    exit 1
  fi

  echo "Downloading Freedoom from ${zip_url}" >&2
  curl -fsSL "${zip_url}" -o "${tmpdir}/freedoom.zip"
  unzip -qo "${tmpdir}/freedoom.zip" "*/freedoom1.wad" "*/freedoom2.wad" -d "${tmpdir}/extract"

  cp "${tmpdir}"/extract/*/freedoom1.wad "${out1}"
  cp "${tmpdir}"/extract/*/freedoom2.wad "${out2}"
  echo "${out1}"
}

download_shareware() {
  local wad_dir="$1"
  local shareware_url="${DOOM_SHAREWARE_URL:-https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad}"
  local out="${wad_dir}/doom1.wad"

  if [[ -f "${out}" ]]; then
    echo "Using existing shareware WAD: ${out}" >&2
    echo "${out}"
    return
  fi

  echo "Downloading shareware DOOM WAD from ${shareware_url}" >&2
  curl -fsSL "${shareware_url}" -o "${out}"
  echo "${out}"
}

main() {
  local wad_dir="${DOOM_WAD_DIR:-/data/wads}"
  mkdir -p "${wad_dir}"

  local -a cmd=(/app/bin/doomcr)

  if contains_iwad_arg "$@"; then
    exec "${cmd[@]}" "$@"
  fi

  if [[ -n "${DOOM_WAD:-}" ]]; then
    cmd+=(-iwad "${DOOM_WAD}")
    exec "${cmd[@]}" "$@"
  fi

  local source="${DOOM_WAD_SOURCE:-shareware}"
  local iwad=""

  case "${source}" in
    shareware)
      iwad="$(download_shareware "${wad_dir}")"
      ;;
    freedoom)
      iwad="$(download_freedoom "${wad_dir}")"
      ;;
    *)
      echo "Unknown DOOM_WAD_SOURCE='${source}' (expected 'shareware' or 'freedoom')" >&2
      exit 1
      ;;
  esac

  cmd+=(-iwad "${iwad}")
  exec "${cmd[@]}" "$@"
}

main "$@"
