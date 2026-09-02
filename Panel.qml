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
  readonly property string pluginVersion: "0.3.5a"
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
  readonly property bool openSettingsShortcutActive: root.shortcutsEnabled
    && root.shortcutEnabled("open_settings")
  property bool globalTabNavigationEnabled: false
  property bool globalTabNavigationEnabledPrevious: false
  property var globalTabFocusOverrides: []
  property string globalTabFocusOverrideMode: ""
  property bool configFileModeEnabled: false
  property bool configFileModeEnabledPrevious: false
  property string configFileText: ""
  property string configFilePayload: ""
  property string configFileStatus: ""
  property string configFileError: ""
  property bool configFileEditorSyncing: false
  property bool configFileBusy: false
  property var shortcutValues: ({
    open_panel: { key: "SUPER+ALT+A", enabled: true },
    toggle_power: { key: "SUPER+ALT+P", enabled: true },
    open_settings: { key: "SUPER+ALT+SHIFT+U", enabled: true },
    settings_previous: { key: "SUPER+CTRL+ALT+LEFT", enabled: true },
    settings_next: { key: "SUPER+CTRL+ALT+RIGHT", enabled: true },
    refresh: { key: "SUPER+ALT+R", enabled: true },
    settings_back: { key: "ESC", enabled: true },
  })
  property var shortcutValuesPrevious: ({})
  property string shortcutCaptureId: ""
  readonly property bool shortcutCaptureActive: shortcutCaptureId !== ""
  property bool customAppearanceEnabled: false
  property bool customAppearanceEnabledPrevious: false
  property bool appearanceAutoAccent: true
  property bool appearanceAutoAccentPrevious: true
  property bool appearanceAutoBackground: true
  property bool appearanceAutoBackgroundPrevious: true
  property color customAccentColor: "#8FA79F"
  property color customAccentColorPrevious: "#8FA79F"
  property string customAccentHexText: "#8FA79F"
  property string customAccentHexTextPrevious: "#8FA79F"
  property color customControlColor: "#8FA79F"
  property color customControlColorPrevious: "#8FA79F"
  property string customControlHexText: "#8FA79F"
  property string customControlHexTextPrevious: "#8FA79F"
  property color customBackgroundColor: "#131516"
  property color customBackgroundColorPrevious: "#131516"
  property string customBackgroundHexText: "#131516"
  property string customBackgroundHexTextPrevious: "#131516"
  property bool appearanceDeviceColorsEnabled: false
  property bool appearanceDeviceColorsEnabledPrevious: false
  property var appearanceDeviceColors: ({})
  property var appearanceDeviceColorsPrevious: ({})
  property real appearanceTransparency: 0
  property real appearanceTransparencyPrevious: 0
  property string appearanceTransparencyText: "0"
  property real appearanceBlur: 0
  property real appearanceBlurPrevious: 0
  property string appearanceBlurText: "0"
  property real appearanceRadius: 16
  property real appearanceRadiusPrevious: 16
  property string appearanceRadiusText: "16"
  property bool compactUiEnabled: false
  property bool compactUiEnabledPrevious: false
  property bool appearanceOuterBorderEnabled: true
  property bool appearanceOuterBorderEnabledPrevious: true
  readonly property color accentColor: customAppearanceEnabled && !appearanceAutoAccent
    ? customAccentColor : Color.accent
  // The control colour drives switches, sliders, fields, and dropdowns. Action
  // buttons and card accents use accentColor. It falls back to Omarchy whenever
  // custom appearance is inactive.
  readonly property color interactionAccentColor: customAppearanceEnabled && !appearanceAutoAccent
    ? customControlColor : Color.accent
  readonly property color controlAccentColor: interactionAccentColor
  readonly property color appearanceBackgroundColor: customAppearanceEnabled && !appearanceAutoBackground
    ? customBackgroundColor : Color.popups.background
  readonly property color appearancePopupBorderColor: customAppearanceEnabled
    ? root.alpha(root.controlAccentColor, 0.52) : Color.popups.border
  // KeyboardPanel paints its own card outside the plugin content. Supplying
  // this spec is what makes the real outer popup border follow customisation;
  // an inner BorderSurface alone cannot replace the stock card border.
  readonly property var panelBorderSpec: !root.appearanceOuterBorderEnabled
    ? Border.none()
    : root.customAppearanceEnabled
      ? Border.flat(root.alpha(root.accentColor, 0.72), Math.max(1, Style.space(1)))
      : Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
  readonly property real appearanceSurfaceOpacity: customAppearanceEnabled
    ? Math.max(0, 1 - appearanceTransparency / 100) : 1
  readonly property real appearanceSoftness: customAppearanceEnabled
    ? Math.max(0, Math.min(1, appearanceBlur / 24)) : 0
  // One radius token keeps every plugin surface and control in the same
  // visual language. Circles (status dots, swatches, knobs) remain explicit.
  readonly property bool compactChromeEnabled: customAppearanceEnabled && compactUiEnabled
  readonly property real uiRadius: compactChromeEnabled ? 0 : (customAppearanceEnabled
    ? appearanceRadius : Style.cornerRadius)
  readonly property real panelRadius: uiRadius
  readonly property real nestedRadius: uiRadius
  readonly property real compactRadius: uiRadius
  readonly property real uiCardPadding: compactChromeEnabled ? Style.space(8) : Style.space(16)
  readonly property real uiGroupSpacing: compactChromeEnabled ? Style.space(4) : Style.space(9)
  readonly property bool deviceColorsActive: customAppearanceEnabled
    && !appearanceAutoAccent && appearanceDeviceColorsEnabled
  readonly property int motionFast: 140
  readonly property int motionStandard: 220
  readonly property int motionEmphasis: 300
  readonly property int motionSplash: 520
  readonly property color panelSurface: Qt.rgba(
    root.appearanceBackgroundColor.r, root.appearanceBackgroundColor.g,
    root.appearanceBackgroundColor.b,
    root.appearanceSurfaceOpacity)
  property var reading: ({})
  property var entityOptions: []
  property var unitLocalStates: ({})
  property int unitLocalStateRevision: 0
  property string selectedEntity: ""
  property string pendingEntity: ""
  property string errorText: ""
  property bool actionBusy: false
  property string actionKind: ""
  property string actionEntityId: ""
  property var localTarget: null
  property string pendingPowerState: ""
  property double powerRequestStartedAt: 0
  property double powerDispatchDueAt: 0
  property string powerReadbackMarker: ""
  property bool powerFinalCheckPending: false
  property bool powerTimedOut: false
  property string powerTimeoutMessage: ""
  property bool powerCanCancel: false
  property string queuedPowerRequest: ""
  property string queuedUnitPowerEntityId: ""
  property string queuedUnitPowerRequest: ""
  property string queuedControlKind: ""
  property string queuedControlValue: ""
  property var temperatureInFlight: null
  property var lastTemperatureSent: null
  property string localMode: ""
  property string localFanMode: ""
  property string modeInFlight: ""
  property string fanModeInFlight: ""
  property bool modeRestarting: false
  property double modeRestartStartedAt: 0
  property bool configResolved: false
  property bool configured: false
  property bool setupOpen: false
  property bool setupTransitioning: false
  property bool setupTransitionClosing: false
  property bool setupBusy: false
  property bool connectionEditing: false
  property bool connectionReconnecting: false
  property bool localServerBusy: false
  property bool localServerConfirming: false
  property bool localServerReady: false
  property bool localServerExpanded: false
  property string localServerMessage: ""
  property string localServerError: ""
  property bool resetAppConfirming: false
  property bool resetAppBusy: false
  property string resetAppMessage: ""
  property string resetAppError: ""
  property bool uninstallConfirming: false
  property bool uninstallOptionConfirming: false
  property bool uninstallBusy: false
  property string uninstallMode: ""
  property string uninstallMessage: ""
  property string uninstallError: ""
  property string uninstallProcessStderr: ""
  property bool turnOffAllConfirming: false
  property bool turnOffAllBusy: false
  property string turnOffAllMessage: ""
  property string turnOffAllError: ""
  property bool turnOnAllConfirming: false
  property bool turnOnAllBusy: false
  property string turnOnAllMessage: ""
  property string turnOnAllError: ""
  // One setting controls the main remote and every experimental per-AC card.
  // The helper key remains advanced_controls for compatibility with existing
  // installations.
  property bool showClimateControls: true
  property bool masterSwitchEnabled: false
  property bool masterSwitchEnabledPrevious: false
  property bool preferenceBusy: false
  property string preferenceKind: ""
  property bool showClimateControlsPrevious: true
  property string temperatureDisplay: "both"
  property string temperatureDisplayPrevious: "both"
  property bool historyEnabled: false
  property bool historyEnabledPrevious: false
  property real historyHours: 24
  property real historyHoursPrevious: 24
  property bool historyCustom: false
  property bool historyCustomPrevious: false
  property string customHistoryHoursText: "24"
  property int historyWindowRevision: 0
  property string historySource: "local"
  property string historySourcePrevious: "local"
  property string remoteHistoryTarget: ""
  property string remoteHistoryPortText: "22"
  property string remoteHistoryUrl: "http://127.0.0.1:8123"
  property string remoteHistoryPath: "~/.local/state/omarchy/homeassistant-ac-temperature.json"
  property bool remoteHistoryBusy: false
  property string remoteHistoryAction: ""
  property bool remoteHistorySourceBusy: false
  property string remoteHistorySourcePayload: ""
  property bool remoteHistoryOperationSucceeded: false
  // A typed target is only a draft. Keep the paired summary hidden until a
  // connect or install action has actually saved the pairing.
  property bool remoteHistoryPairingSaved: false
  property bool remoteHistoryReconfiguring: false
  property string remoteHistoryMessage: ""
  property string remoteHistoryError: ""
  property string remoteHistoryPayload: ""
  property string remoteHistoryTargetBeforeReconfigure: ""
  property string remoteHistoryPortBeforeReconfigure: "22"
  property string remoteHistoryUrlBeforeReconfigure: ""
  property string remoteHistoryPathBeforeReconfigure: ""
  property string remoteHistoryStatusTarget: ""
  property string remoteHistoryStatusPortText: ""
  property string remoteHistoryStatusPath: ""
  property bool remoteHistoryStatusAvailable: false
  property real remoteHistoryStatusPingMs: -1
  property string settingsSection: "preferences"
  property bool setupSucceeded: false
  property string setupUrl: "http://homeassistant.local:8123"
  property string setupAddressScheme: "http"
  property string setupAddressHost: "homeassistant.local"
  property string setupAddressPort: "8123"
  property bool setupAddressSyncing: false
  property string activeHomeAssistantUrl: ""
  property string setupToken: ""
  property string setupError: ""
  property string setupPayload: ""
  property string selectionPayload: ""
  property string setupSelectedEntity: ""
  property var setupEntityOptions: []
  readonly property var appearanceDevicePalette: [
    "#8FA79F", "#8EA7C7", "#C89AAB", "#D0A66A", "#A99BC7", "#83A6A1",
    "#C28C85", "#89A7B2"
  ]
  readonly property var appearanceBackgroundPalette: [
    "#131516", "#1E2224", "#252B2C", "#1D2733", "#272234"
  ]

  function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }

  function latencyColor(value, healthyColor) {
    var latency = Number(value)
    if (!isFinite(latency) || latency < 0) return healthyColor
    if (latency > 500) return root.urgent
    if (latency >= 150) return root.warning
    return healthyColor
  }

  function surfaceColor(value) {
    return root.compactChromeEnabled ? "transparent" : value
  }

  function surfaceBorder(value) {
    if (root.compactChromeEnabled) return Border.none()
    if (!root.customAppearanceEnabled || !value) return value

    // Most panel cards describe their border with a foreground-derived colour
    // before it reaches this helper. Recolour that shared surface path so the
    // fixed accent is visible on every card, not only on controls that happen
    // to receive `accent:` directly.
    var width = Math.max(Border.top(value), Border.right(value),
      Border.bottom(value), Border.left(value))
    if (width <= 0) return value
    var original = Border.color(value)
    var opacity = original && original.a !== undefined ? original.a : 1
    return Border.flat(root.alpha(root.accentColor, opacity), width)
  }

  function controlSurfaceColor(control) {
    return root.compactChromeEnabled
      ? "transparent"
      : Style.controlFill(control.activeFocus, control.hovered,
          root.foreground, root.controlAccentColor)
  }

  function controlSurfaceBorder(control) {
    return root.compactChromeEnabled
      ? Border.none()
      : Border.controlSpec(control.activeFocus
          ? "focus" : (control.hovered ? "hover-cursor" : "normal"),
          root.foreground, root.controlAccentColor)
  }

  function relativeLuminance(color) {
    function linearChannel(value) {
      var channel = Math.max(0, Math.min(1, Number(value)))
      return channel <= 0.03928 ? channel / 12.92
        : Math.pow((channel + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linearChannel(color.r)
      + 0.7152 * linearChannel(color.g)
      + 0.0722 * linearChannel(color.b)
  }

  function textContrast(surface, textColor) {
    var surfaceLuminance = root.relativeLuminance(surface)
    var textLuminance = root.relativeLuminance(textColor)
    var brighter = Math.max(surfaceLuminance, textLuminance)
    var darker = Math.min(surfaceLuminance, textLuminance)
    return (brighter + 0.05) / (darker + 0.05)
  }

  function contrastingTextColor(surface) {
    var lightText = Color.foreground
    var darkText = root.appearanceBackgroundColor
    return root.textContrast(surface, lightText) >= root.textContrast(surface, darkText)
      ? lightText : darkText
  }

  readonly property color accentTextColor: root.contrastingTextColor(root.accentColor)

  function normalizeAppearanceDeviceColors(value) {
    var source = value
    if (typeof source === "string") {
      try { source = JSON.parse(source) } catch (error) { return ({}) }
    }
    if (!source || typeof source !== "object" || Array.isArray(source)) return ({})
    var next = {}
    var count = 0
    for (var id in source) {
      var normalizedId = String(id || "").trim()
      var color = String(source[id] || "").trim().toUpperCase()
      if (!/^climate\.[A-Za-z0-9_-]+$/.test(normalizedId)
          || !/^#[0-9A-F]{6}$/.test(color)) continue
      next[normalizedId] = color
      count += 1
      if (count >= 12) break
    }
    return next
  }

  function copyAppearanceDeviceColors() {
    var next = {}
    var current = appearanceDeviceColors || ({})
    for (var id in current) next[id] = current[id]
    return next
  }

  function copyShortcutValues(source) {
    var next = {}
    var current = source || shortcutValues || shortcutDefaults
    for (var id in current) {
      var item = current[id] || ({})
      next[id] = {
        key: String(item.key || ""),
        enabled: item.enabled !== false,
      }
    }
    return next
  }

  function configFileDocument() {
    return {
      config_version: 1,
      entity_id: String(selectedEntity || ""),
      advanced_controls: showClimateControls,
      master_switch_enabled: masterSwitchEnabled,
      temperature_display: temperatureDisplay,
      history_enabled: historyEnabled,
      history_hours: Number(historyHours),
      history_custom: historyCustom,
      history_source: historySource,
      history_remote_target: String(remoteHistoryTarget || ""),
      history_remote_port: Number(remoteHistoryPortText || 22),
      history_remote_url: String(remoteHistoryUrl || remoteHistoryDefaultUrl),
      history_remote_path: String(remoteHistoryPath || remoteHistoryDefaultPath),
      multi_unit_enabled: multiUnitEnabled,
      global_sync_controls: globalSyncControls,
      sync_non_power_controls: syncNonPowerControls,
      average_temperature_decimals: averageTemperatureDecimals,
      temperature_unit: temperatureUnitPreference,
      selected_entities: Array.isArray(selectedEntities) ? selectedEntities.slice() : [],
      bar_temperature_mode: barTemperatureMode,
      bar_temperature_entities: Array.isArray(barTemperatureEntities)
        ? barTemperatureEntities.slice() : [],
      experimental_history_enabled: experimentalHistoryEnabled,
      shortcuts_enabled: shortcutsEnabled,
      global_tab_navigation_enabled: globalTabNavigationEnabled,
      config_file_mode_enabled: configFileModeEnabled,
      shortcuts: root.copyShortcutValues(),
      custom_appearance_enabled: customAppearanceEnabled,
      appearance_auto_accent: appearanceAutoAccent,
      appearance_auto_background: appearanceAutoBackground,
      appearance_accent: customAccentHexText,
      appearance_control: customControlHexText,
      appearance_background: customBackgroundHexText,
      appearance_device_colors_enabled: appearanceDeviceColorsEnabled,
      appearance_device_colors: root.copyAppearanceDeviceColors(),
      appearance_transparency: Number(appearanceTransparency),
      appearance_blur: Number(appearanceBlur),
      appearance_radius: Number(appearanceRadius),
      appearance_compact: compactUiEnabled,
      appearance_outer_border_enabled: appearanceOuterBorderEnabled,
    }
  }

  function refreshConfigFileText() {
    var next = JSON.stringify(root.configFileDocument(), null, 2)
    // TextArea removes its text binding after a user edit. Keep the model and
    // editor synchronized during an explicit reload without treating that
    // programmatic assignment as a new edit.
    configFileEditorSyncing = true
    configFileText = next
    if (configFileEditor) configFileEditor.text = next
    configFileEditorSyncing = false
  }

  function scheduleConfigFileRefresh() {
    if (configFileRefreshTimer) configFileRefreshTimer.restart()
  }

  function focusConfigFileEditor() {
    if (!root.setupOpen || !root.configFileModeEnabled || !configFileEditor) return
    // Config File Mode is deliberately keyboard-first. When the preference is
    // already enabled before Settings opens, the editor has not necessarily
    // received focus yet, so its TextArea can still be holding its initial
    // empty binding. Refresh before focusing and once after the focus change
    // has completed to make the initial document deterministic.
    if (String(configFileEditor.text || "").trim() === "")
      root.refreshConfigFileText()
    configFileEditor.forceActiveFocus()
    Qt.callLater(function() {
      if (!root.setupOpen || !root.configFileModeEnabled || !configFileEditor) return
      if (String(configFileEditor.text || "").trim() === "")
        root.refreshConfigFileText()
      root.ensureConfigFileCursorVisible()
    })
  }

  function reloadConfigFile() {
    if (configFileBusy || preferenceProcess.running) return
    configFileError = ""
    configFileStatus = ""
    root.refreshConfigFileText()
  }

  function configFileBackwardTab(event) {
    return event.key === Qt.Key_Backtab
      || (event.key === Qt.Key_Tab
        && (event.modifiers & Qt.ShiftModifier) !== 0)
  }

  function restoreGlobalTabOverrides() {
    var overrides = root.globalTabFocusOverrides || []
    for (var i = 0; i < overrides.length; i++) {
      var item = overrides[i].item
      if (!item) continue
      if (overrides[i].property === "focusable")
        item.focusable = overrides[i].value
      else if (overrides[i].property === "activeFocusOnTab")
        item.activeFocusOnTab = overrides[i].value
    }
    root.globalTabFocusOverrides = []
    root.globalTabFocusOverrideMode = ""
  }

  function rememberGlobalTabOverride(overrides, item, property, value) {
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i].item === item && overrides[i].property === property) return
    }
    overrides.push({ item: item, property: property, value: value })
  }

  // The shell's default Tab action moves between panel popouts. When this
  // experimental option is enabled, make the panel's ordinary buttons join
  // the same focus chain as text fields, toggles, and dropdown triggers.
  // Turning it off also disables Qt's normal tab-focus flags, so a stale
  // focus chain cannot keep navigating inside this panel after the switch is
  // turned off.
  function applyGlobalTabNavigation() {
    var overrides = root.globalTabFocusOverrides || []
    var mode = String(root.globalTabFocusOverrideMode || "")

    if (root.configFileModeEnabled) {
      if (mode !== "") root.restoreGlobalTabOverrides()
      return
    }

    if (!root.globalTabNavigationEnabled) {
      if (mode === "enabled") {
        root.restoreGlobalTabOverrides()
        overrides = []
      }

      function disableTabFocus(item) {
        if (!item) return
        if (item !== keyCatcher && item.activeFocusOnTab === true) {
          root.rememberGlobalTabOverride(
            overrides, item, "activeFocusOnTab", item.activeFocusOnTab)
          item.activeFocusOnTab = false
        }
        var children = item.children || []
        for (var i = 0; i < children.length; i++) disableTabFocus(children[i])
      }

      disableTabFocus(keyCatcher)
      root.globalTabFocusOverrides = overrides
      root.globalTabFocusOverrideMode = "disabled"
      return
    }

    if (mode === "disabled") {
      root.restoreGlobalTabOverrides()
      overrides = []
    }

    function visit(item) {
      if (!item) return
      if (item !== keyCatcher && item.focusable === false) {
        root.rememberGlobalTabOverride(overrides, item, "focusable", item.focusable)
        item.focusable = true
      }
      var children = item.children || []
      for (var j = 0; j < children.length; j++) visit(children[j])
    }

    visit(keyCatcher)
    root.globalTabFocusOverrides = overrides
    root.globalTabFocusOverrideMode = "enabled"
  }

  function globalTabFocusItems() {
    root.applyGlobalTabNavigation()
    var result = []

    function isUsable(item) {
      var current = item
      while (current && current !== panel) {
        if (!current.visible || current.opacity <= 0.01
            || current.width <= 0 || current.height <= 0)
          return false
        current = current.parent
      }
      return true
    }

    function visit(item) {
      if (!item) return
      if (item !== keyCatcher && isUsable(item) && item.enabled && item.activeFocusOnTab)
        result.push(item)
      var children = item.children || []
      for (var i = 0; i < children.length; i++) visit(children[i])
    }

    visit(keyCatcher)
    return result
  }

  function ensurePanelFocusVisible(item) {
    if (!item || !panelScroll || panelScroll.contentHeight <= panelScroll.height) return
    var point = item.mapToItem(panelScroll.contentItem, 0, 0)
    var top = point.y
    var bottom = top + Math.max(1, item.height)
    var margin = Style.space(8)
    var maxY = Math.max(0, panelScroll.contentHeight - panelScroll.height)
    if (top < panelScroll.contentY + margin)
      panelScroll.contentY = Math.max(0, top - margin)
    else if (bottom > panelScroll.contentY + panelScroll.height - margin)
      panelScroll.contentY = Math.min(maxY, bottom + margin - panelScroll.height)
  }

  // Confirmation controls replace the button that opened them. Keep keyboard
  // focus attached to the replacement instead of letting Qt fall back to the
  // first item in the panel's focus chain while the split animates in.
  function focusConfirmationItem(item) {
    if (!item) return
    confirmationFocusTimer.targetItem = item
    confirmationFocusTimer.restart()
  }

  function isPanelFocusDescendant(item, ancestor) {
    var current = item
    while (current && current !== panel) {
      if (current === ancestor) return true
      current = current.parent
    }
    return false
  }

  function focusReplacementInPanelBranch(item, items, direction) {
    var ancestor = item ? item.parent : null
    while (ancestor && ancestor !== panel) {
      var branch = []
      for (var i = 0; i < items.length; i++) {
        if (root.isPanelFocusDescendant(items[i], ancestor)) branch.push(items[i])
      }
      if (branch.length > 0)
        return Number(direction) < 0 ? branch[0] : branch[branch.length - 1]
      ancestor = ancestor.parent
    }
    return null
  }

  function focusNextPanelItem(direction) {
    if (!root.globalTabNavigationEnabled) return false
    var items = root.globalTabFocusItems()
    if (items.length === 0) return false
    var focusedItem = panel.activeFocusItem
    var current = focusedItem
    var index = items.indexOf(current)
    while (index < 0 && current) {
      current = current.parent
      index = items.indexOf(current)
    }
    var step = Number(direction) < 0 ? -1 : 1
    var next = index < 0
      ? root.focusReplacementInPanelBranch(focusedItem, items, direction) : null
    if (!next) {
      if (index < 0) index = step > 0 ? -1 : 0
      next = items[(index + step + items.length) % items.length]
    }
    next.forceActiveFocus()
    Qt.callLater(function() { root.ensurePanelFocusVisible(next) })
    return true
  }

  function historyTimestamp(value) {
    var timestamp = Number(value)
    if (!isFinite(timestamp)) return 0
    // Older external loggers may have written Unix time in milliseconds.
    return timestamp > 100000000000 ? timestamp / 1000 : timestamp
  }

  function ensureConfigFileCursorVisible() {
    if (!configFileEditor || !configFileEditorScroll) return
    var cursor = configFileEditor.cursorRectangle
    // cursorRectangle is local to the TextArea. Mapping both edges into the
    // Flickable content item keeps this correct if the control's internal
    // padding/content item changes between Qt versions.
    var cursorTop = configFileEditor.mapToItem(
      configFileEditorScroll.contentItem, cursor.x, cursor.y)
    var cursorBottom = configFileEditor.mapToItem(
      configFileEditorScroll.contentItem, cursor.x,
      cursor.y + Math.max(1, cursor.height))
    var top = cursorTop.y
    var bottom = Math.max(top + 1, cursorBottom.y)
    var margin = Style.space(8)
    var maxY = Math.max(0, configFileEditorScroll.contentHeight
      - configFileEditorScroll.height)
    var nextY = configFileEditorScroll.contentY
    var textLength = String(configFileEditor.text || "").length
    var atDocumentStart = configFileEditor.cursorPosition <= 0
    var atDocumentEnd = configFileEditor.cursorPosition >= textLength
    var documentBottom = Math.max(0, configFileEditorScroll.contentHeight
      - configFileEditor.bottomPadding)

    // Reaching either end should land exactly on the corresponding corner of
    // the editor. This matters for key-repeat: the cursor can arrive at the
    // last visual line without landing at the final character.
    if (atDocumentStart)
      nextY = 0
    else if (atDocumentEnd || bottom >= documentBottom - margin)
      nextY = maxY
    else if (top < configFileEditorScroll.contentY + margin)
      nextY = top - margin
    else if (bottom > configFileEditorScroll.contentY
        + configFileEditorScroll.height - margin)
      nextY = bottom + margin - configFileEditorScroll.height

    configFileEditorScroll.contentY = Math.max(0, Math.min(maxY, nextY))
  }

  function scrollConfigFileBy(delta) {
    if (!configFileEditorScroll) return
    var maxY = Math.max(0, configFileEditorScroll.contentHeight
      - configFileEditorScroll.height)
    configFileEditorScroll.contentY = Math.max(0, Math.min(maxY,
      configFileEditorScroll.contentY + Number(delta || 0)))
  }

  function applyConfigFileState(parsed) {
    if (!parsed) return
    if (parsed.entity_id) {
      selectedEntity = String(parsed.entity_id)
      setupSelectedEntity = selectedEntity
    }
    if (parsed.advanced_controls !== undefined) {
      showClimateControls = parsed.advanced_controls === true
      showClimateControlsPrevious = showClimateControls
    }
    if (parsed.master_switch_enabled !== undefined) {
      masterSwitchEnabled = parsed.master_switch_enabled === true
      masterSwitchEnabledPrevious = masterSwitchEnabled
    }
    if (parsed.temperature_display !== undefined) {
      temperatureDisplay = String(parsed.temperature_display)
      temperatureDisplayPrevious = temperatureDisplay
    }
    if (parsed.history_enabled !== undefined) {
      historyEnabled = parsed.history_enabled === true
      historyEnabledPrevious = historyEnabled
    }
    if (parsed.history_hours !== undefined) {
      historyHours = root.normalizeHistoryHours(parsed.history_hours)
      historyHoursPrevious = historyHours
      customHistoryHoursText = root.formatHours(historyHours)
    }
    if (parsed.history_custom !== undefined) {
      historyCustom = parsed.history_custom === true
      historyCustomPrevious = historyCustom
    }
    if (parsed.history_source !== undefined) {
      historySource = String(parsed.history_source) === "server" ? "server" : "local"
      historySourcePrevious = historySource
    }
    if (parsed.history_remote_target !== undefined)
      remoteHistoryTarget = String(parsed.history_remote_target || "")
    if (parsed.history_remote_port !== undefined)
      remoteHistoryPortText = String(parsed.history_remote_port || "22")
    if (parsed.history_remote_url !== undefined)
      remoteHistoryUrl = String(parsed.history_remote_url || root.remoteHistoryDefaultUrl)
    if (parsed.history_remote_path !== undefined)
      remoteHistoryPath = String(parsed.history_remote_path || root.remoteHistoryDefaultPath)
    remoteHistoryPairingSaved = String(remoteHistoryTarget || "").trim() !== ""
    root.applyExperimentalValues(parsed)
  }

  function applyConfigFile() {
    if (configFileBusy || preferenceBusy) return
    var text = String(configFileText || "").trim()
    if (text === "") {
      configFileError = "The config file cannot be empty."
      configFileStatus = ""
      return
    }
    try {
      var payload = JSON.parse(text)
      if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
        configFileError = "The config file must contain a JSON object."
        configFileStatus = ""
        return
      }
      // The helper receives one stdin line. Keep the editor pretty-printed
      // for humans, but send a compact equivalent so multiline JSON is not
      // truncated at the first newline.
      configFilePayload = JSON.stringify(payload)
    } catch (error) {
      configFileError = "Fix the JSON syntax before applying the config file."
      configFileStatus = ""
      return
    }
    configFileError = ""
    configFileStatus = "Saving preferences…"
    configFileBusy = true
    configFileProcess.command = ["python3", root.helperPath, "set-config-file"]
    configFileProcess.running = true
  }

  function applyConfigFileResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      configFileError = "The config file could not be saved."
      configFileStatus = ""
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true && parsed.config_file_saved === true) {
        root.applyConfigFileState(parsed)
        configFileError = ""
        configFileStatus = parsed.shortcut_sync_error
          ? "Saved, but keyboard bindings need attention."
          : "Saved. Ctrl+S or Ctrl+Enter applies the JSON; Esc returns to AC controls."
        root.refreshConfigFileText()
        Qt.callLater(function() {
          root.refresh()
          if (root.configFileModeEnabled && configFileEditor)
            configFileEditor.forceActiveFocus()
        })
        return
      }
      configFileError = parsed && parsed.error
        ? String(parsed.error) : "The config file could not be saved."
      configFileStatus = ""
    } catch (error) {
      configFileError = "The config file helper returned invalid data."
      configFileStatus = ""
    }
  }

  function normalizeShortcutKey(value, fallback) {
    var raw = String(value || "").trim().toUpperCase()
    var fallbackText = String(fallback || "")
    if (raw === "")
      return fallbackText !== "" ? root.normalizeShortcutKey(fallbackText, "") : ""

    var aliases = {
      META: "SUPER",
      WIN: "SUPER",
      WINDOWS: "SUPER",
      CMD: "SUPER",
      CONTROL: "CTRL",
      OPTION: "ALT",
      OPT: "ALT",
      ESCAPE: "ESC",
      RETURN: "ENTER",
      DEL: "DELETE",
      PGUP: "PAGEUP",
      PAGE_UP: "PAGEUP",
      PGDN: "PAGEDOWN",
      PAGE_DOWN: "PAGEDOWN",
      ARROWLEFT: "LEFT",
      LEFTARROW: "LEFT",
      ARROWRIGHT: "RIGHT",
      RIGHTARROW: "RIGHT",
      ARROWUP: "UP",
      UPARROW: "UP",
      ARROWDOWN: "DOWN",
      DOWNARROW: "DOWN",
      DOT: "PERIOD",
      GRAVE: "QUOTELEFT",
    }
    var modifierAliases = {
      SUPER: "SUPER",
      META: "SUPER",
      WIN: "SUPER",
      WINDOWS: "SUPER",
      CMD: "SUPER",
      CTRL: "CTRL",
      CONTROL: "CTRL",
      ALT: "ALT",
      OPTION: "ALT",
      OPT: "ALT",
      SHIFT: "SHIFT",
    }
    var modifierOrder = ["SUPER", "CTRL", "ALT", "SHIFT"]
    var allowed = {
      ESC: true, ENTER: true, SPACE: true, TAB: true,
      LEFT: true, RIGHT: true, UP: true, DOWN: true,
      BACKSPACE: true, DELETE: true, HOME: true, END: true,
      PAGEUP: true, PAGEDOWN: true, INSERT: true, PRINT: true,
      COMMA: true, PERIOD: true, SLASH: true, SEMICOLON: true,
      APOSTROPHE: true, BRACKETLEFT: true, BRACKETRIGHT: true,
      BACKSLASH: true, MINUS: true, EQUAL: true, QUOTELEFT: true,
      PLUS: true,
    }
    var parts = raw.split(/\s*\+\s*/)
    var modifiers = []
    var key = ""
    for (var i = 0; i < parts.length; i++) {
      var part = String(parts[i] || "").trim()
      if (part === "") {
        key = ""
        break
      }
      var modifier = modifierAliases[part]
      if (modifier) {
        if (modifiers.indexOf(modifier) >= 0) {
          key = ""
          break
        }
        modifiers.push(modifier)
        continue
      }
      var normalized = aliases[part] || part
      var isLetterOrNumber = /^[A-Z0-9]$/.test(normalized)
      var isFunctionKey = /^F([1-9]|1[0-9]|2[0-4])$/.test(normalized)
      var isXf86Key = /^XF86_[A-Z0-9_]+$/.test(normalized)
      if (key !== "" || (!allowed[normalized] && !isLetterOrNumber
          && !isFunctionKey && !isXf86Key)) {
        key = ""
        break
      }
      key = normalized
    }
    if (key === "")
      return fallbackText !== "" && fallbackText !== String(value || "")
        ? root.normalizeShortcutKey(fallbackText, "") : ""
    var ordered = []
    for (var j = 0; j < modifierOrder.length; j++) {
      if (modifiers.indexOf(modifierOrder[j]) >= 0) ordered.push(modifierOrder[j])
    }
    ordered.push(key)
    return ordered.join("+")
  }

  function normalizeShortcutValues(value) {
    var source = value && typeof value === "object" && !Array.isArray(value) ? value : ({})
    var next = {}
    for (var i = 0; i < shortcutDefinitions.length; i++) {
      var definition = shortcutDefinitions[i]
      var id = definition.id
      var item = source[id]
      if (typeof item === "string") item = { key: item }
      item = item && typeof item === "object" ? item : ({})
      var fallback = shortcutDefaults[id] || ({ key: "", enabled: true })
      next[id] = {
        key: root.normalizeShortcutKey(item.key, fallback.key),
        enabled: item.enabled !== false,
      }
    }
    return next
  }

  function shortcutValue(name) {
    var item = shortcutValues && shortcutValues[name]
    var fallback = shortcutDefaults[name] || ({ key: "", enabled: true })
    return root.normalizeShortcutKey(item ? item.key : "", fallback.key)
  }

  function shortcutEnabled(name) {
    var item = shortcutValues && shortcutValues[name]
    return !item || item.enabled !== false
  }

  function shortcutStatus(name) {
    if (!root.shortcutsEnabled) return "PAUSED"
    return root.shortcutEnabled(name) ? "ACTIVE" : "DISABLED"
  }

  function shortcutDisplay(value) {
    var normalized = root.normalizeShortcutKey(value, "")
    if (normalized === "") return "NOT SET"
    var displayNames = {
      LEFT: "←", RIGHT: "→", UP: "↑", DOWN: "↓",
    }
    return normalized.split("+").map(function(part) {
      return displayNames[part] || part
    }).join(" + ")
  }

  function shortcutQmlSequence(value) {
    var normalized = root.normalizeShortcutKey(value, "")
    if (normalized === "") return ""
    var names = {
      SUPER: "Meta", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift",
      ESC: "Escape", ENTER: "Return", SPACE: "Space", TAB: "Tab",
      LEFT: "Left", RIGHT: "Right", UP: "Up", DOWN: "Down",
      BACKSPACE: "Backspace", DELETE: "Delete", HOME: "Home", END: "End",
      PAGEUP: "PageUp", PAGEDOWN: "PageDown", INSERT: "Insert", PRINT: "Print",
      COMMA: ",", PERIOD: ".", SLASH: "/", SEMICOLON: ";",
      APOSTROPHE: "'", BRACKETLEFT: "[", BRACKETRIGHT: "]",
      BACKSLASH: "\\", MINUS: "-", EQUAL: "=", QUOTELEFT: "`", PLUS: "+",
    }
    return normalized.split("+").map(function(part) {
      return names[part] || part
    }).join("+")
  }

  function shortcutKeyName(key) {
    if (key >= Qt.Key_A && key <= Qt.Key_Z)
      return String.fromCharCode("A".charCodeAt(0) + key - Qt.Key_A)
    if (key >= Qt.Key_0 && key <= Qt.Key_9)
      return String.fromCharCode("0".charCodeAt(0) + key - Qt.Key_0)
    if (key >= Qt.Key_F1 && key <= Qt.Key_F24)
      return "F" + String(key - Qt.Key_F1 + 1)
    if (key === Qt.Key_Escape) return "ESC"
    if (key === Qt.Key_Return || key === Qt.Key_Enter) return "ENTER"
    if (key === Qt.Key_Space) return "SPACE"
    if (key === Qt.Key_Tab) return "TAB"
    if (key === Qt.Key_Left) return "LEFT"
    if (key === Qt.Key_Right) return "RIGHT"
    if (key === Qt.Key_Up) return "UP"
    if (key === Qt.Key_Down) return "DOWN"
    if (key === Qt.Key_Backspace) return "BACKSPACE"
    if (key === Qt.Key_Delete) return "DELETE"
    if (key === Qt.Key_Home) return "HOME"
    if (key === Qt.Key_End) return "END"
    if (key === Qt.Key_PageUp) return "PAGEUP"
    if (key === Qt.Key_PageDown) return "PAGEDOWN"
    if (key === Qt.Key_Insert) return "INSERT"
    if (key === Qt.Key_Print) return "PRINT"
    if (key === Qt.Key_Comma) return "COMMA"
    if (key === Qt.Key_Period) return "PERIOD"
    if (key === Qt.Key_Slash) return "SLASH"
    if (key === Qt.Key_Semicolon) return "SEMICOLON"
    if (key === Qt.Key_Apostrophe) return "APOSTROPHE"
    if (key === Qt.Key_BracketLeft) return "BRACKETLEFT"
    if (key === Qt.Key_BracketRight) return "BRACKETRIGHT"
    if (key === Qt.Key_Backslash) return "BACKSLASH"
    if (key === Qt.Key_Minus) return "MINUS"
    if (key === Qt.Key_Equal) return "EQUAL"
    if (key === Qt.Key_QuoteLeft) return "QUOTELEFT"
    if (key === Qt.Key_Plus) return "PLUS"
    return ""
  }

  function shortcutFromEvent(event) {
    var key = root.shortcutKeyName(event.key)
    if (key === "") return ""
    var modifiers = []
    if ((event.modifiers & Qt.MetaModifier) !== 0) modifiers.push("SUPER")
    if ((event.modifiers & Qt.ControlModifier) !== 0) modifiers.push("CTRL")
    if ((event.modifiers & Qt.AltModifier) !== 0) modifiers.push("ALT")
    if ((event.modifiers & Qt.ShiftModifier) !== 0) modifiers.push("SHIFT")
    return root.normalizeShortcutKey(modifiers.concat([key]).join("+"), "")
  }

  function captureShortcut(name, event) {
    if (root.shortcutCaptureId !== name || root.preferenceBusy) return
    var captured = root.shortcutFromEvent(event)
    event.accepted = true
    if (captured === "") return
    root.shortcutCaptureId = ""
    root.setShortcut(name, captured)
  }

  function appearanceColorIndex(entityId) {
    var id = String(entityId || "")
    var index = selectedEntities.indexOf(id)
    return index >= 0 ? index : 0
  }

  function appearanceDeviceColor(entityId) {
    var id = String(entityId || "")
    var colors = appearanceDeviceColors || ({})
    if (colors[id] && /^#[0-9A-Fa-f]{6}$/.test(String(colors[id])))
      return String(colors[id]).toUpperCase()
    if (appearanceDevicePalette.length > 0)
      return appearanceDevicePalette[appearanceColorIndex(id) % appearanceDevicePalette.length]
    return root.accentColor
  }

  function appearanceDeviceColorText(entityId) {
    return appearanceDeviceColor(entityId)
  }

  function deviceCardAccent(entityId) {
    return deviceColorsActive ? appearanceDeviceColor(entityId) : root.accentColor
  }

  function deviceControlAccent(entityId) {
    return deviceColorsActive ? appearanceDeviceColor(entityId) : root.controlAccentColor
  }

  function isLocalHomeAssistantUrl(value) {
    var text = String(value || "").trim().toLowerCase().replace(/\/+$/, "")
    return text === "http://127.0.0.1:8123"
      || text === "http://localhost:8123"
      || text === "https://127.0.0.1:8123"
      || text === "https://localhost:8123"
  }

  function sameHomeAssistantAddress(first, second) {
    function canonical(value) {
      var text = String(value || "").trim()
      if (text === "") return ""
      if (text.indexOf("://") === -1) text = "http://" + text
      text = text.replace(/\/api\/?$/i, "").replace(/\/+$/, "")
      return text.toLowerCase()
    }
    var firstAddress = canonical(first)
    var secondAddress = canonical(second)
    return firstAddress !== "" && firstAddress === secondAddress
  }

  function splitHomeAssistantAddress(value) {
    var text = String(value || "").trim()
    var scheme = "http"
    var schemeMatch = text.match(/^([a-z][a-z0-9+.-]*):\/\//i)
    if (schemeMatch) {
      scheme = String(schemeMatch[1]).toLowerCase()
      text = text.slice(schemeMatch[0].length)
    }
    if (scheme !== "http" && scheme !== "https") scheme = "http"

    var slash = text.indexOf("/")
    var authority = slash >= 0 ? text.slice(0, slash) : text
    var path = slash >= 0 ? text.slice(slash) : ""
    var host = authority
    var port = "8123"
    if (authority.charAt(0) === "[") {
      var closingBracket = authority.indexOf("]")
      if (closingBracket > 0) {
        host = authority.slice(0, closingBracket + 1)
        var bracketPort = authority.slice(closingBracket + 1)
        if (bracketPort.indexOf(":") === 0 && /^\d+$/.test(bracketPort.slice(1)))
          port = bracketPort.slice(1)
      }
    } else {
      var colon = authority.lastIndexOf(":")
      if (colon > 0 && authority.indexOf(":") === colon
          && /^\d+$/.test(authority.slice(colon + 1))) {
        host = authority.slice(0, colon)
        port = authority.slice(colon + 1)
      }
    }
    return { scheme: scheme, host: host + path, port: port }
  }

  function setupAddressParts() {
    var text = String(root.setupAddressHost || "").trim()
    var scheme = root.setupAddressScheme === "https" ? "https" : "http"
    if (text.indexOf("://") >= 0) {
      var parsed = root.splitHomeAssistantAddress(text)
      scheme = parsed.scheme
      text = parsed.host
    }

    var slash = text.indexOf("/")
    var authority = slash >= 0 ? text.slice(0, slash) : text
    var path = slash >= 0 ? text.slice(slash) : ""
    if (authority.charAt(0) === "[") {
      var closingBracket = authority.indexOf("]")
      var bracketPort = authority.slice(closingBracket + 1)
      if (closingBracket > 0 && bracketPort.indexOf(":") === 0
          && /^\d+$/.test(bracketPort.slice(1)))
        authority = authority.slice(0, closingBracket + 1)
    } else {
      var colon = authority.lastIndexOf(":")
      if (colon > 0 && authority.indexOf(":") === colon
          && /^\d+$/.test(authority.slice(colon + 1)))
        authority = authority.slice(0, colon)
    }
    return { scheme: scheme, authority: authority, path: path }
  }

  function setupAddressIsValid() {
    var parts = root.setupAddressParts()
    var portText = String(root.setupAddressPort || "").trim()
    if (parts.authority === "" || /\s/.test(parts.authority)
        || /[?#]/.test(parts.path) || /[?#]/.test(parts.authority)) return false
    if (parts.authority.charAt(0) === "[") {
      if (parts.authority.indexOf("]") < 0) return false
    } else if (parts.authority.indexOf(":") >= 0) {
      // IPv6 addresses must be entered in bracketed form so the port remains
      // unambiguous in the composed URL.
      return false
    }
    var port = Number(portText)
    return /^\d+$/.test(portText) && isFinite(port) && port >= 1 && port <= 65535
  }

  function composeHomeAssistantAddress() {
    var parts = root.setupAddressParts()
    if (!root.setupAddressIsValid()) return ""
    return parts.scheme + "://" + parts.authority + ":"
      + String(root.setupAddressPort || "").trim() + parts.path.replace(/\/+$/, "")
  }

  function syncSetupAddressFields(value) {
    var parsed = root.splitHomeAssistantAddress(value)
    root.setupAddressSyncing = true
    root.setupAddressScheme = parsed.scheme
    root.setupAddressHost = parsed.host
    root.setupAddressPort = parsed.port || "8123"
    if (setupHostField) setupHostField.text = root.setupAddressHost
    if (setupPortField) setupPortField.text = root.setupAddressPort
    if (reconnectHostField) reconnectHostField.text = root.setupAddressHost
    if (reconnectPortField) reconnectPortField.text = root.setupAddressPort
    root.setupAddressSyncing = false
  }

  function updateSetupUrlFromAddress() {
    var next = root.composeHomeAssistantAddress()
    if (next === "") return false
    root.setupAddressSyncing = true
    root.setupUrl = next
    root.setupAddressSyncing = false
    return true
  }

  readonly property var dropdownOptions: [{
    value: "",
    label: "Choose an air conditioner"
  }].concat(entityOptions)
  readonly property var selectedEntityDropdownOptions: selectedEntityDropdownItems()
  readonly property var setupDropdownOptions: [{
    value: "",
    label: "Choose an air conditioner"
  }].concat(setupEntityOptions)
  readonly property var modeDropdownOptions: [{
    value: "",
    label: "Choose a mode"
  }].concat(modeOptions)
  readonly property var fanModeDropdownOptions: [{
    value: "",
    label: "Choose fan speed"
  }].concat(fanModeOptions)
  readonly property var historyRangeOptions: [
    { value: "1", label: "1 H" },
    { value: "3", label: "3 H" },
    { value: "6", label: "6 H" },
    { value: "12", label: "12 H" },
    { value: "24", label: "24 H" },
  ].concat(experimentalHistoryEnabled ? [
    { value: "168", label: "7 D" },
    { value: "720", label: "30 D" },
    { value: "custom", label: "CUSTOM" },
  ] : [])
  readonly property var settingsSections: [
    { value: "preferences", label: "PREFERENCES" },
  ].concat(shortcutsEnabled ? [
    { value: "shortcuts", label: "SHORTCUTS" },
  ] : []).concat(customAppearanceEnabled ? [
    { value: "customisation", label: "CUSTOMISATION" },
  ] : []).concat([
    { value: "experimental", label: "EXPERIMENTAL" },
    { value: "maintenance", label: "MAINTENANCE" },
  ])
  readonly property bool setupAddressValid: root.setupAddressIsValid()
  readonly property bool reconnectCanReuseSavedToken: configured
    && root.sameHomeAssistantAddress(root.composeHomeAssistantAddress(), activeHomeAssistantUrl)
    && String(setupToken || "").trim() === ""
  readonly property bool setupCanSubmit: !setupBusy
    && !preferenceBusy
    && !localServerBusy
    && !remoteHistoryBusy
    && !remoteHistorySourceBusy
    && !resetAppBusy
    && !uninstallBusy
    && !masterSwitchBusy
    && root.setupAddressValid
    && String(setupToken || "").trim() !== ""
    && (setupEntityOptions.length === 0 || setupSelectedEntity !== "")
  readonly property bool reconnectCanSubmit: !setupBusy
    && !preferenceBusy
    && !localServerBusy
    && !remoteHistoryBusy
    && !remoteHistorySourceBusy
    && !resetAppBusy
    && !uninstallBusy
    && !masterSwitchBusy
    && root.setupAddressValid
    && (String(setupToken || "").trim() !== "" || root.reconnectCanReuseSavedToken)
    && (setupEntityOptions.length === 0 || setupSelectedEntity !== "")
  readonly property string setupActionLabel: setupEntityOptions.length > 0
    ? "SAVE & CONTINUE" : "CONNECT & CONTINUE"
  readonly property bool connected: reading && reading.ok === true
  readonly property bool multiUnitActive: multiUnitEnabled && selectedEntities.length > 1
    && unitReadings.length > 1
  readonly property bool splitPowerOnly: multiUnitActive && !globalSyncControls
    && syncNonPowerControls
  readonly property bool separateRemotesActive: multiUnitActive && !globalSyncControls
    && !syncNonPowerControls
  readonly property bool showMainRemote: !multiUnitActive || globalSyncControls || syncNonPowerControls
  readonly property bool remoteHistoryConfigured: historySource === "server"
    && remoteHistoryPairingSaved
  readonly property bool remoteHistoryStatusMatchesCurrent:
    root.remoteHistoryStatusTarget !== ""
    && root.remoteHistoryStatusTarget === String(root.remoteHistoryTarget || "").trim()
    && root.remoteHistoryStatusPortText === String(root.remoteHistoryPortText || "22").trim()
    && root.remoteHistoryStatusPath === String(root.remoteHistoryPath || root.remoteHistoryDefaultPath).trim()
  readonly property bool remoteHistoryConnected: root.remoteHistoryConfigured
    && root.remoteHistoryStatusMatchesCurrent
    && root.remoteHistoryStatusAvailable
  readonly property real remoteHistoryPingMs: root.remoteHistoryConnected
    && isFinite(Number(root.remoteHistoryStatusPingMs))
    ? Number(root.remoteHistoryStatusPingMs) : -1
  readonly property string remoteHistoryStatusText: {
    if (!root.remoteHistoryConfigured) return "NOT CONFIGURED"
    if (root.remoteHistoryBusy && root.remoteHistoryAction === "connect") return "CONNECTING…"
    if (statusProcess.running && !root.remoteHistoryStatusMatchesCurrent) return "CHECKING…"
    if (!root.remoteHistoryStatusMatchesCurrent) return "NOT VERIFIED"
    return root.remoteHistoryConnected ? "CONNECTED" : "UNAVAILABLE"
  }
  readonly property color remoteHistoryStatusColor: root.remoteHistoryConnected
    ? root.latencyColor(root.remoteHistoryPingMs, root.accentColor)
    : root.remoteHistoryStatusText === "CHECKING…" ? root.dim : root.urgent
  readonly property bool barIsOn: connected && multiUnitActive
    ? anyUnitOn() : isOn
  readonly property bool actualIsOn: connected && String(reading.state || "").toLowerCase() !== "off"
  readonly property bool hasLocalPower: pendingPowerState !== ""
  readonly property bool localPower: pendingPowerState === "turning_on"
  readonly property bool isOn: connected
    && (hasLocalPower ? localPower : (actualIsOn || modeRestarting))
  readonly property string unit: connected ? String(reading.unit || "°C") : "°C"
  readonly property string sourceTemperatureUnitCode: root.temperatureUnitCode(unit)
  readonly property string displayTemperatureUnitCode: {
    var requested = root.normalizeTemperatureUnitPreference(temperatureUnitPreference)
    return requested === "source" ? sourceTemperatureUnitCode : requested
  }
  readonly property string displayTemperatureUnit: root.temperatureUnitSymbol(displayTemperatureUnitCode)
  readonly property string ambientText: connected ? temperature(reading.ambient) : "..."
  readonly property color ambientTemperatureTint: root.temperatureTint(
    root.mainAmbientValue(), unit)
  readonly property string mainAmbientText: connected
    ? (multiUnitActive ? root.averageAmbientText() : ambientText) : "..."
  readonly property string barAmbientText: connected ? formatBarAmbient() : "..."
  readonly property bool hasLocalTarget: localTarget !== null && isFinite(Number(localTarget))
  readonly property var targetValue: hasLocalTarget ? Number(localTarget) : reading.target
  readonly property string targetText: connected ? temperature(targetValue) : "..."
  readonly property real historyWindowEnd: {
    var revision = root.historyWindowRevision
    return Date.now() / 1000
  }
  readonly property bool masterSwitchBusy: turnOffAllBusy || turnOnAllBusy
  readonly property bool masterSwitchConfirming: turnOffAllConfirming || turnOnAllConfirming
  readonly property bool otherActionBusy: masterSwitchBusy
    || (actionProcess.running && actionKind !== "temperature")
  readonly property string activeMode: localMode !== "" ? localMode : String(reading.state || "")
  readonly property string activeFanMode: localFanMode !== ""
    ? localFanMode : String(reading.fan_mode || "")
  readonly property var modeOptions: formatControlOptions(reading.hvac_modes, true)
  readonly property var fanModeOptions: formatControlOptions(reading.fan_modes, false)
  readonly property bool climateControlsVisible: showClimateControls && connected
    && (isOn || modeRestarting || localMode !== "")
    && (modeOptions.length > 0 || fanModeOptions.length > 0)
  readonly property string modeText: activeMode !== "" ? controlLabel(activeMode) : "MODE"
  readonly property string fanModeText: activeFanMode !== ""
    ? controlLabel(activeFanMode) : "FAN SPEED"
  readonly property bool showAmbientOnBar: temperatureDisplay === "ambient"
    || temperatureDisplay === "both"
  readonly property bool showTargetOnBar: temperatureDisplay === "target"
    || temperatureDisplay === "both"
  readonly property bool historyChartVisible: historyEnabled && connected
  function historyPointsForWindow(windowEnd, hours) {
    var next = []
    if (!connected || !Array.isArray(reading.history)) return next
    var end = Number(windowEnd)
    var cutoff = end - Number(hours) * 60 * 60
    for (var i = 0; i < reading.history.length; i++) {
      var item = reading.history[i]
      if (!item || !isFinite(Number(item.timestamp)) || !isFinite(Number(item.temperature))) continue
      var timestamp = root.historyTimestamp(item.timestamp)
      if (timestamp >= cutoff && timestamp <= end + 300) {
        next.push({
          timestamp: timestamp,
          temperature: root.convertTemperature(
            Number(item.temperature), String(item.unit || unit), displayTemperatureUnitCode),
          unit: displayTemperatureUnit,
        })
      }
    }
    next.sort(function(first, second) { return first.timestamp - second.timestamp })
    return next
  }
  readonly property var historyPoints: {
    var revision = root.historyWindowRevision
    return root.historyPointsForWindow(root.historyWindowEnd, root.historyHours)
  }
  readonly property string historyServerLabel: {
    var target = String(remoteHistoryTarget || "").trim()
    if (target === "") return "NOT CONFIGURED"
    var at = target.lastIndexOf("@")
    return at >= 0 ? target.slice(at + 1) : target
  }
  readonly property string historySourceLabel: historySource === "server"
    ? "EXTERNAL · " + historyServerLabel : "LOCAL · LOGGED WHILE PC IS ON"
  readonly property bool historyLogHasSamples: {
    if (!Array.isArray(reading.history)) return false
    for (var i = 0; i < reading.history.length; i++) {
      var item = reading.history[i]
      if (item && isFinite(Number(item.timestamp)) && isFinite(Number(item.temperature)))
        return true
    }
    return false
  }
  readonly property real historyLatestTimestamp: {
    var latest = 0
    if (!Array.isArray(reading.history)) return latest
    for (var i = 0; i < reading.history.length; i++) {
      var item = reading.history[i]
      if (!item || !isFinite(Number(item.timestamp))) continue
      latest = Math.max(latest, root.historyTimestamp(item.timestamp))
    }
    return latest
  }
  readonly property bool historyLogStale: historySource === "server"
    && historyLogHasSamples && historyPoints.length === 0
    && historyLatestTimestamp > 0
    && historyWindowEnd - historyLatestTimestamp > Number(historyHours) * 60 * 60
  readonly property real historyChartWindowEnd: historyLogStale
    && historyLatestTimestamp > 0 ? historyLatestTimestamp : historyWindowEnd
  readonly property var historyChartPoints: {
    var revision = root.historyWindowRevision
    return historyLogStale
      ? root.historyPointsForWindow(root.historyLatestTimestamp, root.historyHours)
      : root.historyPoints
  }
  readonly property real homeAssistantPingMs: {
    var value = Number(reading.ping_ms)
    return isFinite(value) && value >= 0 ? value : -1
  }
  readonly property string historyEmptyMessage: historySource === "server"
    ? (String(reading.history_error || "") !== "" ? "EXTERNAL LOG UNAVAILABLE"
      : historyLogStale ? "EXTERNAL LOG STALE · LAST WINDOW UNAVAILABLE"
      : historyLogHasSamples ? "NO READINGS IN SELECTED RANGE" : "WAITING FOR EXTERNAL LOG…")
    : "WAITING FOR LOCAL READINGS…"
  readonly property bool localHomeAssistantConfigured: root.isLocalHomeAssistantUrl(activeHomeAssistantUrl)
  readonly property bool localHomeAssistantConnected: localHomeAssistantConfigured && connected
  readonly property color stateColor: connected && isOn ? root.accentColor : dim
  readonly property color statusColor: hasLocalPower ? root.accentColor : stateColor
  readonly property string deviceInfoText: connected ? String(reading.device_info || "Home Assistant climate") : "Home Assistant climate"
  readonly property string connectionText: !connected ? "OFFLINE"
    : modeRestarting ? "RESTARTING AC…"
    : hasLocalPower ? (localPower === true ? "POWERING ON…" : "POWERING OFF…")
    : isOn ? "ON" : "OFF"
  readonly property real temperatureDelta: connected && isOn
    && isFinite(Number(targetValue)) && isFinite(Number(reading.ambient))
    ? Number(targetValue) - Number(reading.ambient) : 0
  readonly property string moodText: !connected ? "READY"
    : !isOn ? "OFF"
    : Math.abs(temperatureDelta) < 0.5 ? "COMFY"
    : temperatureDelta < 0 ? "COOLER" : "WARMER"
  readonly property real minimumTemperature: connected && isFinite(Number(reading.min_temp))
    ? Number(reading.min_temp) : 16
  readonly property real maximumTemperature: connected && isFinite(Number(reading.max_temp))
    ? Number(reading.max_temp) : 30
  readonly property real temperatureStep: connected && isFinite(Number(reading.step))
    && Number(reading.step) > 0 ? Number(reading.step) : 1
  readonly property real displayMinimumTemperature:
    root.convertTemperature(minimumTemperature, unit, displayTemperatureUnitCode)
  readonly property real displayMaximumTemperature:
    root.convertTemperature(maximumTemperature, unit, displayTemperatureUnitCode)
  readonly property real displayTemperatureStep: {
    var start = root.convertTemperature(minimumTemperature, unit, displayTemperatureUnitCode)
    var end = root.convertTemperature(minimumTemperature + temperatureStep, unit, displayTemperatureUnitCode)
    var result = Math.abs(end - start)
    return isFinite(result) && result > 0 ? result : 1
  }
  readonly property string barLabel: connected
    ? (barIsOn
       ? "󰜗 " + barAmbientText + "\u2009\u2009→\u2009\u2009" + targetText
       : "󰜗 " + barAmbientText + "\u2009\u2009·\u2009\u2009OFF")
    : "󰜗"
  readonly property string tooltip: connected
    ? (String(reading.name || "Air conditioner")
       + (modeRestarting ? " · Restarting AC…"
          : hasLocalPower ? (localPower ? " · Powering on…" : " · Powering off…")
            : " · " + stateLabel(reading.state))
       + " · ambient " + ambientText
       + (!hasLocalPower && isOn ? " · set " + targetText : "")
       + (hasLocalPower && powerCanCancel ? " · right-click to cancel" : ""))
    : "Daikin AC Controls · click to connect"

  function normalizeTemperatureUnitPreference(value) {
    var text = String(value || "").trim().toLowerCase()
    return ["source", "celsius", "fahrenheit", "kelvin"].indexOf(text) >= 0
      ? text : "source"
  }

  function temperatureUnitCode(value) {
    var text = String(value || "").trim().toLowerCase()
    if (text === "f" || text === "°f" || text === "fahrenheit") return "fahrenheit"
    if (text === "k" || text === "kelvin") return "kelvin"
    return "celsius"
  }

  function temperatureUnitSymbol(value) {
    var code = root.temperatureUnitCode(value)
    if (code === "fahrenheit") return "°F"
    if (code === "kelvin") return "K"
    return "°C"
  }

  function convertTemperature(value, sourceUnit, targetUnit) {
    var parsed = Number(value)
    if (!isFinite(parsed)) return Number.NaN
    var source = root.temperatureUnitCode(sourceUnit)
    var target = root.temperatureUnitCode(targetUnit)
    var celsius = source === "fahrenheit" ? (parsed - 32) * 5 / 9
      : source === "kelvin" ? parsed - 273.15 : parsed
    if (target === "fahrenheit") return celsius * 9 / 5 + 32
    if (target === "kelvin") return celsius + 273.15
    return celsius
  }

  function formatTemperatureValue(value, sourceUnit) {
    var converted = root.convertTemperature(value, sourceUnit, displayTemperatureUnitCode)
    if (!isFinite(converted)) return "..."
    var rounded = Math.round(converted * 10) / 10
    return String(rounded).replace(/\.0$/, "") + displayTemperatureUnit
  }

  function temperatureValueFontSize(text, normalSize) {
    var digits = String(text || "").replace(/[^0-9]/g, "").length
    return digits >= 3 ? Math.max(Style.font.display, normalSize - Style.space(4)) : normalSize
  }

  function temperature(value) {
    return formatTemperatureValue(value, unit)
  }

  function formatAverageTemperatureValue(value, displayUnit) {
    var parsed = Number(value)
    if (!isFinite(parsed)) return "..."
    if (averageTemperatureDecimals) return formatTemperatureValue(parsed, displayUnit)
    var converted = root.convertTemperature(parsed, displayUnit, displayTemperatureUnitCode)
    if (!isFinite(converted)) return "..."
    return String(Math.round(converted)) + displayTemperatureUnit
  }

  function mixTemperatureColors(first, second, amount) {
    var t = Math.max(0, Math.min(1, Number(amount)))
    return Qt.rgba(
      first.r + (second.r - first.r) * t,
      first.g + (second.g - first.g) * t,
      first.b + (second.b - first.b) * t,
      1)
  }

  function temperatureTint(value, sourceUnit) {
    var parsed = root.convertTemperature(value, sourceUnit, "celsius")
    if (!isFinite(parsed)) return root.foreground

    var blue = Qt.rgba(0.36, 0.55, 0.66, 1)
    var green = Qt.rgba(0.46, 0.64, 0.53, 1)
    var amber = Qt.rgba(0.73, 0.59, 0.40, 1)
    var warm = Qt.rgba(0.76, 0.45, 0.40, 1)
    var hot = Qt.rgba(0.84, 0.27, 0.29, 1)

    if (parsed <= 24) return blue
    if (parsed < 27) return root.mixTemperatureColors(blue, green, (parsed - 24) / 3)
    if (parsed < 30) return root.mixTemperatureColors(green, amber, (parsed - 27) / 3)
    if (parsed < 33) return root.mixTemperatureColors(amber, warm, (parsed - 30) / 3)
    return root.mixTemperatureColors(warm, hot, Math.min(1, (parsed - 33) / 2))
  }

  function unitReading(entityId) {
    var id = String(entityId || "")
    for (var i = 0; i < unitReadings.length; i++) {
      if (String(unitReadings[i].entity_id || "") === id) return unitReadings[i]
    }
    return null
  }

  function unitLocalState(entityId) {
    var id = String(entityId || "")
    return unitLocalStates && unitLocalStates[id] ? unitLocalStates[id] : ({})
  }

  function copyUnitLocalStates() {
    var next = {}
    var current = unitLocalStates || ({})
    for (var id in current) {
      var source = current[id] || ({})
      var copy = {}
      for (var key in source) copy[key] = source[key]
      next[id] = copy
    }
    return next
  }

  function setUnitLocalStateValue(entityId, key, value) {
    var id = String(entityId || "")
    if (!id) return
    var next = root.copyUnitLocalStates()
    var current = next[id] || ({})
    if (value === null || value === undefined || value === "") delete current[key]
    else current[key] = value
    var hasValues = false
    for (var name in current) {
      hasValues = true
      break
    }
    if (hasValues) next[id] = current
    else delete next[id]
    unitLocalStates = next
    unitLocalStateRevision += 1
  }

  function clearUnitLocalStates() {
    unitLocalStates = ({})
    unitLocalStateRevision += 1
    queuedUnitPowerEntityId = ""
    queuedUnitPowerRequest = ""
    unitPowerDispatchDelayTimer.stop()
  }

  function hasPendingUnitPower() {
    var current = unitLocalStates || ({})
    for (var id in current) {
      if (current[id] && String(current[id].power || "") !== ""
          && current[id].powerTimedOut !== true) return true
    }
    return false
  }

  function hasPendingUnitPowerFinalCheck() {
    var current = unitLocalStates || ({})
    for (var id in current) {
      if (current[id] && current[id].powerFinalCheckPending === true) return true
    }
    return false
  }

  function markUnitPowerFinalChecks() {
    var now = Date.now()
    var next = root.copyUnitLocalStates()
    var changed = false
    for (var id in next) {
      var state = next[id]
      if (!state || !state.power || state.powerTimedOut === true
          || state.powerFinalCheckPending === true) continue
      var startedAt = Number(state.powerStartedAt)
      if (isFinite(startedAt) && startedAt > 0 && now - startedAt >= 15000) {
        state.powerFinalCheckPending = true
        changed = true
      }
    }
    if (!changed || !root.refreshStatus()) return false
    unitLocalStates = next
    unitLocalStateRevision += 1
    return true
  }

  function timeoutUnitPowerFinalChecks() {
    var next = root.copyUnitLocalStates()
    var changed = false
    for (var id in next) {
      var state = next[id]
      if (!state || state.powerFinalCheckPending !== true) continue
      delete state.powerStartedAt
      delete state.powerDispatchDueAt
      delete state.powerReadbackMarker
      delete state.powerFinalCheckPending
      state.powerTimedOut = true
      delete state.powerCanCancel
      changed = true
    }
    if (changed) {
      unitLocalStates = next
      unitLocalStateRevision += 1
    }
    return changed
  }

  function timeoutPendingPowerAfterStatus(message) {
    var messages = []
    if (powerFinalCheckPending) {
      root.timeoutLocalPower(message
        || "Power request timed out after 15 seconds; showing the requested state.")
      messages.push(powerTimeoutMessage)
    }
    if (root.hasPendingUnitPowerFinalCheck()) {
      if (root.timeoutUnitPowerFinalChecks()) {
        messages.push("Power request timed out after 15 seconds; showing the requested AC state.")
      }
    }
    return messages.join(" ")
  }

  function reconcileUnitLocalStates() {
    var current = unitLocalStates || ({})
    var next = {}
    var message = ""
    for (var id in current) {
      var source = current[id] || ({})
      var state = {}
      for (var key in source) state[key] = source[key]
      var climate = root.unitReading(id)
      if (climate) {
        if (state.power) {
          var observedOn = String(climate.state || "").toLowerCase() !== "off"
          var requestedOn = state.power === "turning_on"
          var readbackMarker = root.powerMarker(climate)
          var readbackIsFresh = String(state.powerReadbackMarker || "") !== ""
            && readbackMarker !== "" && readbackMarker !== String(state.powerReadbackMarker)
          var dispatchPending = isFinite(Number(state.powerDispatchDueAt))
            && Number(state.powerDispatchDueAt) > Date.now()
          if (!dispatchPending) {
            if (observedOn === requestedOn
                && (readbackIsFresh || state.powerFinalCheckPending === true
                  || state.powerTimedOut === true)) {
              delete state.power
              delete state.powerStartedAt
              delete state.powerDispatchDueAt
              delete state.powerReadbackMarker
              delete state.powerFinalCheckPending
              delete state.powerTimedOut
              delete state.powerCanCancel
            } else if (state.powerFinalCheckPending === true) {
              delete state.powerStartedAt
              delete state.powerDispatchDueAt
              delete state.powerReadbackMarker
              delete state.powerFinalCheckPending
              state.powerTimedOut = true
              delete state.powerCanCancel
              if (message === "") {
                message = root.entityDisplayName(id)
                  + " power request timed out after 15 seconds; showing the requested state."
              }
            } else if (state.powerTimedOut === true && message === "") {
              message = root.entityDisplayName(id)
                + " power request timed out after 15 seconds; showing the requested state."
            }
          }
        }
        if (state.target !== undefined && root.sameTemperature(climate.target, state.target))
          delete state.target
        if (state.mode && root.sameControlValue(climate.state, state.mode)) delete state.mode
        if (state.fan && root.sameControlValue(climate.fan_mode, state.fan)) delete state.fan
      }
      var hasValues = false
      for (var field in state) {
        hasValues = true
        break
      }
      if (hasValues) next[id] = state
    }
    unitLocalStates = next
    unitLocalStateRevision += 1
    return message
  }

  function rejectUnitLocalAction() {
    var id = String(actionEntityId || "")
    if (!id) return
    if (actionKind === "unit-temperature") root.setUnitLocalStateValue(id, "target", null)
    else if (actionKind === "unit-mode") root.setUnitLocalStateValue(id, "mode", null)
    else if (actionKind === "unit-fan") root.setUnitLocalStateValue(id, "fan", null)
    else if (actionKind === "unit-power") {
      // Keep the optimistic power latch alive until its 15-second readback
      // window expires. A slow or empty helper response is not a rejection.
    }
  }

  function entityDisplayName(entityId) {
    var id = String(entityId || "")
    var item = unitReading(id)
    if (item && String(item.name || "").trim() !== "") return String(item.name)
    for (var i = 0; i < entityOptions.length; i++) {
      if (String(entityOptions[i].value || "") === id) {
        var label = String(entityOptions[i].label || id)
        var separator = label.indexOf(" · ")
        return separator >= 0 ? label.slice(0, separator) : label
      }
    }
    return id
  }

  function anyUnitOn() {
    for (var i = 0; i < unitReadings.length; i++) {
      var id = String(unitReadings[i].entity_id || "")
      var state = root.unitLocalState(id)
      if (state.power) {
        if (state.power === "turning_on") return true
        continue
      }
      if (String(unitReadings[i].state || "").toLowerCase() !== "off") return true
    }
    return false
  }

  function averageAmbientText() {
    var value = root.averageAmbientValue()
    var readings = unitReadings.length > 0 ? unitReadings : [reading]
    var firstUnit = readings.length > 0 ? String(readings[0].unit || unit) : unit
    return formatAverageTemperatureValue(value, firstUnit)
  }

  function averageAmbientValue() {
    var readings = unitReadings.length > 0 ? unitReadings : [reading]
    if (readings.length === 0) return Number.NaN
    var firstUnit = String(readings[0].unit || unit)
    var sum = 0
    var count = 0
    var sameUnits = true
    for (var i = 0; i < readings.length; i++) {
      var value = Number(readings[i].ambient)
      if (!isFinite(value)) continue
      if (String(readings[i].unit || firstUnit) !== firstUnit) sameUnits = false
      sum += value
      count += 1
    }
    return count > 0 && sameUnits ? sum / count : Number(reading.ambient)
  }

  function mainAmbientValue() {
    return multiUnitActive ? root.averageAmbientValue() : Number(reading.ambient)
  }

  function formatBarAmbient() {
    var readings = []
    var all = unitReadings.length > 0 ? unitReadings : [reading]
    var mode = String(barTemperatureMode || "average")
    if (mode === "selected") {
      var wanted = Array.isArray(barTemperatureEntities) ? barTemperatureEntities : []
      for (var i = 0; i < all.length; i++) {
        if (wanted.indexOf(String(all[i].entity_id || "")) >= 0) readings.push(all[i])
      }
      if (readings.length === 0) readings = all
    } else {
      readings = all
    }
    if (readings.length === 0) return ambientText
    if (mode === "average") {
      var sum = 0
      var count = 0
      var firstUnit = String(readings[0].unit || unit)
      var sameUnits = true
      for (var j = 0; j < readings.length; j++) {
        var value = Number(readings[j].ambient)
        if (!isFinite(value)) continue
        if (String(readings[j].unit || firstUnit) !== firstUnit) sameUnits = false
        sum += value
        count += 1
      }
      if (count > 0 && sameUnits) return formatAverageTemperatureValue(sum / count, firstUnit)
    }
    var labels = []
    for (var k = 0; k < readings.length; k++) {
      var label = formatTemperatureValue(readings[k].ambient, readings[k].unit || unit)
      if (label !== "...") labels.push(label)
    }
    return labels.length > 0 ? labels.join(" · ") : ambientText
  }

  function sameTemperature(first, second) {
    var a = Number(first)
    var b = Number(second)
    return isFinite(a) && isFinite(b) && Math.abs(a - b) < 0.001
  }

  function stateLabel(value) {
    var state = String(value || "unknown").replace(/_/g, " ")
    if (state.length === 0) return "Unknown"
    return state.charAt(0).toUpperCase() + state.slice(1)
  }

  function normalizeHistoryHours(value) {
    var next = Number(value)
    if (!isFinite(next)) return 24
    next = Math.max(1, Math.min(31 * 24, next))
    return Math.round(next * 100) / 100
  }

  function historyMaximumHours() {
    return experimentalHistoryEnabled ? 31 * 24 : 24
  }

  function formatHours(value) {
    var next = normalizeHistoryHours(value)
    return String(next).replace(/\.0$/, "")
  }

  function formatHistoryDuration(value) {
    var next = normalizeHistoryHours(value)
    if (next === 1) return "1 HOUR"
    if (next === 168) return "7 DAYS"
    if (next === 720) return "30 DAYS"
    return root.formatHours(next) + " HOURS"
  }

  function historyPresetValue(value) {
    var next = Number(value)
    return isFinite(next) && [1, 3, 6, 12, 24, 168, 720].indexOf(next) !== -1
      ? String(next) : "custom"
  }

  function controlLabel(value) {
    var words = String(value || "").replace(/[_-]+/g, " ").split(/\s+/)
    var result = []
    for (var i = 0; i < words.length; i++) {
      if (words[i] === "") continue
      result.push(words[i].charAt(0).toUpperCase() + words[i].slice(1).toLowerCase())
    }
    return result.join(" ")
  }

  function climateModeIcon(value) {
    var mode = String(value || "").trim().toLowerCase()
    if (mode === "heat") return "󰈸"
    if (mode === "dry") return "󰖌"
    if (mode === "fan_only" || mode === "fan only" || mode === "fan") return "󰡣"
    if (mode === "auto" || mode === "heat_cool" || mode === "heat cool") return "󰖙"
    if (mode === "cool") return "󰜗"
    return "󰜗"
  }

  function sameControlValue(first, second) {
    var a = String(first || "").trim().toLowerCase()
    var b = String(second || "").trim().toLowerCase()
    return a !== "" && a === b
  }

  function powerMarker(climate) {
    if (!climate) return ""
    var changed = String(climate.last_changed || "")
    return changed !== "" ? changed : String(climate.last_updated || "")
  }

  function formatControlOptions(items, excludeOff) {
    var next = []
    if (!Array.isArray(items)) return next
    for (var i = 0; i < items.length; i++) {
      var value = String(items[i] || "").trim()
      if (!value || (excludeOff && value.toLowerCase() === "off")) continue
      var duplicate = false
      for (var j = 0; j < next.length; j++) {
        if (sameControlValue(next[j].value, value)) { duplicate = true; break }
      }
      if (!duplicate) next.push({ value: value, label: controlLabel(value) })
    }
    return next
  }

  function clearLocalPower() {
    pendingPowerState = ""
    powerRequestStartedAt = 0
    powerDispatchDueAt = 0
    powerReadbackMarker = ""
    powerFinalCheckPending = false
    powerTimedOut = false
    powerTimeoutMessage = ""
    powerCanCancel = false
    queuedPowerRequest = ""
    powerDispatchDelayTimer.stop()
  }

  function timeoutLocalPower(message) {
    powerFinalCheckPending = false
    powerTimedOut = true
    powerTimeoutMessage = message || "Power request timed out after 15 seconds; showing the requested state."
    powerCanCancel = false
    errorText = powerTimeoutMessage
  }

  function beginModeRestart() {
    modeRestarting = true
    modeRestartStartedAt = Date.now()
  }

  function clearModeRestart() {
    modeRestarting = false
    modeRestartStartedAt = 0
  }

  function clearLocalClimateControls() {
    localMode = ""
    localFanMode = ""
    modeInFlight = ""
    fanModeInFlight = ""
    root.clearModeRestart()
    queuedControlKind = ""
    queuedControlValue = ""
  }

  function rejectLocalAction() {
    if (actionKind === "temperature") {
      var failedTarget = temperatureInFlight
      if (failedTarget !== null && (!hasLocalTarget || sameTemperature(localTarget, failedTarget))) {
        localTarget = null
        lastTemperatureSent = null
      }
    } else if (actionKind === "mode") {
      if (modeInFlight !== "" && sameControlValue(localMode, modeInFlight)) localMode = ""
      modeInFlight = ""
      root.clearModeRestart()
    } else if (actionKind === "fan") {
      if (fanModeInFlight !== "" && sameControlValue(localFanMode, fanModeInFlight)) localFanMode = ""
      fanModeInFlight = ""
    } else if (actionKind.indexOf("unit-") === 0) {
      root.rejectUnitLocalAction()
    }
  }

  function normalizeTarget(value) {
    var next = Number(value)
    if (!isFinite(next)) return null
    next = Math.round(next / temperatureStep) * temperatureStep
    next = Math.round(next * 100) / 100
    next = Math.max(minimumTemperature, next)
    next = Math.min(maximumTemperature, next)
    return next
  }

  function formatEntityOptions(items) {
    var next = []
    if (!Array.isArray(items)) return next
    for (var i = 0; i < items.length; i++) {
      var item = items[i]
      var id = typeof item === "object" ? String(item.id || item.value || "") : String(item)
      if (!id || id.indexOf("climate.") !== 0) continue
      var name = typeof item === "object" ? String(item.name || item.label || id) : id
      var label = name === id ? id : name + " · " + id
      var duplicate = false
      for (var j = 0; j < next.length; j++) {
        if (next[j].value === id) { duplicate = true; break }
      }
      if (!duplicate) next.push({ value: id, label: label })
    }
    return next
  }

  function selectedEntityDropdownItems() {
    var next = [{ value: "", label: "Choose selected AC" }]
    for (var i = 0; i < selectedEntities.length; i++) {
      var id = String(selectedEntities[i] || "")
      next.push({ value: id, label: entityDisplayName(id) })
    }
    return next
  }

  function setEntityOptions(items) {
    entityOptions = root.formatEntityOptions(items)
  }

  function setSetupEntityOptions(items) {
    setupEntityOptions = root.formatEntityOptions(items)
  }

  function normalizeSelectedEntities(items, fallback) {
    var next = []
    var source = Array.isArray(items) ? items : []
    for (var i = 0; i < source.length && next.length < 12; i++) {
      var id = String(source[i] || "").trim()
      if (id.indexOf("climate.") !== 0 || /\s/.test(id) || next.indexOf(id) >= 0) continue
      next.push(id)
    }
    var fallbackId = String(fallback || "").trim()
    if (next.length === 0 && fallbackId.indexOf("climate.") === 0 && !/\s/.test(fallbackId))
      next.push(fallbackId)
    return next
  }

  function applyExperimentalValues(parsed) {
    if (!parsed) return
    multiUnitEnabled = parsed.multi_unit_enabled === true
    multiUnitEnabledPrevious = multiUnitEnabled
    globalSyncControls = parsed.global_sync_controls !== false
    globalSyncControlsPrevious = globalSyncControls
    syncNonPowerControls = parsed.sync_non_power_controls !== false
    syncNonPowerControlsPrevious = syncNonPowerControls
    averageTemperatureDecimals = parsed.average_temperature_decimals === true
    averageTemperatureDecimalsPrevious = averageTemperatureDecimals
    temperatureUnitPreference = root.normalizeTemperatureUnitPreference(parsed.temperature_unit)
    temperatureUnitPreferencePrevious = temperatureUnitPreference
    selectedEntities = normalizeSelectedEntities(parsed.selected_entities, selectedEntity)
    var parsedBarMode = String(parsed.bar_temperature_mode || "average")
    barTemperatureMode = ["average", "all", "selected"].indexOf(parsedBarMode) >= 0
      ? parsedBarMode : "average"
    barTemperatureModePrevious = barTemperatureMode
    barTemperatureEntities = normalizeSelectedEntities(
      parsed.bar_temperature_entities, selectedEntities.length > 0 ? selectedEntities : selectedEntity)
    barTemperatureEntitiesPrevious = barTemperatureEntities.slice()
    experimentalHistoryEnabled = parsed.experimental_history_enabled === true
    experimentalHistoryEnabledPrevious = experimentalHistoryEnabled
    shortcutsEnabled = parsed.shortcuts_enabled === true
    shortcutsEnabledPrevious = shortcutsEnabled
    globalTabNavigationEnabled = parsed.global_tab_navigation_enabled === true
    globalTabNavigationEnabledPrevious = globalTabNavigationEnabled
    configFileModeEnabled = parsed.config_file_mode_enabled === true
    configFileModeEnabledPrevious = configFileModeEnabled
    shortcutValues = normalizeShortcutValues(parsed.shortcuts)
    shortcutValuesPrevious = copyShortcutValues(shortcutValues)
    if (!shortcutsEnabled && settingsSection === "shortcuts") settingsSection = "experimental"
    if (shortcutsEnabled) Qt.callLater(root.syncShortcutBindings)
    customAppearanceEnabled = parsed.custom_appearance_enabled === true
    customAppearanceEnabledPrevious = customAppearanceEnabled
    appearanceAutoAccent = parsed.appearance_auto_accent !== false
    appearanceAutoAccentPrevious = appearanceAutoAccent
    appearanceAutoBackground = parsed.appearance_auto_background !== false
    appearanceAutoBackgroundPrevious = appearanceAutoBackground
    customAccentHexText = String(parsed.appearance_accent || "#8FA79F")
    customAccentHexTextPrevious = customAccentHexText
    customAccentColor = customAccentHexText
    customAccentColorPrevious = customAccentColor
    customControlHexText = String(parsed.appearance_control || "#8FA79F")
    customControlHexTextPrevious = customControlHexText
    customControlColor = customControlHexText
    customControlColorPrevious = customControlColor
    customBackgroundHexText = String(parsed.appearance_background || "#131516")
    customBackgroundHexTextPrevious = customBackgroundHexText
    customBackgroundColor = customBackgroundHexText
    customBackgroundColorPrevious = customBackgroundColor
    appearanceDeviceColorsEnabled = parsed.appearance_device_colors_enabled === true
    appearanceDeviceColorsEnabledPrevious = appearanceDeviceColorsEnabled
    appearanceDeviceColors = normalizeAppearanceDeviceColors(parsed.appearance_device_colors)
    appearanceDeviceColorsPrevious = copyAppearanceDeviceColors()
    appearanceTransparency = Math.max(0, Math.min(100, Number(parsed.appearance_transparency) || 0))
    appearanceTransparencyPrevious = appearanceTransparency
    appearanceTransparencyText = formatAppearanceValue(appearanceTransparency)
    appearanceBlur = Math.max(0, Math.min(24, Number(parsed.appearance_blur) || 0))
    appearanceBlurPrevious = appearanceBlur
    appearanceBlurText = formatAppearanceValue(appearanceBlur)
    appearanceRadius = Math.max(8, Math.min(32, Number(parsed.appearance_radius) || 16))
    appearanceRadiusPrevious = appearanceRadius
    appearanceRadiusText = formatAppearanceValue(appearanceRadius)
    compactUiEnabled = parsed.appearance_compact === true
    compactUiEnabledPrevious = compactUiEnabled
    appearanceOuterBorderEnabled = parsed.appearance_outer_border_enabled !== false
    appearanceOuterBorderEnabledPrevious = appearanceOuterBorderEnabled
  }

  function formatAppearanceValue(value) {
    var number = Number(value)
    if (!isFinite(number)) return "0"
    return String(Math.round(number * 10) / 10).replace(/\.0$/, "")
  }

  function mergeEntityIds(ids) {
    var combined = entityOptions.slice()
    for (var i = 0; i < ids.length; i++) {
      var id = String(ids[i] || "")
      if (!id || id.indexOf("climate.") !== 0) continue
      var exists = false
      for (var j = 0; j < combined.length; j++) {
        if (combined[j].value === id) { exists = true; break }
      }
      if (!exists) combined.push({ value: id, label: id })
    }
    entityOptions = combined
  }

  function openFromHotkey() {
    root.controller.show()
    root.loadConfig()
    root.refresh()
  }

  function navigateSettings(direction) {
    var sections = root.settingsSections
    if (!sections || sections.length === 0) return
    var current = -1
    for (var i = 0; i < sections.length; i++) {
      if (sections[i].value === root.settingsSection) {
        current = i
        break
      }
    }
    if (current < 0) current = 0
    var next = current + (Number(direction) < 0 ? -1 : 1)
    if (next < 0) next = sections.length - 1
    if (next >= sections.length) next = 0
    root.settingsSection = sections[next].value
  }

  function openSettingsFromShortcut() {
    root.controller.show()
    root.loadConfig(true)
    root.refresh()
    Qt.callLater(function() {
      if (!root.setupOpen) root.openSetup()
    })
  }

  function navigateSettingsFromShortcut(direction) {
    root.controller.show()
    root.loadConfig(true)
    root.refresh()
    Qt.callLater(function() {
      if (!root.configured) return
      if (!root.setupOpen) root.openSetup()
      Qt.callLater(function() {
        if (root.setupOpen) root.navigateSettings(direction)
      })
    })
  }

  function open() { root.openFromHotkey() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.openFromHotkey() }
  function closeForPopoutSwitch() {
    root.popoutSwitchClosing = true
    root.close()
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refreshStatus() {
    if (statusProcess.running || actionProcess.running || setupProcess.running
        || preferenceProcess.running || remoteHistoryProcess.running
        || configFileProcess.running || turnOffAllProcess.running || turnOnAllProcess.running) return false
    statusProcess.command = ["python3", root.helperPath, "status"]
    statusProcess.running = true
    return true
  }

  function loadConfig(force) {
    if (force === true && !configProcess.running) configResolved = false
    if (configResolved || configProcess.running) return
    configProcess.command = ["python3", root.helperPath, "config"]
    configProcess.running = true
  }

  function refresh() {
    root.loadConfig()
    if (setupProcess.running) return
    if (!entitiesProcess.running) {
      entitiesProcess.command = ["python3", root.helperPath, "entities"]
      entitiesProcess.running = true
    }
    root.refreshStatus()
  }

  function syncShortcutBindings() {
    if (!root.shortcutsEnabled || shortcutSyncProcess.running) return
    shortcutSyncProcess.command = ["python3", root.helperPath, "sync-shortcuts"]
    shortcutSyncProcess.running = true
  }

  function openSetup() {
    if (setupProcess.running || setupTransitioning) return
    localServerConfirmTimer.stop()
    localServerConfirming = false
    connectionEditing = false
    connectionReconnecting = false
    localServerExpanded = false
    setupError = ""
    setupEntityOptions = []
    setupSelectedEntity = ""
    setupToken = ""
    if (root.configured) settingsSection = "preferences"
    if (setupUrl === "") setupUrl = "http://homeassistant.local:8123"
    root.syncSetupAddressFields(root.setupUrl)
    if (root.configured && root.opened) {
      setupTransitionClosing = false
      setupTransitioning = true
      setupOpen = false
      setupTransitionTimer.restart()
    } else {
      setupTransitionClosing = false
      setupOpen = true
      Qt.callLater(function() { setupHostField.forceActiveFocus() })
    }
    if (root.configFileModeEnabled)
      root.scheduleConfigFileRefresh()
  }

  function cancelSetup() {
    setupTransitionTimer.stop()
    setupTransitionFinishTimer.stop()
    localServerConfirmTimer.stop()
    localServerConfirming = false
    connectionEditing = false
    connectionReconnecting = false
    if (activeHomeAssistantUrl !== "") setupUrl = activeHomeAssistantUrl
    setupToken = ""
    if (remoteHistoryReconfiguring && !remoteHistoryBusy)
      root.cancelRemoteHistoryReconfigure()
    else {
      remoteHistoryReconfiguring = false
      remoteHistoryMessage = ""
      remoteHistoryError = ""
    }
    if (!configured) {
      setupTransitioning = false
      setupTransitionClosing = false
      root.close()
      return
    }
    setupTransitionClosing = true
    setupTransitioning = true
    setupOpen = false
    setupError = ""
    setupEntityOptions = []
    setupSelectedEntity = ""
    setupToken = ""
    setupTransitionFinishTimer.restart()
    root.refresh()
  }

  function submitSetup(reconnect) {
    if (reconnect === true ? !root.reconnectCanSubmit : !root.setupCanSubmit) return
    if (!root.updateSetupUrlFromAddress()) {
      setupError = "Enter a valid Home Assistant address and port."
      return
    }
    setupError = ""
    setupSucceeded = false
    connectionReconnecting = reconnect === true
    setupPayload = JSON.stringify({
      url: String(root.setupUrl || "").trim(),
      token: String(setupToken || "").trim(),
      reuse_saved_token: reconnect === true && root.reconnectCanReuseSavedToken,
      entity_id: setupSelectedEntity,
      advanced_controls: root.showClimateControls,
      master_switch_enabled: root.masterSwitchEnabled,
    })
    setupBusy = true
    setupProcess.command = ["python3", root.helperPath, "configure"]
    setupProcess.running = true
  }

  function beginReconnect() {
    if (setupBusy || preferenceBusy || !configured) return
    connectionEditing = true
    connectionReconnecting = false
    setupError = ""
    setupToken = ""
    setupUrl = activeHomeAssistantUrl || setupUrl
    setupSelectedEntity = selectedEntity
  }

  function cancelReconnect() {
    if (setupBusy) return
    connectionEditing = false
    connectionReconnecting = false
    setupError = ""
    setupToken = ""
    if (activeHomeAssistantUrl !== "") setupUrl = activeHomeAssistantUrl
  }

  function setHistorySource(value) {
    if (preferenceProcess.running) return
    var next = String(value || "").trim().toLowerCase()
    if (["local", "server"].indexOf(next) === -1 || next === historySource) return
    historySourcePrevious = historySource
    historySource = next
    remoteHistoryError = ""
    preferenceKind = "history_source"
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "history_source", next
    ]
    preferenceProcess.running = true
  }

  function openHomeAssistantSettings() {
    root.updateSetupUrlFromAddress()
    var url = String(activeHomeAssistantUrl || setupUrl || "").trim()
    if (url === "") {
      remoteHistoryError = "Set the Home Assistant address first."
      return
    }
    if (!Qt.openUrlExternally(url)) {
      remoteHistoryMessage = "Open Home Assistant at " + url + "."
    }
  }

  function openExternalHistoryGuide() {
    remoteHistoryError = ""
    if (!Qt.openUrlExternally(root.externalHistoryGuideUrl)) {
      remoteHistoryError = "Could not open the external-server guide. Open the project page manually."
      return
    }
    remoteHistoryMessage = "External-server setup guide opened."
  }

  function clearRemoteHistoryStatus() {
    remoteHistoryStatusTarget = ""
    remoteHistoryStatusPortText = ""
    remoteHistoryStatusPath = ""
    remoteHistoryStatusAvailable = false
    remoteHistoryStatusPingMs = -1
  }

  function recordRemoteHistoryStatus(parsed) {
    if (!parsed || parsed.history_source !== "server") {
      root.clearRemoteHistoryStatus()
      return
    }
    remoteHistoryStatusTarget = String(remoteHistoryTarget || "").trim()
    remoteHistoryStatusPortText = String(remoteHistoryPortText || "22").trim()
    remoteHistoryStatusPath = String(remoteHistoryPath || root.remoteHistoryDefaultPath).trim()
    remoteHistoryStatusAvailable = parsed.history_available === true
    var ping = Number(parsed.history_ping_ms)
    remoteHistoryStatusPingMs = remoteHistoryStatusAvailable && isFinite(ping) && ping >= 0
      ? ping : -1
  }

  function beginRemoteHistoryReconfigure() {
    if (remoteHistoryBusy) return
    remoteHistoryTargetBeforeReconfigure = remoteHistoryTarget
    remoteHistoryPortBeforeReconfigure = remoteHistoryPortText
    remoteHistoryUrlBeforeReconfigure = remoteHistoryUrl
    remoteHistoryPathBeforeReconfigure = remoteHistoryPath
    remoteHistoryReconfiguring = true
    remoteHistoryMessage = ""
    remoteHistoryError = ""
  }

  function copyRemoteHistorySource() {
    if (root.remoteHistorySourceBusy) return
    root.remoteHistorySourceBusy = true
    root.remoteHistorySourcePayload = ""
    remoteHistoryError = ""
    remoteHistoryMessage = "Preparing installer, logger, and cleanup source…"
    remoteHistorySourceProcess.command = ["python3", root.helperPath, "remote-history-source"]
    remoteHistorySourceProcess.running = true
  }

  function applyRemoteHistorySource(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      remoteHistorySourceBusy = false
      remoteHistoryMessage = ""
      remoteHistoryError = "The external-server source returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (!parsed || parsed.ok !== true || String(parsed.source || "") === "") {
        remoteHistorySourceBusy = false
        remoteHistoryMessage = ""
        remoteHistoryError = parsed && parsed.error
          ? String(parsed.error) : "The external-server source could not be prepared."
        return
      }
      remoteHistorySourcePayload = String(parsed.source)
      Quickshell.execDetached(["bash", "-c", "printf %s "
        + Util.shellQuote(remoteHistorySourcePayload) + " | wl-copy"])
      remoteHistorySourceBusy = false
      remoteHistoryError = ""
      remoteHistoryMessage = "Installer, logger, and uninstall source copied to the clipboard."
    } catch (e) {
      remoteHistorySourceBusy = false
      remoteHistoryMessage = ""
      remoteHistoryError = "The external-server source returned invalid data."
    }
  }

  function startRemoteHistoryInstall() {
    if (remoteHistoryBusy || remoteHistorySourceBusy || setupBusy || preferenceBusy) return
    var target = String(remoteHistoryTarget || "").trim()
    if (target === "") {
      remoteHistoryError = "Enter an SSH target such as user@192.168.1.20."
      return
    }
    if (String(remoteHistoryUrl || "").trim() === "") {
      remoteHistoryError = "Enter the Home Assistant URL reachable from the server."
      return
    }
    remoteHistoryBusy = true
    remoteHistoryAction = "install"
    remoteHistoryOperationSucceeded = false
    root.clearRemoteHistoryStatus()
    remoteHistoryMessage = "Installing a server timer over SSH…"
    remoteHistoryError = ""
    remoteHistoryPayload = JSON.stringify({
      ssh_target: target,
      ssh_port: String(remoteHistoryPortText || "22").trim(),
      home_assistant_url: String(remoteHistoryUrl || "").trim(),
      entity_id: root.selectedEntity,
      entity_ids: root.selectedEntities.length > 0
        ? root.selectedEntities : [root.selectedEntity],
      history_path: root.remoteHistoryPath,
    })
    remoteHistoryProcess.command = ["python3", root.helperPath, "install-remote-history"]
    remoteHistoryProcess.running = true
  }

  function startRemoteHistoryConnect() {
    if (remoteHistoryBusy || remoteHistorySourceBusy || setupBusy || preferenceBusy) return
    var target = String(remoteHistoryTarget || "").trim()
    if (target === "") {
      remoteHistoryError = "Enter the external server address, such as user@192.168.1.20."
      return
    }
    remoteHistoryBusy = true
    remoteHistoryAction = "connect"
    remoteHistoryOperationSucceeded = false
    root.clearRemoteHistoryStatus()
    remoteHistoryMessage = "Connecting to the external server over SSH…"
    remoteHistoryError = ""
    remoteHistoryPayload = JSON.stringify({
      ssh_target: target,
      ssh_port: String(remoteHistoryPortText || "22").trim(),
      home_assistant_url: String(remoteHistoryUrl || "").trim(),
      history_path: root.remoteHistoryPath,
    })
    remoteHistoryProcess.command = ["python3", root.helperPath, "connect-remote-history"]
    remoteHistoryProcess.running = true
  }

  function cancelRemoteHistoryReconfigure() {
    if (remoteHistoryBusy) return
    if (remoteHistoryTargetBeforeReconfigure !== "") {
      remoteHistoryTarget = remoteHistoryTargetBeforeReconfigure
      remoteHistoryPortText = remoteHistoryPortBeforeReconfigure
      remoteHistoryUrl = remoteHistoryUrlBeforeReconfigure
      remoteHistoryPath = remoteHistoryPathBeforeReconfigure
    }
    remoteHistoryReconfiguring = false
    remoteHistoryMessage = ""
    remoteHistoryError = ""
  }

  function applyRemoteHistoryResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      remoteHistoryError = "The external server connection returned no data."
      remoteHistoryMessage = ""
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true) {
        historySource = "server"
        historySourcePrevious = "server"
        remoteHistoryTarget = String(parsed.history_remote_target || remoteHistoryTarget)
        remoteHistoryPortText = String(parsed.history_remote_port || remoteHistoryPortText)
        remoteHistoryUrl = String(parsed.history_remote_url || remoteHistoryUrl)
        remoteHistoryPath = String(parsed.history_remote_path || remoteHistoryPath)
        remoteHistoryPairingSaved = true
        remoteHistoryTargetBeforeReconfigure = remoteHistoryTarget
        remoteHistoryPortBeforeReconfigure = remoteHistoryPortText
        remoteHistoryUrlBeforeReconfigure = remoteHistoryUrl
        remoteHistoryPathBeforeReconfigure = remoteHistoryPath
        remoteHistoryError = ""
        remoteHistoryMessage = String(parsed.message || "External server connection saved.")
        remoteHistoryOperationSucceeded = true
        remoteHistoryReconfiguring = parsed.history_available === false
        return
      }
      remoteHistoryOperationSucceeded = false
      remoteHistoryMessage = ""
      remoteHistoryError = parsed && parsed.error
        ? String(parsed.error) : "The server history installer could not complete."
    } catch (e) {
      remoteHistoryOperationSucceeded = false
      remoteHistoryMessage = ""
      remoteHistoryError = "The server history installer returned invalid data."
    }
  }

  function openLocalServer() {
    setupUrl = root.localServerUrl
    var opened = Qt.openUrlExternally(root.localServerUrl)
    if (!opened) {
      localServerMessage = "Home Assistant should be available at " + root.localServerUrl + "."
    }
  }

  function requestLocalServerSetup() {
    if (localServerBusy || setupBusy || preferenceBusy) return
    if (!localServerConfirming) {
      localServerError = ""
      localServerMessage = ""
      localServerConfirming = true
      localServerConfirmTimer.restart()
      return
    }
    localServerConfirmTimer.stop()
    localServerConfirming = false
    root.startLocalServer()
  }

  function cancelLocalServerSetup() {
    if (localServerBusy) return
    localServerConfirmTimer.stop()
    localServerConfirming = false
    localServerError = ""
  }

  function startLocalServer() {
    if (localServerProcess.running || setupProcess.running || preferenceProcess.running) return
    localServerConfirming = false
    localServerError = ""
    localServerMessage = "Checking Docker and preparing the local Home Assistant container…"
    localServerReady = false
    setupUrl = root.localServerUrl
    localServerBusy = true
    localServerProcess.command = [root.localServerScriptPath]
    localServerProcess.running = true
  }

  function applyLocalServerResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      localServerError = "The local Home Assistant setup returned no data."
      localServerMessage = ""
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true) {
        localServerError = ""
        localServerReady = true
        setupUrl = String(parsed.url || root.localServerUrl)
        localServerMessage = String(parsed.message || "Home Assistant is ready locally.")
        var opened = Qt.openUrlExternally(setupUrl)
        if (!opened) {
          localServerMessage += " Open it at " + setupUrl + "."
        }
        return
      }
      localServerReady = false
      localServerMessage = ""
      localServerError = parsed && parsed.error
        ? String(parsed.error) : "The local Home Assistant setup could not be completed."
    } catch (e) {
      localServerReady = false
      localServerMessage = ""
      localServerError = "The local Home Assistant setup returned invalid data."
    }
  }

  function requestResetApp() {
    if (resetAppBusy || uninstallBusy || uninstallConfirming) return
    resetAppError = ""
    resetAppMessage = ""
    resetAppConfirming = true
  }

  function cancelResetApp() {
    if (resetAppBusy) return
    resetAppConfirming = false
    resetAppError = ""
  }

  function resetApp() {
    if (resetAppBusy || uninstallBusy || uninstallConfirming
        || setupProcess.running || localServerProcess.running
        || preferenceProcess.running || actionProcess.running || statusProcess.running
        || configProcess.running || entitiesProcess.running) return
    resetAppBusy = true
    resetAppError = ""
    resetAppMessage = ""
    resetAppProcess.command = ["python3", root.helperPath, "reset-app"]
    resetAppProcess.running = true
  }

  function requestUninstall() {
    if (uninstallBusy || resetAppBusy || setupBusy || localServerBusy || preferenceBusy
        || remoteHistoryBusy || remoteHistorySourceBusy) return
    uninstallConfirming = true
    uninstallOptionConfirming = false
    uninstallMode = ""
    uninstallMessage = ""
    uninstallError = ""
  }

  function cancelUninstall() {
    if (uninstallBusy) return
    uninstallConfirming = false
    uninstallOptionConfirming = false
    uninstallMode = ""
    uninstallError = ""
  }

  function chooseUninstallMode(mode) {
    if (uninstallBusy) return
    var next = String(mode || "").trim().toLowerCase()
    if (["everything", "app_logger", "plugin"].indexOf(next) === -1) return
    uninstallMode = next
    uninstallOptionConfirming = true
    uninstallError = ""
  }

  function uninstallActionLabel() {
    if (uninstallMode === "everything") return "REMOVE EVERYTHING"
    if (uninstallMode === "app_logger") return "REMOVE APP + LOGGER"
    return "REMOVE PLUGIN ONLY"
  }

  function uninstallNotice(mode) {
    var selectedMode = String(mode || uninstallMode)
    if (selectedMode === "everything") {
      return "Removes this plugin, its saved data, the external logger if configured, and the plugin-managed local Home Assistant container and data if present. Docker itself, its image, and unrelated containers stay untouched. Docker may ask for administrator approval."
    }
    if (selectedMode === "app_logger") {
      return "Removes this plugin, its saved connection and local chart, and the external logger if configured. A local Home Assistant container and its data stay untouched."
    }
    return "Removes only the installed plugin files. Saved connection, local chart, local Home Assistant, and any external logger stay untouched."
  }

  function startUninstall() {
    if (uninstallBusy || resetAppBusy || setupBusy || localServerBusy || preferenceBusy
        || remoteHistoryBusy || remoteHistorySourceBusy || setupProcess.running
        || actionProcess.running || statusProcess.running || configProcess.running
        || entitiesProcess.running) return
    var command = ["bash", root.pluginDir + "/uninstall-plugin.sh"]
    if (uninstallMode === "app_logger" || uninstallMode === "everything")
      command.push("--remove-local-data")
    if (uninstallMode === "everything") command.push("--remove-local-homeassistant")
    if (uninstallMode === "app_logger" || uninstallMode === "everything") {
      var target = String(remoteHistoryTarget || "").trim()
      if (target !== "") {
        command.push(
          "--remove-external-history",
          "--ssh-target", target,
          "--ssh-port", String(remoteHistoryPortText || "22").trim(),
          "--history-path", String(remoteHistoryPath || root.remoteHistoryDefaultPath).trim()
        )
      }
    }
    uninstallMessage = "Goodbye :( Removing Daikin AC Controls…"
    uninstallError = ""
    uninstallProcessStderr = ""
    uninstallBusy = true
    uninstallProcess.command = command
    uninstallProcess.running = true
  }

  function confirmTurnOffAll() {
    if (!masterSwitchEnabled || masterSwitchBusy || turnOnAllConfirming) return
    if (!turnOffAllConfirming) {
      turnOffAllError = ""
      turnOffAllMessage = ""
      turnOnAllError = ""
      turnOnAllMessage = ""
      turnOffAllConfirming = true
      turnOffAllConfirmTimer.restart()
      return
    }
    turnOffAllConfirmTimer.stop()
    if (setupProcess.running || localServerProcess.running || preferenceProcess.running
        || resetAppProcess.running || actionProcess.running || statusProcess.running
        || configProcess.running || entitiesProcess.running) {
      turnOffAllConfirming = false
      turnOffAllError = "Wait for the current control request to finish, then try again."
      return
    }
    turnOffAllBusy = true
    turnOffAllConfirming = false
    turnOffAllError = ""
    turnOffAllMessage = ""
    turnOffAllProcess.command = ["python3", root.helperPath, "turn-off-all"]
    turnOffAllProcess.running = true
  }

  function cancelTurnOffAll() {
    if (turnOffAllBusy) return
    turnOffAllConfirmTimer.stop()
    turnOffAllConfirming = false
    turnOffAllError = ""
  }

  function confirmTurnOnAll() {
    if (!masterSwitchEnabled || masterSwitchBusy || turnOffAllConfirming) return
    if (!turnOnAllConfirming) {
      turnOnAllError = ""
      turnOnAllMessage = ""
      turnOffAllError = ""
      turnOffAllMessage = ""
      turnOnAllConfirming = true
      turnOnAllConfirmTimer.restart()
      return
    }
    turnOnAllConfirmTimer.stop()
    if (setupProcess.running || localServerProcess.running || preferenceProcess.running
        || resetAppProcess.running || actionProcess.running || statusProcess.running
        || configProcess.running || entitiesProcess.running) {
      turnOnAllConfirming = false
      turnOnAllError = "Wait for the current control request to finish, then try again."
      return
    }
    turnOnAllBusy = true
    turnOnAllConfirming = false
    turnOnAllError = ""
    turnOnAllMessage = ""
    turnOnAllProcess.command = ["python3", root.helperPath, "turn-on-all"]
    turnOnAllProcess.running = true
  }

  function cancelTurnOnAll() {
    if (turnOnAllBusy) return
    turnOnAllConfirmTimer.stop()
    turnOnAllConfirming = false
    turnOnAllError = ""
  }

  function applyTurnOffAllResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      turnOffAllError = "The MasterSwitch request returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true) {
        var count = Number(parsed.count)
        turnOffAllError = ""
        turnOffAllConfirming = false
        turnOffAllMessage = parsed.message
          ? String(parsed.message)
          : "Turn-off sent to " + (isFinite(count) ? count : 0)
            + (count === 1 ? " climate device." : " climate devices.")
        turnOnAllError = ""
        turnOnAllMessage = ""
        root.clearLocalPower()
        root.clearLocalClimateControls()
        localTarget = null
        lastTemperatureSent = null
        errorText = ""
        return
      }
      turnOffAllError = parsed && parsed.error
        ? String(parsed.error) : "MasterSwitch could not turn off all climate devices."
    } catch (e) {
      turnOffAllError = "The MasterSwitch request returned invalid data."
    }
  }

  function applyTurnOnAllResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      turnOnAllError = "The MasterSwitch request returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true) {
        var count = Number(parsed.count)
        turnOnAllError = ""
        turnOnAllConfirming = false
        turnOnAllMessage = parsed.message
          ? String(parsed.message)
          : "Turn-on sent to " + (isFinite(count) ? count : 0)
            + (count === 1 ? " climate device." : " climate devices.")
        turnOffAllError = ""
        turnOffAllMessage = ""
        root.clearLocalPower()
        errorText = ""
        return
      }
      turnOnAllError = parsed && parsed.error
        ? String(parsed.error) : "MasterSwitch could not turn on all climate devices."
    } catch (e) {
      turnOnAllError = "The MasterSwitch request returned invalid data."
    }
  }

  function applyResetAppResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      resetAppError = "The app reset returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true && parsed.reset === true) {
        configured = false
        configResolved = true
        reading = ({})
        entityOptions = []
        root.clearUnitLocalStates()
        selectedEntity = ""
        pendingEntity = ""
        root.clearLocalPower()
        localTarget = null
        lastTemperatureSent = null
        root.clearLocalClimateControls()
        setupOpen = true
        setupTransitioning = false
        setupTransitionClosing = false
        connectionEditing = false
        connectionReconnecting = false
        setupUrl = "http://homeassistant.local:8123"
        activeHomeAssistantUrl = ""
        setupToken = ""
        setupError = ""
        setupEntityOptions = []
        setupSelectedEntity = ""
        localServerReady = false
        localServerConfirming = false
        localServerExpanded = false
        localServerMessage = ""
        localServerError = ""
        showClimateControls = true
        showClimateControlsPrevious = true
        masterSwitchEnabled = false
        masterSwitchEnabledPrevious = false
        temperatureDisplay = "both"
        temperatureDisplayPrevious = "both"
        historyEnabled = false
        historyEnabledPrevious = false
        historyHours = 24
        historyHoursPrevious = 24
        historyCustom = false
        historyCustomPrevious = false
        customHistoryHoursText = "24"
        historySource = "local"
        historySourcePrevious = "local"
        multiUnitEnabled = false
        multiUnitEnabledPrevious = false
        globalSyncControls = true
        globalSyncControlsPrevious = true
        syncNonPowerControls = true
        syncNonPowerControlsPrevious = true
        averageTemperatureDecimals = false
        averageTemperatureDecimalsPrevious = false
        temperatureUnitPreference = "source"
        temperatureUnitPreferencePrevious = "source"
        selectedEntities = []
        barTemperatureMode = "average"
        barTemperatureModePrevious = "average"
        barTemperatureEntities = []
        barTemperatureEntitiesPrevious = []
        experimentalHistoryEnabled = false
        experimentalHistoryEnabledPrevious = false
        shortcutsEnabled = false
        shortcutsEnabledPrevious = false
        globalTabNavigationEnabled = false
        globalTabNavigationEnabledPrevious = false
        configFileModeEnabled = false
        configFileModeEnabledPrevious = false
        configFileText = ""
        configFilePayload = ""
        configFileStatus = ""
        configFileError = ""
        configFileBusy = false
        shortcutValues = normalizeShortcutValues(shortcutDefaults)
        shortcutValuesPrevious = copyShortcutValues(shortcutValues)
        shortcutCaptureId = ""
        customAppearanceEnabled = false
        customAppearanceEnabledPrevious = false
        appearanceAutoAccent = true
        appearanceAutoAccentPrevious = true
        appearanceAutoBackground = true
        appearanceAutoBackgroundPrevious = true
        customAccentColor = "#8FA79F"
        customAccentColorPrevious = "#8FA79F"
        customAccentHexText = "#8FA79F"
        customAccentHexTextPrevious = "#8FA79F"
        customBackgroundColor = "#131516"
        customBackgroundColorPrevious = "#131516"
        customBackgroundHexText = "#131516"
        customBackgroundHexTextPrevious = "#131516"
        appearanceTransparency = 0
        appearanceTransparencyPrevious = 0
        appearanceTransparencyText = "0"
        appearanceBlur = 0
        appearanceBlurPrevious = 0
        appearanceBlurText = "0"
        appearanceRadius = 16
        appearanceRadiusPrevious = 16
        appearanceRadiusText = "16"
        compactUiEnabled = false
        compactUiEnabledPrevious = false
        appearanceOuterBorderEnabled = true
        appearanceOuterBorderEnabledPrevious = true
        remoteHistoryTarget = ""
        remoteHistoryPortText = "22"
        remoteHistoryUrl = root.remoteHistoryDefaultUrl
        remoteHistoryPath = root.remoteHistoryDefaultPath
        remoteHistoryPairingSaved = false
        remoteHistoryMessage = ""
        remoteHistoryError = ""
        settingsSection = "setup"
        resetAppConfirming = false
        resetAppError = ""
        resetAppMessage = "Daikin AC Controls was reset. Home Assistant was not changed."
        Qt.callLater(function() { setupHostField.forceActiveFocus() })
        return
      }
      resetAppError = parsed && parsed.error
        ? String(parsed.error) : "Daikin AC Controls could not be reset."
    } catch (e) {
      resetAppError = "The app reset returned invalid data."
    }
  }

  function applyConfig(raw) {
    var text = String(raw || "").trim()
    configResolved = true
    if (text === "") {
      configured = false
      setupOpen = true
      setupError = "The local setup could not be read. Connect Home Assistant to continue."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (!parsed || parsed.ok !== true) {
        configured = false
        setupOpen = true
        setupError = parsed && parsed.error ? String(parsed.error) : "Connect Home Assistant to continue."
        return
      }
      configured = parsed.configured === true
      if (configured && settingsSection === "setup") settingsSection = "preferences"
      showClimateControls = parsed.advanced_controls !== undefined
        ? parsed.advanced_controls === true : true
      showClimateControlsPrevious = showClimateControls
      masterSwitchEnabled = parsed.master_switch_enabled === true
      masterSwitchEnabledPrevious = masterSwitchEnabled
      temperatureDisplay = ["ambient", "target", "both"].indexOf(String(parsed.temperature_display || "both")) !== -1
        ? String(parsed.temperature_display || "both") : "both"
      temperatureDisplayPrevious = temperatureDisplay
      historyEnabled = parsed.history_enabled === true
      historyEnabledPrevious = historyEnabled
      historyHours = root.normalizeHistoryHours(parsed.history_hours)
      historyHoursPrevious = historyHours
      historyCustom = parsed.history_custom === true
      historyCustomPrevious = historyCustom
      customHistoryHoursText = root.formatHours(historyHours)
      historySource = String(parsed.history_source || "local") === "server" ? "server" : "local"
      historySourcePrevious = historySource
      remoteHistoryTarget = String(parsed.history_remote_target || "")
      remoteHistoryPortText = String(parsed.history_remote_port || "22")
      remoteHistoryUrl = String(parsed.history_remote_url || root.remoteHistoryDefaultUrl)
      remoteHistoryPath = String(parsed.history_remote_path || root.remoteHistoryDefaultPath)
      remoteHistoryPairingSaved = String(parsed.history_remote_target || "").trim() !== ""
      root.clearRemoteHistoryStatus()
      if (parsed.url) {
        setupUrl = String(parsed.url)
        activeHomeAssistantUrl = setupUrl
      }
      if (parsed.entity_id) {
        selectedEntity = String(parsed.entity_id)
        setupSelectedEntity = selectedEntity
      }
      root.applyExperimentalValues(parsed)
      if (root.configFileModeEnabled)
        root.scheduleConfigFileRefresh()
      if (!configured) {
        setupOpen = true
        setupError = ""
      }
    } catch (e) {
      configured = false
      setupOpen = true
      setupError = "The local setup returned invalid data. Connect Home Assistant to continue."
    }
  }

  function applySetupResult(raw) {
    var text = String(raw || "").trim()
    var wasReconnect = connectionReconnecting
    if (text === "") {
      setupError = "The Home Assistant setup helper returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true && parsed.needs_entity === true) {
        setSetupEntityOptions(parsed.entities || [])
        setupSelectedEntity = ""
        setupError = setupEntityOptions.length > 0
          ? "Connected. Choose the air conditioner you want on the bar."
          : "No available air conditioner was found on Home Assistant."
        return
      }
      if (parsed && parsed.ok === true && parsed.configured === true) {
        configured = true
        configResolved = true
        setupError = ""
        setupToken = ""
        setupEntityOptions = []
        if (parsed.url) {
          setupUrl = String(parsed.url)
          activeHomeAssistantUrl = setupUrl
        }
        if (parsed.entity_id) {
          selectedEntity = String(parsed.entity_id)
          setupSelectedEntity = selectedEntity
        }
        if (parsed.entities) setEntityOptions(parsed.entities)
        root.applyExperimentalValues(parsed)
        if (root.configFileModeEnabled)
          root.scheduleConfigFileRefresh()
        if (parsed.advanced_controls !== undefined) {
          showClimateControls = parsed.advanced_controls === true
          showClimateControlsPrevious = showClimateControls
        }
        if (parsed.master_switch_enabled !== undefined) {
          masterSwitchEnabled = parsed.master_switch_enabled === true
          masterSwitchEnabledPrevious = masterSwitchEnabled
        }
        if (parsed.temperature_display !== undefined) {
          var parsedDisplay = String(parsed.temperature_display)
          if (["ambient", "target", "both"].indexOf(parsedDisplay) !== -1) {
            temperatureDisplay = parsedDisplay
            temperatureDisplayPrevious = parsedDisplay
          }
        }
        if (parsed.history_enabled !== undefined) {
          historyEnabled = parsed.history_enabled === true
          historyEnabledPrevious = historyEnabled
        }
        if (parsed.history_hours !== undefined) {
          historyHours = root.normalizeHistoryHours(parsed.history_hours)
          historyHoursPrevious = historyHours
          customHistoryHoursText = root.formatHours(historyHours)
        }
        if (parsed.history_custom !== undefined) {
          historyCustom = parsed.history_custom === true
          historyCustomPrevious = historyCustom
        }
        if (parsed.history_source !== undefined) {
          historySource = String(parsed.history_source) === "server" ? "server" : "local"
          historySourcePrevious = historySource
        }
        if (parsed.history_remote_target !== undefined)
          remoteHistoryTarget = String(parsed.history_remote_target || "")
        if (parsed.history_remote_port !== undefined)
          remoteHistoryPortText = String(parsed.history_remote_port || "22")
        if (parsed.history_remote_url !== undefined)
          remoteHistoryUrl = String(parsed.history_remote_url || root.remoteHistoryDefaultUrl)
        if (parsed.history_remote_path !== undefined)
          remoteHistoryPath = String(parsed.history_remote_path || root.remoteHistoryDefaultPath)
        if (wasReconnect) {
          connectionReconnecting = false
          connectionEditing = false
          setupSucceeded = false
          Qt.callLater(root.refresh)
          return
        }
        setupOpen = false
        setupSucceeded = true
        return
      }
      if (parsed && parsed.entities) setSetupEntityOptions(parsed.entities)
      setupError = parsed && parsed.error
        ? String(parsed.error) : "Home Assistant setup could not be completed."
    } catch (e) {
      setupError = "The Home Assistant setup helper returned invalid data."
    }
  }

  function applyEntities(raw) {
    var text = String(raw || "").trim()
    if (text === "") return
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true && Array.isArray(parsed.entities))
        root.setEntityOptions(parsed.entities)
    } catch (e) {
      // The status request supplies the user-facing error.
    }
  }

  function applyResult(raw, source) {
    var text = String(raw || "").trim()
    if (text === "") {
      if (source === "status") root.clearRemoteHistoryStatus()
      if (source === "action" && hasLocalPower) {
        errorText = ""
        return
      }
      if (source === "action" && actionKind === "unit-power") {
        errorText = ""
        return
      }
      if (source === "action" && (actionKind === "mode" || actionKind === "fan")) {
        root.rejectLocalAction()
        errorText = ""
        return
      }
      if (source === "action" && actionKind.indexOf("unit-") === 0) {
        if (actionKind !== "unit-power" || queuedUnitPowerEntityId === "")
          root.rejectUnitLocalAction()
        errorText = ""
        return
      }
      if (source === "status"
          && (powerFinalCheckPending || root.hasPendingUnitPowerFinalCheck())) {
        errorText = root.timeoutPendingPowerAfterStatus(
          "Power request timed out after 15 seconds; Home Assistant status could not be refreshed. Showing the requested state.")
        return
      }
      errorText = "The control helper returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.configured === false && parsed.ok !== true) {
        if (source === "status") root.clearRemoteHistoryStatus()
        configured = false
        root.clearUnitLocalStates()
        setupUrl = String(parsed.url || setupUrl)
        setupOpen = true
        setupError = parsed.error ? String(parsed.error) : "Connect Home Assistant to continue."
        return
      }
      if (parsed && parsed.ok === true && parsed.requested_target !== undefined) {
        if (parsed.entity_id) selectedEntity = String(parsed.entity_id)
        lastTemperatureSent = Number(parsed.requested_target)
        errorText = ""
        return
      }
      if (parsed && parsed.ok === true && parsed.requested_fan_mode !== undefined) {
        if (parsed.entity_id) selectedEntity = String(parsed.entity_id)
        fanModeInFlight = ""
        errorText = ""
        return
      }
      if (parsed && parsed.ok === true && parsed.requested_mode !== undefined) {
        if (parsed.entity_id) selectedEntity = String(parsed.entity_id)
        if (actionKind === "mode") modeInFlight = ""
        if (actionKind === "unit-mode" || actionKind === "unit-power") {
          // Separate remotes keep their own optimistic state; do not alter
          // the main remote's mode-restart state for their acknowledgements.
        } else if (actionKind === "mode") {
          if (parsed.restarting === true) root.beginModeRestart()
          else root.clearModeRestart()
        }
        errorText = ""
        return
      }
      // set-entity acknowledges with only an entity_id; keep the current
      // climate reading until the follow-up status request completes.
      if (parsed && parsed.ok === true && parsed.ambient === undefined && parsed.target === undefined) {
        if (parsed.entity_id) selectedEntity = String(parsed.entity_id)
        if (Array.isArray(parsed.selected_entities))
          selectedEntities = root.normalizeSelectedEntities(parsed.selected_entities, selectedEntity)
        else if (!multiUnitEnabled && selectedEntity !== "")
          selectedEntities = [selectedEntity]
        pendingEntity = ""
        errorText = ""
        return
      }
      if (parsed && parsed.ok === true) {
        configured = true
        reading = parsed
        if (source === "status") root.recordRemoteHistoryStatus(parsed)
        selectedEntity = String(parsed.entity_id || selectedEntity)
        unitReadings = Array.isArray(parsed.units) && parsed.units.length > 0
          ? parsed.units : [parsed]
        if (Array.isArray(parsed.selected_entities))
          selectedEntities = root.normalizeSelectedEntities(parsed.selected_entities, selectedEntity)
        pendingEntity = ""
        if (source === "status" && hasLocalPower && !actionProcess.running
            && powerDispatchDueAt <= Date.now() && parsed.state !== undefined) {
          var observedOn = String(parsed.state || "").toLowerCase() !== "off"
          var requestedOn = localPower
          var readbackMarker = root.powerMarker(parsed)
          var readbackIsFresh = powerReadbackMarker !== ""
            && readbackMarker !== "" && readbackMarker !== powerReadbackMarker
          if (observedOn === requestedOn
              && (readbackIsFresh || powerFinalCheckPending || powerTimedOut)) {
            root.clearLocalPower()
          } else if (powerFinalCheckPending) {
            root.timeoutLocalPower(
              "Power request timed out after 15 seconds; showing the requested state.")
          }
        }
        if (source === "status" && hasLocalTarget && sameTemperature(parsed.target, localTarget)) {
          localTarget = null
          lastTemperatureSent = null
        }
        if (source === "status" && localMode !== ""
            && sameControlValue(parsed.state, localMode)) {
          if (modeRestarting) root.clearModeRestart()
          localMode = ""
          modeInFlight = ""
        }
        if (source === "status" && localFanMode !== ""
            && sameControlValue(parsed.fan_mode, localFanMode)) {
          localFanMode = ""
          fanModeInFlight = ""
        }
        var unitError = root.reconcileUnitLocalStates()
        var statusMessages = []
        if (powerTimedOut && powerTimeoutMessage !== "")
          statusMessages.push(powerTimeoutMessage)
        if (unitError !== "") statusMessages.push(unitError)
        errorText = statusMessages.join(" ")
      } else {
        if (source === "status") root.clearRemoteHistoryStatus()
        if (source === "action" && hasLocalPower) {
          errorText = ""
          return
        }
        if (source === "action" && actionKind === "unit-power") {
          errorText = ""
          return
        }
        if (source === "status"
            && (powerFinalCheckPending || root.hasPendingUnitPowerFinalCheck())) {
          var finalStatusError = parsed && parsed.error ? String(parsed.error)
            : "Home Assistant status could not be refreshed"
          errorText = root.timeoutPendingPowerAfterStatus(
            "Power request timed out after 15 seconds; " + finalStatusError
              + ". Showing the requested state.")
          return
        }
        if (source === "action") {
          root.rejectLocalAction()
          if (actionKind === "selection") Qt.callLater(root.refresh)
        }
        if (parsed && parsed.entity_ids && parsed.entity_ids.length > 0) {
          mergeEntityIds(parsed.entity_ids)
          errorText = "Choose an air conditioner from the device list."
        } else {
          errorText = parsed && parsed.error ? String(parsed.error) : "Air-conditioning request failed."
        }
      }
    } catch (e) {
      if (source === "status") root.clearRemoteHistoryStatus()
      if (source === "action" && hasLocalPower) {
        errorText = ""
        return
      }
      if (source === "action" && actionKind === "unit-power") {
        errorText = ""
        return
      }
      if (source === "status"
          && (powerFinalCheckPending || root.hasPendingUnitPowerFinalCheck())) {
        errorText = root.timeoutPendingPowerAfterStatus(
          "Power request timed out after 15 seconds; Home Assistant returned invalid status data. Showing the requested state.")
        return
      }
      if (source === "action") {
        root.rejectLocalAction()
        if (actionKind === "selection") Qt.callLater(root.refresh)
      }
      errorText = "The controller returned invalid data."
    }
  }

  function chooseEntity(value) {
    var next = String(value || "")
    if (!next || actionProcess.running) return
    if (multiUnitEnabled) {
      var nextSelection = normalizeSelectedEntities(selectedEntities, selectedEntity)
      if (nextSelection.indexOf(next) < 0) nextSelection.push(next)
      nextSelection = normalizeSelectedEntities(nextSelection, next)
      root.saveSelection(next, nextSelection)
      return
    }
    if (next === selectedEntity) return
    pendingEntity = next
    localTarget = null
    root.clearLocalPower()
    root.clearLocalClimateControls()
    root.clearUnitLocalStates()
    lastTemperatureSent = null
    actionEntityId = ""
    actionKind = "entity"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-entity", next]
    actionProcess.running = true
  }

  function saveSelection(activeEntity, entityIds) {
    if (actionProcess.running) return
    var active = String(activeEntity || "")
    var next = normalizeSelectedEntities(entityIds, active)
    if (!active || next.length === 0) return
    if (next.indexOf(active) < 0) next.unshift(active)
    pendingEntity = active
    selectedEntities = next
    selectedEntity = active
    localTarget = null
    root.clearLocalPower()
    root.clearLocalClimateControls()
    root.clearUnitLocalStates()
    lastTemperatureSent = null
    errorText = ""
    actionEntityId = ""
    actionKind = "selection"
    actionBusy = true
    selectionPayload = JSON.stringify({ entity_id: active, entities: next })
    actionProcess.command = ["python3", root.helperPath, "set-selection"]
    actionProcess.running = true
  }

  function removeSelectedEntity(entityId) {
    if (!multiUnitEnabled || actionProcess.running || selectedEntities.length <= 1) return
    var id = String(entityId || "")
    var next = selectedEntities.slice()
    var index = next.indexOf(id)
    if (index < 0) return
    next.splice(index, 1)
    var active = selectedEntity === id ? next[0] : selectedEntity
    root.saveSelection(active, next)
  }

  function queueControl(kind, value) {
    queuedControlKind = kind
    queuedControlValue = value
  }

  function dispatchModeRequest(value, entityId) {
    modeInFlight = value
    actionKind = "mode"
    actionEntityId = entityId ? String(entityId) : ""
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-mode", value]
    if (entityId) actionProcess.command.push(String(entityId))
    actionProcess.running = true
  }

  function dispatchFanModeRequest(value, entityId) {
    fanModeInFlight = value
    actionKind = "fan"
    actionEntityId = entityId ? String(entityId) : ""
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-fan-mode", value]
    if (entityId) actionProcess.command.push(String(entityId))
    actionProcess.running = true
  }

  function requestMode(value) {
    var next = String(value || "").trim()
    if (masterSwitchBusy || !next || !connected || (!isOn && localMode === "")) return
    if (sameControlValue(next, activeMode) && localMode === "") return
    localMode = next
    root.beginModeRestart()
    errorText = ""
    if (actionProcess.running) {
      root.queueControl("mode", next)
      return
    }
    root.dispatchModeRequest(next)
  }

  function requestFanMode(value) {
    var next = String(value || "").trim()
    if (masterSwitchBusy || !next || !connected || !isOn) return
    if (sameControlValue(next, activeFanMode) && localFanMode === "") return
    localFanMode = next
    errorText = ""
    if (actionProcess.running) {
      root.queueControl("fan", next)
      return
    }
    root.dispatchFanModeRequest(next)
  }

  function normalizeUnitTarget(climate, value) {
    if (!climate) return null
    var next = Number(value)
    if (!isFinite(next)) return null
    var minimum = isFinite(Number(climate.min_temp)) ? Number(climate.min_temp) : 16
    var maximum = isFinite(Number(climate.max_temp)) ? Number(climate.max_temp) : 30
    var step = isFinite(Number(climate.step)) && Number(climate.step) > 0
      ? Number(climate.step) : 1
    next = Math.round(next / step) * step
    next = Math.round(next * 100) / 100
    return Math.max(minimum, Math.min(maximum, next))
  }

  function requestUnitTemperature(entityId, value) {
    if (actionProcess.running || masterSwitchBusy) return
    var climate = unitReading(entityId)
    if (!climate || String(climate.state || "").toLowerCase() === "off") return
    var next = normalizeUnitTarget(climate, value)
    if (next === null) return
    root.setUnitLocalStateValue(entityId, "target", next)
    actionEntityId = String(entityId)
    actionKind = "unit-temperature"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-temperature", String(next), String(entityId)]
    actionProcess.running = true
  }

  function requestUnitMode(entityId, value) {
    if (actionProcess.running || masterSwitchBusy) return
    var climate = unitReading(entityId)
    var next = String(value || "").trim()
    if (!climate || !next) return
    root.setUnitLocalStateValue(entityId, "mode", next)
    actionEntityId = String(entityId)
    actionKind = "unit-mode"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-mode", next, String(entityId)]
    actionProcess.running = true
  }

  function requestUnitFanMode(entityId, value) {
    if (actionProcess.running || masterSwitchBusy) return
    var climate = unitReading(entityId)
    var next = String(value || "").trim()
    if (!climate || !next) return
    root.setUnitLocalStateValue(entityId, "fan", next)
    actionEntityId = String(entityId)
    actionKind = "unit-fan"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-fan-mode", next, String(entityId)]
    actionProcess.running = true
  }

  function requestUnitPower(entityId, requestedPower, cancellable, dispatchAfter) {
    if (masterSwitchBusy) return
    var id = String(entityId || "")
    var climate = unitReading(id)
    if (!climate) return
    var requested = String(requestedPower || "").toLowerCase()
    if (["on", "off"].indexOf(requested) < 0) return
    var now = Date.now()
    var dueAt = Number(dispatchAfter)
    if (!isFinite(dueAt)) dueAt = 0
    root.setUnitLocalStateValue(id, "power",
      requested === "on" ? "turning_on" : "turning_off")
    root.setUnitLocalStateValue(id, "powerStartedAt", null)
    root.setUnitLocalStateValue(id, "powerDispatchDueAt", dueAt > now ? dueAt : null)
    root.setUnitLocalStateValue(id, "powerReadbackMarker", root.powerMarker(climate))
    root.setUnitLocalStateValue(id, "powerFinalCheckPending", false)
    root.setUnitLocalStateValue(id, "powerTimedOut", false)
    root.setUnitLocalStateValue(id, "powerCanCancel", cancellable !== false)
    errorText = ""
    if (actionProcess.running || dueAt > now) {
      queuedUnitPowerEntityId = id
      queuedUnitPowerRequest = requested
      if (dueAt > now) root.scheduleQueuedUnitPowerRequest()
      return
    }
    queuedUnitPowerEntityId = ""
    queuedUnitPowerRequest = ""
    root.dispatchUnitPowerRequest(id, requested)
  }

  function scheduleQueuedUnitPowerRequest() {
    if (queuedUnitPowerEntityId === "" || actionProcess.running) return
    var state = root.unitLocalState(queuedUnitPowerEntityId)
    var dueAt = Number(state.powerDispatchDueAt)
    if (isFinite(dueAt) && dueAt > Date.now()) {
      unitPowerDispatchDelayTimer.interval = Math.max(50, dueAt - Date.now())
      unitPowerDispatchDelayTimer.restart()
      return
    }
    var id = queuedUnitPowerEntityId
    var requested = queuedUnitPowerRequest
    queuedUnitPowerEntityId = ""
    queuedUnitPowerRequest = ""
    root.dispatchUnitPowerRequest(id, requested)
  }

  function dispatchUnitPowerRequest(entityId, requestedPower) {
    root.setUnitLocalStateValue(entityId, "powerStartedAt", Date.now())
    root.setUnitLocalStateValue(entityId, "powerDispatchDueAt", null)
    actionEntityId = String(entityId || "")
    actionKind = "unit-power"
    actionBusy = true
    actionProcess.command = [
      "python3", root.helperPath, "set-power", String(requestedPower), actionEntityId
    ]
    actionProcess.running = true
  }

  function cancelUnitPower(entityId) {
    var id = String(entityId || "")
    var state = root.unitLocalState(id)
    if (masterSwitchBusy || !state.power || state.powerCanCancel !== true
        || state.powerTimedOut === true) return
    var dueAt = Date.now()
    if (Number(state.powerStartedAt) > 0)
      dueAt = Math.max(dueAt, Number(state.powerStartedAt) + 5000)
    root.requestUnitPower(id, state.power === "turning_on" ? "off" : "on", false, dueAt)
  }

  function setShowClimateControlsEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === showClimateControls) return
    showClimateControlsPrevious = showClimateControls
    showClimateControls = next
    preferenceKind = "advanced_controls"
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "advanced_controls", next ? "on" : "off"
    ]
    preferenceProcess.running = true
  }

  function setMasterSwitchEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === masterSwitchEnabled) return
    masterSwitchEnabledPrevious = masterSwitchEnabled
    masterSwitchEnabled = next
    if (!next) {
      turnOffAllConfirmTimer.stop()
      turnOnAllConfirmTimer.stop()
      turnOffAllConfirming = false
      turnOnAllConfirming = false
    }
    preferenceKind = "master_switch_enabled"
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "master_switch_enabled", next ? "on" : "off"
    ]
    preferenceProcess.running = true
  }

  function setTemperatureDisplay(value) {
    var next = String(value || "").trim().toLowerCase()
    if (preferenceProcess.running || ["ambient", "target", "both"].indexOf(next) === -1) return
    if (next === temperatureDisplay) return
    temperatureDisplayPrevious = temperatureDisplay
    temperatureDisplay = next
    preferenceKind = "temperature_display"
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "temperature_display", next
    ]
    preferenceProcess.running = true
  }

  function setTemperatureUnit(value) {
    if (preferenceProcess.running) return
    var next = root.normalizeTemperatureUnitPreference(value)
    if (["celsius", "fahrenheit", "kelvin"].indexOf(next) < 0) return
    if (next === temperatureUnitPreference) return
    temperatureUnitPreferencePrevious = temperatureUnitPreference
    temperatureUnitPreference = next
    root.beginPreference("temperature_unit", next)
  }

  function setHistoryEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === historyEnabled) return
    historyEnabledPrevious = historyEnabled
    historyEnabled = next
    preferenceKind = "history_enabled"
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "history_enabled", next ? "on" : "off"
    ]
    preferenceProcess.running = true
  }

  function beginPreference(name, encodedValue) {
    if (preferenceProcess.running) return
    preferenceKind = name
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", name, String(encodedValue)
    ]
    preferenceProcess.running = true
  }

  function setMultiUnitEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === multiUnitEnabled) return
    multiUnitEnabledPrevious = multiUnitEnabled
    multiUnitEnabled = next
    if (next) selectedEntities = normalizeSelectedEntities(selectedEntities, selectedEntity)
    root.beginPreference("multi_unit_enabled", next ? "on" : "off")
  }

  function setGlobalSyncControls(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === globalSyncControls) return
    globalSyncControlsPrevious = globalSyncControls
    globalSyncControls = next
    root.beginPreference("global_sync_controls", next ? "on" : "off")
  }

  function setSyncNonPowerControls(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === syncNonPowerControls) return
    syncNonPowerControlsPrevious = syncNonPowerControls
    syncNonPowerControls = next
    root.beginPreference("sync_non_power_controls", next ? "on" : "off")
  }

  function setAverageTemperatureDecimals(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === averageTemperatureDecimals) return
    averageTemperatureDecimalsPrevious = averageTemperatureDecimals
    averageTemperatureDecimals = next
    root.beginPreference("average_temperature_decimals", next ? "on" : "off")
  }

  function setBarTemperatureMode(value) {
    if (preferenceProcess.running) return
    var next = String(value || "").toLowerCase()
    if (["average", "all", "selected"].indexOf(next) < 0
        || next === barTemperatureMode) return
    barTemperatureModePrevious = barTemperatureMode
    barTemperatureMode = next
    root.beginPreference("bar_temperature_mode", next)
  }

  function toggleBarTemperatureEntity(entityId) {
    if (preferenceProcess.running) return
    var id = String(entityId || "")
    barTemperatureEntitiesPrevious = barTemperatureEntities.slice()
    var next = Array.isArray(barTemperatureEntities) ? barTemperatureEntities.slice() : []
    var index = next.indexOf(id)
    if (index >= 0) next.splice(index, 1)
    else next.push(id)
    if (next.length === 0) next = selectedEntities.slice()
    barTemperatureEntities = normalizeSelectedEntities(next, selectedEntity)
    root.beginPreference("bar_temperature_entities", barTemperatureEntities.join(","))
  }

  function setExperimentalHistoryEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === experimentalHistoryEnabled) return
    experimentalHistoryEnabledPrevious = experimentalHistoryEnabled
    experimentalHistoryEnabled = next
    root.beginPreference("experimental_history_enabled", next ? "on" : "off")
  }

  function setShortcutsEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === root.shortcutsEnabled) return
    shortcutsEnabledPrevious = root.shortcutsEnabled
    shortcutsEnabled = next
    if (!next) shortcutCaptureId = ""
    if (!next && settingsSection === "shortcuts") settingsSection = "experimental"
    root.beginPreference("shortcuts_enabled", next ? "on" : "off")
  }

  function setGlobalTabNavigationEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === root.globalTabNavigationEnabled) return
    globalTabNavigationEnabledPrevious = root.globalTabNavigationEnabled
    globalTabNavigationEnabled = next
    root.applyGlobalTabNavigation()
    root.beginPreference("global_tab_navigation_enabled", next ? "on" : "off")
  }

  function setConfigFileModeEnabled(value) {
    if (preferenceProcess.running || configFileBusy) return
    var next = value === true
    if (next === configFileModeEnabled) return
    configFileModeEnabledPrevious = configFileModeEnabled
    configFileModeEnabled = next
    configFileError = ""
    configFileStatus = ""
    if (next) {
      root.refreshConfigFileText()
      Qt.callLater(function() {
        if (root.configFileModeEnabled && configFileEditor) configFileEditor.forceActiveFocus()
      })
    }
    root.beginPreference("config_file_mode_enabled", next ? "on" : "off")
  }

  function setShortcutEnabled(name, value) {
    if (preferenceProcess.running || !shortcutDefaults[name]) return
    var next = value === true
    var current = root.shortcutValues[name]
    if (current && (current.enabled !== false) === next) return
    shortcutValuesPrevious = root.copyShortcutValues()
    var updated = root.copyShortcutValues()
    updated[name].enabled = next
    shortcutValues = updated
    root.beginPreference("shortcut_enabled_" + name, next ? "on" : "off")
  }

  function setShortcut(name, value) {
    if (preferenceProcess.running || !shortcutDefaults[name]) return
    var next = root.normalizeShortcutKey(value, "")
    if (next === "") return
    if (root.shortcutValue(name) === next) return
    shortcutValuesPrevious = root.copyShortcutValues()
    var updated = root.copyShortcutValues()
    updated[name].key = next
    shortcutValues = updated
    root.beginPreference("shortcut_" + name, next)
  }

  function resetShortcuts() {
    if (preferenceProcess.running) return
    shortcutCaptureId = ""
    shortcutValuesPrevious = root.copyShortcutValues()
    shortcutValues = root.normalizeShortcutValues(shortcutDefaults)
    preferenceKind = "reset_shortcuts"
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "reset_shortcuts", "default"
    ]
    preferenceProcess.running = true
  }

  function setCustomAppearanceEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === customAppearanceEnabled) return
    customAppearanceEnabledPrevious = customAppearanceEnabled
    customAppearanceEnabled = next
    if (settingsSection === "customisation") settingsSection = "experimental"
    root.beginPreference("custom_appearance_enabled", next ? "on" : "off")
  }

  function setAppearanceAutoAccent(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === appearanceAutoAccent) return
    appearanceAutoAccentPrevious = appearanceAutoAccent
    appearanceAutoAccent = next
    root.beginPreference("appearance_auto_accent", next ? "on" : "off")
  }

  function setAppearanceAutoBackground(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === appearanceAutoBackground) return
    appearanceAutoBackgroundPrevious = appearanceAutoBackground
    appearanceAutoBackground = next
    root.beginPreference("appearance_auto_background", next ? "on" : "off")
  }

  function setAppearanceDeviceColorsEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === appearanceDeviceColorsEnabled) return
    appearanceDeviceColorsEnabledPrevious = appearanceDeviceColorsEnabled
    appearanceDeviceColorsEnabled = next
    root.beginPreference("appearance_device_colors_enabled", next ? "on" : "off")
  }

  function resetCustomisations() {
    if (preferenceProcess.running) return
    preferenceKind = "reset_appearance"
    preferenceBusy = true
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "reset_appearance", "default"
    ]
    preferenceProcess.running = true
  }

  function setAppearanceColor(name, value) {
    if (preferenceProcess.running) return
    var next = String(value || "").trim().toUpperCase()
    if (!/^#[0-9A-F]{6}$/.test(next)) {
      errorText = "Use a six-digit hex colour such as #8FA79F."
      return
    }
    if (name === "appearance_accent") {
      customAccentHexTextPrevious = customAccentHexText
      customAccentColorPrevious = customAccentColor
      customAccentHexText = next
      customAccentColor = next
    } else if (name === "appearance_control") {
      customControlHexTextPrevious = customControlHexText
      customControlColorPrevious = customControlColor
      customControlHexText = next
      customControlColor = next
    } else if (name === "appearance_background") {
      customBackgroundHexTextPrevious = customBackgroundHexText
      customBackgroundColorPrevious = customBackgroundColor
      customBackgroundHexText = next
      customBackgroundColor = next
    } else {
      return
    }
    root.beginPreference(name, next)
  }

  function setAppearanceHex(value) {
    root.setAppearanceColor("appearance_accent", value)
  }

  function setAppearanceDeviceColor(entityId, value) {
    if (preferenceProcess.running) return
    var id = String(entityId || "").trim()
    var nextColor = String(value || "").trim().toUpperCase()
    if (!/^climate\.[A-Za-z0-9_-]+$/.test(id) || !/^#[0-9A-F]{6}$/.test(nextColor)) {
      errorText = "Use a six-digit hex colour such as #8FA79F."
      return
    }
    var next = root.copyAppearanceDeviceColors()
    next[id] = nextColor
    appearanceDeviceColorsPrevious = root.copyAppearanceDeviceColors()
    appearanceDeviceColors = next
    root.beginPreference("appearance_device_colors", JSON.stringify(next))
  }

  function setAppearanceNumber(name, value) {
    if (preferenceProcess.running) return
    var limits = {
      appearance_transparency: [0, 100],
      appearance_blur: [0, 24],
      appearance_radius: [8, 32],
    }
    if (!limits[name]) return
    var next = Number(value)
    if (!isFinite(next) || next < limits[name][0] || next > limits[name][1]) return
    next = Math.round(next * 10) / 10
    if (name === "appearance_transparency") {
      appearanceTransparencyPrevious = appearanceTransparency
      appearanceTransparency = next
      appearanceTransparencyText = formatAppearanceValue(next)
    } else if (name === "appearance_blur") {
      appearanceBlurPrevious = appearanceBlur
      appearanceBlur = next
      appearanceBlurText = formatAppearanceValue(next)
    } else {
      appearanceRadiusPrevious = appearanceRadius
      appearanceRadius = next
      appearanceRadiusText = formatAppearanceValue(next)
    }
    root.beginPreference(name, formatAppearanceValue(next))
  }

  function setCompactUiEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === compactUiEnabled) return
    compactUiEnabledPrevious = compactUiEnabled
    compactUiEnabled = next
    root.beginPreference("appearance_compact", next ? "on" : "off")
  }

  function setAppearanceOuterBorderEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === appearanceOuterBorderEnabled) return
    appearanceOuterBorderEnabledPrevious = appearanceOuterBorderEnabled
    appearanceOuterBorderEnabled = next
    root.beginPreference("appearance_outer_border_enabled", next ? "on" : "off")
  }

  function setHistoryRange(value, custom, force) {
    if (preferenceProcess.running) return
    var next = normalizeHistoryHours(value)
    var nextCustom = custom === true
    if (nextCustom && !experimentalHistoryEnabled) {
      setupError = "Custom ranges are available in Experimental → Extended chart history."
      return
    }
    if (!isFinite(Number(value)) || next < 1 || next > historyMaximumHours()) return
    if (!force && next === historyHours && nextCustom === historyCustom) return
    historyHoursPrevious = historyHours
    historyCustomPrevious = historyCustom
    historyHours = next
    historyCustom = nextCustom
    customHistoryHoursText = formatHours(next)
    preferenceKind = "history_range"
    preferenceBusy = true
    var encoded = nextCustom ? "custom:" + formatHours(next) : formatHours(next)
    preferenceProcess.command = [
      "python3", root.helperPath, "set-preference", "history_range", encoded
    ]
    preferenceProcess.running = true
  }

  function chooseHistoryRange(value) {
    var next = String(value || "")
    if (next === "custom") {
      if (!experimentalHistoryEnabled) {
        setupError = "Custom ranges are available in Experimental → Extended chart history."
        return
      }
      customHistoryHoursText = formatHours(historyHours)
      if (!historyCustom) root.setHistoryRange(historyHours, true)
      return
    }
    root.setHistoryRange(next, false)
  }

  function applyCustomHistoryRange() {
    if (!experimentalHistoryEnabled) {
      setupError = "Custom ranges are available in Experimental → Extended chart history."
      return
    }
    var next = Number(String(customHistoryHoursText || "").trim())
    if (!isFinite(next) || next < 1 || next > historyMaximumHours()) {
      setupError = "Custom history must be between 1 and " + historyMaximumHours() + " hours."
      return
    }
    root.setHistoryRange(next, true, true)
    setupError = ""
  }

  function restorePreference(kind) {
    if (kind === "advanced_controls") showClimateControls = showClimateControlsPrevious
    else if (kind === "master_switch_enabled") masterSwitchEnabled = masterSwitchEnabledPrevious
    else if (kind === "temperature_display") temperatureDisplay = temperatureDisplayPrevious
    else if (kind === "history_enabled") historyEnabled = historyEnabledPrevious
    else if (kind === "history_source") historySource = historySourcePrevious
    else if (kind === "history_range") {
      historyHours = historyHoursPrevious
      historyCustom = historyCustomPrevious
      customHistoryHoursText = formatHours(historyHours)
    } else if (kind === "multi_unit_enabled") multiUnitEnabled = multiUnitEnabledPrevious
    else if (kind === "global_sync_controls") globalSyncControls = globalSyncControlsPrevious
    else if (kind === "sync_non_power_controls") syncNonPowerControls = syncNonPowerControlsPrevious
    else if (kind === "average_temperature_decimals")
      averageTemperatureDecimals = averageTemperatureDecimalsPrevious
    else if (kind === "temperature_unit")
      temperatureUnitPreference = temperatureUnitPreferencePrevious
    else if (kind === "bar_temperature_mode") barTemperatureMode = barTemperatureModePrevious
    else if (kind === "bar_temperature_entities") barTemperatureEntities = barTemperatureEntitiesPrevious.slice()
    else if (kind === "experimental_history_enabled")
      experimentalHistoryEnabled = experimentalHistoryEnabledPrevious
    else if (kind === "shortcuts_enabled") shortcutsEnabled = shortcutsEnabledPrevious
    else if (kind === "global_tab_navigation_enabled") {
      globalTabNavigationEnabled = globalTabNavigationEnabledPrevious
      root.applyGlobalTabNavigation()
    }
    else if (kind === "config_file_mode_enabled")
      configFileModeEnabled = configFileModeEnabledPrevious
    else if (kind === "reset_shortcuts")
      shortcutValues = copyShortcutValues(shortcutValuesPrevious)
    else if (kind.indexOf("shortcut_enabled_") === 0
        || kind.indexOf("shortcut_") === 0)
      shortcutValues = copyShortcutValues(shortcutValuesPrevious)
    else if (kind === "custom_appearance_enabled") customAppearanceEnabled = customAppearanceEnabledPrevious
    else if (kind === "appearance_auto_accent") appearanceAutoAccent = appearanceAutoAccentPrevious
    else if (kind === "appearance_auto_background")
      appearanceAutoBackground = appearanceAutoBackgroundPrevious
    else if (kind === "appearance_accent") {
      customAccentHexText = customAccentHexTextPrevious
      customAccentColor = customAccentColorPrevious
    } else if (kind === "appearance_control") {
      customControlHexText = customControlHexTextPrevious
      customControlColor = customControlColorPrevious
    } else if (kind === "appearance_background") {
      customBackgroundHexText = customBackgroundHexTextPrevious
      customBackgroundColor = customBackgroundColorPrevious
    } else if (kind === "appearance_device_colors_enabled") {
      appearanceDeviceColorsEnabled = appearanceDeviceColorsEnabledPrevious
    } else if (kind === "appearance_device_colors") {
      appearanceDeviceColors = normalizeAppearanceDeviceColors(appearanceDeviceColorsPrevious)
    } else if (kind === "appearance_transparency") {
      appearanceTransparency = appearanceTransparencyPrevious
      appearanceTransparencyText = formatAppearanceValue(appearanceTransparency)
    } else if (kind === "appearance_blur") {
      appearanceBlur = appearanceBlurPrevious
      appearanceBlurText = formatAppearanceValue(appearanceBlur)
    } else if (kind === "appearance_radius") {
      appearanceRadius = appearanceRadiusPrevious
      appearanceRadiusText = formatAppearanceValue(appearanceRadius)
    } else if (kind === "appearance_compact") {
      compactUiEnabled = compactUiEnabledPrevious
    } else if (kind === "appearance_outer_border_enabled") {
      appearanceOuterBorderEnabled = appearanceOuterBorderEnabledPrevious
    }
  }

  function applyExperimentalPreference(name, value) {
    if (name === "multi_unit_enabled") {
      multiUnitEnabled = value === true
      multiUnitEnabledPrevious = multiUnitEnabled
    } else if (name === "global_sync_controls") {
      globalSyncControls = value === true
      globalSyncControlsPrevious = globalSyncControls
    } else if (name === "sync_non_power_controls") {
      syncNonPowerControls = value === true
      syncNonPowerControlsPrevious = syncNonPowerControls
    } else if (name === "average_temperature_decimals") {
      averageTemperatureDecimals = value === true
      averageTemperatureDecimalsPrevious = averageTemperatureDecimals
    } else if (name === "temperature_unit") {
      temperatureUnitPreference = root.normalizeTemperatureUnitPreference(value)
      temperatureUnitPreferencePrevious = temperatureUnitPreference
    } else if (name === "bar_temperature_mode") {
      var nextBarMode = String(value || "average")
      barTemperatureMode = ["average", "all", "selected"].indexOf(nextBarMode) >= 0
        ? nextBarMode : "average"
      barTemperatureModePrevious = barTemperatureMode
    } else if (name === "bar_temperature_entities") {
      barTemperatureEntities = normalizeSelectedEntities(value, selectedEntity)
      barTemperatureEntitiesPrevious = barTemperatureEntities.slice()
    } else if (name === "experimental_history_enabled") {
      experimentalHistoryEnabled = value === true
      experimentalHistoryEnabledPrevious = experimentalHistoryEnabled
    } else if (name === "shortcuts_enabled") {
      shortcutsEnabled = value === true
      shortcutsEnabledPrevious = shortcutsEnabled
    } else if (name === "global_tab_navigation_enabled") {
      globalTabNavigationEnabled = value === true
      globalTabNavigationEnabledPrevious = globalTabNavigationEnabled
      root.applyGlobalTabNavigation()
    } else if (name === "config_file_mode_enabled") {
      configFileModeEnabled = value === true
      configFileModeEnabledPrevious = configFileModeEnabled
    } else if (name.indexOf("shortcut_enabled_") === 0) {
      var enabledShortcutName = name.slice("shortcut_enabled_".length)
      if (!shortcutDefaults[enabledShortcutName]) return false
      var enabledShortcutValues = copyShortcutValues()
      enabledShortcutValues[enabledShortcutName].enabled = value === true
      shortcutValues = enabledShortcutValues
      shortcutValuesPrevious = copyShortcutValues()
    } else if (name.indexOf("shortcut_") === 0) {
      var keyShortcutName = name.slice("shortcut_".length)
      if (!shortcutDefaults[keyShortcutName]) return false
      var keyShortcut = root.normalizeShortcutKey(value, shortcutDefaults[keyShortcutName].key)
      var keyShortcutValues = copyShortcutValues()
      keyShortcutValues[keyShortcutName].key = keyShortcut
      shortcutValues = keyShortcutValues
      shortcutValuesPrevious = copyShortcutValues()
    } else if (name === "custom_appearance_enabled") {
      customAppearanceEnabled = value === true
      customAppearanceEnabledPrevious = customAppearanceEnabled
    } else if (name === "appearance_auto_accent") {
      appearanceAutoAccent = value === true
      appearanceAutoAccentPrevious = appearanceAutoAccent
    } else if (name === "appearance_auto_background") {
      appearanceAutoBackground = value === true
      appearanceAutoBackgroundPrevious = appearanceAutoBackground
    } else if (name === "appearance_accent") {
      customAccentHexText = String(value || customAccentHexText)
      customAccentColor = customAccentHexText
      customAccentHexTextPrevious = customAccentHexText
      customAccentColorPrevious = customAccentColor
    } else if (name === "appearance_control") {
      customControlHexText = String(value || customControlHexText)
      customControlColor = customControlHexText
      customControlHexTextPrevious = customControlHexText
      customControlColorPrevious = customControlColor
    } else if (name === "appearance_background") {
      customBackgroundHexText = String(value || customBackgroundHexText)
      customBackgroundColor = customBackgroundHexText
      customBackgroundHexTextPrevious = customBackgroundHexText
      customBackgroundColorPrevious = customBackgroundColor
    } else if (name === "appearance_device_colors_enabled") {
      appearanceDeviceColorsEnabled = value === true
      appearanceDeviceColorsEnabledPrevious = appearanceDeviceColorsEnabled
    } else if (name === "appearance_device_colors") {
      appearanceDeviceColors = normalizeAppearanceDeviceColors(value)
      appearanceDeviceColorsPrevious = copyAppearanceDeviceColors()
    } else if (name === "appearance_transparency") {
      appearanceTransparency = Number(value)
      appearanceTransparencyPrevious = appearanceTransparency
      appearanceTransparencyText = formatAppearanceValue(appearanceTransparency)
    } else if (name === "appearance_blur") {
      appearanceBlur = Number(value)
      appearanceBlurPrevious = appearanceBlur
      appearanceBlurText = formatAppearanceValue(appearanceBlur)
    } else if (name === "appearance_radius") {
      appearanceRadius = Number(value)
      appearanceRadiusPrevious = appearanceRadius
      appearanceRadiusText = formatAppearanceValue(appearanceRadius)
    } else if (name === "appearance_compact") {
      compactUiEnabled = value === true
      compactUiEnabledPrevious = compactUiEnabled
    } else if (name === "appearance_outer_border_enabled") {
      appearanceOuterBorderEnabled = value === true
      appearanceOuterBorderEnabledPrevious = appearanceOuterBorderEnabled
    } else {
      return false
    }
    return true
  }

  function applyPreferenceResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      root.restorePreference(preferenceKind)
      setupError = "The preference could not be saved."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.ok === true) {
        if (parsed.preference === "reset_shortcuts" && parsed.shortcuts !== undefined) {
          shortcutValues = root.normalizeShortcutValues(parsed.shortcuts)
          shortcutValuesPrevious = root.copyShortcutValues(shortcutValues)
          shortcutCaptureId = ""
          setupError = ""
          return
        } else if (parsed.preference === "reset_appearance" && parsed.appearance_reset === true) {
          customAppearanceEnabled = parsed.custom_appearance_enabled === true
          customAppearanceEnabledPrevious = customAppearanceEnabled
          appearanceAutoAccent = parsed.appearance_auto_accent !== false
          appearanceAutoAccentPrevious = appearanceAutoAccent
          appearanceAutoBackground = parsed.appearance_auto_background !== false
          appearanceAutoBackgroundPrevious = appearanceAutoBackground
          customAccentHexText = String(parsed.appearance_accent || "#8FA79F")
          customAccentHexTextPrevious = customAccentHexText
          customAccentColor = customAccentHexText
          customAccentColorPrevious = customAccentColor
          customControlHexText = String(parsed.appearance_control || "#8FA79F")
          customControlHexTextPrevious = customControlHexText
          customControlColor = customControlHexText
          customControlColorPrevious = customControlColor
          customBackgroundHexText = String(parsed.appearance_background || "#131516")
          customBackgroundHexTextPrevious = customBackgroundHexText
          customBackgroundColor = customBackgroundHexText
          customBackgroundColorPrevious = customBackgroundColor
          appearanceDeviceColorsEnabled = parsed.appearance_device_colors_enabled === true
          appearanceDeviceColorsEnabledPrevious = appearanceDeviceColorsEnabled
          appearanceDeviceColors = normalizeAppearanceDeviceColors(parsed.appearance_device_colors)
          appearanceDeviceColorsPrevious = copyAppearanceDeviceColors()
          appearanceTransparency = Math.max(0, Math.min(100, Number(parsed.appearance_transparency) || 0))
          appearanceTransparencyPrevious = appearanceTransparency
          appearanceTransparencyText = formatAppearanceValue(appearanceTransparency)
          appearanceBlur = Math.max(0, Math.min(24, Number(parsed.appearance_blur) || 0))
          appearanceBlurPrevious = appearanceBlur
          appearanceBlurText = formatAppearanceValue(appearanceBlur)
          appearanceRadius = Math.max(8, Math.min(32, Number(parsed.appearance_radius) || 16))
          appearanceRadiusPrevious = appearanceRadius
          appearanceRadiusText = formatAppearanceValue(appearanceRadius)
          compactUiEnabled = parsed.appearance_compact === true
          compactUiEnabledPrevious = compactUiEnabled
          appearanceOuterBorderEnabled = parsed.appearance_outer_border_enabled !== false
          appearanceOuterBorderEnabledPrevious = appearanceOuterBorderEnabled
          setupError = ""
          return
        } else if (parsed.preference === "advanced_controls" && parsed.value !== undefined) {
          showClimateControls = parsed.value === true
          showClimateControlsPrevious = showClimateControls
        } else if (parsed.preference === "master_switch_enabled" && parsed.value !== undefined) {
          masterSwitchEnabled = parsed.value === true
          masterSwitchEnabledPrevious = masterSwitchEnabled
        } else if (parsed.preference === "temperature_display" && parsed.value !== undefined) {
          temperatureDisplay = String(parsed.value)
          temperatureDisplayPrevious = temperatureDisplay
        } else if (parsed.preference === "history_enabled" && parsed.value !== undefined) {
          historyEnabled = parsed.value === true
          historyEnabledPrevious = historyEnabled
        } else if (parsed.preference === "history_source" && parsed.value !== undefined) {
          historySource = String(parsed.value) === "server" ? "server" : "local"
          historySourcePrevious = historySource
        } else if (parsed.preference === "history_range"
            && parsed.history_hours !== undefined) {
          historyHours = root.normalizeHistoryHours(parsed.history_hours)
          historyCustom = parsed.history_custom === true
          historyHoursPrevious = historyHours
          historyCustomPrevious = historyCustom
          customHistoryHoursText = root.formatHours(historyHours)
        } else if (parsed.value !== undefined
            && root.applyExperimentalPreference(parsed.preference, parsed.value)) {
          // The experimental setting has already been normalized by the helper.
          if (parsed.preference === "experimental_history_enabled"
              && parsed.history_hours !== undefined) {
            historyHours = root.normalizeHistoryHours(parsed.history_hours)
            historyCustom = parsed.history_custom === true
            historyHoursPrevious = historyHours
            historyCustomPrevious = historyCustom
            customHistoryHoursText = root.formatHours(historyHours)
          }
        } else {
          root.restorePreference(preferenceKind)
          setupError = "The preference returned incomplete data."
          return
        }
        setupError = ""
        return
      }
      root.restorePreference(preferenceKind)
      setupError = parsed && parsed.error
        ? String(parsed.error) : "The preference could not be saved."
    } catch (e) {
      root.restorePreference(preferenceKind)
      setupError = "The preference returned invalid data."
    }
  }

  function adjustTarget(direction) {
    if (masterSwitchBusy || !connected || !isOn
        || targetValue === null || targetValue === undefined) return
    var currentDisplay = root.convertTemperature(
      Number(targetValue), unit, displayTemperatureUnitCode)
    var nextDisplay = currentDisplay + direction * displayTemperatureStep
    var next = normalizeTarget(root.convertTemperature(
      nextDisplay, displayTemperatureUnitCode, unit))
    if (next === null) return
    localTarget = next
    temperatureCommitTimer.restart()
  }

  function previewTarget(value) {
    if (masterSwitchBusy || !connected || !isOn) return
    var next = normalizeTarget(root.convertTemperature(
      value, displayTemperatureUnitCode, unit))
    if (next === null) return
    localTarget = next
  }

  function commitTarget(value) {
    root.previewTarget(value)
    temperatureCommitTimer.restart()
  }

  function commitPendingTemperature() {
    if (masterSwitchBusy || !connected || !isOn || !hasLocalTarget) return
    var value = Number(localTarget)
    if (!isFinite(value)) return
    if (temperatureInFlight !== null || actionProcess.running) return
    if (lastTemperatureSent !== null && sameTemperature(value, lastTemperatureSent)) return
    temperatureInFlight = value
    actionEntityId = ""
    actionKind = "temperature"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-temperature", String(value)]
    actionProcess.running = true
  }

  function requestPower(requestedPower, cancellable, dispatchAfter) {
    dispatchAfter = Number(dispatchAfter)
    var now = Date.now()
    pendingPowerState = requestedPower === "on" ? "turning_on" : "turning_off"
    powerRequestStartedAt = 0
    powerDispatchDueAt = isFinite(dispatchAfter) ? Math.max(0, dispatchAfter) : 0
    powerReadbackMarker = root.powerMarker(reading)
    powerFinalCheckPending = false
    powerTimedOut = false
    powerTimeoutMessage = ""
    powerCanCancel = cancellable
    errorText = ""
    if (actionProcess.running || powerDispatchDueAt > now) {
      queuedPowerRequest = requestedPower
      if (powerDispatchDueAt > now) root.scheduleQueuedPowerRequest()
      return
    }
    queuedPowerRequest = ""
    root.dispatchPowerRequest(requestedPower)
  }

  function scheduleQueuedPowerRequest() {
    if (queuedPowerRequest === "" || actionProcess.running) return
    var dueAt = Number(powerDispatchDueAt)
    if (isFinite(dueAt) && dueAt > Date.now()) {
      powerDispatchDelayTimer.interval = Math.max(50, dueAt - Date.now())
      powerDispatchDelayTimer.restart()
      return
    }
    var requested = queuedPowerRequest
    queuedPowerRequest = ""
    powerDispatchDueAt = 0
    root.dispatchPowerRequest(requested)
  }

  function dispatchPowerRequest(requestedPower) {
    powerRequestStartedAt = Date.now()
    powerDispatchDueAt = 0
    actionEntityId = ""
    actionKind = "power"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-power", requestedPower]
    actionProcess.running = true
  }

  function togglePower() {
    if (masterSwitchBusy || actionProcess.running || !connected
        || (hasLocalPower && !powerTimedOut) || modeRestarting) return
    root.requestPower(isOn ? "off" : "on", true)
  }

  function toggleUnitPowerShortcut(slot) {
    if (!root.shortcutsEnabled || !root.shortcutEnabled("toggle_power")
        || !root.multiUnitEnabled || root.globalSyncControls
        || root.masterSwitchBusy || !root.connected) return
    var index = Number(slot)
    if (!isFinite(index) || index < 1 || index > 9
        || index > root.selectedEntities.length) return
    var id = String(root.selectedEntities[index - 1] || "")
    var climate = root.unitReading(id)
    if (!climate) {
      root.refresh()
      return
    }
    var state = root.unitLocalState(id)
    if (state.power && state.powerCanCancel === true && state.powerTimedOut !== true) {
      root.cancelUnitPower(id)
      return
    }
    var observedState = String(climate.state || "").toLowerCase()
    var isUnitOn = state.power === "turning_on"
      || (state.power !== "turning_off" && observedState !== "off")
    root.requestUnitPower(id, isUnitOn ? "off" : "on", true)
  }

  function cancelPower() {
    if (masterSwitchBusy || !connected || !hasLocalPower || powerTimedOut || !powerCanCancel) return
    var dueAt = Date.now()
    if (powerRequestStartedAt > 0)
      dueAt = Math.max(dueAt, powerRequestStartedAt + 5000)
    root.requestPower(localPower ? "off" : "on", false, dueAt)
  }

  Process {
    id: configProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyConfig(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control", text.trim())
    }
  }

  Process {
    id: shortcutSyncProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var output = String(text || "").trim()
        if (output !== "") {
          try {
            var parsed = JSON.parse(output)
            if (parsed.shortcut_sync_error)
              console.warn("aircon-control shortcuts", parsed.shortcut_sync_error)
          } catch (error) {
            console.warn("aircon-control shortcuts", output)
          }
        }
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control shortcuts", text.trim())
    }
  }

  Process {
    id: preferenceProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyPreferenceResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control", text.trim())
    }
    onExited: {
      var completedPreference = root.preferenceKind
      root.preferenceBusy = false
      root.preferenceKind = ""
      if (completedPreference === "history_source"
          || completedPreference === "history_range") Qt.callLater(root.refresh)
    }
  }

  Process {
    id: configFileProcess
    stdinEnabled: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyConfigFileResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control config", text.trim())
    }
    onStarted: {
      write(root.configFilePayload + "\n")
      root.configFilePayload = ""
    }
    onExited: root.configFileBusy = false
  }

  Process {
    id: remoteHistoryProcess
    stdinEnabled: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyRemoteHistoryResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("homeassistant-ac-history", text.trim())
    }
    onStarted: {
      write(root.remoteHistoryPayload + "\n")
      root.remoteHistoryPayload = ""
    }
    onExited: {
      root.remoteHistoryBusy = false
      root.remoteHistoryAction = ""
      if (root.remoteHistoryOperationSucceeded) Qt.callLater(root.refresh)
    }
  }

  Process {
    id: remoteHistorySourceProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyRemoteHistorySource(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("homeassistant-ac-source", text.trim())
    }
    onExited: {
      if (root.remoteHistorySourceBusy) {
        root.remoteHistorySourceBusy = false
      }
    }
  }

  Process {
    id: localServerProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyLocalServerResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("homeassistant-local-setup", text.trim())
    }
    onExited: root.localServerBusy = false
  }

  Process {
    id: resetAppProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyResetAppResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("homeassistant-ac-reset", text.trim())
    }
    onExited: root.resetAppBusy = false
  }

  Process {
    id: uninstallProcess
    stdout: StdioCollector {
      waitForEnd: true
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.uninstallProcessStderr = String(text || "").trim()
    }
    onStarted: root.uninstallMessage = "Goodbye :( Removing Daikin AC Controls…"
    onExited: function(exitCode) {
      root.uninstallBusy = false
      if (exitCode !== 0) {
        root.uninstallConfirming = true
        root.uninstallError = root.uninstallProcessStderr !== ""
          ? "Uninstall could not complete: " + root.uninstallProcessStderr.split("\n")[0]
          : "Uninstall could not complete; the plugin is still installed."
        return
      }
      root.uninstallMessage = "Goodbye :( Daikin AC Controls has been removed."
      root.close()
    }
  }

  Process {
    id: turnOffAllProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyTurnOffAllResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("homeassistant-ac-all-off", text.trim())
    }
    onExited: {
      root.turnOffAllBusy = false
      Qt.callLater(root.refresh)
    }
  }

  Process {
    id: turnOnAllProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyTurnOnAllResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("homeassistant-ac-all-on", text.trim())
    }
    onExited: {
      root.turnOnAllBusy = false
      Qt.callLater(root.refresh)
    }
  }

  Timer {
    id: turnOffAllConfirmTimer
    interval: 5000
    repeat: false
    onTriggered: root.turnOffAllConfirming = false
  }

  Timer {
    id: turnOnAllConfirmTimer
    interval: 5000
    repeat: false
    onTriggered: root.turnOnAllConfirming = false
  }

  Timer {
    id: localServerConfirmTimer
    interval: 5000
    repeat: false
    onTriggered: root.localServerConfirming = false
  }

  Process {
    id: setupProcess
    stdinEnabled: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applySetupResult(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control", text.trim())
    }
    onStarted: {
      write(root.setupPayload + "\n")
      root.setupPayload = ""
    }
    onExited: {
      root.setupBusy = false
      if (root.setupSucceeded) {
        root.setupSucceeded = false
        Qt.callLater(root.refresh)
      }
    }
  }

  Process {
    id: entitiesProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyEntities(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control", text.trim())
    }
  }

  Process {
    id: statusProcess
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyResult(text, "status")
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control", text.trim())
    }
  }

  Process {
    id: actionProcess
    stdinEnabled: true
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyResult(text, "action")
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control", text.trim())
    }
    onStarted: {
      if (root.actionKind === "selection") {
        write(root.selectionPayload + "\n")
        root.selectionPayload = ""
      }
    }
    onExited: {
      var completedKind = actionKind
      var queuedPower = queuedPowerRequest
      var queuedUnitPowerEntity = queuedUnitPowerEntityId
      var queuedUnitPower = queuedUnitPowerRequest
      var queuedControl = queuedControlKind
      var queuedValue = queuedControlValue
      if (completedKind === "temperature") {
        var completedTarget = temperatureInFlight
        temperatureInFlight = null
        if (hasLocalTarget && completedTarget !== null && !sameTemperature(localTarget, completedTarget))
          temperatureCommitTimer.restart()
      }
      if (completedKind === "mode") modeInFlight = ""
      if (completedKind === "fan") fanModeInFlight = ""
      actionBusy = false
      actionKind = ""
      actionEntityId = ""
      if (queuedUnitPowerEntity !== "") {
        Qt.callLater(root.scheduleQueuedUnitPowerRequest)
      } else if (queuedPower !== "") {
        Qt.callLater(root.scheduleQueuedPowerRequest)
      } else if (queuedControl !== "") {
        queuedControlKind = ""
        queuedControlValue = ""
        if (queuedControl === "mode")
          Qt.callLater(function() { root.dispatchModeRequest(queuedValue) })
        else if (queuedControl === "fan")
          Qt.callLater(function() { root.dispatchFanModeRequest(queuedValue) })
      } else if (completedKind === "power") {
        Qt.callLater(root.refreshStatus)
      } else {
        Qt.callLater(root.refresh)
      }
    }
  }

  Timer {
    id: temperatureCommitTimer
    interval: 250
    repeat: false
    onTriggered: root.commitPendingTemperature()
  }

  Timer {
    id: powerDispatchDelayTimer
    interval: 100
    repeat: false
    onTriggered: root.scheduleQueuedPowerRequest()
  }

  Timer {
    id: unitPowerDispatchDelayTimer
    interval: 100
    repeat: false
    onTriggered: root.scheduleQueuedUnitPowerRequest()
  }

  Timer {
    id: powerConfirmTimer
    interval: 500
    repeat: true
    running: root.hasLocalPower && !root.powerTimedOut
    onTriggered: {
      if (!root.hasLocalPower || root.powerTimedOut) return
      if (root.powerRequestStartedAt <= 0
          || root.powerDispatchDueAt > Date.now()) return
      if (Date.now() - root.powerRequestStartedAt < 15000) return
      if (root.powerFinalCheckPending) return
      if (root.refreshStatus()) root.powerFinalCheckPending = true
    }
  }

  Timer {
    id: unitPowerConfirmTimer
    interval: 500
    repeat: true
    running: root.hasPendingUnitPower()
    onTriggered: {
      if (!root.hasPendingUnitPower() || actionProcess.running || statusProcess.running) return
      root.markUnitPowerFinalChecks()
    }
  }

  Timer {
    id: modeRestartTimer
    interval: 500
    repeat: true
    running: root.modeRestarting
    onTriggered: {
      if (!root.modeRestarting) return
      if (Date.now() - root.modeRestartStartedAt >= 15000) {
        root.clearModeRestart()
        root.errorText = "The AC did not come back on after switching modes. Try TURN ON to retry."
        return
      }
      if (!actionProcess.running && !statusProcess.running) root.refreshStatus()
    }
  }

  Timer {
    id: setupTransitionTimer
    interval: root.motionStandard
    repeat: false
    onTriggered: {
      root.setupOpen = true
      root.setupTransitionClosing = false
      if (!root.configured) Qt.callLater(function() {
        if (root.setupOpen && root.setupTransitioning) setupHostField.forceActiveFocus()
      })
      setupTransitionFinishTimer.restart()
    }
  }

  Timer {
    id: setupTransitionFinishTimer
    interval: root.motionEmphasis
    repeat: false
    onTriggered: {
      root.setupTransitioning = false
      root.setupTransitionClosing = false
    }
  }

  readonly property int pollSeconds: Math.max(15, Number(setting("poll_seconds", 30)) || 30)
  Timer {
    interval: root.pollSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    // Keep the chart's right edge anchored to the current time while the
    // selected range remains the exact rolling window shown to the user.
    interval: 1000
    running: root.historyChartVisible
    repeat: true
    onTriggered: root.historyWindowRevision += 1
  }

  Timer {
    id: configFileRefreshTimer
    interval: 1
    repeat: false
    onTriggered: if (root.configFileModeEnabled) root.refreshConfigFileText()
  }

  onOpenedChanged: {
    if (opened) {
      root.syncSetupAddressFields(root.setupUrl)
      root.refresh()
      Qt.callLater(root.applyGlobalTabNavigation)
    } else {
      setupTransitionTimer.stop()
      setupTransitionFinishTimer.stop()
      setupTransitioning = false
      setupTransitionClosing = false
      connectionEditing = false
      connectionReconnecting = false
      localServerExpanded = false
      if (remoteHistoryReconfiguring && !remoteHistoryBusy)
        root.cancelRemoteHistoryReconfigure()
      else remoteHistoryReconfiguring = false
    }
  }

  onSetupUrlChanged: {
    if (!root.setupAddressSyncing) root.syncSetupAddressFields(root.setupUrl)
  }
  onGlobalTabNavigationEnabledChanged: Qt.callLater(function() {
    root.applyGlobalTabNavigation()
    if (!root.globalTabNavigationEnabled && !root.configFileModeEnabled
        && root.opened && keyCatcher)
      keyCatcher.forceActiveFocus()
  })
  onHistoryHoursChanged: historyWindowRevision += 1
  onHistoryChartVisibleChanged: if (historyChartVisible) historyWindowRevision += 1
  onUnitReadingsChanged: Qt.callLater(root.applyGlobalTabNavigation)
  onSelectedEntitiesChanged: Qt.callLater(root.applyGlobalTabNavigation)
  onConfigFileModeEnabledChanged: {
    Qt.callLater(root.applyGlobalTabNavigation)
    if (root.configFileModeEnabled) {
      root.scheduleConfigFileRefresh()
      Qt.callLater(root.focusConfigFileEditor)
    }
  }

  onResetAppConfirmingChanged: {
    if (root.resetAppConfirming) root.focusConfirmationItem(resetConfirmButton)
  }

  onUninstallConfirmingChanged: {
    if (root.uninstallConfirming) root.focusConfirmationItem(uninstallBackButton)
  }

  Timer {
    id: confirmationFocusTimer
    interval: 16
    repeat: true
    property var targetItem: null
    property int attempts: 0
    onRunningChanged: if (running) attempts = 0
    onTriggered: {
      attempts += 1
      var item = targetItem
      if (!item) {
        stop()
        return
      }
      if (item.enabled && item.visible && item.opacity > 0.01
          && item.width > 0 && item.height > 0) {
        item.forceActiveFocus()
        root.ensurePanelFocusVisible(item)
        stop()
      } else if (attempts >= 24) {
        stop()
      }
    }
  }

  onSetupOpenChanged: {
    if (root.setupOpen && root.configFileModeEnabled) {
      root.scheduleConfigFileRefresh()
      Qt.callLater(root.focusConfigFileEditor)
    }
  }

  onSettingsSectionChanged: {
    if (settingsSection === "shortcuts" && !shortcutsEnabled)
      settingsSection = "experimental"
    if (settingsSection === "customisation" && !customAppearanceEnabled)
      settingsSection = "experimental"
    if (settingsSection !== "maintenance" && connectionEditing && !setupBusy)
      root.cancelReconnect()
    if (settingsSection !== "maintenance") localServerExpanded = false
    if (settingsSection !== "setup" && remoteHistoryReconfiguring
        && !remoteHistoryBusy) root.cancelRemoteHistoryReconfigure()
    Qt.callLater(root.applyGlobalTabNavigation)
  }

  Shortcut {
    id: settingsBackShortcut
    enabled: root.setupOpen && root.configured && root.shortcutsEnabled
      && root.shortcutEnabled("settings_back") && !root.shortcutCaptureActive
    sequence: root.shortcutQmlSequence(root.shortcutValue("settings_back"))
    onActivated: root.cancelSetup()
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.openFromHotkey() }
    function close(): void { root.close() }
    function show(): void { root.openFromHotkey() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function settings(): void {
      root.controller.show()
      root.loadConfig(true)
      root.refresh()
      Qt.callLater(root.openSetup)
    }
    function settings_previous(): void { root.navigateSettingsFromShortcut(-1) }
    function settings_next(): void { root.navigateSettingsFromShortcut(1) }
    function power_1(): void { root.toggleUnitPowerShortcut(1) }
    function power_2(): void { root.toggleUnitPowerShortcut(2) }
    function power_3(): void { root.toggleUnitPowerShortcut(3) }
    function power_4(): void { root.toggleUnitPowerShortcut(4) }
    function power_5(): void { root.toggleUnitPowerShortcut(5) }
    function power_6(): void { root.toggleUnitPowerShortcut(6) }
    function power_7(): void { root.toggleUnitPowerShortcut(7) }
    function power_8(): void { root.toggleUnitPowerShortcut(8) }
    function power_9(): void { root.toggleUnitPowerShortcut(9) }
    function refresh(): string { root.refresh(); return "ok" }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    borderSpec: root.panelBorderSpec
    contentWidth: panel.fittedContentWidth(root.setupOpen
      ? (root.configured
        ? (root.configFileModeEnabled ? Style.space(680) : Style.space(600))
        : Style.space(520))
      : (root.separateRemotesActive ? Style.space(620) : Style.space(360)))
    contentHeight: panel.fittedContentHeight(root.setupOpen
      ? onboardingColumn.implicitHeight : column.implicitHeight)

    Behavior on contentHeight {
      NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
    }

    // KeyboardPanel keeps its stock card just outside this content item. Pull
    // the customised surface back over that inset so the card border and the
    // surrounding outer layer use the same background as the plugin surface.
    BorderSurface {
      id: outerPanelSurface
      visible: root.customAppearanceEnabled
      anchors.fill: parent
      // contentHolder already starts after the shell card's border. Pull the
      // surface back only across the card padding; including the border width
      // here paints over KeyboardPanel's real accent outline and breaks its
      // rounded corners when customisation is enabled.
      anchors.leftMargin: -panel.padding
      anchors.rightMargin: -panel.padding
      anchors.topMargin: -panel.padding
      anchors.bottomMargin: -panel.padding
      z: -3
      // Keep the inner fill inside the card border while matching the shell's
      // corner geometry instead of drawing a second offset outline.
      radius: Math.max(0, Style.cornerRadius - Math.max(
        Border.left(panel.borderSpec), Border.top(panel.borderSpec),
        Border.right(panel.borderSpec), Border.bottom(panel.borderSpec)))
      color: root.panelSurface
      // The actual outer border is supplied through KeyboardPanel.borderSpec;
      // painting another border on this inset overlay creates doubled lines
      // and broken-looking corners.
      borderSpec: Border.none()
    }

    // Keep the panel readable over bright windows. The stock popup surface
    // can inherit a translucent theme alpha, so the plugin adds an opaque
    // surface behind its own content without changing the user's theme.
    Rectangle {
      anchors.fill: parent
      z: -1
      radius: Style.cornerRadius
      color: root.panelSurface
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: -Style.space(8) * root.appearanceSoftness
      z: -2
      radius: Style.cornerRadius
      color: root.alpha(root.accentColor, root.appearanceSoftness * 0.08)
      opacity: root.appearanceSoftness
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      activeFocusOnTab: false
      // Text editors and clicked controls own their keys. The catcher remains
      // available when global Tab is off so its Tab handler can hand control
      // back to the shell instead of allowing Qt to walk a stale focus chain.
      blocked: (root.setupOpen && (setupHostField.activeFocus === true
          || setupPortField.activeFocus === true
          || setupTokenField.activeFocus === true
          || reconnectHostField.activeFocus === true
          || reconnectPortField.activeFocus === true
          || reconnectTokenField.activeFocus === true
          || !!setupEntityDropdown.popupOpen
          || !!reconnectEntityDropdown.popupOpen
          || remoteHistoryTargetField.activeFocus === true
          || remoteHistoryPortField.activeFocus === true
          || remoteHistoryUrlField.activeFocus === true
          || root.configFileModeEnabled === true
          || configFileEditor.activeFocus === true
          || root.shortcutCaptureActive === true))
        || (!!panel.activeFocusItem && panel.activeFocusItem !== keyCatcher)
      onCloseRequested: {
        if (root.setupOpen && root.configured) {
          if (!root.shortcutsEnabled || root.shortcutEnabled("settings_back")) root.cancelSetup()
          else root.close()
        } else {
          root.close()
        }
      }
      onActivateRequested: root.refresh()
      onTabRequested: function(direction) {
        if (root.globalTabNavigationEnabled) root.focusNextPanelItem(direction)
        else if (!root.configFileModeEnabled) root.switchPanel(direction)
      }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refresh()
        else if (t === "-" || t === "_") root.adjustTarget(-1)
        else if (t === "+" || t === "=") root.adjustTarget(1)
        else if (t === "p" || t === "P") {
          if (root.hasLocalPower && root.powerCanCancel) root.cancelPower()
          else root.togglePower()
        }
      }

      Flickable {
        id: panelScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: root.setupOpen
          ? onboardingColumn.implicitHeight : column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          // Text fields and other Qt controls can receive Tab before the panel
          // key catcher. Handle it here in both modes: the explicit option
          // walks this panel, while the hard-off path returns to the shell.
          if (!root.configFileModeEnabled
              && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            event.accepted = true
            var direction = (event.modifiers & Qt.ShiftModifier) !== 0
              || event.key === Qt.Key_Backtab ? -1 : 1
            if (root.globalTabNavigationEnabled)
              root.focusNextPanelItem(
                direction)
            else
              root.switchPanel(direction)
            return
          }
          if (event.key === Qt.Key_Escape) {
            event.accepted = true
            if (root.setupOpen && root.configured) root.cancelSetup()
            else root.close()
          }
        }

        Connections {
          target: root
          function onSetupOpenChanged() { panelScroll.contentY = 0 }
        }

      Column {
        id: onboardingColumn
        visible: root.setupOpen
        width: parent.width
        spacing: root.compactChromeEnabled ? Style.space(6) : Style.space(10)

        BorderSurface {
          id: setupHero
          width: parent.width
          height: Style.space(94)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.foreground, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.16), 1))

          Column {
            anchors.centerIn: parent
            width: parent.width - Style.space(36)
            spacing: Style.space(4)

            Text {
              width: parent.width
              text: root.configured ? "SETTINGS" : "SETUP"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: parent.width
              text: root.configured
                ? "Connection, controls, and local setup."
                : "Connect Home Assistant to control your Daikin AC from the bar."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }

            Text {
              width: parent.width
              text: "VERSION " + root.pluginVersion
              color: root.accentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }

        BorderSurface {
          id: settingsNavigationCard
          visible: root.configured
          width: parent.width
          implicitHeight: settingsNavigationForm.implicitHeight
            + (root.compactChromeEnabled ? Style.space(12) : Style.space(20))
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.foreground, 0.025))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.14), 1))

          Column {
            id: settingsNavigationForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.compactChromeEnabled ? Style.space(6) : Style.space(10)
            spacing: root.compactChromeEnabled ? Style.space(4) : Style.space(7)

            AcButton {
              id: backToControlsButton
              visible: root.configured
              width: parent.width
              height: root.compactChromeEnabled ? Style.space(32) : Style.space(38)
              focusable: true
              text: "BACK TO AC CONTROLS"
              iconText: "←"
              iconSize: Style.font.body
              fontSize: Style.font.bodySmall
              enabled: !root.setupBusy && !root.localServerBusy && !root.setupTransitioning
                && !root.uninstallBusy && !root.uninstallConfirming
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.accentColor, 0.08)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              tooltipText: "Return to the AC controls"
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  event.accepted = true
                  root.cancelSetup()
                }
              }
              onClicked: root.cancelSetup()
            }

            ChromeToggle {
              id: configFileModeToggle
              visible: root.configFileModeEnabled
              width: parent.width
              label: "CONFIG FILE MODE"
              description: "Replace the setting cards with a keyboard-first JSON editor. Secrets stay hidden."
              checked: root.configFileModeEnabled
              enabled: !root.preferenceBusy && !root.configFileBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setConfigFileModeEnabled(!root.configFileModeEnabled)
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  event.accepted = true
                  root.cancelSetup()
                } else if (event.key === Qt.Key_Tab) {
                  event.accepted = true
                  if (root.configFileBackwardTab(event))
                    backToControlsButton.forceActiveFocus()
                  else
                    configFileEditor.forceActiveFocus()
                } else if (event.key === Qt.Key_Backtab) {
                  event.accepted = true
                  backToControlsButton.forceActiveFocus()
                }
              }
            }

            Row {
              id: settingsSectionChoices
              visible: !root.configFileModeEnabled
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.settingsSections

                AcButton {
                  required property var modelData
                  width: (settingsSectionChoices.width
                    - settingsSectionChoices.spacing * (root.settingsSections.length - 1))
                    / root.settingsSections.length
                  height: root.compactChromeEnabled ? Style.space(30) : Style.space(34)
                  text: modelData.label
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(3)
                  foreground: root.foreground
                  accent: root.accentColor
                  background: root.alpha(root.foreground, 0.025)
                  bordered: !root.compactChromeEnabled
                  selected: root.settingsSection === modelData.value
                  radius: root.compactRadius
                  onClicked: root.settingsSection = modelData.value
                }
              }
            }
          }
        }

        BorderSurface {
          id: configFileCard
          visible: root.configured && root.configFileModeEnabled
          width: parent.width
          implicitHeight: configFileForm.implicitHeight + Style.space(28)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))
          onVisibleChanged: if (visible) root.scheduleConfigFileRefresh()
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              event.accepted = true
              root.cancelSetup()
            } else if ((event.modifiers & Qt.ControlModifier) !== 0
                && event.key === Qt.Key_R) {
              event.accepted = true
              root.reloadConfigFile()
            } else if ((event.modifiers & Qt.ControlModifier) !== 0
                && event.key === Qt.Key_S) {
              event.accepted = true
              root.applyConfigFile()
            }
          }

          Column {
            id: configFileForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(14)
            spacing: Style.space(8)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Column {
                width: parent.width - configFileHint.implicitWidth - parent.spacing
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: "KEYBOARD CONFIG"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Text {
                  width: parent.width
                  text: "PREFERENCES JSON · TOKEN HIDDEN"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.7
                }
              }

              Text {
                id: configFileHint
                text: "CTRL+S / CTRL+ENTER"
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                verticalAlignment: Text.AlignVCenter
              }
            }

            Text {
              width: parent.width
              text: "Edit JSON with the keyboard. Ctrl+S or Ctrl+Enter applies, Ctrl+R reloads, and Tab cycles through the editor actions. Esc returns to AC controls. Use "
                + root.shortcutDisplay(root.shortcutValue("open_settings"))
                + " to reopen Settings when Keyboard shortcuts are enabled. The saved Home Assistant connection URL and token stay protected and are never shown here."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Flickable {
              id: configFileEditorScroll
              width: parent.width
              height: Style.space(420)
              // The attached scrollbar is drawn over the right edge of its
              // viewport. Reserve a real gutter so the editor's rounded
              // border remains continuous at the top-right corner.
              readonly property real editorRightInset: Style.space(18)
              contentWidth: configFileEditor.width
              contentHeight: Math.max(height,
                configFileEditor.contentHeight + configFileEditor.topPadding
                  + configFileEditor.bottomPadding)
              clip: true
              boundsBehavior: Flickable.StopAtBounds
              flickableDirection: Flickable.VerticalFlick
              interactive: true
              ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                interactive: true
              }

              onContentHeightChanged: Qt.callLater(root.ensureConfigFileCursorVisible)

              TextArea {
                id: configFileEditor
                width: Math.max(1, configFileEditorScroll.width
                  - configFileEditorScroll.editorRightInset)
                height: Math.max(configFileEditorScroll.height,
                  contentHeight + topPadding + bottomPadding)
                text: root.configFileText
                enabled: !root.configFileBusy
                color: root.foreground
                selectionColor: root.alpha(root.controlAccentColor, 0.36)
                selectedTextColor: root.foreground
                font.family: "monospace"
                font.pixelSize: Style.font.caption
                readonly property var editorBorderSpec: Border.flat(
                  configFileEditor.activeFocus
                    ? root.controlAccentColor
                    : root.alpha(root.controlAccentColor, 0.34),
                  Math.max(1, Style.space(1)))
                leftPadding: Style.space(10) + Border.left(editorBorderSpec)
                rightPadding: Style.space(10) + Border.right(editorBorderSpec)
                topPadding: Style.space(10) + Border.top(editorBorderSpec)
                bottomPadding: Style.space(10) + Border.bottom(editorBorderSpec)
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.NoWrap
                activeFocusOnTab: true
                background: BorderSurface {
                  color: root.alpha(root.appearanceBackgroundColor, 0.88)
                  radius: root.compactRadius
                  borderSpec: configFileEditor.editorBorderSpec
                }
                onTextChanged: {
                  if (!root.configFileEditorSyncing) {
                    if (text !== root.configFileText) root.configFileText = text
                    if (!root.configFileBusy) root.configFileStatus = ""
                  }
                  Qt.callLater(root.ensureConfigFileCursorVisible)
                }
                onCursorPositionChanged: {
                  // Do one immediate pass for key-repeat, then another after
                  // Qt has laid out the newly selected line.
                  root.ensureConfigFileCursorVisible()
                  Qt.callLater(root.ensureConfigFileCursorVisible)
                }
                onVisibleChanged: {
                  if (visible && root.configFileModeEnabled) {
                    root.scheduleConfigFileRefresh()
                    Qt.callLater(root.focusConfigFileEditor)
                  }
                }
                onActiveFocusChanged: {
                  if (activeFocus) {
                    if (String(text || "").trim() === "")
                      root.scheduleConfigFileRefresh()
                    Qt.callLater(root.ensureConfigFileCursorVisible)
                  }
                }

                WheelHandler {
                  id: configFileWheelHandler
                  target: null
                  onWheel: function(event) {
                    var delta = Number(event.angleDelta.y || 0)
                    if (delta === 0) delta = Number(event.pixelDelta.y || 0)
                    if (delta !== 0) {
                      root.scrollConfigFileBy(-delta / 3)
                      event.accepted = true
                    }
                  }
                }

                Keys.onEscapePressed: function(event) {
                  event.accepted = true
                  root.cancelSetup()
                }
                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    event.accepted = true
                    if (root.configFileBackwardTab(event))
                      configFileModeToggle.forceActiveFocus()
                    else
                      configFileApplyButton.forceActiveFocus()
                  } else if ((event.modifiers & Qt.ControlModifier) !== 0
                      && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_S)) {
                    event.accepted = true
                    root.applyConfigFile()
                  } else if ((event.modifiers & Qt.ControlModifier) !== 0
                      && event.key === Qt.Key_R) {
                    event.accepted = true
                    root.reloadConfigFile()
                  } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down
                      || event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
                    root.ensureConfigFileCursorVisible()
                    Qt.callLater(root.ensureConfigFileCursorVisible)
                  }
                }
              }

              // Some Qt builds coalesce cursor-change callbacks while a key
              // is held. Keep the viewport following the cursor until the
              // repeat finishes, including the exact bottom end position.
              Timer {
                id: configFileCursorVisibilityTimer
                interval: 16
                repeat: true
                running: root.setupOpen && root.configFileModeEnabled
                  && configFileEditor.visible && configFileEditor.activeFocus
                onTriggered: root.ensureConfigFileCursorVisible()
              }
            }

            Text {
              visible: root.configFileStatus !== ""
              width: parent.width
              text: root.configFileStatus
              color: root.accentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Text {
              visible: root.configFileError !== ""
              width: parent.width
              text: root.configFileError
              color: root.urgent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              AcButton {
                id: configFileApplyButton
                width: parent.width - configFileReloadButton.width - parent.spacing
                height: Style.space(38)
                text: root.configFileBusy ? "APPLYING…" : "APPLY CONFIG"
                iconText: root.configFileBusy ? "" : "✓"
                iconSize: Style.font.body
                fontSize: Style.font.bodySmall
                enabled: !root.configFileBusy && !root.preferenceBusy
                fontFamily: root.fontFamily
                foreground: root.accentTextColor
                accent: root.accentColor
                background: root.accentColor
                bordered: false
                radius: root.compactRadius
                focusable: true
                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    event.accepted = true
                    if (root.configFileBackwardTab(event))
                      configFileEditor.forceActiveFocus()
                    else
                      configFileReloadButton.forceActiveFocus()
                  } else if (event.key === Qt.Key_Escape) {
                    event.accepted = true
                    root.cancelSetup()
                  }
                }
                onClicked: root.applyConfigFile()
              }

              AcButton {
                id: configFileReloadButton
                width: Style.space(102)
                height: Style.space(38)
                text: "RELOAD"
                fontSize: Style.font.caption
                enabled: !root.configFileBusy && !root.preferenceBusy
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: !root.compactChromeEnabled
                radius: root.compactRadius
                focusable: true
                tooltipText: "Discard edits and reload the current settings"
                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    event.accepted = true
                    if (root.configFileBackwardTab(event))
                      configFileApplyButton.forceActiveFocus()
                    else
                      configFileModeToggle.forceActiveFocus()
                  } else if (event.key === Qt.Key_Escape) {
                    event.accepted = true
                    root.cancelSetup()
                  }
                }
                onClicked: {
                  root.reloadConfigFile()
                }
              }
            }
          }
        }

        BorderSurface {
          id: setupCard
          visible: !root.configured
          width: parent.width
          implicitHeight: setupForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.foreground, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.16), 1))

          Column {
            id: setupForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(9)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: parent.width - setupStep.implicitWidth - parent.spacing
                text: root.configured ? "Connection settings" : "Connect Home Assistant"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
              }

              Text {
                id: setupStep
                text: root.setupEntityOptions.length > 0 ? "2 / 2" : "1 / 2"
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 0.8
              }
            }

            Text {
              width: parent.width
              text: root.setupEntityOptions.length > 0
                ? "Home Assistant is connected. Choose which climate entity this widget should control."
                : "Use the same Home Assistant account that already manages your Daikin AC."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            Text {
              text: "HOME ASSISTANT ADDRESS"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
            }

            Row {
              id: setupAddressRow
              width: parent.width
              spacing: Style.space(5)

              Text {
                id: setupSchemeLabel
                text: root.setupAddressScheme + "://"
                color: root.controlAccentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }

              TextField {
                id: setupHostField
                width: Math.max(0, setupAddressRow.width
                  - setupSchemeLabel.implicitWidth - setupPortSeparator.implicitWidth
                  - setupPortField.width - setupAddressRow.spacing * 3)
                enabled: !root.setupBusy && !root.localServerBusy
                placeholderText: "homeassistant.local or 192.168.0.10"
                text: root.setupAddressHost
                foreground: root.foreground
                accent: root.controlAccentColor
                font.family: root.fontFamily
                inputMethodHints: Qt.ImhUrlCharactersOnly
                selectByMouse: true
                background: BorderSurface {
                  color: root.controlSurfaceColor(setupHostField)
                  borderSpec: root.controlSurfaceBorder(setupHostField)
                  radius: root.compactRadius
                }
                onTextChanged: {
                  if (!root.setupAddressSyncing && text !== root.setupAddressHost)
                    root.setupAddressHost = text
                }
                onEditingFinished: root.updateSetupUrlFromAddress()
                onAccepted: {
                  root.updateSetupUrlFromAddress()
                  setupPortField.forceActiveFocus()
                }
                Keys.onEscapePressed: if (root.configured) root.cancelSetup()
              }

              Text {
                id: setupPortSeparator
                text: ":"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                anchors.verticalCenter: parent.verticalCenter
              }

              TextField {
                id: setupPortField
                width: Style.space(72)
                enabled: !root.setupBusy && !root.localServerBusy
                placeholderText: "8123"
                text: root.setupAddressPort
                foreground: root.foreground
                accent: root.controlAccentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                horizontalAlignment: Text.AlignHCenter
                inputMethodHints: Qt.ImhDigitsOnly
                maximumLength: 5
                validator: IntValidator { bottom: 1; top: 65535 }
                selectByMouse: true
                background: BorderSurface {
                  color: root.controlSurfaceColor(setupPortField)
                  borderSpec: root.controlSurfaceBorder(setupPortField)
                  radius: root.compactRadius
                }
                onTextChanged: {
                  if (!root.setupAddressSyncing && text !== root.setupAddressPort)
                    root.setupAddressPort = text
                }
                onEditingFinished: root.updateSetupUrlFromAddress()
                onAccepted: {
                  root.updateSetupUrlFromAddress()
                  setupTokenField.forceActiveFocus()
                }
              }
            }

            Text {
              width: parent.width
              text: "Enter the Home Assistant hostname or IP address and port. HTTP is the default; HTTPS and reverse-proxy paths are supported."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Text {
              text: "LONG-LIVED ACCESS TOKEN"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
            }

            TextField {
              id: setupTokenField
              width: parent.width
              enabled: !root.setupBusy && !root.localServerBusy
              password: true
              placeholderText: root.configured
                ? "Paste a new token to replace the saved one"
                : "Paste your Home Assistant token"
              text: root.setupToken
              foreground: root.foreground
              accent: root.controlAccentColor
              font.family: root.fontFamily
              selectByMouse: true
              background: BorderSurface {
                color: root.controlSurfaceColor(setupTokenField)
                borderSpec: root.controlSurfaceBorder(setupTokenField)
                radius: root.compactRadius
              }
              onTextChanged: if (text !== root.setupToken) root.setupToken = text
              onAccepted: root.submitSetup()
              Keys.onEscapePressed: if (root.configured) root.cancelSetup()
            }

            Text {
              width: parent.width
              text: "In Home Assistant, open your profile → Security → Long-Lived Access Tokens → Create Token. Copy it immediately, Home Assistant only shows it once, then paste it here."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            AcDropdown {
              id: setupEntityDropdown
              visible: root.setupEntityOptions.length > 0
              width: parent.width
              label: "AIR CONDITIONER"
              options: root.setupDropdownOptions
              value: root.setupSelectedEntity
              foreground: root.foreground
              background: root.appearanceBackgroundColor
              popupBorder: root.appearancePopupBorderColor
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              controlRadius: root.compactRadius
              chromeLess: root.compactChromeEnabled
              onChanged: function(value) { root.setupSelectedEntity = value }
            }

            BorderSurface {
              visible: root.setupError !== ""
              width: parent.width
              implicitHeight: setupMessage.implicitHeight + Style.space(18)
              color: root.surfaceColor(root.alpha(root.setupEntityOptions.length > 0 ? root.accentColor : root.urgent, 0.09))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.setupEntityOptions.length > 0 ? root.accentColor : root.urgent, 0.32), 1))
              radius: root.compactRadius

              Text {
                id: setupMessage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: root.setupError
                color: root.setupEntityOptions.length > 0 ? root.accentColor : root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
            }

            BorderSurface {
              id: onboardingControlsCard
              visible: !root.configured
              width: parent.width
              implicitHeight: onboardingControlsForm.implicitHeight + Style.space(24)
              radius: root.compactRadius
              color: root.surfaceColor(root.alpha(root.accentColor, 0.045))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.22), 1))

              Column {
                id: onboardingControlsForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(8)

                Row {
                  width: parent.width
                  spacing: Style.space(8)

                  Text {
                    width: Style.space(28)
                    height: Style.space(28)
                    text: "󰒓"
                    color: root.accentColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.display
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                  }

                  Column {
                    width: parent.width - Style.space(36)
                    spacing: Style.space(1)

                    Text {
                      width: parent.width
                      text: "CHOOSE YOUR CONTROLS"
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      font.letterSpacing: 0.8
                    }

                    Text {
                      width: parent.width
                      text: "These preferences are saved with your connection and can be changed later."
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }
                  }
                }

                ChromeToggle {
                  width: parent.width
                  label: "Show climate controls"
                  description: "Show mode, fan-speed, and per-AC temperature controls in the panel."
                  checked: root.showClimateControls
                  enabled: !root.setupBusy
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  fontFamily: root.fontFamily
                  chromeLess: root.compactChromeEnabled
                  onClicked: root.showClimateControls = !root.showClimateControls
                }

                ChromeToggle {
                  width: parent.width
                  label: "MasterSwitch"
                  description: "One guarded power button turns every available AC on or off, independently of climate controls."
                  checked: root.masterSwitchEnabled
                  enabled: !root.setupBusy
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  fontFamily: root.fontFamily
                  chromeLess: root.compactChromeEnabled
                  onClicked: root.masterSwitchEnabled = !root.masterSwitchEnabled
                }

                BorderSurface {
                  visible: root.masterSwitchEnabled || height > 0.5
                  width: parent.width
                  implicitHeight: onboardingMasterSwitchWarning.implicitHeight + Style.space(18)
                  height: root.masterSwitchEnabled ? implicitHeight : 0
                  opacity: root.masterSwitchEnabled ? 1 : 0
                  clip: true
                  color: root.surfaceColor(root.alpha(root.urgent, 0.07))
                  borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.25), 1))
                  radius: root.compactRadius

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  Text {
                    id: onboardingMasterSwitchWarning
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Style.space(10)
                    anchors.rightMargin: Style.space(10)
                    text: "Warning: I'm not responsible for wrecking your electricity bill."
                    color: root.urgent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }
                }

              }
            }

            AcButton {
              width: parent.width
              height: Style.space(40)
              text: root.setupActionLabel
              iconText: root.setupBusy ? "" : "→"
              iconSize: Style.font.body
              fontSize: Style.font.bodySmall
              enabled: root.setupCanSubmit
              fontFamily: root.fontFamily
              foreground: root.accentTextColor
              accent: root.accentColor
              background: root.accentColor
              bordered: false
              radius: root.compactRadius
              onClicked: root.submitSetup()

              LoadingRing {
                visible: root.setupBusy
                anchors.left: parent.left
                anchors.leftMargin: Style.space(14)
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(16)
                height: width
                color: root.accentTextColor
                strokeWidth: Style.space(2)
              }
            }

            AcButton {
              width: parent.width
              height: Style.space(40)
              text: "HOME ASSISTANT SETTINGS"
              iconText: "󰏌"
              iconSize: Style.font.body
              fontSize: Style.font.bodySmall
              enabled: !root.setupBusy && !root.localServerBusy
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              tooltipText: "Open the Home Assistant address used by this widget"
              onClicked: root.openHomeAssistantSettings()
            }

            Text {
              width: parent.width
              text: root.configured
                ? "Changing this connection replaces the saved Home Assistant token."
                : "The Daikin AC integration must already be set up in Home Assistant."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }
          }
        }

        BorderSurface {
          id: localServerCard
          visible: !root.configured
          width: parent.width
          implicitHeight: localServerForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))

          Column {
            id: localServerForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(9)

            Row {
              width: parent.width
              spacing: Style.space(9)

              Text {
                width: Style.space(30)
                height: Style.space(30)
                text: "󰒓"
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }

              Column {
                width: parent.width - Style.space(39)
                spacing: Style.space(1)

                Text {
                  width: parent.width
                  text: root.configured ? "RUN HOME ASSISTANT LOCALLY" : "NO SERVER YET?"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Text {
                  width: parent.width
                  text: "Create a self-hosted Home Assistant server on this PC for your Daikin setup."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.WordWrap
                }
              }
            }

            BorderSurface {
              width: parent.width
              implicitHeight: localServerDetails.implicitHeight + Style.space(18)
              color: root.surfaceColor(root.alpha(root.foreground, 0.025))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.11), 1))
              radius: root.compactRadius

              Text {
                id: localServerDetails
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: "This pulls the official Home Assistant Container image, stores its data in ~/.local/share/omarchy/homeassistant by default, and keeps it running through Docker. You still need to finish Home Assistant onboarding, add the Daikin integration, and create a long-lived token."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            Text {
              width: parent.width
              text: "Docker may ask for administrator permission to install or start its service. Host networking helps local AC discovery, so your firewall controls whether other devices can reach Home Assistant."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            BorderSurface {
              visible: root.localServerConfirming || height > 0.5
              width: parent.width
              implicitHeight: localServerConfirmDetails.implicitHeight + Style.space(18)
              height: root.localServerConfirming ? implicitHeight : 0
              opacity: root.localServerConfirming ? 1 : 0
              clip: true
              color: root.surfaceColor(root.alpha(root.accentColor, 0.08))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.30), 1))
              radius: root.compactRadius

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Text {
                id: localServerConfirmDetails
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: "This runs the local setup script. It may install Docker, download Home Assistant, and ask for administrator permission."
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              CriticalActionSplit {
                id: localServerAction
                width: parent.width - localServerGuideButton.width - parent.spacing
                height: Style.space(40)
                idleText: root.localServerReady ? "OPEN HOME ASSISTANT" : "SET UP LOCALLY"
                busyText: "SETTING UP…"
                confirmText: "RUN SETUP"
                idleIcon: root.localServerReady ? "↗" : "󰒓"
                idleTooltip: root.localServerReady
                  ? "Open the local Home Assistant server"
                  : "Prepare the local Home Assistant setup"
                confirmTooltip: "Run the local Home Assistant setup script"
                backTooltip: "Cancel local Home Assistant setup"
                actionColor: root.accentColor
                actionTextColor: root.accentTextColor
                idleBackground: root.alpha(root.accentColor, 0.07)
                backTextColor: root.foreground
                backBackground: root.alpha(root.foreground, 0.025)
                controlRadius: root.compactRadius
                chromeLess: root.compactChromeEnabled
                fontFamily: root.fontFamily
                confirming: root.localServerConfirming
                busy: root.localServerBusy
                actionEnabled: !root.localServerBusy && !root.setupBusy && !root.preferenceBusy
                onActionRequested: root.localServerReady
                  ? root.openLocalServer() : root.requestLocalServerSetup()
                onBackRequested: root.cancelLocalServerSetup()
              }

              AcButton {
                id: localServerGuideButton
                width: Style.space(112)
                height: Style.space(40)
                text: "GUIDE"
                fontSize: Style.font.caption
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: !root.compactChromeEnabled
                radius: root.compactRadius
                tooltipText: root.homeAssistantLinuxGuideUrl
                enabled: !root.localServerBusy && !root.localServerConfirming
                onClicked: Qt.openUrlExternally(root.homeAssistantLinuxGuideUrl)
              }
            }

            BorderSurface {
              readonly property bool hasLocalServerStatus: root.localServerMessage !== ""
                || root.localServerError !== ""
              visible: hasLocalServerStatus || height > 0.5
              width: parent.width
              implicitHeight: localServerStatus.implicitHeight + Style.space(18)
              height: hasLocalServerStatus ? implicitHeight : 0
              opacity: hasLocalServerStatus ? 1 : 0
              clip: true
              color: root.surfaceColor(root.alpha(root.localServerError !== "" ? root.urgent : root.accentColor, 0.09))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.localServerError !== "" ? root.urgent : root.accentColor, 0.32), 1))
              radius: root.compactRadius

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Text {
                id: localServerStatus
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: root.localServerError !== ""
                  ? root.localServerError : root.localServerMessage
                color: root.localServerError !== "" ? root.urgent : root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
            }
          }
        }

        BorderSurface {
          id: advancedSettingsCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "preferences"
          width: parent.width
          implicitHeight: advancedSettingsForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))

          Column {
            id: advancedSettingsForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(9)

            Text {
              width: parent.width
              text: "PREFERENCES"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Optional controls stay hidden until you ask for them. All choices are saved locally."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            ChromeToggle {
              width: parent.width
              label: "Show climate controls"
              description: "Show mode, fan-speed, and per-AC temperature controls in the panel."
              checked: root.showClimateControls
              enabled: !root.setupBusy && !root.preferenceBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setShowClimateControlsEnabled(!root.showClimateControls)
            }

            BorderSurface {
              id: barTemperaturesSettingsCard
              width: parent.width
              implicitHeight: barTemperaturesSettingsForm.implicitHeight + Style.space(20)
              color: root.surfaceColor(root.alpha(root.foreground, 0.018))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.10), 1))
              radius: root.compactRadius

              Column {
                id: barTemperaturesSettingsForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                spacing: Style.space(7)

                Text {
                  width: parent.width
                  text: "BAR TEMPERATURES"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Text {
                  width: parent.width
                  text: "Choose whether the bar shows the ambient temperature, target temperature, or both."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }

                Row {
                  id: temperatureDisplayChoices
                  width: parent.width
                  spacing: Style.space(6)

                  Repeater {
                    model: [
                      { value: "ambient", label: "AMBIENT" },
                      { value: "target", label: "TARGET" },
                      { value: "both", label: "BOTH" },
                    ]

                    AcButton {
                      required property var modelData
                      width: (temperatureDisplayChoices.width
                        - temperatureDisplayChoices.spacing * 2) / 3
                      height: Style.space(34)
                      text: modelData.label
                      fontSize: Style.font.caption
                      horizontalPadding: Style.space(4)
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      selected: root.temperatureDisplay === modelData.value
                      enabled: !root.preferenceBusy
                      radius: root.compactRadius
                      tooltipText: "Show " + modelData.label.toLowerCase() + " temperature in the bar"
                      onClicked: root.setTemperatureDisplay(modelData.value)
                    }
                  }
                }
              }
            }

            BorderSurface {
              id: temperatureUnitSettingsCard
              width: parent.width
              implicitHeight: temperatureUnitSettingsForm.implicitHeight + Style.space(20)
              color: root.surfaceColor(root.alpha(root.foreground, 0.018))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.10), 1))
              radius: root.compactRadius

              Column {
                id: temperatureUnitSettingsForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                spacing: Style.space(7)

                Text {
                  width: parent.width
                  text: "TEMPERATURE UNIT"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Text {
                  width: parent.width
                  text: "Choose the unit shown by the panel and chart. Controls are converted before they are sent to Home Assistant."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }

                Row {
                  id: temperatureUnitChoices
                  readonly property int optionCount: 3
                  width: parent.width
                  spacing: Style.space(6)

                  Repeater {
                    model: [
                      { value: "celsius", label: "CELSIUS" },
                      { value: "fahrenheit", label: "FAHRENHEIT" },
                      { value: "kelvin", label: "KELVIN" },
                    ]

                    AcButton {
                      required property var modelData
                      width: (temperatureUnitChoices.width
                        - temperatureUnitChoices.spacing * (temperatureUnitChoices.optionCount - 1))
                        / temperatureUnitChoices.optionCount
                      height: Style.space(34)
                      text: modelData.label
                      fontSize: Style.font.caption
                      horizontalPadding: Style.space(3)
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      selected: root.displayTemperatureUnitCode === modelData.value
                      enabled: !root.preferenceBusy
                      radius: root.compactRadius
                      tooltipText: "Show temperatures in " + modelData.label.toLowerCase()
                      onClicked: root.setTemperatureUnit(modelData.value)
                    }
                  }
                }
              }
            }

            BorderSurface {
              id: historySettingsGroup
              width: parent.width
              implicitHeight: historySettingsGroupForm.implicitHeight + Style.space(20)
              color: root.surfaceColor(root.alpha(root.foreground, 0.018))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.10), 1))
              radius: root.compactRadius

              Column {
                id: historySettingsGroupForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                spacing: Style.space(7)

                Text {
                  width: parent.width
                  text: "AMBIENT TEMPERATURE CHART"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                ChromeToggle {
                  width: parent.width
                  label: "Ambient temperature chart"
                  description: "Show the recorded ambient temperature history in the main panel."
                  checked: root.historyEnabled
                  enabled: !root.setupBusy && !root.preferenceBusy
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  fontFamily: root.fontFamily
                  chromeLess: root.compactChromeEnabled
                  onClicked: root.setHistoryEnabled(!root.historyEnabled)
                }

                BorderSurface {
                  id: historySourceSettingsCard
                  width: parent.width
                  implicitHeight: historySourceSettingsForm.implicitHeight + Style.space(20)
                  color: root.surfaceColor(root.alpha(root.foreground, 0.012))
                  borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.06), 1))
                  radius: root.compactRadius

                  Column {
                    id: historySourceSettingsForm
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Style.space(10)
                    spacing: Style.space(7)

                    Text {
                      width: parent.width
                      text: "HISTORY SOURCE"
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      font.letterSpacing: 0.8
                    }

                    Text {
                      width: parent.width
                      text: "Choose where the ambient chart is recorded."
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }

                    Row {
                      id: historySourceChoices
                      width: parent.width
                      spacing: Style.space(6)

                      AcButton {
                        width: (parent.width - parent.spacing) / 2
                        height: Style.space(34)
                        text: "LOCAL"
                        fontSize: Style.font.caption
                        horizontalPadding: Style.space(4)
                        foreground: root.foreground
                        accent: root.accentColor
                        background: root.alpha(root.foreground, 0.025)
                        bordered: !root.compactChromeEnabled
                        selected: root.historySource === "local"
                        enabled: !root.preferenceBusy
                        radius: root.compactRadius
                        tooltipText: "Log on this PC while it is on"
                        onClicked: root.setHistorySource("local")
                      }

                      AcButton {
                        width: (parent.width - parent.spacing) / 2
                        height: Style.space(34)
                        text: "EXTERNAL SERVER"
                        fontSize: Style.font.caption
                        horizontalPadding: Style.space(4)
                        foreground: root.foreground
                        accent: root.accentColor
                        background: root.alpha(root.foreground, 0.025)
                        bordered: !root.compactChromeEnabled
                        selected: root.historySource === "server"
                        enabled: !root.preferenceBusy
                        radius: root.compactRadius
                        tooltipText: "Log on the same external host that runs Home Assistant"
                        onClicked: root.setHistorySource("server")
                      }
                    }

                    Column {
              id: remoteHistorySection
              visible: root.historySource === "server" || height > 0.5
              width: parent.width
              height: root.historySource === "server" ? implicitHeight : 0
              opacity: root.historySource === "server" ? 1 : 0
              clip: true
              spacing: Style.space(7)

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              BorderSurface {
                id: remoteHistoryCard
                width: parent.width
                implicitHeight: (root.remoteHistoryConfigured && !root.remoteHistoryReconfiguring
                  ? remoteHistoryPairedSummary.implicitHeight : remoteHistoryForm.implicitHeight)
                  + Style.space(24)
                radius: root.compactRadius
                color: root.surfaceColor(root.alpha(root.accentColor, 0.045))
                borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.24), 1))

                Behavior on implicitHeight {
                  NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                }

                Column {
                  id: remoteHistoryPairedSummary
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.space(12)
                  spacing: Style.space(7)
                  visible: root.remoteHistoryConfigured && !root.remoteHistoryReconfiguring
                  height: visible ? implicitHeight : 0
                  opacity: visible ? 1 : 0
                  clip: true

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  Row {
                    width: parent.width
                    spacing: Style.space(8)

                    Text {
                      width: Style.space(28)
                      height: Style.space(28)
                      text: "󰒓"
                      color: root.accentColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.display
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }

                    Column {
                      width: parent.width - Style.space(36)
                      spacing: Style.space(1)

                      Text {
                        width: parent.width
                        text: "EXTERNAL SERVER"
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 0.8
                      }

                      Row {
                        width: parent.width
                        spacing: Style.space(8)

                        Text {
                          text: root.remoteHistoryStatusText
                          color: root.remoteHistoryStatusColor
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                          font.letterSpacing: 0.8
                        }

                        Text {
                          text: "·"
                          color: root.dim
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                          verticalAlignment: Text.AlignVCenter
                        }

                        ServerStatus {
                          id: externalHistoryConnectionStatus
                          visible: root.remoteHistoryConnected
                          connected: true
                          pingMs: root.remoteHistoryPingMs
                          hideConnectedDot: true
                          metricDotBeforeValue: true
                          statusSpacing: Style.space(8)
                          foreground: root.foreground
                          warningColor: root.warning
                          urgentColor: root.urgent
                          metricLabel: "SSH READ"
                          fontFamily: root.fontFamily
                        }
                      }
                    }
                  }

                  BorderSurface {
                    width: parent.width
                    implicitHeight: remoteHistoryPairedTarget.implicitHeight + Style.space(16)
                    color: root.surfaceColor(root.alpha(root.accentColor, 0.07))
                    borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.24), 1))
                    radius: root.compactRadius

                    Text {
                      id: remoteHistoryPairedTarget
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: Style.space(10)
                      anchors.rightMargin: Style.space(10)
                      text: root.remoteHistoryTarget + ":" + root.remoteHistoryPortText
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      elide: Text.ElideRight
                    }
                  }

                  AcButton {
                    width: parent.width
                    height: Style.space(36)
                    text: "RECONNECT / CHANGE"
                    fontSize: Style.font.caption
                    fontFamily: root.fontFamily
                    foreground: root.foreground
                    accent: root.accentColor
                    background: root.alpha(root.foreground, 0.025)
                    bordered: !root.compactChromeEnabled
                    radius: root.compactRadius
                    enabled: !root.remoteHistoryBusy && !root.preferenceBusy
                    tooltipText: "Edit the external server connection"
                    onClicked: {
                      root.beginRemoteHistoryReconfigure()
                    }
                  }
                }

                Column {
                  id: remoteHistoryForm
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  anchors.margins: Style.space(12)
                  spacing: Style.space(7)
                  visible: !root.remoteHistoryConfigured || root.remoteHistoryReconfiguring
                  height: visible ? implicitHeight : 0
                  opacity: visible ? 1 : 0
                  clip: true

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  Row {
                    width: parent.width
                    spacing: Style.space(8)

                    Text {
                      width: Style.space(28)
                      height: Style.space(28)
                      text: "󰒓"
                      color: root.accentColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.display
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }

                    Column {
                      width: parent.width - Style.space(36)
                      spacing: Style.space(1)

                      Text {
                        width: parent.width
                        text: "EXTERNAL SERVER"
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 0.8
                      }

                      Text {
                        width: parent.width
                        text: "The external server must be the same host that runs Home Assistant. It records there while this PC sleeps, shuts down, or restarts."
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        wrapMode: Text.WordWrap
                      }
                    }
                  }

                  BorderSurface {
                    width: parent.width
                    implicitHeight: remoteHistorySafetyText.implicitHeight + Style.space(18)
                    color: root.surfaceColor(root.alpha(root.foreground, 0.025))
                    borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.12), 1))
                    radius: root.compactRadius

                    Text {
                      id: remoteHistorySafetyText
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: Style.space(10)
                      anchors.rightMargin: Style.space(10)
                      text: "SAFE BY DESIGN · Reviewable source files only. No sudo, package installs, open ports, telemetry, or Home Assistant control calls. One user timer reads every available climate state and writes one owner-only 31-day file on the external host."
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }
                  }

                  Row {
                    id: remoteHistoryTargetRow
                    width: parent.width
                    spacing: Style.space(8)

                    Column {
                      width: parent.width - remoteHistoryPortColumn.width - parent.spacing
                      spacing: Style.space(3)

                      Text {
                        width: parent.width
                        text: "SSH SERVER ADDRESS"
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 0.8
                      }

                      TextField {
                        id: remoteHistoryTargetField
                        width: parent.width
                        height: Style.space(38)
                        text: root.remoteHistoryTarget
                        placeholderText: "user@server-ip"
                        enabled: !root.remoteHistoryBusy
                        foreground: root.foreground
                        accent: root.controlAccentColor
                        font.family: root.fontFamily
                        selectByMouse: true
                        background: BorderSurface {
                          color: root.controlSurfaceColor(remoteHistoryTargetField)
                          borderSpec: root.controlSurfaceBorder(remoteHistoryTargetField)
                          radius: root.compactRadius
                        }
                        onTextChanged: if (text !== root.remoteHistoryTarget)
                          root.remoteHistoryTarget = text
                      }
                    }

                    Column {
                      id: remoteHistoryPortColumn
                      width: Style.space(74)
                      spacing: Style.space(3)

                      Text {
                        width: parent.width
                        text: "SSH PORT"
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 0.8
                      }

                      TextField {
                        id: remoteHistoryPortField
                        width: parent.width
                        height: Style.space(38)
                        text: root.remoteHistoryPortText
                        placeholderText: "22"
                        enabled: !root.remoteHistoryBusy
                        foreground: root.foreground
                        accent: root.controlAccentColor
                        font.family: root.fontFamily
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        selectByMouse: true
                        background: BorderSurface {
                          color: root.controlSurfaceColor(remoteHistoryPortField)
                          borderSpec: root.controlSurfaceBorder(remoteHistoryPortField)
                          radius: root.compactRadius
                        }
                        onTextChanged: if (text !== root.remoteHistoryPortText)
                          root.remoteHistoryPortText = text
                      }
                    }
                  }

                  Text {
                    width: parent.width
                    text: "HOME ASSISTANT URL ON EXTERNAL SERVER"
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    font.letterSpacing: 0.8
                  }

                  TextField {
                    id: remoteHistoryUrlField
                    width: parent.width
                    height: Style.space(38)
                    text: root.remoteHistoryUrl
                    placeholderText: root.remoteHistoryDefaultUrl
                    enabled: !root.remoteHistoryBusy
                    foreground: root.foreground
                    accent: root.controlAccentColor
                    font.family: root.fontFamily
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    selectByMouse: true
                    background: BorderSurface {
                      color: root.controlSurfaceColor(remoteHistoryUrlField)
                      borderSpec: root.controlSurfaceBorder(remoteHistoryUrlField)
                      radius: root.compactRadius
                    }
                    onTextChanged: if (text !== root.remoteHistoryUrl)
                      root.remoteHistoryUrl = text
                  }

                  Text {
                    width: parent.width
                    text: "Use the URL reachable from that same external host, usually http://127.0.0.1:8123. CONNECT TO SERVER only verifies SSH and saves this pairing. INSTALL / UPDATE TIMER is only for first-time setup or when the remote logger needs changing."
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }

                  Column {
                    id: remoteHistoryActionColumn
                    width: parent.width
                    spacing: Style.space(6)

                    AcButton {
                      id: remoteHistoryConnectButton
                      width: parent.width
                      height: Style.space(44)
                      text: root.remoteHistoryBusy && root.remoteHistoryAction === "connect"
                        ? "CONNECTING…" : "CONNECT TO SERVER"
                      iconText: root.remoteHistoryBusy ? "" : "󰒓"
                      iconSize: Style.font.body
                      fontSize: Style.font.bodySmall
                      fontFamily: root.fontFamily
                      foreground: root.accentTextColor
                      accent: root.accentColor
                      background: root.accentColor
                      bordered: false
                      radius: root.compactRadius
                      enabled: !root.remoteHistoryBusy
                        && !root.remoteHistorySourceBusy && !root.preferenceBusy
                      tooltipText: "Verify the SSH address and pair with an existing external history server"
                      onClicked: root.startRemoteHistoryConnect()

                      LoadingRing {
                        visible: root.remoteHistoryBusy && root.remoteHistoryAction === "connect"
                        anchors.left: parent.left
                        anchors.leftMargin: Style.space(12)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Style.space(16)
                        height: width
                        color: root.accentTextColor
                        strokeWidth: Style.space(2)
                      }
                    }

                    AcButton {
                      id: remoteHistoryInstallButton
                      width: parent.width
                      height: Style.space(44)
                      text: root.remoteHistoryBusy && root.remoteHistoryAction === "install"
                        ? "INSTALLING…" : "INSTALL / UPDATE TIMER"
                      iconText: root.remoteHistoryBusy ? "" : "󰒓"
                      iconSize: Style.font.body
                      fontSize: Style.font.bodySmall
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.06)
                      bordered: !root.compactChromeEnabled
                      radius: root.compactRadius
                      enabled: !root.remoteHistoryBusy
                        && !root.remoteHistorySourceBusy && !root.preferenceBusy
                      tooltipText: "Copy the reviewed files and install or update the user timer over SSH"
                      onClicked: root.startRemoteHistoryInstall()

                      LoadingRing {
                        visible: root.remoteHistoryBusy && root.remoteHistoryAction === "install"
                        anchors.left: parent.left
                        anchors.leftMargin: Style.space(12)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Style.space(16)
                        height: width
                        color: root.foreground
                        strokeWidth: Style.space(2)
                      }
                    }

                    AcButton {
                      id: remoteHistoryCancelButton
                      visible: root.remoteHistoryConfigured && root.remoteHistoryReconfiguring
                      width: parent.width
                      height: visible ? Style.space(40) : 0
                      text: "CANCEL"
                      fontSize: Style.font.caption
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      radius: root.compactRadius
                      enabled: !root.remoteHistoryBusy && !root.preferenceBusy
                      tooltipText: "Keep the current external-server pairing"
                      onClicked: root.cancelRemoteHistoryReconfigure()
                    }
                  }

                  Row {
                    id: remoteHistoryLinkRow
                    width: parent.width
                    spacing: Style.space(6)

                    AcButton {
                      width: parent.width
                      height: Style.space(38)
                      text: "GUIDE"
                      iconText: "󰏌"
                      iconSize: Style.font.body
                      fontSize: Style.font.caption
                      horizontalPadding: Style.space(3)
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      radius: root.compactRadius
                      tooltipText: "Open the external-server setup guide on GitHub"
                      enabled: !root.remoteHistoryBusy && !root.remoteHistorySourceBusy
                      onClicked: root.openExternalHistoryGuide()
                    }
                  }

                  Row {
                    id: remoteHistoryCopyRow
                    width: parent.width
                    spacing: Style.space(6)

                    AcButton {
                      width: parent.width
                      height: Style.space(38)
                      text: root.remoteHistorySourceBusy ? "PREPARING…" : "COPY SOURCE"
                      fontSize: Style.font.caption
                      horizontalPadding: Style.space(3)
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      radius: root.compactRadius
                      tooltipText: "Copy all reviewable external-server and uninstall source files"
                      enabled: !root.remoteHistoryBusy && !root.remoteHistorySourceBusy
                      onClicked: root.copyRemoteHistorySource()
                    }
                  }

                  BorderSurface {
                    visible: root.remoteHistoryMessage !== "" || root.remoteHistoryError !== ""
                    width: parent.width
                    implicitHeight: remoteHistoryStatus.implicitHeight + Style.space(16)
                    color: root.surfaceColor(root.alpha(root.remoteHistoryError !== "" ? root.urgent : root.accentColor, 0.08))
                    borderSpec: root.surfaceBorder(Border.flat(root.alpha(
                      root.remoteHistoryError !== "" ? root.urgent : root.accentColor, 0.28), 1))
                    radius: root.compactRadius

                    Text {
                      id: remoteHistoryStatus
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: Style.space(10)
                      anchors.rightMargin: Style.space(10)
                      text: root.remoteHistoryError !== ""
                        ? root.remoteHistoryError : root.remoteHistoryMessage
                      color: root.remoteHistoryError !== "" ? root.urgent : root.accentColor
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }
                  }
                }
              }
            }

                  }
                }

            BorderSurface {
              id: historyRangeSettingsCard
              readonly property bool historyVisible: root.historyEnabled
              visible: historyVisible || height > 0.5
              width: parent.width
              implicitHeight: historyRangeSettingsForm.implicitHeight + Style.space(20)
              height: historyVisible ? implicitHeight : 0
              opacity: historyVisible ? 1 : 0
              clip: true
              color: root.surfaceColor(root.alpha(root.foreground, 0.012))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.06), 1))
              radius: root.compactRadius

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Column {
                id: historyRangeSettingsForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                spacing: Style.space(7)

                Text {
                  width: parent.width
                  text: "CHART RANGE"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Text {
                  width: parent.width
                  text: "READINGS FROM THE LAST "
                    + root.formatHistoryDuration(root.historyHours)
                  color: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.35
                  wrapMode: Text.WordWrap
                }

                Row {
                  id: historyRangeChoices
                  width: parent.width
                  spacing: Style.space(5)

                Repeater {
                  model: root.historyRangeOptions

                  AcButton {
                    required property var modelData
                    width: (historyRangeChoices.width
                      - historyRangeChoices.spacing * (root.historyRangeOptions.length - 1))
                      / root.historyRangeOptions.length
                    height: Style.space(34)
                    text: modelData.label
                    fontSize: Style.font.caption
                    horizontalPadding: Style.space(2)
                    foreground: root.foreground
                    accent: root.accentColor
                    background: root.alpha(root.foreground, 0.025)
                    bordered: !root.compactChromeEnabled
                    selected: modelData.value === "custom"
                      ? root.historyCustom
                      : !root.historyCustom && root.historyHours === Number(modelData.value)
                    enabled: !root.preferenceBusy
                    radius: root.compactRadius
                    tooltipText: modelData.value === "custom"
                      ? "Use a custom chart range from 1 to " + root.historyMaximumHours() + " hours"
                      : "Show the last " + modelData.label.toLowerCase()
                    onClicked: root.chooseHistoryRange(modelData.value)
                  }
                }
              }

              Row {
                visible: root.experimentalHistoryEnabled && (root.historyCustom || height > 0.5)
                width: parent.width
                height: root.experimentalHistoryEnabled && root.historyCustom ? implicitHeight : 0
                opacity: root.experimentalHistoryEnabled && root.historyCustom ? 1 : 0
                clip: true
                spacing: Style.space(8)

                Behavior on height {
                  NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                  NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                }

                TextField {
                  id: customHistoryHoursField
                  width: parent.width - applyCustomHistoryButton.width - parent.spacing
                  height: Style.space(38)
                  text: root.customHistoryHoursText
                  placeholderText: "Hours (1–" + root.historyMaximumHours() + ")"
                  enabled: !root.preferenceBusy
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  font.family: root.fontFamily
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
                  background: BorderSurface {
                    color: root.controlSurfaceColor(customHistoryHoursField)
                    borderSpec: root.controlSurfaceBorder(customHistoryHoursField)
                    radius: root.compactRadius
                  }
                  onTextChanged: if (text !== root.customHistoryHoursText)
                    root.customHistoryHoursText = text
                  onAccepted: root.applyCustomHistoryRange()
                }

                AcButton {
                  id: applyCustomHistoryButton
                  width: Style.space(76)
                  height: Style.space(38)
                  text: "APPLY"
                  fontSize: Style.font.caption
                  enabled: !root.preferenceBusy
                  foreground: root.accentTextColor
                  accent: root.accentColor
                  background: root.accentColor
                  bordered: false
                  radius: root.compactRadius
                  onClicked: root.applyCustomHistoryRange()
                }
              }

                Text {
                  readonly property bool showHistoryDescription: root.historySource === "local"
                    || root.experimentalHistoryEnabled
                  visible: showHistoryDescription || height > 0.5
                  width: parent.width
                  height: showHistoryDescription ? implicitHeight : 0
                  opacity: showHistoryDescription ? 1 : 0
                  clip: true
                  text: root.experimentalHistoryEnabled
                    ? "The chart shows the selected period ending now. Extended history adds 7-day, 30-day, and custom ranges."
                    : "The chart shows the selected hours ending now. Local logging pauses while this PC sleeps or is off. Enable Extended chart history for longer ranges."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }
                }
              }
            }
          }
        }
        }
        }

        BorderSurface {
          id: experimentalCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "experimental"
          width: parent.width
          implicitHeight: experimentalForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))

          Column {
            id: experimentalForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(9)

            Text {
              width: parent.width
              text: "EXPERIMENTAL"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Optional features for multi-aircon panels, longer history, and custom styling."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            BorderSurface {
              width: parent.width
              implicitHeight: experimentalWarning.implicitHeight + Style.space(18)
              color: root.surfaceColor(root.alpha(root.urgent, 0.07))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.25), 1))
              radius: root.compactRadius

              Text {
                id: experimentalWarning
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: "EXPERIMENTAL · Optional extras; some details may be less polished."
                color: root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            ChromeToggle {
              visible: !root.configFileModeEnabled
              width: parent.width
              label: "Config file mode"
              description: "Use the keyboard-first JSON editor above the settings panes. The Home Assistant token stays protected."
              checked: root.configFileModeEnabled
              enabled: !root.preferenceBusy && !root.configFileBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setConfigFileModeEnabled(!root.configFileModeEnabled)
            }

            ChromeToggle {
              width: parent.width
              label: "Global Tab navigation"
              description: "Keep Tab and Shift+Tab inside this panel and move through its controls instead of switching panels."
              checked: root.globalTabNavigationEnabled
              enabled: !root.preferenceBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setGlobalTabNavigationEnabled(!root.globalTabNavigationEnabled)
            }

            ChromeToggle {
              width: parent.width
              label: "MasterSwitch"
              description: "One guarded power button turns every available AC on or off, independently of climate controls."
              checked: root.masterSwitchEnabled
              enabled: !root.preferenceBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setMasterSwitchEnabled(!root.masterSwitchEnabled)
            }

            BorderSurface {
              visible: root.masterSwitchEnabled || height > 0.5
              width: parent.width
              implicitHeight: masterSwitchWarning.implicitHeight + Style.space(18)
              height: root.masterSwitchEnabled ? implicitHeight : 0
              opacity: root.masterSwitchEnabled ? 1 : 0
              clip: true
              color: root.surfaceColor(root.alpha(root.urgent, 0.07))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.25), 1))
              radius: root.compactRadius

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Text {
                id: masterSwitchWarning
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: "Warning: I'm not responsible for wrecking your electricity bill."
                color: root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            ChromeToggle {
              width: parent.width
              label: "Multi-aircon panel"
              description: "Add several Home Assistant climate entities below the panel selector."
              checked: root.multiUnitEnabled
              enabled: !root.preferenceBusy && root.selectedEntities.length > 0
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setMultiUnitEnabled(!root.multiUnitEnabled)
            }

            BorderSurface {
              id: multiAirconOptionsCard
              visible: root.multiUnitEnabled || height > 0.5
              width: parent.width
              implicitHeight: multiAirconOptions.implicitHeight + Style.space(20)
              height: root.multiUnitEnabled ? implicitHeight : 0
              opacity: root.multiUnitEnabled ? 1 : 0
              clip: true
              color: root.surfaceColor(root.alpha(root.accentColor, 0.025))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.18), 1))
              radius: root.compactRadius

              Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

              Column {
                id: multiAirconOptions
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                height: root.multiUnitEnabled ? implicitHeight : 0
                opacity: root.multiUnitEnabled ? 1 : 0
                clip: true
                spacing: Style.space(7)

                Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

                ChromeToggle {
                  width: parent.width
                  label: "Globally synced controls"
                  description: "Use one remote for every selected air conditioner, including power."
                  checked: root.globalSyncControls
                  enabled: !root.preferenceBusy && root.selectedEntities.length > 1
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  fontFamily: root.fontFamily
                  chromeLess: root.compactChromeEnabled
                  borderSpec: Border.none()
                  onClicked: root.setGlobalSyncControls(!root.globalSyncControls)
                }

                Column {
                  visible: (!root.globalSyncControls && root.selectedEntities.length > 1) || height > 0.5
                  width: parent.width
                  height: !root.globalSyncControls && root.selectedEntities.length > 1
                    ? implicitHeight : 0
                  opacity: !root.globalSyncControls && root.selectedEntities.length > 1 ? 1 : 0
                  clip: true
                  spacing: Style.space(5)

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  ChromeToggle {
                    width: parent.width
                    label: "Sync non-power controls"
                    description: "Recommended · sync temperature, mode, and fan while each AC keeps its own power button."
                    checked: root.syncNonPowerControls
                    enabled: !root.preferenceBusy
                    foreground: root.foreground
                    accent: root.controlAccentColor
                    fontFamily: root.fontFamily
                    chromeLess: root.compactChromeEnabled
                    borderSpec: Border.none()
                    onClicked: root.setSyncNonPowerControls(!root.syncNonPowerControls)
                  }
                }

                Text {
                  width: parent.width
                  text: root.selectedEntities.length > 1
                    ? (root.globalSyncControls
                      ? "The main remote controls all selected ACs together."
                      : root.syncNonPowerControls
                        ? "Temperature, mode, and fan stay synced; each AC gets its own power button."
                        : "The main panel will show one compact remote per selected AC.")
                    : "Add another air conditioner from the main panel to unlock sync choices."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }

                Text {
                  width: parent.width
                  text: "BAR AMBIENT TEMPERATURE"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Text {
                  width: parent.width
                  text: "Choose the summary shown in the Omarchy bar."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }

                Row {
                  id: barTemperatureChoices
                  width: parent.width
                  spacing: Style.space(5)

                  Repeater {
                    model: [
                      { value: "average", label: "AVG" },
                      { value: "all", label: "ALL" },
                      { value: "selected", label: "SELECT" },
                    ]

                    AcButton {
                      required property var modelData
                      width: (barTemperatureChoices.width
                        - barTemperatureChoices.spacing * 2) / 3
                      height: Style.space(32)
                      text: modelData.label
                      fontSize: Style.font.caption
                      horizontalPadding: Style.space(2)
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      selected: root.barTemperatureMode === modelData.value
                      enabled: !root.preferenceBusy
                      radius: root.compactRadius
                      tooltipText: modelData.value === "average"
                        ? "Average the selected ambient temperatures"
                        : modelData.value === "all" ? "Show all selected ambient temperatures"
                        : "Choose which selected ambient temperatures appear"
                      onClicked: root.setBarTemperatureMode(modelData.value)
                    }
                  }
                }

                Column {
                  visible: root.barTemperatureMode === "selected"
                  width: parent.width
                  spacing: Style.space(5)

                  Repeater {
                    model: root.selectedEntities

                    AcButton {
                      required property var modelData
                      width: parent.width
                      height: Style.space(32)
                      text: (root.barTemperatureEntities.indexOf(String(modelData)) >= 0 ? "✓  " : "○  ")
                        + root.entityDisplayName(modelData)
                      fontSize: Style.font.caption
                      leftAlign: true
                      horizontalPadding: Style.space(10)
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.accentColor,
                        root.barTemperatureEntities.indexOf(String(modelData)) >= 0 ? 0.10 : 0.025)
                      bordered: !root.compactChromeEnabled
                      selected: root.barTemperatureEntities.indexOf(String(modelData)) >= 0
                      enabled: !root.preferenceBusy
                      radius: root.compactRadius
                      onClicked: root.toggleBarTemperatureEntity(String(modelData))
                    }
                  }
                }

                ChromeToggle {
                  width: parent.width
                  label: "Decimal average"
                  description: "Show one decimal when averaging multiple AC temperatures."
                  checked: root.averageTemperatureDecimals
                  enabled: !root.preferenceBusy && root.selectedEntities.length > 1
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  fontFamily: root.fontFamily
                  chromeLess: root.compactChromeEnabled
                  borderSpec: Border.none()
                  onClicked: root.setAverageTemperatureDecimals(!root.averageTemperatureDecimals)
                }
              }
            }

            ChromeToggle {
              width: parent.width
              label: "Extended chart history"
              description: "Unlock 7-day, 30-day, and custom ranges. An always-on external logger is recommended for long recordings."
              checked: root.experimentalHistoryEnabled
              enabled: !root.preferenceBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setExperimentalHistoryEnabled(!root.experimentalHistoryEnabled)
            }

            BorderSurface {
              visible: root.experimentalHistoryEnabled
              width: parent.width
              implicitHeight: extendedHistoryNotice.implicitHeight + Style.space(18)
              color: root.surfaceColor(root.alpha(root.accentColor, 0.06))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.22), 1))
              radius: root.compactRadius

              Text {
                id: extendedHistoryNotice
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: "Includes 7-day, 30-day, and custom ranges up to 744 hours. For long recordings, an always-on external logger on the Home Assistant host is recommended. It discovers available climate entities automatically."
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            AcButton {
              visible: root.experimentalHistoryEnabled
              width: parent.width
              height: Style.space(34)
              text: "EXTERNAL SERVER SETTINGS"
              iconText: "󰏌"
              iconSize: Style.font.body
              fontSize: Style.font.caption
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              tooltipText: "Open Preferences and configure the external Home Assistant host"
              enabled: !root.preferenceBusy
              onClicked: root.settingsSection = "preferences"
            }

            ChromeToggle {
              id: shortcutsToggle
              width: parent.width
              label: "Keyboard shortcuts"
              description: "Enable global controls for the panel, AC power, settings navigation, and refresh. Edit them in Shortcuts."
              checked: root.shortcutsEnabled
              enabled: !root.preferenceBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setShortcutsEnabled(!root.shortcutsEnabled)
            }

            AcButton {
              visible: root.shortcutsEnabled
              width: parent.width
              height: Style.space(34)
              text: "OPEN SHORTCUTS"
              iconText: "→"
              iconSize: Style.font.body
              fontSize: Style.font.caption
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              enabled: !root.preferenceBusy
              tooltipText: "Open the keyboard shortcut editor"
              onClicked: root.settingsSection = "shortcuts"
            }

            ChromeToggle {
              width: parent.width
              label: "Extra customisations"
              description: "Enable a dedicated Customisation section for colours and surface finish."
              checked: root.customAppearanceEnabled
              enabled: !root.preferenceBusy
              foreground: root.foreground
              accent: root.controlAccentColor
              fontFamily: root.fontFamily
              chromeLess: root.compactChromeEnabled
              onClicked: root.setCustomAppearanceEnabled(!root.customAppearanceEnabled)
            }

            AcButton {
              visible: root.customAppearanceEnabled
              width: parent.width
              height: Style.space(34)
              text: "OPEN CUSTOMISATION"
              iconText: "→"
              iconSize: Style.font.body
              fontSize: Style.font.caption
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              enabled: !root.preferenceBusy
              tooltipText: "Open the customisation editor"
              onClicked: root.settingsSection = "customisation"
            }

            Component {
              id: appearanceOptionsComponent

              Column {
                id: appearanceOptions
              visible: root.customAppearanceEnabled || height > 0.5
              width: parent.width
              height: root.customAppearanceEnabled ? implicitHeight : 0
              opacity: root.customAppearanceEnabled ? 1 : 0
              clip: true
              spacing: root.compactChromeEnabled ? Style.space(5) : Style.space(7)

              Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

              ChromeToggle {
                width: parent.width
                label: "Compact UI · flatten inner cards"
                description: "Use a flatter, tighter layout while keeping the popup outline visible."
                checked: root.compactUiEnabled
                enabled: !root.preferenceBusy
                foreground: root.foreground
                accent: root.controlAccentColor
                fontFamily: root.fontFamily
                chromeLess: root.compactChromeEnabled
                compact: root.compactChromeEnabled
                onClicked: root.setCompactUiEnabled(!root.compactUiEnabled)
              }

              ChromeToggle {
                width: parent.width
                label: "Outer panel border"
                description: "Show the accent outline around the popup. Turn this off to remove that outline."
                checked: root.appearanceOuterBorderEnabled
                enabled: !root.preferenceBusy
                foreground: root.foreground
                accent: root.controlAccentColor
                fontFamily: root.fontFamily
                chromeLess: root.compactChromeEnabled
                compact: root.compactChromeEnabled
                onClicked: root.setAppearanceOuterBorderEnabled(
                  !root.appearanceOuterBorderEnabled)
              }

              ChromeToggle {
                width: parent.width
                label: "Auto · Omarchy background"
                description: "Follow Omarchy's current popup background. Turn this off to choose a fixed panel colour."
                checked: root.appearanceAutoBackground
                enabled: !root.preferenceBusy
                foreground: root.foreground
                accent: root.controlAccentColor
                fontFamily: root.fontFamily
                chromeLess: root.compactChromeEnabled
                compact: root.compactChromeEnabled
                onClicked: root.setAppearanceAutoBackground(!root.appearanceAutoBackground)
              }

              AppearanceColorRow {
                id: appearanceBackgroundRow
                visible: !root.appearanceAutoBackground
                width: parent.width
                label: "PANEL BACKGROUND"
                valueColor: root.customBackgroundColor
                valueText: root.customBackgroundHexText
                swatches: root.appearanceBackgroundPalette
                foreground: root.foreground
                accent: root.accentColor
                accentTextColor: root.accentTextColor
                fontFamily: root.fontFamily
                enabled: !root.preferenceBusy
                chromeLess: root.compactChromeEnabled
                compact: root.compactChromeEnabled
                onSubmitted: function(value) {
                  root.setAppearanceColor("appearance_background", value)
                }
              }

              ChromeToggle {
                width: parent.width
                label: "Auto · Omarchy accent"
                description: "Follow Omarchy's current accent. Turn this off to choose a fixed colour."
                checked: root.appearanceAutoAccent
                enabled: !root.preferenceBusy
                foreground: root.foreground
                accent: root.controlAccentColor
                fontFamily: root.fontFamily
                chromeLess: root.compactChromeEnabled
                onClicked: root.setAppearanceAutoAccent(!root.appearanceAutoAccent)
              }

              AppearanceColorRow {
                id: appearanceAccentRow
                visible: !root.appearanceAutoAccent
                width: parent.width
                label: "ACCENT COLOUR"
                valueColor: root.customAccentColor
                valueText: root.customAccentHexText
                swatches: ["#8FA79F", "#8EA7C7", "#C89AAB", "#D0A66A", "#A99BC7"]
                foreground: root.foreground
                accent: root.accentColor
                accentTextColor: root.accentTextColor
                fontFamily: root.fontFamily
                enabled: !root.preferenceBusy
                chromeLess: root.compactChromeEnabled
                compact: root.compactChromeEnabled
                onSubmitted: function(value) {
                  root.setAppearanceColor("appearance_accent", value)
                }
              }

              AppearanceColorRow {
                id: appearanceControlRow
                visible: !root.appearanceAutoAccent
                width: parent.width
                label: "SWITCH & SLIDER COLOUR"
                valueColor: root.customControlColor
                valueText: root.customControlHexText
                swatches: ["#8FA79F", "#8EA7C7", "#C89AAB", "#D0A66A", "#A99BC7"]
                foreground: root.foreground
                accent: root.accentColor
                accentTextColor: root.accentTextColor
                fontFamily: root.fontFamily
                enabled: !root.preferenceBusy
                chromeLess: root.compactChromeEnabled
                compact: root.compactChromeEnabled
                onSubmitted: function(value) {
                  root.setAppearanceColor("appearance_control", value)
                }
              }

              ChromeToggle {
                width: parent.width
                label: "Per-device colours"
                description: root.appearanceAutoAccent
                  ? "Turn off Auto · Omarchy accent to assign colours to individual AC cards."
                  : "Give each selected AC its own accent on the panel."
                checked: root.appearanceDeviceColorsEnabled
                enabled: !root.preferenceBusy && !root.appearanceAutoAccent
                  && root.selectedEntities.length > 0
                foreground: root.foreground
                accent: root.interactionAccentColor
                fontFamily: root.fontFamily
                chromeLess: root.compactChromeEnabled
                onClicked: root.setAppearanceDeviceColorsEnabled(
                  !root.appearanceDeviceColorsEnabled)
              }

              Column {
                id: appearanceDeviceColorOptions
                visible: root.deviceColorsActive || height > 0.5
                width: parent.width
                height: root.deviceColorsActive ? implicitHeight : 0
                opacity: root.deviceColorsActive ? 1 : 0
                clip: true
                spacing: Style.space(6)

                Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

                Text {
                  width: parent.width
                  text: "AC CARD COLOURS"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Repeater {
                  model: root.selectedEntities

                  AppearanceColorRow {
                    required property var modelData
                    width: appearanceDeviceColorOptions.width
                    label: root.entityDisplayName(modelData)
                    valueColor: root.appearanceDeviceColor(modelData)
                    valueText: root.appearanceDeviceColorText(modelData)
                    swatches: root.appearanceDevicePalette
                    foreground: root.foreground
                    accent: root.accentColor
                    accentTextColor: root.accentTextColor
                    fontFamily: root.fontFamily
                    enabled: !root.preferenceBusy
                    chromeLess: root.compactChromeEnabled
                    compact: root.compactChromeEnabled
                    onSubmitted: function(value) {
                      root.setAppearanceDeviceColor(String(modelData), value)
                    }
                  }
                }
              }

              Row {
                width: parent.width
                spacing: Style.space(7)

                Text {
                  width: Style.space(92)
                  height: Style.space(28)
                  text: "TRANSPARENCY"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  verticalAlignment: Text.AlignVCenter
                }

                PanelSlider {
                  id: transparencySlider
                  width: parent.width - Style.space(92) - transparencyValueField.width - parent.spacing * 2
                  height: Style.space(28)
                  value: root.appearanceTransparency
                  minimum: 0
                  maximum: 100
                  step: 1
                  integer: true
                  bar: root.bar
                  trackHeight: Style.space(3)
                  knobSize: Style.space(12)
                  trackColor: root.alpha(root.controlAccentColor, 0.22)
                  fillColor: root.controlAccentColor
                  knobColor: root.controlAccentColor
                  onMoved: function(value) {
                    root.appearanceTransparency = value
                    root.appearanceTransparencyText = root.formatAppearanceValue(value)
                  }
                  onReleased: function(value) { root.setAppearanceNumber("appearance_transparency", value) }
                }

                TextField {
                  id: transparencyValueField
                  width: Style.space(48)
                  height: Style.space(30)
                  text: root.appearanceTransparencyText
                  enabled: !root.preferenceBusy
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
                  background: BorderSurface {
                    color: root.controlSurfaceColor(transparencyValueField)
                    borderSpec: root.controlSurfaceBorder(transparencyValueField)
                    radius: root.compactRadius
                  }
                  onTextChanged: if (text !== root.appearanceTransparencyText) root.appearanceTransparencyText = text
                  onAccepted: root.setAppearanceNumber("appearance_transparency", text)
                }
              }

              Row {
                width: parent.width
                spacing: Style.space(7)

                Text {
                  width: Style.space(92)
                  height: Style.space(28)
                  text: "BLUR"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  verticalAlignment: Text.AlignVCenter
                }

                PanelSlider {
                  id: blurSlider
                  width: parent.width - Style.space(92) - blurValueField.width - parent.spacing * 2
                  height: Style.space(28)
                  value: root.appearanceBlur
                  minimum: 0
                  maximum: 24
                  step: 1
                  integer: true
                  bar: root.bar
                  trackHeight: Style.space(3)
                  knobSize: Style.space(12)
                  trackColor: root.alpha(root.controlAccentColor, 0.22)
                  fillColor: root.controlAccentColor
                  knobColor: root.controlAccentColor
                  onMoved: function(value) {
                    root.appearanceBlur = value
                    root.appearanceBlurText = root.formatAppearanceValue(value)
                  }
                  onReleased: function(value) { root.setAppearanceNumber("appearance_blur", value) }
                }

                TextField {
                  id: blurValueField
                  width: Style.space(48)
                  height: Style.space(30)
                  text: root.appearanceBlurText
                  enabled: !root.preferenceBusy
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
                  background: BorderSurface {
                    color: root.controlSurfaceColor(blurValueField)
                    borderSpec: root.controlSurfaceBorder(blurValueField)
                    radius: root.compactRadius
                  }
                  onTextChanged: if (text !== root.appearanceBlurText) root.appearanceBlurText = text
                  onAccepted: root.setAppearanceNumber("appearance_blur", text)
                }
              }

              Row {
                width: parent.width
                spacing: Style.space(7)

                Text {
                  width: Style.space(92)
                  height: Style.space(28)
                  text: "CORNER RADIUS"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  verticalAlignment: Text.AlignVCenter
                }

                PanelSlider {
                  id: radiusSlider
                  width: parent.width - Style.space(92) - radiusValueField.width - parent.spacing * 2
                  height: Style.space(28)
                  value: root.appearanceRadius
                  minimum: 8
                  maximum: 32
                  step: 1
                  integer: true
                  bar: root.bar
                  trackHeight: Style.space(3)
                  knobSize: Style.space(12)
                  trackColor: root.alpha(root.controlAccentColor, 0.22)
                  fillColor: root.controlAccentColor
                  knobColor: root.controlAccentColor
                  onMoved: function(value) {
                    root.appearanceRadius = value
                    root.appearanceRadiusText = root.formatAppearanceValue(value)
                  }
                  onReleased: function(value) { root.setAppearanceNumber("appearance_radius", value) }
                }

                TextField {
                  id: radiusValueField
                  width: Style.space(48)
                  height: Style.space(30)
                  text: root.appearanceRadiusText
                  enabled: !root.preferenceBusy
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
                  background: BorderSurface {
                    color: root.controlSurfaceColor(radiusValueField)
                    borderSpec: root.controlSurfaceBorder(radiusValueField)
                    radius: root.compactRadius
                  }
                  onTextChanged: if (text !== root.appearanceRadiusText) root.appearanceRadiusText = text
                  onAccepted: root.setAppearanceNumber("appearance_radius", text)
                }
              }

              Text {
                width: parent.width
                text: "Transparency and softness affect the plugin surface; your compositor still controls system-wide blur."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              AcButton {
                width: parent.width
                height: Style.space(34)
                visible: root.customAppearanceEnabled
                text: root.preferenceKind === "reset_appearance"
                  ? "RESETTING…" : "RESET CUSTOMISATIONS"
                fontSize: Style.font.caption
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: !root.compactChromeEnabled
                radius: root.compactRadius
                enabled: !root.preferenceBusy
                tooltipText: "Restore the default visual values without changing this switch"
                onClicked: root.resetCustomisations()
              }
            }
            }
          }
        }

        BorderSurface {
          id: shortcutsCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "shortcuts"
            && root.shortcutsEnabled
          width: parent.width
          implicitHeight: shortcutsForm.implicitHeight + Style.space(40)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))

          Column {
            id: shortcutsForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(20)
            spacing: Style.space(11)

            Text {
              width: parent.width
              text: "SHORTCUTS"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Click a key field, then press the combination you want. Each shortcut can be disabled separately."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            Repeater {
              model: root.shortcutDefinitions

              delegate: BorderSurface {
                required property var modelData
                width: parent.width
                implicitHeight: Math.max(54, shortcutRow.implicitHeight) + Style.space(14)
                color: root.surfaceColor(root.alpha(root.foreground, 0.018))
                borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.11), 1))
                radius: root.compactRadius

                Row {
                  id: shortcutRow
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(9)
                  anchors.rightMargin: Style.space(9)
                  spacing: Style.space(7)

                  Column {
                    width: shortcutRow.width - shortcutCaptureField.width
                      - shortcutToggle.implicitWidth - shortcutRow.spacing * 2
                    spacing: Style.space(2)
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                      width: parent.width
                      text: modelData.label
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      elide: Text.ElideRight
                    }

                    Text {
                      width: parent.width
                      text: modelData.description
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      wrapMode: Text.WordWrap
                    }

                    Text {
                      width: parent.width
                      text: modelData.scope + " · " + root.shortcutStatus(modelData.id)
                      color: root.shortcutStatus(modelData.id) === "ACTIVE"
                        ? root.accentColor : root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                    }
                  }

                  FocusScope {
                    id: shortcutCaptureField
                    width: Style.space(150)
                    height: Style.space(36)
                    activeFocusOnTab: true
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) {
                      root.captureShortcut(modelData.id, event)
                    }

                    BorderSurface {
                      anchors.fill: parent
                      color: root.compactChromeEnabled ? "transparent" : (root.shortcutCaptureId === modelData.id
                        ? root.alpha(root.accentColor, 0.12)
                        : root.alpha(root.foreground, 0.025))
                      borderSpec: root.surfaceBorder(Border.controlSpec(
                        parent.activeFocus ? "focus" : "normal",
                        root.foreground, root.controlAccentColor))
                      radius: root.compactRadius
                    }

                    Text {
                      anchors.fill: parent
                      anchors.leftMargin: Style.space(7)
                      anchors.rightMargin: Style.space(7)
                      text: root.shortcutCaptureId === modelData.id
                        ? "PRESS KEYS…" : root.shortcutDisplay(root.shortcutValue(modelData.id))
                      color: root.shortcutCaptureId === modelData.id
                        ? root.accentColor : root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      fontSizeMode: Text.HorizontalFit
                      minimumPixelSize: 8
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                      wrapMode: Text.NoWrap
                      elide: Text.ElideNone
                    }

                    MouseArea {
                      anchors.fill: parent
                      enabled: !root.preferenceBusy
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        root.shortcutCaptureId = modelData.id
                        shortcutCaptureField.forceActiveFocus()
                      }
                    }
                  }

                  ToggleSwitch {
                    id: shortcutToggle
                    width: implicitWidth
                    checked: root.shortcutEnabled(modelData.id)
                    enabled: !root.preferenceBusy && !root.shortcutCaptureActive
                    interactive: true
                    foreground: root.foreground
                    accent: root.controlAccentColor
                    anchors.verticalCenter: parent.verticalCenter
                    onToggled: root.setShortcutEnabled(
                      modelData.id, !root.shortcutEnabled(modelData.id))
                  }
                }
              }
            }

            BorderSurface {
              id: multiAcPowerShortcutsCard
              readonly property bool individualPowerAvailable: root.multiUnitEnabled
                && !root.globalSyncControls && root.selectedEntities.length > 1
              visible: individualPowerAvailable || height > 0.5
              width: parent.width
              implicitHeight: multiAcPowerShortcutsForm.implicitHeight + Style.space(20)
              height: individualPowerAvailable ? implicitHeight : 0
              opacity: individualPowerAvailable ? 1 : 0
              clip: true
              color: root.surfaceColor(root.alpha(root.accentColor, 0.045))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.22), 1))
              radius: root.compactRadius

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Column {
                id: multiAcPowerShortcutsForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                spacing: Style.space(6)

                Text {
                  width: parent.width
                  text: "INDIVIDUAL AC POWER"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Text {
                  width: parent.width
                  text: "The power shortcut followed by 1–9 targets one selected AC. Available while Globally synced controls is off."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }

                Repeater {
                  model: Math.min(9, root.selectedEntities.length)

                  delegate: BorderSurface {
                    required property int index
                    width: parent.width
                    implicitHeight: Style.space(44)
                    color: root.surfaceColor(root.alpha(root.accentColor,
                      root.shortcutEnabled("toggle_power") ? 0.055 : 0.018))
                    borderSpec: root.surfaceBorder(Border.flat(root.alpha(
                      root.shortcutEnabled("toggle_power") ? root.accentColor : root.foreground,
                      root.shortcutEnabled("toggle_power") ? 0.20 : 0.10), 1))
                    radius: root.compactRadius

                    Row {
                      id: multiShortcutRow
                      anchors.fill: parent
                      anchors.leftMargin: Style.space(8)
                      anchors.rightMargin: Style.space(8)
                      spacing: Style.space(8)

                      Text {
                        id: multiShortcutNumber
                        width: Style.space(24)
                        height: parent.height
                        text: String(index + 1)
                        color: root.shortcutEnabled("toggle_power")
                          ? root.accentColor : root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.body
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                      }

                      Column {
                        width: parent.width - multiShortcutNumber.width
                          - multiShortcutStatus.width - parent.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(1)

                        Text {
                          width: parent.width
                          text: root.entityDisplayName(root.selectedEntities[index])
                          color: root.foreground
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                          elide: Text.ElideRight
                        }

                        Text {
                          width: parent.width
                          text: root.shortcutDisplay(root.shortcutValue("toggle_power"))
                            + " + " + (index + 1)
                          color: root.dim
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          fontSizeMode: Text.HorizontalFit
                          minimumPixelSize: 8
                          wrapMode: Text.NoWrap
                          elide: Text.ElideNone
                        }
                      }

                      Text {
                        id: multiShortcutStatus
                        width: Style.space(68)
                        height: parent.height
                        text: root.shortcutEnabled("toggle_power") ? "ACTIVE" : "DISABLED"
                        color: root.shortcutEnabled("toggle_power")
                          ? root.accentColor : root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                      }
                    }
                  }
                }
              }
            }

            Text {
              visible: root.multiUnitEnabled && root.globalSyncControls
                && root.selectedEntities.length > 1
              width: parent.width
              text: "Individual AC power shortcuts appear here when Globally synced controls is off."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            AcButton {
              width: parent.width
              height: Style.space(34)
              text: root.preferenceKind === "reset_shortcuts"
                ? "RESETTING…" : "RESET SHORTCUTS"
              fontSize: Style.font.caption
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              enabled: !root.preferenceBusy
              tooltipText: "Restore the default keys and per-shortcut switches"
              onClicked: root.resetShortcuts()
            }
          }
        }

        BorderSurface {
          id: customisationCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "customisation"
            && root.customAppearanceEnabled
          width: parent.width
          implicitHeight: customisationForm.implicitHeight
            + (root.compactChromeEnabled ? Style.space(20) : Style.space(40))
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))

          Column {
            id: customisationForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.uiCardPadding
            spacing: root.uiGroupSpacing

            Text {
              width: parent.width
              text: "CUSTOMISATION"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Tune colours, per-device accents, and the panel's surface finish."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            BorderSurface {
              id: customisationOptionsSurface
              width: parent.width
              implicitHeight: customisationOptionsForm.implicitHeight
                + (root.compactChromeEnabled ? Style.space(16) : Style.space(24))
              color: root.surfaceColor(root.alpha(root.foreground, 0.018))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.10), 1))
              radius: root.compactRadius

              Column {
                id: customisationOptionsForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.compactChromeEnabled ? Style.space(8) : Style.space(12)
                spacing: root.compactChromeEnabled ? Style.space(6) : Style.space(8)

                Loader {
                  id: customisationOptionsLoader
                  width: parent.width
                  active: root.customAppearanceEnabled
                  sourceComponent: appearanceOptionsComponent
                  height: item ? item.implicitHeight : 0
                  onLoaded: if (item) item.width = width
                }
              }
            }
          }
        }

        BorderSurface {
          id: connectionMaintenanceCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "maintenance"
          width: parent.width
          implicitHeight: connectionMaintenanceForm.implicitHeight + Style.space(24)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))

          Column {
            id: connectionMaintenanceForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(12)
            spacing: Style.space(8)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Style.space(30)
                height: Style.space(30)
                text: "󰒓"
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }

              Column {
                width: parent.width - Style.space(38)
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: "HOME ASSISTANT CONNECTION"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Row {
                  id: currentConnectionRow
                  width: parent.width
                  spacing: Style.space(5)

                  Text {
                    width: parent.width - currentConnectionStatus.implicitWidth - parent.spacing
                    text: root.activeHomeAssistantUrl || root.setupUrl
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideMiddle
                  }

                  ServerStatus {
                    id: currentConnectionStatus
                    connected: root.connected
                    pingMs: root.homeAssistantPingMs
                    foreground: root.foreground
                    warningColor: root.warning
                    urgentColor: root.urgent
                    fontFamily: root.fontFamily
                  }
                }
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              AcButton {
                id: reconnectToggleButton
                width: parent.width - maintenanceHomeAssistantSettingsButton.width - parent.spacing
                height: Style.space(38)
                text: root.connectionEditing ? "CANCEL" : "RECONFIGURE"
                iconText: root.connectionEditing ? "󰅖" : "󰑐"
                iconSize: Style.font.body
                fontSize: Style.font.bodySmall
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.accentColor, 0.08)
                bordered: !root.compactChromeEnabled
                radius: root.compactRadius
                enabled: !root.setupBusy && !root.localServerBusy && !root.preferenceBusy
                tooltipText: root.connectionEditing
                  ? "Discard connection changes" : "Change the Home Assistant address or token"
                onClicked: root.connectionEditing
                  ? root.cancelReconnect() : root.beginReconnect()
              }

              AcButton {
                id: maintenanceHomeAssistantSettingsButton
                width: Style.space(196)
                height: Style.space(38)
                text: "HOME ASSISTANT SETTINGS"
                iconText: "󰏌"
                iconSize: Style.font.body
                fontSize: Style.font.caption
                horizontalPadding: Style.space(3)
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: !root.compactChromeEnabled
                radius: root.compactRadius
                enabled: !root.setupBusy && !root.localServerBusy
                tooltipText: "Open the current Home Assistant address"
                onClicked: root.openHomeAssistantSettings()
              }
            }

            Column {
              id: reconnectEditor
              visible: root.connectionEditing || height > 0.5
              width: parent.width
              height: root.connectionEditing ? implicitHeight : 0
              opacity: root.connectionEditing ? 1 : 0
              clip: true
              spacing: Style.space(7)

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Text {
                text: "HOME ASSISTANT ADDRESS"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 0.8
              }

              Row {
                id: reconnectAddressRow
                width: parent.width
                spacing: Style.space(5)

                Text {
                  id: reconnectSchemeLabel
                  text: root.setupAddressScheme + "://"
                  color: root.controlAccentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                  id: reconnectHostField
                  width: Math.max(0, reconnectAddressRow.width
                    - reconnectSchemeLabel.implicitWidth - reconnectPortSeparator.implicitWidth
                    - reconnectPortField.width - reconnectAddressRow.spacing * 3)
                  enabled: root.connectionEditing && !root.setupBusy
                  placeholderText: "homeassistant.local or 192.168.0.10"
                  text: root.setupAddressHost
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  font.family: root.fontFamily
                  inputMethodHints: Qt.ImhUrlCharactersOnly
                  selectByMouse: true
                  background: BorderSurface {
                    color: root.controlSurfaceColor(reconnectHostField)
                    borderSpec: root.controlSurfaceBorder(reconnectHostField)
                    radius: root.compactRadius
                  }
                  onTextChanged: {
                    if (!root.setupAddressSyncing && text !== root.setupAddressHost)
                      root.setupAddressHost = text
                  }
                  onEditingFinished: root.updateSetupUrlFromAddress()
                  onAccepted: {
                    root.updateSetupUrlFromAddress()
                    reconnectPortField.forceActiveFocus()
                  }
                  Keys.onEscapePressed: root.cancelReconnect()
                }

                Text {
                  id: reconnectPortSeparator
                  text: ":"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                  id: reconnectPortField
                  width: Style.space(72)
                  enabled: root.connectionEditing && !root.setupBusy
                  placeholderText: "8123"
                  text: root.setupAddressPort
                  foreground: root.foreground
                  accent: root.controlAccentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  horizontalAlignment: Text.AlignHCenter
                  inputMethodHints: Qt.ImhDigitsOnly
                  maximumLength: 5
                  validator: IntValidator { bottom: 1; top: 65535 }
                  selectByMouse: true
                  background: BorderSurface {
                    color: root.controlSurfaceColor(reconnectPortField)
                    borderSpec: root.controlSurfaceBorder(reconnectPortField)
                    radius: root.compactRadius
                  }
                  onTextChanged: {
                    if (!root.setupAddressSyncing && text !== root.setupAddressPort)
                      root.setupAddressPort = text
                  }
                  onEditingFinished: root.updateSetupUrlFromAddress()
                  onAccepted: {
                    root.updateSetupUrlFromAddress()
                    reconnectTokenField.forceActiveFocus()
                  }
                }
              }

              Text {
                width: parent.width
                text: "Enter the Home Assistant hostname or IP address and port. HTTP is the default; HTTPS and reverse-proxy paths remain supported."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              Text {
                text: "LONG-LIVED ACCESS TOKEN"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 0.8
              }

              TextField {
                id: reconnectTokenField
                width: parent.width
                enabled: root.connectionEditing && !root.setupBusy
                password: true
                placeholderText: "Leave blank to reuse the saved token for this address"
                text: root.setupToken
                foreground: root.foreground
                accent: root.controlAccentColor
                font.family: root.fontFamily
                selectByMouse: true
                background: BorderSurface {
                  color: root.controlSurfaceColor(reconnectTokenField)
                  borderSpec: root.controlSurfaceBorder(reconnectTokenField)
                  radius: root.compactRadius
                }
                onTextChanged: if (text !== root.setupToken) root.setupToken = text
                onAccepted: root.submitSetup(true)
                Keys.onEscapePressed: root.cancelReconnect()
              }

              Text {
                width: parent.width
                text: "For the current Home Assistant address, leaving this blank reuses the saved token locally. Enter a new token only when changing servers or rotating credentials."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              AcDropdown {
                id: reconnectEntityDropdown
                visible: root.setupEntityOptions.length > 0
                width: parent.width
                label: "AIR CONDITIONER"
                options: root.setupDropdownOptions
                value: root.setupSelectedEntity
                foreground: root.foreground
                background: root.appearanceBackgroundColor
                popupBorder: root.appearancePopupBorderColor
                accent: root.controlAccentColor
                fontFamily: root.fontFamily
                controlRadius: root.compactRadius
                chromeLess: root.compactChromeEnabled
                onChanged: function(value) { root.setupSelectedEntity = value }
              }

              AcButton {
                width: parent.width
                height: Style.space(38)
                text: root.setupBusy ? "RECONFIGURING…" : "RECONFIGURE"
                iconText: root.setupBusy ? "" : "󰑐"
                iconSize: Style.font.body
                fontSize: Style.font.bodySmall
                fontFamily: root.fontFamily
                enabled: root.reconnectCanSubmit && root.connectionEditing
                foreground: root.accentTextColor
                accent: root.accentColor
                background: root.accentColor
                bordered: false
                radius: root.compactRadius
                onClicked: root.submitSetup(true)

                LoadingRing {
                  visible: root.setupBusy
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(14)
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(16)
                  height: width
                  color: root.accentTextColor
                  strokeWidth: Style.space(2)
                }
              }

              BorderSurface {
                visible: root.setupError !== ""
                width: parent.width
                implicitHeight: reconnectMessage.implicitHeight + Style.space(18)
                color: root.surfaceColor(root.alpha(root.urgent, 0.09))
                borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.32), 1))
                radius: root.compactRadius

                Text {
                  id: reconnectMessage
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  text: root.setupError
                  color: root.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }

        BorderSurface {
          id: localServerMaintenanceCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "maintenance"
          width: parent.width
          implicitHeight: localServerMaintenanceForm.implicitHeight + Style.space(24)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.20), 1))

          Column {
            id: localServerMaintenanceForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(12)
            spacing: Style.space(8)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                width: Style.space(30)
                height: Style.space(30)
                text: "󰒓"
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }

              Column {
                width: parent.width - Style.space(38)
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: "LOCAL HOME ASSISTANT"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                }

                Row {
                  id: localServerAddressRow
                  width: parent.width
                  spacing: Style.space(5)

                  Text {
                    width: parent.width
                      - (root.localHomeAssistantConfigured
                        ? localServerConnectionStatus.implicitWidth : 0)
                      - (root.localHomeAssistantConfigured ? parent.spacing : 0)
                    text: root.localHomeAssistantConfigured
                      ? root.activeHomeAssistantUrl
                      : (root.localServerReady ? "READY · RECONFIGURE TO USE" : "OPTIONAL · NOT SELECTED")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideMiddle
                  }

                  ServerStatus {
                    id: localServerConnectionStatus
                    visible: root.localHomeAssistantConfigured
                    connected: root.localHomeAssistantConnected
                    pingMs: root.localHomeAssistantConfigured ? root.homeAssistantPingMs : -1
                    offlineText: root.localHomeAssistantConfigured ? "OFFLINE" : "NOT ACTIVE"
                    foreground: root.foreground
                    urgentColor: root.urgent
                    fontFamily: root.fontFamily
                  }
                }
              }
            }

              AcButton {
                id: localServerDetailsToggle
              width: parent.width
              height: Style.space(38)
              text: root.localServerExpanded
                ? "HIDE LOCAL SERVER SETUP"
                : (root.localHomeAssistantConfigured ? "LOCAL SERVER OPTIONS" : "SET UP LOCALLY")
              iconText: root.localServerExpanded ? "↑" : "󰒓"
              iconSize: Style.font.body
              fontSize: Style.font.bodySmall
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              enabled: !root.localServerBusy && !root.setupBusy && !root.preferenceBusy
              onClicked: root.localServerExpanded = !root.localServerExpanded
            }

            Column {
              id: localServerMaintenanceDetails
              visible: root.localServerExpanded || height > 0.5
              width: parent.width
              height: root.localServerExpanded ? implicitHeight : 0
              opacity: root.localServerExpanded ? 1 : 0
              clip: true
              spacing: Style.space(7)

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              BorderSurface {
                width: parent.width
                implicitHeight: localServerMaintenanceDetailsText.implicitHeight + Style.space(18)
                color: root.surfaceColor(root.alpha(root.foreground, 0.025))
                borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.11), 1))
                radius: root.compactRadius

                Text {
                  id: localServerMaintenanceDetailsText
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  text: "Optional official Home Assistant Container on this PC. Docker may ask for administrator approval; data stays in ~/.local/share/omarchy/homeassistant. Your current connection is unchanged until you reconfigure above."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }
              }

              Row {
                width: parent.width
                spacing: Style.space(8)

                CriticalActionSplit {
                  id: localServerMaintenanceAction
                  width: parent.width - localServerMaintenanceGuide.width - parent.spacing
                  height: Style.space(38)
                  idleText: root.localServerReady || root.localHomeAssistantConfigured
                    ? "OPEN HOME ASSISTANT" : "SET UP LOCALLY"
                  busyText: "SETTING UP…"
                  confirmText: "RUN SETUP"
                  idleIcon: root.localServerReady || root.localHomeAssistantConfigured ? "↗" : "󰒓"
                  idleTooltip: root.localServerReady || root.localHomeAssistantConfigured
                    ? "Open the local Home Assistant server"
                    : "Prepare the local Home Assistant setup"
                  confirmTooltip: "Run the local Home Assistant setup script"
                  backTooltip: "Cancel local Home Assistant setup"
                  actionColor: root.accentColor
                  actionTextColor: root.accentTextColor
                  idleBackground: root.alpha(root.accentColor, 0.07)
                  backTextColor: root.foreground
                  backBackground: root.alpha(root.foreground, 0.025)
                  controlRadius: root.compactRadius
                  chromeLess: root.compactChromeEnabled
                  fontFamily: root.fontFamily
                  confirming: root.localServerConfirming
                  busy: root.localServerBusy
                  actionEnabled: !root.localServerBusy && !root.setupBusy && !root.preferenceBusy
                  onActionRequested: root.localServerReady || root.localHomeAssistantConfigured
                    ? root.openLocalServer() : root.requestLocalServerSetup()
                  onBackRequested: root.cancelLocalServerSetup()
                }

                AcButton {
                  id: localServerMaintenanceGuide
                  width: Style.space(96)
                  height: Style.space(38)
                  text: "GUIDE"
                  fontSize: Style.font.caption
                  fontFamily: root.fontFamily
                  foreground: root.foreground
                  accent: root.accentColor
                  background: root.alpha(root.foreground, 0.025)
                  bordered: !root.compactChromeEnabled
                  radius: root.compactRadius
                  tooltipText: root.homeAssistantLinuxGuideUrl
                  enabled: !root.localServerBusy && !root.localServerConfirming
                  onClicked: Qt.openUrlExternally(root.homeAssistantLinuxGuideUrl)
                }
              }

              BorderSurface {
                readonly property bool hasLocalServerMaintenanceStatus: root.localServerMessage !== ""
                  || root.localServerError !== ""
                visible: hasLocalServerMaintenanceStatus || height > 0.5
                width: parent.width
                implicitHeight: localServerMaintenanceStatus.implicitHeight + Style.space(18)
                height: hasLocalServerMaintenanceStatus ? implicitHeight : 0
                opacity: hasLocalServerMaintenanceStatus ? 1 : 0
                clip: true
                color: root.surfaceColor(root.alpha(root.localServerError !== "" ? root.urgent : root.accentColor, 0.09))
                borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.localServerError !== "" ? root.urgent : root.accentColor, 0.32), 1))
                radius: root.compactRadius

                Behavior on height {
                  NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                  NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                }

                Text {
                  id: localServerMaintenanceStatus
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  text: root.localServerError !== ""
                    ? root.localServerError : root.localServerMessage
                  color: root.localServerError !== "" ? root.urgent : root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }

        BorderSurface {
          id: aboutCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "maintenance"
          width: parent.width
          implicitHeight: aboutForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.foreground, 0.025))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.14), 1))

          Column {
            id: aboutForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(8)

            Text {
              width: parent.width
              text: "PROJECT & HELP"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Daikin AC Controls · Made by Sai"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Find setup help, Home Assistant notes, and future tutorials on the project page."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            AcButton {
              width: parent.width
              height: Style.space(40)
              text: "OPEN GITHUB HELP"
              iconText: "󰊤"
              iconSize: Style.font.body
              fontSize: Style.font.bodySmall
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.accentColor, 0.09)
              bordered: !root.compactChromeEnabled
              radius: root.compactRadius
              tooltipText: root.githubUrl
              onClicked: Qt.openUrlExternally(root.githubUrl)
            }
          }
        }

        BorderSurface {
          id: appDataCard
          visible: root.configured && !root.configFileModeEnabled
            && root.settingsSection === "maintenance"
          width: parent.width
          implicitHeight: appDataForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.urgent, 0.025))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.20), 1))

          Column {
            id: appDataForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(16)
            spacing: Style.space(8)

            Text {
              width: parent.width
              text: "APP DATA & RESET"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Manage the plugin's saved data and installation."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              wrapMode: Text.WordWrap
            }

            BorderSurface {
              id: resetCard
              width: parent.width
              implicitHeight: resetForm.implicitHeight + Style.space(20)
              color: root.surfaceColor(root.alpha(root.urgent, 0.035))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.20), 1))
              radius: root.compactRadius

              Column {
                id: resetForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(7)

                Text {
                  width: parent.width
                  text: "RESET PLUGIN"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Text {
                  width: parent.width
                  text: "Start the Daikin AC controls setup again from the beginning."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }

                Column {
                  visible: root.resetAppConfirming || height > 0.5
                  width: parent.width
                  height: root.resetAppConfirming ? implicitHeight : 0
                  opacity: root.resetAppConfirming ? 1 : 0
                  clip: true
                  spacing: Style.space(7)

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  Item {
                    id: resetConfirmWarning
                    width: parent.width
                    height: root.resetAppConfirming ? resetWarningSurface.implicitHeight : 0
                    implicitHeight: height
                    opacity: root.resetAppConfirming ? 1 : 0
                    visible: opacity > 0.01
                    clip: true

                    Behavior on height {
                      NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                      NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                    }

                    BorderSurface {
                      id: resetWarningSurface
                      width: parent.width
                      implicitHeight: resetAppWarning.implicitHeight + Style.space(18)
                      color: root.surfaceColor(root.alpha(root.urgent, 0.07))
                      borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.25), 1))
                      radius: root.compactRadius

                      Text {
                        id: resetAppWarning
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Style.space(10)
                        anchors.rightMargin: Style.space(10)
                        text: "This resets the plugin's saved Home Assistant connection, preferences, and local temperature history. It does not reset Home Assistant, its Docker container, any Home Assistant data, or an external server timer/history file."
                        color: root.urgent
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        wrapMode: Text.WordWrap
                      }
                    }
                  }
                }

                Item {
                  id: resetActionArea
                  width: parent.width
                  height: Style.space(40)
                  clip: true

                  AcButton {
                    id: resetButton
                    anchors.fill: parent
                    visible: opacity > 0.01
                    opacity: 1 - resetSplitFrame.splitProgress
                    text: "RESET PLUGIN"
                    fontSize: Style.font.bodySmall
                    fontFamily: root.fontFamily
                    foreground: root.urgent
                    accent: root.urgent
                    background: root.alpha(root.urgent, 0.08)
                    bordered: !root.compactChromeEnabled
                    radius: root.compactRadius
                    enabled: !root.resetAppBusy && !root.resetAppConfirming && !root.setupBusy
                      && !root.localServerBusy && !root.preferenceBusy
                      && !root.uninstallConfirming && !root.uninstallBusy
                      && !configProcess.running && !entitiesProcess.running
                    onClicked: root.requestResetApp()

                  }

                  Item {
                    id: resetSplitFrame
                    anchors.fill: parent
                    clip: true
                    property real splitProgress: root.resetAppConfirming ? 1 : 0
                    readonly property real backWidth: Style.space(86) * splitProgress
                    readonly property real splitGap: Style.space(8) * splitProgress
                    visible: opacity > 0.01
                    opacity: splitProgress

                    Behavior on splitProgress {
                      NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                    }

                    AcButton {
                      id: resetBackButton
                      x: 0
                      width: resetSplitFrame.backWidth
                      height: parent.height
                      visible: resetSplitFrame.splitProgress > 0.02
                      opacity: Math.min(1, resetSplitFrame.splitProgress * 1.5)
                      clip: true
                      text: "BACK"
                      iconText: "←"
                      iconSize: Style.font.body
                      fontSize: Style.font.bodySmall
                      horizontalPadding: Style.space(4)
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.urgent
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      radius: root.compactRadius
                      enabled: !root.resetAppBusy
                      tooltipText: "Keep the app data"
                      onClicked: root.cancelResetApp()
                    }

                    AcButton {
                      id: resetConfirmButton
                      x: resetSplitFrame.backWidth + resetSplitFrame.splitGap
                      width: Math.max(0, parent.width - x)
                      height: parent.height
                      clip: true
                      opacity: resetSplitFrame.splitProgress
                      text: root.resetAppBusy ? "RESETTING…" : "RESET NOW"
                      fontSize: Style.font.bodySmall
                      fontFamily: root.fontFamily
                      foreground: root.contrastingTextColor(root.urgent)
                      accent: root.urgent
                      background: root.urgent
                      bordered: false
                      radius: root.compactRadius
                      enabled: !root.resetAppBusy
                      tooltipText: "Remove only Daikin AC Controls data"
                      onClicked: root.resetApp()

                      LoadingRing {
                        visible: root.resetAppBusy
                        anchors.left: parent.left
                        anchors.leftMargin: Style.space(14)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Style.space(16)
                        height: width
                        color: root.contrastingTextColor(root.urgent)
                        strokeWidth: Style.space(2)
                      }
                    }
                  }
                }

                BorderSurface {
                  readonly property bool hasResetStatus: root.resetAppMessage !== ""
                    || root.resetAppError !== ""
                  visible: hasResetStatus || height > 0.5
                  width: parent.width
                  implicitHeight: appDataStatus.implicitHeight + Style.space(18)
                  height: hasResetStatus ? implicitHeight : 0
                  opacity: hasResetStatus ? 1 : 0
                  clip: true
                  color: root.surfaceColor(root.alpha(root.resetAppError !== "" ? root.urgent : root.accentColor, 0.09))
                  borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.resetAppError !== "" ? root.urgent : root.accentColor, 0.32), 1))
                  radius: root.compactRadius

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  Text {
                    id: appDataStatus
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Style.space(10)
                    anchors.rightMargin: Style.space(10)
                    text: root.resetAppError !== ""
                      ? root.resetAppError : root.resetAppMessage
                    color: root.resetAppError !== "" ? root.urgent : root.accentColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }

            BorderSurface {
              id: uninstallCard
              width: parent.width
              implicitHeight: uninstallForm.implicitHeight + Style.space(20)
              color: root.surfaceColor(root.alpha(root.urgent, 0.035))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.20), 1))
              radius: root.compactRadius

              Column {
                id: uninstallForm
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(12)
                spacing: Style.space(7)

                Text {
                  width: parent.width
                  text: "UNINSTALL"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 0.8
                }

                Text {
                  width: parent.width
                  text: "Remove Daikin AC Controls from this PC. Home Assistant and Docker are never touched unless you explicitly choose the full local-server cleanup."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }

                Item {
                  id: uninstallActionArea
                  width: parent.width
                  height: Style.space(40)
                  clip: true

                  AcButton {
                    id: uninstallButton
                    anchors.fill: parent
                    visible: opacity > 0.01
                    opacity: 1 - uninstallSplitFrame.splitProgress
                    text: "UNINSTALL"
                    fontSize: Style.font.bodySmall
                    fontFamily: root.fontFamily
                    foreground: root.urgent
                    accent: root.urgent
                    background: root.alpha(root.urgent, 0.08)
                    bordered: !root.compactChromeEnabled
                    radius: root.compactRadius
                    enabled: !root.uninstallBusy && !root.uninstallConfirming
                      && !root.resetAppBusy && !root.setupBusy && !root.localServerBusy
                      && !root.preferenceBusy && !root.remoteHistoryBusy
                      && !root.remoteHistorySourceBusy
                    tooltipText: "Choose what to remove, then confirm"
                    onClicked: root.requestUninstall()
                  }

                  Item {
                    id: uninstallSplitFrame
                    anchors.fill: parent
                    clip: true
                    property real splitProgress: root.uninstallConfirming ? 1 : 0
                    readonly property real backWidth: Style.space(86) * splitProgress
                    readonly property real splitGap: Style.space(8) * splitProgress
                    visible: opacity > 0.01
                    opacity: splitProgress

                    Behavior on splitProgress {
                      NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                    }

                    AcButton {
                      id: uninstallBackButton
                      x: 0
                      width: uninstallSplitFrame.backWidth
                      height: parent.height
                      visible: uninstallSplitFrame.splitProgress > 0.02
                      opacity: Math.min(1, uninstallSplitFrame.splitProgress * 1.5)
                      clip: true
                      text: "BACK"
                      iconText: "←"
                      iconSize: Style.font.body
                      fontSize: Style.font.bodySmall
                      horizontalPadding: Style.space(4)
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.urgent
                      background: root.alpha(root.foreground, 0.025)
                      bordered: !root.compactChromeEnabled
                      radius: root.compactRadius
                      enabled: !root.uninstallBusy
                      tooltipText: "Close uninstall choices"
                      onClicked: root.cancelUninstall()
                    }

                    Text {
                      x: uninstallSplitFrame.backWidth + uninstallSplitFrame.splitGap
                      width: Math.max(0, parent.width - x)
                      height: parent.height
                      color: root.urgent
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: true
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                      text: "CHOOSE WHAT TO REMOVE"
                    }
                  }
                }

                Column {
                  id: uninstallOptions
                  visible: root.uninstallConfirming || height > 0.5
                  width: parent.width
                  height: root.uninstallConfirming ? implicitHeight : 0
                  opacity: root.uninstallConfirming ? 1 : 0
                  clip: true
                  spacing: Style.space(6)

                  Behavior on height {
                    NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  Text {
                    width: parent.width
                    text: "Each choice has its own notice and confirmation. Opening this list changes nothing."
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }

                  Repeater {
                    model: [
                      { value: "everything", label: "REMOVE EVERYTHING" },
                      { value: "app_logger", label: "REMOVE APP + LOGGER" },
                      { value: "plugin", label: "REMOVE PLUGIN ONLY" },
                    ]

                    Item {
                      id: uninstallOptionDelegate
                      required property var modelData
                      readonly property bool selected: root.uninstallOptionConfirming
                        && root.uninstallMode === modelData.value
                      onSelectedChanged: {
                        if (selected) root.focusConfirmationItem(uninstallOptionConfirmButton)
                      }
                      width: uninstallOptions.width
                      height: selected ? uninstallOptionConfirmation.implicitHeight : Style.space(38)
                      clip: true

                      Behavior on height {
                        NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                      }

                      AcButton {
                        id: uninstallOptionButton
                        width: parent.width
                        height: parent.selected ? 0 : Style.space(38)
                        visible: opacity > 0.01
                        opacity: parent.selected ? 0 : 1
                        text: modelData.label
                        fontSize: Style.font.caption
                        horizontalPadding: Style.space(6)
                        fontFamily: root.fontFamily
                        foreground: root.foreground
                        accent: root.urgent
                        background: root.alpha(root.foreground, 0.025)
                        bordered: !root.compactChromeEnabled
                        selected: parent.selected
                        radius: root.compactRadius
                        enabled: !root.uninstallBusy
                        tooltipText: "Review what this uninstall scope removes"
                        onClicked: root.chooseUninstallMode(modelData.value)

                        Behavior on height {
                          NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                          NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                        }
                      }

                      Column {
                        id: uninstallOptionConfirmation
                        width: parent.width
                        height: parent.selected ? implicitHeight : 0
                        opacity: parent.selected ? 1 : 0
                        spacing: Style.space(6)

                        Behavior on height {
                          NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                          NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                        }

                        Item {
                          id: uninstallOptionWarning
                          width: parent.width
                          height: parent.parent.selected
                            ? uninstallOptionWarningSurface.implicitHeight : 0
                          implicitHeight: height
                          opacity: parent.parent.selected ? 1 : 0
                          visible: opacity > 0.01
                          clip: true

                          Behavior on height {
                            NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                          }
                          Behavior on opacity {
                            NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                          }

                          BorderSurface {
                            id: uninstallOptionWarningSurface
                            width: parent.width
                            implicitHeight: uninstallOptionNotice.implicitHeight + Style.space(18)
                            color: root.surfaceColor(root.alpha(root.urgent, 0.07))
                            borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.25), 1))
                            radius: root.compactRadius

                            Text {
                              id: uninstallOptionNotice
                              anchors.left: parent.left
                              anchors.right: parent.right
                              anchors.verticalCenter: parent.verticalCenter
                              anchors.leftMargin: Style.space(10)
                              anchors.rightMargin: Style.space(10)
                              text: root.uninstallNotice(modelData.value)
                              color: root.urgent
                              font.family: root.fontFamily
                              font.pixelSize: Style.font.caption
                              wrapMode: Text.WordWrap
                            }
                          }
                        }

                        Item {
                          id: uninstallOptionConfirmActionArea
                          width: parent.width
                          height: Style.space(40)
                          clip: true

                          Item {
                            id: uninstallOptionSplitFrame
                            anchors.fill: parent
                            clip: true
                            property real splitProgress: uninstallOptionDelegate.selected ? 1 : 0
                            readonly property real backWidth: Style.space(86) * splitProgress
                            readonly property real splitGap: Style.space(8) * splitProgress
                            visible: opacity > 0.01
                            opacity: splitProgress

                            Behavior on splitProgress {
                              NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                            }

                            AcButton {
                              id: uninstallOptionBackButton
                              x: 0
                              width: uninstallOptionSplitFrame.backWidth
                              height: parent.height
                              visible: uninstallOptionSplitFrame.splitProgress > 0.02
                              opacity: Math.min(1, uninstallOptionSplitFrame.splitProgress * 1.5)
                              clip: true
                              text: "BACK"
                              iconText: "←"
                              iconSize: Style.font.body
                              fontSize: Style.font.bodySmall
                              horizontalPadding: Style.space(4)
                              fontFamily: root.fontFamily
                              foreground: root.foreground
                              accent: root.urgent
                              background: root.alpha(root.foreground, 0.025)
                              bordered: !root.compactChromeEnabled
                              radius: root.compactRadius
                              enabled: !root.uninstallBusy
                              tooltipText: "Choose a different uninstall scope"
                              onClicked: {
                                root.uninstallOptionConfirming = false
                                root.uninstallMode = ""
                                root.uninstallError = ""
                              }
                            }

                            AcButton {
                              id: uninstallOptionConfirmButton
                              x: uninstallOptionSplitFrame.backWidth + uninstallOptionSplitFrame.splitGap
                              width: Math.max(0, parent.width - x)
                              height: parent.height
                              clip: true
                              opacity: uninstallOptionSplitFrame.splitProgress
                              text: root.uninstallBusy
                                ? "UNINSTALLING…" : root.uninstallActionLabel()
                              fontSize: Style.font.bodySmall
                              fontFamily: root.fontFamily
                              foreground: root.contrastingTextColor(root.urgent)
                              accent: root.urgent
                              background: root.urgent
                              bordered: false
                              radius: root.compactRadius
                              enabled: !root.uninstallBusy
                              tooltipText: "Confirm this uninstall scope"
                              onClicked: root.startUninstall()

                              LoadingRing {
                                visible: root.uninstallBusy
                                anchors.left: parent.left
                                anchors.leftMargin: Style.space(14)
                                anchors.verticalCenter: parent.verticalCenter
                                width: Style.space(16)
                                height: width
                                color: root.contrastingTextColor(root.urgent)
                                strokeWidth: Style.space(2)
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }

                BorderSurface {
                  readonly property bool hasUninstallStatus: root.uninstallMessage !== ""
                    || root.uninstallError !== ""
                  visible: hasUninstallStatus || height > 0.5
                  width: parent.width
                  implicitHeight: uninstallStatus.implicitHeight + Style.space(18)
                  height: hasUninstallStatus ? implicitHeight : 0
                  opacity: hasUninstallStatus ? 1 : 0
                  clip: true
                  color: root.surfaceColor(root.alpha(root.uninstallError !== "" ? root.urgent : root.accentColor, 0.09))
                  borderSpec: root.surfaceBorder(Border.flat(root.alpha(
                    root.uninstallError !== "" ? root.urgent : root.accentColor, 0.30), 1))
                  radius: root.compactRadius

                  Behavior on height {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on opacity {
                    NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
                  }

                  Text {
                    id: uninstallStatus
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Style.space(10)
                    anchors.rightMargin: Style.space(10)
                    text: root.uninstallError !== ""
                      ? root.uninstallError : root.uninstallMessage
                    color: root.uninstallError !== "" ? root.urgent : root.accentColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }
          }
        }
      }

      Column {
        id: column
        visible: !root.setupOpen
        width: parent.width
        spacing: root.compactChromeEnabled ? Style.space(6) : Style.space(10)

        BorderSurface {
          id: heroCard
          width: parent.width
          height: Style.space(84)
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.accentColor, root.isOn ? 0.10 : 0.04))
          gradient: Gradient {
            GradientStop { position: 0.0; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.accentColor, root.isOn ? 0.24 : 0.10) }
            GradientStop { position: 0.58; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.accentColor, root.isOn ? 0.08 : 0.035) }
            GradientStop { position: 1.0; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.foreground, 0.025) }
          }
          borderSpec: root.surfaceBorder(Border.flat(
            root.isOn ? root.alpha(root.accentColor, 0.58) : root.alpha(root.foreground, 0.18), 1))

          Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: Style.space(16)
            width: Style.space(44)
            height: Style.space(3)
            radius: height / 2
            color: root.isOn ? root.accentColor : root.alpha(root.foreground, 0.32)
          }

          Row {
            anchors.fill: parent
            anchors.margins: Style.space(12)
            spacing: Style.space(12)

            BorderSurface {
              id: climateIcon
              width: Style.space(58)
              height: Style.space(58)
              anchors.verticalCenter: parent.verticalCenter
              radius: root.nestedRadius
              color: root.surfaceColor(root.isOn ? root.alpha(root.accentColor, 0.18) : root.alpha(root.foreground, 0.05))
              borderSpec: root.surfaceBorder(Border.flat(root.isOn ? root.alpha(root.accentColor, 0.78) : root.alpha(root.foreground, 0.22), 1))

              Rectangle {
                id: iconGlow
                anchors.centerIn: parent
                width: Style.space(42)
                height: width
                radius: width / 2
                color: root.accentColor
                opacity: root.isOn ? 0.16 : 0
                scale: root.isOn ? 1.0 : 0.72

                Behavior on opacity { NumberAnimation { duration: root.motionStandard } }
                Behavior on scale { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
              }

              Text {
                width: Style.space(36)
                height: Style.space(36)
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.climateModeIcon(root.activeMode)
                color: root.isOn ? root.accentColor : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                font.bold: true
              }

              Rectangle {
                visible: root.connected
                width: Style.space(7)
                height: width
                radius: width / 2
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: Style.space(7)
                anchors.bottomMargin: Style.space(7)
                color: root.stateColor
                border.color: root.alpha(root.appearanceBackgroundColor, 0.92)
                border.width: Style.space(2)
              }
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: Math.max(0, parent.width - climateIcon.width
                - (heroActions.visible ? heroActions.implicitWidth : 0) - parent.spacing * 2)
              spacing: Style.space(3)

              Row {
                width: parent.width

                Text {
                  width: parent.width
                  text: root.connected ? String(root.reading.name || "Air conditioner") : "Daikin AC Controls"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                  font.bold: true
                  elide: Text.ElideRight
                }
              }

              Text {
                width: parent.width
                text: root.deviceInfoText.toUpperCase()
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 0.8
                elide: Text.ElideRight
              }
            }

            Row {
              id: heroActions
              visible: root.configured
              spacing: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter

              Row {
                id: connectionStatus
                visible: root.connected
                spacing: Style.space(6)
                height: Math.max(connectionDot.height, connectionStatusText.implicitHeight)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                  id: connectionDot
                  width: Style.space(6)
                  height: width
                  radius: width / 2
                  anchors.verticalCenter: parent.verticalCenter
                  color: root.statusColor
                }

                Text {
                  id: connectionStatusText
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.connectionText
                  color: root.statusColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 1.0
                }
              }

              AcButton {
                width: Style.space(34)
                height: Style.space(30)
                iconText: "󰒓"
                iconSize: Style.font.body
                // Keep the visible key compact; the tooltip contains the
                // spaced, human-readable version and its enabled state.
                text: ""
                fontSize: Style.font.bodySmall
                horizontalPadding: Style.space(6)
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.035)
                bordered: !root.compactChromeEnabled
                radius: root.compactRadius
                tooltipText: "Open Settings"
                  + (root.openSettingsShortcutActive
                    ? " · " + root.openSettingsShortcutDisplay
                    : " · keyboard shortcut disabled")
                onClicked: root.openSetup()
              }
            }
          }
        }

        PanelSeparator {
          visible: !root.compactChromeEnabled
          foreground: root.foreground
          strength: 0.08
        }

        AcDropdown {
          visible: root.entityOptions.length > 0
          width: parent.width
          label: "AIR CONDITIONER"
          options: root.dropdownOptions
          value: root.pendingEntity !== "" ? root.pendingEntity : root.selectedEntity
          foreground: root.foreground
          background: root.appearanceBackgroundColor
          popupBorder: root.appearancePopupBorderColor
          accent: root.controlAccentColor
          fontFamily: root.fontFamily
          controlRadius: root.compactRadius
          chromeLess: root.compactChromeEnabled
          onChanged: function(value) { root.chooseEntity(value) }
        }

        Column {
          id: selectedUnitsSection
          visible: root.multiUnitEnabled && root.selectedEntities.length > 0
          width: parent.width
          spacing: Style.space(5)

          Text {
            width: parent.width
            text: "SELECTED AIR CONDITIONERS"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.8
          }

          Repeater {
            model: root.selectedEntities

            BorderSurface {
              required property var modelData
              readonly property color cardAccent: root.deviceCardAccent(String(modelData))
              width: selectedUnitsSection.width
              height: Style.space(32)
              radius: root.compactRadius
              color: root.surfaceColor(root.alpha(cardAccent, String(modelData) === root.selectedEntity ? 0.12 : 0.045))
              borderSpec: root.surfaceBorder(Border.flat(root.alpha(
                cardAccent, String(modelData) === root.selectedEntity ? 0.36 : 0.18), 1))

              Row {
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(4)
                spacing: Style.space(6)

                Text {
                  width: parent.width - removeSelectedUnitButton.width - parent.spacing
                  height: parent.height
                  text: root.entityDisplayName(modelData)
                  color: String(modelData) === root.selectedEntity ? parent.parent.cardAccent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: String(modelData) === root.selectedEntity
                  elide: Text.ElideRight
                  verticalAlignment: Text.AlignVCenter
                }

                AcButton {
                  id: removeSelectedUnitButton
                  width: Style.space(24)
                  height: Style.space(24)
                  anchors.verticalCenter: parent.verticalCenter
                  text: "×"
                  fontSize: Style.font.bodySmall
                  horizontalPadding: 0
                  verticalPadding: 0
                  fontFamily: root.fontFamily
                  foreground: root.foreground
                  accent: parent.parent.cardAccent
                  background: root.alpha(root.foreground, 0.035)
                  bordered: !root.compactChromeEnabled
                  radius: width / 2
                  enabled: root.selectedEntities.length > 1 && !root.actionBusy
                  tooltipText: root.selectedEntities.length > 1
                    ? "Remove this air conditioner from the panel" : "Keep one air conditioner selected"
                  onClicked: root.removeSelectedEntity(String(modelData))
                }
              }
            }
          }
        }

        Column {
          id: separateControlsSection
          visible: root.separateRemotesActive
          width: parent.width
          spacing: Style.space(7)

          Text {
            width: parent.width
            text: "SEPARATE CONTROLS"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            width: parent.width
            text: root.showClimateControls
              ? "Each selected air conditioner has its own remote."
              : "Climate controls are hidden; each AC keeps its own power button."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Flow {
            id: separateRemoteFlow
            width: parent.width
            spacing: Style.space(8)

            Repeater {
              model: root.selectedEntities

              ClimateRemote {
                required property var modelData
                width: Math.max(
                  Style.space(240),
                  (separateRemoteFlow.width - separateRemoteFlow.spacing) / 2)
                climate: root.unitReading(String(modelData)) || ({})
                localState: {
                  var revision = root.unitLocalStateRevision
                  return root.unitLocalState(String(modelData))
                }
                powerCancelEnabled: root.connected && !root.masterSwitchBusy
                showClimateControls: root.showClimateControls
                accent: root.deviceCardAccent(String(modelData))
                controlAccent: root.deviceControlAccent(String(modelData))
                cardAccent: root.deviceCardAccent(String(modelData))
                popupBackground: root.appearanceBackgroundColor
                popupBorder: root.appearancePopupBorderColor
                foreground: root.foreground
                dim: root.dim
                fontFamily: root.fontFamily
                panelRadius: root.compactRadius
                chromeLess: root.compactChromeEnabled
                enabled: root.connected && !root.actionBusy
                onTemperatureRequested: function(value) {
                  root.requestUnitTemperature(String(modelData), value)
                }
                onModeRequested: function(value) {
                  root.requestUnitMode(String(modelData), value)
                }
                onFanModeRequested: function(value) {
                  root.requestUnitFanMode(String(modelData), value)
                }
                onPowerRequested: function(value) {
                  root.requestUnitPower(String(modelData), value, true)
                }
                onPowerCancelRequested: {
                  root.cancelUnitPower(String(modelData))
                }
              }
            }
          }
        }

        PanelSeparator {
          visible: !root.compactChromeEnabled
          foreground: root.foreground
          strength: 0.08
        }

        Item {
          visible: root.showMainRemote || height > 0.5
          width: parent.width
          implicitHeight: Math.max(temperatureHeader.implicitHeight, moodPill.height)
          height: root.showMainRemote ? implicitHeight : 0
          opacity: root.showMainRemote ? 1 : 0

          Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

          PanelSectionHeader {
            id: temperatureHeader
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "TEMPERATURE"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          BorderSurface {
            id: moodPill
            visible: root.connected && root.isOn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: moodTextLabel.implicitWidth + Style.space(14)
            height: Style.space(22)
            radius: height / 2
            color: root.surfaceColor(root.alpha(root.accentColor, root.moodText === "COMFY" ? 0.16 : 0.09))
            borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, root.moodText === "COMFY" ? 0.55 : 0.32), 1))

            Text {
              id: moodTextLabel
              anchors.centerIn: parent
              text: root.moodText
              color: root.accentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
            }
          }
        }

        Row {
          visible: root.showMainRemote || height > 0.5
          width: parent.width
          height: root.showMainRemote ? implicitHeight : 0
          opacity: root.showMainRemote ? 1 : 0
          spacing: Style.spacing.md

          Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

          BorderSurface {
            id: ambientCard
            width: Math.round((parent.width - parent.spacing) * 0.34)
            height: Style.space(98)
            radius: root.panelRadius
            color: root.surfaceColor(root.alpha(root.foreground, 0.035))
            gradient: Gradient {
              GradientStop { position: 0.0; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.ambientTemperatureTint, 0.075) }
              GradientStop { position: 0.56; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.ambientTemperatureTint, 0.032) }
              GradientStop { position: 1.0; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.foreground, 0.018) }
            }
            borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.16), 1))

            Column {
              anchors.centerIn: parent
              width: parent.width - Style.space(16)
              spacing: Style.space(5)

              Text {
                width: parent.width
                text: "AMBIENT"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.0
                horizontalAlignment: Text.AlignHCenter
              }

              Text {
                width: parent.width
                text: root.mainAmbientText
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: root.temperatureValueFontSize(
                  root.mainAmbientText, Style.font.displayLarge)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }

          BorderSurface {
            id: targetCard
            width: parent.width - ambientCard.width - parent.spacing
            height: ambientCard.height
            radius: root.panelRadius
            color: root.compactChromeEnabled ? "transparent" : (root.isOn
              ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.14 : 0.08)
              : root.alpha(root.foreground, 0.035))
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: root.compactChromeEnabled ? "transparent" : (root.isOn
                  ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.22 : 0.14)
                  : root.alpha(root.foreground, 0.075))
              }
              GradientStop {
                position: 1.0
                color: root.compactChromeEnabled ? "transparent" : (root.isOn
                  ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.06 : 0.025)
                  : root.alpha(root.foreground, 0.018))
              }
            }
            borderSpec: root.surfaceBorder(Border.flat(
              root.isOn
                ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.72 : 0.38)
                : root.alpha(root.foreground, 0.16), 1))

            Rectangle {
              visible: root.isOn
              anchors.top: parent.top
              anchors.horizontalCenter: parent.horizontalCenter
              width: Style.space(26)
              height: Style.space(2)
              radius: height / 2
              color: root.accentColor
            }

            Text {
              id: targetLabel
              anchors.top: parent.top
              anchors.topMargin: temperatureSlider.visible ? Style.space(9) : Style.space(17)
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.hasLocalTarget ? "SYNCING" : "TARGET"
              color: root.hasLocalTarget ? root.accentColor : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.9

              Behavior on anchors.topMargin { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }
            }

            Row {
              id: targetControlRow
              anchors.top: targetLabel.bottom
              anchors.topMargin: Style.space(1)
              anchors.horizontalCenter: parent.horizontalCenter
              width: implicitWidth
              height: Style.space(38)
              spacing: Style.space(8)

              AcButton {
                id: decreaseTargetButton
                width: Style.space(34)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                iconText: ""
                horizontalPadding: 0
                verticalPadding: 0
                enabled: root.isOn && !root.otherActionBusy
                fontFamily: root.fontFamily
                foreground: root.isOn ? root.accentColor : root.dim
                accent: root.accentColor
                background: root.isOn ? root.alpha(root.accentColor, 0.09) : root.alpha(root.foreground, 0.025)
                bordered: !root.compactChromeEnabled
                tooltipText: "Lower target temperature"
                onClicked: root.adjustTarget(-1)

                OpticalGlyph {
                  anchors.fill: parent
                  text: "−"
                  fontFamily: root.fontFamily
                  fontSize: Style.font.display
                  color: decreaseTargetButton.enabled
                    ? (decreaseTargetButton.hot ? root.foreground : root.accentColor)
                    : root.dim
                }
              }

              Item {
                width: Style.space(86)
                height: parent.height

                Text {
                  anchors.fill: parent
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  text: root.isOn ? root.targetText : "OFF"
                  color: root.isOn ? (root.hasLocalTarget ? root.accentColor : root.foreground) : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: root.temperatureValueFontSize(
                    root.targetText, Style.font.displayLarge)
                  font.bold: true
                }
              }

              AcButton {
                id: increaseTargetButton
                width: Style.space(34)
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                iconText: ""
                horizontalPadding: 0
                verticalPadding: 0
                enabled: root.isOn && !root.otherActionBusy
                fontFamily: root.fontFamily
                foreground: root.isOn ? root.accentColor : root.dim
                accent: root.accentColor
                background: root.isOn ? root.alpha(root.accentColor, 0.09) : root.alpha(root.foreground, 0.025)
                bordered: !root.compactChromeEnabled
                tooltipText: "Raise target temperature"
                onClicked: root.adjustTarget(1)

                OpticalGlyph {
                  anchors.fill: parent
                  text: "+"
                  fontFamily: root.fontFamily
                  fontSize: Style.font.display
                  color: increaseTargetButton.enabled
                    ? (increaseTargetButton.hot ? root.foreground : root.accentColor)
                    : root.dim
                }
              }
            }

            PanelSlider {
              id: temperatureSlider
              visible: root.connected && root.isOn
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.leftMargin: Style.space(14)
              anchors.rightMargin: Style.space(14)
              anchors.bottomMargin: Style.space(6)
              height: Style.space(14)
              value: isFinite(Number(root.targetValue))
                ? root.convertTemperature(root.targetValue, root.unit, root.displayTemperatureUnitCode)
                : root.displayMinimumTemperature
              minimum: root.displayMinimumTemperature
              maximum: root.displayMaximumTemperature
              step: root.displayTemperatureStep
              integer: false
              bar: root.bar
              trackHeight: Style.space(3)
              knobSize: Style.space(12)
              trackColor: root.alpha(root.controlAccentColor, 0.22)
              fillColor: root.controlAccentColor
              knobColor: root.controlAccentColor
              tickCount: 3
              tickColor: root.alpha(root.appearanceBackgroundColor, 0.82)
              onMoved: function(value) { root.previewTarget(value) }
              onReleased: function(value) { root.commitTarget(value) }
            }
          }
        }

        Item {
          id: powerControl
          readonly property int splitPowerRows: Math.max(1, Math.ceil(root.selectedEntities.length / 2))
          width: parent.width
          visible: root.showMainRemote || height > 0.5
          height: root.showMainRemote
            ? (root.splitPowerOnly
              ? splitPowerRows * Style.space(82)
                + Math.max(0, splitPowerRows - 1) * Style.space(8)
              : Style.space(48)) : 0
          opacity: root.showMainRemote ? 1 : 0
          clip: true

          Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

          ClimatePowerControl {
            id: mainPowerControl
            anchors.fill: parent
            visible: !root.splitPowerOnly
            connected: root.connected
            isOn: root.isOn
            powerPending: root.hasLocalPower && !root.powerTimedOut
            localPowerOn: root.localPower
            modePending: root.modeRestarting
            powerCanCancel: root.powerCanCancel
            actionEnabled: root.connected && !root.actionBusy && !root.masterSwitchBusy
            cancelEnabled: root.connected && !root.masterSwitchBusy
            foreground: root.foreground
            accent: root.deviceCardAccent(root.selectedEntity)
            fontFamily: root.fontFamily
            panelRadius: root.compactRadius
            chromeLess: root.compactChromeEnabled
            onPowerRequested: root.togglePower()
            onPowerCancelRequested: root.cancelPower()
          }

          Flow {
            id: splitPowerFlow
            anchors.fill: parent
            spacing: Style.space(8)
            visible: root.splitPowerOnly
            opacity: root.splitPowerOnly ? 1 : 0

            Repeater {
              model: root.selectedEntities

              Item {
                id: splitPowerCard
                required property var modelData
                readonly property string entityId: String(modelData)
                readonly property var climate: root.unitReading(entityId) || ({})
                readonly property var localState: {
                  var revision = root.unitLocalStateRevision
                  return root.unitLocalState(entityId)
                }
                readonly property bool connected: root.connected
                  && climate.entity_id !== undefined
                readonly property bool hasLocalPower: String(localState.power || "") !== ""
                readonly property bool powerPending: hasLocalPower
                  && localState.powerTimedOut !== true
                readonly property bool localPowerOn: String(localState.power || "") === "turning_on"
                readonly property bool actualIsOn: connected
                  && String(climate.state || "").toLowerCase() !== "off"
                readonly property color cardAccent: root.deviceCardAccent(entityId)

                width: Math.max(
                  Style.space(160),
                  (splitPowerFlow.width - splitPowerFlow.spacing) / 2)
                height: Style.space(82)

                BorderSurface {
                  anchors.fill: parent
                  radius: root.compactRadius
                  color: root.surfaceColor(root.alpha(parent.cardAccent,
                    parent.powerPending || parent.localPowerOn || parent.actualIsOn ? 0.075 : 0.035))
                  borderSpec: root.surfaceBorder(Border.flat(root.alpha(parent.cardAccent,
                    parent.powerPending || parent.localPowerOn || parent.actualIsOn ? 0.30 : 0.14), 1))

                  Column {
                    anchors.fill: parent
                    anchors.margins: Style.space(10)
                    spacing: Style.space(5)

                    Row {
                      width: parent.width
                      spacing: Style.space(5)

                      Text {
                        width: Math.max(0,
                          parent.width - splitPowerAmbientText.implicitWidth - parent.spacing)
                        text: root.entityDisplayName(splitPowerCard.entityId)
                        color: splitPowerCard.cardAccent
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        elide: Text.ElideRight
                      }

                      Text {
                        id: splitPowerAmbientText
                        width: implicitWidth
                        text: splitPowerCard.connected
                          ? root.formatTemperatureValue(
                              splitPowerCard.climate.ambient,
                              splitPowerCard.climate.unit || root.unit) : "..."
                        color: root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideRight
                      }
                    }

                    ClimatePowerControl {
                      width: parent.width
                      height: Style.space(36)
                      connected: splitPowerCard.connected
                      isOn: splitPowerCard.hasLocalPower
                        ? splitPowerCard.localPowerOn : splitPowerCard.actualIsOn
                      powerPending: splitPowerCard.powerPending
                      localPowerOn: splitPowerCard.localPowerOn
                      powerCanCancel: splitPowerCard.localState.powerCanCancel === true
                      compact: true
                      actionEnabled: root.connected && !root.actionBusy && !root.masterSwitchBusy
                      cancelEnabled: root.connected && !root.masterSwitchBusy
                      foreground: root.foreground
                      accent: root.deviceCardAccent(splitPowerCard.entityId)
                      fontFamily: root.fontFamily
                      panelRadius: root.compactRadius
                      chromeLess: root.compactChromeEnabled
                      onPowerRequested: function(value) {
                        root.requestUnitPower(splitPowerCard.entityId, value, true)
                      }
                      onPowerCancelRequested: root.cancelUnitPower(splitPowerCard.entityId)
                    }
                  }
                }
              }
            }
          }

        }

        Column {
          id: advancedClimateSection
          width: parent.width
          visible: (root.showMainRemote && root.climateControlsVisible) || height > 0.5
          height: root.showMainRemote && root.climateControlsVisible ? implicitHeight : 0
          enabled: root.showMainRemote && root.climateControlsVisible
          clip: true
          spacing: Style.space(8)
          opacity: root.showMainRemote && root.climateControlsVisible ? 1 : 0

          Behavior on height {
            NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
          }
          Behavior on opacity {
            NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
          }

          BorderSurface {
            width: parent.width
            implicitHeight: advancedClimateForm.implicitHeight + Style.space(28)
            radius: root.panelRadius
            color: root.surfaceColor(root.alpha(root.accentColor, 0.045))
            borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.25), 1))

            Column {
              id: advancedClimateForm
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(14)
              spacing: Style.space(8)

              Row {
                width: parent.width
                spacing: Style.space(9)

                Text {
                  width: Style.space(30)
                  height: Style.space(30)
                  text: root.climateModeIcon(root.activeMode)
                  color: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                }

                Column {
                  width: parent.width - Style.space(39)
                  spacing: Style.space(1)

                  Text {
                    text: "CLIMATE CONTROLS"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.subtitle
                    font.bold: true
                  }

                  Text {
                    width: parent.width
                    text: "Changes preview instantly, then sync with Home Assistant."
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }
                }
              }

              Row {
                width: parent.width
                spacing: Style.space(8)

                AcDropdown {
                  id: modeControl
                  visible: root.modeOptions.length > 0
                  width: root.modeOptions.length > 0
                    ? (root.fanModeOptions.length > 0
                      ? (parent.width - parent.spacing) / 2 : parent.width) : 0
                  label: "MODE"
                  options: root.modeDropdownOptions
                  value: root.activeMode
                  foreground: root.foreground
                  background: root.appearanceBackgroundColor
                  popupBorder: root.appearancePopupBorderColor
                  accent: root.controlAccentColor
                  fontFamily: root.fontFamily
                  controlRadius: root.compactRadius
                  chromeLess: root.compactChromeEnabled
                  enabled: root.connected && (root.isOn || root.localMode !== "")
                    && !root.actionBusy && !root.masterSwitchBusy
                  onChanged: function(value) { root.requestMode(value) }
                }

                AcDropdown {
                  id: fanModeControl
                  visible: root.fanModeOptions.length > 0
                  width: root.fanModeOptions.length > 0
                    ? (root.modeOptions.length > 0
                      ? (parent.width - parent.spacing) / 2 : parent.width) : 0
                  label: "FAN SPEED"
                  options: root.fanModeDropdownOptions
                  value: root.activeFanMode
                  foreground: root.foreground
                  background: root.appearanceBackgroundColor
                  popupBorder: root.appearancePopupBorderColor
                  accent: root.controlAccentColor
                  fontFamily: root.fontFamily
                  controlRadius: root.compactRadius
                  chromeLess: root.compactChromeEnabled
                  enabled: root.connected && root.isOn && !root.actionBusy && !root.masterSwitchBusy
                  onChanged: function(value) { root.requestFanMode(value) }
                }
              }
            }
          }
        }

        BorderSurface {
          id: masterSwitchCard
          readonly property bool masterSwitchVisible: root.masterSwitchEnabled && root.connected
          visible: masterSwitchVisible || height > 0.5
          width: parent.width
          implicitHeight: masterSwitchForm.implicitHeight + Style.space(28)
          height: masterSwitchVisible ? implicitHeight : 0
          opacity: masterSwitchVisible ? 1 : 0
          clip: true
          radius: root.panelRadius
          color: root.surfaceColor(root.alpha(root.foreground, 0.035))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.foreground, 0.16), 1))

          Behavior on height {
            NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
          }
          Behavior on opacity {
            NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
          }

          Column {
            id: masterSwitchForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(14)
            spacing: Style.space(7)

            Text {
              width: parent.width
              text: "MASTERSWITCH"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
            }

            Text {
              width: parent.width
              text: "Control every available Home Assistant climate device at once, including rooms outside the selected AC."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            CriticalActionSplit {
              id: turnOffAllAction
              width: parent.width
              idleText: "TURN OFF ALL ACs"
              busyText: "TURNING OFF…"
              idleIcon: "⏻"
              idleTooltip: "Prepare to turn off every available climate device"
              confirmTooltip: "Turn off every available climate device"
              backTooltip: "Keep the climate devices running"
              actionColor: root.accentColor
              actionTextColor: root.accentTextColor
              idleBackground: root.alpha(root.accentColor, 0.07)
              backTextColor: root.foreground
              backBackground: root.alpha(root.foreground, 0.025)
              controlRadius: root.compactRadius
              chromeLess: root.compactChromeEnabled
              fontFamily: root.fontFamily
              confirming: root.turnOffAllConfirming
              busy: root.turnOffAllBusy
              actionEnabled: !root.masterSwitchBusy && !root.turnOnAllConfirming
                && !actionProcess.running && !statusProcess.running
                && !root.preferenceBusy && !root.setupBusy && !root.localServerBusy
                && !root.resetAppBusy && !configProcess.running && !entitiesProcess.running
              onActionRequested: root.confirmTurnOffAll()
              onBackRequested: root.cancelTurnOffAll()
            }

            CriticalActionSplit {
              id: turnOnAllAction
              width: parent.width
              idleText: "TURN ON ALL ACs"
              busyText: "TURNING ON…"
              idleIcon: "⏻"
              idleTooltip: "Prepare to turn on every available climate device"
              confirmTooltip: "Turn on every available climate device"
              backTooltip: "Keep the climate devices off"
              actionColor: root.urgent
              actionTextColor: root.contrastingTextColor(root.urgent)
              idleBackground: root.alpha(root.urgent, 0.07)
              backTextColor: root.foreground
              backBackground: root.alpha(root.foreground, 0.025)
              controlRadius: root.compactRadius
              chromeLess: root.compactChromeEnabled
              fontFamily: root.fontFamily
              confirming: root.turnOnAllConfirming
              busy: root.turnOnAllBusy
              actionEnabled: !root.masterSwitchBusy && !root.turnOffAllConfirming
                && !actionProcess.running && !statusProcess.running
                && !root.preferenceBusy && !root.setupBusy && !root.localServerBusy
                && !root.resetAppBusy && !configProcess.running && !entitiesProcess.running
              onActionRequested: root.confirmTurnOnAll()
              onBackRequested: root.cancelTurnOnAll()
            }

            BorderSurface {
              readonly property bool hasMasterSwitchStatus: root.turnOffAllMessage !== ""
                || root.turnOffAllError !== "" || root.turnOnAllMessage !== ""
                || root.turnOnAllError !== ""
              visible: hasMasterSwitchStatus || height > 0.5
              width: parent.width
              implicitHeight: masterSwitchStatus.implicitHeight + Style.space(18)
              height: hasMasterSwitchStatus ? implicitHeight : 0
              opacity: hasMasterSwitchStatus ? 1 : 0
              clip: true
              color: root.surfaceColor(root.alpha(
                root.turnOffAllError !== "" || root.turnOnAllError !== ""
                  ? root.urgent : root.accentColor,
                0.09))
                  borderSpec: root.surfaceBorder(Border.flat(root.alpha(
                    root.turnOffAllError !== "" || root.turnOnAllError !== ""
                      ? root.urgent : root.accentColor,
                    0.32), 1))
              radius: root.compactRadius

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Text {
                id: masterSwitchStatus
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: root.turnOffAllError !== "" ? root.turnOffAllError
                  : root.turnOnAllError !== "" ? root.turnOnAllError
                  : root.turnOffAllMessage !== "" ? root.turnOffAllMessage
                  : root.turnOnAllMessage
                color: root.turnOffAllError !== "" || root.turnOnAllError !== ""
                  ? root.urgent : root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }
        }

        TemperatureHistoryChart {
          id: temperatureHistoryChart
          width: parent.width
          visible: root.historyChartVisible || height > 0.5
          height: root.historyChartVisible ? implicitHeight : 0
          opacity: root.historyChartVisible ? 1 : 0
          enabled: root.historyChartVisible
          clip: true
          points: root.historyChartPoints
          rangeHours: root.historyHours
          windowEndTimestamp: root.historyChartWindowEnd
          unit: root.displayTemperatureUnit
          connected: root.connected
          showLiveIndicator: root.historySource === "server"
          sourceLabel: root.historySourceLabel
          emptyMessage: root.historyEmptyMessage
          foreground: root.foreground
          accent: root.accentColor
          stale: root.historyLogStale
          warningColor: root.warning
          background: root.customAppearanceEnabled
            ? root.panelSurface : root.alpha(root.foreground, 0.035)
          borderColor: root.customAppearanceEnabled
            ? root.alpha(root.accentColor, 0.24)
            : root.alpha(root.foreground, 0.14)
          fontFamily: root.fontFamily
          panelRadius: root.uiRadius
          chromeLess: root.compactChromeEnabled

          Behavior on height {
            NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
          }
          Behavior on opacity {
            NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
          }
        }

        BorderSurface {
          visible: root.errorText !== "" || height > 0.5
          width: parent.width
          implicitHeight: errorLabel.implicitHeight + Style.space(20)
          height: root.errorText !== "" ? implicitHeight : 0
          opacity: root.errorText !== "" ? 1 : 0
          clip: true
          color: root.surfaceColor(root.alpha(root.urgent, 0.10))
          borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.urgent, 0.35), 1))
          radius: root.panelRadius

          Behavior on height {
            NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
          }
          Behavior on opacity {
            NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
          }

          Text {
            id: errorLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            text: root.errorText
            color: root.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
        }

      }
      }

        Item {
          id: setupTransitionOverlay
          anchors.fill: parent
          z: 20
          visible: root.setupTransitioning || opacity > 0.01
          opacity: root.setupTransitioning ? 1 : 0
          scale: root.setupTransitioning ? 1 : 0.975
          transformOrigin: Item.Center

          Behavior on opacity {
            NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
          }
          Behavior on scale {
            NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
          }

          BorderSurface {
            anchors.fill: parent
            color: root.surfaceColor(root.alpha(root.appearanceBackgroundColor, 0.985))
            borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.26), 1))
            radius: root.panelRadius

            Rectangle {
              anchors.top: parent.top
              anchors.horizontalCenter: parent.horizontalCenter
              width: root.setupTransitionClosing ? Style.space(124) : Style.space(164)
              height: Style.space(2)
              radius: height / 2
              color: root.alpha(root.accentColor, 0.82)

              Behavior on width {
                NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
              }
            }
          }

          BorderSurface {
            id: setupSplashCard
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
              + (root.setupTransitionClosing ? Style.space(4) : -Style.space(4))
            width: Math.min(parent.width - Style.space(24), Style.space(320))
            height: Style.space(148)
            scale: root.setupTransitioning ? 1 : 0.94
            opacity: root.setupTransitioning ? 1 : 0
            transformOrigin: Item.Center
            radius: root.nestedRadius
            color: root.surfaceColor(root.alpha(root.accentColor, 0.075))
            gradient: Gradient {
              GradientStop { position: 0.0; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.accentColor, 0.19) }
              GradientStop { position: 1.0; color: root.compactChromeEnabled ? "transparent" : root.alpha(root.accentColor, 0.035) }
            }
            borderSpec: root.surfaceBorder(Border.flat(root.alpha(root.accentColor, 0.44), 1))

            Behavior on y {
              NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
              NumberAnimation { duration: root.motionSplash; easing.type: Easing.OutBack }
            }
            Behavior on opacity {
              NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
            }

            Rectangle {
              anchors.top: parent.top
              anchors.horizontalCenter: parent.horizontalCenter
              width: root.setupTransitionClosing ? Style.space(106) : Style.space(142)
              height: Style.space(2)
              radius: height / 2
              color: root.accentColor

              Behavior on width {
                NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
              }
            }

            Column {
              anchors.centerIn: parent
              width: parent.width - Style.space(36)
              spacing: Style.space(6)

              Item {
                width: Style.space(54)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                  anchors.centerIn: parent
                  width: Style.space(52)
                  height: width
                  radius: width / 2
                  color: root.accentColor
                  opacity: root.setupTransitioning ? 0.13 : 0
                  scale: root.setupTransitioning
                    ? (root.setupTransitionClosing ? 1.08 : 1.25) : 0.68

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on scale {
                    NumberAnimation { duration: root.motionSplash; easing.type: Easing.OutBack }
                  }
                }

                Rectangle {
                  anchors.centerIn: parent
                  width: Style.space(44)
                  height: width
                  radius: width / 2
                  color: "transparent"
                  border.color: root.alpha(root.accentColor, 0.48)
                  border.width: 1
                  opacity: root.setupTransitioning ? 0.72 : 0
                  scale: root.setupTransitioning ? 1 : 0.74

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on scale {
                    NumberAnimation { duration: root.motionSplash; easing.type: Easing.OutBack }
                  }
                }

                Text {
                  id: setupSplashGear
                  anchors.fill: parent
                  text: "󰒓"
                  color: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  opacity: root.setupTransitionClosing ? 0 : 1
                  scale: root.setupTransitionClosing ? 0.84 : 1

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on scale {
                    NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                  }

                  RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1050
                    loops: Animation.Infinite
                    running: root.setupTransitioning && !root.setupTransitionClosing
                  }
                }

                Text {
                  anchors.fill: parent
                  text: "←"
                  color: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.display
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  opacity: root.setupTransitionClosing ? 1 : 0
                  scale: root.setupTransitionClosing ? 1 : 0.84

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on scale {
                    NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                  }
                }
              }

              Item {
                width: parent.width
                implicitHeight: Math.max(setupSettingsTitle.implicitHeight, setupBackTitle.implicitHeight)
                height: implicitHeight

                Text {
                  id: setupSettingsTitle
                  anchors.fill: parent
                  text: "CONNECTION SETTINGS"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  opacity: root.setupTransitionClosing ? 0 : 1
                  scale: root.setupTransitionClosing ? 0.96 : 1

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on scale {
                    NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                  }
                }

                Text {
                  id: setupBackTitle
                  anchors.fill: parent
                  text: "BACK TO CONTROLS"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  opacity: root.setupTransitionClosing ? 1 : 0
                  scale: root.setupTransitionClosing ? 1 : 0.96

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                  Behavior on scale {
                    NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
                  }
                }
              }

              Item {
                width: parent.width
                implicitHeight: Math.max(setupSettingsSubtitle.implicitHeight, setupBackSubtitle.implicitHeight)
                height: implicitHeight

                Text {
                  id: setupSettingsSubtitle
                  anchors.fill: parent
                  text: "Preparing a fresh Home Assistant connection."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  wrapMode: Text.WordWrap
                  opacity: root.setupTransitionClosing ? 0 : 1

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                }

                Text {
                  id: setupBackSubtitle
                  anchors.fill: parent
                  text: "Returning to your AC controls."
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  wrapMode: Text.WordWrap
                  opacity: root.setupTransitionClosing ? 1 : 0

                  Behavior on opacity {
                    NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                  }
                }
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            z: 10
            enabled: root.setupTransitioning
            acceptedButtons: Qt.AllButtons
          }
        }

      }
    }
  }
