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

  readonly property color statusColor: {
    var value = Number(root.pingMs)
    if (!root.connected || !isFinite(value) || value < 0) return root.foreground
    if (value >= 1000) return root.urgentColor
    if (value >= 100) return root.warningColor
    return root.goodColor
  }

  readonly property string statusText: {
    var value = Number(root.pingMs)
    if (!root.connected) return root.offlineText
    if (!isFinite(value) || value < 0) return "WAITING"
    return String(Math.max(0, Math.round(value))) + " MS"
  }

  implicitWidth: statusRow.implicitWidth
  implicitHeight: statusRow.implicitHeight

  Row {
    id: statusRow
    anchors.fill: parent
    spacing: root.statusSpacing

    Item {
      width: root.connected && root.hideConnectedDot ? 0 : Style.space(8)
      height: width
      visible: !(root.connected && root.hideConnectedDot)
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
      text: root.statusText
      color: root.statusColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.8
      verticalAlignment: Text.AlignVCenter
    }
  }
}
