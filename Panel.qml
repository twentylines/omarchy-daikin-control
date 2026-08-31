import QtQuick
import QtQuick.Controls
import Quickshell
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
  property string barTemperatureMode: "average"
  property string barTemperatureModePrevious: "average"
  property string barTemperatureEntity: ""
  property string barTemperatureEntityPrevious: ""
  property var barTemperatureEntities: []
  property var barTemperatureEntitiesPrevious: []
  property bool experimentalHistoryEnabled: false
  property bool experimentalHistoryEnabledPrevious: false
  property bool customAppearanceEnabled: false
  property bool customAppearanceEnabledPrevious: false
  property color customAccentColor: "#8FA79F"
  property color customAccentColorPrevious: "#8FA79F"
  property string customAccentHexText: "#8FA79F"
  property string customAccentHexTextPrevious: "#8FA79F"
  property real appearanceTransparency: 0
  property real appearanceTransparencyPrevious: 0
  property string appearanceTransparencyText: "0"
  property real appearanceBlur: 0
  property real appearanceBlurPrevious: 0
  property string appearanceBlurText: "0"
  property real appearanceRadius: 16
  property real appearanceRadiusPrevious: 16
  property string appearanceRadiusText: "16"
  readonly property color accentColor: customAppearanceEnabled ? customAccentColor : Color.accent
  readonly property real appearanceSurfaceOpacity: customAppearanceEnabled
    ? Math.max(0.30, 1 - appearanceTransparency / 100) : 1
  readonly property real appearanceSoftness: customAppearanceEnabled
    ? Math.max(0, Math.min(1, appearanceBlur / 24)) : 0
  readonly property real panelRadius: customAppearanceEnabled
    ? appearanceRadius : Style.cornerRadius
  readonly property real nestedRadius: Math.max(0, panelRadius - Style.space(2))
  readonly property real compactRadius: panelRadius > 0
    ? Math.max(Style.space(6), panelRadius - Style.space(4)) : 0
  readonly property int motionFast: 140
  readonly property int motionStandard: 220
  readonly property int motionEmphasis: 300
  readonly property int motionSplash: 520
  readonly property color panelSurface: Qt.rgba(
    Color.popups.background.r, Color.popups.background.g, Color.popups.background.b,
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
  property string powerReadbackMarker: ""
  property bool powerFinalCheckPending: false
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
  property bool localServerBusy: false
  property bool localServerConfirming: false
  property bool localServerReady: false
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
  property bool advancedControls: true
  property bool masterSwitchEnabled: false
  property bool masterSwitchEnabledPrevious: false
  property bool preferenceBusy: false
  property string preferenceKind: ""
  property bool advancedControlsPrevious: true
  property string temperatureDisplay: "both"
  property string temperatureDisplayPrevious: "both"
  property bool historyEnabled: false
  property bool historyEnabledPrevious: false
  property real historyHours: 24
  property real historyHoursPrevious: 24
  property bool historyCustom: false
  property bool historyCustomPrevious: false
  property string customHistoryHoursText: "24"
  property string historySource: "local"
  property string historySourcePrevious: "local"
  property string remoteHistoryTarget: ""
  property string remoteHistoryPortText: "22"
  property string remoteHistoryUrl: "http://127.0.0.1:8123"
  property string remoteHistoryPath: "~/.local/state/omarchy/homeassistant-ac-temperature.json"
  property bool remoteHistoryBusy: false
  property bool remoteHistorySourceBusy: false
  property string remoteHistorySourcePayload: ""
  property bool remoteHistoryInstallSucceeded: false
  property bool remoteHistoryReconfiguring: false
  property string remoteHistoryMessage: ""
  property string remoteHistoryError: ""
  property string remoteHistoryPayload: ""
  property string settingsSection: "preferences"
  property bool setupSucceeded: false
  property string setupUrl: "http://homeassistant.local:8123"
  property string setupToken: ""
  property string setupError: ""
  property string setupPayload: ""
  property string selectionPayload: ""
  property string setupSelectedEntity: ""
  property var setupEntityOptions: []

  function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }

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
    { value: "setup", label: "SETUP" },
    { value: "preferences", label: "PREFERENCES" },
    { value: "experimental", label: "EXPERIMENTAL" },
    { value: "maintenance", label: "MAINTENANCE" },
  ]
  readonly property bool setupCanSubmit: !setupBusy
    && !preferenceBusy
    && !localServerBusy
    && !remoteHistoryBusy
    && !remoteHistorySourceBusy
    && !resetAppBusy
    && !uninstallBusy
    && !masterSwitchBusy
    && String(setupUrl || "").trim() !== ""
    && String(setupToken || "").trim() !== ""
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
  readonly property bool remoteHistoryPaired: historySource === "server"
    && String(remoteHistoryTarget || "").trim() !== ""
  readonly property bool barIsOn: connected && multiUnitActive
    ? anyUnitOn() : isOn
  readonly property bool actualIsOn: connected && String(reading.state || "").toLowerCase() !== "off"
  readonly property bool hasLocalPower: pendingPowerState !== ""
  readonly property bool localPower: pendingPowerState === "turning_on"
  readonly property bool isOn: connected
    && (hasLocalPower ? localPower : (actualIsOn || modeRestarting))
  readonly property string unit: connected ? String(reading.unit || "°C") : "°C"
  readonly property string ambientText: connected ? temperature(reading.ambient) : "..."
  readonly property string barAmbientText: connected ? formatBarAmbient() : "..."
  readonly property bool hasLocalTarget: localTarget !== null && isFinite(Number(localTarget))
  readonly property var targetValue: hasLocalTarget ? Number(localTarget) : reading.target
  readonly property string targetText: connected ? temperature(targetValue) : "..."
  readonly property bool masterSwitchBusy: turnOffAllBusy || turnOnAllBusy
  readonly property bool masterSwitchConfirming: turnOffAllConfirming || turnOnAllConfirming
  readonly property bool otherActionBusy: masterSwitchBusy
    || (actionProcess.running && actionKind !== "temperature")
  readonly property string activeMode: localMode !== "" ? localMode : String(reading.state || "")
  readonly property string activeFanMode: localFanMode !== ""
    ? localFanMode : String(reading.fan_mode || "")
  readonly property var modeOptions: formatControlOptions(reading.hvac_modes, true)
  readonly property var fanModeOptions: formatControlOptions(reading.fan_modes, false)
  readonly property bool advancedControlsVisible: advancedControls && connected
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
  readonly property var historyPoints: {
    var next = []
    if (!connected || !Array.isArray(reading.history)) return next
    var cutoff = Date.now() / 1000 - Number(historyHours) * 60 * 60
    for (var i = 0; i < reading.history.length; i++) {
      var item = reading.history[i]
      if (!item || !isFinite(Number(item.timestamp)) || !isFinite(Number(item.temperature))) continue
      if (Number(item.timestamp) >= cutoff) {
        next.push({
          timestamp: Number(item.timestamp),
          temperature: Number(item.temperature),
          unit: String(item.unit || unit),
        })
      }
    }
    next.sort(function(first, second) { return first.timestamp - second.timestamp })
    return next
  }
  readonly property string historyHoursLabel: formatHours(historyHours) + " H"
  readonly property string historyServerLabel: {
    var target = String(remoteHistoryTarget || "").trim()
    if (target === "") return "NOT CONFIGURED"
    var at = target.lastIndexOf("@")
    return at >= 0 ? target.slice(at + 1) : target
  }
  readonly property string historySourceLabel: historySource === "server"
    ? "EXTERNAL · " + historyServerLabel : "LOCAL · LOGGED WHILE PC IS ON"
  readonly property string historyEmptyMessage: historySource === "server"
    ? (String(reading.history_error || "") !== "" ? "EXTERNAL LOG UNAVAILABLE" : "WAITING FOR EXTERNAL LOG…")
    : "WAITING FOR LOCAL READINGS…"
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

  function formatTemperatureValue(value, displayUnit) {
    var parsed = Number(value)
    if (!isFinite(parsed)) return "..."
    var rounded = Math.round(parsed * 10) / 10
    return String(rounded).replace(/\.0$/, "") + String(displayUnit || unit)
  }

  function temperature(value) {
    return formatTemperatureValue(value, unit)
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
  }

  function hasPendingUnitPower() {
    var current = unitLocalStates || ({})
    for (var id in current) {
      if (current[id] && String(current[id].power || "") !== "") return true
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
      if (!state || !state.power || state.powerFinalCheckPending === true) continue
      var startedAt = Number(state.powerStartedAt)
      if (isFinite(startedAt) && now - startedAt >= 15000) {
        state.powerFinalCheckPending = true
        changed = true
      }
    }
    if (!changed || !root.refreshStatus()) return false
    unitLocalStates = next
    unitLocalStateRevision += 1
    return true
  }

  function failUnitPowerFinalChecks() {
    var next = root.copyUnitLocalStates()
    var changed = false
    for (var id in next) {
      var state = next[id]
      if (!state || state.powerFinalCheckPending !== true) continue
      delete state.power
      delete state.powerStartedAt
      delete state.powerReadbackMarker
      delete state.powerFinalCheckPending
      delete state.powerCanCancel
      changed = true
      var hasValues = false
      for (var key in state) {
        hasValues = true
        break
      }
      if (!hasValues) delete next[id]
    }
    if (changed) {
      unitLocalStates = next
      unitLocalStateRevision += 1
    }
    return changed
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
          if (observedOn === requestedOn && readbackIsFresh) {
            delete state.power
            delete state.powerStartedAt
            delete state.powerReadbackMarker
            delete state.powerFinalCheckPending
            delete state.powerCanCancel
          } else if (state.powerFinalCheckPending === true) {
            delete state.power
            delete state.powerStartedAt
            delete state.powerReadbackMarker
            delete state.powerFinalCheckPending
            delete state.powerCanCancel
            if (message === "") {
              message = "Home Assistant still reports " + root.entityDisplayName(id)
                + " as " + (observedOn ? "on" : "off") + "."
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
      root.setUnitLocalStateValue(id, "power", null)
      root.setUnitLocalStateValue(id, "powerStartedAt", null)
      root.setUnitLocalStateValue(id, "powerReadbackMarker", null)
      root.setUnitLocalStateValue(id, "powerFinalCheckPending", null)
      root.setUnitLocalStateValue(id, "powerCanCancel", null)
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
      if (String(unitReadings[i].state || "").toLowerCase() !== "off") return true
    }
    return false
  }

  function formatBarAmbient() {
    var readings = []
    var all = unitReadings.length > 0 ? unitReadings : [reading]
    var mode = String(barTemperatureMode || "average")
    if (mode === "single") {
      var single = unitReading(barTemperatureEntity)
      if (single) readings = [single]
      else if (all.length > 0) readings = [all[0]]
    } else if (mode === "selected") {
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
      if (count > 0 && sameUnits) return formatTemperatureValue(sum / count, firstUnit)
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
    powerReadbackMarker = ""
    powerFinalCheckPending = false
    powerCanCancel = false
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
    selectedEntities = normalizeSelectedEntities(parsed.selected_entities, selectedEntity)
    var parsedBarMode = String(parsed.bar_temperature_mode || "average")
    barTemperatureMode = ["average", "all", "single", "selected"].indexOf(parsedBarMode) >= 0
      ? parsedBarMode : "average"
    barTemperatureModePrevious = barTemperatureMode
    barTemperatureEntity = String(parsed.bar_temperature_entity || "")
    barTemperatureEntityPrevious = barTemperatureEntity
    barTemperatureEntities = normalizeSelectedEntities(
      parsed.bar_temperature_entities, selectedEntities.length > 0 ? selectedEntities : selectedEntity)
    barTemperatureEntitiesPrevious = barTemperatureEntities.slice()
    experimentalHistoryEnabled = parsed.experimental_history_enabled === true
    experimentalHistoryEnabledPrevious = experimentalHistoryEnabled
    customAppearanceEnabled = parsed.custom_appearance_enabled === true
    customAppearanceEnabledPrevious = customAppearanceEnabled
    customAccentHexText = String(parsed.appearance_accent || "#8FA79F")
    customAccentHexTextPrevious = customAccentHexText
    customAccentColor = customAccentHexText
    customAccentColorPrevious = customAccentColor
    appearanceTransparency = Math.max(0, Math.min(70, Number(parsed.appearance_transparency) || 0))
    appearanceTransparencyPrevious = appearanceTransparency
    appearanceTransparencyText = formatAppearanceValue(appearanceTransparency)
    appearanceBlur = Math.max(0, Math.min(24, Number(parsed.appearance_blur) || 0))
    appearanceBlurPrevious = appearanceBlur
    appearanceBlurText = formatAppearanceValue(appearanceBlur)
    appearanceRadius = Math.max(8, Math.min(32, Number(parsed.appearance_radius) || 16))
    appearanceRadiusPrevious = appearanceRadius
    appearanceRadiusText = formatAppearanceValue(appearanceRadius)
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
        || turnOffAllProcess.running || turnOnAllProcess.running) return false
    statusProcess.command = ["python3", root.helperPath, "status"]
    statusProcess.running = true
    return true
  }

  function loadConfig() {
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

  function openSetup() {
    if (setupProcess.running || setupTransitioning) return
    localServerConfirmTimer.stop()
    localServerConfirming = false
    setupError = ""
    setupEntityOptions = []
    setupSelectedEntity = ""
    setupToken = ""
    if (root.configured) settingsSection = "preferences"
    if (setupUrl === "") setupUrl = "http://homeassistant.local:8123"
    if (root.configured && root.opened) {
      setupTransitionClosing = false
      setupTransitioning = true
      setupOpen = false
      setupTransitionTimer.restart()
    } else {
      setupTransitionClosing = false
      setupOpen = true
      Qt.callLater(function() { setupUrlField.forceActiveFocus() })
    }
  }

  function cancelSetup() {
    setupTransitionTimer.stop()
    setupTransitionFinishTimer.stop()
    localServerConfirmTimer.stop()
    localServerConfirming = false
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

  function submitSetup() {
    if (!root.setupCanSubmit) return
    setupError = ""
    setupSucceeded = false
    setupPayload = JSON.stringify({
      url: String(setupUrl || "").trim(),
      token: String(setupToken || "").trim(),
      entity_id: setupSelectedEntity,
      advanced_controls: root.advancedControls,
      master_switch_enabled: root.masterSwitchEnabled,
    })
    setupBusy = true
    setupProcess.command = ["python3", root.helperPath, "configure"]
    setupProcess.running = true
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
    var url = String(setupUrl || "").trim()
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
    remoteHistoryInstallSucceeded = false
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

  function applyRemoteHistoryResult(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      remoteHistoryError = "The server history installer returned no data."
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
        remoteHistoryError = ""
        remoteHistoryMessage = String(parsed.message || "Server history logger installed.")
        remoteHistoryInstallSucceeded = true
        remoteHistoryReconfiguring = false
        return
      }
      remoteHistoryInstallSucceeded = false
      remoteHistoryMessage = ""
      remoteHistoryError = parsed && parsed.error
        ? String(parsed.error) : "The server history installer could not complete."
    } catch (e) {
      remoteHistoryInstallSucceeded = false
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
        setupUrl = "http://homeassistant.local:8123"
        setupToken = ""
        setupError = ""
        setupEntityOptions = []
        setupSelectedEntity = ""
        localServerReady = false
        localServerConfirming = false
        localServerMessage = ""
        localServerError = ""
        advancedControls = true
        advancedControlsPrevious = true
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
        selectedEntities = []
        barTemperatureMode = "average"
        barTemperatureModePrevious = "average"
        barTemperatureEntity = ""
        barTemperatureEntityPrevious = ""
        barTemperatureEntities = []
        barTemperatureEntitiesPrevious = []
        experimentalHistoryEnabled = false
        experimentalHistoryEnabledPrevious = false
        customAppearanceEnabled = false
        customAppearanceEnabledPrevious = false
        customAccentColor = "#8FA79F"
        customAccentColorPrevious = "#8FA79F"
        customAccentHexText = "#8FA79F"
        customAccentHexTextPrevious = "#8FA79F"
        appearanceTransparency = 0
        appearanceTransparencyPrevious = 0
        appearanceTransparencyText = "0"
        appearanceBlur = 0
        appearanceBlurPrevious = 0
        appearanceBlurText = "0"
        appearanceRadius = 16
        appearanceRadiusPrevious = 16
        appearanceRadiusText = "16"
        remoteHistoryTarget = ""
        remoteHistoryPortText = "22"
        remoteHistoryUrl = root.remoteHistoryDefaultUrl
        remoteHistoryPath = root.remoteHistoryDefaultPath
        remoteHistoryMessage = ""
        remoteHistoryError = ""
        settingsSection = "setup"
        resetAppConfirming = false
        resetAppError = ""
        resetAppMessage = "Daikin AC Controls was reset. Home Assistant was not changed."
        Qt.callLater(function() { setupUrlField.forceActiveFocus() })
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
      advancedControls = parsed.advanced_controls !== undefined
        ? parsed.advanced_controls === true : true
      advancedControlsPrevious = advancedControls
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
      if (parsed.url) setupUrl = String(parsed.url)
      if (parsed.entity_id) {
        selectedEntity = String(parsed.entity_id)
        setupSelectedEntity = selectedEntity
      }
      root.applyExperimentalValues(parsed)
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
        setupOpen = false
        setupError = ""
        setupToken = ""
        setupEntityOptions = []
        if (parsed.url) setupUrl = String(parsed.url)
        if (parsed.entity_id) {
          selectedEntity = String(parsed.entity_id)
          setupSelectedEntity = selectedEntity
        }
        if (parsed.entities) setEntityOptions(parsed.entities)
        root.applyExperimentalValues(parsed)
        if (parsed.advanced_controls !== undefined) {
          advancedControls = parsed.advanced_controls === true
          advancedControlsPrevious = advancedControls
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
      if (source === "action" && hasLocalPower) {
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
      if (source === "status" && powerFinalCheckPending) {
        root.clearLocalPower()
        errorText = "Could not refresh Home Assistant after 15 seconds; showing the last known state."
        return
      }
      if (source === "status" && root.hasPendingUnitPowerFinalCheck()) {
        root.failUnitPowerFinalChecks()
        errorText = "Could not refresh Home Assistant after 15 seconds; showing the last known AC states."
        return
      }
      errorText = "The control helper returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.configured === false && parsed.ok !== true) {
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
        selectedEntity = String(parsed.entity_id || selectedEntity)
        unitReadings = Array.isArray(parsed.units) && parsed.units.length > 0
          ? parsed.units : [parsed]
        if (Array.isArray(parsed.selected_entities))
          selectedEntities = root.normalizeSelectedEntities(parsed.selected_entities, selectedEntity)
        pendingEntity = ""
        if (source === "status" && hasLocalPower && !actionProcess.running
            && parsed.state !== undefined) {
          var observedOn = String(parsed.state || "").toLowerCase() !== "off"
          var requestedOn = localPower
          var readbackMarker = root.powerMarker(parsed)
          var readbackIsFresh = powerReadbackMarker !== ""
            && readbackMarker !== "" && readbackMarker !== powerReadbackMarker
          if (observedOn === requestedOn && readbackIsFresh) {
            root.clearLocalPower()
            errorText = ""
            return
          }
          if (powerFinalCheckPending) {
            root.clearLocalPower()
            errorText = "Home Assistant still reports the air conditioner as "
              + (observedOn ? "on" : "off") + " after 15 seconds."
            return
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
        errorText = ""
        var unitError = root.reconcileUnitLocalStates()
        if (unitError !== "") errorText = unitError
      } else {
        if (source === "action" && hasLocalPower) {
          errorText = ""
          return
        }
        if (source === "action" && actionKind === "unit-power"
            && queuedUnitPowerEntityId !== "") {
          errorText = ""
          return
        }
        if (source === "status" && powerFinalCheckPending) {
          var finalStatusError = parsed && parsed.error ? String(parsed.error)
            : "Home Assistant status could not be refreshed"
          root.clearLocalPower()
          errorText = finalStatusError + "; showing the last known state."
          return
        }
        if (source === "status" && root.hasPendingUnitPowerFinalCheck()) {
          var unitFinalStatusError = parsed && parsed.error ? String(parsed.error)
            : "Home Assistant status could not be refreshed"
          root.failUnitPowerFinalChecks()
          errorText = unitFinalStatusError + "; showing the last known AC states."
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
      if (source === "action" && hasLocalPower) {
        errorText = ""
        return
      }
      if (source === "action" && actionKind === "unit-power"
          && queuedUnitPowerEntityId !== "") {
        errorText = ""
        return
      }
      if (source === "status" && powerFinalCheckPending) {
        root.clearLocalPower()
        errorText = "Home Assistant returned invalid status data; showing the last known state."
        return
      }
      if (source === "status" && root.hasPendingUnitPowerFinalCheck()) {
        root.failUnitPowerFinalChecks()
        errorText = "Home Assistant returned invalid status data; showing the last known AC states."
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

  function requestUnitPower(entityId, requestedPower, cancellable) {
    if (masterSwitchBusy) return
    var id = String(entityId || "")
    var climate = unitReading(id)
    if (!climate) return
    var requested = String(requestedPower || "").toLowerCase()
    if (["on", "off"].indexOf(requested) < 0) return
    root.setUnitLocalStateValue(id, "power",
      requested === "on" ? "turning_on" : "turning_off")
    root.setUnitLocalStateValue(id, "powerStartedAt", Date.now())
    root.setUnitLocalStateValue(id, "powerReadbackMarker", root.powerMarker(climate))
    root.setUnitLocalStateValue(id, "powerFinalCheckPending", false)
    root.setUnitLocalStateValue(id, "powerCanCancel", cancellable !== false)
    errorText = ""
    if (actionProcess.running) {
      queuedUnitPowerEntityId = id
      queuedUnitPowerRequest = requested
      return
    }
    root.dispatchUnitPowerRequest(id, requested)
  }

  function dispatchUnitPowerRequest(entityId, requestedPower) {
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
    if (masterSwitchBusy || !state.power || state.powerCanCancel !== true) return
    root.requestUnitPower(id, state.power === "turning_on" ? "off" : "on", false)
  }

  function setAdvancedControlsEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === advancedControls) return
    advancedControlsPrevious = advancedControls
    advancedControls = next
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

  function setBarTemperatureMode(value) {
    if (preferenceProcess.running) return
    var next = String(value || "").toLowerCase()
    if (["average", "all", "single", "selected"].indexOf(next) < 0
        || next === barTemperatureMode) return
    barTemperatureModePrevious = barTemperatureMode
    barTemperatureMode = next
    root.beginPreference("bar_temperature_mode", next)
  }

  function setBarTemperatureEntity(value) {
    if (preferenceProcess.running) return
    var next = String(value || "")
    if (next === barTemperatureEntity) return
    barTemperatureEntityPrevious = barTemperatureEntity
    barTemperatureEntity = next
    root.beginPreference("bar_temperature_entity", next)
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

  function setCustomAppearanceEnabled(value) {
    if (preferenceProcess.running) return
    var next = value === true
    if (next === customAppearanceEnabled) return
    customAppearanceEnabledPrevious = customAppearanceEnabled
    customAppearanceEnabled = next
    root.beginPreference("custom_appearance_enabled", next ? "on" : "off")
  }

  function setAppearanceHex(value) {
    if (preferenceProcess.running) return
    var next = String(value || "").trim().toUpperCase()
    if (!/^#[0-9A-F]{6}$/.test(next)) {
      errorText = "Use a six-digit hex color such as #8FA79F."
      return
    }
    customAccentHexTextPrevious = customAccentHexText
    customAccentColorPrevious = customAccentColor
    customAccentHexText = next
    customAccentColor = next
    root.beginPreference("appearance_accent", next)
  }

  function setAppearanceNumber(name, value) {
    if (preferenceProcess.running) return
    var limits = {
      appearance_transparency: [0, 70],
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
    if (kind === "advanced_controls") advancedControls = advancedControlsPrevious
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
    else if (kind === "bar_temperature_mode") barTemperatureMode = barTemperatureModePrevious
    else if (kind === "bar_temperature_entity") barTemperatureEntity = barTemperatureEntityPrevious
    else if (kind === "bar_temperature_entities") barTemperatureEntities = barTemperatureEntitiesPrevious.slice()
    else if (kind === "experimental_history_enabled")
      experimentalHistoryEnabled = experimentalHistoryEnabledPrevious
    else if (kind === "custom_appearance_enabled") customAppearanceEnabled = customAppearanceEnabledPrevious
    else if (kind === "appearance_accent") {
      customAccentHexText = customAccentHexTextPrevious
      customAccentColor = customAccentColorPrevious
    } else if (kind === "appearance_transparency") {
      appearanceTransparency = appearanceTransparencyPrevious
      appearanceTransparencyText = formatAppearanceValue(appearanceTransparency)
    } else if (kind === "appearance_blur") {
      appearanceBlur = appearanceBlurPrevious
      appearanceBlurText = formatAppearanceValue(appearanceBlur)
    } else if (kind === "appearance_radius") {
      appearanceRadius = appearanceRadiusPrevious
      appearanceRadiusText = formatAppearanceValue(appearanceRadius)
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
    } else if (name === "bar_temperature_mode") {
      barTemperatureMode = String(value || "average")
      barTemperatureModePrevious = barTemperatureMode
    } else if (name === "bar_temperature_entity") {
      barTemperatureEntity = String(value || "")
      barTemperatureEntityPrevious = barTemperatureEntity
    } else if (name === "bar_temperature_entities") {
      barTemperatureEntities = normalizeSelectedEntities(value, selectedEntity)
      barTemperatureEntitiesPrevious = barTemperatureEntities.slice()
    } else if (name === "experimental_history_enabled") {
      experimentalHistoryEnabled = value === true
      experimentalHistoryEnabledPrevious = experimentalHistoryEnabled
    } else if (name === "custom_appearance_enabled") {
      customAppearanceEnabled = value === true
      customAppearanceEnabledPrevious = customAppearanceEnabled
    } else if (name === "appearance_accent") {
      customAccentHexText = String(value || customAccentHexText)
      customAccentColor = customAccentHexText
      customAccentHexTextPrevious = customAccentHexText
      customAccentColorPrevious = customAccentColor
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
        if (parsed.preference === "advanced_controls" && parsed.value !== undefined) {
          advancedControls = parsed.value === true
          advancedControlsPrevious = advancedControls
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
    var next = normalizeTarget(Number(targetValue) + direction * temperatureStep)
    if (next === null) return
    localTarget = next
    temperatureCommitTimer.restart()
  }

  function previewTarget(value) {
    if (masterSwitchBusy || !connected || !isOn) return
    var next = normalizeTarget(value)
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

  function requestPower(requestedPower, cancellable) {
    pendingPowerState = requestedPower === "on" ? "turning_on" : "turning_off"
    powerRequestStartedAt = Date.now()
    powerReadbackMarker = root.powerMarker(reading)
    powerFinalCheckPending = false
    powerCanCancel = cancellable
    errorText = ""
    if (actionProcess.running) {
      queuedPowerRequest = requestedPower
      return
    }
    root.dispatchPowerRequest(requestedPower)
  }

  function dispatchPowerRequest(requestedPower) {
    actionEntityId = ""
    actionKind = "power"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-power", requestedPower]
    actionProcess.running = true
  }

  function togglePower() {
    if (masterSwitchBusy || actionProcess.running || !connected || hasLocalPower || modeRestarting) return
    root.requestPower(isOn ? "off" : "on", true)
  }

  function cancelPower() {
    if (masterSwitchBusy || !connected || !hasLocalPower || !powerCanCancel) return
    root.requestPower(localPower ? "off" : "on", false)
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
      if (completedPreference === "history_source") Qt.callLater(root.refresh)
    }
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
      if (root.remoteHistoryInstallSucceeded) Qt.callLater(root.refresh)
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
        queuedUnitPowerEntityId = ""
        queuedUnitPowerRequest = ""
        Qt.callLater(function() {
          root.dispatchUnitPowerRequest(queuedUnitPowerEntity, queuedUnitPower)
        })
      } else if (queuedPower !== "") {
        queuedPowerRequest = ""
        Qt.callLater(function() { root.dispatchPowerRequest(queuedPower) })
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
    id: powerConfirmTimer
    interval: 500
    repeat: true
    running: root.hasLocalPower
    onTriggered: {
      if (!root.hasLocalPower) return
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
      Qt.callLater(function() {
        if (root.setupOpen && root.setupTransitioning) setupUrlField.forceActiveFocus()
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

  onOpenedChanged: {
    if (opened) {
      root.refresh()
    } else {
      setupTransitionTimer.stop()
      setupTransitionFinishTimer.stop()
      setupTransitioning = false
      setupTransitionClosing = false
    }
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
      root.loadConfig()
      root.refresh()
      Qt.callLater(root.openSetup)
    }
    function refresh(): string { root.refresh(); return "ok" }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.setupOpen
      ? (root.configured ? Style.space(600) : Style.space(520))
      : (root.separateRemotesActive ? Style.space(620) : Style.space(360)))
    contentHeight: panel.fittedContentHeight(root.setupOpen
      ? onboardingColumn.implicitHeight : column.implicitHeight)

    Behavior on contentHeight {
      NumberAnimation { duration: root.motionEmphasis; easing.type: Easing.OutCubic }
    }

    // Keep the panel readable over bright windows. The stock popup surface
    // can inherit a translucent theme alpha, so the plugin adds an opaque
    // surface behind its own content without changing the user's theme.
    Rectangle {
      anchors.fill: parent
      z: -1
      radius: root.panelRadius
      color: root.panelSurface
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: -Style.space(8) * root.appearanceSoftness
      z: -2
      radius: root.panelRadius + Style.space(8) * root.appearanceSoftness
      color: root.alpha(root.accentColor, root.appearanceSoftness * 0.08)
      opacity: root.appearanceSoftness
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.setupOpen && (setupUrlField.activeFocus
        || setupTokenField.activeFocus || setupEntityDropdown.popupOpen
        || remoteHistoryTargetField.activeFocus || remoteHistoryPortField.activeFocus
        || remoteHistoryUrlField.activeFocus)
      onCloseRequested: root.setupOpen && root.configured ? root.cancelSetup() : root.close()
      onActivateRequested: root.refresh()
      onTabRequested: function(direction) { root.switchPanel(direction) }
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

        Connections {
          target: root
          function onSetupOpenChanged() { panelScroll.contentY = 0 }
        }

      Column {
        id: onboardingColumn
        visible: root.setupOpen
        width: parent.width
        spacing: Style.space(10)

        BorderSurface {
          id: setupHero
          width: parent.width
          height: Style.space(94)
          radius: root.panelRadius
          color: root.alpha(root.foreground, 0.035)
          borderSpec: Border.flat(root.alpha(root.foreground, 0.16), 1)

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
          }
        }

        BorderSurface {
          id: settingsNavigationCard
          visible: root.configured
          width: parent.width
          implicitHeight: settingsNavigationForm.implicitHeight + Style.space(20)
          radius: root.panelRadius
          color: root.alpha(root.foreground, 0.025)
          borderSpec: Border.flat(root.alpha(root.foreground, 0.14), 1)

          Column {
            id: settingsNavigationForm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(10)
            spacing: Style.space(7)

            Button {
              id: backToControlsButton
              visible: root.configured
              width: parent.width
              height: Style.space(38)
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
              bordered: true
              radius: root.compactRadius
              tooltipText: "Return to the AC controls"
              onClicked: root.cancelSetup()
            }

            Text {
              width: parent.width
              text: "SETTINGS SECTIONS"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
            }

            Row {
              id: settingsSectionChoices
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.settingsSections

                Button {
                  required property var modelData
                  width: (settingsSectionChoices.width
                    - settingsSectionChoices.spacing * (root.settingsSections.length - 1))
                    / root.settingsSections.length
                  height: Style.space(34)
                  text: modelData.label
                  fontSize: Style.font.caption
                  horizontalPadding: Style.space(3)
                  foreground: root.foreground
                  accent: root.accentColor
                  background: root.alpha(root.foreground, 0.025)
                  bordered: true
                  selected: root.settingsSection === modelData.value
                  radius: root.compactRadius
                  onClicked: root.settingsSection = modelData.value
                }
              }
            }
          }
        }

        BorderSurface {
          id: setupCard
          visible: !root.configured || root.settingsSection === "setup"
          width: parent.width
          implicitHeight: setupForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.alpha(root.foreground, 0.035)
          borderSpec: Border.flat(root.alpha(root.foreground, 0.16), 1)

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

            TextField {
              id: setupUrlField
              width: parent.width
              enabled: !root.setupBusy && !root.localServerBusy
              placeholderText: "http://homeassistant.local:8123"
              text: root.setupUrl
              foreground: root.foreground
              accent: root.accentColor
              font.family: root.fontFamily
              inputMethodHints: Qt.ImhUrlCharactersOnly
              selectByMouse: true
              onTextChanged: if (text !== root.setupUrl) root.setupUrl = text
              onAccepted: setupTokenField.forceActiveFocus()
              Keys.onEscapePressed: if (root.configured) root.cancelSetup()
            }

            Text {
              width: parent.width
              text: "Enter the server URL, hostname, or IP address with its port. HTTPS and reverse-proxy paths are supported."
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
              accent: root.accentColor
              font.family: root.fontFamily
              selectByMouse: true
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
              background: Color.popups.background
              popupBorder: Color.popups.border
              accent: root.accentColor
              fontFamily: root.fontFamily
              controlRadius: root.compactRadius
              onChanged: function(value) { root.setupSelectedEntity = value }
            }

            BorderSurface {
              visible: root.setupError !== ""
              width: parent.width
              implicitHeight: setupMessage.implicitHeight + Style.space(18)
              color: root.alpha(root.setupEntityOptions.length > 0 ? root.accentColor : root.urgent, 0.09)
              borderSpec: Border.flat(root.alpha(root.setupEntityOptions.length > 0 ? root.accentColor : root.urgent, 0.32), 1)
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
              color: root.alpha(root.accentColor, 0.045)
              borderSpec: Border.flat(root.alpha(root.accentColor, 0.22), 1)

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

                Toggle {
                  width: parent.width
                  label: "Show climate controls"
                  description: "On by default. Keep mode and fan-speed controls visible in the main panel."
                  checked: root.advancedControls
                  enabled: !root.setupBusy
                  foreground: root.foreground
                  accent: root.accentColor
                  fontFamily: root.fontFamily
                  onClicked: root.advancedControls = !root.advancedControls
                }

                Toggle {
                  width: parent.width
                  label: "MasterSwitch"
                  description: "Show guarded actions that control every available AC together."
                  checked: root.masterSwitchEnabled
                  enabled: !root.setupBusy
                  foreground: root.foreground
                  accent: root.accentColor
                  fontFamily: root.fontFamily
                  onClicked: root.masterSwitchEnabled = !root.masterSwitchEnabled
                }

                BorderSurface {
                  width: parent.width
                  implicitHeight: onboardingMasterSwitchWarning.implicitHeight + Style.space(18)
                  color: root.alpha(root.urgent, 0.07)
                  borderSpec: Border.flat(root.alpha(root.urgent, 0.25), 1)
                  radius: root.compactRadius

                  Text {
                    id: onboardingMasterSwitchWarning
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Style.space(10)
                    anchors.rightMargin: Style.space(10)
                    text: "Warning: MasterSwitch can turn every available AC on or off at once. I'm not responsible for wrecking your electricity bills."
                    color: root.urgent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }

            Button {
              width: parent.width
              height: Style.space(40)
              text: root.setupActionLabel
              iconText: root.setupBusy ? "" : "→"
              iconSize: Style.font.body
              fontSize: Style.font.bodySmall
              enabled: root.setupCanSubmit
              fontFamily: root.fontFamily
              foreground: Color.popups.background
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
                color: Color.popups.background
                strokeWidth: Style.space(2)
              }
            }

            Button {
              width: parent.width
              height: Style.space(40)
              text: "HOME ASSISTANT SETTINGS"
              iconText: "↗"
              iconSize: Style.font.body
              fontSize: Style.font.bodySmall
              enabled: !root.setupBusy && !root.localServerBusy
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: true
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
          visible: !root.configured || root.settingsSection === "setup"
          width: parent.width
          implicitHeight: localServerForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.alpha(root.accentColor, 0.035)
          borderSpec: Border.flat(root.alpha(root.accentColor, 0.20), 1)

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
              color: root.alpha(root.foreground, 0.025)
              borderSpec: Border.flat(root.alpha(root.foreground, 0.11), 1)
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
              color: root.alpha(root.accentColor, 0.08)
              borderSpec: Border.flat(root.alpha(root.accentColor, 0.30), 1)
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
                actionTextColor: Color.popups.background
                idleBackground: root.alpha(root.accentColor, 0.07)
                backTextColor: root.foreground
                backBackground: root.alpha(root.foreground, 0.025)
                controlRadius: root.compactRadius
                fontFamily: root.fontFamily
                confirming: root.localServerConfirming
                busy: root.localServerBusy
                actionEnabled: !root.localServerBusy && !root.setupBusy && !root.preferenceBusy
                onActionRequested: root.localServerReady
                  ? root.openLocalServer() : root.requestLocalServerSetup()
                onBackRequested: root.cancelLocalServerSetup()
              }

              Button {
                id: localServerGuideButton
                width: Style.space(112)
                height: Style.space(40)
                text: "GUIDE"
                fontSize: Style.font.caption
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: true
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
              color: root.alpha(root.localServerError !== "" ? root.urgent : root.accentColor, 0.09)
              borderSpec: Border.flat(root.alpha(root.localServerError !== "" ? root.urgent : root.accentColor, 0.32), 1)
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
          visible: root.configured && root.settingsSection === "preferences"
          width: parent.width
          implicitHeight: advancedSettingsForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.alpha(root.accentColor, 0.035)
          borderSpec: Border.flat(root.alpha(root.accentColor, 0.20), 1)

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

            Toggle {
              width: parent.width
              label: "Show climate controls"
              description: "Show mode and fan-speed controls in the main panel."
              checked: root.advancedControls
              enabled: !root.setupBusy && !root.preferenceBusy
              foreground: root.foreground
              accent: root.accentColor
              fontFamily: root.fontFamily
              onClicked: root.setAdvancedControlsEnabled(!root.advancedControls)
            }

            Toggle {
              visible: root.advancedControls || height > 0.5
              width: parent.width
              height: root.advancedControls ? implicitHeight : 0
              opacity: root.advancedControls ? 1 : 0
              clip: true
              label: "MasterSwitch"
              description: "Show guarded controls for every available climate device."
              checked: root.masterSwitchEnabled
              enabled: !root.setupBusy && !root.preferenceBusy
              foreground: root.foreground
              accent: root.accentColor
              fontFamily: root.fontFamily
              onClicked: root.setMasterSwitchEnabled(!root.masterSwitchEnabled)

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }
            }

            BorderSurface {
              visible: root.advancedControls || height > 0.5
              width: parent.width
              implicitHeight: masterSwitchWarning.implicitHeight + Style.space(18)
              height: root.advancedControls ? implicitHeight : 0
              opacity: root.advancedControls ? 1 : 0
              clip: true
              color: root.alpha(root.urgent, 0.07)
              borderSpec: Border.flat(root.alpha(root.urgent, 0.25), 1)
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
                text: "Warning: MasterSwitch can turn every available AC on or off at once. I'm not responsible for wrecking your electricity bills."
                color: root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

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

                Button {
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
                  bordered: true
                  selected: root.temperatureDisplay === modelData.value
                  enabled: !root.preferenceBusy
                  radius: root.compactRadius
                  tooltipText: "Show " + modelData.label.toLowerCase() + " temperature in the bar"
                  onClicked: root.setTemperatureDisplay(modelData.value)
                }
              }
            }

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

              Button {
                width: (parent.width - parent.spacing) / 2
                height: Style.space(34)
                text: "LOCAL"
                fontSize: Style.font.caption
                horizontalPadding: Style.space(4)
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: true
                selected: root.historySource === "local"
                enabled: !root.preferenceBusy
                radius: root.compactRadius
                tooltipText: "Log on this PC while it is on"
                onClicked: root.setHistorySource("local")
              }

              Button {
                width: (parent.width - parent.spacing) / 2
                height: Style.space(34)
                text: "EXTERNAL SERVER"
                fontSize: Style.font.caption
                horizontalPadding: Style.space(4)
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: true
                selected: root.historySource === "server"
                enabled: !root.preferenceBusy
                radius: root.compactRadius
                tooltipText: "Log on the same external host that runs Home Assistant"
                onClicked: root.setHistorySource("server")
              }
            }

            Toggle {
              width: parent.width
              label: "Ambient temperature history"
              description: root.historySource === "server"
                ? "Show the server's ambient log in the main panel."
                : "Show the ambient log saved on this PC in the main panel."
              checked: root.historyEnabled
              enabled: !root.setupBusy && !root.preferenceBusy
              foreground: root.foreground
              accent: root.accentColor
              fontFamily: root.fontFamily
              onClicked: root.setHistoryEnabled(!root.historyEnabled)
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
                implicitHeight: (root.remoteHistoryPaired && !root.remoteHistoryReconfiguring
                  ? remoteHistoryPairedSummary.implicitHeight : remoteHistoryForm.implicitHeight)
                  + Style.space(24)
                radius: root.compactRadius
                color: root.alpha(root.accentColor, 0.045)
                borderSpec: Border.flat(root.alpha(root.accentColor, 0.24), 1)

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
                  visible: root.remoteHistoryPaired && !root.remoteHistoryReconfiguring
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
                        text: "EXTERNAL SERVER HISTORY"
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 0.8
                      }

                      Text {
                        width: parent.width
                        text: "PAIRED · CONNECTED"
                        color: root.accentColor
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                      }
                    }
                  }

                  BorderSurface {
                    width: parent.width
                    implicitHeight: remoteHistoryPairedTarget.implicitHeight + Style.space(16)
                    color: root.alpha(root.accentColor, 0.07)
                    borderSpec: Border.flat(root.alpha(root.accentColor, 0.24), 1)
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

                  Button {
                    width: parent.width
                    height: Style.space(36)
                    text: "RECONFIGURE"
                    fontSize: Style.font.caption
                    fontFamily: root.fontFamily
                    foreground: root.foreground
                    accent: root.accentColor
                    background: root.alpha(root.foreground, 0.025)
                    bordered: true
                    radius: root.compactRadius
                    enabled: !root.remoteHistoryBusy && !root.preferenceBusy
                    tooltipText: "Edit the external server connection"
                    onClicked: {
                      root.remoteHistoryReconfiguring = true
                      root.remoteHistoryMessage = ""
                      root.remoteHistoryError = ""
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
                  visible: !root.remoteHistoryPaired || root.remoteHistoryReconfiguring
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
                        text: "EXTERNAL SERVER HISTORY"
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
                    color: root.alpha(root.foreground, 0.025)
                    borderSpec: Border.flat(root.alpha(root.foreground, 0.12), 1)
                    radius: root.compactRadius

                    Text {
                      id: remoteHistorySafetyText
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: Style.space(10)
                      anchors.rightMargin: Style.space(10)
                      text: "SAFE BY DESIGN · Reviewable source files only. No sudo, package installs, open ports, telemetry, or Home Assistant control calls. One user timer reads the selected climate states and writes one owner-only 31-day file on the external host."
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
                        text: "SSH TARGET"
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
                        accent: root.accentColor
                        font.family: root.fontFamily
                        selectByMouse: true
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
                        accent: root.accentColor
                        font.family: root.fontFamily
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        selectByMouse: true
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
                    accent: root.accentColor
                    font.family: root.fontFamily
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    selectByMouse: true
                    onTextChanged: if (text !== root.remoteHistoryUrl)
                      root.remoteHistoryUrl = text
                  }

                  Text {
                    width: parent.width
                    text: "Use the URL reachable from that same external host, usually http://127.0.0.1:8123. The token is sent through encrypted SSH stdin, stored owner-only, and used by one user systemd timer."
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }

                  Row {
                    id: remoteHistoryInstallRow
                    width: parent.width
                    spacing: Style.space(6)

                    Button {
                      width: parent.width
                      height: Style.space(40)
                      text: root.remoteHistoryBusy ? "INSTALLING…" : "INSTALL SERVER TIMER"
                      iconText: root.remoteHistoryBusy ? "" : "󰒓"
                      iconSize: Style.font.body
                      fontSize: Style.font.caption
                      fontFamily: root.fontFamily
                      foreground: Color.popups.background
                      accent: root.accentColor
                      background: root.accentColor
                      bordered: false
                      radius: root.compactRadius
                      enabled: !root.remoteHistoryBusy
                        && !root.remoteHistorySourceBusy && !root.preferenceBusy
                      tooltipText: "Copy the reviewed files and install one user timer over SSH"
                      onClicked: root.startRemoteHistoryInstall()

                      LoadingRing {
                        visible: root.remoteHistoryBusy
                        anchors.left: parent.left
                        anchors.leftMargin: Style.space(12)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Style.space(16)
                        height: width
                        color: Color.popups.background
                        strokeWidth: Style.space(2)
                      }
                    }
                  }

                  Row {
                    id: remoteHistoryLinkRow
                    width: parent.width
                    spacing: Style.space(6)

                    Button {
                      width: parent.width
                      height: Style.space(38)
                      text: "GUIDE"
                      iconText: "↗"
                      iconSize: Style.font.body
                      fontSize: Style.font.caption
                      horizontalPadding: Style.space(3)
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: true
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

                    Button {
                      width: parent.width
                      height: Style.space(38)
                      text: root.remoteHistorySourceBusy ? "PREPARING…" : "COPY SOURCE"
                      fontSize: Style.font.caption
                      horizontalPadding: Style.space(3)
                      fontFamily: root.fontFamily
                      foreground: root.foreground
                      accent: root.accentColor
                      background: root.alpha(root.foreground, 0.025)
                      bordered: true
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
                    color: root.alpha(root.remoteHistoryError !== "" ? root.urgent : root.accentColor, 0.08)
                    borderSpec: Border.flat(root.alpha(
                      root.remoteHistoryError !== "" ? root.urgent : root.accentColor, 0.28), 1)
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

            Column {
              visible: root.historyEnabled || height > 0.5
              width: parent.width
              height: root.historyEnabled ? implicitHeight : 0
              opacity: root.historyEnabled ? 1 : 0
              clip: true
              spacing: Style.space(7)

              Behavior on height {
                NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
              }
              Behavior on opacity {
                NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic }
              }

              Text {
                width: parent.width
                text: "CHART RANGE"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 0.8
              }

              Row {
                id: historyRangeChoices
                width: parent.width
                spacing: Style.space(5)

                Repeater {
                  model: root.historyRangeOptions

                  Button {
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
                    bordered: true
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
                  accent: root.accentColor
                  font.family: root.fontFamily
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
                  onTextChanged: if (text !== root.customHistoryHoursText)
                    root.customHistoryHoursText = text
                  onAccepted: root.applyCustomHistoryRange()
                }

                Button {
                  id: applyCustomHistoryButton
                  width: Style.space(76)
                  height: Style.space(38)
                  text: "APPLY"
                  fontSize: Style.font.caption
                  enabled: !root.preferenceBusy
                  foreground: Color.popups.background
                  accent: root.accentColor
                  background: root.accentColor
                  bordered: false
                  radius: root.compactRadius
                  onClicked: root.applyCustomHistoryRange()
                }
              }

              Text {
                width: parent.width
                text: root.experimentalHistoryEnabled
                  ? "Extended history includes 7-day, 30-day, and custom ranges. For long recordings, an always-on external server logger is recommended."
                  : "The chart keeps the selected range (" + root.formatHours(root.historyHours) + " hours). Local logging needs this PC active; sleep, shutdown, and restart periods remain empty. Extended and custom ranges are in Experimental."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }
        }

        BorderSurface {
          id: experimentalCard
          visible: root.configured && root.settingsSection === "experimental"
          width: parent.width
          implicitHeight: experimentalForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.alpha(root.accentColor, 0.035)
          borderSpec: Border.flat(root.alpha(root.accentColor, 0.20), 1)

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
              color: root.alpha(root.urgent, 0.07)
              borderSpec: Border.flat(root.alpha(root.urgent, 0.25), 1)
              radius: root.compactRadius

              Text {
                id: experimentalWarning
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: "EXPERIMENTAL · These options are opt-in and may change."
                color: root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            Toggle {
              width: parent.width
              label: "Multi-aircon panel"
              description: "Add several Home Assistant climate entities below the panel selector."
              checked: root.multiUnitEnabled
              enabled: !root.preferenceBusy && root.selectedEntities.length > 0
              foreground: root.foreground
              accent: root.accentColor
              fontFamily: root.fontFamily
              onClicked: root.setMultiUnitEnabled(!root.multiUnitEnabled)
            }

            Column {
              id: multiAirconOptions
              visible: root.multiUnitEnabled || height > 0.5
              width: parent.width
              height: root.multiUnitEnabled ? implicitHeight : 0
              opacity: root.multiUnitEnabled ? 1 : 0
              clip: true
              spacing: Style.space(7)

              Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

              Toggle {
                width: parent.width
                label: "Globally synced controls"
                description: "Use one remote for every selected air conditioner, including power."
                checked: root.globalSyncControls
                enabled: !root.preferenceBusy && root.selectedEntities.length > 1
                foreground: root.foreground
                accent: root.accentColor
                fontFamily: root.fontFamily
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

                Toggle {
                  width: parent.width
                  label: "Sync non-power controls"
                  description: "Recommended · sync temperature, mode, and fan while each AC keeps its own power button."
                  checked: root.syncNonPowerControls
                  enabled: !root.preferenceBusy
                  foreground: root.foreground
                  accent: root.accentColor
                  fontFamily: root.fontFamily
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
                    { value: "single", label: "ONE" },
                    { value: "selected", label: "PICK" },
                  ]

                  Button {
                    required property var modelData
                    width: (barTemperatureChoices.width
                      - barTemperatureChoices.spacing * 3) / 4
                    height: Style.space(32)
                    text: modelData.label
                    fontSize: Style.font.caption
                    horizontalPadding: Style.space(2)
                    foreground: root.foreground
                    accent: root.accentColor
                    background: root.alpha(root.foreground, 0.025)
                    bordered: true
                    selected: root.barTemperatureMode === modelData.value
                    enabled: !root.preferenceBusy
                    radius: root.compactRadius
                    tooltipText: modelData.value === "average"
                      ? "Average the selected ambient temperatures"
                      : modelData.value === "all" ? "Show all selected ambient temperatures"
                      : modelData.value === "single" ? "Show one selected ambient temperature"
                      : "Choose which selected ambient temperatures appear"
                    onClicked: root.setBarTemperatureMode(modelData.value)
                  }
                }
              }

              AcDropdown {
                visible: root.barTemperatureMode === "single"
                width: parent.width
                label: "BAR AIR CONDITIONER"
                options: root.selectedEntityDropdownOptions
                value: root.barTemperatureEntity
                foreground: root.foreground
                background: Color.popups.background
                popupBorder: Color.popups.border
                accent: root.accentColor
                fontFamily: root.fontFamily
                controlRadius: root.compactRadius
                enabled: !root.preferenceBusy
                onChanged: function(value) { root.setBarTemperatureEntity(value) }
              }

              Column {
                visible: root.barTemperatureMode === "selected"
                width: parent.width
                spacing: Style.space(5)

                Repeater {
                  model: root.selectedEntities

                  Button {
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
                    bordered: true
                    selected: root.barTemperatureEntities.indexOf(String(modelData)) >= 0
                    enabled: !root.preferenceBusy
                    radius: root.compactRadius
                    onClicked: root.toggleBarTemperatureEntity(String(modelData))
                  }
                }
              }
            }

            Toggle {
              width: parent.width
              label: "Extended chart history"
              description: "Unlock 7-day, 30-day, and custom ranges. An always-on external logger is recommended for long recordings."
              checked: root.experimentalHistoryEnabled
              enabled: !root.preferenceBusy
              foreground: root.foreground
              accent: root.accentColor
              fontFamily: root.fontFamily
              onClicked: root.setExperimentalHistoryEnabled(!root.experimentalHistoryEnabled)
            }

            BorderSurface {
              visible: root.experimentalHistoryEnabled
              width: parent.width
              implicitHeight: extendedHistoryNotice.implicitHeight + Style.space(18)
              color: root.alpha(root.accentColor, 0.06)
              borderSpec: Border.flat(root.alpha(root.accentColor, 0.22), 1)
              radius: root.compactRadius

              Text {
                id: extendedHistoryNotice
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: "Includes 7-day, 30-day, and custom ranges up to 744 hours. For long recordings, an always-on external logger on the Home Assistant host is recommended. Reinstall its timer after changing the selected AC list."
                color: root.accentColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            Button {
              visible: root.experimentalHistoryEnabled
              width: parent.width
              height: Style.space(34)
              text: "EXTERNAL SERVER SETTINGS"
              iconText: "↗"
              iconSize: Style.font.body
              fontSize: Style.font.caption
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: root.accentColor
              background: root.alpha(root.foreground, 0.025)
              bordered: true
              radius: root.compactRadius
              tooltipText: "Open Preferences and configure the external Home Assistant host"
              enabled: !root.preferenceBusy
              onClicked: root.settingsSection = "preferences"
            }

            Text {
              width: parent.width
              text: "ACCENT MODE"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
            }

            Text {
              width: parent.width
              text: "Auto follows Omarchy's current accent. Custom keeps the plugin's chosen accent and finish."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Row {
              id: appearanceModeChoices
              width: parent.width
              spacing: Style.space(6)

              Button {
                width: (appearanceModeChoices.width - appearanceModeChoices.spacing) / 2
                height: Style.space(34)
                text: "AUTO · OMARCHY"
                fontSize: Style.font.caption
                horizontalPadding: Style.space(3)
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: true
                selected: !root.customAppearanceEnabled
                enabled: !root.preferenceBusy
                radius: root.compactRadius
                tooltipText: "Follow Omarchy's current accent"
                onClicked: root.setCustomAppearanceEnabled(false)
              }

              Button {
                width: (appearanceModeChoices.width - appearanceModeChoices.spacing) / 2
                height: Style.space(34)
                text: "CUSTOM"
                fontSize: Style.font.caption
                horizontalPadding: Style.space(3)
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.025)
                bordered: true
                selected: root.customAppearanceEnabled
                enabled: !root.preferenceBusy
                radius: root.compactRadius
                tooltipText: "Use the custom accent and finish below"
                onClicked: root.setCustomAppearanceEnabled(true)
              }
            }

            Column {
              id: appearanceOptions
              visible: root.customAppearanceEnabled || height > 0.5
              width: parent.width
              height: root.customAppearanceEnabled ? implicitHeight : 0
              opacity: root.customAppearanceEnabled ? 1 : 0
              clip: true
              spacing: Style.space(7)

              Behavior on height { NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

              Text {
                width: parent.width
                text: "ACCENT COLOR"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 0.8
              }

              Row {
                id: appearanceSwatches
                width: parent.width
                spacing: Style.space(6)

                Repeater {
                  model: ["#8FA79F", "#8EA7C7", "#C89AAB", "#D0A66A", "#A99BC7"]

                  Button {
                    required property var modelData
                    width: Style.space(30)
                    height: Style.space(30)
                    text: ""
                    fontFamily: root.fontFamily
                    foreground: modelData
                    accent: modelData
                    background: modelData
                    bordered: true
                    radius: width / 2
                    selected: root.customAccentHexText.toUpperCase() === String(modelData).toUpperCase()
                    enabled: !root.preferenceBusy
                    tooltipText: "Use " + modelData + " as the accent"
                    onClicked: root.setAppearanceHex(modelData)
                  }
                }

              }

              Row {
                id: appearanceHexRow
                width: parent.width
                spacing: Style.space(7)

                TextField {
                  id: appearanceHexField
                  width: parent.width - appearanceHexApplyButton.width - parent.spacing
                  height: Style.space(30)
                  text: root.customAccentHexText
                  placeholderText: "#RRGGBB"
                  enabled: !root.preferenceBusy
                  foreground: root.foreground
                  accent: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  selectByMouse: true
                  onTextChanged: if (text !== root.customAccentHexText) root.customAccentHexText = text
                  onAccepted: root.setAppearanceHex(text)
                }

                Button {
                  id: appearanceHexApplyButton
                  width: Style.space(60)
                  height: Style.space(30)
                  text: "APPLY"
                  fontSize: Style.font.caption
                  fontFamily: root.fontFamily
                  foreground: Color.popups.background
                  accent: root.accentColor
                  background: root.accentColor
                  bordered: false
                  radius: root.compactRadius
                  enabled: !root.preferenceBusy
                  onClicked: root.setAppearanceHex(appearanceHexField.text)
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
                  maximum: 70
                  step: 1
                  integer: true
                  bar: root.bar
                  trackHeight: Style.space(3)
                  knobSize: Style.space(12)
                  trackColor: root.alpha(root.accentColor, 0.22)
                  fillColor: root.accentColor
                  knobColor: root.accentColor
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
                  accent: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
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
                  trackColor: root.alpha(root.accentColor, 0.22)
                  fillColor: root.accentColor
                  knobColor: root.accentColor
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
                  accent: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
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
                  text: "CORNERS"
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
                  trackColor: root.alpha(root.accentColor, 0.22)
                  fillColor: root.accentColor
                  knobColor: root.accentColor
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
                  accent: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  horizontalAlignment: Text.AlignHCenter
                  inputMethodHints: Qt.ImhFormattedNumbersOnly
                  selectByMouse: true
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
            }
          }
        }

        BorderSurface {
          id: aboutCard
          visible: root.configured && root.settingsSection === "maintenance"
          width: parent.width
          implicitHeight: aboutForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.alpha(root.foreground, 0.025)
          borderSpec: Border.flat(root.alpha(root.foreground, 0.14), 1)

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

            Button {
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
              bordered: true
              radius: root.compactRadius
              tooltipText: root.githubUrl
              onClicked: Qt.openUrlExternally(root.githubUrl)
            }
          }
        }

        BorderSurface {
          id: appDataCard
          visible: root.configured && root.settingsSection === "maintenance"
          width: parent.width
          implicitHeight: appDataForm.implicitHeight + Style.space(32)
          radius: root.panelRadius
          color: root.alpha(root.urgent, 0.025)
          borderSpec: Border.flat(root.alpha(root.urgent, 0.20), 1)

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
              color: root.alpha(root.urgent, 0.035)
              borderSpec: Border.flat(root.alpha(root.urgent, 0.20), 1)
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
                      color: root.alpha(root.urgent, 0.07)
                      borderSpec: Border.flat(root.alpha(root.urgent, 0.25), 1)
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

                  Button {
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
                    bordered: true
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

                    Button {
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
                      bordered: true
                      radius: root.compactRadius
                      enabled: !root.resetAppBusy
                      tooltipText: "Keep the app data"
                      onClicked: root.cancelResetApp()
                    }

                    Button {
                      id: resetConfirmButton
                      x: resetSplitFrame.backWidth + resetSplitFrame.splitGap
                      width: Math.max(0, parent.width - x)
                      height: parent.height
                      clip: true
                      opacity: resetSplitFrame.splitProgress
                      text: root.resetAppBusy ? "RESETTING…" : "RESET NOW"
                      fontSize: Style.font.bodySmall
                      fontFamily: root.fontFamily
                      foreground: Color.popups.background
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
                        color: Color.popups.background
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
                  color: root.alpha(root.resetAppError !== "" ? root.urgent : root.accentColor, 0.09)
                  borderSpec: Border.flat(root.alpha(root.resetAppError !== "" ? root.urgent : root.accentColor, 0.32), 1)
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
              color: root.alpha(root.urgent, 0.035)
              borderSpec: Border.flat(root.alpha(root.urgent, 0.20), 1)
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
                  text: "UNINSTALL PLUGIN"
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

                  Button {
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
                    bordered: true
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

                    Button {
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
                      bordered: true
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
                      width: uninstallOptions.width
                      height: selected ? uninstallOptionConfirmation.implicitHeight : Style.space(38)
                      clip: true

                      Behavior on height {
                        NumberAnimation { duration: root.motionStandard; easing.type: Easing.OutCubic }
                      }

                      Button {
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
                        bordered: true
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
                            color: root.alpha(root.urgent, 0.07)
                            borderSpec: Border.flat(root.alpha(root.urgent, 0.25), 1)
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

                            Button {
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
                              bordered: true
                              radius: root.compactRadius
                              enabled: !root.uninstallBusy
                              tooltipText: "Choose a different uninstall scope"
                              onClicked: {
                                root.uninstallOptionConfirming = false
                                root.uninstallMode = ""
                                root.uninstallError = ""
                              }
                            }

                            Button {
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
                              foreground: Color.popups.background
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
                                color: Color.popups.background
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
                  color: root.alpha(root.uninstallError !== "" ? root.urgent : root.accentColor, 0.09)
                  borderSpec: Border.flat(root.alpha(
                    root.uninstallError !== "" ? root.urgent : root.accentColor, 0.30), 1)
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
        spacing: Style.space(10)

        BorderSurface {
          id: heroCard
          width: parent.width
          height: Style.space(84)
          radius: root.panelRadius
          color: root.alpha(root.accentColor, root.isOn ? 0.10 : 0.04)
          gradient: Gradient {
            GradientStop { position: 0.0; color: root.alpha(root.accentColor, root.isOn ? 0.24 : 0.10) }
            GradientStop { position: 0.58; color: root.alpha(root.accentColor, root.isOn ? 0.08 : 0.035) }
            GradientStop { position: 1.0; color: root.alpha(root.foreground, 0.025) }
          }
          borderSpec: Border.flat(
            root.isOn ? root.alpha(root.accentColor, 0.58) : root.alpha(root.foreground, 0.18), 1)

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
              color: root.isOn ? root.alpha(root.accentColor, 0.18) : root.alpha(root.foreground, 0.05)
              borderSpec: Border.flat(root.isOn ? root.alpha(root.accentColor, 0.78) : root.alpha(root.foreground, 0.22), 1)

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
                border.color: root.alpha(Color.popups.background, 0.92)
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

              Button {
                width: Style.space(30)
                height: Style.space(30)
                iconText: "󰒓"
                iconSize: Style.font.body
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: root.accentColor
                background: root.alpha(root.foreground, 0.035)
                bordered: true
                radius: root.compactRadius
                tooltipText: "Edit Home Assistant connection"
                onClicked: root.openSetup()
              }
            }
          }
        }

        PanelSeparator {
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
          background: Color.popups.background
          popupBorder: Color.popups.border
          accent: root.accentColor
          fontFamily: root.fontFamily
          controlRadius: root.compactRadius
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
              width: selectedUnitsSection.width
              height: Style.space(32)
              radius: root.compactRadius
              color: root.alpha(root.accentColor, String(modelData) === root.selectedEntity ? 0.12 : 0.045)
              borderSpec: Border.flat(root.alpha(
                root.accentColor, String(modelData) === root.selectedEntity ? 0.36 : 0.18), 1)

              Row {
                anchors.fill: parent
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(4)
                spacing: Style.space(6)

                Text {
                  width: parent.width - removeSelectedUnitButton.width - parent.spacing
                  height: parent.height
                  text: root.entityDisplayName(modelData)
                  color: String(modelData) === root.selectedEntity ? root.accentColor : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: String(modelData) === root.selectedEntity
                  elide: Text.ElideRight
                  verticalAlignment: Text.AlignVCenter
                }

                Button {
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
                  accent: root.accentColor
                  background: root.alpha(root.foreground, 0.035)
                  bordered: true
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
            text: "Each selected air conditioner has its own remote."
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
                accent: root.accentColor
                foreground: root.foreground
                dim: root.dim
                fontFamily: root.fontFamily
                panelRadius: root.compactRadius
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
            color: root.alpha(root.accentColor, root.moodText === "COMFY" ? 0.16 : 0.09)
            borderSpec: Border.flat(root.alpha(root.accentColor, root.moodText === "COMFY" ? 0.55 : 0.32), 1)

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
            color: root.alpha(root.foreground, 0.035)
            gradient: Gradient {
              GradientStop { position: 0.0; color: root.alpha(root.foreground, 0.075) }
              GradientStop { position: 1.0; color: root.alpha(root.foreground, 0.018) }
            }
            borderSpec: Border.flat(root.alpha(root.foreground, 0.16), 1)

            Column {
              anchors.centerIn: parent
              spacing: Style.space(5)

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "AMBIENT"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.0
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.ambientText
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.displayLarge
                font.bold: true
              }
            }
          }

          BorderSurface {
            id: targetCard
            width: parent.width - ambientCard.width - parent.spacing
            height: ambientCard.height
            radius: root.panelRadius
            color: root.isOn
              ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.14 : 0.08)
              : root.alpha(root.foreground, 0.035)
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: root.isOn
                  ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.22 : 0.14)
                  : root.alpha(root.foreground, 0.075)
              }
              GradientStop {
                position: 1.0
                color: root.isOn
                  ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.06 : 0.025)
                  : root.alpha(root.foreground, 0.018)
              }
            }
            borderSpec: Border.flat(
              root.isOn
                ? root.alpha(root.accentColor, root.hasLocalTarget ? 0.72 : 0.38)
                : root.alpha(root.foreground, 0.16), 1)

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

              Button {
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
                bordered: true
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
                  font.pixelSize: Style.font.displayLarge
                  font.bold: true
                }
              }

              Button {
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
                bordered: true
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
              value: isFinite(Number(root.targetValue)) ? Number(root.targetValue) : root.minimumTemperature
              minimum: root.minimumTemperature
              maximum: root.maximumTemperature
              step: root.temperatureStep
              integer: false
              bar: root.bar
              trackHeight: Style.space(3)
              knobSize: Style.space(12)
              trackColor: root.alpha(root.accentColor, 0.22)
              fillColor: root.accentColor
              knobColor: root.accentColor
              tickCount: 3
              tickColor: root.alpha(Color.popups.background, 0.82)
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
            powerPending: root.hasLocalPower
            localPowerOn: root.localPower
            modePending: root.modeRestarting
            powerCanCancel: root.powerCanCancel
            actionEnabled: root.connected && !root.actionBusy && !root.masterSwitchBusy
            cancelEnabled: root.connected && !root.masterSwitchBusy
            foreground: root.foreground
            accent: root.accentColor
            fontFamily: root.fontFamily
            panelRadius: root.compactRadius
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
                readonly property bool powerPending: String(localState.power || "") !== ""
                readonly property bool localPowerOn: String(localState.power || "") === "turning_on"
                readonly property bool actualIsOn: String(climate.state || "").toLowerCase() !== "off"

                width: Math.max(
                  Style.space(160),
                  (splitPowerFlow.width - splitPowerFlow.spacing) / 2)
                height: Style.space(82)

                BorderSurface {
                  anchors.fill: parent
                  radius: root.compactRadius
                  color: root.alpha(root.accentColor,
                    parent.powerPending || parent.localPowerOn || parent.actualIsOn ? 0.075 : 0.035)
                  borderSpec: Border.flat(root.alpha(root.accentColor,
                    parent.powerPending || parent.localPowerOn || parent.actualIsOn ? 0.30 : 0.14), 1)

                  Column {
                    anchors.fill: parent
                    anchors.margins: Style.space(10)
                    spacing: Style.space(5)

                    Text {
                      width: parent.width
                      text: root.entityDisplayName(splitPowerCard.entityId)
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      elide: Text.ElideRight
                    }

                    ClimatePowerControl {
                      width: parent.width
                      height: Style.space(36)
                      connected: root.connected && splitPowerCard.climate.entity_id !== undefined
                      isOn: splitPowerCard.powerPending
                        ? splitPowerCard.localPowerOn : splitPowerCard.actualIsOn
                      powerPending: splitPowerCard.powerPending
                      localPowerOn: splitPowerCard.localPowerOn
                      powerCanCancel: splitPowerCard.localState.powerCanCancel === true
                      compact: true
                      actionEnabled: root.connected && !root.actionBusy && !root.masterSwitchBusy
                      cancelEnabled: root.connected && !root.masterSwitchBusy
                      foreground: root.foreground
                      accent: root.accentColor
                      fontFamily: root.fontFamily
                      panelRadius: root.compactRadius
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
          visible: (root.showMainRemote && root.advancedControlsVisible) || height > 0.5
          height: root.showMainRemote && root.advancedControlsVisible ? implicitHeight : 0
          enabled: root.showMainRemote && root.advancedControlsVisible
          clip: true
          spacing: Style.space(8)
          opacity: root.showMainRemote && root.advancedControlsVisible ? 1 : 0

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
            color: root.alpha(root.accentColor, 0.045)
            borderSpec: Border.flat(root.alpha(root.accentColor, 0.25), 1)

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
                  background: Color.popups.background
                  popupBorder: Color.popups.border
                  accent: root.accentColor
                  fontFamily: root.fontFamily
                  controlRadius: root.compactRadius
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
                  background: Color.popups.background
                  popupBorder: Color.popups.border
                  accent: root.accentColor
                  fontFamily: root.fontFamily
                  controlRadius: root.compactRadius
                  enabled: root.connected && root.isOn && !root.actionBusy && !root.masterSwitchBusy
                  onChanged: function(value) { root.requestFanMode(value) }
                }
              }
            }
          }
        }

        BorderSurface {
          id: masterSwitchCard
          readonly property bool masterSwitchVisible: root.advancedControls
            && root.masterSwitchEnabled && root.connected
          visible: masterSwitchVisible || height > 0.5
          width: parent.width
          implicitHeight: masterSwitchForm.implicitHeight + Style.space(28)
          height: masterSwitchVisible ? implicitHeight : 0
          opacity: masterSwitchVisible ? 1 : 0
          clip: true
          radius: root.panelRadius
          color: root.alpha(root.foreground, 0.035)
          borderSpec: Border.flat(root.alpha(root.foreground, 0.16), 1)

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
              actionTextColor: Color.popups.background
              idleBackground: root.alpha(root.accentColor, 0.07)
              backTextColor: root.foreground
              backBackground: root.alpha(root.foreground, 0.025)
              controlRadius: root.compactRadius
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
              actionTextColor: Color.popups.background
              idleBackground: root.alpha(root.urgent, 0.07)
              backTextColor: root.foreground
              backBackground: root.alpha(root.foreground, 0.025)
              controlRadius: root.compactRadius
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
              color: root.alpha(
                root.turnOffAllError !== "" || root.turnOnAllError !== "" ? root.urgent : root.accentColor,
                0.09)
              borderSpec: Border.flat(root.alpha(
                root.turnOffAllError !== "" || root.turnOnAllError !== "" ? root.urgent : root.accentColor,
                0.32), 1)
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
          points: root.historyPoints
          rangeHours: root.historyHours
          unit: root.unit
          sourceLabel: root.historySourceLabel
          emptyMessage: root.historyEmptyMessage
          foreground: root.foreground
          accent: root.accentColor
          background: root.alpha(root.foreground, 0.035)
          borderColor: root.alpha(root.foreground, 0.14)
          fontFamily: root.fontFamily

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
          color: root.alpha(root.urgent, 0.10)
          borderSpec: Border.flat(root.alpha(root.urgent, 0.35), 1)
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
            color: root.alpha(Color.popups.background, 0.985)
            borderSpec: Border.flat(root.alpha(root.accentColor, 0.26), 1)
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
            color: root.alpha(root.accentColor, 0.075)
            gradient: Gradient {
              GradientStop { position: 0.0; color: root.alpha(root.accentColor, 0.19) }
              GradientStop { position: 1.0; color: root.alpha(root.accentColor, 0.035) }
            }
            borderSpec: Border.flat(root.alpha(root.accentColor, 0.44), 1)

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
