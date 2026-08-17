#!/usr/bin/env bash
set -euo pipefail

root_dir="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
branding_dir="${root_dir}/assets/branding"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

command -v rsvg-convert >/dev/null || {
  printf 'rsvg-convert is required\n' >&2
  exit 1
}
command -v convert >/dev/null || {
  printf 'ImageMagick convert is required\n' >&2
  exit 1
}

render() {
  local source="$1"
  local size="$2"
  local destination="$3"
  mkdir -p "$(dirname "${destination}")"
  rsvg-convert -w "${size}" -h "${size}" "${source}" -o "${destination}"
}

app_source="${branding_dir}/app_icon.svg"
tray_source="${branding_dir}/tray_icon.svg"

render "${app_source}" 512 "${root_dir}/linux/runner/resources/app_icon.png"
render "${tray_source}" 32 "${root_dir}/assets/tray/icon.png"

render "${app_source}" 256 "${tmp_dir}/app_icon.png"
convert "${tmp_dir}/app_icon.png" \
  -define icon:auto-resize=256,128,64,48,32,24,16 \
  "${root_dir}/windows/runner/resources/app_icon.ico"

render "${tray_source}" 64 "${tmp_dir}/tray_icon.png"
convert "${tmp_dir}/tray_icon.png" \
  -define icon:auto-resize=64,48,32,24,16 \
  "${root_dir}/assets/tray/icon.ico"

for density_and_size in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  density="${density_and_size%%:*}"
  size="${density_and_size##*:}"
  render "${app_source}" "${size}" \
    "${root_dir}/android/app/src/main/res/mipmap-${density}/ic_launcher.png"
done
