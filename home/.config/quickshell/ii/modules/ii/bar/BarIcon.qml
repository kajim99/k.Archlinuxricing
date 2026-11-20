import qs.modules.common
import qs.modules.common.widgets
import QtQuick

// Bar icon in the cursor style (2026-11-14): violet filled glyph over a slightly bigger neon-blue copy = thin blue edge.
// Drop-in for MaterialSymbol in the bar: takes text + iconSize; fill/color/alignment are accepted but the style is fixed.
Item {
    id: root
    property string text: ""
    property real iconSize: Appearance.font.pixelSize.large
    property real fill: 1
    property color color: "#8703ff"
    property int horizontalAlignment: Text.AlignHCenter
    property int verticalAlignment: Text.AlignVCenter
    readonly property real size: Math.round(iconSize * 1.25)   // ~1.25x bigger than end-4's default

    implicitWidth: front.implicitWidth
    implicitHeight: front.implicitHeight

    MaterialSymbol {
        anchors.centerIn: parent
        fill: 1
        text: root.text
        iconSize: Math.round(root.size * 1.18)
        color: "#0059e7"
    }
    MaterialSymbol {
        id: front
        anchors.centerIn: parent
        fill: 1
        text: root.text
        iconSize: root.size
        color: "#8703ff"
    }
}
