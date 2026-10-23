# Changes from Omarchy defaults

## Dynamic GPU memory

The factory configuration reserves 48 GiB of the 64 GiB unified-memory pool as
fixed VRAM, leaving Linux about 16 GiB of ordinary RAM. The installer uses the
kernel's AMD UMA carveout interface to select the 512 MiB minimum for the next
boot, then installs `z13-gpu-memory.conf` for Limine with:

```text
ttm.pages_limit=12582912 amdgpu.gttsize=49152
```

That permits `amdgpu` to allocate up to 48 GiB of GPU-accessible system memory
on demand while keeping nearly all memory CPU-visible when the GPU is idle.
Both the firmware carveout change and kernel arguments require a reboot.

## Internal display scale

`install.sh` replaces Omarchy's untouched `"auto"` monitor scale with `1.6`.
The 2560x1600 13.4-inch panel otherwise resolves to scale 2 on this machine.
The installer leaves any numeric value alone, including values selected later
with Omarchy's scaling shortcuts.

## ALC294 audio routing

Omarchy installs `api.alsa.soft-mixer = true` broadly on ASUS ROG hardware.
The GZ302EA uses an ALC294 codec. With the soft mixer active, PipeWire does not
manage the codec's hardware Speaker and Headphone switches, so jack switching
can leave the selected route muted. `install.sh` moves that override aside and
restarts WirePlumber/PipeWire.

## HDMI audio

`home/.config/wireplumber/wireplumber.conf.d/hdmi-audio-autoactivate.conf`
enables WirePlumber's automatic profile and port selection for the AMD HDMI
audio controller. The installer also removes a stale saved `off` profile for
the controller when one exists.

## Fixes intentionally omitted

Linux 7.2 and Omarchy 4.0.6 on this machine already provide:

- native MT7925 Wi-Fi and ASPM behavior;
- `SW_TABLET_MODE` from `asus-wmi`;
- the GZ302 touchpad integration udev rule;
- native CS35L41 amplifier binding and firmware loading;
- `asusctl`/`asusd` platform-profile and keyboard-light control.

Older Z13 setup scripts duplicate or counteract those implementations, so this
repo does not install their Wi-Fi ASPM, tablet polling, `hid_asus` reload, or
CS35L41 soft-dependency workarounds.
