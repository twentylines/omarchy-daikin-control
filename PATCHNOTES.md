# Patch Notes

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

The household shutdown control is available only when Advanced Controls are
enabled. It targets climate entities that Home Assistant reports as available,
including entities in rooms other than the selected AC.
