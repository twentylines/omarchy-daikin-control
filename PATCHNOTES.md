# Patch Notes

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
  unavailable.
- Fixed customisation layering so the real popup outline remains visible and
  follows the configured accent; the optional outer-border switch still hides
  it completely when disabled.
- Made Global Tab navigation a true opt-in: disabling it restores every focus
  flag, prevents Qt from walking the panel's controls, and returns Tab to
  normal panel switching until the switch is enabled again.
- Reserved a scrollbar gutter in Config File Mode so the JSON editor's
  top-right border is continuous.

## 0.3.3

- Fixed stale external charts so the last available logged window remains
  visible, with a clear stale indicator instead of a blank graph.
- Added a separate Home Assistant port pill beside the hostname/IP field;
  http:// is the default while HTTPS and reverse-proxy paths remain supported.
- Kept the popup outline visible through Compact UI, made it follow the
  configured accent, and added a separate outer-border switch.
- Made Global Tab navigation a hard opt-in, tightened the config editor border,
  simplified the Settings button, and marked latency above 500 ms red.

## 0.3.2

- Added a visible `VERSION 0.3.2` marker to the Settings header so the
  installed build can be identified directly in the plugin.
- Updated the live chart range badge to show the selected duration directly
  (`24 H`, `6 H`, and so on), removing the stale `PAST` wording and duplicate
  unit suffix.
- In Config File Mode, the panel's settings control now displays the current
  remappable Open Settings shortcut and its tooltip reports whether that
  shortcut is active. Clicking it still opens Settings directly.
- Made Global Tab navigation own the ordinary settings focus chain when it is
  enabled, while Config File Mode keeps its dedicated editor order.
- Kept focus inside confirmation flows after activation: MasterSwitch and
  shared split actions select their confirmation action, Reset selects RESET
  NOW, and uninstall scope confirmations stay in their selected branch.

## 0.3.1

- Pushed customisation through every plugin button: selected tabs, choices,
  swatches, action controls, text, fills, and borders now use the configured
  instance accent instead of Omarchy's foreground-selected fallback.
- Wired the actual `KeyboardPanel` outer border to customisation and removed
  the duplicate inset border that caused broken-looking rounded corners.
  Panel card borders now follow the configured accent as well.
- Made Compact UI denser with tighter panel/card padding, settings navigation,
  colour editors, dropdown rows, and appearance spacing while retaining safe
  wrapping for descriptions.
- Made Global Tab navigation genuinely opt-in: disabled mode no longer changes
  panels or lets focused ordinary settings fields traverse with Tab. Config
  File Mode remains the intentional exception with its own editor/apply/reload
  order.

## 0.3.0

- Fixed Config File Mode so its redacted JSON loads automatically, Ctrl+S and
  Ctrl+Enter send a compact valid payload, and Esc returns to AC Controls.
- Added reliable arrow/page navigation, mouse-wheel scrolling, and an
  interactive scrollbar to the config editor, plus the Settings shortcut hint;
  held cursor movement now follows the editor to the exact top or bottom.
- Added the optional global Tab/Shift+Tab focus mode under Experimental.
- Applied custom background and control colours through the outer panel and
  shared controls, including dropdowns, sliders, switches, and action buttons.
- Guarded both MasterSwitch directions so a cancel/reversal only targets the
  devices whose original state the bulk action changed.
- Made the ambient chart use the selected rolling window ending now: choosing
  X H displays the past X hours, reports an empty selected range accurately,
  and identifies a stale external logger instead of making the readings look
  deleted. Kept the chart range badge compact (for example, `24 H`).

## 2.6.2

- Keep a newly typed external-server address as a draft until **CONNECT TO
  SERVER** or **INSTALL / UPDATE TIMER** succeeds, so entering an IP no longer
  collapses the form or starts a connection attempt after the first character.

## 2.6.1

- Rebuilt the external-server guide around one idempotent setup path with an
  explicit Omarchy SSH-agent setup and copy/paste troubleshooting.
- External SSH now recognizes the standard per-user agent sockets when the
  GUI process does not inherit a terminal `SSH_AUTH_SOCK`.
- Reconnect remains non-destructive and no longer depends on the local Home
  Assistant token; SSH failures now explain the relevant agent or target fix.

## 2.6.0

- Added optional multi-AC controls with selected entities, synced or separate
  remotes, and compact bar temperature choices.
- Added per-device colour controls, automatic accent colours, keyboard
  shortcuts, and a dedicated Customisation section.
- Refined power feedback, temperature history presentation, settings
  navigation, and the external-history documentation.
- Added a compact README gallery with complete single-AC and multi-AC home
  screen examples.
- Gallery examples use the fuller external-server history; local history no
  longer shows a live indicator beside the chart range.
- Added a non-destructive external-server reconnect action, separate from
  installing or updating the server timer, plus same-address reconnects that
  can reuse the saved Home Assistant token.

## 2.5.1

- Renamed the settings section to **MAINTENANCE** and removed the privacy
  banner so the section reads as practical app maintenance.
- Moved the external-server manual checklist to a dedicated GitHub page and
  removed **COPY GUIDE**; **COPY SOURCE** remains available for script review.

## 2.5.0

- Added a three-scope uninstall flow with the same animated expansion language
  as the reset action. Each scope has its own removal notice and a separate
  confirmation step: **REMOVE EVERYTHING**, **REMOVE APP + LOGGER**, or
  **REMOVE PLUGIN ONLY**.
- Full cleanup can remove the plugin-managed local Home Assistant
  container/data when present, while refusing an unmanaged same-named
  container. Docker, its image, and unrelated containers remain untouched.
- Added reviewable local and external cleanup scripts and made custom external
  history paths persist correctly in the server logger.

## 2.4.0

- Added optional **EXTERNAL SERVER** temperature history through SSH and a
  user systemd timer, so the chart can keep recording while this PC sleeps,
  shuts down, or restarts. The external server must be the same host that runs
  Home Assistant.
- Added an explicit Local / EXTERNAL SERVER history source selector. The chart
  labels the selected source and never mixes local and external logs.
- Added a transparent installer, a dedicated GitHub manual guide, a **COPY
  SOURCE** action, and a **HOME ASSISTANT SETTINGS** quick link.
  The installer is user-owned and does not use sudo, install packages, open
  ports, send telemetry, or call Home Assistant control endpoints.
- Reworked Settings into a compact universal-width panel with universal back
  navigation and focused `SETUP`, `PREFERENCES`, and `MAINTENANCE` tabs.

## 2.3.0

- Redesigned the temperature history chart with a padded plot area, clearer
  temperature labels, and readable time labels across a full 24-hour range.
- The chart now shows a smaller date marker only when the timeline crosses into
  another day.
- Reworded the chart disclaimer to explain that readings are saved locally and
  recording pauses while the PC sleeps.
- Made the panel surface opaque so controls stay readable over bright windows.
- Standardized UI motion across settings, confirmations, control sections, and
  dropdowns, with a smoother splash when opening Settings and returning to AC Controls.
- Added an optional MasterSwitch setting with matching turn-on and turn-off
  controls for every available climate device.
- Added a neutral confirmation step before the local Home Assistant setup
  script runs, plus a clearer manual guide action.
- Moved the basic mode and fan-speed choices under the clearer Climate Controls
  name, with climate controls enabled by default during onboarding.

## 2.2.0

- Added a single inline `SURE?` confirmation button to turn off every
  available Home Assistant `climate.*` entity in the household.
- Added a result message showing how many climate devices received the
  turn-off request.
- Added automatic mode-change recovery by turning the AC back on after a
  Cool, Heat, Dry, Auto, or Fan mode change.
- Added a visible `RESTARTING AC…` state while the AC returns to its selected
  mode.
- Improved temperature history chart spacing, padding, and label placement.
