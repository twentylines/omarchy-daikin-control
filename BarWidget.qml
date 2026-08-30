import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "sai.homeassistant-ac"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  function togglePower() {
    var panel = panelLoader.item
    if (!panel) return
    if (panel.modeRestarting) return
    if (panel.hasLocalPower && panel.powerCanCancel && panel.cancelPower)
      panel.cancelPower()
    else if (panel.togglePower)
      panel.togglePower()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property bool powerPending: panelLoader.item
    ? panelLoader.item.hasLocalPower === true || panelLoader.item.modeRestarting === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch)
      panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontSize: Style.bar.iconFont
    labelVisible: false
    hasVisualContent: true
    fixedHeight: root.barSize
    fixedWidth: root.vertical ? root.barSize : -1
    horizontalMargin: 0
    implicitWidth: root.vertical ? root.barSize : Math.max(Style.bar.iconSlot, barContent.implicitWidth)
    active: panelLoader.item ? panelLoader.item.isOn : false
    tooltipText: panelLoader.item ? panelLoader.item.tooltip : "Daikin Air · click to connect"
    activeColor: Color.accent

    Row {
      id: barContent
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      height: Style.bar.iconCanvas
      spacing: Style.space(2)

      Item {
        width: Style.bar.iconSlot
        height: Style.bar.iconCanvas

        OpticalGlyph {
          anchors.centerIn: parent
          width: Style.bar.iconCanvas
          height: Style.bar.iconCanvas
          text: panelLoader.item
            ? panelLoader.item.climateModeIcon(panelLoader.item.activeMode) : "󰜗"
          visible: !root.powerPending
          color: button.active && button.useActiveColor ? button.activeColor : button.foreground
          fontFamily: button.fontFamily
          fontSize: Style.bar.iconFont
        }

        LoadingRing {
          anchors.centerIn: parent
          width: Style.bar.iconCanvas
          height: Style.bar.iconCanvas
          visible: root.powerPending
          color: button.activeColor
          strokeWidth: Style.space(2)
          running: root.powerPending
        }
      }

      Row {
        id: activeValues
        visible: !root.vertical && !root.powerPending
          && (panelLoader.item ? panelLoader.item.connected && panelLoader.item.isOn : false)
        height: Style.bar.iconCanvas
        // Explicit positioner spacing keeps the values readable without
        // relying on Unicode or normal spaces inside a Text item.
        spacing: Style.spacing.lg

        Text {
          visible: panelLoader.item ? panelLoader.item.showAmbientOnBar : true
          width: implicitWidth
          height: Style.bar.iconCanvas
          text: panelLoader.item ? panelLoader.item.ambientText : ""
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.bodySmall
          renderType: Text.NativeRendering
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          visible: panelLoader.item
            ? panelLoader.item.showAmbientOnBar && panelLoader.item.showTargetOnBar : true
          width: implicitWidth
          height: Style.bar.iconCanvas
          text: "→"
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.caption
          renderType: Text.NativeRendering
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          visible: panelLoader.item ? panelLoader.item.showTargetOnBar : true
          width: implicitWidth
          height: Style.bar.iconCanvas
          text: panelLoader.item ? panelLoader.item.targetText : ""
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.bodySmall
          renderType: Text.NativeRendering
          verticalAlignment: Text.AlignVCenter
        }
      }

      Row {
        id: offValues
        visible: !root.vertical && !root.powerPending
          && (panelLoader.item ? panelLoader.item.connected && !panelLoader.item.isOn : false)
        height: Style.bar.iconCanvas
        spacing: Style.spacing.lg

        Text {
          visible: panelLoader.item ? panelLoader.item.showAmbientOnBar : true
          width: implicitWidth
          height: Style.bar.iconCanvas
          text: panelLoader.item ? panelLoader.item.ambientText : ""
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.bodySmall
          renderType: Text.NativeRendering
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          visible: panelLoader.item
            ? panelLoader.item.showAmbientOnBar && panelLoader.item.showTargetOnBar : true
          width: implicitWidth
          height: Style.bar.iconCanvas
          text: "→"
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.caption
          renderType: Text.NativeRendering
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          visible: panelLoader.item ? panelLoader.item.showTargetOnBar : true
          width: implicitWidth
          height: Style.bar.iconCanvas
          text: panelLoader.item ? panelLoader.item.targetText : ""
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: Style.font.bodySmall
          renderType: Text.NativeRendering
          verticalAlignment: Text.AlignVCenter
        }

        Text {
          width: implicitWidth
          height: Style.bar.iconCanvas
          text: "· OFF"
          color: Qt.darker(button.foreground, 1.35)
          font.family: button.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.weight: Font.Normal
          renderType: Text.NativeRendering
          verticalAlignment: Text.AlignVCenter
        }
      }

    }

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.togglePower()
      else if (buttonCode === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}
