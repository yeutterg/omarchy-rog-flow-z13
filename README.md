# Omarchy config for the ASUS ROG Flow Z13

Hardware-specific display and audio configuration for the 2025 ASUS ROG Flow
Z13 on Omarchy.

## Compatibility

The installer currently accepts DMI product names containing `GZ302EA`, the
model on which these settings were verified. The broader repository name makes
room for other Flow Z13 generations, but each model should be checked before it
is added to the installer allowlist.

Verified with:

- ASUS ROG Flow Z13 GZ302EA
- Omarchy 4.0.6
- Linux 7.2

## What it configures

| Area | Change |
|---|---|
| Internal display | Changes Omarchy's untouched automatic scale to `1.6` on first install. Later choices made with Omarchy's display-scaling controls are preserved. |
| Analog audio | Removes Omarchy's broad ASUS software-mixer override so WirePlumber can manage the ALC294 speaker and headphone switches during jack detection. |
| HDMI audio | Enables automatic profiles and ports for the AMD HDMI audio controller so an attached display appears as an output. |

Current Omarchy and Linux releases already provide the touchpad udev rule,
MT7925 Wi-Fi support, tablet-mode events, CS35L41 amplifier support, and ASUS
platform controls needed by this model. This repository does not duplicate
those implementations, and it does not install tablet-mode UI or an on-screen
keyboard.

## Install

```bash
git clone https://github.com/yeutterg/omarchy-rog-flow-z13 ~/dotfiles/omarchy-rog-flow-z13
~/dotfiles/omarchy-rog-flow-z13/install.sh
```

The installer:

1. verifies the DMI product name;
2. preserves replaced regular files as `<file>.pre-z13`;
3. links the tracked WirePlumber configuration into `$HOME`;
4. updates the untouched automatic display scale; and
5. restarts the user audio services when they are available.

It is safe to rerun. Pass `--force` only when deliberately testing the layer on
different hardware.

## Updating

```bash
git -C ~/dotfiles/omarchy-rog-flow-z13 pull --ff-only
~/dotfiles/omarchy-rog-flow-z13/install.sh
```

See [CHANGES.md](CHANGES.md) for the reason behind each setting and the
upstream behavior that may eventually make it unnecessary.
