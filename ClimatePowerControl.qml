import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// Shared optimistic power control.  The caller owns the latch; this component
// never replaces a pending local state with the slower Home Assistant reading.
Item {
  id: root

  property bool connected: true
  property bool isOn: false
  property bool powerPending: false
  property bool localPowerOn: false
  property bool modePending: false
  property bool powerCanCancel: false
  property bool actionEnabled: true
  property bool cancelEnabled: true
  property bool compact: false
  property bool chromeLess: false
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real panelRadius: Style.cornerRadius

  signal powerRequested(string value)
  signal powerCancelRequested()

  readonly property bool pending: root.powerPending || root.modePending

  implicitHeight: Style.space(48)
  height: implicitHeight
  clip: true

  Button {
    id: idleButton
    anchors.fill: parent
    visible: opacity > 0.01
    opacity: root.pending ? 0 : 1
    iconText: "⏻"
    iconSize: root.compact ? Style.font.caption : Style.font.display
    text: root.compact ? (root.isOn ? "OFF" : "ON")
      : (root.isOn ? "TURN OFF" : "TURN ON")
    fontSize: root.compact ? Style.font.caption : Style.font.bodySmall
    enabled: root.actionEnabled && root.connected && !root.pending
    fontFamily: root.fontFamily
    foreground: root.isOn ? root.accent : root.foreground
    accent: root.accent
    background: root.isOn ? root.alpha(root.accent, 0.13) : root.alpha(root.foreground, 0.035)
    bordered: !root.chromeLess
    radius: root.panelRadius
    tooltipText: root.isOn ? "Turn off" : "Turn on"
    onClicked: root.powerRequested(root.isOn ? "off" : "on")

    Behavior on opacity { NumberAnimation { duration: 140 } }
  }

  Row {
    anchors.fill: parent
    visible: opacity > 0.01
    opacity: root.pending ? 1 : 0
    spacing: root.powerCanCancel ? Style.space(8) : 0

    Behavior on opacity { NumberAnimation { duration: 140 } }

    BorderSurface {
      width: parent.width - cancelButton.width - parent.spacing
      height: parent.height
      radius: root.panelRadius
      color: root.alpha(root.accent, 0.12)
      borderSpec: root.chromeLess
        ? Border.none() : Border.flat(root.alpha(root.accent, 0.42), 1)

      Row {
        anchors.centerIn: parent
        spacing: Style.space(8)

        LoadingRing {
          width: Style.space(18)
          height: width
          anchors.verticalCenter: parent.verticalCenter
          color: root.accent
          strokeWidth: Style.space(2)
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.modePending ? "RESTARTING AC…"
            : root.compact
              ? (root.localPowerOn ? "ON…" : "OFF…")
              : (root.localPowerOn ? "POWERING ON…" : "POWERING OFF…")
          color: root.accent
          font.family: root.fontFamily
          font.pixelSize: root.compact ? Style.font.caption : Style.font.bodySmall
          font.bold: true
          font.letterSpacing: 0.6
        }
      }
    }

    Button {
      id: cancelButton
      width: root.powerCanCancel ? (root.compact ? Style.space(72) : Style.space(86)) : 0
      height: parent.height
      visible: width > 0
      opacity: root.powerCanCancel ? 1 : 0
      text: "CANCEL"
      fontSize: root.compact ? Style.font.caption : Style.font.bodySmall
      enabled: root.powerCanCancel && root.cancelEnabled
      fontFamily: root.fontFamily
      foreground: root.foreground
      accent: root.accent
      background: root.alpha(root.foreground, 0.035)
      bordered: !root.chromeLess
      radius: root.panelRadius
      tooltipText: "Reverse this power request"
      onClicked: root.powerCancelRequested()

      Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: 140 } }
    }
  }

  function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }
}
