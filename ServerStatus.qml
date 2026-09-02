import QtQuick
import qs.Commons
import qs.Ui

// Compact connection readout shared by the server cards. The dot is the
// connection indicator; latency changes its color when the server is slow.
Item {
  id: root

  property bool connected: false
  property real pingMs: -1
  property bool hideConnectedDot: false
  property real statusSpacing: Style.space(5)
  property color goodColor: "#79B889"
  property color warningColor: "#D0A66A"
  property color urgentColor: Color.urgent
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property string offlineText: "OFFLINE"
  property string metricLabel: ""
  // When enabled, place the animated status dot between the metric label and
  // its value. A parent row can then use a quiet separator before the label.
  property bool metricDotBeforeValue: false
  property real warningThresholdMs: 150
  property real urgentThresholdMs: 500

  readonly property color statusColor: {
    var value = Number(root.pingMs)
    if (!root.connected || !isFinite(value) || value < 0) return root.foreground
    if (value > root.urgentThresholdMs) return root.urgentColor
    if (value >= root.warningThresholdMs) return root.warningColor
    return root.goodColor
  }

  readonly property string statusText: {
    var value = Number(root.pingMs)
    if (!root.connected) return root.offlineText
    if (!isFinite(value) || value < 0) return "WAITING"
    var metric = root.metricLabel !== "" ? root.metricLabel + " · " : ""
    return metric + String(Math.max(0, Math.round(value))) + " MS"
  }
  readonly property bool metricValueLayoutVisible: root.metricDotBeforeValue
    && root.metricLabel !== ""
    && root.connected
    && isFinite(Number(root.pingMs))
    && Number(root.pingMs) >= 0
  readonly property string metricValueText: {
    var value = Number(root.pingMs)
    return isFinite(value) && value >= 0
      ? String(Math.max(0, Math.round(value))) + " MS" : ""
  }

  implicitWidth: statusRow.implicitWidth
  implicitHeight: statusRow.implicitHeight

  Row {
    id: statusRow
    anchors.fill: parent
    spacing: root.statusSpacing

    Item {
      width: root.metricValueLayoutVisible
        ? 0 : (root.connected && root.hideConnectedDot ? 0 : Style.space(8))
      height: width
      visible: !root.metricValueLayoutVisible
        && !(root.connected && root.hideConnectedDot)
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        id: statusDot
        anchors.centerIn: parent
        width: Style.space(5)
        height: width
        radius: width / 2
        color: root.statusColor
        opacity: root.connected ? 1 : 0.45

        SequentialAnimation on opacity {
          running: root.connected && root.visible && !root.hideConnectedDot
          loops: Animation.Infinite
          NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
        }

        SequentialAnimation on scale {
          running: root.connected && root.visible && !root.hideConnectedDot
          loops: Animation.Infinite
          NumberAnimation { to: 1.3; duration: 700; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
        }
      }
    }

    Text {
      visible: root.metricValueLayoutVisible
      text: root.metricLabel
      color: root.statusColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.8
      verticalAlignment: Text.AlignVCenter
    }

    Item {
      width: root.metricValueLayoutVisible ? Style.space(8) : 0
      height: width
      visible: root.metricValueLayoutVisible
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.centerIn: parent
        width: Style.space(5)
        height: width
        radius: width / 2
        color: root.statusColor

        SequentialAnimation on opacity {
          running: root.metricValueLayoutVisible && root.visible
          loops: Animation.Infinite
          NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
        }

        SequentialAnimation on scale {
          running: root.metricValueLayoutVisible && root.visible
          loops: Animation.Infinite
          NumberAnimation { to: 1.3; duration: 700; easing.type: Easing.InOutQuad }
          NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
        }
      }
    }

    Text {
      visible: !root.metricValueLayoutVisible
      text: root.statusText
      color: root.statusColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.8
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      visible: root.metricValueLayoutVisible
      text: root.metricValueText
      color: root.statusColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.8
      verticalAlignment: Text.AlignVCenter
    }
  }
}
