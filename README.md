# Omarchy config for the ASUS ROG Flow Z13

Hardware-specific display, audio, input, battery, and memory configuration for
the 2025 ASUS ROG Flow Z13 on Omarchy.

This layer installs
[omarchy-touchscreen](https://github.com/yeutterg/omarchy-touchscreen) for
generic touchscreen behavior. It does not install `omarchy-tablet`, so a Z13
used as a desktop does not inherit the on-screen keyboard, mobile controls or
tablet window gestures.

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
| Unified memory | Reduces fixed VRAM to 512 MiB and gives `amdgpu` a 48 GiB on-demand GTT pool, leaving almost all 64 GiB visible to Linux when the GPU is idle. |
| Function row | Makes brightness, volume, and other media actions work without Fn; hold Fn for F1-F12. |
| Touchpad | Replaces the fixed disable-while-typing pause with movement-based palm rejection that preserves deliberate motion and two-finger scrolling; Control-click emits a secondary click. |
| Touchscreen | Installs the shared touchscreen layer, which maps touch to the built-in display and runs Spotify through native Wayland. |
| Battery care | Keeps the persistent charge ceiling at 80%; supports a one-shot 100% charge for travel. |
| Face unlock | Installs a lock-screen-only PAM service for Biopass when its module is present. The Z13 has a Windows Hello-style IR camera but no fingerprint reader; enrollment and the Omarchy UI live in the private personal layer. |

Current Omarchy and Linux releases already provide the base touchpad udev rule,
MT7925 Wi-Fi support, tablet-mode events, CS35L41 amplifier support, and ASUS
platform controls needed by this model. This repository adds a behavioral
filter because the touchpad does not expose contact pressure or size. It does
not install tablet-mode UI or an on-screen keyboard.

## Install

```bash
git clone https://github.com/yeutterg/omarchy-rog-flow-z13 ~/dotfiles/omarchy-rog-flow-z13
~/dotfiles/omarchy-rog-flow-z13/install.sh
```

The installer:

1. verifies the DMI product name;
2. preserves replaced regular files as `<file>.pre-z13`;
3. installs the shared `omarchy-touchscreen` layer;
4. links the tracked user configuration into `$HOME` and enables Hyprland's
   sorted hardware drop-ins;
5. updates the untouched automatic display scale;
6. restarts the user audio services when they are available;
7. makes the detachable keyboard's function row media-first;
8. installs and starts the Z13 palm-filter service;
9. installs the lock-screen-only Biopass PAM service when Biopass is present;
10. sets the ASUS battery charge ceiling to 80%; and
11. configures the AMD UMA carveout and Limine kernel arguments for dynamic GPU
   memory.

It is safe to rerun. Pass `--force` only when deliberately testing the layer on
different hardware. System-level changes require `sudo`; the function-row and
palm-filter changes apply immediately. Restart Spotify for native touch
support. The persistent function-row default and memory change take effect
after a reboot.

## Battery care

The installer uses the Z13's firmware-backed `asusctl` control to set an 80%
charge ceiling. It persists through reboots and avoids keeping the battery at
100% while the machine is docked. Lithium batteries do not benefit from
scheduled deep-discharge cycles, so none are automated.

For a trip, request one full charge without replacing the saved 80% ceiling:

```bash
~/dotfiles/omarchy-rog-flow-z13/scripts/configure-battery-care --full
```

To choose a different persistent ceiling, pass it directly (20–100), then run
the installer later to return to the recommended default:

```bash
~/dotfiles/omarchy-rog-flow-z13/scripts/configure-battery-care 70
```

## Palm-filter tuning

The filter keeps normal touchpad behavior except around typing. A contact that
begins while typing is withheld until it moves 5 mm; another keystroke instead
confirms it as a palm. Recent central touches need 3 mm of movement, and recent
edge touches need 5 mm. There is no fixed post-typing wait. Holding either
Control key while physically clicking the touchpad changes that click to a
right-click before Hyprland receives it.

Classification decisions are available without recording key codes:

```bash
journalctl -u z13-palm-filter.service -f
```

The thresholds are environment values in
`system/etc/systemd/system/z13-palm-filter.service`. Re-run `install.sh` after
changing them.

## Updating

```bash
git -C ~/dotfiles/omarchy-rog-flow-z13 pull --ff-only
~/dotfiles/omarchy-rog-flow-z13/install.sh
```

See [CHANGES.md](CHANGES.md) for the reason behind each setting and the
upstream behavior that may eventually make it unnecessary.
