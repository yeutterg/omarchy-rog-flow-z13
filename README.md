# Omarchy config for the ROG Flow Z13

Desktop-oriented configuration for the 2025 ASUS ROG Flow Z13 running
Omarchy 4. It currently verifies and supports the `GZ302EA` hardware in this
machine; other Z13 generations and GZ302 variants should be added only after
their device details are checked.

The model code stays inside the installer as a safety check, while the repo name
uses the recognizable product family.

## What it configures

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

Clone and run the hardware layer:

```bash
git clone https://github.com/yeutterg/omarchy-rog-flow-z13 ~/dotfiles/omarchy-rog-flow-z13
~/dotfiles/omarchy-rog-flow-z13/install.sh
```

The installer verifies the DMI product name, backs up any real file it
replaces as `<file>.pre-z13`, links the repo's `home/` tree into `$HOME`, and
restarts the user audio services when available. Pass `--force` only when
testing on different hardware.

The generic `omarchy-tablet` and Dell Latitude 7350 repositories are separate
optional layers and are not installed by this repo.
