import QtQuick
import qs.Commons

// Climate glyphs are icon-font characters, not geometric shapes. Their
// advance box is shared, but their painted bounds are not, so AlignHCenter /
// AlignVCenter leaves some modes visibly off-centre. Position the actual ink
// bounds in the available canvas instead.
Item {
  id: root

  property string text: ""
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.display
  property color color: Color.foreground
  property bool bold: false

  readonly property int renderedFontSize: Math.max(1, Math.round(root.fontSize))
  readonly property real inkWidth: Math.max(1, glyphMetrics.tightBoundingRect.width)
  readonly property real inkHeight: Math.max(1, glyphMetrics.tightBoundingRect.height)
  // TextMetrics reports the vertical tight bound from the baseline, while a
  // Text item's y coordinate starts at its top edge.
  readonly property real inkTop: glyph.baselineOffset + glyphMetrics.tightBoundingRect.y

  TextMetrics {
    id: glyphMetrics
    font.family: root.fontFamily
    font.pixelSize: root.renderedFontSize
    font.bold: root.bold
    text: root.text
  }

  Text {
    id: glyph
    x: Math.round((root.width - root.inkWidth) / 2 - glyphMetrics.tightBoundingRect.x)
    y: Math.round((root.height - root.inkHeight) / 2 - root.inkTop)
    textFormat: Text.PlainText
    text: root.text
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: root.renderedFontSize
    font.bold: root.bold
    renderType: Text.NativeRendering
  }
}
