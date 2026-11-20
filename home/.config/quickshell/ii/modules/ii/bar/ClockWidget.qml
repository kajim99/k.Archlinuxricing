import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // Numbers in violet (primary), letters in blue (secondary)
    function paint(str) {
        return str.replace(/([0-9]+)|([A-Za-z]+)/g, (m, num, word) =>
            `<font color="${num ? BarColors.colPrimary : Appearance.colors.colSecondary}">${m}</font>`);
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Config.options.appearance.fonts.numbers // Orbitron
            color: BarColors.colOnLayer1
            textFormat: Text.StyledText
            text: root.paint(DateTime.time)
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSecondary
            text: "•"
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: BarColors.colOnLayer1
            textFormat: Text.StyledText
            text: root.paint(DateTime.longDate)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
