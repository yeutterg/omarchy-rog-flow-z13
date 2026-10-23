# Changes from Omarchy defaults

## Windows Hello-style face unlock

The GZ302EA exposes a normal ASUS 5 MP camera at `/dev/video0` and a separate
greyscale IR camera at `/dev/video2`, but no fingerprint reader. When Biopass
is installed, `install.sh` installs the dedicated `omarchy-lock-biopass` PAM
service used by the personal Omarchy lock-screen plugin. It does not add face
authentication to `sudo`, polkit, SDDM, or the system-wide PAM stack, and the
normal password remains available in parallel.

The IR sensor is not enabled by default: its emitter does not activate under
Linux, and the available UVC auto-prober warns that probing unknown controls
can corrupt camera firmware. The working setup uses the RGB camera with local
software anti-spoofing.

## Battery charge ceiling

The installer sets the ASUS firmware-backed charge limit to 80% through
`asusctl`. This avoids long periods at 100% while docked, while
`scripts/configure-battery-care --full` provides a one-shot full charge for
travel and then returns to the saved ceiling. No periodic forced discharge is
scheduled: deep cycling adds wear rather than conditioning a lithium battery.

## Behavioral palm rejection

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

Generic touchscreen-to-display mapping and Spotify's native Wayland flags now
live in `omarchy-touchscreen`, which this repo installs as a dependency. This
repo retains only the Z13-specific touchpad behavior.

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
