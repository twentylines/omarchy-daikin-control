# Patch Notes

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
