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
  readonly property string pluginDir: {
    var u = String(Qt.resolvedUrl("."))
    if (u.indexOf("file://") === 0) u = u.slice(7)
    if (u.length > 1 && u.charAt(u.length - 1) === "/") u = u.slice(0, u.length - 1)
    return u
  }
  readonly property string helperPath: root.pluginDir + "/omarchy-homeassistant-ac"
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property real panelRadius: Style.cornerRadius
  readonly property real nestedRadius: Math.max(0, panelRadius - Style.space(2))
  readonly property real compactRadius: panelRadius > 0
    ? Math.max(Style.space(6), panelRadius - Style.space(4)) : 0
  property var reading: ({})
  property var entityOptions: []
  property string selectedEntity: ""
  property string pendingEntity: ""
  property string errorText: ""
  property bool actionBusy: false
  property string actionKind: ""
  property var localTarget: null
  property string pendingPowerState: ""
  property double powerRequestStartedAt: 0
  property bool powerFinalCheckPending: false
  property bool powerCanCancel: false
  property string queuedPowerRequest: ""
  property var temperatureInFlight: null
  property var lastTemperatureSent: null
  property bool configResolved: false
  property bool configured: false
  property bool setupOpen: false
  property bool setupBusy: false
  property bool setupSucceeded: false
  property string setupUrl: "http://homeassistant.local:8123"
  property string setupToken: ""
  property string setupError: ""
  property string setupPayload: ""
  property string setupSelectedEntity: ""
  property var setupEntityOptions: []

  function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }

  readonly property var dropdownOptions: [{
    value: "",
    label: "Choose an air conditioner"
  }].concat(entityOptions)
  readonly property var setupDropdownOptions: [{
    value: "",
    label: "Choose an air conditioner"
  }].concat(setupEntityOptions)
  readonly property bool setupCanSubmit: !setupBusy
    && String(setupUrl || "").trim() !== ""
    && String(setupToken || "").trim() !== ""
    && (setupEntityOptions.length === 0 || setupSelectedEntity !== "")
  readonly property string setupActionLabel: setupEntityOptions.length > 0
    ? "SAVE & CONTINUE" : "CONNECT & CONTINUE"
  readonly property bool connected: reading && reading.ok === true
  readonly property bool actualIsOn: connected && String(reading.state || "").toLowerCase() !== "off"
  readonly property bool hasLocalPower: pendingPowerState !== ""
  readonly property bool localPower: pendingPowerState === "turning_on"
  readonly property bool isOn: connected && (hasLocalPower ? localPower : actualIsOn)
  readonly property string unit: connected ? String(reading.unit || "°C") : "°C"
  readonly property string ambientText: connected ? temperature(reading.ambient) : "—"
  readonly property bool hasLocalTarget: localTarget !== null && isFinite(Number(localTarget))
  readonly property var targetValue: hasLocalTarget ? Number(localTarget) : reading.target
  readonly property string targetText: connected ? temperature(targetValue) : "—"
  readonly property bool otherActionBusy: actionProcess.running && actionKind !== "temperature"
  readonly property color stateColor: connected && isOn ? Color.accent : dim
  readonly property color statusColor: hasLocalPower ? Color.accent : stateColor
  readonly property string deviceInfoText: connected ? String(reading.device_info || "Home Assistant climate") : "Home Assistant climate"
  readonly property string connectionText: !connected ? "OFFLINE"
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
    ? (isOn
       ? "󰜗 " + ambientText + "\u2009\u2009→\u2009\u2009" + targetText
       : "󰜗 " + ambientText + "\u2009\u2009·\u2009\u2009OFF")
    : "󰜗"
  readonly property string tooltip: connected
    ? (String(reading.name || "Air conditioner")
       + (hasLocalPower ? (localPower ? " · Powering on…" : " · Powering off…")
          : " · " + stateLabel(reading.state))
       + " · ambient " + ambientText
       + (!hasLocalPower && isOn ? " · set " + targetText : "")
       + (hasLocalPower && powerCanCancel ? " · right-click to cancel" : ""))
    : "Daikin Air · click to connect"

  function temperature(value) {
    var parsed = Number(value)
    if (!isFinite(parsed)) return "—"
    var rounded = Math.round(parsed * 10) / 10
    return String(rounded).replace(/\.0$/, "") + unit
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

  function clearLocalPower() {
    pendingPowerState = ""
    powerRequestStartedAt = 0
    powerFinalCheckPending = false
    powerCanCancel = false
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

  function setEntityOptions(items) {
    entityOptions = root.formatEntityOptions(items)
  }

  function setSetupEntityOptions(items) {
    setupEntityOptions = root.formatEntityOptions(items)
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
    if (statusProcess.running || actionProcess.running || setupProcess.running) return false
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
    if (setupProcess.running) return
    setupOpen = true
    setupError = ""
    setupEntityOptions = []
    setupSelectedEntity = ""
    setupToken = ""
    if (setupUrl === "") setupUrl = "http://homeassistant.local:8123"
    Qt.callLater(function() { setupUrlField.forceActiveFocus() })
  }

  function cancelSetup() {
    if (!configured) {
      root.close()
      return
    }
    setupOpen = false
    setupError = ""
    setupEntityOptions = []
    setupSelectedEntity = ""
    setupToken = ""
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
    })
    setupBusy = true
    setupProcess.command = ["python3", root.helperPath, "configure"]
    setupProcess.running = true
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
      if (parsed.url) setupUrl = String(parsed.url)
      if (parsed.entity_id) {
        selectedEntity = String(parsed.entity_id)
        setupSelectedEntity = selectedEntity
      }
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
      if (source === "status" && powerFinalCheckPending) {
        root.clearLocalPower()
        errorText = "Could not refresh Home Assistant after 15 seconds; showing the last known state."
        return
      }
      errorText = "The control helper returned no data."
      return
    }
    try {
      var parsed = JSON.parse(text)
      if (parsed && parsed.configured === false && parsed.ok !== true) {
        configured = false
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
      if (parsed && parsed.ok === true && parsed.requested_mode !== undefined) {
        if (parsed.entity_id) selectedEntity = String(parsed.entity_id)
        errorText = ""
        return
      }
      // set-entity acknowledges with only an entity_id; keep the current
      // climate reading until the follow-up status request completes.
      if (parsed && parsed.ok === true && parsed.ambient === undefined && parsed.target === undefined) {
        if (parsed.entity_id) selectedEntity = String(parsed.entity_id)
        pendingEntity = ""
        errorText = ""
        return
      }
      if (parsed && parsed.ok === true) {
        configured = true
        reading = parsed
        selectedEntity = String(parsed.entity_id || selectedEntity)
        pendingEntity = ""
        if (source === "status" && hasLocalPower && !actionProcess.running
            && parsed.state !== undefined) {
          var observedOn = String(parsed.state || "").toLowerCase() !== "off"
          var requestedOn = localPower
          if (observedOn === requestedOn) {
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
        errorText = ""
      } else {
        if (source === "action" && hasLocalPower) {
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
        if (source === "action" && actionKind === "temperature") {
          var failedTarget = temperatureInFlight
          if (failedTarget !== null && (!hasLocalTarget || sameTemperature(localTarget, failedTarget))) {
            localTarget = null
            lastTemperatureSent = null
          }
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
      if (source === "status" && powerFinalCheckPending) {
        root.clearLocalPower()
        errorText = "Home Assistant returned invalid status data; showing the last known state."
        return
      }
      errorText = "The controller returned invalid data."
    }
  }

  function chooseEntity(value) {
    var next = String(value || "")
    if (!next || next === selectedEntity || actionProcess.running) return
    pendingEntity = next
    localTarget = null
    root.clearLocalPower()
    lastTemperatureSent = null
    actionKind = "entity"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-entity", next]
    actionProcess.running = true
  }

  function adjustTarget(direction) {
    if (!connected || !isOn || targetValue === null || targetValue === undefined) return
    var next = normalizeTarget(Number(targetValue) + direction * temperatureStep)
    if (next === null) return
    localTarget = next
    temperatureCommitTimer.restart()
  }

  function previewTarget(value) {
    if (!connected || !isOn) return
    var next = normalizeTarget(value)
    if (next === null) return
    localTarget = next
  }

  function commitTarget(value) {
    root.previewTarget(value)
    temperatureCommitTimer.restart()
  }

  function commitPendingTemperature() {
    if (!connected || !isOn || !hasLocalTarget) return
    var value = Number(localTarget)
    if (!isFinite(value)) return
    if (temperatureInFlight !== null || actionProcess.running) return
    if (lastTemperatureSent !== null && sameTemperature(value, lastTemperatureSent)) return
    temperatureInFlight = value
    actionKind = "temperature"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-temperature", String(value)]
    actionProcess.running = true
  }

  function requestPower(requestedPower, cancellable) {
    pendingPowerState = requestedPower === "on" ? "turning_on" : "turning_off"
    powerRequestStartedAt = Date.now()
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
    actionKind = "power"
    actionBusy = true
    actionProcess.command = ["python3", root.helperPath, "set-power", requestedPower]
    actionProcess.running = true
  }

  function togglePower() {
    if (actionProcess.running || !connected || hasLocalPower) return
    root.requestPower(isOn ? "off" : "on", true)
  }

  function cancelPower() {
    if (!connected || !hasLocalPower || !powerCanCancel) return
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
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyResult(text, "action")
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("aircon-control", text.trim())
    }
    onExited: {
      var completedKind = actionKind
      var queuedPower = queuedPowerRequest
      if (completedKind === "temperature") {
        var completedTarget = temperatureInFlight
        temperatureInFlight = null
        if (hasLocalTarget && completedTarget !== null && !sameTemperature(localTarget, completedTarget))
          temperatureCommitTimer.restart()
      }
      actionBusy = false
      actionKind = ""
      if (queuedPower !== "") {
        queuedPowerRequest = ""
        Qt.callLater(function() { root.dispatchPowerRequest(queuedPower) })
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

  readonly property int pollSeconds: Math.max(15, Number(setting("poll_seconds", 30)) || 30)
  Timer {
    interval: root.pollSeconds * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onOpenedChanged: if (opened) root.refresh()

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.openFromHotkey() }
    function close(): void { root.close() }
    function show(): void { root.openFromHotkey() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refresh(); return "ok" }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.setupOpen ? Style.space(420) : Style.space(360))
    contentHeight: panel.fittedContentHeight(root.setupOpen
      ? onboardingColumn.implicitHeight : column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.setupOpen && (setupUrlField.activeFocus
        || setupTokenField.activeFocus || setupEntityDropdown.popupOpen)
      onCloseRequested: root.close()
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

      Column {
        id: onboardingColumn
        visible: root.setupOpen
        anchors.fill: parent
        spacing: Style.space(10)

        BorderSurface {
          id: setupHero
          width: parent.width
          height: Style.space(144)
          radius: root.panelRadius
          color: root.alpha(Color.accent, 0.07)
          gradient: Gradient {
            GradientStop { position: 0.0; color: root.alpha(Color.accent, 0.22) }
            GradientStop { position: 0.58; color: root.alpha(Color.accent, 0.07) }
            GradientStop { position: 1.0; color: root.alpha(root.foreground, 0.025) }
          }
          borderSpec: Border.flat(root.alpha(Color.accent, 0.42), 1)

          Column {
            anchors.centerIn: parent
            width: parent.width - Style.space(36)
            spacing: Style.space(7)

            BorderSurface {
              width: Style.space(48)
              height: width
              anchors.horizontalCenter: parent.horizontalCenter
              radius: width / 2
              color: root.alpha(Color.accent, 0.18)
              borderSpec: Border.flat(root.alpha(Color.accent, 0.62), 1)

              Text {
                anchors.centerIn: parent
                text: "󰜗"
                color: Color.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                font.bold: true
              }
            }

            Text {
              width: parent.width
              text: "COOL AIR, ONE CLICK AWAY"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: parent.width
              text: "Connect Home Assistant once, then keep your Daikin control in the bar."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }
          }
        }

        BorderSurface {
          id: setupCard
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
                color: Color.accent
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
              enabled: !root.setupBusy
              placeholderText: "http://homeassistant.local:8123"
              text: root.setupUrl
              foreground: root.foreground
              accent: Color.accent
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
              enabled: !root.setupBusy
              password: true
              placeholderText: root.configured
                ? "Paste a new token to replace the saved one"
                : "Paste your Home Assistant token"
              text: root.setupToken
              foreground: root.foreground
              accent: Color.accent
              font.family: root.fontFamily
              selectByMouse: true
              onTextChanged: if (text !== root.setupToken) root.setupToken = text
              onAccepted: root.submitSetup()
              Keys.onEscapePressed: if (root.configured) root.cancelSetup()
            }

            Text {
              width: parent.width
              text: "Create one in Home Assistant → your profile → Security → Long-Lived Access Tokens."
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
              accent: Color.accent
              fontFamily: root.fontFamily
              controlRadius: root.compactRadius
              onChanged: function(value) { root.setupSelectedEntity = value }
            }

            BorderSurface {
              visible: root.setupError !== ""
              width: parent.width
              implicitHeight: setupMessage.implicitHeight + Style.space(18)
              color: root.alpha(root.setupEntityOptions.length > 0 ? Color.accent : root.urgent, 0.09)
              borderSpec: Border.flat(root.alpha(root.setupEntityOptions.length > 0 ? Color.accent : root.urgent, 0.32), 1)
              radius: root.compactRadius

              Text {
                id: setupMessage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                text: root.setupError
                color: root.setupEntityOptions.length > 0 ? Color.accent : root.urgent
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
            }

            BorderSurface {
              width: parent.width
              implicitHeight: setupPrivacy.implicitHeight + Style.space(18)
              color: root.alpha(root.foreground, 0.025)
              borderSpec: Border.flat(root.alpha(root.foreground, 0.11), 1)
              radius: root.compactRadius

              Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(10)
                spacing: Style.space(8)

                Text {
                  id: setupPrivacyIcon
                  text: "󰌆"
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  id: setupPrivacy
                  width: parent.width - Style.space(8) - setupPrivacyIcon.width
                  text: "Your token is stored locally with owner-only permissions and is only sent to your Home Assistant server."
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

              Button {
                id: cancelSetupButton
                visible: root.configured
                width: visible ? Style.space(94) : 0
                height: Style.space(40)
                text: "CANCEL"
                fontSize: Style.font.bodySmall
                enabled: !root.setupBusy
                fontFamily: root.fontFamily
                foreground: root.foreground
                accent: Color.accent
                background: root.alpha(root.foreground, 0.025)
                bordered: true
                radius: root.compactRadius
                onClicked: root.cancelSetup()
              }

              Button {
                width: parent.width - cancelSetupButton.width
                  - (cancelSetupButton.visible ? parent.spacing : 0)
                height: Style.space(40)
                text: root.setupActionLabel
                iconText: root.setupBusy ? "" : "→"
                iconSize: Style.font.body
                fontSize: Style.font.bodySmall
                enabled: root.setupCanSubmit
                fontFamily: root.fontFamily
                foreground: Color.popups.background
                accent: Color.accent
                background: Color.accent
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
            }
          }
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

      Column {
        id: column
        visible: !root.setupOpen
        anchors.fill: parent
        spacing: Style.space(10)

        BorderSurface {
          id: heroCard
          width: parent.width
          height: Style.space(84)
          radius: root.panelRadius
          color: root.alpha(Color.accent, root.isOn ? 0.10 : 0.04)
          gradient: Gradient {
            GradientStop { position: 0.0; color: root.alpha(Color.accent, root.isOn ? 0.24 : 0.10) }
            GradientStop { position: 0.58; color: root.alpha(Color.accent, root.isOn ? 0.08 : 0.035) }
            GradientStop { position: 1.0; color: root.alpha(root.foreground, 0.025) }
          }
          borderSpec: Border.flat(
            root.isOn ? root.alpha(Color.accent, 0.58) : root.alpha(root.foreground, 0.18), 1)

          Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: Style.space(16)
            width: Style.space(44)
            height: Style.space(3)
            radius: height / 2
            color: root.isOn ? Color.accent : root.alpha(root.foreground, 0.32)
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
              color: root.isOn ? root.alpha(Color.accent, 0.18) : root.alpha(root.foreground, 0.05)
              borderSpec: Border.flat(root.isOn ? root.alpha(Color.accent, 0.78) : root.alpha(root.foreground, 0.22), 1)

              Rectangle {
                id: iconGlow
                anchors.centerIn: parent
                width: Style.space(42)
                height: width
                radius: width / 2
                color: Color.accent
                opacity: root.isOn ? 0.16 : 0
                scale: root.isOn ? 1.0 : 0.72

                Behavior on opacity { NumberAnimation { duration: 220 } }
                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
              }

              Text {
                anchors.centerIn: parent
                text: "󰜗"
                color: root.isOn ? Color.accent : root.dim
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
                  text: root.connected ? String(root.reading.name || "Air conditioner") : "Daikin Air"
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
                accent: Color.accent
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
          accent: Color.accent
          fontFamily: root.fontFamily
          controlRadius: root.compactRadius
          onChanged: function(value) { root.chooseEntity(value) }
        }

        PanelSeparator {
          foreground: root.foreground
          strength: 0.08
        }

        Item {
          width: parent.width
          implicitHeight: Math.max(temperatureHeader.implicitHeight, moodPill.height)
          height: implicitHeight

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
            color: root.alpha(Color.accent, root.moodText === "COMFY" ? 0.16 : 0.09)
            borderSpec: Border.flat(root.alpha(Color.accent, root.moodText === "COMFY" ? 0.55 : 0.32), 1)

            Text {
              id: moodTextLabel
              anchors.centerIn: parent
              text: root.moodText
              color: Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.spacing.md

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
              ? root.alpha(Color.accent, root.hasLocalTarget ? 0.14 : 0.08)
              : root.alpha(root.foreground, 0.035)
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: root.isOn
                  ? root.alpha(Color.accent, root.hasLocalTarget ? 0.22 : 0.14)
                  : root.alpha(root.foreground, 0.075)
              }
              GradientStop {
                position: 1.0
                color: root.isOn
                  ? root.alpha(Color.accent, root.hasLocalTarget ? 0.06 : 0.025)
                  : root.alpha(root.foreground, 0.018)
              }
            }
            borderSpec: Border.flat(
              root.isOn
                ? root.alpha(Color.accent, root.hasLocalTarget ? 0.72 : 0.38)
                : root.alpha(root.foreground, 0.16), 1)

            Rectangle {
              visible: root.isOn
              anchors.top: parent.top
              anchors.horizontalCenter: parent.horizontalCenter
              width: Style.space(26)
              height: Style.space(2)
              radius: height / 2
              color: Color.accent
            }

            Text {
              id: targetLabel
              anchors.top: parent.top
              anchors.topMargin: temperatureSlider.visible ? Style.space(9) : Style.space(17)
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.hasLocalTarget ? "SYNCING" : "TARGET"
              color: root.hasLocalTarget ? Color.accent : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.9

              Behavior on anchors.topMargin { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
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
                foreground: root.isOn ? Color.accent : root.dim
                accent: Color.accent
                background: root.isOn ? root.alpha(Color.accent, 0.09) : root.alpha(root.foreground, 0.025)
                bordered: true
                tooltipText: "Lower target temperature"
                onClicked: root.adjustTarget(-1)

                OpticalGlyph {
                  anchors.fill: parent
                  text: "−"
                  fontFamily: root.fontFamily
                  fontSize: Style.font.display
                  color: decreaseTargetButton.enabled
                    ? (decreaseTargetButton.hot ? root.foreground : Color.accent)
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
                  color: root.isOn ? (root.hasLocalTarget ? Color.accent : root.foreground) : root.dim
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
                foreground: root.isOn ? Color.accent : root.dim
                accent: Color.accent
                background: root.isOn ? root.alpha(Color.accent, 0.09) : root.alpha(root.foreground, 0.025)
                bordered: true
                tooltipText: "Raise target temperature"
                onClicked: root.adjustTarget(1)

                OpticalGlyph {
                  anchors.fill: parent
                  text: "+"
                  fontFamily: root.fontFamily
                  fontSize: Style.font.display
                  color: increaseTargetButton.enabled
                    ? (increaseTargetButton.hot ? root.foreground : Color.accent)
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
              trackColor: root.alpha(Color.accent, 0.22)
              fillColor: Color.accent
              knobColor: Color.accent
              tickCount: 3
              tickColor: root.alpha(Color.popups.background, 0.82)
              onMoved: function(value) { root.previewTarget(value) }
              onReleased: function(value) { root.commitTarget(value) }
            }
          }
        }

        Item {
          id: powerControl
          width: parent.width
          height: Style.space(48)

          Button {
            anchors.fill: parent
            visible: opacity > 0
            opacity: root.hasLocalPower ? 0 : 1
            iconText: "⏻"
            iconSize: Style.font.display
            text: root.isOn ? "TURN OFF" : "TURN ON"
            fontSize: Style.font.bodySmall
            enabled: root.connected && !root.actionBusy && !root.hasLocalPower
            fontFamily: root.fontFamily
            foreground: root.isOn ? Color.accent : root.foreground
            accent: Color.accent
            background: root.isOn ? root.alpha(Color.accent, 0.13) : root.alpha(root.foreground, 0.035)
            bordered: true
            tooltipText: root.isOn ? "Turn off" : "Turn on"
            onClicked: root.togglePower()

            Behavior on opacity { NumberAnimation { duration: 150 } }
          }

          Row {
            anchors.fill: parent
            visible: opacity > 0
            opacity: root.hasLocalPower ? 1 : 0
            spacing: cancelPowerButton.width > 0 ? Style.space(8) : 0

            Behavior on opacity { NumberAnimation { duration: 150 } }

            BorderSurface {
              width: parent.width - cancelPowerButton.width - parent.spacing
              height: parent.height
              radius: root.compactRadius
              color: root.alpha(Color.accent, 0.12)
              borderSpec: Border.flat(root.alpha(Color.accent, 0.42), 1)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(8)

                LoadingRing {
                  width: Style.space(18)
                  height: width
                  anchors.verticalCenter: parent.verticalCenter
                  color: Color.accent
                  strokeWidth: Style.space(2)
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.localPower ? "POWERING ON…" : "POWERING OFF…"
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  font.letterSpacing: 0.6
                }
              }

              Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            Button {
              id: cancelPowerButton
              width: root.powerCanCancel ? Style.space(86) : 0
              height: parent.height
              visible: width > 0
              opacity: root.powerCanCancel ? 1 : 0
              text: "CANCEL"
              fontSize: Style.font.bodySmall
              enabled: root.powerCanCancel
              fontFamily: root.fontFamily
              foreground: root.foreground
              accent: Color.accent
              background: root.alpha(root.foreground, 0.035)
              bordered: true
              radius: root.compactRadius
              tooltipText: "Reverse this power request"
              onClicked: root.cancelPower()

              Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
              Behavior on opacity { NumberAnimation { duration: 120 } }
            }
          }
        }

        BorderSurface {
          visible: root.errorText !== ""
          width: parent.width
          implicitHeight: errorLabel.implicitHeight + Style.space(20)
          color: root.alpha(root.urgent, 0.10)
          borderSpec: Border.flat(root.alpha(root.urgent, 0.35), 1)
          radius: root.panelRadius

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
  }
}
