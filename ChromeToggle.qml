import qs.Commons
import qs.Ui

// Toggle row variant that can drop its surface chrome while keeping the
// standard hover/focus behaviour when chromeLess is disabled.
Toggle {
  id: root

  property bool chromeLess: false
  property bool pointerHot: false
  // Compact appearance removes a little vertical breathing room from toggle
  // rows as well as removing their card chrome.
  property bool compact: chromeLess

  onHovered: function(isHovered) { root.pointerHot = isHovered }

  // Toggle.qml computes its own height from these inherited text properties;
  // shrinking the title in compact mode keeps that calculation intact while
  // avoiding clipped multi-line descriptions.
  titleSize: root.compact ? Style.font.bodySmall : Style.font.subtitle

  color: root.chromeLess
    ? "transparent"
    : Style.controlFill(root.activeFocus, root.hasCursor || root.pointerHot,
        root.foreground, root.accent)
  borderSpec: root.chromeLess
    ? Border.none()
    : Border.controlSpec(root.activeFocus ? "focus"
        : (root.hasCursor || root.pointerHot ? "hover-cursor" : "normal"),
        root.foreground, root.accent)
}
