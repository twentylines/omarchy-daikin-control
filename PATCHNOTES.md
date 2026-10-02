# Patch Notes

## 0.3.5c

- Pinned the optional local Home Assistant container to an immutable official
  image digest instead of the mutable `stable` tag.
- Documented the review and validation process for updating that image pin.

## 0.3.5b

- Fixed every AC mode glyph (cool, heat, dry, fan, and auto) so its painted
  bounds are optically centred in the hero tile and climate-controls header.
- Preserved the shell's baseline-safe optical renderer in the menu bar and
  checked the surrounding panel spacing for related alignment regressions.

## 0.3.5a

- Improved chart-range and external-history refresh performance.
- Fixed the chart-range UI copy so the selected window is clear at a glance,
  for example, `READINGS FROM THE LAST 24 HOURS`.

## 0.3.5

- Moved the live latency dot beside the SSH read value and replaced the old
  leading indicator with a quiet separator.
- Reused a short-lived SSH connection for recurring history reads, so the
  displayed SSH read time no longer pays a fresh handshake on every refresh.
- Clarified that SSH READ measures the complete remote history-file read, not
  the PC's network ping.

## 0.3.4

- Fixed the external chart header so `STALE` appears once, the selected-range
  explanation stays accent-coloured, and stale data uses a warning colour.
- Repaired keyboard shortcuts by routing Hyprland binds directly to the
  running shell IPC target; opening the panel and settings now works without
  the unreliable global-shortcut bridge.
- Fixed stale external history diagnostics: the panel now labels the measured
  value as SSH read time, uses 150 ms for a warning and over 500 ms for red,
  and keeps the chart's last logged window visible while the remote logger is
