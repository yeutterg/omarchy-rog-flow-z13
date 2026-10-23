# Omarchy config for the ROG Flow Z13 GZ302EA

Machine-specific configuration for the 2025 ASUS ROG Flow Z13
(`GZ302EA`) running Omarchy 4.

This repo is the hardware layer on top of
[omarchy-tablet](https://github.com/yeutterg/omarchy-tablet). The tablet repo
owns portable detachable/tablet behavior; this repo contains only details tied
to the Z13 hardware.

## What it configures

- Identifies `GZ302EA-Keyboard Touchpad` as the detachable keyboard signal for
  the on-screen keyboard plugin. This makes attached/detached state correct at
  login, before the kernel tablet-mode switch changes for the first time.
- Changes Omarchy's automatic internal-display scale to `1.6` on first install.
  Omarchy's normal display-scaling shortcuts can change it afterward.
- Removes Omarchy's broad ASUS `alsa-soft-mixer.conf` override. The Z13 uses an
  ALC294 codec, and the software-only mixer prevents PipeWire from managing the
  speaker/headphone hardware switches during jack detection.
- Enables automatic profiles and ports for the AMD HDMI audio controller, so
  an attached display appears as an audio output.

Current Omarchy and Linux releases already provide the Z13 touchpad udev rule,
native MT7925 Wi-Fi support, tablet-mode events, and CS35L41 amplifier support.
This repo deliberately does not carry the old module and daemon workarounds for
those components.

## Install

Install the shared tablet layer first, then this hardware layer:

```bash
git clone https://github.com/yeutterg/omarchy-tablet ~/dotfiles/omarchy-tablet
~/dotfiles/omarchy-tablet/install.sh

git clone https://github.com/yeutterg/omarchy-rog-flow-z13-gz302ea ~/dotfiles/omarchy-rog-flow-z13-gz302ea
~/dotfiles/omarchy-rog-flow-z13-gz302ea/install.sh
```

The installer verifies the DMI product name, backs up any real file it
replaces as `<file>.pre-z13`, links the repo's `home/` tree into `$HOME`, and
restarts the user audio services when available. Pass `--force` only when
testing on different hardware.

Log out and back in once after installing `omarchy-tablet` so the input-method
environment and fcitx5 service override take effect.

## Relationship to other repos

- `omarchy-tablet`: shared tablet and detachable behavior
- `omarchy-on-screen-keyboard`: touch keyboard
- `omarchy-display-rotation`: rotation UI and accelerometer support
- `omarchy-lock-pin`: optional lock-screen PIN pad
- `omarchy-tray-touch`: touch-friendly system tray
- `omarchy-wifi-filter`: filter and forget actions in the Wi-Fi panel

The Dell Latitude 7350 configuration is intentionally separate and should not
be installed on this machine.
