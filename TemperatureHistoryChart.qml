import QtQuick
import qs.Commons
import qs.Ui

// A deliberately small chart. The helper supplies timestamped ambient
// readings from either this PC or the configured Home Assistant host; this
// component only draws them and never fetches data.
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
  property string sourceLabel: "LOCAL · LOGGED WHILE PC IS ON"
  property string emptyMessage: "WAITING FOR LOCAL READINGS…"
  property bool connected: false
  property var liveTemperature: null
  property color liveColor: "#79B889"

  implicitHeight: Style.space(248)
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

  function formatTime(timestamp) {
    var date = new Date(Number(timestamp) * 1000)
    return Qt.formatTime(date, "HH:mm")
  }

  function dayKey(timestamp) {
    var date = new Date(Number(timestamp) * 1000)
    return date.getFullYear() + ":" + date.getMonth() + ":" + date.getDate()
  }

  function formatDay(timestamp) {
    return Qt.formatDate(new Date(Number(timestamp) * 1000), "dd MMM")
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
      anchors.margins: Style.space(16)
      spacing: Style.space(7)

      Row {
        id: historyHeader
        width: parent.width
        height: historyHeaderColumn.implicitHeight

        Column {
          id: historyHeaderColumn
          width: parent.width - historyRange.width - Style.space(8)
          spacing: Style.space(2)

          Text {
            id: historyTitle
            width: parent.width
            text: "AMBIENT TEMPERATURE HISTORY"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.9
          }

          Text {
            width: parent.width
            text: root.sourceLabel
            color: Qt.darker(root.foreground, 1.6)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.letterSpacing: 0.35
            elide: Text.ElideRight
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
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Item {
        id: chartFrame
        width: parent.width
        height: Math.max(Style.space(132), parent.height - parent.spacing - historyHeader.height)

        BorderSurface {
          anchors.fill: parent
          radius: root.panelRadius - Style.space(4)
          color: root.alpha(root.foreground, 0.018)
          borderSpec: Border.flat(root.alpha(root.foreground, 0.08), 1)
        }

        Canvas {
          id: chart
          anchors.fill: parent
          anchors.margins: Style.space(1)
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
            var now = Date.now() / 1000
            var rangeSeconds = Math.max(3600, Number(root.rangeHours) * 3600)
            var start = now - rangeSeconds
            var visible = []
            var liveValid = root.connected && isFinite(Number(root.liveTemperature))
            var liveTemperature = Number(root.liveTemperature)

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
            if (liveValid) {
              minValue = Math.min(minValue, liveTemperature)
              maxValue = Math.max(maxValue, liveTemperature)
            }
            if (visible.length === 0 && !liveValid) {
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

            var fontFamily = "'" + root.fontFamily + "'"
            context.font = Style.font.caption + "px " + fontFamily
            var maxLabelWidth = Math.max(
              context.measureText(root.formatTemperature(maxValue)).width,
              context.measureText(root.formatTemperature(minValue)).width
            )
            var left = Math.max(Style.space(56), maxLabelWidth + Style.space(14))
            var right = Math.max(left + Style.space(40), width - Style.space(12))
            var top = Style.space(14)
            var bottom = Math.max(top + Style.space(32), height - Style.space(40))
            var plotWidth = right - left
            var plotHeight = bottom - top
            var longRange = Number(root.rangeHours) > 72
            var labelCount = longRange ? 5 : 3

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
              drawLabel(context, root.formatTemperature(axisValue), left - Style.space(12), y, "right")
            }

            for (var xIndex = 0; xIndex < labelCount; xIndex++) {
              var xRatio = xIndex / (labelCount - 1)
              var x = left + plotWidth * xRatio
              context.beginPath()
              context.moveTo(x, top)
              context.lineTo(x, bottom)
              context.stroke()
              var axisTimestamp = start + rangeSeconds * xRatio
              var axisAlign = xIndex === 0 ? "left" : (xIndex === labelCount - 1 ? "right" : "center")
              if (xIndex > 0 && !longRange) {
                var previousTimestamp = start + rangeSeconds * ((xIndex - 1) / (labelCount - 1))
                if (root.dayKey(axisTimestamp) !== root.dayKey(previousTimestamp)) {
                  context.font = Math.max(8, Style.font.caption - 2) + "px " + fontFamily
                  context.fillStyle = root.alpha(root.foreground, 0.48)
                  drawLabel(context, root.formatDay(axisTimestamp), x, height - Style.space(27), axisAlign)
                }
              }
              context.font = Style.font.caption + "px " + fontFamily
              context.fillStyle = root.alpha(root.foreground, 0.70)
              drawLabel(context, longRange ? root.formatDay(axisTimestamp) : root.formatTime(axisTimestamp),
                x, height - Style.space(11), axisAlign)
            }

            if (visible.length === 0 && !liveValid) {
              context.fillStyle = root.alpha(root.foreground, 0.54)
              context.textAlign = "center"
              context.textBaseline = "middle"
              context.fillText(root.emptyMessage, left + plotWidth / 2, top + plotHeight / 2)
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

            if (visible.length > 0) {
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

            if (liveValid) {
              var liveX = left + plotWidth
              var liveY = pointY(({ timestamp: now, temperature: liveTemperature }))
              context.beginPath()
              context.arc(liveX, liveY, Style.space(5), 0, Math.PI * 2)
              context.fillStyle = root.liveColor
              context.fill()
              context.beginPath()
              context.arc(liveX, liveY, Style.space(9), 0, Math.PI * 2)
              context.strokeStyle = root.alpha(root.liveColor, 0.34)
              context.lineWidth = Style.space(2)
              context.stroke()
            }

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
            function onEmptyMessageChanged() { chart.requestPaint() }
            function onConnectedChanged() { chart.requestPaint() }
            function onLiveTemperatureChanged() { chart.requestPaint() }
          }
        }
      }
    }
  }
}
