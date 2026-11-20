import QtQuick
import qs.modules.common

// Single-line text that slides back and forth (ping-pong) when it doesn't fit
Item {
    id: root
    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    property int horizontalAlignment: Text.AlignLeft
    property int pauseDuration: 1400
    property real pixelsPerSecond: 28

    readonly property real overflow: Math.max(0, label.implicitWidth - root.width)
    property real offset: 0

    implicitWidth: 10 // Layouts/anchors decide the width; the text never pushes siblings
    implicitHeight: label.implicitHeight
    clip: true

    StyledText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        x: root.overflow > 0 ? -root.offset
            : root.horizontalAlignment === Text.AlignHCenter ? (root.width - implicitWidth) / 2
            : root.horizontalAlignment === Text.AlignRight ? root.width - implicitWidth
            : 0
    }

    onOverflowChanged: {
        root.offset = 0;
        if (slide.running) slide.restart();
    }

    SequentialAnimation {
        id: slide
        running: root.overflow > 0 && root.visible
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.offset = 0
        PauseAnimation { duration: root.pauseDuration }
        NumberAnimation {
            target: root; property: "offset"
            from: 0; to: root.overflow
            duration: root.overflow / root.pixelsPerSecond * 1000
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: root.pauseDuration }
        NumberAnimation {
            target: root; property: "offset"
            from: root.overflow; to: 0
            duration: root.overflow / root.pixelsPerSecond * 1000
            easing.type: Easing.InOutSine
        }
    }
}
