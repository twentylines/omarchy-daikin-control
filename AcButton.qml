import QtQuick
import QtQuick.Controls
import qs.Commons

// The plugin owns this button skin so its selected state follows the
// appearance accent. Omarchy's stock Button resolves selected-color to the
// foreground by default, which makes selected tabs look unchanged even when a
// custom accent is active. Keep the stock API so all existing plugin buttons
// receive the fix without touching /usr/share/omarchy.
BorderSurface {
  id: root

  property string text: ""
  property string iconText: ""
  property string tooltipText: ""

  property bool selected: false
  property bool active: false
  property bool hasCursor: false
  property bool focusable: false
  property bool bordered: false

  property color foreground: Color.foreground
  property color background: "transparent"
  property color accent: Color.accent

  // These defaults deliberately use the instance accent, not Color.accent.
  // Callers can still override them for a special-purpose swatch or action.
  property color selectedTextColor: root.accent
  property color selectedFillColor: Qt.rgba(
    root.accent.r, root.accent.g, root.accent.b, Style.selectedFillAlpha)
  property color selectedBorderColor: root.accent
  property int selectedBorderWidth: Style.selectedBorderWidth > 0
    ? Style.selectedBorderWidth
    : (root.bordered ? Style.normalBorderWidth : 0)

  function accentWithAlpha(amount) {
    return Qt.rgba(root.accent.r, root.accent.g, root.accent.b, amount)
  }

  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property real iconSize: Style.font.icon
  property real iconRotation: 0
  property bool iconSpinning: false
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.controlPaddingY
  property bool leftAlign: false

  leftPadding: horizontalPadding
  rightPadding: horizontalPadding
  topPadding: verticalPadding
  bottomPadding: verticalPadding

  property color tooltipBackground: Color.tooltip.background
  property color tooltipForeground: Color.tooltip.text
  property color tooltipBorder: Color.tooltip.border

  signal clicked()
  signal rightClicked()
  signal hovered(bool isHovered)

  activeFocusOnTab: focusable
  Keys.onReturnPressed: if (focusable) root.clicked()
  Keys.onEnterPressed: if (focusable) root.clicked()
  Keys.onSpacePressed: if (focusable) root.clicked()

  implicitWidth: row.implicitWidth + horizontalPadding * 2
    + _reservedBorderLeft + _reservedBorderRight
  implicitHeight: row.implicitHeight + verticalPadding * 2
    + _reservedBorderTop + _reservedBorderBottom
  radius: Style.cornerRadius

  readonly property bool hot: mouseArea.containsMouse || hasCursor
  readonly property bool _showFocusRing: focusable && activeFocus
  readonly property var _tooltipBorderSpec: Border.localOrSurfaceSpec(
    "tooltip", "border", root.tooltipBorder, Color.tooltip.border,
    Math.max(1, Style.normalBorderWidth))
  // Button state tokens in the shell default to the foreground. Resolve the
  // plugin-owned interaction states directly against the instance accent so
  // custom appearance colours remain visible in every state.
  readonly property color _hoverFillColor: root.accentWithAlpha(Style.hoverFillAlpha)
  readonly property color _focusFillColor: root.accentWithAlpha(Style.focusFillAlpha)
  readonly property color _pressedFillColor: root.accentWithAlpha(Style.pressedFillAlpha)
  readonly property var _focusBorderSpec: Border.flat(
    root.accentWithAlpha(Style.focusBorderAlpha), Style.focusBorderWidth)
  readonly property var _hoverBorderSpec: Border.flat(
    root.accentWithAlpha(Style.hoverBorderAlpha), Style.hoverBorderWidth)
  readonly property var _normalBorderSpec: Border.flat(
    root.accentWithAlpha(Style.normalBorderAlpha), Style.normalBorderWidth)
  readonly property var _selectedBorderSpec: root.selectedBorderWidth > 0
    ? Border.flat(root.selectedBorderColor, root.selectedBorderWidth)
    : Border.none()
  readonly property real _reservedBorderTop: Math.max(
    focusable ? Border.top(_focusBorderSpec) : 0,
    Border.top(_hoverBorderSpec),
    Border.top(_selectedBorderSpec),
    bordered ? Border.top(_normalBorderSpec) : 0)
  readonly property real _reservedBorderRight: Math.max(
    focusable ? Border.right(_focusBorderSpec) : 0,
    Border.right(_hoverBorderSpec),
    Border.right(_selectedBorderSpec),
    bordered ? Border.right(_normalBorderSpec) : 0)
  readonly property real _reservedBorderBottom: Math.max(
    focusable ? Border.bottom(_focusBorderSpec) : 0,
    Border.bottom(_hoverBorderSpec),
    Border.bottom(_selectedBorderSpec),
    bordered ? Border.bottom(_normalBorderSpec) : 0)
  readonly property real _reservedBorderLeft: Math.max(
    focusable ? Border.left(_focusBorderSpec) : 0,
    Border.left(_hoverBorderSpec),
    Border.left(_selectedBorderSpec),
    bordered ? Border.left(_normalBorderSpec) : 0)
  readonly property real _reservedContentLeftInset: _reservedBorderLeft + leftPadding
  readonly property var _borderSpec: _showFocusRing ? _focusBorderSpec
    : hot ? _hoverBorderSpec
    : (selected || active) ? _selectedBorderSpec
    : bordered ? _normalBorderSpec
    : Border.none()

  color: mouseArea.pressed ? root._pressedFillColor
    : _showFocusRing ? root._focusFillColor
    : hot ? root._hoverFillColor
    : (selected || active) ? root.selectedFillColor
    : root.background
  borderSpec: _borderSpec

  Behavior on color { ColorAnimation { duration: 120 } }

  ToolTip {
    visible: root.tooltipText !== "" && mouseArea.containsMouse
    text: root.tooltipText
    delay: 400
    padding: 0
    background: BorderSurface {
      color: root.tooltipBackground
      borderSpec: root._tooltipBorderSpec
      radius: 0
    }
    contentItem: Text {
      textFormat: Text.PlainText
      text: root.tooltipText
      color: root.tooltipForeground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      leftPadding: Border.left(root._tooltipBorderSpec) + Style.spacing.controlPaddingX
      rightPadding: Border.right(root._tooltipBorderSpec) + Style.spacing.controlPaddingX
      topPadding: Border.top(root._tooltipBorderSpec) + Style.spacing.controlPaddingY
      bottomPadding: Border.bottom(root._tooltipBorderSpec) + Style.spacing.controlPaddingY
    }
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: root.leftAlign ? parent.left : undefined
    anchors.leftMargin: root.leftAlign ? root._reservedContentLeftInset : 0
    anchors.horizontalCenter: root.leftAlign ? undefined : parent.horizontalCenter
    spacing: Style.spacing.controlGap

    Text {
      textFormat: Text.PlainText
      visible: root.iconText !== ""
      text: root.iconText
      color: (root.selected || root.active) ? root.selectedTextColor : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.iconSize
      rotation: root.iconSpinning ? 0 : root.iconRotation
      transformOrigin: Item.Center
      anchors.verticalCenter: parent.verticalCenter

      RotationAnimation on rotation {
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
        running: root.iconSpinning
      }
    }

    Text {
      textFormat: Text.PlainText
      visible: root.text !== ""
      text: root.text
      color: (root.selected || root.active) ? root.selectedTextColor : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      font.bold: root.selected || root.active
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (root.focusable) root.forceActiveFocus()
      if (mouse.button === Qt.RightButton) root.rightClicked()
      else root.clicked()
    }
  }

  HoverHandler {
    onHoveredChanged: root.hovered(hovered)
  }
}
