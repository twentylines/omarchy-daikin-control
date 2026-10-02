import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "sai.homeassistant-ac"
  ipcTarget: "sai.homeassistant-ac"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string pluginVersion: "0.3.5c"
  readonly property string githubUrl: "https://github.com/twentylines/omarchy-daikin-control"
  readonly property string externalHistoryGuideUrl:
    root.githubUrl + "/blob/main/EXTERNAL_SERVER_HISTORY.md"
  readonly property string homeAssistantLinuxGuideUrl: "https://www.home-assistant.io/installation/linux/"
  readonly property string localServerUrl: "http://127.0.0.1:8123"
  readonly property string remoteHistoryDefaultUrl: "http://127.0.0.1:8123"
  readonly property string remoteHistoryDefaultPath: "~/.local/state/omarchy/homeassistant-ac-temperature.json"
  readonly property string pluginDir: {
    var u = String(Qt.resolvedUrl("."))
    if (u.indexOf("file://") === 0) u = u.slice(7)
    if (u.length > 1 && u.charAt(u.length - 1) === "/") u = u.slice(0, u.length - 1)
    return u
  }
  readonly property string helperPath: root.pluginDir + "/omarchy-homeassistant-ac"
  readonly property string localServerScriptPath: root.pluginDir + "/setup-homeassistant.sh"
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color warning: "#D0A66A"
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  property var unitReadings: []
  property var selectedEntities: []
  property bool multiUnitEnabled: false
  property bool multiUnitEnabledPrevious: false
  property bool globalSyncControls: true
  property bool globalSyncControlsPrevious: true
  property bool syncNonPowerControls: true
  property bool syncNonPowerControlsPrevious: true
  property bool averageTemperatureDecimals: false
  property bool averageTemperatureDecimalsPrevious: false
  property string temperatureUnitPreference: "source"
  property string temperatureUnitPreferencePrevious: "source"
  property string barTemperatureMode: "average"
  property string barTemperatureModePrevious: "average"
  property var barTemperatureEntities: []
  property var barTemperatureEntitiesPrevious: []
  property bool experimentalHistoryEnabled: false
  property bool experimentalHistoryEnabledPrevious: false
  readonly property var shortcutDefaults: ({
    open_panel: { key: "SUPER+ALT+A", enabled: true },
    toggle_power: { key: "SUPER+ALT+P", enabled: true },
    open_settings: { key: "SUPER+ALT+SHIFT+U", enabled: true },
    settings_previous: { key: "SUPER+CTRL+ALT+LEFT", enabled: true },
    settings_next: { key: "SUPER+CTRL+ALT+RIGHT", enabled: true },
    refresh: { key: "SUPER+ALT+R", enabled: true },
    settings_back: { key: "ESC", enabled: true },
  })
  readonly property var shortcutDefinitions: [
    { id: "open_panel", label: "OPEN PANEL", description: "Show the AC panel from anywhere.", scope: "GLOBAL" },
    { id: "toggle_power", label: "TOGGLE AC POWER", description: "Toggle the main AC power state.", scope: "GLOBAL" },
    { id: "open_settings", label: "OPEN SETTINGS", description: "Open this panel directly on its settings view.", scope: "GLOBAL" },
    { id: "settings_previous", label: "PREVIOUS SETTINGS PANE", description: "Move to the previous settings pane.", scope: "GLOBAL" },
    { id: "settings_next", label: "NEXT SETTINGS PANE", description: "Move to the next settings pane.", scope: "GLOBAL" },
    { id: "refresh", label: "REFRESH STATUS", description: "Refresh the Home Assistant status.", scope: "GLOBAL" },
    { id: "settings_back", label: "BACK TO AC CONTROLS", description: "Return from settings. Esc is the default.", scope: "PANEL" },
  ]
  property bool shortcutsEnabled: false
  property bool shortcutsEnabledPrevious: false
  readonly property string openSettingsShortcutDisplay:
    root.shortcutDisplay(root.shortcutValue("open_settings"))
