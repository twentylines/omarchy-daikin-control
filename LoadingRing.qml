import QtQuick

Item {
  id: root

  property color color: "white"
  property real strokeWidth: 2
  property bool running: true
  readonly property color trackColor: Qt.rgba(color.r, color.g, color.b, 0.20)

  Canvas {
    id: ring
    anchors.fill: parent

    function repaint() { requestPaint() }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
      var context = getContext("2d")
      var inset = root.strokeWidth / 2 + 1
      var radius = Math.max(0, Math.min(width, height) / 2 - inset)
      var centerX = width / 2
      var centerY = height / 2
      var start = -Math.PI / 2

      context.reset()
      context.lineWidth = root.strokeWidth
      context.lineCap = "round"
      context.strokeStyle = root.trackColor
      context.beginPath()
      context.arc(centerX, centerY, radius, 0, Math.PI * 2)
      context.stroke()

      context.strokeStyle = root.color
      context.beginPath()
      context.arc(centerX, centerY, radius, start, start + Math.PI * 1.55)
      context.stroke()
    }

    Connections {
      target: root
      function onColorChanged() { ring.requestPaint() }
      function onStrokeWidthChanged() { ring.requestPaint() }
    }

    RotationAnimator on rotation {
      running: root.running && root.visible
      from: 0
      to: 360
      duration: 760
      loops: Animation.Infinite
    }
  }
}
