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
  property color liveColor: "#79B889"

  implicitHeight: Style.space(272)
  height: implicitHeight

  function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }

  function temperatureCelsius(value) {
    var number = Number(value)
    if (!isFinite(number)) return Number.NaN
    var unitText = String(root.unit || "").trim().toLowerCase()
    if (unitText === "k" || unitText === "kelvin") return number - 273.15
    if (unitText === "f" || unitText === "°f" || unitText === "fahrenheit")
      return (number - 32) * 5 / 9
    return number
  }

  function mixTemperatureColors(first, second, amount) {
    var t = Math.max(0, Math.min(1, Number(amount)))
    return Qt.rgba(
      first.r + (second.r - first.r) * t,
      first.g + (second.g - first.g) * t,
      first.b + (second.b - first.b) * t,
      1)
  }

  function temperatureColor(value) {
    var celsius = root.temperatureCelsius(value)
    if (!isFinite(celsius)) return root.accent

    // Keep the chart in the same restrained cool/green/warm language as the
    // ambient card. Only genuinely hot readings progress to a strong red.
    var blue = Qt.rgba(0.36, 0.55, 0.66, 1)
    var green = Qt.rgba(0.46, 0.64, 0.53, 1)
    var amber = Qt.rgba(0.73, 0.59, 0.40, 1)
    var warm = Qt.rgba(0.76, 0.45, 0.40, 1)
    var hot = Qt.rgba(0.84, 0.27, 0.29, 1)

    if (celsius <= 24) return blue
    if (celsius < 27) return root.mixTemperatureColors(blue, green, (celsius - 24) / 3)
    if (celsius < 30) return root.mixTemperatureColors(green, amber, (celsius - 27) / 3)
    if (celsius < 33) return root.mixTemperatureColors(amber, warm, (celsius - 30) / 3)
    return root.mixTemperatureColors(warm, hot, Math.min(1, (celsius - 33) / 2))
  }

  function addTemperatureGradientStops(gradient, minimum, maximum, topAlpha, bottomAlpha) {
    var span = Math.max(0.001, Number(maximum) - Number(minimum))
    var stops = [Number(minimum), Number(maximum), 24, 27, 30, 33, 35]
      .filter(function(value) { return value >= minimum && value <= maximum })
    stops.sort(function(first, second) { return second - first })

    var previous = Number.NaN
    for (var i = 0; i < stops.length; i++) {
      if (isFinite(previous) && Math.abs(stops[i] - previous) < 0.001) continue
      var offset = (Number(maximum) - stops[i]) / span
      var alphaValue = topAlpha + (bottomAlpha - topAlpha) * offset
      gradient.addColorStop(offset, root.alpha(root.temperatureColor(stops[i]), alphaValue))
      previous = stops[i]
    }
  }

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

  function visiblePointsInRange() {
    var values = root.numericPoints()
    var now = Date.now() / 1000
    var rangeSeconds = Math.max(3600, Number(root.rangeHours) * 3600)
    var start = now - rangeSeconds
    var visible = []
    for (var i = 0; i < values.length; i++) {
      if (values[i].timestamp >= start && values[i].timestamp <= now + 300)
        visible.push(values[i])
    }
    return visible
  }

  function historySummary() {
    var visible = root.visiblePointsInRange()
    if (visible.length === 0)
      return { peak: Number.NaN, average: Number.NaN, low: Number.NaN }

    var peak = -Infinity
    var low = Infinity
    var total = 0
    for (var i = 0; i < visible.length; i++) {
      var value = Number(visible[i].temperature)
      peak = Math.max(peak, value)
      low = Math.min(low, value)
      total += value
    }
    return { peak: peak, average: total / visible.length, low: low }
  }

  function summaryValue(kind) {
    var summary = root.summaryValues
    var normalized = String(kind).toUpperCase()
    if (normalized === "PEAK") return Number(summary.peak)
    if (normalized === "AVERAGE") return Number(summary.average)
    return Number(summary.low)
  }

  function summaryValueText(value) {
    return isFinite(Number(value)) ? root.formatTemperature(value) : "—"
  }

  property var summaryValues: root.historySummary()

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
        height: Math.max(historyHeaderColumn.implicitHeight, historyStatus.implicitHeight)

        Column {
          id: historyHeaderColumn
          width: parent.width - historyStatus.implicitWidth - Style.space(8)
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

        Row {
          id: historyStatus
          width: implicitWidth
          height: implicitHeight
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(5)

          Item {
            width: Style.space(8)
            height: width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              id: liveIndicatorDot
              anchors.centerIn: parent
              width: Style.space(5)
              height: width
              radius: width / 2
              color: root.liveColor
              opacity: root.connected ? 1 : 0.35

              SequentialAnimation on opacity {
                running: root.connected
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
              }

              SequentialAnimation on scale {
                running: root.connected
                loops: Animation.Infinite
                NumberAnimation { to: 1.3; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
              }
            }
          }

          Text {
            text: root.formatHours(root.rangeHours)
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.8
            horizontalAlignment: Text.AlignRight
          }
        }
      }

      BorderSurface {
        id: historySummary
        width: parent.width
        height: Style.space(44)
        radius: root.panelRadius
        color: root.alpha(root.foreground, 0.018)
        borderSpec: Border.flat(root.alpha(root.foreground, 0.08), 1)

        Row {
          id: historySummaryContent
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(10)

          Repeater {
          model: [
            { key: "PEAK", label: "Peak" },
            { key: "AVERAGE", label: "Average" },
            { key: "LOW", label: "Low" },
          ]

          Item {
            required property var modelData
            property real summaryValue: root.summaryValue(modelData.key)
            property color summaryColor: isFinite(summaryValue)
              ? root.temperatureColor(summaryValue) : root.alpha(root.foreground, 0.55)

            width: historySummaryContent.width / 3
            height: historySummaryContent.height

            Column {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(1)

              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(5)

                Rectangle {
                  width: Style.space(5)
                  height: width
                  radius: width / 2
                  anchors.verticalCenter: parent.verticalCenter
                  color: summaryColor
                }

                Text {
                  text: modelData.label
                  color: root.alpha(root.foreground, 0.72)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              Text {
                width: parent.width
                text: root.summaryValueText(summaryValue)
                color: summaryColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
            }

            Rectangle {
              visible: modelData.key !== "LOW"
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: Style.space(24)
              color: root.alpha(root.foreground, 0.08)
            }
          }
        }
      }
      }

      Item {
        id: chartFrame
        width: parent.width
        height: Math.max(Style.space(132), parent.height - parent.spacing * 2
          - historyHeader.height - historySummary.height)

        BorderSurface {
          anchors.fill: parent
          radius: root.panelRadius
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

            var now = Date.now() / 1000
            var rangeSeconds = Math.max(3600, Number(root.rangeHours) * 3600)
            var start = now - rangeSeconds
            var visible = root.visiblePointsInRange()

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

            if (visible.length === 0) {
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
              root.addTemperatureGradientStops(fill, minValue, maxValue, 0.20, 0.012)
              context.fillStyle = fill
              context.fill()

              context.beginPath()
              context.moveTo(firstX, firstY)
              for (var lineIndex = 1; lineIndex < segment.length; lineIndex++)
                context.lineTo(pointX(segment[lineIndex]), pointY(segment[lineIndex]))
              var lineGradient = context.createLinearGradient(0, top, 0, bottom)
              root.addTemperatureGradientStops(lineGradient, minValue, maxValue, 0.98, 0.98)
              context.strokeStyle = lineGradient
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
              var latestColor = root.temperatureColor(latest.temperature)
              context.beginPath()
              context.arc(latestX, latestY, Style.space(4), 0, Math.PI * 2)
              context.fillStyle = latestColor
              context.fill()
              context.beginPath()
              context.arc(latestX, latestY, Style.space(7), 0, Math.PI * 2)
              context.strokeStyle = root.alpha(latestColor, 0.30)
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
          }
        }
      }
    }
  }
}
