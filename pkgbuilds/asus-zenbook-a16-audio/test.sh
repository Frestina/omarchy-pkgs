#!/bin/bash

set -euo pipefail

package_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

fail() {
  echo "not ok - $1" >&2
  exit 1
}

source "$package_dir/PKGBUILD"
[[ " ${arch[*]} " == " aarch64 " && " ${groups[*]} " == *" omarchy-platform-qualcomm "* ]] ||
  fail "the package is tagged Qualcomm-only for aarch64"

pkgdir="$scratch/pkg"
(cd "$package_dir" && package)

# Each board name must resolve to the CRD file it stands in for.
root="$scratch/root"
mkdir -p "$root/usr/lib/firmware/qcom/glymur" "$root/usr/share/alsa/ucm2/Qualcomm/glymur"
touch "$root/usr/lib/firmware/qcom/glymur/GLYMUR-CRD-tplg.bin"
touch "$root/usr/share/alsa/ucm2/Qualcomm/glymur/GLYMUR-CRD.conf"
cp -a "$pkgdir/usr" "$root/"

tplg="$root/usr/lib/firmware/qcom/glymur/GLYMUR-ASUS-Zenbook-A16-UX3607OA-tplg.bin"
[[ $(readlink -f "$tplg") == "$root/usr/lib/firmware/qcom/glymur/GLYMUR-CRD-tplg.bin" ]] ||
  fail "the topology links to the CRD topology"
ucm="$root/usr/share/alsa/ucm2/conf.d/glymur/GLYMUR-ASUS-Zenbook-A16-UX3607OA.conf"
[[ $(readlink -f "$ucm") == "$root/usr/share/alsa/ucm2/Qualcomm/glymur/GLYMUR-CRD.conf" ]] ||
  fail "the UCM profile links to the CRD profile"

echo "ok - asus-zenbook-a16-audio"
