# Changes from Omarchy defaults

## Behavioral palm rejection and native Spotify touch

The Z13 touchpad reports position and a firmware palm label but does not expose
pressure or contact-size axes. Native libinput palm detection therefore has
less information than it receives from richer touchpads, while its
disable-while-typing mode introduces a noticeable fixed pause.

`z13-palm-filter` uses typing cadence, landing position, firmware labels, and
movement instead. Suspicious contacts are promoted as soon as deliberate
motion crosses a small distance, so the pointer does not wait on a timer.
Stationary contacts followed by another keystroke are swallowed, and paired
contacts are promoted together for two-finger scrolling. The physical device
is grabbed only while the service is healthy; if it exits, the grab is
released and the original touchpad resumes.

Spotify defaults to XWayland on this system even though its Chromium runtime
contains native Wayland touch support. `spotify-flags.conf` selects the Wayland
backend and its fractional-scale/window-decoration features. This keeps touch
native instead of globally converting the touchscreen to mouse input, which
would discard multitouch and interfere with applications that already handle
touch correctly.

The ELAN touchscreen is also explicitly bound to `eDP-1`. Hyprland otherwise
falls back to the currently focused monitor for an unbound touch device, so a
touch on the built-in panel can be routed to an external display whenever an
external application has keyboard focus. The explicit binding fixes all apps
on the internal panel rather than adding an application-specific click replay.

## Media-first function row

The detachable keyboard defaults to F1-F12 on an unmodified key press. The
installer sends the ASUS HID Fn-lock feature report to reverse that immediately
and adds `asus_wmi.fnlock_default=N` to the Limine kernel command line so the
choice survives reboot and keyboard reconnection. Brightness, volume, and the
other printed media actions are the default; hold Fn for F1-F12.

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
