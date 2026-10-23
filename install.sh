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

install_touchscreen_layer() {
  local touchscreen_repo=${OMARCHY_TOUCHSCREEN_DIR:-$(dirname "$repo")/omarchy-touchscreen}
  if [[ ! -x $touchscreen_repo/install.sh ]]; then
    git clone https://github.com/yeutterg/omarchy-touchscreen "$touchscreen_repo"
  fi
  "$touchscreen_repo/install.sh"
}

backup_path() {
  local source=$1 backup="$1.pre-z13"
  if [[ -e $backup || -L $backup ]]; then
    backup="$backup.$(date +%s)"
  fi
  mv "$source" "$backup"
  echo "Moved existing $source to $backup"
}

as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
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

ensure_hypr_extras_loader() {
  local config=$HOME/.config/hypr/hyprland.lua
  local loader='for file in io.popen("find -L ~/.config/hypr/extras -maxdepth 1 -type f -name '\''*.lua'\'' 2>/dev/null | sort"):lines() do dofile(file) end'
  [[ -f $config ]] || return 0
  grep -qF "$loader" "$config" && return 0

  local block="
-- Drop-in files from hardware and tablet layers, loaded in name order.
$loader"
  if grep -q '^require("default.hypr.toggles")' "$config"; then
    BLOCK=$block awk '{ print } /^require\("default\.hypr\.toggles"\)/ { print ENVIRON["BLOCK"] }' "$config" >"$config.tmp"
    mv "$config.tmp" "$config"
  else
    printf '%s\n' "$block" >>"$config"
  fi
  echo "Added the Hyprland extras loader to $config"
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

configure_function_row() {
  local helper=$repo/scripts/configure-function-row
  if [[ $product != *GZ302EA* ]]; then
    echo "Skipped GZ302EA-specific function-row configuration"
    return 0
  fi
  if ((EUID == 0)); then
    "$helper" --defer-boot-update
  else
    sudo "$helper" --defer-boot-update
  fi
}

configure_palm_filter() {
  if [[ $product != *GZ302EA* ]]; then
    echo "Skipped GZ302EA-specific palm filter"
    return 0
  fi

  if ! pacman -Q python-evdev >/dev/null 2>&1; then
    as_root pacman -S --needed --noconfirm python-evdev
  fi

  as_root install -Dm755 "$repo/scripts/z13-palm-filter" /usr/local/libexec/z13-palm-filter
  as_root install -Dm644 \
    "$repo/system/etc/systemd/system/z13-palm-filter.service" \
    /etc/systemd/system/z13-palm-filter.service
  as_root systemctl daemon-reload
  as_root systemctl enable --now z13-palm-filter.service
}

configure_face_unlock_pam() {
  local pam_module=/usr/lib/security/libbiopass_pam.so
  local pam_source=$repo/system/etc/pam.d/omarchy-lock-biopass

  if [[ ! -f $pam_module ]]; then
    echo "Skipped face-unlock PAM service because Biopass is not installed"
    return 0
  fi

  as_root install -Dm644 "$pam_source" /etc/pam.d/omarchy-lock-biopass
  echo "Installed the lock-screen-only Biopass PAM service"
}

configure_battery_care() {
  if [[ $product != *GZ302EA* ]]; then
    echo "Skipped GZ302EA-specific battery-care configuration"
    return 0
  fi
  "$repo/scripts/configure-battery-care"
}

install_touchscreen_layer
link_tree
ensure_hypr_extras_loader
set_monitor_scale
fix_alc294_routing
configure_palm_filter
configure_face_unlock_pam
configure_battery_care
configure_function_row
configure_gpu_memory

echo "Done. Restart Spotify to use native Wayland touch; reboot to apply persistent hardware defaults and GPU-memory changes."
