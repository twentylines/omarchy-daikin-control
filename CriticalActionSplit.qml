import QtQuick
import qs.Commons
import qs.Ui

// A bounded critical-action control. The confirmation halves are positioned
// directly inside one clipped frame so the transition cannot escape its box.
Item {
  id: root

  property string idleText: "ACTION"
  property string busyText: "WORKING…"
  property string confirmText: "SURE?"
  property string idleIcon: ""
  property string idleTooltip: ""
  property string confirmTooltip: ""
  property string backTooltip: "Go back"
  property color actionColor: Color.accent
  property color actionTextColor: Color.popups.background
  property color idleBackground: Qt.rgba(actionColor.r, actionColor.g, actionColor.b, 0.07)
  property color backTextColor: Color.foreground
  property color backBackground: Qt.rgba(backTextColor.r, backTextColor.g, backTextColor.b, 0.025)
  property real controlRadius: Style.cornerRadius
  property string fontFamily: Style.font.family
  property real backWidth: Style.space(86)
  property real splitGap: Style.space(8)
  property bool confirming: false
  property bool busy: false
  property bool actionEnabled: true
  property bool chromeLess: false
  readonly property int motionDuration: 300

  signal actionRequested()
  signal backRequested()

  implicitHeight: Style.space(42)
  height: implicitHeight
  clip: true

  // The idle button disappears when confirmation opens. Refocus the actual
  // confirmation action after the split has started so global Tab navigation
  // remains in this action instead of jumping to the panel's first control.
  onConfirmingChanged: {
    if (root.confirming) confirmationFocusTimer.restart()
    else confirmationFocusTimer.stop()
  }

  Timer {
    id: confirmationFocusTimer
    interval: 16
    repeat: true
    property int attempts: 0
    onTriggered: {
      attempts += 1
      if (!root.confirming) {
        stop()
        return
      }
      if (confirmButton.enabled && splitFrame.splitProgress > 0.02) {
        confirmButton.forceActiveFocus()
        stop()
      } else if (attempts >= 24) {
        stop()
      }
    }
    onRunningChanged: if (running) attempts = 0
  }

  AcButton {
    id: idleButton
    anchors.fill: parent
    visible: opacity > 0.01
    opacity: 1 - splitFrame.splitProgress
    text: root.busy ? root.busyText : root.idleText
    iconText: ""
    fontSize: Style.font.bodySmall
    fontFamily: root.fontFamily
    horizontalPadding: Style.space(16)
    foreground: root.busy ? root.actionTextColor : root.actionColor
    accent: root.actionColor
    background: root.busy ? root.actionColor : root.idleBackground
    bordered: !root.chromeLess
    radius: root.controlRadius
    enabled: root.actionEnabled && !root.busy && !root.confirming
    tooltipText: root.idleTooltip
    onClicked: root.actionRequested()

    LoadingRing {
      visible: root.busy
      anchors.left: parent.left
      anchors.leftMargin: Style.space(14)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(16)
      height: width
      color: root.actionTextColor
      strokeWidth: Style.space(2)
    }

    Text {
      visible: !root.busy && root.idleIcon !== ""
      anchors.left: parent.left
      anchors.leftMargin: Style.space(14)
      anchors.verticalCenter: parent.verticalCenter
      text: root.idleIcon
      color: root.actionColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      horizontalAlignment: Text.AlignHCenter
      width: Style.space(20)
    }
  }

  Item {
    id: splitFrame
    anchors.fill: parent
    clip: true
    property real splitProgress: root.confirming ? 1 : 0
    readonly property real currentBackWidth: root.backWidth * splitProgress
    readonly property real currentGap: root.splitGap * splitProgress
    visible: opacity > 0.01
    opacity: splitProgress

    Behavior on splitProgress {
      NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
    }

    AcButton {
      id: backButton
      x: 0
      width: splitFrame.currentBackWidth
      height: parent.height
      visible: splitFrame.splitProgress > 0.02
      opacity: Math.min(1, splitFrame.splitProgress * 1.5)
      clip: true
      text: "BACK"
      iconText: "←"
      iconSize: Style.font.body
      fontSize: Style.font.bodySmall
      horizontalPadding: Style.space(4)
      fontFamily: root.fontFamily
      foreground: root.backTextColor
      accent: root.actionColor
      background: root.backBackground
      bordered: !root.chromeLess
      radius: root.controlRadius
      enabled: (root.confirming || root.actionEnabled) && !root.busy
      tooltipText: root.backTooltip
      onClicked: root.backRequested()
    }

    AcButton {
      id: confirmButton
      x: splitFrame.currentBackWidth + splitFrame.currentGap
      width: Math.max(0, parent.width - x)
      height: parent.height
      clip: true
      opacity: splitFrame.splitProgress
      text: root.confirmText
      fontSize: Style.font.bodySmall
      horizontalPadding: Style.space(8)
      fontFamily: root.fontFamily
      foreground: root.actionTextColor
      accent: root.actionColor
      background: root.actionColor
      bordered: false
      radius: root.controlRadius
      enabled: (root.confirming || root.actionEnabled) && !root.busy
      tooltipText: root.confirmTooltip
      onClicked: root.actionRequested()
    }
  }
}
