-- Machine-specific input behavior for the ROG Flow Z13 GZ302EA.

-- The behavioral filter rejects palms without libinput's post-key timeout.
hl.config({
  input = {
    touchpad = {
      disable_while_typing = false,
    },
    -- Without an explicit output Hyprland maps touch to the focused monitor,
    -- which makes the built-in panel stop working when an external is focused.
    touchdevice = {
      output = "eDP-1",
    },
  },
})

-- Preserve the fast, accelerating motion profile on both the physical pad
-- (used if the filter is stopped) and its filtered virtual replacement.
for _, name in ipairs({
  "asustek-computer-inc.-gz302ea-keyboard-touchpad",
  "asustek-computer-inc.-gz302ea-keyboard-touchpad-(palm-filter)",
}) do
  hl.device({
    name = name,
    sensitivity = 0.55,
    accel_profile = "adaptive",
  })
end
