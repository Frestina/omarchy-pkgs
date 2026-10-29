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
ucm="$root/usr/share/alsa/ucm2/conf.d/glymur/ASUSTeKCOMPUTERINC.-ZenbookA16UX3607OA-1.0-UX3607OA.conf"
[[ $(readlink -f "$ucm") == "$root/usr/share/alsa/ucm2/Qualcomm/glymur/GLYMUR-CRD.conf" ]] ||
  fail "the UCM profile links to the CRD profile"

rules="$pkgdir/usr/lib/udev/rules.d/60-asus-zenbook-a16-soundwire.rules"
[[ -f $rules ]] || fail "the SoundWire udev rule is installed"
grep -q 'ATTR{\[dmi/id\]board_name}=="UX3607OA"' "$rules" ||
  fail "the SoundWire udev rule only applies to the Zenbook A16"
grep -q 'KERNEL=="6c80000.soundwire|6ca0000.soundwire"' "$rules" ||
  fail "the SoundWire udev rule covers both WSA controllers"
grep -q 'ATTR{power/control}="on"' "$rules" ||
  fail "the SoundWire udev rule keeps the controllers awake"
if command -v udevadm >/dev/null; then
  udevadm verify --no-style "$rules" >/dev/null 2>&1 || fail "the SoundWire udev rule parses"
fi

wp="$pkgdir/usr/share/wireplumber/wireplumber.conf.d/60-asus-zenbook-a16-soft-volume.conf"
[[ -f $wp ]] || fail "the WirePlumber soft-volume rule is installed"
grep -q 'api.alsa.card.longname = "ASUSTeKCOMPUTERINC.-ZenbookA16UX3607OA-1.0-UX3607OA"' "$wp" ||
  fail "the soft-volume rule only applies to the Zenbook A16's card"
grep -q 'api.alsa.soft-mixer = true' "$wp" || fail "the soft-volume rule switches to software volume"

echo "ok - asus-zenbook-a16-audio"
