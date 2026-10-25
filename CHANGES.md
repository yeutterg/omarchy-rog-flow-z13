# Changes from Omarchy defaults

## Quiet idle power profiles

The ASUS daemon previously selected Performance whenever external power was
connected. At an idle temperature near 48°C that profile held the CPU around
3.9 GHz, drew roughly 19–21 W at the APU, and kept the CPU/GPU fans near
3,900/4,300 RPM even with both displays in DPMS sleep. A controlled comparison
showed Balanced dropping the APU to roughly 12–16 W and both fans to 0 RPM
within six seconds, while still allowing normal boost under load.

`configure-power-profiles` therefore persists Balanced on AC and Quiet on
battery through `asusctl`. It uses the firmware profiles rather than installing
custom fan curves.

## Mac-style Control-click

The touchpad filter already observes the detachable keyboard's modifier state
for palm rejection. When either Control key is held as the physical touchpad
button is pressed, it now emits `BTN_RIGHT` from the virtual touchpad instead
of `BTN_LEFT`. The choice is latched until release, avoiding stuck buttons if
Control is released first. Doing this before Hyprland receives the event keeps
normal pointer focus and works on application windows and shell layer surfaces.

The filtered touch surface retains the kernel `INPUT_PROP_BUTTONPAD` marker so
libinput applies the correct clickpad thumb/index tracking during a physical
drag. Mapped left, right and middle clicks are emitted through a companion
virtual pointer instead of the touch surface. This keeps libinput from
replacing Control-click with its own finger-count decision while button state
still combines normally at the Wayland seat. The filter maps one-, two- and
three-finger physical presses to left, right and middle itself; tap-to-click
remains handled by libinput.

`SECONDARY_CLICK_MODE=control-only` is available for a personal systemd
override. It makes every unmodified physical press a primary click while
retaining Control-click; the hardware layer's default remains `finger-count`.

## Windows Hello-style face unlock

The GZ302EA exposes a normal ASUS 5 MP camera at `/dev/video0` and a separate
greyscale IR camera at `/dev/video2`, but no fingerprint reader. When Biopass
is installed, `install.sh` installs the dedicated `omarchy-lock-biopass` PAM
service used by the personal Omarchy lock-screen plugin. It does not add face
authentication to `sudo`, polkit, SDDM, or the system-wide PAM stack, and the
normal password remains available in parallel.

The IR sensor works as a standard greyscale UVC stream. On this unit it emits
alternating illuminated and black synchronization frames as soon as `/dev/video2`
is streamed, so no firmware-risking UVC control probe is needed. After guided
IR enrollment, the personal Biopass configuration uses that sensor as its
primary camera for recognition in darkness and retains local software
anti-spoofing. Biopass's separate IR field is then disabled because upstream
implements it as presence-only and would try to open the same sensor twice.

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

The clickpad firmware can relabel a fingertip as a palm when physical pressure
is applied near its bottom edge. The filter now treats the mechanical button
press as confirmation that the selected contact is intentional, keeps it
visible for the rest of that contact, and reports it to libinput as a finger.
This preserves pointer motion throughout a physical click-and-drag without
loosening palm rejection for ordinary unclicked contacts.

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
