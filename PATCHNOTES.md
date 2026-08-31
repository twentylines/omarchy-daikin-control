# Patch Notes

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
- Renamed the project/data area to **MAINTENANCE**, removed the privacy banner,
  and moved the external-server manual checklist to a dedicated GitHub page.

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
- Added a three-scope uninstall flow with animated, separately confirmed
  choices for **REMOVE EVERYTHING**, **REMOVE APP + LOGGER**, and **REMOVE
  PLUGIN ONLY**. Full cleanup only removes the plugin-managed local Home
  Assistant container/data and refuses an unmanaged same-named container.
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

The household shutdown control is available only when climate controls and
MasterSwitch are enabled. It targets climate entities that Home Assistant
reports as available, including entities in rooms other than the selected AC.
