import QtQuick
import qs.Commons
import qs.Ui

// A deliberately small, local-only chart. The helper supplies timestamped
// ambient readings; this component only draws them and never fetches data.
Item {
  id: root

  property var points: []
  property real rangeHours: 24
  property string unit: "°C"
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color background: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.035)
  property color borderColor: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
  property string fontFamily: Style.font.family
  property real panelRadius: Style.cornerRadius

  implicitHeight: Style.space(224)
  height: implicitHeight

  function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }

  function numericPoints() {
    var next = []
    if (!Array.isArray(root.points)) return next
    for (var i = 0; i < root.points.length; i++) {
      var item = root.points[i]
      if (!item || !isFinite(Number(item.timestamp)) || !isFinite(Number(item.temperature))) continue
      next.push({
        timestamp: Number(item.timestamp),
        temperature: Number(item.temperature),
      })
    }
    next.sort(function(first, second) { return first.timestamp - second.timestamp })
    return next
  }

  function formatTemperature(value) {
    var number = Number(value)
    if (!isFinite(number)) return "..."
    var rounded = Math.round(number * 10) / 10
    return String(rounded).replace(/\.0$/, "") + root.unit
  }

  function formatHours(value) {
    var number = Number(value)
    if (!isFinite(number)) return "24 H"
    return String(Math.round(number * 100) / 100).replace(/\.0$/, "") + " H"
  }

  function formatTime(timestamp, rangeSeconds) {
    var date = new Date(Number(timestamp) * 1000)
    if (rangeSeconds <= 6 * 60 * 60)
      return Qt.formatTime(date, "HH:mm")
    return Qt.formatDateTime(date, "dd MMM HH:mm")
  }

  function latestText() {
    var values = root.numericPoints()
    return values.length > 0 ? root.formatTemperature(values[values.length - 1].temperature) : "NO DATA"
  }

  BorderSurface {
    anchors.fill: parent
    radius: root.panelRadius
    color: root.background
    borderSpec: Border.flat(root.borderColor, 1)

    Column {
      anchors.fill: parent
      anchors.margins: Style.space(14)
      spacing: Style.space(5)

      Row {
        width: parent.width
        height: Math.max(historyTitle.implicitHeight, historyRange.implicitHeight)

        Column {
          width: parent.width - historyRange.width - Style.space(8)
          spacing: Style.space(1)

          Text {
            id: historyTitle
            text: "AMBIENT HISTORY"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.9
          }

          Text {
            text: "LOCAL LOG · PC ACTIVE TO RECORD"
            color: Qt.darker(root.foreground, 1.6)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 0.35
          }
        }

        Text {
          id: historyRange
          width: implicitWidth
          text: root.formatHours(root.rangeHours)
          color: root.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 0.8
          horizontalAlignment: Text.AlignRight
        }
      }

      Item {
        id: chartFrame
        width: parent.width
        height: parent.height - parent.spacing - historyTitle.implicitHeight

        Canvas {
          id: chart
          anchors.fill: parent
          renderTarget: Canvas.Image

          function drawLabel(context, text, x, y, align) {
            context.textAlign = align || "left"
            context.textBaseline = "middle"
            context.fillText(text, x, y)
          }

          onPaint: {
            var context = getContext("2d")
            context.reset()

            var values = root.numericPoints()
            var left = Style.space(42)
            var right = Math.max(left + 20, width - Style.space(8))
            var top = Style.space(7)
            var bottom = Math.max(top + 20, height - Style.space(24))
            var plotWidth = right - left
            var plotHeight = bottom - top
            var now = Date.now() / 1000
            var rangeSeconds = Math.max(3600, Number(root.rangeHours) * 3600)
            var start = now - rangeSeconds
            var visible = []

            for (var i = 0; i < values.length; i++) {
              if (values[i].timestamp >= start && values[i].timestamp <= now + 300)
                visible.push(values[i])
            }

            var minValue = Infinity
            var maxValue = -Infinity
            for (var j = 0; j < visible.length; j++) {
              minValue = Math.min(minValue, visible[j].temperature)
              maxValue = Math.max(maxValue, visible[j].temperature)
            }
            if (visible.length === 0) {
              minValue = 0
              maxValue = 1
            } else if (Math.abs(maxValue - minValue) < 0.1) {
              minValue -= 0.5
              maxValue += 0.5
            } else {
              var padding = Math.max(0.25, (maxValue - minValue) * 0.12)
              minValue -= padding
              maxValue += padding
            }

            context.font = Style.font.caption + "px '" + root.fontFamily + "'"
            context.fillStyle = root.alpha(root.foreground, 0.58)
            context.lineWidth = 1
            context.strokeStyle = root.alpha(root.foreground, 0.09)

            for (var yIndex = 0; yIndex < 4; yIndex++) {
              var yRatio = yIndex / 3
              var y = top + plotHeight * yRatio
              context.beginPath()
              context.moveTo(left, y)
              context.lineTo(right, y)
              context.stroke()
              var axisValue = maxValue - (maxValue - minValue) * yRatio
              drawLabel(context, root.formatTemperature(axisValue), left - Style.space(7), y, "right")
            }

            for (var xIndex = 0; xIndex < 3; xIndex++) {
              var xRatio = xIndex / 2
              var x = left + plotWidth * xRatio
              context.beginPath()
              context.moveTo(x, top)
              context.lineTo(x, bottom)
              context.stroke()
              drawLabel(
                context,
                root.formatTime(start + rangeSeconds * xRatio, rangeSeconds),
                x,
                height - Style.space(10),
                xIndex === 0 ? "left" : (xIndex === 2 ? "right" : "center")
              )
            }

            if (visible.length === 0) {
              context.fillStyle = root.alpha(root.foreground, 0.54)
              context.textAlign = "center"
              context.textBaseline = "middle"
              context.fillText("Waiting for local readings…", left + plotWidth / 2, top + plotHeight / 2)
              return
            }

            function pointX(item) {
              return left + Math.max(0, Math.min(1, (item.timestamp - start) / rangeSeconds)) * plotWidth
            }
            function pointY(item) {
              return top + (1 - (item.temperature - minValue) / (maxValue - minValue)) * plotHeight
            }
            function drawSegment(segment) {
              if (segment.length === 0) return
              var firstX = pointX(segment[0])
              var firstY = pointY(segment[0])
              var lastX = pointX(segment[segment.length - 1])
              context.beginPath()
              context.moveTo(firstX, bottom)
              context.lineTo(firstX, firstY)
              for (var segmentIndex = 1; segmentIndex < segment.length; segmentIndex++)
                context.lineTo(pointX(segment[segmentIndex]), pointY(segment[segmentIndex]))
              context.lineTo(lastX, bottom)
              context.closePath()
              var fill = context.createLinearGradient(0, top, 0, bottom)
              fill.addColorStop(0, root.alpha(root.accent, 0.22))
              fill.addColorStop(1, root.alpha(root.accent, 0.015))
              context.fillStyle = fill
              context.fill()

              context.beginPath()
              context.moveTo(firstX, firstY)
              for (var lineIndex = 1; lineIndex < segment.length; lineIndex++)
                context.lineTo(pointX(segment[lineIndex]), pointY(segment[lineIndex]))
              context.strokeStyle = root.accent
              context.lineWidth = Style.space(2)
              context.lineJoin = "round"
              context.lineCap = "round"
              context.stroke()
            }

            var gapLimit = Math.max(10 * 60, rangeSeconds * 0.04)
            var segment = [visible[0]]
            for (var pointIndex = 1; pointIndex < visible.length; pointIndex++) {
              if (visible[pointIndex].timestamp - visible[pointIndex - 1].timestamp > gapLimit) {
                drawSegment(segment)
                segment = []
              }
              segment.push(visible[pointIndex])
            }
            drawSegment(segment)

            var latest = visible[visible.length - 1]
            var latestX = pointX(latest)
            var latestY = pointY(latest)
            context.beginPath()
            context.arc(latestX, latestY, Style.space(4), 0, Math.PI * 2)
            context.fillStyle = root.accent
            context.fill()
            context.beginPath()
            context.arc(latestX, latestY, Style.space(7), 0, Math.PI * 2)
            context.strokeStyle = root.alpha(root.accent, 0.28)
            context.lineWidth = Style.space(2)
            context.stroke()
          }

          Component.onCompleted: requestPaint()
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()
          onVisibleChanged: if (visible) requestPaint()

          Connections {
            target: root
            function onPointsChanged() { chart.requestPaint() }
            function onRangeHoursChanged() { chart.requestPaint() }
            function onUnitChanged() { chart.requestPaint() }
          }
        }
      }
    }
  }
}
