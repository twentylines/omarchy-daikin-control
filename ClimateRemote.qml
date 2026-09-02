import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// Compact per-air-conditioner remote used by the experimental separate mode.
// The parent owns all requests; this component only presents one climate state.
Item {
  id: root

  property var climate: ({})
  property var localState: ({})
  property color foreground: Color.foreground
  property color dim: Qt.darker(foreground, 1.55)
  property color accent: Color.accent
  property color cardAccent: accent
  property color popupBackground: Color.popups.background
  property string fontFamily: Style.font.family
  property real panelRadius: Style.cornerRadius
  property bool powerCancelEnabled: true
  property bool showClimateControls: true
  property bool chromeLess: false

  readonly property bool connected: climate && String(climate.entity_id || "") !== ""
  readonly property bool hasLocalPower: String(localState.power || "") !== ""
  readonly property bool powerPending: hasLocalPower && localState.powerTimedOut !== true
  readonly property bool localPowerOn: String(localState.power || "") === "turning_on"
  readonly property bool powerCanCancel: localState.powerCanCancel === true
    && localState.powerTimedOut !== true
  readonly property bool actualIsOn: connected && String(climate.state || "").toLowerCase() !== "off"
  readonly property bool isOn: connected && (hasLocalPower ? localPowerOn : actualIsOn)
  readonly property bool hasLocalTarget: localState.target !== undefined
    && isFinite(Number(localState.target))
  readonly property real targetValue: hasLocalTarget ? Number(localState.target) : Number(climate.target)
  readonly property string activeMode: String(localState.mode || climate.state || "")
  readonly property string activeFanMode: String(localState.fan || climate.fan_mode || "")
  readonly property real minimumTemperature: isFinite(Number(climate.min_temp))
    ? Number(climate.min_temp) : 16
  readonly property real maximumTemperature: isFinite(Number(climate.max_temp))
    ? Number(climate.max_temp) : 30
  readonly property real temperatureStep: isFinite(Number(climate.step))
    && Number(climate.step) > 0 ? Number(climate.step) : 1
  readonly property var modeOptions: formatOptions(climate.hvac_modes, true)
  readonly property var fanModeOptions: formatOptions(climate.fan_modes, false)
  readonly property var modeDropdownOptions: [{ value: "", label: "MODE" }].concat(modeOptions)
  readonly property var fanModeDropdownOptions: [{ value: "", label: "FAN SPEED" }].concat(fanModeOptions)

  signal temperatureRequested(real value)
  signal modeRequested(string value)
  signal fanModeRequested(string value)
  signal powerRequested(string value)
  signal powerCancelRequested()

  implicitHeight: remoteCard.implicitHeight
  height: implicitHeight

  function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }

  function label(value) {
    var words = String(value || "").replace(/[_-]+/g, " ").split(/\s+/)
    var result = []
    for (var i = 0; i < words.length; i++) {
      if (words[i] !== "") result.push(words[i].charAt(0).toUpperCase() + words[i].slice(1).toLowerCase())
    }
    return result.join(" ")
  }

  function formatOptions(values, excludeOff) {
    var result = []
    if (!Array.isArray(values)) return result
    for (var i = 0; i < values.length; i++) {
      var value = String(values[i] || "")
      if (!value || (excludeOff && value.toLowerCase() === "off")) continue
      var duplicate = false
      for (var j = 0; j < result.length; j++) {
        if (result[j].value.toLowerCase() === value.toLowerCase()) duplicate = true
      }
      if (!duplicate) result.push({ value: value, label: label(value) })
    }
    return result
  }

  function formatTemperature(value) {
    var number = Number(value)
    if (!isFinite(number)) return "—"
    return String(Math.round(number * 10) / 10).replace(/\.0$/, "")
      + String(climate.unit || "°C")
  }

  function adjustedTarget(direction) {
    if (!isOn || !isFinite(targetValue)) return null
    var next = Math.round((targetValue + direction * temperatureStep) / temperatureStep)
      * temperatureStep
    next = Math.round(next * 100) / 100
    return Math.max(minimumTemperature, Math.min(maximumTemperature, next))
  }

  BorderSurface {
    id: remoteCard
    width: parent.width
    implicitHeight: remoteForm.implicitHeight + Style.space(24)
    radius: root.panelRadius
    color: root.chromeLess
      ? "transparent" : root.alpha(root.cardAccent, root.isOn ? 0.075 : 0.035)
    borderSpec: root.chromeLess
      ? Border.none() : Border.flat(root.alpha(root.cardAccent, root.isOn ? 0.30 : 0.14), 1)

    Column {
      id: remoteForm
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: root.chromeLess ? Style.space(4) : Style.space(12)
      spacing: Style.space(7)

      Row {
        width: parent.width
        spacing: Style.space(7)

        Column {
          width: parent.width - remotePowerArea.width - parent.spacing
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: String(root.climate.name || root.climate.entity_id || "Air conditioner")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: root.connected
              ? (root.powerPending
                ? (root.localPowerOn ? "POWERING ON…" : "POWERING OFF…")
                : ("AMBIENT " + root.formatTemperature(root.climate.ambient)
                  + "  ·  " + (root.isOn ? "TARGET " + root.formatTemperature(root.targetValue) : "OFF")))
              : "WAITING FOR HOME ASSISTANT"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }

        ClimatePowerControl {
          id: remotePowerArea
          width: root.powerPending && root.powerCanCancel ? Style.space(134) : Style.space(54)
          height: Style.space(34)
          connected: root.connected
          isOn: root.isOn
          powerPending: root.powerPending
          localPowerOn: root.localPowerOn
          powerCanCancel: root.powerCanCancel
          compact: true
          actionEnabled: root.enabled
          cancelEnabled: root.powerCancelEnabled
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          panelRadius: root.panelRadius
          chromeLess: root.chromeLess
          onPowerRequested: function(value) { root.powerRequested(value) }
          onPowerCancelRequested: root.powerCancelRequested()
        }
      }

      Item {
        id: climateControls
        width: parent.width
        implicitHeight: root.showClimateControls ? climateControlsColumn.implicitHeight : 0
        visible: root.showClimateControls || height > 0.5
        height: implicitHeight
        opacity: root.showClimateControls ? 1 : 0
        clip: true

        Behavior on height {
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on opacity { NumberAnimation { duration: 140 } }

        Column {
          id: climateControlsColumn
          width: parent.width
          spacing: Style.space(7)

          Row {
            width: parent.width
            height: Style.space(34)
            spacing: Style.space(6)

            Text {
              width: Style.space(50)
              height: parent.height
              text: "TARGET"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              verticalAlignment: Text.AlignVCenter
            }

            Button {
              width: Style.space(28)
              height: width
              text: "−"
              fontSize: Style.font.body
              horizontalPadding: 0
              verticalPadding: 0
              fontFamily: root.fontFamily
              foreground: root.accent
              accent: root.accent
              background: root.alpha(root.accent, 0.08)
              bordered: !root.chromeLess
              radius: width / 2
              enabled: root.enabled && root.isOn && !root.powerPending
              tooltipText: "Lower this target temperature"
              onClicked: {
                var next = root.adjustedTarget(-1)
                if (next !== null) root.temperatureRequested(next)
              }
            }

            Text {
              width: Style.space(64)
              height: parent.height
              text: root.isOn ? root.formatTemperature(root.targetValue) : "OFF"
              color: root.isOn ? root.foreground : root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }

            Button {
              width: Style.space(28)
              height: width
              text: "+"
              fontSize: Style.font.body
              horizontalPadding: 0
              verticalPadding: 0
              fontFamily: root.fontFamily
              foreground: root.accent
              accent: root.accent
              background: root.alpha(root.accent, 0.08)
              bordered: !root.chromeLess
              radius: width / 2
              enabled: root.enabled && root.isOn && !root.powerPending
              tooltipText: "Raise this target temperature"
              onClicked: {
                var next = root.adjustedTarget(1)
                if (next !== null) root.temperatureRequested(next)
              }
            }

            Item {
              width: Math.max(0, parent.width - Style.space(50) - Style.space(28)
                - Style.space(64) - Style.space(28) - parent.spacing * 4)
              height: 1
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(6)

            AcDropdown {
              visible: root.modeOptions.length > 0
              width: root.modeOptions.length > 0
                ? (root.fanModeOptions.length > 0 ? (parent.width - parent.spacing) / 2 : parent.width) : 0
              label: "MODE"
              options: root.modeDropdownOptions
              value: root.activeMode
              foreground: root.foreground
              background: root.popupBackground
              popupBorder: Color.popups.border
              accent: root.accent
              fontFamily: root.fontFamily
              controlRadius: root.panelRadius
              chromeLess: root.chromeLess
              enabled: root.enabled && root.isOn && !root.powerPending
              onChanged: function(value) { if (value) root.modeRequested(value) }
            }

            AcDropdown {
              visible: root.fanModeOptions.length > 0
              width: root.fanModeOptions.length > 0
                ? (root.modeOptions.length > 0 ? (parent.width - parent.spacing) / 2 : parent.width) : 0
              label: "FAN SPEED"
              options: root.fanModeDropdownOptions
              value: root.activeFanMode
              foreground: root.foreground
              background: root.popupBackground
              popupBorder: Color.popups.border
              accent: root.accent
              fontFamily: root.fontFamily
              controlRadius: root.panelRadius
              chromeLess: root.chromeLess
              enabled: root.enabled && root.isOn && !root.powerPending
              onChanged: function(value) { if (value) root.fanModeRequested(value) }
            }
          }
        }
      }
    }
  }
}
