#!/bin/bash

# Install the machine-specific layer for the ASUS ROG Flow Z13 GZ302EA.
# Safe to re-run. Real files replaced by links are preserved as .pre-z13.

set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
force=${1:-}
product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)

if [[ $product != *GZ302EA* && $force != --force ]]; then
  echo "This doesn't look like a ROG Flow Z13 GZ302EA (${product:-unknown})."
  echo "Rerun with --force only if you intend to test this hardware layer elsewhere."
  exit 1
fi

backup_path() {
  local source=$1 backup="$1.pre-z13"
  if [[ -e $backup || -L $backup ]]; then
    backup="$backup.$(date +%s)"
  fi
  mv "$source" "$backup"
  echo "Moved existing $source to $backup"
}

link_tree() {
  local rel target
  while IFS= read -r -d '' rel; do
    rel=${rel#./}
    target=$HOME/$rel
    mkdir -p "$(dirname "$target")"

    if [[ -e $target && ! -L $target ]]; then
      backup_path "$target"
    fi

    ln -sfn "$repo/home/$rel" "$target"
    echo "Linked $target"
  done < <(cd "$repo/home" && find . -type f -print0)
}

set_monitor_scale() {
  local config=$HOME/.config/hypr/monitors.lua
  [[ -f $config ]] || return 0

  if grep -q '^local omarchy_monitor_scale = "auto"' "$config"; then
    cp "$config" "$config.pre-z13"
    sed -i 's/^local omarchy_monitor_scale = "auto"/local omarchy_monitor_scale = 1.6/' "$config"
    echo "Set the internal display's default scale to 1.6"
  else
    echo "Kept the existing numeric monitor scale"
  fi
}

fix_alc294_routing() {
  local soft_mixer=$HOME/.config/wireplumber/wireplumber.conf.d/alsa-soft-mixer.conf
  local profile_state=$HOME/.local/state/wireplumber/default-profile

  if [[ -e $soft_mixer || -L $soft_mixer ]]; then
    backup_path "$soft_mixer"
    echo "Disabled the ASUS soft-mixer override for the Z13's ALC294 codec"
  fi

  if [[ -f $profile_state ]] && grep -q 'alsa_card.pci-0000_c4_00.1=off' "$profile_state"; then
    sed -i '/alsa_card.pci-0000_c4_00.1=off/d' "$profile_state"
    echo "Cleared the saved off profile for AMD HDMI audio"
  fi

  systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null || true
}

configure_gpu_memory() {
  local helper=$repo/scripts/configure-gpu-memory
  if [[ $product != *GZ302EA* ]]; then
    echo "Skipped GZ302EA-specific GPU-memory configuration"
    return 0
  fi
  if ((EUID == 0)); then
    "$helper"
  else
    sudo "$helper"
  fi
}

link_tree
set_monitor_scale
fix_alc294_routing
configure_gpu_memory

echo "Done. Hyprland reloads the monitor config automatically; reboot to apply GPU-memory changes."
