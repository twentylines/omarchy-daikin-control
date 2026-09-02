import qs.Commons
import qs.Ui

// Toggle row variant that can drop its surface chrome while keeping the
// standard hover/focus behaviour when chromeLess is disabled.
Toggle {
  id: root

  property bool chromeLess: false
  property bool pointerHot: false

  onHovered: function(isHovered) { root.pointerHot = isHovered }

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
