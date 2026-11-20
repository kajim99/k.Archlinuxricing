import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Power mode pill next to the active window title (2026-11-14, replaces the small util-row button).
// Click: Power saver -> Balanced -> Performance (= Lenovo Custom at every firmware max, purple light).
// Reads the real firmware mode via ~/.local/bin/power-mode (power-profiles-daemon can't see Custom).
Rectangle {
    id: pill
    property string mode: "balanced"
    readonly property string icon: ({ saver: "eco", balanced: "balance", max: "bolt", performance: "bolt", custom: "tune" })[mode] ?? "balance"
    readonly property string label: ({ saver: "Power saver", balanced: "Balanced", max: "Performance", performance: "Performance (red)", custom: "Custom" })[mode] ?? mode

    Process {
        id: getMode
        command: ["bash", "-c", "$HOME/.local/bin/power-mode get"]
        stdout: StdioCollector { onStreamFinished: pill.mode = text.trim() }
    }
    Process {
        id: cycleMode
        command: ["bash", "-c", "$HOME/.local/bin/power-mode cycle"]
        onExited: getMode.running = true
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: getMode.running = true }

    readonly property int iconPx: Math.round(Appearance.font.pixelSize.large * 1.6)

    implicitWidth: row.implicitWidth + 24
    implicitHeight: Math.max(row.implicitHeight + 6, 34)
    radius: height / 2
    color: mouse.containsMouse ? "#3a1470" : "#24104a"
    border.width: 1
    border.color: "#8703ff"
    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Item {
            implicitWidth: violetFill.implicitWidth
            implicitHeight: violetFill.implicitHeight
            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: pill.icon
                iconSize: Math.round(pill.iconPx * 1.18)
                color: "#0059e7"
            }
            MaterialSymbol {
                id: violetFill
                anchors.centerIn: parent
                fill: 1
                text: pill.icon
                iconSize: pill.iconPx
                color: "#8703ff"
            }
        }
        StyledText {
            text: pill.label
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            color: "#a020ff"
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cycleMode.running = true
    }
}
