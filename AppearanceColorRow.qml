import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import qs.Commons
import qs.Ui

// Compact colour editor shared by the appearance settings and per-device
// colour rows. The hex field stays available for precise values; the swatch
// button opens the native Qt picker for quick experimentation.
Item {
  id: root

  property string label: "COLOUR"
  property color valueColor: "#8FA79F"
  property string valueText: "#8FA79F"
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property var swatches: []
  property bool enabled: true

  signal submitted(string value)

  implicitHeight: editorRow.height + (root.swatches.length > 0 ? swatchRow.height + Style.space(4) : 0)

  function channel(value) {
    var number = Math.round(Math.max(0, Math.min(1, Number(value))) * 255)
    var text = number.toString(16).toUpperCase()
    return text.length < 2 ? "0" + text : text
  }

  function colorToHex(value) {
    return "#" + channel(value.r) + channel(value.g) + channel(value.b)
  }

  Column {
    anchors.fill: parent
    spacing: Style.space(4)

    Row {
      id: editorRow
      width: parent.width
      height: Style.space(30)
      spacing: Style.space(6)

      Text {
        id: editorLabel
        width: Style.space(126)
        height: parent.height
        text: root.label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      Button {
        id: pickerButton
        width: Style.space(30)
        height: parent.height
        text: ""
        fontFamily: root.fontFamily
        foreground: root.foreground
        accent: root.accent
        background: root.valueColor
        bordered: true
        radius: root.height / 2
        enabled: root.enabled
        tooltipText: "Open the colour picker"
        onClicked: {
          colorDialog.selectedColor = root.valueColor
          colorDialog.open()
        }
      }

      TextField {
        id: valueField
        width: Math.max(Style.space(80), parent.width - editorLabel.width
          - pickerButton.width - applyButton.width - parent.spacing * 3)
        height: parent.height
        text: root.valueText
        placeholderText: "#RRGGBB"
        enabled: root.enabled
        foreground: root.foreground
        accent: root.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        selectByMouse: true
        onAccepted: root.submitted(text)
      }

      Button {
        id: applyButton
        width: Style.space(58)
        height: parent.height
        text: "APPLY"
        fontSize: Style.font.caption
        fontFamily: root.fontFamily
        foreground: Color.popups.background
        accent: root.accent
        background: root.accent
        bordered: false
        radius: root.height / 2
        enabled: root.enabled
        onClicked: root.submitted(valueField.text)
      }
    }

    Row {
      id: swatchRow
      width: parent.width
      height: Style.space(22)
      spacing: Style.space(5)

      Text {
        id: swatchLabel
        width: Style.space(126)
        height: parent.height
        text: ""
      }

      Repeater {
        model: root.swatches

        Button {
          required property var modelData
          width: Style.space(22)
          height: width
          text: ""
          fontFamily: root.fontFamily
          foreground: modelData
          accent: root.accent
          background: modelData
          bordered: true
          radius: width / 2
          selected: root.valueText.toUpperCase() === String(modelData).toUpperCase()
          enabled: root.enabled
          tooltipText: "Use " + modelData
          onClicked: root.submitted(String(modelData))
        }
      }
    }
  }

  ColorDialog {
    id: colorDialog
    title: root.label
    selectedColor: root.valueColor
    onAccepted: root.submitted(root.colorToHex(selectedColor))
  }
}
